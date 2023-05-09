local self = SheetManager
local _ISCLIENT = Ext.IsClient()

local function ErrorMessage(prefix, txt, ...)
	if #{...} > 0 then
		return prefix .. string.format(txt, ...)
	else
		return prefix .. txt
	end
end

---@param characterId GUID|NETID
---@param character EsvCharacter|EclCharacter
---@param stat SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@param value integer|boolean
---@param isInCharacterCreation boolean|nil
---@param skipSessionCheck boolean|nil
local function SetValue(characterId, character, stat, value, isInCharacterCreation, skipSessionCheck)
	if not StringHelpers.IsNullOrWhitespace(stat.BoostAttribute) then
		if character and character.Stats then
			if not _ISCLIENT then
				---@cast characterId GUID
				if stat.StatType == "Talent" then
					if not string.find(stat.BoostAttribute, "TALENT_") then
						Osi.NRD_CharacterSetPermanentBoostTalent(characterId, stat.BoostAttribute, value)
					else
						Osi.NRD_CharacterSetPermanentBoostTalent(characterId, string.gsub(stat.BoostAttribute, "TALENT_", ""), value)
					end
					Osi.CharacterAddAttribute(characterId, "Dummy", 0)
					--character.Stats.DynamicStats[2][stat.BoostAttribute] = value
				else
					Osi.NRD_CharacterSetPermanentBoostInt(characterId, stat.BoostAttribute, value)
					-- Sync boost changes
					Osi.CharacterAddAttribute(character.MyGuid, "Dummy", 0)
					--character.Stats.DynamicStats[2][stat.BoostAttribute] = value
				end
				-- local success = character.Stats.DynamicStats[2][stat.BoostAttribute] == value
				-- fprint(LOGLEVEL.DEFAULT, "[%s][SetEntryValue:%s] BoostAttribute(%s) Changed(%s) Current(%s) => Desired(%s)", isClient and "CLIENT" or "SERVER", stat.ID, stat.BoostAttribute, success, character.Stats.DynamicStats[2][stat.BoostAttribute], value)
			else
				if not isInCharacterCreation then
					character.Stats.DynamicStats[2][stat.BoostAttribute] = value
				else
					local state = SessionManager.CharacterCreationWizard.GetWizCustomizationForCharacter(character)
					if state then
						if Data.Ability[stat.BoostAttribute] then
							---@cast value integer
							for i,v in pairs(state.Class.AbilityChanges) do
								if v.Ability == stat.BoostAttribute then
									v.AmountIncreased = value
									return
								end
							end
							table.insert(state.Class.AbilityChanges, {
								Ability = stat.BoostAttribute,
								AmountIncreased = value
							})
						elseif Data.Attribute[stat.BoostAttribute] then
							---@cast value integer
							for i,v in pairs(state.Class.AttributeChanges) do
								if v.Attribute == stat.BoostAttribute then
									v.AmountIncreased = value
									return
								end
							end
							table.insert(state.Class.AttributeChanges, {
								Attribute = stat.BoostAttribute,
								AmountIncreased = value
							})
						elseif Data.Talents[stat.BoostAttribute] then
							---@cast value boolean
							for i,v in pairs(state.Class.TalentsAdded) do
								if v == stat.BoostAttribute then
									if value == false then
										table.remove(state.Class.TalentsAdded, i)
									end
									return
								end
							end
							table.insert(state.Class.TalentsAdded, stat.BoostAttribute)
						end
					end
				end
			end
		else
			fprint(LOGLEVEL.ERROR, "[%s][SetEntryValue:%s] Failed to get character from id (%s)", _ISCLIENT and "CLIENT" or "SERVER", stat.ID, characterId)
		end
	else
		if _ISCLIENT or (stat.StatType ~= "Custom" or not SheetManager.CustomStats:GMStatsEnabled()) then
			SheetManager.Save.SetEntryValue(character, stat, value, skipSessionCheck)
		elseif type(value) == "number" then
			---@cast value integer
			if StringHelpers.IsNullOrWhitespace(stat.UUID) and not _ISCLIENT then
				stat.UUID = Ext.CustomStat.Create(stat.DisplayName, stat.Description)
			end
			if StringHelpers.IsNullOrWhitespace(stat.UUID) then
				character:SetCustomStat(stat.UUID, value)
			end
		end
	end
