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

function sDKP:ModifySlashWrapper(param, method, announce)
    local who, points, reason = param:match("(.-)%s+(%d+)%s*(.*)")
    local reason, chan = self.ExtractChannel(reason)

    if not who then
        return self:Print("Both character filter and DKP amount required.")
    end

    local list, num = self:Select(who)
    points = (tonumber(points) or 0) * (method == "Award" and 1 or -1)

    if num > 0 and points ~= 0 then
        if announce then
            self:Announce(chan, "%s %s%+d DKP|r%s%s", who,
                points >= 0 and "|cff33ff33" or "|cffff3333",
                points, reason ~= "" and ": " or "", reason)
        end

        self:Discard()
        self:ForEach(list, method, abs(points), reason)

        num = self:Store()

        self:Printf("%s %s %d DKP (%d |4player:players;)%s%s.",
            points >= 0 and "Awarding" or "Charging", who,
            abs(points), num, reason ~= "" and ": " or "", reason)
    else
        self:Printf(num > 0 and "Nonzero DKP amount required."
            or "No characters match %s.", who)
    end

    self.dispose(list)
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
                self:ModifySlashWrapper(param, "Award", false)
            end
        },
        ["award!"] = {
            name = "Award with announce",
            desc = "Award DKP amount and announce.",
            type = "execute",
            usage = "<player>||<class>||raid <points>[ <reason>[ @<channel>]]",
            func = function(self, param)
                self:ModifySlashWrapper(param, "Award", true)
            end
        },
        charge = {
            name = "Charge",
            desc = "Charge player/class/raid specified DKP amount with optional reason.",
            type = "execute",
            usage = "<player>||<class>||raid <points>[ <reason>]",
            func = function(self, param)
                self:ModifySlashWrapper(param, "Charge", false)
            end
        },
        ["charge!"] = {
            name = "Charge with announce",
            desc = "Charge DKP amount and announce.",
            type = "execute",
            usage = "<player>||<class>||raid <points>[ <reason>[ @<channel>]]",
            func = function(self, param)
                self:ModifySlashWrapper(param, "Charge", true)
            end
        },
        discard = {
            name = "Discard",
            desc = "Discard all pending roster changes.",
            type = "execute",
            func = function(self, param)
                self:Printf("Total of %d |4change:changes; discarded.", self:Discard())
            end
        },
        info = {
            name = "Info",
            desc = "Print DKP info for given player.",
            type = "execute",
            usage = "<player>",
            func = function(self, param)
                local char = self(param or "")

                if not char then
                    return self:Print("No character specified or player not in your guild.")
                end

                local main = char:GetMain()
                self:Printf("Info for %s: %d net, %d tot, %d hrs.",
                    format(char.name ~= main.name and "%s <%s>" or "%2$s",
                        char:GetColoredName(), main:GetColoredName()),
                    main:GetPoints())
            end,
        },
        modify = {
            name = "Modify",
            desc = "Change player DKP amounts as relative values.",
            type = "execute",
            usage = "<player> <netDelta> [<totDelta> [<hrsDelta>]]",
            func = function(self, param)
                local name, netD, totD, hrsD = param:match("(%S+)%s*([-]?%d*)%s*([-]?%d*)%s*([-]?%d*)")

                local char = self(name or "")

                if not char then
                    return self:Print("No character specified or player not in your guild.")
                end

                char:Modify(netD, totD, hrsD)
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
                        self:Set("core.format", param ~= "" and param or "Net:%n Tot:%t Hrs:%h")
                        self:Printf("DKP note format set to %q.", self:Get("core.format"))
                    end
                },
                ignoreginfo = {
                    name = "Ignore guild info note format",
                    desc = "Toggles ignoring of guild info DKP note format.",
                    type = "execute",
                    usage = "off||on",
                    func = function(self, param)
                        self:Set("core.noginfo", param:match("^on$") and true or nil)
                        self:Printf("Guild info DKP note format ignore %s.", self:Get("core.noginfo") and "enabled" or "disabled")
                    end
                },
                verbosediff = {
                    name = "Verbose diff",
                    desc = "Prints chat message on DKP change.",
                    type = "execute",
                    usage = "off||on",
                    func = function(self, param)
                        self:Set("core.diff", param:match("^on$") and true or nil)
                        self:Printf("Verbose diff to chat frame %s.", self:Get("core.diff") and "enabled" or "disabled")
                    end
                },
                whispers = {
                    name = "Whisper announces",
                    desc = "Toggles whisper announces on DKP change.",
                    type = "execute",
                    usage = "off||on",
                    func = function(self, param)
                        self:Set("whisper.toggle", param:match("^on$") and true or nil)
                        self:Printf("Whisper announces %s.", self:Get("whisper.toggle") and "enabled" or "disabled")
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

                local char = self(name or "")

                if not char then
                    return self:Print("No character specified or player not in your guild.")
                end

                char:Set(net, tot, hrs):Store()
            end
        },
        store = {
            name = "Store",
            desc = "Save all or given player's DKP changes to officer note(s).",
            type = "execute",
            func = function(self, param)
                if self:Store() > 0 then
                    self:Printf("Applying pending changes to notes...")
                end
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
