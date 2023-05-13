local _ISCLIENT = Ext.IsClient()

---@class SheetAbilityData:SheetBaseData
---@field MaxValue integer|nil Overrides the default max value (`Ext.ExtraData.CombatAbilityCap` or `Ext.ExtraData.CivilAbilityCap`).
local SheetAbilityData = {
	Type = "SheetAbilityData",
	TooltipType = "Ability",
	StatType = "Ability",
	Icon = "",
	IconWidth = 128,
	IconHeight = 128,
	CategoryID = 0,
	---Used for new ability categories
	CustomCategory = "",
	---For new categories, this is the mod Guid to use when retrieving it.
	CategoryMod = "",
	IsCivil = false,
}

Classes.SheetAbilityData = SheetAbilityData

SheetAbilityData.__index = function(t,k)
	local v = Classes.SheetAbilityData[k] or Classes.SheetBaseData[k]
	if v then
		t[k] = v
	end
	return v
end

SheetAbilityData.PropertyMap = {
	MAXVALUE = {Name="MaxValue", Type = "integer"},
	ISCIVIL = {Name="IsCivil", Type = "boolean"},
	CATEGORYMOD = {Name="CategoryMod", Type = "string"},
	CUSTOMCATEGORY = {Name="CustomCategory", Type = "string"},
	CATEGORYID = {Name="CategoryID", Type = "enum", Parse = function(val,t)
		if t == "string" then
			local id = string.lower(val)
			for k,v in pairs(SheetManager.Abilities.Data.CategoryID) do
				if string.lower(k) == id then
					return v
				end
			end
		elseif t == "number" then
			local id = SheetManager.Abilities.Data.CategoryID[val]
			if id then
				return val
			end
		end
		return SheetManager.Abilities.Data.CategoryID.Skills
	end},
}
---For compatibility.
---@deprecated
SheetAbilityData.PropertyMap.GROUPID = SheetAbilityData.PropertyMap.CATEGORYID

TableHelpers.AddOrUpdate(SheetAbilityData.PropertyMap, Classes.SheetBaseData.PropertyMap, true)

local defaults = {
	CategoryID = 0,
	IsCivil = false,
	Icon = "",
	IconWidth = SheetAbilityData.IconWidth,
	IconHeight = SheetAbilityData.IconHeight,
}

---@protected
function SheetAbilityData.SetDefaults(data)
	if not data.CategoryMod and type(data.CustomCategory) == "string" then
		data.CategoryMod = data.Mod
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

---@param character EsvCharacter|EclCharacter
---@return integer
function SheetAbilityData:GetValue(character)
	return SheetManager:GetValueByEntry(self, character) or 0
end

---[SERVER]
---@param character EsvCharacter|EclCharacter
---@param value integer
---@param opts? SheetManagerSetEntryValueOptions
function SheetAbilityData:SetValue(character, value, opts)
	return SheetManager:SetEntryValue(self, character, value, opts)
end

---@param character EsvCharacter|EclCharacter
---@param amount integer
---@param opts? SheetManagerSetEntryValueOptions
function SheetAbilityData:ModifyValue(character, amount, opts)
	return self:SetValue(character, self:GetValue(character) + amount, opts)
end