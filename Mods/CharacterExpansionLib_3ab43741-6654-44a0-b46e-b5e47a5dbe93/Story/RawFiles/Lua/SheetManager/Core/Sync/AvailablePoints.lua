local self = SheetManager
local _ISCLIENT = Ext.IsClient()

if SheetManager.Sync == nil then SheetManager.Sync = {} end

---Get points via SheetManager:GetAvailablePoints
---@private
---@type table<Guid|NETID,table<string,integer>>
SheetManager.CustomAvailablePoints = {}
if not _ISCLIENT then
	setmetatable(SheetManager.CustomAvailablePoints, {
		__index = function(tbl, k)
			return PersistentVars.CustomStatAvailablePoints[k]
		end
	})
end

---@param characterId CharacterParam|nil Leave nil to sync points for all players.
function SheetManager.Sync.CustomAvailablePoints(characterId)
	if not _ISCLIENT then
		if not characterId then
			--Sync all
			local allPoints = {}
			for player in GameHelpers.Character.GetPlayers(false) do
				allPoints[player.NetID] = PersistentVars.CustomStatAvailablePoints[player.MyGuid] or {}
			end
			GameHelpers.Net.Broadcast("CEL_SheetManager_LoadAllAvailablePoints", allPoints)
		else
			local character = GameHelpers.GetCharacter(characterId)
			assert(character ~= nil, string.format("Failed to get character from id %s", characterId))
			GameHelpers.Net.PostToUser(character, "CEL_SheetManager_LoadAvailablePointsForCharacter", {
				NetID = character.NetID,
				Points = PersistentVars.CustomStatAvailablePoints[character.MyGuid] or {}
			})
		end
	else
		local netid = GameHelpers.GetNetID(characterId)
		GameHelpers.Net.PostMessageToServer("CEL_SheetManager_RequestAvailablePoints", tostring(netid))
	end
end

if not _ISCLIENT then
	RegisterNetListener("CEL_SheetManager_RequestAvailablePoints", function(cmd, payload)
		local netid = tonumber(payload)
		if netid then
			local character = GameHelpers.GetCharacter(netid)
			if character then
				Timer.Cancel("CEL_RequestSyncAvailablePoints", character.MyGuid)
				SheetManager.Sync.CustomAvailablePoints(character)
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

	Timer.Subscribe("CEL_RequestSyncAvailablePoints", function(e)
		if e.Data.Object then
			SheetManager.Sync.CustomAvailablePoints(e.Data.Object)
		end
	end)

	RegisterNetListener("CEL_SheetManager_RequestChangeAvailablePoints", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local character = GameHelpers.GetCharacter(data.Target)
			assert(character ~= nil, string.format("Failed to get character\n%s", payload))
			assert(data.PointID ~= nil, string.format("PointID not specified\n%s", payload))
			assert(type(data.Value) == "number", string.format("Value is not a number\n%s", payload))
			if SheetManager.CustomAvailablePoints[character.MyGuid] == nil then
				SheetManager.CustomAvailablePoints[character.MyGuid] = {}
			end
			SheetManager.CustomAvailablePoints[character.MyGuid][data.PointID] = data.Value
			SheetManager.Sync.CustomAvailablePoints(character)
		end
	end)

	-- local function BasePointsChanged(character)
	-- 	character = StringHelpers.GetUUID(character)
	-- 	local timerName = string.format("CEL_AggregateAvailablePoints%s", character)
	-- 	Timer.StartOneshot(timerName, 50, function()
	-- 		SheetManager.Sync.CustomAvailablePoints(character)
	-- 	end)
	-- end

	-- Ext.Osiris.RegisterListener("CharacterBaseAbilityChanged", 4, "after", BasePointsChanged)
else
	---@param characterId Guid|EsvCharacter|NETID|EclCharacter|nil Leave nil to sync points for all players.
	function SheetManager.Sync.AvailablePointsWithDelay(characterId)
		local netid = GameHelpers.GetNetID(characterId)
		GameHelpers.Net.PostMessageToServer("CEL_SheetManager_RequestAvailablePointsWithDelay", tostring(netid))
	end

	RegisterNetListener("CEL_SheetManager_LoadAvailablePointsForCharacter", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data and data.NetID and data.Points then
			SheetManager.CustomAvailablePoints[data.NetID] = data.Points
		end
		--SheetManager.UI.CharacterSheet.Update(SheetManager.UI.CharacterSheet.Instance, "updateArraySystem", {Abilities = true, PrimaryStats = true, Civil = true, Talents = true, CustomStats = true})
		if SheetManager.UI.CharacterSheet.IsOpen then
			SheetManager.UI.CharacterSheet.UpdateAllEntries()
		end
	end)

	RegisterNetListener("CEL_SheetManager_LoadAllAvailablePoints", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			for id,v in pairs(data) do
				SheetManager.CustomAvailablePoints[id] = v
			end
			if SheetManager.UI.CharacterSheet.IsOpen then
				SheetManager.UI.CharacterSheet.UpdateAllEntries()
			end
		end
	end)
end