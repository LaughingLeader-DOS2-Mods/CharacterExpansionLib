if SheetManager.UI == nil then SheetManager.UI = {} end

---@class CharacterSheetWrapper:LeaderLibUIWrapper
local CharacterSheet = Classes.UIWrapper:CreateFromType(Data.UIType.characterSheet, {ControllerID = Data.UIType.statsPanel_c, IsControllerSupported = true, IsOpen = false})
local self = CharacterSheet

SheetManager.UI.CharacterSheet = CharacterSheet

---@private
---@class SheetUpdateTargets
local updateTargetsDefaults = {
	Abilities = false,
	Civil = false,
	Talents = false,
	PrimaryStats = false,
	SecondaryStats = false,
	Tags = false,
	CustomStats = false,
}

---@type SheetUpdateTargets
local updateTargets = TableHelpers.Clone(updateTargetsDefaults)

---@param this stats_1
---@param listHolder string
---@param id number
---@param groupID integer|nil
---@return FlashMovieClip,FlashArray,integer
local function TryGetMovieClip(this, listHolder, id, groupID, arrayName)
	if this == nil then
		this = CharacterSheet.Root
		if this then
			this = this.stats_mc
		end
	end
	if this and not StringHelpers.IsNullOrWhitespace(listHolder) then
		local holder = this[listHolder]
		if holder then
			local array = nil
			if not StringHelpers.IsNullOrWhitespace(arrayName) then
				array = holder[arrayName]
			else
				local list = holder
				if holder.list then
					list = holder.list
				end
				if groupID ~= nil then
					for i=0,#list.content_array-1 do
						local group = list.content_array[i]
						if group and group.groupId == groupID then
							list = group.list
							break
						end
					end
				end
				array = list.content_array
			end

			if array then
				local mc = nil
				local i = 0
				while i < #array do
					local obj = array[i]
					if obj and obj.statID == id then
						mc = obj
						break
					end
					i = i + 1
				end
				return mc,array,i
			end
		end
		---@diagnostic disable-next-line
	end
end

---@param this stats_1
---@param listHolder string
---@param id number
---@param groupID integer|nil
---@return FlashMovieClip,FlashArray,integer
local function TryGetMovieClip_Controller(this, listHolder, id, groupID, arrayName)
	--TODO
	if this == nil then
		this = CharacterSheet.Root
		if this then
			this = this.mainpanel_mc.stats_mc
		end
	end
	return TryGetMovieClip(this, listHolder, id, groupID, arrayName)
end

---@param this stats_1
---@param listHolder string
---@param id number
---@param groupID integer|nil
---@return FlashMovieClip|nil
---@return FlashArray|nil
---@return integer|nil
CharacterSheet.TryGetMovieClip = function(this, listHolder, id, groupID, arrayName)
	local func = TryGetMovieClip
	if Vars.ControllerEnabled then
		func = TryGetMovieClip_Controller
	end
	local result = {xpcall(func, debug.traceback, this, listHolder, id, groupID, arrayName)}
	if not result[1] then
		--fprint(LOGLEVEL.ERROR, "[CharacterSheet.TryGetMovieClip] Error:\n%s", result[2])
		return nil
	end
	table.remove(result, 1)
	---@diagnostic disable-next-line
	return table.unpack(result)
end

local entryListHolders = {
	primaryStatList = "content_array",
	infoStatList = "content_array",
	secondaryStatList = "content_array",
	resistanceStatList = "content_array",
	expStatList = "content_array",
	civicAbilityHolder_mc = "content_array",
	combatAbilityHolder_mc = "content_array",
	talentHolder_mc = "content_array",
	customStats_mc = "stats_array",
}

---@param entry SheetAbilityData|SheetStatData
---@return FlashMovieClip,FlashArray,integer
CharacterSheet.TryGetEntryMovieClip = function(entry, this)
	local listHolder = nil
	local arrayName = nil
	--[[ if StringHelpers.IsNullOrWhitespace(entry.ListHolder) then
		if entry.StatType == "PrimaryStat" then
			entry.ListHolder = "primaryStatList"
		elseif entry.StatType == "SecondaryStat" then
			if entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Info then
				entry.ListHolder = "infoStatList"
			elseif entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Stat then
				entry.ListHolder = "secondaryStatList"
			elseif entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Resistance then
				entry.ListHolder = "resistanceStatList"
			elseif entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Experience then
				entry.ListHolder = "expStatList"
			end
		elseif entry.StatType == "Ability" then
			if entry.IsCivil then
				entry.ListHolder = "civicAbilityHolder_mc"
			else
				entry.ListHolder = "combatAbilityHolder_mc"
			end
		elseif entry.StatType == "Talent" then
			entry.ListHolder = "talentHolder_mc"
		end
	end ]]
	if entry.StatType == SheetManager.StatType.PrimaryStat then
		listHolder = "primaryStatList"
	elseif entry.StatType == SheetManager.StatType.SecondaryStat then
		if entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Info then
			listHolder = "infoStatList"
		elseif entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Stat then
			listHolder = "secondaryStatList"
		elseif entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Resistance then
			listHolder = "resistanceStatList"
		elseif entry.SecondaryStatType == SheetManager.Stats.Data.SecondaryStatType.Experience then
			listHolder = "expStatList"
		end
	elseif entry.StatType == SheetManager.StatType.Ability then
		if entry.IsCivil then
			listHolder = "civicAbilityHolder_mc"
		else
			listHolder = "combatAbilityHolder_mc"
		end
	elseif entry.StatType == SheetManager.StatType.Talent then
		listHolder = "talentHolder_mc"
	elseif entry.StatType == SheetManager.StatType.Custom then
		listHolder = "customStats_mc"
		arrayName = "stats_array"
	end
	return CharacterSheet.TryGetMovieClip(this, listHolder, entry.GeneratedID, entry.CategoryID, arrayName)
