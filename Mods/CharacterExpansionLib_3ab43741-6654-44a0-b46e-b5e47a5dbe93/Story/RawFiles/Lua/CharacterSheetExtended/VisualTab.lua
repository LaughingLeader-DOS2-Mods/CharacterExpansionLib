local _ISCLIENT = Ext.IsClient()

local _ContentToVisualType = {
	[0] = "Hairstyle",
	[1] = "Head",
	[2] = "Torso",
	[3] = "Arms",
	[4] = "Trousers",
	[5] = "Boots",
	[6] = "Beard",
}

VisualSlot = {
	Hairstyle = 1,
	Head = 2,
	Torso = 3,
	Arms = 4,
	Trousers = 5,
	Boots = 6,
	Beard = 7,
	Extra1 = 8,
	Extra2 = 9
}

if _ISCLIENT then
	Ext.Events.SessionLoaded:Subscribe(function (_)
		if Ext.Utils.GetGameMode() ~= "GameMaster" then
			Ext.Events.UICall:Subscribe(function (e)
				if e.Function == "selectOption" and e.UI.Type == 119 and e.When == "Before" then
					local contentID, optionID, someBool = table.unpack(e.Args)
					local visualType = _ContentToVisualType[contentID]

					local player = GameHelpers.Client.GetCharacterSheetCharacter(e.UI:GetRoot())
					local visualSet = GameHelpers.Visual.GetVisualSet(player, true)
					local visualId = visualSet.Visuals[contentID+1][optionID+1]
					if visualId then
						local visual = Ext.Resource.Get("Visual", visualId)

						if visual then
							GameHelpers.Net.PostMessageToServer("CEL_Sheet_SetVisualElement", {NetID=player.NetID, Slot=VisualSlot[visualType], Element=visual.Name})
						end

						--[[ Ext.Utils.Print(Lib.serpent.dump({
							Call=string.format("selectOption(%s, %s, %s)", contentID, optionID, someBool),
							VisualSlot = {contentName, VisualSlot[contentName]},
							VisualId = visualId,
							Visual = visual.Name
						})) ]]
					end
				end
			end)
		end
	end)
else
	---@class CEL_Sheet_SetVisualElement
	---@field NetID NetId
	---@field Slot ElementManagerVisualSlot
	---@field Element FixedString

	GameHelpers.Net.Subscribe("CEL_Sheet_SetVisualElement", function (e, data)
		local player = GameHelpers.GetCharacter(data.NetID, "EsvCharacter")
		assert(player ~= nil, "Failed to get player from NetID" .. tostring(data.NetID))
		GameHelpers.Utils.UpdatePlayerCustomData(player)
		Osi.CharacterSetVisualElement(player.MyGuid, data.Slot, data.Element)
	end)
end