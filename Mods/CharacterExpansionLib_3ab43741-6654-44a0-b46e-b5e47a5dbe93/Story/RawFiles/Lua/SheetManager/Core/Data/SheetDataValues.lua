if SheetManager.Config == nil then
	SheetManager.Config = {}
end
SheetManager.Config.Calls = {
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

SheetManager.Config.BaseCalls = {
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

SheetManager.Config.BaseCreationCalls = {
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