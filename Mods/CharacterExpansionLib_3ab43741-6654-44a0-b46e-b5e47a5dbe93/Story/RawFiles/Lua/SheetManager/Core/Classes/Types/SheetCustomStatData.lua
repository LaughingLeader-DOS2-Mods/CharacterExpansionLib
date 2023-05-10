local isClient = Ext.IsClient()

---@class STAT_DISPLAY_MODE
local STAT_DISPLAY_MODE = {
	Default = "Integer",
	Percentage = "Percentage"
}

---@class SheetCustomStatData:SheetCustomStatBase
---@field UUID Guid|nil If this is an actual custom stat (GM mode), this is the UUID.
---@field Double number|nil If this is an actual custom stat (GM mode), this is the double handle used by the engine code.
---@field MaxValue number|nil If set, the add button logic will check the current amount against this value when determining if the stat can be added to.
local SheetCustomStatData = {
	Type="SheetCustomStatData",
	StatType = "Custom",
	---If true, the custom stat is created automatically on the server, if GM custom stats are enabled.
	Create = false,
	---Whether this custom stat uses custom available points.
	UsePoints = false,
	---A category ID this stat belongs to, if any. Defaults to the Miscellaneous category.
	Category = "MISC",
	---An ID to use for a common pool of available points.
	PointID = "",
	---@private
	---@type table<ComponentHandle|Guid,integer>
	LastValue = {},
	---Alternative display modes for a stat, such as percentage display.
	DisplayMode = STAT_DISPLAY_MODE.Default,
	DisplayValueInTooltip = false,
	---Enum values for DisplayMode.
	STAT_DISPLAY_MODE = STAT_DISPLAY_MODE,
	---Text to append to the value display, such as a percentage sign.
	Suffix = "",
	AutoAddAvailablePointsOnRemove = true,
}

---@param tbl SheetCustomStatData
SheetCustomStatData.__index = function(tbl,k)
	if k == "Handle" or k == "Double" then
		return tbl.GeneratedID
	end
	return SheetCustomStatData[k] or Classes.SheetCustomStatBase[k]
end

---@param tbl SheetCustomStatData|UnregisteredCustomStatData
SheetCustomStatData.__tostring = function (tbl)
	if tbl.UUID then
		return tostring(tbl.UUID)
	end
	return tostring(tbl.ID)
end

SheetCustomStatData.PropertyMap = {
	CREATE = {Name="Create", Type = "boolean"},
	CATEGORY = {Name="Category", Type = "string"},
	POINTID = {Name="PointID", Type = "string"},
	DISPLAYMODE = {Name="DisplayMode", Type = "string"},
	DISPLAYVALUEINTOOLTIP = {Name="DisplayValueInTooltip", Type = "boolean"},
	VISIBLE = {Name="Visible", Type = "boolean"},
	--Defaults to true. AvailablePoints are added to when a stat is reduced in the UI.
	AUTOADDAVAILABLEPOINTSONREMOVE = {Name="AutoAddAvailablePointsOnRemove", Type = "boolean"},
	MAXVALUE = {Name="MaxValue", Type = "number"},
}
---@deprecated
SheetCustomStatData.PropertyMap.MAXAMOUNT = SheetCustomStatData.PropertyMap.MAXVALUE

TableHelpers.AddOrUpdate(SheetCustomStatData.PropertyMap, Classes.SheetCustomStatBase.PropertyMap)

local defaults = {
	Create = SheetCustomStatData.Create,
	--Category = SheetCustomStatData.Category,
	PointID = SheetCustomStatData.PointID,
	LastValue = {},
	DisplayMode = SheetCustomStatData.DisplayMode,
	MaxValue = SheetCustomStatData.MaxValue,
	Suffix = SheetCustomStatData.Suffix,
	AutoAddAvailablePointsOnRemove = SheetCustomStatData.AutoAddAvailablePointsOnRemove,
}

local ID_MAP = 0

---@param data SheetCustomStatData|table
function SheetCustomStatData.SetDefaults(data)
	Classes.SheetCustomStatBase.SetDefaults(data)
	for k,v in pairs(defaults) do
		if data[k] == nil then
			if type(v) == "table" then
				data[k] = {}
			else
				data[k] = v
			end
		end
	end
	if StringHelpers.IsNullOrWhitespace(data.Category) then
		data.Category = nil
	end
	if not SheetManager.CustomStats:GMStatsEnabled() then
		data.GeneratedID = ID_MAP
		ID_MAP = ID_MAP + 1
	end
	if not StringHelpers.IsNullOrEmpty(data.PointID) then
		data.UsePoints = true
	end
end

---@class UnregisteredCustomStatData
---@field UUID string
Classes.UnregisteredCustomStatData = {
	Type = "UnregisteredCustomStatData",
	IsUnregistered = true,
	LastValue = {},
	__index = function(tbl,k)
		if k == "Type" then
			return "UnregisteredCustomStatData"
		end
		local v = rawget(Classes.UnregisteredCustomStatData, k)
		if v ~= nil then
			tbl[k] = v
			return v
		end
		return Classes.SheetCustomStatData[k] or Classes.SheetCustomStatBase[k]
	end
}

---@param character EsvCharacter|EclCharacter
---@return integer
function SheetCustomStatData:GetValue(character)
	return SheetManager:GetValueByEntry(self, character) or 0
end

---@param character EsvCharacter|EclCharacter
---@return integer|boolean Returns false if it's never been set.
function SheetCustomStatData:GetLastValue(character)
	local last = self.LastValue[character.Handle]
	return last or false
end

local STAT_VALUE_MAX = 2147483647

---[SERVER]
---@param character EsvCharacter|string|number
---@param value integer
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetCustomStatData:SetValue(character, value, skipListenerInvoke, skipSync)
	if value > STAT_VALUE_MAX then
		value = STAT_VALUE_MAX
	end
	return SheetManager:SetEntryValue(self, character, value, skipListenerInvoke, skipSync)
end

---[SERVER]
---Adds an amount to the value. Can be negative.
---@param character EsvCharacter|string|number
---@param amount integer
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetCustomStatData:ModifyValue(character, amount, skipListenerInvoke, skipSync)
	return self:SetValue(character, self:GetValue(character) + amount, skipListenerInvoke, skipSync)
end

---[SERVER]
---@param character EsvCharacter|string|number
---@param amount integer
function SheetCustomStatData:AddAvailablePoints(character, amount)
	assert(isClient == false, string.format("[SheetCustomStatData:AddAvailablePoints(%s, %s, %s)] [WARNING] - This function is server-side only!", self.ID, character, amount))
	return SheetManager:ModifyAvailablePointsForEntry(self, character, amount)
end

---Get the PointID for this stat.  
---@return string
function SheetCustomStatData:GetAvailablePointsID()
	if not StringHelpers.IsNullOrWhitespace(self.PointID) then
		return self.PointID
	else
		return self.ID
	end
end

---Get the amount of available points for this stat's PointID or ID for a specific character.
---@param character EsvCharacter|EclCharacter
---@return integer
function SheetCustomStatData:GetAvailablePoints(character)
	return SheetManager:GetAvailablePoints(character, SheetManager.StatType.Custom, self:GetAvailablePointsID())
end

---Sets the stat's last value for a character.
---@param character EsvCharacter|EclCharacter
function SheetCustomStatData:UpdateLastValue(character)
	local value = self:GetValue(character)
	if character and value then
		self.LastValue[character.Handle] = value
	end
end

Classes.SheetCustomStatData = SheetCustomStatData