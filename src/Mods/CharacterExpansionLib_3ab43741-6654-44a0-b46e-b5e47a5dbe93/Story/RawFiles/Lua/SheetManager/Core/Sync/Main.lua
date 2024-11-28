local self = SheetManager
local _ISCLIENT = Ext.IsClient()

---Functions related to data that gets saved to PersistentVars.
SheetManager.Save = {}
---Functions for data syncing.
SheetManager.Sync = {}

---@class SheetManagerSyncDataOptions
---@field DeleteSession boolean Delete the current SessionManager session on the client.
---@field SetValueOptions SheetManagerSetEntryValueOptions
local _DefaultSheetManagerSyncDataOptions = {
	DeleteSession = false
}

---Sync all current values and available points for a specific character, or all characters if nil.
---@param character? Guid|EsvCharacter|EclCharacter
---@param opts? SheetManagerSyncDataOptions
function SheetManager:SyncData(character, opts)
	local options = TableHelpers.SetDefaultOptions(opts, _DefaultSheetManagerSyncDataOptions)
	if SheetManager.Loaded ~= true then
		return false
	end
	if not _ISCLIENT then
		SheetManager.Sync.EntryValues(character, options)
		SheetManager.Sync.CustomAvailablePoints(character)
		if character ~= nil then
			SessionManager:SyncSession(character)
			GameHelpers.Net.PostToUser(GameHelpers.GetUserID(character), "CEL_SheetManager_NotifyDataSynced", "")
		else
			GameHelpers.Net.Broadcast("CEL_SheetManager_NotifyDataSynced", "")
		end
	elseif character then
		GameHelpers.Net.PostMessageToServer("CEL_SheetManager_RequestCharacterSync", GameHelpers.GetNetID(character))
	end
end

if not _ISCLIENT then
	RegisterNetListener("CEL_SheetManager_RequestCharacterSync", function(cmd, payload)
		local netid = tonumber(payload)
		if netid then
			local character = GameHelpers.GetCharacter(netid, "EsvCharacter")
			if character then
				SheetManager:SyncData(character)
			end
		end
	end)
else
	---@private
	function SheetManager:OnDataSynced()
		if SheetManager.UI.CharacterCreation.IsOpen then
			SheetManager.UI.CharacterCreation.UpdateAttributes(SheetManager.UI.CharacterCreation)
			SheetManager.UI.CharacterCreation.UpdateAbilities(SheetManager.UI.CharacterCreation)
			SheetManager.UI.CharacterCreation.UpdateTalents(SheetManager.UI.CharacterCreation)
		elseif SheetManager.UI.CharacterSheet.IsOpen then
			-- SheetManager.UI.CharacterSheet.UpdateAttributes()
			-- SheetManager.UI.CharacterSheet.UpdateAbilities()
			-- SheetManager.UI.CharacterSheet.UpdateTalents()
		end
	end

	RegisterNetListener("CEL_SheetManager_NotifyDataSynced", function()
		SheetManager:OnDataSynced()
	end)
end