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

local function CheckCreateTooltip(requestType, requestedUI, call, id, x, y, width, height, side)
	local data = SheetManager:GetEntryByGeneratedID(id, requestType)
	if data then
		if not Vars.ControllerEnabled then
			_nextTooltip = {
				RequestType = requestType,
				UIType = requestedUI.Type,
				ID = id,
				X = x,
				Y = y,
				Width = width,
				Height = height,
				Side = side
			}
		else
			_nextTooltip = {
				RequestType = requestType,
				UIType = requestedUI.Type,
				ID = id,
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
	local requestType = _nextTooltip.RequestType
	local requestingUIType = _nextTooltip.UIType
	_nextTooltip = nil

	local this = ui:GetRoot()

	this.isStatusTT = true
	this.addStatusTooltip() -- Clear tooltip_array
	this.isStatusTT = false

	local data = SheetManager:GetEntryByGeneratedID(id, requestType)
	if this and this.tooltip_array and data then
		local request = Game.Tooltip.RequestProcessor.CreateRequest()
		local character = GameHelpers.Client.GetCharacterSheetCharacter(this)
		local tooltipType = data.TooltipType
		request.Type = requestType
		request.ObjectHandleDouble = Ext.UI.HandleToDouble(character.Handle)

		local resolved = false
		if requestType == "Ability" then
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
		elseif requestType == "Talent" then
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
		elseif requestType == "Stat" then
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
		elseif requestType == "CustomStat" then
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
					e:StopPropagation()
					blockNextPropagation = nil
					return
				end
				local t = SheetManager.Config.CustomCallToTooltipRequestType[e.Function]
				if t then
					Ext.Dump(e.Args)
					local args = {table.unpack(e.Args)}
					local characterDouble = nil
					if e.UI.Type == Data.UIType.characterCreation then
						--Pop the characterHandle arg so we don't go crazy
						characterDouble = args[1]
						table.remove(args, 1)
					end
					local id = args[1] or 0
					local x = args[2] or 0
					local y = args[3] or 0
					local width = args[4] or 0
					local height = args[5] or 0
					local side = args[6] or "left"
					if CheckCreateTooltip(t, e.UI, e.Function, id, x, y, width, height, side) then
						e:StopPropagation()
						blockNextPropagation = SheetManager.Config.BaseCalls.Tooltip[t]
						if t == "CustomStat" then
							blockNextPropagation = SheetManager.Config.BaseCalls.Tooltip.Stat
						end
						if not characterDouble then
							e.UI:ExternalInterfaceCall(blockNextPropagation, 0, x, y, width, height, side)
						else
							_nextTooltip.CharacterDouble = characterDouble
							e.UI:ExternalInterfaceCall(blockNextPropagation, characterDouble, 0, x, y, width, height, side)
						end
					end
				end
			end
		end, {Priority=9998})

		Ext.Events.UIInvoke:Subscribe(function (e)
			if _nextTooltip and e.When == "Before" and e.UI.Type == 44 and e.Function == "addFormattedTooltip" then
				CreateTooltip(e.UI, e.Function)
			end
		end, {Priority=9999})
	end
end, {Priority=0})