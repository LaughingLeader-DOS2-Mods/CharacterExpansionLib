local isClient = Ext.IsClient()

---@class OriginSettings
local OriginSettings = {
	Type="OriginSettings",
	ID = "",
	---@type string
	Mod = "",
	SkillSets = {},
	Force = {
		Face = -1,
		Hair = -1,
		HairColor = -1,
		SkinColor = -1,
	},
}

local PropertyMap = {
	SKILLSETS = {Name = "SkillSets", Type = "table", EntryType = "string"},
	FORCE = {Name = "Force", Type = "table", EntryMap = {
		FACE = {Name = "Face", Type = "number"},
		HAIR = {Name = "Hair", Type = "number"},
		HAIRCOLOR = {Name = "HairColor", Type = "number"},
		SKINCOLOR = {Name = "SkinColor", Type = "number"},
	}}
}

function OriginSettings.GetPropertyMap()
	return PropertyMap
end

local defaults = {
	SkillSets = {},
	Force = {
		Face = -1,
		Hair = -1,
		HairColor = -1,
		SkinColor = -1,
	},
}

---@protected
function OriginSettings.SetDefaults(data)
	for k,v in pairs(defaults) do
		if data[k] == nil then
			if type(v) == "table" then
				data[k] = TableHelpers.Clone(v)
			else
				data[k] = v
			end
		end
	end
end

---@param character EsvCharacter|EclCharacter
function OriginSettings:ApplySettings(character)
	local isInCC = SheetManager.IsInCharacterCreation(character)
	if self.SkillSets then
		for i=1,#self.SkillSets do
			local skillset = Ext.GetSkillSet(self.SkillSets[i])
			if skillset then
				for j=1,#skillset.Skills do
					if not isClient then
						CharacterAddSkill(character.MyGuid, skillset.Skills[j], 0)
					elseif isInCC then
						
					end
				end
			end
		end
	end

	if character.PlayerCustomData then
		if self.Force then
			if self.Force.HairColor then
				character.PlayerCustomData.HairColor = self.Force.HairColor
			end
			if self.Force.SkinColor then
				character.PlayerCustomData.SkinColor = self.Force.SkinColor
			end
		end
		character.PlayerCustomData.OriginName = self.ID
	end

	if isInCC and isClient then

	end
end

Classes.OriginSettings = OriginSettings