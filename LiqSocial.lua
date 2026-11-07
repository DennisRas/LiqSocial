---@class LS_Addon
local addon = select(2, ...)

local LibAceAddon = addon.libs.AceAddon
local Constants = addon.Constants
local Data = addon.Data
local LiqUI = addon.libs.LiqUI
local Events = LiqUI.Events
local TableForEach = LiqUI.Utils.TableForEach

---@class LS_Core
local Core = LibAceAddon:NewAddon(addon.name)
addon.Core = Core

local hooked = false
local friendsWindowHooked = false

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
local rowHeight = 22
local friendsListFrame
local flatteningFriends = false

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
  ---@param contentKey string
  local function hideBottomDivider(contentKey)
    ---@type LS_ContactsFrame?
    local contactsFrame = socialFrame[contentKey]
    if contactsFrame and contactsFrame.BottomDivider then
      contactsFrame.BottomDivider:Hide()
    end
  end
  TableForEach(contentKeys, hideBottomDivider)
end

---@param contactsFrame LS_ContactsFrame
local function extendScrollBox(contactsFrame)
  local scrollBox = contactsFrame.ScrollBox
  scrollBox:ClearAllPoints()
  scrollBox:SetPoint("TOPLEFT", contactsFrame.TopDivider, "BOTTOMLEFT", 0, -scrollTopGap)
  scrollBox:SetPoint("BOTTOMRIGHT", contactsFrame, "BOTTOMRIGHT", -scrollRightInset, scrollBottomInset)
end

---@param menuButton LS_BattleNetMenuButton
---@param method (fun(self: LS_BattleNetMenuButton): boolean)?
---@return boolean
local function menuOptionShown(menuButton, method)
  if type(method) ~= "function" then
    return false
  end
  return not not method(menuButton)
end

---@param menuButton LS_BattleNetMenuButton
---@param sideWindowType number
local function toggleMenuSideWindow(menuButton, sideWindowType)
  local method = menuButton.SocialUIRequestToggleSideWindow
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

---@param menuButton LS_BattleNetMenuButton
local function hideBattleNetMenuButton(menuButton)
  local closeMenu = menuButton.CloseMenu
  if type(closeMenu) == "function" then
    closeMenu(menuButton)
  end
  if menuButton:IsShown() then
    menuButton:Hide()
  end
end

---@param button Button
local function onActionEnabled(button)
  if not addFriendButton then
    return
  end
  addFriendButton:SetEnabled(button:IsEnabled())
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
    hooksecurefunc(actionButton, "RefreshEnabledState", onActionEnabled)
  end
  addFriendButton:SetEnabled(actionButton:IsEnabled())
  addFriendButton:ClearAllPoints()
  addFriendButton:SetPoint("RIGHT", controls, "RIGHT", -barInset, 0)
  addFriendButton:Show()

  ---@type LS_SocialSideWindowType?
  local sideWindowTypes = _G.SocialUISideWindowType
  ---@type LS_BattleNetMenuButton
  local menuButton = controls.BattleNetMenuButton
  hideBattleNetMenuButton(menuButton)

  local canToggle = type(menuButton.SocialUIRequestToggleSideWindow) == "function"
  local showIgnore = false
  local showBroadcast = false
  if sideWindowTypes and canToggle then
    showIgnore = menuOptionShown(menuButton, menuButton.ShouldShowIgnoreListMenuOption)
    local broadcastReady = socialFrame["BattleNetBroadcastFrame"] ~= nil and type(BNFeaturesEnabled) == "function" and type(BNConnected) == "function"
    if broadcastReady then
      showBroadcast = menuOptionShown(menuButton, menuButton.ShouldShowBroadcastMenuOption)
    end
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

  ---@param contentKey string
  local function extendContactsFrame(contentKey)
    ---@type LS_ContactsFrame?
    local contactsFrame = socialFrame[contentKey]
    if not contactsFrame then
      return
    end
    if contentKey ~= friendsListKey then
      contactsFrame.ActionButton:Hide()
    end
    extendScrollBox(contactsFrame)
  end
  TableForEach(addFriendKeys, extendContactsFrame)
