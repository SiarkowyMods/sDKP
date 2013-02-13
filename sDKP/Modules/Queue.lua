--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local ChatThrottleLib = ChatThrottleLib
local Util = sDKP.Util

local format = format
local gsub = gsub
local pairs = pairs
local select = select
local sub = string.sub
local tinsert = tinsert
local tremove = tremove
local trim = string.trim

do
	local queue = { }
	sDKP.StorageQueue = queue
	
	local ann
	local counter = 0
	local working -- queue activated flag
	
	--- Begins operation queue if not yet active.
	function sDKP:QueueActivate()
		if working then return end
		
		ann = self.Options.Core_WhisperAnnounce
		counter = 0
		working = true
		
		self:QueueProcess()
	end
	
	--- Adds player to storage queue.
	-- @param player Player to add.
	function sDKP:QueueAdd(player)
		tinsert(queue, player)
	end
	
	--- Clears all entries in storage queue.
	function sDKP:QueueClear()
		for k, v in pairs(queue) do
			queue[k] = nil
		end
	end
	
	--- Fired after queue completion, beginning whisper announces if option enabled.
	function sDKP:QueueDone()
		self:Echo("Total of %d |4note:notes; affected.", counter)
		if ann then
			self:SendQueuedWhispers()
		end
	end
	
	--- Processes a single queue entry.
	function sDKP:QueueProcess()
		if not working then return end
		
		local n = tremove(queue) -- get player from the beginning of queue
		if not n then
			working = nil
			self:QueueDone()
			return
		end
		
		counter = counter + 1
		
		local d = self.Roster[n]
		
		assert(d)
		
		local oldnote = trim(gsub(select(8, GetGuildRosterInfo(d.id)), "{.-}", ""))
		local newnote = trim(sub(format("{%s}%s", Util.FormatNoteData(d, d.netD, d.totD, d.hrsD), oldnote), 1, 31))
		
		local recipent = ann and n ~= self.player and ( d.on and n or self:GetPlayerOnlineAlt(n) )
		if recipent then
			self:QueueWhisper(recipent, format("Your DKP now is: %d net, %d tot, %+d change.", d.net + d.netD, d.tot + d.totD, d.netD))
		end
		
		d.hrsD = 0
		d.netD = 0
		d.totD = 0
		d.new = nil
		
		GuildRosterSetOfficerNote(d.id, newnote)
	end
end

do
	local whispers = { }
	sDKP.WhisperQueue = whispers
	
	--- Adds (player, message) pair to whisper queue.
	-- @param player Recipent of the message.
	-- @param message Message to send.
	function sDKP:QueueWhisper(player, message)
		whispers[player] = message
	end
	
	--- Sends every queued message using ChatThrottleLib and deletes it from whisper queue.
	function sDKP:SendQueuedWhispers()
		for player, message in pairs(whispers) do
			ChatThrottleLib:SendChatMessage("BULK", nil, message, "WHISPER", nil, player)
			whispers[player] = nil
		end
	end
end

sDKP.Modules.Queue = GetTime()
