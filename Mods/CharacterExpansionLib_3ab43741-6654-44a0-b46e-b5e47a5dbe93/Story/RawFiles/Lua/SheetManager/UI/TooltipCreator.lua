local isVisible = false
local lastTooltipX = nil
local lastTooltipY = nil

Game.Tooltip.RegisterRequestListener("Stat", function(request, ui, uiType, event, id, statOrWidth, ...)
	local stat = SheetManager:GetEntryByGeneratedID(id, "Stat")
	if stat then
		request.Stat = stat.ID
	end
end, "Before")

Game.Tooltip.RegisterRequestListener("Ability", function(request, ui, uiType, event, id, statOrWidth, ...)
	local stat = SheetManager:GetEntryByGeneratedID(id, "Ability")
	if stat then
		request.Ability = stat.ID
	end
end, "Before")

Game.Tooltip.RegisterRequestListener("Talent", function(request, ui, uiType, event, id, statOrWidth, ...)
	local stat = SheetManager:GetEntryByGeneratedID(id, "Talent")
	if stat then
		request.Talent = stat.ID
	end
end, "Before")

Game.Tooltip.RegisterRequestListener("CustomStat", function(request, ui, uiType, event, id, statOrWidth, ...)
	local stat = SheetManager:GetEntryByGeneratedID(id, "Custom")
	if stat then
		request.Stat = stat.ID
		request.StatData = stat
	end
end, "After")

-- Game.Tooltip.RegisterBeforeNotifyListener("CustomStat", function(request, ui, method, tooltip, ...)
-- 	if request.RequestUpdate or type(request.Stat) ~= "table" then
-- 		SheetManager.CustomStats:UpdateStatTooltipArray(ui, request.Stat, tooltip, request)
-- 		request.RequestUpdate = false
-- 	end
-- end)

-- Game.Tooltip.RegisterListener("CustomStat", nil, function(character, statData, tooltip)
-- 	SheetManager.CustomStats:OnTooltip(tooltip.Instance, character, statData, tooltip)
-- end)

local _nextTooltip = nil

local function CheckCreateTooltip(tooltipType, requestedUI, call, idOrCharacter, idOrOther, y, width, height, side)
	local id = idOrCharacter
	local requestedUIType = requestedUI.Type
	if requestedUIType == Data.UIType.characterCreation or requestedUIType == Data.UIType.characterCreation_c then
		id = idOrOther
	end
	local data = SheetManager:GetEntryByGeneratedID(id, tooltipType)
	if data then
		if not Vars.ControllerEnabled then
			_nextTooltip = {
				ID = id,
				TooltipType = tooltipType,
				UIType = requestedUI.Type,
				X = idOrOther,
				Y = y,
				Width = width,
				Height = height,
				Side = side
			}
		else
			_nextTooltip = {
				ID = id,
				TooltipType = tooltipType,
				UIType = requestedUI.Type
			}
		end

		return true
	end
	return false
end

