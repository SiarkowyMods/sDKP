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

--- Sets alias status for given character.
-- @param alias Alias character name.
-- @param main Main character name.
-- @return boolean - success flag.
function sDKP:SetAlias(alias, main)
    assert(alias, "Alias character name required.")
    assert(self.Roster[main] or not main, "Guild member or no name required.")

    self.aliases[alias] = main
    return true
end

--- Returns guild member name for specified alias.
-- @param alias Alias character name.
-- @return string - Guild member name.
function sDKP:Unalias(alias)
    return self.aliases[alias]
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
                if name ~= "" then
                    self:SetAlias(name ~= "" and name, nil)
                end
            end
        },
        list = {
            name = "List",
            desc = "List all aliases to chat frame.",
            type = "execute",
            func = function(self, name)
                self:Print("Current aliases:")

                for alias, main in pairs(self.aliases) do
                    self:Echo("   %s --> %s", alias, main)
                end
            end
        },
        set = {
            name = "Set",
            desc = "Set alias status.",
            type = "execute",
            usage = "<alias> <main>",
            func = function(self, param)
                local alias, main = match(param, "(%S+)%s*(%S+)")
                self:SetAlias(alias, main)
            end
        }
    }
}

sDKP.Modules.Aliases = GetTime()
