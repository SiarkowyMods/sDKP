--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local GetRaidRosterInfo = GetRaidRosterInfo
local UnitInRaid = UnitInRaid
local colorize_diff = sDKP.DiffColorize
local colorize_unit = sDKP.ClassColoredPlayerName
local dec2hex = sDKP.DecimalToHexColor
local dispose = sDKP.dispose
local getmetatable = getmetatable
local new = sDKP.table
local parse = sDKP.ParseOfficerNote
local select = select
local setmetatable = setmetatable
local tonumber = tonumber

local LOG_DKP_MODIFY = 1
local LOG_DKP_DIFF = 8

--- Character object prototype.
local Character = { --[[
    -- General:
    id    = number,     -- Guild roster ID number.
    name  = string,     -- Character name.
    class = string,     -- Character class.
    on    = boolean,    -- Online flag.
    altof = nil|string, -- Main character reference if any.
    new   = boolean,    -- Data update flag for Store().
    iron  = boolean,    -- Ironman flag.
    stby  = boolean,    -- Standby flag.

    -- DKP values:
    net = number,       -- Netto DKP value.
    tot = number,       -- Total DKP value.
    hrs = number,       -- Hour counter.
    netD = number|nil,  -- Netto delta value.
    totD = number|nil,  -- Total delta value.
    hrsD = number|nil,  -- Hour counter delta.
]] }

-- Metatable for object<-->class binding.
Character.__meta = { __index = Character }

Character.Echo   = sDKP.Echo
Character.Print  = sDKP.Print
Character.Printf = sDKP.Printf

function Character:GetColoredName()
    local c = RAID_CLASS_COLORS[self.class]
    return format("%s%s|r", dec2hex(c.r, c.g, c.b), self.name)
end

function Character:GetMain()
    return self.altof and sDKP(self.altof) or self
end

--- Returns character data in officer note format.
-- @param fmt (string) Officer note format.
-- @return string - Formatted note data.
function Character:GetNote(fmt)
    local data = new()

    if self.altof then
        return format("{%s}", self.altof)
    end

    data.d = date("%d")
    data.m = date("%m")
    data.Y = date("%Y")

    data.n = (tonumber(self.net) or 0) + (tonumber(self.netD) or 0)
    data.t = (tonumber(self.tot) or 0) + (tonumber(self.totD) or 0)
    data.h = (tonumber(self.hrs) or 0) + (tonumber(self.hrsD) or 0)

    local note = gsub(fmt, "%%(.)", data)
    dispose(data)
    return format("{%s}", note)
end

function Character:GetOwnerOnline()
    return self.on and self.name or sDKP:GetOwnerOnline(self.altof or self.name)
end

function Character:GetPoints()
    return self.net, self.tot, self.hrs
end

function Character:GetRaidSubgroup()
    return UnitInRaid(self.name)
       and select(3, GetRaidRosterInfo(UnitInRaid(self.name) + 1))
end

function Character:GetZone()
    return select(6, GetGuildRosterInfo(self.id))
end

function Character:IsAlt()
    return self.altof
end

function Character:IsInParty()
    return UnitInParty(self.name) and (GetNumPartyMembers() > 0 or UnitInRaid(self.name))
end

function Character:IsInRaid()
    return UnitInRaid(self.name)
end

function Character:IsInRaidSubgroup(group)
    return self:GetRaidSubgroup() == group
end

function Character:IsIronMan()
    return self.iron
end

function Character:IsMain()
    return not self.altof
end

function Character:IsOfficer()
    GuildControlSetRank(select(3, GetGuildRosterInfo(self.id)) + 1)
    return (select(12, GuildControlGetRankFlags()))
end

function Character:IsStandBy()
    if self:IsInRaid() then
        return (self:GetRaidSubgroup() or 0) > 5
    else
        return self.stby
    end
end

function Character:SetIronMan(flag)
    if self.altof then self = self:GetMain() end
    self.iron = flag and true or nil
end

function Character:SetStandBy(flag)
    self.stby = flag and true or nil
end

-- Event handlers --------------------------------------------------------------

