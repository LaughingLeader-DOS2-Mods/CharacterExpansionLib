local CustomStatsUI = {}

SheetManager.CustomStats.UI = CustomStatsUI

CustomStatsUI.Visible = false
CustomStatsUI.MaxVisibleValue = 999 -- Values greater than this are truncated visually in the UI

function CustomStatsUI:GetNextCustomStatIconId()
	self.LastIconId = self.LastIconId + 1
	return self.LastIconId
end

--Ext.UI.GetByType(63):GetRoot().showPanel(6)
--Ext.UI.GetByType(63):GetRoot().addStatsTab(6, 0, "Extra Stats")

local function AdjustCustomStatMovieClips(ui)
	local this = ui:GetRoot()
	local arr = this.stats_mc.customStats_mc.list.content_array
	for i=0,#arr do
		local mc = arr[i]
		if mc then
			local displayName = mc.label_txt.htmlText
			local stat = CustomStatsUI:GetStatByName(displayName)
			if stat then
				stat.Double = mc.statID
				mc.label_txt.htmlText = stat:GetDisplayName()
			end
		end
	end
end

---@class CharacterSheetStatArrayData
---@field Index integer Original index
---@field DisplayName string
---@field Handle number
---@field Value number
---@field GroupId integer
---@field Stat SheetCustomStatData|nil

---@class SheetManager.CustomStatsUIEntry
---@field ID string
---@field GeneratedID integer
---@field GroupID integer
---@field DisplayName string
---@field PlusVisible boolean
---@field MinusVisible boolean
---@field Value number

