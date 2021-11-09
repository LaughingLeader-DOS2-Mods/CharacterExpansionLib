local isClient = Ext.IsClient()

if Vars.DebugMode then
	--CustomStatSystem.DebugEnabled = true
	if not isClient then
		Ext.RegisterConsoleCommand("clearavailablepoints", function()
			---@private
			PersistentVars.CustomStatAvailablePoints = {}
			CustomStatSystem:SyncData()
		end)
	end

	local specialStats = {
		"Lucky",
		"Fear",
		"Pure",
		"RNGesus"
	}
	CustomStatSystem:RegisterAvailablePointsChangedListener("All", function(id, stat, character, previousPoints, currentPoints, isClientSide)
		--fprint(LOGLEVEL.DEFAULT, "[OnAvailablePointsChanged:%s] Stat(%s) Character(%s) %s => %s [%s]", id, stat.UUID, character.DisplayName, previousPoints, currentPoints, isClientSide and "CLIENT" or "SERVER")
	end)
	CustomStatSystem:RegisterStatValueChangedListener("All", function(id, stat, character, previousPoints, currentPoints, isClientSide)
		--fprint(LOGLEVEL.DEFAULT, "[OnStatValueChanged:%s] Stat(%s) Character(%s) %s => %s [%s]", id, stat.UUID, character.DisplayName, previousPoints, currentPoints, isClientSide and "CLIENT" or "SERVER")
	end)
	if isClient then
		CustomStatSystem:RegisterCanAddPointsHandler(specialStats, function(id, stat, character, current, availablePoints, canAdd)
			return canAdd or (availablePoints > 0 and current < 5)
		end)
		CustomStatSystem:RegisterCanRemovePointsHandler("Lucky", function(id, stat, character, current, canRemove)
			return canRemove or current > 0
		end)
		-- CustomStatSystem:RegisterCanAddPointsHandler("All", function(id, stat, character, current, availablePoints, canAdd)
		-- 	if availablePoints > 0 then
		-- 		print(id,canAdd,availablePoints,current)
		-- 		return true
		-- 	end
		-- end)
		-- CustomStatSystem:RegisterCanRemovePointsHandler("All", function(id, stat, character, current, canRemove)
		-- 	return true
		-- end)
	end
end

--CustomStatSystem.DebugEnabled = true