end

---@param node LS_FriendNode
---@return boolean
local function isGroupNode(node)
  local data = node:GetData()
  return data.isSpacer or data.headerText ~= nil
end

---@param row LS_FriendRow
---@param selected boolean
local function setFriendRowSelected(row, selected)
  row.Selected:SetShown(selected)
end

---@return number?
local function shownFriendsWindowAccountID()
  ---@type LS_FriendsWindow?
  local friendsWindow = _G.FriendsFriendsFrame
  if not friendsWindow or not friendsWindow:IsShown() then
    return nil
  end
  local accountID = friendsWindow.bnetIDAccount
  if not accountID then
    return nil
  end
  return accountID
end

---@param node LS_FriendNode
---@return boolean
local function friendRowMatchesFriendsWindow(node)
  local accountID = shownFriendsWindowAccountID()
  if not accountID then
    return false
  end
  local accountInfo = node:GetData().accountInfo
  return accountInfo ~= nil and accountInfo.bnetAccountID == accountID
end

---@param row LS_FriendRow
local function syncVisibleFriendRow(row)
  if row.SetSelected and row.node then
    row:SetSelected(friendRowMatchesFriendsWindow(row.node))
  end
end

local function syncFriendRowSelection()
  local friendsList = friendsListFrame
  if not friendsList then
    return
  end
  local scrollBox = friendsList.ScrollBox
  ---@type (fun(self: Frame, func: fun(row: LS_FriendRow)))?
  local forEachFrame = scrollBox["ForEachFrame"]
  if type(forEachFrame) ~= "function" then
    return
  end
  forEachFrame(scrollBox, syncVisibleFriendRow)
end

local function hookFriendsWindow()
  if friendsWindowHooked then
    return
  end
  ---@type LS_FriendsWindow?
  local friendsWindow = _G.FriendsFriendsFrame
  if not friendsWindow then
    return
  end
  friendsWindowHooked = true
  hooksecurefunc(friendsWindow, "Open", syncFriendRowSelection)
  friendsWindow:HookScript("OnHide", syncFriendRowSelection)
end

---@param accountInfo BNetAccountInfo
local function openFriendMenu(accountInfo)
  local contextData = {
    battleTag = accountInfo.battleTag,
    bnetIDAccount = accountInfo.bnetAccountID,
    friendsList = true,
    name = accountInfo.accountName,
    titleColor = FriendsListUtil.GetFriendNameColorForFriendType(accountInfo),
    menuMainTitlePreInitializer = SocialUIUtil.InitializeUserScaledDropdownMainTitle,
    menuSubtitlePreInitializer = SocialUIUtil.InitializeUserScaledDropdownTitle,
    menuElementPreInitializer = SocialUIUtil.InitializeUserScaledDropdownButton,
    hasMainTitleDivider = true,
  }
  local gameAccountInfo = accountInfo.gameAccountInfo
  if gameAccountInfo and gameAccountInfo.isOnline then
    UnitPopup_OpenMenu("BN_FRIEND", contextData)
    return
  end
  UnitPopup_OpenMenu("BN_FRIEND_OFFLINE", contextData)
end

---@param row LS_FriendRow
---@param mouseButtonName string
local function onFriendRowClick(row, mouseButtonName)
  if mouseButtonName ~= "LeftButton" and mouseButtonName ~= "RightButton" then
    return
  end
  if not row.node then
    return
  end
  local accountInfo = row.node:GetData().accountInfo
  if accountInfo then
    openFriendMenu(accountInfo)
  end
end

