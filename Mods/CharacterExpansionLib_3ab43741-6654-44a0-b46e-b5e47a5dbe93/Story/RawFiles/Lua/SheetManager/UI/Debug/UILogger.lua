local logLines = {
	cc = {},
	inventory = {},
	tutorialBox = {},
}

local function SaveLogs()
	Ext.IO.SaveFile("Logs/UI_characterCreation_EventLog.log", StringHelpers.Join("\n", logLines.cc))
	Ext.IO.SaveFile("Logs/UI_partyInventory_EventLog.log", StringHelpers.Join("\n", logLines.inventory))
	Ext.IO.SaveFile("Logs/UI_tutorialBox_EventLog.log", StringHelpers.Join("\n", logLines.tutorialBox))
end

Ext.Events.UICall:Subscribe(function (e)
	if e.When == "After" then
		local id = e.UI.Type
		if id == Data.UIType.characterCreation then
			logLines.cc[#logLines.cc+1] = string.format("[%s(call)] (%s)", e.Function, StringHelpers.DebugJoin(", ", e.Args))
			Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
		elseif id == Data.UIType.partyInventory then
			logLines.inventory[#logLines.inventory+1] = string.format("[%s(call)] (%s)", e.Function, StringHelpers.DebugJoin(", ", e.Args))
			Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
		elseif id == Data.UIType.tutorialBox then
			logLines.tutorialBox[#logLines.tutorialBox+1] = string.format("[%s(call)] (%s)", e.Function, StringHelpers.DebugJoin(", ", e.Args))
			Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
		end
	end
end)

Ext.Events.UIInvoke:Subscribe(function(e)
	if e.When == "After" then
		local id = e.UI.Type
		if id == Data.UIType.characterCreation then
			logLines.cc[#logLines.cc+1] = string.format("[%s(method)] (%s)", e.Function, StringHelpers.DebugJoin(", ", e.Args))
			Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
		elseif id == Data.UIType.partyInventory then
			logLines.inventory[#logLines.inventory+1] = string.format("[%s(method)] (%s)", e.Function, StringHelpers.DebugJoin(", ", e.Args))
			Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
		elseif id == Data.UIType.tutorialBox then
			logLines.tutorialBox[#logLines.tutorialBox+1] = string.format("[%s(method)] (%s)", e.Function, StringHelpers.DebugJoin(", ", e.Args))
			Timer.StartOneshot("CEL_Debug_SaveUILogs", 250, SaveLogs)
		end
	end
end)