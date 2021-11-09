---@class SheetCustomStatCategoryData:SheetCustomStatBase
local SheetCustomStatCategoryData = {
	Type="SheetCustomStatCategoryData",
	ShowAlways = false,
	HideTotalPoints = false,
	TooltipType = "Stat",
	GroupId = nil,
}

SheetCustomStatCategoryData.PropertyMap = {
	SHOWALWAYS = {Name="ShowAlways", Type = "boolean"},
	HIDETOTALPOINTS = {Name="HideTotalPoints", Type = "boolean"},
}

TableHelpers.AddOrUpdate(SheetCustomStatCategoryData.PropertyMap, Classes.SheetCustomStatBase.PropertyMap)

SheetCustomStatCategoryData.__index = function(t,k)
	local v = Classes.SheetCustomStatBase[k]
	if v then
		t[k] = v
	end
	return v
end

--setmetatable(SheetCustomStatCategoryData, SheetCustomStatCategoryData)
Classes.SheetCustomStatCategoryData = SheetCustomStatCategoryData