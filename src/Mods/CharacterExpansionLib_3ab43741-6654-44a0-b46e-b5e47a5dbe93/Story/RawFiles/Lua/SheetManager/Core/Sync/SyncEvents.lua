local isClient = Ext.IsClient()

if not isClient then
	Ext.Osiris.RegisterListener("CharacterLeveledUp", 1, "after", function(uuid)
		if GameHelpers.Character.IsPlayer(uuid) then
			SheetManager:SyncData(uuid)
		end
	end)
	
	Ext.RegisterConsoleCommand("addpoints", function()
		SheetManager:SyncData()
	end)
end