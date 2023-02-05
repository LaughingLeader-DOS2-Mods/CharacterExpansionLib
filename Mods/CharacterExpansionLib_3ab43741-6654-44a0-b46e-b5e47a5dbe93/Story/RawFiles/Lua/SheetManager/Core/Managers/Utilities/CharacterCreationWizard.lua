---@class CharacterCreationWizard
local CharacterCreationWizard = {}

---@private
---@class CCAbilityChangeEntry
---@field Ability string
---@field AmountIncreased integer

---@private
---@class CCAttributeChangeEntry
---@field Attribute string
---@field AmountIncreased integer

---@class CCWizardTalents
---@field ItemMovement boolean
---@field ItemCreation boolean
---@field Flanking boolean
---@field AttackOfOpportunity boolean
---@field Backstab boolean
---@field Trade boolean
---@field Lockpick boolean
---@field ChanceToHitRanged boolean
---@field ChanceToHitMelee boolean
---@field Damage boolean
---@field ActionPoints boolean
---@field ActionPoints2 boolean
---@field Criticals boolean
---@field IncreasedArmor boolean
---@field Sight boolean
---@field ResistFear boolean
---@field ResistKnockdown boolean
---@field ResistStun boolean
---@field ResistPoison boolean
---@field ResistSilence boolean
---@field ResistDead boolean
---@field Carry boolean
---@field Throwing boolean
---@field Repair boolean
---@field ExpGain boolean
---@field ExtraStatPoints boolean
---@field ExtraSkillPoints boolean
---@field Durability boolean
---@field Awareness boolean
---@field Vitality boolean
---@field FireSpells boolean
---@field WaterSpells boolean
---@field AirSpells boolean
---@field EarthSpells boolean
---@field Charm boolean
---@field Intimidate boolean
---@field Reason boolean
---@field Luck boolean
---@field Initiative boolean
---@field InventoryAccess boolean
---@field AvoidDetection boolean
---@field AnimalEmpathy boolean
---@field Escapist boolean
---@field StandYourGround boolean
---@field SurpriseAttack boolean
---@field LightStep boolean
---@field ResurrectToFullHealth boolean
---@field Scientist boolean
---@field Raistlin boolean
---@field MrKnowItAll boolean
---@field WhatARush boolean
---@field FaroutDude boolean
---@field Leech boolean
---@field ElementalAffinity boolean
---@field FiveStarRestaurant boolean
---@field Bully boolean
---@field ElementalRanger boolean
---@field LightningRod boolean
---@field Politician boolean
---@field WeatherProof boolean
---@field LoneWolf boolean
---@field Zombie boolean
---@field Demon boolean
---@field IceKing boolean
---@field Courageous boolean
---@field GoldenMage boolean
---@field WalkItOff boolean
---@field FolkDancer boolean
---@field SpillNoBlood boolean
---@field Stench boolean
---@field Kickstarter boolean
---@field WarriorLoreNaturalArmor boolean
---@field WarriorLoreNaturalHealth boolean
---@field WarriorLoreNaturalResistance boolean
---@field RangerLoreArrowRecover boolean
---@field RangerLoreEvasionBonus boolean
---@field RangerLoreRangedAPBonus boolean
---@field RogueLoreDaggerAPBonus boolean
---@field RogueLoreDaggerBackStab boolean
---@field RogueLoreMovementBonus boolean
---@field RogueLoreHoldResistance boolean
---@field NoAttackOfOpportunity boolean
---@field WarriorLoreGrenadeRange boolean
---@field RogueLoreGrenadePrecision boolean
---@field WandCharge boolean
---@field DualWieldingDodging boolean
---@field Human_Inventive boolean
---@field Human_Civil boolean
---@field Elf_Lore boolean
---@field Elf_CorpseEating boolean
---@field Dwarf_Sturdy boolean
---@field Dwarf_Sneaking boolean
---@field Lizard_Resistance boolean
---@field Lizard_Persuasion boolean
---@field Perfectionist boolean
---@field Executioner boolean
---@field ViolentMagic boolean
---@field QuickStep boolean
---@field Quest_SpidersKiss_Str boolean
---@field Quest_SpidersKiss_Int boolean
---@field Quest_SpidersKiss_Per boolean
---@field Quest_SpidersKiss_Null boolean
---@field Memory boolean
---@field Quest_TradeSecrets boolean
---@field Quest_GhostTree boolean
---@field BeastMaster boolean
---@field LivingArmor boolean
---@field Torturer boolean
---@field Ambidextrous boolean
---@field Unstable boolean
---@field ResurrectExtraHealth boolean
---@field NaturalConductor boolean
---@field Quest_Rooted boolean
---@field PainDrinker boolean
---@field DeathfogResistant boolean
---@field Sourcerer boolean
---@field Rager boolean
---@field Elementalist boolean
---@field Sadist boolean
---@field Haymaker boolean
---@field Gladiator boolean
---@field Indomitable boolean
---@field WildMag boolean
---@field Jitterbug boolean
---@field Soulcatcher boolean
---@field MasterThief boolean
---@field GreedyVessel boolean
---@field MagicCycles boolean

