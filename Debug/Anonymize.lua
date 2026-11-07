---@class LS_Addon
local addon = select(2, ...)

---@class LS_Anonymize
local Anonymize = {}
addon.Anonymize = Anonymize

local HIDE_REAL_INFO = true

local accountNames = {
  "Bluebell",
  "Copperline",
  "Mistvale",
  "Thornwick",
  "Ashford",
  "Bramble",
  "Goldpetal",
  "Riverock",
  "Stonequill",
  "Fernwhistle",
  "Amberlane",
  "Mossglen",
  "Hartwick",
  "Pebbleton",
  "Cinderwell",
  "Larkspur",
}
local characterNames = {
  "Aldric Hale",
  "Mira Stone",
  "Cedric Vale",
  "Elowen Marsh",
  "Rowan Pike",
  "Tamsin Greer",
  "Harlan Crowe",
  "Isolde Fenn",
  "Bram Calder",
  "Nessa Wilde",
  "Corin Ash",
  "Liora Penn",
  "Edric Moss",
  "Sylvie Hart",
  "Galen Brook",
  "Maren Holt",
}
local notes = {
  "Met in the city.",
  "Dungeon group.",
  "From the guild.",
  "Raid night.",
  "Leveling together.",
}

---@param accountInfo BNetAccountInfo
---@param names string[]
---@return string
local function anonymizeName(accountInfo, names)
  local index = (accountInfo.bnetAccountID % #names) + 1
  return names[index]
end

---@param accountInfo BNetAccountInfo
---@param name string
---@return string
function Anonymize.AccountName(accountInfo, name)
  if not HIDE_REAL_INFO or name == "" then
    return name
  end
  return FriendsListUtil.GetFriendNameDisplayColor(accountInfo):WrapTextInColorCode(anonymizeName(accountInfo, accountNames))
end

---@param accountInfo BNetAccountInfo
---@param name string
---@return string
function Anonymize.CharacterName(accountInfo, name)
  if not HIDE_REAL_INFO or name == "" then
    return name
  end
  return anonymizeName(accountInfo, characterNames)
end

---@param accountInfo BNetAccountInfo
---@param note string
---@return string
function Anonymize.Note(accountInfo, note)
  if not HIDE_REAL_INFO or note == "" then
    return note
  end
  return anonymizeName(accountInfo, notes)
end
