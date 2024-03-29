--local function ActuallySetCharacterHandle(ui, this, player, uiType, uiName)
local function ActuallySetCharacterHandle(ui, call)
	local player = Client:GetCharacter()
	if player then
		local doubleHandle = Ext.UI.HandleToDouble(player.Handle)
		local this = ui:GetRoot()
		this.characterHandle = doubleHandle
		this.charHandle = doubleHandle
	end
end

local uiTypes = {Data.UIType.characterCreation, Data.UIType.characterCreation_c, Data.UIType.characterSheet, Data.UIType.statsPanel_c}
-- UI.RegisterUICreatedListener(uiTypes, ActuallySetCharacterHandle)

Ext.RegisterUINameCall("characterCreationStarted", ActuallySetCharacterHandle, "After")

local function UpdateSheetHandlesAfterHotbar(hotBar, event, doubleHandle)
	if doubleHandle ~= nil and doubleHandle ~= 0 then
		for i=1,#uiTypes do
			local ui = Ext.UI.GetByType(uiTypes[i])
			if ui then
				local this = ui:GetRoot()
				if this then
					this.characterHandle = doubleHandle
				end
				--ui:SetValue("characterHandle", doubleHandle)
			end
		end
	end
end
Ext.RegisterUITypeInvokeListener(Data.UIType.hotBar, "setPlayerHandle", UpdateSheetHandlesAfterHotbar)
Ext.RegisterUITypeInvokeListener(Data.UIType.bottomBar_c, "setPlayerHandle", UpdateSheetHandlesAfterHotbar)
Ext.RegisterUITypeInvokeListener(Data.UIType.GMPanelHUD, "showTargetBar", function(ui, event, enabled, doubleHandle, posBtnEnabled)
	UpdateSheetHandlesAfterHotbar(ui, event, doubleHandle)
end)