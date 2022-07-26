Ext.Require("BootstrapShared.lua")

Ext.Require("SheetManager/UI/CharacterCreation.lua")
Ext.Require("SheetManager/UI/CharacterSheet.lua")
Ext.Require("SheetManager/UI/Fixes.lua")
Ext.Require("SheetManager/UI/TooltipCreator.lua")
Ext.Require("SheetManager/UI/ValueChangedHandler.lua")
Ext.Require("SheetManager/UI/CustomStatsUI.lua")

Ext.Require("CharacterCreationExtended/Init.lua")

-- if Ext.IsDeveloperMode() then
--     Ext.Require("SheetManager/UI/Debug/UILogger.lua")
-- end

local overridePath = "Public/CharacterExpansionLib_3ab43741-6654-44a0-b46e-b5e47a5dbe93/GUI/Overrides/"

UIOverrides = {
	Files = {
		characterSheet = {Source = "Public/Game/GUI/characterSheet.swf", Replacement = overridePath .. "characterSheet.swf"},
		characterCreation = {Source = "Public/Game/GUI/characterCreation.swf", Replacement = overridePath .. "characterCreation.swf"},
		--statsPanel_c = {Source = "Public/Game/GUI/statsPanel_c.swf", Replacement = overridePath .. "statsPanel_c.swf"},
		--characterCreation_c = {Source = "Public/Game/GUI/characterCreation_c.swf", Replacement = overridePath .. "characterCreation_c.swf"},
	},
	Enable = function(force)
		for k,v in pairs(UIOverrides.Files) do
			local currentPath = Ext.IO.GetPathOverride(v.Source)
			if not currentPath or currentPath == v.Source or force then
				Ext.IO.AddPathOverride(v.Source, v.Replacement)
            --The currentPath may be the full path including the drive letter, so string.find helps with checking that.
			elseif currentPath ~= v.Replacement and not string.find(currentPath, v.Replacement, 1, true) then
				Ext.PrintError(string.format("[CharacterExpansionLib] UI file (%s) is already being overwritten! Mod conflict! The replacement path is (%s).", k, currentPath))
			end
		end
	end
}

UIOverrides.Enable(Ext.IsDeveloperMode())

-- Ext.RegisterListener("SessionLoading", function ()
--  UIOverrides.Enable(Ext.IsDeveloperMode())
-- end)

-- RegisterListener("LuaReset", function ()
--     UIOverrides.Enable(Ext.IsDeveloperMode())
-- end)


Ext.RegisterConsoleCommand("abilityTest", function(cmd, enabled)
    if enabled == "false" then
        SheetManager.Abilities.DisableAbility("all", ModuleUUID)
    else
        SheetManager.Abilities.EnableAbility("all", ModuleUUID)
    end
end)

local registeredContextListeners = false
Ext.RegisterConsoleCommand("contextRollTest", function()
    if not registeredContextListeners then
        UI.ContextMenu.Register.ShouldOpenListener(function(contextMenu, x, y)
            if Game.Tooltip.RequestTypeEquals("CustomStat") then
                return true
            end
        end)
        
        --[[ UI.ContextMenu.Register.OpeningListener(function(contextMenu, x, y)
            if Game.Tooltip.RequestTypeEquals("CustomStat") and Game.Tooltip.IsOpen() then
                ---@type TooltipCustomStatRequest
                local request = Game.Tooltip.GetCurrentOrLastRequest()
                local characterId = request.Character.NetID
                local modId = nil
                local statId = request.Stat
                if request.StatData then
                    modId = request.StatData.Mod
                    statId = request.StatData.ID
                end
                contextMenu:AddEntry("RollCustomStat", function(cMenu, ui, id, actionID, handle)
                    CustomStatSystem:RequestStatChange(statId, characterId, Ext.Random(1,10), modId)
                end, "<font color='#33AA33'>Roll</font>")
            end
        end) ]]
        
        UI.ContextMenu.Register.EntryClickedListener(function(...)
            --fprint(LOGLEVEL.DEFAULT, "[ContextMenu.EntryClickedListener] %s", Lib.inspect({...}))
        end)

        registeredContextListeners = true
    end
end)