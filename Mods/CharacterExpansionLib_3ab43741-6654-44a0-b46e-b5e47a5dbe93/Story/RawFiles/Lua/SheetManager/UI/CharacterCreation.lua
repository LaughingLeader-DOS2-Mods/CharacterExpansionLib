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
-- CharacterCreation:RegisterCallListener("toggleTalent", function (self, ui, call, statID)
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
function CharacterCreation.UpdateTalents(self, ui, method)
	local this = self.Root
	if not this or not this.isExtended then
		return
	end

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()

	local engineValues = {}

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
			-- 		SheetManager.SessionManager:RequestPointsUpdate(player, "Talent", -1)
			-- 	else
			-- 		SheetManager.SessionManager:RequestPointsUpdate(player, "Talent", 1)
			-- 	end
			-- 	updateSessionPoints[player.NetID].Talent = nil
			-- end
		end
	end

	---@type FlashCharacterCreationTalentsMC
	local talentsMC = this.CCPanel_mc.talents_mc

	for talent in SheetManager.Talents.GetVisible(player, true) do
		if engineValues[talent.ID] ~= nil then
			talent.HasTalent = engineValues[talent.ID]
		end
		talentsMC.addTalentElement(talent.ID, talent.DisplayName, talent.HasTalent, talent.IsChoosable, talent.IsRacial, talent.IsCustom)
	end

	if not Vars.ControllerEnabled then
		talentsMC.positionLists()
	else
		talentsMC.talents_mc.setupLists()
	end
end

CharacterCreation:RegisterInvokeListener("updateTalents", CharacterCreation.UpdateTalents, "Before", "All")

---@private
---@param ui UIObject
function CharacterCreation.UpdateAbilities(self, ui, method)
	local this = self.Root
	if not this or not this.isExtended then
		return
	end
	--this.clearArray("abilityArray")

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
	local engineValues = {}

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
		-- 	SheetManager.SessionManager:RequestPointsUpdate(player, "Ability", abilityValue)
		-- 	updateSessionPoints[player.NetID].Ability = nil
		-- end
	end

	local abilities_mc = this.CCPanel_mc.abilities_mc

	local abilitiesWithDelta = {}
	local updateClassContent = SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION
	
	for ability in SheetManager.Abilities.GetVisible(player, nil, true) do
		local updateData = engineValues[ability.ID]
		if updateData then
			ability.Value = updateData.Value
			ability.Delta = updateData.Delta
		end
		abilities_mc.addAbility(ability.GroupID, ability.GroupDisplayName, ability.ID, ability.DisplayName, ability.Value, ability.Delta, ability.IsCivil, ability.IsCustom)

		if updateClassContent and ability.Delta > 0 then
			abilitiesWithDelta[#abilitiesWithDelta+1] = {
				ID = ability.ID,
				DisplayName = ability.DisplayName,
				Delta = ability.Delta
			}
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

CharacterCreation:RegisterInvokeListener("updateAbilities", CharacterCreation.UpdateAbilities, "Before", "All")

---@private
---@param ui UIObject
function CharacterCreation.UpdateAttributes(self, ui, method)
	local this = CharacterCreation.Root
	if not this or not this.isExtended then
		return
	end
	--this.clearArray("abilityArray")

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()

	local engineValues = {}
	for i=0,#this.attributeArray-1 do
		Ext.PrintWarning(i, this.attributeArray[i])
	end
	for i=0,#this.attributeArray-1,5 do
		--Ext.PrintWarning(i, this.attributeArray[i], this.attributeArray[i+1], this.attributeArray[i+3], this.attributeArray[i+4])
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
		-- 	SheetManager.SessionManager:RequestPointsUpdate(player, "Stat", value)
		-- 	updateSessionPoints[player.NetID].Stat = nil
		-- end
	end

	--Ext.PrintWarning(Lib.serpent.block(engineValues))

	local attributes_mc = this.CCPanel_mc.attributes_mc

	this.availableAttributePoints = SheetManager:GetAvailablePoints(player, "Attribute")

	local attributesWithDelta = {}
	local updateClassContent = SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION
	
	for stat in SheetManager.Stats.GetVisible(player, true, false, not updateClassContent) do
		local updateData = engineValues[stat.ID]
		if updateData then
			stat.Value = updateData.Value
			stat.Delta = updateData.Delta
		end
		attributes_mc.addAttribute(stat.ID, stat.DisplayName, stat.Description, stat.Value, stat.Delta, stat.Frame, stat.IsCustom, stat.IconClipName or "", -3, -3, 0.5, stat.CallbackID or -1)
		if updateClassContent and stat.Delta > 0 then
			attributesWithDelta[#attributesWithDelta+1] = {
				ID = stat.ID,
				DisplayName = stat.DisplayName,
				Delta = stat.Delta
			}
		end
		if not StringHelpers.IsNullOrWhitespace(stat.IconClipName) then
			self.Instance:SetCustomIcon(stat.IconDrawCallName, stat.Icon, stat.IconWidth, stat.IconHeight)
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
	attributes_mc.freePoints_txt.htmlText = string.format("%s %i", this.textArray[12], this.availableAttributePoints)
end

CharacterCreation:RegisterInvokeListener("updateAttributes", CharacterCreation.UpdateAttributes, "Before", "All")

---@private
---@param ui UIObject
function CharacterCreation.OnClassPointsUpdated(self, ui, method, pointType, amount)
	local this = self.Root
	if not this or not this.isExtended then
		return
	end
	if pointType ~= "Skill" then
		local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
		--Since we don't have a way to access the points CC uses, store the change immediately
		SheetManager.AvailablePoints[player.NetID][pointType] = amount
		SheetManager.SessionManager:RequestPointsUpdate(player, pointType, amount, true, true)
	end
end

CharacterCreation:RegisterCallListener("characterCreationPointsUpdated", CharacterCreation.OnClassPointsUpdated, "Before", "Keyboard")
CharacterCreation:RegisterInvokeListener("setDetails", function (self, ui, methid, num, b)
	local this = self.Root
	if not this or not this.isExtended then
		return
	end
	---@type EclCharacter
	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
	if player and player.PlayerCustomData then
		local preset = player.PlayerCustomData.ClassType
		local data = PresetData[preset]
		if data then
			local session = SheetManager.SessionManager:GetSession(player)
			for _,change in pairs(data.AbilityChanges) do
				session.Stats[change.Ability] = session.Stats[change.Ability] + change.AmountIncreased
			end
			for _,change in pairs(data.AttributeChanges) do
				session.Stats[change.Attribute] = session.Stats[change.Attribute] + change.AmountIncreased
			end
			-- SheetManager.AvailablePoints[player.NetID] = {
			-- 	Attribute = data.NumStartingAttributePoints,
			-- 	Ability = data.NumStartingCombatAbilityPoints,
			-- 	Civil = data.NumStartingCivilAbilityPoints,
			-- 	Talent = data.NumStartingTalentPoints,
			-- }
		end
	end
end, "Before", "Keyboard")
--Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation_c, "updateAttributes", CharacterCreation.UpdateAttributes)

