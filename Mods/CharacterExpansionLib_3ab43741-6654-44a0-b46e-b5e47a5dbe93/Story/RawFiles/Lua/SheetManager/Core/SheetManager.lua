if SheetManager == nil then
	---@class SheetManager
	SheetManager = {}
end

---@alias SHEET_ENTRY_ID string

SheetManager.__index = SheetManager
SheetManager.Loaded = false

---@alias SheetEntryType string|'"PrimaryStat"'|'"SecondaryStat"'|'"Ability"'|'"CivilAbility"'|'"Talent"'|'"Custom"'

---@class SheetStatType
SheetManager.StatType = {
	---@type SheetEntryType
	PrimaryStat = "PrimaryStat",
	---@type SheetEntryType
	SecondaryStat = "SecondaryStat",
	---@type SheetEntryType
	Ability = "Ability",
	---@type SheetEntryType
	Talent = "Talent",
	---@type SheetEntryType
	Custom = "Custom"
}

local isClient = Ext.IsClient()

Ext.Require("SheetManager/Core/Data/SheetDataValues.lua")
Ext.Require("SheetManager/Core/DataSync.lua")
Ext.Require("SheetManager/Core/Getters.lua")
Ext.Require("SheetManager/Core/Setters.lua")
Ext.Require("SheetManager/Core/Listeners.lua")

SheetManager.Data = {
	---@type table<MOD_UUID, table<SHEET_ENTRY_ID, SheetAbilityData>>
	Abilities = {},
	---@type table<MOD_UUID, table<SHEET_ENTRY_ID, SheetTalentData>>
	Talents = {},
	---@type table<MOD_UUID, table<SHEET_ENTRY_ID, SheetStatData>>
	Stats = {},
	ID_MAP = {
		Abilities = {
			NEXT_ID = 1999,
			---@type table<integer, SheetAbilityData>
			Entries = {}
		},
		---@type table<integer, SheetTalentData>
		Talents = {
			NEXT_ID = 1999,
			Entries = {}
		},
		---@type table<integer, SheetTalentData>
		Stats = {
			NEXT_ID = 1999,
			Entries = {}
		},
	}
}

---@type fun():table<string, table<string, SheetAbilityData|SheetTalentData|SheetStatData>>
local loader = Ext.Require("SheetManager/Core/ConfigLoader.lua")

local function LoadData()
	if Vars.DebugMode then
		Vars.LeaderDebugMode = Ext.LoadFile("LeaderDebug") ~= nil
	end
	
	local b,data = xpcall(loader, debug.traceback)
	if b and data then
		for uuid,entryData in pairs(data) do

			if not SheetManager.Data.Abilities[uuid] then
				SheetManager.Data.Abilities[uuid] = entryData.Abilities or {}
			elseif entryData.Abilities then
				TableHelpers.AddOrUpdate(SheetManager.Data.Abilities[uuid], entryData.Abilities)
			end

			if not SheetManager.Data.Talents[uuid] then
				SheetManager.Data.Talents[uuid] = entryData.Talents or {}
			elseif entryData.Talents then
				TableHelpers.AddOrUpdate(SheetManager.Data.Talents[uuid], entryData.Talents)
			end

			if not SheetManager.Data.Stats[uuid] then
				SheetManager.Data.Stats[uuid] = entryData.Stats or {}
			elseif entryData.Stats then
				TableHelpers.AddOrUpdate(SheetManager.Data.Stats[uuid], entryData.Stats)
			end
		end
		
	else
		Ext.PrintError(data)
	end

	SheetManager.Talents.LoadRequirements()

	--SheetManager.Talents.HideTalent("LoneWolf", ModuleUUID)

	SheetManager.Loaded = true
	InvokeListenerCallbacks(SheetManager.Listeners.Loaded, SheetManager)

	if isClient then
		---Divine Talents
		if Ext.IsModLoaded("ca32a698-d63e-4d20-92a7-dd83cba7bc56") or GameSettings.Settings.Client.DivineTalentsEnabled then
			SheetManager.Talents.ToggleDivineTalents(true)
		end
	else
		SheetManager:SyncData()
	end
