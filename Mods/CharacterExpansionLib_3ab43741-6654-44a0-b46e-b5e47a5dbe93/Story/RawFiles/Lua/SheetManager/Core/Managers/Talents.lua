local ts = Classes.TranslatedString

local _ISCLIENT = Ext.IsClient()

---@alias TalentRequirementCheckCallback fun(talentId:string, player:EclCharacter):boolean

---@class SheetManagerTalents
SheetManager.Talents = {}

local _INTERNAL = {
	RegisteredTalents = {},
	RegisteredCount = {},
	---@type table<string, table<string, TalentRequirementCheckCallback>>
	RequirementHandlers = {},
	---@type table<string, StatRequirement[]>
	BuiltinRequirements = {},
	HiddenTalents = {},
	HiddenCount = {},
}
local _Data = {}
SheetManager.Talents._Internal = _INTERNAL
SheetManager.Talents.Data = _Data

---@enum TalentState
_Data.TalentState = {
	Selected = 0,
	Selectable = 2,
	Locked = 3
}

_Data.TalentStateColor = {
	[2] = "#403625",
	[3] = "#C80030"
}

_Data.DOSTalents = {
	ItemMovement = "TALENT_ItemMovement",
	ItemCreation = "TALENT_ItemCreation",
	--Flanking = "TALENT_Flanking",
	--AttackOfOpportunity = "TALENT_AttackOfOpportunity",
	Backstab = "TALENT_Backstab",
	Trade = "TALENT_Trade",
	Lockpick = "TALENT_Lockpick",
	ChanceToHitRanged = "TALENT_ChanceToHitRanged",
	ChanceToHitMelee = "TALENT_ChanceToHitMelee",
	Damage = "TALENT_Damage",
	ActionPoints = "TALENT_ActionPoints",
	ActionPoints2 = "TALENT_ActionPoints2",
	Criticals = "TALENT_Criticals",
	IncreasedArmor = "TALENT_IncreasedArmor",
	Sight = "TALENT_Sight",
	ResistFear = "TALENT_ResistFear",
	ResistKnockdown = "TALENT_ResistKnockdown",
	ResistStun = "TALENT_ResistStun",
	ResistPoison = "TALENT_ResistPoison",
	ResistSilence = "TALENT_ResistSilence",
	ResistDead = "TALENT_ResistDead",
	Carry = "TALENT_Carry",
	Throwing = "TALENT_Throwing",
	Repair = "TALENT_Repair",
	ExpGain = "TALENT_ExpGain",
	ExtraStatPoints = "TALENT_ExtraStatPoints",
	ExtraSkillPoints = "TALENT_ExtraSkillPoints",
	Durability = "TALENT_Durability",
	Awareness = "TALENT_Awareness",
	Vitality = "TALENT_Vitality",
	FireSpells = "TALENT_FireSpells",
	WaterSpells = "TALENT_WaterSpells",
	AirSpells = "TALENT_AirSpells",
	EarthSpells = "TALENT_EarthSpells",
	Charm = "TALENT_Charm",
	Intimidate = "TALENT_Intimidate",
	Reason = "TALENT_Reason",
	Luck = "TALENT_Luck",
	Initiative = "TALENT_Initiative",
	InventoryAccess = "TALENT_InventoryAccess",
	AvoidDetection = "TALENT_AvoidDetection",
	--AnimalEmpathy = "TALENT_AnimalEmpathy",
	--Escapist = "TALENT_Escapist",
	StandYourGround = "TALENT_StandYourGround",
	--SurpriseAttack = "TALENT_SurpriseAttack",
	LightStep = "TALENT_LightStep",
	ResurrectToFullHealth = "TALENT_ResurrectToFullHealth",
	Scientist = "TALENT_Scientist",
	--Raistlin = "TALENT_Raistlin",
	MrKnowItAll = "TALENT_MrKnowItAll",
	--WhatARush = "TALENT_WhatARush",
	--FaroutDude = "TALENT_FaroutDude",
	--Leech = "TALENT_Leech",
	--ElementalAffinity = "TALENT_ElementalAffinity",
	--FiveStarRestaurant = "TALENT_FiveStarRestaurant",
	Bully = "TALENT_Bully",
	--ElementalRanger = "TALENT_ElementalRanger",
	LightningRod = "TALENT_LightningRod",
	Politician = "TALENT_Politician",
	WeatherProof = "TALENT_WeatherProof",
	--LoneWolf = "TALENT_LoneWolf",
	--Zombie = "TALENT_Zombie",
	--Demon = "TALENT_Demon",
	--IceKing = "TALENT_IceKing",
	Courageous = "TALENT_Courageous",
	GoldenMage = "TALENT_GoldenMage",
	--WalkItOff = "TALENT_WalkItOff",
	FolkDancer = "TALENT_FolkDancer",
	SpillNoBlood = "TALENT_SpillNoBlood",
	--Stench = "TALENT_Stench",
	Kickstarter = "TALENT_Kickstarter",
	WarriorLoreNaturalArmor = "TALENT_WarriorLoreNaturalArmor",
	WarriorLoreNaturalHealth = "TALENT_WarriorLoreNaturalHealth",
	WarriorLoreNaturalResistance = "TALENT_WarriorLoreNaturalResistance",
	RangerLoreArrowRecover = "TALENT_RangerLoreArrowRecover",
	RangerLoreEvasionBonus = "TALENT_RangerLoreEvasionBonus",
	RangerLoreRangedAPBonus = "TALENT_RangerLoreRangedAPBonus",
	RogueLoreDaggerAPBonus = "TALENT_RogueLoreDaggerAPBonus",
	RogueLoreDaggerBackStab = "TALENT_RogueLoreDaggerBackStab",
	RogueLoreMovementBonus = "TALENT_RogueLoreMovementBonus",
	RogueLoreHoldResistance = "TALENT_RogueLoreHoldResistance",
	NoAttackOfOpportunity = "TALENT_NoAttackOfOpportunity",
	WarriorLoreGrenadeRange = "TALENT_WarriorLoreGrenadeRange",
	RogueLoreGrenadePrecision = "TALENT_RogueLoreGrenadePrecision",
	WandCharge = "TALENT_WandCharge",
	--DualWieldingDodging = "TALENT_DualWieldingDodging",
	--DualWieldingBlock = "TALENT_DualWieldingBlock",
	--Human_Inventive = "TALENT_Human_Inventive",
	--Human_Civil = "TALENT_Human_Civil",
	--Elf_Lore = "TALENT_Elf_Lore",
	--Elf_CorpseEating = "TALENT_Elf_CorpseEating",
	--Dwarf_Sturdy = "TALENT_Dwarf_Sturdy",
	--Dwarf_Sneaking = "TALENT_Dwarf_Sneaking",
	--Lizard_Resistance = "TALENT_Lizard_Resistance",
	--Lizard_Persuasion = "TALENT_Lizard_Persuasion",
	Perfectionist = "TALENT_Perfectionist",
	--Executioner = "TALENT_Executioner",
	--ViolentMagic = "TALENT_ViolentMagic",
	--QuickStep = "TALENT_QuickStep",
	--Quest_SpidersKiss_Str = "TALENT_Quest_SpidersKiss_Str",
	--Quest_SpidersKiss_Int = "TALENT_Quest_SpidersKiss_Int",
	--Quest_SpidersKiss_Per = "TALENT_Quest_SpidersKiss_Per",
	--Quest_SpidersKiss_Null = "TALENT_Quest_SpidersKiss_Null",
	--Memory = "TALENT_Memory",
	--Quest_TradeSecrets = "TALENT_Quest_TradeSecrets",
	--Quest_GhostTree = "TALENT_Quest_GhostTree",
	BeastMaster = "TALENT_BeastMaster",
	--LivingArmor = "TALENT_LivingArmor",
	--Torturer = "TALENT_Torturer",
	--Ambidextrous = "TALENT_Ambidextrous",
	--Unstable = "TALENT_Unstable",
	ResurrectExtraHealth = "TALENT_ResurrectExtraHealth",
	NaturalConductor = "TALENT_NaturalConductor",
	--Quest_Rooted = "TALENT_Quest_Rooted",
	PainDrinker = "TALENT_PainDrinker",
	DeathfogResistant = "TALENT_DeathfogResistant",
	Sourcerer = "TALENT_Sourcerer",
	-- Divine Talents
	Rager = "TALENT_Rager",
	Elementalist = "TALENT_Elementalist",
	Sadist = "TALENT_Sadist",
	Haymaker = "TALENT_Haymaker",
	Gladiator = "TALENT_Gladiator",
	Indomitable = "TALENT_Indomitable",
	WildMag = "TALENT_WildMag",
	Jitterbug = "TALENT_Jitterbug",
	Soulcatcher = "TALENT_Soulcatcher",
	MasterThief = "TALENT_MasterThief",
	GreedyVessel = "TALENT_GreedyVessel",
	MagicCycles = "TALENT_MagicCycles",
}

