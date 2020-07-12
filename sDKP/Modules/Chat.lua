--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local format = format
local tConcat = table.concat
local tonumber = tonumber
local GetItemInfo = GetItemInfo
local GetRealZoneText = GetRealZoneText
local IsInInstance = IsInInstance

local LOG_LOOT = 0

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
        local char = sDKP(data.player)
        if char then char:Charge(value, data.iLink):Store() end
        getglobal(this:GetParent():GetName().."EditBox"):SetText("")
    end,
    EditBoxOnEnterPressed = function(data)
        local value = tonumber(getglobal(this:GetParent():GetName().."EditBox"):GetText()) or 0
        local char = sDKP(data.player)
        if char then char:Charge(value, data.iLink):Store() end
        getglobal(this:GetParent():GetName().."EditBox"):SetText("")
        this:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function()
        this:GetParent():Hide()
    end,
}

do
    local prevPlayer, prevItemId

    function sDKP:CHAT_MSG_LOOT(msg)
        if not self.inRaid then return end

        local player, itemId, itemCount = self.ParseLootMessage(msg)
        if player and itemId and (player ~= prevPlayer or itemId ~= prevItemId) then
            prevPlayer, prevItemId = player, itemId

            local _, link, rarity = GetItemInfo(itemId)
            if rarity >= self:Get("log.rarity") or self:Get("log.includeitems")[tonumber(itemId)] then
                self:Log(LOG_LOOT, player, link, itemCount)
            end
        end
    end
end

sDKP:RegisterEvent("CHAT_MSG_LOOT")

function sDKP:CHAT_MSG_WHISPER(msg, sender)
    if msg:sub(1, 1) ~= "?" or not sender then
        return
    end

    if msg:sub(1, 5) == "?bind" and UnitInRaid(sender) then
        if not self:Get("whisper.binding") then
            return
        end

        local name, dkp = msg:match("?bind%s*(%S+)%s*(%d+)")
        dkp = dkp and tonumber(dkp)

        if not name then
            self:SendWhisper(sender, format("<sDKP> Binding usage: ?bind main net_dkp"))

        elseif self(sender) then
            self:SendWhisper(sender, format("<sDKP> Your character is already bound. Use ?dkp"))

        elseif not self(name) then
            self:SendWhisper(sender, format("<sDKP> Your target has to be in the guild."))

        elseif self(name):GetMain().net ~= dkp or not dkp then
            self:SendWhisper(sender, format("<sDKP> You supplied wrong amount of points."))

        else -- all right, bind me!
            if self:SetAlias(sender, self(name):GetMain().name) then
                self:SendWhisper(sender, format("<sDKP> You have been bound successfully. Use ?dkp"))
            else
                assert(false, "Could not bind external character.")
            end
        end

        return
    end

    if not self(sender) then
        return
    end

    if msg == "?dkp" then
        self:SendWhisper(sender, format("<sDKP> Point info: %d net, %d tot, %d hrs.",
            self(sender):GetMain():GetPoints()))

    elseif msg == "?standby" then
        local list, num = self:Select("standby")
        local t = self.table()

        if num > 0 then
            self:SendWhisper(sender, "<sDKP> Standby list:")

            for name, char in self:GetChars() do
                if char:IsStandBy() then
                    tinsert(t, char.name)

                    if #t >= 5 then
                        self:SendWhisper(sender, tConcat(t, ", "))
                        self.wipe(t)
                    end
                end
            end

            if #t > 0 then
                self:SendWhisper(sender, tConcat(t, ", "))
            end
        else
            self:SendWhisper(sender, "<sDKP> Standby list empty.")
        end

        self.dispose(t)
        self.dispose(list)
    end
end

sDKP:RegisterEvent("CHAT_MSG_WHISPER")

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
    if sDKP.inRaid and not sDKP:Get("chat.nolootlinks") then
        local player, itemId = sDKP.ParseLootMessage(msg)
        if player and itemId then
            local name, link, rarity = GetItemInfo(itemId)
            if rarity >= sDKP:Get("chat.rarity") and not sDKP:Get("chat.ignoredids")[tonumber(itemId)] then
                msg = format("%s %s", msg, sDKP.CreateHyperlink("ch", "charge", player, itemId))
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
    local dialog = StaticPopup_Show("SDKP_CHAT_CHARGE_PLAYER", sDKP.ClassColoredPlayerName(player), iLink)
    if (dialog) then
        dialog.data = {
            iLink = iLink,
            player = player
        }
    end
end
