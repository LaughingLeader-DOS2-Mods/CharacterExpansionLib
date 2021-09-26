local self = SheetManager
local isClient = Ext.IsClient()


---Get a sheet entry from a string id.
---@param id string
---@param mod string|nil
---@param statType SheetEntryType|nil Stat type.
---@return SheetAbilityData|SheetStatData|SheetTalentData
function SheetManager:GetEntryByID(id, mod, statType)
	local targetTable = nil
	if statType then
		if statType == "Stat" or statType == "Stats" or statType == "PrimaryStat" or statType == "SecondaryStat" then
			targetTable = self.Data.Stats
		elseif statType == "Ability" or statType == "Abilities" then
			targetTable = self.Data.Abilities
		elseif statType == "Talent" or statType == "Talents" then
			targetTable = self.Data.Talents
		elseif statType == "CustomStats" then
			return SheetManager.CustomStats:GetStatByID(id, mod)
		end
	end
	if targetTable then
		if mod then
			return targetTable[mod][id]
		else
			for modId,tbl in pairs(targetTable) do
				if tbl[id] then
					return tbl[id]
				end
			end
		end
	end
	return nil
end

---Gets custom sheet data from a generated id.
---@param generatedId integer
---@param statType SheetEntryType|nil Optional stat type.
---@return SheetAbilityData|SheetStatData|SheetTalentData
function SheetManager:GetEntryByGeneratedID(generatedId, statType)
	if statType then
		if statType == "Stat" or statType == "PrimaryStat" or statType == "SecondaryStat" then
			return self.Data.ID_MAP.Stats.Entries[generatedId]
		elseif statType == "Ability" then
			return self.Data.ID_MAP.Abilities.Entries[generatedId]
		elseif statType == "Talent" then
			return self.Data.ID_MAP.Talents.Entries[generatedId]
		end
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
---@param characterId UUID|NETID
function SheetManager:GetValueByEntry(entry, characterId)
	if not StringHelpers.IsNullOrWhitespace(entry.BoostAttribute) then
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
	end
	if entry.StatType == "Talent" then
		return false
	end
	return 0
end

---Checks if an entry with the provided ID has the provided value.
---@param id string
---@param character EsvCharacter|EclCharacter|UUID|NETID
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
---@param entry SheetStatData|SheetAbilityData|SheetTalentData
---@param character EsvCharacter|EclCharacter|UUID|NETID
---@return integer
function SheetManager:GetBuiltinAvailablePointsForEntry(entry, character)
	local entryType = entry.StatType
	local isCivil = entryType == "Ability" and entry.IsCivil

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

	return 0
end

---@alias AvailablePointsType string|'"Attribute"'|'"Ability"'|'"Civil"'|'"Talent"'|'"Custom"'

---@param characterId EsvCharacter|EclCharacter|UUID|NETID|ObjectHandle
---@param pointType AvailablePointsType
function SheetManager:GetAvailablePoints(characterId, pointType)
	characterId = GameHelpers.GetCharacterID(characterId)

	local sessionData = SheetManager.SessionManager:GetSession(characterId)
	if sessionData then
		local base = 0
		if SheetManager.AvailablePoints[characterId] then
			base = SheetManager.AvailablePoints[characterId][pointType] or 0
		end
		if pointType == "Attribute" then
			return base + sessionData.ModifyPoints.Attribute
		elseif pointType == "Ability" then
			return base + sessionData.ModifyPoints.Ability
		elseif pointType == "Civil" then
			return base + sessionData.ModifyPoints.Civil
		elseif pointType == "Talent" then
			return base + sessionData.ModifyPoints.Talent
		end
	end

	if isClient then
		if SheetManager.AvailablePoints[characterId] then
			return SheetManager.AvailablePoints[characterId][pointType] or 0
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

	for t,tbl in pairs(self.Data.Stats) do
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