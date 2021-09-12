local self = SheetManager
local isClient = Ext.IsClient()

---@class SheetManagerSaveData:table
---@field Stats table<MOD_UUID, table<SHEET_ENTRY_ID, integer>>
---@field Abilities table<MOD_UUID, table<SHEET_ENTRY_ID, integer>>
---@field Talents table<MOD_UUID, table<SHEET_ENTRY_ID, boolean>>
---@field Custom table<MOD_UUID, table<SHEET_ENTRY_ID, integer>>

---@type table<UUID|NETID, SheetManagerSaveData>
SheetManager.CurrentValues = {}

if not isClient then
	local Handler = {
		__index = function(tbl,k)
			return PersistentVars.CharacterSheetValues[k]
		end,
		__newindex = function(tbl,k,v)
			PersistentVars.CharacterSheetValues[k] = v
		end
	}
	setmetatable(SheetManager.CurrentValues, Handler)
end

SheetManager.Save = {}

---@private
---@param characterId UUID|EsvCharacter|NETID|EclCharacter
---@return SheetManagerSaveData
function SheetManager.Save.CreateCharacterData(characterId)
	characterId = GameHelpers.GetCharacterID(characterId)
	assert(type(characterId) == "string" or type(characterId) == "number", "Character ID (UUID or NetID) required.")
	local data = self.CurrentValues[characterId]
	if not data then
		data = {
			Stats = {},
			Abilities = {},
			Talents = {},
			CustomStats = {}
		}
		self.CurrentValues[characterId] = data
	end
	return data
end

---@param statType SheetEntryType
---@return integer|boolean
function SheetManager.Save.GetTableNameForType(statType)
	if statType == self.StatType.PrimaryStat or statType == self.StatType.SecondaryStat then
		return "Stats"
	elseif statType == self.StatType.Ability then
		return "Abilities"
	elseif statType == self.StatType.Talent then
		return "Talents"
	elseif statType == self.StatType.Custom then
		return "CustomStats"
	end
end

---@param characterId UUID|EsvCharacter|NETID|EclCharacter
---@param statType SheetStatType|nil
---@param mod string|nil
---@param entryId string|nil
---@return table
function SheetManager.Save.GetCharacterData(characterId, statType, mod, entryId)
	local data = self.CurrentValues[characterId]
	if data then
		if statType then
			local tableName = SheetManager.Save.GetTableNameForType(statType)
			if tableName ~= nil then
				local statTypeTable = data[tableName]
				if statTypeTable then
					if mod then
						local modData = statTypeTable[mod]
						if entryId then
							return modData[entryId]
						end
						return modData
					end
					return statTypeTable
				end
			end
		end
		if mod then
			for statType,modData in pairs(data) do
				if modData[mod] then
					if entryId then
						return modData[mod][entryId]
					end
					return modData[mod]
				end
			end
		elseif entryId then
			for statType,modData in pairs(data) do
				for modId,statData in pairs(modData) do
					if statData[entryId] then
						return statData[entryId]
					end
				end
			end
		end
		return data
	end
	return nil
end

---Get the pending value from character creation, if any.
---@param characterId UUID|EsvCharacter|NETID|EclCharacter
---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@return integer|boolean
---@return table<SHEET_ENTRY_ID, integer> The mod data table containing all stats.
function SheetManager.Save.GetPendingValue(characterId, entry, tableName)
	characterId = GameHelpers.GetCharacterID(characterId)
	local sessionData = SheetManager.SessionManager:GetSession(characterId)
	local pendingValues = sessionData and sessionData.PendingChanges or nil
	if pendingValues then
		tableName = tableName or SheetManager.Save.GetTableNameForType(entry.StatType)
		if tableName ~= nil then
			local statTypeTable = pendingValues[tableName]
			if statTypeTable then
				local modTable = statTypeTable[entry.Mod]
				if modTable then
					return modTable[entry.ID]
				end
			end
		end
	end
	return nil
end

