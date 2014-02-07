--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local pairs = pairs
local tonumber = tonumber
local GetGuildInfoText = GetGuildInfoText
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumRaidMembers = GetNumRaidMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetTime = GetTime
local GuildRosterSetOfficerNote = GuildRosterSetOfficerNote
local UnitInRaid = UnitInRaid

-- Event handlers --------------------------------------------------------------

function sDKP:GUILD_ROSTER_UPDATE()
    if not GetGuildRosterShowOffline() then
        GuildFrameLFGButton:Click()
        self:Print("Enabled offline guild members visibility for addon to remain functional.")
        return
    end

    GuildFrameLFGButton:Disable()
    self:OnGuildRosterUpdate()
    self.GUILD_ROSTER_UPDATE = self.OnGuildRosterUpdate
end

function sDKP:OnGuildRosterUpdate()
    local O = self.Options
    if not O.Core_IgnoreGuildInfoFormat then
        local newformat = GetGuildInfoText():match("{dkp:(.-)}")
        if newformat then
            O.Core_NoteFormat = newformat
        end
    end

    self:Update()
    self:QueueProcess()
end

function sDKP:PLAYER_GUILD_UPDATE(unit)
    if not unit or unit ~= "player" then return end

    local guild = (GetGuildInfo("player"))
    if self.guild and guild ~= self.guild then
        self.Roster = { }
    end
    self.guild = guild
    self:CheckLogPresence()
end

-- Utility functions -----------------------------------------------------------

--- Returns character object if name specified, otherwise the whole roster table.
-- @param name (optional) Character name.
-- @return table|nil - Roster table, character object or nil if character not found.
function sDKP:GetRoster(name)
    return not name and self.Roster or self.Roster[name]
end

--- Returns character object.
-- @param name Character name.
-- @return table|nil - Character object or nil if character not found.
function sDKP:GetCharacter(name)
    return self:GetRoster(assert(name, "Character name required."))
end

--- Returns main name.
-- @param name Player name.
-- @return mixed - Main name for alt or nil for main.
function sDKP:GetMainName(n)
    if self.Roster[n] then
        if self.Roster[n].main then
            if self.Roster[self.Roster[n].main] then
                return self.Roster[n].main
            end
            return
        end
        return n
    elseif self.Externals[n] and self.Roster[self.Externals[n]] then
        return self.Externals[n]
    end
    return
end

--- Returns character object. Resolves aliases to their owner characters.
-- @param name Character name.
-- @return table|nil - Character object or nil if character not found.
function sDKP:GetPlayer(name)
    return self:GetRoster(assert(name, "Player name required.")) -- check roster
        or self:Unalias(name) and self:GetRoster(self:Unalias(name)) -- check aliases
end

--- Returns player online alt.
-- @param main Main name.
-- @return mixed - Online alt name or nil if none.
function sDKP:GetPlayerOnlineAlt(main)
    for n, d in pairs(self.Roster) do
        if d.main == main and d.on then
            return n
        end
    end
end

--- Returns DKP values for given player
-- @param name Character name.
-- @return number - Net amount.
-- @return number - Total value.
-- @return number - Hours count.
function sDKP:GetPlayerPointValues(n)
    return self.Roster[n].net, self.Roster[n].tot, self.Roster[n].hrs
end

function sDKP:IsInGuild(name)
    return not not self:GetPlayer(name)
end

--- Returns 1 if character is an officer,  i.e. can
-- read and write to officer chat, or nil otherwise
-- @param name Character name.
-- @return boolean - True for officer, nil otherwise.
function sDKP:IsOfficer(name)
    if self:GetMainName(name) then
        local _, _, rank = GetGuildRosterInfo(self.Roster[name].id)
        GuildControlSetRank(rank + 1)
        local _, _, oListen, oSpeak = GuildControlGetRankFlags()
        return (oListen and oSpeak) or nil
    end
    return
end

-- Core functionality ----------------------------------------------------------

--- Deletes all roster entries that do not contain unsaved data.
function sDKP:CleanupRoster()
    for n, d in pairs(self.Roster) do
        if not d.new and not d.iron then
            self.Roster[n] = nil
        end
    end
end

