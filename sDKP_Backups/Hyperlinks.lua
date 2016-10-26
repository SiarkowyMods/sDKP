--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP
local self = sDKP

local format = format

StaticPopupDialogs["SDKP_BACKUP"] = {
    text = "",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = nil,
    timeout = 0,

    -- common popup settings
    exclusive = 0,
    hideOnEscape = 1,
    showAlert = 1,
    whileDead = 1,
}

local Popup = StaticPopupDialogs.SDKP_BACKUP

sDKP.HyperlinkHandlers.bkp = function(btn, data)
    local action, id, rest = string.split(":", data, 3)

    action = tonumber(action) or 0
    id = tonumber(id) or 0

    if not self:GetBackup(id) then
        self:Print("Specified backup does not exist.")
        return
    end

    if action == 1 then -- restore
        Popup.text = format("You are about to restore guild <%s> officer notes' " ..
            "backup from %s. This cannot be undone. Proceed?",
            self:GetBackup(id)[1], date(self:Get("log.dateformat"), id))

        Popup.OnAccept = function()
            self:Printf("%d notes restored.", self:RestoreNotes(id) or 0)
        end

        StaticPopup_Show("SDKP_BACKUP")

    elseif action == 2 then -- delete
        Popup.text = format("You are about to delete guild <%s> officer notes' " ..
            "backup from %s. Data will be entirely lost. Proceed?",
            self:GetBackup(id)[1], date(self:Get("log.dateformat"), id))

        Popup.OnAccept = function()
            if self:DeleteBackup(id) then
                self:Print("Backup deleted.")
            end
        end

        StaticPopup_Show("SDKP_BACKUP")

    elseif action == 3 then -- diff
        self:VisualDiff(id)

    elseif action == 4 then -- revert
        self:RevertFromBackup(id, rest)
    end
end
