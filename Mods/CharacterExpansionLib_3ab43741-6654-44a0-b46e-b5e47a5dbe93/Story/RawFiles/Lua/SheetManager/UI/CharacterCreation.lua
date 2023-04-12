if SheetManager.UI == nil then SheetManager.UI = {} end

local ts = Classes.TranslatedString

---@class CharacterCreationWrapper:LeaderLibUIWrapper
local CharacterCreation = Classes.UIWrapper:CreateFromType(Data.UIType.characterCreation, {ControllerID = Data.UIType.characterCreation_c, IsControllerSupported = true})
local self = CharacterCreation

---@class FlashCharacterCreationTalentsMC:FlashMovieClip
---@field addTalentElement fun(talentID:integer, talentLabel:string, isUnlocked:boolean, isChoosable:boolean, isRacial:boolean):void
---@field addCustomTalentElement fun(customID:string, talentLabel:string, isUnlocked:boolean, isChoosable:boolean, isRacial:boolean):void

local updateSessionPoints = {}
local PresetData = {}

local Text = {
	AvailableAbilityPoints = ts:Create("h407af7f3g2453g4367g9a9ega9ca67d88668", "Available Ability Points:"),
	AvailableAttributePoints = ts:Create("h9bd665efg713dg43e6g936fg5ae882e7b635", "Available Attribute Points:"),
	AvailableTalentPoints = ts:Create("h77a814fcgc8b9g4e27g8e35g8ac9e90e1214", "Available Talents: "),
	Available = ts:Create("h36303e10g0c17g4aebgbeb6ge0b865ba3fc6", "Available"),
	CivilAbilityPoints = ts:Create("h529eed46g7472g4ecdgbd5eg37b2a60c8a52", "Civil Ability points"),
}

local function UpdatePresetData()
	local cc = Ext.Stats.GetCharacterCreation()
	for i,v in pairs(cc.ClassPresets) do
		PresetData[v.ClassType] = v
	end
end

function CharacterCreation.IsExtended()
	local this = CharacterCreation.Root
	if this then
		return this.isExtended
	end
	return false
end

function CharacterCreation.UpdateAvailablePoints()
	if CharacterCreation.IsOpen then
		local this = CharacterCreation.Root
		if this then
			local ccwiz = Ext.UI.GetCharacterCreationWizard()
			this.availableAttributePoints = ccwiz.AvailablePoints.Attribute
			this.availableAbilityPoints = ccwiz.AvailablePoints.Ability
			this.availableCivilPoints = ccwiz.AvailablePoints.Civil
			this.availableTalentPoints = ccwiz.AvailablePoints.Talent
			this.availableSkillPoints = ccwiz.AvailablePoints.SkillSlots

			this.CCPanel_mc.attributes_mc.freePoints_txt.htmlText = string.format("%s %i", Text.AvailableAttributePoints.Value, this.availableAttributePoints)
			this.CCPanel_mc.abilities_mc.freePoints_txt.htmlText = string.format("%s %i", Text.AvailableAbilityPoints.Value, this.availableAbilityPoints)
			this.CCPanel_mc.abilities_mc.freePoints2_txt.htmlText = string.format("%s %s: %i", Text.Available.Value, Text.CivilAbilityPoints.Value, this.availableCivilPoints)
			this.CCPanel_mc.talents_mc.availablePoints_txt.htmlText = string.format("%s %i", Text.AvailableTalentPoints.Value, this.availableTalentPoints)
			
			local maxSlots = GameHelpers.GetExtraData("CharacterBaseMemoryCapacity", 3) + ccwiz.AssignedPoints.SkillSlots
			if this.numberOfSlots ~= maxSlots then
				this.setAvailableSkillSlots(maxSlots)
			end

			return true
		end
	end

	return false
end

local function GetAvailablePoints()
	return Ext.UI.GetCharacterCreationWizard().AvailablePoints
end

-- CharacterCreation.Register:Call("toggleTalent", function (self, e, ui, call, statID)
-- 	local this = ui:GetRoot()
-- 	if this and this.isExtended then
-- 		local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
-- 		if updateSessionPoints[player.NetID] == nil then
-- 			updateSessionPoints[player.NetID] = {}
-- 		end
-- 		updateSessionPoints[player.NetID].Talent = statID
-- 	end
-- end, "Before")

