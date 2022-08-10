local ElementType = {
	[0] = "OptionSelector",
	[1] = "Option",
	[2] = "Content",
	[3] = "ControllerInput",
	[4] = "Title",
	[5] = "OptionSelector",
}

local ContentType = {
	[0] = "Text",
	[1] = "List",
	[2] = "cdContent",
	[3] = "Tooltip",
	[4] = "inputBtnHint",
}

local ContentTypeLength = {
	[false] = {
		Text = 1,
		List = 2,
		cdContent = 2,
		Tooltip = 1,
		inputBtnHint = 0,
	},
	--Controllers
	[true] = {
		Text = 1,
		List = 2,
		cdContent = 2,
		Tooltip = 1,
		inputBtnHint = 2,
	},
}
local function GetContentLength(arr, contentTypeEnum, contentStartIndex)
	local length = 3
	local contentType = ContentType[contentTypeEnum]
	--fprint("[GetContentLength] type(%s) name(%s)", contentTypeEnum, contentType)
	if contentType then
		if contentType ~= "List" then
			return length + ContentTypeLength[Vars.ControllerEnabled][contentType],contentType
		else
			local listLength = arr[contentStartIndex+1]
			length = length + 2
			if listLength and type(listLength) == "number" then
				length = length + (listLength * 2)
			end
			return length,contentType
		end
	end
	return length,contentType
end

local ElementTypeSize = {
	[false] = {
		OptionSelector = 0,
		Option = 3,
		Content = GetContentLength,
		ControllerInput = 0,
		Title = 2,
	},
	--Controllers
	[true] = {
		OptionSelector = 3,
		Option = 3,
		Content = GetContentLength,
		ControllerInput = 3,
		Title = 2,
	},
}

local ElementTypeNames = {
	OptionSelector = "OptionSelector",
	Option = "Option",
	Content = "Content",
	ControllerInput = "ControllerInput",
	Title = "Title",
}

---@class ContentParserElement
---@field TypeName string
---@field TypeId integer
---@field ContentType string
---@field Count integer
---@field Elements string|integer|boolean[]

---@return ContentParserElement[]
local function ParseArray(arr)
	local content = {}
	local count = 0
	local i = 0
	local length = #arr-1
	while i < length do
		local entryTypeInt = arr[i]
		local entryType = ElementType[entryTypeInt]
		i = i + 1
		if entryType then
			local data = {
				TypeName = entryType,
				TypeId = entryTypeInt,
				Elements = {}
			}
			local length = ElementTypeSize[Vars.ControllerEnabled][entryType]
			if length then
				if type(length) == "function" then
					local contentLength,contentType = length(arr, arr[i+2], i+3)
					data.ContentType = contentType

					length = contentLength
				end
				for j=0,length-1 do
					data.Elements[#data.Elements+1] = arr[i+j]
				end
				data.Count = length
				i = i + length
			end
			count = count + 1
			content[count] = data
		end
	end
	Ext.SaveFile("ConsoleDebug/ContentParser_ArrayToTableDump.lua", TableHelpers.ToString(content))
	return content,count
end

---@param element ContentParserElement
local function IgnoreElement(element)
	if not element then
		return true
	end
	-- if element.TypeName == ElementTypeNames.Option and element.Elements[3] == '<font color="#C80030">Custom:</font> Elf' then
	-- 	return true
	-- end
	return false
end

---@param self CharacterCreationWrapper
---@param ui UIObject
local function OnUpdateContent(self, ui, event)
	if not SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION then
		return
	end
	-- local this = self:GetRoot()
	-- if this then
		--Override success
		--[[ if this.isExtended then
			local content,count = ParseArray(this.contentArray)
			this.clearArray("contentArray")

			local index = 0
			for i=1,count do
				local element = content[i]
				if not IgnoreElement(element) then
					this.contentArray[index] = element.TypeId
					index = index + 1
					for j=1,#element.Elements do
						this.contentArray[index] = element.Elements[j]
						index = index + 1
					end
				end
			end
		end ]]
	--end
end

--[[
	Original:
	x: -67.5
	y: 155
	width: 135
	height: 55
]]
--[[
	Modified:
	x -67.5
	y 155
	width 135
]]

local activeCustomDraws = {}

---@param self CharacterCreationWrapper
---@param ui UIObject
local function SetSkills(self, ui, event)
	if not SharedData.RegionData.LevelType == LEVELTYPE.CHARACTER_CREATION then
		return
	end
	local this = self:GetRoot()
	if this then
		local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle))
		local origin = player.PlayerCustomData.OriginName
		local race = player.PlayerCustomData.Race

		local skills = {}
		activeCustomDraws = {}

		if not Vars.ControllerEnabled then
			for i=0,#this.racialSkills-1 do
				if this.racialSkills[i] then
					table.insert(skills, this.racialSkills[i])
				end
			end
	
			local callbacks = Mods.CharacterExpansionLib.Listeners.SetCharacterCreationOriginSkills.Callbacks
			if callbacks then
				for i=1,#callbacks do
					local callback = callbacks[i]
					local b,result = xpcall(callback, debug.traceback, player, origin, race, skills)
					if not b then
						Ext.PrintError(result)
					else
						if type(result) == "table" then
							skills = result
						end
					end
				end
			end
	
			if this.clearArray then
				this.clearArray("racialSkills")
			end

			local i = 0
			for _,v in ipairs(skills) do
				local icon = Ext.StatGetAttribute(v, "Icon")
				if not StringHelpers.IsNullOrWhitespace(icon) then
					local iconId = string.format("llcel_racial%i", i)
					ui:SetCustomIcon(iconId, icon, this.iconSize, this.iconSize)
					activeCustomDraws[#activeCustomDraws+1] = {
						ID = iconId,
						Icon = icon,
						Size = this.iconSize
					}
				end
				this.racialSkills[i] = v
				i = i + 1
			end
		else
			--TODO
		end
	end
end

if Ext.IsDeveloperMode() then
	RegisterListener("BeforeLuaReset", function ()
		Ext.SaveFile("CEL_Debug_CCDrawIcons.json", Common.JsonStringify(activeCustomDraws))
	end)
	
	RegisterListener("LuaReset", function ()
		local f = Ext.LoadFile("CEL_Debug_CCDrawIcons.json")
		if f then
			local data = Common.JsonParse(f)
			if data then
				local ui = SheetManager.UI.CharacterCreation:GetInstance()
				if ui then
					for _,v in pairs(data) do
						ui:SetCustomIcon(v.ID, v.Icon, v.Size, v.Size)
					end
					activeCustomDraws = data
				end
			end
		end
	end)

	local testArray = Ext.Require("CharacterCreationExtended/Debug/ContentParserTesting.lua")
	Ext.RegisterConsoleCommand("testcc", function()
		ParseArray(testArray)
	end)
end

SheetManager.UI.CharacterCreation.Register:Invoke("updateContent", OnUpdateContent, "Before", "All")
SheetManager.UI.CharacterCreation.Register:Invoke("updateSkills", SetSkills, "After", "All")