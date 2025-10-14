# Vehicle System Guide

**Version:** 1.0
**Last Updated:** 2025-10-12
**Author:** FPS System Team

---

## Table of Contents

1. [Overview](#overview)
2. [Vehicle Types](#vehicle-types)
3. [Vehicle Configuration](#vehicle-configuration)
4. [Creating New Vehicles](#creating-new-vehicles)
5. [Vehicle Controls](#vehicle-controls)
6. [Damage System](#damage-system)
7. [Destruction Physics](#destruction-physics)
8. [Vehicle Spawning](#vehicle-spawning)
9. [AA Gun System](#aa-gun-system)
10. [Testing Vehicles](#testing-vehicles)
11. [Troubleshooting](#troubleshooting)
12. [Vehicle Presets](#vehicle-presets)

---

## Overview

The vehicle system adds drivable/pilotable vehicles to the FPS game, including **tanks**, **helicopters**, and **mounted AA guns**. Vehicles feature realistic physics, destruction mechanics, passenger seats, and weapon systems.

### Key Features

- **Multiple Vehicle Types**: Tanks, helicopters, transport vehicles, AA guns
- **Realistic Physics**: VehicleSeat-based movement with custom constraints
- **Destruction System**: Health-based damage with visual destruction
- **Weapon Integration**: Vehicle-mounted weapons with unique damage models
- **Passenger System**: Driver + multiple passenger seats
- **Armor Penetration**: Special weapons/ammo required to damage armored vehicles
- **Admin Controls**: Spawn, clear, and destroy vehicles via commands

### Core Modules

```
ReplicatedStorage.FPSSystem.Modules
├─ VehicleSystem.lua           -- Core vehicle logic (client/server shared)
├─ VehicleConfig.lua           -- Vehicle definitions and stats
├─ DamageSystem.lua            -- Handles vehicle damage calculations
└─ DestructionPhysics.lua      -- Vehicle destruction and debris

ServerScriptService
├─ VehicleHandler.server.lua   -- Server-side vehicle management
└─ TeamSpawnSystem.server.lua  -- Spawns vehicles at team bases

StarterPlayer.StarterPlayerScripts
└─ VehicleController.client.lua -- Client-side vehicle controls and camera
```

---

## Vehicle Types

### 1. Ground Vehicles (Tanks)

**Purpose**: Heavy armor, high firepower, slow movement

**Examples**:
- **M1 Abrams**: Modern main battle tank
- **T-90**: Russian heavy tank
- **Light Tank**: Faster, less armor

**Features**:
- Treads/wheels for movement
- Turret rotation (independent of chassis)
- Main cannon + secondary weapons
- Heavy armor (requires AP rounds to damage)
- Slower movement speed
- Can crush obstacles

### 2. Air Vehicles (Helicopters)

**Purpose**: Air superiority, fast transport, aerial attacks

**Examples**:
- **AH-64 Apache**: Attack helicopter
- **UH-60 Black Hawk**: Transport helicopter
- **Light Scout Chopper**: Fast reconnaissance

**Features**:
- BodyGyro/BodyVelocity for flight physics
- Rotor animations
- Missiles + machine guns
- Vulnerable to AA weapons
- High speed, low armor
- Can transport multiple passengers

### 3. Stationary Weapons (AA Guns)

**Purpose**: Anti-aircraft defense, area denial

**Examples**:
- **ZU-23-2**: Twin-barrel AA gun
- **Flak Cannon**: Heavy AA gun
- **SAM Launcher**: Surface-to-air missiles

**Features**:
- Mountable/placeable on buildings
- 360° rotation + vertical aim
- High damage to air vehicles
- Limited traverse speed
- Cannot move once placed
- Can be destroyed

### 4. Transport Vehicles

**Purpose**: Move multiple players quickly

**Examples**:
- **Humvee**: Light transport (4 passengers)
- **APC**: Armored personnel carrier (8 passengers)
- **Truck**: Fast transport, no armor

**Features**:
- Multiple passenger seats
- Light/no armor
- Fast movement
- No weapons (or light weapons)

---

## Vehicle Configuration

All vehicle configurations are stored in:
```
ReplicatedStorage.FPSSystem.Modules.VehicleConfig
```

### Base Vehicle Config Structure

```lua
VehicleConfig = {
    Vehicles = {
        M1Abrams = {
            -- Basic Info
            Name = "M1Abrams",
            DisplayName = "M1 Abrams Tank",
            Description = "Modern main battle tank with heavy armor and powerful cannon",
            Type = "Tank", -- "Tank", "Helicopter", "Transport", "AAGun"
            Team = "All", -- "FBI", "KFC", "All"

            -- Model
            ModelPath = "ReplicatedStorage.FPSSystem.Vehicles.M1Abrams",

            -- Health & Armor
            MaxHealth = 2000,
            ArmorType = "Heavy", -- "Light", "Medium", "Heavy", "None"
            RequiresArmorPiercing = true, -- Regular bullets do reduced damage

            -- Movement (Ground Vehicles)
            MaxSpeed = 50, -- Studs/second
            Acceleration = 10,
            TurnSpeed = 20, -- Degrees/second
            BrakeForce = 50,

            -- OR Movement (Air Vehicles)
            MaxFlightSpeed = 80,
            LiftForce = 5000,
            TurnRate = 30,

            -- Seats
            Seats = {
                Driver = {
                    SeatName = "DriverSeat", -- VehicleSeat name in model
                    CanControlMovement = true,
                    CanControlWeapons = true,
                    CameraMode = "FirstPerson", -- "FirstPerson", "ThirdPerson", "Both"
                    ExitPosition = Vector3.new(-5, 0, 0), -- Relative to vehicle
                },
                Gunner = {
                    SeatName = "GunnerSeat",
                    CanControlMovement = false,
                    CanControlWeapons = true,
                    CameraMode = "FirstPerson",
                    WeaponType = "MainCannon", -- Which weapon this seat controls
                    ExitPosition = Vector3.new(5, 0, 0),
                },
                Passenger1 = {
                    SeatName = "PassengerSeat1",
                    CanControlMovement = false,
                    CanControlWeapons = false,
                    CameraMode = "ThirdPerson",
                    ExitPosition = Vector3.new(0, 0, 5),
                },
            },

            -- Weapons
            Weapons = {
                MainCannon = {
                    Name = "120mm Cannon",
                    Type = "Projectile", -- "Projectile", "Hitscan", "Missile"
                    Damage = 500,
                    SplashDamage = 200,
                    SplashRadius = 15,
                    FireRate = 0.2, -- Rounds per second
                    ReloadTime = 5, -- Seconds
                    MagazineSize = 1,
                    ReserveAmmo = 40,
                    ProjectileSpeed = 500, -- Studs/second
                    Gravity = true,
                    ExplosionEffect = "Explosion",
                    FireSound = "rbxassetid://12345",
                    MuzzleFlashAttachment = "CannonMuzzle", -- Attachment in model
                },
                MachineGun = {
                    Name = "Coaxial MG",
                    Type = "Hitscan",
                    Damage = 30,
                    FireRate = 10, -- Rounds per second
                    MagazineSize = 100,
                    ReserveAmmo = 500,
                    Spread = 2,
                    FireSound = "rbxassetid://67890",
                    MuzzleFlashAttachment = "MGMuzzle",
                },
            },

            -- Destruction
            DestructionConfig = {
                ExplodeOnDestroy = true,
                ExplosionSize = 20,
                ExplosionDamage = 150,
                DebrisLifetime = 30, -- Seconds before cleanup
                DestroyEffect = "VehicleExplosion",
                SpawnDebris = true,
                DebrisParts = { -- Parts that separate on death
                    "Turret",
                    "Hatch",
                    "Treads",
                },
            },

            -- Special Properties
            CanCrushPlayers = true, -- Run over enemies
            CanDestroyBuildings = false, -- Environment destruction
            WaterProof = false, -- Sinks in water
            RegenerationRate = 0, -- HP/second (0 = no regen)

            -- Spawn Settings
            SpawnCooldown = 120, -- Seconds before can respawn
            RequiresCapture = false, -- Must capture point to spawn
            MaxActiveVehicles = 2, -- Max of this type per team
        },

        -- More vehicles...
    },
}
```

---

## Creating New Vehicles

### Step-by-Step Process

#### Step 1: Design Vehicle Model

1. **Create the vehicle model in Roblox Studio**:
   ```
   M1Abrams (Model)
   ├─ Chassis (Part) [PrimaryPart, Heavy armor]
   ├─ Turret (Model) -- Can rotate independently
   │  ├─ TurretBase (Part)
   │  ├─ Cannon (Part)
   │  └─ CannonMuzzle (Attachment) -- Where projectiles spawn
   ├─ DriverSeat (VehicleSeat)
   ├─ GunnerSeat (Seat)
   ├─ PassengerSeat1 (Seat)
   ├─ Wheels/Treads (Parts with motors)
   └─ DestructionParts (Folder)
      ├─ Turret (for separating on death)
      └─ Hatch (for separating on death)
   ```

2. **Set up vehicle physics**:
   - Add VehicleSeat for driver
   - Configure seat properties:
     - `MaxSpeed`
     - `Torque`
     - `TurnSpeed`
   - Add BodyGyro/BodyVelocity for helicopters
   - Add WeldConstraints for parts that should stay together

3. **Add weapon attachment points**:
   - `CannonMuzzle`: Where main cannon fires from
   - `MGMuzzle`: Machine gun fire point
   - `MissileLaunchers`: Missile spawn points
   - Each attachment should face forward (LookVector)

4. **Set up turret rotation**:
   - Turret should be a separate Model
   - Use HingeConstraint or Motor6D for rotation
   - Connect to driver/gunner seat

5. **Add seat positions**:
   - Driver: Front of vehicle
   - Gunner: Turret position
   - Passengers: Rear/sides

6. **Save to ReplicatedStorage**:
   ```
   ReplicatedStorage.FPSSystem.Vehicles.M1Abrams
   ```

#### Step 2: Define Vehicle in VehicleConfig

Open `ReplicatedStorage.FPSSystem.Modules.VehicleConfig.lua`

```lua
VehicleConfig = {
    Vehicles = {
        -- NEW TANK
        M1Abrams = {
            Name = "M1Abrams",
            DisplayName = "M1 Abrams Tank",
            Description = "Modern main battle tank with heavy armor and powerful cannon",
            Type = "Tank",
            Team = "All",

            ModelPath = "ReplicatedStorage.FPSSystem.Vehicles.M1Abrams",

            MaxHealth = 2000,
            ArmorType = "Heavy",
            RequiresArmorPiercing = true,

            MaxSpeed = 50,
            Acceleration = 10,
            TurnSpeed = 20,
            BrakeForce = 50,

            Seats = {
                Driver = {
                    SeatName = "DriverSeat",
                    CanControlMovement = true,
                    CanControlWeapons = false, -- Driver only drives
                    CameraMode = "FirstPerson",
                    ExitPosition = Vector3.new(-5, 0, 0),
                },
                Gunner = {
                    SeatName = "GunnerSeat",
                    CanControlMovement = false,
                    CanControlWeapons = true, -- Gunner fires weapons
                    CameraMode = "FirstPerson",
                    WeaponType = "MainCannon",
                    ExitPosition = Vector3.new(5, 0, 0),
                },
            },

            Weapons = {
                MainCannon = {
                    Name = "120mm Cannon",
                    Type = "Projectile",
                    Damage = 500,
                    SplashDamage = 200,
                    SplashRadius = 15,
                    FireRate = 0.2,
                    ReloadTime = 5,
                    MagazineSize = 1,
                    ReserveAmmo = 40,
                    ProjectileSpeed = 500,
                    Gravity = true,
                    ExplosionEffect = "Explosion",
                    FireSound = "rbxassetid://12345",
                    MuzzleFlashAttachment = "CannonMuzzle",
                },
            },

            DestructionConfig = {
                ExplodeOnDestroy = true,
                ExplosionSize = 20,
                ExplosionDamage = 150,
                DebrisLifetime = 30,
                DestroyEffect = "VehicleExplosion",
                SpawnDebris = true,
                DebrisParts = {"Turret", "Hatch", "Treads"},
            },

            CanCrushPlayers = true,
            WaterProof = false,
            SpawnCooldown = 120,
            MaxActiveVehicles = 2,
        },

        -- NEW HELICOPTER
        AH64Apache = {
            Name = "AH64Apache",
            DisplayName = "AH-64 Apache",
            Description = "Attack helicopter with missiles and chain gun",
            Type = "Helicopter",
            Team = "All",

            ModelPath = "ReplicatedStorage.FPSSystem.Vehicles.AH64Apache",

            MaxHealth = 800,
            ArmorType = "Light",
            RequiresArmorPiercing = false,

            -- Flight physics
            MaxFlightSpeed = 80,
            LiftForce = 5000,
            TurnRate = 30,
            MaxAltitude = 500, -- Studs

            Seats = {
                Pilot = {
                    SeatName = "PilotSeat",
                    CanControlMovement = true,
                    CanControlWeapons = true, -- Pilot can fire rockets
                    CameraMode = "ThirdPerson",
                    WeaponType = "Rockets",
                    ExitPosition = Vector3.new(-5, -10, 0), -- Ejects downward
                },
                Gunner = {
                    SeatName = "GunnerSeat",
                    CanControlMovement = false,
                    CanControlWeapons = true,
                    CameraMode = "FirstPerson",
                    WeaponType = "ChainGun",
                    ExitPosition = Vector3.new(5, -10, 0),
                },
            },

            Weapons = {
                Rockets = {
                    Name = "Hydra Rockets",
                    Type = "Missile",
                    Damage = 300,
                    SplashDamage = 150,
                    SplashRadius = 10,
                    FireRate = 2, -- Rockets per second
                    MagazineSize = 16,
                    ReserveAmmo = 64,
                    ProjectileSpeed = 200,
                    HomingEnabled = false,
                    ExplosionEffect = "Explosion",
                    FireSound = "rbxassetid://rocket_sound",
                    MuzzleFlashAttachment = "RocketPods",
                },
                ChainGun = {
                    Name = "M230 Chain Gun",
                    Type = "Hitscan",
                    Damage = 50,
                    FireRate = 10,
                    MagazineSize = 200,
                    ReserveAmmo = 1000,
                    Spread = 3,
                    FireSound = "rbxassetid://chaingun_sound",
                    MuzzleFlashAttachment = "ChainGunMuzzle",
                },
            },

            DestructionConfig = {
                ExplodeOnDestroy = true,
                ExplosionSize = 15,
                ExplosionDamage = 120,
                DebrisLifetime = 20,
                DestroyEffect = "HelicopterExplosion",
                SpawnDebris = true,
                DebrisParts = {"Rotors", "Tail"},
            },

            CanCrushPlayers = false,
            WaterProof = false,
            SpawnCooldown = 180, -- Longer cooldown for powerful vehicle
            MaxActiveVehicles = 1,
        },
    },
}
```

#### Step 3: Configure Vehicle Spawners

**Place vehicle spawn points on the map**:

1. Create a Part named "VehicleSpawner"
2. Add a Configuration folder inside with:
   ```
   VehicleSpawner (Part)
   └─ Config (Configuration)
      ├─ VehicleType (StringValue) = "M1Abrams"
      ├─ Team (StringValue) = "FBI" or "KFC" or "All"
      ├─ SpawnInterval (NumberValue) = 120
      └─ MaxActive (NumberValue) = 2
   ```

3. Place in `Workspace.VehicleSpawners` folder

4. **TeamSpawnSystem.server.lua** will detect and spawn vehicles automatically

#### Step 4: Test Vehicle

See [Testing Vehicles](#testing-vehicles) section.

---

## Vehicle Controls

### Driver Controls

| Input | Action |
|-------|--------|
| W | Accelerate forward |
| S | Reverse / Brake |
| A | Turn left |
| D | Turn right |
| Space | Handbrake (ground) / Descend (air) |
| Shift | Boost (if available) |
| F | Exit vehicle |
| C | Change camera mode |

### Gunner Controls

| Input | Action |
|-------|--------|
| Mouse | Aim turret / weapon |
| Left Click | Fire weapon |
| Right Click | Secondary fire / Zoom |
| R | Reload |
| F | Exit vehicle |
| 1, 2, 3 | Switch weapons (if multiple) |

### Helicopter Controls

| Input | Action |
|-------|--------|
| W | Pitch forward (fly forward) |
| S | Pitch backward (fly backward) |
| A | Roll left |
| D | Roll right |
| Q | Yaw left (turn left) |
| E | Yaw right (turn right) |
| Space | Ascend (up) |
| Shift | Descend (down) |
| Left Click | Fire rockets/missiles |
| F | Exit helicopter |

### Control Implementation

**Client-side controller** (`VehicleController.client.lua`):

```lua
local VehicleController = {}
local UserInputService = game:GetService("UserInputService")
local currentVehicle = nil
local seatType = nil -- "Driver", "Gunner", "Passenger"

function VehicleController:EnterVehicle(vehicle, seat)
    currentVehicle = vehicle
    seatType = seat

    if seatType == "Driver" then
        self:SetupDriverControls(vehicle)
    elseif seatType == "Gunner" then
        self:SetupGunnerControls(vehicle)
    end

    self:SetupCamera(vehicle, seat)
end

function VehicleController:SetupDriverControls(vehicle)
    local vehicleConfig = VehicleConfig:GetVehicle(vehicle.Name)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.W then
            -- Accelerate forward
            RemoteEvents.VehicleAction:FireServer(vehicle, "Accelerate", 1)
        elseif input.KeyCode == Enum.KeyCode.S then
            -- Reverse
            RemoteEvents.VehicleAction:FireServer(vehicle, "Accelerate", -1)
        elseif input.KeyCode == Enum.KeyCode.A then
            -- Turn left
            RemoteEvents.VehicleAction:FireServer(vehicle, "Turn", -1)
        elseif input.KeyCode == Enum.KeyCode.D then
            -- Turn right
            RemoteEvents.VehicleAction:FireServer(vehicle, "Turn", 1)
        elseif input.KeyCode == Enum.KeyCode.F then
            -- Exit vehicle
            self:ExitVehicle()
        end
    end)
end

function VehicleController:SetupGunnerControls(vehicle)
    local vehicleConfig = VehicleConfig:GetVehicle(vehicle.Name)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Fire weapon
            local mousePosition = UserInputService:GetMouseLocation()
            RemoteEvents.VehicleAction:FireServer(vehicle, "Fire", mousePosition)
        elseif input.KeyCode == Enum.KeyCode.R then
            -- Reload
            RemoteEvents.VehicleAction:FireServer(vehicle, "Reload")
        end
    end)
end

function VehicleController:ExitVehicle()
    if not currentVehicle then return end

    RemoteEvents.VehicleAction:FireServer(currentVehicle, "Exit")
    currentVehicle = nil
    seatType = nil
end

return VehicleController
```

**Server-side handler** (`VehicleHandler.server.lua`):

```lua
RemoteEvents.VehicleAction.OnServerEvent:Connect(function(player, vehicle, action, data)
    if not vehicle or not vehicle:IsA("Model") then return end

    -- Verify player is in vehicle
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or not humanoid.SeatPart then return end

    -- Check if seat is part of this vehicle
    if not humanoid.SeatPart:IsDescendantOf(vehicle) then return end

    -- Handle action
    if action == "Fire" then
        VehicleSystem:FireWeapon(vehicle, player, data)
    elseif action == "Accelerate" then
        VehicleSystem:Accelerate(vehicle, data)
    elseif action == "Turn" then
        VehicleSystem:Turn(vehicle, data)
    elseif action == "Exit" then
        VehicleSystem:ExitVehicle(vehicle, player)
    end
end)
```

---

## Damage System

### Armor Types

Vehicles have different armor types that affect damage taken:

| Armor Type | Damage Multiplier | Requires AP | Examples |
|-----------|------------------|------------|----------|
| None | 1.0x | No | Transport trucks |
| Light | 0.7x | No | Helicopters, light vehicles |
| Medium | 0.4x | Yes | APCs, IFVs |
| Heavy | 0.2x | Yes | Main battle tanks |

### Armor Piercing Requirements

**Regular bullets** do reduced damage to armored vehicles:
```lua
if vehicleConfig.RequiresArmorPiercing and not weaponConfig.ArmorPiercing then
    damage = damage * 0.1 -- Only 10% damage
end
```

**Armor Piercing weapons/ammo**:
- Sniper rifles with AP ammo
- Anti-tank weapons (RPGs, AT4)
- Tank cannons
- AA guns
- Some revolvers (by default)

**Weapons that can damage heavy vehicles**:
```lua
-- In WeaponConfig
Weapons = {
    NTW20 = {
        -- ... other stats
        CanDamageVehicles = true, -- Can damage all vehicles
        ArmorPiercing = true,
        VehicleDamageMultiplier = 2.0, -- Double damage to vehicles
    },

    RPG7 = {
        CanDamageVehicles = true,
        VehicleDamageMultiplier = 5.0, -- Extreme damage to vehicles
    },
}
```

### Damage Zones

Vehicles can have different damage multipliers for hit zones:

```lua
-- In VehicleConfig
DamageZones = {
    Chassis = {
        Parts = {"Chassis", "Hull"},
        Multiplier = 1.0, -- Normal damage
    },
    Turret = {
        Parts = {"Turret", "TurretBase"},
        Multiplier = 0.8, -- More armor
    },
    Engine = {
        Parts = {"Engine", "EngineBay"},
        Multiplier = 1.5, -- Vulnerable spot
    },
    Treads = {
        Parts = {"LeftTread", "RightTread"},
        Multiplier = 2.0, -- Can disable movement
        DisablesMovement = true,
    },
}
```

### Damage Calculation

**DamageSystem.lua** handles vehicle damage:

```lua
function DamageSystem:DamageVehicle(vehicle, damage, attacker, weapon, hitPart)
    local vehicleConfig = VehicleConfig:GetVehicle(vehicle.Name)
    if not vehicleConfig then return end

    -- Check if weapon can damage this vehicle
    local weaponConfig = WeaponConfig:GetWeapon(weapon)
    if not weaponConfig.CanDamageVehicles then
        damage = damage * 0.05 -- Minimal damage
    end

    -- Apply armor multiplier
    local armorMultiplier = self:GetArmorMultiplier(vehicleConfig.ArmorType)
    damage = damage * armorMultiplier

    -- Check armor piercing requirement
    if vehicleConfig.RequiresArmorPiercing and not weaponConfig.ArmorPiercing then
        damage = damage * 0.1 -- 90% damage reduction
    end

    -- Apply damage zone multiplier
    if hitPart and vehicleConfig.DamageZones then
        local zoneMultiplier = self:GetDamageZoneMultiplier(vehicleConfig, hitPart)
        damage = damage * zoneMultiplier
    end

    -- Apply vehicle damage multiplier from weapon
    if weaponConfig.VehicleDamageMultiplier then
        damage = damage * weaponConfig.VehicleDamageMultiplier
    end

    -- Apply damage to vehicle
    local currentHealth = vehicle:GetAttribute("Health") or vehicleConfig.MaxHealth
    local newHealth = math.max(0, currentHealth - damage)
    vehicle:SetAttribute("Health", newHealth)

    -- Check for destruction
    if newHealth <= 0 then
        self:DestroyVehicle(vehicle, attacker)
    end

    -- Update UI
    RemoteEvents.VehicleDamaged:FireAllClients(vehicle, newHealth, vehicleConfig.MaxHealth)
end
```

---

## Destruction Physics

### Vehicle Destruction Sequence

When a vehicle reaches 0 health:

1. **Trigger explosion** (if configured)
2. **Spawn debris parts** (turret, doors, etc. fly off)
3. **Apply ragdoll to vehicle** (parts become unanchored)
4. **Kill all occupants** (or eject them)
5. **Create fire/smoke effects**
6. **Remove vehicle after debris lifetime**

### Destruction Implementation

**DestructionPhysics.lua**:

```lua
function DestructionPhysics:DestroyVehicle(vehicle, killer)
    local vehicleConfig = VehicleConfig:GetVehicle(vehicle.Name)
    if not vehicleConfig or not vehicleConfig.DestructionConfig then return end

    local config = vehicleConfig.DestructionConfig

    -- Explosion
    if config.ExplodeOnDestroy then
        local explosion = Instance.new("Explosion")
        explosion.Position = vehicle.PrimaryPart.Position
        explosion.BlastRadius = config.ExplosionSize
        explosion.BlastPressure = 500000
        explosion.DestroyJointRadiusPercent = 0 -- Don't auto-destroy joints
        explosion.Parent = workspace

        -- Damage nearby players/vehicles
        self:ExplosionDamage(vehicle.PrimaryPart.Position, config.ExplosionDamage, config.ExplosionSize, killer)
    end

    -- Spawn debris
    if config.SpawnDebris and config.DebrisParts then
        for _, partName in pairs(config.DebrisParts) do
            local part = vehicle:FindFirstChild(partName, true)
            if part and part:IsA("BasePart") then
                self:CreateDebris(part, vehicle)
            end
        end
    end

    -- Eject/kill occupants
    self:EjectOccupants(vehicle, true) -- true = kill them

    -- Ragdoll vehicle
    self:RagdollVehicle(vehicle)

    -- Destruction effects
    self:CreateDestructionEffects(vehicle, config.DestroyEffect)

    -- Cleanup after debris lifetime
    task.wait(config.DebrisLifetime)
    vehicle:Destroy()
end

function DestructionPhysics:CreateDebris(part, vehicle)
    -- Clone part for debris
    local debris = part:Clone()
    debris.Parent = workspace.Debris

    -- Unanchor and make physics-enabled
    debris.Anchored = false
    debris.CanCollide = true

    -- Apply random velocity
    local randomForce = Vector3.new(
        math.random(-100, 100),
        math.random(50, 200),
        math.random(-100, 100)
    )
    debris.AssemblyLinearVelocity = randomForce
    debris.AssemblyAngularVelocity = Vector3.new(
        math.random(-10, 10),
        math.random(-10, 10),
        math.random(-10, 10)
    )

    -- Set debris properties
    debris:SetAttribute("Debris", true)
    game:GetService("Debris"):AddItem(debris, 30)

    -- Remove original part from vehicle
    part:Destroy()
end

function DestructionPhysics:RagdollVehicle(vehicle)
    for _, part in pairs(vehicle:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = true
        elseif part:IsA("JointInstance") then
            part:Destroy() -- Break welds
        end
    end
end
```

### Environment Destruction

**Vehicles can destroy buildings** (if configured):

```lua
-- In VehicleConfig
CanDestroyBuildings = true,
DestructionForce = 10000, -- Force applied to building parts

-- When vehicle collides with building
function VehicleSystem:OnVehicleCollision(vehicle, hitPart)
    local vehicleConfig = VehicleConfig:GetVehicle(vehicle.Name)
    if not vehicleConfig or not vehicleConfig.CanDestroyBuildings then return end

    if hitPart:HasTag("Destructible") then
        -- Apply damage to building part
        local health = hitPart:GetAttribute("Health") or 100
        local damage = vehicleConfig.DestructionForce / 100
        hitPart:SetAttribute("Health", health - damage)

        if hitPart:GetAttribute("Health") <= 0 then
            -- Destroy building part
            DestructionPhysics:CreateDebris(hitPart, nil)
        end
    end
end
```

---

## Vehicle Spawning

### Spawn System

**TeamSpawnSystem.server.lua** handles vehicle spawning:

```lua
local VehicleSpawns = {}

function TeamSpawnSystem:InitializeVehicleSpawns()
    local spawners = workspace:FindFirstChild("VehicleSpawners")
    if not spawners then return end

    for _, spawner in pairs(spawners:GetChildren()) do
        if spawner:IsA("BasePart") and spawner:FindFirstChild("Config") then
            local config = {
                Position = spawner.Position,
                Orientation = spawner.Orientation,
                VehicleType = spawner.Config.VehicleType.Value,
                Team = spawner.Config.Team.Value,
                SpawnInterval = spawner.Config.SpawnInterval.Value,
                MaxActive = spawner.Config.MaxActive.Value,
            }

            table.insert(VehicleSpawns, config)

            -- Initial spawn
            self:SpawnVehicle(config)

            -- Respawn on interval
            spawn(function()
                while true do
                    wait(config.SpawnInterval)
                    self:CheckAndRespawnVehicle(config)
                end
            end)
        end
    end
end

function TeamSpawnSystem:SpawnVehicle(spawnConfig)
    local vehicleConfig = VehicleConfig:GetVehicle(spawnConfig.VehicleType)
    if not vehicleConfig then
        warn("Vehicle not found:", spawnConfig.VehicleType)
        return
    end

    -- Check if max vehicles reached
    local activeCount = self:CountActiveVehicles(spawnConfig.VehicleType, spawnConfig.Team)
    if activeCount >= spawnConfig.MaxActive then
        return -- Don't spawn more
    end

    -- Clone vehicle model
    local vehicleModel = ReplicatedStorage:FindFirstChild(vehicleConfig.ModelPath, true)
    if not vehicleModel then
        warn("Vehicle model not found:", vehicleConfig.ModelPath)
        return
    end

    local vehicle = vehicleModel:Clone()
    vehicle:SetPrimaryPartCFrame(CFrame.new(spawnConfig.Position) * CFrame.Angles(0, math.rad(spawnConfig.Orientation.Y), 0))
    vehicle.Parent = workspace.Vehicles

    -- Initialize vehicle
    VehicleSystem:InitializeVehicle(vehicle, vehicleConfig, spawnConfig.Team)

    print("Spawned vehicle:", spawnConfig.VehicleType, "for team:", spawnConfig.Team)
end

function TeamSpawnSystem:CountActiveVehicles(vehicleType, team)
    local count = 0
    for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
        if vehicle.Name == vehicleType and vehicle:GetAttribute("Team") == team then
            count = count + 1
        end
    end
    return count
end
```

### Admin Spawn Commands

```lua
-- Spawn vehicle at admin's position
function AdminCommands:SpawnVehicle(admin, vehicleType)
    local vehicleConfig = VehicleConfig:GetVehicle(vehicleType)
    if not vehicleConfig then
        warn("Invalid vehicle type:", vehicleType)
        return
    end

    local character = admin.Character
    if not character or not character.PrimaryPart then return end

    local spawnPosition = character.PrimaryPart.Position + character.PrimaryPart.CFrame.LookVector * 20

    -- Spawn vehicle
    local vehicleModel = ReplicatedStorage:FindFirstChild(vehicleConfig.ModelPath, true)
    local vehicle = vehicleModel:Clone()
    vehicle:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
    vehicle.Parent = workspace.Vehicles

    VehicleSystem:InitializeVehicle(vehicle, vehicleConfig, "All")

    print("Admin spawned vehicle:", vehicleType)
end

-- Clear all vehicles
function AdminCommands:ClearVehicles(admin)
    for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
        vehicle:Destroy()
    end

    RemoteEvents.ClearVehicles:FireAllClients()
    print("Admin cleared all vehicles")
end

-- Destroy specific vehicle
function AdminCommands:DestroyVehicle(admin, vehicle)
    if not vehicle or not vehicle:IsA("Model") then return end

    DestructionPhysics:DestroyVehicle(vehicle, admin)
    print("Admin destroyed vehicle:", vehicle.Name)
end
```

**Command usage**:
```
/spawnvehicle M1Abrams
/clearvehicles
/destroyvehicle [click vehicle]
```

---

## AA Gun System

### AA Gun Types

**Anti-Aircraft guns** are stationary or mountable weapons designed to damage air vehicles.

### AA Gun Configuration

```lua
-- In VehicleConfig
Vehicles = {
    ZU23_AAGun = {
        Name = "ZU23_AAGun",
        DisplayName = "ZU-23-2 Anti-Aircraft Gun",
        Description = "Twin-barrel 23mm AA gun",
        Type = "AAGun",
        Team = "All",

        ModelPath = "ReplicatedStorage.FPSSystem.Vehicles.ZU23_AAGun",

        MaxHealth = 500,
        ArmorType = "None",
        RequiresArmorPiercing = false,

        -- AA guns don't move
        Stationary = true,
        CanBePlaced = true, -- Can be placed on buildings
        PlacementRules = {
            RequiresSurface = true,
            MinHeight = 5, -- Studs above ground
            MaxSlope = 30, -- Degrees
        },

        Seats = {
            Gunner = {
                SeatName = "GunnerSeat",
                CanControlMovement = false,
                CanControlWeapons = true,
                CameraMode = "FirstPerson",
                WeaponType = "TwinCannon",
                ExitPosition = Vector3.new(0, 0, 5),
            },
        },

        Weapons = {
            TwinCannon = {
                Name = "23mm Twin Cannon",
                Type = "Hitscan",
                Damage = 80,
                FireRate = 15, -- Very high fire rate
                MagazineSize = 200,
                ReserveAmmo = 1000,
                Spread = 1,
                TrackingSpeed = 45, -- Degrees/second (can track fast targets)
                ElevationRange = {-10, 85}, -- Min/max degrees
                DamageMultiplierAir = 3.0, -- Triple damage to aircraft
                FireSound = "rbxassetid://aa_gun_sound",
                MuzzleFlashAttachment = "LeftBarrel",
                MuzzleFlashAttachment2 = "RightBarrel", -- Twin barrels
            },
        },

        DestructionConfig = {
            ExplodeOnDestroy = true,
            ExplosionSize = 10,
            ExplosionDamage = 50,
            DebrisLifetime = 30,
            DestroyEffect = "SmallExplosion",
            SpawnDebris = false,
        },

        SpawnCooldown = 60,
        MaxActiveVehicles = 3,
    },
}
```

### Mounting AA Guns

**Placement system** allows players to deploy AA guns:

```lua
-- Client-side placement
function AAGunSystem:StartPlacement(player, aaGunType)
    local placementMode = true
    local ghostModel = self:CreateGhostModel(aaGunType)

    RunService.RenderStepped:Connect(function()
        if not placementMode then return end

        -- Raycast from mouse to find placement surface
        local mouse = player:GetMouse()
        local ray = workspace:Raycast(mouse.Hit.Position, Vector3.new(0, -100, 0))

        if ray and self:IsValidPlacement(ray) then
            ghostModel:SetPrimaryPartCFrame(CFrame.new(ray.Position))
            ghostModel.PrimaryPart.Color = Color3.fromRGB(0, 255, 0) -- Valid
        else
            ghostModel.PrimaryPart.Color = Color3.fromRGB(255, 0, 0) -- Invalid
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self:IsValidPlacement(ray) then
                -- Place AA gun
                RemoteEvents.PlaceAAGun:FireServer(aaGunType, ray.Position, ray.Normal)
                placementMode = false
                ghostModel:Destroy()
            end
        end
    end)
end

-- Server-side placement
RemoteEvents.PlaceAAGun.OnServerEvent:Connect(function(player, aaGunType, position, normal)
    local aaGunConfig = VehicleConfig:GetVehicle(aaGunType)
    if not aaGunConfig or not aaGunConfig.CanBePlaced then return end

    -- Validate placement
    if not AAGunSystem:IsValidPlacement(position, normal, aaGunConfig) then
        warn("Invalid AA gun placement")
        return
    end

    -- Spawn AA gun
    local aaGun = ReplicatedStorage:FindFirstChild(aaGunConfig.ModelPath, true):Clone()
    aaGun:SetPrimaryPartCFrame(CFrame.new(position, position + normal))
    aaGun.Parent = workspace.Vehicles

    VehicleSystem:InitializeVehicle(aaGun, aaGunConfig, player.Team.Name)

    print("Placed AA gun:", aaGunType, "by", player.Name)
end)
```

### AA Gun Targeting

**AA guns are highly effective against aircraft**:

```lua
-- In AA gun weapon script
function AAGunWeapon:Fire(gunner, target)
    local weaponConfig = self.Config.Weapons.TwinCannon

    -- Check if target is aircraft
    local damageMultiplier = 1.0
    if target and target:FindFirstChild("Type") and target.Type.Value == "Helicopter" then
        damageMultiplier = weaponConfig.DamageMultiplierAir or 1.0
    end

    local damage = weaponConfig.Damage * damageMultiplier

    -- Fire weapon
    self:FireHitscan(weaponConfig, damage, gunner)
end
```

---

## Testing Vehicles

### Testing Checklist

#### Model & Physics
- [ ] Vehicle model loads correctly
- [ ] PrimaryPart is set
- [ ] All seats are present and functional
- [ ] VehicleSeat properties configured (MaxSpeed, Torque)
- [ ] Vehicle drives/flies smoothly
- [ ] No clipping through terrain
- [ ] Proper collision detection
- [ ] Vehicle respects physics (gravity, friction)

#### Controls
- [ ] Driver can accelerate, brake, turn
- [ ] Gunner can aim and fire weapons
- [ ] Passengers can enter/exit
- [ ] Exit positions work correctly (no spawning in walls)
- [ ] Camera modes work (first/third person)
- [ ] Controls responsive and smooth
- [ ] Helicopter flight controls work properly

#### Weapons
- [ ] Weapons fire correctly
- [ ] Projectiles spawn at correct attachment points
- [ ] Hitscan weapons raycast properly
- [ ] Missiles track targets (if homing enabled)
- [ ] Weapon sounds play
- [ ] Muzzle flashes appear
- [ ] Reloading works
- [ ] Ammo counts correctly
- [ ] Weapon damage applies to targets

#### Damage & Destruction
- [ ] Vehicle takes damage from weapons
- [ ] Armor types work (heavy armor reduces damage)
- [ ] Armor piercing requirement works
- [ ] Damage zones apply correct multipliers
- [ ] Vehicle health displays correctly
- [ ] Vehicle explodes on destruction
- [ ] Debris spawns correctly
- [ ] Occupants ejected/killed on destruction
- [ ] Ragdoll physics work

#### Spawning & Management
- [ ] Vehicle spawns at spawn points
- [ ] Respawn cooldown works
- [ ] Max active vehicles enforced
- [ ] Team restrictions work (FBI/KFC vehicles)
- [ ] Admin spawn commands work
- [ ] Admin clear vehicles works
- [ ] Vehicles persist across rounds

#### AA Guns (If Applicable)
- [ ] AA gun can be placed
- [ ] Placement validation works (flat surface, height requirements)
- [ ] AA gun stationary once placed
- [ ] Gunner can mount and fire
- [ ] Extra damage to aircraft applies
- [ ] Tracking speed appropriate
- [ ] Elevation limits work

#### Performance
- [ ] No significant FPS drop with vehicle
- [ ] Multiple vehicles perform well
- [ ] Vehicle model optimized (triangle count)
- [ ] No memory leaks when spawning/destroying
- [ ] Physics calculations efficient

### Test Commands

```lua
-- Spawn vehicle at player position
/spawnvehicle M1Abrams

-- Give armor piercing weapon
/give NTW20

-- Set vehicle health
/setvehiclehealth [vehicle] [health]

-- Teleport to vehicle spawner
/gotospawn vehicle

-- Force destroy vehicle
/destroyvehicle [vehicle]

-- Toggle vehicle debug info
/vehicledebug true
```

### Debug Output

Enable vehicle debug mode:

```lua
-- In VehicleSystem.lua
local DEBUG_MODE = true

function VehicleSystem:InitializeVehicle(vehicle, config, team)
    if DEBUG_MODE then
        print("[VehicleSystem] Initializing vehicle:", config.Name)
        print("  Team:", team)
        print("  Max Health:", config.MaxHealth)
        print("  Armor Type:", config.ArmorType)
        print("  Seats:", #config.Seats)
        print("  Weapons:", #config.Weapons)
    end

    -- ... initialization
end

function VehicleSystem:DamageVehicle(vehicle, damage, attacker, weapon)
    if DEBUG_MODE then
        print("[VehicleSystem] Vehicle damaged:", vehicle.Name)
        print("  Damage:", damage)
        print("  Attacker:", attacker)
        print("  Weapon:", weapon)
        print("  Health:", vehicle:GetAttribute("Health"))
    end

    -- ... damage logic
end
```

---

## Troubleshooting

### Common Issues

#### Vehicle Not Spawning

**Symptoms**: Vehicle doesn't appear at spawn point

**Possible Causes**:
1. ModelPath incorrect
2. Vehicle model not in ReplicatedStorage
3. Spawn point not configured correctly
4. Max active vehicles reached

**Solutions**:
1. Verify ModelPath in VehicleConfig
2. Check vehicle model is in correct location
3. Ensure spawn point has Config folder with correct values
4. Check current active vehicle count

#### Vehicle Doesn't Move

**Symptoms**: Vehicle spawns but doesn't respond to controls

**Possible Causes**:
1. VehicleSeat not configured
2. No driver in vehicle
3. Controls not connected
4. Vehicle anchored

**Solutions**:
1. Set VehicleSeat MaxSpeed, Torque properties
2. Ensure player is sitting in DriverSeat
3. Check VehicleController connects to vehicle
4. Unanchor vehicle parts

#### Weapons Not Firing

**Symptoms**: Gunner can't fire weapons

**Possible Causes**:
1. Weapon attachment points missing
2. Weapon config incorrect
3. Gunner seat not configured for weapons
4. Ammo depleted

**Solutions**:
1. Add weapon attachment points to vehicle model
2. Check weapon config in VehicleConfig
3. Set CanControlWeapons = true for gunner seat
4. Check ammo count

#### Vehicle Takes No Damage

**Symptoms**: Vehicle health doesn't decrease when shot

**Possible Causes**:
1. Weapon can't damage vehicles (CanDamageVehicles = false)
2. Armor piercing required but not present
3. DamageSystem not processing vehicle damage

**Solutions**:
1. Set CanDamageVehicles = true on weapon
2. Use AP ammo or anti-vehicle weapons
3. Check DamageSystem:DamageVehicle() is called

#### Vehicle Explodes Immediately

**Symptoms**: Vehicle explodes right after spawning

**Possible Causes**:
1. Health not initialized
2. Collision with spawn point
3. Vehicle falling through map

**Solutions**:
1. Set vehicle:SetAttribute("Health", MaxHealth) on spawn
2. Move spawn point away from obstacles
3. Ensure vehicle parts are not CanCollide = false

#### Helicopter Won't Fly

**Symptoms**: Helicopter falls to ground

**Possible Causes**:
1. BodyGyro/BodyVelocity not configured
2. LiftForce too low
3. Mass too high

**Solutions**:
1. Add BodyGyro and BodyVelocity to helicopter PrimaryPart
2. Increase LiftForce in config
3. Reduce part density or mass

---

## Vehicle Presets

### Light Tank

```lua
LightTank = {
    Name = "LightTank",
    DisplayName = "Light Tank",
    Type = "Tank",
    MaxHealth = 1200,
    ArmorType = "Medium",
    MaxSpeed = 60,
    Acceleration = 15,
    Weapons = {
        MainCannon = {
            Damage = 350,
            FireRate = 0.33, -- Faster than heavy tank
            MagazineSize = 1,
            ReloadTime = 3,
        },
    },
}
```

### Heavy Tank

```lua
HeavyTank = {
    Name = "HeavyTank",
    DisplayName = "Heavy Tank",
    Type = "Tank",
    MaxHealth = 2500,
    ArmorType = "Heavy",
    MaxSpeed = 35, -- Slower
    Acceleration = 5,
    Weapons = {
        MainCannon = {
            Damage = 600, -- Much higher damage
            FireRate = 0.15,
            MagazineSize = 1,
            ReloadTime = 7,
        },
    },
}
```

### Attack Helicopter

```lua
AttackHeli = {
    Name = "AttackHeli",
    DisplayName = "Attack Helicopter",
    Type = "Helicopter",
    MaxHealth = 800,
    ArmorType = "Light",
    MaxFlightSpeed = 85,
    Weapons = {
        Missiles = {
            Damage = 300,
            FireRate = 2,
            HomingEnabled = true,
        },
        ChainGun = {
            Damage = 50,
            FireRate = 12,
        },
    },
}
```

### Transport Helicopter

```lua
TransportHeli = {
    Name = "TransportHeli",
    DisplayName = "Transport Helicopter",
    Type = "Helicopter",
    MaxHealth = 600,
    ArmorType = "None",
    MaxFlightSpeed = 95, -- Faster than attack
    Seats = {
        Pilot = {},
        Passenger1 = {},
        Passenger2 = {},
        Passenger3 = {},
        Passenger4 = {}, -- 5 total seats
    },
    Weapons = {}, -- No weapons
}
```

### AA Gun

```lua
AAGun = {
    Name = "AAGun",
    DisplayName = "Anti-Aircraft Gun",
    Type = "AAGun",
    MaxHealth = 500,
    Stationary = true,
    CanBePlaced = true,
    Weapons = {
        AAGun = {
            Damage = 80,
            FireRate = 15,
            DamageMultiplierAir = 3.0,
            TrackingSpeed = 45,
        },
    },
}
```

---

## Summary

This guide covered the complete vehicle system:

1. **Vehicle Types**: Tanks, helicopters, transport vehicles, AA guns
2. **Configuration**: VehicleConfig structure and all available options
3. **Creating Vehicles**: Step-by-step model creation and configuration
4. **Controls**: Driver, gunner, and helicopter controls
5. **Damage System**: Armor types, AP requirements, damage zones
6. **Destruction**: Explosion, debris, ragdoll physics
7. **Spawning**: Spawn points, respawn cooldowns, admin commands
8. **AA Guns**: Placement system, mounting, anti-aircraft bonuses
9. **Testing**: Comprehensive checklist and debug tools
10. **Presets**: Ready-to-use vehicle configurations

**Next Steps**:
1. Review [WEAPON_SYSTEM_GUIDE.md](WEAPON_SYSTEM_GUIDE.md) for weapon system
2. Review [ATTACHMENT_SYSTEM_GUIDE.md](ATTACHMENT_SYSTEM_GUIDE.md) for attachments
3. Create your first vehicle following this guide
4. Test thoroughly using the testing checklist
5. Balance vehicles based on gameplay testing

**Need Help?**
- Check [Troubleshooting](#troubleshooting) section
- Review example vehicle configs in VehicleConfig.lua
- Enable debug mode for detailed output
- Test vehicles in isolated environment first

---

**Document Version:** 1.0
**Last Updated:** 2025-10-12
**Maintained By:** FPS System Team
