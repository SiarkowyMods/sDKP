--------------------------------------------------------------------------------
--	sDKP (c) 2012 by Siarkowy
--	Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

function sDKP:GetOpt(option)
	return self.Options[option]
end

function sDKP:SetOpt(option, value)
	self.Options[option] = value
end

sDKP.Modules.Options = GetTime()