---@private
---@param ui UIObject
function CharacterCreation.UpdateTalents(self, e, ui, method)
	local this = self.Root
	if not this or not this.isExtended then
		return
	end

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
	---@cast player EclCharacter

	local engineValues = {}

	local points = GetAvailablePoints().Talent
	this.availableTalentPoints = points

	--talentArray[0] is available points
	for i=1,#this.talentArray-1,4 do
		local statID = this.talentArray[i]
		--local talentLabel = this.talentArray[i+1]
		local isUnlocked = this.talentArray[i+2]
		--local choosable = this.talentArray[i+3]
		if statID and isUnlocked ~= nil then
			engineValues[statID] = isUnlocked
			-- if updateSessionPoints[player.NetID] and updateSessionPoints[player.NetID].Talent == statID then
			-- 	if isUnlocked then
			-- 		SessionManager:RequestPointsUpdate(player, "Talent", -1)
			-- 	else
			-- 		SessionManager:RequestPointsUpdate(player, "Talent", 1)
			-- 	end
			-- 	updateSessionPoints[player.NetID].Talent = nil
			-- end
		end
	end

	---@type FlashCharacterCreationTalentsMC
	local talentsMC = this.CCPanel_mc.talents_mc

	for talent in SheetManager.Talents.GetVisible(player, true, nil, this.availableTalentPoints) do
		if engineValues[talent.ID] ~= nil then
			talent.HasTalent = engineValues[talent.ID]
		end
		SheetManager.Events.OnEntryUpdating:Invoke({ID=talent.ID, EntryType="SheetTalentData", Stat=talent, Character=player})
		if talent.Visible then
			talentsMC.addTalentElement(talent.GeneratedID, talent.DisplayName, talent.HasTalent, talent.IsChoosable, talent.IsRacial, talent.IsCustom)
		end
	end

	if not Vars.ControllerEnabled then
		talentsMC.positionLists()
	else
		talentsMC.talents_mc.setupLists()
	end

	this.CCPanel_mc.talents_mc.availablePoints_txt.htmlText = string.format("%s %i", Text.AvailableTalentPoints.Value, this.availableTalentPoints)
end

CharacterCreation.Register:Invoke("updateTalents", CharacterCreation.UpdateTalents, "Before", "All")

---@private
---@param ui UIObject
function CharacterCreation.UpdateAbilities(self, e, ui, method)
	local this = self.Root
	if not this or not this.isExtended then
		return
	end
	--this.clearArray("abilityArray")

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
	---@cast player EclCharacter
	local engineValues = {}

	local points = GetAvailablePoints()
	this.availableAbilityPoints = points.Ability
	this.availableCivilPoints = points.Civil

	for i=0,#this.abilityArray-1,7 do
		--local groupID = this.abilityArray[i]
		--local groupTitle = this.abilityArray[i+1]
		local statID = this.abilityArray[i+2]
		--local abilityLabel = this.abilityArray[i+3]
		local abilityValue = this.abilityArray[i+4]
		local abilityDelta = this.abilityArray[i+5]
		--local isCivil = this.abilityArray[i+6]
		engineValues[statID] = {
			Value = abilityValue,
			Delta = abilityDelta
		}
		-- if updateSessionPoints[player.NetID] and updateSessionPoints[player.NetID].Ability == statID then
		-- 	SessionManager:RequestPointsUpdate(player, "Ability", abilityValue)
		-- 	updateSessionPoints[player.NetID].Ability = nil
		-- end
	end

	local abilities_mc = this.CCPanel_mc.abilities_mc

	local abilitiesWithDelta = {}
	local updateClassContent = SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION
	
	for ability in SheetManager.Abilities.GetVisible(player, nil, true, nil, this.availableAbilityPoints, this.availableCivilPoints) do
		local updateData = engineValues[ability.ID]
		if updateData then
			ability.Value = updateData.Value
			ability.Delta = updateData.Delta
		end
		SheetManager.Events.OnEntryUpdating:Invoke({ID=ability.ID, EntryType="SheetAbilityData", Stat=ability, Character=player})
		if ability.Visible then
			abilities_mc.addAbility(ability.GroupID, ability.GroupDisplayName, ability.GeneratedID, ability.DisplayName, ability.Value, ability.Delta, ability.IsCivil, ability.IsCustom)
			if updateClassContent and ability.Delta > 0 then
				abilitiesWithDelta[#abilitiesWithDelta+1] = {
					ID = ability.GeneratedID,
					DisplayName = ability.DisplayName,
					Delta = ability.Delta
				}
			end
		end
	end

	if updateClassContent then
		local class_mc = this.CCPanel_mc.class_mc
		local classEditList = class_mc.classEditList
		local classEdit_mc = classEditList[1]
		if classEdit_mc then
			classEdit_mc.contentList.clearElements()
			for _,v in ipairs(abilitiesWithDelta) do
				classEdit_mc.addContentString(v.ID,v.DisplayName,v.Delta)
			end
			classEdit_mc.contentList.positionElements()
		end
	end

	if not Vars.ControllerEnabled then
		abilities_mc.updateComplete()

		abilities_mc.freePoints_txt.htmlText = string.format("%s %i", Text.AvailableAbilityPoints.Value, this.availableAbilityPoints)
		abilities_mc.freePoints2_txt.htmlText = string.format("%s %s: %i", Text.Available.Value, Text.CivilAbilityPoints.Value, this.availableCivilPoints)
	end
