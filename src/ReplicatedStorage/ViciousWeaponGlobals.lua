-- ViciousWeaponGlobals.lua
-- Provides access to ViciousWeapon RemoteEvents for scripts inside weapon models
-- Works with 00_ViciousStingerInit.server.lua for high-priority setup

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViciousWeaponGlobals = {}

-- Try to get from globals first (set by 00_ViciousStingerInit)
if _G.ViciousWeaponEvents then
    ViciousWeaponGlobals.remoteEvents = _G.ViciousWeaponEvents
    ViciousWeaponGlobals.weaponHitEvent = _G.weaponHitEvent
    ViciousWeaponGlobals.overdriveEvent = _G.overdriveEvent
    ViciousWeaponGlobals.honeyFogEvent = _G.honeyFogEvent
    ViciousWeaponGlobals.earthquakeEvent = _G.earthquakeEvent
    print("ViciousWeaponGlobals: Using pre-loaded globals from 00_ViciousStingerInit")
else
    -- Fallback: Wait for the ViciousWeaponEvents folder to be created by the server
    local viciousWeaponEvents = ReplicatedStorage:WaitForChild("ViciousWeaponEvents", 10)

    if viciousWeaponEvents then
        -- Wait for all expected RemoteEvents
        ViciousWeaponGlobals.remoteEvents = viciousWeaponEvents
        ViciousWeaponGlobals.weaponHitEvent = viciousWeaponEvents:WaitForChild("WeaponHit", 5)
        ViciousWeaponGlobals.overdriveEvent = viciousWeaponEvents:WaitForChild("TriggerViciousOverdrive", 5)
        ViciousWeaponGlobals.honeyFogEvent = viciousWeaponEvents:WaitForChild("TriggerHoneyFog", 5)
        ViciousWeaponGlobals.earthquakeEvent = viciousWeaponEvents:WaitForChild("TriggerEarthquake", 5)

        -- Update global variables for legacy compatibility
        _G.remoteEvents = ViciousWeaponGlobals.remoteEvents
        _G.weaponHitEvent = ViciousWeaponGlobals.weaponHitEvent
        _G.overdriveEvent = ViciousWeaponGlobals.overdriveEvent
        _G.honeyFogEvent = ViciousWeaponGlobals.honeyFogEvent
        _G.earthquakeEvent = ViciousWeaponGlobals.earthquakeEvent

        print("ViciousWeaponGlobals: All RemoteEvents loaded via fallback method")
    else
        warn("ViciousWeaponGlobals: Could not find ViciousWeaponEvents folder")
        -- Create empty references to prevent errors
        ViciousWeaponGlobals.remoteEvents = nil
        ViciousWeaponGlobals.weaponHitEvent = nil
        ViciousWeaponGlobals.overdriveEvent = nil
        ViciousWeaponGlobals.honeyFogEvent = nil
        ViciousWeaponGlobals.earthquakeEvent = nil
    end
end

return ViciousWeaponGlobals