end

---@param customOnly boolean
---@return fun():FlashMovieClip
function CharacterSheet.GetAllEntries(customOnly, this)
	this = this or CharacterSheet.Root
	local stats_mc = this.stats_mc
	local movieclips = {}
	for listName,arrayName in pairs(entryListHolders) do
		if stats_mc[listName] and stats_mc[listName][arrayName] then
			local arr = stats_mc[listName][arrayName]
			local length = #arr
			if length > 0 then
				for i=0,length-1 do
					if arr[i] then
						if not customOnly or customOnly == arr[i].isCustom then
							movieclips[#movieclips+1] = arr[i]
						end
					end
				end
			end
		end
	end
	local i = 0
	local count = #movieclips
	return function ()
		i = i + 1
		if i <= count then
			return movieclips[i]
			---@diagnostic disable-next-line
		end
	end
end

local function debugExportStatArrays(this)
	local saveData = {
		Default = {
			Primary={},
			Secondary={},
			Spacing={},
			Order={}
		}
	}
	for i=0,#this.primStat_array-1,4 do
		saveData.Default.Primary[this.primStat_array[i+1]] = {
			StatID = this.primStat_array[i],
			DisplayName = this.primStat_array[i+1],
			TooltipID = this.primStat_array[i+3]
		}
		table.insert(saveData.Default.Order, this.primStat_array[i+1])
	end
	for i=0,#this.secStat_array-1,7 do
		if this.secStat_array[i] then
			table.insert(saveData.Default.Spacing, {
				Type = "Spacing",
				StatType = this.secStat_array[i+1],
				Height = this.secStat_array[i+2]
			})
			table.insert(saveData.Default.Order, "Spacing")
		else
			saveData.Default.Secondary[this.secStat_array[i+2]] = {
				Type = "SecondaryStat",
				StatType = this.secStat_array[i+1],
				StatID = this.secStat_array[i+4],
				DisplayName = this.secStat_array[i+2],
				Frame = this.secStat_array[i+5]
			}
			table.insert(saveData.Default.Order, this.secStat_array[i+2])
		end
	end
	Ext.IO.SaveFile("StatsArrayContents.lua", Lib.serpent.raw(saveData, {indent = '\t', sortkeys = false, comment = false}))
end

--local triggers = {}; for _,uuid in pairs(Ext.GetAllTriggers()) do local trigger = Ext.GetTrigger(uuid); triggers[#triggers+1] = trigger; end; Ext.IO.SaveFile("Triggers.json", inspect(triggers))
--local triggers = {}; for _,uuid in pairs(Ext.GetAllTriggers()) do local trigger = Ext.GetTrigger(uuid); triggers[#triggers+1] = trigger; end; Ext.IO.SaveFile("Triggers.lua", Mods.CharacterExpansionLib:Lib.serpent.block(triggers))

local updating = false
local requestedClear = {}

local panelToTabType = {
	[0] = "Stats",
	[1] = "Abilities",
	[2] = "Abilities",
	[3] = "Talents",
	[4] = "Tags",
	[5] = "Inventory",
	[6] = "Skills",
	[7] = "Visuals",
	[8] = "CustomStats",
}

local clearPanelMethods = {
	Stats = "clearStats",
	Abilities = "clearAbilities",
	Talents = "clearTalents",
}

local function clearRequested(ui, method, force)
	if not updating and force ~= true then
		requestedClear[method] = true
	end
end

Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "clearStats", clearRequested)
Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "clearAbilities", clearRequested)
Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "clearTalents", clearRequested)
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "selectedTab", function(ui, call, panel)
	
end, "Before")

local function getParamsValue(params, index, default)
	if params[index] ~= nil then
		return params[index]
	else
		return default
	end
end

local targetsUpdated = {}

local function SortLists(this)
	if not Vars.ControllerEnabled then
		if targetsUpdated.PrimaryStats or targetsUpdated.SecondaryStats then
			this.stats_mc.mainStatsList.positionElements()
		end
		if targetsUpdated.Talents then
			this.stats_mc.talentHolder_mc.list.positionElements()
		end
		if targetsUpdated.Abilities then
			this.stats_mc.combatAbilityHolder_mc.list.positionElements()
			this.stats_mc.recountAbilityPoints(false)
		end
		if targetsUpdated.Civil then
			this.stats_mc.civicAbilityHolder_mc.list.positionElements()
			this.stats_mc.recountAbilityPoints(true)
		end
		if targetsUpdated.CustomStats then
			this.stats_mc.customStats_mc.positionElements()
		end
	else
		if targetsUpdated.Talents then
			this.mainpanel_mc.stats_mc.talents_mc.updateDone()
		end
		if targetsUpdated.Abilities then
			if targetsUpdated.Civil then
				this.mainpanel_mc.stats_mc.civilAbilities_mc.updateDone()
			else
				this.mainpanel_mc.stats_mc.combatAbilities_mc.updateDone()
			end
		end
	end
