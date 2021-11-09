local self = CustomStatSystem
local isClient = Ext.IsClient() 

--Deprecated functions that ultimately lead to SheetManager usage.

---@param character EsvCharacter|UUID|EclCharacter|NETID
---@param stat SheetCustomStatData
---@param amount integer The amount to modify the stat by.
function CustomStatSystem:ModifyStat(character, stat, amount, ...)
	if type(stat) == "string" then
		local mod = table.unpack({...}) or ""
		stat = self:GetStatByID(stat, mod)
	end
	local current = self:GetStatValueForCharacter(character, stat)
	return self:SetStat(character, stat, current + amount)
end

---@param character EsvCharacter|UUID|EclCharacter|NETID
---@param stat SheetCustomStatData
---@param value integer The value to set the stat to.
function CustomStatSystem:SetStat(character, stat, value, ...)
	if type(stat) == "string" then
		local mod = table.unpack({...}) or ""
		stat = self:GetStatByID(stat, mod)
	end
	fassert(stat ~= nil, "Stat parameter (%s) is nil!", stat)
	SheetManager:SetEntryValue(stat, character, value)
end

---@param character EsvCharacter|UUID|NETID
---@param statId string A stat id.
---@param value integer The value to set the stat to.
---@param mod string|nil A mod UUID to use when fetching the stat by ID.
function CustomStatSystem:SetStatByID(character, statId, value, mod)
	local stat = self:GetStatByID(statId, mod)
	fassert(stat ~= nil, "Failed to get CustomStat with id (%s)", statId)
	SheetManager:SetEntryValue(stat, character, value)
end