_Data.RacialTalents = {
	Human_Inventive = "TALENT_Human_Inventive",
	Human_Civil = "TALENT_Human_Civil",
	Elf_Lore = "TALENT_Elf_Lore",
	Elf_CorpseEating = "TALENT_Elf_CorpseEating",
	Dwarf_Sturdy = "TALENT_Dwarf_Sturdy",
	Dwarf_Sneaking = "TALENT_Dwarf_Sneaking",
	Lizard_Resistance = "TALENT_Lizard_Resistance",
	Lizard_Persuasion = "TALENT_Lizard_Persuasion",
	Zombie = "TALENT_Zombie",
}

_Data.DivineTalents = {
	Rager = "TALENT_Rager",
	Elementalist = "TALENT_Elementalist",
	Sadist = "TALENT_Sadist",
	Haymaker = "TALENT_Haymaker",
	Gladiator = "TALENT_Gladiator",
	Indomitable = "TALENT_Indomitable",
	WildMag = "TALENT_WildMag",
	Jitterbug = "TALENT_Jitterbug",
	Soulcatcher = "TALENT_Soulcatcher",
	MasterThief = "TALENT_MasterThief",
	GreedyVessel = "TALENT_GreedyVessel",
	MagicCycles = "TALENT_MagicCycles",
}

