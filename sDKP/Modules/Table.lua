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
local dispose, table, wipe

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

sDKP.dispose = dispose
sDKP.table = table
sDKP.wipe = wipe
