SheetManager:RegisterVisibilityListener("Demon", function(id, entry, character, currentValue, b)
	if entry.StatType == "Talent" and entry.IsRacial then
		if character:HasTag("DEMON") then
			return true
		end
	end
	----fprint(LOGLEVEL.TRACE, "[SheetManager.Listeners.IsEntryVisible] id(%s) character(%s) value(%s) visibility(%s) [CLIENT]", id, character.DisplayName, currentValue, b)
end)

-- SheetManager.Events.OnEntryUpdating:Subscribe(function (e)
-- 	if e.EntryType == "SheetAbilityData" then
-- 		if e.ID == "Polymorph" then
-- 			e.Stat.Delta = 5
-- 		end
-- 	end
-- end)