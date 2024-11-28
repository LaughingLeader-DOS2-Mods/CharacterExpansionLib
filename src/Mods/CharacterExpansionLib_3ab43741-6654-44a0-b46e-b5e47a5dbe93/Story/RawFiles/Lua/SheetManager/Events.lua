local _ISCLIENT = Ext.IsClient()

local _EVENTS = {}

SheetManager.Events = _EVENTS

---Called when the SheetManager is fully loaded.   
---🔨🔧**Server/Client**🔧🔨  
---@type LeaderLibSubscribableEvent<EmptyEventArgs>
_EVENTS.Loaded = Classes.SubscribableEvent:Create("SheetManager.Loaded")

---@class SheetManagerOnEntryChangedBaseEventArgs
---@field ModuleUUID Guid The related mod Guid.
---@field ID string
---@field Character EsvCharacter|EclCharacter
---@field CharacterID Guid|NetId Guid on the server-side, NetId on the client-side.
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

---@class SheetManagerOnAvailablePointsChangedEventArgs
---@field ModuleUUID Guid The related mod Guid.
---@field EntryType SheetEntryDataType
---@field ID string
---@field Stat AnyStatEntryDataType
---@field Character EclCharacter
---@field CharacterID NetId
---@field LastValue integer
---@field Value integer

---Called available points change.  
---🔨🔧**Server/Client**🔧🔨   
---@type LeaderLibSubscribableEvent<SheetManagerOnAvailablePointsChangedEventArgs>
_EVENTS.OnAvailablePointsChanged = Classes.SubscribableEvent:Create("SheetManager.OnAvailablePointsChanged", {
	ArgsKeyOrder = {"ID", "Stat", "Character", "LastValue", "Value"}
})

if _ISCLIENT then
	---@class SheetManagerCanChangeEntryBaseEventArgs
	---@field ModuleUUID Guid The related mod Guid.
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
	---@field ModuleUUID Guid The mod Guid.
	---@field ID string
	---@field Character EclCharacter
	---@field CharacterID NetId

	---@class SheetManagerOnEntryUpdatingStatEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetStatData"
	---@field Stat SheetManager.StatsUIEntry

	---@class SheetManagerOnEntryUpdatingAbilityEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetAbilityData"
	---@field Stat SheetManager.AbilitiesUIEntry

	---@class SheetManagerOnEntryUpdatingAbilityCategoryEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetAbilityCategoryData"
	---@field Stat SheetManager.AbilityCategoryUIEntry

	---@class SheetManagerOnEntryUpdatingTalentEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetTalentData"
	---@field Stat SheetManager.TalentsUIEntry

	---@class SheetManagerOnEntryUpdatingCustomStatEventArgs:SheetManagerOnEntryUpdatingBaseEventArgs
	---@field EntryType "SheetCustomStatData"
	---@field Stat SheetManager.CustomStatsUIEntry

	---@alias SheetManagerOnEntryUpdatingAnyTypeEventArgs SheetManagerOnEntryUpdatingStatEventArgs|SheetManagerOnEntryUpdatingAbilityEventArgs|SheetManagerOnEntryUpdatingTalentEventArgs|SheetManagerOnEntryUpdatingCustomStatEventArgs|SheetManagerOnEntryUpdatingAbilityCategoryEventArgs

	---Called when a visible sheet entry is about to be added to the UI.  
	---🔧**Client-Only**🔧  
	---@type LeaderLibSubscribableEvent<SheetManagerOnEntryUpdatingAnyTypeEventArgs>
	_EVENTS.OnEntryUpdating = Classes.SubscribableEvent:Create("SheetManager.OnEntryUpdating", {
		ArgsKeyOrder = {"ID", "Stat", "Character"}
	})

	---@class SheetManagerOnEntryAddedToUIEventArgs
	---@field ModuleUUID Guid The mod Guid.
	---@field EntryType SheetEntryDataType
	---@field ID string
	---@field Stat AnyStatEntryDataType
	---@field Character EclCharacter
	---@field CharacterID NetId
	---@field MovieClip FlashMovieClip
	---@field UI UIObject
	---@field Root FlashMainTimeline
	---@field UIType integer

	---Called when a visible sheet entry is added to the UI.  
	---🔧**Client-Only**🔧  
	---@type LeaderLibSubscribableEvent<SheetManagerOnEntryAddedToUIEventArgs>
	_EVENTS.OnEntryAddedToUI = Classes.SubscribableEvent:Create("SheetManager.OnEntryAddedToUI", {
		ArgsKeyOrder = {"ID", "Stat", "Character", "MovieClip"}
	})
end

---@class SheetManagerCanUnlockTalentEventArgs
---@field Character EclCharacter|EsvCharacter
---@field CharacterID Guid|NetId Guid on the server-side, NetId on the client-side.
---@field EntryType "SheetTalentData"
---@field ID string
---@field Talent SheetTalentData
---@field CanUnlock boolean

---Called when checking if a talent can be unlocked. 
---This is called after the talent's requirements are checked.  
---🔨🔧**Server/Client**🔧🔨   
---@type LeaderLibSubscribableEvent<SheetManagerCanUnlockTalentEventArgs>
_EVENTS.CanUnlockTalent = Classes.SubscribableEvent:Create("SheetManager.CanUnlockTalent")