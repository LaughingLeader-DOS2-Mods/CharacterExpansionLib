Ext.Require("BootstrapShared.lua")
Ext.Require("CharacterCreationExtended/Init.lua")

---@class CharacterExpansionLibPersistentVars
local defaultPersistentVars = {
	---Used in story mode for storing values, since CustomStats get added to everything.
	---@type table<UUID,table<string,integer>>
	CustomStatValues = {},
	---@type table<UUID,table<string,integer>>
	CustomStatAvailablePoints = {},
	---@type table<SHEET_ENTRY_ID,table<UUID, integer|boolean>>
	CharacterSheetValues = {},
}

---@private
---@type CharacterExpansionLibPersistentVars
PersistentVars = Common.CloneTable(defaultPersistentVars, true)

RegisterListener("PersistentVarsLoaded", function()
    Common.InitializeTableFromSource(PersistentVars, defaultPersistentVars)
end)