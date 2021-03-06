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
	characterId = GameHelpers.GetObjectID(characterId)
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
	characterId = GameHelpers.GetObjectID(characterId)
	local sessionData = SessionManager:GetSession(characterId)
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
		characterId = GameHelpers.GetObjectID(characterId)
		local data = nil
		local sessionData = SessionManager:GetSession(characterId)
		if sessionData then
			data = sessionData.PendingChanges
			assert(data ~= nil, string.format("Failed to get character creation session data for (%s)", characterId))
		else
			data = self.CurrentValues[characterId]
		end
		if data then
			local tableName = SheetManager.Save.GetTableNameForType(entry.StatType)
			if tableName ~= nil then
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
---@param skipSessionCheck ?boolean
---@return boolean
function SheetManager.Save.SetEntryValue(characterId, entry, value, skipSessionCheck)
	characterId = GameHelpers.GetObjectID(characterId)
	local data = nil
	if skipSessionCheck ~= true then
		local sessionData = SessionManager:GetSession(characterId)
		if sessionData then
			data = sessionData.PendingChanges
			assert(data ~= nil, string.format("Failed to get character creation session data for (%s)", characterId))
		else
			data = self.CurrentValues[characterId] or SheetManager.Save.CreateCharacterData(characterId)
		end
	else
		data = self.CurrentValues[characterId] or SheetManager.Save.CreateCharacterData(characterId)
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
	---@param isInCharacterCreation ?boolean
	function SheetManager:RequestValueChange(entry, character, value, isInCharacterCreation)
		local netid = GameHelpers.GetNetID(character)
		local data = {
			ID = entry.ID,
			Mod = entry.Mod,
			NetID = netid,
			Value = value,
			StatType = entry.StatType,
			IsGameMaster = GameHelpers.Client.IsGameMaster() and not Client.Character.IsPossessed,
			IsInCharacterCreation = isInCharacterCreation or SheetManager.IsInCharacterCreation(character)
		}
		if data.IsInCharacterCreation then
			local ccwiz = Ext.UI.GetCharacterCreationWizard()
			if ccwiz then
				local points = ccwiz.AvailablePoints
				data.AvailablePoints = {
					Attribute = points.Attribute,
					Ability = points.Ability,
					Civil = points.Civil,
					Talent = points.Talent,
				}
			end
		end
		Ext.PostMessageToServer("CEL_SheetManager_RequestValueChange", Common.JsonStringify(data))
	end

	RegisterNetListener("CEL_SheetManager_UpdateCCWizardAvailablePoints", function (cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local ccwiz = Ext.UI.GetCharacterCreationWizard()
			if ccwiz then
				ccwiz.AvailablePoints.Attribute = data.Attribute
				ccwiz.AvailablePoints.Ability = data.Ability
				ccwiz.AvailablePoints.Civil = data.Civil
				ccwiz.AvailablePoints.Talent = data.Talent

				SheetManager.UI.CharacterCreation.UpdateAvailablePoints()
			end
		end
	end)
else
	local function ProcessPointChange(character, statId, statMod, statType, value, isGameMaster, isInCharacterCreation, availablePoints)
		local characterId = GameHelpers.GetObjectID(character)
		local stat = SheetManager:GetEntryByID(statId, statMod, statType)
		if characterId and stat then
			--TODO CustomStat support
			if isGameMaster or not stat.UsePoints then
				SheetManager:SetEntryValue(stat, characterId, value, isInCharacterCreation, true)
				return true
			else
				local modifyPointsBy = 0
				if stat.ValueType == "number" then
					modifyPointsBy = stat:GetValue(characterId) - value
				elseif stat.ValueType == "boolean" then
					modifyPointsBy = stat:GetValue(characterId) ~= true and -1 or 1
				end
				if modifyPointsBy ~= 0 then
					if modifyPointsBy < 0 then
						local points = SheetManager:GetBuiltinAvailablePointsForEntry(stat, characterId, availablePoints)
						if points > 0 and SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy, availablePoints) then
							SheetManager:SetEntryValue(stat, characterId, value, isInCharacterCreation, true)
							return true,availablePoints
						end
					else
						if SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy, availablePoints) then
							SheetManager:SetEntryValue(stat, characterId, value, isInCharacterCreation, true)
							return true,availablePoints
						end
					end
				end
			end
		end
		return false
	end

	RegisterNetListener("CEL_SheetManager_RequestValueChange", function(cmd, payload)
		Ext.PrintError(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			if ProcessPointChange(data.NetID, data.ID, data.Mod, data.StatType, data.Value, data.IsGameMaster, data.IsInCharacterCreation, data.AvailablePoints) then
				local player = GameHelpers.GetCharacter(data.NetID)
				if data.AvailablePoints then
					GameHelpers.Net.PostToUser(player, "CEL_SheetManager_UpdateCCWizardAvailablePoints", data.AvailablePoints)
					SessionManager:SyncSession(player)
				else
					SheetManager:SyncData(player)
				end
			end
		end
	end)
	RegisterNetListener("CEL_SheetManager_RequestBaseValueChange", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			assert(data.ModifyBy ~= "nil", "Payload needs a ModifyBy value (integer or boolean).")
			assert(type(data.NetID) == "number", "Payload needs a NetID.")
			assert(type(data.ID) == "string", "Payload needs an ID for the attribute/ability/talent.")
			assert(type(data.StatType) == "string", "Payload needs an StatType string value (Ability,Attribute,Talent).")
			local character = GameHelpers.GetCharacter(data.NetID)
			assert(character ~= nil, string.format("Failed to get character for NetID (%s).", data.NetID))
			
			if data.StatType == "Attribute" then
				NRD_PlayerSetBaseAttribute(character.MyGuid, data.ID, CharacterGetBaseAttribute(character.MyGuid, data.ID) + data.ModifyBy)
			elseif data.StatType == "Ability" then
				NRD_PlayerSetBaseAbility(character.MyGuid, data.ID, CharacterGetBaseAbility(character.MyGuid, data.ID) + data.ModifyBy)
			elseif data.StatType == "Talent" then
				NRD_PlayerSetBaseTalent(character.MyGuid, data.ID, data.ModifyBy)
			end

			--Force PlayerUpgrade sync
			CharacterAddCivilAbilityPoint(character.MyGuid, 0)
		end
	end)
end

--region Value Syncing
if not isClient then
	---@protected
	---@param character UUID|EsvCharacter
	---@param user number|string|nil Optional client to sync to if character is nil.
	function SheetManager.Sync.EntryValues(character, user)
		if character then
			local character = GameHelpers.GetCharacter(character)
			local data = {
				NetID = character.NetID,
				Values = {}
			}
			if PersistentVars.CharacterSheetValues[character.MyGuid] ~= nil then
				data.Values = TableHelpers.SanitizeTable(PersistentVars.CharacterSheetValues[character.MyGuid])
			end
			--fprint(LOGLEVEL.TRACE, "[SheetManager.Save.SyncEntryValues:SERVER] Syncing data for character (%s) NetID(%s) to client.", character.MyGuid, data.NetID)
			GameHelpers.Net.PostToUser(GameHelpers.GetUserID(character.MyGuid), "CEL_SheetManager_LoadCharacterSyncData", data)
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

			if user then
				local t = type(user)
				if t == "number" then
					GameHelpers.Net.PostToUser(user, "CEL_SheetManager_LoadSyncData", data)
					return true
				elseif t == "string" then
					GameHelpers.Net.PostToUser(GameHelpers.GetUserID(user), "CEL_SheetManager_LoadSyncData", data)
					return true
				else
					--fprint(LOGLEVEL.ERROR, "[SheetManager:SyncData] Invalid type (%s)[%s] for user parameter.", t, user)
				end
			end
			GameHelpers.Net.Broadcast("CEL_SheetManager_LoadSyncData", data)
			return true
		end
		return false
	end
else
	local function NotifyValueChanges(character, lastValues, values)
		for entryType,mods in pairs(values) do
			for modid,entries in pairs(mods) do
				for id,value in pairs(entries) do
					local entry = SheetManager:GetEntryByID(id, modid, entryType)
					if entry == nil then
						Ext.PrintWarning(entryType, SheetManager.Loaded, Ext.DumpExport(entries))
						Ext.PrintWarning(SheetManager.Data.CustomStats[modid])
					end
					assert(entry ~= nil, string.format("Failed to get sheet entry from id(%s) mod(%s) entryType(%s)", id, modid, entryType))
					local last = entryType == "Talents" and false or 0
					if lastValues and lastValues[entryType] and lastValues[entryType][modid] and lastValues[entryType][modid][id] then
						last = lastValues[entryType][modid][id]
					end
					self.Events.OnEntryChanged:Invoke({
						EntryType = entry.Type,
						Stat = entry,
						ID = entry.ID,
						LastValue = last,
						Value = value,
						Character = character,
						IsClient = isClient,
					})
				end
			end
		end
	end

	local delayNotify = false

	RegisterNetListener("CEL_SheetManager_LoadSyncData", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local lastValues = TableHelpers.Clone(self.CurrentValues)
			self.CurrentValues = data

			if SheetManager.Loaded then
				delayNotify = false
				for netid,data in pairs(self.CurrentValues) do
					local character = Ext.GetCharacter(netid)
					if character then
						NotifyValueChanges(character, lastValues[netid], data)
					end
				end
			else
				delayNotify = true
			end
		end
	end)

	SheetManager.Events.Loaded:Subscribe(function (e)
		if delayNotify then
			delayNotify = false
			local client = Client:GetCharacter()
			if client then
				Ext.PostMessageToServer("CEL_SheetManager_RequestCharacterSync", client.NetID)
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
			--fprint(LOGLEVEL.TRACE, "[SheetManager:LoadCharacterSyncData:CLIENT] Received sync data for character NetID (%s).", data.NetID)

			if SheetManager.Loaded then
				local character = Ext.GetCharacter(data.NetID)
				if character then
					NotifyValueChanges(character, lastValues, self.CurrentValues[data.NetID])
				end
			else
				delayNotify = true
			end
		end
	end)
end
--endregion

if isClient then
	RegisterNetListener("CEL_SheetManager_EntryValueChanged", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local characterId = GameHelpers.GetObjectID(data.NetID)
			local stat = SheetManager:GetEntryByID(data.ID, data.Mod, data.StatType)
			if characterId and stat then
				local skipInvoke = data.SkipInvoke
				if skipInvoke == nil then
					skipInvoke = false
				end
				SheetManager:SetEntryValue(stat, characterId, data.Value, skipInvoke, true, true)
				--SheetManager.Save.SetEntryValue(characterId, stat, data.Value)
			end
		end
	end)
end