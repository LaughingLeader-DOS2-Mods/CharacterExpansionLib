---@class CharacterExpansionLibPersistentVars
local defaultPersistentVars = {
	---Used in story mode for storing values, since CustomStats get added to everything.
	---@type table<Guid,table<string,integer>>
	CustomStatValues = {},
	---@type table<Guid,table<string,integer>>
	CustomStatAvailablePoints = {},
	---@type table<Guid, table<SheetEntryId,table<ModGuid, table<string, integer|boolean>>>>
	CharacterSheetValues = {},
}

Ext.Require("Shared.lua")
Ext.Require("CharacterCreationExtended/Init.lua")

---@type CharacterExpansionLibPersistentVars
PersistentVars = GameHelpers.PersistentVars.Initialize(Mods.CharacterExpansionLib, defaultPersistentVars, function ()
	PersistentVars = GameHelpers.PersistentVars.Update(defaultPersistentVars, PersistentVars)
end)

Events.TemporaryCharacterRemoved:Subscribe(function (e)
	SheetManager.Save.RemoveCharacterData(e.CharacterGUID)
	if e.NetID then
		GameHelpers.Net.Broadcast("CEL_SheetManager_ClearCharacterData", {NetID=e.NetID})
	end
end)