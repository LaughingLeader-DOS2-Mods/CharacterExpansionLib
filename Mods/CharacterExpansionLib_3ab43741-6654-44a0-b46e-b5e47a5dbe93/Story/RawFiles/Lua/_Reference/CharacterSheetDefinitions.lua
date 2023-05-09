---@class FlashScrollListGrouped:FlashScrollList
---@class FlashHorizontalScrollList:FlashHorizontalList
---@class BtnCreateCustomStat:FlashMovieClip
---@class FlashComboBox:FlashMovieClip
---@class FlashEmpty:FlashMovieClip
---@class mcPlus_Anim_69:FlashMovieClip
---@class larTween:FlashMovieClip
---@class btnDeleteCustomStat:FlashMovieClip
---@class btnEditCustomStat:FlashMovieClip
---@class deleteBtn:FlashMovieClip
---@class FlashFocusEvent:FlashEvent

---@class abilitiesholder_9
---@field listHolder_mc FlashEmpty
---@field list FlashScrollListGrouped
---@field init function

---@class customStatsHolder_14
---@field create_mc BtnCreateCustomStat
---@field listHolder_mc FlashEmpty
---@field list FlashScrollListGrouped
---@field stats_array table
---@field groups_array table
---@field init function
---@field onCreateBtnClicked function
---@field positionElements fun(sortElements:boolean, sortValue:string)
---@field clearElements function
---@field resetGroups function
---@field setGameMasterMode fun(isGM:boolean)
---@field OnGroupClicked fun(group_mc:StatCategory)
---@field addGroup fun(groupId:number, labelText:string, reposition:boolean, visible:boolean)
---@field setGroupTooltip fun(groupId:number, text:string)
---@field setGroupVisibility fun(groupId:number, visible:boolean)
---@field recountAllPoints function
---@field addCustomStat fun(doubleHandle:number, labelText:string, valueText:string, groupId:number, plusVisible:boolean, minusVisible:boolean, isCustom:boolean)

