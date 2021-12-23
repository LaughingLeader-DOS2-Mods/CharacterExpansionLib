local isVisible = false
local lastTooltipX = nil
local lastTooltipY = nil

Game.Tooltip.RegisterBeforeNotifyListener("CustomStat", function(request, ui, method, tooltip, ...)
	if request.RequestUpdate then
		SheetManager.CustomStats:UpdateStatTooltipArray(ui, request.Stat, tooltip, request)
		request.RequestUpdate = false
	end
end)

Game.Tooltip.RegisterRequestListener("Ability", function(request, ui, uiType, event, id, statOrWidth, ...)
	local stat = SheetManager:GetEntryByGeneratedID(id, "Ability")
	if stat then
		request.Ability = stat.ID
	end
end, "before")

Game.Tooltip.RegisterRequestListener("Talent", function(request, ui, uiType, event, id, statOrWidth, ...)
	local stat = SheetManager:GetEntryByGeneratedID(id, "Talent")
	if stat then
		request.Talent = stat.ID
	end
end, "before")

Game.Tooltip.RegisterRequestListener("CustomStat", function(request, ui, uiType, event, id, statOrWidth, ...)
	SheetManager.CustomStats:OnRequestTooltip(ui, event, request.Stat, request.Character, ...)
end, "after")

Game.Tooltip.RegisterListener("CustomStat", nil, function(character, statData, tooltip)
	SheetManager.CustomStats:OnTooltip(tooltip.Instance, character, statData, tooltip)
end)

local function CreateTooltip(tooltipType, requestedUI, call, idOrCharacter, idOrOther)
	local targetSide = "left"
	local id = idOrCharacter
	local requestedUIType = requestedUI:GetTypeId()
	if requestedUIType == Data.UIType.characterCreation or requestedUIType == Data.UIType.characterCreation_c then
		id = idOrOther
		targetSide = "right"
	end
	local ui = Ext.GetUIByType(Data.UIType.tooltip)
	if ui then
		local this = ui:GetRoot()
		local data = SheetManager:GetEntryByGeneratedID(id, tooltipType)
		if this and this.tooltip_array and data then
			local request = {
				Type = data.TooltipType,
				Character = SheetManager.UI.CharacterSheet.GetCharacter()
			}

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
			end

			if not resolved then
				this.tooltip_array[0] = Game.Tooltip.TooltipItemTypes.StatName
				this.tooltip_array[1] = data:GetDisplayName()
				this.tooltip_array[2] = Game.Tooltip.TooltipItemTypes.StatsDescription
				this.tooltip_array[3] = data:GetDescription()
				-- request.Text = this.tooltip_array[3]
				-- request.Type = "Generic"
				-- request.CallingUI = ui:GetTypeId()
			end

			Game.Tooltip.TooltipHooks.NextRequest = request
			Game.Tooltip.TooltipHooks.Last.Event = call
			Game.Tooltip.TooltipHooks.Last.UIType = requestedUI:GetTypeId()

			isVisible = true

			local tf = this.formatTooltip
			if tf then
				lastTooltipX = tf.x
				lastTooltipY = tf.y
			end

			ui:ExternalInterfaceCall("setAnchor", targetSide, "mouse", targetSide)
			ui:Invoke("addFormattedTooltip",0,0,true)
			local tf = this.formatTooltip or this.tf
			if tf then
				tf.x = 50
				tf.y = 90
			end
		end
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

for t,v in pairs(SheetManager.Config.Calls.Tooltip) do
	local func = function(...)
		CreateTooltip(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.characterSheet, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation, v, func, "Before")
end
for t,v in pairs(SheetManager.Config.Calls.TooltipController) do
	local func = function(...)
		CreateTooltip(t, ...)
	end
	Ext.RegisterUITypeCall(Data.UIType.statsPanel_c, v, func, "Before")
	Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, v, func, "Before")
end