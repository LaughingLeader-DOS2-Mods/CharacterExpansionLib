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
	GroupID = 0,
	---For new categories, this is the mod Guid to use when retrieving it.
	GroupMod = "",
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
	GROUPMOD = {Name="GroupMod", Type = "string"},
	GROUPID = {Name="GroupID", Type = "enum", Parse = function(val,t)
		if t == "string" then
			local id = string.lower(val)
			for k,v in pairs(SheetManager.Abilities.Data.GroupID) do
				if string.lower(k) == id then
					return v
				end
			end
			return id -- Custom categories?
		elseif t == "number" then
			local id = SheetManager.Abilities.Data.GroupID[val]
			if id then
				return val
			end
		end
		--fprint(LOGLEVEL.WARNING, "[SheetManager:ConfigLoader] Property value type [%s](%s) is incorrect for property Ability GroupID. Using default.", t, val)
		return SheetManager.Abilities.Data.GroupID.Skills
	end},
}

TableHelpers.AddOrUpdate(SheetAbilityData.PropertyMap, Classes.SheetBaseData.PropertyMap, true)

local defaults = {
	GroupID = 0,
	IsCivil = false,
	Icon = "",
	IconWidth = SheetAbilityData.IconWidth,
	IconHeight = SheetAbilityData.IconHeight,
}

---@protected
function SheetAbilityData.SetDefaults(data)
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
function SheetAbilityData:GetValue(character)
	if StringHelpers.IsNullOrWhitespace(self.ID) then
		return 0
	end
	if not StringHelpers.IsNullOrWhitespace(self.BoostAttribute) then
		return self:GetBoostValue(character, 0)
	else
		if not _ISCLIENT then
			return SheetManager:GetValueByEntry(self, GameHelpers.GetUUID(character)) or 0
		else
			return SheetManager:GetValueByEntry(self, GameHelpers.GetNetID(character)) or 0
		end
	end
end

---[SERVER]
---@param character CharacterParam
---@param value integer
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetAbilityData:SetValue(character, value, skipListenerInvoke, skipSync)
	return SheetManager:SetEntryValue(self, character, value, skipListenerInvoke, skipSync)
end

---@param character CharacterParam
---@param amount integer
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetAbilityData:ModifyValue(character, amount, skipListenerInvoke, skipSync)
	return self:SetValue(character, self:GetValue(character) + amount, skipListenerInvoke, skipSync)
end