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
    local reason, chan = self.ExtractChannel(reason or "")

    if not who then
        return self:Printf("Usage: /sdkp %s[!] <character filter> <points>[ <reason>]", method:lower())
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

-- Slash command table
sDKP.Slash = {
    name = format("Dragon Kill Points manager version %s.", sDKP.version),
    type = "group",
    args = {
        award = {
            name = "Award",
            desc = "Award player(s) specified amount of DKP with optional reason.",
            type = "execute",
            usage = "<filter> <points>[ <reason>]",
            func = function(self, param)
                self:ModifySlashWrapper(param, "Award", false)
            end
        },
        ["award!"] = {
            name = "Award with announce",
            desc = "Award DKP amount and announce.",
            type = "execute",
            usage = "<filter> <points>[ <reason>[ @<channel>]]",
            func = function(self, param)
                self:ModifySlashWrapper(param, "Award", true)
            end
        },
        charge = {
            name = "Charge",
            desc = "Charge player(s) specified amount of DKP with optional reason.",
            type = "execute",
            usage = "<filter> <points>[ <reason>]",
            func = function(self, param)
                self:ModifySlashWrapper(param, "Charge", false)
            end
        },
        ["charge!"] = {
            name = "Charge with announce",
            desc = "Charge DKP amount and announce.",
            type = "execute",
            usage = "<filter> <points>[ <reason>[ @<channel>]]",
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
        invite = {
            name = "Invite",
            desc = "Invite selected player(s) into the raid group. Defaults to any online characters.",
            type = "execute",
            usage = "[<filter>]",
            func = function(self, param)
                local list, num = self:Select(param ~= "" and param or "online")
                for main, char in pairs(list) do
                    char = self(char)
                    if char.on and not UnitInRaid(char.name) and char.name ~= self.player then
                        InviteUnit(char.name)
                    end
                end
                self.dispose(list)
            end
        },
        modify = {
            name = "Modify",
            desc = "Change player's DKP amounts as relative values.",
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
                binding = {
                    name = "External character binding",
                    desc = "Toggles character binding through ?bind command.",
                    type = "execute",
                    usage = "off||on",
                    func = function(self, param)
                        self:Set("whisper.binding", param:match("^on$") and true or nil)
                        self:Printf("Whisper binding through ?bind command %s.", self:Get("whisper.binding") and "enabled" or "disabled")
                    end
                },
                dkpformat = {
                    name = "DKP note format",
                    desc = "Sets DKP format for officer notes. Use %n for net, %t - total, %h - hour counter.",
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
            desc = "Sets fixed player DKP amounts and stores to officer note.",
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
            desc = "Stores pending DKP changes to officer notes.",
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
            desc = "Print guild mates' addon versions.",
            type = "execute",
            func = "VersionDump"
        },
    }
}

-- Slash command table structure -----------------------------------------------

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

local day = 86400
function sDKP.SlashCommandHandler(msg)
    local data = sDKP.table()

    data.target     = UnitName("target") or "<no target>"
    data.focus      = UnitName("focus") or "<no focus>"
    data.year       = date("%Y")
    data.yearago    = date("%Y", time() - 366 * day)
    data.month      = date("%Y%m")
    data.monthago   = date("%Y%m", time() - 31 * day)
    data.today      = date("%Y%m%d")
    data.tomorrow   = date("%Y%m%d", time() + day)
    data.yesterday  = date("%Y%m%d", time() - day)

    sDKP:SlashTraverseTree(sDKP.Slash, msg:gsub("%%(%w+)", data))
    sDKP.dispose(data)
end

SlashCmdList.SDKP = sDKP.SlashCommandHandler
SLASH_SDKP1 = "/sdkp"
SLASH_SDKP2 = "/dkp"
