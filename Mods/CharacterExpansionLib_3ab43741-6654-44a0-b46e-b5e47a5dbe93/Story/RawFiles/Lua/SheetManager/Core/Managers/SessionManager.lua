local _ISCLIENT = Ext.IsClient()

---@class CharacterCreationSessionPointsData
---@field Attribute integer
---@field Ability integer
---@field Civil integer
---@field Talent integer

---@class CharacterCreationSessionData
---@field Stats table
---@field PendingChanges table

SessionManager = {
	---@type table<integer,CharacterCreationSessionData>
	Sessions = {},
	HasSessionData = false
}

local self = SessionManager

local function ErrorMessage(prefix, txt, ...)
	if #{...} > 0 then
		return prefix .. string.format(txt, ...)
	else
		return prefix .. txt
	end
end

if not _ISCLIENT then
	---@param character CharacterParam
	---@param respec boolean
	---@param skipSync boolean|nil
	function SessionManager:CreateSession(character, respec, skipSync)
		character = GameHelpers.GetCharacter(character)
		local characterId = character.MyGuid

		if respec == nil then
			respec = false
		end

		local data = {
			UserID = character.ReservedUserID,
			UUID = characterId,
			NetID = character.NetID,
			PendingChanges = {},
			Respec = respec
		}

		local currentValues = SheetManager.CurrentValues[characterId]
		if currentValues then
			TableHelpers.AddOrUpdate(data.PendingChanges, currentValues)
		end

		self.Sessions[character.ReservedUserID] = data

		SessionManager.HasSessionData = true

		if skipSync ~= true then
			self:SyncSession(character)
		end

		return data
	end

	---@param character  EsvCharacter
	function SessionManager:SyncSession(character)
		local player = GameHelpers.GetCharacter(character)
		if player then
			if self.Sessions[player.ReservedUserID] then
				GameHelpers.Net.PostToUser(player, "CEL_SessionManager_SyncCharacterData", {
					NetID = player.NetID,
					Data = self.Sessions[player.ReservedUserID],
				})
			else
				GameHelpers.Net.PostToUser(player, "CEL_SessionManager_ClearCharacterData", player.NetID)
			end
		end
	end

	---@param character string
	---@param respec boolean
	---@param success boolean
	local function OnCharacterCreationStarted(character, respec, success)
		SessionManager:CreateSession(StringHelpers.GetUUID(character), respec)
	end

	Events.RegionChanged:Subscribe(function(e)
		if e.LevelType == LEVELTYPE.CHARACTER_CREATION and e.State == REGIONSTATE.GAME then
			--[[ for player in GameHelpers.Character.GetPlayers(false) do
				SessionManager:CreateSession(player, false)
			end ]]
		elseif e.LevelType == LEVELTYPE.GAME and e.State == REGIONSTATE.GAME and SessionManager.HasSessionData then
			for player in GameHelpers.Character.GetPlayers(false) do
				SessionManager:ApplySession(player)
			end
			SessionManager.HasSessionData = false
		end
	end)

	Ext.Osiris.RegisterListener("CharacterAddToCharacterCreation", 3, "after", function(character, respec, success)
		if success == 1 then
			OnCharacterCreationStarted(character, respec == 2, true)
		end
	end)

	Ext.Osiris.RegisterListener("GameMasterAddToCharacterCreation", 3, "after", function(character, respec, success)
		if success == 1 then
			OnCharacterCreationStarted(character, respec == 2, true)
		end
	end)

else -- _ISCLIENT
	GameHelpers.Net.Subscribe("CEL_SessionManager_SyncCharacterData", function(e, data)
		if data.NetID then
			local player = GameHelpers.GetCharacter(data.NetID, "EclCharacter")
			if player then
				self.Sessions[player.Handle] = data.Data
				if SheetManager.UI.CharacterCreation.IsOpen then
					SheetManager.UI.CharacterCreation:UpdateAttributes()
					SheetManager.UI.CharacterCreation:UpdateAbilities()
					SheetManager.UI.CharacterCreation:UpdateTalents()
				end
			end
		end
	end)

	RegisterNetListener("CEL_SessionManager_ClearCharacterData", function(cmd, netIDStr)
		local netID = tonumber(netIDStr)
		local character = GameHelpers.GetCharacter(netID, "EclCharacter")
		if character and SessionManager.Sessions[character.Handle] ~= nil then
			SessionManager.Sessions[character.Handle] = nil
			fprint(LOGLEVEL.TRACE, "[CEL:SessionManager:Client] Cleared session data for (%s).", GameHelpers.GetDisplayName(character))
		end
	end)

	RegisterNetListener("CEL_SessionManager_ApplyCharacterData", function(cmd, userid)
		userid = tonumber(userid)
		local player = GameHelpers.GetCharacter(GetCurrentCharacter(userid))
		SessionManager:ApplySession(player)
	end)
end