end

if not isClient then
	RegisterListener("Initialized", LoadData)
else
	Ext.RegisterListener("SessionLoaded", LoadData)
	--Ext.Require("SheetManager/Core/UI/_Init.lua")
end

if isClient then
	if SheetManager.UI == nil then
		SheetManager.UI = {}
	end
else
	Ext.RegisterNetListener("CEL_SheetManager_RequestValueChange", function(cmd, payload)
		local data = Common.JsonParse(payload)
		if data then
			local characterId = GameHelpers.GetCharacterID(data.NetID)
			local stat = SheetManager:GetEntryByID(data.ID, data.Mod, data.StatType)
			if characterId and stat then
				if data.IsGameMaster or not stat.UsePoints then
					SheetManager:SetEntryValue(stat, characterId, data.Value)
				else
					local modifyPointsBy = 0
					if stat.ValueType == "number" then
						modifyPointsBy = stat:GetValue(characterId) - data.Value
					elseif stat.ValueType == "boolean" then
						modifyPointsBy = stat:GetValue(characterId) ~= true and - 1 or 1
					end
					if modifyPointsBy ~= 0 then
						if modifyPointsBy < 0 then
							local points = SheetManager:GetBuiltinAvailablePointsForEntry(stat, characterId)
							if points > 0 and SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy) then
								SheetManager:SetEntryValue(stat, characterId, data.Value)
							end
						else
							if SheetManager:ModifyAvailablePointsForEntry(stat, characterId, modifyPointsBy) then
								SheetManager:SetEntryValue(stat, characterId, data.Value)
							end
						end
					end
				end
			end
		end
	end)

	--Query support

	local function Query_GetAttribute(uuid, id, val, boostCheck, statType)
		local stat = SheetManager:GetEntryByID(id, nil, statType or "PrimaryStat")
		if stat and (boostCheck ~= true or stat.BoostAttribute) then
			return stat:GetValue(StringHelpers.GetUUID(uuid))
		end
	end
	Ext.RegisterOsirisListener("CharacterGetAttribute", 3, "after", Query_GetAttribute)
	Ext.RegisterOsirisListener("CharacterGetBaseAttribute", 3, "after", Query_GetAttribute)
	Ext.RegisterOsirisListener("NRD_ItemGetPermanentBoostInt", 3, "after", function(uuid,id,val) 
		return Query_GetAttribute(uuid,id,val,true,"Stat")
	end)

	local function Query_GetAbility(uuid, id, value, boostCheck)
		local stat = SheetManager:GetEntryByID(id, nil, "Ability")
		if stat and (boostCheck ~= true or stat.BoostAttribute) then
			return stat:GetValue(StringHelpers.GetUUID(uuid))
		end
	end
	Ext.RegisterOsirisListener("CharacterGetAbility", 3, "after", Query_GetAbility)
	Ext.RegisterOsirisListener("CharacterGetBaseAbility", 3, "after", Query_GetAbility)
	Ext.RegisterOsirisListener("NRD_ItemGetPermanentBoostAbility", 3, "after", function(uuid,id,bool) 
		return Query_GetAbility(uuid,id,bool,true) 
	end)

	local function Query_HasTalent(uuid, id, bool, boostCheck)
		if bool ~= 1 then
			local stat = SheetManager:GetEntryByID(id, nil, "Talent")
			if stat and (boostCheck ~= true or stat.BoostAttribute) then
				return stat:GetValue(StringHelpers.GetUUID(uuid))
			end
		end
	end
	Ext.RegisterOsirisListener("CharacterHasTalent", 3, "after", Query_HasTalent)
	Ext.RegisterOsirisListener("NRD_ItemGetPermanentBoostTalent", 3, "after", function(uuid,id,bool) 
		return Query_HasTalent(uuid,id,bool,true) 
	end)
end

--print(CharacterGetAbility(Osi.DB_IsPlayer:Get(nil)[1][1], "Test1"))
--print(CharacterGetAbility("41a06985-7851-4c29-8a78-398ccb313f39", "Test1"))