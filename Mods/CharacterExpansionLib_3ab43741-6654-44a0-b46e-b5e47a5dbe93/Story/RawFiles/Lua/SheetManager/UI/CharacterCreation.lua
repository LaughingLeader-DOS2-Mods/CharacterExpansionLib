if SheetManager.UI == nil then SheetManager.UI = {} end

---@class CharacterCreationWrapper:LeaderLibUIWrapper
local CharacterCreation = Classes.UIWrapper:CreateFromType(Data.UIType.characterCreation, {ControllerID = Data.UIType.characterCreation_c, IsControllerSupported = true})
local self = CharacterCreation

---@class FlashCharacterCreationTalentsMC:FlashMovieClip
---@field addTalentElement fun(talentID:integer, talentLabel:string, isUnlocked:boolean, isChoosable:boolean, isRacial:boolean):void
---@field addCustomTalentElement fun(customID:string, talentLabel:string, isUnlocked:boolean, isChoosable:boolean, isRacial:boolean):void

---@private
---@param ui UIObject
function CharacterCreation.UpdateTalents(ui, method)
	local this = self.Root
	if not this then
		return
	end

	local engineValues = {}

	--talentArray[0] is available points
	for i=1,#this.talentArray-1,4 do
		local statID = this.talentArray[i]
		--local talentLabel = this.talentArray[i+1]
		local isUnlocked = this.talentArray[i+2]
		--local choosable = this.talentArray[i+3]
		if statID and isUnlocked ~= nil then
			engineValues[statID] = isUnlocked
		end
	end

	--this.clearArray("talentArray")
	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()

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

Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation, "updateTalents", CharacterCreation.UpdateTalents)
Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation_c, "updateTalents", CharacterCreation.UpdateTalents)

---@private
---@param ui UIObject
function CharacterCreation.UpdateAbilities(ui, method)
	local this = self.Root
	if not this then
		return
	end
	--this.clearArray("abilityArray")

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
	end

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()

	local abilities_mc = this.CCPanel_mc.abilities_mc
	
	local class_mc = this.CCPanel_mc.class_mc
	local classEdit = class_mc.classEditList[1]
	classEdit.contentList.clearElements()
	for ability in SheetManager.Abilities.GetVisible(player, nil, true) do
		local updateData = engineValues[ability.ID]
		if updateData then
			ability.Value = updateData.Value
			ability.Delta = updateData.Delta
		end
		classEdit.addContentString(1,ability.ID,ability.DisplayName)
		abilities_mc.addAbility(ability.GroupID, ability.GroupDisplayName, ability.ID, ability.DisplayName, ability.Value, ability.Delta, ability.IsCivil, ability.IsCustom)
	end
	classEdit.contentList.positionElements()

	if not Vars.ControllerEnabled then
		abilities_mc.updateComplete()
	end
end

Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation, "updateAbilities", CharacterCreation.UpdateAbilities)
Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation_c, "updateAbilities", CharacterCreation.UpdateAbilities)

---@private
---@param ui UIObject
function CharacterCreation.UpdateAttributes(ui, method)
	local this = self.Root
	if not this then
		return
	end
	--this.clearArray("abilityArray")

	local engineValues = {}
	for i=0,#this.attributeArray-1,5 do
		local statID = this.attributeArray[i]
		-- local label = this.abilityArray[i+1]
		-- local attributeInfo = this.abilityArray[i+2]
		local value = this.attributeArray[i+3]
		local delta = this.attributeArray[i+4]
		engineValues[statID] = {
			Value = value,
			Delta = delta
		}
	end

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
	local attributes_mc = this.CCPanel_mc.attributes_mc

	this.availableAttributePoints = SheetManager:GetAvailablePoints(player, "Attribute")
	
	for stat in SheetManager.Stats.GetVisible(player, true) do
		local updateData = engineValues[stat.ID]
		if updateData then
			stat.Value = updateData.Value
			stat.Delta = updateData.Delta
		end
		attributes_mc.addAttribute(stat.ID, stat.DisplayName, stat.Description, stat.Value, stat.Delta, stat.Frame, stat.IsCustom, stat.IconClipName or "", -3, -3)
		if not StringHelpers.IsNullOrWhitespace(stat.IconClipName) then
			self.Instance:SetCustomIcon(stat.IconDrawCallName, stat.Icon, stat.IconWidth, stat.IconHeight)
		end
	end

	--attributes_mc.root_mc.CCPanel_mc.class_mc.addTabTextContent(0,val2);

	attributes_mc.attributes.cleanUpElements()
	attributes_mc.freePoints_txt.htmlText = string.format("%s %i", this.textArray[12], this.availableAttributePoints)
end

Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation, "updateAttributes", CharacterCreation.UpdateAttributes)
Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation_c, "updateAttributes", CharacterCreation.UpdateAttributes)

function CharacterCreation.Started(ui, call)
	CharacterCreation.IsOpen = true
end

Ext.RegisterUITypeCall(Data.UIType.characterCreation, "characterCreationStarted", CharacterCreation.Started)
Ext.RegisterUITypeCall(Data.UIType.characterCreation_c, "characterCreationStarted", CharacterCreation.Started)

function CharacterCreation.CreationDone(ui, method, startText, backText, visible)
	if visible == false then
		-- UI is closing with no message box confirmation, which can happen if points were only spent on custom entries
		if not MessageBox.UI.Instance and CharacterCreation.IsOpen then
			SheetManager.Save.CharacterCreationDone(Client:GetCharacter(), true)
			CharacterCreation.IsOpen = false
		end
	end
end
Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation, "creationDone", CharacterCreation.CreationDone)
Ext.RegisterUITypeInvokeListener(Data.UIType.characterCreation_c, "creationDone", CharacterCreation.CreationDone)

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