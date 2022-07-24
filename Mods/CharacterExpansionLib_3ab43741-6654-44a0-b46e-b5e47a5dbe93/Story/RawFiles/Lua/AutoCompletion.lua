--This file is never actually loaded, and is used to make EmmyLua work better.

--For auto-completion
if Mods == nil then Mods = {} end
if Mods.CharacterExpansionLib == nil then Mods.CharacterExpansionLib = {} end

---@alias AnyStatEntryIDType string|integer