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

local friendsListKey = "FriendsList"
local addFriendKeys = {
  "FriendsList",
  "RecentAlliesList",
  "FriendRequestsList",
}
local filterRightInset = 10
local contactsRightInset = 2
local barInset = filterRightInset + contactsRightInset
local buttonGap = 7
local nameGap = 7
local nameBarHeight = 29
local buttonTextPadding = 40
local addFriendButton
local ignoreButton
local broadcastButton
local scrollTopGap = 5
local scrollRightInset = 23
local scrollBottomInset = 8

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

---@param contactsFrame LS_ContactsFrame
local function extendScrollBox(contactsFrame)
  local scrollBox = contactsFrame.ScrollBox
  scrollBox:ClearAllPoints()
  scrollBox:SetPoint("TOPLEFT", contactsFrame.TopDivider, "BOTTOMLEFT", 0, -scrollTopGap)
  scrollBox:SetPoint("BOTTOMRIGHT", contactsFrame, "BOTTOMRIGHT", -scrollRightInset, scrollBottomInset)
end

---@param menuButton Button
---@param methodName string
---@return boolean
local function menuOptionShown(menuButton, methodName)
  ---@type (fun(self: Button): boolean)?
  local method = menuButton[methodName]
  if type(method) ~= "function" then
    return false
  end
  if methodName == "ShouldShowBroadcastMenuOption" then
    if type(BNFeaturesEnabled) ~= "function" or type(BNConnected) ~= "function" then
      return false
    end
  end
  return not not method(menuButton)
end

---@param menuButton Button
---@param sideWindowType number
local function toggleMenuSideWindow(menuButton, sideWindowType)
  ---@type (fun(self: Button, sideWindowType: number))?
  local method = menuButton["SocialUIRequestToggleSideWindow"]
  if type(method) ~= "function" then
    return
  end
  method(menuButton, sideWindowType)
end

---@param parent Frame
---@param label string
---@param onClick fun()
---@return Button
local function createPanelButton(parent, label, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetText(label)
  local labelText = button:GetFontString()
  local textWidth = labelText and labelText:GetStringWidth() or 0
  button:SetSize(textWidth + buttonTextPadding, nameBarHeight)
  button:SetScript("OnClick", onClick)
  return button
end

---@param menuButton Button
local function hideBattleNetMenuButton(menuButton)
  ---@type (fun(self: Button))?
  local closeMenu = menuButton["CloseMenu"]
  if type(closeMenu) == "function" then
    closeMenu(menuButton)
  end
  if menuButton:IsShown() then
    menuButton:Hide()
  end
end

local function layoutAddFriendButton()
  local socialFrame = _G.SocialUIFrame
  if not socialFrame then
    return
  end
  ---@type LS_ContactsFrame?
  local friendsList = socialFrame[friendsListKey]
  if not friendsList then
    return
  end

  local controls = socialFrame.BattleNetBar.ControlsContainer
  local actionButton = friendsList.ActionButton
  actionButton:Hide()

  if not addFriendButton then
    addFriendButton = createPanelButton(controls, actionButton:GetText(), function()
      actionButton:Click()
    end)
    ---@param button Button
    local function onActionEnabled(button)
      addFriendButton:SetEnabled(button:IsEnabled())
    end
    hooksecurefunc(actionButton, "RefreshEnabledState", onActionEnabled)
  end
  addFriendButton:SetEnabled(actionButton:IsEnabled())
  addFriendButton:ClearAllPoints()
  addFriendButton:SetPoint("RIGHT", controls, "RIGHT", -barInset, 0)
  addFriendButton:Show()

  ---@type LS_SocialSideWindowType?
  local sideWindowTypes = _G.SocialUISideWindowType
  local menuButton = controls.BattleNetMenuButton
  hideBattleNetMenuButton(menuButton)

  local canToggle = type(menuButton["SocialUIRequestToggleSideWindow"]) == "function"
  local showIgnore = false
  local showBroadcast = false
  if sideWindowTypes and canToggle then
    showIgnore = menuOptionShown(menuButton, "ShouldShowIgnoreListMenuOption")
    showBroadcast = socialFrame["BattleNetBroadcastFrame"] ~= nil and menuOptionShown(menuButton, "ShouldShowBroadcastMenuOption")
  end

  if showIgnore and sideWindowTypes and not ignoreButton then
    local ignoreListFrame = sideWindowTypes.IgnoreListFrame
    ignoreButton = createPanelButton(controls, SOCIAL_UI_MENU_IGNORE_LIST_BUTTON_LABEL, function()
      toggleMenuSideWindow(menuButton, ignoreListFrame)
    end)
  end
  if ignoreButton then
    if showIgnore then
      ignoreButton:ClearAllPoints()
      ignoreButton:SetPoint("RIGHT", addFriendButton, "LEFT", -buttonGap, 0)
      ignoreButton:Show()
    else
      ignoreButton:Hide()
    end
  end

  if showBroadcast and sideWindowTypes and not broadcastButton then
    local broadcastFrame = sideWindowTypes.BattleNetBroadcastFrame
    broadcastButton = createPanelButton(controls, SOCIAL_UI_MENU_BROADCAST_BUTTON_LABEL, function()
      toggleMenuSideWindow(menuButton, broadcastFrame)
    end)
  end
  local nameNeighbor = addFriendButton
  if showIgnore and ignoreButton then
    nameNeighbor = ignoreButton
  end
  if broadcastButton then
    if showBroadcast then
      local broadcastNeighbor = addFriendButton
      if showIgnore and ignoreButton then
        broadcastNeighbor = ignoreButton
      end
      broadcastButton:ClearAllPoints()
      broadcastButton:SetPoint("RIGHT", broadcastNeighbor, "LEFT", -buttonGap, 0)
      broadcastButton:Show()
      nameNeighbor = broadcastButton
    else
      broadcastButton:Hide()
    end
  end

  controls.PersonalBattleTagDisplay:SetPoint("RIGHT", nameNeighbor, "LEFT", -nameGap, 0)
  controls.BattleNetBackground:SetPoint("RIGHT", nameNeighbor, "LEFT", -nameGap, 0)

  TableForEach(addFriendKeys, function(contentKey)
    ---@type LS_ContactsFrame?
    local contactsFrame = socialFrame[contentKey]
    if not contactsFrame then
      return
    end
    if contentKey ~= friendsListKey then
      contactsFrame.ActionButton:Hide()
    end
    extendScrollBox(contactsFrame)
  end)
end

---@param menuButton Button
---@param shown boolean
local function onMenuButtonShown(menuButton, shown)
  if shown then
    hideBattleNetMenuButton(menuButton)
  end
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
  local controls = socialFrame.BattleNetBar.ControlsContainer
  ---@param _controls Frame
  local function onControlsVisibility(_controls)
    layoutAddFriendButton()
  end
  hooksecurefunc(controls, "RefreshElementVisibility", onControlsVisibility)
  hooksecurefunc(controls.BattleNetMenuButton, "SetShown", onMenuButtonShown)
  socialFrame:HookScript("OnShow", function()
    setFrameWidth()
    hideCenteredTextures()
    layoutAddFriendButton()
  end)
  setFrameWidth()
  hideCenteredTextures()
  layoutAddFriendButton()
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
