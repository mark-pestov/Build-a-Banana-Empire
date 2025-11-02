-- EmpireSystem.luau
-- Core city economy: citizens, mood, taxes, money, and events

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MOODS = {"happy", "neutral", "unhappy", "angry", "tired", "excited", "bored"}
local MOOD_MULTIPLIER = {
    happy = 1.25,
    excited = 1.15,
    neutral = 1.0,
    bored = 0.85,
    tired = 0.5,
    unhappy = 0.75,
    angry = 0.5
}

local BUILDING_MOOD_EFFECTS = {
    Park = 0.10,         -- +10% happiness
    Factory = -0.05,     -- -5% happiness
    Entertainment = 0.15 -- +15% happiness
}

local BUILDING_INCOME = {
    House = 5,
    Office = 15,
    Factory = 25,
    Park = 2,
    Entertainment = 10,
    Market = 8,
    Workshop = 12
}

local DEFAULT_PRODUCTIVITY = 5 -- base money per tick per citizen
local MOOD_UPDATE_INTERVAL = 10 -- seconds
local MONEY_TICK_INTERVAL = 2 -- seconds
local DAY_INTERVAL = 60 -- seconds per in-game day

local playerData = {} -- [userId] = {taxRate, citizens = {citizenData...}, money}

local JOBS = {
    Office = {pay = 10, mood = 0},
    Factory = {pay = 8, mood = -1},
    Park = {pay = 4, mood = 2},
    Unemployed = {pay = 2, mood = -2},
}

-- Utility: Get or create player data
local function getPlayerData(player)
    local userId = player.UserId
    if not playerData[userId] then
        playerData[userId] = {
            taxRate = 0.1, -- 10% default
            money = 0,
            citizens = {},
        }
    end
    return playerData[userId]
end

-- Utility: Random mood
local function randomMood()
    return MOODS[math.random(1, #MOODS)]
end

-- Spawn a citizen for a player (called when building is placed)
function SpawnCitizen(player, building, jobType)
    local pdata = getPlayerData(player)
    local mood = randomMood()
    local job = jobType or "Unemployed"
    local citizen = {
        Mood = mood,
        Productivity = DEFAULT_PRODUCTIVITY,
        IsProtesting = false,
        CurrentBuilding = building,
        LastMoodChange = os.time(),
        Job = job,
        Money = 0,
        Location = building and building.Name or "Unknown",
        Destination = nil,
    }
    table.insert(pdata.citizens, citizen)
    return citizen
end

-- Set tax rate for a player
function SetTaxRate(player, rate)
    local pdata = getPlayerData(player)
    pdata.taxRate = math.clamp(rate, 0, 1)
end

-- Get info for a citizen (for UI)
function GetCitizenInfo(player, citizenIdx)
    local pdata = getPlayerData(player)
    local c = pdata.citizens[citizenIdx]
    if not c then return nil end
    return {
        Mood = c.Mood,
        Money = c.Money,
        Location = c.Location,
        Destination = c.Destination,
        Job = c.Job,
    }
end

-- Apply building mood effects to citizens (call when building is placed/removed)
function ApplyBuildingMoodEffects(player)
    local pdata = getPlayerData(player)
    for _, citizen in ipairs(pdata.citizens) do
        local effect = 0
        if citizen.CurrentBuilding and BUILDING_MOOD_EFFECTS[citizen.CurrentBuilding.Type] then
            effect = BUILDING_MOOD_EFFECTS[citizen.CurrentBuilding.Type]
        end
        citizen.MoodEffect = effect
    end
end

-- Mood update logic (now includes building effects)
local function updateCitizenMood(player, citizen)
    local tax = getPlayerData(player).taxRate
    local jobMood = JOBS[citizen.Job] and JOBS[citizen.Job].mood or 0
    local buildingEffect = citizen.MoodEffect or 0
    -- Mood logic: high tax = more unhappy, low tax = more happy
    local idx
    if tax > 0.7 then
        idx = 7 -- angry
    elseif tax > 0.5 then
        idx = 6 -- unhappy
    elseif tax > 0.3 then
        idx = 3 -- neutral
    elseif tax > 0.15 then
        idx = 2 -- happy
    else
        idx = 1 -- excited
    end
    idx = math.clamp(idx + jobMood, 1, #MOODS)
    -- Apply building effect as a percent shift
    if buildingEffect ~= 0 then
        local shift = math.floor(#MOODS * buildingEffect)
        idx = math.clamp(idx + shift, 1, #MOODS)
    end
    citizen.Mood = MOODS[idx]
end

-- Periodic mood update
spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            local pdata = getPlayerData(player)
            for _, citizen in ipairs(pdata.citizens) do
                updateCitizenMood(player, citizen)
            end
        end
        wait(MOOD_UPDATE_INTERVAL)
    end
end)

-- Passive income tick (every second)
spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            local pdata = getPlayerData(player)
            local buildings = getPlayerBuildings(player)
            local baseIncome = 0
            for _, b in ipairs(buildings) do
                local bType = b:GetAttribute("Type") or b.Name
                baseIncome = baseIncome + (BUILDING_INCOME[bType] or 0)
            end
            local taxMod = pdata.taxRate or 0.1
            local moodMult = getAverageMoodMultiplier(player)
            local income = baseIncome * (1 + taxMod) * moodMult
            pdata.money = pdata.money + income
            if _G.CoinSystem and _G.CoinSystem.setCoins then
                _G.CoinSystem.setCoins(player, math.floor(pdata.money))
            end
        end
        wait(1)
    end
end)

-- Admin event hooks (example)
function ApplyEventMoodModifier(eventName, moodDelta)
    for _, player in ipairs(Players:GetPlayers()) do
        local pdata = getPlayerData(player)
        for _, citizen in ipairs(pdata.citizens) do
            -- Example: Banana Eclipse = -1 mood, Banana Bloom Burst = +1 mood
            -- You can expand this logic for more nuanced effects
            local idx = table.find(MOODS, citizen.Mood) or 3
            idx = math.clamp(idx + moodDelta, 1, #MOODS)
            citizen.Mood = MOODS[idx]
        end
    end
end

-- Expose API globally
_G.EmpireSystem = {
    SpawnCitizen = SpawnCitizen,
    SetTaxRate = SetTaxRate,
    ApplyEventMoodModifier = ApplyEventMoodModifier,
    GetPlayerData = getPlayerData,
    GetCitizenInfo = GetCitizenInfo,
    ApplyBuildingMoodEffects = ApplyBuildingMoodEffects,
    CollectBuildingIncome = CollectBuildingIncome
}
