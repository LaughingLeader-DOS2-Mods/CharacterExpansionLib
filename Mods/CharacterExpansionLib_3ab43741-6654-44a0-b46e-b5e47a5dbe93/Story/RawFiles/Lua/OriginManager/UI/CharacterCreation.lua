---@class CharacterCreationWrapper:LeaderLibUIWrapper
local CharacterCreation = Classes.UIWrapper:CreateFromType(Data.UIType.characterCreation, {ControllerID = Data.UIType.characterCreation_c, IsControllerSupported = true})
local self = CharacterCreation

local contentParser = Ext.Require("OriginManager/UI/ContentParser.lua")
contentParser.Init(CharacterCreation)