--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

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

function sDKP.ClassColoredPlayerName(player)
    if not sDKP.Roster[player] then
        return player
    end
    
    local c = RAID_CLASS_COLORS[sDKP.Roster[player].class]
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

--- Cuts out @channel part from string and returns it as second parameter.
-- @param msg Message to extract channel from.
-- @param defchan Default channel if not found.
-- @return string - Message without channel part.
-- @return string - Extracted or default channel.
function sDKP.ExtractChannel(msg, defchan)
    local channel

    local func = function(m)
        channel = m
        return ""
    end

    msg = msg:gsub("@(%S+)", func):trim()
    return msg, (channel or defchan)
end

do
    local data = { }
    --- Returns formatted note data string from given player data
    -- to be enclosed in curly brackets and stored to officer note.
    -- @param d Player data table (form Roster table).
    -- @param netD Net amount delta. This will be added to current value (optional, defaults to 0).
    -- @param totD Total amount delta. This will be added to current value (optional, defaults to 0).
    -- @param hrsD Hours count delta. This will be added to current value (optional, defaults to 0).
    -- @return string - Formatted note data.
    function sDKP.FormatNoteData(d, netD, totD, hrsD)
        data.d = date("%d")
        data.m = date("%m")
        data.Y = date("%Y")

        data.n = d.net + (netD or 0)
        data.t = d.tot + (totD or 0)
        data.h = d.hrs + (hrsD or 0)

        return gsub(sDKP:Get("core.format"), "%%(.)", data)
    end
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

--- Returns decimal timestamp from given date string.
-- @param param String timestamp.
-- @return number - Integer timestamp.
function sDKP.ParamToTimestamp(param)
    local timestamp
    local year, month, day, hour, min, sec = param:match("(%d+).(%d+).(%d+)%s*(%d+).(%d+).(%d+)")

    if sec then
        timestamp = time{year = year, month = month, day = day, hour = hour, min = min, sec = sec}
    else
        timestamp = tonumber(param:match("%d+"))
    end

    return timestamp
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
    local param = o or ""
    local between = param:match("{(.-)}") or ""
    
    if between:match("%D+") == between then -- alt
        return between, 0, 0, 0
    end
    
    local net = tonumber(between:match("Ne?t?.([-]?%d+)")) or 0
    local tot = tonumber(between:match("To?t?.([-]?%d+)")) or 0
    local hrs = tonumber(between:match("Hr?s?.([-]?%d+)")) or 0
    
    return nil, net, tot, hrs
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
