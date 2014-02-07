--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local VARIABLES_LOADED = sDKP.VARIABLES_LOADED
function sDKP:VARIABLES_LOADED()
    VARIABLES_LOADED(self)
    sDKP_LOG = sDKP_LOG or { }
    self.LogData = sDKP_LOG
    self:Print("Log loaded.")
end
