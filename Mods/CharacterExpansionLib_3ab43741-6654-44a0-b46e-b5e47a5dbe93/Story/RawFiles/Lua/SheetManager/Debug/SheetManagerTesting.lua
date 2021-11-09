--[[ SheetManager:RegisterEntryChangedListener("All", function(id, entry, character, lastValue, value, isClientSide)
	--fprint(LOGLEVEL.TRACE, "[SheetManager.Listeners.OnEntryChanged] id(%s) character(%s) lastValue(%s) value(%s) [%s]\n%s", id, character, lastValue, value, isClientSide and "CLIENT" or "SERVER", Lib.inspect(entry))
end) ]]
-- SheetManager:RegisterCanAddListener("All", function(id, entry, character, currentValue, b)
-- 	if entry.Type == "SheetStatData" and entry.StatType ~= "PrimaryStat" then
-- 		return false
-- 	end
-- 	--return true
-- end)
-- SheetManager:RegisterCanRemoveListener("All", function(id, entry, character, currentValue, b)
-- 	if entry.Type == "SheetStatData" and entry.StatType ~= "PrimaryStat" then
-- 		return false
-- 	end
-- 	return true
-- end)
SheetManager:RegisterVisibilityListener("Demon", function(id, entry, character, currentValue, b)
	if entry.StatType == "Talent" and entry.IsRacial then
		if character:HasTag("DEMON") then
			return true
		end
	end
	----fprint(LOGLEVEL.TRACE, "[SheetManager.Listeners.IsEntryVisible] id(%s) character(%s) value(%s) visibility(%s) [CLIENT]", id, character.DisplayName, currentValue, b)
end)