local _ISCLIENT = Ext.IsClient()

local _INTERNAL = {}

---@class SheetManagerCustomStats
local CustomStats = {
	Loaded = false,
	MISC_CATEGORY = 99999,
	TooltipType = {
		Default = "Stat",
		Ability = "Ability", -- Icon
		Stat = "Stat",
		Tag = "Tag", -- Icon
	},
	UnregisteredStats = {},
	_Internal = _INTERNAL
}

SheetManager.CustomStats = CustomStats

local self = SheetManager.CustomStats

---@type table<Guid|NETID, table<string, integer>>
CustomStats.PointsPool = {}
if not _ISCLIENT then
	local PointsPoolHandler = {
		__index = function(tbl,k)
			return PersistentVars.CustomStatAvailablePoints[k]
		end,
		__newindex = function(tbl,k,v)
			PersistentVars.CustomStatAvailablePoints[k] = v
		end
	}
	setmetatable(CustomStats.PointsPool, PointsPoolHandler)
end

---Returns true if actual custom stats can be used, which are currently disabled if not in GM mode.
---This is due to the fact that custom stats may be added to every NPC, which can be an issue in story mode.
function CustomStats:GMStatsEnabled()
	return SharedData.GameMode == GAMEMODE.GAMEMASTER
end

---@param a SheetCustomStatCategoryData
---@param b SheetCustomStatCategoryData
local function _SortCategories(a,b)
	local name1 = a:GetDisplayName()
	local name2 = b:GetDisplayName()
	local sortVal1 = a.Index
	local sortVal2 = b.Index
	local trySortByValue = false
	if a.SortName then
		name1 = a.SortName
	end
	if a.SortValue then
		sortVal1 = a.SortValue
		trySortByValue = true
	end
	if b.SortName then
		name2 = b.SortName
	end
	if b.SortValue then
		sortVal2 = b.SortValue
		trySortByValue = true
	end
	if trySortByValue and sortVal1 ~= sortVal2 then
		return sortVal1 < sortVal2
	end
	return name1 < name2
end

_INTERNAL.SortCategories = _SortCategories

