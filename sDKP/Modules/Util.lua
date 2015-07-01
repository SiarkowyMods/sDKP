--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local ctl = ChatThrottleLib
local date = date
local format = format
local gsub = gsub
local match = string.match
local pairs = pairs
local sort = sort
local strjoin = strjoin
local tinsert = tinsert
local tonumber = tonumber

function sDKP.CreateHyperlink(kind, visual, ...)
    return format("|Hsdkp:%s:%s|h|cff88ff88(%s)|h", kind, strjoin(':', ...), visual)
end

function sDKP.ClassColoredPlayerName(player, class)
    if not sDKP.Roster[player] and not class then
        return player
    end

    local c = RAID_CLASS_COLORS[sDKP.Roster[player] and sDKP.Roster[player].class or class]
    return format("%s%s|r", sDKP.DecimalToHexColor(c.r, c.g, c.b), player)
end

--- Returns hex encoded color string from float red, green and blue values.
-- @param r Red value [0; 1].
-- @param g Green value [0; 1].
-- @param b Blue value [0; 1].
-- @return string - Hex color string.
function sDKP.DecimalToHexColor(r, g, b) -- from http://wowprogramming.com/snippets/Convert_decimal_classcolor_into_hex_27
    return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local RED   = "|cffff3333"
local GREEN = "|cff33ff33"
local GRAY  = "|cff888888"

--- Returns the color sequence (red, green or gray) for specified difference.
-- @param diff (number|string) Quantity difference, diff = new - old.
-- @return string - Color sequence.
function sDKP.DiffColorize(diff)
    diff = tonumber(diff) or 0

    if diff > 0 then return GREEN end
    if diff < 0 then return RED end

    return GRAY
end

--- Cuts out @channel part from string and returns it as second parameter.
-- @param msg Message to extract channel from.
-- @param chan Default channel if not found.
-- @return string - Message without channel part.
-- @return string - Extracted or default channel.
function sDKP.ExtractChannel(msg, chan)
    msg = msg:gsub("@(%S+)", function(m)
        chan = m
        return ""
    end):trim()

    return msg, chan
end

--- Returns an iterator to traverse hash indexed table in alphabetical order.
-- @param t Table.
-- @param f Sort function for table's keys.
-- @return function - Hash table alphabetical iterator.
function sDKP.PairsByKeys(t, f) -- from http://www.lua.org/pil/19.3.html
    local a = {}
    for n in pairs(t) do tinsert(a, n) end
    sort(a, f)
    local i = 0             -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]] end
    end
    return iter
end

local multipliers = {
    y = 31536000,   -- year (365d)
    m = 2678400,    -- month (31d)
    w = 604800,     -- week (7d)
    d = 86400,      -- day (24h)
    h = 3600,       -- hour (60M)
    M = 60,         -- minute (60s)
    s = 1           -- second (1)
}

--- Converts interval string to numeric interval.
-- @param string (string) Interval string.
-- @return (number) Numeric interval value.
function sDKP.ParamToInterval(string)
    local interval = 0

    for num, mul in string:lower():gmatch("(%d+)(%a)") do
        interval = interval + num * (multipliers[mul] or 1)
    end

    return interval
end

--- Returns decimal timestamp from given date string.
-- @param p String timestamp.
-- @return number - Integer timestamp.
function sDKP.ParamToTimestamp(p)
    p = tostring(p)

    return tonumber(p) and (time{
        year  = tonumber(p:sub( 1, 4)) or 1970,
        month = tonumber(p:sub( 5, 6)) or 1,
        day   = tonumber(p:sub( 7, 8)) or 1,
        hour  = tonumber(p:sub( 9,10)) or 0,
        min   = tonumber(p:sub(11,12)) or 0,
        sec   = tonumber(p:sub(13,14)) or 0
    } or 0) or time() - sDKP.ParamToInterval(p)
end

--- Parses loot message for item looter, ID and count.
-- @param msg Loot message.
-- @return string - Item looter.
-- @return mixed - Item ID or nil.
-- @return mixed - Count or false.
function sDKP.ParseLootMessage(msg)
    local player, id, count
    player, id = msg:match("(%S+) receives? loot:.*item:(%d+)")
    if not player or not id then
        player, id = msg:match("(%S+) won:.*item:(%d+)")
    end

    count = msg:match("x(%d+)") or id and 1
    if player then player = gsub(player, "^You$", sDKP.player) end

    return player, id, count
end

--- Returns alt status and DKP amounts from given officer note string.
-- @param o Officer note contents.
-- @return mixed - Main name or nil.
-- @return number - Net amount.
-- @return number - Total amount.
-- @return number - Hours count.
function sDKP.ParseOfficerNote(o)
    local data = (o or ""):match("{(.-)}") or ""

    if data:match("%D+") == data then -- alt
        return data, 0, 0, 0
    end

    return nil,
        tonumber(data:match("Ne?t?.(%-?%d+)")) or 0,
        tonumber(data:match("To?t?.(%-?%d+)")) or 0,
        tonumber(data:match("Hr?s?.(%-?%d+)")) or 0
end

--- Sends whisper using ChatThrottleLib.
-- @param who (string) Recipent.
-- @param message (string) Message to send.
function sDKP:SendWhisper(who, message)
    if who and who ~= self.player then
        ctl:SendChatMessage("BULK", nil, tostring(message), "WHISPER", nil, who)
    end
end

--- Returns boolean.
-- @param ver1 Version string.
-- @param ver2 Version string.
-- @return boolean - True if first version is newer than second, false otherwise.
function sDKP.VersionCompare(ver1, ver2)
    local a, b, c = ver1:match("(%d+).(%d+).(%d+)")
    local d, e, f = ver2:match("(%d+).(%d+).(%d+)")

    if a > d then return true
    elseif a < d then return false
    elseif b > e then return true
    elseif b < e then return false
    else return c > f end
end