---@class CCWizardAbilities:CCWizardTalents
---@field WarriorLore CCAbilityChangeEntry
---@field RangerLore CCAbilityChangeEntry
---@field RogueLore CCAbilityChangeEntry
---@field SingleHanded CCAbilityChangeEntry
---@field TwoHanded CCAbilityChangeEntry
---@field Reflection CCAbilityChangeEntry
---@field Ranged CCAbilityChangeEntry
---@field Shield CCAbilityChangeEntry
---@field Reflexes CCAbilityChangeEntry
---@field PhysicalArmorMastery CCAbilityChangeEntry
---@field Sourcery CCAbilityChangeEntry
---@field Telekinesis CCAbilityChangeEntry
---@field FireSpecialist CCAbilityChangeEntry
---@field WaterSpecialist CCAbilityChangeEntry
---@field AirSpecialist CCAbilityChangeEntry
---@field EarthSpecialist CCAbilityChangeEntry
---@field Necromancy CCAbilityChangeEntry
---@field Summoning CCAbilityChangeEntry
---@field Polymorph CCAbilityChangeEntry
---@field Sulfurology CCAbilityChangeEntry
---@field Repair CCAbilityChangeEntry
---@field Sneaking CCAbilityChangeEntry
---@field Pickpocket CCAbilityChangeEntry
---@field Thievery CCAbilityChangeEntry
---@field Loremaster CCAbilityChangeEntry
---@field Crafting CCAbilityChangeEntry
---@field Barter CCAbilityChangeEntry
---@field Charm CCAbilityChangeEntry
---@field Intimidate CCAbilityChangeEntry
---@field Reason CCAbilityChangeEntry
---@field Persuasion CCAbilityChangeEntry
---@field Leadership CCAbilityChangeEntry
---@field Luck CCAbilityChangeEntry
---@field DualWielding CCAbilityChangeEntry
---@field Wand CCAbilityChangeEntry
---@field MagicArmorMastery CCAbilityChangeEntry
---@field VitalityMastery CCAbilityChangeEntry
---@field Perseverance CCAbilityChangeEntry
---@field Runecrafting CCAbilityChangeEntry
---@field Brewmaster CCAbilityChangeEntry

---@class CCWizardAttributes:CCWizardAbilities
---@field Strength CCAttributeChangeEntry
---@field Finesse CCAttributeChangeEntry
---@field Intelligence CCAttributeChangeEntry
---@field Constitution CCAttributeChangeEntry
---@field Memory CCAttributeChangeEntry
---@field Wit CCAttributeChangeEntry

---@class CCWizardCurrentStats:CCWizardAttributes

---Get the current available point values of the CC wizard. This table isn't linked with metadata, so don't use it for long-term point referencing.
---@return CCWizardAvailablePoints
function CharacterCreationWizard.GetAvailablePointsAsTable()
	local ccwiz = Ext.UI.GetCharacterCreationWizard()
	if ccwiz then
		return {
			Attribute = ccwiz.AvailablePoints.Attribute,
			Ability = ccwiz.AvailablePoints.Ability,
			Civil = ccwiz.AvailablePoints.Civil,
			Talent = ccwiz.AvailablePoints.Talent,
			SkillSlots = ccwiz.AvailablePoints.SkillSlots,
		}
	end
	fprint(LOGLEVEL.ERROR, "[CharacterCreationWizard] Failed to get current available points.")
	return {
		Attribute = 0,
		Ability = 0,
		Civil = 0,
		Talent = 0,
		SkillSlots = 0,
	}
end

---@class CCWizardAvailablePoints
---@field Attribute integer
---@field Ability integer
---@field Civil integer
---@field Talent integer
---@field SkillSlots integer
CharacterCreationWizard.AvailablePoints = {}
setmetatable(CharacterCreationWizard.AvailablePoints, {
	__index = function(tbl, k)
		local ccwiz = Ext.UI.GetCharacterCreationWizard()
		if ccwiz then
			local points = ccwiz.AvailablePoints
			if k == "Attribute" then
				return points.Attribute
			elseif k == "Ability" then
				return points.Ability
			elseif k == "Civil" then
				return points.Civil
			elseif k == "Talent" then
				return points.Talent
			elseif k == "SkillSlots" then
				return points.SkillSlots
			end
		end
	end,
	-- __newindex = function(tbl, k, v)
	-- 	local ccwiz = Ext.UI.GetCharacterCreationWizard()
	-- 	if ccwiz then
	-- 		local points = ccwiz.AvailablePoints
	-- 		if k == "Attribute" then
	-- 			points[1] = v
	-- 		elseif k == "Ability" then
	-- 			points[2] = v
	-- 		elseif k == "Civil" then
	-- 			points[3] = v
	-- 		elseif k == "Talent" then
	-- 			points[5] = v
	-- 		elseif k == "SkillSlots" then
	-- 			points[4] = v
	-- 		end
	-- 	end
	-- end
})

