local isClient = Ext.IsClient()

if SheetManager.Save == nil then SheetManager.Save = {} end

---@param characterId UUID|EsvCharacter|NETID|EclCharacter
function SheetManager.IsInCharacterCreation(characterId)
	characterId = GameHelpers.GetCharacterID(characterId)
	if isClient then
		if Client.Character then
			if characterId == Client.Character.NetID and Client.Character.IsInCharacterCreation then
				return true
			end
		end
		local ui = not Vars.ControllerEnabled and Ext.GetUIByType(Data.UIType.characterCreation) or Ext.GetUIByType(Data.UIType.characterCreation_c)
		local player = GameHelpers.Client.GetCharacterCreationCharacter()
		if player then
			return GameHelpers.GetCharacterID(player) == characterId
		end
	elseif Ext.OsirisIsCallable() then
		local db = Osi.DB_Illusionist:Get(nil,nil)
		if db and #db > 0 then
			local playerId = StringHelpers.GetUUID(db[1][1])
			if playerId == characterId then
				return true
			end
		end
		local db = Osi.DB_AssignedDummyForUser:Get(nil,nil)
		if db and #db > 0 then
			local playerId = StringHelpers.GetUUID(db[1][2])
			if playerId == characterId then
				return true
			end
		end
	end
	return false
end

---Callback for when a character exits character creation, for applying pending changes, if any.
---@param characterId UUID|EsvCharacter|NETID|EclCharacter
---@param applyChanges boolean
function SheetManager.Save.CharacterCreationDone(characterId, applyChanges)
	if not isClient then
		characterId = GameHelpers.GetCharacterID(characterId)
		if applyChanges then
			SessionManager:ApplySession(characterId)
		else
			SessionManager:ClearSession(characterId)
		end
		SheetManager:SyncData()
	else
		local netid = GameHelpers.GetNetID(characterId)
		Ext.PostMessageToServer("CEL_SheetManager_CharacterCreationDone", Ext.JsonStringify({
			NetID = netid,
			ApplyChanges = applyChanges
		}))
	end
end

if not isClient then
	RegisterNetListener("CEL_SheetManager_CharacterCreationDone", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local character = Ext.GetCharacter(data.NetID)
			if character then
				local applyChanges = data.ApplyChanges
				if applyChanges == nil then
					applyChanges = false
				end
				SheetManager.Save.CharacterCreationDone(character.MyGuid, applyChanges)
			end
		end
	end)
end