--------------------------------------------------------------------------------
--  sDKP Stat (c) 2012 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local Util = sDKP.Util

local gsub = gsub
local match = string.match
local max = max
local min = min
local select = select
local tonumber = tonumber
local trim = string.trim
local upper = string.upper

-- Util
local data = { }
local function clear() for k, _ in pairs(data) do data[k] = nil end end

function sDKP:StatTopQuery(param)
    local param, chan = Util.ExtractChannel(param, "SELF")
    param, gsubcount = gsub(param, "tot", "")
    local mode = gsubcount >= 1
    local count = tonumber(match(param, "%d+")) or 5
    param = gsub(param, "%d+", "")
    local class = trim(param)
    local classU = upper(class)

    local maxD = 0
    local minD = 0
    local val

    for n, d in pairs(self.Roster) do
        if not d.main and (classU == "" or d.class == classU) then
            val = mode and d.tot or d.net
            maxD = max(maxD, val)
            minD = min(minD, val)
            data[val] = n
        end
    end

    local c = 0
    local m = mode and "tot" or "net"
    self:Announce(chan, "Top %d %s ranking%s:", count, m, class ~= "" and format(" for class %s", class) or "")
    for i = maxD, minD, -1 do
        if data[i] then
            c = c + 1
            self:Announce(chan, " %d. %s %d DKP", c, Util.ClassColoredPlayerName(data[i]), i)
            if c >= count then clear() return end
        end
    end

    clear()
end

--- Prints: Guild <%s>: %d members, %d mains, %d alts.
function sDKP:StatGeneralInfo(param)
    local param, chan = Util.ExtractChannel(param, "SELF")

    local mains         = 0
    local mainsonline   = 0
    local alts          = 0
    local altsonline    = 0

    for name, d in pairs(self.Roster) do
        if not d.main then
            mains = mains + 1
            mainsonline = mainsonline + (d.on and 1 or 0)
        else
            alts = alts + 1
            altsonline = altsonline + (d.on and 1 or 0)
        end
    end

    local num = GetNumGuildMembers()
    local mainsP = mains / num * 100
    self:Announce(chan, "General information for <%s>:", self.guild)
    self:Announce(chan, "   Overall members: %d, online: %d", num, mainsonline + altsonline)
    self:Announce(chan, "   Mains: %d (%.1f%%), online: %d", mains, mainsP, mainsonline)
    self:Announce(chan, "   Alts: %d (%.1f%%), online: %d", alts, 100 - mainsP, altsonline)
end

