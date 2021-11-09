ModuleFolder = Ext.GetModInfo(ModuleUUID).Directory

---@class CharacterExpansionLibListeners:table
local listeners = {}
Mods.CharacterExpansionLib.Listeners = listeners

Mods.LeaderLib.Import(Mods.CharacterExpansionLib)

local isClient = Ext.IsClient()

---@alias SetCharacterCreationOriginSkillsCallback fun(player:EclCharacter, origin:string, race:string, skills:string[]):string[]

if isClient then
	listeners.SetCharacterCreationOriginSkills = {
		---@private
		---@type SetCharacterCreationOriginSkillsCallback[]
		Callbacks = {},
		---@param callback SetCharacterCreationOriginSkillsCallback
		Register = function(callback)
			table.insert(listeners.SetCharacterCreationOriginSkills.Callbacks, callback)
		end
	}
end

---@param id string
---@param callback fun(id:string, payload:string, user:integer|nil):void
function RegisterNetListener(id, callback)
	Ext.RegisterNetListener(id, function(id, payload, user)
		-- if Vars.LeaderDebugMode then
		-- 	--fprint(LOGLEVEL.DEFAULT, "[NetListener:%s] id(%s) user(%s) payload:\n%s", Ext.IsClient() and "CLIENT" or "SERVER", id, user, payload)
		-- end
		local b,err = xpcall(callback, debug.traceback, id, payload, user)
		if not b then
			Ext.PrintError(err)
		end
	end)
end


Ext.Require("SheetManager/Init.lua")
Ext.Require("OriginManager/Init.lua")

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