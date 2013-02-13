--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP
local Util = sDKP.Util

sDKP.Slash.args.backup = {
    name = "Backup",
    desc = "Backup management commands.",
    type = "group",
    args = {
        create = {
            name = "Create",
            desc = "Saves new backup.",
            type = "execute",
            func = function(self, param)
                local id = self:BackupNotes()
                self:Print(
                    id  and format("Guild <%s> notes' backup complete (%s).", self.guild, date("%d.%m.%Y %X", id))
                        or  "Could not backup officer notes. You have to be in a guild and have the permission to view officer notes for this to work."
                )
            end
        },
        delete = {
            name = "Delete",
            desc = "Deletes specified backup.",
            type = "execute",
            usage = "<timestamp>",
            func = function(self, param)
                if self:DeleteBackup(Util.ParamToTimestamp(param)) then
                    self:Print("Backup deleted.")
                end
            end
        },
        diff = {
            name = "Diff",
            desc = "Show differences between saved and current roster DKP values.",
            type = "execute",
            usage = "<timestamp>",
            func = function(self, param)
                self:VisualDiff(Util.ParamToTimestamp(param))
            end
        },
        list = {
            name = "List",
            desc = "Lists all saved backups.",
            type = "execute",
            usage = "[<guild>]",
            func = "BackupsList"
        },
        restore = {
            name = "Restore",
            desc = "Load saved backup to guild notes.",
            type = "execute",
            usage = "<timestamp>",
            func = function(self, param)
                self:Printf("%d |4note:notes; restored.", self:RestoreNotes(Util.ParamToTimestamp(param)) or 0)
            end
        }
    }
}