end

local function GetArrayValues(this,baseChanges,modChanges)
	local defaultCanAdd = this.isGameMasterChar
	local defaultCanRemove = this.isGameMasterChar
	local time = Ext.Utils.MonotonicTime()
	local arr = this.primStat_array
	for i=0,#arr-1,4 do
		local id = arr[i]
		if id ~= nil then
			local targetTable = modChanges
			if SheetManager.Stats.Data.Builtin.ID[id] then
				targetTable = baseChanges
			end
			targetTable.Stats[id] = {
				DisplayName = arr[i+1],
				Value = arr[i+2],
				TooltipID = arr[i+3],
				Type = "PrimaryStat",
			}
		end
	end
	arr = this.secStat_array
	for i=0,#arr-1,7 do
		--Not spacing
		if not arr[i] then
			local id = arr[i+4]
			if id ~= nil then
				local targetTable = modChanges
				if SheetManager.Stats.Data.Builtin.ID[id] then
					targetTable = baseChanges
				end
				targetTable.Stats[id] = {
					DisplayName = arr[i+2],
					Value = arr[i+3],
					StatType = arr[i+1],
					Frame = arr[i+5],
					BoostValue = arr[i+6],
					Type = "SecondaryStat",
				}
			end
		end
	end
	arr = this.talent_array
	for i=0,#arr-1,3 do
		local id = arr[i+1]
		if id ~= nil then
			local targetTable = modChanges
			if Data.Talents[id] then
				targetTable = baseChanges
			end
			targetTable.Talents[id] = {
				DisplayName = arr[i],
				State = arr[i+2],
			}
		end
	end
	arr = this.ability_array
	for i=0,#arr-1,7 do
		local id = arr[i+2]
		if id ~= nil then
			local targetTable = modChanges
			if Data.Ability[id] then
				targetTable = baseChanges
			end
			local isCivil = arr[i] == true
			targetTable.Abilities[id] = {
				IsCivil = isCivil,
				DisplayName = arr[i+3],
				Value = arr[i+4],
				CategoryID = arr[i+1],
				AddPointsTooltip = arr[i+5],
				RemovePointsTooltip = arr[i+6],
			}
		end
	end
	arr = this.lvlBtnStat_array
	for i=0,#arr-1,3 do
		local canAddPoints = arr[i]
		local id = arr[i+1]
		local isVisible = arr[i+2]
		local entry = modChanges[id] or baseChanges[id]
		if entry then
			if canAddPoints then
				entry.CanAdd = isVisible or this.isGameMasterChar
			else
				entry.CanRemove = isVisible or this.isGameMasterChar
			end
		end
	end
	arr = this.lvlBtnSecStat_array
	local hasButtons = arr[0]
	for i=1,#arr-1,4 do
		local id = arr[i]
		local entry = modChanges[id] or baseChanges[id]
		if entry then
			if hasButtons then
				local showBothButtons = arr[i+1]
				entry.CanRemove = arr[i+2] or this.isGameMasterChar
				entry.CanAdd = arr[i+3] or this.isGameMasterChar
			else
				entry.CanRemove = this.isGameMasterChar
				entry.CanAdd = this.isGameMasterChar
			end
		end
	end
	arr = this.lvlBtnAbility_array
	for i=0,#arr-1,5 do
		local canAddPoints = arr[i]
		local id = arr[i+3]
		local isVisible = arr[i+4]
		local entry = modChanges[id] or baseChanges[id]
		if entry then
			if canAddPoints then
				entry.CanAdd = isVisible
			else
				entry.CanRemove = isVisible
			end
		end
	end
	arr = this.lvlBtnTalent_array
	for i=0,#arr-1,3 do
		local canAddPoints = arr[i]
		local id = arr[i+1]
		local isVisible = arr[i+2]
		local entry = modChanges[id] or baseChanges[id]
		if entry then
			if canAddPoints then
				entry.CanAdd = isVisible
			else
				entry.CanRemove = isVisible
			end
		end
	end
	--fprint(LOGLEVEL.DEFAULT, "Took (%s)ms to parse character sheet arrays.", Ext.MonotonicTime() - time)
end

