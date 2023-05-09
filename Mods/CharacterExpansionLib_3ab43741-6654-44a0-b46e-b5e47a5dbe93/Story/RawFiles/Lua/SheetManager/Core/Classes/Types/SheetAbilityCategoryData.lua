---@class SheetAbilityCategoryData
---@field Mod ModGuid
---@field DisplayName TranslatedString|string
---@field Description TranslatedString|string
---@field ExpandedDescription TranslatedString|string|nil The description to use if the tooltip is expanded. Defaults to the `Description` value if not set.
local SheetAbilityCategoryData = {
	Type="SheetAbilityCategoryData",
	Mod = "",
	ID = "",
	DisplayName = "",
	Description = "",
	GeneratedID = -1,
	Visible = true,
	IsCivil = false,
}
SheetAbilityCategoryData.__index = SheetAbilityCategoryData

SheetAbilityCategoryData.PropertyMap = {
	DISPLAYNAME = {Name="DisplayName", Type = "TranslatedString"},
	DESCRIPTION = {Name="Description", Type = "TranslatedString"},
	EXPANDEDDESCRIPTION = {Name="ExpandedDescription", Type = "TranslatedString"},
	ISCIVIL = {Name="IsCivil", Type = "boolean"},
}

local defaults = {
	ID = SheetAbilityCategoryData.ID,
	Mod = SheetAbilityCategoryData.Mod,
	DisplayName = SheetAbilityCategoryData.DisplayName,
	Description = SheetAbilityCategoryData.Description,
	FlashID = SheetAbilityCategoryData.GeneratedID,
	Visible = SheetAbilityCategoryData.Visible,
	IsCivil = SheetAbilityCategoryData.IsCivil,
}

---@protected
function SheetAbilityCategoryData.SetDefaults(data)
	for k,v in pairs(defaults) do
		if data[k] == nil then
			if type(v) == "table" then
				data[k] = {}
			else
				data[k] = v
			end
		end
	end
end

---@param character? CharacterParam Optional character to pass to GameHelpers.Tooltip.ReplacePlaceholders.
function SheetAbilityCategoryData:GetDisplayName(character)
	return GameHelpers.Tooltip.ReplacePlaceholders(self.DisplayName, character)
end

---@param character? CharacterParam Optional character to pass to GameHelpers.Tooltip.ReplacePlaceholders.
---@param isExpanded? boolean Whether the tooltip is expanded, which will result in the `ExpandedDescription` being used, if set.
function SheetAbilityCategoryData:GetDescription(character, isExpanded)
	local text = ""
	if isExpanded and self.ExpandedDescription then
		text = GameHelpers.Tooltip.ReplacePlaceholders(self.ExpandedDescription, character)
	end
	if self.Description and StringHelpers.IsNullOrEmpty(text) then
		text = GameHelpers.Tooltip.ReplacePlaceholders(self.Description, character)
	end
	if self.Mod then
		local name = GameHelpers.GetModName(self.Mod, true)
		if not StringHelpers.IsNullOrWhitespace(name) then
			local titleColor = "#2299FF"
			local settings = SettingsManager.GetMod(self.Mod, false, false)
			if settings and not StringHelpers.IsNullOrWhitespace(settings.TitleColor) and not StringHelpers.Equals(settings.TitleColor, "#FFFFFF", true, true) then
				titleColor = settings.TitleColor
			end
			text = string.format("%s<br><font color='%s' size='18'>%s</font>", text, titleColor, name)
		end
	end
	return text
end

Classes.SheetAbilityCategoryData = SheetAbilityCategoryData