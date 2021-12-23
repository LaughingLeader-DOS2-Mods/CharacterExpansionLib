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
			local character = GameHelpers.GetCharacter(netid)
			if character then
				Timer.Cancel("CEL_RequestSyncAvailablePoints", character.MyGuid)
				SheetManager.Sync.AvailablePoints(character)
			end
		end
	end)

	RegisterNetListener("CEL_SheetManager_RequestAvailablePointsWithDelay", function(cmd, payload)
		local netid = tonumber(payload)
		if netid then
			local character = GameHelpers.GetCharacter(netid)
			Timer.StartObjectTimer("CEL_RequestSyncAvailablePoints", character.MyGuid, 500)
		end
	end)

	Timer.RegisterListener("CEL_RequestSyncAvailablePoints", function(timerName, uuid)
		local character = GameHelpers.GetCharacter(uuid)
		if character then
			SheetManager.Sync.AvailablePoints(character)
		end
	end)

	-- local function BasePointsChanged(character)
	-- 	character = StringHelpers.GetUUID(character)
	-- 	local timerName = string.format("CEL_AggregateAvailablePoints%s", character)
	-- 	Timer.StartOneshot(timerName, 50, function()
	-- 		SheetManager.Sync.AvailablePoints(character)
	-- 	end)
	-- end

	-- Ext.RegisterOsirisListener("CharacterBaseAbilityChanged", 4, "after", BasePointsChanged)
else
		---@param characterId UUID|EsvCharacter|NETID|EclCharacter|nil Leave nil to sync points for all players.
	function SheetManager.Sync.AvailablePointsWithDelay(characterId)
		local netid = GameHelpers.GetNetID(characterId)
		Ext.PostMessageToServer("CEL_SheetManager_RequestAvailablePointsWithDelay", tostring(netid))
	end

	RegisterNetListener("CEL_SheetManager_LoadAvailablePointsForCharacter", function(cmd, payload)
		Ext.PrintWarning(cmd, payload)
		local data = Common.JsonParse(payload)
		if data and data.NetID and data.Points then
			SheetManager.AvailablePoints[data.NetID] = data.Points
		end
		--SheetManager.UI.CharacterSheet.Update(SheetManager.UI.CharacterSheet.Instance, "updateArraySystem", {Abilities = true, PrimaryStats = true, Civil = true, Talents = true, CustomStats = true})
		if SheetManager.UI.CharacterSheet.IsOpen then
			SheetManager.UI.CharacterSheet.UpdateAllEntries()
		end
	end)
	RegisterNetListener("CEL_SheetManager_LoadAllAvailablePoints", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			SheetManager.AvailablePoints = data
			if SheetManager.UI.CharacterSheet.IsOpen then
				SheetManager.UI.CharacterSheet.UpdateAllEntries()
			end
		end
	end)
end