end

CharacterCreation.Register:Invoke("updateAbilities", CharacterCreation.UpdateAbilities, "Before", "All")

---@private
---@param ui UIObject
function CharacterCreation.UpdateAttributes(self, e, ui, method)
	local this = CharacterCreation.Root
	if not this or not this.isExtended then
		return
	end
	--this.clearArray("abilityArray")

	local player = GameHelpers.Client.TryGetCharacterFromDouble(this.characterHandle) or Client:GetCharacter()
	---@cast player EclCharacter
	local points = GetAvailablePoints().Attribute
	this.availableAttributePoints = points

	local engineValues = {}
	for i=0,#this.attributeArray-1,5 do
		--Ext.Utils.PrintWarning(i, this.attributeArray[i], this.attributeArray[i+1], this.attributeArray[i+3], this.attributeArray[i+4])
		local statID = this.attributeArray[i]
		-- local label = this.abilityArray[i+1]
		-- local attributeInfo = this.abilityArray[i+2]
		local value = this.attributeArray[i+3]
		local delta = this.attributeArray[i+4]
		engineValues[statID] = {
			Value = value,
			Delta = delta
		}

		-- if updateSessionPoints[player.NetID] and updateSessionPoints[player.NetID].Stat == statID then
		-- 	SessionManager:RequestPointsUpdate(player, "Stat", value)
		-- 	updateSessionPoints[player.NetID].Stat = nil
		-- end
	end

	local attributes_mc = this.CCPanel_mc.attributes_mc

	local attributesWithDelta = {}
	local updateClassContent = SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION

	for stat in SheetManager.Stats.GetVisible(player, true, false, not updateClassContent, this.availableAttributePoints) do
		local updateData = engineValues[stat.ID]
		if updateData then
			stat.Value = updateData.Value
			stat.Delta = updateData.Delta
		end
		SheetManager.Events.OnEntryUpdating:Invoke({ID=stat.ID, EntryType="SheetStatData", Stat=stat, Character=player})
		if stat.Visible then
			attributes_mc.addAttribute(stat.GeneratedID, stat.DisplayName, stat.Description, stat.Value, stat.Delta, stat.Frame, stat.IsCustom, stat.IconClipName or "", -3, -3, 0.5, stat.CallbackID or -1)
			if updateClassContent and stat.Delta > 0 then
				attributesWithDelta[#attributesWithDelta+1] = {
					ID = stat.GeneratedID,
					DisplayName = stat.DisplayName,
					Delta = stat.Delta
				}
			end
			if not StringHelpers.IsNullOrWhitespace(stat.IconClipName) then
				self.Instance:SetCustomIcon(stat.IconDrawCallName, stat.Icon, stat.IconWidth, stat.IconHeight)
			end
		end
	end

	if updateClassContent then
		local class_mc = this.CCPanel_mc.class_mc
		local classEditList = class_mc.classEditList
		local classEdit_mc = classEditList[0]
		if classEdit_mc then
			classEdit_mc.contentList.clearElements()
			for _,v in ipairs(attributesWithDelta) do
				classEdit_mc.addContentString(v.ID,v.DisplayName,v.Delta)
			end
			classEdit_mc.contentList.positionElements()
		end
	end

	--attributes_mc.root_mc.CCPanel_mc.class_mc.addTabTextContent(0,val2);

	attributes_mc.attributes.cleanUpElements()
	attributes_mc.freePoints_txt.htmlText = string.format("%s %i", Text.AvailableAttributePoints.Value, this.availableAttributePoints)
