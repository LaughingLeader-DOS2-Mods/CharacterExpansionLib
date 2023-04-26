local ts = Classes.TranslatedString
local _ISCLIENT = Ext.IsClient()

---@class SheetManagerAbilities
SheetManager.Abilities = {
	---@type table<AbilityType, integer>
	EnabledDOSAbilities = {},
	---@type table<AbilityType, integer>
	HiddenBuiltinAbilities = {},
	Data = {
		GroupID = {
			Weapons = 0,
			Defense = 1,
			Skills = 2,
			Personality = 3,
			Craftsmanship = 4,
			NastyDeeds = 5,
		},
		GroupDisplayName = {
			[0] = ts:Create("h5fb2ef9cg4258g446eg9522gd6be58f3ab23", "Weapons"), -- May be a different handle
			[1] = ts:Create("ha65cecedg819dg4d17g9f0ag1bf646ec4f6c", "Defence"),
			[2] = ts:Create("hb5277ad5gafbcg4f31g8022gaeedf7a516aa", "Skills"), -- May be a different handle
			[3] = ts:Create("h3df7f54fg51f4g4355g93ecgb0b7add14018", "Personality"), -- or h5b78d698gab2ag4423g88d5gbfb549b015f8
			[4] = ts:Create("h2890aceag6c58g41a7gb286g5044fc11d7f1", "Craftsmanship"), -- or h7cc0941cg4b22g43a6gae93g3f3b240741cd
			[5] = ts:Create("he920062fg4553g4b1eg9935gec94a4c1aa59", "Nasty Deeds"), -- or hc92a5451g8a18g40f4g9a80g40bb23b98a8a
		},
		GroupIDInteger = {
			[0] = "Weapons",
			[1] = "Defense",
			[2] = "Skills",
			[3] = "Personality",
			[4] = "Craftsmanship",
			[5] = "NastyDeeds",
		},
		Abilities = {
			SingleHanded = {Group=0, Civil=false},
			TwoHanded = {Group=0, Civil=false},
			Ranged = {Group=0, Civil=false},
			DualWielding = {Group=0, Civil=false},
			PainReflection = {Group=1, Civil=false},
			Leadership = {Group=1, Civil=false},
			Perseverance = {Group=1, Civil=false},
			WarriorLore = {Group=2, Civil=false},
			RangerLore = {Group=2, Civil=false},
			RogueLore = {Group=2, Civil=false},
			FireSpecialist = {Group=2, Civil=false},
			WaterSpecialist = {Group=2, Civil=false},
			AirSpecialist = {Group=2, Civil=false},
			EarthSpecialist = {Group=2, Civil=false},
			Necromancy = {Group=2, Civil=false},
			Summoning = {Group=2, Civil=false},
			Polymorph = {Group=2, Civil=false},
			Barter = {Group=3, Civil=true},
			Persuasion = {Group=3, Civil=true},
			Luck = {Group=3, Civil=true},
			Telekinesis = {Group=4, Civil=true},
			Loremaster = {Group=4, Civil=true},
			Sneaking = {Group=5, Civil=true},
			Thievery = {Group=5, Civil=true},
		},
		DOSAbilities = {
			Shield = {Group=0, Civil=false},
			Reflexes = {Group=1, Civil=false},
			PhysicalArmorMastery = {Group=1, Civil=false},
			Sourcery = {Group=2, Civil=false},
			Sulfurology = {Group=2, Civil=false},
			Repair = {Group=1, Civil=true},
			Crafting = {Group=1, Civil=true},
			Charm = {Group=3, Civil=true},
			Intimidate = {Group=3, Civil=true},
			Reason = {Group=3, Civil=true},
			Wand = {Group=0, Civil=false},
			MagicArmorMastery = {Group=1, Civil=false},
			VitalityMastery = {Group=1, Civil=false},
			Runecrafting = {Group=4, Civil=true},
			Brewmaster = {Group=4, Civil=true},
			Pickpocket = {Group=5, Civil=true},
		}
	}
}


local missingAbilities = SheetManager.Abilities.Data.DOSAbilities
for name,v in pairs(missingAbilities) do
	SheetManager.Abilities.EnabledDOSAbilities[name] = 0
end

local Builtin = {}

SheetManager.Abilities.Builtin = Builtin

