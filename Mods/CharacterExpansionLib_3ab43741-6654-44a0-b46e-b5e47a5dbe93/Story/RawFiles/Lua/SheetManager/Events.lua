local _ISCLIENT = Ext.IsClient()

local _EVENTS = {}

SheetManager.Events = _EVENTS

---Called when the SheetManager is fully loaded.   
---🔨🔧**Server/Client**🔧🔨  
---@type LeaderLibSubscribableEvent<EmptyEventArgs>
_EVENTS.Loaded = Classes.SubscribableEvent:Create("SheetManager.Loaded")

---@class SheetManagerOnEntryChangedBaseEventArgs
---@field ID string
---@field Character EsvCharacter|EclCharacter
---@field IsClient boolean

---@class SheetManagerOnEntryChangedStatEventArgs:SheetManagerOnEntryChangedBaseEventArgs
---@field EntryType "SheetStatData"
---@field Stat SheetStatData
---@field LastValue integer
---@field Value integer

---@class SheetManagerOnEntryChangedAbilityEventArgs:SheetManagerOnEntryChangedBaseEventArgs
---@field EntryType "SheetAbilityData"
---@field Stat SheetAbilityData
---@field LastValue integer
---@field Value integer

---@class SheetManagerOnEntryChangedTalentEventArgs:SheetManagerOnEntryChangedBaseEventArgs
---@field EntryType "SheetTalentData"
---@field Stat SheetTalentData
---@field LastValue boolean
---@field Value boolean

---@class SheetManagerOnEntryChangedCustomStatEventArgs:SheetManagerOnEntryChangedBaseEventArgs
---@field EntryType "SheetCustomStatData"
---@field Stat SheetCustomStatData
---@field LastValue number
---@field Value number

---@alias SheetManagerOnEntryChangedAnyTypeEventArgs SheetManagerOnEntryChangedStatEventArgs|SheetManagerOnEntryChangedAbilityEventArgs|SheetManagerOnEntryChangedTalentEventArgs|SheetManagerOnEntryChangedCustomStatEventArgs

---Called when a SheetManager entry's value changes.  
---🔨🔧**Server/Client**🔧🔨  
---@type LeaderLibSubscribableEvent<SheetManagerOnEntryChangedAnyTypeEventArgs>
_EVENTS.OnEntryChanged = Classes.SubscribableEvent:Create("SheetManager.OnEntryChanged", {
	ArgsKeyOrder = {"ID", "Stat", "Character", "LastValue", "Value", "IsClient"}
})

if _ISCLIENT then
	---@class SheetManagerCanChangeEntryBaseEventArgs
	---@field ID string
	---@field Character EclCharacter
	---@field Action "Add"|"Remove"|"Visibility"
	---@field Result boolean

	---@class SheetManagerCanChangeEntryStatEventArgs:SheetManagerCanChangeEntryBaseEventArgs
	---@field EntryType "SheetStatData"
	---@field Stat SheetStatData
	---@field Value integer

	---@class SheetManagerCanChangeEntryAbilityEventArgs:SheetManagerCanChangeEntryBaseEventArgs
	---@field EntryType "SheetAbilityData"
	---@field Stat SheetAbilityData
	---@field Value integer

	---@class SheetManagerCanChangeEntryTalentEventArgs:SheetManagerCanChangeEntryBaseEventArgs
	---@field EntryType "SheetTalentData"
	---@field Stat SheetTalentData
	---@field Value boolean

	---@class SheetManagerCanChangeEntryCustomStatEventArgs:SheetManagerCanChangeEntryBaseEventArgs
	---@field EntryType "SheetCustomStatData"
	---@field Stat SheetCustomStatData
	---@field Value number

	---@alias SheetManagerCanChangeEntryAnyTypeEventArgs SheetManagerCanChangeEntryStatEventArgs|SheetManagerCanChangeEntryAbilityEventArgs|SheetManagerCanChangeEntryTalentEventArgs|SheetManagerCanChangeEntryCustomStatEventArgs

	---Called when the UI checks if a stat can be added to. 
	---🔧**Client-Only**🔧  
	---@type LeaderLibSubscribableEvent<SheetManagerCanChangeEntryAnyTypeEventArgs>
	_EVENTS.CanChangeEntry = Classes.SubscribableEvent:Create("SheetManager.CanChangeEntry", {
		ArgsKeyOrder = {"ID", "Stat", "Character", "Value", "Result"}
	})

	---@class SheetManagerOnEntryUpdatingBaseEventArgs
	---@field ID string
	---@field Character EclCharacter

	---@class SheetManagerOnEntryUpdatingStatEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetStatData"
	---@field Stat SheetManager.StatsUIEntry

	---@class SheetManagerOnEntryUpdatingAbilityEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetAbilityData"
	---@field Stat SheetManager.AbilitiesUIEntry

	---@class SheetManagerOnEntryUpdatingTalentEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetTalentData"
	---@field Stat SheetManager.TalentsUIEntry

	---@class SheetManagerOnEntryUpdatingCustomStatEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetCustomStatData"
	---@field Stat SheetManager.CustomStatsUIEntry

	---@alias SheetManagerOnEntryUpdatingAnyTypeEventArgs SheetManagerOnEntryUpdatingStatEventArgs|SheetManagerOnEntryUpdatingAbilityEventArgs|SheetManagerOnEntryUpdatingTalentEventArgs|SheetManagerOnEntryUpdatingCustomStatEventArgs

	---Called when a visible sheet entry is about to be added to the UI.  
	---🔧**Client-Only**🔧  
	---@type LeaderLibSubscribableEvent<SheetManagerOnEntryUpdatingAnyTypeEventArgs>
	_EVENTS.OnEntryUpdating = Classes.SubscribableEvent:Create("SheetManager.OnEntryUpdating", {
		ArgsKeyOrder = {"ID", "Stat", "Character"}
	})
end

