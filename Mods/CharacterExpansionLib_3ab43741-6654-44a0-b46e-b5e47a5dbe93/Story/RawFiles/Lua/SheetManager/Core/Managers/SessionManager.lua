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
			Ext.PostMessageToClient(characterId, "CEL_SessionManager_SyncCharacterData", Ext.JsonStringify(self.Sessions[characterId]))
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
		Ext.PostMessageToClient(character.MyGuid, "CEL_SessionManager_ClearCharacterData", character.NetID)
	end
end

---@param character EsvCharacter|EclCharacter|UUID|NETID
function SessionManager:ApplySession(character)
	character = GameHelpers.GetCharacter(character)
	
	if isClient then
		Ext.PostMessageToServer("CEL_SessionManager_ApplyCharacterData", character.NetID)
	else
		local characterId = character.MyGuid
		local sessionData = self.Sessions[characterId]
		if sessionData then
			--fprint(LOGLEVEL.TRACE, "[SessionManager:ApplySession] Applying session changes.\n%s", Lib.serpent.block(sessionData))
			local currentPoints = {
				Attribute = CharacterGetAttributePoints(characterId),
				Ability = CharacterGetAbilityPoints(characterId),
				Civil = CharacterGetCivilAbilityPoints(characterId),
				Talent = CharacterGetTalentPoints(characterId),
			}
			if sessionData.ModifyPoints.Attribute ~= 0 and sessionData.ModifyPoints.Attribute + currentPoints.Attribute >= 0 then
				CharacterAddAttributePoint(characterId, sessionData.ModifyPoints.Attribute)
			end
			if sessionData.ModifyPoints.Ability ~= 0 and sessionData.ModifyPoints.Ability + currentPoints.Ability >= 0 then
				CharacterAddAbilityPoint(characterId, sessionData.ModifyPoints.Ability)
			end
			if sessionData.ModifyPoints.Civil ~= 0 and sessionData.ModifyPoints.Civil + currentPoints.Civil >= 0 then
				CharacterAddCivilAbilityPoint(characterId, sessionData.ModifyPoints.Civil)
			end
			if sessionData.ModifyPoints.Talent ~= 0 and sessionData.ModifyPoints.Talent + currentPoints.Talent >= 0 then
				CharacterAddTalentPoint(characterId, sessionData.ModifyPoints.Talent)
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
								if type(data[statType][modId][id]) == "number" then
									data[statType][modId][id] = data[statType][modId][id] + value
								else
									data[statType][modId][id] = value
								end
							end
						end
					end
				end
			end

			SheetManager:SyncData(character)
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

SheetManager.SessionManager = SessionManager