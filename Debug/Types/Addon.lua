---@class LS_Libs
---@field AceAddon AceAddon-3.0
---@field AceDB AceDB-3.0
---@field LiqUI LiqUI

---@class LS_Addon
---@field name string
---@field title string
---@field notes string
---@field version string
---@field libs LS_Libs
---@field Anonymize LS_Anonymize
---@field Constants LS_Constants
---@field Data LS_Data
---@field Core LS_Core

---@class LS_Anonymize
---@field AccountName fun(accountInfo: BNetAccountInfo, name: string): string
---@field CharacterName fun(accountInfo: BNetAccountInfo, name: string): string
---@field Note fun(accountInfo: BNetAccountInfo, note: string): string

---@class LS_BattleNetMenuButton : Button
---@field CloseMenu fun(self: LS_BattleNetMenuButton)?
---@field ShouldShowBroadcastMenuOption (fun(self: LS_BattleNetMenuButton): boolean)?
---@field ShouldShowIgnoreListMenuOption (fun(self: LS_BattleNetMenuButton): boolean)?
---@field SocialUIRequestToggleSideWindow fun(self: LS_BattleNetMenuButton, sideWindowType: number)?

---@class LS_ContactsFrame : Frame
---@field TopDivider Texture
---@field ScrollBox Frame
---@field ActionButton Button
---@field BottomDivider Texture
---@field IsHeaderCollapsed fun(): boolean

---@class LS_Core : AceAddon

---@class LS_FriendsWindow : Frame
---@field bnetIDAccount number?

---@class LS_SocialSideWindowType
---@field IgnoreListFrame number
---@field BattleNetBroadcastFrame number
