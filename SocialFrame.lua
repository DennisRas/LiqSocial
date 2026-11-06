---@class LS_Addon
local addon = select(2, ...)

---@class LS_SocialFrame
local SocialFrame = {}
addon.SocialFrame = SocialFrame

local Constants = addon.Constants
local LiqUI = addon.libs.LiqUI
local Events = LiqUI.Events
local TableForEach = LiqUI.Utils.TableForEach

local hooked = false

local contentKeys = {
  "FriendsList",
  "RecentAlliesList",
  "QuickJoinFrame",
  "FriendRequestsList",
  "RecruitAFriendFrame",
}

local function setFrameWidth()
  local socialFrame = _G.SocialUIFrame
  if not socialFrame then
    return
  end
  local width = Constants.frameWidth
  socialFrame:SetWidth(width)
  socialFrame.BattleNetBar:SetWidth(width)
end

local function hideCenteredTextures()
  local socialFrame = _G.SocialUIFrame
  if not socialFrame then
    return
  end
  socialFrame.TopFade:Hide()
  socialFrame.BottomFade:Hide()
  socialFrame.BattleNetBar.Background:Hide()
  TableForEach(contentKeys, function(contentKey)
    ---@type LS_ContactsFrame?
    local contactsFrame = socialFrame[contentKey]
    if contactsFrame and contactsFrame.BottomDivider then
      contactsFrame.BottomDivider:Hide()
    end
  end)
end

local function attachSocialFrame()
  if hooked then
    return
  end
  local socialFrame = _G.SocialUIFrame
  if not socialFrame then
    return
  end
  hooked = true
  socialFrame:HookScript("OnShow", function()
    setFrameWidth()
    hideCenteredTextures()
  end)
  setFrameWidth()
  hideCenteredTextures()
end

---@param _frame Frame
---@param _event string
---@param addonName string
local function onSocialUILoaded(_frame, _event, addonName)
  if addonName ~= "Blizzard_SocialUI" then
    return
  end
  Events:UnregisterEvent("ADDON_LOADED", onSocialUILoaded)
  attachSocialFrame()
end

function SocialFrame:Enable()
  if C_AddOns.IsAddOnLoaded("Blizzard_SocialUI") then
    attachSocialFrame()
    return
  end
  Events:RegisterEvent("ADDON_LOADED", onSocialUILoaded, true)
end