local function ParseArrayValues(this, skipSort)

	local modChanges = {Stats = {},Abilities = {},Talents = {}}
	local baseChanges = {Stats = {},Abilities = {},Talents = {}}

	pcall(GetArrayValues, this, baseChanges, modChanges)

	this.clearArray("lvlBtnStat_array")
	this.clearArray("lvlBtnTalent_array")
	this.clearArray("lvlBtnSecStat_array")
	this.clearArray("lvlBtnAbility_array")

	-- print("baseChanges",Lib.serpent.dump(baseChanges))
	-- print("modChanges",Lib.serpent.dump(modChanges))

	for id,entry in pairs(modChanges.Stats) do
		if entry.Type == "PrimaryStat" then
			targetsUpdated.PrimaryStats = true
			if not Vars.ControllerEnabled then
				this.stats_mc.addPrimaryStat(id, entry.DisplayName, entry.Value, entry.TooltipID, entry.CanAdd or false, entry.CanRemove or false)
			end
		else
			targetsUpdated.SecondaryStats = true
			if not Vars.ControllerEnabled then
				this.stats_mc.addSecondaryStat(entry.StatType, entry.DisplayName, entry.Value, id, entry.Frame or 0, entry.BoostValue, entry.CanAdd or false, entry.CanRemove or false)
			end
		end
	end

	for id,entry in pairs(modChanges.Talents) do
		targetsUpdated.Talents = true
		if not Vars.ControllerEnabled then
			if entry.State == SheetManager.Talents.Data.TalentState.Selected then
				entry.CanRemove = this.isGameMasterChar
				entry.CanAdd = false
			else
				entry.CanRemove = false
			end
			this.stats_mc.addTalent(entry.DisplayName, id, entry.State, entry.CanAdd or false, entry.CanRemove or false)
		else
			this.mainpanel_mc.stats_mc.talents_mc.addTalent(entry.DisplayName, id, entry.State, entry.CanAdd or false, entry.CanRemove or false)
		end
	end

	for id,entry in pairs(modChanges.Abilities) do
		if entry.IsCivil then
			targetsUpdated.Civil = true
		else
			targetsUpdated.Abilities = true
		end
		if not Vars.ControllerEnabled then
			this.stats_mc.addAbility(entry.IsCivil, entry.CategoryID, id, entry.DisplayName, entry.Value, entry.AddPointsTooltip, entry.RemovePointsTooltip, entry.CanAdd or false, entry.CanRemove or false)
		end
	end

	if skipSort ~= true then
		SortLists(this)
	end
end

---@param this CharacterSheetMainTimeline
---@return EclCharacter|nil
local function TryGetSheetCharacter(this)
	if this.characterHandle ~= nil then
		return GameHelpers.Client.TryGetCharacterFromDouble(this.characterHandle)
	end
end

---@return EclCharacter
function CharacterSheet.GetCharacter()
	if Ext.GetGameState() ~= "Running" or SharedData.RegionData.LevelType ~= LEVELTYPE.GAME then
		---@diagnostic disable-next-line
		return GameHelpers.Client.GetCharacter()
	end
	local this = CharacterSheet.Root
	if this then
		local b,client = xpcall(TryGetSheetCharacter, debug.traceback, this)
		if b and client ~= nil then
			return client
		end
	end
	return Client:GetCharacter()
end

