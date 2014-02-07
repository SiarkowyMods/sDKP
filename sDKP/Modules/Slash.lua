--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local COLORS = RAID_CLASS_COLORS
local assert = assert
local format = format
local gsub = gsub
local lower = string.lower
local match = string.match
local pairs = pairs
local tonumber = tonumber
local trim = string.trim
local type = type
local unpack = unpack
local upper = string.upper

-- Log entry types
local LOG_DKP_MODIFY    = 1
local LOG_DKP_RAID      = 2
local LOG_DKP_CLASS     = 3

local t = { }
function sDKP:RosterIterateAction(action, paramsA, criteria, paramsB)
    assert(action)
    assert(type(action) == "function")
    
    if criteria then
        assert(type(criteria) == "function")
    end
    
    paramsA = paramsA or t
    paramsB = paramsB or t
    assert(type(paramsA) == "table")
    assert(type(paramsB) == "table")
    
    for n, d in pairs(self.Roster) do
        if not criteria or criteria(d, unpack(paramsB)) then
            action(d, unpack(paramsA))
        end
    end
end

local function actionModify(d, points)
    sDKP:Modify(d.n, points, (points > 0) and points or 0, 0)
end

local function criteriaOnlineInRaid(d)
    return UnitInRaid(d.name) and d.on
end

local function criteriaClassOnlineInRaid(d, class)
    return UnitInRaid(d.name) and d.class == class and d.on
end

local GINFO_ZONE = 6

local function criteriaSameZoneInRaid(d)
    return UnitInRaid(d.name) and select(GINFO_ZONE, GetGuildRosterInfo(d.id)) == GetRealZoneText() and d.on
end

local function criteriaOtherZoneInRaid(d)
    return UnitInRaid(d.name) and select(GINFO_ZONE, GetGuildRosterInfo(d.id)) ~= GetRealZoneText() and d.on
end

function sDKP:ModifyChatWrapper(who, points, reason, announce)
    local output

    points = tonumber(points) or 0

    if announce then
        output = reason:match("@(%S+)")
        if output then
            reason = trim(gsub(reason, "@(%S+)", ""))
        end
    end

    if lower(who) == "raid" then
        self:Discard()
        self:RosterIterateAction(actionModify, {points}, criteriaOnlineInRaid)

        if announce then
            self:Announce(output, "raid %+d DKP%s", points, reason ~= "" and ": " .. reason or "")
        end

        local count = self:Store()
        self:Printf("%d |4player was:players were; %s %d DKP%s.", count, points >= 0 and "awarded" or "charged", abs(points), reason ~= "" and ": " .. reason or "")

        if reason ~= "" then
            self:Log(LOG_DKP_RAID, count, points, match(reason, "item:(%d+)") or reason)
        else
            self:Log(LOG_DKP_RAID, count, points)
        end

    elseif lower(who) == "zone" then
        self:Discard()
        self:RosterIterateAction(actionModify, {points}, criteriaSameZoneInRaid)

        if announce then
            self:Announce(output, "zone %+d DKP%s", points, reason ~= "" and ": " .. reason or "")
        end

        local count = self:Store()
        self:Printf("%d |4player was:players were; %s %d DKP%s.", count, points >= 0 and "awarded" or "charged", abs(points), reason ~= "" and ": " .. reason or "")

        -- TODO: zone DKP logging

    elseif lower(who) == "otherzone" then
        self:Discard()
        self:RosterIterateAction(actionModify, {points}, criteriaOtherZoneInRaid)

        if announce then
            self:Announce(output, "out of zone %+d DKP%s", points, reason ~= "" and ": " .. reason or "")
        end

        local count = self:Store()
        self:Printf("%d |4player was:players were; %s %d DKP%s.", count, points >= 0 and "awarded" or "charged", abs(points), reason ~= "" and ": " .. reason or "")

        -- TODO: zone DKP logging

    elseif COLORS[upper(who)] then
        local classUpper = upper(who)
        local classLower = lower(who)

        self:Discard()
        self:RosterIterateAction(actionModify, {points}, criteriaClassOnlineInRaid, {classUpper})

        if announce then
            local r, g, b = COLORS[classUpper].r, COLORS[classUpper].g, COLORS[classUpper].b
            self:Announce(output, "%s%ss|r %+d DKP%s", self.DecimalToHexColor(r, g, b), classLower, points, reason ~= "" and ": " .. reason or "")
        end

        local count = self:Store()
        self:Printf("%d |4player was:players were; %s %d DKP%s.", count, points >= 0 and "awarded" or "charged", abs(points), reason ~= "" and ": " .. reason or "")

        if reason ~= "" then
            self:Log(LOG_DKP_CLASS, classLower, count, points, match(reason, "item:(%d+)") or reason)
        else
            self:Log(LOG_DKP_CLASS, classLower, count, points)
        end

    elseif self:GetMainName(who) then
        self:Discard(who)
        self:Modify(who, points, (points > 0) and points or 0, 0)

        local player = self.ClassColoredPlayerName(who)
        if announce then
            self:Announce(output, "%s %+d DKP%s", player, points, reason ~= "" and ": " .. reason or "")
        end

        self:Store(self:GetMainName(who))
        self:Printf("%s was %s %d DKP%s.", player, points >= 0 and "awarded" or "charged", abs(points), reason ~= "" and ": " .. reason or "")

        if reason ~= "" then
            self:Log(LOG_DKP_MODIFY, who, points, match(reason, "item:(%d+)") or reason)
        else
            self:Log(LOG_DKP_MODIFY, who, points)
        end

    else
        self:Print("Character has to be in your guild. No notes changed.")
        return
    end
