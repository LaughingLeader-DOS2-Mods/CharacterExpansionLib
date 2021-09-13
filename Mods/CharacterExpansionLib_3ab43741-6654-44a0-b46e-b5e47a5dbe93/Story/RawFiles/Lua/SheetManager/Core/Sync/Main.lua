local self = SheetManager
local isClient = Ext.IsClient()

---Functions related to data that gets saved to PersistentVars.
SheetManager.Save = {}
---Functions for data syncing.
SheetManager.Sync = {}

if not isClient then
	---Sync all current values and available points for a specific character, or all characters if nil.
	---@param character UUID|EsvCharacter
	---@param user integer|nil
	function SheetManager:SyncData(character)
		SheetManager.Sync.EntryValues(character)
		SheetManager.Sync.AvailablePoints(character)
		if character ~= nil then
			SheetManager.SessionManager:SyncSession(character)
			Ext.PostMessageToClient(GameHelpers.GetCharacterID(character), "CEL_SheetManager_NotifyDataSynced", "")
		else
			Ext.BroadcastMessage("CEL_SheetManager_NotifyDataSynced", "")
		end
	end
else
	---@private
	function SheetManager:OnDataSynced()
		if SheetManager.UI.CharacterCreation.IsOpen then
			SheetManager.UI.CharacterCreation:UpdateAttributes()
			SheetManager.UI.CharacterCreation:UpdateAbilities()
			SheetManager.UI.CharacterCreation:UpdateTalents()
		end
	end

	RegisterNetListener("CEL_SheetManager_NotifyDataSynced", function()
		SheetManager:OnDataSynced()
	end)
end