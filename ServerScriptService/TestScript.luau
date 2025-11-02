-- TestScript.lua - Quick test to verify all systems are working
-- This file can be deleted after testing

print("🧪 Testing Banana Game Systems...")

-- Test 1: Check if scripts loaded correctly
local tests = {
    {name = "AdminCommands", system = _G.AdminCommands},
    {name = "PlayerTitleSystem", system = _G.PlayerTitleSystem},
    {name = "CoinSystem", system = _G.CoinSystem},
    {name = "SeedSystem", system = _G.SeedSystem},
    {name = "SellingSystem", system = _G.SellingSystem},
    {name = "SprinklerSystem", system = _G.SprinklerSystem}
}

for _, test in ipairs(tests) do
    if test.system then
        print("✅ " .. test.name .. " loaded successfully")
    else
        print("❌ " .. test.name .. " failed to load")
    end
end

-- Test 2: Check RemoteEvents
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")

if remoteEvents then
    print("✅ RemoteEvents folder found")
    local requiredRemotes = {
        "AdminCommand",
        "RouletteUpdate", 
        "UpdateTitleRemote",
        "GetTitleDataRemote",
        "GetPlayerTitles",
        "SetPlayerTitle",
        "RedeemCode"
    }
    
    for _, remoteName in ipairs(requiredRemotes) do
        if remoteEvents:FindFirstChild(remoteName) then
            print("  ✅ " .. remoteName .. " remote found")
        else
            print("  ❌ " .. remoteName .. " remote missing")
        end
    end
else
    print("❌ RemoteEvents folder not found")
end

-- Test 3: Check inversion functions
local inversionSystems = {"CoinSystem", "SellingSystem", "SeedSystem", "SprinklerSystem"}
for _, systemName in ipairs(inversionSystems) do
    local system = _G[systemName]
    if system and system.invertRewards then
        print("✅ " .. systemName .. " has inversion support")
    elseif system and system.invertValues then
        print("✅ " .. systemName .. " has inversion support")
    elseif system and system.invertPrices then
        print("✅ " .. systemName .. " has inversion support")
    elseif system and system.invertEffects then
        print("✅ " .. systemName .. " has inversion support")
    else
        print("⚠️ " .. systemName .. " may not have full inversion support")
    end
end

print("🧪 Test complete! Check results above.")
print("📋 Remember to:")
print("   1. Update admin user IDs in AdminCommands.luau")
print("   2. Enable DataStore access in game settings")
print("   3. Test in-game before publishing")
print("   4. Delete this test script after verification")