---@param row LS_FriendRow
---@param accountInfo BNetAccountInfo
local function setCharacterName(row, accountInfo)
  local gameAccountInfo = accountInfo.gameAccountInfo
  local name = ""
  if gameAccountInfo and gameAccountInfo.characterName then
    name = FriendsListUtil.GetFormattedCharacterName(accountInfo) or ""
  end
  --@debug@
  name = addon.Anonymize.CharacterName(accountInfo, name)
  --@end-debug@
  row.CharacterName:SetText(name)
  if name == "" or not gameAccountInfo or not gameAccountInfo.isOnline then
    row.CharacterName:SetTextColor(DARKGRAY_COLOR:GetRGB())
    return
  end
  ---@type string?
  local classFilename = gameAccountInfo["classFilename"]
  if FriendsListUtil.IsPlayingWoW(gameAccountInfo) and type(classFilename) == "string" and classFilename ~= "" then
    local classColor = GetClassColorObj(classFilename)
    if classColor then
      row.CharacterName:SetTextColor(classColor:GetRGB())
      return
    end
  end
  row.CharacterName:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
end

---@param row LS_FriendRow
---@param accountInfo BNetAccountInfo
local function setLevel(row, accountInfo)
  local gameAccountInfo = accountInfo.gameAccountInfo
  local level = gameAccountInfo and gameAccountInfo.characterLevel
  if level == nil then
    row.Level:SetText("")
    return
  end
  row.Level:SetText(tostring(level))
  if gameAccountInfo and gameAccountInfo.isOnline then
    row.Level:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    return
  end
  row.Level:SetTextColor(DARKGRAY_COLOR:GetRGB())
end

---@param row LS_FriendRow
---@param accountInfo BNetAccountInfo
local function setLocation(row, accountInfo)
  local gameAccountInfo = accountInfo.gameAccountInfo
  local location = ""
  if not gameAccountInfo or not gameAccountInfo.isOnline then
    location = FriendsListUtil.GetLastOnlineText(accountInfo)
  elseif FriendsListUtil.ShouldShowRichPresenceOnly(accountInfo) then
    location = gameAccountInfo.richPresence or ""
  else
    location = gameAccountInfo.areaName or ""
  end
  row.Location:SetText(location)
  if gameAccountInfo and gameAccountInfo.isOnline then
    row.Location:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    return
  end
  row.Location:SetTextColor(DARKGRAY_COLOR:GetRGB())
end

---@param groupIcon LS_FriendRowGroupIcon
---@param gameAccountInfo BNetGameAccountInfo?
---@return string
local function partyIconAtlas(groupIcon, gameAccountInfo)
  local playerGUID = gameAccountInfo and gameAccountInfo.playerGuid
  local inGroup = playerGUID ~= nil and C_SocialQueue.IsSystemSupported() and C_SocialQueue.GetGroupForPlayer(playerGUID) ~= nil
  local enabled = groupIcon.isOnline and not groupIcon:HasInviteRestriction()
  local atlas = "friends-icon-friendsAvailable"
  if inGroup then
    atlas = "friends-icon-friendsInGroup"
  end
  if not enabled then
    atlas = atlas .. "-dis"
  end
  return atlas
end

---@param groupIcon LS_FriendRowGroupIcon
local function onGroupIconEnter(groupIcon)
  local tooltip = GetAppropriateTooltip()
  tooltip:SetOwner(groupIcon, "ANCHOR_RIGHT")
  FriendsListSocialCardPartyButtonMixin.BuildTooltip(groupIcon, tooltip)
  tooltip:Show()
end

---@param groupIcon LS_FriendRowGroupIcon
local function onGroupIconLeave(groupIcon)
  local tooltip = GetAppropriateTooltip()
  if tooltip:IsOwned(groupIcon) then
    tooltip:Hide()
  end
end

