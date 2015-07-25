--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local format = format
local gsub = gsub
local match = string.match
local select = select
local sub = string.sub
local trim = string.trim
local GetGuildRosterInfo = GetGuildRosterInfo

--- Sets alias status for given character.
-- @param alias Alias character.
-- @param owner Owner of alias character.
-- @return boolean - success flag.
function sDKP:SetAlias(alias, owner)
    assert(alias, "Alias character name required.")
    assert(not owner or self(owner), "Guild member or no name required.")

    if owner then -- create
        if self(alias) then -- check if already exists
            return false
        end

        self:GetRoster()[alias] = self:BindClass({
            id      = 0,
            name    = alias,
            class   = select(2, UnitClass(alias)) or UNKNOWN,
            altof   = self(owner):GetMain().name,
            net     = 0,
            tot     = 0,
            hrs     = 0,
        }, "Character")

        return true

    elseif self(alias) and self(alias):IsExternal() then -- delete
        local char = self(alias)
        self:GetRoster()[alias] = nil
        self.dispose(char)

        return true
    end

    return false
end

sDKP.Slash.args.alias = {
    type = "group",
    name = "Alias",
    desc = "Alias management functions.",
    args = {
        clear = {
            name = "Clear",
            desc = "Clear alias from character.",
            type = "execute",
            usage = "<player>",
            func = function(self, name)
                self:Print(self:SetAlias(name, nil) and "Alias status cleared successfully."
                    or "Could not clear alias status from specified character.")
            end
        },
        list = {
            name = "List",
            desc = "List all aliases to chat frame.",
            type = "execute",
            func = function(self, name)
                self:Print("Current aliases:")

                local count = 0
                for name, char in self:GetChars() do
                    if char:IsExternal() then
                        self:Echo("   %s -> %s", self.ClassColoredPlayerName(name),
                            self.ClassColoredPlayerName(char:GetMain().name))
                        count = count + 1
                    end
                end

                self:Echo("Total of %d |4alias:aliases;.", count)
            end
        },
        set = {
            name = "Set",
            desc = "Set alias status.",
            type = "execute",
            usage = "<alias> <main>",
            func = function(self, param)
                local alias, main = match(param, "(%S+)%s*(%S+)")
                self:Print(self:SetAlias(alias, main) and "Alias status set successfully."
                    or "Could not set alias status for specified character.")
            end
        },
        unbound = {
            name = "Unbound",
            desc = "Print raid members not bound to any guild character.",
            type = "execute",
            func = function(self, param)
                if not UnitInRaid("player") then
                    return self:Print(ERR_NOT_IN_RAID)
                end

                self:Print("Unbound characters:")

                local count = 0
                for i = 1, GetNumRaidMembers() do
                    local name, _, _, _, _, class = GetRaidRosterInfo(i)

                    if not self(name) then
                        self:Echo("   %s", self.ClassColoredPlayerName(name, class))
                        count = count + 1
                    end
                end

                self:Echo("Total of %d unbound |4character:characters;.", count)
            end
        },
    }
}
