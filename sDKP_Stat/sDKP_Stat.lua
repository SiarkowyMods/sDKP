--------------------------------------------------------------------------------
--	sDKP Stat (c) 2012 by Siarkowy
--	Released under the terms of GNU GPL v3 license.
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
	self:Announce(chan, "Top %d %s%s:", count, m, class ~= "" and format(" for class %s", class) or "")
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
	local _, chan = Util.ExtractChannel(param, "SELF")

	local mains			= 0
	local mainsonline	= 0
	local alts			= 0
	local altsonline	= 0

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
	self:Announce(chan, "<%s> guild information:", self.guild)
	self:Announce(chan, " ~ overall members: %d, online: %d", num, mainsonline + altsonline)
	self:Announce(chan, " ~ mains: %d (%.2f%%), online: %d", mains, mainsP, mainsonline)
	self:Announce(chan, " ~ alts: %d (%.2f%%), online: %d", alts, 100 - mainsP, altsonline)
end

--- Prints: Druids: %d, Hunters: %d, ...
function sDKP:StatByClass(param)
	local _, chan = Util.ExtractChannel(param, "SELF")
	local num = GetNumGuildMembers()

	for i = 1, num do
		local _, _, _, _, class = GetGuildRosterInfo(i)
		data[class] = data[class] and data[class] + 1 or 1
	end

	self:Announce(chan, "Guild class breakdown:")
	for class, count in Util.PairsByKeys(data) do
		self:Announce(chan, " ~ %s: %d (%.2f%%)", class, count, count / num * 100)
	end

	clear()
end

--- Prints: Guild level range: 70: %d, 68: %d, ...
function sDKP:StatByLevel(param)
	local _, chan = Util.ExtractChannel(param, "SELF")
	local num = GetNumGuildMembers()

	for i = 1, num do
		local _, _, _, level = GetGuildRosterInfo(i)
		data[level] = data[level] and data[level] + 1 or 1
	end

	self:Announce(chan, "Guild level breakdown:")
	for i = 70, 1 do
		if data[i] then
			self:Announce(chan, " ~ level %d: %d (%.2f%%)", i, data[i], data[i] / num * 100)
		end
	end

	clear()
end

--- Prints: GM: %d, Vice GM: %d, ...
function sDKP:StatByRank(param)
	local _, chan = Util.ExtractChannel(param, "SELF")
	local num = GetNumGuildMembers()

	for i = 1, GuildControlGetNumRanks() do data[i - 1] = 0 end

	for i = 1, num do
		local _, _, rankId = GetGuildRosterInfo(i)
		data[rankId] = data[rankId] + 1
	end

	self:Announce(chan, "Guild rank breakdown:")
	for rank, count in ipairs(data) do
		self:Announce(chan, " ~ %s: %d (%.2f%%)", GuildControlGetRankName(rank + 1), count, count / num * 100)
	end

	clear()
end

--- Prints: Shattrath City: %d, Black Temple: %d, ...
function sDKP:StatByZone(param)
	local _, chan = Util.ExtractChannel(param, "SELF")
	local num = GetNumGuildMembers()

	for i = 1, num do
		local _, _, _, _, _, zone = GetGuildRosterInfo(i)
		data[zone] = data[zone] and data[zone] + 1 or 1
	end

	self:Announce(chan, "Guild zone breakdown:")
	for zone, count in Util.PairsByKeys(data) do
		self:Announce(chan, " ~ %s: %d (%.2f%%)", zone, count, count / num * 100)
	end

	clear()
end

local specs = {
	D	= "Melee",
	H	= "Healer",
	L	= "Leveling",
	RD	= "Ranged",
	T	= "Tank",
}

function sDKP:StatBySpec(param)
	local _, chan = Util.ExtractChannel(param, "SELF")
	local num = GetNumGuildMembers()

	for i = 1, num do
		local name, _, _, _, _, _, note = GetGuildRosterInfo(i)
		for spec in (note:match("%[(.-)%]") or ""):gmatch("%w+") do
			spec = spec:upper()
			data[spec] = data[spec] and data[spec] + 1 or 1
		end
	end

	self:Announce(chan, "Specialization breakdown:")
	for spec, count in Util.PairsByKeys(data) do
		sDKP:Announce(chan, " ~ %s: %d", specs[spec] or UNKNOWN, count)
	end

	clear()
end

function sDKP:StatBySpent(param)
	local _, chan = Util.ExtractChannel(param, "SELF")

	local min = 0
	local max = 0
	local spent

	for name, d in pairs(self.Roster) do
		if not d.main then
			spent = d.tot - d.net
			if spent < min then min = spent end
			if spent > max then max = spent end
			data[name] = spent
		end
	end

	for name, value in pairs(data) do
		self:Echo("%s = %d", name, value)
	end

	clear()
end

--[[
function sDKP:StatByNetValues() -- net DKP ranking
function sDKP:StatByProf()      -- Blacksmiths: %d, Jewelcrafters: %d, ...
function sDKP:StatBySpec()      -- Tanks: %d (%d online), Healers: %d (%d online), Ranged: %d (%d online), Melee: %d (%d online)
function sDKP:StatByTotValues() -- total DKP ranking
function sDKP:StatRosterLookup(query)
--]]

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

sDKP.Modules.Stats = GetTime()
