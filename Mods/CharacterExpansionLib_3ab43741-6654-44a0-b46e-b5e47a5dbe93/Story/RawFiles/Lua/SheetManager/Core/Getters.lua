local self = SheetManager
local _ISCLIENT = Ext.IsClient()


---Get a sheet entry from a string id.
---@param id string
---@param mod string|nil
---@param statType SheetEntryType|nil Stat type.
---@return SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
function SheetManager:GetEntryByID(id, mod, statType)
	local targetTable = nil
	if statType then
		if statType == "Stat" or statType == "Stats" or statType == self.StatType.PrimaryStat or statType == self.StatType.SecondaryStat then
			targetTable = self.Data.Stats
		elseif statType == self.StatType.Ability or statType == "Abilities" then
			targetTable = self.Data.Abilities
		elseif statType == self.StatType.Talent or statType == "Talents" then
			targetTable = self.Data.Talents
		elseif statType == self.StatType.Custom or statType == "CustomStats" then
			targetTable = self.Data.CustomStats
		elseif statType == "CustomStatCategories" then
			targetTable = self.Data.CustomStatCategories
		end
	end
	if targetTable then
		if mod and targetTable[mod] and targetTable[mod][id] then
			return targetTable[mod][id]
		end
		for modId,tbl in pairs(targetTable) do
			if tbl[id] then
				return tbl[id]
			end
		end
	end
	return nil
end

---Gets custom sheet data from a generated id.
---@param generatedId integer
---@param statType SheetEntryType|nil Optional stat type.
---@return AnyStatEntryDataType|nil
function SheetManager:GetEntryByGeneratedID(generatedId, statType)
	if statType then
		if statType == "Stat" or statType == "PrimaryStat" or statType == "SecondaryStat" or statType == "InfoStat" then
			return self.Data.ID_MAP.Stats.Entries[generatedId]
		elseif statType == "Ability" then
			return self.Data.ID_MAP.Abilities.Entries[generatedId]
		elseif statType == "Talent" then
			return self.Data.ID_MAP.Talents.Entries[generatedId]
		elseif statType == "Custom" or statType == "CustomStat" then
			return self.Data.ID_MAP.CustomStats.Entries[generatedId]
		elseif statType == "CustomCategory" then
			return self.Data.ID_MAP.CustomStatCategories.Entries[generatedId]
		end
		return nil
	end
	for t,tbl in pairs(self.Data.ID_MAP) do
		for checkId,data in pairs(tbl.Entries) do
			if checkId == generatedId then
				return data
			end
		end
	end
	return nil
end

---@param entry SheetAbilityData|SheetStatData|SheetTalentData
---@param characterId Guid|NETID
---@return integer|boolean
function SheetManager:GetValueByEntry(entry, characterId)
	local isInCharacterCreation = SheetManager.IsInCharacterCreation(characterId)
	if not StringHelpers.IsNullOrWhitespace(entry.BoostAttribute) then
		if not isInCharacterCreation then
			local character = GameHelpers.GetCharacter(characterId)
			if character and character.Stats then
				local charValue = character.Stats.DynamicStats[2][entry.BoostAttribute]
				if charValue ~= nil then
					return charValue
				end
			end
		else
			local value = SheetManager.Save.GetEntryValue(characterId, entry)
			if value ~= nil then
				return value
			end
			if _ISCLIENT then
				local stats = SessionManager.CharacterCreationWizard.Stats[characterId]
				if stats and stats[entry.BoostAttribute] then
					return stats[entry.BoostAttribute]
				end
			end
		end
	else
		local value = SheetManager.Save.GetEntryValue(characterId, entry)
		if value ~= nil then
			return value
		end
	end
	if entry.StatType == "Talent" then
		return false
	end
	return 0
end

---@param characterId Guid|NETID
---@param id string
---@param mod? string
---@param statType? SheetEntryType
---@return integer|boolean
function SheetManager:GetValueByID(characterId, id, mod, statType)
	local entry = self:GetEntryByID(id, mod, statType)
	if entry then
		return self:GetValueByEntry(entry, characterId)
	end
	if statType == "Talent" then
		return false
	end
	return 0
end

---Checks if an entry with the provided ID has the provided value.
---@param id string
---@param character CharacterParam
---@param value integer|boolean
---@param mod string|nil
---@param statType SheetEntryType|nil Optional stat type.
---@return boolean
function SheetManager:EntryHasValue(id, character, value, mod, statType)
	local targetTable = nil
	if statType then
		if statType == "Stat" or statType == "PrimaryStat" or statType == "SecondaryStat" then
			targetTable = self.Data.Stats
		elseif statType == "Ability" then
			targetTable = self.Data.Abilities
		elseif statType == "Talent" then
			targetTable = self.Data.Talents
		elseif statType == "Custom" then
			targetTable = self.Data.CustomStats
		elseif statType == "CustomCategory" then
			targetTable = self.Data.CustomStatCategories
		end
	end
	if targetTable then
		if mod then
			local entry = targetTable[mod][id]
			if entry then
				return self:GetValueByEntry(entry, character) == value
			end
		else
			for modId,tbl in pairs(targetTable) do
				if tbl[id] then
					if self:GetValueByEntry(tbl[id], character) == value then
						return true
					end
				end
			end
		end
	end
	return false
