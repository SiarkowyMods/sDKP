--------------------------------------------------------------------------------
-- sDKP (c) 2011 by Siarkowy
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local pairs = pairs
local tinsert = tinsert
local tremove = tremove
local type = type

-- Table pool management -------------------------------------------------------

local pool = {}
local count, dispose, table, wipe

function count(t)
    local size = 0

    for k in pairs(t) do
        size = size + 1
    end

    return size
end

function table()
    return tremove(pool) or {}
end

function wipe(t)
    for k, v in pairs(t) do
        if type(v) == "table" then dispose(t[k]) end
        t[k] = nil
    end

    return t
end

function dispose(t)
    if type(t) ~= "table" then return end
    tinsert(pool, wipe(t))
end

-- Expose functions ------------------------------------------------------------

sDKP.count = count
sDKP.dispose = dispose
sDKP.table = table
sDKP.wipe = wipe