---@param this CharacterSheetMainTimeline
function CustomStatsUI.Update(ui, method, this)
	CustomStatsUI:SetupGroups(ui, method)
	local client = SheetManager.UI.CharacterSheet.GetCharacter()

	local isGM = GameHelpers.Client.IsGameMaster()
	local defaultCanRemove = isGM
	
	if SheetManager.CustomStats:GMStatsEnabled() then
		if client then
			local changedStats = {NetID=client.NetID,Stats={}}
			for stat in CustomStatsUI:GetAllStats(false,false,true) do
				local last = stat:GetLastValue(client)
				local value = stat:GetValue(client)
				if last and value ~= last then
					changedStats.Stats[#changedStats.Stats+1] = {
						ID = stat.ID,
						Mod = stat.Mod,
						Last = last,
						Current = value
					}
					CustomStatsUI:InvokeStatValueChangedListeners(stat, client, last, value)
				end
				stat:UpdateLastValue(client)
			end
			-- if #changedStats.Stats > 0 then
			-- 	Ext.PostMessageToServer("CEL_CustomStatsUI_StatValuesChanged", Ext.JsonStringify(changedStats))
			-- end
		end

		local length = #this.customStats_array
		if length == 0 then
			return
		end
		local sortList = {}
		
		for i=0,length-1,3 do
			-- print("i", i,this.customStats_array[i])
			-- print("i+1", i+1,this.customStats_array[i+1])
			-- print("i+2", i+2,this.customStats_array[i+2])
			local doubleHandle = this.customStats_array[i]
			local displayName = this.customStats_array[i+1]
			local value = this.customStats_array[i+2]
			local groupId = SheetManager.CustomStats.MISC_CATEGORY
			local hideStat = false

			if type(displayName) ~= "string" then
				goto continue
			end
	
			if doubleHandle then
				local stat = SheetManager.CustomStats:GetStatByName(displayName)
				if stat then
					stat.Double = doubleHandle
					displayName = stat:GetDisplayName()
					groupId = SheetManager.CustomStats:GetCategoryGroupId(stat.Category, stat.Mod)
					local visible = SheetManager:IsEntryVisible(stat, client)
					if visible == false then
						hideStat = true
					end
				else
					local text = GameHelpers.GetStringKeyText(displayName)
					if not StringHelpers.IsNullOrWhitespace(text) then
						displayName = text
					end
				end
				if not hideStat then
					sortList[#sortList+1] = {Index=i, DisplayName=displayName, Handle=doubleHandle, Value=value, GroupId=groupId, Stat=stat}
				end
			end

			::continue::
		end

		if #sortList > 0 then
			table.sort(sortList, CustomStatsUI.SortStats)
			--Remove any stats that were hidden
			this.clearArray("customStats_array")

			for i=1,#sortList do
				local entry = sortList[i]
				local value = entry.Value
				local defaultCanAdd = not StringHelpers.IsNullOrWhitespace(entry.PointID) or isGM
				local plusVisible = SheetManager:GetIsPlusVisible(entry, client, defaultCanAdd, value)
				local minusVisible = SheetManager:GetIsMinusVisible(entry, client, defaultCanRemove, value)
				this.stats_mc.customStats_mc.addCustomStat(entry.Handle, entry.DisplayName, entry.Value, entry.GroupId, plusVisible, minusVisible, false)
			end
		end
	else
		if this.isExtended then
			this.clearArray("customStats_array")
		end
		
		for stat in SheetManager.CustomStats.GetAllStats(false, true, true) do
			local visible = SheetManager:IsEntryVisible(stat, client)
			if visible then
				local value = stat:GetValue(client)
				local defaultCanAdd = not StringHelpers.IsNullOrWhitespace(stat.PointID) or isGM
				local plusVisible = SheetManager:GetIsPlusVisible(stat, client, defaultCanAdd, value)
				local minusVisible = SheetManager:GetIsMinusVisible(stat, client, defaultCanRemove, value)

				---@type SheetManager.CustomStatsUIEntry
				local data = {
					ID = stat.ID,
					GeneratedID = stat.GeneratedID,
					Value = value,
					GroupID = SheetManager.CustomStats:GetCategoryGroupId(stat.Category, stat.Mod),
					PlusVisible = plusVisible,
					MinusVisible = minusVisible,
					DisplayName = stat:GetDisplayName(),
				}
				SheetManager.Events.OnEntryUpdating:Invoke({ID=stat.ID, EntryType="Custom", Stat=data, Character=client})
				if stat.Visible then
					this.stats_mc.customStats_mc.addCustomStat(data.GeneratedID, data.DisplayName, tostring(data.Value), data.GroupID, data.PlusVisible == true, data.MinusVisible == true, true)
				end
			end
		end
	end
end

local miscGroupDisplayName = Classes.TranslatedString:Create("hb8ed2061ge5a3g4f64g9d54g9a9b65e27e1e", "Miscellaneous")

local initializedGroups = false
local lastScrollY = 0

function CustomStatsUI:SetupGroups(ui, call)
	local this = ui:GetRoot()
	if not this then
		return
	end
	local isGM = GameHelpers.Client.IsGameMaster()
	local this = this.stats_mc.customStats_mc
	if not this.list then
		return
	end
	lastScrollY = this.list.m_scrollbar_mc.m_scrolledY
	if not initializedGroups then
		this.resetGroups()
	end
	local miscIsVisible = SheetManager.CustomStats:GetTotalStatsInCategory(nil, true) > 0 or not SheetManager.CustomStats:HasCategories()
	-- Group for stats without an assigned category
	this.addGroup(SheetManager.CustomStats.MISC_CATEGORY, miscGroupDisplayName.Value, false, miscIsVisible)
	for category in SheetManager.CustomStats:GetAllCategories() do
		local isVisible = isGM or category.ShowAlways or SheetManager.CustomStats:GetTotalStatsInCategory(category.ID, true) > 0
		this.addGroup(category.GroupId, category:GetDisplayName(), false, isVisible)
	end
	--this.positionElements(false)
	if not initializedGroups then
		this.positionElements(true, "groupId")
		initializedGroups = true
	end
end

function CustomStatsUI:UpdateAvailablePoints(ui)
	if ui == nil then
		ui = SheetManager.UI.CharacterSheet.Instance
	end
	if ui then
		local this = ui:GetRoot()
		if not this or this.isExtended ~= true then
			return
		end
		local character = Client:GetCharacter()
		local totalPoints = SheetManager.CustomStats:GetTotalAvailablePoints(character)
		if totalPoints then
			this.setAvailableCustomStatPoints(totalPoints)
			--[[ local stats = this.stats_mc.customStats_mc.stats_array
			if stats then
				for i=0,#stats-1 do
					local stats_mc = stats[i]
					if stats_mc then
						stats_mc.plus_mc.visible = self:GetCanAddPoints(ui, stats_mc.statID)
						stats_mc.minus_mc.visible = self:GetCanRemovePoints(ui, stats_mc.statID)
					end
				end
			end ]]
		end
	end
end

function CustomStatsUI:OnUpdateDone(ui, call)
	local stats_mc = ui:GetRoot().stats_mc
	local this = stats_mc.customStats_mc
	this.recountAllPoints()
	self:UpdateAvailablePoints(ui)
	if stats_mc.currentOpenPanel == 8 then
		this.positionElements()
		this.list.m_scrollbar_mc.scrollTo(lastScrollY)
	else
		this.list.m_scrollbar_mc.visible = false
	end
end

function CustomStatsUI:UpdateStatMovieClips()
	if SharedData.RegionData.State ~= REGIONSTATE.GAME or SharedData.RegionData.LevelType ~= LEVELTYPE.GAME then
		return
	end
	--TODO This returns nil if we try to get the character too early. It may also be the dummy.
	local character = SheetManager.UI.CharacterSheet.GetCharacter()
	---@type CharacterSheetMainTimeline
	local this = SheetManager.UI.CharacterSheet.Root
	if not this or this.isExtended ~= true then
		return
	end
	if this then
		if not Vars.ControllerEnabled then
			local arr = this.stats_mc.customStats_mc.stats_array
			for i=0,#arr-1 do
				local cstat_mc = arr[i]
				if cstat_mc then
					local stat = SheetManager.CustomStats:GetStatByDouble(cstat_mc.statID)
					if stat then
						local value = stat:GetValue(character)
						if value then
							cstat_mc.setValue(value)
						end
					end
				end
			end
		else
	
		end
	end
end

function CustomStatsUI:OnGroupAdded(ui, call, id, label, arrayIndex)
	local this = ui:GetRoot().stats_mc.customStats_mc
	local category = SheetManager.CustomStats:GetCategoryByGroupId(id)
	if this.groups_array then
		local group_mc = this.groups_array[arrayIndex]
		if group_mc then
			if category then
				if category.IsOpen ~= nil then
					group_mc.setIsOpen(category.IsOpen)
				end
				if category.HideTotalPoints == true then
					group_mc.hidePoints = true
					group_mc.amount_txt.visible = false
				else
					group_mc.hidePoints = false
					group_mc.amount_txt.visible = true
				end
			else
				group_mc.setIsOpen(true)
				group_mc.hidePoints = false
				group_mc.amount_txt.visible = true
			end
		end
	end
	if category and category.Description then
		this.setGroupTooltip(category.GroupId, category:GetDescription())
	end
end

function CustomStatsUI:OnGroupClicked(ui, call, arrayIndex, groupId, isOpen, groupName)
	local category = SheetManager.CustomStats:GetCategoryByGroupId(groupId)
	if category then
		category.IsOpen = isOpen
	end
end

function CustomStatsUI:OnStatRemoved(ui, call, doubleHandle)
	local uuid = SheetManager.CustomStats._Internal.RemoveStatByDouble(doubleHandle)
	if not StringHelpers.IsNullOrWhitespace(uuid) then
		local client = Client:GetCharacter()
		if client then
			client = client.MyGuid
		else
			client = ""
		end
		Ext.Net.PostMessageToServer("CEL_CustomStats_RemoveStatByUUID", Common.JsonStringify({UUID=uuid, Client=client}))
	end
end

Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "clearCustomStats", function(...) CustomStatsUI:SetupGroups(...) end)
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "customStatsGroupAdded", function(...) CustomStatsUI:OnGroupAdded(...) end)
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "characterSheetUpdateDone", function(...) CustomStatsUI:OnUpdateDone(...) end, "After")
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "customStatAdded", function(...) CustomStatsUI:OnStatAdded(...) end, "Before")
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "statCategoryCollapseChanged", function(...) CustomStatsUI:OnGroupClicked(...) end, "After")
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "removeCustomStat", function(...) CustomStatsUI:OnStatRemoved(...) end, "Before")
--Ext.RegisterUITypeCall(Data.UIType.characterSheet, "createCustomStatGroups", CustomStatsUI.SetupGroups)
--Ext.RegisterUITypeInvokeListener(Data.UIType.characterSheet, "setPlayerInfo", AdjustCustomStatMovieClips)

