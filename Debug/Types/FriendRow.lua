---@class LS_FriendNode
---@field GetData fun(self: LS_FriendNode): LS_FriendNodeData

---@class LS_FriendNodeData
---@field isSpacer boolean?
---@field headerText string?
---@field friendIndex number?
---@field accountInfo BNetAccountInfo?

---@class LS_FriendRow : Button
---@field Stripe Texture
---@field Selected Texture
---@field PresenceIcon Texture
---@field AccountName FontString
---@field Level FontString
---@field CharacterName FontString
---@field Location FontString
---@field Note FontString
---@field FavoriteIcon Texture
---@field GroupIcon LS_FriendRowGroupIcon
---@field GameIcon Texture
---@field node LS_FriendNode
---@field SetSelected fun(self: LS_FriendRow, selected: boolean)

---@class LS_FriendRowGroupIcon : Frame
---@field Icon Texture
---@field friendIndex number?
---@field isOnline boolean
---@field inviteRestriction number?
---@field HasInviteRestriction fun(self: LS_FriendRowGroupIcon): boolean
