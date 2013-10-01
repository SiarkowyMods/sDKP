--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local ctl = assert(ChatThrottleLib, "sDKP: Required ChatThrottleLib instance not found.")

local GetChannelName = GetChannelName
local IsRaidLeader = IsRaidLeader
local IsRaidOfficer = IsRaidOfficer
local UnitInRaid = UnitInRaid
local format = format
local upper = string.upper

-- ChatThrottleLib config constants
local CTL_PREFIX    = "sDKP"
local CTL_PRIO      = "NORMAL"

local CHANNELS = {
    GUILD   = true,
    OFFICER = true,
    PARTY   = true,
    RAID    = true,
    RAID_WARNING = true,
    SAY     = true,
    YELL    = true,
}

sDKP.VALID_CHANNELS = CHANNELS

--- Sends given message to preferred channel using ChatThrottleLib.
-- @param channel Destination channel (optional, defaults to :GetProperAnnounceChannel()).
-- @param ... Message args tuple for format() to send.
function sDKP:Announce(channel, ...)
    channel = channel or self.Options.Core_AnnounceChannel or self:GetProperAnnounceChannel()
    local message = format(...)

    if channel:upper() == "SELF" then DEFAULT_CHAT_FRAME:AddMessage(message)
    elseif CHANNELS[upper(channel)] then ctl:SendChatMessage(CTL_PRIO, CTL_PREFIX, message, channel)
    elseif GetChannelName(channel) > 0 then ctl:SendChatMessage(CTL_PRIO, CTL_PREFIX, message, "CHANNEL", nil, GetChannelName(channel))
    else ctl:SendChatMessage(CTL_PRIO, CTL_PREFIX, message, "WHISPER", nil, channel) end
end

--- Returns appropriate channel depending on raid role.
function sDKP:GetProperAnnounceChannel()
    return UnitInRaid("player") and ((IsRaidLeader() or IsRaidOfficer()) and "RAID_WARNING" or "RAID") or "GUILD"
end

sDKP.Modules.Announce = GetTime()
