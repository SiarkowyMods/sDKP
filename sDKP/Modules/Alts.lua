--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local format = format
local gsub = gsub
local match = string.match
local select = select
local sub = string.sub
local trim = string.trim
local GetGuildRosterInfo = GetGuildRosterInfo
local GuildRosterSetOfficerNote = GuildRosterSetOfficerNote

--- Clears alt status from given player.
-- @param name Player to clear alt status from.
-- @return boolean - success flag.
function sDKP:ClearAlt(name)
    if not name or not self.Roster[name] then
        return
    end

    local d = self.Roster[name]
    d.new = nil
    GuildRosterSetOfficerNote(d.id, trim(sub(gsub(select(8, GetGuildRosterInfo(d.id)), "{%S+}", ""), 1, 31)))
    return true
end

--- Sets alt status for given player.
-- @param alt Alt character name.
-- @param main Main character name.
-- @return boolean - success flag.
function sDKP:SetAlt(alt, main)
    if not alt or not main or not self.Roster[alt] or not self.Roster[main] then
        return
    end

    local d = self.Roster[alt]
    d.new = nil
    GuildRosterSetOfficerNote(d.id, trim(sub(format("{%s}%s", main, gsub(select(8, GetGuildRosterInfo(d.id)), "{.-}","")), 1, 31)))
    return true
end

--- Swaps player's main between his alts.
-- @param oldmain Old main.
-- @param newmain New main.
-- @return boolean - success flag.
function sDKP:SwapAlts(oldmain, newmain)
    if not oldmain or not newmain or not self.Roster[oldmain] or not self.Roster[newmain] then
        return
    end

    local oldmainmatch = format("{%s}", oldmain)
    local newmainmatch = format("{%s}", newmain)
    local oldmainid = 0
    local newmainid = 0

    for i = 1, GetNumGuildMembers() do
        local n, _, _, _, _, _, _, o = GetGuildRosterInfo(i)
        if match(o, oldmainmatch) then
            GuildRosterSetOfficerNote(i, sub(trim(gsub(select(8, GetGuildRosterInfo(i)), oldmainmatch, newmainmatch)), 1, 31))
        end
        if n == oldmain then
            oldmainid = i
        elseif n == newmain then
            newmainid = i
        end
    end

    assert(oldmainid > 0)
    assert(newmainid > 0)

    GuildRosterSetOfficerNote(newmainid, sub(trim(gsub(select(8, GetGuildRosterInfo(newmainid)), "{.-}", match(select(8, GetGuildRosterInfo(oldmainid)), "{.-}") or "")), 1, 31))
    GuildRosterSetOfficerNote(oldmainid, sub(trim(format("{%s}%s", newmain, gsub(select(8, GetGuildRosterInfo(oldmainid)), "{.-}",""))), 1, 31))

    return true
end

sDKP.Slash.args.alt = {
    type = "group",
    name = "Alt",
    desc = "Alts management functions.",
    args = {
        clear = {
            name = "Clear",
            desc = "Clear alt status form character.",
            type = "execute",
            usage = "<player>",
            func = function(self, name)
                self:ClearAlt(name ~= "" and name)
            end
        },
        set = {
            name = "Set",
            desc = "Set alt status.",
            type = "execute",
            usage = "<alt> <main>",
            func = function(self, param)
                local alt, main = match(param, "(%S+)%s*(%S+)")
                self:SetAlt(alt, main)
            end
        },
        swap = {
            name = "Swap",
            desc = "Swap player's main character and point all alts to this character.",
            type = "execute",
            usage = "<oldmain> <newmain>",
            func = function(self, param)
                local oldmain, newmain = match(param, "(%S+)%s*(%S+)")
                self:SwapAlts(oldmain, newmain)
            end
        },
    }
}

sDKP.Modules.Alts = GetTime()
