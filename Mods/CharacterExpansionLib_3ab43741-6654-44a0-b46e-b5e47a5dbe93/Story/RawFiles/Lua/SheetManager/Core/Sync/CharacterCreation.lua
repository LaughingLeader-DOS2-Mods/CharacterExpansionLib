local _ISCLIENT = Ext.IsClient()

if SheetManager.Save == nil then SheetManager.Save = {} end

---@param characterId CharacterParam
function SheetManager.IsInCharacterCreation(characterId)
	characterId = GameHelpers.GetObjectID(characterId)
	if GameHelpers.IsLevelType(LEVELTYPE.CHARACTER_CREATION) then
		return true
	end
	if _ISCLIENT then
		if Client.Character then
			if characterId == Client.Character.NetID and Client.Character.IsInCharacterCreation then
				return true
			end
		end
		local ui = not Vars.ControllerEnabled and Ext.UI.GetByType(Data.UIType.characterCreation) or Ext.UI.GetByType(Data.UIType.characterCreation_c)
		local player = GameHelpers.Client.GetCharacterCreationCharacter()
		if player then
			return GameHelpers.GetObjectID(player) == characterId
		end
	elseif Ext.Osiris.IsCallable() then
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
---@param characterId CharacterParam
---@param applyChanges boolean
function SheetManager.Save.CharacterCreationDone(characterId, applyChanges)
	local player = GameHelpers.GetCharacter(characterId)
	if not _ISCLIENT then
		if applyChanges == true then
			SessionManager:ApplySession(player)
		else
			SessionManager:ClearSession(player, true)
		end
		SheetManager:SyncData(player)
	else
		GameHelpers.Net.PostMessageToServer("CEL_SheetManager_CharacterCreationDone", {
			UserId = Client.Character.ID,
			ApplyChanges = applyChanges
		})
	end
end

if not _ISCLIENT then
	RegisterNetListener("CEL_SheetManager_CharacterCreationDone", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local character = GameHelpers.GetCharacter(GetCurrentCharacter(data.UserId))
			if character then
				local applyChanges = data.ApplyChanges
				if applyChanges == nil then
					applyChanges = false
				end
				SheetManager.Save.CharacterCreationDone(character, applyChanges)
			end
		end
	end)
end