---@param character  EclCharacter
local function GetWizCustomizationForCharacter(character)
	local ccwiz = Ext.UI.GetCharacterCreationWizard()
	if ccwiz then
		for i,v in pairs(ccwiz.CharacterCreationManager.Customizations) do
			local entryCharacter = GameHelpers.GetCharacter(v.CharacterHandle)
			if entryCharacter and entryCharacter.NetID == character.NetID then
				return v.State
			end
		end
	end

	return nil
end

CharacterCreationWizard.GetWizCustomizationForCharacter = GetWizCustomizationForCharacter

---Get the current available point values of the CC wizard. This table isn't linked with metadata, so don't use it for long-term point referencing.
---@return CCWizardAvailablePoints
function CharacterCreationWizard.GetStatsAsTable()
	local ccwiz = Ext.UI.GetCharacterCreationWizard()
	if ccwiz then
		local player = GameHelpers.Client.GetCharacterCreationCharacter()
		local customization = GetWizCustomizationForCharacter(player)
		if customization then
			local stats = {}
			for i,k in Data.Attribute:Get() do
				stats[k] = player.Stats[k]
			end
			for i,k in Data.Ability:Get() do
				stats[k] = player.Stats[k]
			end
			for i,k in Data.Talents:Get() do
				local talentid = "TALENT_" .. k
				stats[talentid] = player.Stats[talentid]
			end
			for i,v in pairs(customization.Class.AttributeChanges) do
				stats[v.Attribute] = stats[v.Attribute] + v.AmountIncreased
			end
			for i,v in pairs(customization.Class.AbilityChanges) do
				stats[v.Ability] = stats[v.Ability] + v.AmountIncreased
			end
			for i,v in pairs(customization.Class.TalentsAdded) do
				stats["TALENT_" .. v] = true
			end
			return stats
		end
	end
	fprint(LOGLEVEL.ERROR, "[CharacterCreationWizard] Failed to get current available points.")
	return {
		Attribute = 0,
		Ability = 0,
		Civil = 0,
		Talent = 0,
		SkillSlots = 0,
	}
end

local function GetCharacterStats(character)
	character = GameHelpers.GetCharacter(character)
	if character then
		local netid = character.NetID
		local customization = GetWizCustomizationForCharacter(character)
		if customization then
			local stats = {}
			setmetatable(stats, {
				__index = function (tbl, k)
					local player = GameHelpers.GetCharacter(netid, "EclCharacter")
					local customization = GetWizCustomizationForCharacter(player)
					assert(customization ~= nil, "Failed to get CC Customization for character")
					local base, current = 0,0
					if string.find(k, "TALENT_") then
						k = StringHelpers.Replace(k, "TALENT_", "")
					end
					local baseStatHolder = player.Stats.DynamicStats[1]
					if SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION then
						--The character is likely the dummy being transformed. Stat changes apply immediately.
						baseStatHolder = {}
					end
					if Data.AttributeEnum[k] then
						base = (baseStatHolder[k] or 0) + GameHelpers.GetExtraData("AttributeBaseValue", 10)
						current = base
						for i,v in pairs(customization.Class.AttributeChanges) do
							if v.Attribute == k then
								current = base + v.AmountIncreased
								break
							end
						end
					elseif Data.AbilityEnum[k] then
						base = (baseStatHolder[k] or 0) + GameHelpers.GetExtraData("AbilityBaseValue", 0)
						current = base
						for i,v in pairs(customization.Class.AbilityChanges) do
							if v.Ability == k then
								current = base + v.AmountIncreased
								break
							end
						end
					elseif Data.TalentEnum[k] then
						base = baseStatHolder["TALENT_" .. k] or false
						current = base
						for i,v in pairs(customization.Class.TalentsAdded) do
							if v == k then
								current = true
								break
							end
						end
					end

					return current
				end,
				__newindex = function (tbl, k, value)
					local player = GameHelpers.GetCharacter(netid)
					local customization = GetWizCustomizationForCharacter(player)
					if Data.AttributeEnum[k] then
						for i,v in pairs(customization.Class.AttributeChanges) do
							if v.Attribute == k then
								v.AmountIncreased = value
								return
							end
						end
						table.insert(customization.Class.AttributeChanges, {Attribute = k, AmountIncreased = value})
					elseif Data.AbilityEnum[k] then
						for i,v in pairs(customization.Class.AbilityChanges) do
							if v.Ability == k then
								v.AmountIncreased = value
								return
							end
						end
						table.insert(customization.Class.AbilityChanges, {Ability = k, AmountIncreased = value})
					elseif Data.TalentEnum[k] then
						for i,v in pairs(customization.Class.TalentsAdded) do
							if v == k then
								return
							end
						end
						table.insert(customization.Class.TalentsAdded, k)
					end
				end
			})
			return stats
		end
	end
end

---@type table<NETID,CCWizardCurrentStats>
CharacterCreationWizard.Stats = {}
setmetatable(CharacterCreationWizard.Stats, {
	__index = function(tbl, k)
		return GetCharacterStats(k)
	end
})

return CharacterCreationWizard