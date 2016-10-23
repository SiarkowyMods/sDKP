--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local dectohex = sDKP.DecimalToHexColor
local dispose = sDKP.dispose
local extract = sDKP.ExtractChannel
local gsub = gsub
local match = string.match
local max = max
local min = min
local new = sDKP.table
local select = select
local tonumber = tonumber
local trim = string.trim
local upper = string.upper

-- Utils
local data = { }
local function clear() for k, _ in pairs(data) do data[k] = nil end end

--- Displays net DKP ranking.
-- @param param (string) Optional player query or channel redirection string.
function sDKP:StatTopQuery(param)
    local chan
    param, chan = extract(param, "SELF")
    local count = tonumber(param:match("^%d+") or "") or 5
    param = gsub(param, "^%d+", ""):trim()
    param = param ~= "" and param or "main"

    for _, unit in pairs(self:Select(param)) do
        tinsert(data, unit)
    end

    sort(data, function(a, b)
        return self:GetCharacter(a):GetMain().net > self:GetCharacter(b):GetMain().net
    end)

    self:Announce(chan, "Top %d %s DKP ranking:", count, param)
    for i, name in ipairs(data) do
        if i > count then
            break
        end
        self:Announce(chan, " %d. %s %d DKP", i, self.ClassColoredPlayerName(name), self:GetCharacter(name):GetMain().net)
    end

    clear()
end

--- Displays total DKP ranking.
-- @param param (string) Optional channel redirection string.
function sDKP:StatByTotal(param)
    local chan
    param, chan = extract(param, "SELF")
    local count = tonumber(param:match("^%d+") or "") or 5
    param = gsub(param, "^%d+", ""):trim()

    for _, unit in pairs(self:Select("mains")) do
        tinsert(data, unit)
    end

    sort(data, function(a, b)
        return self:GetCharacter(a):GetMain().tot > self:GetCharacter(b):GetMain().tot
    end)

    self:Announce(chan, "Top %d total DKP ranking:", count)
    for i, name in ipairs(data) do
        if i > count then
            break
        end
        self:Announce(chan, " %d. %s %d DKP", i, self.ClassColoredPlayerName(name), self:GetCharacter(name):GetMain().tot)
    end

    clear()
end

--- Displays general information about guild's members, mains and alts.
-- @param param (string) Optional channel redirection string.
function sDKP:StatGeneralInfo(param)
    local param, chan = extract(param, "SELF")

    local mains         = 0
    local mainsonline   = 0
    local alts          = 0
    local altsonline    = 0

    for _, char in self:GetChars() do
        if not char:IsExternal() then
            if char:IsMain() then
                mains = mains + 1
                mainsonline = mainsonline + (char.on and 1 or 0)
            else
                alts = alts + 1
                altsonline = altsonline + (char.on and 1 or 0)
            end
        end
    end

    local num = GetNumGuildMembers()
    local mainsP = mains / num * 100
    self:Announce(chan, "General information for <%s>:", self.guild)
    self:Announce(chan, "   Overall members: %d, online: %d", num, mainsonline + altsonline)
    self:Announce(chan, "   Mains: %d (%.1f%%), online: %d", mains, mainsP, mainsonline)
    self:Announce(chan, "   Alts: %d (%.1f%%), online: %d", alts, 100 - mainsP, altsonline)
end

