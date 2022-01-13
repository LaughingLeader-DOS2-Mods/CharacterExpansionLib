local isClient = Ext.IsClient()

---@class CharacterCreationSessionPointsData
---@field Attribute integer
---@field Ability integer
---@field Civil integer
---@field Talent integer

---@class CharacterCreationSessionData
---@field Stats table
---@field ModifyPoints CharacterCreationSessionPointsData
---@field PendingChanges table

local SessionManager = {
	---@type table<UUID,CharacterCreationSessionData>
	Sessions = {}
}

local self = SessionManager

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
			Stats = {},
			ModifyPoints = {
				Attribute = 0,
				Ability = 0,
				Civil = 0,
				Talent = 0,
			},
			PendingChanges = {},
			Respec = respec
		}

		for k,v in pairs(Data.AttributeEnum) do
			data.Stats[k] = character.Stats[k]
		end
		for k,v in pairs(Data.AbilityEnum) do
			data.Stats[k] = character.Stats[k]
		end
		for k,v in pairs(Data.TalentEnum) do
			data.Stats["TALENT_" .. k] = character.Stats["TALENT_" .. k]
		end

		self.Sessions[characterId] = data

		if skipSync ~= true then
			self:SyncSession(character)
		end

		return self.Sessions[characterId]
	end

	function SessionManager:SyncSession(character)
		local characterId = GameHelpers.GetCharacterID(character)
		if self.Sessions[characterId] then
			GameHelpers.Net.PostToUser(GameHelpers.GetUserID(characterId), "CEL_SessionManager_SyncCharacterData", Ext.JsonStringify(self.Sessions[characterId]))
		end
	end

	---@param character string
	---@param respec boolean
	---@param success boolean
	local function OnCharacterCreationStarted(character, respec, success)
		SessionManager:CreateSession(StringHelpers.GetUUID(character), respec)
	end

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
			fprint(LOGLEVEL.TRACE, "[SessionManager:ApplySession] Applying session changes.\n%s\n%s", Lib.serpent.block(sessionData.ModifyPoints), Lib.serpent.block(sessionData.PendingChanges))

			if sessionData.ModifyPoints then
				local modifyPoints = TableHelpers.Clone(sessionData.ModifyPoints)
				--Delay slightly because the engine will revert point changes otherwise
				Timer.StartOneshot(string.format("CEL_ApplyCCSessionData_%s", characterId), 500, function()
					local currentPoints = {
						Attribute = CharacterGetAttributePoints(characterId),
						Ability = CharacterGetAbilityPoints(characterId),
						Civil = CharacterGetCivilAbilityPoints(characterId),
						Talent = CharacterGetTalentPoints(characterId),
					}
					fprint(LOGLEVEL.TRACE, "[SessionManager:ApplySession] Apply point changes.\n%s\n%s", Lib.serpent.block(modifyPoints), Lib.serpent.block(currentPoints))
					if modifyPoints.Attribute ~= 0 and modifyPoints.Attribute + currentPoints.Attribute >= 0 then
						CharacterAddAttributePoint(characterId, modifyPoints.Attribute)
					end
					if modifyPoints.Ability ~= 0 and modifyPoints.Ability + currentPoints.Ability >= 0 then
						CharacterAddAbilityPoint(characterId, modifyPoints.Ability)
					end
					if modifyPoints.Civil ~= 0 and modifyPoints.Civil + currentPoints.Civil >= 0 then
						CharacterAddCivilAbilityPoint(characterId, modifyPoints.Civil)
					end
					if modifyPoints.Talent ~= 0 and modifyPoints.Talent + currentPoints.Talent >= 0 then
						CharacterAddTalentPoint(characterId, modifyPoints.Talent)
					end

					SheetManager.Sync.AvailablePoints(characterId)
				end)
			end
	
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
	local sessionData = SheetManager.SessionManager:GetSession(character)
	if sessionData then
		local targetStats = {}
		setmetatable(targetStats, {
			__index = function(_, k)
				if sessionData.Stats[k] then
					return sessionData.Stats[k]
				else
					return character.Stats[k]
				end
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