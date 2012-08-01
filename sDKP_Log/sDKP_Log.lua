--------------------------------------------------------------------------------
--	sDKP Log (c) 2012 by Siarkowy
--	Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local VARIABLES_LOADED = sDKP.VARIABLES_LOADED
function sDKP:VARIABLES_LOADED()
	VARIABLES_LOADED(self)
	sDKP_LOG = sDKP_LOG or { }
	self.LogData = sDKP_LOG
	self.Modules.LogData = GetTime()
	self:Print("Log loaded.")
end