_Data.VisibleDivineTalents = {
	Sadist = "TALENT_Sadist",
	Haymaker = "TALENT_Haymaker",
	Gladiator = "TALENT_Gladiator",
	Indomitable = "TALENT_Indomitable",
	Soulcatcher = "TALENT_Soulcatcher",
	MasterThief = "TALENT_MasterThief",
	GreedyVessel = "TALENT_GreedyVessel",
	MagicCycles = "TALENT_MagicCycles",
}

_Data.TalentStatAttributes = {
	ItemMovement = "TALENT_ItemMovement",
	ItemCreation = "TALENT_ItemCreation",
	Flanking = "TALENT_Flanking",
	AttackOfOpportunity = "TALENT_AttackOfOpportunity",
	Backstab = "TALENT_Backstab",
	Trade = "TALENT_Trade",
	Lockpick = "TALENT_Lockpick",
	ChanceToHitRanged = "TALENT_ChanceToHitRanged",
	ChanceToHitMelee = "TALENT_ChanceToHitMelee",
	Damage = "TALENT_Damage",
	ActionPoints = "TALENT_ActionPoints",
	ActionPoints2 = "TALENT_ActionPoints2",
	Criticals = "TALENT_Criticals",
	IncreasedArmor = "TALENT_IncreasedArmor",
	Sight = "TALENT_Sight",
	ResistFear = "TALENT_ResistFear",
	ResistKnockdown = "TALENT_ResistKnockdown",
	ResistStun = "TALENT_ResistStun",
	ResistPoison = "TALENT_ResistPoison",
	ResistSilence = "TALENT_ResistSilence",
	ResistDead = "TALENT_ResistDead",
	Carry = "TALENT_Carry",
	Throwing = "TALENT_Throwing",
	Repair = "TALENT_Repair",
	ExpGain = "TALENT_ExpGain",
	ExtraStatPoints = "TALENT_ExtraStatPoints",
	ExtraSkillPoints = "TALENT_ExtraSkillPoints",
	Durability = "TALENT_Durability",
	Awareness = "TALENT_Awareness",
	Vitality = "TALENT_Vitality",
	FireSpells = "TALENT_FireSpells",
	WaterSpells = "TALENT_WaterSpells",
	AirSpells = "TALENT_AirSpells",
	EarthSpells = "TALENT_EarthSpells",
	Charm = "TALENT_Charm",
	Intimidate = "TALENT_Intimidate",
	Reason = "TALENT_Reason",
	Luck = "TALENT_Luck",
	Initiative = "TALENT_Initiative",
	InventoryAccess = "TALENT_InventoryAccess",
	AvoidDetection = "TALENT_AvoidDetection",
	AnimalEmpathy = "TALENT_AnimalEmpathy",
	Escapist = "TALENT_Escapist",
	StandYourGround = "TALENT_StandYourGround",
	SurpriseAttack = "TALENT_SurpriseAttack",
	LightStep = "TALENT_LightStep",
	ResurrectToFullHealth = "TALENT_ResurrectToFullHealth",
	Scientist = "TALENT_Scientist",
	Raistlin = "TALENT_Raistlin",
	MrKnowItAll = "TALENT_MrKnowItAll",
	WhatARush = "TALENT_WhatARush",
	FaroutDude = "TALENT_FaroutDude",
	Leech = "TALENT_Leech",
	ElementalAffinity = "TALENT_ElementalAffinity",
	FiveStarRestaurant = "TALENT_FiveStarRestaurant",
	Bully = "TALENT_Bully",
	ElementalRanger = "TALENT_ElementalRanger",
	LightningRod = "TALENT_LightningRod",
	Politician = "TALENT_Politician",
	WeatherProof = "TALENT_WeatherProof",
	LoneWolf = "TALENT_LoneWolf",
	Zombie = "TALENT_Zombie",
	Demon = "TALENT_Demon",
	IceKing = "TALENT_IceKing",
	Courageous = "TALENT_Courageous",
	GoldenMage = "TALENT_GoldenMage",
	WalkItOff = "TALENT_WalkItOff",
	FolkDancer = "TALENT_FolkDancer",
	SpillNoBlood = "TALENT_SpillNoBlood",
	Stench = "TALENT_Stench",
	Kickstarter = "TALENT_Kickstarter",
	WarriorLoreNaturalArmor = "TALENT_WarriorLoreNaturalArmor",
	WarriorLoreNaturalHealth = "TALENT_WarriorLoreNaturalHealth",
	WarriorLoreNaturalResistance = "TALENT_WarriorLoreNaturalResistance",
	RangerLoreArrowRecover = "TALENT_RangerLoreArrowRecover",
	RangerLoreEvasionBonus = "TALENT_RangerLoreEvasionBonus",
	RangerLoreRangedAPBonus = "TALENT_RangerLoreRangedAPBonus",
	RogueLoreDaggerAPBonus = "TALENT_RogueLoreDaggerAPBonus",
	RogueLoreDaggerBackStab = "TALENT_RogueLoreDaggerBackStab",
	RogueLoreMovementBonus = "TALENT_RogueLoreMovementBonus",
	RogueLoreHoldResistance = "TALENT_RogueLoreHoldResistance",
	NoAttackOfOpportunity = "TALENT_NoAttackOfOpportunity",
	WarriorLoreGrenadeRange = "TALENT_WarriorLoreGrenadeRange",
	RogueLoreGrenadePrecision = "TALENT_RogueLoreGrenadePrecision",
	WandCharge = "TALENT_WandCharge",
	DualWieldingDodging = "TALENT_DualWieldingDodging",
	DualWieldingBlock = "TALENT_DualWieldingBlock",
	Human_Inventive = "TALENT_Human_Inventive",
	Human_Civil = "TALENT_Human_Civil",
	Elf_Lore = "TALENT_Elf_Lore",
	Elf_CorpseEating = "TALENT_Elf_CorpseEating",
	Dwarf_Sturdy = "TALENT_Dwarf_Sturdy",
	Dwarf_Sneaking = "TALENT_Dwarf_Sneaking",
	Lizard_Resistance = "TALENT_Lizard_Resistance",
	Lizard_Persuasion = "TALENT_Lizard_Persuasion",
	Perfectionist = "TALENT_Perfectionist",
	Executioner = "TALENT_Executioner",
	ViolentMagic = "TALENT_ViolentMagic",
	QuickStep = "TALENT_QuickStep",
	Quest_SpidersKiss_Str = "TALENT_Quest_SpidersKiss_Str",
	Quest_SpidersKiss_Int = "TALENT_Quest_SpidersKiss_Int",
	Quest_SpidersKiss_Per = "TALENT_Quest_SpidersKiss_Per",
	Quest_SpidersKiss_Null = "TALENT_Quest_SpidersKiss_Null",
	Memory = "TALENT_Memory",
	Quest_TradeSecrets = "TALENT_Quest_TradeSecrets",
	Quest_GhostTree = "TALENT_Quest_GhostTree",
	BeastMaster = "TALENT_BeastMaster",
	LivingArmor = "TALENT_LivingArmor",
	Torturer = "TALENT_Torturer",
	Ambidextrous = "TALENT_Ambidextrous",
	Unstable = "TALENT_Unstable",
	ResurrectExtraHealth = "TALENT_ResurrectExtraHealth",
	NaturalConductor = "TALENT_NaturalConductor",
	Quest_Rooted = "TALENT_Quest_Rooted",
	PainDrinker = "TALENT_PainDrinker",
	DeathfogResistant = "TALENT_DeathfogResistant",
	Sourcerer = "TALENT_Sourcerer",
	-- Divine Talents
	Rager = "TALENT_Rager",
	Elementalist = "TALENT_Elementalist",
	Sadist = "TALENT_Sadist",
	Haymaker = "TALENT_Haymaker",
	Gladiator = "TALENT_Gladiator",
	Indomitable = "TALENT_Indomitable",
	WildMag = "TALENT_WildMag",
	Jitterbug = "TALENT_Jitterbug",
	Soulcatcher = "TALENT_Soulcatcher",
	MasterThief = "TALENT_MasterThief",
	GreedyVessel = "TALENT_GreedyVessel",
	MagicCycles = "TALENT_MagicCycles",
}