--- Discards all or only given player's changes.
-- @param name Player name (optional).
-- @return number - Discarded notes count.
function sDKP:Discard(name)
    local count = 0
    if name then
        name = self:GetMainName(name)
        if not name then
            return count
        end
        local d = self.Roster[name]
        if d.new then
            d.hrsD = 0
            d.netD = 0
            d.totD = 0
            d.new = nil
            count = count + 1
        end
        return count
    end
    for n, d in pairs(self.Roster) do
        if not name or (n == name) then
            if d.new then
                d.hrsD = 0
                d.netD = 0
                d.totD = 0
                d.new = nil
                count = count + 1
            end
        end
    end
    return count
end

--- Modifies relative DKP amounts of given player for future storage.
-- @param name Player name.
-- @param netD Net delta (optional, defaults to 0).
-- @param totD Total delta (optional, defaults to 0).
-- @param hrsD Hours count delta (optional, defaults to 0).
-- @return boolean - Success flag.
function sDKP:Modify(name, netD, totD, hrsD)
    n = self:GetMainName(name)
    if not n then
        return
    end
    
    netD = tonumber(netD) or 0
    totD = tonumber(totD) or 0
    hrsD = tonumber(hrsD) or 0
    
    local d = self.Roster[n]
    
    d.new = true
    d.netD = d.netD + netD
    d.totD = d.totD + totD
    d.hrsD = d.hrsD + hrsD
    
    return true
end

--- Sets absolute DKP amounts of given player for future storage.
-- @param name Player name.
-- @param net Net amount (optional, defaults to player's current net).
-- @param tot Total amount (optional, defaults to player's current tot).
-- @param hrs Hours count (optional, defaults to player's current hours count).
-- @return boolean - Success flag.
function sDKP:Set(name, net, tot, hrs)
    n = self:GetMainName(name)
    if not n then
        return
    end
    
    local d = self.Roster[n]

    net = tonumber(net) or d.net
    tot = tonumber(tot) or d.tot
    hrs = tonumber(hrs) or d.hrs
    
    d.new = true
    d.net = net
    d.tot = tot
    d.hrs = hrs
    
    d.netD = 0
    d.totD = 0
    d.hrsD = 0
    
    return true
end

--- Enqueues officer note data storage and activates the queue.
-- @param name Player to store data for (optional).
-- @return number - Queued changes count.
function sDKP:Store(name)
    local count = 0
    for n, d in pairs(self.Roster) do
        if not name or (n == name) then
            if d.new and not d.main then
                self:QueueAdd(n)
                count = count + 1
            end
        end
    end
    self:QueueActivate()
    return count
end

do
    local parse = sDKP.ParseOfficerNote
    
    --- Updates roster data.
    function sDKP:Update()
        local diff = self.Options.Core_VerboseDiff
        for i = 1, GetNumGuildMembers() do
            local n, _, _, _, _, _, _, o, on, _, class = GetGuildRosterInfo(i)
            
            -- prevent nil errors when roster data still
            -- returns  empty  data  after GuildRoster()
            if not n then return end
            
            local main, net, tot, hrs = parse(o)
            self.Roster[n] = self.Roster[n] or {
                class = class,
                hrsD = 0,
                netD = 0,
                totD = 0,
                new = nil,
            }
            
            local d = self.Roster[n]
            
            d.id = i        -- GuildRoster...() index
            d.n = n         -- name
            d.main = main   -- main's name if present
            
            if diff then
                self:VerboseDiff(n, d.net, d.tot, d.hrs, net, tot, hrs)
            end
            
            d.hrs = hrs     -- hours counter
            d.net = net     -- netto DKP
            d.tot = tot     -- total DKP
            
            d.on = on       -- online status
        end
    end
end

do
    local RED   = "|cffff3333"
    local GREEN = "|cff33ff33"
    local GRAY  = "|cff888888"
    
    local function col(a, b)
        a = tonumber(a) or 0
        b = tonumber(b) or 0
        if b > a then return GREEN end
        if b < a then return RED end
        return GRAY
    end
    
    --- Prints a message with amount deltas on DKP change.
    function sDKP:VerboseDiff(n, net, tot, hrs, oldnet, oldtot, oldhrs)
        if net and tot and hrs and (oldnet ~= net or oldtot ~= tot or oldhrs ~= hrs) then
            self:Echo("DKP change: %s %s%+d net|r, %s%+d tot|r, %s%+d hrs|r", sDKP.ClassColoredPlayerName(n), col(net, oldnet), oldnet - net, col(tot, oldtot), oldtot - tot, col(hrs, oldhrs), oldhrs - hrs)
        end
    end
end