local function CreateTooltip(ui, call, idOrCharacter, idOrOther)
	if not _nextTooltip then
		return
	end
	local id = _nextTooltip.ID
	local tooltipType = _nextTooltip.TooltipType
	local requestingUIType = _nextTooltip.UIType
	_nextTooltip = nil

	local this = ui:GetRoot()

	this.isStatusTT = true
	this.addStatusTooltip() -- Clear tooltip_array
	this.isStatusTT = false

	local data = SheetManager:GetEntryByGeneratedID(id, tooltipType)
	if this and this.tooltip_array and data then
		local request = Game.Tooltip.RequestProcessor.CreateRequest()
		local character = GameHelpers.Client.GetCharacterSheetCharacter(this)
		request.Type = data.TooltipType
		request.CharacterNetID = character.NetID

		local resolved = false
		if tooltipType == "Ability" then
			this.tooltip_array[0] = Game.Tooltip.TooltipItemTypes.StatName
			this.tooltip_array[1] = data:GetDisplayName()
			this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.AbilityDescription
			this.tooltip_array[3] = data.GeneratedID
			this.tooltip_array[4] = data:GetDescription()
			this.tooltip_array[5] = ""
			this.tooltip_array[6] = ""
			this.tooltip_array[7] = ""

			request.Ability = data.ID

			if not StringHelpers.IsNullOrWhitespace(data.Icon) then
				Game.Tooltip.PrepareIcon(ui, string.format("tt_ability_%i", data.GeneratedID), data.Icon, data.IconWidth or 128, data.IconHeight or 128)
			end
			resolved = true
		elseif tooltipType == "Talent" then
			this.tooltip_array[0] = Game.Tooltip.TooltipItemTypes.StatName
			this.tooltip_array[1] = data:GetDisplayName()
			--TalentDescription = {{"TalentId", "number"}, {"Description", "string"}, {"Requirement", "string"}, {"IncompatibleWith", "string"}, {"Selectable", "boolean"}, {"Unknown", "boolean"}},
			this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.TalentDescription
			this.tooltip_array[3] = data.GeneratedID
			this.tooltip_array[4] = data:GetDescription()
			this.tooltip_array[5] = ""
			this.tooltip_array[6] = ""
			this.tooltip_array[7] = true
			this.tooltip_array[8] = true

			request.Talent = data.ID

			if not StringHelpers.IsNullOrWhitespace(data.Icon) then
				Game.Tooltip.PrepareIcon(ui, string.format("tt_talent_%i", data.GeneratedID), data.Icon, data.IconWidth or 128, data.IconHeight or 128)
			end
			resolved = true
		elseif tooltipType == "Stat" or tooltipType == "PrimaryStat" or tooltipType == "SecondaryStat" then
			this.tooltip_array[0] = Game.Tooltip.TooltipItemTypes.StatName
			this.tooltip_array[1] = data:GetDisplayName()

			if not StringHelpers.IsNullOrWhitespace(data.Icon) then
				this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.AbilityDescription
				this.tooltip_array[3] = data.GeneratedID
				this.tooltip_array[4] = data:GetDescription()
				this.tooltip_array[5] = ""
				this.tooltip_array[6] = ""
				this.tooltip_array[7] = ""
				Game.Tooltip.PrepareIcon(ui, string.format("tt_ability_%i", data.GeneratedID), data.Icon, data.IconWidth or 128, data.IconHeight or 128)
			else
				this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.StatsDescription
				this.tooltip_array[3] = data:GetDescription()
			end

			request.Stat = data.ID
			resolved = true
		elseif tooltipType == "Custom" then
			---@cast data SheetCustomStatData
			---@cast data +UnregisteredCustomStatData

			request.StatData = data
			request.Stat = data.ID
			local description = data:GetDescription()
			if data.DisplayValueInTooltip then
				local value = data:GetValue(character)
				local valueFormatted = StringHelpers.CommaNumber(value)
				local total = GameHelpers.GetTranslatedString("h79b967bcg4197g498fgb1dcged15f69f7913", "Total")
				local text = string.format("<font color='#11D77A'>%s: %s%s</font>", total, valueFormatted, data.DisplayMode == data.STAT_DISPLAY_MODE.Percentage and "%" or "")
				if not StringHelpers.IsNullOrWhitespace(text) then
					description = string.format("%s<br>%s", description, text)
				end
			end

			if not StringHelpers.IsNullOrWhitespace(data.Icon) then
				this.tooltip_array[0] = Game.Tooltip.TooltipItemTypes.StatName
				this.tooltip_array[1] = data:GetDisplayName()
				if tooltipType == Game.Tooltip.TooltipItemTypes.Tag then
					this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.TagDescription
					this.tooltip_array[3] = description
					this.tooltip_array[4] = ""
					Game.Tooltip.PrepareIcon(ui, string.format("tt_tag_%i", data.GeneratedID), data.Icon, data.IconWidth or 128, data.IconHeight or 128)
				else
					this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.AbilityDescription
					this.tooltip_array[3] = data.GeneratedID
					this.tooltip_array[4] = description
					this.tooltip_array[5] = ""
					this.tooltip_array[6] = ""
					this.tooltip_array[7] = ""

					Game.Tooltip.PrepareIcon(ui, string.format("tt_ability_%i", data.GeneratedID), data.Icon, data.IconWidth or 128, data.IconHeight or 128)
				end
				resolved = true
			end

			if not resolved then
				this.tooltip_array[0] = Game.Tooltip.TooltipItemTypes.StatName
				this.tooltip_array[1] = data:GetDisplayName()
				this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.StatsDescription
				this.tooltip_array[3] = description
				resolved = true
			end
		end

		if not resolved then
			this.tooltip_array[0] = Game.Tooltip.TooltipItemTypes.StatName
			this.tooltip_array[1] = data:GetDisplayName()
			this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.StatsDescription
			this.tooltip_array[3] = data:GetDescription()
		end

		Game.Tooltip.TooltipHooks.NextRequest = request
		Game.Tooltip.TooltipHooks.Last.Event = call
		Game.Tooltip.TooltipHooks.Last.UIType = requestingUIType

		isVisible = true
	end