---@private
---@param ui UIObject
---@param method string
---@param params SheetUpdateTargets
function CharacterSheet.Update(ui, method, params)
	updating = true
	---@type CharacterSheetMainTimeline|table
	local this = self.Root

	if not this or this.isExtended ~= true then
		return
	end

	--local currentPanelType = panelToTabType[this.stats_mc.currentOpenPanel]
	for method,b in pairs(requestedClear) do
		pcall(this[method], true)
		-- if clearPanelMethods[currentPanelType] ~= method then
		-- 	pcall(this[method], true)
		-- end
	end

	local player = CharacterSheet.GetCharacter()

	local extraParams = type(params) == "table" and params or {}

	this.justUpdated = true

	updateTargets.Abilities = extraParams.Abilities or #this.ability_array > 0
	updateTargets.Civil = extraParams.Civil or (updateTargets.Abilities and this.ability_array[0] == true)
	updateTargets.Talents = extraParams.Talents or #this.talent_array > 0
	updateTargets.PrimaryStats = extraParams.PrimaryStats or #this.primStat_array > 0
	updateTargets.SecondaryStats = extraParams.SecondaryStats or #this.secStat_array > 0
	updateTargets.Tags = extraParams.Tags or #this.tags_array > 0
	updateTargets.CustomStats = extraParams.CustomStats or #this.customStats_array > 0

	---@type SheetUpdateTargets
	targetsUpdated = TableHelpers.Clone(updateTargetsDefaults)
	local isGM = GameHelpers.Client.IsGameMaster(ui, this)

	local stats = SessionManager:CreateCharacterSessionMetaTable(player)

	if updateTargets.PrimaryStats or updateTargets.SecondaryStats then
		--this.clearStats()
		for stat in SheetManager.Stats.GetVisible(player, {IsGM=isGM, Stats=stats}) do
			SheetManager.Events.OnEntryUpdating:Invoke({ModuleUUID = stat.Mod, ID=stat.ID, EntryType="SheetStatData", Stat=stat, Character=player, CharacterID=player.NetID})
			-- local arrayData = modChanges.Stats[stat.ID]
			-- if arrayData then
			-- 	if arrayData.Value ~= stat.Value then
			-- 		--fprint(LOGLEVEL.WARNING, "Stat value differs from the array value Lua(%s) <=> Array(%s)", stat.Value, arrayData.Value)
			-- 	end
			-- end
			-- if stat.IsCustom then
			-- 	print(Lib.serpent.block(stat))
			-- end
			--Mods may set this to false in the listener, to hide the entry
			if stat.Visible then
				if not Vars.ControllerEnabled then
					if stat.StatType == SheetManager.Stats.Data.StatType.PrimaryStat then
						targetsUpdated.PrimaryStats = true
						this.stats_mc.addPrimaryStat(stat.GeneratedID, stat.DisplayName, stat.Value.Label, stat.GeneratedID, stat.CanAdd, stat.CanRemove, stat.IsCustom, stat.Frame or -1, stat.IconClipName or "")
						if not StringHelpers.IsNullOrWhitespace(stat.IconClipName) then
							ui:SetCustomIcon(stat.IconDrawCallName, stat.Icon, stat.IconWidth, stat.IconHeight)
						end
					else
						targetsUpdated.SecondaryStats = true
						if stat.StatType == SheetManager.Stats.Data.StatType.Spacing then
							this.stats_mc.addSpacing(stat.GeneratedID, stat.SpacingHeight)
						else
							this.stats_mc.addSecondaryStat(stat.SecondaryStatTypeInteger, stat.DisplayName, stat.Value.Label, stat.GeneratedID, stat.Frame, stat.BoostValue, stat.CanAdd, stat.CanRemove, stat.IsCustom, stat.IconClipName or "")
							if not StringHelpers.IsNullOrWhitespace(stat.IconClipName) then
								ui:SetCustomIcon(stat.IconDrawCallName, stat.Icon, stat.IconWidth, stat.IconHeight)
							end
						end
					end
				else
					--TODO
					--this.mainpanel_mc.stats_mc.addPrimaryStat(stat.GeneratedID, stat.DisplayName, stat.Value, stat.TooltipID, canAdd, canRemove, stat.IsCustom)
				end
			end
		end
	end

	if updateTargets.Talents then
		--this.clearTalents()
		--local points = this.stats_mc.pointsWarn[3].avPoints
		for talent in SheetManager.Talents.GetVisible(player, {IsGM=isGM, Stats=stats}) do
			SheetManager.Events.OnEntryUpdating:Invoke({ModuleUUID = talent.Mod, ID=talent.ID, EntryType="SheetTalentData", Stat=talent, Character=player, CharacterID=player.NetID})
			if talent.Visible then
				if not Vars.ControllerEnabled then
					this.stats_mc.addTalent(talent.DisplayName, talent.GeneratedID, talent.State, talent.CanAdd, talent.CanRemove, talent.IsCustom)
				else
					this.mainpanel_mc.stats_mc.talents_mc.addTalent(talent.DisplayName, talent.GeneratedID, talent.State, talent.CanAdd, talent.CanRemove, talent.IsCustom)
				end
			end
			targetsUpdated.Talents = true
		end
	end

	if updateTargets.Abilities then
		for category in SheetManager.Abilities.GetVisibleCategories(player, {IsGM=isGM, Stats=stats, CivilOnly=updateTargets.Civil}) do
			SheetManager.Events.OnEntryUpdating:Invoke({ModuleUUID = category.Mod, ID=category.ID, EntryType="SheetAbilityCategoryData", Stat=category, Character=player, CharacterID=player.NetID})
			if category.Visible then
				this.stats_mc.addAbilityGroup(category.IsCivil, category.GeneratedID, category.DisplayName)
			end
		end
		for ability in SheetManager.Abilities.GetVisible(player, {IsGM=isGM, Stats=stats, CivilOnly=updateTargets.Civil}) do
			SheetManager.Events.OnEntryUpdating:Invoke({ModuleUUID = ability.Mod, ID=ability.ID, EntryType="SheetAbilityData", Stat=ability, Character=player, CharacterID=player.NetID})
			if ability.Visible then
				this.stats_mc.addAbility(ability.IsCivil, ability.CategoryID, ability.GeneratedID, ability.DisplayName, ability.Value.Label, ability.AddPointsTooltip, ability.RemovePointsTooltip, ability.CanAdd, ability.CanRemove, ability.IsCustom)
				if ability.IsCivil then
					targetsUpdated.Civil = true
				else
					targetsUpdated.Abilities = true
				end
			end
		end
		--this.stats_mc.addAbility(false, 1, 77, "Test Ability", "0", "", "", false, false, true)
		--this.stats_mc.addAbility(true, 3, 78, "Test Ability2", "0", "", "", false, false, true)
	end

	if updateTargets.CustomStats or this.stats_mc.currentOpenPanel == 8 then
		SheetManager.CustomStats.UI.Update(ui, method, this)
		targetsUpdated.CustomStats = true
	end
end

---@private
---@param ui UIObject
function CharacterSheet.PostUpdate(ui, method)
	---@type CharacterSheetMainTimeline
	local this = self.Root
	if not this or this.isExtended ~= true then
		return
	end

	SortLists(this)

	this.stats_mc.resetScrollBarsPositions()
	this.stats_mc.resetListPositions()
	this.stats_mc.recheckScrollbarVisibility()
