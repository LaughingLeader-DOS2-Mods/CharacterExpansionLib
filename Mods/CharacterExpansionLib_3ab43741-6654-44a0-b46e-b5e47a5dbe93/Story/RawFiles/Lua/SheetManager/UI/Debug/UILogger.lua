local logLines = {
	cc = {},
	inventory = {},
	tutorialBox = {},
}

local function SaveLogs()
	Ext.SaveFile("Logs/UI_characterCreation_EventLog.log", StringHelpers.Join("\n", logLines.cc))
	Ext.SaveFile("Logs/UI_partyInventory_EventLog.log", StringHelpers.Join("\n", logLines.inventory))
	Ext.SaveFile("Logs/UI_tutorialBox_EventLog.log", StringHelpers.Join("\n", logLines.tutorialBox))
end

---@param ui UIObject
Ext.RegisterListener("UICall", function(ui, event, state, ...)
	local id = ui:GetTypeId()
	if id == Data.UIType.characterCreation then
		logLines.cc[#logLines.cc+1] = string.format("[%s(call)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
	elseif id == Data.UIType.partyInventory then
		logLines.inventory[#logLines.inventory+1] = string.format("[%s(call)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
	elseif id == Data.UIType.tutorialBox then
		logLines.tutorialBox[#logLines.tutorialBox+1] = string.format("[%s(call)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
	end
end)

Ext.RegisterListener("UIInvoke", function(ui, event, state, ...)
	local id = ui:GetTypeId()
	if id == Data.UIType.characterCreation then
		logLines.cc[#logLines.cc+1] = string.format("[%s(method)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
	elseif id == Data.UIType.partyInventory then
		logLines.inventory[#logLines.inventory+1] = string.format("[%s(method)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
	elseif id == Data.UIType.tutorialBox then
		logLines.tutorialBox[#logLines.tutorialBox+1] = string.format("[%s(method)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
	end
end)