---@class CharacterSheetMainTimeline:FlashMainTimeline
---@field stats_mc stats_1
---@field initDone boolean
---@field events table
---@field layout string
---@field alignment string
---@field curTooltip integer
---@field hasTooltip boolean
---@field availableStr string
---@field uiLeft integer
---@field uiRight integer
---@field uiTop integer
---@field uiMinHeight integer
---@field uiMinWidth integer
---@field charList_array table
---@field invRows integer
---@field invCols integer
---@field invCellSize integer
---@field invCellSpacing integer
---@field skillList table
---@field tabsTexts table
---@field primStat_array table
---@field secStat_array table
---@field ability_array table
---@field tags_array table
---@field talent_array table
---@field visual_array table
---@field visualValues_array table
---@field customStats_array table
---@field lvlBtnAbility_array table
---@field lvlBtnStat_array table
---@field lvlBtnSecStat_array table
---@field lvlBtnTalent_array table
---@field allignmentArray table
---@field aiArray table
---@field inventoryUpdateList table
---@field isGameMasterChar boolean
---@field EQContainer FlashMovieClip
---@field slotAmount number
---@field cellSize number
---@field slot_array table
---@field itemsUpdateList table
---@field renameBtnTooltip string
---@field alignmentTooltip string
---@field aiTooltip string
---@field createNewStatBtnLabel string
---@field isDragging boolean
---@field draggingSkill boolean
---@field tabState number
---@field screenWidth number
---@field screenHeight number
---@field text_array table
---@field strSelectTreasure string
---@field strGenerate string
---@field strClear string
---@field strLevel string
---@field listRarity table
---@field listTreasures table
---@field generateTreasureRarityId integer
---@field generateTreasureId integer
---@field generateTreasureLevel integer
---@field characterHandle number
---@field charHandle number
---@field onWheel function
---@field onEventResize function
---@field updateVisuals function
---@field updateSkills function
---@field GMShowTargetSkills function
---@field resetSkillDragging function
---@field updateInventory function
---@field updateAllignmentList function
---@field selectAllignment fun(id:integer)
---@field updateAIList function
---@field selectAI fun(id:integer)
---@field setGameMasterMode fun(isGameMasterMode:boolean, isGameMasterChar:boolean, isPossessed:boolean)
---@field onEventUp fun(index:number)
---@field onEventDown fun(index:number)
---@field onEventResolution fun(width:number, height:number)
---@field onEventInit function
---@field setPossessedState fun(param1:boolean)
---@field getGlobalPositionOfMC fun(mc:FlashMovieClip):FlashPoint
---@field showTooltipForMC fun(mc:FlashMovieClip, externalCall:string)
---@field showCustomTooltipForMC fun(mc:FlashMovieClip, externalCall:string, statID:number)
---@field setActionsDisabled fun(disabled:boolean)
---@field updateItems function
---@field setHelmetOptionState fun(state:number)
---@field setHelmetOptionTooltip fun(text:string)
---@field setPlayerInfo fun(text:string)
---@field setAvailableLabels fun(text:string)
---@field pointsTextfieldChanged fun(tf:FlashTextField)
---@field selectCharacter fun(id:number)
---@field setText fun(tabId:number, text:string)
---@field setTitle fun(text:string)
---@field addText fun(labelText:string, tooltipText:string, isSecondary:boolean)
---@field addPrimaryStat fun(statID:number, labelText:string, valueText:string, tooltipType:number)
---@field addSecondaryStat fun(statType:number, labelText:string, valueText:string, statID:number, frame:number, boostValue:number)
---@field clearSecondaryStats function
---@field addAbilityGroup fun(isCivil:boolean, groupId:number, labelText:string)
---@field addAbility fun(isCivil:boolean, groupId:number, statID:number, labelText:string, valueText:string, plusTooltip:string, minusTooltip:string)
---@field addTalent fun(labelText:string, statID:number, talentState:number)
---@field addTag fun(tooltipText:string, labelText:string, descriptionText:string, statID:number)
---@field addVisual fun(titleText:string, contentID:number)
---@field addVisualOption fun(id:number, optionId:number, select:boolean)
---@field updateCharList function
---@field cycleCharList fun(previous:boolean)
---@field clearArray fun(name:string)
---@field updateArraySystem function
---@field setStatPlusVisible fun(statID:number, isVisible:boolean)
---@field setStatMinusVisible fun(statID:number, isVisible:boolean)
---@field setupSecondaryStatsButtons fun(id:integer, showBoth:boolean, minusVisible:boolean, plusVisible:boolean, maxChars:number)
---@field setAbilityPlusVisible fun(isCivil:boolean, groupId:number, statID:number, isVisible:boolean)
---@field setAbilityMinusVisible fun(isCivil:boolean, groupId:number, statID:number, isVisible:boolean)
---@field setTalentPlusVisible fun(statID:number, isVisible:boolean)
---@field setTalentMinusVisible fun(statID:number, isVisible:boolean)
---@field addTitle fun(param1:string)
---@field hideLevelUpStatButtons function
---@field hideLevelUpAbilityButtons function
---@field hideLevelUpTalentButtons function
---@field clearStats function
---@field clearTags function
---@field clearTalents function
---@field clearAbilities function
---@field setPanelTitle fun(param1:number, param2:string)
---@field showAcceptStatsAcceptButton fun(b:boolean)
---@field showAcceptAbilitiesAcceptButton fun(b:boolean)
---@field showAcceptTalentAcceptButton fun(b:boolean)
---@field setAvailableStatPoints fun(amount:number)
---@field setAvailableCombatAbilityPoints fun(amount:number)
---@field setAvailableCivilAbilityPoints fun(amount:number)
---@field setAvailableTalentPoints fun(amount:number)
---@field setAvailableCustomStatPoints fun(amount:number)
---@field addSpacing fun(param1:number, param2:number)
---@field addGoldWeight fun(param1:string, param2:string)
---@field startsWith fun(param1:string, param2:string):boolean
---@field ShowItemUnEquipAnim fun(param1:integer, param2:integer)
---@field ShowItemEquipAnim fun(param1:integer, param2:integer)
---@field setupStrings function
---@field setupRarity function
---@field setupTreasures function
---@field onOpenDropList fun(mc:FlashMovieClip)
---@field closeDropLists function
---@field setGenerationRarity fun(id:integer)
---@field onSelectGenerationRarity fun(id:integer)
---@field onChangeGenerationLevel fun(level:number)
---@field onSelectTreasure fun(index:integer)
---@field onBtnGenerateStock function
---@field onBtnClearInventory function

