--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local abs = abs
local assert = assert
local format = format
local match = string.match
local mod = mod
local pairs = pairs
local select = select
local sort = sort
local strjoin = strjoin
local strsplit = strsplit
local time = time
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local tremove = tremove
local unpack = unpack
local GetItemInfo = GetItemInfo
local GetTime = GetTime

local LOG_DELIMETER         = "\a"

-- Log entry types
local LOG_UNKNOWN           = -1 -- Unknown entry
local LOG_PLAYER_LOOT       = 0 --- Loot entry
local LOG_DKP_MODIFY        = 1 --- DKP modification (award, charge) entry
local LOG_DKP_RAID          = 2 --- (Unused)
local LOG_DKP_CLASS         = 3 --- (Unused)
local LOG_PARTY_KILL        = 4 --- Boss slain entry
local LOG_IRONMAN_START     = 5 --- Ironman start entry
local LOG_IRONMAN_CANCEL    = 6 --- Ironman cancel entry
local LOG_IRONMAN_AWARD     = 7 --- Ironman award entry
local LOG_DKP_DIFF          = 8 --- DKP difference entry (with external changes)
local LOG_GUILD_JOIN        = 9 --- Guild join entry
local LOG_GUILD_QUIT        = 10 -- Guild quit entry

-- Helper functions ------------------------------------------------------------

local function tostringall(...)
    if select('#', ...) > 1 then
        return tostring(select(1, ...)), tostringall(select(2, ...));
    else
        return tostring(select(1, ...));
    end
end

local function serialize(...) return strjoin(LOG_DELIMETER, tostringall(...)) end
local function unserialize(data) return strsplit(LOG_DELIMETER, data) end

-- Save to Util
sDKP.tostringall = tostringall
sDKP.LogSerialize = serialize
sDKP.LogUnserialize = unserialize

-- Log -> String handling ------------------------------------------------------

--- Log entry formatting handlers
-- Contains type<->func pairs.
-- @param type (number) Entry type.
-- @param func (function) Formatting function which is passed unpacked data from log.
sDKP.LogToStringHandlers = {
    [LOG_UNKNOWN] = function() -- -1
        return "Unknown entry."
    end,

    [LOG_PLAYER_LOOT] = function(player, item, count) -- 0
        local _, link = GetItemInfo(item)
        count = tonumber(count) or 1
        return format("%s looted %s%s.", sDKP.ClassColoredPlayerName(player), link or "<unknown item>", count > 1 and format("x%d", count) or "")
    end,

    [LOG_DKP_MODIFY] = function(player, points, reason) -- 1
        points = tonumber(points) or 0
        if tonumber(reason) then
            _, reason = GetItemInfo(reason)
        end
        return format("%s got %+d DKP%s.", sDKP.ClassColoredPlayerName(player), points, reason and format(": %s", reason) or "")
    end,

    [LOG_DKP_RAID] = function(count, points, reason) -- 2
        count = tonumber(count) or 0
        points = tonumber(points) or 0
        if tonumber(reason) then
            _, reason = GetItemInfo(reason)
        end
        return format("Raid (%d |4player:players;) %+d DKP%s.", count, points, reason and format(": %s", reason) or "")
    end,

    [LOG_DKP_CLASS] = function(class, count, points, reason) -- 3
        count = tonumber(count) or 0
        points = tonumber(points) or 0
        if tonumber(reason) then
            _, reason = GetItemInfo(reason)
        end
        return format("%ss (%d |4player:players;) %+d DKP%s.", gsub(class, "^(.)", string.upper), count, points, reason and format(": %s", reason) or "")
    end,

    [LOG_PARTY_KILL] = function(mob) -- 4
        return format("%s has been slain.", mob)
    end,

    [LOG_IRONMAN_START] = function(count) -- 5
        count = tonumber(count) or 0
        return format("Ironman started for %d |4player:players;.", count)
    end,

    [LOG_IRONMAN_CANCEL] = function() -- 6
        return "Ironman canceled."
    end,

    [LOG_IRONMAN_AWARD] = function(count, points) -- 7
        return format("Ironman awarded: %d |4player:players; %+d DKP.", count, points)
    end,

    [LOG_DKP_DIFF] = function(player, netD, totD, hrsD, curNet, curTot, curHrs) -- 8
        return format("%s's points changed: %s%+d net|r, %s%+d tot|r, %s%+d hrs|r.",
            sDKP.ClassColoredPlayerName(player),
            sDKP.DiffColorize(netD), netD,
            sDKP.DiffColorize(totD), totD,
            sDKP.DiffColorize(hrsD), hrsD)
    end,

    [LOG_GUILD_JOIN] = function(player, class)
        return format("%s joined the guild.", sDKP.ClassColoredPlayerName(player, class))
    end,

    [LOG_GUILD_QUIT] = function(player, class, net, tot, hrs)
        return format("%s left the guild with %+d net, %+d tot, %+d hrs DKP.",
            sDKP.ClassColoredPlayerName(player, class), net, tot, hrs)
    end,
}