end

---@param stat SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData
---@param character EsvCharacter|EclCharacter
---@param value integer|boolean
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
---@param force boolean|nil Skip requesting changes if on the client side.
---@param skipSessionCheck boolean|nil Used by the SessionManager to write changes directly when applying changes.
function SheetManager:SetEntryValue(stat, character, value, skipListenerInvoke, skipSync, force, skipSessionCheck)
	local characterId = GameHelpers.GetObjectID(character)
	local last = stat:GetValue(character)
	local character = GameHelpers.GetCharacter(characterId, "EsvCharacter")
	local isInCharacterCreation = not skipSessionCheck and SheetManager.IsInCharacterCreation(character)

	if _ISCLIENT and not force then
		---@cast characterId NETID
		self:RequestValueChange(stat, characterId, value, false)
	else
		SetValue(characterId, character, stat, value, isInCharacterCreation, skipSessionCheck)
	end

	if stat.StatType == self.StatType.Custom then
		stat:UpdateLastValue(character)
	end

	if isInCharacterCreation then
		skipListenerInvoke = true
	end

	if not skipListenerInvoke then
		value = stat:GetValue(character)

		self.Events.OnEntryChanged:Invoke({
			ModuleUUID = stat.Mod,
			EntryType = stat.Type,
			Stat = stat,
			ID = stat.ID,
			LastValue = last,
			Value = value,
			Character = character,
			CharacterID = characterId,
			IsClient = _ISCLIENT,
		})
		
		if not _ISCLIENT then
			if stat.StatType == "Ability" then
				Osi.CharacterBaseAbilityChanged(character.MyGuid, stat.ID, last, value)
			elseif stat.StatType == "Talent" then
				if value then
					Osi.CharacterUnlockedTalent(character.MyGuid, stat.ID)
				else
					Osi.CharacterLockedTalent(character.MyGuid, stat.ID)
				end
			end
		end
	end
	if skipSync ~= true and not _ISCLIENT then
		GameHelpers.Net.Broadcast("CEL_SheetManager_EntryValueChanged", {
			ID = stat.ID,
			Mod = stat.Mod,
			NetID = GameHelpers.GetNetID(characterId),
			Value = value,
			StatType = stat.StatType,
			IsInCharacterCreation = isInCharacterCreation
		})
	end
end

---Add an amount to a stat value.
---@param character EsvCharacter|EclCharacter
---@param id string The stat ID.
---@param amount integer|boolean
---@param modGUID GUID|nil The ModuleUUID for the stat.
---@param statType SheetEntryType|nil Stat type.
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetManager:ModifyValueByID(character, id, amount, modGUID, statType, skipListenerInvoke, skipSync)
	local stat = self:GetEntryByID(id, modGUID, statType)
	if stat then
		stat:ModifyValue(character, amount, skipListenerInvoke, skipSync)
	end
end

---Set a stat value.
---@param character EsvCharacter|EclCharacter
---@param id string The stat ID.
---@param value integer|boolean
---@param modGUID GUID|nil The ModuleUUID for the stat.
---@param statType SheetEntryType|nil Stat type.
---@param skipListenerInvoke boolean|nil If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync boolean|nil If on the client and this is true, the value change won't be sent to the server.
function SheetManager:SetValueByID(character, id, value, modGUID, statType, skipListenerInvoke, skipSync)
	local stat = self:GetEntryByID(id, modGUID, statType)
	if stat then
		stat:SetValue(character, value, skipListenerInvoke, skipSync)
	end
end

---@param player EsvCharacter|EclCharacter
---@param entryType StatSheetStatType
---@param isCivil boolean|nil
---@return integer
local function _GetPoints(player, entryType, isCivil)
	if player.PlayerUpgrade then
		if entryType == "PrimaryStat" then
			return player.PlayerUpgrade.AttributePoints
		elseif entryType == "Ability" then
			if isCivil == true then
				return player.PlayerUpgrade.CivilAbilityPoints
			else
				return player.PlayerUpgrade.CombatAbilityPoints
			end
		elseif entryType == "Talent" then
			return player.PlayerUpgrade.TalentPoints
		end
	end
	return 0
end

