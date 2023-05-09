if SheetManager == nil then
	---@class SheetManager
	SheetManager = {}
end

SheetManager.__index = SheetManager
SheetManager.Loaded = false

---@enum SheetStatType
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
	Custom = "Custom",
	---@type SheetEntryType
	CustomCategory = "CustomCategory",
	---@type SheetEntryType
	AbilityCategory = "AbilityCategory",
}

local _ISCLIENT = Ext.IsClient()

Ext.Require("SheetManager/Events.lua")
Ext.Require("SheetManager/Core/DeprecatedListeners.lua")
Ext.Require("SheetManager/Core/Data/SheetDataValues.lua")
Ext.Require("SheetManager/Core/Sync/Main.lua")
Ext.Require("SheetManager/Core/Sync/AvailablePoints.lua")
Ext.Require("SheetManager/Core/Sync/CharacterCreation.lua")
Ext.Require("SheetManager/Core/Sync/EntryValues.lua")
Ext.Require("SheetManager/Core/Sync/SyncEvents.lua")
Ext.Require("SheetManager/Core/Getters.lua")
Ext.Require("SheetManager/Core/Setters.lua")

SheetManager.Data = {
	---@type table<ModGuid, table<SheetEntryId, SheetAbilityData>>
	Abilities = {},
	---@type table<ModGuid, table<SheetEntryId, SheetAbilityCategoryData>>
	AbilityCategories = {},
	---@type table<ModGuid, table<SheetEntryId, SheetTalentData>>
	Talents = {},
	---@type table<ModGuid, table<SheetEntryId, SheetStatData>>
	Stats = {},
	---@type table<ModGuid, table<SheetEntryId, SheetCustomStatData>>
	CustomStats = {},
	---@type table<ModGuid, table<SheetEntryId, SheetCustomStatCategoryData>>
	CustomStatCategories = {},
	ID_MAP = {
		Abilities = {
			NEXT_ID = 7999,
			---@type table<integer, SheetAbilityData>
			Entries = {}
		},
		AbilityCategories = {
			NEXT_ID = 6,
			---@type table<integer, SheetAbilityCategoryData>
			Entries = {}
		},
		Talents = {
			NEXT_ID = 4999,
			---@type table<integer, SheetTalentData>
			Entries = {}
		},
		Stats = {
			NEXT_ID = 1999,
			---@type table<integer, SheetStatData>
			Entries = {}
		},
		CustomStats = {
			NEXT_ID = -1,
			---@type table<integer, SheetCustomStatData>
			Entries = {}
		},
		CustomStatCategories = {
			NEXT_ID = -1,
			---@type table<integer, SheetCustomStatCategoryData>
			Entries = {}
		},
	}
}

---@type fun():table<string, table<string, SheetAbilityData|SheetTalentData|SheetStatData>>
local _Loader = Ext.Require("SheetManager/Core/ConfigLoader.lua")

