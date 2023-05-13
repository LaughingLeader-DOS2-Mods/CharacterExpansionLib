local self = SheetManager
local _ISCLIENT = Ext.IsClient()

if SheetManager.Save == nil then SheetManager.Save = {} end

---@class SheetManagerSaveData:table
---@field Stats table<ModGuid, table<SheetEntryId, integer>>
---@field Abilities table<ModGuid, table<SheetEntryId, integer>>
---@field Talents table<ModGuid, table<SheetEntryId, boolean>>
---@field Custom table<ModGuid, table<SheetEntryId, integer>>

---SheetManager entry values for specific characters. Saved to PersistentVars.
---@type table<Guid|NETID, SheetManagerSaveData>
SheetManager.CurrentValues = {}

if not _ISCLIENT then
	local Handler = {
		__index = function(tbl,k)
			return PersistentVars.CharacterSheetValues[k]
		end,
		__newindex = function(tbl,k,v)
			PersistentVars.CharacterSheetValues[k] = v
		end,
		__pairs = function(t, ...)
			return next, PersistentVars.CharacterSheetValues, nil
		end
	}
	Handler.__ipairs = Handler.__pairs
	setmetatable(SheetManager.CurrentValues, Handler)
end

---@private
---@param characterId CharacterParam
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
---@return PersistentVarsStatTypeTableName|nil
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

---@param characterId CharacterParam
---@param statType? SheetStatType
---@param mod? string
---@param entryId? string
---@return table|nil
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
---@param character EsvCharacter|EclCharacter
---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@return integer|boolean|nil
---@return table<SheetEntryId, integer>|nil modData #The mod data table containing all stats.
function SheetManager.Save.GetPendingValue(character, entry, tableName)
	local sessionData = SessionManager:GetSession(character)
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

---@param character EsvCharacter|EclCharacter
---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@return integer|boolean|nil
function SheetManager.Save.GetEntryValue(character, entry)
	local t = type(entry)
	assert(t == "table", string.format("[SheetManager.Save.GetEntryValue] Entry type invalid (%s). Must be one of the following types: SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData", t))
	if entry then
		---@type integer|boolean
		local defaultValue = 0
		if entry.ValueType == "boolean" then
			---@cast defaultValue boolean
			defaultValue = false
		end
		local characterId = GameHelpers.GetObjectID(character)
		local data = self.CurrentValues[characterId]
		local sessionData = SessionManager:GetSession(character)
		if sessionData then
			data = sessionData.PendingChanges
			assert(data ~= nil, string.format("Failed to get character creation session data for (%s)", characterId))
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

---@param character EsvCharacter|EclCharacter
---@param entry SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@param value integer|boolean
---@param skipSessionCheck ?boolean
---@return boolean
function SheetManager.Save.SetEntryValue(character, entry, value, skipSessionCheck)
	--Ext.Utils.PrintError("SheetManager.Save.SetEntryValue", character.NetID, GameHelpers.GetDisplayName(character))
	local characterId = GameHelpers.GetObjectID(character)
	local data = nil
	if skipSessionCheck ~= true then
		local sessionData = SessionManager:GetSession(character)
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

---@param characterId Guid|NetId
function SheetManager.Save.RemoveCharacterData(characterId)
	self.CurrentValues[characterId] = nil
	if not _ISCLIENT then
		PersistentVars.CustomStatAvailablePoints[characterId] = nil
		PersistentVars.CustomStatValues[characterId] = nil
	end
end

--endregion

