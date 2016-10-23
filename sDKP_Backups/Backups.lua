--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local format = format
local pairs = pairs
local time = time
local CanEditOfficerNote = CanEditOfficerNote
local CanViewOfficerNote = CanViewOfficerNote
local GetGuildInfo = GetGuildInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumGuildMembers = GetNumGuildMembers
local GuildRosterSetOfficerNote = GuildRosterSetOfficerNote
local IsInGuild = IsInGuild

hooksecurefunc(sDKP, "VARIABLES_LOADED", function(self)
    sDKP_BACKUPS = sDKP_BACKUPS or { }
    self.Backups = sDKP_BACKUPS
end)

function sDKP:GetBackup(timestamp)
    return self.Backups[timestamp]
end

function sDKP:BackupsList(guild)
    local count = 0
    self:Printf("Saved backups%s:", (guild ~= "") and format(" for guild <%s>", guild or "?") or "")
    for timestamp, data in self.PairsByKeys(self.Backups) do
        if not guild or guild == "" or guild == data[1] then
            count = count + 1
            self:Echo("   %s <%s> " ..
                "|Hsdkp:bkp:1:%3$d|h|cff88ffff(restore)|r|h " ..
                "|Hsdkp:bkp:2:%3$d|h|cff88ffff(delete)|r|h " ..
                "|Hsdkp:bkp:3:%3$d|h|cff88ffff(diff)|r|h",
                date(self:Get("log.dateformat"), timestamp),
                data[1], timestamp)
        end
    end
    self:Echo("Total of %d |4backup:backups;.", count)
end

function sDKP:BackupNotes()
    if not (IsInGuild() and CanViewOfficerNote()) then return end

    local timestamp = time()
    self.Backups[timestamp] = self.Backups[timestamp] or { }
    self.Backups[timestamp][1] = (GetGuildInfo("player"))
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, note = GetGuildRosterInfo(i)
        if note ~= "" then
            self.Backups[timestamp][name] = note
        end
    end

    return timestamp
end

function sDKP:RestoreNotes(timestamp)
    local backup = self:GetBackup(timestamp)
    if not (backup and IsInGuild() and CanViewOfficerNote() and CanEditOfficerNote()) then return end

    local num = 0
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, note = GetGuildRosterInfo(i)
        if backup[name] and backup[name] ~= note then
            GuildRosterSetOfficerNote(i, backup[name])
            num = num + 1
        end
    end

    return num
end

function sDKP:DeleteBackup(timestamp)
    local backup = self:GetBackup(timestamp)

    if backup then
        for k in pairs(backup) do
            backup[k] = nil
        end
        self.Backups[timestamp] = nil
        return true
    end

    return false
end

function sDKP:DeleteAllBackups()
    for timestamp, _ in pairs(self.Backups) do
        self:DeleteBackup(timestamp)
    end
end

do
    local RED   = "|cffff3333"
    local GREEN = "|cff33ff33"
    local GRAY  = "|cff888888"

    local function col(a, b)
        a = tonumber(a) or 0
        b = tonumber(b) or 0
        if b > a then return GREEN end
        if b < a then return RED end
        return GRAY
    end

    function sDKP:VisualDiff(timestamp)
        local backup = self:GetBackup(timestamp)

        if backup then
            self:Printf("Current to %s note differences:", date(self:Get("log.dateformat"), timestamp))

            local count = 0
            for name, note in pairs(backup) do
                local _, net, tot, hrs = self:ParseOfficerNote(note)
                local char = self:GetCharacter(name)

                if char and (net ~= char.net or tot ~= char.tot or hrs ~= char.hrs) then
                    self:Echo("   %s: %s%+d net|r, %s%+d tot|r, %s%+d hrs|r", name,
                        col(net, char.net), char.net - net,
                        col(tot, char.tot), char.tot - tot,
                        col(hrs, char.hrs), char.hrs - hrs)
                    count = count + 1
                end
            end
            self:Echo("Total of %d |4difference:differences;.", count)
        else
            self:Print("Non-existent backup ID supplied.")
        end
    end
end
