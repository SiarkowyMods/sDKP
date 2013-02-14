--------------------------------------------------------------------------------
--  sDKP (c) 2011-2013 by Siarkowy
--  Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------

local sDKP = sDKP

-- Used log entry types
local LOG_PARTY_KILL    = 4

local mobs = { -- logged mobs list
    -- T6 / Black Temple
    ["High Warlord Naj'entus"] = true,
    ["Supremus"] = true,
    ["Shade of Akama"] = true,
    ["Teron Gorefiend"] = true,
    ["Gurtogg Bloodboil"] = true,
    ["Essence of Anger"] = true,
    ["Mother Shahraz"] = true,
    ["Gathios the Shatterer"] = true,
    ["High Nethermancer Zerevor"] = true,
    ["Lady Malande"] = true,
    ["Veras Darkshadow"] = true,
    ["Illidan Stormrage"] = true,

    -- T6 / Battle for Mount Hyjal
    ["Rage Winterchill"] = true,
    ["Anetheron"] = true,
    ["Kaz'rogal"] = true,
    ["Azgalor"] = true,
    ["Archimonde"] = true,

    -- Zul'Aman
    ["Nalorakk"] = true,
    ["Akil'zon"] = true,
    ["Jan'alai"] = true,
    ["Halazzi"] = true,
    ["Hex Lord Malacrass"] = true,
    ["Zul'jin"] = true,

    -- T5 / Tempest Keep
    ["Al'ar"] = true,
    ["Void Reaver"] = true,
    ["High Astromancer Solarian"] = true,
    ["Kael'thas Sunstrider"] = true,

    -- T5 / Serpentshrine Cavern
    ["Hydross the Unstable"] = true,
    ["The Lurker Below"] = true,
    ["Leotheras the Blind"] = true,
    ["Fathom-Lord Karathress"] = true,
    ["Morogrim Tidewalker"] = true,
    ["Lady Vashj"] = true,

    -- T4 / Magtheridon's Lair
    ["Magtheridon"] = true,

    -- T4 / Gruul's Lair
    ["High King Maulgar"] = true,
    ["Gruul the Dragonkiller"] = true,

    -- T4 / Karazhan
    ["Attumen the Huntsman"] = true,
    ["Moroes"] = true,
    ["Maiden of Virtue"] = true,
    ["Hyakiss the Lurker"] = true,
    ["Rokad the Ravager"] = true,
    ["Shadikith the Glider"] = true,
    ["The Big Bad Wolf"] = true,
    ["The Crone"] = true,
    ["Julianne"] = true,
    ["Romulo"] = true,
    ["The Curator"] = true,
    ["Shade of Aran"] = true,
    ["Terestian Illhoof"] = true,
    ["Netherspite"] = true,
    ["Prince Malchezaar"] = true,
    ["Nightbane"] = true,
}

function sDKP:UNIT_TARGET(unit)
    if unit ~= "player" then return end
    local health = UnitHealth("target")
    if health > 0 and mobs[UnitName("target")] then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function sDKP:COMBAT_LOG_EVENT_UNFILTERED(_, event, _, _, _, _, victim)
    if event ~= "UNIT_DIED" then return end
    if mobs[victim] then
        self:Log(LOG_PARTY_KILL, victim)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

sDKP.Modules.Boss = GetTime()