_Data.DefaultVisible = {
	Ambidextrous = "TALENT_Ambidextrous",
	AnimalEmpathy = "TALENT_AnimalEmpathy",
	AttackOfOpportunity = "TALENT_AttackOfOpportunity",
	Demon = "TALENT_Demon",
	DualWieldingDodging = "TALENT_DualWieldingDodging",
	ElementalAffinity = "TALENT_ElementalAffinity",
	ElementalRanger = "TALENT_ElementalRanger",
	Escapist = "TALENT_Escapist",
	Executioner = "TALENT_Executioner",
	ExtraSkillPoints = "TALENT_ExtraSkillPoints",
	ExtraStatPoints = "TALENT_ExtraStatPoints",
	FaroutDude = "TALENT_FaroutDude",
	FiveStarRestaurant = "TALENT_FiveStarRestaurant",
	IceKing = "TALENT_IceKing",
	Leech = "TALENT_Leech",
	LivingArmor = "TALENT_LivingArmor",
	LoneWolf = "TALENT_LoneWolf",
	Memory = "TALENT_Memory",
	NoAttackOfOpportunity = "TALENT_NoAttackOfOpportunity",
	Perfectionist = "TALENT_Perfectionist",
	QuickStep = "TALENT_QuickStep",
	Raistlin = "TALENT_Raistlin",
	RangerLoreArrowRecover = "TALENT_RangerLoreArrowRecover",
	ResistDead = "TALENT_ResistDead",
	Stench = "TALENT_Stench",
	SurpriseAttack = "TALENT_SurpriseAttack",
	Torturer = "TALENT_Torturer",
	Unstable = "TALENT_Unstable",
	ViolentMagic = "TALENT_ViolentMagic",
	WalkItOff = "TALENT_WalkItOff",
	WarriorLoreGrenadeRange = "TALENT_WarriorLoreGrenadeRange",
	WarriorLoreNaturalHealth = "TALENT_WarriorLoreNaturalHealth",
	WhatARush = "TALENT_WhatARush",
}

