# Vehicle and Map Setup Guide
## KFCS Funny Randomizer - Advanced Combat Operations

This guide explains how to manually set up vehicle spawns and map configurations for the KFCS FPS system.

## Table of Contents
1. [Map Structure](#map-structure)
2. [Team Spawn Setup](#team-spawn-setup)
3. [Vehicle Spawn Configuration](#vehicle-spawn-configuration)
4. [Objective Placement](#objective-placement)
5. [Destruction Physics Setup](#destruction-physics-setup)
6. [Configuration Files](#configuration-files)

---

## Map Structure

### Required Folder Hierarchy
```
Workspace/
├── Map/
│   ├── Spawns/
│   │   ├── FBI/
│   │   │   ├── FBISpawn1 (Part)
│   │   │   ├── FBISpawn2 (Part)
│   │   │   └── ... (more FBI spawn points)
│   │   └── KFC/
│   │       ├── KFCSpawn1 (Part)
│   │       ├── KFCSpawn2 (Part)
│   │       └── ... (more KFC spawn points)
│   ├── Vehicles/
│   │   ├── TankSpawns/
│   │   │   ├── TankSpawn1 (Part)
│   │   │   └── TankSpawn2 (Part)
│   │   └── HelicopterSpawns/
│   │       ├── HeliSpawn1 (Part)
│   │       └── HeliSpawn2 (Part)
│   ├── Objectives/
│   │   ├── Hill/
│   │   │   └── HillZone (Part)
│   │   ├── Flags/
│   │   │   ├── FBI_Flag (Part)
│   │   │   └── KFC_Flag (Part)
│   │   ├── Flares/
│   │   │   ├── FlarePoint1 (Part)
│   │   │   ├── FlarePoint2 (Part)
│   │   │   └── FlarePoint3 (Part)
│   │   └── Hardpoints/
│   │       ├── Hardpoint1 (Part)
│   │       ├── Hardpoint2 (Part)
│   │       └── Hardpoint3 (Part)
│   └── Destructible/
│       ├── Buildings/
│       └── Objects/
```

---

## Team Spawn Setup

### Creating Team Spawn Points

1. **Create FBI Spawn Points:**
   - Navigate to `Workspace/Map/Spawns/FBI/`
   - Insert Part objects named `FBISpawn1`, `FBISpawn2`, etc.
   - Position them around the bunker area
   - Recommended minimum: 8-12 spawn points per team
   - Set Part properties:
     - Size: `Vector3(4, 1, 4)`
     - Material: `Enum.Material.Neon`
     - BrickColor: `Really blue`
     - CanCollide: `false`
     - Anchored: `true`
     - Transparency: `0.5`

2. **Create KFC Spawn Points:**
   - Navigate to `Workspace/Map/Spawns/KFC/`
   - Insert Part objects named `KFCSpawn1`, `KFCSpawn2`, etc.
   - Position them in and around the city near the KFC building
   - Same Part properties as FBI, but use:
     - BrickColor: `Really red`

### Spawn Point Configuration

Each spawn point should have a **StringValue** child named `SpawnConfig` with the following format:
```lua
-- Example SpawnConfig value:
{
  team = "FBI", -- or "KFC"
  priority = 1, -- 1 = high priority, 5 = low priority
  gamemode = "ALL", -- or specific gamemode like "TDM", "KOTH"
  safezone = true, -- whether this is a protected spawn
  facing = "North" -- preferred facing direction
}
```

---

## Vehicle Spawn Configuration

### Tank Spawns

1. **Create Tank Spawn Points:**
   - Navigate to `Workspace/Map/Vehicles/TankSpawns/`
   - Insert Part objects for each tank spawn location
   - Recommended: 2-4 tank spawns per map
   - Set Part properties:
     - Size: `Vector3(8, 1, 12)` (tank-sized)
     - Material: `Enum.Material.Concrete`
     - BrickColor: `Medium stone grey`
     - CanCollide: `false`
     - Anchored: `true`

2. **Tank Configuration:**
   Add a **ModuleScript** child named `TankConfig` to each spawn point:
   ```lua
   -- TankConfig ModuleScript
   return {
       vehicleType = "Tank",
       model = "M1Abrams", -- or other tank models
       spawnCooldown = 120, -- seconds before respawn
       maxConcurrent = 1, -- max tanks from this spawn
       teamRestriction = "NONE", -- "FBI", "KFC", or "NONE"
       requiredRank = 10, -- minimum rank to use
       fuel = 1000,
       ammo = 50,
       health = 2000
   }
   ```

### Helicopter Spawns

1. **Create Helicopter Spawn Points:**
   - Navigate to `Workspace/Map/Vehicles/HelicopterSpawns/`
   - Insert Part objects for helicopter landing pads
   - Position them on elevated areas or helipads
   - Set Part properties:
     - Size: `Vector3(10, 1, 10)` (helipad-sized)
     - Material: `Enum.Material.Metal`
     - BrickColor: `Dark stone grey`

2. **Helicopter Configuration:**
   Add **ModuleScript** child named `HeliConfig`:
   ```lua
   -- HeliConfig ModuleScript
   return {
       vehicleType = "Helicopter",
       model = "BlackHawk", -- or other helicopter models
       spawnCooldown = 180,
       maxConcurrent = 1,
       teamRestriction = "NONE",
       requiredRank = 15,
       fuel = 800,
       missiles = 8,
       health = 1500,
       maxPassengers = 6
   }
   ```

---

## Objective Placement

### King of the Hill (KOTH)

1. **Hill Zone Setup:**
   - Create a Part in `Workspace/Map/Objectives/Hill/` named `HillZone`
   - Size: `Vector3(20, 10, 20)` (adjust based on desired capture area)
   - Position: Central map location with strategic value
   - Properties:
     - Material: `Enum.Material.ForceField`
     - Transparency: `0.7`
     - CanCollide: `false`
     - BrickColor: `Bright yellow`

### Capture the Flag (CTF)

1. **Flag Base Setup:**
   - Create Parts for `FBI_Flag` and `KFC_Flag` in `Objectives/Flags/`
   - Position near each team's main base
   - Size: `Vector3(4, 8, 4)`
   - Add **StringValue** child named `FlagConfig`:
   ```lua
   team = "FBI" -- or "KFC"
   returnTime = 60 -- seconds to auto-return
   captureScore = 1 -- points for capture
   ```

### Flare Domination

1. **Flare Points Setup:**
   - Create 3-5 Parts named `FlarePoint1`, `FlarePoint2`, etc.
   - Distribute evenly across the map
   - Size: `Vector3(6, 6, 6)`
   - Material: `Enum.Material.Neon`
   - Add effects with **Attachment** and **ParticleEmitter**

### Hardpoints

1. **Hardpoint Zones:**
   - Create multiple hardpoint areas
   - Only one active at a time (handled by GameModeSystem)
   - Size: `Vector3(15, 8, 15)`
   - Add rotation timer configuration

---

## Destruction Physics Setup

### Destructible Buildings

1. **Building Structure:**
   - Create buildings using **UnionOperations** or **Model** groups
   - Add **IntValue** child named `HealthPoints` (HP)
   - Add **StringValue** child named `DestructionType`:
     - `"COLLAPSE"` - Building collapses in pieces
     - `"EXPLODE"` - Building explodes instantly
     - `"CRUMBLE"` - Building breaks into debris

2. **Destruction Configuration:**
   ```lua
   -- Add to each destructible building
   local destructionConfig = {
       maxHealth = 500,
       damageThreshold = 50, -- minimum damage to affect
       explosiveMultiplier = 2.0, -- extra damage from explosives
       debrisCount = 15, -- pieces when destroyed
       debrisLifetime = 30, -- seconds before cleanup
       smokeEffect = true,
       fireEffect = false,
       soundEffect = "rbxasset://sounds/impact_heavy.mp3"
   }
   ```

### Interactive Objects

1. **Barrels, Crates, Vehicles:**
   - Add similar destruction configs
   - Lower health values
   - Different destruction effects
   - Some may contain pickups

---

## Configuration Files

### Map Configuration

Create a **ModuleScript** in `Workspace/Map/` named `MapConfig`:

```lua
-- MapConfig.lua
local MapConfig = {
    mapName = "Dust_City",
    version = "1.0",
    supportedGamemodes = {
        "TDM", "KOTH", "KC", "CTF", "FD", "HD"
    },
    
    -- Map boundaries
    boundaries = {
        min = Vector3(-500, 0, -500),
        max = Vector3(500, 200, 500)
    },
    
    -- Weather and lighting
    environment = {
        timeOfDay = "12:00:00",
        weatherType = "Clear", -- "Clear", "Rainy", "Foggy"
        ambientColor = Color3.fromRGB(70, 70, 70),
        shadowSoftness = 0.5
    },
    
    -- Gameplay settings
    gameplay = {
        fallDamageEnabled = true,
        destructionEnabled = true,
        vehiclesEnabled = true,
        maxPlayers = 32,
        recommendedPlayers = 16
    },
    
    -- Spawn settings
    spawns = {
        FBI = {
            count = 12,
            area = "Bunker Complex"
        },
        KFC = {
            count = 12,
            area = "City Center"
        }
    }
}

return MapConfig
```

### Vehicle System Configuration

Create `Workspace/Map/VehicleSystemConfig`:

```lua
-- VehicleSystemConfig.lua
local VehicleSystemConfig = {
    enabled = true,
    maxVehicles = 6,
    spawnDelay = 30, -- seconds after map load
    
    tankSettings = {
        enabled = true,
        maxConcurrent = 2,
        spawnCooldown = 120,
        fuelConsumption = 1, -- per second
        ammoRegeneration = false
    },
    
    helicopterSettings = {
        enabled = true,
        maxConcurrent = 2,
        spawnCooldown = 180,
        fuelConsumption = 2,
        autoHover = true
    },
    
    damageSettings = {
        collisionDamage = true,
        explosiveDamage = true,
        smallArmsDamage = false -- rifles/pistols don't damage vehicles
    }
}

return VehicleSystemConfig
```

---

## Implementation Steps

1. **Create Map Structure:**
   - Set up all required folders in Workspace/Map/
   - Follow the exact hierarchy shown above

2. **Place Spawn Points:**
   - Add FBI spawns around bunker area
   - Add KFC spawns around city center
   - Test spawn distribution for balance

3. **Configure Vehicles:**
   - Place vehicle spawn points
   - Add configuration ModuleScripts
   - Test vehicle spawning system

4. **Set Up Objectives:**
   - Place objective markers for each gamemode
   - Configure capture zones and timers
   - Test objective functionality

5. **Enable Destruction:**
   - Mark destructible buildings
   - Configure destruction physics
   - Test explosive interactions

6. **Final Testing:**
   - Test all gamemodes on the map
   - Verify spawn balance
   - Check vehicle accessibility
   - Validate objective placement

---

## Notes

- All spawn points should be tested for line-of-sight issues
- Vehicle spawns should be accessible but not overpowered
- Objective placement should encourage map movement
- Destruction should be balanced (not too easy/hard)
- Keep performance in mind with destruction debris
- Test with full player count for spawn conflicts

## Support

For questions or issues with map setup:
1. Check console for error messages
2. Verify folder structure matches exactly
3. Ensure all Parts are properly named
4. Test configurations with smaller player counts first

---

*This guide covers the essential setup for KFCS Funny Randomizer maps. Adjust configurations based on your specific map design and gameplay requirements.*