local _ISCLIENT = Ext.IsClient()

---@class SheetStatData:SheetBaseData
local SheetStatData = {
	Type = "SheetStatData",
	TooltipType = "Stat",
	---@type StatSheetStatType
	StatType = "SecondaryStat",
	---@type StatSheetSecondaryStatType
	SecondaryStatType = "Info",
	---For if the StatType is "Spacing".
	SpacingHeight = 0,
	Frame = 0,
	SheetIcon = "",
	SheetIconWidth = 28,
	SheetIconHeight = 28,
}

SheetStatData.__index = function(t,k)
	if k == "BaseValue" and t.StatType == "PrimaryStat" then
		return Ext.ExtraData.AttributeBaseValue
	end
	local v = Classes.SheetStatData[k] or Classes.SheetBaseData[k]
	if v then
		t[k] = v
	end
	return v
end

SheetStatData.PropertyMap = {
	STATTYPE = {Name="StatType", Type = "enum", Parse = function(val,t)
		if t == "string" then
			local id = string.lower(val)
			for k,v in pairs(SheetManager.Stats.Data.StatType) do
				if string.lower(k) == id then
					return k
				end
			end
		else
			--fprint(LOGLEVEL.WARNING, "[SheetManager:ConfigLoader] Property value type [%s](%s) is incorrect for property StatType.", t, val)
		end
		return SheetManager.Stats.Data.StatType.Secondary
	end},
	SECONDARYSTATTYPE = {Name="SecondaryStatType", Type = "enum", Parse = function(val,t) 
		if t == "string" then
			local id = string.lower(val)
			for k,v in pairs(SheetManager.Stats.Data.SecondaryStatType) do
				if string.lower(k) == id then
					return k
				end
			end
		elseif t == "number" then
			local id = SheetManager.Stats.Data.SecondaryStatTypeInteger[val]
			if id then
				return id
			end
		end
		--fprint(LOGLEVEL.WARNING, "[SheetManager:ConfigLoader] Property value type [%s](%s) is incorrect for property Stat StatType. Using default.", t, val)
		return SheetManager.Stats.Data.SecondaryStatType.Info
	end},
	SHEETICON = {Name="SheetIcon", Type = "string"},
	SHEETICONWIDTH = {Name="SheetIconWidth", Type = "number"},
	SHEETICONHEIGHT = {Name="SheetIconHeight", Type = "number"},
	SPACINGHEIGHT = {Name="SpacingHeight", Type = "number"},
	FRAME = {Name="Frame", Type = "integer"},
}

TableHelpers.AddOrUpdate(SheetStatData.PropertyMap, Classes.SheetBaseData.PropertyMap, true)

local defaults = {
	StatType = "Secondary",
	SecondaryStatType = "Info",
	SpacingHeight = 0,
	SheetIcon = "",
	SheetIconWidth = 28,
	SheetIconHeight = 28,
}

---@protected
function SheetStatData.SetDefaults(data)
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
---@return integer
function SheetStatData:GetValue(character)
	return SheetManager:GetValueByEntry(self, GameHelpers.GetObjectID(character)) or 0
end

---@param character CharacterParam
---@param value integer
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetStatData:SetValue(character, value, skipListenerInvoke, skipSync)
	return SheetManager:SetEntryValue(self, character, value, skipListenerInvoke, skipSync)
end

---@param character CharacterParam
---@param amount integer
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetStatData:ModifyValue(character, amount, skipListenerInvoke, skipSync)
	return self:SetValue(character, self:GetValue(character) + amount, skipListenerInvoke, skipSync)
end

Classes.SheetStatData = SheetStatData