# Example Weapon Implementations

**Version:** 1.0
**Last Updated:** 2025-10-12
**Author:** FPS System Team

---

## Table of Contents

1. [Overview](#overview)
2. [Example 1: M4A1 Assault Rifle](#example-1-m4a1-assault-rifle)
3. [Example 2: Remington 700 Sniper Rifle](#example-2-remington-700-sniper-rifle)
4. [Example 3: Glock 17 Pistol](#example-3-glock-17-pistol)
5. [Example 4: Remington 870 Shotgun](#example-4-remington-870-shotgun)
6. [Example 5: RPG-7 Launcher](#example-5-rpg-7-launcher)
7. [Example 6: MP5 SMG](#example-6-mp5-smg)
8. [Universal Client Script Template](#universal-client-script-template)
9. [Customization Guide](#customization-guide)

---

## Overview

This document provides **complete, working examples** of weapons for the FPS System. Each example includes:

- **WeaponConfig entry**: Complete configuration with all stats
- **Client script**: Full LocalScript implementation
- **Customization notes**: How to modify for your needs
- **Testing tips**: Common issues and solutions

These examples can be copied directly into your project and modified as needed.

---

## Example 1: M4A1 Assault Rifle

### Description

A modern, versatile assault rifle with:
- Full-auto fire mode
- Moderate damage and recoil
- Good for all ranges
- Standard magazine capacity

### WeaponConfig Entry

```lua
-- In ReplicatedStorage.FPSSystem.Modules.WeaponConfig.lua

Weapons = {
    M4A1 = {
        -- Basic Info
        Name = "M4A1",
        DisplayName = "M4A1 Carbine",
        Description = "5.56mm assault rifle with high versatility",
        Category = "Primary",
        Subcategory = "AssaultRifles",

        -- Unlock Requirements
        UnlockLevel = 0, -- Available from start
        UnlockCost = 0,

        -- Fire Modes
        FireModes = {"Auto", "Semi", "Burst"},
        DefaultFireMode = "Auto",
        BurstCount = 3,

        -- Damage
        Damage = 30,
        HeadMultiplier = 2.0,
        TorsoMultiplier = 1.0,
        LimbMultiplier = 0.75,

        -- Range
        MaxRange = 500, -- Studs
        MinRange = 10,
        DamageDropoffStart = 200, -- Start losing damage at 200 studs
        DamageDropoffEnd = 500, -- Minimum damage at 500 studs
        MinDamage = 18, -- Damage at max range

        -- Fire Rate
        FireRate = 750, -- RPM (rounds per minute)
        FireRateSeconds = 60 / 750, -- Calculated automatically

        -- Ammo
        MagazineSize = 30,
        ReserveAmmo = 210, -- 7 extra mags
        ReloadTime = 2.5, -- Seconds
        ReloadAnimationSpeed = 1.0,

        -- Ballistics
        BulletVelocity = 900, -- Studs/second
        BulletGravity = true,
        BulletDrop = 0.5, -- Moderate bullet drop
        Penetration = 2, -- Can penetrate 2 walls

        -- Recoil
        RecoilVertical = 1.2,
        RecoilHorizontal = 0.8,
        RecoilRecoverySpeed = 0.15,
        RecoilPattern = "Vertical", -- "Vertical", "Random", "Zigzag"

        -- Spread
        SpreadBase = 2.0,
        SpreadAiming = 0.5,
        SpreadMoving = 3.5,
        SpreadSprinting = 5.0,
        SpreadIncrease = 0.3, -- Per shot
        SpreadMax = 8.0,
        SpreadRecovery = 0.2, -- Per second

        -- Handling
        AimSpeed = 0.25, -- Seconds to enter ADS
        WalkSpeedMultiplier = 0.95,
        SprintSpeedMultiplier = 1.0,
        AimWalkSpeedMultiplier = 0.60,

        -- Equipment
        EquipTime = 0.5,
        UnequipTime = 0.4,

        -- Sounds (Asset IDs)
        FireSound = "rbxassetid://12345",
        ReloadSound = "rbxassetid://67890",
        EquipSound = "rbxassetid://11111",
        DryFireSound = "rbxassetid://22222",
        BoltSound = "rbxassetid://33333",

        -- Effects
        MuzzleFlashEffect = "MuzzleFlash",
        EjectionPort = "EjectionPort", -- Attachment name for shell ejection
        MuzzleFlashAttachment = "Muzzle",
        BulletTracerColor = Color3.fromRGB(255, 200, 100),
        BulletTracerSpeed = 0.1,

        -- Viewmodel
        ViewmodelPath = "ReplicatedStorage.FPSSystem.Viewmodels.Primary.AssaultRifles.M4A1",
        WeaponModelPath = "ReplicatedStorage.FPSSystem.WeaponModels.Primary.AssaultRifles.M4A1",

        -- Animations
        Animations = {
            Idle = "rbxassetid://idle_anim",
            Fire = "rbxassetid://fire_anim",
            Reload = "rbxassetid://reload_anim",
            ReloadEmpty = "rbxassetid://reload_empty_anim",
            Equip = "rbxassetid://equip_anim",
            Unequip = "rbxassetid://unequip_anim",
            Inspect = "rbxassetid://inspect_anim",
            Sprint = "rbxassetid://sprint_anim",
        },

        -- Attachments
        Attachments = {
            Sight = {
                {Name = "IronSights", UnlockKills = 0, Cost = 0},
                {Name = "RedDot", UnlockKills = 10, Cost = 300,
                    Modifiers = {AimSpeed = 0.95, ZoomLevel = 1.0}},
                {Name = "Holographic", UnlockKills = 50, Cost = 500,
                    Modifiers = {AimSpeed = 0.93, ZoomLevel = 1.0}},
                {Name = "ACOG_4x", UnlockKills = 200, Cost = 1500,
                    Modifiers = {AimSpeed = 0.80, ZoomLevel = 4.0, RecoilMultiplier = 0.95}},
            },
            Barrel = {
                {Name = "Standard", UnlockKills = 0, Cost = 0},
                {Name = "HeavyBarrel", UnlockKills = 300, Cost = 2000,
                    Modifiers = {Range = 1.25, BulletVelocity = 1.15, WalkSpeedMultiplier = 0.90}},
                {Name = "ShortBarrel", UnlockKills = 150, Cost = 1000,
                    Modifiers = {AimSpeed = 1.10, Range = 0.85, DamageMultiplier = 0.95}},
            },
            Underbarrel = {
                {Name = "VerticalGrip", UnlockKills = 50, Cost = 500,
                    Modifiers = {RecoilMultiplier = 0.85, AccuracyMultiplier = 1.05}},
                {Name = "AngledGrip", UnlockKills = 150, Cost = 1000,
                    Modifiers = {AimSpeed = 1.10, RecoilMultiplier = 1.05}},
            },
            Other = {
                {Name = "Suppressor", UnlockKills = 200, Cost = 1500,
                    Modifiers = {SuppressedRange = 50, DamageMultiplier = 0.95, BulletVelocity = 0.92}},
                {Name = "Laser", UnlockKills = 25, Cost = 400},
                {Name = "Flashlight", UnlockKills = 5, Cost = 200},
            },
        },

        -- Special Properties
        CanDamageVehicles = false,
        ArmorPiercing = false,
        VehicleDamageMultiplier = 0.1,
    },
}
```

### Client Script (LocalScript)

Place this in: `ServerStorage.WeaponTools.M4A1.LocalScript`

```lua
--[[
    M4A1 Client Script
    Handles firing, reloading, and animations for M4A1
]]

local Tool = script.Parent
local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)
local BallisticsSystem = require(ReplicatedStorage.FPSSystem.Modules.BallisticsSystem)
local AudioSystem = require(ReplicatedStorage.FPSSystem.Modules.AudioSystem)
local GlobalStateManager = require(ReplicatedStorage.FPSSystem.Modules.GlobalStateManager)

-- Remote Events
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponFired = RemoteEvents:WaitForChild("WeaponFired")
local WeaponReloaded = RemoteEvents:WaitForChild("WeaponReloaded")
local WeaponEquipped = RemoteEvents:WaitForChild("WeaponEquipped")
local WeaponUnequipped = RemoteEvents:WaitForChild("WeaponUnequipped")

-- Configuration
local Config = WeaponConfig:GetWeapon("M4A1")
if not Config then
    warn("M4A1 config not found!")
    return
end

-- Weapon State
local CurrentAmmo = Config.MagazineSize
local ReserveAmmo = Config.ReserveAmmo
local IsReloading = false
local IsFiring = false
local IsEquipped = false
local CurrentFireMode = Config.DefaultFireMode
local BurstCount = 0

-- Viewmodel
local Viewmodel = nil
local ViewmodelAnimations = {}

-- Mouse
local Mouse = Player:GetMouse()

-- Initialize Weapon
function Initialize()
    print("M4A1: Initializing...")

    -- Load viewmodel
    Viewmodel = ViewmodelSystem:LoadViewmodel(Config.ViewmodelPath)
    if not Viewmodel then
        warn("M4A1: Failed to load viewmodel")
        return
    end

    -- Load animations
    LoadAnimations()

    print("M4A1: Initialized")
end

-- Load Animations
function LoadAnimations()
    if not Viewmodel then return end

    local animator = Viewmodel:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
    if not animator then
        warn("M4A1: No animator found")
        return
    end

    for animName, animId in pairs(Config.Animations) do
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        ViewmodelAnimations[animName] = animator:LoadAnimation(anim)
    end

    print("M4A1: Loaded", #ViewmodelAnimations, "animations")
end

-- Equip
Tool.Equipped:Connect(function()
    print("M4A1: Equipped")
    IsEquipped = true

    -- Show viewmodel
    ViewmodelSystem:ShowViewmodel()

    -- Play equip animation
    if ViewmodelAnimations.Equip then
        ViewmodelAnimations.Equip:Play()
    end

    -- Play equip sound
    AudioSystem:PlaySound(Config.EquipSound, Tool.Handle)

    -- Notify server
    WeaponEquipped:FireServer("M4A1")

    -- Update player state
    GlobalStateManager:UpdatePlayerState(Player, "CurrentWeapon", "M4A1")

    -- Start idle animation after equip
    wait(Config.EquipTime)
    if ViewmodelAnimations.Idle then
        ViewmodelAnimations.Idle:Play()
    end
end)

-- Unequip
Tool.Unequipped:Connect(function()
    print("M4A1: Unequipped")
    IsEquipped = false
    IsFiring = false

    -- Play unequip animation
    if ViewmodelAnimations.Unequip then
        ViewmodelAnimations.Unequip:Play()
    end

    -- Hide viewmodel
    wait(Config.UnequipTime)
    ViewmodelSystem:HideViewmodel()

    -- Notify server
    WeaponUnequipped:FireServer("M4A1")

    -- Update player state
    GlobalStateManager:UpdatePlayerState(Player, "CurrentWeapon", nil)
end)

-- Fire Weapon
function Fire()
    if not IsEquipped or IsReloading or CurrentAmmo <= 0 then
        if CurrentAmmo <= 0 then
            -- Dry fire sound
            AudioSystem:PlaySound(Config.DryFireSound, Tool.Handle)
        end
        return
    end

    -- Consume ammo
    CurrentAmmo = CurrentAmmo - 1

    -- Get camera position and direction
    local camera = workspace.CurrentCamera
    local mousePosition = Mouse.Hit.Position
    local direction = (mousePosition - camera.CFrame.Position).Unit

    -- Apply spread
    direction = BallisticsSystem:ApplyWeaponSpread(direction, Config, Player)

    -- Fire projectile (client-side visualization)
    BallisticsSystem:FireHitscanVisual(camera.CFrame.Position, direction, Config)

    -- Play fire animation
    if ViewmodelAnimations.Fire then
        ViewmodelAnimations.Fire:Play()
    end

    -- Play fire sound
    AudioSystem:PlaySound(Config.FireSound, Tool.Handle)

    -- Create muzzle flash
    ViewmodelSystem:CreateMuzzleFlash(Viewmodel, Config.MuzzleFlashAttachment)

    -- Eject shell casing
    ViewmodelSystem:EjectShell(Viewmodel, Config.EjectionPort)

    -- Apply recoil
    ViewmodelSystem:ApplyRecoil(Config.RecoilVertical, Config.RecoilHorizontal)

    -- Notify server (server validates and deals damage)
    WeaponFired:FireServer("M4A1", camera.CFrame.Position, direction)

    -- Update ammo display
    UpdateAmmoDisplay()
end

-- Handle Mouse Button
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not IsEquipped then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsFiring = true

        if CurrentFireMode == "Auto" then
            -- Full auto: hold to fire
            while IsFiring and IsEquipped and CurrentAmmo > 0 and not IsReloading do
                Fire()
                wait(Config.FireRateSeconds)
            end
        elseif CurrentFireMode == "Semi" then
            -- Semi auto: one shot per click
            Fire()
        elseif CurrentFireMode == "Burst" then
            -- Burst: fire 3 rounds
            for i = 1, Config.BurstCount do
                if CurrentAmmo > 0 then
                    Fire()
                    wait(Config.FireRateSeconds)
                end
            end
        end
    elseif input.KeyCode == Enum.KeyCode.R then
        -- Reload
        Reload()
    elseif input.KeyCode == Enum.KeyCode.V then
        -- Switch fire mode
        SwitchFireMode()
    elseif input.KeyCode == Enum.KeyCode.H then
        -- Inspect weapon
        Inspect()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsFiring = false
    end
end)

-- Reload
function Reload()
    if IsReloading or CurrentAmmo == Config.MagazineSize or ReserveAmmo <= 0 then
        return
    end

    IsReloading = true
    print("M4A1: Reloading...")

    -- Play reload animation
    local reloadAnim = CurrentAmmo > 0 and ViewmodelAnimations.Reload or ViewmodelAnimations.ReloadEmpty
    if reloadAnim then
        reloadAnim:Play()
    end

    -- Play reload sound
    AudioSystem:PlaySound(Config.ReloadSound, Tool.Handle)

    -- Wait for reload time
    wait(Config.ReloadTime)

    -- Calculate ammo
    local ammoNeeded = Config.MagazineSize - CurrentAmmo
    local ammoToAdd = math.min(ammoNeeded, ReserveAmmo)

    CurrentAmmo = CurrentAmmo + ammoToAdd
    ReserveAmmo = ReserveAmmo - ammoToAdd

    IsReloading = false
    print("M4A1: Reloaded. Ammo:", CurrentAmmo, "/", ReserveAmmo)

    -- Update ammo display
    UpdateAmmoDisplay()

    -- Notify server
    WeaponReloaded:FireServer("M4A1", CurrentAmmo, ReserveAmmo)
end

-- Switch Fire Mode
function SwitchFireMode()
    local currentIndex = table.find(Config.FireModes, CurrentFireMode)
    if not currentIndex then return end

    local nextIndex = (currentIndex % #Config.FireModes) + 1
    CurrentFireMode = Config.FireModes[nextIndex]

    print("M4A1: Fire mode switched to", CurrentFireMode)

    -- Show UI notification
    -- (You can add a UI notification here)
end

-- Inspect Weapon
function Inspect()
    if IsReloading or IsFiring then return end

    print("M4A1: Inspecting...")

    if ViewmodelAnimations.Inspect then
        ViewmodelAnimations.Inspect:Play()
    else
        warn("M4A1: No inspect animation found")
    end
end

-- Update Ammo Display
function UpdateAmmoDisplay()
    -- Update HUD (you can create a UI module to handle this)
    print("M4A1: Ammo:", CurrentAmmo, "/", ReserveAmmo)
end

-- Initialize when script loads
Initialize()
```

### Customization Notes

**To create a new assault rifle based on M4A1**:

1. **Copy M4A1 config** in WeaponConfig
2. **Change Name** to new weapon name (e.g., "AK47")
3. **Adjust stats**:
   - Increase `Damage` for more damage
   - Decrease `FireRate` for slower fire
   - Increase `RecoilVertical` for more recoil
   - Adjust `MagazineSize` for different capacity
4. **Update paths**:
   - `ViewmodelPath`
   - `WeaponModelPath`
   - `Animations`
5. **Copy client script** and change weapon name references

---

## Example 2: Remington 700 Sniper Rifle

### Description

A bolt-action sniper rifle with:
- Very high damage
- Long range
- Slow fire rate
- Scoped by default

### WeaponConfig Entry

```lua
Weapons = {
    Remington700 = {
        Name = "Remington700",
        DisplayName = "Remington 700",
        Description = ".308 bolt-action sniper rifle",
        Category = "Primary",
        Subcategory = "SniperRifles",

        UnlockLevel = 10,
        UnlockCost = 5000,

        -- Bolt-action: one shot, then bolt cycle
        FireModes = {"Bolt"},
        DefaultFireMode = "Bolt",
        BoltCycleTime = 1.2, -- Seconds to cycle bolt

        -- Very high damage
        Damage = 120,
        HeadMultiplier = 3.0, -- One-shot headshot
        TorsoMultiplier = 1.5,
        LimbMultiplier = 1.0,

        -- Long range
        MaxRange = 1500,
        MinRange = 50,
        DamageDropoffStart = 800,
        DamageDropoffEnd = 1500,
        MinDamage = 60,

        -- Slow fire rate
        FireRate = 40, -- RPM (bolt-action)
        FireRateSeconds = 60 / 40,

        -- Small magazine
        MagazineSize = 5,
        ReserveAmmo = 35,
        ReloadTime = 3.5,

        -- Ballistics
        BulletVelocity = 1200, -- Very fast
        BulletGravity = true,
        BulletDrop = 0.3, -- Less drop than AR
        Penetration = 5, -- High penetration

        -- Low recoil per shot (but camera kick)
        RecoilVertical = 5.0, -- High visual recoil
        RecoilHorizontal = 0.3,
        RecoilRecoverySpeed = 0.5,

        -- Very accurate
        SpreadBase = 0.1,
        SpreadAiming = 0.05,
        SpreadMoving = 2.0,
        SpreadSprinting = 5.0,

        -- Slow handling
        AimSpeed = 0.5, -- Slow ADS
        WalkSpeedMultiplier = 0.85, -- Slow movement
        SprintSpeedMultiplier = 0.90,
        AimWalkSpeedMultiplier = 0.40, -- Very slow when aiming

        EquipTime = 1.0,
        UnequipTime = 0.8,

        -- Sounds
        FireSound = "rbxassetid://sniper_fire",
        BoltSound = "rbxassetid://bolt_cycle",
        ReloadSound = "rbxassetid://sniper_reload",
        EquipSound = "rbxassetid://sniper_equip",
        DryFireSound = "rbxassetid://dry_fire",

        -- Effects
        MuzzleFlashEffect = "SniperMuzzleFlash",
        EjectionPort = "EjectionPort",
        MuzzleFlashAttachment = "Muzzle",
        BulletTracerColor = Color3.fromRGB(255, 255, 200),
        BulletTracerSpeed = 0.05, -- Faster tracer

        -- Viewmodel
        ViewmodelPath = "ReplicatedStorage.FPSSystem.Viewmodels.Primary.SniperRifles.Remington700",
        WeaponModelPath = "ReplicatedStorage.FPSSystem.WeaponModels.Primary.SniperRifles.Remington700",

        -- Animations
        Animations = {
            Idle = "rbxassetid://sniper_idle",
            Fire = "rbxassetid://sniper_fire_anim",
            BoltCycle = "rbxassetid://bolt_cycle_anim",
            Reload = "rbxassetid://sniper_reload_anim",
            ReloadEmpty = "rbxassetid://sniper_reload_empty",
            Equip = "rbxassetid://sniper_equip_anim",
            Unequip = "rbxassetid://sniper_unequip_anim",
            Inspect = "rbxassetid://sniper_inspect",
            Sprint = "rbxassetid://sniper_sprint",
        },

        -- Scope by default
        DefaultScope = "Scope_6x",

        -- Attachments
        Attachments = {
            Sight = {
                {Name = "Scope_6x", UnlockKills = 0, Cost = 0,
                    Modifiers = {ZoomLevel = 6.0, AimSpeed = 0.90}},
                {Name = "Scope_8x", UnlockKills = 150, Cost = 1200,
                    Modifiers = {ZoomLevel = 8.0, AimSpeed = 0.85}},
                {Name = "Scope_12x", UnlockKills = 500, Cost = 3000,
                    Modifiers = {ZoomLevel = 12.0, AimSpeed = 0.75}},
            },
            Barrel = {
                {Name = "Standard", UnlockKills = 0, Cost = 0},
                {Name = "HeavyBarrel", UnlockKills = 400, Cost = 2500,
                    Modifiers = {Range = 1.5, BulletVelocity = 1.2, WalkSpeedMultiplier = 0.80}},
            },
            Underbarrel = {
                {Name = "Bipod", UnlockKills = 200, Cost = 1500,
                    Modifiers = {RecoilMultiplier = 0.50, RequiresProne = true}},
            },
            Other = {
                {Name = "Suppressor", UnlockKills = 300, Cost = 2500,
                    Modifiers = {SuppressedRange = 100, DamageMultiplier = 0.95}},
                {Name = "MuzzleBrake", UnlockKills = 100, Cost = 800,
                    Modifiers = {RecoilMultiplier = 0.80}},
            },
        },

        -- Special properties
        CanDamageVehicles = false, -- Needs AP ammo
        ArmorPiercing = false,
        VehicleDamageMultiplier = 0.2,

        -- Bolt-action specific
        RequiresBoltCycle = true,
    },
}
```

### Special Notes for Bolt-Action

**Bolt-action weapons require bolt cycling** after each shot:

```lua
-- In client script:
function Fire()
    if not CanFire() then return end

    -- Fire shot
    FireProjectile()

    -- Start bolt cycle
    if Config.RequiresBoltCycle then
        IsBoltCycling = true

        -- Play bolt animation
        if ViewmodelAnimations.BoltCycle then
            ViewmodelAnimations.BoltCycle:Play()
        end

        -- Play bolt sound
        AudioSystem:PlaySound(Config.BoltSound, Tool.Handle)

        -- Wait for bolt cycle
        wait(Config.BoltCycleTime)

        IsBoltCycling = false
    end
end
```

---

## Example 3: Glock 17 Pistol

### Description

A semi-automatic pistol with:
- Moderate damage
- Fast fire rate for pistol
- High accuracy
- Quick handling

### WeaponConfig Entry

```lua
Weapons = {
    Glock17 = {
        Name = "Glock17",
        DisplayName = "Glock 17",
        Description = "9mm semi-automatic pistol",
        Category = "Secondary",
        Subcategory = "Pistols",

        UnlockLevel = 0,
        UnlockCost = 0,

        -- Semi-auto only
        FireModes = {"Semi"},
        DefaultFireMode = "Semi",

        -- Moderate damage
        Damage = 25,
        HeadMultiplier = 2.5,
        TorsoMultiplier = 1.0,
        LimbMultiplier = 0.8,

        -- Short range
        MaxRange = 300,
        MinRange = 5,
        DamageDropoffStart = 100,
        DamageDropoffEnd = 300,
        MinDamage = 12,

        -- Fast for pistol
        FireRate = 400, -- RPM
        FireRateSeconds = 60 / 400,

        -- Standard pistol mag
        MagazineSize = 17,
        ReserveAmmo = 85,
        ReloadTime = 1.8,

        -- Ballistics
        BulletVelocity = 600,
        BulletGravity = true,
        BulletDrop = 1.0,
        Penetration = 1,

        -- Low recoil
        RecoilVertical = 2.0,
        RecoilHorizontal = 1.0,
        RecoilRecoverySpeed = 0.3,

        -- Accurate
        SpreadBase = 1.5,
        SpreadAiming = 0.3,
        SpreadMoving = 2.5,
        SpreadSprinting = 4.0,

        -- Fast handling
        AimSpeed = 0.15, -- Very fast ADS
        WalkSpeedMultiplier = 1.0, -- No movement penalty
        SprintSpeedMultiplier = 1.0,
        AimWalkSpeedMultiplier = 0.85,

        EquipTime = 0.3,
        UnequipTime = 0.2,

        -- Sounds
        FireSound = "rbxassetid://pistol_fire",
        ReloadSound = "rbxassetid://pistol_reload",
        EquipSound = "rbxassetid://pistol_equip",
        DryFireSound = "rbxassetid://dry_fire",
        SlideSound = "rbxassetid://pistol_slide",

        -- Effects
        MuzzleFlashEffect = "PistolMuzzleFlash",
        EjectionPort = "EjectionPort",
        MuzzleFlashAttachment = "Muzzle",
        BulletTracerColor = Color3.fromRGB(255, 255, 100),

        -- Viewmodel
        ViewmodelPath = "ReplicatedStorage.FPSSystem.Viewmodels.Secondary.Pistols.Glock17",
        WeaponModelPath = "ReplicatedStorage.FPSSystem.WeaponModels.Secondary.Pistols.Glock17",

        -- Animations
        Animations = {
            Idle = "rbxassetid://pistol_idle",
            Fire = "rbxassetid://pistol_fire_anim",
            Reload = "rbxassetid://pistol_reload_anim",
            ReloadEmpty = "rbxassetid://pistol_reload_empty",
            Equip = "rbxassetid://pistol_equip_anim",
            Unequip = "rbxassetid://pistol_unequip_anim",
            Inspect = "rbxassetid://pistol_inspect",
            Sprint = "rbxassetid://pistol_sprint",
        },

        -- Attachments
        Attachments = {
            Sight = {
                {Name = "IronSights", UnlockKills = 0, Cost = 0},
                {Name = "MiniRedDot", UnlockKills = 100, Cost = 800,
                    Modifiers = {AimSpeed = 0.97, ZoomLevel = 1.0}},
            },
            Barrel = {
                {Name = "Standard", UnlockKills = 0, Cost = 0},
                {Name = "ExtendedBarrel", UnlockKills = 200, Cost = 1500,
                    Modifiers = {Range = 1.2, BulletVelocity = 1.1}},
            },
            Other = {
                {Name = "PistolSuppressor", UnlockKills = 150, Cost = 1200,
                    Modifiers = {SuppressedRange = 30, DamageMultiplier = 0.97}},
                {Name = "Laser", UnlockKills = 50, Cost = 400},
                {Name = "Flashlight", UnlockKills = 25, Cost = 300},
                {Name = "ExtendedMag", UnlockKills = 100, Cost = 800,
                    Modifiers = {MagazineSize = 10}}, -- +10 rounds
            },
        },

        CanDamageVehicles = false,
        ArmorPiercing = false,
        VehicleDamageMultiplier = 0.05,
    },
}
```

---

## Example 4: Remington 870 Shotgun

### Description

A pump-action shotgun with:
- High close-range damage
- Pellet spread
- Slow fire rate
- Ammo type conversions

### WeaponConfig Entry

```lua
Weapons = {
    Remington870 = {
        Name = "Remington870",
        DisplayName = "Remington 870",
        Description = "12-gauge pump-action shotgun",
        Category = "Primary",
        Subcategory = "Shotguns",

        UnlockLevel = 5,
        UnlockCost = 2000,

        -- Pump-action
        FireModes = {"Pump", "Burst"}, -- Can fire both barrels at once
        DefaultFireMode = "Pump",
        PumpTime = 0.8, -- Time to pump

        -- High damage per pellet
        Damage = 25,
        PelletCount = 8, -- 8 pellets per shot
        HeadMultiplier = 1.5,
        TorsoMultiplier = 1.0,
        LimbMultiplier = 0.9,

        -- Short range
        MaxRange = 150,
        MinRange = 0,
        DamageDropoffStart = 30,
        DamageDropoffEnd = 150,
        MinDamage = 8, -- Per pellet

        -- Slow fire rate
        FireRate = 60, -- RPM
        FireRateSeconds = 60 / 60,

        -- Small magazine
        MagazineSize = 6,
        ReserveAmmo = 30,
        ReloadTime = 0.6, -- Per shell
        ReloadType = "Individual", -- Load one shell at a time

        -- Ballistics
        BulletVelocity = 400, -- Slow projectiles
        BulletGravity = true,
        BulletDrop = 2.0, -- High drop
        Penetration = 0, -- Pellets don't penetrate

        -- Pellet spread
        PelletSpread = 8.0, -- Degrees
        PelletSpreadIncrease = 0, -- No increase (one shot at a time)

        -- High recoil
        RecoilVertical = 8.0,
        RecoilHorizontal = 2.0,
        RecoilRecoverySpeed = 0.4,

        -- Spread not applicable (uses pellet spread)
        SpreadBase = 0,
        SpreadAiming = 0,

        -- Handling
        AimSpeed = 0.35,
        WalkSpeedMultiplier = 0.90,
        SprintSpeedMultiplier = 0.95,
        AimWalkSpeedMultiplier = 0.70,

        EquipTime = 0.6,
        UnequipTime = 0.5,

        -- Sounds
        FireSound = "rbxassetid://shotgun_fire",
        PumpSound = "rbxassetid://shotgun_pump",
        ReloadSound = "rbxassetid://shotgun_reload_shell",
        EquipSound = "rbxassetid://shotgun_equip",
        DryFireSound = "rbxassetid://dry_fire",

        -- Effects
        MuzzleFlashEffect = "ShotgunMuzzleFlash",
        EjectionPort = "EjectionPort",
        MuzzleFlashAttachment = "Muzzle",
        BulletTracerColor = Color3.fromRGB(255, 200, 50),

        -- Viewmodel
        ViewmodelPath = "ReplicatedStorage.FPSSystem.Viewmodels.Primary.Shotguns.Remington870",
        WeaponModelPath = "ReplicatedStorage.FPSSystem.WeaponModels.Primary.Shotguns.Remington870",

        -- Animations
        Animations = {
            Idle = "rbxassetid://shotgun_idle",
            Fire = "rbxassetid://shotgun_fire_anim",
            Pump = "rbxassetid://shotgun_pump_anim",
            ReloadStart = "rbxassetid://shotgun_reload_start",
            ReloadShell = "rbxassetid://shotgun_reload_shell_anim",
            ReloadEnd = "rbxassetid://shotgun_reload_end",
            Equip = "rbxassetid://shotgun_equip_anim",
            Unequip = "rbxassetid://shotgun_unequip_anim",
            Inspect = "rbxassetid://shotgun_inspect",
            Sprint = "rbxassetid://shotgun_sprint",
        },

        -- Attachments
        Attachments = {
            Sight = {
                {Name = "BeadSight", UnlockKills = 0, Cost = 0},
                {Name = "RedDot", UnlockKills = 50, Cost = 500},
            },
            Barrel = {
                {Name = "Standard", UnlockKills = 0, Cost = 0},
                {Name = "FullChoke", UnlockKills = 100, Cost = 800,
                    Modifiers = {PelletSpread = 0.70, Range = 1.2}}, -- Tighter spread
                {Name = "SawedOff", UnlockKills = 250, Cost = 2000,
                    Modifiers = {PelletSpread = 1.5, WalkSpeedMultiplier = 1.05, Range = 0.70}},
            },
            Underbarrel = {
                {Name = "Foregrip", UnlockKills = 75, Cost = 600,
                    Modifiers = {RecoilMultiplier = 0.85}},
            },
            Other = {
                {Name = "Birdshot", UnlockKills = 50, Cost = 500,
                    Modifiers = {PelletCount = 18, DamageMultiplier = 0.60, PelletSpread = 1.3}},
                {Name = "Slugs", UnlockKills = 200, Cost = 1500,
                    Modifiers = {PelletCount = 1, DamageMultiplier = 2.5, Range = 2.0, PelletSpread = 0.1}},
                {Name = "DragonsBreath", UnlockKills = 500, Cost = 3500,
                    Modifiers = {PelletCount = 8, DamageMultiplier = 0.70, StatusEffect = "Burn"}},
                {Name = "Laser", UnlockKills = 25, Cost = 400},
            },
        },

        -- Shotgun specific
        IsShotgun = true,
        RequiresPump = true,

        CanDamageVehicles = false,
        ArmorPiercing = false,
    },
}
```

### Shotgun-Specific Logic

**Individual shell reloading**:

```lua
-- Reload one shell at a time
function ReloadShotgun()
    IsReloading = true

    -- Play reload start animation
    if ViewmodelAnimations.ReloadStart then
        ViewmodelAnimations.ReloadStart:Play()
        wait(0.5)
    end

    -- Load shells individually
    while CurrentAmmo < Config.MagazineSize and ReserveAmmo > 0 and IsReloading do
        -- Play shell insert animation
        if ViewmodelAnimations.ReloadShell then
            ViewmodelAnimations.ReloadShell:Play()
        end

        -- Play shell sound
        AudioSystem:PlaySound(Config.ReloadSound, Tool.Handle)

        -- Wait for reload time per shell
        wait(Config.ReloadTime)

        -- Add one shell
        CurrentAmmo = CurrentAmmo + 1
        ReserveAmmo = ReserveAmmo - 1

        UpdateAmmoDisplay()
    end

    -- Play reload end animation
    if ViewmodelAnimations.ReloadEnd then
        ViewmodelAnimations.ReloadEnd:Play()
        wait(0.3)
    end

    IsReloading = false
end

-- Can interrupt reload
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if IsReloading then
            IsReloading = false -- Stop reloading to fire
        end
    end
end)
```

---

## Example 5: RPG-7 Launcher

### Description

An explosive launcher with:
- Very high damage
- Explosion radius
- Slow reload
- Limited ammo

### WeaponConfig Entry

```lua
Weapons = {
    RPG7 = {
        Name = "RPG7",
        DisplayName = "RPG-7",
        Description = "Rocket-propelled grenade launcher",
        Category = "Primary",
        Subcategory = "Launchers",

        UnlockLevel = 20,
        UnlockCost = 10000,

        FireModes = {"Single"},
        DefaultFireMode = "Single",

        -- Explosion damage
        Damage = 500, -- Direct hit
        ExplosionDamage = 200, -- Splash damage
        ExplosionRadius = 20, -- Studs
        HeadMultiplier = 1.0, -- Explosions don't have headshots
        TorsoMultiplier = 1.0,
        LimbMultiplier = 1.0,

        -- Long range
        MaxRange = 800,
        MinRange = 10, -- Minimum arm distance
        DamageDropoffStart = 0, -- No dropoff (explosion)
        DamageDropoffEnd = 0,

        -- Very slow fire rate
        FireRate = 10, -- RPM
        FireRateSeconds = 60 / 10,

        -- Small ammo pool
        MagazineSize = 1,
        ReserveAmmo = 5,
        ReloadTime = 5.0, -- Very slow reload

        -- Projectile ballistics
        ProjectileType = "Rocket",
        BulletVelocity = 150, -- Slow rocket
        BulletGravity = false, -- Rocket-powered (no drop)
        BulletDrop = 0,
        Penetration = 0,

        -- High recoil
        RecoilVertical = 15.0,
        RecoilHorizontal = 3.0,
        RecoilRecoverySpeed = 1.0,

        -- No spread (rockets go straight)
        SpreadBase = 0,
        SpreadAiming = 0,

        -- Very slow handling
        AimSpeed = 0.8,
        WalkSpeedMultiplier = 0.70, -- Very slow with RPG
        SprintSpeedMultiplier = 0.80,
        AimWalkSpeedMultiplier = 0.50,

        EquipTime = 1.2,
        UnequipTime = 1.0,

        -- Sounds
        FireSound = "rbxassetid://rpg_fire",
        ReloadSound = "rbxassetid://rpg_reload",
        ExplosionSound = "rbxassetid://rpg_explosion",
        EquipSound = "rbxassetid://rpg_equip",
        DryFireSound = "rbxassetid://dry_fire",

        -- Effects
        MuzzleFlashEffect = "RPGMuzzleFlash",
        MuzzleFlashAttachment = "Muzzle",
        RocketTrailEffect = "RocketTrail",
        ExplosionEffect = "LargeExplosion",

        -- Viewmodel
        ViewmodelPath = "ReplicatedStorage.FPSSystem.Viewmodels.Primary.Launchers.RPG7",
        WeaponModelPath = "ReplicatedStorage.FPSSystem.WeaponModels.Primary.Launchers.RPG7",

        -- Animations
        Animations = {
            Idle = "rbxassetid://rpg_idle",
            Fire = "rbxassetid://rpg_fire_anim",
            Reload = "rbxassetid://rpg_reload_anim",
            Equip = "rbxassetid://rpg_equip_anim",
            Unequip = "rbxassetid://rpg_unequip_anim",
            Inspect = "rbxassetid://rpg_inspect",
            Sprint = "rbxassetid://rpg_sprint",
        },

        -- No attachments for RPG
        Attachments = {},

        -- Special properties
        CanDamageVehicles = true,
        ArmorPiercing = true,
        VehicleDamageMultiplier = 5.0, -- Extreme damage to vehicles

        -- Explosion properties
        ExplosionPressure = 500000,
        ExplosionBlastRadius = 20,
        ExplosionDestroysBuildings = true,

        -- Rocket properties
        RocketAcceleration = 200, -- Accelerates after firing
        RocketMaxSpeed = 300,
        RocketLifetime = 10, -- Seconds before self-destruct
        RocketArmDistance = 10, -- Minimum distance before explosion
    },
}
```

---

## Example 6: MP5 SMG

### Description

A submachine gun with:
- Fast fire rate
- Low damage
- High mobility
- Good for close quarters

### WeaponConfig Entry

```lua
Weapons = {
    MP5 = {
        Name = "MP5",
        DisplayName = "MP5",
        Description = "9mm submachine gun",
        Category = "Primary",
        Subcategory = "SMGs",

        UnlockLevel = 3,
        UnlockCost = 1500,

        FireModes = {"Auto", "Burst"},
        DefaultFireMode = "Auto",
        BurstCount = 3,

        -- Low damage
        Damage = 22,
        HeadMultiplier = 2.0,
        TorsoMultiplier = 1.0,
        LimbMultiplier = 0.75,

        -- Short range
        MaxRange = 300,
        MinRange = 5,
        DamageDropoffStart = 100,
        DamageDropoffEnd = 300,
        MinDamage = 10,

        -- Very fast fire rate
        FireRate = 900, -- RPM
        FireRateSeconds = 60 / 900,

        -- Standard SMG mag
        MagazineSize = 30,
        ReserveAmmo = 180,
        ReloadTime = 2.0,

        -- Ballistics
        BulletVelocity = 700,
        BulletGravity = true,
        BulletDrop = 0.8,
        Penetration = 1,

        -- Moderate recoil
        RecoilVertical = 1.5,
        RecoilHorizontal = 1.2,
        RecoilRecoverySpeed = 0.25,

        -- Good accuracy
        SpreadBase = 2.5,
        SpreadAiming = 0.8,
        SpreadMoving = 3.0,
        SpreadSprinting = 4.5,
        SpreadIncrease = 0.2,
        SpreadMax = 7.0,

        -- Fast handling (SMG advantage)
        AimSpeed = 0.20,
        WalkSpeedMultiplier = 1.05, -- Faster movement
        SprintSpeedMultiplier = 1.10,
        AimWalkSpeedMultiplier = 0.75,

        EquipTime = 0.4,
        UnequipTime = 0.3,

        -- Sounds
        FireSound = "rbxassetid://smg_fire",
        ReloadSound = "rbxassetid://smg_reload",
        EquipSound = "rbxassetid://smg_equip",
        DryFireSound = "rbxassetid://dry_fire",

        -- Effects
        MuzzleFlashEffect = "SMGMuzzleFlash",
        EjectionPort = "EjectionPort",
        MuzzleFlashAttachment = "Muzzle",
        BulletTracerColor = Color3.fromRGB(255, 200, 100),

        -- Viewmodel
        ViewmodelPath = "ReplicatedStorage.FPSSystem.Viewmodels.Primary.SMGs.MP5",
        WeaponModelPath = "ReplicatedStorage.FPSSystem.WeaponModels.Primary.SMGs.MP5",

        -- Animations
        Animations = {
            Idle = "rbxassetid://smg_idle",
            Fire = "rbxassetid://smg_fire_anim",
            Reload = "rbxassetid://smg_reload_anim",
            ReloadEmpty = "rbxassetid://smg_reload_empty",
            Equip = "rbxassetid://smg_equip_anim",
            Unequip = "rbxassetid://smg_unequip_anim",
            Inspect = "rbxassetid://smg_inspect",
            Sprint = "rbxassetid://smg_sprint",
        },

        -- Attachments
        Attachments = {
            Sight = {
                {Name = "IronSights", UnlockKills = 0, Cost = 0},
                {Name = "RedDot", UnlockKills = 20, Cost = 300},
                {Name = "Holographic", UnlockKills = 75, Cost = 600},
            },
            Barrel = {
                {Name = "Standard", UnlockKills = 0, Cost = 0},
                {Name = "ExtendedBarrel", UnlockKills = 150, Cost = 1000,
                    Modifiers = {Range = 1.2, BulletVelocity = 1.1, WalkSpeedMultiplier = 0.98}},
            },
            Underbarrel = {
                {Name = "VerticalGrip", UnlockKills = 50, Cost = 400,
                    Modifiers = {RecoilMultiplier = 0.90}},
            },
            Other = {
                {Name = "Suppressor", UnlockKills = 100, Cost = 800,
                    Modifiers = {SuppressedRange = 40, DamageMultiplier = 0.97}},
                {Name = "ExtendedMag", UnlockKills = 75, Cost = 600,
                    Modifiers = {MagazineSize = 15}}, -- +15 rounds
                {Name = "Laser", UnlockKills = 15, Cost = 300},
            },
        },

        CanDamageVehicles = false,
        ArmorPiercing = false,
        VehicleDamageMultiplier = 0.05,
    },
}
```

---

## Universal Client Script Template

This template works for **most weapon types** with minimal customization:

```lua
--[[
    Universal Weapon Client Script
    Works for: Assault Rifles, SMGs, Pistols, Sniper Rifles, Shotguns

    Customize:
    - Change WEAPON_NAME to your weapon's name
    - Add special logic for weapon-specific features
]]

local WEAPON_NAME = "M4A1" -- CHANGE THIS

local Tool = script.Parent
local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)
local BallisticsSystem = require(ReplicatedStorage.FPSSystem.Modules.BallisticsSystem)
local AudioSystem = require(ReplicatedStorage.FPSSystem.Modules.AudioSystem)
local GlobalStateManager = require(ReplicatedStorage.FPSSystem.Modules.GlobalStateManager)

-- Remote Events
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponFired = RemoteEvents:WaitForChild("WeaponFired")
local WeaponReloaded = RemoteEvents:WaitForChild("WeaponReloaded")
local WeaponEquipped = RemoteEvents:WaitForChild("WeaponEquipped")
local WeaponUnequipped = RemoteEvents:WaitForChild("WeaponUnequipped")

-- Config
local Config = WeaponConfig:GetWeapon(WEAPON_NAME)
if not Config then
    warn(WEAPON_NAME .. " config not found!")
    return
end

-- State
local CurrentAmmo = Config.MagazineSize
local ReserveAmmo = Config.ReserveAmmo
local IsReloading = false
local IsFiring = false
local IsEquipped = false
local CurrentFireMode = Config.DefaultFireMode

-- Viewmodel
local Viewmodel = nil
local ViewmodelAnimations = {}

-- Mouse
local Mouse = Player:GetMouse()

-- Initialize
function Initialize()
    print(WEAPON_NAME .. ": Initializing...")
    Viewmodel = ViewmodelSystem:LoadViewmodel(Config.ViewmodelPath)
    if Viewmodel then
        LoadAnimations()
    end
    print(WEAPON_NAME .. ": Initialized")
end

-- Load Animations
function LoadAnimations()
    local animator = Viewmodel:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
    if not animator then return end

    for animName, animId in pairs(Config.Animations) do
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        ViewmodelAnimations[animName] = animator:LoadAnimation(anim)
    end
end

-- Equip
Tool.Equipped:Connect(function()
    IsEquipped = true
    ViewmodelSystem:ShowViewmodel()

    if ViewmodelAnimations.Equip then
        ViewmodelAnimations.Equip:Play()
    end

    AudioSystem:PlaySound(Config.EquipSound, Tool.Handle)
    WeaponEquipped:FireServer(WEAPON_NAME)
    GlobalStateManager:UpdatePlayerState(Player, "CurrentWeapon", WEAPON_NAME)

    wait(Config.EquipTime)
    if ViewmodelAnimations.Idle then
        ViewmodelAnimations.Idle:Play()
    end
end)

-- Unequip
Tool.Unequipped:Connect(function()
    IsEquipped = false
    IsFiring = false

    if ViewmodelAnimations.Unequip then
        ViewmodelAnimations.Unequip:Play()
    end

    wait(Config.UnequipTime)
    ViewmodelSystem:HideViewmodel()
    WeaponUnequipped:FireServer(WEAPON_NAME)
    GlobalStateManager:UpdatePlayerState(Player, "CurrentWeapon", nil)
end)

-- Fire
function Fire()
    if not IsEquipped or IsReloading or CurrentAmmo <= 0 then
        if CurrentAmmo <= 0 then
            AudioSystem:PlaySound(Config.DryFireSound, Tool.Handle)
        end
        return
    end

    CurrentAmmo = CurrentAmmo - 1

    local camera = workspace.CurrentCamera
    local mousePosition = Mouse.Hit.Position
    local direction = (mousePosition - camera.CFrame.Position).Unit

    direction = BallisticsSystem:ApplyWeaponSpread(direction, Config, Player)

    -- Visual effects
    BallisticsSystem:FireHitscanVisual(camera.CFrame.Position, direction, Config)

    if ViewmodelAnimations.Fire then
        ViewmodelAnimations.Fire:Play()
    end

    AudioSystem:PlaySound(Config.FireSound, Tool.Handle)
    ViewmodelSystem:CreateMuzzleFlash(Viewmodel, Config.MuzzleFlashAttachment)
    ViewmodelSystem:EjectShell(Viewmodel, Config.EjectionPort)
    ViewmodelSystem:ApplyRecoil(Config.RecoilVertical, Config.RecoilHorizontal)

    -- Server validation
    WeaponFired:FireServer(WEAPON_NAME, camera.CFrame.Position, direction)

    UpdateAmmoDisplay()
end

-- Mouse Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not IsEquipped then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsFiring = true

        if CurrentFireMode == "Auto" then
            while IsFiring and IsEquipped and CurrentAmmo > 0 and not IsReloading do
                Fire()
                wait(Config.FireRateSeconds)
            end
        elseif CurrentFireMode == "Semi" then
            Fire()
        elseif CurrentFireMode == "Burst" then
            for i = 1, Config.BurstCount or 3 do
                if CurrentAmmo > 0 then
                    Fire()
                    wait(Config.FireRateSeconds)
                end
            end
        end
    elseif input.KeyCode == Enum.KeyCode.R then
        Reload()
    elseif input.KeyCode == Enum.KeyCode.V then
        SwitchFireMode()
    elseif input.KeyCode == Enum.KeyCode.H then
        Inspect()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsFiring = false
    end
end)

-- Reload
function Reload()
    if IsReloading or CurrentAmmo == Config.MagazineSize or ReserveAmmo <= 0 then
        return
    end

    IsReloading = true

    local reloadAnim = CurrentAmmo > 0 and ViewmodelAnimations.Reload or ViewmodelAnimations.ReloadEmpty
    if reloadAnim then
        reloadAnim:Play()
    end

    AudioSystem:PlaySound(Config.ReloadSound, Tool.Handle)
    wait(Config.ReloadTime)

    local ammoNeeded = Config.MagazineSize - CurrentAmmo
    local ammoToAdd = math.min(ammoNeeded, ReserveAmmo)

    CurrentAmmo = CurrentAmmo + ammoToAdd
    ReserveAmmo = ReserveAmmo - ammoToAdd

    IsReloading = false
    UpdateAmmoDisplay()
    WeaponReloaded:FireServer(WEAPON_NAME, CurrentAmmo, ReserveAmmo)
end

-- Switch Fire Mode
function SwitchFireMode()
    local currentIndex = table.find(Config.FireModes, CurrentFireMode)
    if not currentIndex then return end

    local nextIndex = (currentIndex % #Config.FireModes) + 1
    CurrentFireMode = Config.FireModes[nextIndex]

    print(WEAPON_NAME .. ": Fire mode switched to " .. CurrentFireMode)
end

-- Inspect
function Inspect()
    if IsReloading or IsFiring then return end

    if ViewmodelAnimations.Inspect then
        ViewmodelAnimations.Inspect:Play()
    else
        warn(WEAPON_NAME .. ": No inspect animation")
    end
end

-- Update Ammo Display
function UpdateAmmoDisplay()
    print(WEAPON_NAME .. ": Ammo: " .. CurrentAmmo .. "/" .. ReserveAmmo)
    -- TODO: Update UI element
end

-- Initialize
Initialize()
```

---

## Customization Guide

### Creating Variants

**To create a weapon variant** (e.g., AK47 from M4A1):

1. **Copy config** from existing weapon
2. **Change basic info**:
   ```lua
   Name = "AK47"
   DisplayName = "AK-47"
   Description = "7.62mm assault rifle"
   ```
3. **Adjust stats**:
   ```lua
   Damage = 35 -- Higher damage
   FireRate = 600 -- Slower fire rate
   RecoilVertical = 2.0 -- More recoil
   MagazineSize = 30
   ```
4. **Update paths**:
   ```lua
   ViewmodelPath = "...AK47"
   WeaponModelPath = "...AK47"
   ```
5. **Change sounds/animations** to asset IDs
6. **Copy client script** and change `WEAPON_NAME`

### Balancing Weapons

**Use these formulas** for balanced gameplay:

**DPS (Damage Per Second)**:
```
DPS = (Damage * FireRate) / 60
```

Example:
- M4A1: (30 * 750) / 60 = 375 DPS
- AK47: (35 * 600) / 60 = 350 DPS

**TTK (Time To Kill)** for 100 HP target:
```
TTK = (100 / Damage) * (60 / FireRate)
```

**Effective Range** sweet spot:
- SMGs: 50-150 studs
- ARs: 100-300 studs
- DMRs: 200-500 studs
- Snipers: 300-1000+ studs

---

## Summary

This document provided **6 complete weapon examples**:

1. **M4A1**: Standard assault rifle
2. **Remington 700**: Bolt-action sniper
3. **Glock 17**: Semi-auto pistol
4. **Remington 870**: Pump shotgun
5. **RPG-7**: Explosive launcher
6. **MP5**: Fast SMG

Each example includes:
- Complete WeaponConfig entry
- All relevant stats
- Attachment configurations
- Special mechanics (bolt-action, pump-action, explosions)
- Customization notes

**Use these as templates** for creating your own weapons!

---

**Document Version:** 1.0
**Last Updated:** 2025-10-12
**Maintained By:** FPS System Team
