local isClient = Ext.IsClient()

--Ext.Require("CharacterCreationExtended/Core/Classes/OriginSettings.lua")
--Ext.Require("CharacterCreationExtended/Core/ConfigLoader.lua")

if isClient then
	Ext.Require("CharacterCreationExtended/UI/ContentParser.lua")
end