end

---Gets the builtin available points for a stat.
---@param entry SheetStatData|SheetAbilityData|SheetTalentData|SheetCustomStatData
---@param character CharacterParam
---@param clientCharacterCreationPoints table|nil If in CC, pass this from Ext.UI.GetCharacterCreationWizard
---@return integer
function SheetManager:GetBuiltinAvailablePointsForEntry(entry, character, clientCharacterCreationPoints)
	local entryType = entry.StatType

	local characterId = GameHelpers.GetObjectID(character)

	if entryType == "Custom" then
		if SheetManager.CustomAvailablePoints[characterId] then
			local pointID = entry:GetAvailablePointsID()
			return SheetManager.CustomAvailablePoints[characterId][pointID] or 0
		end
		return 0
	end

	local isCivil = entryType == "Ability" and entry.IsCivil

	if not clientCharacterCreationPoints then
		if entryType == "PrimaryStat" then
			return self:GetAvailablePoints(character, "Attribute")
		elseif entryType == "Ability" then
			if isCivil == true then
				return self:GetAvailablePoints(character, "Civil")
			else
				return self:GetAvailablePoints(character, "Ability")
			end
		elseif entryType == "Talent" then
			return self:GetAvailablePoints(character, "Talent")
		end
	else
		if entryType == "PrimaryStat" then
			return clientCharacterCreationPoints.Attribute
		elseif entryType == "Ability" then
			if isCivil == true then
				return clientCharacterCreationPoints.Civil
			else
				return clientCharacterCreationPoints.Ability
			end
		elseif entryType == "Talent" then
			return clientCharacterCreationPoints.Talent
		end
	end

	return 0
end

---@param characterId CharacterParam
---@param pointType AvailablePointsType
---@param customStatPointsID string|nil If pointType is "Custom", this is the point ID.
---@param isCharacterCreation ?boolean
function SheetManager:GetAvailablePoints(characterId, pointType, customStatPointsID, isCharacterCreation)
	characterId = GameHelpers.GetObjectID(characterId)

	if pointType == "Custom" then
		if _ISCLIENT then
			assert(not StringHelpers.IsNullOrWhitespace(customStatPointsID), "Param customStatPointsID needs to be a valid string (not empty/whitespace).")
			if SheetManager.CustomAvailablePoints[characterId] then
				return SheetManager.CustomAvailablePoints[characterId][customStatPointsID] or 0
			end
		else
			local data = PersistentVars.CustomStatAvailablePoints[characterId]
			if data then
				return data[customStatPointsID] or 0
			end
		end
		return 0
	elseif _ISCLIENT and isCharacterCreation then
		return SessionManager.CharacterCreationWizard.AvailablePoints[pointType]
	end

	if _ISCLIENT or not Ext.Osiris.IsCallable() then
		local character = GameHelpers.GetCharacter(characterId)
		if character.PlayerUpgrade then
			if pointType == "Attribute" then
				return character.PlayerUpgrade.AttributePoints or 0
			elseif pointType == "Ability" then
				return character.PlayerUpgrade.CombatAbilityPoints or 0
			elseif pointType == "Civil" then
				return character.PlayerUpgrade.CivilAbilityPoints or 0
			elseif pointType == "Talent" then
				return character.PlayerUpgrade.TalentPoints or 0
			end
		end
		if SheetManager.CustomAvailablePoints[characterId] then
			return SheetManager.CustomAvailablePoints[characterId][pointType] or 0
		end
	else
		if pointType == "Attribute" then
			return CharacterGetAttributePoints(characterId) or 0
		elseif pointType == "Ability" then
			return CharacterGetAbilityPoints(characterId) or 0
		elseif pointType == "Civil" then
			return CharacterGetCivilAbilityPoints(characterId) or 0
		elseif pointType == "Talent" then
			return CharacterGetTalentPoints(characterId) or 0
		end
	end
	return 0
end

