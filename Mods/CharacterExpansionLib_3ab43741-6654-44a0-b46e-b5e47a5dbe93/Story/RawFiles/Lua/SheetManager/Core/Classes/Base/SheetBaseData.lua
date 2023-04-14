---@class SheetBaseData
---@field DisplayName TranslatedString|string
---@field Description TranslatedString|string
---@field ExpandedDescription TranslatedString|string|nil The description to use if the tooltip is expanded. Defaults to the `Description` value if not set.
local SheetBaseData = {
	Type="SheetBaseData",
	TooltipType = "Stat",
	ID = "",
	---@type ModGuid
	Mod = "",
	DisplayName = "",
	Description = "",
	Visible = true,
	---@type integer If set, this is the sort value number to use when the list of stats get sorted for display.
	SortValue = nil,
	---@type string If set, this is the name to use instead of DisplayName when the list of stats get sorted for display. 
	SortName = nil,
	---Optional setting to force the string key conversion for DisplayName, in case the value doesn't have an underscore.
	LoadStringKey = false,
	---A generated ID assigned by the SheetManager, used to associate a stat in the UI with this data.
	GeneratedID = -1,
	---The character attribute to use for automatic get/set outside of the PersistentVars system.
	---If set, value get/set will use the built-in boost attribute of the character with this name.
	BoostAttribute = "",
	---Text to append to the value display, such as a percentage sign.
	Suffix = "",
	---Whether  this entry uses character points, such as Attribute/Ability/Talent points.
	UsePoints = false,
	Icon = "",
	IconWidth = 128,
	IconHeight = 128,
	ValueType = "number",
	BaseValue = 0,
}

SheetBaseData.PropertyMap = {
	DISPLAYNAME = {Name="DisplayName", Type = "TranslatedString"},
	DESCRIPTION = {Name="Description", Type = "TranslatedString"},
	EXPANDEDDESCRIPTION = {Name="ExpandedDescription", Type = "TranslatedString"},
	TOOLTIPTYPE = {Name="TooltipType", Type = "string"},
	BASEVALUE = {Name="BaseValue", Type = "number"},
	VISIBLE = {Name="Visible", Type = "boolean"},
	SORTNAME = {Name="SortName", Type = "string"},
	SORTVALUE = {Name="SortValue", Type = "number"},
	LOADSTRINGKEY = {Name="LoadStringKey", Type = "boolean"},
	BOOSTATTRIBUTE = {Name="BoostAttribute", Type = "string"},
	SUFFIX = {Name="Suffix", Type = "string"},
	USEPOINTS = {Name="UsePoints", Type = "boolean"},
	ICON = {Name="Icon", Type = "string"},
	ICONWIDTH = {Name="IconWidth", Type = "number"},
	ICONHEIGHT = {Name="IconHeight", Type = "number"},
}

local defaults = {
	ID = SheetBaseData.ID,
	Mod = SheetBaseData.Mod,
	DisplayName = SheetBaseData.DisplayName,
	Description = SheetBaseData.Description,
	Visible = SheetBaseData.Visible,
	SortValue = SheetBaseData.SortValue,
	SortName = SheetBaseData.SortName,
	LoadStringKey = SheetBaseData.LoadStringKey,
	GeneratedID = SheetBaseData.GeneratedID,
	BoostAttribute = SheetBaseData.BoostAttribute,
	Suffix = SheetBaseData.Suffix,
	UsePoints = SheetBaseData.UsePoints,
	Icon = SheetBaseData.Icon,
	IconWidth = SheetBaseData.IconWidth,
	IconHeight = SheetBaseData.IconWidth,
}

---@protected
function SheetBaseData.SetDefaults(data)
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
function SheetBaseData:GetDisplayName(character)
	return GameHelpers.Tooltip.ReplacePlaceholders(self.DisplayName, character)
end

---@param character? CharacterParam Optional character to pass to GameHelpers.Tooltip.ReplacePlaceholders.
---@param isExpanded? boolean Whether the tooltip is expanded, which will result in the `ExpandedDescription` being used, if set.
function SheetBaseData:GetDescription(character, isExpanded)
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

---@param character CharacterParam
---@param fallback integer|boolean
function SheetBaseData:GetBoostValue(character, fallback)
	local character = GameHelpers.GetCharacter(character)
	if character then
		local value = character.Stats.DynamicStats[2][self.BoostAttribute]
		if value == nil then
			--fprint(LOGLEVEL.ERROR, "[LeaderLib:SheetTalentData:GetValue] BoostAttribute(%s) for entry (%s) does not exist within StatCharacter!", self.BoostAttribute, self.ID)
			return fallback
		end
		return value
	end
	return fallback
end

Classes.SheetBaseData = SheetBaseData