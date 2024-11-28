if SheetManager.Config == nil then
	SheetManager.Config = {}
end

SheetManager.Config.CustomCallToTooltipRequestType = {
	showAbilityTooltipCustom = "Ability",
	showTalentTooltipCustom = "Talent",
	showStatTooltipCustom = "Stat",
	showCustomStatTooltip = "CustomStat",
	selectAbilityCustom = "Ability",
	selectTalentCustom = "Talent",
	selectStatCustom = "Stat",
	selectSecStatCustom = "Stat",
}

local customCalls = {
	Tooltip = {
		Ability = "showAbilityTooltipCustom",
		Talent = "showTalentTooltipCustom",
		Stat = "showStatTooltipCustom"
	},
	TooltipController = {
		Ability = "selectAbilityCustom",
		Talent = "selectTalentCustom",
		PrimaryStat = "selectStatCustom",
		SecondaryStat = "selectSecStatCustom",
	},
	PointRemoved = {
		Ability = "minusAbilityCustom",
		Talent = "minusTalentCustom",
		PrimaryStat = "minusStatCustom",
		SecondaryStat = "minusSecStatCustom",
	},
	PointAdded = {
		Ability = "plusAbilityCustom",
		Talent = "plusTalentCustom",
		PrimaryStat = "plusStatCustom",
		SecondaryStat = "plusSecStatCustom",
	}
}

SheetManager.Config.Calls = customCalls

local baseCalls = {
	Tooltip = {
		Ability = "showAbilityTooltip",
		Talent = "showTalentTooltip",
		Stat = "showStatTooltip",
		CustomStat = "showCustomStatTooltip"
	},
	TooltipController = {
		Ability = "selectAbility",
		Talent = "selectTalent",
		PrimaryStat = "selectStat",
		SecondaryStat = "selectSecStat",
		CustomStat = "selectCustomStat",
	},
	PointRemoved = {
		Ability = "minusAbility",
		Talent = "minusTalent",
		PrimaryStat = "minusStat",
		SecondaryStat = "minusSecStat",
	},
	PointAdded = {
		Ability = "plusAbility",
		Talent = "plusTalent",
		PrimaryStat = "plusStat",
		SecondaryStat = "plusSecStat",
	}
}

SheetManager.Config.BaseCalls = baseCalls

local baseCreationCalls = {
	Tooltip = {
		Ability = "showAbilityTooltip",
		Talent = "showTalentTooltip",
		Stat = "showStatTooltip"
	},
	TooltipController = {
		Ability = "selectAbility",
		Talent = "selectTalent",
		PrimaryStat = "selectStat",
		SecondaryStat = "selectSecStat",
	},
	PointRemoved = {
		Ability = "minAbility",
		Talent = "toggleTalent",
		Stat = "minAttribute",
	},
	PointAdded = {
		Ability = "plusAbility",
		Talent = "toggleTalent",
		Stat = "plusAttribute",
	}
}

SheetManager.Config.BaseCreationCalls = baseCreationCalls