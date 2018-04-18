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


function GetPlayerInfoByName(player_name)
    local player_info = cache[player_name]

    if player_info then
        return unpack(player_info)
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
        local localized_class, class = UnitClass(unit)
        local localized_race, race = UnitRace(unit)
        local gender = UnitSex(unit)

        storePlayerInfo(name,
                        localized_class, class,
                        localized_race, race,
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
    local num_whos = GetNumWhoResults()
    local name, localized_race, race, class
    for i = 1, num_whos do
        name, _, _, localized_race, class = GetWhoInfo(i)
        race = localized_race == 'Undead' and 'Scourge' or localized_race
        if not cache[name] then
            storePlayerInfo(name,
                            class, stringUpper(class),
                            localized_race, race)
        end
    end
end


function PIL:PLAYER_LOGIN()
    local default_color_mt = {
        __index = function()
            return { r = 0.75, g = 0.75, b = 0.75 }
        end
    }
    setmetatable(RAID_CLASS_COLORS, default_color_mt)

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
