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

local Externals, Roster, Options

--- Addon settings getter.
-- @param opt (string) Option name.
-- @return mixed - Setting value.
function sDKP:Get(opt) return Options[opt] end

--- Addon settings setter.
-- @param opt (string) Option name.
-- @param v (mixed) New value.
function sDKP:Set(opt, v) Options[opt] = v end

--- Returns character object.
-- @param name Character name.
-- @return table|nil - Character object or nil if character not found.
function sDKP:GetCharacter(name)
    return Roster[assert(name, "Character name required.")]
end

--- Roster table getter.
-- @param name (optional) Character name.
-- @return table - Roster table.
function sDKP:GetRoster()
    return Roster
end

--- Shorthand for pairs(Roster).
function sDKP:GetChars()
    return pairs(Roster)
end

--- Sets internal upvalues.
function sDKP:Reconfigure()
    Externals   = self.Externals
    Roster      = self.Roster
    Options     = self.Options
end

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

function sDKP:GetGuildRoster(guild)
    if not guild then
        return new()
    end

    if not self.DB.Rosters[guild] then
        self.DB.Rosters[guild] = new()
    end

    return self.DB.Rosters[guild]
end

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
    return self:GetCharacter(assert(name, "Player name required.")) -- check roster
        or self:Unalias(name) and self:GetCharacter(self:Unalias(name)) -- check aliases
end

--- Returns player online character.
-- @param main (string) Main name.
-- @return mixed - Online alt name or nil if none.
function sDKP:GetOwnerOnline(main)
    assert(main, "Main name required.")

    for name, char in self:GetChars() do
        if char.on and (char.name == main or char.altof == main) then
            return name
        end
    end

    return nil
end

function sDKP:IsInGuild(name)
    return not not self:GetPlayer(name)
end

local conds = {
    -- adjectives
    alt     = function(self) return self:IsAlt() end,
    main    = function(self) return self:IsMain() end,
    all     = function(self) return self:IsInRaid() or self:IsStandBy() end,
    guild   = function(self) return true end,
    name    = function(self, cond) return self.name == cond end,
    officer = function(self) return self:IsOfficer() end,
    online  = function(self) return self.on end,
    raid    = function(self) return (self:GetRaidSubgroup() or 6) <= 5 end,
    standby = function(self) return self:IsStandBy() end,

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

function sDKP:Select(who)
    local list = new()

    for set in who:gmatch("[^,]+") do -- split who by commas into sets
        for name, char in self:GetChars() do -- for every character
            if not list[name] then -- check if already matches
                local flag = true -- assume a match

                for cond in set:gmatch("%S+") do -- split set by whitespace into conds
                    if flag then
                        flag = (conds[cond] or conds.name)(char, cond)
                    end
                end

                if flag then
                    list[name] = true
                end
            end
        end
    end

    return list, count(list)
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
    if GetNumGuildMembers() < 1 then return end

    local roster = new()
    local diff = self:Get("core.diff")

    for i = 1, GetNumGuildMembers() do
        roster[GetGuildRosterInfo(i)] = true
    end

    for name, char in self:GetChars() do
        if roster[name] then
            self:BindClass(char, "Character")
        else -- not in roster
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

--- Discards all pending changes to player data.
-- @return number - Discarded count.
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
-- @return number - Queued changes count.
function sDKP:Store()
    local count = 0

    for name, char in self:GetChars() do
        if char.new then
            self:QueueAdd(name, char)
            count = count + 1
        end
    end

    self:QueueActivate()

    return count
end

--- Updates roster data.
function sDKP:Update()
    local diff = self:Get("core.diff")

    for i = 1, GetNumGuildMembers() do
        local name, rank, rankId, level, _, zone,
            pnote, onote, online, status, class = GetGuildRosterInfo(i)

        if not name then return end -- prevent nil errors despite GuildRoster()

        local char, new = self:GetCharacter(name)
        if not char then char, new = self:BindClass(nil, "Character") end

        char:OnUpdate(i, name, rank, rankId, level, _, zone,
            pnote, onote, online, status, class, diff)

        if new then
            Roster[name] = char
            if diff then self:Printf("<%s> |cff33ff33+%s|r", self.guild, name) end
        end
    end
end
