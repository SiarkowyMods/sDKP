--------------------------------------------------------------------------------
--  sDKP (c) 2012 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local O -- Options
local Util = sDKP.Util

local format = format
local tonumber = tonumber
local GetItemInfo = GetItemInfo
local GetRealZoneText = GetRealZoneText
local IsInInstance = IsInInstance

local LOG_LOOT = 0

local VARIABLES_LOADED = sDKP.VARIABLES_LOADED
function sDKP:VARIABLES_LOADED()
    VARIABLES_LOADED(self)
    O = sDKP.Options
end

-- Static popup appearing after clicking charge links
StaticPopupDialogs["SDKP_CHAT_CHARGE_PLAYER"] = {
    text = "Type item cost into the box below to charge player %s for %s", -- Are you sure you wish to exchange %s for the following item
    button1     = OKAY,
    button2     = CANCEL,
    hasEditBox  = 1,
    hideOnEscape = 1,
    maxLetters  = 5,
    timeout     = 0,
    whileDead   = 1,
    OnHide = function()
        if ( ChatFrameEditBox:IsShown() ) then
          ChatFrameEditBox:SetFocus()
        end
        getglobal(this:GetName().."EditBox"):SetText("")
    end,
    OnAccept = function(data)
        local value = tonumber(getglobal(this:GetParent():GetName().."EditBox"):GetText()) or 0
        sDKP:ModifyChatWrapper(data.player, -value, data.iLink)
        getglobal(this:GetParent():GetName().."EditBox"):SetText("")
    end,
    EditBoxOnEnterPressed = function(data)
        local value = tonumber(getglobal(this:GetParent():GetName().."EditBox"):GetText()) or 0
        sDKP:ModifyChatWrapper(data.player, -value, data.iLink)
        getglobal(this:GetParent():GetName().."EditBox"):SetText("")
        this:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function()
        this:GetParent():Hide()
    end,
}

function sDKP:CHAT_MSG_LOOT(msg)
    if not self.inRaid then return end
    player, id, count = Util.ParseLootMessage(msg)
    if player and id then
        local _, link, rarity = GetItemInfo(id)
        if rarity >= O.Log_FilterMinRarity then
            self:Log(LOG_LOOT, player, link, count)
        end
    end
end

sDKP:RegisterEvent("CHAT_MSG_LOOT")

function sDKP:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.inInstance, self.instanceType = IsInInstance()
    self.inRaid = (self.instanceType == "raid")
    self.zone = GetRealZoneText()
    
    GuildRoster()
    
    if self.inRaid then
        self:RegisterEvent("UNIT_TARGET")
    else
        self:UnregisterEvent("UNIT_TARGET")
    end
end

sDKP:RegisterEvent("PLAYER_ENTERING_WORLD")

function sDKP:ZONE_CHANGED_NEW_AREA()
    self.zone = GetRealZoneText()
end

sDKP:RegisterEvent("ZONE_CHANGED_NEW_AREA")

function sDKP.ChatMsgLootFilter(msg)
    if sDKP.inRaid and not O.Chat_HideLootHyperlinks then
        local player, itemId = Util.ParseLootMessage(msg)
        if player and itemId then
            local name, link, rarity = GetItemInfo(itemId)
            if rarity >= O.Chat_FilterMinRarity and not O.Chat_IgnoreItemIds[tonumber(itemId)] then
                msg = format("%s %s", msg, Util.CreateHyperlink("ch", "charge", player, itemId))
            end
        end
    end
    return false, msg
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", sDKP.ChatMsgLootFilter)

sDKP.HyperlinkHandlers.ch = function(btn, data)
    local player, itemId = strsplit(":", data)
    if not player or not itemId then
        return
    end
    
    local iName, iLink, iRarity = GetItemInfo(itemId)
    local dialog = StaticPopup_Show("SDKP_CHAT_CHARGE_PLAYER", Util.ClassColoredPlayerName(player), iLink)
    if (dialog) then
        dialog.data = {
            iLink = iLink,
            player = player
        }
    end
end
