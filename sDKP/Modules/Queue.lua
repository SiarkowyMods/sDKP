--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

local ChatThrottleLib = ChatThrottleLib

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

    local counter = 0
    local whisper
    local working -- queue activated flag

    --- Begins operation queue if not yet active.
    function sDKP:QueueActivate()
        if working then return end

        whisper = self:Get("whisper.toggle") and self:Get("whisper.modify")
        counter = 0
        working = true

        self:QueueProcess()
    end

    --- Adds character to storage queue.
    -- @param name (string) Character name.
    function sDKP:QueueAdd(name)
        queue[name] = true
    end

    --- Processes a single queue entry.
    function sDKP:QueueProcess()
        if not working then return end

        for name in pairs(queue) do
            local char = self(name)
            queue[name] = nil

            if char then
                if char:Store(nil, true) then
                    counter = counter + 1

                    if whisper then
                        self:QueueWhisper(char:GetOwnerOnline(),
                            format(whisper, char.net + char.netD,
                                char.tot + char.totD, char.netD))
                    end

                    char:Discard()

                    return
                end
            end
        end

        self:Printf("Total of %d |4note:notes; affected.", counter)
        if whisper then self:SendQueuedWhispers() end

        working = nil
    end
end

do
    local whispers = { }
    sDKP.WhisperQueue = whispers

    --- Adds (character, message) pair to whisper queue.
    -- @param char (string) Recipent of the message.
    -- @param message (string) Message to send.
    function sDKP:QueueWhisper(char, message)
        if char then
            whispers[char] = message
        end
    end

    --- Sends queued whispers using ChatThrottleLib and clears them from queue.
    function sDKP:SendQueuedWhispers()
        for char, message in pairs(whispers) do
            if char ~= self.player then
                ChatThrottleLib:SendChatMessage("BULK", nil, message, "WHISPER", nil, char)
            end

            whispers[char] = nil
        end
    end
end