---@class minusButton_65
---@field bg_mc FlashMovieClip
---@field hit_mc FlashMovieClip
---@field base FlashMovieClip
---@field stat FlashMovieClip
---@field callbackStr string
---@field tooltip string
---@field currentTooltip string
---@field onMouseOver fun(param1:FlashMouseEvent)
---@field onMouseOut fun(param1:FlashMouseEvent)
---@field onDown fun(param1:FlashMouseEvent)
---@field onUp fun(param1:FlashMouseEvent)

---@class plusButton_62
---@field bg_mc FlashMovieClip
---@field hit_mc FlashMovieClip
---@field base FlashMovieClip
---@field stat FlashMovieClip
---@field callbackStr string
---@field tooltip string
---@field currentTooltip string
---@field onMouseOver fun(param1:FlashMouseEvent)
---@field onMouseOut fun(param1:FlashMouseEvent)
---@field onDown fun(param1:FlashMouseEvent)
---@field onUp fun(param1:FlashMouseEvent)

---@class pointsAvailable_56
---@field civilAbilPoints_txt FlashTextField
---@field combatAbilPoints_txt FlashTextField
---@field label_txt FlashTextField
---@field statPoints_txt FlashTextField
---@field talentPoints_txt FlashTextField
---@field customStatPoints_txt FlashTextField
---@field setTab fun(tabIndex:integer)

