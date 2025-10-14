# Weapon System Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Weapon Categories & Types](#weapon-categories--types)
3. [Adding a New Weapon](#adding-a-new-weapon)
4. [WeaponConfig Setup](#weaponconfig-setup)
5. [Tool Creation](#tool-creation)
6. [Viewmodel Setup](#viewmodel-setup)
7. [Weapon Models](#weapon-models)
8. [Client Scripts](#client-scripts)
9. [Animation Integration](#animation-integration)
10. [Testing Checklist](#testing-checklist)
11. [Troubleshooting](#troubleshooting)

---

## Overview

The FPS weapon system is built around several key components:
- **WeaponConfig.lua**: Central configuration for all weapon stats
- **Tool System**: Roblox tools that hold weapon models
- **Viewmodels**: First-person weapon models visible only to the player
- **Client Scripts**: Handle firing, reloading, and weapon logic
- **Server Handlers**: Validate and process weapon actions

All weapons follow a consistent structure for easy maintenance and balancing.

---

## Weapon Categories & Types

### Primary Weapons
- **AssaultRifles**: G36, AK47, M4A1, SCAR, etc.
- **BattleRifles**: FAL, SCAR-H, etc.
- **Carbines**: M4 Carbine, etc.
- **Shotguns**: Double Barrel, Sawed Off, etc.
- **DMRs**: Designated Marksman Rifles
- **LMGs**: M249, etc.
- **PDW/SMGs**: MP5, UMP45, P90, etc.
- **SniperRifles**: Barrett, AWP, Intervention, NTW-20

### Secondary Weapons
- **Pistols**: M9, Glock, 1911, USP, P250
- **AutoPistols**: Automatic pistols
- **Revolvers**: Magnum, etc.
- **Other**: Special secondaries

### Melee Weapons
- **OneHandBlade**: Knives, etc. (faster, backstab bonus)
- **TwoHandBlade**: Katana, Machete, etc. (slower, more range)
- **OneHandBlunt**: Bats, etc.
- **TwoHandBlunt**: Hammers, etc.

### Grenades
- **Frag**: M67, Impact Grenades
- **HighExplosive**: High damage grenades
- **Other**: Flashbangs, Smoke, C4, Flares

### Special
- **Magic Weapons**: ViciousStinger, NTW20_Admin, etc.

---

## Adding a New Weapon

### Step 1: Plan Your Weapon

Before adding a weapon, decide:
1. **Category**: Primary, Secondary, Melee, Grenade, or Special?
2. **Type**: Which subcategory?
3. **Class Restrictions**: Which classes can use it?
4. **Stats**: Damage, fire rate, accuracy, range, etc.
5. **Unlock Requirements**: Level and cost
6. **Attachments**: Compatible attachments

### Step 2: Add to WeaponConfig.lua

Open `src/ReplicatedStorage/FPSSystem/Modules/WeaponConfig.lua` and add your weapon to the `WEAPON_CONFIGS` table.

**Example: Adding a new Assault Rifle**

```lua
["YourWeaponName"] = {
    -- Basic Information
    Name = "Your Weapon Display Name",
    Type = "AssaultRifles",
    Category = "Primary",
    Class = "Assault", -- or "Universal" for all classes
    UnlockLevel = 5,
    UnlockCost = 0,
    PreBuyCost = 1500, -- Cost to buy before unlock level

    -- Damage Stats
    Damage = 35,
    HeadshotMultiplier = 2.0,
    BodyMultiplier = 1.0,
    LimbMultiplier = 0.8,

    -- Range and Ballistics
    Range = 1000, -- Maximum effective range in studs
    MinRange = 100, -- Minimum range before damage falloff
    MaxRange = 1500, -- Absolute maximum range
    BulletVelocity = 800, -- Studs per second
    BulletDrop = 9.81, -- Gravity effect
    Penetration = 2.5, -- How many surfaces it can penetrate
    PenetrationPower = 65, -- Damage retention through walls

    -- Ammo Types and Effects
    AmmoType = "556",
    AvailableAmmoTypes = {
        Standard = {Damage = 1.0, Penetration = 1.0, Velocity = 1.0},
        FMJ = {Damage = 0.95, Penetration = 1.5, Velocity = 1.1},
        AP = {Damage = 0.85, Penetration = 2.0, Velocity = 1.2, HeadshotMultiplier = 0.8},
        HP = {Damage = 1.2, Penetration = 0.5, Velocity = 0.9}
    },
    DefaultAmmoType = "Standard",

    -- Fire Rate and Ammo
    FireRate = 750, -- Rounds per minute
    MaxAmmo = 30, -- Magazine size
    MaxReserveAmmo = 120, -- Total ammo carried
    ReloadTime = 2.8, -- Seconds for tactical reload
    EmptyReloadTime = 3.2, -- Seconds for empty reload

    -- Accuracy and Recoil
    BaseSpread = 0.05, -- Base accuracy (lower = more accurate)
    AimSpread = 0.025, -- Accuracy when aiming
    MovingSpread = 0.08, -- Accuracy while moving

    Recoil = {
        Vertical = 0.8, -- Vertical recoil per shot
        Horizontal = 0.4, -- Horizontal recoil per shot
        RandomFactor = 0.3, -- Random recoil variation
        FirstShotMultiplier = 0.7, -- First shot recoil modifier
        DecayRate = 0.95 -- How fast recoil recovers
    },

    -- Fire Modes
    FireModes = {"Auto", "Semi"}, -- Available fire modes
    DefaultFireMode = "Auto",

    -- Attachment Compatibility
    AttachmentSlots = {
        Sights = {
            Compatible = {"RedDot", "Holographic", "ACOG", "Scope", "IronSights"},
            Default = "IronSights"
        },
        Barrels = {
            Compatible = {"StandardSuppressor", "HeavySuppressor", "Compensator", "FlashHider"},
            Default = nil
        },
        Underbarrel = {
            Compatible = {"VerticalGrip", "AngledGrip", "Bipod", "Laser", "Flashlight"},
            Default = nil
        },
        Other = {
            Compatible = {"LaserSight", "Flashlight", "CantedSight"},
            Default = nil
        }
    },

    -- Mastery System (attachments unlocked by kills)
    MasteryRequirements = {
        {Level = 1, Kills = 50, Reward = "RedDot"},
        {Level = 2, Kills = 150, Reward = "Compensator"},
        {Level = 3, Kills = 300, Reward = "VerticalGrip"},
        {Level = 4, Kills = 500, Reward = "ACOG"},
        {Level = 5, Kills = 750, Reward = "StandardSuppressor"},
        {Level = 6, Kills = 1000, Reward = "HolographicSight"},
        {Level = 7, Kills = 1500, Reward = "HeavySuppressor"},
        {Level = 8, Kills = 2000, Reward = "Bipod"},
        {Level = 9, Kills = 2500, Reward = "LaserSight"},
        {Level = 10, Kills = 3000, Reward = "MasterySkin"}
    },

    -- Movement and Handling
    WalkSpeedMultiplier = 0.85, -- Movement speed when equipped
    AimWalkSpeedMultiplier = 0.4, -- Movement speed when aiming
    AimDownSightTime = 0.35, -- Time to aim down sights
    SprintToFireTime = 0.25, -- Time to fire after sprinting

    -- Special Properties
    CanWallbang = true,
    HasBurstFire = false,
    HasFullAuto = true,
    SupportsSpecialAmmo = true,
    IsDefault = false -- Is this a default weapon for rank 0?
}
```

---

## WeaponConfig Setup

### Understanding Weapon Stats

#### Damage Stats
- **Damage**: Base damage per shot
- **HeadshotMultiplier**: Headshot damage multiplier (usually 2.0-2.5)
- **BodyMultiplier**: Torso damage multiplier (usually 1.0)
- **LimbMultiplier**: Limb damage multiplier (usually 0.7-0.8)

#### Range & Ballistics
- **Range**: Effective range before damage falloff
- **BulletVelocity**: Speed of bullets (affects hit registration at distance)
- **BulletDrop**: Gravity effect on bullets (9.81 is realistic)
- **Penetration**: Number of surfaces bullet can pass through
- **PenetrationPower**: Damage retained after penetrating (0-100%)

#### Fire Rate & Ammo
- **FireRate**: Rounds per minute (RPM)
  - SMGs: 700-1200 RPM
  - Assault Rifles: 600-850 RPM
  - LMGs: 600-800 RPM
  - Sniper Rifles: 40-60 RPM
- **MaxAmmo**: Magazine capacity
- **MaxReserveAmmo**: Total ammo (excluding magazine)
- **ReloadTime**: Tactical reload (magazine not empty)
- **EmptyReloadTime**: Empty reload (requires cocking/charging)

#### Accuracy & Recoil
- **BaseSpread**: Standing still accuracy (0.01 = very accurate, 0.1 = inaccurate)
- **AimSpread**: Aiming accuracy (usually half of base)
- **MovingSpread**: Moving accuracy (usually 1.5x base)
- **Recoil.Vertical**: Vertical kick per shot
- **Recoil.Horizontal**: Horizontal kick per shot
- **Recoil.RandomFactor**: Random recoil variation (0-1)
- **Recoil.FirstShotMultiplier**: First shot recoil modifier
- **Recoil.DecayRate**: Recovery speed (0.9-0.95 typical)

---

## Tool Creation

### Step 3: Create the Weapon Tool

1. **Create Tool in ServerStorage**
   - Location: `ServerStorage/WeaponTools/[Category]/[WeaponName]`
   - Right-click ServerStorage > Insert Object > Tool
   - Name it exactly as in WeaponConfig

2. **Add Handle**
   - Right-click Tool > Insert Object > Part
   - Name it "Handle" (must be exact)
   - Set properties:
     - Size: Small (e.g., `0.2, 0.2, 1`)
     - Transparency: 1 (invisible)
     - CanCollide: false
     - Massless: true

3. **Add Configuration Values** (optional)
   - Right-click Tool > Insert Object > Configuration
   - Add IntValue/StringValue for weapon-specific data
   - Example:
     - `Ammo` (IntValue): Current ammo
     - `MaxAmmo` (IntValue): Max magazine size
     - `TotalAmmo` (IntValue): Reserve ammo

4. **Add Client Script**
   - Right-click Tool > Insert Object > LocalScript
   - Name it: `[WeaponName]Script`
   - Add weapon firing logic (see Client Scripts section)

---

## Viewmodel Setup

### Step 4: Create First-Person Viewmodel

Viewmodels are what the player sees when holding the weapon.

**Folder Structure:**
```
ReplicatedStorage
└── FPSSystem
    └── Viewmodels
        └── [Category]
            └── [Type]
                └── [WeaponName]
                    ├── [WeaponModel] (Model or Parts)
                    └── CameraPart (Part) -- REQUIRED
```

**Example:**
```
ReplicatedStorage/FPSSystem/Viewmodels/Primary/AssaultRifles/G36/
```

### Creating a Viewmodel

1. **Create Folder Structure**
   - Navigate to `ReplicatedStorage.FPSSystem.Viewmodels`
   - Create folders: Category > Type > WeaponName

2. **Build the Viewmodel**
   - Create a Model inside the weapon folder
   - Name it after your weapon
   - Build the first-person weapon model
   - **Scale**: Make it larger than real-world (players see it close-up)
   - **Detail**: Add high-detail parts (will only render for one player)

3. **Add CameraPart** (CRITICAL!)
   - Insert a Part named "CameraPart"
   - This anchors the viewmodel to the camera
   - Position it where you want the camera to be relative to the weapon
   - Typical position: Behind and above the weapon
   - Set Transparency: 1
   - Set CanCollide: false

4. **Add Attachment Points** (for attachments)
   - Insert Attachments on the model for:
     - `SightAttachment` (on top rail)
     - `BarrelAttachment` (on muzzle)
     - `UnderbarrelAttachment` (under barrel)
     - `MuzzleAttachment` (exact muzzle position for effects)

5. **Set Properties**
   - All parts should have:
     - CanCollide: false
     - Massless: true
     - CastShadow: false
     - Anchored: false

6. **Test Positioning**
   - Equip weapon in-game
   - Adjust CameraPart position if viewmodel is off-center
   - Viewmodel should fill lower-right of screen

---

## Weapon Models

### Step 5: Create Third-Person Weapon Model

This is what other players see when you hold the weapon.

**Location:**
```
ReplicatedStorage/FPSSystem/WeaponModels/[Category]/[Type]/[WeaponName]
```

1. **Create Model**
   - Same weapon model as viewmodel but smaller scale
   - Real-world proportions
   - Less detail (renders for all players)

2. **Add Motor6D Welds**
   - Weld to player's right hand
   - Position: Held naturally in hand

3. **Add Attachment Point**
   - `GripAttachment`: Where hand grips weapon

---

## Client Scripts

### Step 6: Create Weapon Client Script

The client script handles weapon firing, reloading, and input.

**Template:**

```lua
-- [WeaponName].client.lua
-- Place this LocalScript inside the Tool

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local RaycastSystem = require(ReplicatedStorage.FPSSystem.Modules.RaycastSystem)
local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)
local GlobalStateManager = require(ReplicatedStorage.FPSSystem.Modules.GlobalStateManager)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Camera = workspace.CurrentCamera

local tool = script.Parent
local weaponName = tool.Name

-- Get weapon config
local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
if not weaponConfig then
    warn("No weapon config found for:", weaponName)
    return
end

local weaponStats = WeaponConfig:GetWeaponStats(weaponName)

-- Weapon state
local currentAmmo = weaponConfig.MaxAmmo
local totalAmmo = weaponConfig.MaxReserveAmmo
local isReloading = false
local canFire = true
local lastFireTime = 0
local isAiming = false
local currentFireMode = weaponConfig.DefaultFireMode

-- Input connections
local connections = {}

-- Remote events
local remoteEventsFolder = ReplicatedStorage.FPSSystem.RemoteEvents

--========================================
-- WEAPON FUNCTIONS
--========================================

function fireWeapon()
    if not canFire or isReloading or currentAmmo <= 0 then return end

    local currentTime = tick()
    local fireRate = 60 / (weaponStats.FireRate or 600)

    if currentTime - lastFireTime < fireRate then return end

    lastFireTime = currentTime
    currentAmmo = currentAmmo - 1

    -- Update player state
    GlobalStateManager:UpdatePlayerState(player, "LastShotTime", currentTime)

    -- Apply zoom factor for accuracy
    local spreadModifier = isAiming and 0.1 or 1.0

    -- Perform raycast
    local rayDirection = Camera.CFrame.LookVector
    local rayResult = RaycastSystem:FireRay(
        Camera.CFrame.Position,
        rayDirection,
        weaponStats.Range or 1000,
        weaponName,
        weaponStats.Damage or 35,
        spreadModifier,
        {player.Character}
    )

    -- Send to server
    local weaponFiredEvent = remoteEventsFolder:FindFirstChild("WeaponFired")
    if weaponFiredEvent then
        weaponFiredEvent:FireServer({
            WeaponName = weaponName,
            Origin = Camera.CFrame.Position,
            Direction = rayDirection,
            Hit = rayResult.Hit,
            Distance = rayResult.Distance,
            Damage = weaponStats.Damage
        })
    end

    -- Play effects
    playFireEffects()

    -- Apply recoil
    applyRecoil()

    -- Update UI
    updateAmmoUI()

    -- Auto reload if empty
    if currentAmmo <= 0 then
        reloadWeapon()
    end
end

function playFireEffects()
    -- Muzzle flash
    local viewmodel = ViewmodelSystem:GetActiveViewmodel()
    if viewmodel then
        local muzzle = viewmodel:FindFirstChild("Muzzle", true)
        if muzzle then
            local flash = Instance.new("PointLight")
            flash.Brightness = 10
            flash.Range = 20
            flash.Color = Color3.fromRGB(255, 200, 100)
            flash.Parent = muzzle
            game:GetService("Debris"):AddItem(flash, 0.1)
        end
    end

    -- Play sound
    local weaponSoundEvent = remoteEventsFolder:FindFirstChild("WeaponSound")
    if weaponSoundEvent then
        weaponSoundEvent:FireServer({
            SoundType = "Fire",
            WeaponName = weaponName,
            Position = Camera.CFrame.Position
        })
    end
end

function applyRecoil()
    if not weaponStats.Recoil then return end

    local recoilMultiplier = isAiming and 0.5 or 1.0
    local verticalRecoil = (weaponStats.Recoil.Vertical or 1) * recoilMultiplier
    local horizontalRecoil = (weaponStats.Recoil.Horizontal or 0.5) * recoilMultiplier

    local recoilX = (math.random() - 0.5) * horizontalRecoil
    local recoilY = verticalRecoil

    Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(-recoilY), math.rad(recoilX), 0)

    if ViewmodelSystem.ApplyRecoil then
        ViewmodelSystem:ApplyRecoil(Vector3.new(recoilX, recoilY, 0))
    end
end

function reloadWeapon()
    if isReloading or currentAmmo >= weaponConfig.MaxAmmo or totalAmmo <= 0 then return end

    isReloading = true
    canFire = false

    local reloadTime = currentAmmo > 0 and weaponStats.ReloadTime or weaponStats.EmptyReloadTime or 2.5

    -- Send to server
    local weaponReloadedEvent = remoteEventsFolder:FindFirstChild("WeaponReloaded")
    if weaponReloadedEvent then
        weaponReloadedEvent:FireServer({WeaponName = weaponName})
    end

    wait(reloadTime)

    local ammoNeeded = weaponConfig.MaxAmmo - currentAmmo
    local ammoToReload = math.min(ammoNeeded, totalAmmo)

    currentAmmo = currentAmmo + ammoToReload
    totalAmmo = totalAmmo - ammoToReload

    isReloading = false
    canFire = true

    updateAmmoUI()
end

function updateAmmoUI()
    local ammoUpdateEvent = remoteEventsFolder:FindFirstChild("AmmoUpdate")
    if ammoUpdateEvent then
        ammoUpdateEvent:FireServer({
            WeaponName = weaponName,
            CurrentAmmo = currentAmmo,
            TotalAmmo = totalAmmo
        })
    end
end

function startAiming()
    if isAiming or isReloading then return end
    isAiming = true
    ViewmodelSystem:SetAiming(true)
end

function stopAiming()
    if not isAiming then return end
    isAiming = false
    ViewmodelSystem:SetAiming(false)
end

--========================================
-- INPUT HANDLING
--========================================

function setupInputHandling()
    -- Right-click to aim
    connections.MouseButton2Down = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            startAiming()
        end
    end)

    connections.MouseButton2Up = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            stopAiming()
        end
    end)

    -- Left-click to fire
    connections.MouseButton1Down = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if currentFireMode == "Auto" then
                -- Hold to fire
                connections.AutoFire = RunService.Heartbeat:Connect(function()
                    fireWeapon()
                end)
            else
                fireWeapon() -- Semi-auto
            end
        end
    end)

    connections.MouseButton1Up = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if connections.AutoFire then
                connections.AutoFire:Disconnect()
                connections.AutoFire = nil
            end
        end
    end)

    -- R to reload
    connections.ReloadKey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.R then
            reloadWeapon()
        end
    end)

    -- V to toggle fire mode
    connections.FireModeKey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.V and #weaponConfig.FireModes > 1 then
            -- Toggle fire mode
            local currentIndex = table.find(weaponConfig.FireModes, currentFireMode)
            currentIndex = (currentIndex % #weaponConfig.FireModes) + 1
            currentFireMode = weaponConfig.FireModes[currentIndex]
            print("Fire mode:", currentFireMode)
        end
    end)
end

function cleanupInputHandling()
    for name, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
end

--========================================
-- TOOL EVENTS
--========================================

function onEquipped()
    print("Equipped", weaponName)
    setupInputHandling()
    updateAmmoUI()
end

function onUnequipped()
    print("Unequipped", weaponName)
    if isAiming then stopAiming() end
    cleanupInputHandling()
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

print(weaponName, "client script loaded")
```

---

## Animation Integration

### Step 7: Add Weapon Animations

Animations make weapons feel responsive and realistic.

**Animation Types:**
- **Equip**: Pulling out the weapon
- **Idle**: Holding the weapon
- **Fire**: Firing animation
- **Reload**: Reloading animation
- **Inspect**: Inspect animation (H key)

**Animation Folder Structure:**
```
ReplicatedStorage/FPSSystem/Animations/[Category]/[Type]/[WeaponName]/
├── Equip
├── Idle
├── Fire
├── Reload
├── ReloadEmpty
└── Inspect
```

### Creating Animations

1. **Use Roblox Animation Editor**
   - Plugin: "Animation Editor"
   - Animate the viewmodel
   - Export as Animation instances

2. **Place Animations**
   - Put in correct folder
   - Name them correctly

3. **Auto-Loading**
   - ViewmodelSystem automatically loads animations
   - Play them via `AnimationController` in viewmodel

---

## Testing Checklist

### Step 8: Test Your Weapon

Before releasing your weapon, test these features:

- [ ] **Basic Functionality**
  - [ ] Weapon can be equipped
  - [ ] Viewmodel displays correctly
  - [ ] Weapon fires when clicking
  - [ ] Ammo decreases on fire
  - [ ] Weapon reloads when pressing R
  - [ ] Weapon reloads automatically when empty

- [ ] **Damage & Ballistics**
  - [ ] Damage is correct
  - [ ] Headshots deal correct damage
  - [ ] Range is appropriate
  - [ ] Bullet drop is noticeable (for snipers/long range)
  - [ ] Penetration works through walls

- [ ] **Accuracy & Recoil**
  - [ ] Base accuracy feels right
  - [ ] Aim accuracy improves when aiming
  - [ ] Moving reduces accuracy
  - [ ] Recoil pattern is manageable
  - [ ] First shot accuracy is good

- [ ] **Fire Modes**
  - [ ] Auto fire works (holds down)
  - [ ] Semi-auto works (single shots)
  - [ ] V key toggles between modes
  - [ ] Current mode is displayed

- [ ] **Aiming & Scope**
  - [ ] Right-click aims down sights
  - [ ] FOV changes when aiming (for scopes)
  - [ ] Scope renders correctly (if applicable)
  - [ ] T key toggles scope mode (if applicable)

- [ ] **Animations**
  - [ ] Equip animation plays
  - [ ] Fire animation plays
  - [ ] Reload animation plays
  - [ ] Inspect animation plays (H key)

- [ ] **Sound Effects**
  - [ ] Fire sound plays
  - [ ] Reload sound plays
  - [ ] Empty click sound (if out of ammo)

- [ ] **Visual Effects**
  - [ ] Muzzle flash appears
  - [ ] Bullet tracers visible
  - [ ] Impact effects on hit
  - [ ] Shell ejection (if implemented)

- [ ] **Multiplayer**
  - [ ] Other players see you holding weapon
  - [ ] Other players see fire effects
  - [ ] Hits register on server
  - [ ] No exploits possible

- [ ] **UI Integration**
  - [ ] Ammo display updates
  - [ ] Weapon name shows
  - [ ] Fire mode indicator works
  - [ ] Crosshair displays

- [ ] **Unlocks & Progression**
  - [ ] Weapon unlocks at correct level
  - [ ] Pre-buy cost is correct
  - [ ] Mastery levels work
  - [ ] Attachments unlock at correct kills

---

## Troubleshooting

### Common Issues

#### Viewmodel Not Showing
- **Check**: Is CameraPart present in viewmodel?
- **Check**: Is viewmodel in correct folder structure?
- **Check**: Is WeaponConfig name matching tool name exactly?
- **Fix**: Add CameraPart, verify folder structure

#### Weapon Not Firing
- **Check**: Is client script present in tool?
- **Check**: Are RemoteEvents set up correctly?
- **Check**: Is WeaponHandler running on server?
- **Fix**: Add client script, check server scripts

#### Ammo Not Updating
- **Check**: Is AmmoUpdate RemoteEvent firing?
- **Check**: Is HUD controller listening for ammo updates?
- **Fix**: Verify RemoteEvent connections

#### Recoil Too Strong/Weak
- **Fix**: Adjust `Recoil.Vertical` and `Recoil.Horizontal` in WeaponConfig
- **Tip**: Start with 0.5 and increase/decrease by 0.1 increments

#### Damage Not Correct
- **Check**: Is WeaponConfig damage value correct?
- **Check**: Is DamageSystem calculating correctly?
- **Fix**: Verify damage multipliers (headshot, body, limb)

#### Viewmodel Positioned Wrong
- **Fix**: Adjust CameraPart position in viewmodel
- **Tip**: Move CameraPart closer/farther, up/down to reposition

#### Third-Person Model Not Showing
- **Check**: Is weapon model in WeaponModels folder?
- **Check**: Is server-side script equipping model?
- **Fix**: Verify folder structure and server handler

---

## Advanced Features

### Custom Weapon Behaviors

For special weapons (like ViciousStinger), you can:

1. **Add Custom UI**
   - Create custom UI module
   - Show/hide when weapon equipped

2. **Custom Keybinds**
   - Add to `CustomKeybinds` in WeaponConfig
   - Handle in client script

3. **Special Abilities**
   - Define in `SpecialAbilities` in WeaponConfig
   - Add server-side handler

4. **Unique Animations**
   - Create custom animations
   - Play via AnimationController

---

## Best Practices

1. **Balance First**
   - Test damage, fire rate, and recoil extensively
   - Compare with similar weapons
   - Get feedback from players

2. **Consistent Naming**
   - Use same name everywhere (Tool, WeaponConfig, folders)
   - No spaces in internal names (use in Display Name)

3. **Performance**
   - Keep viewmodels under 1000 triangles
   - Use LOD for third-person models
   - Optimize scripts (avoid loops in loops)

4. **Documentation**
   - Comment your code
   - Document special behaviors
   - Keep changelog of balance changes

5. **Version Control**
   - Save backups before major changes
   - Test on separate branch/place
   - Document all stat changes

---

## Quick Reference

### Weapon Stat Presets

**Assault Rifle (Balanced)**
- Damage: 30-35
- FireRate: 650-750 RPM
- MaxAmmo: 30
- Range: 1000
- Recoil.Vertical: 0.8

**SMG (High ROF, Close Range)**
- Damage: 20-25
- FireRate: 800-1000 RPM
- MaxAmmo: 25-35
- Range: 600
- Recoil.Vertical: 0.6

**Sniper Rifle (High Damage, Slow)**
- Damage: 80-100
- FireRate: 40-60 RPM
- MaxAmmo: 5-10
- Range: 5000
- Recoil.Vertical: 2.5

**Shotgun (Close Range, High Damage)**
- Damage: 15 per pellet × 8 pellets
- FireRate: 80-120 RPM
- MaxAmmo: 6-8
- Range: 50
- Spread: High

---

## Support

For additional help:
- Check existing weapons in WeaponConfig.lua for examples
- Review ExampleSniperWeapon.client.lua for script templates
- See SCOPE_SYSTEM_GUIDE.md for scope integration
- Consult ATTACHMENT_SYSTEM_GUIDE.md for attachment setup

---

**Last Updated**: 2025-10-12
**Version**: 1.0
**Author**: FPS System Documentation
