local isClient = Ext.IsClient()

---@class SheetCustomStatBase
---@field DisplayName TranslatedString|string
---@field Description TranslatedString|string
---@field ExpandedDescription TranslatedString|string|nil The description to use if the tooltip is expanded. Defaults to the `Description` value if not set.
local SheetCustomStatBase = {
	Type="SheetCustomStatBase",
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
	Icon = "",
	IconWidth = 128,
	IconHeight = 128,
	---A generated ID assigned by the SheetManager, used to associate a stat in the UI with this data. In GM mode, this is also the double handle.
	GeneratedID = -1,
	ValueType = "number",
}
SheetCustomStatBase.__index = SheetCustomStatBase

SheetCustomStatBase.PropertyMap = {
	DISPLAYNAME = {Name="DisplayName", Type = "TranslatedString"},
	DESCRIPTION = {Name="Description", Type = "TranslatedString"},
	EXPANDEDDESCRIPTION = {Name="ExpandedDescription", Type = "TranslatedString"},
	ICON = {Name="Icon", Type = "string"},
	ICONWIDTH = {Name="IconWidth", Type = "number"},
	ICONHEIGHT = {Name="IconHeight", Type = "number"},
	TOOLTIPTYPE = {Name="TooltipType", Type = "string"},
	SORTNAME = {Name="SortName", Type = "string"},
	SORTVALUE = {Name="SortValue", Type = "number"},
	LOADSTRINGKEY = {Name="LoadStringKey", Type = "boolean"},
}

local defaults = {
	TooltipType = SheetCustomStatBase.TooltipType,
	ID = SheetCustomStatBase.ID,
	Mod = SheetCustomStatBase.Mod,
	DisplayName = SheetCustomStatBase.DisplayName,
	Description = SheetCustomStatBase.Description,
	GeneratedID = SheetCustomStatBase.GeneratedID,
	Visible = SheetCustomStatBase.Visible,
	SortValue = SheetCustomStatBase.SortValue,
	SortName = SheetCustomStatBase.SortName,
	LoadStringKey = SheetCustomStatBase.LoadStringKey,
	Icon = SheetCustomStatBase.Icon,
	IconWidth = SheetCustomStatBase.IconWidth,
	IconHeight = SheetCustomStatBase.IconWidth,
}

function SheetCustomStatBase.SetDefaults(data)
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
function SheetCustomStatBase:GetDisplayName(character)
	return Classes.SheetBaseData.GetDisplayName(self, character)
end

---@param character? CharacterParam Optional character to pass to GameHelpers.Tooltip.ReplacePlaceholders.
---@param isExpanded? boolean Whether the tooltip is expanded, which will result in the `ExpandedDescription` being used, if set.
function SheetCustomStatBase:GetDescription(character, isExpanded)
	return Classes.SheetBaseData.GetDescription(self, character, isExpanded)
end

Classes.SheetCustomStatBase = SheetCustomStatBase