---@class stats_1
---@field aiSel_mc FlashComboBox
---@field alignments_mc FlashComboBox
---@field attrPointsWrn_mc FlashMovieClip
---@field bg_mc FlashMovieClip
---@field charInfo_mc FlashMovieClip
---@field charList_mc FlashEmpty
---@field civicAbilityHolder_mc FlashMovieClip
---@field civilAbilityPointsWrn_mc FlashMovieClip
---@field close_mc FlashMovieClip
---@field combatAbilityHolder_mc FlashMovieClip
---@field combatAbilityPointsWrn_mc FlashMovieClip
---@field customStats_mc customStatsHolder_14
---@field customStatsPointsWrn_mc mcPlus_Anim_69
---@field customStatsPoints_txt FlashTextField
---@field dragHit_mc FlashMovieClip
---@field equip_mc FlashMovieClip
---@field equipment_txt FlashTextField
---@field hitArea_mc FlashMovieClip
---@field invTabHolder_mc FlashMovieClip
---@field leftCycleBtn_mc FlashMovieClip
---@field mainStats_mc FlashMovieClip
---@field onePlayerOverlay_mc FlashMovieClip
---@field panelBg1_mc FlashMovieClip
---@field panelBg2_mc FlashMovieClip
---@field pointsFrame_mc FlashMovieClip
---@field rightCycleBtn_mc FlashMovieClip
---@field scrollbarHolder_mc FlashEmpty
---@field skillTabHolder_mc FlashMovieClip
---@field tabTitle_txt FlashTextField
---@field tabsHolder_mc FlashEmpty
---@field tagsHolder_mc FlashMovieClip
---@field talentHolder_mc FlashMovieClip
---@field talentPointsWrn_mc FlashMovieClip
---@field title_txt FlashTextField
---@field visualHolder_mc FlashMovieClip
---@field myText string
---@field closeCenterX number
---@field closeSideX number
---@field buttonY number
---@field base FlashMovieClip
---@field lvlUP boolean
---@field cellSize number
---@field statholderListPosY number
---@field listOffsetY number
---@field tabsList FlashHorizontalList
---@field charList FlashHorizontalScrollList
---@field primaryStatList FlashListDisplay
---@field secondaryStatList FlashListDisplay
---@field expStatList FlashListDisplay
---@field resistanceStatList FlashListDisplay
---@field infoStatList FlashListDisplay
---@field secELSpacing number
---@field currentOpenPanel number
---@field panelArray table
---@field selectedTabY number
---@field deselectedTabY number
---@field selectedTabAlpha number
---@field deselectedTabAlpha number
---@field tabsArray table
---@field pointsWarn table
---@field pointTexts table
---@field root_mc FlashMovieClip
---@field gmSkillsString string
---@field customStatIconOffsetX number
---@field customStatIconOffsetY number
---@field pointWarningOffsetX number
---@field customStatPointsTextOffsetX number
---@field mainStatsList FlashScrollListGrouped
---@field GROUP_MAIN_ATTRIBUTES integer
---@field GROUP_MAIN_STATS integer
---@field GROUP_MAIN_EXPERIENCE integer
---@field GROUP_MAIN_RESISTANCES integer
---@field init function
---@field selectAI function
---@field selectAlignment function
---@field renameCallback function
---@field updateInventorySlots fun(arr:table)
---@field resetListPositions function
---@field buildTabs fun(tabState:number, initializeTabs:boolean)
---@field alignPointWarningsToButtons function
---@field pushTabTooltip fun(tabId:number, text:string)
---@field initTabs fun(bInitTab:boolean, resetTabs:boolean)
---@field selectCharacter fun(id:number)
---@field addCharPortrait fun(id:number, iconId:string, order:integer)
---@field cleanupCharListObsoletes function
---@field removeChildrenOf fun(mc:FlashMovieClip)
---@field ClickTab fun(tabIndex:number)
---@field selectTab fun(index:number)
---@field getTabById fun(tabId:number):FlashMovieClip
---@field setPanelTitle fun(index:number, titleText:string)
---@field resetScrollBarsPositions function
---@field INTSetWarnAndPoints fun(index:number, pointsValue:number)
---@field INTSetAvailablePointsVisible function
---@field setAvailableStatPoints fun(points:number)
---@field setAvailableCombatAbilityPoints fun(points:number)
---@field setAvailableCivilAbilityPoints fun(points:number)
---@field setAvailableTalentPoints fun(points:number)
---@field setVisibilityStatButtons fun(isVisible:boolean)
---@field setStatPlusVisible fun(id:number, isVisible:boolean)
---@field setStatMinusVisible fun(id:number, isVisible:boolean)
---@field setupSecondaryStatsButtons fun(id:integer, showBoth:boolean, minusVisible:boolean, plusVisible:boolean, maxChars:number)
---@field getStat fun(statID:number, isCustom:boolean):FlashMovieClip
---@field getSecStat fun(statID:number, isCustom:boolean):FlashMovieClip
---@field getAbility fun(isCivil:boolean, groupId:number, statID:number, isCustom:boolean):FlashMovieClip
---@field getTalent fun(statID:number, isCustom:boolean):FlashMovieClip
---@field getTag fun(statID:number):FlashMovieClip
---@field setVisibilityAbilityButtons fun(isCivil:boolean, isVisible:boolean)
---@field setAbilityPlusVisible fun(param1:boolean, param2:number, param3:number, param4:boolean)
---@field setAbilityMinusVisible fun(param1:boolean, param2:number, param3:number, param4:boolean)
---@field setVisibilityTalentButtons fun(isVisible:boolean)
---@field setTalentPlusVisible fun(talentId:number, visible:boolean)
---@field setTalentMinusVisible fun(talentId:number, visible:boolean)
---@field addText fun(text:string, tooltip:string, isSecondary:boolean)
---@field addSpacing fun(listId:number, height:number)
---@field addAbilityGroup fun(isCivil:boolean, groupId:number, labelText:string)
---@field addAbility fun(isCivil:boolean, groupId:number, statID:number, labelText:string, valueText:string, plusTooltip:string, minusTooltip:string, plusVisible:boolean, minusVisible:boolean, isCustom:boolean)
---@field recountAbilityPoints fun(isCivil:boolean)
---@field addTalent fun(labelText:string, statID:number, talentState:number, plusVisible:boolean, minusVisible:boolean, isCustom:boolean)
---@field getTalentStateFrame fun(state:number):number
---@field addPrimaryStat fun(statID:number, displayName:string, value:string, tooltipId:number, plusVisible:boolean, minusVisible:boolean, isCustom:boolean, iconFrame:number, iggyIconName:string)
---@field addSecondaryStat fun(statType:number, labelText:string, valueText:string, statID:number, iconFrame:number, boostValue:number, plusVisible:boolean, minusVisible:boolean, isCustom:boolean, iggyIconName:string)
---@field addTag fun(labelText:string, statID:number, tooltipText:string, descriptionText:string)
---@field addToListWithId fun(id:number, mc:FlashMovieClip)
---@field clearSecondaryStats function
---@field addTitle fun(param1:string)
---@field clearStats function
---@field clearAbilities function
---@field addVisual fun(titleText:string, contentID:number)
---@field clearVisualOptions function
---@field addVisualOption fun(id:number, optionId:number, select:boolean)
---@field getVisual fun(contentID:number):FlashMovieClip
---@field clearCustomStatsOptions function
---@field addCustomStat fun(doubleHandle:number, labelText:string, valueText:string)
---@field justEatClick fun(param1:FlashMouseEvent)
---@field onBGOut fun(param1:FlashMouseEvent)
---@field closeUIOnClick fun(param1:FlashMouseEvent)
---@field closeUI function
---@field addIcon fun(param1:FlashMovieClip, param2:string, param3:number)
---@field updateAIs fun(param1:table)
---@field updateAllignments fun(param1:table)
---@field recheckScrollbarVisibility function
---@field setMainStatsGroupName fun(groupId:integer, name:string)