---@param character CharacterParam
---@param skipSync ?boolean
function SessionManager:ClearSession(character, skipSync)
	if not _ISCLIENT then
		character = GameHelpers.GetCharacter(character)
		local characterId = GameHelpers.GetObjectID(character)
		SessionManager.Sessions[character.ReservedUserID] = nil
		--fprint(LOGLEVEL.TRACE, "[SessionManager:ClearSession:%s] Cleared session data for (%s)[%s]", isClient and "CLIENT" or "SERVER", character.DisplayName, characterId)
		if skipSync ~= true and not _ISCLIENT then
			GameHelpers.Net.PostToUser(GameHelpers.GetUserID(characterId), "CEL_SessionManager_ClearCharacterData", character.NetID)
		end
	end
	SessionManager.HasSessionData = Common.TableHasAnyEntry(SessionManager.Sessions)
end

---For reseting session data, such as when the preset changes.
---@param character CharacterParam
---@param skipSync ?boolean
---@param respec ?boolean
function SessionManager:ResetSession(character, skipSync, respec, isInCharacterCreation)
	character = GameHelpers.GetCharacter(character)
	local id = _ISCLIENT and character.Handle or character.ReservedUserID
	local respec = respec or SessionManager.Sessions[id] and SessionManager.Sessions[id].Respec
	SessionManager.Sessions[id] = nil
	if not _ISCLIENT then
		if skipSync ~= true then
			SessionManager:CreateSession(character, respec, skipSync)
		end
		-- if SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION or SheetManager.IsInCharacterCreation(characterId) then
		-- 	GameHelpers.Net.PostToUser(character, "CEL_CharacterCreation_UpdateEntries")
		-- end
	else
		GameHelpers.Net.PostMessageToServer("CEL_SessionManager_ResetCharacterData", {
			NetID = character.NetID,
			SkipSync = skipSync,
			Respec = respec
		})
	end
end

if not _ISCLIENT then
	RegisterNetListener("CEL_SessionManager_ResetCharacterData", function (cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			SessionManager:ResetSession(GameHelpers.GetCharacter(data.NetID), data.SkipSync, data.Respec)
		end
	end)
end

---@param character CharacterParam
function SessionManager:ApplySession(character)
	character = GameHelpers.GetCharacter(character)
	if _ISCLIENT then
		GameHelpers.Net.PostMessageToServer("CEL_SessionManager_ApplyCharacterData", character.ReservedUserID)
	else
		local characterId = GameHelpers.GetUUID(character)
		local sessionData = self:GetSession(character)
		if sessionData then
			if sessionData.PendingChanges then
				fprint(LOGLEVEL.TRACE, "[SessionManager:ApplySession] Applying session changes.\n%s", Lib.serpent.block(sessionData.PendingChanges))
				for statType,mods in pairs(sessionData.PendingChanges) do
					for modId,entries in pairs(mods) do
						for id,value in pairs(entries) do
							local stat = SheetManager:GetEntryByID(id, modId, statType)
							--SheetManager.Save.SetEntryValue(character.MyGuid, stat, value)
							SheetManager:SetEntryValue(stat, characterId, value, false, true, true, true)
						end
					end
				end
				SheetManager:SyncData(character)
			else
				fprint(LOGLEVEL.ERROR, "[SessionManager:ApplySession] Session data is missing PendingChanges for character %s", character.DisplayName)
			end
		else
			fprint(LOGLEVEL.ERROR, "[SessionManager:ApplySession] No active session for character (%s)\n%s", characterId, Lib.serpent.block(self.Sessions))
		end
	end
	SessionManager:ClearSession(character)
end

---@param character CharacterParam
---@return CharacterCreationSessionData
function SessionManager:GetSession(character)
	character = GameHelpers.GetCharacter(character)
	if not _ISCLIENT then
		return self.Sessions[character.ReservedUserID]
	else
		return self.Sessions[character.Handle]
	end
end

---@type CharacterCreationWizard
local CharacterCreationWizard = _ISCLIENT and Ext.Require("SheetManager/Core/Managers/Utilities/CharacterCreationWizard.lua") or {}
SessionManager.CharacterCreationWizard = CharacterCreationWizard

---Creates a table that can be used to get a current value of a session, that falls back to the character's Stats otherwise.
---This is mainly used when the UI builds the list of entries, for the character sheet or character creation UIs.
---@param character CharacterParam
---@return StatCharacter
function SessionManager:CreateCharacterSessionMetaTable(character)
	local character = GameHelpers.GetCharacter(character)
	local netid = character.NetID
	local sessionData = SessionManager:GetSession(character)
	if sessionData then
		local targetStats = {}
		setmetatable(targetStats, {
			__index = function(_, k)
				if _ISCLIENT then
					local stats = CharacterCreationWizard.Stats[netid]
					if stats then
						if k == "Stats" then
							return stats
						end
						return stats[k]
					end
				end
				if k == "Stats" then
					return character.Stats
				end
				return character.Stats[k]
			end,
			__newindex = function(_, k, v)
				if k == "Stats" then
					return
				end
				character.Stats[k] = v
			end
		})
		return targetStats
	else
		return character.Stats
	end
end