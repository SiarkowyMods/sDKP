--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local assert = assert
local count = sDKP.count
local dispose = sDKP.dispose
local new = sDKP.table
local pairs = pairs
local tonumber = tonumber
local GetGuildInfoText = GetGuildInfoText
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumRaidMembers = GetNumRaidMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetTime = GetTime
local GuildRosterSetOfficerNote = GuildRosterSetOfficerNote
local UnitInRaid = UnitInRaid

local LOG_GUILD_JOIN = 9
local LOG_GUILD_QUIT = 10

local Roster, Options

-- Event handlers --------------------------------------------------------------

--- The initial GUILD_ROSTER_UPDATE event handler.
-- Enables guild roster offline player visibility if not set.
-- Subsequent GUILD_ROSTER_UPDATE events are handled in OnGuildRosterUpdate().
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

--- Normal GUILD_ROSTER_UPDATE event handler.
-- Called on guild roster updates. Does roster cleanup, updates and pending
-- operation queue processing. Checks for DKP data format changes.
function sDKP:OnGuildRosterUpdate()
    if not self.guild then return end
    if not self:Get("core.noginfo") then
        local newformat = GetGuildInfoText():match("{dkp:(.-)}")

        if newformat and newformat ~= self:Get("core.format") then
            self:Set("core.format", newformat)
        end
    end

    if self.cleanup then
        self:CleanupRoster()
    end

    self:Update()
    self:QueueProcess()
end

--- PLAYER_GUILD_UPDATE event handler.
-- Prepares roster and log tables. Reconfigures local variables.
function sDKP:PLAYER_GUILD_UPDATE(unit)
    if not unit or unit ~= "player" then return end
    local guild = GetGuildInfo("player")
    if not guild or self.guild == guild then return end

    self.guild = guild
    self.cleanup = true
    self.Roster = self:GetGuildRoster(guild)

    self:Reconfigure()
    self:CheckLogPresence()
end

-- Utility functions -----------------------------------------------------------

--- Addon settings getter.
-- @param opt (string) Option name.
-- @return mixed - Setting value.
function sDKP:Get(opt) return Options[opt] end

--- Addon settings setter.
-- @param opt (string) Option name.
-- @param v (mixed) New value.
function sDKP:Set(opt, v) Options[opt] = v end

--- Sets internal upvalues.
function sDKP:Reconfigure()
    Roster      = self.Roster
    Options     = self.Options
end

--- Prepares roster table for operation.
function sDKP:CleanupRoster()
    if GetNumGuildMembers() < 1 then return end

    local roster = new()
    local diff = self:Get("core.diff")

    for i = 1, GetNumGuildMembers() do
        roster[GetGuildRosterInfo(i)] = true
    end

    for name, char in self:GetChars() do
        if roster[name] or char.id == 0 then
            self:BindClass(char, "Character")
        elseif char.id ~= 0 then -- neither in roster nor external character
            self:Log(LOG_GUILD_QUIT, name, char.class, char.net, char.tot, char.hrs)

            Roster[name] = nil
            dispose(char)

            if diff then
                self:Printf("<%s> |cffff3333-%s|r", self.guild, name)
            end
        end
    end

    dispose(roster)
    self.cleanup = nil
end

--- Calls function by name with supplied params for each character in list.
-- @param list (table) Character list as returned from Select().
-- @param func (string) Method name.
-- @param ... (tuple) Argument vararg.
function sDKP:ForEach(list, func, ...)
    assert(func)

    for _, name in pairs(list) do
        local char = self(name)

        if char then
            char[func](char, ...)
        end
    end
end

--- Returns character object.
-- @param name Character name.
-- @return table|nil - Character object or nil if not found.
function sDKP:GetCharacter(name)
    assert(name, "Character name required.")
    return Roster[name]
end

--- Returns desired guild's roster table from database.
-- Creates new roster when needed!
-- @param guild (string) Guild name.
-- @return table - Guild roster table.
function sDKP:GetGuildRoster(guild)
    if not guild then
        return new()
    end

    if not self.DB.Rosters[guild] then
        self.DB.Rosters[guild] = new()
    end

    return self.DB.Rosters[guild]
end

--- Returns roster table iterator. A shorthand for pairs(Roster).
-- @return function - Roster table iterator.
function sDKP:GetChars()
    return pairs(Roster)
end

--- Roster table getter.
-- @return table - Roster table.
function sDKP:GetRoster()
    return Roster
end

--- Returns player online character.
-- @param main (string) Main name.
-- @return string|nil - Online alt name or nil if none.
function sDKP:GetOwnerOnline(main)
    assert(main, "Main name required.")

    for name, char in self:GetChars() do
        if char.name == main or char.altof == main then
            -- check for guild character
            if char.on then
                return name
            end

            -- check for external character
            if char.id == 0 and UnitInRaid(char.name)
            and select(8, GetRaidRosterInfo(UnitInRaid(char.name) + 1)) then
                return name
            end
        end
    end

    return nil