local function LoadData()
	local b,data = xpcall(_Loader, debug.traceback)
	if b and data then
		for modId,entryData in pairs(data) do
			if not SheetManager.Data.Abilities[modId] then
				SheetManager.Data.Abilities[modId] = entryData.Abilities or {}
			elseif entryData.Abilities then
				TableHelpers.AddOrUpdate(SheetManager.Data.Abilities[modId], entryData.Abilities)
			end

			if not SheetManager.Data.AbilityCategories[modId] then
				SheetManager.Data.AbilityCategories[modId] = entryData.AbilityCategories or {}
			elseif entryData.AbilityCategories then
				TableHelpers.AddOrUpdate(SheetManager.Data.AbilityCategories[modId], entryData.AbilityCategories)
			end

			if not SheetManager.Data.Talents[modId] then
				SheetManager.Data.Talents[modId] = entryData.Talents or {}
			elseif entryData.Talents then
				TableHelpers.AddOrUpdate(SheetManager.Data.Talents[modId], entryData.Talents)
			end

			if not SheetManager.Data.Stats[modId] then
				SheetManager.Data.Stats[modId] = entryData.Stats or {}
			elseif entryData.Stats then
				TableHelpers.AddOrUpdate(SheetManager.Data.Stats[modId], entryData.Stats)
			end

			if not SheetManager.Data.CustomStats[modId] then
				SheetManager.Data.CustomStats[modId] = entryData.CustomStats or {}
			elseif entryData.Stats then
				TableHelpers.AddOrUpdate(SheetManager.Data.CustomStats[modId], entryData.CustomStats)
			end

			if not SheetManager.Data.CustomStatCategories[modId] then
				SheetManager.Data.CustomStatCategories[modId] = entryData.CustomStatCategories or {}
			elseif entryData.Stats then
				TableHelpers.AddOrUpdate(SheetManager.Data.CustomStatCategories[modId], entryData.CustomStatCategories)
			end
		end
	else
		Ext.Utils.PrintError(data)
	end

	--Set abilities using custom categories to use the generated ID
	for modId,entries in pairs(SheetManager.Data.Abilities) do
		for id,entry in pairs(entries) do
			if not StringHelpers.IsNullOrEmpty(entry.CustomGroup) then
				local category = SheetManager:GetEntryByID(entry.CustomGroup, entry.GroupMod, "AbilityCategory")
				if category then
					entry.GroupID = category.GeneratedID
				end
			end
		end
	end

	if not _ISCLIENT then
		for uuid,entry in pairs(PersistentVars.CharacterSheetValues) do
			local characterCount = 0
			for statType,modTable in pairs(entry) do
				local statTypeCount = 0
				for modId,entries in pairs(modTable) do
					local entryCount = 0
					for entryID,value in pairs(entries) do
						entryCount = entryCount + 1
						local entry = SheetManager:GetEntryByID(entryID, modId, statType)
						if entry then
							--This entry uses boost values, so it doesn't need to be saved in PersistentVars
							if not StringHelpers.IsNullOrWhitespace(entry.BoostAttribute) then
								fprint(LOGLEVEL.ERROR, "[SheetManager] Deleted a value (%s) in PersistentVars for an entry (%s) that uses a BoostAttribute (%s).", value, entryID, entry.BoostAttribute)
								PersistentVars.CharacterSheetValues[uuid][statType][modId][entryID] = nil
								entryCount = entryCount - 1
							end
						else
							fprint(LOGLEVEL.ERROR, "[SheetManager] Failed to find entry for %s (%s) - %s", entryID, statType, modId)
						end
					end
					if entryCount <= 0 then
						PersistentVars.CharacterSheetValues[uuid][statType][modId] = nil
					else
						statTypeCount = statTypeCount + entryCount
					end
				end
				if statTypeCount <= 0 then
					PersistentVars.CharacterSheetValues[uuid][statType] = nil
				else
					characterCount = characterCount + 1
				end
			end
			if characterCount <= 0 then
				PersistentVars.CharacterSheetValues[uuid] = nil
			end
		end
	end

	SheetManager.Talents.Builtin.LoadRequirements()

	if not _ISCLIENT then
		--SheetManager.CustomStats.LoadUnregistered()
	end

	SheetManager.CustomStats._Internal.Initialize()

	SheetManager.Loaded = true
	SheetManager.Events.Loaded:Invoke({})

	if _ISCLIENT then
		---Divine Talents
		if Ext.Mod.IsModLoaded("ca32a698-d63e-4d20-92a7-dd83cba7bc56") then
			SheetManager.Talents.Builtin.ToggleDivineTalents(true, "ca32a698-d63e-4d20-92a7-dd83cba7bc56")
		elseif Mods.LeaderLib then
			local gameSettings = GameSettingsManager.GetSettings()
			if gameSettings.Client.DivineTalentsEnabled then
				SheetManager.Talents.Builtin.ToggleDivineTalents(true, Mods.LeaderLib.ModuleUUID)
			end
		end
	else
		SheetManager:SyncData()
	end
end

Events.RegionChanged:Subscribe(function(e)
	if not SheetManager.Loaded then
		LoadData()
	end
end)

if _ISCLIENT then
	if SheetManager.UI == nil then
		SheetManager.UI = {}
	end
else
	--Query support

	local function Query_GetAttribute(uuid, id, val, boostCheck, statType)
		local character = GameHelpers.GetCharacter(uuid, "EsvCharacter")
		if character then
			local stat = SheetManager:GetEntryByID(id, nil, statType or "PrimaryStat")
			if stat and (boostCheck ~= true or stat.BoostAttribute) then
				return stat:GetValue(character)
			end
		end
	end
	Ext.Osiris.RegisterListener("CharacterGetAttribute", 3, "after", Query_GetAttribute)
	Ext.Osiris.RegisterListener("CharacterGetBaseAttribute", 3, "after", Query_GetAttribute)
	Ext.Osiris.RegisterListener("NRD_ItemGetPermanentBoostInt", 3, "after", function(uuid,id,val)
		return Query_GetAttribute(uuid,id,val,true,"Stat")
	end)

	local function Query_GetAbility(uuid, id, value, boostCheck)
		local character = GameHelpers.GetCharacter(uuid, "EsvCharacter")
		if character then
			local stat = SheetManager:GetEntryByID(id, nil, "Ability")
			if stat and (boostCheck ~= true or stat.BoostAttribute) then
				return stat:GetValue(character)
			end
		end
	end
	Ext.Osiris.RegisterListener("CharacterGetAbility", 3, "after", Query_GetAbility)
	Ext.Osiris.RegisterListener("CharacterGetBaseAbility", 3, "after", Query_GetAbility)
	Ext.Osiris.RegisterListener("NRD_ItemGetPermanentBoostAbility", 3, "after", function(uuid,id,bool) 
		return Query_GetAbility(uuid,id,bool,true) 
	end)

	local function Query_HasTalent(uuid, id, bool, boostCheck)
		local character = GameHelpers.GetCharacter(uuid, "EsvCharacter")
		if character then
			if bool ~= 1 then
				local stat = SheetManager:GetEntryByID(id, nil, "Talent")
				if stat and (boostCheck ~= true or stat.BoostAttribute) then
					return stat:GetValue(character)
				end
			end
		end
	end
	Ext.Osiris.RegisterListener("CharacterHasTalent", 3, "after", Query_HasTalent)
	Ext.Osiris.RegisterListener("NRD_ItemGetPermanentBoostTalent", 3, "after", function(uuid,id,bool) 
		return Query_HasTalent(uuid,id,bool,true) 
	end)
end

--print(CharacterGetAbility(Osi.DB_IsPlayer:Get(nil)[1][1], "Test1"))
--print(CharacterGetAbility("41a06985-7851-4c29-8a78-398ccb313f39", "Test1"))