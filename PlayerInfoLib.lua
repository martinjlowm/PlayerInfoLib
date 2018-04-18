if not LibStub then return end

local MAJOR_VERSION, MINOR_VERSION = 'PlayerInfoLib-1.0', '$Format:%ct-%h$'

-- Probably not a release
if not string.find(MINOR_VERSION, '%d+') then MINOR_VERSION = 0 end

local PIL = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not PIL then return end


-- Locals
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName
local UnitRace = UnitRace
local UnitSex = UnitSex
local stringUpper = string.upper

local cache = {}


function GetPlayerInfoByName(playerName)
    local playerInfo = cache[playerName]

    if playerInfo then
        return unpack(playerInfo)
    end
end

local function storePlayerInfo(name, ...)
    arg.n = nil
    cache[name] = arg
end

local function storeUnit(unit)
    if not UnitIsPlayer(unit) then
        return
    end

    local name = UnitName(unit)

    if name and (not cache[name] or not cache[name][1]) then
        local localizedClass, class = UnitClass(unit)
        local localizedRace, race = UnitRace(unit)
        local gender = UnitSex(unit)

        storePlayerInfo(name,
                        localizedClass, class,
                        localizedRace, race,
                        gender)
    end
end

function PIL:PLAYER_TARGET_CHANGED()
    storeUnit('target')
end

function PIL:UPDATE_MOUSEOVER_UNIT()
    storeUnit('mouseover')
end

function PIL:WHO_LIST_UPDATE()
    local numWhos = GetNumWhoResults()
    local name, localizedRace, race, class
    for i = 1, numWhos do
        name, _, _, localizedRace, class = GetWhoInfo(i)
        race = localizedRace == 'Undead' and 'Scourge' or localizedRace
        if not cache[name] then
            storePlayerInfo(name,
                            class, stringUpper(class),
                            localizedRace, race)
        end
    end
end


function PIL:PLAYER_LOGIN()
    local defaultColorMt = {
        __index = function()
            return { r = 0.75, g = 0.75, b = 0.75 }
        end
    }
    setmetatable(RAID_CLASS_COLORS, defaultColorMt)

    local realm = GetRealmName()

    PlayerInfoData = PlayerInfoData or { [realm] = {} }
    local mt = {
        __index = function(t, name)
            return name and PlayerInfoData[realm][name]
        end,
        __newindex = function(t, name, value)
            PlayerInfoData[realm][name] = value
        end
    }
    setmetatable(cache, mt)
end

local handler = CreateFrame('Frame')
handler:RegisterEvent('PLAYER_TARGET_CHANGED')
handler:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
handler:RegisterEvent('PLAYER_LOGIN')
handler:RegisterEvent('WHO_LIST_UPDATE')
handler:SetScript('OnEvent', function() return PIL[event]() end)