---@param characterId UUID|EsvCharacter|NETID|EclCharacter
---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@return integer|boolean
---@return table<SHEET_ENTRY_ID, integer> The mod data table containing all stats.
function SheetManager.Save.GetEntryValue(characterId, entry)
	local t = type(entry)
	assert(t == "table", string.format("[SheetManager.Save.GetEntryValue] Entry type invalid (%s). Must be one of the following types: SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData", t))
	if entry then
		local defaultValue = 0
		if entry.ValueType == "boolean" then
			defaultValue = false
		end
		characterId = GameHelpers.GetCharacterID(characterId)
		local data = self.CurrentValues[characterId]
		if data then
			local tableName = SheetManager.Save.GetTableNameForType(entry.StatType)
			if tableName ~= nil then
				local pendingValue = SheetManager.Save.GetPendingValue(characterId, entry, tableName)
				if pendingValue ~= nil then
					return pendingValue
				end
				local statTypeTable = data[tableName]
				if statTypeTable then
					local modTable = statTypeTable[entry.Mod]
					if modTable then
						local value = modTable[entry.ID]
						if entry.ValueType ~= "boolean" then
							if value == nil then
								value = 0
							end
							return value,modTable
						elseif value == nil then
							return defaultValue,modTable
						end
					end
				end
				return pendingValue
			end
		end
		return defaultValue
	end
	return nil
end

function SheetManager.IsInCharacterCreation(characterId)
	characterId = GameHelpers.GetCharacterID(characterId)
	if isClient then
		if characterId == Client.Character.NetID then
			return Client.Character.IsInCharacterCreation
		end
		local ui = not Vars.ControllerEnabled and Ext.GetUIByType(Data.UIType.characterCreation) or Ext.GetUIByType(Data.UIType.characterCreation_c)
		local player = GameHelpers.Client.GetCharacterCreationCharacter()
		if player then
			return GameHelpers.GetCharacterID(player) == characterId
		end
	else
		local db = Osi.DB_Illusionist:Get(nil,nil)
		if db and #db > 0 then
			local playerId = StringHelpers.GetUUID(db[1][1])
			return playerId == characterId
		end
	end
	return false
end

---@param characterId UUID|EsvCharacter|NETID|EclCharacter
---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@param value integer|boolean
---@return boolean
function SheetManager.Save.SetEntryValue(characterId, entry, value)
	characterId = GameHelpers.GetCharacterID(characterId)
	local data = self.CurrentValues[characterId] or SheetManager.Save.CreateCharacterData(characterId)
	local sessionData = SheetManager.SessionManager:GetSession(characterId)
	if sessionData then
		data = sessionData.PendingChanges
		assert(data ~= nil, string.format("Failed to get character creation session data for (%s)", characterId))
	end
	local tableName = SheetManager.Save.GetTableNameForType(entry.StatType)
	assert(tableName ~= nil, string.format("Failed to find data table for stat type (%s)", entry.StatType))
	if data[tableName] == nil then
		data[tableName] = {}
	end
	if data[tableName][entry.Mod] == nil then
		data[tableName][entry.Mod] = {}
	end
	data[tableName][entry.Mod][entry.ID] = value
	return true
end

