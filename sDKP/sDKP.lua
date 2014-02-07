--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
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

local DB_VERSION = 20140207
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

do
    local Externals, Roster, Options

    function sDKP:Reconfigure()
        Externals   = self.Externals
        Roster      = self.Roster
        Options     = self.Options
    end

    function sDKP:Get(opt) return Options[opt] end
    function sDKP:Set(opt, v) Options[opt] = v end
end

--- Variables Loaded event handler.
function sDKP:VARIABLES_LOADED()
    self:UnregisterEvent("VARIABLES_LOADED")

    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_GUILD_UPDATE")

    -- database management
    sDKP_DB = sDKP_DB and sDKP_DB.Version == DB_VERSION and sDKP_DB or
    self:Print("Database initialised.") or {
        Externals = {}, -- out of guild aliases to guild mains
        Roster = {}, -- current DKP data
        Options = {
            -- Chat
            ["chat.rarity"] = 4,                        -- min. item quality (epic)
            ["chat.nolootlinks"] = false,               -- toggle
            ["chat.ignoredids"] = {                     -- ignored item IDs
                [29434] = true, -- Badge of Justice
            },

            -- Core
            ["core.noginfo"] = false,                   -- Guild Info DKP note format ignore toggle
            ["core.format"] = "Net:%n Tot:%t Hrs:%h",   -- DKP note format
            ["core.diff"] = true,                       -- verbose diff toggle
            ["core.whispers"] = true,                   -- whisper announce toggle

            -- Log
            ["log.rarity"] = 4,                         -- min. item quality (epic)
        },

        -- database version
        Version = DB_VERSION
    }

    self.DB         = sDKP_DB
    self.Externals  = sDKP_DB.Externals
    self.Options    = sDKP_DB.Options
    self.Roster     = sDKP_DB.Roster

    self:Reconfigure()

    self:PLAYER_GUILD_UPDATE("player")
    self:CleanupRoster()
    self:CommSend("HI")

    self.VARIABLES_LOADED = nil
end

sDKP:Init()
