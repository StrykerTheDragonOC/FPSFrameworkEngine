-- 00_ViciousStingerInit.server.lua
-- HIGH PRIORITY INITIALIZATION - Creates RemoteEvents for ViciousStinger weapon
-- The "00_" prefix ensures this script runs before other scripts

-- IMMEDIATE SETUP - Create RemoteEvents folder and events
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents folder if it doesn't exist
local remoteEvents = ReplicatedStorage:FindFirstChild("ViciousWeaponEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "ViciousWeaponEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Create all RemoteEvents immediately
local events = {
    "WeaponHit",
    "TriggerViciousOverdrive",
    "TriggerHoneyFog",
    "TriggerEarthquake"
}

local remoteEventInstances = {}

for _, eventName in pairs(events) do
    local remoteEvent = remoteEvents:FindFirstChild(eventName)
    if not remoteEvent then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = remoteEvents
    end
    remoteEventInstances[eventName] = remoteEvent
end

-- Set global variables IMMEDIATELY for weapon model scripts
_G.ViciousWeaponEvents = remoteEvents
_G.remoteEvents = remoteEvents
_G.weaponHitEvent = remoteEventInstances.WeaponHit
_G.overdriveEvent = remoteEventInstances.TriggerViciousOverdrive
_G.honeyFogEvent = remoteEventInstances.TriggerHoneyFog
_G.earthquakeEvent = remoteEventInstances.TriggerEarthquake

-- Also set individual event globals that weapon scripts might expect
for eventName, eventInstance in pairs(remoteEventInstances) do
    _G[eventName] = eventInstance
end

print("00_ViciousStingerInit: HIGH PRIORITY SETUP COMPLETE")
print("  - ViciousWeaponEvents folder:", remoteEvents and "✓" or "✗")
for _, eventName in pairs(events) do
    print("  - " .. eventName .. ":", remoteEventInstances[eventName] and "✓" or "✗")
end
print("  - Global variables set for weapon model scripts")