---Enables a base game ability.  
---@param abilityID string
function Builtin.EnableAbility(abilityID)
	if StringHelpers.Equals(abilityID, "all", true) then
		for ability,v in pairs(missingAbilities) do
			Builtin.EnableAbility(ability)
		end
	else
		if SheetManager.Abilities.Data.Abilities[abilityID] then
			local count = SheetManager.Abilities.HiddenBuiltinAbilities[abilityID] or 0
			count = math.max(0, count - 1)
			SheetManager.Abilities.HiddenBuiltinAbilities[abilityID] = count
		else
			local count = SheetManager.Abilities.EnabledDOSAbilities[abilityID] or 0
			count = count + 1
			SheetManager.Abilities.EnabledDOSAbilities[abilityID] = count
		end
	end
end

---Disables/hides a base game ability.  
---@param abilityID string
---@param skipClear? boolean Skip clearing the UI.
function Builtin.DisableAbility(abilityID, skipClear)
	if StringHelpers.Equals(abilityID, "all", true) then
		for ability,v in pairs(missingAbilities) do
			Builtin.DisableAbility(ability, true)
		end
		if not Vars.ControllerEnabled and not skipClear then
			GameHelpers.UI.TryInvoke(Data.UIType.characterSheet, "clearAbilities")
		end
	else
		if SheetManager.Abilities.Data.Abilities[abilityID] then
			local count = SheetManager.Abilities.HiddenBuiltinAbilities[abilityID] or 0
			count = math.max(0, count + 1)
			SheetManager.Abilities.HiddenBuiltinAbilities[abilityID] = count
		else
			local count = SheetManager.Abilities.EnabledDOSAbilities[abilityID] or 0
			count = count - 1
			SheetManager.Abilities.EnabledDOSAbilities[abilityID] = count
		end
	end
end

