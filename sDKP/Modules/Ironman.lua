--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local pairs = pairs
local tConcat = table.concat

sDKP.Slash.args.ironman = {
    type = "group",
    name = "Ironman",
    desc = "Ironman functions.",
    args = {
        add = {
            name = "Add",
            desc = "Add players to ironman list.",
            type = "execute",
            usage = "<filter>",
            func = function(self, param)
                local list, num = self:Select(param)

                if num > 0 then
                    self:ForEach(list, "SetIronMan", true)
                    self:Printf("Total of %d |4player:players; added to list.", num)
                else
                    self:Print("No characters matched the filter.")
                end

                self.dispose(list)
            end,
            order = 5
        },
        clear = {
            name = "Clear",
            desc = "Cancel ironman bonus awarning no DKP.",
            type = "execute",
            func = function(self, param)
                local list, num = self:Select("ironman")

                if num > 0 then
                    self:ForEach(list, "SetIronMan", nil)
                    self:Printf("Total of %d |4player:players; cleared.", num)
                else
                    self:Print("No characters eligible for ironman bonus.")
                end

                self.dispose(list)
            end,
            order = 10
        },
        remove = {
            name = "Remove",
            desc = "Remove players from ironman list.",
            type = "execute",
            usage = "<filter>",
            func = function(self, param)
                local list, num = self:Select(param)

                if num > 0 then
                    self:ForEach(list, "SetIronMan", nil)
                    self:Printf("Total of %d |4player:players; removed from list.", num)
                else
                    self:Print("No characters matched the filter.")
                end

                self.dispose(list)
            end,
            order = 15
        },
        list = {
            name = "List",
            desc = "List players eligible for ironman bonus.",
            type = "execute",
            func = function(self, param)
                local list, num = self:Select("ironman")
                local t = self.table()

                if num > 0 then
                    self:Print("List of ironman eligible players:")

                    for name, char in self:GetChars() do
                        if char:IsIronMan() then
                            tinsert(t, char.name)

                            if #t >= 5 then
                                self:Echo(tConcat(t, ", "))
                                self.wipe(t)
                            end
                        end
                    end

                    if #t > 0 then
                        self:Echo(tConcat(t, ", "))
                    end

                    self:Printf("Total of %d |4player:players;.", num)
                else
                    self:Print("No players eligible for ironman bonus.")
                end

                self.dispose(t)
                self.dispose(list)
            end,
            order = 20
        },
        start = {
            name = "Start",
            desc = "Save raid or filtered roster for ironman bonus.",
            type = "execute",
            usage = "[<filter>]",
            func = function(self, param)
                local list, num = self:Select("ironman")

                if num > 0 then
                    self:ForEach(list, "SetIronMan", nil)
                end

                self.dispose(list)

                list, num = self:Select(param ~= "" and param or "all")

                if num > 0 then
                    self:ForEach(list, "SetIronMan", true)
                    self:Printf("Total of %d |4player:players; added to list.", num)
                else
                    self:Print("No characters matched the filter.")
                end

                self.dispose(list)
            end,
            order = 25
        },
        reinvite = {
            name = "Reinvite",
            desc = "Reinvite ironman eligible players who remain out of raid.",
            type = "execute",
            func = function(self, param)
                local list, num = self:Select("ironman")

                if num > 0 then
                    for main, char in pairs(list) do
                        char = self(main):GetOwnerOnline()

                        if char and not UnitInRaid(char.name) and char.name ~= self.player then
                            InviteUnit(char.name)
                        end
                    end
                end

                self.dispose(list)
            end,
            order = 30
        },
    }
}