end

local function HideTooltip(callingUI, call)
	if isVisible then
		isVisible = false
		local ui = Ext.GetUIByType(Data.UIType.tooltip)
		if ui then
			ui:Invoke("removeTooltip")
			if lastTooltipX and lastTooltipY then
				local this = ui:GetRoot()
				local tf = this.formatTooltip
				if tf then
					tf.x = lastTooltipX
					tf.y = lastTooltipY
					lastTooltipX = nil
					lastTooltipY = nil
				end
			end
		end
	end
end

Ext.RegisterUINameCall("hideTooltip", HideTooltip, "Before")
Ext.RegisterUITypeCall(Data.UIType.characterSheet, "hideUI", HideTooltip, "Before")
Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, "hideUI", HideTooltip, "Before")
Ext.RegisterUITypeInvokeListener(Data.UIType.hotBar, "setButtonActive", function(ui, method, buttonId, isActive)
	if buttonId == 1 and not isActive then
		HideTooltip(ui, method)
	end
end)

local blockNextPropagation = nil

Ext.Events.SessionLoaded:Subscribe(function (e)
	if not Vars.ControllerEnabled then
		Ext.Events.UICall:Subscribe(function (e)
			if e.When == "Before" then
				if blockNextPropagation and e.Function == blockNextPropagation then
					Ext.PrintError("Blocking propagation for", blockNextPropagation)
					e:StopPropagation()
					blockNextPropagation = nil
					return
				end
				local t = SheetManager.Config.CustomCallToTooltipType[e.Function]
				if t then
					local id = e.Args[1]
					local x = e.Args[2] or 0
					local y = e.Args[3] or 0
					local width = e.Args[4] or 0
					local height = e.Args[5] or 0
					local side = e.Args[6]
					if CheckCreateTooltip(t, e.UI, e.Function, id,x,y,width,height,side) then
						e:StopPropagation()
						blockNextPropagation = SheetManager.Config.BaseCalls.Tooltip[t]
						if t == "Custom" then
							blockNextPropagation = SheetManager.Config.BaseCalls.Tooltip.Stat
						end
						if side then
							e.UI:ExternalInterfaceCall(blockNextPropagation, 0, x, y, width, height, side)
						else
							e.UI:ExternalInterfaceCall(blockNextPropagation, 0, x, y, width, height)
						end
					end
				end
			end
		end, {Priority=9998})

		Ext.Events.UIInvoke:Subscribe(function (e)
			if _nextTooltip and e.When == "Before" and e.UI.Type == 44 and e.Function == "addFormattedTooltip" then
				Ext.PrintError("Creating tooltip for", Ext.DumpExport(_nextTooltip))
				CreateTooltip(e.UI, e.Function)
			end
		end, {Priority=9999})
	end
end, {Priority=0})

-- for t,v in pairs(SheetManager.Config.Calls.Tooltip) do
-- 	local func = function(...)
-- 		CreateTooltip(t, ...)
-- 	end
-- 	Ext.RegisterUITypeCall(Data.UIType.characterSheet, v, func, "Before")
-- 	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
-- end
-- for t,v in pairs(SheetManager.Config.Calls.TooltipController) do
-- 	local func = function(...)
-- 		CreateTooltip(t, ...)
-- 	end
-- 	Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, v, func, "Before")
-- 	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
-- end