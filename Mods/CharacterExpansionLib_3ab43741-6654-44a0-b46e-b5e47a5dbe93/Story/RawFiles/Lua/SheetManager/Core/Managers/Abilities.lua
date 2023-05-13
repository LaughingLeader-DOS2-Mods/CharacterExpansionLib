local ts = Classes.TranslatedString
local _ISCLIENT = Ext.IsClient()

---@class SheetManagerAbilities
SheetManager.Abilities = {
	---@type table<AbilityType, integer>
	EnabledDOSAbilities = {},
	---@type table<AbilityType, integer>
	HiddenBuiltinAbilities = {},
	Data = {
		CategoryID = {
			Weapons = 0,
			Defense = 1,
			Skills = 2,
			Personality = 3,
			Craftsmanship = 4,
			NastyDeeds = 5,
		},
		CategoryIDDisplayName = {
			[0] = ts:Create("h5fb2ef9cg4258g446eg9522gd6be58f3ab23", "Weapons"), -- May be a different handle
			[1] = ts:Create("ha65cecedg819dg4d17g9f0ag1bf646ec4f6c", "Defence"),
			[2] = ts:Create("hb5277ad5gafbcg4f31g8022gaeedf7a516aa", "Skills"), -- May be a different handle
			[3] = ts:Create("h3df7f54fg51f4g4355g93ecgb0b7add14018", "Personality"), -- or h5b78d698gab2ag4423g88d5gbfb549b015f8
			[4] = ts:Create("h2890aceag6c58g41a7gb286g5044fc11d7f1", "Craftsmanship"), -- or h7cc0941cg4b22g43a6gae93g3f3b240741cd
			[5] = ts:Create("he920062fg4553g4b1eg9935gec94a4c1aa59", "Nasty Deeds"), -- or hc92a5451g8a18g40f4g9a80g40bb23b98a8a
		},
		CategoryIDInteger = {
			[0] = "Weapons",
			[1] = "Defense",
			[2] = "Skills",
			[3] = "Personality",
			[4] = "Craftsmanship",
			[5] = "NastyDeeds",
		},
		Abilities = {
			SingleHanded = {CategoryID=0, Civil=false},
			TwoHanded = {CategoryID=0, Civil=false},
			Ranged = {CategoryID=0, Civil=false},
			DualWielding = {CategoryID=0, Civil=false},
			PainReflection = {CategoryID=1, Civil=false},
			Leadership = {CategoryID=1, Civil=false},
			Perseverance = {CategoryID=1, Civil=false},
			WarriorLore = {CategoryID=2, Civil=false},
			RangerLore = {CategoryID=2, Civil=false},
			RogueLore = {CategoryID=2, Civil=false},
			FireSpecialist = {CategoryID=2, Civil=false},
			WaterSpecialist = {CategoryID=2, Civil=false},
			AirSpecialist = {CategoryID=2, Civil=false},
			EarthSpecialist = {CategoryID=2, Civil=false},
			Necromancy = {CategoryID=2, Civil=false},
			Summoning = {CategoryID=2, Civil=false},
			Polymorph = {CategoryID=2, Civil=false},
			Barter = {CategoryID=3, Civil=true},
			Persuasion = {CategoryID=3, Civil=true},
			Luck = {CategoryID=3, Civil=true},
			Telekinesis = {CategoryID=4, Civil=true},
			Loremaster = {CategoryID=4, Civil=true},
			Sneaking = {CategoryID=5, Civil=true},
			Thievery = {CategoryID=5, Civil=true},
		},
		DOSAbilities = {
			Shield = {CategoryID=0, Civil=false},
			Reflexes = {CategoryID=1, Civil=false},
			PhysicalArmorMastery = {CategoryID=1, Civil=false},
			Sourcery = {CategoryID=2, Civil=false},
			Sulfurology = {CategoryID=2, Civil=false},
			Repair = {CategoryID=1, Civil=true},
			Crafting = {CategoryID=1, Civil=true},
			Charm = {CategoryID=3, Civil=true},
			Intimidate = {CategoryID=3, Civil=true},
			Reason = {CategoryID=3, Civil=true},
			Wand = {CategoryID=0, Civil=false},
			MagicArmorMastery = {CategoryID=1, Civil=false},
			VitalityMastery = {CategoryID=1, Civil=false},
			Runecrafting = {CategoryID=4, Civil=true},
			Brewmaster = {CategoryID=4, Civil=true},
			Pickpocket = {CategoryID=5, Civil=true},
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
						main.stats_mc.setAbilityPlusVisible(false, data.CategoryID, abilityID, abilityPoints > 0)
					else
						main.mainpanel_mc.stats_mc.combatAbilities_mc.setBtnVisible(data.CategoryID, abilityID, true, canAddPoints)
					end
				else
					local canAddPoints = civilPoints > 0 and character.Stats[abilityName] < maxCivil
					if not Vars.ControllerEnabled then
						main.stats_mc.setAbilityPlusVisible(true, data.CategoryID, abilityID, civilPoints > 0)
					else
						main.mainpanel_mc.stats_mc.civilAbilities_mc.setBtnVisible(data.CategoryID, abilityID, true, canAddPoints)
					end
				end
			end
		end
	end

	---@class SheetManager.AbilityCategoryUIEntry
	---@field ID string
	---@field Mod Guid
	---@field GeneratedID integer
	---@field DisplayName string
	---@field IsCivil boolean
	---@field Visible boolean

	---@class SheetManager.AbilitiesUIEntry
	---@field ID string
	---@field GeneratedID integer
	---@field DisplayName string
	---@field IsCivil boolean
	---@field CategoryID integer
	---@field CategoryDisplayName string
	---@field AddPointsTooltip string
	---@field RemovePointsTooltip string
	---@field Value {Value:integer, Label:string}
	---@field Delta integer
	---@field CanAdd boolean
	---@field CanRemove boolean
	---@field IsCustom boolean
	---@field Visible boolean
	---@field Mod Guid

	---@class SheetManagerAbilitiesGetVisibleOptions:SheetManagerGetVisibleBaseOptions
	---@field CivilOnly boolean
	---@field AvailableAbilityPoints integer
	---@field AvailableCivilPoints integer
	local DefaultOptions = {
		IsCharacterCreation = false,
		IsGM = false,
	}

	local function _CanDisplayBuiltin(entry, civilOnly)
		if civilOnly == nil then
			return true
		end
		return (civilOnly == true and entry.Civil) or (civilOnly == false and not entry.Civil)
	end

	---@private
	---@param player EclCharacter
	---@param opts? SheetManagerAbilitiesGetVisibleOptions
	---@return fun():SheetManager.AbilityCategoryUIEntry
	function SheetManager.Abilities.GetVisibleCategories(player, opts)
		local options = TableHelpers.SetDefaultOptions(opts, DefaultOptions)
		---@type SheetManager.AbilityCategoryUIEntry[]
		local entries = {}
		local len = 0

		local civilOnly = options.CivilOnly == true

		for mod,dataTable in pairs(SheetManager.Data.AbilityCategories) do
			for id,data in pairs(dataTable) do
				if data.Visible and data.IsCivil == civilOnly then
					len = len + 1
					entries[len] = {
						ID = data.ID,
						Mod = data.Mod,
						GeneratedID = data.GeneratedID,
						DisplayName = data:GetDisplayName(player),
						IsCivil = data.IsCivil,
						Visible = true
					}
				end
			end
		end

		if len > 1 then
			table.sort(entries, SheetManager.Utils.DisplayNameSort)
		end

		local i = 0
		return function ()
			i = i + 1
			if i <= len then
				return entries[i]
				---@diagnostic disable-next-line
			end
		end
	end

	---@private
	---@param player EclCharacter
	---@param opts? SheetManagerAbilitiesGetVisibleOptions
	---@return fun():SheetManager.AbilitiesUIEntry
	function SheetManager.Abilities.GetVisible(player, opts)
		local options = TableHelpers.SetDefaultOptions(opts, DefaultOptions)
		if options.Stats == nil then
			options.Stats = SessionManager:CreateCharacterSessionMetaTable(player)
		end
		local entries = {}
		local tooltip = LocalizedText.UI.AbilityPlusTooltip:ReplacePlaceholders(Ext.ExtraData.CombatAbilityLevelGrowth)

		local civilOnly = options.CivilOnly == true
		local abilityPoints = options.AvailableAbilityPoints or SheetManager:GetAvailablePoints(player, "Ability", nil, options.IsCharacterCreation)
		local civilPoints = options.AvailableCivilPoints or SheetManager:GetAvailablePoints(player, "Civil", nil, options.IsCharacterCreation)
		
		local MAX_ABILITY = GameHelpers.GetExtraData("CombatAbilityCap", 10)
		local MAX_CIVIL = GameHelpers.GetExtraData("CivilAbilityCap", 5)
		local BASE_ABILITY = GameHelpers.GetExtraData("AbilityBaseValue", 0)
		
		local defaultCanRemove = options.IsCharacterCreation or options.IsGM
		local targetStats = options.Stats

		--Defaults
		for numId,id in Data.Ability:Get() do
			local data = SheetManager.Abilities.Data.Abilities[id] or SheetManager.Abilities.Data.DOSAbilities[id]
			if data ~= nil and _CanDisplayBuiltin(data, civilOnly) then
				if Builtin.IsAbilityVisible(id) then
					local statVal = targetStats[id] or 0
					local baseVal = targetStats["Base"..id] or statVal
					local canAddPoints = options.IsGM
					if not canAddPoints then
						if civilOnly then
							canAddPoints = civilPoints > 0 and baseVal < MAX_CIVIL
						else
							canAddPoints = abilityPoints > 0 and baseVal < MAX_ABILITY
						end
					end
					local name = GameHelpers.GetAbilityName(id)
					local isCivil = data.Civil == true
					local groupID = data.CategoryID
					local delta = statVal - BASE_ABILITY

					---@type string|TranslatedString
					local groupName = SheetManager.Abilities.Data.CategoryIDDisplayName[groupID]
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
						CategoryID = groupID,
						CategoryDisplayName = groupName,
						IsCustom = false,
						Value = {Value=statVal, Label=tostring(statVal)},
						Delta = delta,
						AddPointsTooltip = tooltip,
						RemovePointsTooltip = "",
						CanAdd = canAddPoints,
						CanRemove = defaultCanRemove,
						Visible = true,
					}
					entries[#entries+1] = uiEntry
				end
			end
		end

		local customEntries = {}
		local customEntriesLen = 0

		for mod,dataTable in pairs(SheetManager.Data.Abilities) do
			for id,data in pairs(dataTable) do
				local value = SheetManager:GetValueByEntry(data, player)
				if SheetManager:IsEntryVisible(data, player, value) then
					local canAddPoints = false
					local maxVal = civilOnly and MAX_CIVIL or MAX_ABILITY
					if data.MaxValue then
						maxVal = data.MaxValue
					end
					if civilOnly then
						canAddPoints = civilPoints > 0 and value < maxVal
					else
						canAddPoints = abilityPoints > 0 and value < maxVal
					end

					local delta = value - BASE_ABILITY

					if id == "Sourcery" then
						Ext.Utils.PrintError(id, value, delta)
						if value == 0 then
							Ext.Dump(SessionManager.Sessions)
						end
					end

					local visible = true

					local groupName = ""
					local groupID = data.CategoryID

					if type(groupID) == "number" then
						if groupID <= 5 then
							---@type string|TranslatedString
							local groupNameEntry = SheetManager.Abilities.Data.CategoryIDDisplayName[groupID]
							if groupNameEntry then
								groupName = groupNameEntry.Value
							end
						else
							local category = SheetManager:GetEntryByGeneratedID(groupID, "AbilityCategory")
							if category and category.Visible then
								groupName = category:GetDisplayName(player)
							else
								visible = false
							end
						end
					end
					
					---@type SheetManager.AbilitiesUIEntry
					local uiEntry = {
						ID = data.ID,
						Mod = data.Mod,
						GeneratedID = data.GeneratedID,
						DisplayName = data:GetDisplayName(),
						IsCivil = data.IsCivil,
						CategoryID = groupID,
						CategoryDisplayName = groupName,
						IsCustom = true,
						Value = {Value=value, Label=string.format("%s%s", value, data.Suffix or "")},
						Delta = delta,
						AddPointsTooltip = tooltip,
						RemovePointsTooltip = "",
						CanAdd = SheetManager:GetIsPlusVisible(data, player, canAddPoints, value),
						CanRemove = SheetManager:GetIsMinusVisible(data, player, defaultCanRemove, value),
						Visible = visible
					}
					customEntriesLen = customEntriesLen + 1
					customEntries[customEntriesLen] = uiEntry
				end
			end
		end

		if customEntriesLen > 0 then
			if customEntriesLen > 1 then
				table.sort(customEntries, SheetManager.Utils.DisplayNameSort)
			end
			TableHelpers.AppendArrays(entries, customEntries)
		end

		local i = 0
		local count = #entries
		return function ()
			i = i + 1
			if i <= count then
				return entries[i]
				---@diagnostic disable-next-line
			end
		end
	end
end