if _ISCLIENT then
	---@class CEL_SheetManager_ClearCharacterData
	---@field NetID integer

	GameHelpers.Net.Subscribe("CEL_SheetManager_ClearCharacterData", function (e, data)
		SheetManager.Save.RemoveCharacterData(data.NetID)
	end)

	--Mods.CharacterExpansionLib.SheetManager:RequestValueChange(Mods.CharacterExpansionLib.SheetManager:GetEntryByID("FastCasting", "", "Ability"), me.MyGuid, 12)

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
			IsInCharacterCreation = isInCharacterCreation or character.CharCreationInProgress
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
		GameHelpers.Net.PostMessageToServer("CEL_SheetManager_RequestValueChange", data)
	end

	---@return CharacterCreationClassDesc|nil
	local function _GetClassPreset(id)
		local ccStats = Ext.Stats.GetCharacterCreation()
		for _,v in pairs(ccStats.ClassPresets) do
			if v.ClassType == id then
				return v
			end
		end
		return nil
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

				--Update the "assigned" points, so they don't get extra points from getting new entries
				local playerData = GameHelpers.CC.GetCharacterData()
				local preset = _GetClassPreset(playerData.Customization.State.Class.ClassType)
				if preset then
					playerData.Customization.State.AttributePointsAssigned = math.max(0, preset.NumStartingAttributePoints - data.Attribute)
					playerData.Customization.State.CombatAbilityPointsAssigned = math.max(0, preset.NumStartingCombatAbilityPoints - data.Ability)
					playerData.Customization.State.CivilAbilityPointsAssigned = math.max(0, preset.NumStartingCivilAbilityPoints - data.Civil)
					playerData.Customization.State.TalentPointsAssigned = math.max(0, preset.NumStartingTalentPoints - data.Talent)
				end

				SheetManager.UI.CharacterCreation.UpdateAvailablePoints()
			end
		end
	end)
