SheetManager:RegisterVisibilityListener("Demon", function(id, entry, character, currentValue, b)
	if entry.StatType == "Talent" and entry.IsRacial then
		if character:HasTag("DEMON") then
			return true
		end
	end
	----fprint(LOGLEVEL.TRACE, "[SheetManager.Listeners.IsEntryVisible] id(%s) character(%s) value(%s) visibility(%s) [CLIENT]", id, character.DisplayName, currentValue, b)
end)