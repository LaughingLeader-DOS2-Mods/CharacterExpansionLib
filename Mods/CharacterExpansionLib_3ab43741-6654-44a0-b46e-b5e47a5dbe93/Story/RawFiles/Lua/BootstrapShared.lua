ModuleFolder = Ext.GetModInfo(ModuleUUID).Directory
Mods.LeaderLib.ImportUnsafe(Mods.CharacterExpansionLib)

Ext.Require("SheetManager/Init.lua")

local function TryFindOsiToolsConfig(info)
	local filePath = string.format("Mods/%s/OsiToolsConfig.json", info.Directory)
	local file = Ext.LoadFile(filePath, "data")
	if file then
		return Common.JsonParse(file)
	end
end

local function CheckOsiToolsConfig()
	local order = Ext.GetModLoadOrder()
	for i=1,#order do
		local uuid = order[i]
		if IgnoredMods[uuid] ~= true then
			local info = Ext.GetModInfo(uuid)
			if info ~= nil then
				local b,result = xpcall(TryFindOsiToolsConfig, debug.traceback, info)
				if not b then
					Ext.PrintError(result)
				elseif result ~= nil then
					if result.FeatureFlags 
					and (Common.TableHasValue(result.FeatureFlags, "CustomStats") or Common.TableHasValue(result.FeatureFlags, "CustomStatsPane")) then
						return true
					end
				end
			end
		end
	end
end

Ext.RegisterListener("SessionLoading", function()
	--CheckOsiToolsConfig()
end)

function Import(targetTable)
	local targetOriginalGetIndex = nil
	local getIndex = function(tbl, k)
		if _G[k] then
			return _G[k]
		end
		if Mods.LeaderLib[k] then
			return Mods.LeaderLib[k]
		end
		if targetOriginalGetIndex then
			return targetOriginalGetIndex(tbl, k)
		end
	end
	local targetMeta = getmetatable(targetTable)
	if not targetMeta then
		setmetatable(targetTable, {
			__index = getIndex
		})
	else
		if targetMeta.__index then
			targetOriginalGetIndex = targetMeta.__index
		end
		targetMeta.__index = getIndex
	end
end