end

CharacterCreation.Register:Invoke("updateAttributes", CharacterCreation.UpdateAttributes, "Before", "All")

function CharacterCreation.Started(self, e, ui, call)
	CharacterCreation.IsOpen = true
	if SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION then
		local this = self.Root
		if this and not this.isExtended then
			this.isExtended = string.find(Ext.IO.GetPathOverride(ui.Path), "CharacterExpansionLib")
		end
	end
end

CharacterCreation.Register:Call("characterCreationStarted", CharacterCreation.Started, "Before", "All")

function CharacterCreation.CreationDone(self, e, ui, method, startText, backText, visible)
	if GameHelpers.IsLevelType(LEVELTYPE.CHARACTER_CREATION) then
		SheetManager.Save.CharacterCreationDone(Client:GetCharacter(), true)
	end
	-- if visible == false then
	-- 	-- UI is closing with no message box confirmation, which can happen if points were only spent on custom entries
	-- 	if not MessageBox.UI.Instance and CharacterCreation.IsOpen then
	-- 		SheetManager.Save.CharacterCreationDone(Client:GetCharacter(), true)
	-- 		CharacterCreation.IsOpen = false
	-- 		-- local this = self.Root
	-- 		-- if this and not this.isExtended then
	-- 		-- 	this.isExtended = true
	-- 		-- end
	-- 	end
	-- end
end
--CharacterCreation.Register:Invoke("creationDone", CharacterCreation.CreationDone, "After", "All")

CharacterCreation.Register:Call("selectOption", function(self, e, ui, call)
	local this = ui:GetRoot()
	if not this then
		return
	end
	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
	if player then
		SessionManager:ResetSession(player)
	end
	-- local color = math.tointeger(0xCC00FF); local wiz = Ext.UI.GetCharacterCreationWizard().CharacterCreationManager.Customizations[0].State; wiz.SkinColor.Value = color; Ext.GetUIByType(3):ExternalInterfaceCall("setArmourState", 0); --Ext.GetUIByType(119):ExternalInterfaceCall("setHelmetOption", 0) --Ext.GetUIByType(3):ExternalInterfaceCall("setGender", true); 
	-- local wiz = Ext.UI.GetCharacterCreationWizard()
	-- if wiz then
	-- 	local raceData = wiz.CharacterCreationManager.Customizations[0].State
	-- 	raceData.SkinColor.Value = math.tointeger(0xCC00FF)
	-- end
end, "Before", "All")

--Ext.IO.SaveFile("Dumps/CC_UI_Dump.json", Ext.DumpExport(Ext.UI.GetCharacterCreationWizard()))
-- CharacterCreation.Register:Invoke("updatePortraits", function(self, ui, call)
-- 	local wiz = Ext.UI.GetCharacterCreationWizard()
-- 	if wiz then
-- 		local raceData = wiz.CharacterCreationManager.Customizations[0].State
-- 		raceData.SkinColor.Value = math.tointeger(0xCC00FF)
-- 	end
-- end, "Before", "All")

MessageBox:RegisterListener("CharacterCreationConfirm", function(event, isConfirmed, player)
	if isConfirmed and CharacterCreation.IsOpen then
		SheetManager.Save.CharacterCreationDone(player, true)
		CharacterCreation.IsOpen = false
	end
end)

MessageBox:RegisterListener("CharacterCreationCancel", function(event, isConfirmed, player)
	if isConfirmed and CharacterCreation.IsOpen then
		SheetManager.Save.CharacterCreationDone(player, false)
		CharacterCreation.IsOpen = false
	end
end)

SheetManager.UI.CharacterCreation = CharacterCreation

Events.LuaReset:Subscribe(function (e)
	local this = CharacterCreation.Root
	CharacterCreation.IsOpen = this ~= nil
	if CharacterCreation.IsOpen then
		CharacterCreation.UpdateAvailablePoints()
		local player = Client:GetCharacter()
		if player then
			local doubleHandle = Ext.UI.HandleToDouble(player.Handle)
			this.characterHandle = doubleHandle
			this.charHandle = doubleHandle
		end
	end
end)

RegisterNetListener("CEL_CharacterCreation_UpdateEntries", function ()
	if CharacterCreation.IsOpen then
		CharacterCreation:UpdateAttributes()
		CharacterCreation:UpdateAbilities()
		CharacterCreation:UpdateTalents()
	end
end)