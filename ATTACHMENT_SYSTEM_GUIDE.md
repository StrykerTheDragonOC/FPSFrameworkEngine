# Attachment System Guide

**Version:** 1.0
**Last Updated:** 2025-10-12
**Author:** FPS System Team

---

## Table of Contents

1. [Overview](#overview)
2. [Attachment Categories](#attachment-categories)
3. [How Attachments Work](#how-attachments-work)
4. [Creating New Attachments](#creating-new-attachments)
5. [Stat Modification System](#stat-modification-system)
6. [Compatibility Rules](#compatibility-rules)
7. [3D Model Setup](#3d-model-setup)
8. [Unlock Progression](#unlock-progression)
9. [Special Attachment Types](#special-attachment-types)
10. [Testing Attachments](#testing-attachments)
11. [Troubleshooting](#troubleshooting)
12. [Attachment Presets](#attachment-presets)

---

## Overview

The attachment system allows players to customize their weapons with various modifications that affect weapon performance, appearance, and behavior. Attachments can be **universal** (work on many weapons) or **weapon-specific** (exclusive to certain guns).

### Key Features

- **Stat Modification**: Attachments can increase/decrease weapon stats (recoil, range, damage, etc.)
- **Unlock Progression**: Attachments unlock through kills (5 to 2500+) or can be pre-bought
- **Visual Integration**: Attachments attach to Roblox `Attachment` instances in weapon models
- **Trade-offs**: Many attachments have both positive and negative effects for balance
- **Category System**: Organized into Sights, Barrels, Underbarrel, and Other categories

### Where Attachments Are Defined

All attachment configurations are stored in:
```
ReplicatedStorage.FPSSystem.Modules.WeaponConfig
```

Attachments are defined per-weapon in the `Attachments` table of each weapon's configuration.

---

## Attachment Categories

### 1. Sights (Optics)

**Purpose**: Improve target acquisition and aiming

**Subcategories**:
- **Iron Sights**: Default sights (no attachment)
- **Red Dots**: 1x magnification, fast target acquisition
- **Holographic Sights**: Similar to red dots, different reticle
- **Scopes**: 2x-12x magnification, precision aiming

**Key Features**:
- Scopes support **T** key to toggle between 3D scope and UI scope modes
- UI scope mode includes sway and **Shift** to stabilize
- Different zoom levels affect ADS (Aim Down Sights) speed
- Each sight has unique reticle and FOV

**Common Stats Modified**:
- `AimSpeed`: How fast you enter ADS
- `ZoomLevel`: Magnification factor
- `ScopeType`: "3D", "UI", or "Both"

### 2. Barrels

**Purpose**: Modify weapon range, velocity, and handling

**Types**:
- **Standard Barrel**: Default (no attachment)
- **Heavy Barrel**: Increased range, slower movement
- **Short Barrel / Obrez**: Better CQC, reduced range
- **Carbine Barrel**: Balanced stats
- **Marksman Barrel**: Long-range precision
- **Shotgun Chokes**: Modify pellet spread

**Key Features**:
- Barrels significantly impact weapon identity
- Heavy barrels can require crouching/stabilizing (e.g., NTW-20 heavy barrel)
- Short barrels increase mobility
- Chokes (shotguns only) tighten spread patterns

**Common Stats Modified**:
- `Range`: Maximum effective range
- `BulletVelocity`: Speed of projectile
- `WalkSpeedMultiplier`: Movement penalty/bonus
- `SpreadMultiplier`: Accuracy modification (chokes)
- `RequiresCrouchToScope`: Special barrel restrictions

### 3. Underbarrel (Grips)

**Purpose**: Control recoil and improve handling

**Types**:
- **Vertical Grip**: Reduces vertical recoil
- **Angled Grip**: Faster ADS, slight recoil increase
- **Folding Grip**: Balanced stats
- **Bipod**: Significant recoil reduction when prone/mounted

**Key Features**:
- Most grips are **universal for Primary weapons**
- All grips have **trade-offs** (positive and negative effects)
- Bipods only activate in specific stances

**Common Stats Modified**:
- `RecoilMultiplier`: Vertical/horizontal recoil reduction
- `AimSpeed`: ADS time modification
- `AccuracyMultiplier`: Spread pattern changes
- `RequiresProne`: Bipod requirement

### 4. Other (Miscellaneous)

**Purpose**: Special modifications and tactical equipment

**Types**:
- **Suppressors**: Reduce sound and radar signature
- **Muzzle Brakes**: Reduce recoil, increase sound
- **Flashlights**: Illuminate dark areas (visible to all)
- **Lasers**: Show aim point (visible to team only)
- **Ammo Types**: Special ammunition (Armor Piercing, Incendiary, etc.)
- **Stocks**: Improve stability and recoil
- **Magazines**: Extended/Fast mags

**Key Features**:
- **Suppressors**:
  - Mostly universal for Primary/Secondary
  - Some weapons (NTW-20) cannot equip
  - Show on radar only within certain range
- **Flashlights**: Visible to enemies
- **Lasers**: Client-side or team-only visible
- **Ammo Types**: See [Special Attachment Types](#special-attachment-types)

**Common Stats Modified**:
- `SuppressedRange`: Radar signature range
- `DamageMultiplier`: Ammo type modifications
- `PenetrationMultiplier`: Armor piercing
- `RecoilMultiplier`: Stocks/brakes
- `MagazineSize`: Extended mags
- `ReloadSpeed`: Fast mags

---

## How Attachments Work

### Attachment Flow

1. **Player selects attachment** in Loadout UI
2. **Server validates** attachment is unlocked and compatible
3. **WeaponConfig applies stat modifications** to base weapon stats
4. **3D model spawned** at attachment point on weapon model/viewmodel
5. **Client uses modified stats** for weapon behavior

### Stat Application Order

When multiple attachments are equipped:

1. **Start with base weapon stats** from WeaponConfig
2. **Apply each attachment's modifiers** in order:
   - Sight modifiers
   - Barrel modifiers
   - Underbarrel modifiers
   - Other modifiers
3. **Calculate final stats** (multipliers stack)

**Example**:
```lua
Base Recoil: 1.0
+ Vertical Grip: 0.85x recoil
+ Muzzle Brake: 0.90x recoil
= Final Recoil: 1.0 * 0.85 * 0.90 = 0.765
```

### Attachment Data Structure

Each attachment in WeaponConfig follows this structure:

```lua
Attachments = {
    Sight = {
        {
            Name = "RedDot_Reflex",
            DisplayName = "Reflex Sight",
            Description = "1x red dot sight for fast target acquisition",
            UnlockKills = 10,
            Cost = 500,
            Category = "Sight",
            Subcategory = "RedDot",

            -- Stat Modifiers
            Modifiers = {
                AimSpeed = 0.95, -- 5% faster ADS
                ZoomLevel = 1.0,
            },

            -- 3D Model Info
            ModelPath = "ReplicatedStorage.FPSSystem.Attachments.Sights.RedDot_Reflex",
            AttachmentPoint = "SightAttachment", -- Name of Attachment in weapon model

            -- Special Properties
            ScopeType = "None", -- "3D", "UI", "Both", "None"
            ReticleImage = "rbxassetid://123456789",

            -- Compatibility
            Universal = true, -- Works on all weapons with SightAttachment
            ExcludedWeapons = {}, -- Weapons that cannot use this
            RequiredWeapons = {}, -- Only these weapons can use (if not Universal)
        },
    },

    Barrel = {
        -- Barrel attachments...
    },

    Underbarrel = {
        -- Underbarrel attachments...
    },

    Other = {
        -- Other attachments...
    },
}
```

---

## Creating New Attachments

### Step-by-Step Process

#### Step 1: Define Attachment in WeaponConfig

Open `ReplicatedStorage.FPSSystem.Modules.WeaponConfig.lua` and find the weapon you want to add an attachment to.

**Example: Adding a new scope**

```lua
-- In WeaponConfig, under a specific weapon (e.g., G36)
Weapons = {
    G36 = {
        -- ... base weapon stats ...

        Attachments = {
            Sight = {
                -- Existing sights...

                -- NEW SCOPE
                {
                    Name = "ACOG_4x",
                    DisplayName = "ACOG 4x Scope",
                    Description = "4x magnification scope for medium-long range engagements",
                    UnlockKills = 250,
                    Cost = 2000,
                    Category = "Sight",
                    Subcategory = "Scope",

                    Modifiers = {
                        AimSpeed = 0.80, -- 20% slower ADS
                        ZoomLevel = 4.0,
                        RecoilMultiplier = 0.95, -- Slight recoil reduction
                    },

                    ModelPath = "ReplicatedStorage.FPSSystem.Attachments.Sights.ACOG_4x",
                    AttachmentPoint = "SightAttachment",

                    ScopeType = "Both", -- Support both 3D and UI modes
                    ReticleImage = "rbxassetid://987654321",
                    ScopeOverlayImage = "rbxassetid://987654322",

                    Universal = false,
                    RequiredWeapons = {"G36", "M4A1", "SCAR"}, -- Only these weapons
                },
            },

            Barrel = {
                -- NEW BARREL
                {
                    Name = "HeavyBarrel_G36",
                    DisplayName = "Heavy Barrel",
                    Description = "Increases range but reduces mobility",
                    UnlockKills = 500,
                    Cost = 3000,
                    Category = "Barrel",
                    Subcategory = "Heavy",

                    Modifiers = {
                        Range = 1.25, -- 25% more range
                        BulletVelocity = 1.15,
                        WalkSpeedMultiplier = 0.85, -- 15% slower movement
                        AimSpeed = 0.90,
                    },

                    ModelPath = "ReplicatedStorage.FPSSystem.Attachments.Barrels.HeavyBarrel_G36",
                    AttachmentPoint = "BarrelAttachment",

                    Universal = false,
                    RequiredWeapons = {"G36"},
                },
            },

            Underbarrel = {
                -- NEW GRIP
                {
                    Name = "AngledGrip",
                    DisplayName = "Angled Foregrip",
                    Description = "Faster ADS but slightly more recoil",
                    UnlockKills = 100,
                    Cost = 800,
                    Category = "Underbarrel",
                    Subcategory = "Grip",

                    Modifiers = {
                        AimSpeed = 1.10, -- 10% faster ADS
                        RecoilMultiplier = 1.05, -- 5% more recoil (trade-off)
                        AccuracyMultiplier = 0.98,
                    },

                    ModelPath = "ReplicatedStorage.FPSSystem.Attachments.Underbarrel.AngledGrip",
                    AttachmentPoint = "UnderbarrelAttachment",

                    Universal = true, -- Works on all Primary weapons
                    ExcludedWeapons = {"NTW20"}, -- Sniper rifles excluded
                },
            },

            Other = {
                -- NEW SUPPRESSOR
                {
                    Name = "TacticalSuppressor",
                    DisplayName = "Tactical Suppressor",
                    Description = "Reduces sound and radar signature",
                    UnlockKills = 150,
                    Cost = 1500,
                    Category = "Other",
                    Subcategory = "Suppressor",

                    Modifiers = {
                        SuppressedRange = 50, -- Only shows on radar within 50 studs
                        DamageMultiplier = 0.95, -- 5% damage reduction
                        BulletVelocity = 0.92,
                        RecoilMultiplier = 0.97, -- Slight recoil reduction
                    },

                    ModelPath = "ReplicatedStorage.FPSSystem.Attachments.Other.TacticalSuppressor",
                    AttachmentPoint = "MuzzleAttachment",

                    Universal = true,
                    ExcludedWeapons = {"NTW20", "M107"}, -- Cannot suppress .50 cal
                },
            },
        },
    },
}
```

#### Step 2: Create 3D Attachment Model

1. **Open Roblox Studio**
2. **Create the attachment model**:
   - Model the attachment in Blender/other 3D software
   - Import as MeshPart or use Roblox parts
   - Name the model (e.g., "ACOG_4x")

3. **Add Attachment point reference**:
   ```
   ACOG_4x (Model)
   ├─ MainPart (MeshPart) [Set as PrimaryPart]
   ├─ WeaponAttach (Attachment) -- Position where it connects to weapon
   └─ ScopeGlass (Part) -- Transparent part for scope lens
   ```

4. **Position the attachment**:
   - The `WeaponAttach` Attachment should be at (0, 0, 0) locally
   - This will align with the weapon's attachment point

5. **Save to correct location**:
   ```
   ReplicatedStorage
   └─ FPSSystem
      └─ Attachments
         ├─ Sights
         │  └─ ACOG_4x
         ├─ Barrels
         │  └─ HeavyBarrel_G36
         ├─ Underbarrel
         │  └─ AngledGrip
         └─ Other
            └─ TacticalSuppressor
   ```

#### Step 3: Add Attachment Points to Weapon Models

**For Weapon Model** (in ServerStorage/ReplicatedStorage):
```
G36 (Model)
├─ Handle (Part)
├─ SightAttachment (Attachment) -- Top rail
├─ BarrelAttachment (Attachment) -- Muzzle/barrel tip
├─ UnderbarrelAttachment (Attachment) -- Bottom rail
└─ MuzzleAttachment (Attachment) -- End of barrel
```

**For Viewmodel** (in ReplicatedStorage.FPSSystem.Viewmodels):
```
G36 (Model)
└─ Viewmodel (Model)
   ├─ GunModel (Model)
   │  ├─ Handle (Part)
   │  ├─ SightAttachment (Attachment)
   │  ├─ BarrelAttachment (Attachment)
   │  ├─ UnderbarrelAttachment (Attachment)
   │  └─ MuzzleAttachment (Attachment)
   └─ CameraPart (Part) -- Camera position
```

#### Step 4: Update Attachment Manager

The `AttachmentManager` module handles attaching/detaching attachment models. It should automatically detect new attachments if they follow the naming conventions.

**Verify in**: `ReplicatedStorage.FPSSystem.Modules.AttachmentManager.lua`

```lua
-- AttachmentManager should have functions:
function AttachmentManager:ApplyAttachment(weaponModel, attachmentConfig)
    local attachmentModel = self:LoadAttachmentModel(attachmentConfig.ModelPath)
    local attachPoint = weaponModel:FindFirstChild(attachmentConfig.AttachmentPoint)

    if attachmentModel and attachPoint then
        -- Attach to weapon
        self:AttachToWeapon(attachmentModel, attachPoint)
    end
end
```

#### Step 5: Test in Game

See [Testing Attachments](#testing-attachments) section below.

---

## Stat Modification System

### Understanding Modifiers

Modifiers are **multipliers or additive values** applied to base weapon stats.

### Modifier Types

#### 1. Multiplicative Modifiers (Most Common)

Applied as: `FinalValue = BaseValue * Modifier`

**Examples**:
```lua
Modifiers = {
    RecoilMultiplier = 0.85, -- 15% less recoil
    DamageMultiplier = 1.10, -- 10% more damage
    WalkSpeedMultiplier = 0.90, -- 10% slower movement
}
```

#### 2. Additive Modifiers

Applied as: `FinalValue = BaseValue + Modifier`

**Examples**:
```lua
Modifiers = {
    MagazineSize = 10, -- +10 rounds
    ReserveAmmo = 60, -- +60 reserve ammo
    Range = 50, -- +50 studs range
}
```

#### 3. Replacement Modifiers

Completely replaces base value:

**Examples**:
```lua
Modifiers = {
    ZoomLevel = 4.0, -- Sets zoom to 4x (not multiplied)
    FireMode = "Semi", -- Changes fire mode
    PelletCount = 12, -- Sets exact pellet count
}
```

### All Available Modifiers

```lua
Modifiers = {
    -- Damage
    DamageMultiplier = 1.0,
    HeadshotMultiplier = 1.0,

    -- Range
    Range = 0, -- Additive
    RangeMultiplier = 1.0,
    BulletVelocity = 1.0, -- Multiplier
    BulletDropOff = 1.0,

    -- Recoil
    RecoilMultiplier = 1.0,
    RecoilHorizontal = 1.0,
    RecoilVertical = 1.0,

    -- Accuracy
    AccuracyMultiplier = 1.0,
    SpreadMultiplier = 1.0,

    -- Handling
    AimSpeed = 1.0, -- Multiplier for ADS time
    WalkSpeedMultiplier = 1.0,
    SprintSpeedMultiplier = 1.0,

    -- Ammo
    MagazineSize = 0, -- Additive
    ReserveAmmo = 0, -- Additive
    ReloadSpeed = 1.0, -- Multiplier

    -- Penetration
    PenetrationMultiplier = 1.0,
    PenetrationDepth = 0, -- Additive (studs)

    -- Special
    FireRate = 0, -- Additive (RPM change)
    FireRateMultiplier = 1.0,
    ZoomLevel = 1.0, -- Replacement for sights
    SuppressedRange = nil, -- Set value for suppressors

    -- Shotgun-specific
    PelletCount = nil, -- Replacement
    PelletSpread = 1.0, -- Multiplier

    -- Special Requirements
    RequiresProne = false,
    RequiresCrouchToScope = false,
}
```

### Stacking Multiple Attachments

When multiple attachments modify the same stat:

**Multiplicative**: Multiply together
```lua
Base: 1.0
Grip: 0.90x
Brake: 0.85x
Final: 1.0 * 0.90 * 0.85 = 0.765 (23.5% reduction)
```

**Additive**: Add together
```lua
Base: 30 rounds
Extended Mag: +10 rounds
Tactical Mag: +5 rounds
Final: 30 + 10 + 5 = 45 rounds
```

### Creating Balanced Attachments

**Best Practices**:

1. **Trade-offs**: Give strong positives with meaningful negatives
   ```lua
   -- Good balance:
   Modifiers = {
       AimSpeed = 1.15, -- 15% faster ADS
       RecoilMultiplier = 1.08, -- 8% more recoil
   }
   ```

2. **Avoid pure upgrades**: Every attachment should have a downside
   ```lua
   -- Bad (pure upgrade):
   Modifiers = {
       DamageMultiplier = 1.10, -- Only positive
   }

   -- Good (trade-off):
   Modifiers = {
       DamageMultiplier = 1.10,
       FireRateMultiplier = 0.92, -- Slower fire rate
   }
   ```

3. **Scale with weapon type**:
   - SMGs: Focus on mobility/fire rate
   - Snipers: Focus on range/accuracy
   - ARs: Balanced modifications

4. **Test in combat**: Play with the attachment to ensure it's not overpowered

---

## Compatibility Rules

### Universal Attachments

**Universal attachments** work on all weapons in a category (with exceptions).

**Example: Universal Suppressor**
```lua
{
    Name = "StandardSuppressor",
    Universal = true,
    ExcludedWeapons = {"NTW20", "M107"}, -- Cannot suppress these
}
```

This suppressor works on:
- All Primary weapons EXCEPT NTW20 and M107
- All Secondary weapons EXCEPT excluded

### Weapon-Specific Attachments

**Weapon-specific attachments** only work on certain weapons.

**Example: NTW-20 Heavy Barrel**
```lua
{
    Name = "NTW20_HeavyBarrel",
    Universal = false,
    RequiredWeapons = {"NTW20"},
}
```

This barrel ONLY works on NTW-20.

### Category-Specific Rules

#### Primary Weapons
- **Sights**: Universal (all primaries have SightAttachment)
- **Grips**: Universal except some sniper rifles
- **Suppressors**: Universal except .50 cal snipers
- **Barrels**: Usually weapon-specific or subcategory-specific

#### Secondary Weapons
- **Sights**: Limited (not all pistols have rails)
- **Suppressors**: Universal for pistols
- **Barrels**: Weapon-specific

#### Shotguns
- **Chokes**: Shotgun-specific attachments
- **Ammo Types**: Shotgun-only

#### Subcategory Sharing

Some attachments work across subcategories:

```lua
{
    Name = "CarbineBarrel",
    Universal = false,
    RequiredWeapons = {}, -- Empty means use subcategory
    RequiredSubcategories = {"AssaultRifles", "BattleRifles", "DMRs"},
}
```

### Validation System

The server validates attachments before applying:

1. **Check if weapon is unlocked**
2. **Check if attachment is unlocked** (kills or purchase)
3. **Check compatibility**:
   - If Universal, check ExcludedWeapons
   - If not Universal, check RequiredWeapons/RequiredSubcategories
4. **Check attachment points exist** on weapon model
5. **Apply attachment**

**Server validation in AttachmentHandler**:
```lua
function AttachmentHandler:ValidateAttachment(player, weaponName, attachmentName)
    local weaponConfig = WeaponConfig:GetWeapon(weaponName)
    local attachment = self:FindAttachment(weaponConfig, attachmentName)

    if not attachment then return false end

    -- Check if attachment is compatible
    if attachment.Universal then
        if table.find(attachment.ExcludedWeapons or {}, weaponName) then
            return false -- Weapon is excluded
        end
    else
        if not table.find(attachment.RequiredWeapons or {}, weaponName) then
            return false -- Weapon not in required list
        end
    end

    -- Check if player has unlocked
    if not DataStoreManager:HasAttachmentUnlocked(player, weaponName, attachmentName) then
        return false
    end

    return true
end
```

---

## 3D Model Setup

### Creating Attachment Models

#### Model Structure

Every attachment model should follow this structure:

```
AttachmentName (Model)
├─ PrimaryPart (MeshPart/Part) [Set as Model.PrimaryPart]
├─ WeaponAttach (Attachment) -- Connection point to weapon
└─ [Optional visual parts]
```

**Key Requirements**:
1. **Model must have PrimaryPart set**
2. **Must contain "WeaponAttach" Attachment**
3. **WeaponAttach should be at (0,0,0) relative to PrimaryPart**

#### Attachment Point Naming

**Standard attachment point names** on weapons:

| Attachment Type | Attachment Point Name | Location on Weapon |
|----------------|----------------------|-------------------|
| Sights         | `SightAttachment`     | Top rail          |
| Barrels        | `BarrelAttachment`    | Muzzle/barrel end |
| Underbarrel    | `UnderbarrelAttachment` | Bottom rail     |
| Suppressors    | `MuzzleAttachment`    | Very end of barrel |
| Lasers/Lights  | `AccessoryAttachment` | Side rail         |

#### Positioning Attachments

1. **Create attachment point on weapon** at desired location
2. **Create matching attachment on attachment model** at connection point
3. **System will align** the two attachments automatically

**Example: Scope mounting**

Weapon model:
```lua
-- On weapon's top rail
SightAttachment.Position = Vector3.new(0, 0.5, -0.2)
SightAttachment.Orientation = Vector3.new(0, 0, 0)
```

Scope model:
```lua
-- On bottom of scope
WeaponAttach.Position = Vector3.new(0, -0.1, 0) -- Relative to scope
WeaponAttach.Orientation = Vector3.new(0, 0, 0)
```

When attached, the scope's WeaponAttach aligns with weapon's SightAttachment.

#### Viewmodel vs Third-Person Models

**Viewmodel attachments** (client-side):
- High detail
- Can be larger/more visible
- Attached to viewmodel in `ReplicatedStorage.FPSSystem.Viewmodels`

**Third-person attachments** (server-side):
- Lower detail (performance)
- Attached to player's weapon tool
- Other players see this version

**Both should have same attachment points** for consistency.

#### Special Attachment Types

##### Scopes with Glass

```
ScopeModel (Model)
├─ ScopeBody (MeshPart) [PrimaryPart]
├─ ScopeLens (Part) -- Transparent part
│  └─ SurfaceGui (for reticle overlay)
├─ WeaponAttach (Attachment)
└─ LookAttachment (Attachment) -- Where camera looks through
```

##### Lasers

```
LaserModel (Model)
├─ LaserBody (MeshPart) [PrimaryPart]
├─ LaserEmitter (Attachment) -- Where beam starts
├─ LaserBeam (Beam or Part) -- Visual laser
└─ WeaponAttach (Attachment)
```

Laser logic in weapon script:
```lua
local function UpdateLaser()
    local rayOrigin = laserEmitter.WorldPosition
    local rayDirection = weapon.CFrame.LookVector * 1000

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection)
    if raycastResult then
        -- Update laser endpoint
        laserBeam.Attachment1.WorldPosition = raycastResult.Position
    end
end
```

##### Suppressors

```
SuppressorModel (Model)
├─ SuppressorMesh (MeshPart) [PrimaryPart]
├─ WeaponAttach (Attachment) -- Screws onto barrel
└─ MuzzleFlash (Attachment) -- New muzzle flash location
```

### Model Optimization

**Performance Tips**:
1. **Use MeshParts** instead of unions when possible
2. **Combine multiple parts** into single mesh
3. **Use simple collision boxes** (CanCollide = false for most parts)
4. **Optimize triangle count**: <1000 triangles for most attachments
5. **Use texture atlases** to reduce texture calls

---

## Unlock Progression

### Unlock Methods

Players can unlock attachments through:

1. **Kill Requirements**: Get X kills with the weapon
2. **Pre-Purchase**: Buy with credits (same price as kill unlock)
3. **Level Requirements**: Some attachments require certain rank

### Unlock Tiers

**Standard progression** (kills required):

| Tier | Kills Required | Typical Attachments |
|------|---------------|-------------------|
| 0    | 0 (Default)   | Iron Sights, Standard Barrel |
| 1    | 5-25          | Basic Red Dots, Flashlight |
| 2    | 50-100        | Grips, Laser, Basic Suppressors |
| 3    | 150-300       | Advanced Sights, Tactical Suppressors |
| 4    | 400-700       | Scopes, Special Barrels |
| 5    | 1000-1500     | High-magnification Scopes, Special Grips |
| 6    | 2000-2500     | Exclusive Attachments |

**Credit costs** match tier:
- Tier 1: 200-500 credits
- Tier 2: 500-1000 credits
- Tier 3: 1000-2000 credits
- Tier 4: 2000-3500 credits
- Tier 5: 4000-6000 credits
- Tier 6: 7500+ credits

### Defining Unlock Requirements

```lua
{
    Name = "ACOG_4x",
    UnlockKills = 250, -- Requires 250 kills with this weapon
    Cost = 2000, -- Can pre-buy for 2000 credits
    LevelRequirement = 10, -- Also requires player to be rank 10+
}
```

### Kill Tracking

Kills are tracked per-weapon in DataStoreManager:

```lua
-- DataStoreManager structure
PlayerData = {
    Weapons = {
        G36 = {
            Kills = 327,
            UnlockedAttachments = {
                "RedDot_Reflex",
                "AngledGrip",
                "TacticalSuppressor"
            }
        }
    }
}
```

### Unlock Notification

When a player unlocks an attachment:

```lua
-- Server-side unlock
local function UnlockAttachment(player, weaponName, attachmentName)
    DataStoreManager:UnlockAttachment(player, weaponName, attachmentName)

    -- Notify client
    RemoteEvents.AttachmentUnlocked:FireClient(player, weaponName, attachmentName)
end

-- Client receives unlock notification
RemoteEvents.AttachmentUnlocked.OnClientEvent:Connect(function(weaponName, attachmentName)
    -- Show UI popup: "New Attachment Unlocked: [Name]"
end)
```

### Pre-Purchase System

Players can buy attachments before unlocking them:

**Server handler**:
```lua
function ShopHandler:PurchaseAttachment(player, weaponName, attachmentName)
    local attachment = self:GetAttachment(weaponName, attachmentName)
    if not attachment then return false end

    -- Check if already unlocked
    if DataStoreManager:HasAttachmentUnlocked(player, weaponName, attachmentName) then
        return false, "Already unlocked"
    end

    -- Check if player has enough credits
    local credits = DataStoreManager:GetPlayerCredits(player)
    if credits < attachment.Cost then
        return false, "Insufficient credits"
    end

    -- Deduct credits
    DataStoreManager:AddCredits(player, -attachment.Cost)

    -- Unlock attachment
    DataStoreManager:UnlockAttachment(player, weaponName, attachmentName)

    return true
end
```

---

## Special Attachment Types

### Ammo Types (Conversions)

**Ammo type attachments** change weapon behavior significantly.

#### Armor Piercing

```lua
{
    Name = "ArmorPiercing",
    DisplayName = "Armor Piercing Rounds",
    Category = "Other",
    Subcategory = "Ammo",
    UnlockKills = 500,
    Cost = 3000,

    Modifiers = {
        PenetrationMultiplier = 2.0, -- Double penetration
        DamageMultiplier = 0.85, -- 15% less damage to torso
        HeadshotMultiplier = 0.90, -- 10% less headshot damage
        CanDamageVehicles = true, -- Can now damage vehicles
    },
}
```

#### Shotgun Ammo Types

```lua
-- Birdshot (more pellets, less damage)
{
    Name = "Birdshot",
    PelletCount = 18, -- More pellets
    DamageMultiplier = 0.60, -- Much less damage per pellet
    PelletSpread = 1.3, -- Wider spread
}

-- Slugs (single projectile)
{
    Name = "Slugs",
    PelletCount = 1, -- Single slug
    DamageMultiplier = 2.5, -- Much more damage
    Range = 2.0, -- Double range
    PelletSpread = 0.1, -- Very accurate
}

-- Dragon's Breath (incendiary)
{
    Name = "DragonsBreath",
    PelletCount = 8,
    DamageMultiplier = 0.70,
    StatusEffect = "Burn", -- Apply burn status
    StatusEffectDuration = 5,
}
```

### Barrel Conversions

Some weapons have **conversion attachments** that dramatically change the weapon:

#### NTW-20 Barrels

```lua
-- Heavy Barrel (extreme range)
{
    Name = "NTW20_HeavyBarrel",
    Modifiers = {
        Range = 2.0, -- Double range
        BulletVelocity = 1.5,
        WalkSpeedMultiplier = 0.60, -- Much slower
        RequiresCrouchToScope = true, -- Must crouch/mount
    },
}

-- Obrez Barrel (CQC sniper)
{
    Name = "NTW20_ObrezBarrel",
    Modifiers = {
        Range = 0.40, -- 60% less range
        AccuracyMultiplier = 0.60, -- Poor accuracy
        WalkSpeedMultiplier = 1.15, -- Faster movement
        RequiresCrouchToScope = false, -- Can scope standing
        BulletDropOff = 2.0, -- Must aim higher
    },
}
```

### Scopes (Advanced)

#### 3D Scopes

Uses Roblox ViewportFrame to render a second camera:

```lua
{
    Name = "Sniper_8x_3D",
    ScopeType = "3D",
    ZoomLevel = 8.0,

    -- 3D Scope configuration
    Scope3DConfig = {
        LensSize = UDim2.new(0.4, 0, 0.4, 0), -- Size of scope view
        RenderDistance = 2000, -- Max render distance
        FOV = 15, -- Narrow FOV when zoomed
    },
}
```

#### UI Scopes

Uses GuiObject overlay:

```lua
{
    Name = "Sniper_8x_UI",
    ScopeType = "UI",
    ZoomLevel = 8.0,

    -- UI Scope configuration
    ScopeUIConfig = {
        OverlayImage = "rbxassetid://12345",
        ReticleImage = "rbxassetid://67890",
        BlackoutScreen = true, -- Black out non-scope area
        SwayEnabled = true, -- Enable scope sway
        SwayAmount = 0.5,
        StabilizeKey = Enum.KeyCode.LeftShift,
        StabilizeDuration = 3.0, -- Seconds of stabilization
    },
}
```

#### Toggleable Scopes

Support both modes with **T** key:

```lua
{
    Name = "HybridScope_4x",
    ScopeType = "Both", -- Can toggle
    ZoomLevel = 4.0,
    ToggleKey = Enum.KeyCode.T,
    DefaultMode = "UI", -- Start in UI mode
}
```

### Underbarrel Weapons

Some "attachments" are actually secondary weapons:

```lua
{
    Name = "UnderbarrelGrenadeLauncher",
    Category = "Underbarrel",
    Subcategory = "Weapon",

    -- Acts as separate weapon
    WeaponType = "GrenadeLauncher",
    SwitchKey = Enum.KeyCode.B,
    Ammo = 3,
    Damage = 150,
    ExplosionRadius = 15,

    Modifiers = {
        WalkSpeedMultiplier = 0.92, -- Adds weight
    },
}
```

---

## Testing Attachments

### Testing Checklist

#### Visual Testing

- [ ] Attachment model appears correctly on weapon
- [ ] No clipping with weapon model
- [ ] Attachment positioned correctly on viewmodel
- [ ] Attachment visible in third-person
- [ ] Attachment respects weapon's CFrame/rotation
- [ ] Attachment disappears when weapon is unequipped

#### Stat Testing

- [ ] Modified stats are applied (check damage, range, recoil)
- [ ] Stat changes match config values
- [ ] Multiple attachments stack correctly
- [ ] Negative modifiers work (penalties applied)
- [ ] Stat changes persist through respawn
- [ ] Original stats restored when attachment removed

#### Unlock Testing

- [ ] Attachment locked initially
- [ ] Kill count increases on weapon kills
- [ ] Attachment unlocks at correct kill count
- [ ] Can pre-purchase with credits
- [ ] Credits deducted on purchase
- [ ] Unlock persists through server restart

#### Compatibility Testing

- [ ] Universal attachments work on all compatible weapons
- [ ] Weapon-specific attachments only show for correct weapons
- [ ] Excluded weapons cannot equip attachment
- [ ] Server validates attachment compatibility
- [ ] Invalid attachments rejected with warning

#### Special Feature Testing

**Scopes**:
- [ ] Scope zoom level correct
- [ ] T key toggles between 3D/UI modes (if applicable)
- [ ] 3D scope renders correctly
- [ ] UI scope overlay displays
- [ ] Scope sway works
- [ ] Stabilization with Shift works
- [ ] ADS speed modifier applied

**Suppressors**:
- [ ] Gunshot sound quieter
- [ ] Radar signature reduced
- [ ] Suppressed range working correctly
- [ ] Muzzle flash reduced/hidden

**Lasers**:
- [ ] Laser visible to player
- [ ] Laser only visible to team (not enemies)
- [ ] Laser updates with weapon aim
- [ ] Laser disappears when weapon unequipped

**Flashlights**:
- [ ] Light illuminates area
- [ ] Light visible to all players (enemies too)
- [ ] Light toggle works
- [ ] Light drains battery (if applicable)

**Ammo Types**:
- [ ] Ammo type changes weapon behavior
- [ ] Special effects apply (fire, ice, etc.)
- [ ] Penetration changes work
- [ ] Damage modifiers apply correctly
- [ ] Vehicle damage enabled (if applicable)

#### Performance Testing

- [ ] No significant FPS drop with attachment
- [ ] Multiple players with attachments perform well
- [ ] Attachment models optimized
- [ ] No memory leaks when equipping/unequipping

### Testing Commands

Use these admin commands to test attachments:

```lua
-- Unlock all attachments for a weapon
/unlock [weaponName] all

-- Give credits for purchasing
/addcredits [amount]

-- Set weapon kills
/setkills [weaponName] [killCount]

-- Force equip attachment (bypass unlock)
/equipattachment [weaponName] [attachmentName]
```

### Debug Output

Enable debug prints in AttachmentManager:

```lua
-- In AttachmentManager.lua
local DEBUG_MODE = true

function AttachmentManager:ApplyAttachment(weaponModel, attachmentConfig)
    if DEBUG_MODE then
        print("[AttachmentManager] Applying:", attachmentConfig.Name)
        print("  Model Path:", attachmentConfig.ModelPath)
        print("  Attachment Point:", attachmentConfig.AttachmentPoint)
        print("  Modifiers:", attachmentConfig.Modifiers)
    end

    -- ... attachment logic
end
```

---

## Troubleshooting

### Common Issues

#### Attachment Not Appearing

**Symptoms**: Attachment model doesn't show on weapon

**Possible Causes**:
1. ModelPath is incorrect
2. Attachment point doesn't exist on weapon
3. Attachment model not in correct location
4. Model's PrimaryPart not set

**Solutions**:
1. Verify ModelPath matches exact location in ReplicatedStorage
2. Check weapon model has attachment point (e.g., "SightAttachment")
3. Move attachment model to correct folder
4. Set Model.PrimaryPart in Roblox Studio

#### Stats Not Changing

**Symptoms**: Equipping attachment doesn't change weapon behavior

**Possible Causes**:
1. Modifiers not defined in config
2. Weapon script not reading attachment modifiers
3. Attachment not actually equipped (failed validation)

**Solutions**:
1. Check WeaponConfig has Modifiers table
2. Verify weapon script calls `ApplyAttachmentModifiers()`
3. Check server output for validation errors

#### Attachment Clipping

**Symptoms**: Attachment model clips through weapon model

**Possible Causes**:
1. Attachment point positioned incorrectly
2. Attachment model sized wrong
3. WeaponAttach Attachment misaligned

**Solutions**:
1. Adjust attachment point position on weapon
2. Scale attachment model
3. Ensure WeaponAttach is at (0,0,0) relative to PrimaryPart

#### Can't Unlock Attachment

**Symptoms**: Attachment stays locked despite meeting requirements

**Possible Causes**:
1. Kill count not saving
2. DataStore error
3. Unlock requirement mismatch

**Solutions**:
1. Check DataStoreManager is saving weapon kills
2. Check Studio console for DataStore errors
3. Verify UnlockKills in config matches expected value

#### Scope Not Working

**Symptoms**: Scope doesn't zoom or render incorrectly

**Possible Causes**:
1. ScopeType not set correctly
2. ZoomLevel not defined
3. ViewportFrame not created (3D scopes)
4. Overlay image missing (UI scopes)

**Solutions**:
1. Set ScopeType to "3D", "UI", or "Both"
2. Define ZoomLevel (e.g., 4.0 for 4x)
3. Check ScopeSystem creates ViewportFrame
4. Verify ScopeOverlayImage asset ID is valid

#### Multiplayer Desync

**Symptoms**: Attachment appears in different position for different players

**Possible Causes**:
1. Attachment applied client-side only
2. Replication lag
3. Attachment point positions differ between viewmodel and third-person model

**Solutions**:
1. Ensure server applies attachments to third-person model
2. Add replication wait time
3. Match attachment point positions exactly

---

## Attachment Presets

### Assault Rifle Attachments

```lua
Attachments = {
    Sight = {
        {Name = "IronSights", UnlockKills = 0, Cost = 0}, -- Default
        {Name = "RedDot", UnlockKills = 10, Cost = 300},
        {Name = "Holographic", UnlockKills = 50, Cost = 500},
        {Name = "ACOG_4x", UnlockKills = 200, Cost = 1500},
    },
    Barrel = {
        {Name = "Standard", UnlockKills = 0, Cost = 0}, -- Default
        {Name = "CarbineBarrel", UnlockKills = 100, Cost = 800},
        {Name = "HeavyBarrel", UnlockKills = 300, Cost = 2000},
    },
    Underbarrel = {
        {Name = "VerticalGrip", UnlockKills = 50, Cost = 500},
        {Name = "AngledGrip", UnlockKills = 150, Cost = 1000},
    },
    Other = {
        {Name = "Suppressor", UnlockKills = 200, Cost = 1500},
        {Name = "Laser", UnlockKills = 25, Cost = 400},
        {Name = "Flashlight", UnlockKills = 5, Cost = 200},
    },
}
```

### Sniper Rifle Attachments

```lua
Attachments = {
    Sight = {
        {Name = "IronSights", UnlockKills = 0, Cost = 0},
        {Name = "Scope_6x", UnlockKills = 0, Cost = 0}, -- Default scope
        {Name = "Scope_8x", UnlockKills = 150, Cost = 1200},
        {Name = "Scope_12x", UnlockKills = 500, Cost = 3000},
    },
    Barrel = {
        {Name = "Standard", UnlockKills = 0, Cost = 0},
        {Name = "HeavyBarrel", UnlockKills = 400, Cost = 2500},
        {Name = "ObrezBarrel", UnlockKills = 600, Cost = 3500}, -- CQC variant
    },
    Underbarrel = {
        {Name = "Bipod", UnlockKills = 200, Cost = 1500},
    },
    Other = {
        {Name = "Suppressor", UnlockKills = 300, Cost = 2500},
        {Name = "MuzzleBrake", UnlockKills = 100, Cost = 800},
    },
}
```

### Shotgun Attachments

```lua
Attachments = {
    Sight = {
        {Name = "BeadSight", UnlockKills = 0, Cost = 0}, -- Default
        {Name = "RedDot", UnlockKills = 50, Cost = 500},
    },
    Barrel = {
        {Name = "Standard", UnlockKills = 0, Cost = 0},
        {Name = "FullChoke", UnlockKills = 100, Cost = 800}, -- Tighter spread
        {Name = "SawedOff", UnlockKills = 250, Cost = 2000}, -- Wide spread, high mobility
    },
    Underbarrel = {
        {Name = "Foregrip", UnlockKills = 75, Cost = 600},
    },
    Other = {
        {Name = "Birdshot", UnlockKills = 50, Cost = 500}, -- More pellets
        {Name = "Slugs", UnlockKills = 200, Cost = 1500}, -- Single projectile
        {Name = "DragonsBreath", UnlockKills = 500, Cost = 3500}, -- Incendiary
        {Name = "Laser", UnlockKills = 25, Cost = 400},
    },
}
```

### Pistol Attachments

```lua
Attachments = {
    Sight = {
        {Name = "IronSights", UnlockKills = 0, Cost = 0},
        {Name = "MiniRedDot", UnlockKills = 100, Cost = 800},
    },
    Barrel = {
        {Name = "Standard", UnlockKills = 0, Cost = 0},
        {Name = "ExtendedBarrel", UnlockKills = 200, Cost = 1500},
    },
    Other = {
        {Name = "PistolSuppressor", UnlockKills = 150, Cost = 1200},
        {Name = "Laser", UnlockKills = 50, Cost = 400},
        {Name = "Flashlight", UnlockKills = 25, Cost = 300},
        {Name = "ExtendedMag", UnlockKills = 100, Cost = 800},
    },
}
```

---

## Summary

This guide covered the complete attachment system:

1. **Attachment Categories**: Sights, Barrels, Underbarrel, Other
2. **Creating Attachments**: WeaponConfig definition, 3D models, attachment points
3. **Stat Modifications**: Multiplicative, additive, and replacement modifiers
4. **Compatibility**: Universal vs weapon-specific attachments
5. **3D Models**: Proper structure, attachment points, optimization
6. **Unlock Progression**: Kill requirements, pre-purchase, credit costs
7. **Special Types**: Ammo conversions, scopes, lasers, suppressors
8. **Testing**: Comprehensive checklist and debug tools
9. **Troubleshooting**: Common issues and solutions
10. **Presets**: Ready-to-use attachment sets for different weapon types

**Next Steps**:
1. Review [WEAPON_SYSTEM_GUIDE.md](WEAPON_SYSTEM_GUIDE.md) for weapon creation
2. Review [VEHICLE_SYSTEM_GUIDE.md](VEHICLE_SYSTEM_GUIDE.md) for vehicle system
3. Create your first custom attachment following this guide
4. Test thoroughly using the testing checklist
5. Balance attachments based on player feedback

**Need Help?**
- Check [Troubleshooting](#troubleshooting) section
- Review example attachment configs in WeaponConfig.lua
- Test with debug mode enabled
- Ask for help with specific error messages

---

**Document Version:** 1.0
**Last Updated:** 2025-10-12
**Maintained By:** FPS System Team