---@param boostOnly boolean
---@param includeCustom boolean
---@return fun():SheetStatData|SheetAbilityData|SheetTalentData
function SheetManager:GetAllEntries(boostOnly, includeCustom)
	local entries = {}

	for _,tbl in pairs(self.Data.Stats) do
		for id,entry in pairs(tbl) do
			if boostOnly then
				if not StringHelpers.IsNullOrWhitespace(entry.BoostAttribute) then
					entries[#entries+1] = entry
				end
			else
				entries[#entries+1] = entry
			end
		end
	end

	for t,tbl in pairs(self.Data.Abilities) do
		for id,entry in pairs(tbl) do
			if boostOnly then
				if not StringHelpers.IsNullOrWhitespace(entry.BoostAttribute) then
					entries[#entries+1] = entry
				end
			else
				entries[#entries+1] = entry
			end
		end
	end

	for t,tbl in pairs(self.Data.Talents) do
		for id,entry in pairs(tbl) do
			if boostOnly then
				if not StringHelpers.IsNullOrWhitespace(entry.BoostAttribute) then
					entries[#entries+1] = entry
				end
			else
				entries[#entries+1] = entry
			end
		end
	end

	if includeCustom then
		for t,tbl in pairs(self.CustomStats.Stats) do
			for id,entry in pairs(tbl) do
				if boostOnly then
					if not StringHelpers.IsNullOrWhitespace(entry.BoostAttribute) then
						entries[#entries+1] = entry
					end
				else
					entries[#entries+1] = entry
				end
			end
		end
	end

	local i = 0
	local total = #entries
	return function ()
		i = i + 1
		if i <= total then
			return entries[i]
		end
	end
end


---@param entry SheetStatData|SheetAbilityData|SheetTalentData|SheetCustomStatData
---@param character EclCharacter
---@param defaultValue boolean
---@param entryValue integer|boolean|nil The entry's current value. Provide one here to skip having to retrieve it.
function SheetManager:GetIsPlusVisible(entry, character, defaultValue, entryValue)
	if defaultValue == nil then
		defaultValue = GameHelpers.Client.IsGameMaster()
	end
	if entryValue == nil then
		entryValue = entry:GetValue(character)
	end
	if defaultValue == true and entry.StatType == SheetManager.StatType.Talent and entryValue == true then
		return false
	end
	local bResult = defaultValue
	---@type SubscribableEventInvokeResult<SheetManagerCanChangeEntryAnyTypeEventArgs>
	local invokeResult = self.Events.CanChangeEntry:Invoke({
		ModuleUUID = entry.Mod,
		EntryType = entry.Type,
		ID = entry.ID,
		Value = entryValue,
		Character = character,
		CharacterID = character.NetID,
		Stat = entry,
		Result = bResult,
		Action = "Add",
	})
	if invokeResult.ResultCode ~= "Error" then
		bResult = invokeResult.Args.Result == true
	end
	return bResult
end

---@param entry SheetStatData|SheetAbilityData|SheetTalentData|SheetCustomStatData
---@param character EclCharacter
---@param defaultValue boolean
---@param entryValue integer|boolean|nil The entry's current value. Provide one here to skip having to retrieve it.
function SheetManager:GetIsMinusVisible(entry, character, defaultValue, entryValue)
	if defaultValue == nil then
		defaultValue = GameHelpers.Client.IsGameMaster()
	end
	if entryValue == nil then
		entryValue = entry:GetValue(character)
	end
	if defaultValue == true and entry.StatType == SheetManager.StatType.Talent and entryValue == false then
		return false
	end
	local bResult = defaultValue
	---@type SubscribableEventInvokeResult<SheetManagerCanChangeEntryAnyTypeEventArgs>
	local invokeResult = self.Events.CanChangeEntry:Invoke({
		ModuleUUID = entry.Mod,
		EntryType = entry.Type,
		ID = entry.ID,
		Value = entryValue,
		Character = character,
		CharacterID = character.NetID,
		Stat = entry,
		Result = bResult,
		Action = "Remove",
	})
	if invokeResult.ResultCode ~= "Error" then
		bResult = invokeResult.Args.Result == true
	end
	return bResult
end

---@param entry SheetStatData|SheetAbilityData|SheetTalentData|SheetCustomStatData
---@param character EclCharacter
---@param entryValue integer|boolean|nil The entry's current value. Provide one here to skip having to retrieve it.
---@param isCharacterCreation boolean|nil
---@param isGM boolean|nil
function SheetManager:IsEntryVisible(entry, character, entryValue, isCharacterCreation, isGM)
	if entryValue == nil then
		entryValue = entry:GetValue(character)
	end
	if isGM == nil then
		isGM = _ISCLIENT and GameHelpers.Client.IsGameMaster()
	end
	local bResult = entry.Visible == true
	--Default racial talents to not being visible
	if entry.IsRacial then
		bResult = isGM or entryValue == true
	end

	---@type SubscribableEventInvokeResult<SheetManagerCanChangeEntryAnyTypeEventArgs>
	local invokeResult = self.Events.CanChangeEntry:Invoke({
		ModuleUUID = entry.Mod,
		EntryType = entry.Type,
		ID = entry.ID,
		Value = entryValue,
		Character = character,
		CharacterID = character.NetID,
		Stat = entry,
		Result = bResult,
		Action = "Visibility",
	})
	if invokeResult.ResultCode ~= "Error" then
		bResult = invokeResult.Args.Result == true
	end
	return bResult
end