--Story mode changes so custom stats don't use the custom stats system, since they get added to every character apparently
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "minusCustomStatCustom", function(ui, call, statId)
	local stat = SheetManager.CustomStats:GetStatByDouble(statId)
	if stat then
		stat:ModifyValue(Client:GetCharacter(), -1)
	end
end)
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "plusCustomStatCustom", function(ui, call, statId)
	local stat = SheetManager.CustomStats:GetStatByDouble(statId)
	if stat then
		stat:ModifyValue(Client:GetCharacter(), 1)
	end
end)

---@return FlashCustomStat
function CustomStatsUI:GetStatMovieClipByDouble(ui, statId)
	if ui:GetTypeId() == Data.UIType.characterSheet then
		local character = Ext.GetCharacter(ui:GetPlayerHandle())
		local this = ui:GetRoot()
		local stats = this.stats_mc.customStats_mc.stats_array
		for i=0,#stats do
			local mc = stats[i]
			if mc and mc.statID == statId then
				return mc
			end
		end
	end
	return nil
end

function CustomStatsUI:OnStatAdded(ui, call, doubleHandle, index)
	---@type CharacterSheetMainTimeline
	local this = ui:GetRoot()

	local stat_mc = this.stats_mc.customStats_mc.stats_array[index]
	local stat = SheetManager.CustomStats:GetStatByDouble(doubleHandle)

	if stat then
		--[[
			Stat values greater than a certain amount have issues fitting into the UI, 
			so display a small version and use the tooltip to display the full value.
		]]
		if stat.DisplayMode == "Percentage" then
			stat_mc.setTextValue(string.format("%s%%", math.floor(stat_mc.am)))
		else
			if stat_mc.am > self.MaxVisibleValue then
				stat_mc.setTextValue(StringHelpers.GetShortNumberString(stat_mc.am))
			end
		end

		stat_mc.label_txt.htmlText = stat:GetDisplayName()

		SheetManager.Events.OnEntryAddedToUI:Invoke({
			ID = stat.ID,
			EntryType = "SheetCustomStatData",
			Stat = stat,
			MovieClip = stat_mc,
			Character = GameHelpers.Client.GetCharacterSheetCharacter(this),
			UI = ui,
			Root = this,
			UIType = ui.Type,
		})
	end