else
	local _ProcessPointChangeOpts = {SkipListenerInvoke=true, SkipSync=true}

	---@class CharacterExpansionLibProcessPointChangeOptions
	---@field ID string
	---@field Mod Guid
	---@field StatType SheetStatType
	---@field Value integer|boolean
	---@field IsGameMaster boolean|nil
	---@field IsInCharacterCreation boolean|nil
	---@field AvailablePoints table|nil

	---@param character EsvCharacter
	---@param opts CharacterExpansionLibProcessPointChangeOptions
	local function ProcessPointChange(character, opts)
		--statId, statMod, statType, value, isGameMaster, isInCharacterCreation, availablePoints
		local value = opts.Value
		local characterId = GameHelpers.GetObjectID(character)
		local stat = SheetManager:GetEntryByID(opts.ID, opts.Mod, opts.StatType)
		if opts.IsGameMaster == nil then
			opts.IsGameMaster = character.IsGameMaster
		end
		if opts.IsInCharacterCreation == nil then
			opts.IsInCharacterCreation = character.CharCreationInProgress
		end
		if characterId and stat then
			--TODO CustomStat support
			if opts.IsGameMaster or not stat.UsePoints then
				SheetManager:SetEntryValue(stat, character, value, _ProcessPointChangeOpts)
				return true
			else
				local currentValue = stat:GetValue(character)
				local modifyPointsBy = 0
				if stat.ValueType == "number" then
					modifyPointsBy = currentValue - value
				elseif stat.ValueType == "boolean" then
					modifyPointsBy = currentValue ~= true and -1 or 1
				end
				if modifyPointsBy ~= 0 then
					if modifyPointsBy < 0 then
						local maxValue = SheetManager:GetMaxValue(stat)
						if maxValue ~= nil and currentValue >= maxValue then
							fprint(LOGLEVEL.ERROR, "[CharacterExpansionLib:ProcessPointChange] Requested value (%s) exceeds the max value (%s). Denying value change request for entry (%s)[%s] type(%s).", value, maxValue, opts.ID, opts.Mod, opts.StatType)
							return false
						end
						local points = SheetManager:GetBuiltinAvailablePointsForEntry(stat, character, opts.AvailablePoints)
						if points > 0 and SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy, opts.AvailablePoints) then
							SheetManager:SetEntryValue(stat, character, value, _ProcessPointChangeOpts)
							return true,opts.AvailablePoints
						end
					else
						if SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy, opts.AvailablePoints) then
							SheetManager:SetEntryValue(stat, character, value, _ProcessPointChangeOpts)
							return true,opts.AvailablePoints
						end
					end
				end
			end
		end
		return false
	end

	RegisterNetListener("CEL_SheetManager_RequestValueChange", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local player = GameHelpers.GetCharacter(data.NetID)
			--if ProcessPointChange(player, data.ID, data.Mod, data.StatType, data.Value, data.IsGameMaster, data.IsInCharacterCreation, data.AvailablePoints) then
			if ProcessPointChange(player, data) then
				if data.AvailablePoints then
					GameHelpers.Net.PostToUser(player, "CEL_SheetManager_UpdateCCWizardAvailablePoints", data.AvailablePoints)
					SessionManager:SyncSession(player)
				else
					SheetManager:SyncData(player)
				end
			end
		end
	end)

	---@param character EsvCharacter
	local function _CheckTalentRequirements(character)
		local talents = SheetManager.Save.GetCharacterData(character.MyGuid, "Talent")
		if talents then
			--Clone so we aren't iterating a table that may be changing
			local tbl = TableHelpers.Clone(talents)
			local availablePoints = nil
			if character.CharCreationInProgress then
				availablePoints = SheetManager:GetAvailablePoints(character.MyGuid, "Talent", nil, character.CharCreationInProgress)
			end
			for modGuid,entries in pairs(tbl) do
				for id,b in pairs(entries) do
					if b then
						local talent = SheetManager:GetEntryByID(id, modGuid, "Talent") --[[@as SheetTalentData]]
						if talent and not talent:IsUnlockable(character) then
							--talent:SetValue(character, false)
							--id, modGuid, "Talent", false, character.IsGameMaster, character.CharCreationInProgress, availablePoints
							if ProcessPointChange(character, {
								Value=false, 
								ID=id,
								Mod=modGuid,
								StatType="Talent",
								AvailablePoints=availablePoints
							}) then
								if availablePoints then
									GameHelpers.Net.PostToUser(character, "CEL_SheetManager_UpdateCCWizardAvailablePoints", availablePoints)
									SessionManager:SyncSession(character)
								else
									SheetManager:SyncData(character)
								end
							end
						end
					end
				end
			end
		end
	end

	RegisterNetListener("CEL_SheetManager_RequestBaseValueChange", function(cmd, payload, user)
		local data = Common.JsonParse(payload)
		if data then
			assert(data.ModifyBy ~= "nil", "Payload needs a ModifyBy value (integer or boolean).")
			assert(type(data.NetID) == "number", "Payload needs a NetID.")
			assert(type(data.ID) == "string", "Payload needs an ID for the attribute/ability/talent.")
			assert(type(data.StatType) == "string", "Payload needs an StatType string value (Ability,Attribute,Talent).")
			local character = GameHelpers.GetCharacter(data.NetID)
			assert(character ~= nil, string.format("Failed to get character for NetID (%s).", data.NetID))
			
			if data.StatType == "Attribute" then
				Osi.NRD_PlayerSetBaseAttribute(character.MyGuid, data.ID, Osi.CharacterGetBaseAttribute(character.MyGuid, data.ID) + data.ModifyBy)
			elseif data.StatType == "Ability" then
				Osi.NRD_PlayerSetBaseAbility(character.MyGuid, data.ID, Osi.CharacterGetBaseAbility(character.MyGuid, data.ID) + data.ModifyBy)
			elseif data.StatType == "Talent" then
				Osi.NRD_PlayerSetBaseTalent(character.MyGuid, data.ID, data.ModifyBy)
			end

			--Force PlayerUpgrade sync
			Osi.CharacterAddCivilAbilityPoint(character.MyGuid, 0)

			_CheckTalentRequirements(character)
		end
	end)
end

