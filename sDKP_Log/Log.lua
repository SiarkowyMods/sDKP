--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

hooksecurefunc(sDKP, "VARIABLES_LOADED", function(self)
    sDKP_LOG = sDKP_LOG or { }
    self.LogData = sDKP_LOG
    self:Reconfigure()
    self:Print("Log loaded.")
end)
