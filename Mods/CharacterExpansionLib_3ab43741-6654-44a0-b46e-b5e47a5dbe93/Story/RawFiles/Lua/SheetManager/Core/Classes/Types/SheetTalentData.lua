local isClient = Ext.IsClient()

---@class SheetTalentData:SheetBaseData
---@field Requirements (StatRequirement[])|nil
---@field IncompatibleWith (string[])|nil
local SheetTalentData = {
	Type = "SheetTalentData",
	StatType = "Talent",
	TooltipType = "Talent",
	ValueType = "boolean",
	Icon = "",
	IconWidth = 128,
	IconHeight = 128,
	IsRacial = false,
	BaseValue = false
}

SheetTalentData.__index = function(t,k)
	local v = Classes.SheetTalentData[k] or Classes.SheetBaseData[k]
	if v then
		t[k] = v
	end
	return v
end

SheetTalentData.PropertyMap = {
	ISRACIAL = {Name="IsRacial", Type = "boolean"},
	REQUIREMENTS = {Name="Requirements", Type = "table"},
	INCOMPATIBLEWITH = {Name="IncompatibleWith", Type = "table"},
}

TableHelpers.AddOrUpdate(SheetTalentData.PropertyMap, Classes.SheetBaseData.PropertyMap)

local defaults = {
	Icon = "",
	IconWidth = SheetTalentData.IconWidth,
	IconHeight = SheetTalentData.IconHeight,
	IsRacial = false,
}

---@protected
function SheetTalentData.SetDefaults(data)
	if data.IsRacial and data.UsePoints == nil then
		data.UsePoints = false
	end
	Classes.SheetBaseData.SetDefaults(data)
	for k,v in pairs(defaults) do
		if data[k] == nil then
			if type(v) == "table" then
				data[k] = {}
			else
				data[k] = v
			end
		end
	end
end

---@param character CharacterParam
---@return boolean
function SheetTalentData:GetValue(character)
	return SheetManager:GetValueByEntry(self, GameHelpers.GetObjectID(character))
end

---@param character CharacterParam
---@return boolean
function SheetTalentData:IsUnlockable(character)
	local canUnlock = false
	if self.Requirements then
		canUnlock = GameHelpers.Stats.CharacterHasRequirements(character, self.Requirements)
	else
		canUnlock = true
	end

	if self.IncompatibleWith then
		for _,id in pairs(self.IncompatibleWith) do
			local actualId = id
			if string.find(id, "TALENT_") then
				actualId = string.gsub(id, "TALENT_", "")
			end
			if Data.Talents[actualId] then
				if character.Stats[id] == true then
					canUnlock = false
					break
				end
			elseif SheetManager.Talents.HasTalent(character, id) then
				canUnlock = false
				break
			end
		end
	end

	---@type SubscribableEventInvokeResult<SheetManagerCanUnlockTalentEventArgs>
	local invokeResult = SheetManager.Events.CanUnlockTalent:Invoke({
		ModuleUUID = self.Mod,
		CanUnlock = canUnlock,
		Character = character,
		CharacterID = GameHelpers.GetObjectID(character),
		ID = self.ID,
		EntryType = "SheetTalentData",
		Talent = self,
	})
	if invokeResult.ResultCode ~= "Error" then
		canUnlock = invokeResult.Args.CanUnlock == true
		if invokeResult.Results then
			for i=1,#invokeResult.Results do
				local b = invokeResult.Results[i]
				if type(b) == "boolean" then
					canUnlock = b
				end
			end
		end
	end
	return canUnlock
end

---@param character CharacterParam
---@return TalentState
function SheetTalentData:GetState(character)
	local value = self:GetValue(character)
	if value then
		return SheetManager.Talents.Data.TalentState.Selected
	else
		local canUnlock = self:IsUnlockable(character)
		if canUnlock then
			return SheetManager.Talents.Data.TalentState.Selectable
		end
	end
	return SheetManager.Talents.Data.TalentState.Locked
end

---@param character CharacterParam
---@param value boolean
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetTalentData:SetValue(character, value, skipListenerInvoke, skipSync)
	return SheetManager:SetEntryValue(self, character, value, skipListenerInvoke, skipSync)
