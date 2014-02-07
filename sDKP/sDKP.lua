--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

sDKP = {
    name    = "sDKP",
    author  = GetAddOnMetadata("sDKP", "Author"),
    version = GetAddOnMetadata("sDKP", "Version"),
    frame   = CreateFrame("Frame", "sDKP_Frame"),
    player  = UnitName("player"),

    Comms   = {},   -- comm message handlers
    LogData = {},   -- operations' log
    Options = {},   -- options database
    Roster  = {},   -- guild roster data
    Versions = {}   -- guild mates' versions
}

local sDKP = sDKP
local frame = sDKP.frame

local DB_VERSION = 20130919
local prompt = format("|cff56a3ff%s:|r ", sDKP.name)

local format = format
local select = select
local tostring = tostring

-- Chat functions
function sDKP:Print(s, ...) DEFAULT_CHAT_FRAME:AddMessage(prompt .. tostring(s), ...) end
function sDKP:Printf(...) DEFAULT_CHAT_FRAME:AddMessage(prompt .. format(...)) end
function sDKP:Echo(...) DEFAULT_CHAT_FRAME:AddMessage(format(...)) end

-- Event management functions
function sDKP:RegisterEvent(e) frame:RegisterEvent(e) end
function sDKP:UnregisterEvent(e) frame:UnregisterEvent(e) end

function sDKP:Init()
    frame:SetScript("OnEvent", function(frame, event, ...)
        self[event](self, ...)
    end)

    self:RegisterEvent("VARIABLES_LOADED")
    self:Printf("Version %s enabled. Usage: /sdkp", self.version)
end

--- Variables Loaded event handler.
function sDKP:VARIABLES_LOADED()
    self:UnregisterEvent("VARIABLES_LOADED")

    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_GUILD_UPDATE")
    self:RegisterEvent("RAID_ROSTER_UPDATE")

    -- database management
    sDKP_DB = sDKP_DB and sDKP_DB.Version == DB_VERSION and sDKP_DB or
    self:Print("Database initialised.") or {
        Data = {}, -- misc. data
        Externals = {}, -- out of guild aliases to guild mains
        Options = {
            -- chat
            Chat_FilterMinRarity = 4,                   -- [charge links] min. item quality (epic)
            Chat_HideLootHyperlinks = false,            -- [charge links] toggle
            Chat_IgnoreItemIds = {                      -- [charge links] ignored item IDs
                [29434] = true, -- Badge of Justice
            },

            -- core
            Core_IgnoreGuildInfoFormat = false,         -- [core] Guild Info DKP note format ignore toggle
            Core_NoteFormat = "Net:%n Tot:%t Hrs:%h",   -- [core] DKP note format
            Core_VerboseDiff = true,                    -- [core] verbose diff toggle
            Core_WhisperAnnounce = true,                -- [core] whisper announce toggle

            -- log
            Log_FilterMinRarity = 4,                    -- [log] min. item quality (epic)
        },
        Roster = {}, -- current DKP data

        -- database version
        Version = DB_VERSION
    }

    self.DB         = sDKP_DB
    self.Externals  = sDKP_DB.Externals
    self.Options    = sDKP_DB.Options
    self.Roster     = sDKP_DB.Roster

    self:PLAYER_GUILD_UPDATE("player")
    self:CleanupRoster()
    self:CommSend("HI")
end

sDKP:Init()