---@class talentsHolder_11
---@field bgGlow_mc FlashMovieClip
---@field listHolder_mc FlashEmpty
---@field list FlashScrollList
---@field init function
---@field updateBGPos fun(e:FlashEvent)

---@class AbilityEl
---@field abilTooltip_mc FlashMovieClip
---@field hl_mc FlashMovieClip
---@field texts_mc FlashMovieClip
---@field timeline larTween
---@field base FlashMovieClip
---@field isCivil boolean
---@field statID number
---@field callbackStr string
---@field isCustom boolean
---@field MakeCustom fun(id:number, b:boolean)
---@field onOver fun(param1:FlashMouseEvent)
---@field onOut fun(e:FlashMouseEvent)
---@field onHLOver fun(e:FlashMouseEvent)
---@field onHLOut fun(e:FlashMouseEvent)
---@field hlInvis function

---@class FlashCustomStat
---@field delete_mc btnDeleteCustomStat
---@field edit_mc btnEditCustomStat
---@field hl_mc FlashMovieClip
---@field label_txt FlashTextField
---@field line_mc FlashMovieClip
---@field minus_mc FlashMovieClip
---@field plus_mc FlashMovieClip
---@field text_txt FlashTextField
---@field timeline larTween
---@field base FlashMovieClip
---@field tooltip string
---@field statID number
---@field am number
---@field id integer
---@field statIndex integer
---@field init function
---@field onOver fun(param1:FlashMouseEvent)
---@field onOut fun(param1:FlashMouseEvent)
---@field onEditBtnClicked function
---@field onDeleteBtnClicked function