--- Handles logging and displaying of DKP differences.
-- @param oldNet (number) Old netto DKP.
-- @param oldTot (number) Old total DKP.
-- @param oldHrs (number) Old hour count.
-- @param show (boolean) If true, displays the difference to chat frame.
function Character:OnDiff(oldNet, oldTot, oldHrs, show)
    if self.net ~= oldNet or self.tot ~= oldTot or self.hrs ~= oldHrs then
        local netDiff = self.net - oldNet
        local totDiff = self.tot - oldTot
        local hrsDiff = self.hrs - oldHrs

        -- log the difference
        sDKP:Log(LOG_DKP_DIFF, self.name, netDiff, totDiff, hrsDiff,
            self.net, self.tot, self.hrs)

        -- show to chat frame if the option is set
        if show then
            self:Printf("Change: %s %s%+d net|r, %s%+d tot|r, %s%+d hrs|r",
                self:GetColoredName(),
                colorize_diff(netDiff), netDiff,
                colorize_diff(totDiff), totDiff,
                colorize_diff(hrsDiff), hrsDiff)
        end
    end
end

function Character:OnUpdate(id, name, _, _, _, _, _, _, o, on, _, class, diff)
    local net, tot, hrs = self.net, self.tot, self.hrs
    self.id, self.name, self.on, self.class = id, name, on, class
    self.altof, self.net, self.tot, self.hrs = parse(o)
    if net and tot and hrs then
        self:OnDiff(net, tot, hrs, diff)
    end
end

-- Methods ---------------------------------------------------------------------

--- Awards character DKP.
-- @param pts (number) Amount to award.
-- @param reason (string) Optional reason string.
-- @return table - Main character object.
function Character:Award(pts, reason)
    sDKP:Log(LOG_DKP_MODIFY, self.name, pts, reason ~= "" and reason or nil)
    return self:Modify(pts, pts, 0)
end

--- Charges character DKP.
-- @param pts (number) Amount to charge.
-- @param reason (string) Optional reason string.
-- @return table - Main character object.
function Character:Charge(pts, reason)
    sDKP:Log(LOG_DKP_MODIFY, self.name, -pts, reason ~= "" and reason or nil)
    return self:Modify(-pts, 0, 0)
end

--- Modifies character relative DKP amounts for future storage.
-- @param netD (number) Net delta, defaults to 0.
-- @param totD (number) Total delta, defaults to 0.
-- @param hrsD (number) Hour count delta, defaults to 0.
-- @return table - Main character object.
function Character:Modify(netD, totD, hrsD)
    if self.altof then self = self:GetMain() end

    netD = tonumber(netD) or 0
    totD = tonumber(totD) or 0
    hrsD = tonumber(hrsD) or 0

    self.netD = (tonumber(self.netD) or 0) + netD
    self.totD = (tonumber(self.totD) or 0) + totD
    self.hrsD = (tonumber(self.hrsD) or 0) + hrsD

    self.new = netD ~= 0 or totD ~= 0 or hrsD ~= 0

    return self
end

--- Sets character absolute DKP amounts for immediate storage.
-- This values will be overwritten on next GUILD_ROSTER_UPDATE!
-- @param net (number) Net amount, defaults to current netto DKP.
-- @param tot (number) Total amount, defaults to current total DKP.
-- @param hrs (number) Hours count, defaults to current hour count.
-- @return table - Main character object.
function Character:Set(net, tot, hrs)
    if self.altof then self = self:GetMain() end

    self.net  = tonumber(net) or self.net
    self.tot  = tonumber(tot) or self.tot
    self.hrs  = tonumber(hrs) or self.hrs

    self.netD = nil
    self.totD = nil
    self.hrsD = nil

    self.new = true

    return self
end

--- Discards pending modifications.
-- @return boolean - Success flag.
function Character:Discard()
    if self.altof then self = self:GetMain() end

    if not self.new then
        return false
    end

    self.netD = nil
    self.totD = nil
    self.hrsD = nil

    self.new = nil

    return true
end

--- Stores pending modifications to officer note.
function Character:Store(nodiscard, quiet)
    local fmt = sDKP:Get("core.format")
    local old = select(8, GetGuildRosterInfo(self.id))
    local new = ("%s%s")
        :format(self:GetNote(fmt), old:gsub("{.-}", ""))
        :trim()
        :sub(1, 31)

    if not quiet and sDKP:Get("whisper.toggle") then
        sDKP:SendWhisper(self:GetOwnerOnline(), format(sDKP:Get("whisper.modify"),
            self.net + (self.netD or 0), self.tot + (self.totD or 0), self.netD or 0))
    end

    if not nodiscard then
        self:Discard()
    end

    if new ~= old then
        GuildRosterSetOfficerNote(self.id, new)
        return true
    end

    return false
end

-- Expose to class registry
sDKP.Class.Character = Character
