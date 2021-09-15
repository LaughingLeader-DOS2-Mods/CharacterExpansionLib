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
	--this.clearArray("talentArray")
	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()

	---@type FlashCharacterCreationTalentsMC
	local talentsMC = this.CCPanel_mc.talents_mc

	for talent in SheetManager.Talents.GetVisible(player, true) do
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
	--this.clearArray("abilityArray")

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()

	local abilities_mc = this.CCPanel_mc.abilities_mc
	
	local class_mc = this.CCPanel_mc.class_mc
	local classEdit = class_mc.classEditList[1]
	classEdit.contentList.clearElements()
	for ability in SheetManager.Abilities.GetVisible(player, nil, true) do
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
	--this.clearArray("abilityArray")

	-- print("attributeArray")
	-- for i=0,#this.attributeArray-1 do
	-- 	print(i, this.attributeArray[i])
	-- end

	local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle)) or Client:GetCharacter()
	local attributes_mc = this.CCPanel_mc.attributes_mc

	this.availableAttributePoints = SheetManager:GetAvailablePoints(player, "Attribute")
	
	for stat in SheetManager.Stats.GetVisible(player, true) do
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