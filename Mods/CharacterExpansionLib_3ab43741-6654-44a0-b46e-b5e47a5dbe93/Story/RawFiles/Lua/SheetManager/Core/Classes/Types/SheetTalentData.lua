local isClient = Ext.IsClient()

---@class SheetTalentData:SheetBaseData
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

---@param character UUID|NETID|EsvCharacter|EclCharacter
---@return boolean
function SheetTalentData:GetValue(character)
	return SheetManager:GetValueByEntry(self, GameHelpers.GetObjectID(character))
end

---@class TalentState
local TalentState = {
	Selected = 0,
	Selectable = 2,
	Locked = 3
}

---@param character UUID|NETID|EsvCharacter|EclCharacter
---@return boolean
function SheetTalentData:GetState(character)
	local value = self:GetValue(character)
	if value then
		return TalentState.Selected
	else
		--TODO
		-- Hook into talent requirement listener
		return TalentState.Selectable
	end
end

---@param character EsvCharacter|EclCharacter|string|number
---@param value boolean
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetTalentData:SetValue(character, value, skipListenerInvoke, skipSync)
	return SheetManager:SetEntryValue(self, character, value, skipListenerInvoke, skipSync)
end

SheetTalentData.ModifyValue = SheetTalentData.SetValue

---@param character EsvCharacter|EclCharacter|string|number
function SheetTalentData:HasTalent(character)
	return self:GetValue(character) == true
end

Classes.SheetTalentData = SheetTalentData