for name,v in pairs(_Data.DOSTalents) do
	_INTERNAL.RegisteredCount[name] = 0
end

local _TalentEnum = Mods.LeaderLib.Data.Talents

for _,talentId in _TalentEnum:Get() do
	_INTERNAL.HiddenTalents[talentId] = {}
end

local Builtin = {}

SheetManager.Talents.Builtin = Builtin

---@param talentId string
---@return boolean
function Builtin.IsRegistered(talentId)
	return _INTERNAL.RegisteredCount[talentId] and _INTERNAL.RegisteredCount[talentId] > 0
end

---@param player EclCharacter|EsvCharacter
---@param talentId string Builtin talent ID or a custom talent ID.
---@param mod Guid|nil The mod UUID, if any (for custom talents).
---@return boolean
function SheetManager.Talents.HasTalent(player, talentId, mod)
	if _TalentEnum[talentId] then
		local talentIdPrefixed = "TALENT_" .. talentId
		if player ~= nil and player.Stats ~= nil and player.Stats[talentIdPrefixed] == true then
			return true
		end
	else
		local talentData = SheetManager:GetEntryByID(talentId, mod, "Talent")
		if talentData then
			return SheetManager:GetValueByEntry(talentData, player) == true
		end
	end
	return false
end

local function TryRequestRefresh()
	-- if isClient then
	-- 	if Vars.ControllerEnabled then
	-- 		GameHelpers.UI.TryInvoke(Data.UIType.characterSheet, "clearTalents")
	-- 	else
	-- 		GameHelpers.UI.TryInvoke(Data.UIType.statsPanel_c, "clearTalents")
	-- 	end
	-- end
end

--Requires a name and description to be manually set in the tooltip, as well as an icon
local ragerWasEnabled = false

---@param talentId string A builtin talent id, i.e. Executioner
---@param modID string The registering mod's UUID.
---@param getRequirements TalentRequirementCheckCallback|nil A function that gets invoked when looking to see if a player has met the talent's requirements.
function Builtin.EnableTalent(talentId, modID, getRequirements)
	if talentId == "Rager" then
		ragerWasEnabled = true
	end
	if talentId == "all" then
		for talent,v in pairs(_Data.DOSTalents) do
			Builtin.EnableTalent(talent, modID, getRequirements)
		end
	else
		if _INTERNAL.RegisteredTalents[talentId] == nil then
			_INTERNAL.RegisteredTalents[talentId] = {}
		end
		if _INTERNAL.RegisteredTalents[talentId][modID] ~= true then
			_INTERNAL.RegisteredTalents[talentId][modID] = true
			_INTERNAL.RegisteredCount[talentId] = (_INTERNAL.RegisteredCount[talentId] or 0) + 1
		end
		if getRequirements then
			if not _INTERNAL.RequirementHandlers[talentId] then
				_INTERNAL.RequirementHandlers[talentId] = {}
			end
			_INTERNAL.RequirementHandlers[talentId][modID] = getRequirements
		end
	end