end

---@private
function CharacterSheet.UpdateComplete(ui, method)
	---@type CharacterSheetMainTimeline
	local this = self.Root
	if not this or this.isExtended ~= true then
		return
	end

	--ParseArrayValues(this, false)

	this.justUpdated = false
	targetsUpdated = {}
	updating = false
	requestedClear = {}
	this.clearArray("update")
end

Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "updateArraySystem", CharacterSheet.Update, "Before")
Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "updateArraySystem", CharacterSheet.PostUpdate, "After")
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "characterSheetUpdateDone", CharacterSheet.UpdateComplete)
--Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "changeSecStatCustom", function(...) CharacterSheet:ValueChanged("SecondaryStat", ...))

Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "setTitle", function(ui, method)
	local this = CharacterSheet.Root
	if this and this.isExtended then
		local stats_mc = this.stats_mc
		stats_mc.setMainStatsGroupName(stats_mc.GROUP_MAIN_ATTRIBUTES, GameHelpers.GetTranslatedString("h15c226f2g54dag4f0eg80e6g121098c0766e", "Attributes"))
		stats_mc.setMainStatsGroupName(stats_mc.GROUP_MAIN_STATS, GameHelpers.GetTranslatedString("h3d70a7c1g6f19g4f28gad0cgf0722eea9850", "Stats"))
		stats_mc.setMainStatsGroupName(stats_mc.GROUP_MAIN_EXPERIENCE, GameHelpers.GetTranslatedString("he50fce4dg250cg4449g9f33g7706377086f6", "Experience"))
		stats_mc.setMainStatsGroupName(stats_mc.GROUP_MAIN_RESISTANCES, GameHelpers.GetTranslatedString("h5a0c9b53gd3f7g4e01gb43ege4a255e1c8ee", "Resistances"))
	end
end)
Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, "characterSheetUpdateDone", CharacterSheet.Update)

local secondaryStatListProperties = {
	infoStatList = true,
	secondaryStatList = true,
	resistanceStatList = true,
	expStatList = true,
}

--local mc = sheet.stats_mc.resistanceStatList.content_array[8]; print(mc.statID, mc.texts_mc.label_txt.htmlText)
--for i=5,9 do local mc = sheet.stats_mc.resistanceStatList.content_array[i]; print(mc.statID, mc.texts_mc.label_txt.htmlText) end
local function OnEntryAdded(ui, call, isCustom, statID, listProperty, groupID)
	if not secondaryStatListProperties[listProperty] then
		return
	end
	local main = ui:GetRoot()
	local this = main.stats_mc
	local list = this[listProperty]
	if list then
		if list.list then
			list = list.list
		end
		local arr = nil
		local mc = nil
		if groupID ~= nil then
			for i=0,#list.content_array-1 do
				if list.content_array[i] and list.content_array[i].groupID == groupID then
					arr = list.content_array[i].content_array
					break
				end
			end
		else
			arr = list.content_array
		end
		if arr then
			for i=0,#arr-1 do
				if arr[i] and arr[i].statID == statID then
					mc = arr[i]
					break
				end
			end
		end
		if mc then
			if mc.type == "SecondaryStat" or mc.type == "InfoStat" then
				if main.isGameMasterChar then
					this.setupSecondaryStatsButtons(mc.statID,true,true,true,mc.statID == 44 and 9 or 5)
				else
					this.setupSecondaryStatsButtons(mc.statID,false,false,false)
				end
			end
			if isCustom then
				local stat = SheetManager:GetEntryByGeneratedID(statID, mc.Type)
				if stat then
					local character = GameHelpers.Client.GetCharacterSheetCharacter(this)
					SheetManager.Events.OnEntryAddedToUI:Invoke({
						ModuleUUID = stat.Mod,
						ID = stat.ID,
						EntryType = stat.Type,
						Stat = stat,
						MovieClip = mc,
						Character = character,
						CharacterID = character.NetID,
						UI = ui,
						Root = this,
						UIType = ui.Type,
					})
				end
			end
		end
	end
end
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "entryAdded", OnEntryAdded)

local function OnCharacterSelected(wrapper, e, ui, event, doubleHandle)
	if doubleHandle then
		local player = GameHelpers.Client.TryGetCharacterFromDouble(doubleHandle)
		if player then
			SheetManager:SyncData(player)
		end
	end
end

CharacterSheet.Register:Invoke("selectCharacter", OnCharacterSelected, "After", "Keyboard")
CharacterSheet.Register:Invoke("setPlayer", OnCharacterSelected, "After", "Controller")

local function getTalentStateFrame(talentState)
	if talentState == 0 then
		return 2
	elseif talentState == 1 then
		return 3
	else
		return 1
	end
end

