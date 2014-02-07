--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local format = format
local gsub = gsub
local pairs = pairs
local tConcat = table.concat
local trim = string.trim

local LOG_IRONMAN_START     = 5
local LOG_IRONMAN_CANCEL    = 6
local LOG_IRONMAN_AWARD     = 7

local GuildControlSetRank = GuildControlSetRank
local GuildControlGetRankFlags = GuildControlGetRankFlags

local unserialize = sDKP.Util.LogUnserialize
local serialize = sDKP.Util.LogSerialize

function sDKP:IronManCheck()
    for name, d in pairs(self.Roster) do
        if d.iron then
            return true
        end
    end
end

function sDKP:IronManStart()
    if self:IronManCheck() then
        return
    end
    
    local count = 0
    for name, d in pairs(self.Roster) do
        name = self:GetMainName(name)
        if d.raid and d.on then
            self.Roster[name].iron = true
            count = count + 1
        end
    end
    self:Log(LOG_IRONMAN_START, count)
    return count
end

function sDKP:IronManStartAnn()
    if not UnitInRaid("player") then
        self:Print("You have to be in a raid group.")
        return
    end
    
    local count = self:IronManStart()
    if count then
        self:Announce(nil, "Ironman start: %d player(s) saved", count)
    else
        self:Print("Ironman could not be started. Unsaved ironman data found.")
    end
end

function sDKP:IronManAward(award)
    local n = self:Discard()
    if n > 0 then
        self:Printf("%d |4change:changes; discarded.", n)
    end
    for name, d in pairs(self.Roster) do
        name = self:GetMainName(name)
        if self.Roster[name].iron and d.raid and d.on then
            self:Modify(name, award, (award > 0) and award or 0, 0)
        end
    end
    self:IronManCancel(true)
    local count = self:Store()
    self:Log(LOG_IRONMAN_AWARD, count, award)
    return count
end

function sDKP:IronManAwardAnn(award, output)
    self:Announce(output, "Ironman bonus %+d DKP for %d player(s)", award, self:IronManAward(award))
end

function sDKP:IronManCancel(nolog)
    local count = 0
    for n, d in pairs(self.Roster) do
        if d.iron then
            d.iron = nil
            count = count + 1
        end
    end
    if not nolog then self:Log(LOG_IRONMAN_CANCEL) end
    return count
end

function sDKP:IronManCancelAnn(param)
    if not self:IronManCheck() then return end
    local output = param:match("@(%S+)")
    if output then
        param = trim(gsub(param, "@(%S+)", ""))
    end
    self:IronManCancel()
    self:Announce(output, "Ironman canceled%s", param ~= "" and ": " .. param or "")
end

function sDKP:IronManReinvite()
    if not self:IronManCheck() then
        self:Print("No ironman data found.")
        return
    end

    if not UnitInRaid("player") then
        self:Print("You have to be in a raid group.")
        return
    end

    for name, d in pairs(self.Roster) do
        if d.iron then
            if not d.raid and d.on and name ~= self.player then
                InviteUnit(name)
            else
                local alt = self:GetPlayerOnlineAlt(name)
                local a = self.Roster[alt]

                if alt and not a.raid then InviteUnit(alt) end
            end
        end
    end
end

local function wipe(t) for k, v in pairs(t) do t[k] = nil end end
local t = { }

function sDKP:IronManList()
    self:Print("Players eligible for ironman bonus:")
    local count = 0
    wipe(t)
    for name, d in pairs(self.Roster) do
        local name = self:GetMainName(name)
        if self.Roster[name].iron and d.raid and d.on then
            tinsert(t, name)
            count = count + 1
            if #t >= 5 then
                self:Echo("   " .. tConcat(t, ", "))
                wipe(t)
            end
        end
    end
    if #t >= 1 then
        self:Echo("   " .. tConcat(t, ", "))
        wipe(t)
    end
    self:Echo("Total of %d |4player:players;.", count)
end

function sDKP:IronManFetch(param)
    if not self:GetMainName(param) or not self.Roster[param].on then
        return
    end
    
    self:CommSend("IMAN", "F", "WHISPER", param)
    return true
end

