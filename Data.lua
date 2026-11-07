---@class LS_Addon
local addon = select(2, ...)

---@class LS_Data
local Data = {}
addon.Data = Data

local LibAceDB = addon.libs.AceDB

Data.dbVersion = 1

---@type LS_Global
local defaultGlobal = {
  dbVersion = 1,
  liqui = {
    windows = {},
    tables = {},
  },
}

---@type LS_DefaultDB
local defaultDB = {
  global = defaultGlobal,
}

Data.defaultDB = defaultDB

function Data:Initialize()
  self.db = LibAceDB:New("LiqSocialDB", self.defaultDB, true)
  self:MigrateDB()
end

---@diagnostic disable: undefined-field, inject-field
function Data:MigrateDB()
  local stored = self.db.global.dbVersion
  if stored == Data.dbVersion then
    return
  end
  self.db.global.dbVersion = Data.dbVersion
end
---@diagnostic enable: undefined-field, inject-field
