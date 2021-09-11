ModuleFolder = Ext.GetModInfo(ModuleUUID).Directory
Mods.LeaderLib.Import(Mods.CharacterExpansionLib)

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

---Makes CharacterExpansionLib's and LeaderLib's globals accessible using metamethod magic. Pass it a mod table, such as Mods.MyModTable.
---@param targetModTable table
function Import(targetModTable)
	Mods.LeaderLib.Import(targetModTable, Mods.CharacterExpansionLib)
end