---Get an iterator of sorted categories.
---@param skipSort boolean|nil
---@return fun():SheetCustomStatCategoryData
function CustomStats:GetAllCategories(skipSort)
	local allCategories = {}

	local index = 0
	--To avoid duplicate categories by the same id, we set a dictionary first
	for uuid,categories in pairs(SheetManager.Data.CustomStatCategories) do
		for id,category in pairs(categories) do
			category.Index = index
			index = index + 1
			allCategories[id] = category
		end
	end

	---@type SheetCustomStatCategoryData[]
	local categories = {}
	for id,v in pairs(allCategories) do
		categories[#categories+1] = v
	end
	if skipSort ~= true then
		table.sort(categories, _SortCategories)
	end

	local i = 0
	local count = #categories
	return function ()
		i = i + 1
		if i <= count then
			return categories[i]
		end
	end
end

---Gets the Group ID for a stat that will be used in the characterSheet.
---@param id string The category ID.
---@param mod string Optional mod UUID.
---@return integer
function CustomStats:GetCategoryGroupId(id, mod)
	if not id then
		return self.MISC_CATEGORY
	end
	if mod then
		local categories = SheetManager.Data.CustomStatCategories[mod]
		if categories and categories[id] then
			return categories[id].GroupId or self.MISC_CATEGORY
		end
	end
	for uuid,categories in pairs(SheetManager.Data.CustomStatCategories) do
		if categories[id] then
			return categories[id].GroupId or self.MISC_CATEGORY
		end
	end
	return self.MISC_CATEGORY
end

---@return boolean
function CustomStats:HasCategories()
	for uuid,categories in pairs(SheetManager.Data.CustomStatCategories) do
		for id,category in pairs(categories) do
			return true
		end
	end
	return false
end

---@param groupId integer
---@return SheetCustomStatCategoryData|nil
function CustomStats:GetCategoryByGroupId(groupId)
	for uuid,categories in pairs(SheetManager.Data.CustomStatCategories) do
		for id,category in pairs(categories) do
			if category.GroupId == groupId then
				return category
			end
		end
	end
	return nil
end

---Gets the total number of registered stats for a category.
---@param categoryId string
---@param visibleOnly boolean|nil
---@return integer
function CustomStats:GetTotalStatsInCategory(categoryId, visibleOnly)
	local total = 0
	if StringHelpers.IsNullOrWhitespace(categoryId) then
		categoryId = "MISC"
	end
	local character = _ISCLIENT and Client:GetCharacter() or GameHelpers.GetCharacter(CharacterGetHostCharacter())
	for mod,stats in pairs(SheetManager.Data.CustomStats) do
		for id,stat in pairs(stats) do
			local isRegistered = not SheetManager.CustomStats:GMStatsEnabled() or not StringHelpers.IsNullOrWhitespace(stat.UUID)
			local visible = isRegistered
			if visibleOnly and visible then
				visible = SheetManager:IsEntryVisible(stat, character) == true
			end
			if visible and stat.Category == categoryId then
				Ext.Utils.PrintError(categoryId, stat.ID, total)
				total = total + 1
			end
		end
	end
	if categoryId == "MISC" then
		for uuid,stat in pairs(self.UnregisteredStats) do
			total = total + 1
		end
	end
	return total
end

function _INTERNAL.Initialize()
	CustomStats.Loaded = false
	if not _ISCLIENT then
		CustomStats.UnregisteredStats = {}

		local foundStats = {}
		if CustomStats:GMStatsEnabled() then
			for _,stats in pairs(SheetManager.Data.CustomStats) do
				for _,stat in pairs(stats) do
					if stat.DisplayName then
						local existingData = Ext.CustomStat.GetByName(stat.DisplayName)
						if not existingData then
							if stat.Create then
								Ext.CustomStat.Create(stat.DisplayName, stat.Description)
								--fprint(LOGLEVEL.DEFAULT, "[CharacterExpansionLib:LoadCustomStatsData] Created a new custom stat for mod [%s]. ID(%s) DisplayName(%s) Description(%s)", modName, id, stat.DisplayName, stat.Description)
								existingData = Ext.CustomStat.GetByName(stat.DisplayName)
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
	
			for _,uuid in pairs(Ext.CustomStat.GetAll()) do
				if not foundStats[uuid] then
					local stat = Ext.CustomStat.GetById(uuid)
					if stat then
						local data = {
							UUID = uuid,
							ID = uuid,
							DisplayName = stat.Name,
							Description = stat.Description,
							LastValue = {}
						}
						setmetatable(data, Classes.UnregisteredCustomStatData)
						CustomStats.UnregisteredStats[uuid] = data
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
		for category in CustomStats:GetAllCategories() do
			if categoryId == CustomStats.MISC_CATEGORY then
				categoryId = categoryId + 1
			end
			category.GroupId = categoryId
			categoryId = categoryId + 1
		end
	end
	CustomStats.Loaded = true
end

---@param displayName string
---@return SheetCustomStatData|nil
function CustomStats:GetStatByName(displayName)
	for uuid,stats in pairs(SheetManager.Data.CustomStats) do
		for id,stat in pairs(stats) do
			if stat.DisplayName == displayName or stat:GetDisplayName() == displayName then
				return stat
			end
		end
	end
	for uuid,stat in pairs(self.UnregisteredStats) do
		if stat.DisplayName == displayName then
			return stat
		end
	end
	return nil
end

if _ISCLIENT then
	---@param double number
	---@return Guid
	function _INTERNAL.RemoveStatByDouble(double)
		local removedId = nil
		for mod,stats in pairs(SheetManager.Data.CustomStats) do
			for id,stat in pairs(stats) do
				if stat.Double == double then
					removedId = stat.UUID
					stats[id] = nil
				end
			end
		end
		for uuid,stat in pairs(CustomStats.UnregisteredStats) do
			if stat.Double == double then
				removedId = uuid
				CustomStats.UnregisteredStats[uuid] = nil
			end
		end
		return removedId
	end

	---@param a CharacterSheetStatArrayData
	---@param b CharacterSheetStatArrayData
	function _SortStats(a,b)
		local name1 = a.DisplayName
		local name2 = b.DisplayName
		local sortVal1 = a.Index
		local sortVal2 = b.Index
		local trySortByValue = false
		if a.Stat then
			if a.Stat.SortName and type(a.Stat.SortName) == "string" then
				name1 = a.Stat.SortName
			end
			if a.Stat.SortValue then
				sortVal1 = a.Stat.SortValue
				trySortByValue = true
			end
		end
		if b.Stat then
			if b.Stat.SortName and type(b.Stat.SortName) == "string" then
				name2 = b.Stat.SortName
			end
			if b.Stat.SortValue then
				sortVal2 = b.Stat.SortValue
				trySortByValue = true
			end
		end
		if trySortByValue and sortVal1 ~= sortVal2 then
			return sortVal1 < sortVal2
		end
		return tostring(name1) < tostring(name2)
	end

	_INTERNAL.SortStats = _SortStats

	---@param double number
	---@return SheetCustomStatData|nil
	function CustomStats:GetStatByDouble(double)
		for mod,stats in pairs(SheetManager.Data.CustomStats) do
			for id,stat in pairs(stats) do
				if stat.Double == double then
					return stat
				end
			end
		end
		for uuid,stat in pairs(CustomStats.UnregisteredStats) do
			if stat.Double == double then
				return stat
			end
		end
		return nil
	end

	---Get an iterator of all stats.
	---@param inSheetOnly boolean|nil Only get stats in the character sheet,
	---@param sortStats boolean|nil
	---@param includeUnregisteredStats boolean|nil
	---@return fun():SheetCustomStatData
	function CustomStats.GetAllStats(inSheetOnly, sortStats, includeUnregisteredStats)
		local allStats = {}

		local findAll = true

		if inSheetOnly == true and not Vars.ControllerEnabled then
			local ui = Ext.UI.GetByType(Data.UIType.characterSheet)
			if ui then
				local this = ui:GetRoot()
				if not this then
					return function() end
				end
				findAll = false
				local arr = this.stats_mc.customStats_mc.stats_array
				for i=0,#arr-1 do
					local stat_mc = arr[i]
					if stat_mc and stat_mc.statID then
						local stat = self:GetStatByDouble(stat_mc.statID)
						if stat then
							allStats[#allStats+1] = stat
						end
					end
				end
			end
		end

		if findAll then
			for uuid,stats in pairs(SheetManager.Data.CustomStats) do
				for id,stat in pairs(stats) do
					allStats[#allStats+1] = stat
				end
			end
			if includeUnregisteredStats then
				for uuid,stat in pairs(self.UnregisteredStats) do
					allStats[#allStats+1] = stat
				end
			end
		end

		if sortStats == true then
			table.sort(allStats, _SortStats)
		end

		local i = 0
		local count = #allStats
		return function ()
			i = i + 1
			if i <= count then
				return allStats[i]
			end
		end
	end
end

---@param character CharacterParam
---@return integer
function CustomStats:GetTotalAvailablePoints(character)
	character = character or SheetManager.UI.CharacterSheet.GetCharacter()
	local characterId = GameHelpers.GetNetID(character)
	if characterId then
		local points = 0
		if self.PointsPool[characterId] then
			for id,amount in pairs(self.PointsPool[characterId]) do
				points = points + amount
			end
		end
		return points
	end
	return 0
end

---@param double number
---@return Guid
function _INTERNAL.RemoveStatByDouble(double)
	local removedId = nil
	for mod,stats in pairs(SheetManager.Data.CustomStats) do
		for id,stat in pairs(stats) do
			if stat.Double == double then
				removedId = stat.UUID
				stats[id] = nil
			end
		end
	end
	for uuid,stat in pairs(CustomStats.UnregisteredStats) do
		if stat.Double == double then
			removedId = uuid
			CustomStats.UnregisteredStats[uuid] = nil
		end
	end
	return removedId
end

if not _ISCLIENT then
	RegisterNetListener("CEL_CustomStats_RemoveStatByUUID", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			if StringHelpers.IsNullOrEmpty(data.UUID) then
				return
			end
			for mod,stats in pairs(SheetManager.Data.CustomStats) do
				for id,stat in pairs(stats) do
					if stat.UUID == data.UUID then
						stats[id] = nil
					end
				end
			end
			CustomStats.UnregisteredStats[data.UUID] = nil
		end
	end)
end