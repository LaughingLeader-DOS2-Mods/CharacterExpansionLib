if CustomStatSystem == nil then
	---@class CustomStatSystem
	CustomStatSystem = {}
end

CustomStatSystem.__index = CustomStatSystem
CustomStatSystem.Loaded = false
CustomStatSystem.MISC_CATEGORY = 99999

SheetManager.CustomStats = CustomStatSystem

CustomStatSystem.Listeners = {
	---@type table<string, OnAvailablePointsChangedCallback[]>
	OnAvailablePointsChanged = {All = {}},
	---@type table<string, OnCustomStatValueChangedCallback[]>
	OnStatValueChanged = {All = {}},
	Loaded = {},
}

---@param callback fun(self:CustomStatSystem):void
function CustomStatSystem:RegisterLoadedListener(callback)
	if callback == nil then
		return
	end
	if type(callback) == "table" then
		for i=1,#callback do
			self:RegisterLoadedListener(callback[i])
		end
	else
		table.insert(self.Listeners.Loaded, callback)
	end
end

---@class CustomStatTooltipType
CustomStatSystem.TooltipType = {
	Default = "Stat",
	Ability = "Ability", -- Icon
	Stat = "Stat",
	Tag = "Tag", -- Icon
}

local self = CustomStatSystem

local isClient = Ext.IsClient()

---@type table<UUID|NETID, table<CUSTOMSTATID, integer>>
CustomStatSystem.PointsPool = {}
if not isClient then
	local PointsPoolHandler = {
		__index = function(tbl,k)
			return PersistentVars.CustomStatAvailablePoints[k]
		end,
		__newindex = function(tbl,k,v)
			PersistentVars.CustomStatAvailablePoints[k] = v
		end
	}
	setmetatable(CustomStatSystem.PointsPool, PointsPoolHandler)
end

---@alias MOD_UUID string
---@alias CUSTOMSTATID string

---@type table<MOD_UUID, table<CUSTOMSTATID, SheetCustomStatCategoryData>>
CustomStatSystem.Categories = {}
---@type table<MOD_UUID, table<CUSTOMSTATID, SheetCustomStatData>>
CustomStatSystem.Stats = {}
CustomStatSystem.UnregisteredStats = {}

Ext.Require("SheetManager/Core/Managers/CustomStats/PointChangeSyncing.lua")
---@type fun():table<string, table<string, SheetCustomStatData>>
local loader = Ext.Require("SheetManager/Core/Managers/CustomStats/ConfigLoader.lua")
Ext.Require("SheetManager/Core/Managers/CustomStats/Getters.lua")
Ext.Require("SheetManager/Core/Managers/CustomStats/DataSync.lua")
Ext.Require("SheetManager/Core/Managers/CustomStats/PointsHandler.lua")

---Returns true if actual custom stats can be used, which are currently disabled if not in GM mode.
---This is due to the fact that custom stats may be added to every NPC, which can be an issue in story mode.
function CustomStatSystem:GMStatsEnabled()
	return SharedData.GameMode == GAMEMODE.GAMEMASTER
end

