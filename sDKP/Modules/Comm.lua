--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

assert(ChatThrottleLib, "sDKP: ChatThrottleLib instance not found.")

local sDKP = sDKP
local ctl = ChatThrottleLib

local format = format
local strjoin = strjoin
local strsplit = strsplit

local CTL_PRIO  = "NORMAL"
local DELIMETER = "\a"

sDKP.commPrefix = "sDKP"
local comms = sDKP.Comms

function sDKP:CHAT_MSG_ADDON(prefix, msg, distr, sender)
    if not self:GetCharacter(sender) then return end
    if prefix ~= self.commPrefix or sender == self.player then return end
    local type, data = strsplit(DELIMETER, msg, 2)
    if not comms[type] then return end
    comms[type](self, data, distr, sender)
end

sDKP:RegisterEvent("CHAT_MSG_ADDON")

--- Adds new comm handler.
-- @param type Handler type.
-- @param func Handler function.
function sDKP:CommRegisterHandler(type, func)
    assert(type and func, format("sDKP: Could not register comm of type %s.", type or "<?>"))
    comms[type] = func
end

-- ------------------------------------------------------------------
-- .CommHandlers.<TYPE>(self, data, distr, sender)
-- ------------------------------------------------------------------
-- self
--     always passed as first parameter, points to addon object
-- data
--     received data without the message type part
-- distr
--     distribution type
-- sender
--     message sender
-- ------------------------------------------------------------------
function comms.TEST(self, data, distr, sender)
    self:Print(format("%q %q %q", data or "?", distr or "?", sender or "?"))
end

function comms.HI(self, data, distr, sender)
    self:CommSend("VER", self.version, "WHISPER", sender)
end

function comms.VER(self, data, distr, sender)
    self.Versions[sender] = data
end

--- Sends comm message.
-- @param type Handler type to use when receiving message.
-- @param data Single data string to send.
-- @param distr Distribution type (optional, defaults to "GUILD").
-- @param chan Channel for "WHISPER" or "CHANNEL" destination (optional).
function sDKP:CommSend(type, data, distr, chan)
    ctl:SendAddonMessage(CTL_PRIO, self.commPrefix, data and strjoin(DELIMETER, type, data) or type, distr or "GUILD", chan)
end

--- Prints guild mates' addon versions to chat frame.
function sDKP:VersionDump()
    local version = self.version
    compare = self.VersionCompare
    self:Print("Guild mates' versions detected:")
    local count = 0
    for n, v in self.PairsByKeys(self.Versions) do
        self:Echo("   %s |cff%s%s|r", n, compare(v, version) and "33ff33" or (v == version) and "ffffff" or "ff3333", v)
        count = count + 1
    end
    self:Echo("Total of %d |4player:players;.", count)
end