end

--ExternalInterface.call(param2,param1.statID,val3.x + val5,val3.y + val4,val6,param1.height,param1.tooltipAlign);

local addedCustomTab = false

local function addCustomStatsTab_Controller(ui)
	local title = GameHelpers.GetTranslatedString("ha62e1eccgc1c2g4452g8d78g65ea010f3d85", "Custom Stats")
	ui:Invoke("addStatsTab", 6, 7, title)
	addedCustomTab = true
end

Ext.RegisterUITypeInvokeListener(Data.UIType.statsPanel_c, "addStatsTab", function(ui, method, id, imageId, title)
	if not addedCustomTab and id == 5 then
		addCustomStatsTab_Controller(ui)
	end
end)

Ext.RegisterUITypeInvokeListener(Data.UIType.statsPanel_c, "selectStatsTab", function(ui, method, id, imageId, title)
	if not addedCustomTab and id == 5 then
		addCustomStatsTab_Controller(ui)
	end
end)

Events.LuaReset:Subscribe(function(e)
	if Vars.ControllerEnabled then
		local ui = Ext.UI.GetByType(Data.UIType.statsPanel_c)
		if ui then
			local tabBar_mc = ui:GetRoot().mainpanel_mc.stats_mc.tabBar_mc
			for i=0,tabBar_mc.tabList.length do
				local entry = tabBar_mc.tabList.content_array[i]
				if entry and entry.id == 6 then
					addedCustomTab = true
					break
				end
			end
		end
	end
end)

local function OnStatPointChanged(ui, call, doubleHandle, modifyBy)
	local stat = SheetManager.CustomStats:GetStatByDouble(doubleHandle)
	local stat_mc = CustomStatsUI:GetStatMovieClipByDouble(ui, doubleHandle)

	local character = SheetManager.UI.CharacterSheet.GetCharacter()
	local characterId = GameHelpers.GetNetID(character)
	if characterId and not StringHelpers.IsNullOrEmpty(stat.PointID) then
		local points = stat:GetAvailablePoints(character)
		if points then
			local character = Client:GetCharacter()
			local isGM = GameHelpers.Client.IsGameMaster()

			local lastPoints = points
			points = points + modifyBy
			
			if isGM then
				stat_mc.plus_mc.visible = true
				stat_mc.minus_mc.visible = true
			else
				stat_mc.plus_mc.visible = SheetManager:GetIsPlusVisible(stat, character, points > 0)
				stat_mc.minus_mc.visible = false
			end

			if lastPoints ~= points then
				SheetManager:ModifyAvailablePointsForEntry(stat, character, points)
			end
		end
	end
end

local function OnStatPointAdded(ui, call, doubleHandle)
	OnStatPointChanged(ui, call, doubleHandle, 1)
end

local function OnStatPointRemoved(ui, call, doubleHandle)
	OnStatPointChanged(ui, call, doubleHandle, -1)
end

Ext.RegisterUITypeCall(Data.UIType.characterSheet, "plusCustomStat", OnStatPointAdded, "After")
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "minusCustomStat", OnStatPointRemoved, "After")