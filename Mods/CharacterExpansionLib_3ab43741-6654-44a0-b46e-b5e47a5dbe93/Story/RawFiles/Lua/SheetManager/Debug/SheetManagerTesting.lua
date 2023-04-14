SheetManager.Events.CanChangeEntry:Subscribe(function (e)
	local talent = e.Stat --[[@as SheetTalentData]]
	if talent.IsRacial then
		if e.Character:HasTag("DEMON") then
			e.Result = true
		end
	end
end, {MatchArgs={ID="Demon", Action="Visibility"}})