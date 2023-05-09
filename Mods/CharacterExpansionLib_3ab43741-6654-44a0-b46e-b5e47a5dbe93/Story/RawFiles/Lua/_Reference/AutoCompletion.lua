--This file is never actually loaded, and is used to make EmmyLua work better.

--For auto-completion
if Mods == nil then Mods = {} end

---@class CharacterExpansionLib
---@field SheetManager SheetManager
---@field PersistentVars CharacterExpansionLibPersistentVars
Mods.CharacterExpansionLib = {
	Import = Import,
	UIOverrides = UIOverrides,
}


---@alias SheetEntryId string
---@alias ModGuid string

---@alias AnyStatEntryIDType string|integer
---@alias AnyStatEntryDataType SheetAbilityData|SheetStatData|SheetTalentData|SheetCustomStatData|SheetCustomStatCategoryData|SheetAbilityCategoryData
---@alias AvailablePointsType "Attribute"|"Ability"|"Civil"|"Talent"|"Custom"
---@alias SetCharacterCreationOriginSkillsCallback fun(player:EclCharacter, origin:string, race:string, skills:string[]):string[]
---@alias SheetAbilityCategoryID string |"Weapons"|"Defense"|"Skills"|"Personality"|"Craftsmanship"|"NastyDeeds"
---@alias SheetEntryDataType "SheetAbilityData"|"SheetCustomStatData"|"SheetCustomStatCategoryData"|"SheetStatData"|"SheetTalentData"
---@alias SheetEntryType "PrimaryStat"|"SecondaryStat"|"Ability"|"CivilAbility"|"Talent"|"Custom"|"CustomCategory"|"AbilityCategory"
---@alias StatSheetSecondaryStatType "Info"|"Stat"|"Resistance"|"Experience"
---@alias StatSheetStatType "PrimaryStat"|"SecondaryStat"|"Spacing"
---@alias PersistentVarsStatTypeTableName "Stats"|"Abilities"|"Talents"|"CustomStats"
---@alias SheetBuiltinType "Attribute"|"Ability"|"Talent"
---@alias SheetBuiltinSecondaryType "PrimaryStat"|"SecondaryStat"|"CombatAbility"|"CivilAbility"

---@class SheetManagerGetVisibleBaseOptions
---@field IsCharacterCreation boolean
---@field IsGM boolean
---@field Stats CDivinityStatsCharacter 