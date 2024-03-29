local self = SheetManager
local _ISCLIENT = Ext.IsClient()

---@diagnostic disable deprecated

---@alias OnSheetStatChangedCallback fun(id:string, stat:SheetStatData, character:EsvCharacter, lastValue:integer, value:integer, isClientSide:boolean)
---@alias OnSheetAbilityChangedCallback fun(id:string, stat:SheetAbilityData, character:EsvCharacter, lastValue:integer, value:integer, isClientSide:boolean)
---@alias OnSheetTalentChangedCallback fun(id:string, stat:SheetTalentData, character:EsvCharacter, lastValue:boolean, value:boolean, isClientSide:boolean)

---@alias OnSheetCanAddStatCallback fun(id:string, stat:SheetStatData, character:EclCharacter, currentValue:integer, canAdd:boolean):boolean
---@alias OnSheetCanAddAbilityCallback fun(id:string, stat:SheetAbilityData, character:EclCharacter, currentValue:integer, canAdd:boolean):boolean
---@alias OnSheetCanAddTalentCallback fun(id:string, stat:SheetTalentData, character:EclCharacter, currentValue:boolean, canAdd:boolean):boolean

---@alias OnSheetCanRemoveStatCallback fun(id:string, stat:SheetStatData, character:EclCharacter, currentValue:integer, canRemove:boolean):boolean
---@alias OnSheetCanRemoveAbilityCallback fun(id:string, stat:SheetAbilityData, character:EclCharacter, currentValue:integer, canRemove:boolean):boolean
---@alias OnSheetCanRemoveTalentCallback fun(id:string, stat:SheetTalentData, character:EclCharacter, currentValue:boolean, canRemove:boolean):boolean

---@alias OnSheetEntryVisibilityCallback fun(id:string, stat:SheetStatData|SheetAbilityData|SheetTalentData, character:EclCharacter, currentValue:boolean, isVisible:boolean):boolean

---@alias OnSheetEntryUpdatingCallback fun(id:string, data:SheetManager.StatsUIEntry|SheetManager.AbilitiesUIEntry|SheetManager.TalentsUIEntry, character:EclCharacter)

---@deprecated
---@param callback fun(self:SheetManager)
function SheetManager:RegisterLoadedListener(callback)
	self.Events.Loaded:Subscribe(callback)
end

---@deprecated
---Generic version for stat/ability/talent entries.
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetStatChangedCallback|OnSheetAbilityChangedCallback|OnSheetTalentChangedCallback
function SheetManager:RegisterEntryChangedListener(id, callback)
	if type(id) == "table" then
		for _,v in pairs(id) do
			SheetManager:RegisterEntryChangedListener(v, callback)
		end
	else
		---@cast id string

		if StringHelpers.Equals(id, "All", true) then
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end)
		else
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={ID=id}})
		end
	end
end

---@deprecated
---Called when a registered stat changes.
---Use this vs. RegisterEntryChangedListener for stat-related auto-completion.
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetStatChangedCallback
function SheetManager:RegisterStatChangedListener(id, callback)
	if type(id) == "table" then
		for _,v in pairs(id) do
			SheetManager:RegisterStatChangedListener(v, callback)
		end
	else
		---@cast id string

		if StringHelpers.Equals(id, "All", true) then
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={EntryType="SheetStatData"}})
		else
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={ID=id, EntryType="SheetStatData"}})
		end
	end
end

---@deprecated
---Called when a registered ability changes.
---Use this vs. RegisterEntryChangedListener for ability-related auto-completion.
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetAbilityChangedCallback
function SheetManager:RegisterAbilityChangedListener(id, callback)
	if type(id) == "table" then
		for _,v in pairs(id) do
			SheetManager:RegisterAbilityChangedListener(v, callback)
		end
	else
		---@cast id string

		if StringHelpers.Equals(id, "All", true) then
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={EntryType="SheetAbilityData"}})
		else
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={ID=id, EntryType="SheetAbilityData"}})
		end
	end
end

---@deprecated
---Called when a registered talent changes.
---Use this vs. RegisterEntryChangedListener for talent-related auto-completion.
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetTalentChangedCallback
function SheetManager:RegisterTalentChangedListener(id, callback)
	if type(id) == "table" then
		for _,v in pairs(id) do
			SheetManager:RegisterTalentChangedListener(v, callback)
		end
	else
		---@cast id string

		if StringHelpers.Equals(id, "All", true) then
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={EntryType="SheetTalentData"}})
		else
			self.Events.OnEntryChanged:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={ID=id, EntryType="SheetTalentData"}})
		end
	end
end

---@deprecated
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetCanAddStatCallback|OnSheetCanAddAbilityCallback|OnSheetCanAddStatCallback
function SheetManager:RegisterCanAddListener(id, callback)
	if type(id) == "table" then
		for _,v in pairs(id) do
			SheetManager:RegisterCanAddListener(v, callback)
		end
	else
		---@cast id string

		if StringHelpers.Equals(id, "All", true) then
			self.Events.CanChangeEntry:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={Action="Add"}})
		else
			self.Events.CanChangeEntry:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={ID=id, Action="Add"}})
		end
	end
end

---@deprecated
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetCanAddStatCallback|OnSheetCanAddAbilityCallback|OnSheetCanAddStatCallback
function SheetManager:RegisterCanRemoveListener(id, callback)
	if type(id) == "table" then
		for _,v in pairs(id) do
			SheetManager:RegisterCanRemoveListener(v, callback)
		end
	else
		---@cast id string

		if StringHelpers.Equals(id, "All", true) then
			self.Events.CanChangeEntry:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={Action="Remove"}})
		else
			self.Events.CanChangeEntry:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={ID=id, Action="Remove"}})
		end
	end
end

---@deprecated
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetEntryVisibilityCallback
function SheetManager:RegisterVisibilityListener(id, callback)
	if type(id) == "table" then
		for _,v in pairs(id) do
			SheetManager:RegisterVisibilityListener(v, callback)
		end
	else
		---@cast id string

		if StringHelpers.Equals(id, "All", true) then
			self.Events.CanChangeEntry:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={Action="Visibility"}})
		else
			self.Events.CanChangeEntry:Subscribe(function (e)
				callback(e:Unpack())
			end, {MatchArgs={ID=id, Action="Visibility"}})
		end
	end
end

---@deprecated
---@param id AnyStatEntryIDType|AnyStatEntryIDType[]
---@param callback OnSheetEntryUpdatingCallback
function SheetManager:RegisterEntryUpdatingListener(id, callback)
	if _ISCLIENT then
		if type(id) == "table" then
			for _,v in pairs(id) do
				SheetManager:RegisterEntryUpdatingListener(v, callback)
			end
		else
			---@cast id string

			if StringHelpers.Equals(id, "All", true) then
				self.Events.OnEntryUpdating:Subscribe(function (e)
					callback(e:Unpack())
				end)
			else
				self.Events.OnEntryUpdating:Subscribe(function (e)
					callback(e:Unpack())
				end, {MatchArgs={ID=id}})
			end
		end
	else
		error("SheetManager:RegisterEntryUpdatingListener is a client-side listener only.", 2)
	end
end