--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

sDKP = {
	author	= GetAddOnMetadata("sDKP", "Author"),
	frame	= CreateFrame("frame"),
	name	= "sDKP",
	player	= (UnitName("player")),
	version	= GetAddOnMetadata("sDKP", "Version"),
}

local sDKP = sDKP

local format = format
local select = select
local tostring = tostring

local frame = sDKP.frame
local prompt = format("|cff56a3ff%s:|r ", sDKP.name)

local DATABASE_VERSION = 20111217
local sDKP_DB_DEFAULTS = {
	Data = { }, -- misc. data
	Options = {
		-- core
		Core_IgnoreGuildInfoNoteFormat = nil,		-- disable Guild Info supplied DKP note format
		Core_NoteFormat = "Net:%n Tot:%t Hrs:%h",	-- current note format
		Core_VerboseDiff = nil,						-- verbose diff to chat frame on every officer note change
		-- chat
		Chat_FilterMinRarity = 4,					-- min. quality to display chat charge links while in a raid (4 = epic)
		Chat_HideLootHyperlinks = nil,				-- disable all chat charge links
		Chat_IgnoreItemIds = {						-- item IDs to ignore from appending charge links
			[29434] = true, -- Badge of Justice
		},
		-- log
		Log_FilterMinRarity = 4,					-- min. quality to log item loot
	},
	Roster = { }, -- current DKP data
	Version = DATABASE_VERSION,
}

-- Chat functions
function sDKP:Print(s, ...) DEFAULT_CHAT_FRAME:AddMessage(prompt .. tostring(s), ...) end
function sDKP:Printf(...) DEFAULT_CHAT_FRAME:AddMessage(prompt .. format(...)) end
function sDKP:Echo(...) DEFAULT_CHAT_FRAME:AddMessage(format(...)) end

-- Event management functions
function sDKP:RegisterEvent(e) frame:RegisterEvent(e) end
function sDKP:UnregisterEvent(e) frame:UnregisterEvent(e) end

function sDKP:Init()
	self.Comms = { }	-- comm message handlers
	self.LogData = { }	-- operations' log
	self.Modules = { }	-- enabled modules
	self.Options = { }	-- options database
	self.Roster	= { }	-- guild roster data
	self.Versions = { }	-- guild mates' versions

	frame:SetScript("OnEvent", self.OnEvent)
	self:RegisterEvent("VARIABLES_LOADED")

	self:Printf("Version %s enabled. Usage info: /sdkp", self.version)
end

--- Loads database defaults if database is not present or its format is older than current,
-- otherwise wipes database defaults table.
function sDKP:CheckDatabaseVersion()
	if not sDKP_DB or sDKP_DB.Version < DATABASE_VERSION then
		sDKP_DB = sDKP_DB_DEFAULTS
		self:Print("New database version. All data resetted to defaults.")
	else
		local function wipe(t)
			for k, v in pairs(t) do
				if type(v) == "table" then
					wipe(t[k])
				end
				t[k] = nil
			end
			t = nil
		end

		wipe(sDKP_DB_DEFAULTS)
	end
end

--- Generic OnEvent handler.
-- @param frame Target frame.
-- @param event Event.
-- @param ... Additional args tuple.
function sDKP.OnEvent(frame, event, ...)
	sDKP[event](sDKP, ...)
end

--- Variables Loaded event handler.
function sDKP:VARIABLES_LOADED()
	self:UnregisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:CheckDatabaseVersion()
	self.DB			= sDKP_DB	-- general database
	self.Options	= sDKP_DB.Options
	self.Roster		= sDKP_DB.Roster
	self:PLAYER_GUILD_UPDATE("player")
	self:CleanupRoster()
	self:CommSend("HI")
end

sDKP:Init()
sDKP.Modules.Base = GetTime()