end

---@param talentId string The talent id, i.e. Executioner
---@param modID string The registering mod's UUID.
function Builtin.DisableTalent(talentId, modID)
	if talentId == "all" then
		for talent,v in pairs(_Data.DOSTalents) do
			Builtin.DisableTalent(talent, modID)
		end
		TryRequestRefresh()
	else
		local data = _INTERNAL.RegisteredTalents[talentId]
		if data ~= nil then
			if _INTERNAL.RegisteredTalents[talentId][modID] ~= nil then
				_INTERNAL.RegisteredTalents[talentId][modID] = nil
				_INTERNAL.RegisteredCount[talentId] = _INTERNAL.RegisteredCount[talentId] - 1
			end
			if _INTERNAL.RegisteredCount[talentId] <= 0 then
				_INTERNAL.RegisteredTalents[talentId] = nil
				_INTERNAL.RegisteredCount[talentId] = 0
				TryRequestRefresh()
			end
		end
	end
end

---Hides a talent from the UI, effectively disabling the ability to select it.
---@param talentId string
---@param modID string
function Builtin.HideTalent(talentId, modID)
	if talentId == "all" then
		for _,talentId in _TalentEnum:Get() do
			Builtin.HideTalent(talentId, modID)
		end
		TryRequestRefresh()
	else
		if _INTERNAL.HiddenTalents[talentId] == nil then
			_INTERNAL.HiddenTalents[talentId] = {}
		end
		if _INTERNAL.HiddenTalents[talentId][modID] ~= true then
			_INTERNAL.HiddenTalents[talentId][modID] = true
			_INTERNAL.HiddenCount[talentId] = (_INTERNAL.HiddenCount[talentId] or 0) + 1
			TryRequestRefresh()
		end
	end
end

---Stops hiding a talent from the UI.
---@param talentId string
---@param modID string
function Builtin.UnhideTalent(talentId, modID)
	if talentId == "all" then
		for _,talent in pairs(_Data.Talents) do
			Builtin.UnhideTalent(talent, modID)
		end
	else
		local count = _INTERNAL.HiddenCount[talentId] or 0
		local data = _INTERNAL.HiddenTalents[talentId]
		if data ~= nil then
			if _INTERNAL.HiddenTalents[talentId][modID] ~= nil then
				_INTERNAL.HiddenTalents[talentId][modID] = nil
				count = count - 1
			end
		end
		if count <= 0 then
			_INTERNAL.HiddenTalents[talentId] = nil
			_INTERNAL.HiddenCount[talentId] = nil
		else
			_INTERNAL.HiddenCount[talentId] = count
		end
	end
end

---@param player EclCharacter
---@param talentId string
function Builtin.HasRequirements(player, talentId)
	local getRequirementsHandlers = _INTERNAL.RequirementHandlers[talentId]
	if getRequirementsHandlers then
		for modid,handler in pairs(getRequirementsHandlers) do
			local b,result = xpcall(handler, debug.traceback, talentId, player)
			if b then
				if result == false then
					return false
				end
			else
				--fprint(LOGLEVEL.ERROR, "[CharacterExpansionLib:SheetManager.Talents.HasRequirements] Error invoking requirement handler for talent [%s] modid[%s]", id, modid)
				Ext.Utils.PrintError(result)
			end
		end
	end
	local builtinRequirements = _INTERNAL.BuiltinRequirements[talentId]
	if builtinRequirements and #builtinRequirements > 0 then
		for _,req in pairs(builtinRequirements) do
			local playerValue = player.Stats[req.Requirement]
			local t = type(playerValue)
			if t == "boolean" then
				if req.Not and playerValue then
					return false
				elseif req.Not == false and not playerValue then
					return false
				end
			elseif t == "number" and playerValue < req.Param then
				return false
			end
		end
	end
	return true
end

---@param talentState TalentState
---@return string
function SheetManager.Talents.GetTalentStateFontFormat(talentState)
	local color = _Data.TalentStateColor[talentState]
	if color then
		return "<font color='"..color.."'>%s</font>"
	end
	return "%s"