---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@param character EclCharacter
---@param value integer|boolean
function CharacterSheet.UpdateEntry(entry, character, value)
	---@type CharacterSheetMainTimeline
	local this = CharacterSheet.Root
	if this and this.isExtended then
		character = character or CharacterSheet.GetCharacter()
		value = value or entry:GetValue(character)
		local maxValue = SheetManager:GetMaxValue(entry)
		local points = SheetManager:GetBuiltinAvailablePointsForEntry(entry, character)
		local isGM = GameHelpers.Client.IsGameMaster(CharacterSheet.Instance, this)
		local defaultCanAdd = isGM == true
		if not defaultCanAdd then
			local hasPoints = (entry.UsePoints and points > 0)
			if maxValue then
				defaultCanAdd = value < maxValue and hasPoints
			else
				defaultCanAdd = hasPoints
			end
		end
		local defaultCanRemove = entry.UsePoints and isGM

		local recountGroup = ""

		local mc,arr,index = CharacterSheet.TryGetEntryMovieClip(entry, this.stats_mc)
		--fprint(LOGLEVEL.TRACE, "Entry[%s](%s) statID(%s) ListHolder(%s) arr(%s) mc(%s) index(%s)", entry.StatType, id, entry.GeneratedID, entry.ListHolder, arr, mc, index)
		if arr and mc then
			local plusVisible = SheetManager:GetIsPlusVisible(entry, character, defaultCanAdd, value)
			local minusVisible = SheetManager:GetIsMinusVisible(entry, character, defaultCanRemove, value)

			if entry.StatType == "Ability" then
				mc.texts_mc.plus_mc.visible = plusVisible
				mc.texts_mc.minus_mc.visible = minusVisible
			else
				mc.plus_mc.visible = plusVisible
				mc.minus_mc.visible = minusVisible
			end

			if entry.StatType == "PrimaryStat" then
				mc.text_txt.htmlText = string.format("%i%s", value, entry.Suffix or "")
				mc.statBasePoints = value
				-- mc.statPoints = 0
			elseif entry.StatType == "SecondaryStat" then
				mc.boostValue = value
				mc.text_txt.htmlText = string.format("%i%s", value, entry.Suffix or "")
				mc.statBasePoints = value
				-- mc.statPoints = 0
			elseif entry.StatType == "Ability" then
				mc.am = value
				mc.texts_mc.text_txt.htmlText = string.format("%i%s", value, entry.Suffix or "")
				mc.statBasePoints = value
				if not StringHelpers.IsNullOrEmpty(entry.CustomCategory) then
					recountGroup = entry.IsCivil and "Civil" or "Combat"
				end
				-- mc.statPoints = 0
			elseif entry.StatType == "Talent" then
				local talentState = entry:GetState(character)
				local name = string.format(SheetManager.Talents.GetTalentStateFontFormat(talentState), entry:GetDisplayName())
				if mc.label_txt then
					mc.label_txt.htmlText = name
				end
				mc.label = name
				mc.talentState = talentState
				mc.bullet_mc.gotoAndStop(getTalentStateFrame(talentState))

				if not Vars.ControllerEnabled then
					this.stats_mc.talentHolder_mc.list.positionElements()
				else
					this.stats_mc.mainpanel_mc.stats_mc.talents_mc.updateDone()
				end
			elseif entry.StatType == SheetManager.StatType.Custom then
				local visible = true
				if visible then
					mc.am = value

					if entry.DisplayMode == "Percentage" then
						mc.setTextValue(string.format("%s%%%s", math.floor(value), entry.Suffix or ""))
					elseif value > 999 then -- Values greater than this are truncated visually in the UI
						mc.setTextValue(string.format("%s%s", StringHelpers.GetShortNumberString(value), entry.Suffix or ""))
					end

					mc.plus_mc.visible = plusVisible
					mc.minus_mc.visible = minusVisible
					mc.edit_mc.visible = not mc.isCustom and isGM
					mc.delete_mc.visible = not mc.isCustom and isGM
				end
			end
		end

		if recountGroup ~= "" then
			this.stats_mc.recountAbilityPoints(recountGroup == "Civil")
		end
	end
end

SheetManager.Events.OnEntryChanged:Subscribe(function (e)
	if CharacterSheet.Visible then
		CharacterSheet.UpdateEntry(e.Stat, e.Character, e.Value)
	end
end)

