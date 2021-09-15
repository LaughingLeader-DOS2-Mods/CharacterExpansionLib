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
	fprint("[GetContentLength] type(%s) name(%s)", contentTypeEnum, contentType)
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
	local this = self:GetRoot()
	if this then
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
	end
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

---@param self CharacterCreationWrapper
---@param ui UIObject
local function SetSkills(self, ui, event)
	local this = self:GetRoot()
	if this then
		local player = Ext.GetCharacter(Ext.DoubleToHandle(this.characterHandle))
		local origin = player.PlayerCustomData.OriginName
		local race = player.PlayerCustomData.Race

		InvokeListenerCallbacks(Listeners.SetCharacterCreationOriginSkills, player, origin, race, this.racialSkills)

		for i=0,#this.racialSkills-1 do
			local icon = Ext.StatGetAttribute(this.racialSkills[i], "Icon")
			ui:SetCustomIcon(string.format("cel_racial%i", i), icon, this.iconSize, this.iconSize)
		end
		--ui:SetCustomIcon("p", "Skill_Fire_EpidemicOfFire", 64, 64)
	end
end

if Vars.DebugMode then
	local testArray = Ext.Require("OriginManager/Debug/ContentParserTesting.lua")
	Ext.RegisterConsoleCommand("testcc", function()
		ParseArray(testArray)
	end)
end

return {
	---@param cc CharacterCreationWrapper
	Init = function(cc)
		cc:RegisterInvokeListener("updateContent", OnUpdateContent, "Before", "All")
		cc:RegisterInvokeListener("updateSkills", SetSkills, "After", "All")
	end
}