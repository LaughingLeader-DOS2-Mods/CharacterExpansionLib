local _ISCLIENT = Ext.IsClient()

---@class CharacterCreationSessionPointsData
---@field Attribute integer
---@field Ability integer
---@field Civil integer
---@field Talent integer

---@class CharacterCreationSessionData
---@field UserID integer
---@field NetID integer
---@field PendingChanges SheetManagerSaveData
---@field Respec boolean

SessionManager = {
	---@type table<ComponentHandle,CharacterCreationSessionData>
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
	---@param character EsvCharacter|EclCharacter
	---@param respec boolean
	---@param skipSync boolean|nil
	function SessionManager:CreateSession(character, respec, skipSync)
		local characterId = character.MyGuid

		if respec == nil then
			respec = false
		end

		---@type CharacterCreationSessionData
		local data = {
			UserID = character.ReservedUserID,
			UUID = characterId,
			NetID = character.NetID,
			PendingChanges = {},
			Respec = respec
		}

		local currentValues = SheetManager.CurrentValues[characterId]
		if currentValues then
			for k,v in pairs(currentValues) do
				if k ~= "CustomStats" then
					data.PendingChanges[k] = TableHelpers.Clone(v)
				end
			end
		end

		self.Sessions[character.ReservedUserID] = data

		SessionManager.HasSessionData = true

		if skipSync ~= true then
			self:SyncSession(character)
		end

		return data
	end

	---@param player EsvCharacter
	function SessionManager:SyncSession(player)
		if self.Sessions[player.ReservedUserID] then
			GameHelpers.Net.PostToUser(player, "CEL_SessionManager_SyncCharacterData", {
				UserID = player.ReservedUserID,
				NetID = player.NetID,
				Data = self.Sessions[player.ReservedUserID],
			})
		else
			GameHelpers.Net.PostToUser(player, "CEL_SessionManager_ClearCharacterData", player.ReservedUserID)
		end
	end

	---@param characterGUID Guid
	---@param respec boolean
	---@param success boolean
	local function OnCharacterCreationStarted(characterGUID, respec, success)
		local character = GameHelpers.GetCharacter(characterGUID)
		assert(character ~= nil, ("Failed to get character being added to character creation: (%s)"):format(characterGUID or "nil"))
		SessionManager:CreateSession(character, respec)
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
	---@class CEL_SessionManager_SyncCharacterData
	---@field UserID integer
	---@field NetID integer
	---@field Data table

	GameHelpers.Net.Subscribe("CEL_SessionManager_SyncCharacterData", function(e, data)
		if data.NetID then
			self.Sessions[data.UserID] = data.Data
			if SheetManager.UI.CharacterCreation.IsOpen then
				SheetManager.UI.CharacterCreation:UpdateAttributes()
				SheetManager.UI.CharacterCreation:UpdateAbilities()
				SheetManager.UI.CharacterCreation:UpdateTalents()
			end
		end
	end)

	RegisterNetListener("CEL_SessionManager_ClearCharacterData", function(cmd, userIDStr)
		local userID = tonumber(userIDStr)
		if userID and SessionManager.Sessions[userID] ~= nil then
			SessionManager.Sessions[userID] = nil
			fprint(LOGLEVEL.TRACE, "[CEL:SessionManager:Client] Cleared session data for (%s).", userID)
		end
	end)

	RegisterNetListener("CEL_SessionManager_ApplyCharacterData", function(cmd, netid)
		netid = tonumber(netid)
		local player = GameHelpers.GetCharacter(netid)
		SessionManager:ApplySession(player)
	end)

	RegisterNetListener("CEL_SessionManager_ApplyCharacterData_User", function(cmd, userid)
		userid = tonumber(userid)
		local player = GameHelpers.GetCharacter(Osi.GetCurrentCharacter(userid))
		SessionManager:ApplySession(player)
	end)
end

---@param character EsvCharacter|EclCharacter
---@param skipSync ?boolean
function SessionManager:ClearSession(character, skipSync)
	if not _ISCLIENT then
		SessionManager.Sessions[character.ReservedUserID] = nil
		--fprint(LOGLEVEL.TRACE, "[SessionManager:ClearSession:%s] Cleared session data for (%s)[%s]", isClient and "CLIENT" or "SERVER", character.DisplayName, characterId)
		if skipSync ~= true and not _ISCLIENT then
			GameHelpers.Net.PostToUser(character, "CEL_SessionManager_ClearCharacterData", character.NetID)
		end
	end
	SessionManager.HasSessionData = Common.TableHasAnyEntry(SessionManager.Sessions)
end

---For reseting session data, such as when the preset changes.
---@param character EsvCharacter|EclCharacter
---@param skipSync ?boolean
---@param respec ?boolean
function SessionManager:ResetSession(character, skipSync, respec)
	local id = not _ISCLIENT and character.ReservedUserID or Client:GetCharacterData().ID
	local respec = respec
	if respec == nil and SessionManager.Sessions[id] then
		respec = SessionManager.Sessions[id].Respec == true
	end
	SessionManager.Sessions[id] = nil
	if not _ISCLIENT then
		if skipSync ~= true then
			SessionManager:CreateSession(character, respec, skipSync)
		end
	else
		GameHelpers.Net.PostMessageToServer("CEL_SessionManager_ResetCharacterData", {
			UserID = id,
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

---@param character EsvCharacter|EclCharacter
function SessionManager:ApplySession(character)
	if _ISCLIENT then
		---@cast character EclCharacter
		if GameHelpers.IsLevelType(LEVELTYPE.CHARACTER_CREATION) then
			GameHelpers.Net.PostMessageToServer("CEL_SessionManager_ApplyCharacterData_User", Client:GetCharacterData().ID)
		else
			GameHelpers.Net.PostMessageToServer("CEL_SessionManager_ApplyCharacterData", character.NetID)
		end
	else
		local sessionData = self:GetSession(character)
		if sessionData then
			if sessionData.PendingChanges then
				fprint(LOGLEVEL.TRACE, "[SessionManager:ApplySession] Applying session changes.\n%s", Lib.serpent.block(sessionData.PendingChanges))
				for statType,mods in pairs(sessionData.PendingChanges) do
					for modId,entries in pairs(mods) do
						for id,value in pairs(entries) do
							local stat = SheetManager:GetEntryByID(id, modId, statType)
							--SheetManager.Save.SetEntryValue(character.MyGuid, stat, value)
							SheetManager:SetEntryValue(stat, character, value, false, true, true, true)
						end
					end
				end
				SheetManager:SyncData(character)
			else
				fprint(LOGLEVEL.ERROR, "[SessionManager:ApplySession] Session data is missing PendingChanges for character %s", character.DisplayName)
			end
		else
			fprint(LOGLEVEL.ERROR, "[SessionManager:ApplySession] No active session for character (%s)\n%s", character.MyGuid, Lib.serpent.block(self.Sessions))
		end
	end
	SessionManager:ClearSession(character)
end

---@param character EsvCharacter|EclCharacter
---@return CharacterCreationSessionData
function SessionManager:GetSession(character)
	if _ISCLIENT then
		return self.Sessions[Client:GetCharacterData().ID]
	else
		return self.Sessions[character.ReservedUserID]
	end
end

---@type CharacterCreationWizard
local CharacterCreationWizard = _ISCLIENT and Ext.Require("SheetManager/Core/Managers/Utilities/CharacterCreationWizard.lua") or {}
SessionManager.CharacterCreationWizard = CharacterCreationWizard

---Creates a table that can be used to get a current value of a session, that falls back to the character's Stats otherwise.
---This is mainly used when the UI builds the list of entries, for the character sheet or character creation UIs.
---@param character EsvCharacter|EclCharacter
---@return StatCharacter
function SessionManager:CreateCharacterSessionMetaTable(character)
	print("CreateCharacterSessionMetaTable", GameHelpers.GetDisplayName(character), character.MyGuid, character.UserID, GameHelpers.GetTemplate(character, true).Name)
	local handle = character.Handle
	local sessionData = SessionManager:GetSession(character)
	if sessionData then
		local targetStats = {}
		setmetatable(targetStats, {
			__index = function(_, k)
				local player = GameHelpers.GetObjectFromHandle(handle, "EclCharacter")
				if _ISCLIENT then
					local stats = CharacterCreationWizard.Stats[player]
					if stats then
						if k == "Stats" then
							return stats
						end
						return stats[k]
					end
				end
				if k == "Stats" then
					return player.Stats
				end
				return player.Stats[k]
			end,
			__newindex = function(_, k, v)
				if k == "Stats" then
					return
				end
				local player = GameHelpers.GetObjectFromHandle(handle, "EclCharacter")
				player.Stats[k] = v
			end
		})
		return targetStats
	else
		return character.Stats
	end
end

---Callback for when a character exits character creation, for applying pending changes, if any.
---@param player EsvCharacter|EclCharacter
---@param applyChanges boolean
function SessionManager.CharacterCreationDone(player, applyChanges)
	if not _ISCLIENT then
		if applyChanges == true then
			SessionManager:ApplySession(player)
		else
			SessionManager:ClearSession(player, true)
		end
		SheetManager:SyncData(player)
	else
		GameHelpers.Net.PostMessageToServer("CEL_SessionManager_CharacterCreationDone", {
			UserId = Client.Character.ID,
			ApplyChanges = applyChanges
		})
	end
end

if not _ISCLIENT then
	Ext.Events.SessionLoaded:Subscribe(function ()
		Events.Osiris.CharacterCreationFinished:Subscribe(function (e)
			if e.Character then
				local handle = e.Character.Handle
				Timer.StartOneshot("", 250, function ()
					if SessionManager.Sessions[handle] ~= nil then
						local player = GameHelpers.GetObjectFromHandle(handle, "EsvCharacter")
						fprint(LOGLEVEL.WARNING, "[SessionManager] CC session not cleared for character (%s)[%s]", GameHelpers.GetDisplayName(player), player.MyGuid)
						SessionManager:ClearSession(player)
					end
				end)
			end
		end)
	end)

	---@class CEL_SessionManager_CharacterCreationDone
	---@field UserId integer
	---@field ApplyChanges boolean|nil

	GameHelpers.Net.Subscribe("CEL_SessionManager_CharacterCreationDone", function(e, data)
		local character = GameHelpers.GetCharacter(Osi.GetCurrentCharacter(data.UserId))
		if character then
			local applyChanges = data.ApplyChanges
			if applyChanges == nil then
				applyChanges = false
			end
			SessionManager.CharacterCreationDone(character, applyChanges)
		end
	end)
end