local function LoadCustomStatsData()
	local categories,stats = loader()
	TableHelpers.AddOrUpdate(CustomStatSystem.Categories, categories)
	TableHelpers.AddOrUpdate(CustomStatSystem.Stats, stats)

	Ext.SaveFile(string.format("ConsoleDebug/CustomStats_%s_%s.lua", "Categories", isClient and "CLIENT" or "SERVER"), Lib.serpent.block(CustomStatSystem.Categories))
	Ext.SaveFile(string.format("ConsoleDebug/CustomStats_%s_%s.lua", "Stats", isClient and "CLIENT" or "SERVER"), Lib.serpent.block(CustomStatSystem.Stats))

	if not isClient then
		local foundStats = {}
		if CustomStatSystem:GMStatsEnabled() then
			for uuid,stats in pairs(CustomStatSystem.Stats) do
				local modName = Ext.GetModInfo(uuid).Name
				for id,stat in pairs(stats) do
					if stat.DisplayName then
						local existingData = Ext.GetCustomStatByName(stat.DisplayName)
						if not existingData then
							if stat.Create then
								Ext.CreateCustomStat(stat.DisplayName, stat.Description)
								fprint(LOGLEVEL.DEFAULT, "[CharacterExpansionLib:LoadCustomStatsData] Created a new custom stat for mod [%s]. ID(%s) DisplayName(%s) Description(%s)", modName, id, stat.DisplayName, stat.Description)
								existingData = Ext.GetCustomStatByName(stat.DisplayName)
							end
						end
						if existingData then
							stat.UUID = existingData.Id
							for player in GameHelpers.Character.GetPlayers() do
								stat:UpdateLastValue(player)
							end
							foundStats[stat.UUID] = true
						end
					end
				end
			end

			CustomStatSystem.UnregisteredStats = {}
	
			for _,uuid in pairs(Ext.GetAllCustomStats()) do
				if not foundStats[uuid] then
					local stat = Ext.GetCustomStatById(uuid)
					if stat then
						local data = {
							UUID = uuid,
							ID = uuid,
							DisplayName = stat.Name,
							Description = stat.Description,
							LastValue = {}
						}
						setmetatable(data, Classes.UnregisteredCustomStatData)
						CustomStatSystem.UnregisteredStats[uuid] = data
						foundStats[uuid] = true
	
						for player in GameHelpers.Character.GetPlayers() do
							data:UpdateLastValue(player)
						end
					end
				end
			end
		end
	else
		local categoryId = 0
		for category in CustomStatSystem:GetAllCategories() do
			if categoryId == CustomStatSystem.MISC_CATEGORY then
				categoryId = categoryId + 1
			end
			category.GroupId = categoryId
			categoryId = categoryId + 1
		end
		CustomStatSystem.TooltipValueEnabled = {}
		for stat in CustomStatSystem:GetAllStats() do
			if stat.DisplayValueInTooltip then
				CustomStatSystem.TooltipValueEnabled[stat.ID] = true
			end
		end
	end
	CustomStatSystem.Loaded = true

	InvokeListenerCallbacks(CustomStatSystem.Listeners.Loaded, CustomStatSystem)
end

if not isClient then
	RegisterListener("Initialized", LoadCustomStatsData)
else
	Ext.RegisterListener("SessionLoaded", LoadCustomStatsData)
end
--RegisterListener("LuaReset", LoadCustomStatsData)

---@private
---@param character EsvCharacter|EclCharacter
---@return boolean
function CustomStatSystem:IsTooltipWorking(character)
	if isClient then
		local characterData = Client:GetCharacterData()
		if characterData then
			if characterData.IsGameMaster then
				return not characterData.IsPossessed
			else
				return false
			end
		end
	else
		character = character or Ext.GetCharacter(CharacterGetHostCharacter())
		if character then
			if character.IsGameMaster then
				return not character.IsPossessed
			else
				return false
			end
		end
	end
	return true
end

---@private
---@param double number
---@return UUID
function CustomStatSystem:RemoveStatByDouble(double)
	local removedId = nil
	for mod,stats in pairs(CustomStatSystem.Stats) do
		for id,stat in pairs(stats) do
			if stat.Double == double then
				removedId = stat.UUID
				stats[id] = nil
			end
		end
	end
	for uuid,stat in pairs(CustomStatSystem.UnregisteredStats) do
		if stat.Double == double then
			removedId = uuid
			CustomStatSystem.UnregisteredStats[uuid] = nil
		end
	end
	return removedId
end

if not isClient then
	local canFix = Ext.GetCustomStatByName ~= nil
	RegisterNetListener("CEL_CheckCustomStatCallback", function(cmd, payload)
		if not payload then
			return
		end
		local data = Common.JsonParse(payload)
		if data then
			local statDouble = data.Stat
			local character = Ext.GetCharacter(data.Character)
			if character and not CustomStatSystem.IsTooltipWorking(character) then
				if canFix then
					local stat = Ext.GetCustomStatByName(data.StatId)
					if stat then
						data.DisplayName = stat.Name
						data.ID = stat.Id
						data.Description = stat.Description
					else
						data.DisplayName = data.StatId
						data.Description = ""
					end
				end
				Ext.PostMessageToUser(character.ReservedUserID, "CEL_CreateCustomStatTooltip", Ext.JsonStringify(data))
			end
		end
	end)
	RegisterNetListener("CEL_RequestCustomStatData", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local uuid = data.UUID
			local character = Ext.GetCharacter(data.Character)
			local statValue = character:GetCustomStat(uuid)
			--TODO Need some way to get a custom stat's name and tooltip from the UUID.
		end
	end)
end