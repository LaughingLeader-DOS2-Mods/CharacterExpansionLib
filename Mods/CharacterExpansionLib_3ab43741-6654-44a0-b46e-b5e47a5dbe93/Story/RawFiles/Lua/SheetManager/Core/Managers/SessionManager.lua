local isClient = Ext.IsClient()

---@class CharacterCreationSessionPointsData
---@field Attribute integer
---@field Ability integer
---@field Civil integer
---@field Talent integer

---@class CharacterCreationSessionData
---@field Stats table
---@field PendingChanges table

local SessionManager = {
	---@type table<UUID,CharacterCreationSessionData>
	Sessions = {}
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
	---@param character EsvCharacter|EclCharacter|UUID|NETID
	---@param respec boolean
	---@param skipSync boolean|nil
	function SessionManager:CreateSession(character, respec, skipSync)
		character = GameHelpers.GetCharacter(character)
		local characterId = character.MyGuid

		if respec == nil then
			respec = false
		end

		local data = {
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

		self.Sessions[characterId] = data

		if skipSync ~= true then
			self:SyncSession(character)
		end

		return self.Sessions[characterId]
	end

	function SessionManager:SyncSession(character)
		local characterId = GameHelpers.GetCharacterID(character)
		if self.Sessions[characterId] then
			GameHelpers.Net.PostToUser(GameHelpers.GetUserID(characterId), "CEL_SessionManager_SyncCharacterData", self.Sessions[characterId])
		end
	end

	---@param character string
	---@param respec boolean
	---@param success boolean
	local function OnCharacterCreationStarted(character, respec, success)
		SessionManager:CreateSession(StringHelpers.GetUUID(character), respec)
	end
--[[ 
	---@param region string
	---@param state REGIONSTATE
	---@param levelType LEVELTYPE
	RegisterListener("RegionChanged", function (region, state, levelType)
		Ext.PrintError("RegionChanged", region, state, levelType)
		if levelType == LEVELTYPE.CHARACTER_CREATION and state ~= REGIONSTATE.ENDED then
			for player in GameHelpers.Character.GetPlayers(false) do
				fprint(LOGLEVEL.WARNING, "[CC:PlayerCheck] Name(%s) IsPlayer(%s) CharacterCreationFinished(%s) PlayerCustomData(%s) CharacterControl(%s)", player.DisplayName, player.IsPlayer, player.CharacterCreationFinished, player.PlayerCustomData ~= nil, player.CharacterControl)
				SessionManager:CreateSession(player, false)
			end
		end
	end)
 ]]
	Ext.RegisterOsirisListener("CharacterAddToCharacterCreation", 3, "after", function(character, respec, success)
		if success == 1 then
			OnCharacterCreationStarted(character, respec == 2, true)
		end
	end)

	Ext.RegisterOsirisListener("GameMasterAddToCharacterCreation", 3, "after", function(character, respec, success)
		if success == 1 then
			OnCharacterCreationStarted(character, respec == 2, true)
		end
	end)

	--Fallback in case none of the UI listeners notify the server that CC is done
	Ext.RegisterOsirisListener("CharacterCreationFinished", 1, "after", function(character)
		if not StringHelpers.IsNullOrEmpty(character) then
			Timer.StartOneshot("", 900, function()
				SheetManager.Save.CharacterCreationDone(character, true)
			end)
		end
	end)

	--[[ Ext.RegisterOsirisListener("CharacterCreationFinished", 1, "after", function(character)
		if character ~= StringHelpers.NULL_UUID then

		else

		end
	end) ]]
else
	RegisterNetListener("CEL_SessionManager_SyncCharacterData", function(cmd, payload)
		Ext.PrintError(cmd,payload)
		local data = Common.JsonParse(payload)
		if data then
			self.Sessions[data.NetID] = data
		end
	end)

	RegisterNetListener("CEL_SessionManager_ClearCharacterData", function(cmd, netid)
		netid = tonumber(netid)
		SessionManager:ClearSession(netid, true)
	end)

	RegisterNetListener("CEL_SessionManager_ApplyCharacterData", function(cmd, netid)
		netid = tonumber(netid)
		SessionManager:ApplySession(netid)
	end)
end

---@param character EsvCharacter|EclCharacter|UUID|NETID
function SessionManager:ClearSession(character, skipSync)
	character = GameHelpers.GetCharacter(character)
	local characterId = GameHelpers.GetCharacterID(character)
	SessionManager.Sessions[characterId] = nil
	--fprint(LOGLEVEL.TRACE, "[SessionManager:ClearSession:%s] Cleared session data for (%s)[%s]", isClient and "CLIENT" or "SERVER", character.DisplayName, characterId)
	if skipSync ~= true and not isClient then
		GameHelpers.Net.PostToUser(GameHelpers.GetUserID(characterId), "CEL_SessionManager_ClearCharacterData", character.NetID)
	end
end

---@param character EsvCharacter|EclCharacter|UUID|NETID
function SessionManager:ApplySession(character)
	character = GameHelpers.GetCharacter(character)
	if isClient then
		Ext.PostMessageToServer("CEL_SessionManager_ApplyCharacterData", character.NetID)
	else
		local characterId = GameHelpers.GetUUID(character)
		local sessionData = self.Sessions[characterId]
		if sessionData then
			fprint(LOGLEVEL.TRACE, "[SessionManager:ApplySession] Applying session changes.\n%s", Lib.serpent.block(sessionData.PendingChanges))
			if sessionData.PendingChanges then
				local data = SheetManager.CurrentValues[characterId] or SheetManager.Save.CreateCharacterData(characterId)
				for statType,mods in pairs(sessionData.PendingChanges) do
					if not data[statType] then
						data[statType] = {}
					end
					for modId,entries in pairs(mods) do
						if data[statType][modId] == nil then
							data[statType][modId] = entries
						else
							for id,value in pairs(entries) do
								data[statType][modId][id] = value
							end
						end
					end
				end
			end
		end
	end
	SessionManager:ClearSession(character)
end

---@param character EsvCharacter|EclCharacter|UUID|NETID
---@return CharacterCreationSessionData
function SessionManager:GetSession(character)
	local characterId = GameHelpers.GetCharacterID(character)
	return self.Sessions[characterId]
end

---Creates a table that can be used to get a current value of a session, that falls back to the character's Stats otherwise.
---This is mainly used when the UI builds the list of entries, for the character sheet or character creation UIs.
---@param character EsvCharacter|EclCharacter|UUID|NETID
---@return StatCharacter
function SessionManager:CreateCharacterSessionMetaTable(character)
	local character = GameHelpers.GetCharacter(character)
	local netid = character.NetID
	local sessionData = SheetManager.SessionManager:GetSession(character)
	if sessionData then
		local targetStats = {}
		setmetatable(targetStats, {
			__index = function(_, k)
				if isClient then
					local stats = CharacterCreationWizard.Stats[netid]
					if stats then
						return stats
					end
				end
				return character.Stats[k]
			end,
			__newindex = function(_, k, v)
				character.Stats[k] = v
			end
		})
		return targetStats
	else
		return character.Stats
	end
end

SheetManager.SessionManager = SessionManager