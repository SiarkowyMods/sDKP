--------------------------------------------------------------------------------
--	sDKP (c) 2012 by Siarkowy
--	Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

sDKP.HyperlinkHandlers = { }

local OrigHyperlinkFunc = ChatFrame_OnHyperlinkShow

function ChatFrame_OnHyperlinkShow(frame, link, btn)
	local command, data = link:match("^|Hsdkp:(.-):(.-)|h")
	if data then
		sDKP.HyperlinkHandlers[command](btn, data)
	else
		OrigHyperlinkFunc(frame, link, btn)
	end
end

sDKP.Modules.Hyperlinks = GetTime()
