--[[
Mods/ModName_UUID/CharacterSheetConfig.json
Format:
{
	"Talents": {
		"ID": {
			"DisplayName": "",
			"Description": "",
			"Icon": ""
		}
	},
	"Abilities": {
		"ID": {
			"DisplayName": "",
			"Description": "",
			"Icon": ""
		}
	},
	"Stats": {
		"ID": {
			"DisplayName": "",
			"Description": ""
		}
	},
	"CustomStats": {
		"ID": {
			"DisplayName": "",
			"Description": ""
		}
	},
	"CustomStatCategories": {
		"ID": {
			"DisplayName": "",
			"Description": ""
		}
	}
}
]]

local isClient = Ext.IsClient()

local function parseTable(tbl, propertyMap, modId, defaults, class, id_map)
	local tableData = nil
	if type(tbl) == "table" then
		tableData = {}
		for k,v in pairs(tbl) do
			if type(v) == "table" then
				local data = {
					ID = k,
					Mod = modId
				}
				if defaults then
					for property,value in pairs(defaults) do
						if type(property) == "string" then
							local propKey = string.upper(property)
							local propData = propertyMap[propKey]
							local t = type(value)
							if propData then
								if propData.Type == "enum" then
									data[propData.Name] = propData.Parse(value,t)
								elseif (propData.Type == "any" or t == propData.Type) then
									data[propData.Name] = value
								elseif t == "number" and propData.Type == "integer" then
									data[propData.Name] = Ext.Round(value)
								end
							else
								--fprint(LOGLEVEL.WARNING, "[CharacterExpansionLib:SheetManager.ConfigLoader] Defaults for stat(%s) has unknown property (%s) with value type(%s)", k, property, t)
							end
						end
					end
				end
				for property,value in pairs(v) do
					if type(property) == "string" then
						local propKey = string.upper(property)
						local propData = propertyMap[propKey]
						local t = type(value)
						if propData then
							if propData.Type == "enum" then
								data[propData.Name] = propData.Parse(value,t)
							elseif (propData.Type == "any" or t == propData.Type) then
								data[propData.Name] = value
							end
						else
							--fprint(LOGLEVEL.WARNING, "[CharacterExpansionLib:SheetManager.ConfigLoader] Stat(%s) has unknown property (%s) with value type(%s)", k, property, t)
						end
					end
				end
				if id_map then
					id_map.NEXT_ID = id_map.NEXT_ID + 1
					data.GeneratedID = id_map.NEXT_ID
					id_map.Entries[data.GeneratedID] = data
				end

				if class then
					if class.SetDefaults then
						class.SetDefaults(data)
					end
					setmetatable(data, class)
				end
				tableData[k] = data
			end
		end
	end
	return tableData
end

local function LoadConfig(uuid, config)
	local loaded = {}
	local defaults = {
		Stats = nil,
		Abilities = nil,
		Talents = nil,
		CustomStats = nil,
		CustomStatCategories = nil
	}
	if config ~= nil then
		if config.Defaults then
			if config.Defaults.Stats then
				defaults.Stats = config.Defaults.Stats
			end
			if config.Defaults.Abilities then
				defaults.Abilities = config.Defaults.Abilities
			end
			if config.Defaults.Talents then
				defaults.Talents = config.Defaults.Talents
			end
			if config.Defaults.CustomStats then
				defaults.CustomStats = config.Defaults.CustomStats
			end
			if config.Defaults.CustomStatCategories then
				defaults.CustomStatCategories = config.Defaults.CustomStatCategories
			end
		end
		local stats = parseTable(config.Stats, Classes.SheetStatData.PropertyMap, uuid, defaults.Stats, Classes.SheetStatData, SheetManager.Data.ID_MAP.Stats)
		local abilities = parseTable(config.Abilities, Classes.SheetAbilityData.PropertyMap, uuid, defaults.Abilities, Classes.SheetAbilityData, SheetManager.Data.ID_MAP.Abilities)
		local talents = parseTable(config.Talents, Classes.SheetTalentData.PropertyMap, uuid, defaults.Talents, Classes.SheetTalentData, SheetManager.Data.ID_MAP.Talents)
		local customStats = parseTable(config.CustomStats, Classes.SheetCustomStatData.PropertyMap, uuid, defaults.CustomStats, Classes.SheetCustomStatData, SheetManager.Data.ID_MAP.CustomStats)
		local categories = parseTable(config.CustomStatCategories, Classes.SheetCustomStatCategoryData.PropertyMap, uuid, defaults.CustomStatCategories, Classes.SheetCustomStatCategoryData, SheetManager.Data.ID_MAP.CustomStatCategories)

		if stats then
			loaded.Stats = stats
			loaded.Success = true
		end
		if talents then
			loaded.Talents = talents
			loaded.Success = true
		end
		if abilities then
			loaded.Abilities = abilities
			loaded.Success = true
		end
		if customStats then
			loaded.CustomStats = customStats
			loaded.Success = true
		end
		if categories then
			loaded.CustomStatCategories = categories
			loaded.Success = true
		end
	end
	return loaded