---@class InfoStat
---@field hl_mc FlashMovieClip
---@field icon_mc FlashMovieClip
---@field minus_mc FlashMovieClip
---@field plus_mc FlashMovieClip
---@field texts_mc FlashMovieClip
---@field timeline larTween
---@field base FlashMovieClip
---@field statID number
---@field tooltip number
---@field callbackStr string
---@field isCustom boolean
---@field MakeCustom fun(statID:number, b:boolean)
---@field onOver fun(e:FlashMouseEvent)
---@field onOut fun(e:FlashMouseEvent)
---@field hlInvis function

---@class SecStat
---@field editText_txt FlashTextField
---@field hl_mc FlashMovieClip
---@field icon_mc FlashMovieClip
---@field minus_mc FlashMovieClip
---@field mod_txt FlashTextField
---@field plus_mc FlashMovieClip
---@field texts_mc FlashMovieClip
---@field timeline larTween
---@field base FlashMovieClip
---@field boostValue number
---@field statID number
---@field tooltip number
---@field callbackStr string
---@field isCustom boolean
---@field MakeCustom fun(statID:number, b:boolean)
---@field setupButtons fun(param1:boolean, minusVisible:boolean, plusVisible:boolean, maxChars:number)
---@field onTextPress fun(e:FlashMouseEvent)
---@field onValueAccept fun(e:FlashFocusEvent)
---@field onOver fun(e:FlashMouseEvent)
---@field onOut fun(param1:FlashMouseEvent)
---@field hlInvis function

---@class skillEl
---@field hl_mc FlashMovieClip
---@field itemSkillFrame_mc FlashMovieClip
---@field removeSkillBtn_mc deleteBtn
---@field root_mc FlashMovieClip
---@field dragTreshHold integer
---@field mousePosDown FlashPoint
---@field _canBeRemoved boolean
---@field onInit fun(param1:FlashMovieClip)
---@field canBeRemoved fun(b:boolean):boolean
---@field onRemoveSkillButtonPressed fun(param1:FlashMovieClip)
---@field onOver fun(param1:FlashMouseEvent)
---@field onOut fun(param1:FlashMouseEvent)
---@field onDown fun(param1:FlashMouseEvent)
---@field onUp fun(param1:FlashMouseEvent)
---@field onDragging fun(param1:FlashMouseEvent)

---@class Stat
---@field hl_mc FlashMovieClip
---@field icon_mc FlashMovieClip
---@field label_txt FlashTextField
---@field minus_mc FlashMovieClip
---@field plus_mc FlashMovieClip
---@field text_txt FlashTextField
---@field timeline larTween
---@field base FlashMovieClip
---@field statID number
---@field tooltip number
---@field callbackStr string
---@field isCustom boolean
---@field MakeCustom fun(statID:number, b:boolean)
---@field onOver fun(param1:FlashMouseEvent)
---@field onOut fun(param1:FlashMouseEvent)

---@class StatCategory
---@field amount_txt FlashTextField
---@field bg_mc FlashMovieClip
---@field listContainer_mc FlashEmpty
---@field title_txt FlashTextField
---@field isOpen boolean
---@field hidePoints boolean
---@field texty number
---@field groupName string
---@field setIsOpen fun(b:boolean)
---@field onMouseOver fun(e:FlashMouseEvent)
---@field onMouseOut fun(e:FlashMouseEvent)
---@field onDown fun(e:FlashMouseEvent)
---@field onUp fun(e:FlashMouseEvent)
---@field length fun():number
---@field content_array fun():table

---@class Talent
---@field bullet_mc FlashMovieClip
---@field hl_mc FlashMovieClip
---@field label_txt FlashTextField
---@field minus_mc FlashMovieClip
---@field plus_mc FlashMovieClip
---@field timeline larTween
---@field base FlashMovieClip
---@field statID number
---@field callbackStr string
---@field isCustom boolean
---@field MakeCustom fun(statID:number, b:boolean)
---@field onOver fun(e:FlashMouseEvent)
---@field onOut fun(e:FlashMouseEvent)