end

---@param tbl StatRequirement[]
local function _GetRequirementLabels(tbl)
	local requirementLabels = {}
	for _,req in pairs(tbl) do
		if req.Requirement ~= "None" then
			local reqName = ""
			local notText = req.Not and "!" or ""
			if req.Requirement == "Level" then
				reqName = string.format("%s%s %i", notText, LocalizedText.Requirements.Level.Value, req.Param)
			elseif req.Requirement == "Combat" then
				if req.Not then
					reqName = string.format("%s%s", notText, LocalizedText.Requirements.NotCombat.Value)
				else
					reqName = string.format("%s%s", notText, LocalizedText.Requirements.Combat.Value)
				end
			elseif req.Requirement == "Immobile" then
				if req.Not then
					reqName = string.format("%s%s", notText, LocalizedText.Requirements.NotImmobile.Value)
				else
					reqName = string.format("%s%s", notText, LocalizedText.Requirements.Immobile.Value)
				end
			elseif req.Requirement == "TALENT_Sourcerer" then
				if req.Not then
					reqName = LocalizedText.Requirements.NotTALENT_Sourcerer.Value
				else
					reqName = LocalizedText.Requirements.TALENT_Sourcerer.Value
				end
			elseif req.Requirement == "Tag" then
				local tagReqName = LocalizedText.Requirements.Tag.Value
				if not StringHelpers.IsNullOrWhitespace(tagReqName) then
					tagReqName = tagReqName .. " "
				end
				local tagName = GameHelpers.GetStringKeyText(req.Param)
				reqName = string.format("%s%s%s", notText, tagReqName, tagName)
			elseif Data.Attribute[req.Requirement] then
				reqName = string.format("%s%s %i", notText, LocalizedText.AttributeNames[req.Requirement].Value, req.Param)
			elseif Data.Ability[req.Requirement] then
				reqName = string.format("%s%s %i", notText, LocalizedText.AbilityNames[req.Requirement].Value, req.Param)
			elseif Data.Talents[req.Requirement] or Data.Talents["TALENT_" .. req.Requirement] then
				local talentId = string.gsub(req.Requirement, "TALENT_", "")
				reqName = string.format("%s%s", notText, LocalizedText.TalentNames[talentId].Value)
			elseif Data.Traits[req.Requirement] or Data.Traits["TRAIT_" .. req.Requirement] then
				local traitId = string.gsub(req.Requirement, "TRAIT_", "")
				reqName = string.format("%s%s", notText, LocalizedText.TraitNames[traitId].Value)
			end
			if not StringHelpers.IsNullOrEmpty(reqName) then
				requirementLabels[#requirementLabels+1] = reqName
			end
		end
	end
	table.sort(requirementLabels)
	return requirementLabels
end

function SheetTalentData:GetRequirementText()
	local text = ""
	if self.Requirements then
		local requirementLabels = _GetRequirementLabels(self.Requirements)
		text = LocalizedText.Requirements.Requires:ReplacePlaceholders(StringHelpers.Join(", ", requirementLabels))
	end
	return text
end

---@param character? CharacterParam Optional character to pass to GameHelpers.Tooltip.ReplacePlaceholders.
function SheetTalentData:GetIncompatibleWithText(character)
	local text = ""
	if self.IncompatibleWith then
		local talentNames = {}
		for _,v in pairs(self.IncompatibleWith) do
			local talentId = string.gsub(v, "TALENT_", "")
			if Data.Talents[talentId] then
				talentNames[#talentNames+1] = LocalizedText.TalentNames[talentId].Value
			else
				local talent = SheetManager:GetEntryByID(talentId, nil, "Talent")
				if talent then
					talentNames[#talentNames+1] = talent:GetDisplayName(character)
				end
			end
		end
	end
	return text
end

SheetTalentData.ModifyValue = SheetTalentData.SetValue

---@param character CharacterParam
function SheetTalentData:HasTalent(character)
	return self:GetValue(character) == true
end

Classes.SheetTalentData = SheetTalentData