local self = SheetManager
local isClient = Ext.IsClient()

if SheetManager.Save == nil then SheetManager.Save = {} end

---@class SheetManagerSaveData:table
---@field Stats table<MOD_UUID, table<SHEET_ENTRY_ID, integer>>
---@field Abilities table<MOD_UUID, table<SHEET_ENTRY_ID, integer>>
---@field Talents table<MOD_UUID, table<SHEET_ENTRY_ID, boolean>>
---@field Custom table<MOD_UUID, table<SHEET_ENTRY_ID, integer>>

---SheetManager entry values for specific characters. Saved to PersistentVars.
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

--region Get/Set Values

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
						if value == nil then
							return defaultValue
						else
							return value
						end
					end
				end
			end
		end
		return defaultValue
	end
	return nil
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
--endregion

if isClient then
	---Request a value change for a sheet entry on the server side.
	---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
	---@param character EclCharacter|NETID
	---@param value integer|boolean
	function SheetManager:RequestValueChange(entry, character, value)
		local netid = GameHelpers.GetNetID(character)
		Ext.PostMessageToServer("CEL_SheetManager_RequestValueChange", Ext.JsonStringify({
			ID = entry.ID,
			Mod = entry.Mod,
			NetID = netid,
			Value = value,
			StatType = entry.StatType,
			IsGameMaster = GameHelpers.Client.IsGameMaster() and not Client.Character.IsPossessed,
			IsInCharacterCreation = SheetManager.IsInCharacterCreation(character)
		}))
	end
else
	RegisterNetListener("CEL_SheetManager_RequestValueChange", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local characterId = GameHelpers.GetCharacterID(data.NetID)
			local stat = SheetManager:GetEntryByID(data.ID, data.Mod, data.StatType)
			if characterId and stat then
				if data.IsGameMaster or not stat.UsePoints then
					SheetManager:SetEntryValue(stat, characterId, data.Value, data.IsInCharacterCreation, true)
					SheetManager:SyncData(characterId)
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
								SheetManager:SetEntryValue(stat, characterId, data.Value, data.IsInCharacterCreation, true)
								SheetManager:SyncData(characterId)
							end
						else
							if SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy) then
								SheetManager:SetEntryValue(stat, characterId, data.Value, data.IsInCharacterCreation, true)
								SheetManager:SyncData(characterId)
							end
						end
					end
				end
			end
		end
	end)
end

--region Value Syncing
if not isClient then
	---@protected
	---@param character UUID|EsvCharacter
	function SheetManager.Sync.EntryValues(character)
		if character then
			local character = GameHelpers.GetCharacter(character)
			local data = {
				NetID = character.NetID,
				Values = {}
			}
			if PersistentVars.CharacterSheetValues[character.MyGuid] ~= nil then
				data.Values = TableHelpers.SanitizeTable(PersistentVars.CharacterSheetValues[character.MyGuid])
			end
			fprint(LOGLEVEL.TRACE, "[SheetManager.Save.SyncEntryValues:SERVER] Syncing data for character (%s) NetID(%s) to client.", character.MyGuid, data.NetID)
			Ext.PostMessageToClient(character.MyGuid, "CEL_SheetManager_LoadCharacterSyncData", Ext.JsonStringify(data))
			return true
		else
			--Sync all characters
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
else
	local function NotifyValueChanges(character, lastValues, values)
		for entryType,mods in pairs(values) do
			for modId,entries in pairs(mods) do
				for entryId,value in pairs(entries) do
					local entry = SheetManager:GetEntryByID(entryId, modId, entryType)
					assert(entry ~= nil, string.format("Failed to get sheet entry from id(%s) mod(%s) entryType(%s)", entryId, modId, entryType))
					local last = entryType == "Talents" and false or 0
					if lastValues and lastValues[entryType] and lastValues[entryType][modId] and lastValues[entryType][modId][entryId] then
						last = lastValues[entryType][modId][entryId]
					end
					for listener in self:GetListenerIterator(self.Listeners.OnEntryChanged[entry.ID], self.Listeners.OnEntryChanged.All) do
						local b,err = xpcall(listener, debug.traceback, entry.ID, entry, character, last, value, isClient)
						if not b then
							fprint(LOGLEVEL.ERROR, "[CharacterExpansionLib:CustomStatSystem:OnStatPointAdded] Error calling OnAvailablePointsChanged listener for stat (%s):\n%s", entry.ID, err)
						end
					end
				end
			end
		end
	end

	RegisterNetListener("CEL_SheetManager_LoadSyncData", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local lastValues = TableHelpers.Clone(self.CurrentValues)
			self.CurrentValues = data

			for netid,data in pairs(self.CurrentValues) do
				local character = Ext.GetCharacter(netid)
				if character then
					NotifyValueChanges(character, lastValues[netid], data)
				end
			end
		end
	end)

	RegisterNetListener("CEL_SheetManager_LoadCharacterSyncData", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			assert(type(data.NetID) == "number", "NetID is invalid.")
			assert(data.Values ~= nil, "Payload has no Values table.")
			local lastValues = TableHelpers.Clone(self.CurrentValues[data.NetID] or {})
			self.CurrentValues[data.NetID] = data.Values
			fprint(LOGLEVEL.TRACE, "[SheetManager:LoadCharacterSyncData:CLIENT] Received sync data for character NetID (%s).", data.NetID)

			local character = Ext.GetCharacter(data.NetID)
			if character then
				NotifyValueChanges(character, lastValues, self.CurrentValues[data.NetID])
			end
		end
	end)
end
--endregion

if isClient then
	RegisterNetListener("CEL_SheetManager_EntryValueChanged", function(cmd, payload)
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