---@param row LS_FriendRow
---@param node LS_FriendNode
---@param accountInfo BNetAccountInfo?
local function setGroupIcon(row, node, accountInfo)
  local groupIcon = row.GroupIcon
  groupIcon:EnableMouseMotion(true)
  groupIcon:SetScript("OnEnter", onGroupIconEnter)
  groupIcon:SetScript("OnLeave", onGroupIconLeave)
  groupIcon.HasInviteRestriction = FriendsListSocialCardPartyButtonMixin.HasInviteRestriction
  if not accountInfo then
    groupIcon.friendIndex = nil
    groupIcon.isOnline = false
    groupIcon.inviteRestriction = nil
    groupIcon:Hide()
    return
  end
  local gameAccountInfo = accountInfo.gameAccountInfo
  groupIcon.friendIndex = node:GetData().friendIndex
  groupIcon.isOnline = gameAccountInfo ~= nil and gameAccountInfo.isOnline == true
  groupIcon.inviteRestriction = FriendsListUtil.GetBattleNetFriendPartyInviteRestriction(groupIcon.friendIndex)
  groupIcon.Icon:SetAtlas(partyIconAtlas(groupIcon, gameAccountInfo))
  groupIcon:Show()
end

---@param row LS_FriendRow
local function setFriendRowStripe(row)
  ---@type (fun(self: LS_FriendRow): number?)?
  local getElementDataIndex = row["GetElementDataIndex"]
  local showStripe = false
  if type(getElementDataIndex) == "function" then
    local dataIndex = getElementDataIndex(row)
    showStripe = dataIndex ~= nil and dataIndex % 2 == 0
  end
  row.Stripe:SetShown(showStripe)
end

---@param row LS_FriendRow
---@param node LS_FriendNode
local function showFriendRow(row, node)
  row.node = node
  row.SetSelected = setFriendRowSelected
  row:SetScript("OnClick", onFriendRowClick)
  row:SetSelected(friendRowMatchesFriendsWindow(node))
  setFriendRowStripe(row)

  local accountInfo = node:GetData().accountInfo
  if not accountInfo then
    row.AccountName:SetText("")
    row.CharacterName:SetText("")
    row.Level:SetText("")
    row.Location:SetText("")
    row.Note:SetText("")
    row.FavoriteIcon:Hide()
    row.GameIcon:Hide()
    setGroupIcon(row, node, nil)
    return
  end
  local gameAccountInfo = accountInfo.gameAccountInfo
  local isOnline = gameAccountInfo and gameAccountInfo.isOnline
  local presenceType = SocialUIUtil.GetPresenceTypeForBattleNetAccountInfo(accountInfo)
  row.PresenceIcon:SetAtlas(SocialUIUtil.GetIconForPresenceType(presenceType))

  local favoriteIcon = "friends-icon-favorites-dis"
  if isOnline then
    favoriteIcon = "friends-icon-favorites"
  end
  row.FavoriteIcon:SetAtlas(favoriteIcon)
  row.FavoriteIcon:SetShown(accountInfo.isFavorite)
  setGroupIcon(row, node, accountInfo)

  local accountName = FriendsListUtil.BuildFriendNameDisplayText(accountInfo)
  --@debug@
  accountName = addon.Anonymize.AccountName(accountInfo, accountName)
  --@end-debug@
  row.AccountName:SetText(accountName)
  setCharacterName(row, accountInfo)
  setLevel(row, accountInfo)
  setLocation(row, accountInfo)
  local note = accountInfo.note
  --@debug@
  note = addon.Anonymize.Note(accountInfo, note)
  --@end-debug@
  row.Note:SetText(note)
  row.Note:SetTextColor(NORMAL_FONT_COLOR:GetRGB())

  local clientProgram = gameAccountInfo and gameAccountInfo.clientProgram or nil
  local showGameIcon = gameAccountInfo and gameAccountInfo.isOnline and type(clientProgram) == "string" and clientProgram ~= ""
  row.GameIcon:SetShown(showGameIcon)
  if showGameIcon and clientProgram then
    C_Texture.SetTitleIconTexture(row.GameIcon, clientProgram, Enum.TitleIconVersion.Medium)
  end
end

