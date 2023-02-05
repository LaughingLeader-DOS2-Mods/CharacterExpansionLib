local function OnPointsAdded(statType, ui, event, generatedId, ...)
	local character = Client:GetCharacter()
	local stat = SheetManager:GetEntryByGeneratedID(generatedId, statType)
	if stat then
		if statType ~= "Talent" then
			stat:ModifyValue(character, 1)
		else
			stat:SetValue(character, true)
		end
	end
end

local function OnPointsRemove(statType, ui, event, generatedId, ...)
	local character = Client:GetCharacter()
	local stat = SheetManager:GetEntryByGeneratedID(generatedId, statType)
	if stat then
		if statType ~= "Talent" then
			stat:ModifyValue(character, -1)
		else
			stat:SetValue(character, false)
		end
	end
end

for t,v in pairs(SheetManager.Config.Calls.PointAdded) do
	local func = function(...)
		OnPointsAdded(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.characterSheet, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
end
for t,v in pairs(SheetManager.Config.Calls.PointRemoved) do
	local func = function(...)
		OnPointsRemove(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.characterSheet, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
end

---@return string|nil statID
---@return string statType
local function GetBaseStatID(id, statType)
	if statType == "PrimaryStat" then
		return SheetManager.Stats.Data.Builtin.ID[id],"Attribute"
	elseif statType == "SecondaryStat" or statType == "Stat" then
		return SheetManager.Stats.Data.Builtin.ID[id],"Stat"
	elseif statType == "Ability" then
		return Ext.Stats.EnumIndexToLabel("AbilityType", id),"Ability"
	elseif statType == "Talent" then
		return Ext.Stats.EnumIndexToLabel("TalentType", id),"Talent"
	end
	return nil,"None"
end

--region Fix for base stats not being adjustable when the sheet is in GM mode in campaign mode

local function RequestBaseValueChange(statType, id, modifyBy, skipPointsCheck)
	local character = Client:GetCharacter()
	if not GameHelpers.Client.IsGameMaster() and SharedData.GameMode == GAMEMODE.CAMPAIGN then
		local stat,entryType = GetBaseStatID(id, statType)
		if stat then
			if character then
				local points = 0
				if not skipPointsCheck then
					points = SheetManager:GetAvailablePoints(character, entryType)
				end
				if skipPointsCheck or points == 0 then
					if entryType == "Talent" then
						modifyBy = modifyBy > 0
					end
					local netid = GameHelpers.GetNetID(character)
					GameHelpers.Net.PostMessageToServer("CEL_SheetManager_RequestBaseValueChange", {
						ID = stat,
						NetID = netid,
						ModifyBy = modifyBy,
						StatType = entryType
					})
					SheetManager.Sync.AvailablePointsWithDelay(character)
				end
			end
		end
	end
end

local function OnBasePointsAdded(statType, ui, event, id)
	RequestBaseValueChange(statType, id, 1)
end

local function OnBasePointsRemove(statType, ui, event, id)
	RequestBaseValueChange(statType, id, -1, true)
end

for t,v in pairs(SheetManager.Config.BaseCalls.PointAdded) do
	local func = function(...)
		OnBasePointsAdded(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.characterSheet, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, v, func, "Before")
end
for t,v in pairs(SheetManager.Config.BaseCalls.PointRemoved) do
	local func = function(...)
		OnBasePointsRemove(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.characterSheet, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, v, func, "Before")
end

--[[ for t,v in pairs(SheetManager.Config.BaseCreationCalls.PointAdded) do
	local func = function(...)
		Ext.Utils.PrintError(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
end
for t,v in pairs(SheetManager.Config.BaseCreationCalls.PointRemoved) do
	local func = function(...)
		Ext.Utils.PrintError(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
end ]]


-- for t,v in pairs(SheetManager.Config.BaseCreationCalls.PointAdded) do
-- 	local func = function(...)
-- 		OnBasePointsAdded(t, ...)
-- 	end
-- 	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
-- 	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
-- end
-- for t,v in pairs(SheetManager.Config.BaseCreationCalls.PointRemoved) do
-- 	local func = function(...)
-- 		OnBasePointsRemove(t, ...)
-- 	end
-- 	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
-- 	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
-- end

--endregion