local ts = Classes.TranslatedString

local _ISCLIENT = Ext.IsClient()

---@class SheetManagerStats
SheetManager.Stats = {
	Data = {
		Default = {
			Entries = {
				Strength = {
					DisplayName = LocalizedText.CharacterSheet.Strength,
					StatID = 0,
					TooltipID = 0,
					Attribute = "Strength",
					Type = "PrimaryStat",
					CCFrame = 1,
				},
				Finesse = {
					DisplayName = LocalizedText.CharacterSheet.Finesse,
					StatID = 1,
					TooltipID = 1,
					Attribute = "Finesse",
					Type = "PrimaryStat",
					CCFrame = 2,
				},
				Intelligence = {
					DisplayName = LocalizedText.CharacterSheet.Intelligence,
					StatID = 2,
					TooltipID = 2,
					Attribute = "Intelligence",
					Type = "PrimaryStat",
					CCFrame = 3,
				},
				Constitution = {
					DisplayName = LocalizedText.CharacterSheet.Constitution,
					StatID = 3,
					TooltipID = 3,
					Attribute = "Constitution",
					Type = "PrimaryStat",
					CCFrame = 4,
				},
				Memory = {
					DisplayName = LocalizedText.CharacterSheet.Memory,
					StatID = 4,
					TooltipID = 4,
					Attribute = "Memory",
					Type = "PrimaryStat",
					CCFrame = 5,
				},
				Wits = {
					DisplayName = LocalizedText.CharacterSheet.Wits,
					StatID = 5,
					TooltipID = 5,
					Attribute = "Wits",
					Type = "PrimaryStat",
					CCFrame = 6,
				},
				Dodging = {
					StatID = 11,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.Dodging,
					Type = "SecondaryStat",
					Frame = 15,
					Attribute = "Dodge",
					Suffix = "%"
				},
				Movement = {
					StatID = 20,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.Movement,
					Type = "SecondaryStat",
					Frame = 18,
					---@param character StatCharacter
					Attribute = function (character)
						return GameHelpers.GetMovement(character)
					end
				},
				Initiative = {
					StatID = 21,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.Initiative,
					Type = "SecondaryStat",
					Frame = 16,
					Attribute = "Initiative"
				},
				CriticalChance = {
					StatID = 9,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.CriticalChance,
					Type = "SecondaryStat",
					Frame = 20,
					Attribute = "CriticalChance",
					Suffix = "%"
				},
				Accuracy = {
					StatID = 10,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.Accuracy,
					Type = "SecondaryStat",
					Frame = 13,
					Attribute = "Accuracy",
					Suffix = "%"
				},
				Damage = {
					StatID = 6,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.Damage,
					Type = "SecondaryStat",
					Frame = 14,
					---@param character CDivinityStatsCharacter
					Attribute = function(character)
						local mainWeapon = character.MainWeapon
						local offHandWeapon = character.OffHandWeapon

						--- @param weapon StatItem
						local getReqFunc = function(weapon)
							local requirementName
							local largestRequirement = -1

							for i, requirement in pairs(weapon.Requirements) do
								local reqName = requirement.Requirement
								if not requirement.Not and type(requirement.Param) == "number" and requirement.Param > largestRequirement and
									(reqName == "Strength" or reqName == "Finesse" or reqName == "Intelligence" or
									reqName == "Constitution" or reqName == "Memory" or reqName == "Wits") then
									requirementName = reqName
									largestRequirement = requirement.Param
								end
							end

							return requirementName
						end
						local originalFunc = Game.Math.GetWeaponScalingRequirement
						Game.Math.GetWeaponScalingRequirement = getReqFunc

						local mainDamageRange = {}

						local minDamage = 0
						local maxDamage = 0

						local mainDamageType = "Sentinel"
						local offDamageType = "Sentinel"

						if mainWeapon ~= nil then
							mainDamageType = mainWeapon["Damage Type"]
							mainDamageRange = Game.Math.CalculateWeaponScaledDamageRanges(character, mainWeapon)
						end

						Game.Math.GetWeaponScalingRequirement = originalFunc

						if offHandWeapon ~= nil and Game.Math.IsRangedWeapon(mainWeapon) == Game.Math.IsRangedWeapon(offHandWeapon) then
							offDamageType = offHandWeapon["Damage Type"]
							local offHandDamageRange = Game.Math.CalculateWeaponScaledDamageRanges(character, offHandWeapon)
							local dualWieldPenalty = Ext.ExtraData.DualWieldingDamagePenalty
							for damageType, range in pairs(offHandDamageRange) do
								local min = math.ceil(range.Min * dualWieldPenalty)
								local max = math.ceil(range.Max * dualWieldPenalty)
								local range = mainDamageRange[damageType]
								if mainDamageRange[damageType] ~= nil then
									range.Min = range.Min + min
									range.Max = range.Max + max
								else
									mainDamageRange[damageType] = {Min = min, Max = max}
								end
							end
						end
				
						for damageType, range in pairs(mainDamageRange) do
							local min = Ext.Utils.Round(range.Min * 1.0)
							local max = Ext.Utils.Round(range.Max * 1.0)
							range.Min = min + math.ceil(min * Game.Math.GetDamageBoostByType(character, damageType))
							range.Max = max + math.ceil(max * Game.Math.GetDamageBoostByType(character, damageType))
						end

						-- if mainDamageType ~= "None" and mainDamageType ~= "Sentinel" then
						-- 	local min, max = 0, 0
						-- 	local boost = Game.Math.GetDamageBoostByType(character, mainDamageType)
						-- 	for _, range in pairs(mainDamageRange) do
						-- 		min = min + range.Min + math.ceil(range.Min * Game.Math.GetDamageBoostByType(character, mainDamageType))
						-- 		max = max + range.Max + math.ceil(range.Min * Game.Math.GetDamageBoostByType(character, mainDamageType))
						-- 	end
					
						-- 	mainDamageRange[mainDamageType] = {Min = min, Max = max}
						-- end

						-- if offDamageType ~= "None" and offDamageType ~= "Sentinel" and offDamageType ~= mainDamageType then
						-- 	local min, max = 0, 0
						-- 	local boost = Game.Math.GetDamageBoostByType(character, offDamageType)
						-- 	for _, range in pairs(mainDamageRange) do
						-- 		min = min + range.Min + math.ceil(range.Min * Game.Math.GetDamageBoostByType(character, offDamageType))
						-- 		max = max + range.Max + math.ceil(range.Min * Game.Math.GetDamageBoostByType(character, offDamageType))
						-- 	end
						-- 	mainDamageRange[mainDamageType] = {Min = min, Max = max}
						-- end

						for damageType, range in pairs(mainDamageRange) do
							minDamage = minDamage + range.Min
							maxDamage = maxDamage + range.Max
						end

						return string.format("%s - %s", minDamage, maxDamage)
					end
				},
				Vitality = {
					StatID = 12,
					StatType = 0,
					DisplayName = LocalizedText.CharacterSheet.Vitality,
					Type = "SecondaryStat",
					Frame = 1,
					Attribute = function(character) return string.format("%s/%s", character.CurrentVitality, character.MaxVitality) end
				},
				ActionPoints = {
					StatID = 13,
					StatType = 0,
					DisplayName = LocalizedText.CharacterSheet.ActionPoints,
					Type = "SecondaryStat",
					Frame = 2,
					Attribute = "APStart"
				},
				SourcePoints = {
					StatID = 14,
					StatType = 0,
					DisplayName = LocalizedText.CharacterSheet.SourcePoints,
					Type = "SecondaryStat",
					Frame = 3,
					Attribute = "MPStart"
				},
				PhysicalArmour = {
					StatID = 7,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.PhysicalArmour,
					Type = "SecondaryStat",
					Frame = 10,
					Attribute = function(character) return string.format("%s/%s", character.CurrentArmor, character.MaxArmor) end
				},
				MagicArmour = {
					StatID = 8,
					StatType = 1,
					DisplayName = LocalizedText.CharacterSheet.MagicArmour,
					Type = "SecondaryStat",
					Frame = 11,
					Attribute = function(character) return string.format("%s/%s", character.CurrentMagicArmor, character.MaxMagicArmor) end
				},
				NextLevel = {
					StatID = 37,
					StatType = 3,
					DisplayName = LocalizedText.CharacterSheet.NextLevel,
					Type = "SecondaryStat",
					Frame = 17,
					Attribute = function(character) return string.format("%s", math.floor(Data.LevelExperience[character.Level+1] - character.Experience)) end
				},
				Experience = {
					StatID = 36,
					StatType = 3,
					DisplayName = LocalizedText.CharacterSheet.Total,
					Type = "SecondaryStat",
					Frame = 19,
					Attribute = "Experience"
				},
				Air = {
					StatID = 31,
					StatType = 2,
					DisplayName = LocalizedText.CharacterSheet.Air,
					Type = "SecondaryStat",
					Frame = 8,
					Attribute = "AirResistance",
					Suffix = "%"
				},
				Earth = {
					StatID = 30,
					StatType = 2,
					DisplayName = LocalizedText.CharacterSheet.Earth,
					Type = "SecondaryStat",
					Frame = 7,
					Attribute = "EarthResistance",
					Suffix = "%"
				},
				Fire = {
					StatID = 28,
					StatType = 2,
					DisplayName = LocalizedText.CharacterSheet.Fire,
					Type = "SecondaryStat",
					Frame = 5,
					Attribute = "FireResistance",
					Suffix = "%"
				},
				Poison = {
					StatID = 32,
					StatType = 2,
					DisplayName = LocalizedText.CharacterSheet.Poison,
					Type = "SecondaryStat",
					Frame = 9,
					Attribute = "PoisonResistance",
					Suffix = "%"
				},
				Water = {
					StatID = 29,
					StatType = 2,
					DisplayName = LocalizedText.CharacterSheet.Water,
					Type = "SecondaryStat",
					Frame = 6,
					Attribute = "WaterResistance",
					Suffix = "%"
				},
				Spacing = {
					Height = 10,
					Type = "Spacing",
					StatType = 1
				}
			},
			Order = {
				"Strength",
				"Finesse",
				"Intelligence",
				"Constitution",
				"Memory",
				"Wits",
				"Vitality",
				"ActionPoints",
				"SourcePoints",
				"Damage",
				"CriticalChance",
				"Accuracy",
				"Dodging",
				"PhysicalArmour",
				"MagicArmour",
				--"Spacing",
				"Movement",
				"Initiative",
				"Fire",
				"Water",
				"Earth",
				"Air",
				"Poison",
				"Experience",
				"NextLevel"
			}
		},
		Attributes = {},
		Resistances = {},
		StatType = {
			PrimaryStat = "PrimaryStat",
			SecondaryStat = "SecondaryStat",
			Spacing = "Spacing"
		},
		SecondaryStatType = {
			Info = 0,
			Stat = 1,
			Resistance = 2,
			Experience = 3,
		},
		---@type table<integer,StatSheetSecondaryStatType>
		SecondaryStatTypeInteger = {
			[0] = "Info",
			[1] = "Stat",
			[2] = "Resistance",
			[3] = "Experience",
		},
		Builtin = {
			StatEnum = {
				Strength = 0,
				Finesse = 1,
				Intelligence = 2,
				Constitution = 3,
				Memory = 4,
				Wit = 5,
				Damage = 6,
				PhysicalArmour = 7,
				MagicArmour = 8,
				CriticalChance = 9,
				Accuracy = 10,
				Dodging = 11,
				Vitality = 12,
				ActionPoints = 13,
				SourcePoints = 14,
				Movement = 20,
				Initiative = 21,
				Fire = 28,
				Water = 29,
				Earth = 30,
				Air = 31,
				Poison = 32,
				Experience = 36,
				NextLevel = 37,
			},
			ID = {
				[0]="Strength",
				[1]="Finesse",
				[2]="Intelligence",
				[3]="Constitution",
				[4]="Memory",
				[5]="Wits",
				[6]="Damage",
				[7]="PhysicalArmour",
				[8]="MagicArmour",
				[9]="CriticalChance",
				[10]="Accuracy",
				[11]="Dodging",
				[12]="Vitality",
				[13]="ActionPoints",
				[14]="SourcePoints",
				[20]="Movement",
				[21]="Initiative",
				[28]="Fire",
				[29]="Water",
				[30]="Earth",
				[31]="Air",
				[32]="Poison",
				[36]="Experience",
				[37]="NextLevel"
			}
		}
	}
}