end

local function TryFindConfig(info)
	local filePath = string.format("Mods/%s/CharacterSheetConfig.json", info.Directory)
	local file = Ext.IO.LoadFile(filePath, "data")
	return file
end

local function TryFindOldCustomStatsConfig(info)
	local filePath = string.format("Mods/%s/CustomStatsConfig.json", info.Directory)
	local file = Ext.IO.LoadFile(filePath, "data")
	return file
end

---@return table<string, table<string, SheetCustomStatBase>>
local function LoadConfigFiles()
	local entries = {}
	local order = Ext.GetModLoadOrder()
	for i=1,#order do
		local uuid = order[i]
		if IgnoredMods[uuid] ~= true then
			local info = Ext.GetModInfo(uuid)
			if info ~= nil then
				local b,result = xpcall(TryFindConfig, debug.traceback, info)
				if not b then
					Ext.Utils.PrintError(result)
				elseif result ~= nil and result ~= "" then
					local config = Common.JsonParse(result)
					if config then
						local data = LoadConfig(uuid, config)
						if data and data.Success then
							entries[uuid] = data
						end
					end
				end
				local b,result = xpcall(TryFindOldCustomStatsConfig, debug.traceback, info)
				if not b then
					Ext.Utils.PrintError(result)
				elseif result ~= nil and result ~= "" then
					local config = Common.JsonParse(result)
					if config then
						--Translate table to new system
						if config.Defaults then
							if config.Defaults.Stats then
								config.Defaults.CustomStats = TableHelpers.Clone(config.Defaults.Stats)
								config.Defaults.Stats = nil
							end
							if config.Defaults.Categories then
								config.Defaults.CustomStatCategories = TableHelpers.Clone(config.Defaults.Categories)
								config.Defaults.Categories = nil
							end
						end
						if config.Stats then
							config.CustomStats = TableHelpers.Clone(config.Stats)
							config.Stats = nil
						end
						if config.Categories then
							config.CustomStatCategories = TableHelpers.Clone(config.Categories)
							config.Categories = nil
						end
						local data = LoadConfig(uuid, config)
						if data and data.Success then
							if entries[uuid] == nil then
								entries[uuid] = data
							else
								TableHelpers.AddOrUpdate(entries[uuid], data)
							end
						end
					end
				end
			end
		end
	end

	-- if Vars.DebugMode and Vars.LeaderDebugMode then
	-- 	--local data = LoadConfig(ModuleUUID, Ext.IO.LoadFile("Mods/"..ModuleFolder.."/Story/RawFiles/Lua/SheetManager/Debug/TestSheetEntriesConfig.json", "data"))
	-- 	local dataStr = Ext.IO.LoadFile("Mods/"..ModuleFolder.."/Story/RawFiles/Lua/SheetManager/Debug/TestSheetEntriesConfig2.json", "data")
	-- 	if dataStr then
	-- 		local data = LoadConfig(ModuleUUID, Common.JsonParse(dataStr))
	-- 		if data and data.Success then
	-- 			entries[ModuleUUID] = data
	-- 		end
	-- 	end
	-- end
	return entries
end

return LoadConfigFiles