local isClient = Ext.IsClient()

---@class SheetTalentData:SheetBaseData
---@field Requirements (StatRequirement[])|nil
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
	end

	---@type SubscribableEventInvokeResult<SheetManagerCanUnlockTalentEventArgs>
	local invokeResult = SheetManager.Events.CanUnlockTalent:Invoke({
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

---@class TalentState
local TalentState = {
	Selected = 0,
	Selectable = 2,
	Locked = 3
}

---@param character CharacterParam
---@return integer
function SheetTalentData:GetState(character)
	local value = self:GetValue(character)
	if value then
		return TalentState.Selected
	else
		local canUnlock = self:IsUnlockable(character)
		if canUnlock then
			return TalentState.Selectable
		end
	end
	return TalentState.Locked
end

---@param character CharacterParam
---@param value boolean
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetTalentData:SetValue(character, value, skipListenerInvoke, skipSync)
	return SheetManager:SetEntryValue(self, character, value, skipListenerInvoke, skipSync)
end

SheetTalentData.ModifyValue = SheetTalentData.SetValue

---@param character CharacterParam
function SheetTalentData:HasTalent(character)
	return self:GetValue(character) == true
end

Classes.SheetTalentData = SheetTalentData