--region Value Syncing
if not _ISCLIENT then
	---@protected
	---@param character Guid|EsvCharacter
	---@param user number|string|nil Optional client to sync to if character is nil.
	function SheetManager.Sync.EntryValues(character, user)
		character = GameHelpers.GetCharacter(character, "EsvCharacter")
		if character then
			local data = {
				NetID = character.NetID,
			}
			local values = {
				Stats = {},
				Abilities = {},
				Talents = {},
				CustomStats = {}
			}
			for entry in SheetManager:GetAllEntries(false, true) do
				local value = entry:GetValue(character)
				local statTypeTable = values[SheetManager.Save.GetTableNameForType(entry.StatType)]
				if statTypeTable ~= nil then
					local modTable = statTypeTable[entry.Mod] or {}
					statTypeTable[entry.Mod] = modTable
					modTable[entry.ID] = value
				end
			end
			data.Values = values
			-- if PersistentVars.CharacterSheetValues[character.MyGuid] ~= nil then
			-- 	data.Values = TableHelpers.SanitizeTable(PersistentVars.CharacterSheetValues[character.MyGuid])
			-- end
			--fprint(LOGLEVEL.TRACE, "[SheetManager.Save.SyncEntryValues:SERVER] Syncing data for character (%s) NetID(%s) to client.", character.MyGuid, data.NetID)
			--GameHelpers.Net.PostToUser(character, "CEL_SheetManager_LoadCharacterSyncData", data)
			GameHelpers.Net.PostToUser(character, "CEL_SheetManager_LoadAllCharacterEntryValues", data)
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
					assert(entry ~= nil, string.format("Failed to get sheet entry from id(%s) mod(%s) entryType(%s)", id, modid, entryType))
					local last = entryType == "Talents" and false or 0
					if lastValues and lastValues[entryType] and lastValues[entryType][modid] and lastValues[entryType][modid][id] then
						last = lastValues[entryType][modid][id]
					end
					self.Events.OnEntryChanged:Invoke({
						ModuleUUID = entry.Mod,
						EntryType = entry.Type,
						Stat = entry,
						ID = entry.ID,
						LastValue = last,
						Value = value,
						Character = character,
						CharacterID = GameHelpers.GetObjectID(character),
						IsClient = _ISCLIENT,
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
					local character = GameHelpers.GetCharacter(netid)
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
				GameHelpers.Net.PostMessageToServer("CEL_SheetManager_RequestCharacterSync", client.NetID)
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
				local character = GameHelpers.GetCharacter(data.NetID)
				if character then
					NotifyValueChanges(character, lastValues, self.CurrentValues[data.NetID])
				end
			else
				delayNotify = true
			end
		end
	end)

	RegisterNetListener("CEL_SheetManager_LoadAllCharacterEntryValues", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			assert(type(data.NetID) == "number", "NetID is invalid.")
			assert(data.Values ~= nil, "Payload has no Values table.")
			local character = GameHelpers.GetCharacter(data.NetID)
			if character then
				for statType,mods in pairs(data.Values) do
					for modId,entries in pairs(mods) do
						for id,value in pairs(entries) do
							local stat = SheetManager:GetEntryByID(id, modId, statType)
							if stat then
								SheetManager:SetEntryValue(stat, character, value, SessionManager.SetValuesOptions)
							end
						end
					end
				end
			end
		end
	end)
end
--endregion

if _ISCLIENT then
	RegisterNetListener("CEL_SheetManager_EntryValueChanged", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local character = GameHelpers.GetCharacter(data.NetID, "EclCharacter")
			local stat = SheetManager:GetEntryByID(data.ID, data.Mod, data.StatType)
			if character and stat then
				local skipInvoke = data.SkipInvoke
				if skipInvoke == nil then
					skipInvoke = false
				end
				SheetManager:SetEntryValue(stat, character, data.Value, {SkipListenerInvoke=skipInvoke, SkipSync=true, SkipRequest=true,})
				--SheetManager.Save.SetEntryValue(characterId, stat, data.Value)
			end
		end
	end)
end