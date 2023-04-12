local isClient = Ext.IsClient()

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

if not isClient then
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

		-- for k,v in pairs(Data.AttributeEnum) do
		-- 	data.Stats[k] = character.Stats[k]
		-- end
		-- for k,v in pairs(Data.AbilityEnum) do
		-- 	data.Stats[k] = character.Stats[k]
		-- end
		-- for k,v in pairs(Data.TalentEnum) do
		-- 	data.Stats["TALENT_" .. k] = character.Stats["TALENT_" .. k]
		-- end

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
		if self.Sessions[player.ReservedUserID] then
			GameHelpers.Net.PostToUser(player, "CEL_SessionManager_SyncCharacterData", {
				NetID = player.NetID,
				Data = self.Sessions[player.ReservedUserID],
			})
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

	--Fallback in case none of the UI listeners notify the server that CC is done
	-- Ext.Osiris.RegisterListener("CharacterCreationFinished", 1, "after", function(character)
	-- 	if not StringHelpers.IsNullOrEmpty(character) then
	-- 		Timer.StartOneshot("", 900, function()
	-- 			SheetManager.Save.CharacterCreationDone(character, true)
	-- 		end)
	-- 	else
	-- 		for player in GameHelpers.Character.GetPlayers(false) do
	-- 			SheetManager.Save.CharacterCreationDone(player, true)
	-- 		end
	-- 	end
	-- end)

	--[[ Ext.Osiris.RegisterListener("CharacterCreationFinished", 1, "after", function(character)
		if character ~= StringHelpers.NULL_UUID then

		else

		end
	end) ]]
else
	RegisterNetListener("CEL_SessionManager_SyncCharacterData", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			self.Sessions[data.NetID] = data.Data
			if SheetManager.UI.CharacterCreation.IsOpen then
				SheetManager.UI.CharacterCreation:UpdateAttributes()
				SheetManager.UI.CharacterCreation:UpdateAbilities()
				SheetManager.UI.CharacterCreation:UpdateTalents()
			end
		end
	end)

	RegisterNetListener("CEL_SessionManager_ClearCharacterData", function(cmd, netid)
		netid = tonumber(netid)
		SessionManager:ClearSession(netid, true)
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
	if not isClient then
		character = GameHelpers.GetCharacter(character)
		local characterId = GameHelpers.GetObjectID(character)
		SessionManager.Sessions[character.ReservedUserID] = nil
		--fprint(LOGLEVEL.TRACE, "[SessionManager:ClearSession:%s] Cleared session data for (%s)[%s]", isClient and "CLIENT" or "SERVER", character.DisplayName, characterId)
		if skipSync ~= true and not isClient then
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
	local id = isClient and character.NetID or character.ReservedUserID
	local respec = respec or SessionManager.Sessions[id] and SessionManager.Sessions[id].Respec
	SessionManager.Sessions[id] = nil
	if not isClient then
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

if not isClient then
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
	if isClient then
		GameHelpers.Net.PostMessageToServer("CEL_SessionManager_ApplyCharacterData", character.ReservedUserID)
	else
		local characterId = GameHelpers.GetUUID(character)
		local sessionData = self:GetSession(character)
		if sessionData then
			if sessionData.PendingChanges then
				fprint(LOGLEVEL.TRACE, "[SessionManager:ApplySession] Applying session changes.\n%s", Lib.serpent.block(sessionData.PendingChanges))
				-- local data = SheetManager.CurrentValues[characterId] or SheetManager.Save.CreateCharacterData(characterId)
				-- for statType,mods in pairs(sessionData.PendingChanges) do
				-- 	if not data[statType] then
				-- 		data[statType] = {}
				-- 	end
				-- 	for modId,entries in pairs(mods) do
				-- 		if data[statType][modId] == nil then
				-- 			data[statType][modId] = entries
				-- 		else
				-- 			for id,value in pairs(entries) do
				-- 				data[statType][modId][id] = value
				-- 			end
				-- 		end
				-- 	end
				-- end
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
	if not isClient then
		return self.Sessions[character.ReservedUserID]
	else
		return self.Sessions[character.NetID]
	end
end

---@type CharacterCreationWizard
local CharacterCreationWizard = isClient and Ext.Require("SheetManager/Core/Managers/Utilities/CharacterCreationWizard.lua") or {}
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
				if isClient then
					local stats = CharacterCreationWizard.Stats[netid]
					if stats then
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