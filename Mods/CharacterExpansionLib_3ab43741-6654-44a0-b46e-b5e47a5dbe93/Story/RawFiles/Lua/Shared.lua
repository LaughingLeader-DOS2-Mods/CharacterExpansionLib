local _VERSION = Ext.Utils.Version()

ModuleFolder = Ext.Mod.GetModInfo(ModuleUUID).Directory

---@class CharacterExpansionLibListeners:table
local listeners = {}
Mods.CharacterExpansionLib.Listeners = listeners

Mods.LeaderLib.Import(Mods.CharacterExpansionLib)

---Makes CharacterExpansionLib's and LeaderLib's globals accessible using metamethod magic. Pass it a mod table, such as Mods.MyModTable.
---Usage: Mods.CharacterExpansionLib.Import(Mods.MyModTable)
---@param targetModTable table
function Import(targetModTable)
	Mods.LeaderLib.Import(targetModTable, Mods.CharacterExpansionLib)
end

local _ISCLIENT = Ext.IsClient()

if _ISCLIENT then
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

local printMessages = {
	CEL_SheetManager_RequestValueChange = true,
	CEL_SheetManager_LoadAvailablePointsForCharacter = true,
	CEL_SheetManager_LoadAllAvailablePoints = true,
	CEL_SheetManager_RequestAvailablePoints = true,
	CEL_SheetManager_RequestAvailablePointsWithDelay = true,
	CEL_RequestSyncAvailablePoints = true,
}

local _netListeners = {}
Ext.Events.NetMessageReceived:Subscribe(function(e)
	InvokeListenerCallbacks(_netListeners[e.Channel], e.Channel, e.Payload, e.UserID)
end)

---@param id string
---@param callback fun(id:string, payload:string, user:integer|nil)
function RegisterNetListener(id, callback)
	if _netListeners[id] == nil then
		_netListeners[id] = {}
	end
	local listeners = _netListeners[id]
	local wrapper = function (_id, payload, user)
		--fprint(LOGLEVEL.WARNING, "[%s:NetListener] id(%s) user(%s) payload:\n%s", isClient and "CLIENT" or "SERVER", _id, user, payload)
		-- if Vars.LeaderDebugMode and printMessages[id] then
		-- 	--fprint(LOGLEVEL.WARNING,"%s (%s)", id, isClient and "CLIENT" or "SERVER")
		-- 	fprint(LOGLEVEL.WARNING, "[%s:NetListener] id(%s) user(%s) payload:\n%s", isClient and "CLIENT" or "SERVER", _id, user, payload)
		-- end
		local b,err = xpcall(callback, debug.traceback, _id, payload, user)
		if not b then
			Ext.Utils.PrintError(err)
		end
	end
	listeners[#listeners+1] = wrapper
end

Ext.Require("SheetManager/Init.lua")
Ext.Require("CharacterSheetExtended/VisualTab.lua")

Ext.Events.SessionLoaded:Subscribe(function (e)
	local type = type
	local GetDamageBoostByType = Ext.Stats.Math.GetDamageBoostByType
	--- @param character CDivinityStatsCharacter
	--- @param damageType string See DamageType enum
	Game.Math.GetDamageBoostByType = function(character, damageType)
		if type(character) == "table" then
			local boostFunc = Game.Math.DamageBoostTable[damageType]
			if boostFunc ~= nil then
				return boostFunc(character) * 0.01
			end
		else
			local boost = GetDamageBoostByType(character, damageType)
			if boost then
				return boost * 0.01
			end
		end
		return 0
	end
end)