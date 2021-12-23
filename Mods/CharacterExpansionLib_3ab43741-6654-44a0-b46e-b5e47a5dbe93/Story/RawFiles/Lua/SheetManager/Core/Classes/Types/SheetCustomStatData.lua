local isClient = Ext.IsClient()

---@class STAT_DISPLAY_MODE
local STAT_DISPLAY_MODE = {
	Default = "Integer",
	Percentage = "Percentage"
}

---@class SheetCustomStatData:SheetCustomStatBase
local SheetCustomStatData = {
	Type="SheetCustomStatData",
	StatType = "Custom",
	---If true, the custom stat is created automatically on the server, if GM custom stats are enabled.
	Create = false,
	---A category ID this stat belongs to, if any.
	Category = "",
	---An ID to use for a common pool of available points.
	PointID = "",
	---@private
	---@type table<NETID,table<string,integer>>
	LastValue = {},
	---Alternative display modes for a stat, such as percentage display.
	DisplayMode = STAT_DISPLAY_MODE.Default,
	DisplayValueInTooltip = false,
	---Enum values for DisplayMode.
	STAT_DISPLAY_MODE = STAT_DISPLAY_MODE,
	---If set, the add button logic will check the current amount against this value when determining if the stat can be added to.
	---@type integer
	MaxAmount = nil,
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

SheetCustomStatData.PropertyMap = {
	CREATE = {Name="Create", Type = "boolean"},
	CATEGORY = {Name="Category", Type = "string"},
	POINTID = {Name="PointID", Type = "string"},
	DISPLAYMODE = {Name="DisplayMode", Type = "string"},
	DISPLAYVALUEINTOOLTIP = {Name="DisplayValueInTooltip", Type = "boolean"},
	VISIBLE = {Name="Visible", Type = "boolean"},
	--Defaults to true. AvailablePoints are added to when a stat is reduced in the UI.
	AUTOADDAVAILABLEPOINTSONREMOVE = {Name="AutoAddAvailablePointsOnRemove", Type = "boolean"},
	MAXAMOUNT = {Name="MaxAmount", Type = "number"},
}

TableHelpers.AddOrUpdate(SheetCustomStatData.PropertyMap, Classes.SheetCustomStatBase.PropertyMap)

local defaults = {
	Create = SheetCustomStatData.Create,
	Category = SheetCustomStatData.Category,
	GeneratedID = SheetCustomStatData.GeneratedID,
	PointID = SheetCustomStatData.PointID,
	LastValue = {},
	DisplayMode = SheetCustomStatData.DisplayMode,
	MaxAmount = SheetCustomStatData.MaxAmount,
	Suffix = SheetCustomStatData.Suffix,
	AutoAddAvailablePointsOnRemove = SheetCustomStatData.AutoAddAvailablePointsOnRemove,
}

local ID_MAP = 0

---@protected
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
	if not CustomStatSystem:GMStatsEnabled() then
		data.GeneratedID = ID_MAP
		ID_MAP = ID_MAP + 1
	end
end

local canUseRawFunctions = Ext.Version() >= 55

Classes.UnregisteredCustomStatData = {
	Type = "UnregisteredCustomStatData",
	IsUnregistered = true,
	LastValue = {},
	__index = function(tbl,k)
		if k == "Type" then
			return "UnregisteredCustomStatData"
		end
		if canUseRawFunctions then
			local v = rawget(Classes.UnregisteredCustomStatData, k)
			if v then
				tbl[k] = v
				return v
			end
		end
		return Classes.SheetCustomStatData[k] or Classes.SheetCustomStatBase[k]
	end
}

---@param character UUID|NETID|EsvCharacter|EclCharacter
---@return integer
function SheetCustomStatData:GetValue(character)
	if type(character) == "userdata" then
		return CustomStatSystem:GetStatValueForCharacter(character, self) or 0
	else
		character = Ext.GetCharacter(character)
		if character then
			return CustomStatSystem:GetStatValueForCharacter(character, self) or 0
		end
	end
	return 0
end

---@param character UUID|NETID|EsvCharacter|EclCharacter
---@return integer|boolean Returns false if it's never been set.
function SheetCustomStatData:GetLastValue(character)
	local characterId = character
	if not isClient then
		characterId = GameHelpers.GetUUID(character)
	else
		characterId = GameHelpers.GetNetID(character)
	end
	return self.LastValue[characterId] or false
end

local STAT_VALUE_MAX = 2147483647

---[SERVER]
---@param character EsvCharacter|string|number
---@param value integer
function SheetCustomStatData:SetValue(character, value)
	if value > STAT_VALUE_MAX then
		value = STAT_VALUE_MAX
	end
	return CustomStatSystem:SetStat(character, self, value)
end

---[SERVER]
---Adds an amount to the value. Can be negative.
---@param character EsvCharacter|string|number
---@param amount integer
function SheetCustomStatData:ModifyValue(character, amount)
	return self:SetValue(character, self:GetValue(character) + amount)
end

---[SERVER]
---@param character EsvCharacter|string|number
---@param amount integer
function SheetCustomStatData:AddAvailablePoints(character, amount)
	assert(isClient == false, string.format("[SheetCustomStatData:AddAvailablePoints(%s, %s, %s)] [WARNING] - This function is server-side only!", self.ID, character, amount))
	return SheetManager.CustomStats:AddAvailablePoints(character, self, amount)
end

---Get the amount of available points for this stat's PointID or ID for a specific character.
---@param character EsvCharacter|EclCharacter|UUID|NETID
---@return integer
function SheetCustomStatData:GetAvailablePoints(character)
	if not StringHelpers.IsNullOrWhitespace(self.PointID) then
		return SheetManager:GetAvailablePoints(character, SheetManager.StatType.Custom, self.PointID)
	else
		return SheetManager:GetAvailablePoints(character, SheetManager.StatType.Custom, self.ID)
	end
end

---@protected
---Sets the stat's last value for a character.
---@param character EsvCharacter|EclCharacter|UUID|NETID
function SheetCustomStatData:UpdateLastValue(character)
	local characterId = GameHelpers.GetCharacterID(character)
	local value = self:GetValue(characterId)
	if value then
		if Vars.DebugMode and Vars.Print.CustomStats then
			--fprint(LOGLEVEL.WARNING, "[SheetCustomStatData:UpdateLastValue:%s] Set LastValue for (%s) to (%s) [%s]", self.Type, characterId, value, Ext.IsServer() and "SERVER" or "CLIENT")
		end
		self.LastValue[characterId] = value
	end
end

Classes.SheetCustomStatData = SheetCustomStatData