function CharacterSheet.UpdateAllEntries()
	local this = CharacterSheet.Root
	if this and this.isExtended then
		local character = CharacterSheet.GetCharacter()
		for mc in CharacterSheet.GetAllEntries(true) do
			local entry = SheetManager:GetEntryByGeneratedID(mc.statID, mc.type)
			if entry then
				local maxValue = SheetManager:GetMaxValue(entry)
				local value = entry:GetValue(character)
				local points = SheetManager:GetBuiltinAvailablePointsForEntry(entry, character)
				local isGM = GameHelpers.Client.IsGameMaster(CharacterSheet.Instance, this)
				local defaultCanRemove = isGM
				local defaultCanAdd = isGM == true
				if not defaultCanAdd then
					local hasPoints = (entry.UsePoints and points > 0)
					if maxValue then
						defaultCanAdd = value < maxValue and hasPoints
					else
						defaultCanAdd = hasPoints
					end
				end

				local plusVisible = SheetManager:GetIsPlusVisible(entry, character, defaultCanAdd, value)
				local minusVisible = SheetManager:GetIsMinusVisible(entry, character, defaultCanRemove, value)

				if entry.StatType == "Ability" then
					mc.texts_mc.plus_mc.visible = plusVisible
					mc.texts_mc.minus_mc.visible = minusVisible
				else
					mc.plus_mc.visible = plusVisible
					mc.minus_mc.visible = minusVisible
				end

				if mc.type == "PrimaryStat" then
					mc.text_txt.htmlText = string.format("%i%s", value, entry.Suffix or "")
					mc.statBasePoints = value
					-- mc.statPoints = 0
				elseif mc.type == "SecondaryStat" or mc.type == "InfoStat" then
					mc.boostValue = value
					if mc.texts_mc then
						mc.texts_mc.text_txt.htmlText = string.format("%i%s", value, entry.Suffix or "")
						if isGM then
							this.setupSecondaryStatsButtons(mc.statID,true,minusVisible,plusVisible,mc.statID == 44 and 9 or 5)
						else
							this.setupSecondaryStatsButtons(mc.statID,false,false,false)
						end
					else
						if mc.text_txt then
							mc.text_txt.htmlText = string.format("%i%s", value, entry.Suffix or "")
						end
					end
					mc.statBasePoints = value
					-- mc.statPoints = 0
				elseif entry.StatType == "Ability" then
					mc.am = value
					mc.texts_mc.text_txt.htmlText = string.format("%i%s", value, entry.Suffix or "")
					mc.statBasePoints = value
					-- mc.statPoints = 0
				elseif entry.StatType == "Talent" then
					local talentState = entry:GetState(character)
					local name = string.format(SheetManager.Talents.GetTalentStateFontFormat(talentState), entry:GetDisplayName())
					if mc.label_txt then
						mc.label_txt.htmlText = name
					end
					mc.label = name
					mc.talentState = talentState
					mc.bullet_mc.gotoAndStop(getTalentStateFrame(talentState))

					if not Vars.ControllerEnabled then
						this.talentHolder_mc.list.positionElements()
					else
						this.mainpanel_mc.stats_mc.talents_mc.updateDone()
					end
				elseif entry.StatType == "Custom" then
					--local groupId = SheetManager.CustomStats:GetCategoryGroupId(entry.Category, entry.Mod)
					SheetManager.CustomStats.UI:UpdateStatValue(mc, entry, character)

					mc.plus_mc.visible = plusVisible
					mc.minus_mc.visible = minusVisible
					mc.edit_mc.visible = not mc.isCustom and isGM
					mc.delete_mc.visible = not mc.isCustom and isGM
				end
			end
		end
	end
end

if Vars.DebugMode then
	Events.BeforeLuaReset:Subscribe(function(e)
		if CharacterSheet.Visible then
			local ui = CharacterSheet.Instance
			if ui then
				ui:ExternalInterfaceCall("closeCharacterUIs")
				ui:ExternalInterfaceCall("hideUI")
			end
		end
	end)

	Events.LuaReset:Subscribe(function(e)
		local this = CharacterSheet.Root
		if this then
			local player = Client:GetCharacter()
			if player then
				local doubleHandle = Ext.UI.HandleToDouble(player.Handle)
				this.characterHandle = doubleHandle
				this.charHandle = doubleHandle
			end
			if not Vars.ControllerEnabled then
				this.clearAbilities(true)
				this.clearTalents(true)
				this.clearStats(true)
			else
				-- this.removeAbilities()
				-- this.removeTalents()
				-- this.removeStatsTabs()
				-- this.clearCustomStats()
			end
		end
	end)
end

Ext.RegisterUITypeInvokeListener(Data.UIType.hotBar, "setButtonActive", function(ui, method, id, isActive)
	if id == 1 then
		CharacterSheet.IsOpen = isActive
	end
end)

-- CTRL + G to toggle GameMasterMode
Input.RegisterListener("ToggleCraft", function(event, pressed, id, keys, controllerEnabled)
	if Input.IsPressed("ToggleInfo") and CharacterSheet.IsOpen then
		---@type FlashMainTimeline
		local this = nil
		if not Vars.ControllerEnabled then
			this = Ext.UI.GetByType(Data.UIType.characterSheet):GetRoot()
		else
			this = Ext.UI.GetByType(Data.UIType.statsPanel_c):GetRoot()
		end
		if not this then
			return
		end
		if this.isGameMasterChar then
			local character = Client:GetCharacter()
			this.setGameMasterMode(false, false, false)
			CharacterSheet.UpdateAllEntries()
			GameHelpers.Net.PostMessageToServer("LeaderLib_RefreshCharacterSheet", Client.Character.UUID)

			local points = Client.Character.Points
			this.setAvailableStatPoints(points.Attribute)
			this.setAvailableCombatAbilityPoints(points.Ability)
			this.setAvailableCivilAbilityPoints(points.Civil)
			this.setAvailableTalentPoints(points.Talent)
			this.setAvailableCustomStatPoints(SheetManager.CustomStats:GetTotalAvailablePoints(character))
		else
			this.setGameMasterMode(true, true, false)
			CharacterSheet.UpdateAllEntries()
		end
	end
end)