--This file is never actually loaded, and is used to make EmmyLua work better.

--For auto-completion
if Mods == nil then Mods = {} end
if Mods.CharacterExpansionLib == nil then
	---@class CharacterExpansionLib
	---@field SheetManager SheetManager
	Mods.CharacterExpansionLib = {}
end

---@alias SHEET_ENTRY_ID string
---@alias MOD_UUID string

---@alias AnyStatEntryIDType string|integer
---@alias AvailablePointsType "Attribute"|"Ability"|"Civil"|"Talent"|"Custom"
---@alias SetCharacterCreationOriginSkillsCallback fun(player:EclCharacter, origin:string, race:string, skills:string[]):string[]
---@alias SheetAbilityGroupID string |"Weapons"|"Defense"|"Skills"|"Personality"|"Craftsmanship"|"NastyDeeds"
---@alias SheetEntryDataType "SheetAbilityData"|"SheetCustomStatData"|"SheetCustomStatCategoryData"|"SheetStatData"|"SheetTalentData"
---@alias SheetEntryType "PrimaryStat"|"SecondaryStat"|"Ability"|"CivilAbility"|"Talent"|"Custom"
---@alias StatSheetSecondaryStatType "Info"|"Normal"|"Resistance"
---@alias StatSheetStatType "PrimaryStat"|"SecondaryStat"|"Spacing"