end

---@param talentId string The talent ID
---@param talentState TalentState
---@return string
function Builtin.GetDisplayName(talentId, talentState)
	local name = talentId
	if LocalizedText.TalentNames[talentId] then
		name = LocalizedText.TalentNames[talentId].Value
	end
	return string.format(SheetManager.Talents.GetTalentStateFontFormat(talentState), name)
end

---@param player EclCharacter
---@param talentId string
---@param hasTalent boolean
---@return TalentState
function Builtin.GetTalentState(player, talentId, hasTalent)
	if hasTalent == true then 
		return _Data.TalentState.Selected
	elseif not Builtin.HasRequirements(player, talentId) then 
		return _Data.TalentState.Locked
	else
		return _Data.TalentState.Selectable
	end
end

function Builtin.TalentIsHidden(talentId)
	local count = _INTERNAL.HiddenCount[talentId]
	return count and count > 0
end

local function CanDisplayDivineTalent(talentId)
	if not _Data.DivineTalents[talentId] then
		return true
	end
	local name = LocalizedText.TalentNames[talentId]
	if not name or StringHelpers.IsNullOrEmpty(name.Value) then
		name = talentId
	else
		name = name.Value
	end
	if string.find(name, "|", 1, true) then
		return false
	end
	if talentId == "Rager" then
		-- Seems to have no handles for its name/description
		return ragerWasEnabled
	elseif talentId == "Jitterbug" then
		local tooltip = GameHelpers.GetTranslatedString("h758efe2fgb3bag4935g9500g2c789497e87a", "|Being depleted of Physical or Magical armour teleports you to random location, away from the source of damage. Can happen once every 2 turns.|")
		if string.find(tooltip, "|", 1, true) then
			return false
		end
	end
	return true
end

---@private
function Builtin.CanAddTalent(talentId, hasTalent)
	local isGM = GameHelpers.Client.IsGameMaster()
	if (Builtin.TalentIsHidden(talentId) and not isGM) then
		return false
	end
	if hasTalent == true then
		return true
	end

	local isRegistered = _INTERNAL.RegisteredCount[talentId] and _INTERNAL.RegisteredCount[talentId] > 0
	if isRegistered then
		return true
	end

	if _Data.VisibleDivineTalents[talentId] and CanDisplayDivineTalent(talentId) then
		return true
	end

	if talentId == "RogueLoreDaggerBackStab" 
	and GameSettings.Settings.BackstabSettings.Player.Enabled
	and GameSettings.Settings.BackstabSettings.Player.TalentRequired
	then
		return true
	end
	if _Data.DefaultVisible[talentId] then
		return true
	end
	if _Data.RacialTalents[talentId] and isGM then
		return true
	end
	return false
end

if Vars.DebugMode then
	if _ISCLIENT then
		Events.LuaReset:Subscribe(function(e)
			if Vars.ControllerEnabled then
				local ui = Ext.UI.GetByType(_Data.UIType.statsPanel_c)
				if ui then
					ui:GetRoot().mainpanel_mc.stats_mc.talents_mc.statList.clearElements()
				end
			end
		end)
	end
end

---@param enabled boolean
---@param modId Guid|nil Mod UUID
function Builtin.ToggleDivineTalents(enabled, modId)
	if enabled then
		for talent,id in pairs(_Data.VisibleDivineTalents) do
			Builtin.EnableTalent(talent, modId or ModuleUUID)
		end
	else
		for talent,id in pairs(_Data.VisibleDivineTalents) do
			Builtin.DisableTalent(talent, modId or ModuleUUID)
		end
	end
end

local pointRequirement = "(.+) (%d+)"
local talentRequirement = "(%!*)(TALENT_.+)"

local function _GetRequirementFromText(text)
	local requirementName,param = string.match(text, pointRequirement)
	if requirementName and param then
		return {
			Requirement = requirementName,
			Param = tonumber(param),
			Not = false
		}
	else
		local notParam,requirementName = string.match(text, talentRequirement)
		if requirementName then
			return {
				Requirement = requirementName,
				Param = "Talent",
				Not = notParam and true or false
			}
		end
	end
	return nil
end