---@param player EclCharacter|EsvCharacter
---@param entryType StatSheetStatType
---@param isCivil boolean|nil
---@param amount integer
---@param pointID string
local function _SetPoints(player, entryType, isCivil, amount, pointID)
	if player.PlayerUpgrade then
		if entryType == "PrimaryStat" then
			player.PlayerUpgrade.AttributePoints = player.PlayerUpgrade.AttributePoints + amount
		elseif entryType == "Ability" then
			if isCivil == true then
				player.PlayerUpgrade.CivilAbilityPoints = player.PlayerUpgrade.CivilAbilityPoints + amount
			else
				player.PlayerUpgrade.CombatAbilityPoints = player.PlayerUpgrade.CombatAbilityPoints + amount
			end
		elseif entryType == "Talent" then
			player.PlayerUpgrade.TalentPoints = player.PlayerUpgrade.TalentPoints + amount
		end
	end
end

---Changes available points by a value, such as adding -1 to attribute points.
---@param entry SheetStatData|SheetAbilityData|SheetTalentData|SheetCustomStatData
---@param character EsvCharacter|Guid|NETID
---@param amount integer
---@param availablePoints table|nil
---@return boolean success
function SheetManager:ModifyAvailablePointsForEntry(entry, character, amount, availablePoints)
	if amount == 0 then
		return true
	end
	local errorMessage = function(...) ErrorMessage("[SheetManager:ModifyAvailablePointsForEntry] ", ...) end

	assert(entry ~= nil and not StringHelpers.IsNullOrEmpty(entry.StatType), errorMessage("entry is isn't a SheetBaseData!"))
	assert(type(amount) == "number" and not GameHelpers.Math.IsNaN(amount), errorMessage("entry(%s) character(%s) amount(%s) - Amount is not a number!", entry.ID, character, amount))
	assert(character ~= nil, errorMessage("A valid character target is needed."))

	local entryType = entry.StatType
	local isCivil = entryType == "Ability" and entry.IsCivil
	local character = GameHelpers.GetCharacter(character)
	local characterId = GameHelpers.GetObjectID(character)
	
	if characterId then
		if availablePoints then
			if entryType == "PrimaryStat" then
				availablePoints.Attribute = availablePoints.Attribute + amount
			elseif entryType == "Ability" then
				if isCivil == true then
					availablePoints.Civil = availablePoints.Civil + amount
				else
					availablePoints.Ability = availablePoints.Ability + amount
				end
			elseif entryType == "Talent" then
				availablePoints.Talent = availablePoints.Talent + amount
			elseif entryType == "Custom" then
				local pointID = entry:GetAvailablePointsID()
				local current = entry:GetAvailablePoints(character)
				availablePoints[pointID] = current + amount
			end
			return true
		else
			local points = 0
			local pointID = ""
			if entryType == "Custom" then
				pointID = entry:GetAvailablePointsID()
				points = entry:GetAvailablePoints(character)
				if not _ISCLIENT then
					if SheetManager.CustomAvailablePoints[characterId] == nil then
						SheetManager.CustomAvailablePoints[characterId] = {}
					end
					SheetManager.CustomAvailablePoints[characterId][pointID] = amount
					SheetManager.Sync.CustomAvailablePoints(characterId)
				end
			else
				points = _GetPoints(character, entryType, isCivil)
				if not _ISCLIENT then
					_SetPoints(character, entryType, isCivil, amount, pointID)
				else
					Ext.Net.PostMessageToServer("CEL_SheetManager_RequestChangeAvailablePoints", Common.JsonStringify({
						Target = characterId,
						PointID = pointID,
						Value = amount
					}))
				end
			end
			if not _ISCLIENT then
				local updatedPoints = 0
				if entryType == "Custom" then
					updatedPoints = entry:GetAvailablePoints(character)
				else
					updatedPoints = _GetPoints(character, entryType, isCivil)
				end
				assert(points ~= updatedPoints, errorMessage("Failed to alter character(%s)'s (%s) points.", characterId, (entryType and isCivil) and "CivilAbility" or entryType))
			end
			SheetManager.Events.OnAvailablePointsChanged:Invoke({
				ModuleUUID = entry.Mod,
				EntryType = entry.Type,
				ID = entry.ID,
				Stat = entry,
				Character = character,
				CharacterID = characterId,
				LastValue = points,
				Value = points,
			})
		end
		return true
	end
	return false
end