end

-- slash command table
sDKP.Slash = {
    name = format("Dragon Kill Points manager version %s.", sDKP.version),
    type = "group",
    args = {
        award = {
            name = "Award",
            desc = "Award player/class/raid specified DKP amount with optional reason.",
            type = "execute",
            usage = "<player>||<class>||raid <points>[ <reason>]",
            func = function(self, param)
                local who, points, reason = param:match("(%S+)%s*(%d+)%s*(.*)")
                points = tonumber(points)
                if not who or not points then
                    self:Print("You have to specify both who award points to and the point amount.")
                    return
                end
                self:ModifyChatWrapper(who, points, reason)
            end
        },
        ["award!"] = {
            name = "Award with announce",
            desc = "Award DKP amount and announce.",
            type = "execute",
            usage = "<player>||<class>||raid <points>[ <reason>[ @<channel>]]",
            func = function(self, param)
                local who, points, reason = param:match("(%S+)%s*(%d+)%s*(.*)")
                points = tonumber(points)
                if not who or not points then
                    self:Print("You have to specify both who award points to and the point amount.")
                    return
                end
                self:ModifyChatWrapper(who, points, reason, true)
            end
        },
        charge = {
            name = "Charge",
            desc = "Charge player/class/raid specified DKP amount with optional reason.",
            type = "execute",
            usage = "<player>||<class>||raid <points>[ <reason>]",
            func = function(self, param)
                local who, points, reason = param:match("(%S+)%s*(%d+)%s*(.*)")
                points = tonumber(points)
                if not who or not points then
                    self:Print("You have to specify both who to charge points and the point amount.")
                    return
                end
                self:ModifyChatWrapper(who, -points, reason)
            end
        },
        ["charge!"] = {
            name = "Charge with announce",
            desc = "Charge DKP amount and announce.",
            type = "execute",
            usage = "<player>||<class>||raid <points>[ <reason>[ @<channel>]]",
            func = function(self, param)
                local who, points, reason = param:match("(%S+)%s*(%d+)%s*(.*)")
                points = tonumber(points)
                if not who or not points then
                    self:Print("You have to specify both who to charge points and the point amount.")
                    return
                end
                self:ModifyChatWrapper(who, -points, reason, true)
            end
        },
        discard = {
            name = "Discard",
            desc = "Discard unsaved changes for all or only given player.",
            type = "execute",
            usage = "[<player>]",
            func = function(self, param)
                local name = param:match("%S+")
                self:Printf("%d changes discarded.", self:Discard(name ~= "" and name))
            end
        },
        info = {
            name = "Info",
            desc = "Print DKP info for given player.",
            type = "execute",
            usage = "<player>",
            func = function(self, param)
                local name = param:match("%S+")
                local main = self:GetMainName(name)
                if not main then
                    self:Print("No character specified or player not in your guild.")
                    return
                end
                local net, tot, hrs = self:GetPlayerPointValues(main)
                self:Printf("%s: %d net, %d tot, %d hrs.", format(name ~= main and "%s (%s)" or "%2$s", self.ClassColoredPlayerName(name), self.ClassColoredPlayerName(main)), net, tot, hrs)
            end,
        },
        modify = {
            name = "Modify",
            desc = "Change player DKP amounts as relative values.",
            type = "execute",
            usage = "<player> <netDelta> [<totDelta> [<hrsDelta>]]",
            func = function(self, param)
                local name, netD, totD, hrsD = param:match("(%S+)%s*([-]?%d*)%s*([-]?%d*)%s*([-]?%d*)")
                
                netD = tonumber(netD) or 0
                totD = tonumber(totD) or 0
                hrsD = tonumber(hrsD) or 0
                
                self:Modify(name, netD, totD, hrsD)
            end
        },
        option = {
            name = "Option",
            desc = "Options management.",
            type = "group",
            args = {
                dkpformat = {
                    name = "DKP note format",
                    desc = "Sets DKP format for officer notes. Use %n for netto, %t - total, %h - hour counter.",
                    type = "execute",
                    usage = "<format>",
                    func = function(self, param)
                        local O = self.Options
                        O.Core_NoteFormat = param ~= "" and param or "Net:%n Tot:%t Hrs:%h"
                        self:Printf("DKP note format set to %q.", O.Core_NoteFormat)
                    end
                },
                ignoreginfo = {
                    name = "Ignore guild info note format",
                    desc = "Controls whether to load DKP note format from guild info.",
                    type = "execute",
                    usage = "off||on",
                    func = function(self, param)
                        local O = self.Options
                        O.Core_IgnoreGuildInfoFormat = param:match("^on$") and true or nil
                        self:Printf("Guild info DKP note format ignore %s.", O.Core_IgnoreGuildInfoFormat and "enabled" or "disabled")
                    end
                },
                verbosediff = {
                    name = "Verbose diff",
                    desc = "Prints chat message on DKP change.",
                    type = "execute",
                    usage = "off||on",
                    func = function(self, param)
                        local O = self.Options
                        O.Core_VerboseDiff = param:match("^on$") and true or nil
                        self:Printf("Verbose diff to chat frame %s.", O.Core_VerboseDiff and "enabled" or "disabled")
                    end
                },
                whispers = {
                    name = "Whisper announces",
                    desc = "Controls whether to send whisper announces on DKP change.",
                    type = "execute",
                    usage = "off||on",
                    func = function(self, param)
                        local O = self.Options
                        O.Core_WhisperAnnounce = param:match("^on$") and true or nil
                        self:Printf("Whisper announces %s.", O.Core_WhisperAnnounce and "enabled" or "disabled")
                    end
                },
            }
        },
        set = {
            name = "Set",
            desc = "Immediately set fixed player DKP amounts.",
            type = "execute",
            usage = "<player> <net> [<tot> [<hrs>]]",
            func = function(self, param)
                local name, net, tot, hrs = param:match("(%S+)%s*([-]?%d*)%s*([-]?%d*)%s*([-]?%d*)")
                
                net = tonumber(net)
                tot = tonumber(tot)
                hrs = tonumber(hrs)
                
                self:Set(name, net, tot, hrs)
            end
        },
        store = {
            name = "Store",
            desc = "Save all or given player's DKP changes to officer note(s).",
            type = "execute",
            usage = "[<player>]",
            func = function(self, param)
                local name = param:match("%S+")
                self:Printf("Making changes to notes...")
                self:Store(name ~= "" and name)
            end
        },
        usage = {
            name = "Usage",
            desc = "Prints some help about usage strings.",
            type = "execute",
            func = function(self, param)
                self:Print("Usage information:")
                self:Echo("   |cff88ffff<arg>|r - Angle brackets contain a single mandatory argument.")
                self:Echo("   |cff88ffff[<arg>]|r - Square brackets contain an optional argument.")
                self:Echo("   |cff88ffff<arg1>||<arg2>||...|r - Pipe separates possible argument list.")
                self:Echo("   |cff88ffff<timestamp>|r - Represents date in following format: YYYY.MM.DD HH.MM.SS, where . is any single not numeric character.")
            end
        },
        versions = {
            name = "Versions",
            desc = "Print guild mates addon versions.",
            type = "execute",
            func = "VersionDump"
        },
    }
}

local Actions = { }

function Actions.execute(self, node, param)
    if type(node.func) == "string" then
        self[node.func](self, param)
        return
    end
    node.func(self, param)
end

function Actions.group(self, node, param)
    self:Printf(node.desc and "%s - %s" or "%s", node.name, node.desc)
    for command, data in self.PairsByKeys(node.args) do
        self:Echo("   |cff56a3ff%s|r%s - %s", command, data.usage and format(" |cff88ffff%s|r", data.usage) or "", data.desc)
    end
end

function sDKP:SlashHandleNode(node, param)
    Actions[node.type](self, node, param)
end

function sDKP:SlashTraverseTree(node, arg)
    local command, param = arg:trim():match("(%S+)%s*(.*)")
    if (node.type == "group") and node.args[command] then
        self:SlashTraverseTree(node.args[command], param)
    else
        self:SlashHandleNode(node, arg)
    end
end

function sDKP.SlashCommandHandler(msg)
    sDKP:SlashTraverseTree(sDKP.Slash, msg)
end

SlashCmdList.SDKP = sDKP.SlashCommandHandler
SLASH_SDKP1 = "/sdkp"
SLASH_SDKP2 = "/dkp"