function Builtin.LoadRequirements()
	for _,uuid in pairs(Ext.Mod.GetLoadOrder()) do
		local mod = Ext.Mod.GetMod(uuid)
		if mod and mod.Info and mod.Info.Directory then
			local directory = mod.Info.Directory
			local talentRequirementsText = Ext.IO.LoadFile("Public/"..directory.."/Stats/Generated/Data/Requirements.txt", "data")
			if not StringHelpers.IsNullOrEmpty(talentRequirementsText) then
				for line in StringHelpers.GetLines(talentRequirementsText) do
					local talent,requirementText = string.match(line, 'requirement.*"(.+)",.*"(.*)"')
					if talent then
						_INTERNAL.BuiltinRequirements[talent] = {}
						if requirementText then
							for i,v in pairs(StringHelpers.Split(requirementText, ";")) do
								local req = _GetRequirementFromText(v)
								if req then
									table.insert(_INTERNAL.BuiltinRequirements[talent], req)
								end
							end
						end
					end
				end
			end
		end
	end
end

if _ISCLIENT then

	---@private
	function SheetManager.Talents.HideTalents(uiType)
		if uiType == _Data.UIType.characterSheet or uiType == _Data.UIType.statsPanel_c then
			SheetManager.UI.Sheet.HideTalents()
		elseif uiType == _Data.UIType.characterCreation or uiType == _Data.UIType.characterCreation_c then
			SheetManager.UI.CC.HideTalents()
		end
	end

	---@class SheetManager.TalentsUIEntry
	---@field ID string
	---@field GeneratedID integer
	---@field Enum string
	---@field HasTalent boolean
	---@field DisplayName string
	---@field IsRacial boolean
	---@field IsChoosable boolean
	---@field CanAdd boolean
	---@field CanRemove boolean
	---@field IsCustom boolean
	---@field State TalentState
	---@field Visible boolean

	---@private
	---@param player EclCharacter
	---@param isCharacterCreation boolean|nil
	---@param isGM boolean|nil
	---@param availablePoints ?integer
	---@return fun():SheetManager.TalentsUIEntry
	function SheetManager.Talents.GetVisible(player, isCharacterCreation, isGM, availablePoints)
		if isCharacterCreation == nil then
			isCharacterCreation = false
		end
		if isGM == nil then
			isGM = false
		end

		local talentPoints = availablePoints or SheetManager:GetAvailablePoints(player, "Talent", nil, isCharacterCreation)
		local targetStats = SessionManager:CreateCharacterSessionMetaTable(player)

		local entries = {}
		--Default entries
		for numId,talentId in _Data.Talents:Get() do
			local hasTalent = targetStats[_Data.TalentStatAttributes[talentId]] == true
			if Builtin.CanAddTalent(talentId, hasTalent) then
				local talentState = Builtin.GetTalentState(player, talentId, hasTalent)
				local name = Builtin.GetDisplayName(talentId, talentState)
				local isRacial = _Data.RacialTalents[talentId] ~= nil
				local isChoosable = not isRacial and talentState ~= _Data.TalentState.Locked

				local canAdd = not hasTalent and (isGM or (talentPoints > 0 and talentState == _Data.TalentState.Selectable))
				local canRemove = hasTalent and ((not isRacial and isCharacterCreation) or isGM)

				---@type SheetManager.TalentsUIEntry
				local data = {
					ID = talentId,
					GeneratedID = _TalentEnum[talentId],
					HasTalent = hasTalent,
					DisplayName = name,
					IsRacial = isRacial,
					IsChoosable = isChoosable,
					State = talentState,
					IsCustom = false,
					CanAdd = canAdd,
					CanRemove = canRemove,
					Visible = true,
				}
				entries[#entries+1] = data
			end
		end
		for mod,dataTable in pairs(SheetManager.Data.Talents) do
			for id,data in pairs(dataTable) do
				local hasTalent = data:GetValue(player) == true
				if SheetManager:IsEntryVisible(data, player, hasTalent, isCharacterCreation, isGM) then
					local talentState = data:GetState(player)
					local name = string.format(SheetManager.Talents.GetTalentStateFontFormat(talentState), data:GetDisplayName(player))
					local isRacial = data.IsRacial
					local isChoosable = not isRacial and talentState ~= _Data.TalentState.Locked
					local canAdd = not hasTalent and (isChoosable and talentPoints > 0) or isGM
					local canRemove = hasTalent and (isCharacterCreation or isGM)
					---@type SheetManager.TalentsUIEntry
					local sheetData = {
						ID = data.ID,
						GeneratedID = data.GeneratedID,
						HasTalent = hasTalent,
						DisplayName = name .. data.Suffix,
						IsRacial = isRacial,
						IsChoosable = isChoosable,
						CanAdd = SheetManager:GetIsPlusVisible(data, player, canAdd, hasTalent),
						CanRemove = SheetManager:GetIsMinusVisible(data, player, canRemove, hasTalent),
						State = talentState,
						IsCustom = true,
						Visible = true,
					}
					entries[#entries+1] = sheetData
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