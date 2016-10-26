--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

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
                    id  and format("Guild <%s> notes' backup complete (%s).", self.guild, date(self:Get("log.dateformat"), id))
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
                if self:DeleteBackup(self.ParamToTimestamp(param)) then
                    self:Print("Backup deleted.")
                end
            end
        },
        diff = {
            name = "Diff",
            desc = "Show differences between saved and current roster DKP values.",
            type = "execute",
            usage = "<timestamp>[ @<channel>]",
            func = function(self, param)
                local param, chan = self.ExtractChannel(param, "SELF")
                self:VisualDiff(self.ParamToTimestamp(param), chan)
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
                self:Printf("%d |4note:notes; restored.", self:RestoreNotes(self.ParamToTimestamp(param)) or 0)
            end
        },
        revert = {
            name = "Revert",
            desc = "Reverts player's DKP from backup.",
            type = "execute",
            usage = "<player> <timestamp>",
            func = function(self, param)
                local player, backup = param:match("(%w+) (%d+)")
                assert(player and backup, "Specify both player and timestamp")
                self:RevertFromBackup(self.ParamToTimestamp(backup), player)
            end
        },
    }
}