local handlers = sDKP.LogToStringHandlers

function sDKP.LogToString(data)
    local type, a, b, c, d, e, f, g, h, i = unserialize(data)
    type = tonumber(type) or LOG_UNKNOWN
    return handlers[type](a, b, c, d, e, f, g, h, i)
end

-- Logging methods -------------------------------------------------------------

function sDKP:CheckLogPresence()
    if self.guild and not self.LogData[self.guild] then
        self.LogData[self.guild] = { }
    end
end

--- Logs data to current guild's log.
-- @param type (integer) Entry type integer, see LOG_* locals.
-- @param ... (tuple) Data list to serialize. Nils are ignored.
function sDKP:Log(type, ...)
    if not self.guild then return end

    local log = self.LogData[self.guild]
    local t = self.table()

    for i = 1, select("#", ...) do
        tinsert(t, (select(i, ...)))
    end

    local stamp = time() + mod(GetTime(), 1) -- calculate timestamp

    while log[stamp] do -- if already used
        stamp = stamp + 0.01
    end

    log[stamp] = serialize(type, unpack(t))
end

local result = { }
function sDKP:PrepareLog(startTime, endTime)
    startTime = startTime or time() - 86400 -- 1 day
    endTime = endTime or time()
    while (tremove(result)) do end
    for timestamp, data in pairs(self.LogData[self.guild]) do
        if timestamp >= startTime and timestamp <= endTime then
            tinsert(result, timestamp)
        end
    end
    sort(result)
    return result
end

-- Slash handlers --------------------------------------------------------------

function sDKP:LogDump()
    self:Print("Full log entry list:")

    local node = self.LogData[self.guild]
    local count = 0
    local LOG_DATEFORMAT = self:Get("log.dateformat")

    for _, timestamp in pairs(self:PrepareLog(0)) do
        self:Echo("|cff888888[%s]|r %s", date(LOG_DATEFORMAT, timestamp), self.LogToString(node[timestamp]))
        count = count + 1
    end

    self:Echo("Total of %d |4entry:entries;.", count)
end

function sDKP:LogPurge(param)
    param = param ~= "" and param or "4w"
    local timestamp = self.ParamToTimestamp(param)
    local node = self.LogData[self.guild]
    local count = 0
    for t, d in pairs(node) do
        if t < timestamp then
            node[t] = nil
            count = count + 1
        end
    end
    self:Printf("%d |4entry:entries; purged.", count)
end

function sDKP:LogSearch(param)
    local LOG_DATEFORMAT = self:Get("log.dateformat")

    param = param ~= "" and param or "time>8h"
    local param, chan = self.ExtractChannel(param, "SELF")

    local max_time = param:match('time<(%w+)')
    local min_time = param:match('time>(%w+)') or param:match('(%w+)<time')

    if max_time then max_time = self.ParamToTimestamp(max_time) end
    if min_time then min_time = self.ParamToTimestamp(min_time) end

    if max_time and min_time and min_time > max_time then
        min_time, max_time = max_time, min_time
    end

    self:Announce(chan, "Log search: %s", param)

    local param = param:gsub("[%w<>]*time[%w<>]*", ""):trim()

    local count = 0
    for time, entry in self.PairsByKeys(self.LogData[self.guild]) do
        if (not min_time or time >= min_time) and (not max_time or time <= max_time) then
            local flag = param == ""

            for str in param:gmatch("[^|]+") do
                flag = flag or entry:match(str)
            end

            if flag then
                self:Announce(chan, "|cff888888[%s]|r %s",
                    date(LOG_DATEFORMAT, time), self.LogToString(entry))

                count = count + 1
            end
        end
    end
    self:Announce(chan, "Total entries: %d", count)
end

sDKP.Slash.args.log = {
    type = "group",
    name = "Log",
    desc = "Operation log functions.",
    args = {
        dump = {
            name = "Dump",
            desc = "Prints all entries from log into chat frame.",
            type = "execute",
            func = "LogDump",
            order = 1
        },
        purge = {
            name = "Purge",
            desc = "Deletes log entries for current guild older than specified or at least 4 weeks old if no parameter given.",
            type = "execute",
            usage = "[<timestamp>]",
            func = "LogPurge",
            order = 2
        },
        search = {
            name = "Search",
            desc = "Shows all entries matching given string(s).",
            type = "execute",
            usage = "<query>[||...] [[from<]time[<to]] [@<channel>]",
            func = "LogSearch",
            order = 3
        },
    }
}
