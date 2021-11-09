local self = SheetManager
local isClient = Ext.IsClient()

if SheetManager.Sync == nil then SheetManager.Sync = {} end

---@class SheetManagerAvailablePointsData:table
---@field Attribute integer
---@field Ability integer
---@field Civil integer
---@field Talent integer
---@field Custom table<CUSTOMSTATID,integer>

---Get points via SheetManager:GetAvailablePoints
---@private
---@type table<UUID|NETID, SheetManagerAvailablePointsData>
SheetManager.AvailablePoints = {}

---@param characterId UUID|EsvCharacter|NETID|EclCharacter|nil Leave nil to sync points for all players.
function SheetManager.Sync.AvailablePoints(characterId)
	if not isClient then
		if not characterId then
			--Sync all
			local allPoints = {}
			for player in GameHelpers.Character.GetPlayers(false) do
				local data = {}
				data.Attribute = CharacterGetAttributePoints(player.MyGuid) or 0
				data.Ability = CharacterGetAbilityPoints(player.MyGuid) or 0
				data.Civil = CharacterGetCivilAbilityPoints(player.MyGuid) or 0
				data.Talent = CharacterGetTalentPoints(player.MyGuid) or 0
				data.Custom = PersistentVars.CustomStatAvailablePoints[player.MyGuid] or {}
				SheetManager.AvailablePoints[player.MyGuid] = data
				allPoints[player.NetID] = data
			end
			Ext.BroadcastMessage("CEL_SheetManager_LoadAllAvailablePoints", Ext.JsonStringify(allPoints))
		else
			local character = GameHelpers.GetCharacter(characterId)
			local data = {}
			data.Attribute = CharacterGetAttributePoints(character.MyGuid) or 0
			data.Ability = CharacterGetAbilityPoints(character.MyGuid) or 0
			data.Civil = CharacterGetCivilAbilityPoints(character.MyGuid) or 0
			data.Talent = CharacterGetTalentPoints(character.MyGuid) or 0
			data.Custom = PersistentVars.CustomStatAvailablePoints[character.MyGuid] or {}
			SheetManager.AvailablePoints[character.MyGuid] = data
	
			Ext.PostMessageToClient(character.MyGuid, "CEL_SheetManager_LoadAvailablePointsForCharacter", Ext.JsonStringify({
				NetID = character.NetID,
				Points = data
			}))
		end
	else
		local netid = GameHelpers.GetNetID(characterId)
		Ext.PostMessageToServer("CEL_SheetManager_RequestAvailablePoints", tostring(netid))
	end
end

if not isClient then
	RegisterNetListener("CEL_SheetManager_RequestAvailablePoints", function(cmd, payload)
		local netid = tonumber(payload)
		if netid then
			local character = Ext.GetCharacter(netid)
			if character then
				SheetManager.Sync.AvailablePoints(character)
			end
		end
	end)
else
	RegisterNetListener("CEL_SheetManager_LoadAvailablePointsForCharacter", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data and data.NetID and data.Points then
			SheetManager.AvailablePoints[data.NetID] = data.Points
		end
		--SheetManager.UI.CharacterSheet.Update(SheetManager.UI.CharacterSheet.Instance, "updateArraySystem", {Abilities = true, PrimaryStats = true, Civil = true, Talents = true, CustomStats = true})
		SheetManager.UI.CharacterSheet.UpdateAllEntries()
	end)
	RegisterNetListener("CEL_SheetManager_LoadAllAvailablePoints", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			SheetManager.AvailablePoints = data

			SheetManager.UI.CharacterSheet.UpdateAllEntries()
		end
	end)
end