function CharacterCreation.Started(self, ui, call)
	CharacterCreation.IsOpen = true
	if SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION then
		local this = self.Root
		if this and this.isExtended then
			this.isExtended = false
		end
	end
end

CharacterCreation:RegisterCallListener("characterCreationStarted", CharacterCreation.Started, "Before", "All")

function CharacterCreation.CreationDone(self, ui, method, startText, backText, visible)
	if visible == false then
		-- UI is closing with no message box confirmation, which can happen if points were only spent on custom entries
		if not MessageBox.UI.Instance and CharacterCreation.IsOpen then
			SheetManager.Save.CharacterCreationDone(Client:GetCharacter(), true)
			CharacterCreation.IsOpen = false
			local this = self.Root
			if this and not this.isExtended then
				this.isExtended = true
			end
		end
	end
end
CharacterCreation:RegisterInvokeListener("creationDone", CharacterCreation.CreationDone, "Before", "All")

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

RegisterListener("RegionChanged", function (region, state, levelType)
	if levelType == LEVELTYPE.CHARACTER_CREATION then
		local this = CharacterCreation.Root
		if this then
			if state ~= REGIONSTATE.ENDED then
				if this.isExtended then this.isExtended = false end
			else
				if this.isExtended == false then this.isExtended = true end
			end
		end
	else
		CharacterCreation.IsOpen = false
	end
end)