if _ISCLIENT then
	---@class SheetManager.StatsUIEntry
	---@field ID string
	---@field GeneratedID integer
	---@field DisplayName string
	---@field Value string
	---@field StatType string
	---@field SecondaryStatType string
	---@field SecondaryStatTypeInteger integer
	---@field CanAdd boolean
	---@field CanRemove boolean
	---@field IsCustom boolean
	---@field SpacingHeight number
	---@field Frame integer stat_mc.icon_mc's frame. If > totalFrames, then a custom iggy icon is used.
	---@field IconClipName string iggy_LL_ID
	---@field IconDrawCallName string LL_ID
	---@field Icon string
	---@field IconWidth number
	---@field IconHeight number
	---@field Visible boolean
	---@field Mod Guid

	local _NEGATIVE_FORMAT = "<font color='#C80030'>%s</font>"

	---@class SheetManagerStatsGetVisibleOptions:SheetManagerGetVisibleBaseOptions
	---@field IsRespec boolean
	---@field AvailablePoints integer
	local DefaultOptions = {
		IsCharacterCreation = false,
		IsGM = false,
		IsRespec = false,
	}

	---@private
	---@param player EclCharacter
	---@param opts? SheetManagerStatsGetVisibleOptions
	---@return fun():SheetManager.StatsUIEntry
	function SheetManager.Stats.GetVisible(player, opts)
		local options = TableHelpers.SetDefaultOptions(opts, DefaultOptions)
		if options.Stats == nil then
			options.Stats = SessionManager:CreateCharacterSessionMetaTable(player)
		end
		local targetStats = options.Stats
		local defaultCanRemove = options.IsCharacterCreation or options.IsGM

		local entries = {}
		--local tooltip = LocalizedText.UI.AbilityPlusTooltip:ReplacePlaceholders(Ext.ExtraData.CombatAbilityLevelGrowth)
		local points = options.AvailablePoints or SheetManager:GetAvailablePoints(player, "Attribute", nil, options.IsCharacterCreation)
		local maxAttribute = GameHelpers.GetExtraData("AttributeSoftCap", 40)
		local startAttribute = GameHelpers.GetExtraData("AttributeBaseValue", 10)
		
		for i=1,#SheetManager.Stats.Data.Default.Order do
			local id = SheetManager.Stats.Data.Default.Order[i]
			local data = SheetManager.Stats.Data.Default.Entries[id]
			if not options.IsCharacterCreation or data.Type == "PrimaryStat" then
				if id == "Spacing" then
					local entry = {
						StatType = SheetManager.Stats.Data.StatType.Spacing,
						SpacingHeight = data.Height,
					}
					entries[#entries+1] = entry
				else
					local value = nil
					local baseValue = 0
					if type(data.Attribute) == "function" then
						local b,result = xpcall(data.Attribute, debug.traceback, targetStats)
						if b then
							value = result
						else
							fprint(LOGLEVEL.ERROR, "[SheetManager.Stats.GetVisible] Error getting value for %s:\n%s", id, result)
						end
					else
						value = targetStats[data.Attribute]
						if data.Attribute ~= "MPStart" and data.Attribute ~= "Experience" then
							baseValue = targetStats["Base"..data.Attribute]
						end
					end
					if value ~= nil then
						--TODO Make sure add/remove works for info stats
						local canAdd = (data.Type == "PrimaryStat" and points > 0 and baseValue < maxAttribute) or options.IsGM
						local canRemove = defaultCanRemove
						if data.Type == "PrimaryStat" and not canRemove then
							canRemove = options.IsCharacterCreation and value > startAttribute
						end
						
						local frame = data.Frame or (data.Type == "PrimaryStat" and -1 or 0)
						if options.IsCharacterCreation and data.CCFrame then
							frame = data.CCFrame
						end

						local delta = 0
						if data.Type == "PrimaryStat" then
							delta = value - startAttribute
						end

						local name = id
						if data.DisplayName then
							name = data.DisplayName.Value
						end
						local valueLabel = string.format("%s%s", value, data.Suffix or "")
						--TODO Red text conditions may be more complex (like it looking for a negative boost)
						if type(value) == "number" and value < 0 then
							name = string.format(_NEGATIVE_FORMAT, name)
							valueLabel = string.format(_NEGATIVE_FORMAT, valueLabel)
						end

						local uiEntry = {
							ID = id,
							Mod = Data.ModID.Shared,
							GeneratedID = data.StatID,
							DisplayName = name,
							Description = "",
							Value = valueLabel,
							Delta = delta,
							CanAdd = canAdd,
							CanRemove = canRemove,
							IsCustom = false,
							StatType = data.Type,
							Frame = frame,
							SecondaryStatTypeInteger = data.StatType or 0,
							Icon = "",
							IconWidth = 0,
							IconHeight = 0,
							IconClipName = "",
							IconDrawCallName = "",
							Visible = true,
						}
						if options.IsCharacterCreation and not options.IsRespec then
							uiEntry.GeneratedID = uiEntry.GeneratedID + 1
						end
						entries[#entries+1] = uiEntry
					end
				end
			end
		end

		for mod,dataTable in pairs(SheetManager.Data.Stats) do
			for id,data in pairs(dataTable) do
				if data.StatType == "PrimaryStat" then
					local value = data:GetValue(player) or 0
					if SheetManager:IsEntryVisible(data, player, value) then
						local defaultCanAdd = false
						if data.StatType == "PrimaryStat" then
							local maxVal = data.MaxValue or maxAttribute
							defaultCanAdd = options.IsGM
							if not defaultCanAdd then
								if data.UsePoints then
									defaultCanAdd = points > 0 and value < maxVal
								else
									defaultCanAdd = value < maxVal
								end
							end
						end

						local name = data:GetDisplayName(player)
						local valueLabel = string.format("%s%s", value, data.Suffix or "")
						if type(value) == "number" and value < 0 then
							name = string.format(_NEGATIVE_FORMAT, name)
							valueLabel = string.format(_NEGATIVE_FORMAT, valueLabel)
						end

						local uiEntry = {
							ID = data.ID,
							Mod = data.Mod,
							GeneratedID = data.GeneratedID,
							DisplayName = name,
							Description = data:GetDescription(player, TooltipExpander.IsExpanded()),
							Value = valueLabel,
							Delta = value - data.BaseValue,
							CanAdd = SheetManager:GetIsPlusVisible(data, player, defaultCanAdd, value),
							CanRemove = SheetManager:GetIsMinusVisible(data, player, defaultCanRemove, value),
							IsCustom = true,
							StatType = data.StatType,
							Frame = data.Frame or (data.StatType == "PrimaryStat" and -1 or 0),
							SecondaryStatType = data.SecondaryStatType,
							SecondaryStatTypeInteger = SheetManager.Stats.Data.SecondaryStatType[data.SecondaryStatType] or 0,
							SpacingHeight = data.SpacingHeight,
							Icon = data.SheetIcon or "",
							IconWidth = data.SheetIconWidth or 28,
							IconHeight = data.SheetIconHeight or 28,
							IconClipName = "",
							IconDrawCallName = "",
							Visible = true,
						}
						if not StringHelpers.IsNullOrEmpty(data.SheetIcon) then
							uiEntry.Frame = 99
							uiEntry.IconDrawCallName = string.format("LL_%s", data.ID)
							uiEntry.IconClipName = "iggy_" .. uiEntry.IconDrawCallName
						end
						entries[#entries+1] = uiEntry
					end
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