---@param characterId UUID|EsvCharacter|NETID|EclCharacter
---@param applyChanges boolean
function SheetManager.Save.CharacterCreationDone(characterId, applyChanges)
	if not isClient then
		characterId = GameHelpers.GetCharacterID(characterId)
		if applyChanges then
			SheetManager.SessionManager:ApplySession(characterId)
		else
			SheetManager.SessionManager:ClearSession(characterId)
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
	Ext.RegisterNetListener("CEL_SheetManager_CharacterCreationDone", function(cmd, payload)
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

	---@private
	---@param character UUID|EsvCharacter
	---@param user integer|nil
	function SheetManager:SyncData(character, user)
		if character ~= nil then
			local characterId = GameHelpers.GetCharacterID(character)
			local data = {
				NetID = GameHelpers.GetNetID(character),
				Values = {}
			}
			if PersistentVars.CharacterSheetValues[characterId] ~= nil then
				data.Values = TableHelpers.SanitizeTable(PersistentVars.CharacterSheetValues[characterId])
			end
			data = Ext.JsonStringify(data)
			if user then
				local t = type(user)
				if t == "number" then
					fprint(LOGLEVEL.TRACE, "[SheetManager:SyncData:SERVER] Syncing data for character (%s) NetID(%s) to user (%s).", characterId, data.NetID, user)
					Ext.PostMessageToUser(user, "CEL_SheetManager_LoadCharacterSyncData", data)
					return true
				elseif t == "string" then
					fprint(LOGLEVEL.TRACE, "[SheetManager:SyncData:SERVER] Syncing data for character (%s) NetID(%s) to client (%s).", characterId, data.NetID, user)
					Ext.PostMessageToClient(user, "CEL_SheetManager_LoadCharacterSyncData", data)
					return true
				else
					fprint(LOGLEVEL.ERROR, "[SheetManager:SyncData] Invalid type (%s)[%s] for user parameter.", t, user)
				end
			end
			fprint(LOGLEVEL.TRACE, "[SheetManager:SyncData:SERVER] Syncing data for character (%s) NetID(%s) to all clients.", characterId, data.NetID)
			Ext.BroadcastMessage("CEL_SheetManager_LoadCharacterSyncData", data)
		else
			local data = {}
			for uuid,entries in pairs(TableHelpers.SanitizeTable(PersistentVars.CharacterSheetValues)) do
				local netid = GameHelpers.GetNetID(uuid)
				if netid then
					data[netid] = entries
				end
			end

			data = Ext.JsonStringify(data)
			if user then
				local t = type(user)
				if t == "number" then
					Ext.PostMessageToUser(user, "CEL_SheetManager_LoadSyncData", data)
					return true
				elseif t == "string" then
					Ext.PostMessageToClient(user, "CEL_SheetManager_LoadSyncData", data)
					return true
				else
					fprint(LOGLEVEL.ERROR, "[SheetManager:SyncData] Invalid type (%s)[%s] for user parameter.", t, user)
				end
			end
			Ext.BroadcastMessage("CEL_SheetManager_LoadSyncData", data)
			return true
		end
		return false
	end

	Ext.RegisterNetListener("CEL_SheetManager_RequestValueChange", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local characterId = GameHelpers.GetCharacterID(data.NetID)
			local stat = SheetManager:GetEntryByID(data.ID, data.Mod, data.StatType)
			if characterId and stat then
				if data.IsGameMaster or not stat.UsePoints then
					SheetManager:SetEntryValue(stat, characterId, data.Value)
				else
					local modifyPointsBy = 0
					if stat.ValueType == "number" then
						modifyPointsBy = stat:GetValue(characterId) - data.Value
					elseif stat.ValueType == "boolean" then
						modifyPointsBy = stat:GetValue(characterId) ~= true and - 1 or 1
					end
					if modifyPointsBy ~= 0 then
						if modifyPointsBy < 0 then
							local points = SheetManager:GetBuiltinAvailablePointsForEntry(stat, characterId)
							if points > 0 and SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy) then
								SheetManager:SetEntryValue(stat, characterId, data.Value)
							end
						else
							if SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy) then
								SheetManager:SetEntryValue(stat, characterId, data.Value)
							end
						end
					end
				end
				SheetManager:SyncData(characterId)
			end
		end
	end)
else
	---@private
	function SheetManager:OnDataSynced()
		print("SheetManager:OnDataSynced|SheetManager.UI.CharacterCreation.IsOpen", SheetManager.UI.CharacterCreation.IsOpen)
		if SheetManager.UI.CharacterCreation.IsOpen then
			SheetManager.UI.CharacterCreation:UpdateAttributes()
			SheetManager.UI.CharacterCreation:UpdateAbilities()
			SheetManager.UI.CharacterCreation:UpdateTalents()
		end
	end

	Ext.RegisterNetListener("CEL_SheetManager_LoadSyncData", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			self.CurrentValues = data
			SheetManager.OnDataSynced()
		end
	end)

	Ext.RegisterNetListener("CEL_SheetManager_LoadCharacterSyncData", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			assert(type(data.NetID) == "number", "NetID is invalid.")
			assert(data.Values ~= nil, "Payload has no Values table.")
			self.CurrentValues[data.NetID] = data.Values
			fprint(LOGLEVEL.TRACE, "[SheetManager:LoadCharacterSyncData:CLIENT] Received sync data for character NetID (%s).", data.NetID)

			SheetManager.OnDataSynced()
		end
	end)
	
	---Request a value change for a sheet entry on the server side.
	---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
	---@param character EclCharacter|NETID
	---@param value integer|boolean
	function SheetManager:RequestValueChange(entry, character, value, isInCharacterCreation)
		local netid = GameHelpers.GetNetID(character)
		Ext.PostMessageToServer("CEL_SheetManager_RequestValueChange", Ext.JsonStringify({
			ID = entry.ID,
			Mod = entry.Mod,
			NetID = netid,
			Value = value,
			StatType = entry.StatType,
			IsGameMaster = GameHelpers.Client.IsGameMaster() and not Client.Character.IsPossessed,
			IsInCharacterCreation = isInCharacterCreation
		}))
	end

	Ext.RegisterNetListener("CEL_SheetManager_EntryValueChanged", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local characterId = GameHelpers.GetCharacterID(data.NetID)
			local stat = SheetManager:GetEntryByID(data.ID, data.Mod, data.StatType)
			if characterId and stat then
				local skipInvoke = data.SkipInvoke
				if skipInvoke == nil then
					skipInvoke = false
				end
				SheetManager:SetEntryValue(stat, characterId, data.Value, skipInvoke, true, data.IsInCharacterCreation)
			end
		end
	end)
end