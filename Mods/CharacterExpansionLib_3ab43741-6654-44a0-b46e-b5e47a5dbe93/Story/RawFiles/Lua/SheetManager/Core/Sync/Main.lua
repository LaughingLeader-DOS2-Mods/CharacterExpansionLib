local self = SheetManager
local isClient = Ext.IsClient()

---Functions related to data that gets saved to PersistentVars.
SheetManager.Save = {}
---Functions for data syncing.
SheetManager.Sync = {}

---Sync all current values and available points for a specific character, or all characters if nil.
---@param character UUID|EsvCharacter
---@param user integer|nil
function SheetManager:SyncData(character)
	if not isClient then
		SheetManager.Sync.EntryValues(character)
		SheetManager.Sync.AvailablePoints(character)
		if character ~= nil then
			SheetManager.SessionManager:SyncSession(character)
			Ext.PostMessageToClient(GameHelpers.GetCharacterID(character), "CEL_SheetManager_NotifyDataSynced", "")
		else
			Ext.BroadcastMessage("CEL_SheetManager_NotifyDataSynced", "")
		end
	else
		if character then
			Ext.PostMessageToServer("CEL_SheetManager_RequestCharacterSync", GameHelpers.GetNetID(character))
		end
	end
end

if not isClient then
	RegisterNetListener("CEL_SheetManager_RequestCharacterSync", function(cmd, payload)
		local netid = tonumber(payload)
		if netid then
			local character = Ext.GetCharacter(netid)
			if character then
				SheetManager:SyncData(character)
			end
		end
	end)
else
	---@private
	function SheetManager:OnDataSynced()
		if SheetManager.UI.CharacterCreation.IsOpen then
			SheetManager.UI.CharacterCreation.UpdateAttributes()
			SheetManager.UI.CharacterCreation.UpdateAbilities()
			SheetManager.UI.CharacterCreation.UpdateTalents()
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