if _ISCLIENT then
	function Builtin.IsAbilityVisible(id)
		if SheetManager.Abilities.Data.Abilities[id] then
			local count = SheetManager.Abilities.HiddenBuiltinAbilities[id] or 0
			return count <= 0
		end
		if SheetManager.Abilities.Data.DOSAbilities[id] then
			local count = SheetManager.Abilities.EnabledDOSAbilities[id] or 0
			return count > 0
		end
		return false
	end

	function SheetManager.Abilities.UpdateCharacterSheetPoints(ui, method, main, amount)
		local character = Client:GetCharacter()
		if not character then
			return
		end

		local abilityPoints = SheetManager:GetAvailablePoints(character, "Ability")
		local civilPoints = SheetManager:GetAvailablePoints(character, "Civil")

		local maxAbility = GameHelpers.GetExtraData("CombatAbilityCap", 10)
		local maxCivil = GameHelpers.GetExtraData("CivilAbilityCap", 5)

		for abilityName,data in pairs(missingAbilities) do
			if SheetManager.Abilities.EnabledDOSAbilities[abilityName] > 0 then
				local abilityID = Data.AbilityEnum[abilityName]
				if not data.Civil then
					local canAddPoints = abilityPoints > 0 and character.Stats[abilityName] < maxAbility
					if not Vars.ControllerEnabled then
						main.stats_mc.setAbilityPlusVisible(false, data.Group, abilityID, abilityPoints > 0)
					else
						main.mainpanel_mc.stats_mc.combatAbilities_mc.setBtnVisible(data.Group, abilityID, true, canAddPoints)
					end
				else
					local canAddPoints = civilPoints > 0 and character.Stats[abilityName] < maxCivil
					if not Vars.ControllerEnabled then
						main.stats_mc.setAbilityPlusVisible(true, data.Group, abilityID, civilPoints > 0)
					else
						main.mainpanel_mc.stats_mc.civilAbilities_mc.setBtnVisible(data.Group, abilityID, true, canAddPoints)
					end
				end
			end
		end
	end

	---@class SheetManager.AbilitiesUIEntry
	---@field ID string
	---@field GeneratedID integer
	---@field DisplayName string
	---@field IsCivil boolean
	---@field GroupID integer
	---@field GroupDisplayName string
	---@field AddPointsTooltip string
	---@field RemovePointsTooltip string
	---@field Value integer
	---@field Delta integer
	---@field CanAdd boolean
	---@field CanRemove boolean
	---@field IsCustom boolean
	---@field Visible boolean
	---@field Mod Guid

	---@private
	---@param player EclCharacter
	---@param civilOnly boolean|nil
	---@param isCharacterCreation boolean|nil
	---@param isGM boolean|nil
	---@param availableAbilityPoints ?integer
	---@param availableCivilPoints ?integer
	---@return fun():SheetManager.AbilitiesUIEntry
	function SheetManager.Abilities.GetVisible(player, civilOnly, isCharacterCreation, isGM, availableAbilityPoints, availableCivilPoints)
		if isCharacterCreation == nil then
			isCharacterCreation = false
		end
		if isGM == nil then
			isGM = false
		end
		local entries = {}
		local tooltip = LocalizedText.UI.AbilityPlusTooltip:ReplacePlaceholders(Ext.ExtraData.CombatAbilityLevelGrowth)

		local abilityPoints = availableAbilityPoints or SheetManager:GetAvailablePoints(player, "Ability", nil, isCharacterCreation)
		local civilPoints = availableCivilPoints or SheetManager:GetAvailablePoints(player, "Civil", nil, isCharacterCreation)
	
		local maxAbility = GameHelpers.GetExtraData("CombatAbilityCap", 10)
		local maxCivil = GameHelpers.GetExtraData("CivilAbilityCap", 5)
		local baseValue = GameHelpers.GetExtraData("AbilityBaseValue", 0)

		local targetStats = SessionManager:CreateCharacterSessionMetaTable(player)

		--Defaults
		for numId,id in Data.Ability:Get() do
			local data = SheetManager.Abilities.Data.Abilities[id] or SheetManager.Abilities.Data.DOSAbilities[id]
			if data ~= nil and (civilOnly == nil or (civilOnly == true and data.Civil) or (civilOnly == false and not data.Civil)) then
				if Builtin.IsAbilityVisible(id) then
					local canAddPoints = isGM
					if not canAddPoints then
						if civilOnly then
							canAddPoints = civilPoints > 0 and targetStats[id] < maxCivil
						else
							canAddPoints = abilityPoints > 0 and targetStats[id] < maxAbility
						end
					end
					local name = GameHelpers.GetAbilityName(id)
					local isCivil = data.Civil == true
					local groupID = data.Group
					local statVal = targetStats[id] or 0
					local delta = statVal - baseValue

					---@type string|TranslatedString
					local groupName = SheetManager.Abilities.Data.GroupDisplayName[groupID]
					if groupName then
						groupName = groupName.Value
					else
						groupName = ""
					end

					---@type SheetManager.AbilitiesUIEntry
					local uiEntry = {
						ID = id,
						Mod = Data.ModID.Shared,
						GeneratedID = Data.AbilityEnum[id],
						DisplayName = name,
						IsCivil = isCivil,
						GroupID = groupID,
						GroupDisplayName = groupName,
						IsCustom = false,
						Value = statVal,
						Delta = delta,
						AddPointsTooltip = tooltip,
						RemovePointsTooltip = "",
						CanAdd = canAddPoints,
						CanRemove = isCharacterCreation or isGM,
						Visible = true,
					}
					entries[#entries+1] = uiEntry
				end
			end
		end

		for mod,dataTable in pairs(SheetManager.Data.Abilities) do
			for id,data in pairs(dataTable) do
				local value = data:GetValue(player)
				if SheetManager:IsEntryVisible(data, player, value) then
					local canAddPoints = false
					local maxVal = civilOnly and maxCivil or maxAbility
					if data.MaxValue then
						maxVal = data.MaxValue
					end
					if civilOnly then
						canAddPoints = civilPoints > 0 and value < maxVal
					else
						canAddPoints = abilityPoints > 0 and value < maxVal
					end

					---@type string|TranslatedString
					local groupName = SheetManager.Abilities.Data.GroupDisplayName[data.GroupID]
					if groupName then
						groupName = groupName.Value
					else
						groupName = ""
					end

					---@type SheetManager.AbilitiesUIEntry
					local uiEntry = {
						ID = data.ID,
						Mod = data.Mod,
						GeneratedID = data.GeneratedID,
						DisplayName = data:GetDisplayName(),
						IsCivil = data.IsCivil,
						GroupID = data.GroupID,
						GroupDisplayName = groupName,
						IsCustom = true,
						Value = string.format("%s", value) .. data.Suffix,
						Delta = value - baseValue,
						AddPointsTooltip = tooltip,
						RemovePointsTooltip = "",
						CanAdd = SheetManager:GetIsPlusVisible(data, player, canAddPoints, value),
						CanRemove = SheetManager:GetIsMinusVisible(data, player, isCharacterCreation or isGM, value),
						Visible = true
					}
					entries[#entries+1] = uiEntry
				end
			end
		end

		local i = 0
		local count = #entries
		return function ()
			i = i + 1
			if i <= count then
				return entries[i]
			end
		end
	end
end