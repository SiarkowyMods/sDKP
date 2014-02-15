--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local pairs = pairs
local tConcat = table.concat

sDKP.Slash.args.stanby = {
    type = "group",
    name = "Standby",
    desc = "Standby functions.",
    args = {
        add = {
            name = "Add",
            desc = "Add players to standby list.",
            type = "execute",
            usage = "<filter>",
            func = function(self, param)
                local list, num = self:Select(param)

                if num > 0 then
                    self:ForEach(list, "SetStandby", true)
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
            desc = "Clear standby data from guild roster.",
            type = "execute",
            func = function(self, param)
                local count = 0

                for name, char in self:GetChars() do
                    if char.stby then
                        char:SetStandby(nil)
                        count = count + 1
                    end
                end

                self:Printf("Total of %d |4player:players; cleared.", count)
            end,
            order = 10
        },
        remove = {
            name = "Remove",
            desc = "Remove players from standby list.",
            type = "execute",
            usage = "<filter>",
            func = function(self, param)
                local list, num = self:Select(param)

                if num > 0 then
                    self:ForEach(list, "SetStandby", nil)
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
            desc = "Prints standby list.",
            type = "execute",
            func = function(self, param)
                local list, num = self:Select("standby")
                local t = self.table()

                if num > 0 then
                    self:Print("Standby list:")

                    for name, char in self:GetChars() do
                        if char:IsStandby() then
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
                    self:Print("Standby list empty.")
                end

                self.dispose(t)
                self.dispose(list)
            end,
            order = 20
        },
        start = {
            name = "Start",
            desc = "Add raid or filtered roster to standby list.",
            type = "execute",
            usage = "[<filter>]",
            func = function(self, param)
                for name, char in self:GetChars() do
                    char:SetStandby(nil)
                end

                local list, num = self:Select(param ~= "" and param or "all")

                if num > 0 then
                    self:ForEach(list, "SetStandby", true)
                    self:Printf("Total of %d |4player:players; added to standby list.", num)
                else
                    self:Print("No characters matched the filter.")
                end

                self.dispose(list)
            end,
            order = 25
        },
        reinvite = {
            name = "Reinvite",
            desc = "Reinvite standby players to raid.",
            type = "execute",
            func = function(self, param)
                local list, num = self:Select("standby")

                if num > 0 then
                    for main, char in pairs(list) do
                        char = self(main):GetOwnerOnline()

                        if char and not UnitInRaid(char.name) then
                            InviteUnit(char.name)
                        end
                    end
                end

                self.dispose(list)
            end,
            order = 30
        },
        uninvite = {
            name = "Uninvite",
            desc = "Uninvite standby players (groups 6-8) from raid.",
            type = "execute",
            func = function(self, param)
                local list, num = self:Select("standby")

                if num > 0 then
                    for main, char in pairs(list) do
                        char = self(main):GetOwnerOnline()

                        if char and UnitInRaid(char.name) then
                            UninviteUnit(char.name)
                        end
                    end
                end

                self.dispose(list)
            end,
            order = 35
        },
    }
}
