---@class LS_Addon
local addon = select(2, ...)

local LibAceAddon = addon.libs.AceAddon

---@class LS_Core
local Core = LibAceAddon:NewAddon(addon.name)
addon.Core = Core

local Data = addon.Data

function Core:OnInitialize()
  Data:Initialize()
end