function sDKP:IronManComm(data, distr, sender)
    if not self:IsOfficer(sender) then return end
    if data == "F" then
        for n, d in pairs(self.Roster) do
            if d.iron then
                self:CommSend("IMAN", n, "WHISPER", sender)
            end
        end
    elseif data ~= "" then
        local n = self:GetMainName(data)
        if n then
            self.Roster[n].iron = true
        end
    end
end

sDKP:CommRegisterHandler("IMAN", sDKP.IronManComm)

sDKP.Slash.args.ironman = {
    type = "group",
    name = "Ironman",
    desc = "Ironman functions.",
    args = {
        award = {
            name = "Award",
            desc = "Award ironman bonus to raid.",
            type = "execute",
            usage = "<points>",
            func = function(self, award)
                if not UnitInRaid("player") then
                    self:Print("You have to be in a raid group.")
                    return
                end
                
                award = tonumber(award)
                if not award then
                    self:Print("Bonus has to be a number.")
                    return
                end
                self:IronManAward(award)
            end,
            order = 1
        },
        ["award!"] = {
            name = "Award with announce",
            desc = "Award ironman bonus with announce.",
            type = "execute",
            usage = "<points>[ @<channel>]",
            func = function(self, award)
                if not UnitInRaid("player") then
                    self:Print("You have to be in a raid group.")
                    return
                end
                
                local output = award:match("@(%S+)")
                if output then
                    award = trim(gsub(award, "@(%S+)", ""))
                end
                award = tonumber(award)
                if not award then
                    self:Print("Bonus has to be a number.")
                    return
                end
                self:IronManAwardAnn(award, output)
            end,
            order = 2
        },
        cancel = {
            name = "Cancel",
            desc = "Cancel ironman bonus awarning no DKP.",
            type = "execute",
            func = function(self, param)
                if self:IronManCheck() then
                    self:IronManCancel()
                end
            end,
            order = 3
        },
        ["cancel!"] = {
            name = "Cancel with announce",
            desc = "Cancel ironman bonus with announce.",
            type = "execute",
            usage = "[<reason>]",
            func = "IronManCancelAnn",
            order = 4
        },
        exclude = {
            name = "Exclude",
            desc = "Exclude player from ironman list.",
            type = "execute",
            usage = "<player>",
            func = function(self, param)
                local n = self:GetMainName(trim(param))
                if not n then
                    self:Print("Character has to be in your guild.")
                    return
                end
                self.Roster[n].iron = nil
                self:Printf("Player %s excluded from ironman list.", n)
            end,
            order = 5
        },
        fetch = {
            name = "Fetch",
            desc = "Fetch ironman data from given player.",
            type = "execute",
            usage = "<player>",
            func = function(self, param)
                if self:IronManCheck() then
                    self:Print("You cannot request ironman data before canceling or awarding the current one.")
                    return
                end
                
                if not self:IronManFetch(param) then
                    self:Print("Player has to be in your guild and online.")
                    return
                end
                
                self:Printf("Ironman data request sent to %s.", param)
            end,
            order = 6
        },
        include = {
            name = "Include",
            desc = "Include player to ironman list.",
            type = "execute",
            usage = "<player>",
            func = function(self, param)
                local n = self:GetMainName(trim(param))
                if not n then
                    self:Print("Character has to be in your guild.")
                    return
                end
                self.Roster[n].iron = true
                self:Printf("Player %s included to ironman list.", n)
            end,
            order = 7
        },
        list = {
            name = "List",
            desc = "List players eligible for ironman bonus.",
            type = "execute",
            func = "IronManList",
            order = 8
        },
        start = {
            name = "Start",
            desc = "Save raid roster for ironman bonus.",
            type = "execute",
            func = function(self, param)
                if not UnitInRaid("player") then
                    self:Print("You have to be in a raid group.")
                    return
                end
                
                local count = self:IronManStart()
                if not count then
                    self:Print("Ironman could not be started. Unsaved ironman data found.")
                end
            end,
            order = 9
        },
        ["start!"] = {
            name = "Start with announce",
            desc = "Save ironman data with announce.",
            type = "execute",
            func = "IronManStartAnn",
            order = 10
        },
        reinvite = {
            name = "Reinvite",
            desc = "Reinvite ironman eligible players who remain out of raid.",
            type = "execute",
            func = "IronManReinvite",
            order = 11
        },
    }
}
