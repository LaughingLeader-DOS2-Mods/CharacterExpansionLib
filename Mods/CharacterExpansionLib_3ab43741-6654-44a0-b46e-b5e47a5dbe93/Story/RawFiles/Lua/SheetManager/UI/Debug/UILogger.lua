local ccLog = {}

local function SaveCCLog()
	Ext.SaveFile("Logs/CC_UI_EventLog.log", StringHelpers.Join("\n", ccLog))
end

---@param ui UIObject
Ext.RegisterListener("UICall", function(ui, event, state, ...)
	if ui:GetTypeId() == Data.UIType.characterCreation then
		ccLog[#ccLog+1] = string.format("[%s(call)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveCCUILog", 250, SaveCCLog)
	end
end)

Ext.RegisterListener("UIInvoke", function(ui, event, state, ...)
	if ui:GetTypeId() == Data.UIType.characterCreation then
		ccLog[#ccLog+1] = string.format("[%s(method)] (%s)", event, StringHelpers.DebugJoin(", ", {...}))
		Timer.StartOneshot("CEL_Debug_SaveCCUILog", 250, SaveCCLog)
	end
end)