---@param factory fun(template: string, initializer: fun(row: LS_FriendRow, node: LS_FriendNode)?)
---@param node LS_FriendNode
local function createFriendElement(factory, node)
  if isGroupNode(node) then
    factory("SocialUIScrollableSpacerTemplate")
    return
  end
  factory("LiqSocialFriendRowTemplate", showFriendRow)
end

---@param _dataIndex number
---@param node LS_FriendNode
---@return number
local function friendRowExtent(_dataIndex, node)
  if isGroupNode(node) then
    return 1
  end
  return rowHeight
end

---@param scrollBox Frame
local function flattenFriendRows(scrollBox)
  if flatteningFriends then
    return
  end
  ---@type (fun(self: Frame): TreeDataProviderMixin)?
  local getDataProvider = scrollBox["GetDataProvider"]
  if type(getDataProvider) ~= "function" then
    return
  end
  local dataProvider = getDataProvider(scrollBox)
  if not dataProvider then
    return
  end

  local hasGroup = false
  local flat = CreateTreeDataProvider()
  ---@param node LS_FriendNode
  local function copyFriendNode(node)
    local data = node:GetData()
    if data.headerText ~= nil or data.isSpacer then
      hasGroup = true
      return
    end
    if data.accountInfo then
      flat:Insert(data)
    end
  end
  dataProvider:ForEach(copyFriendNode, TreeDataProviderConstants.IncludeCollapsed)
  if not hasGroup then
    return
  end

  flatteningFriends = true
  ---@type (fun(self: Frame, dataProvider: TreeDataProviderMixin, retainScrollPosition: boolean))?
  local setDataProvider = scrollBox["SetDataProvider"]
  if type(setDataProvider) == "function" then
    setDataProvider(scrollBox, flat, ScrollBoxConstants.RetainScrollPosition)
  end
  flatteningFriends = false
end

---@return boolean
local function headersStayOpen()
  return false
end

---@param socialFrame Frame
local function useFriendRows(socialFrame)
  ---@type LS_ContactsFrame?
  local friendsList = socialFrame[friendsListKey]
  if not friendsList then
    return
  end
  friendsListFrame = friendsList
  friendsList.IsHeaderCollapsed = headersStayOpen

  local scrollBox = friendsList.ScrollBox
  ---@type (fun(self: Frame): ScrollBoxListViewMixin)?
  local getView = scrollBox["GetView"]
  if type(getView) ~= "function" then
    return
  end
  local view = getView(scrollBox)
  if not view then
    return
  end

  ---@type ScrollBoxPaddingMixin?
  local padding = view:GetPadding()
  if padding then
    padding:SetSpacing(0)
  end
  view:SetElementFactory(createFriendElement)
  ---@type (fun(self: ScrollBoxListViewMixin, calculator: fun(dataIndex: number, elementData: LS_FriendNode): number))?
  local setExtent = view["SetElementExtentCalculator"]
  if type(setExtent) == "function" then
    setExtent(view, friendRowExtent)
  end
  view:SetPanExtent(rowHeight)

  hooksecurefunc(scrollBox, "SetDataProvider", flattenFriendRows)
  flattenFriendRows(scrollBox)
  hookFriendsWindow()
end

local function showSocialFrame()
  setFrameWidth()
  hideCenteredTextures()
  layoutAddFriendButton()
end

---@param menuButton LS_BattleNetMenuButton
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
  hooksecurefunc(controls, "RefreshElementVisibility", layoutAddFriendButton)
  hooksecurefunc(controls.BattleNetMenuButton, "SetShown", onMenuButtonShown)
  socialFrame:HookScript("OnShow", showSocialFrame)
  showSocialFrame()
  useFriendRows(socialFrame)
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

local function enableSocialFrame()
  if C_AddOns.IsAddOnLoaded("Blizzard_SocialUI") then
    attachSocialFrame()
    return
  end
  Events:RegisterEvent("ADDON_LOADED", onSocialUILoaded, true)
end

function Core:OnInitialize()
  Data:Initialize()
end

function Core:OnEnable()
  enableSocialFrame()
end
