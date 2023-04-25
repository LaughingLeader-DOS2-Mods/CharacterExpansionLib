---@class SheetRaceDataTalentEntry
---@field ID string
---@field Mod string The mod for the talent. Defaults to the mod the parent race was loaded from.
local SheetRaceDataTalentEntry = {
	ID = "",
	Mod = ""
}
---@private
SheetRaceDataTalentEntry.PropertyMap = {
	ID = {Name="ID", Type = "string"},
	MOD = {Name="Mod", Type = "table"},
}

Classes.SheetRaceDataTalentEntry = SheetRaceDataTalentEntry

---@class SheetRaceData
local SheetRaceData = {
	Type="SheetRaceData",
	---The race ID. This should be the ID used by race presets / PlayerCustomData.
	Race = "",
	Mod = "",
	---Identifying tags for this race. NPCs use tags, due to not having PlayerCustomData.
	---@type string[]
	Tags = {},
	---Talents that should be automatically added to this race.
	---@type SheetRaceDataTalentEntry[]
	Talents = {},
	---Allow custom/generic origins to use this race.<br>If this is `false`, only pre-configured origins can use this race.<br>This property is checked in character creation.
	AllowCustom = true,
}

---@private
SheetRaceData.PropertyMap = {
	RACE = {Name="Race", Type = "string"},
	TAGS = {Name="Tags", Type = "table"},
	TALENTS = {Name="Talents", Type = "table"},
	ALLOWCUSTOM = {Name="AllowCustom", Type = "boolean"},
}

local defaults = {
	Race = SheetRaceData.Race,
	AllowCustom = SheetRaceData.AllowCustom
}

---@protected
function SheetRaceData.SetDefaults(data)
	for _,v in pairs(SheetRaceData.PropertyMap) do
		local k = v.Name
		if data[k] == nil then
			if v.Type == "table" then
				data[k] = {}
			else
				data[k] = defaults[k]
			end
		end
	end
end

---@param id string
---@param mod? Guid
function SheetRaceData:AddTalent(id, mod)
	self.Talents[#self.Talents+1] = {ID = id, Mod = mod}
end

Classes.SheetRaceData = SheetRaceData