end

--- Returns true if player is in guild.
-- @param name (string) Player name.
-- @return boolean
function sDKP:IsInGuild(name)
    return not not self(name)
end

-- Core functionality ----------------------------------------------------------

--- Discards all pending changes to player data.
-- @return number - Count of discarded changes.
function sDKP:Discard()
    local count = 0

    for name, char in self:GetChars() do
        if char:Discard() then
            count = count + 1
        end
    end

    return count
end

--- Enqueues officer note data storage and activates the queue.
-- @return number - Count of queued changes.
function sDKP:Store()
    local count = 0

    for name, char in self:GetChars() do
        if char.new then
            self:QueueAdd(name)
            count = count + 1
        end
    end

    self:QueueActivate()

    return count
end

--- Updates roster data. Called by GUILD_ROSTER_UPDATE handler.
function sDKP:Update()
    local diff = self:Get("core.diff")

    for i = 1, GetNumGuildMembers() do
        local name, rank, rankId, level, _, zone,
            pnote, onote, online, status, class = GetGuildRosterInfo(i)

        if not name then return end -- prevent nil errors despite GuildRoster()

        local char, new = self(name)
        if not char then char, new = self:BindClass(nil, "Character") end

        char:OnUpdate(i, name, rank, rankId, level, _, zone,
            pnote, onote, online, status, class, diff)

        if new then
            Roster[name] = char
            self:Log(LOG_GUILD_JOIN, name, char.class)

            if diff then
                self:Printf("<%s> |cff33ff33+%s|r", self.guild, name)
            end
        end
    end
end

local conds = {
    -- adjectives
    alt     = function(self) return self:IsAlt() end,
    main    = function(self) return self:IsMain() end,
    all     = function(self) return self:IsInRaid() or self:IsStandBy() end,
    guild   = function(self) return true end,
    ironman = function(self) return self:IsIronMan() end,
    name    = function(self, cond) return self.name == cond end,
    officer = function(self) return self:IsOfficer() end,
    online  = function(self) return self.on end,
    raid    = function(self) return (self:GetRaidSubgroup() or 6) <= 5 end,
    standby = function(self) return self:IsStandBy() end,
    zone    = function(self) return self:GetZone() == GetRealZoneText() end,
    otherzone = function(self) return self:GetZone() ~= GetRealZoneText() end,

    -- general objects
    party   = function(self) return self:IsInParty() end,
    party1  = function(self) return self:IsInRaidSubgroup(1) end,
    party2  = function(self) return self:IsInRaidSubgroup(2) end,
    party3  = function(self) return self:IsInRaidSubgroup(3) end,
    party4  = function(self) return self:IsInRaidSubgroup(4) end,
    party5  = function(self) return self:IsInRaidSubgroup(5) end,
    party6  = function(self) return self:IsInRaidSubgroup(6) end,
    party7  = function(self) return self:IsInRaidSubgroup(7) end,
    party8  = function(self) return self:IsInRaidSubgroup(8) end,

    -- class objects
    druids   = function(self) return self.class == "DRUID"   end,
    hunters  = function(self) return self.class == "HUNTER"  end,
    mages    = function(self) return self.class == "MAGE"    end,
    paladins = function(self) return self.class == "PALADIN" end,
    priests  = function(self) return self.class == "PRIEST"  end,
    rogues   = function(self) return self.class == "ROGUE"   end,
    shamans  = function(self) return self.class == "SHAMAN"  end,
    warlocks = function(self) return self.class == "WARLOCK" end,
    warriors = function(self) return self.class == "WARRIOR" end,
}

-- some adjectives can also be used as objects
conds.alts = conds.alt
conds.mains = conds.main
conds.officers = conds.officer

-- abbreviations
conds.pt = conds.party
conds.pt1 = conds.party1
conds.pt2 = conds.party2
conds.pt3 = conds.party3
conds.pt4 = conds.party4
conds.pt5 = conds.party5
conds.pt6 = conds.party6
conds.pt7 = conds.party7
conds.pt8 = conds.party8

--- Returns filter character list.
-- @param who (string) Filter string.
-- @return table - Table of main<-->match pairs.
-- @return number - Count of matched characters.
function sDKP:Select(who)
    local list = new()

    for set in (who or ""):gmatch("[^,]+") do -- split who by commas into sets
        local char = self(set:trim()) -- can be player name

        if char then
            list[char:GetMain().name] = set:trim()
        else
            for name, char in self:GetChars() do -- for every character
                if not list[name] then -- check if already matches
                    local flag = true -- assume a match

                    for cond in set:gmatch("%S+") do -- split set by whitespace into conds
                        if flag then
                            flag = (conds[cond] or conds.name)(char, cond)
                        end
                    end

                    if flag then
                        list[char:GetMain().name] = name
                    end
                end
            end
        end
    end

    return list, count(list)
end