--- Prints: Druids: %d, Hunters: %d, ...
function sDKP:StatByClass(param)
    local _, chan = Util.ExtractChannel(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, num do
        local _, _, _, _, class = GetGuildRosterInfo(i)
        data[class] = (data[class] or 0) + 1
    end

    self:Announce(chan, "Guild class breakdown:")
    for class, count in Util.PairsByKeys(data) do
        self:Announce(chan, "   %s: %d (%.1f%%)", class, count, count / num * 100)
    end

    clear()
end

--- Prints: Guild level range: 70: %d, 68: %d, ...
function sDKP:StatByLevel(param)
    local param, chan = Util.ExtractChannel(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, num do
        local _, _, _, level = GetGuildRosterInfo(i)
        data[level] = (data[level] or 0) + 1
    end

    self:Announce(chan, "Guild level breakdown:")
    for i = 70, 1, -1 do
        if data[i] then
            self:Announce(chan, "   Level %d: %d (%.1f%%)", i, data[i], data[i] / num * 100)
        end
    end

    clear()
end

--- Prints: GM: %d, Vice GM: %d, ...
function sDKP:StatByRank(param)
    local param, chan = Util.ExtractChannel(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, GuildControlGetNumRanks() do data[i] = 0 end

    for i = 1, num do
        local _, _, rankId = GetGuildRosterInfo(i)
        rankId = rankId + 1
        data[rankId] = data[rankId] + 1
    end

    self:Announce(chan, "Guild rank breakdown:")
    for rank, count in ipairs(data) do
        self:Announce(chan, "   %s: %d (%.1f%%)", GuildControlGetRankName(rank), count, count / num * 100)
    end

    clear()
end

--- Prints: Shattrath City: %d, Black Temple: %d, ...
function sDKP:StatByZone(param)
    local param, chan = Util.ExtractChannel(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, num do
        local _, _, _, _, _, zone = GetGuildRosterInfo(i)
        data[zone] = (data[zone] or 0) + 1
    end

    self:Announce(chan, "Guild zone breakdown:")
    for zone, count in Util.PairsByKeys(data) do
        self:Announce(chan, "   %s: %d (%.1f%%)", zone, count, count / num * 100)
    end

    clear()
end

local specs = {
    D   = "Melee",
    H   = "Healer",
    L   = "Leveling",
    RD  = "Ranged",
    T   = "Tank",
}

function sDKP:StatBySpec(param)
    local _, chan = Util.ExtractChannel(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, num do
        local name, _, _, _, _, _, note = GetGuildRosterInfo(i)
        for spec in (note:match("%[(.-)%]") or ""):gmatch("%w+") do
            spec = spec:upper()
            data[spec] = (data[spec] or 0) + 1
        end
    end

    self:Announce(chan, "Guild specialization breakdown:")
    for spec, count in Util.PairsByKeys(data) do
        sDKP:Announce(chan, "   %s: %d", specs[spec] or UNKNOWN, count)
    end

    clear()
end

function sDKP:StatBySpent(param)
    local param, chan = Util.ExtractChannel(param, "SELF")
    local count = tonumber(param:match("%d+") or 5)

    self:Announce(chan, "Top %d spent DKP ranking", count)

    local spent
    for name, info in pairs(self.Roster) do
        spent = info.tot - info.net
        if spent > 0 then
            tinsert(data, format("%s %d", Util.ClassColoredPlayerName(name), spent))
        end
    end

    sort(data, function(a, b) return a:match("%d+$") < b:match("%d+$") end)

    for i, info in ipairs(data) do
        self:Announce(chan, "   %d. %s", i, info)
        if i >= count then return clear() end
    end

    clear()
end

--[[
function sDKP:StatByNetto()     -- net DKP ranking
function sDKP:StatByProf()      -- Blacksmiths: %d, Jewelcrafters: %d, ...
function sDKP:StatBySpec()      -- Tanks: %d (%d online), Healers: %d (%d online), Ranged: %d (%d online), Melee: %d (%d online)
function sDKP:StatByTotal()     -- total DKP ranking
--]]

--- Guild Who-Like utility.
-- Similar to /who command with some slight differences.
function sDKP:StatWho(param)
    if param:lower() == "help" then
        self:Print("Guild Who List: Usage")
        self:Echo("/sdkp who [n-Name] [r-MinRank[-MaxRank]] [R-RankName] [l-MinLvl[-MaxLvl]] [c-Class] [z-Zone] [N-PlayerNote] [o-OfficerNote] [online] [raid]")
        self:Echo("   All string lookups are treated as string parts. They also use Lua pattern matching mechanisms so characters ^$()%%.[]*+-? need to be escaped: %%., %%%%, %%* etc.")
        return
    end

    local param, chan = Util.ExtractChannel(param, "SELF")

    local _name = param:match('n%-"([^"]+)"') or param:match('n%-(%w+)')
    local _minrank, _maxrank = param:match("r%-(%d+)%-?(%d*)")
    local _rankname = param:match('R%-"([^"]+)"') or param:match('R%-(%S+)')
    local _minlvl, _maxlvl = param:match("l%-(%d+)%-?(%d*)")
    local _class = param:match('c%-(%w+)')
    local _zone = param:match('z%-"([^"]+)"') or param:match("z%-(%w+)")
    local _note = param:match('N%-"([^"]+)"') or param:match("N%-(%S+)")
    local _onote = param:match('[Oo]%-"([^"]+)"') or param:match("[Oo]%-(%S+)")
    local _online = param:match('online')
    local _inraid = param:match('raid')

    self:Announce(chan, "Guild Who List: %s", param)

    _minrank = tonumber(_minrank)
    _maxrank = tonumber(_maxrank) or _minrank

    _minlvl = tonumber(_minlvl)
    _maxlvl = tonumber(_maxlvl) or _minlvl

    if _minrank and _minrank > _maxrank then _minrank, _maxrank = _maxrank, _minrank end
    if _minlvl and _minlvl > _maxlvl then _minlvl, _maxlvl = _maxlvl, _minlvl end

    local count = 0

    for i = 1, GetNumGuildMembers() do
        local name, rankname, rank, level, class, zone, note, onote, online = GetGuildRosterInfo(i)

        if not _name or name:lower():match(_name) then
            if not _minrank or rank >= _minrank then
                if not _maxrank or rank <= _maxrank then
                    if not _rankname or rankname:lower():match(_rankname) then
                        if not _minlvl or level >= _minlvl then
                            if not _maxlvl or level <= _maxlvl then
                                if not _class or class:lower():match(_class) then
                                    if not _zone or zone:lower():match(_zone) then
                                        if not _note or note:match(_note) then
                                            if not _onote or onote:match(_onote) then
                                                if not _online or online then
                                                    if not _inraid or UnitInRaid(name) then
                                                        count = count + 1
                                                        self:Announce(chan, "   %s%s - Lvl %d %s (%s) - %s", (chan == "SELF" and "|Hplayer:%1$s|h[%1$s]|h" or "[%s]"):format(name), UnitInRaid(name) and " |cFFFFA500<RAID>|r" or "", level, class, rankname, zone)

                                                        if _note and note then
                                                            self:Announce(chan, "   Player note: |cff00ff00%q|r", note)
                                                        end

                                                        if _onote and onote then
                                                            self:Announce(chan, "   Officer note: |cff00ffff%q|r", onote)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    self:Announce(chan, "Total characters: %d", count)
end

sDKP.Slash.args.stat = {
    name = "Stat",
    desc = "Statistics module functions.",
    type = "group",
    args = {
        class = {
            name = "By class",
            desc = "Displays class breakdown.",
            type = "execute",
            func = "StatByClass"
        },
        guild = {
            name = "Guild",
            desc = "Displays overall, main and alt counts.",
            type = "execute",
            func = "StatGeneralInfo"
        },
        level = {
            name = "By level",
            desc = "Displays level breakdown.",
            type = "execute",
            func = "StatByLevel"
        },
        rank = {
            name = "By rank",
            desc = "Displays rank breakdown.",
            type = "execute",
            func = "StatByRank"
        },
        spec = {
            name = "By specialization",
            desc = "Displays specialization breakdown.",
            type = "execute",
            func = "StatBySpec"
        },
        spent = {
            name = "By spent DKP",
            desc = "Displays spent DKP breakdown.",
            type = "execute",
            func = "StatBySpent"
        },
        top = {
            name = "Top",
            desc = "Prints total or netto DKP ranking for all or only given class.",
            type = "execute",
            usage = "<count> [tot] [<class>]",
            func = "StatTopQuery"
        },
        zone = {
            name = "By zone",
            desc = "Displays zone breakdown.",
            type = "execute",
            func = "StatByZone"
        }
    }
}

sDKP.Slash.args.who = {
    name = "Who",
    desc = "Who-like utility for current guild.",
    usage = "help || <query>",
    type = "execute",
    func = "StatWho"
}

sDKP.Modules.Stats = GetTime()
