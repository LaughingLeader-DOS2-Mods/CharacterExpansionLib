local self = SheetManager
local isClient = Ext.IsClient()

local function ErrorMessage(prefix, txt, ...)
	if #{...} > 0 then
		return prefix .. string.format(txt, ...)
	else
		return prefix .. txt
	end
end

local function SetValue(characterId, character, stat, value, isInCharacterCreation)
	if not StringHelpers.IsNullOrWhitespace(stat.BoostAttribute) then
		if character and character.Stats then
			if not isClient then
				if stat.StatType == "Talent" then
					if not string.find(stat.BoostAttribute, "TALENT_") then
						NRD_CharacterSetPermanentBoostTalent(characterId, stat.BoostAttribute, value)
					else
						NRD_CharacterSetPermanentBoostTalent(characterId, string.gsub(stat.BoostAttribute, "TALENT_", ""), value)
					end
					CharacterAddAttribute(characterId, "Dummy", 0)
					--character.Stats.DynamicStats[2][stat.BoostAttribute] = value
				else
					NRD_CharacterSetPermanentBoostInt(characterId, stat.BoostAttribute, value)
					-- Sync boost changes
					CharacterAddAttribute(character.MyGuid, "Dummy", 0)
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
						if Data.AbilityEnum[stat.BoostAttribute] then
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
						elseif Data.AttributeEnum[stat.BoostAttribute] then
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
						elseif Data.TalentEnum[stat.BoostAttribute] then
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
			fprint(LOGLEVEL.ERROR, "[%s][SetEntryValue:%s] Failed to get character from id (%s)", isClient and "CLIENT" or "SERVER", stat.ID, characterId)
		end
	else
		if isClient or stat.StatType ~= SheetManager.StatType.Custom or not CustomStatSystem:GMStatsEnabled() then
			SheetManager.Save.SetEntryValue(characterId, stat, value)
		else
			if StringHelpers.IsNullOrWhitespace(stat.UUID) and not isClient then
				stat.UUID = Ext.CreateCustomStat(stat.DisplayName, stat.Description)
			end
			if StringHelpers.IsNullOrWhitespace(stat.UUID) then
				character:SetCustomStat(stat.UUID, value)
			end
		end
	end
end

---@param stat SheetAbilityData|SheetStatData|SheetTalentData
---@param characterId UUID|NETID
---@param value integer|boolean
---@param skipListenerInvoke ?boolean If true, Listeners.OnEntryChanged invoking is skipped.
---@param skipSync ?boolean If on the client and this is true, the value change won't be sent to the server.
---@param force ?boolean Skip requesting changes if on the client side.
function SheetManager:SetEntryValue(stat, characterId, value, skipListenerInvoke, skipSync, force)
	local last = stat:GetValue(characterId)
	characterId = GameHelpers.GetCharacterID(characterId)
	local character = GameHelpers.GetCharacter(characterId)
	local isInCharacterCreation = SheetManager.IsInCharacterCreation(characterId)

	if isClient and not force then
		self:RequestValueChange(stat, characterId, value, false)
	else
		SetValue(characterId, character, stat, value, isInCharacterCreation)
	end

	if stat.StatType == SheetManager.StatType.Custom then
		stat:UpdateLastValue(character)
	end

	if isInCharacterCreation then
		skipListenerInvoke = true
	end

	if not skipListenerInvoke then
		value = stat:GetValue(character)

		if stat.StatType == SheetManager.StatType.Custom then
			CustomStatSystem:InvokeStatValueChangedListeners(stat, character, last, value)
		end

		for listener in self:GetListenerIterator(self.Listeners.OnEntryChanged[stat.ID], self.Listeners.OnEntryChanged.All) do
			local b,err = xpcall(listener, debug.traceback, stat.ID, stat, character, last, value, isClient)
			if not b then
				--fprint(LOGLEVEL.ERROR, "[CharacterExpansionLib:SheetManager:SetEntryValue] Error calling OnAvailablePointsChanged listener for stat (%s):\n%s", stat.ID, err)
			end
		end
		if not isClient then
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
	if skipSync ~= true and not isClient then
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

if not isClient then
	
	local function GetPoints(uuid, t, isCivil)
		if t == "PrimaryStat" then
			return CharacterGetAttributePoints(uuid) or 0
		elseif t == "Ability" then
			if isCivil == true then
				return CharacterGetCivilAbilityPoints(uuid) or 0
			else
				return CharacterGetAbilityPoints(uuid) or 0
			end
		elseif t == "Talent" then
			return CharacterGetTalentPoints(uuid) or 0
		end
	end
---Changes available points by a value, such as adding -1 to attribute points.
---@param entry SheetStatData|SheetAbilityData|SheetTalentData
---@param character EsvCharacter|UUID|NETID
---@param amount integer
---@param availablePoints ?SheetManagerAvailablePointsData
---@return boolean
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
	local characterId = GameHelpers.GetCharacterID(character)
	
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
			end
			return true, availablePoints
		else
			local points = GetPoints(characterId, entryType, isCivil)
			if entryType == "PrimaryStat" then
				CharacterAddAttributePoint(characterId, amount)
			elseif entryType == "Ability" then
				if isCivil == true then
					CharacterAddCivilAbilityPoint(characterId, amount)
				else
					CharacterAddAbilityPoint(characterId, amount)
				end
			elseif entryType == "Talent" then
				CharacterAddTalentPoint(characterId, amount)
			end
			SheetManager.Sync.CustomAvailablePoints(characterId)
			assert(points ~= GetPoints(characterId, entryType, isCivil), errorMessage("Failed to alter character(%s)'s (%s) points.", characterId, (entryType and isCivil) and "CivilAbility" or entryType))
		end
		return true
	end
	return false
end


end