--- Displays member class breakdown.
-- @param param (string) Optional channel redirection string.
function sDKP:StatByClass(param)
    local _, chan = extract(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, num do
        local _, _, _, _, class = GetGuildRosterInfo(i)
        data[class] = (data[class] or 0) + 1
    end

    self:Announce(chan, "Guild class breakdown:")
    for class, count in self.PairsByKeys(data) do
        local c = RAID_CLASS_COLORS[class:upper()]
        self:Announce(chan, "   %s%s|r: %d (%.1f%%)",
            dectohex(c.r, c.g, c.b), class, count, count / num * 100)
    end

    clear()
end

--- Displays member level breakdown.
-- @param param (string) Optional channel redirection string.
function sDKP:StatByLevel(param)
    local param, chan = extract(param, "SELF")
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

--- Displays member rank breakdown.
-- @param param (string) Optional channel redirection string.
function sDKP:StatByRank(param)
    local param, chan = extract(param, "SELF")
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

--- Displays member zone breakdown.
-- @param param (string) Optional channel redirection string.
function sDKP:StatByZone(param)
    local param, chan = extract(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, num do
        local _, _, _, _, _, zone = GetGuildRosterInfo(i)
        data[zone] = (data[zone] or 0) + 1
    end

    self:Announce(chan, "Guild zone breakdown:")
    for zone, count in self.PairsByKeys(data) do
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

    EXP = "Leveling",
    MDPS = "Melee",
    RDPS = "Ranged",
}

--- Displays member specialization breakdown.
-- @param param (string) Optional channel redirection string.
function sDKP:StatBySpec(param)
    local _, chan = extract(param, "SELF")
    local num = GetNumGuildMembers()

    for i = 1, num do
        local name, _, _, _, _, _, note = GetGuildRosterInfo(i)
        for spec in (note:match("%[(.-)%]") or ""):gmatch("%w+") do
            spec = spec:upper()
            data[spec] = (data[spec] or 0) + 1
        end
    end

    self:Announce(chan, "Guild specialization breakdown:")
    for spec, count in self.PairsByKeys(data) do
        self:Announce(chan, "   %s: %d", specs[spec] or UNKNOWN, count)
    end

    clear()
end

--- Displays spent DKP breakdown.
-- @param param (string) Optional player query or channel redirection string.
function sDKP:StatBySpent(param)
    local chan
    param, chan = extract(param, "SELF")
    local count = tonumber(param:match("^%d+") or "") or 5
    param = gsub(param, "^%d+", ""):trim()
    param = param ~= "" and param or "main"

    for _, unit in pairs(self:Select(param)) do
        tinsert(data, unit)
    end

    sort(data, function(a, b)
        a = self:GetCharacter(a):GetMain()
        b = self:GetCharacter(b):GetMain()
        return a.tot - a.net > b.tot - b.net
    end)

    self:Announce(chan, "Top %d %s spent DKP ranking:", count, param)
    for i, name in ipairs(data) do
        if i > count then
            break
        end
        local char = self:GetCharacter(name):GetMain()
        local spent = char.tot - char.net
        self:Announce(chan, " %d. %s %d DKP", i, self.ClassColoredPlayerName(name), spent)
    end

    clear()
end

--- Guild Who-Like utility. Similar in principle to /who command.
-- @param param (string) Who query string. Described in usage string.
function sDKP:StatWho(param)
    if param == "" or param:lower() == "help" then
        self:Print("Guild Who List: Usage")
        self:Echo("   /sdkp who [n-|cFFFFA500Name|r] [c-|cFFFFA500Class|r] " ..
        "[z-|cFFFFA500Zone|r] [N-|cFFFFA500PlayerNote|r] " ..
        "[O-|cFFFFA500OfficerNote|r] [R-|cFFFFA500RankName|r] " ..
        "[lvl-|cFFFFA500Level|r || |cFFFFA500min|r<lvl<|cFFFFA500max|r] " ..
        "[rank-|cFFFFA500RankId|r || |cFFFFA500min|r<rank<|cFFFFA500max|r] " ..
        "[|cFFFFA500min|r<net<|cFFFFA500max|r] " ..
        "[|cFFFFA500min|r<tot<|cFFFFA500max|r] " ..
        "[|cFFFFA500min|r<hrs<|cFFFFA500max|r] " ..
        "[online] [raid] [main || alt]")
        self:Echo("   All string lookups are treated as string parts. They also use Lua pattern matching mechanisms so characters ^$()%%.[]*+-? need to be escaped: %%., %%%%, %%* etc.")
        return
    end

    local param, chan = extract(param, "SELF")

    -- strings
    local _name     = param:match('n%-"([^"]+)"') or param:match('n%-(%S+)')
    local _zone     = param:match('z%-"([^"]+)"') or param:match("z%-(%S+)")
    local _note     = param:match('N%-"([^"]+)"') or param:match("N%-(%S+)")
    local _onote    = param:match('O%-"([^"]+)"') or param:match("O%-(%S+)")
    local _rankname = param:match('R%-"([^"]+)"') or param:match('R%-(%S+)')
    local _class    = param:match('c%-(%S+)')

    -- booleans
    local _online = not not param:match('online')
    local _raid   = not not param:match('raid')
    local _main   = not not param:match('main')
    local _alt    = not not param:match('alt')

    -- decimals
    local _lvl    = tonumber(param:match('lvl%-(%d+)'))
    local _rnk    = tonumber(param:match('rank%-(%d+)'))

    -- possible relative
    local _maxLvl = _lvl or tonumber(param:match('lvl<(%d+)'))
    local _minLvl = _lvl or tonumber(param:match('lvl>(%d+)') or param:match('(%d+)<lvl'))
    local _maxRnk = _rnk or tonumber(param:match('rank<(%d+)'))
    local _minRnk = _rnk or tonumber(param:match('rank>(%d+)') or param:match('(%d+)<rank'))

    -- relative-only
    local _maxNet = tonumber(param:match('net<(%d+)'))
    local _minNet = tonumber(param:match('net>(%d+)') or param:match('(%d+)<net'))
    local _maxTot = tonumber(param:match('tot<(%d+)'))
    local _minTot = tonumber(param:match('tot>(%d+)') or param:match('(%d+)<tot'))
    local _maxHrs = tonumber(param:match('hrs<(%d+)'))
    local _minHrs = tonumber(param:match('hrs>(%d+)') or param:match('(%d+)<hrs'))

    -- check order of min/max values
    if _minRnk and _maxRnk and _minRnk > _maxRnk then _minRnk, _maxRnk = _maxRnk, _minRnk end
    if _minLvl and _maxLvl and _minLvl > _maxLvl then _minLvl, _maxLvl = _maxLvl, _minLvl end
    if _minNet and _maxNet and _minNet > _maxNet then _minNet, _maxNet = _maxNet, _minNet end
    if _minTot and _maxTot and _minTot > _maxTot then _minTot, _maxTot = _maxTot, _minTot end
    if _minHrs and _maxHrs and _minHrs > _maxHrs then _minHrs, _maxHrs = _maxHrs, _minHrs end

    local dkp = _minNet or _maxNet or _minTot or _maxTot or _minHrs or _maxHrs
    local count = 0

    self:Announce(chan, "Guild Who List: %s", param)

    for i = 1, GetNumGuildMembers() do
        local name, rankname, rnk, lvl, class, zone, note, onote, online = GetGuildRosterInfo(i)
        local alt, net, tot, hrs = self:ParseOfficerNote(onote)

        if (not _name or name:lower():match(_name:lower()))
            and (not _zone or zone:lower():match(_zone:lower()))
            and (not _note or note:match(_note))
            and (not _onote or onote:match(_onote))
            and (not _rankname or rankname:lower():match(_rankname:lower()))
            and (not _class or class:lower():match(_class:lower()))
            and (not _online or online)
            and (not _raid or UnitInRaid(name))
            and (not _main or not alt)
            and (not _alt or alt)
            and (not _minLvl or lvl >= _minLvl)
            and (not _maxLvl or lvl <= _maxLvl)
            and (not _minRnk or rnk >= _minRnk)
            and (not _maxRnk or rnk <= _maxRnk)
            and (not _minNet or net >= _minNet)
            and (not _maxNet or net <= _maxNet)
            and (not _minTot or tot >= _minTot)
            and (not _maxTot or tot <= _maxTot)
            and (not _minHrs or hrs >= _minHrs)
            and (not _maxHrs or hrs <= _maxHrs)
        then
            count = count + 1
            self:Announce(chan, "   %s%s - Lvl %d %s (%s) - %s",
                chan == "SELF" and format("|Hplayer:%1$s|h[%1$s]|h", name) or self.ClassColoredPlayerName(name),
                UnitInRaid(name) and " |cFFFFA500<RAID>|r" or "", lvl, class, rankname,
                dkp and format("DKP %d/%d/%d", net, tot, hrs) or zone)

            if _note and note then
                self:Announce(chan, "   Player note: |cff00ff00%q|r", note)
            end

            if _onote and onote then
                self:Announce(chan, "   Officer note: |cff00ffff%q|r", onote)
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
            desc = "Displays net DKP ranking. Accepts optional player query.",
            type = "execute",
            usage = "[<count>] [<query>]",
            func = "StatTopQuery"
        },
        total = {
            name = "Total",
            desc = "Displays total DKP ranking.",
            type = "execute",
            usage = "[<count>]",
            func = "StatByTotal"
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
    desc = "Who-like utility for the guild.",
    usage = "help||<query>[ @channel]",
    type = "execute",
    func = "StatWho"
}
