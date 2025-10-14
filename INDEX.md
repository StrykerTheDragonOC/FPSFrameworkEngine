# FPS System Documentation Index

**Version:** 1.0
**Last Updated:** 2025-10-12
**Project:** KFC vs FBI FPS Game

---

## Welcome

Welcome to the **FPS System Documentation**! This comprehensive guide covers all aspects of the weapon, attachment, and vehicle systems for the KFC vs FBI FPS game.

### Documentation Overview

This documentation is organized into the following guides:

1. **[Weapon System Guide](WEAPON_SYSTEM_GUIDE.md)** - Complete weapon creation and implementation
2. **[Attachment System Guide](ATTACHMENT_SYSTEM_GUIDE.md)** - Weapon customization and modifications
3. **[Vehicle System Guide](VEHICLE_SYSTEM_GUIDE.md)** - Tanks, helicopters, and AA guns
4. **[Example Weapons](EXAMPLE_WEAPONS.md)** - Ready-to-use weapon implementations
5. **[Scope System Guide](SCOPE_SYSTEM_GUIDE.md)** - Advanced scope implementation (if available)
6. **[Project Instructions](CLAUDE.md)** - Core gameplay rules and requirements

---

## Quick Start

### For New Developers

If you're new to this system, follow this path:

1. **Read [CLAUDE.md](CLAUDE.md)** - Understand the project vision and core mechanics
2. **Study [WEAPON_SYSTEM_GUIDE.md](WEAPON_SYSTEM_GUIDE.md)** - Learn the weapon system architecture
3. **Review [EXAMPLE_WEAPONS.md](EXAMPLE_WEAPONS.md)** - See working examples
4. **Try creating your first weapon** using the M4A1 template
5. **Add attachments** using [ATTACHMENT_SYSTEM_GUIDE.md](ATTACHMENT_SYSTEM_GUIDE.md)

### For Experienced Developers

Jump directly to:

- **[Weapon System Guide](WEAPON_SYSTEM_GUIDE.md)** for weapon creation
- **[Attachment System Guide](ATTACHMENT_SYSTEM_GUIDE.md)** for customization
- **[Vehicle System Guide](VEHICLE_SYSTEM_GUIDE.md)** for vehicles
- **[Example Weapons](EXAMPLE_WEAPONS.md)** for reference implementations

---

## Documentation Structure

### 1. Weapon System Guide

**File:** [WEAPON_SYSTEM_GUIDE.md](WEAPON_SYSTEM_GUIDE.md)

**Covers:**
- Weapon categories and types (Primary, Secondary, Melee, Grenade, Special)
- Complete weapon creation process
- WeaponConfig structure and all available stats
- Tool setup in Roblox Studio
- Viewmodel system with CameraPart
- Third-person weapon models
- Client script implementation
- Animation integration
- Testing checklist (40+ items)
- Troubleshooting common issues
- Weapon stat presets

**When to use:**
- Creating a new weapon from scratch
- Understanding weapon stats and how they work
- Debugging weapon issues
- Balancing weapon performance

**Key Sections:**
- [Weapon Categories](WEAPON_SYSTEM_GUIDE.md#weapon-categories)
- [Creating New Weapons](WEAPON_SYSTEM_GUIDE.md#creating-new-weapons)
- [WeaponConfig Structure](WEAPON_SYSTEM_GUIDE.md#weaponconfig-structure)
- [Client Script Template](WEAPON_SYSTEM_GUIDE.md#client-script-template)
- [Testing Checklist](WEAPON_SYSTEM_GUIDE.md#testing-weapons)

---

### 2. Attachment System Guide

**File:** [ATTACHMENT_SYSTEM_GUIDE.md](ATTACHMENT_SYSTEM_GUIDE.md)

**Covers:**
- Attachment categories (Sights, Barrels, Underbarrel, Other)
- Creating new attachments
- Stat modification system (multiplicative, additive, replacement)
- Compatibility rules (universal vs weapon-specific)
- 3D attachment models and positioning
- Unlock progression (kill requirements, pre-purchase)
- Special attachment types (scopes, suppressors, ammo conversions)
- Testing attachment effects

**When to use:**
- Adding attachments to existing weapons
- Creating universal attachments for multiple weapons
- Implementing special attachment types (scopes, lasers)
- Setting up unlock progression
- Balancing attachment effects

**Key Sections:**
- [Attachment Categories](ATTACHMENT_SYSTEM_GUIDE.md#attachment-categories)
- [Creating New Attachments](ATTACHMENT_SYSTEM_GUIDE.md#creating-new-attachments)
- [Stat Modification System](ATTACHMENT_SYSTEM_GUIDE.md#stat-modification-system)
- [3D Model Setup](ATTACHMENT_SYSTEM_GUIDE.md#3d-model-setup)
- [Special Attachment Types](ATTACHMENT_SYSTEM_GUIDE.md#special-attachment-types)

---

### 3. Vehicle System Guide

**File:** [VEHICLE_SYSTEM_GUIDE.md](VEHICLE_SYSTEM_GUIDE.md)

**Covers:**
- Vehicle types (Tanks, Helicopters, Transport, AA Guns)
- Complete vehicle configuration
- Creating new vehicles from scratch
- Vehicle controls (driver, gunner, passenger)
- Damage system with armor types
- Destruction physics and debris
- Vehicle spawning and management
- AA gun placement system
- Testing vehicles

**When to use:**
- Creating new vehicles (tanks, helicopters, etc.)
- Setting up vehicle spawn points
- Configuring vehicle weapons and armor
- Implementing destruction physics
- Creating mountable AA guns

**Key Sections:**
- [Vehicle Types](VEHICLE_SYSTEM_GUIDE.md#vehicle-types)
- [Vehicle Configuration](VEHICLE_SYSTEM_GUIDE.md#vehicle-configuration)
- [Creating New Vehicles](VEHICLE_SYSTEM_GUIDE.md#creating-new-vehicles)
- [Damage System](VEHICLE_SYSTEM_GUIDE.md#damage-system)
- [AA Gun System](VEHICLE_SYSTEM_GUIDE.md#aa-gun-system)

---

### 4. Example Weapons

**File:** [EXAMPLE_WEAPONS.md](EXAMPLE_WEAPONS.md)

**Covers:**
- 6 complete, working weapon examples
- Full WeaponConfig entries with all stats
- Complete client scripts for each weapon
- Customization notes
- Universal client script template
- Weapon balancing formulas

**Weapon Examples:**
1. **M4A1 Assault Rifle** - Standard full-auto AR
2. **Remington 700 Sniper Rifle** - Bolt-action sniper
3. **Glock 17 Pistol** - Semi-auto pistol
4. **Remington 870 Shotgun** - Pump-action shotgun
5. **RPG-7 Launcher** - Explosive rocket launcher
6. **MP5 SMG** - Fast-firing submachine gun

**When to use:**
- Starting a new weapon (copy and modify)
- Understanding complete weapon implementation
- Reference for specific weapon types
- Learning weapon balancing

**Key Sections:**
- [Example 1: M4A1](EXAMPLE_WEAPONS.md#example-1-m4a1-assault-rifle)
- [Universal Client Script Template](EXAMPLE_WEAPONS.md#universal-client-script-template)
- [Customization Guide](EXAMPLE_WEAPONS.md#customization-guide)

---

### 5. Scope System Guide

**File:** [SCOPE_SYSTEM_GUIDE.md](SCOPE_SYSTEM_GUIDE.md) *(if available)*

**Covers:**
- 3D scope implementation
- UI scope overlay system
- Scope sway and stabilization
- Toggle between 3D and UI modes
- Custom reticles

**When to use:**
- Creating custom scopes
- Implementing advanced scope features
- Troubleshooting scope rendering

---

### 6. Project Instructions

**File:** [CLAUDE.md](CLAUDE.md)

**Covers:**
- Core gameplay mechanics
- Universal rules and guidelines
- Weapon system requirements
- Progression system
- Gamemode specifications
- UI/UX requirements

**When to use:**
- Understanding project vision
- Checking gameplay requirements
- Verifying implementation matches specifications
- Reference for game balance decisions

---

## System Architecture

### Module Overview

```
ReplicatedStorage.FPSSystem
├── Modules
│   ├── WeaponConfig.lua           -- Weapon definitions
│   ├── VehicleConfig.lua          -- Vehicle definitions
│   ├── WeaponBase.lua             -- Base weapon class
│   ├── BallisticsSystem.lua       -- Bullet physics & spread
│   ├── DamageSystem.lua           -- Damage calculation
│   ├── RaycastSystem.lua          -- Hitscan & penetration
│   ├── ViewmodelSystem.lua        -- First-person weapon rendering
│   ├── AttachmentManager.lua      -- Attachment application
│   ├── VehicleSystem.lua          -- Vehicle logic
│   ├── DestructionPhysics.lua     -- Vehicle destruction
│   ├── AudioSystem.lua            -- Sound management
│   ├── AmmoSystem.lua             -- Ammo tracking
│   ├── GrenadeSystem.lua          -- Grenade physics
│   ├── MeleeSystem.lua            -- Melee combat
│   ├── DataStoreManager.lua       -- Save/load player data
│   ├── XPSystem.lua               -- Progression & leveling
│   ├── WeaponPoolManager.lua      -- Weapon unlocks
│   ├── GlobalStateManager.lua     -- Centralized state
│   └── ViciousStingerUI.lua       -- Custom weapon UI
│
├── Viewmodels                     -- First-person weapon models
│   ├── Primary
│   │   ├── AssaultRifles
│   │   ├── BattleRifles
│   │   ├── Carbines
│   │   ├── Shotguns
│   │   ├── DMRs
│   │   ├── LMGs
│   │   ├── SMGs
│   │   └── SniperRifles
│   └── Secondary
│       ├── Pistols
│       ├── AutoPistols
│       └── Revolvers
│
├── WeaponModels                   -- Third-person weapon models
├── Vehicles                       -- Vehicle models
├── Attachments                    -- Attachment 3D models
└── RemoteEvents                   -- Client-server communication
    ├── WeaponFired
    ├── WeaponReloaded
    ├── WeaponEquipped
    ├── WeaponUnequipped
    ├── VehicleAction
    ├── AttachmentDataUpdated
    └── ...
```

### Server Scripts

```
ServerScriptService
├── SystemsInitializer.server.lua  -- Initializes all systems
├── WeaponHandler.server.lua       -- Server weapon logic
├── AttachmentHandler.server.lua   -- Attachment validation
├── VehicleHandler.server.lua      -- Vehicle management
├── DamageHandler.server.lua       -- Damage processing
├── DataStoreHandler.server.lua    -- Data persistence
├── TeamSpawnSystem.server.lua     -- Spawn vehicles
├── GamemodeManager.server.lua     -- Gamemode logic
└── ...
```

### Client Scripts

```
StarterPlayer.StarterPlayerScripts
├── ClientSystemsInitializer.client.lua  -- Initialize client systems
├── VehicleController.client.lua         -- Vehicle controls
├── MovementSystem.client.lua            -- Player movement
├── InGameHUD.client.lua                 -- HUD elements
└── AttachmentController.client.lua      -- Attachment UI

StarterGUI
├── MenuController.client.lua            -- Main menu
├── HotbarController.client.lua          -- Weapon hotbar
└── TabScoreboard.client.lua             -- Scoreboard
```

---

## Common Tasks

### Adding a New Weapon

1. **Open [EXAMPLE_WEAPONS.md](EXAMPLE_WEAPONS.md)**
2. **Copy a similar weapon** (e.g., M4A1 for assault rifle)
3. **Modify in WeaponConfig.lua**:
   - Change `Name`, `DisplayName`, `Description`
   - Adjust stats (damage, fire rate, recoil, etc.)
   - Update paths to models and animations
4. **Create 3D models**:
   - Viewmodel in `ReplicatedStorage.FPSSystem.Viewmodels`
   - Weapon model in `ReplicatedStorage.FPSSystem.WeaponModels`
   - Tool in `ServerStorage.WeaponTools`
5. **Copy and modify client script**
6. **Test using [Testing Checklist](WEAPON_SYSTEM_GUIDE.md#testing-weapons)**

**Related Guides:**
- [Weapon System Guide](WEAPON_SYSTEM_GUIDE.md)
- [Example Weapons](EXAMPLE_WEAPONS.md)

---

### Adding Attachments to a Weapon

1. **Open [ATTACHMENT_SYSTEM_GUIDE.md](ATTACHMENT_SYSTEM_GUIDE.md)**
2. **In WeaponConfig.lua**, find your weapon
3. **Add to `Attachments` table**:
   ```lua
   Attachments = {
       Sight = {
           {Name = "RedDot", UnlockKills = 10, Cost = 300,
               Modifiers = {AimSpeed = 0.95, ZoomLevel = 1.0}},
       },
   }
   ```
4. **Create 3D attachment model** in `ReplicatedStorage.FPSSystem.Attachments`
5. **Add attachment point** to weapon model
6. **Test attachment effects**

**Related Guides:**
- [Attachment System Guide](ATTACHMENT_SYSTEM_GUIDE.md)
- [Attachment Categories](ATTACHMENT_SYSTEM_GUIDE.md#attachment-categories)

---

### Creating a Vehicle

1. **Open [VEHICLE_SYSTEM_GUIDE.md](VEHICLE_SYSTEM_GUIDE.md)**
2. **Design vehicle model** in Roblox Studio
   - Add VehicleSeat, weapon attachment points
   - Set up physics constraints
3. **Configure in VehicleConfig.lua**:
   - Define stats (health, speed, armor)
   - Configure seats and weapons
   - Set destruction behavior
4. **Create vehicle spawn points** on map
5. **Test vehicle thoroughly**

**Related Guides:**
- [Vehicle System Guide](VEHICLE_SYSTEM_GUIDE.md)
- [Creating New Vehicles](VEHICLE_SYSTEM_GUIDE.md#creating-new-vehicles)

---

### Balancing Weapons

1. **Calculate DPS**: `(Damage × FireRate) / 60`
2. **Calculate TTK**: `(100 / Damage) × (60 / FireRate)`
3. **Compare to existing weapons** in [EXAMPLE_WEAPONS.md](EXAMPLE_WEAPONS.md)
4. **Test in actual gameplay**
5. **Adjust stats** based on feedback

**Formula Reference:**
- **DPS (Damage Per Second)**: `(Damage × FireRate) / 60`
- **TTK (Time To Kill)**: `(TargetHP / Damage) × (60 / FireRate)`
- **Effective Range**: Distance where damage > 50% of max

**Related Guides:**
- [Weapon System Guide - Balancing](WEAPON_SYSTEM_GUIDE.md#weapon-stat-presets)
- [Example Weapons - Customization](EXAMPLE_WEAPONS.md#customization-guide)

---

## Troubleshooting

### Weapon Issues

| Issue | Solution | Guide |
|-------|----------|-------|
| Weapon not firing | Check client script, ammo count, IsEquipped | [Weapon Troubleshooting](WEAPON_SYSTEM_GUIDE.md#troubleshooting) |
| Viewmodel not showing | Verify ViewmodelPath, CameraPart exists | [Weapon System Guide](WEAPON_SYSTEM_GUIDE.md#viewmodel-setup) |
| Incorrect damage | Check DamageSystem, server validation | [Weapon System Guide](WEAPON_SYSTEM_GUIDE.md#damage-system) |
| Animations not playing | Verify Animation IDs, Animator exists | [Weapon System Guide](WEAPON_SYSTEM_GUIDE.md#animations) |

### Attachment Issues

| Issue | Solution | Guide |
|-------|----------|-------|
| Attachment not appearing | Check ModelPath, attachment point exists | [Attachment Troubleshooting](ATTACHMENT_SYSTEM_GUIDE.md#troubleshooting) |
| Stats not changing | Verify Modifiers table, check server logs | [Stat Modification System](ATTACHMENT_SYSTEM_GUIDE.md#stat-modification-system) |
| Can't unlock attachment | Check kill count, DataStoreManager | [Unlock Progression](ATTACHMENT_SYSTEM_GUIDE.md#unlock-progression) |
| Attachment clipping | Adjust attachment point position | [3D Model Setup](ATTACHMENT_SYSTEM_GUIDE.md#3d-model-setup) |

### Vehicle Issues

| Issue | Solution | Guide |
|-------|----------|-------|
| Vehicle not spawning | Check ModelPath, spawn point config | [Vehicle Troubleshooting](VEHICLE_SYSTEM_GUIDE.md#troubleshooting) |
| Vehicle doesn't move | Configure VehicleSeat properties, check controls | [Vehicle Controls](VEHICLE_SYSTEM_GUIDE.md#vehicle-controls) |
| Weapons not firing | Verify weapon attachment points, config | [Vehicle Weapons](VEHICLE_SYSTEM_GUIDE.md#vehicle-configuration) |
| Vehicle takes no damage | Check CanDamageVehicles on weapon | [Damage System](VEHICLE_SYSTEM_GUIDE.md#damage-system) |

---

## Best Practices

### Code Organization

1. **Use WeaponConfig for all stats** - Never hardcode weapon stats in scripts
2. **Centralize state management** - Use GlobalStateManager instead of _G
3. **Validate on server** - Always validate weapon actions server-side
4. **Modular design** - Keep systems separate and reusable
5. **Comment your code** - Explain complex logic and calculations

### Performance Optimization

1. **Optimize 3D models** - Keep polygon count low (<5000 for weapons)
2. **Use object pooling** - Reuse bullet tracers, effects
3. **Limit remote events** - Batch updates when possible
4. **Cache frequently used values** - Store references to commonly accessed objects
5. **Clean up effects** - Destroy particles, sounds after use

### Testing

1. **Test locally first** - Use Roblox Studio play mode
2. **Test with multiple players** - Check replication and sync
3. **Test edge cases** - Empty magazine, max spread, extreme ranges
4. **Use debug mode** - Enable debug prints in modules
5. **Check performance** - Monitor FPS, memory usage

### Documentation

1. **Update configs** - Keep WeaponConfig comments current
2. **Document special cases** - Note any unique weapon behaviors
3. **Record stat changes** - Log balance adjustments
4. **Share findings** - Document bugs and solutions
5. **Version control** - Use git commits with clear messages

---

## Reference Tables

### Weapon Categories

| Category | Subcategories | Examples | Guide |
|----------|--------------|----------|-------|
| Primary | AssaultRifles, BattleRifles, Carbines, Shotguns, DMRs, LMGs, SMGs, SniperRifles | M4A1, AK47, Remington 700 | [Weapon Guide](WEAPON_SYSTEM_GUIDE.md) |
| Secondary | Pistols, AutoPistols, Revolvers, Other | Glock 17, M9, Desert Eagle | [Weapon Guide](WEAPON_SYSTEM_GUIDE.md) |
| Melee | OneHandBlade, TwoHandBlade, OneHandBlunt, TwoHandBlunt | Knife, Machete, Baseball Bat | [Weapon Guide](WEAPON_SYSTEM_GUIDE.md) |
| Grenade | Frag, HighExplosive, Other | M67, Flashbang, C4 | [Weapon Guide](WEAPON_SYSTEM_GUIDE.md) |
| Special | N/A | ViciousStinger, Magic Weapons | [Weapon Guide](WEAPON_SYSTEM_GUIDE.md) |

### Attachment Categories

| Category | Types | Examples | Guide |
|----------|-------|----------|-------|
| Sight | IronSights, RedDots, Holographic, Scopes | ACOG, Reflex, EOTech | [Attachment Guide](ATTACHMENT_SYSTEM_GUIDE.md) |
| Barrel | Standard, Heavy, Short, Marksman, Choke | Heavy Barrel, Suppressor | [Attachment Guide](ATTACHMENT_SYSTEM_GUIDE.md) |
| Underbarrel | Grips, Bipods, Launchers | Vertical Grip, Angled Grip | [Attachment Guide](ATTACHMENT_SYSTEM_GUIDE.md) |
| Other | Suppressors, Lasers, Lights, Ammo, Mags | Tactical Suppressor, AP Rounds | [Attachment Guide](ATTACHMENT_SYSTEM_GUIDE.md) |

### Vehicle Types

| Type | Examples | Features | Guide |
|------|----------|----------|-------|
| Tank | M1 Abrams, T-90 | Heavy armor, main cannon, slow | [Vehicle Guide](VEHICLE_SYSTEM_GUIDE.md) |
| Helicopter | Apache, Black Hawk | Flight, missiles, fast | [Vehicle Guide](VEHICLE_SYSTEM_GUIDE.md) |
| Transport | Humvee, APC | Multiple seats, light armor | [Vehicle Guide](VEHICLE_SYSTEM_GUIDE.md) |
| AA Gun | ZU-23-2, Flak Cannon | Stationary, anti-air | [Vehicle Guide](VEHICLE_SYSTEM_GUIDE.md) |

---

## Stat Reference

### Fire Rate Conversion

| RPM | Seconds per Shot | Fire Rate Type |
|-----|-----------------|----------------|
| 60 | 1.000 | Very Slow (Bolt-action) |
| 120 | 0.500 | Slow (Shotgun) |
| 300 | 0.200 | Moderate (Semi-auto) |
| 600 | 0.100 | Fast (Assault Rifle) |
| 900 | 0.067 | Very Fast (SMG) |
| 1200 | 0.050 | Extreme (Minigun) |

**Formula**: `FireRateSeconds = 60 / FireRate`

### Damage Ranges

| Weapon Type | Damage | Headshot Multiplier | Typical Range |
|-------------|--------|-------------------|---------------|
| SMG | 20-25 | 2.0x | 50-200 studs |
| Assault Rifle | 28-35 | 2.0x | 100-400 studs |
| Battle Rifle | 38-45 | 2.0x | 150-500 studs |
| DMR | 45-60 | 2.5x | 200-600 studs |
| Sniper Rifle | 80-150 | 3.0x | 400-1500 studs |
| Pistol | 22-30 | 2.5x | 30-250 studs |
| Shotgun | 15-30 (per pellet) | 1.5x | 10-100 studs |

### Recoil Values

| Recoil Level | Vertical | Horizontal | Weapon Type |
|--------------|----------|-----------|-------------|
| Very Low | 0.5-1.0 | 0.3-0.5 | Pistol, SMG |
| Low | 1.0-1.5 | 0.5-1.0 | AR, BR |
| Moderate | 1.5-2.5 | 1.0-1.5 | LMG, DMR |
| High | 2.5-5.0 | 1.5-2.5 | Sniper |
| Very High | 5.0-15.0 | 2.0-5.0 | Shotgun, RPG |

---

## Version History

### Version 1.0 (2025-10-12)

**Initial Release**

**Created Documentation:**
- WEAPON_SYSTEM_GUIDE.md (500+ lines)
- ATTACHMENT_SYSTEM_GUIDE.md (450+ lines)
- VEHICLE_SYSTEM_GUIDE.md (500+ lines)
- EXAMPLE_WEAPONS.md (900+ lines)
- INDEX.md (this file)

**System Improvements:**
- Implemented GlobalStateManager for centralized state
- Integrated WeaponPoolManager with DataStoreManager
- Created ViciousStingerUI custom weapon UI
- Fixed BallisticsSystem player state tracking

**Modules Updated:**
- GlobalStateManager.lua (added player state tracking)
- BallisticsSystem.lua (integrated with GlobalStateManager)
- WeaponPoolManager.lua (DataStore integration)
- MovementSystem.client.lua (state reporting)
- ViewmodelSystem.lua (aiming state tracking)

---

## Contributing

### Adding New Documentation

When creating new guides:

1. **Follow the format** of existing guides
2. **Include Table of Contents**
3. **Add code examples** with syntax highlighting
4. **Create reference tables**
5. **Add troubleshooting section**
6. **Update this INDEX.md** with new guide

### Updating Existing Documentation

When making changes:

1. **Update version number** in guide header
2. **Add to Version History** section
3. **Update INDEX.md** if structure changes
4. **Keep examples up to date** with code changes
5. **Test all code examples** before committing

---

## Support & Resources

### Getting Help

1. **Check this INDEX** for relevant guide
2. **Search guide's Table of Contents** for specific topic
3. **Review troubleshooting sections**
4. **Check example implementations**
5. **Review CLAUDE.md** for project requirements

### External Resources

- **Roblox DevHub**: https://create.roblox.com/docs
- **Roblox API Reference**: https://create.roblox.com/docs/reference/engine
- **Phantom Forces** (reference game for mechanics)
- **Battlefield 2042** (reference for vehicles and destruction)

---

## Quick Reference

### File Locations

```
Project Root
├── CLAUDE.md                      # Project instructions
├── INDEX.md                       # This file
├── WEAPON_SYSTEM_GUIDE.md         # Weapon documentation
├── ATTACHMENT_SYSTEM_GUIDE.md     # Attachment documentation
├── VEHICLE_SYSTEM_GUIDE.md        # Vehicle documentation
├── EXAMPLE_WEAPONS.md             # Working examples
├── SCOPE_SYSTEM_GUIDE.md          # Scope system (if available)
│
├── src/
│   ├── ReplicatedStorage/
│   │   └── FPSSystem/
│   │       ├── Modules/           # Core system modules
│   │       ├── Viewmodels/        # First-person models
│   │       ├── WeaponModels/      # Third-person models
│   │       ├── Vehicles/          # Vehicle models
│   │       └── RemoteEvents/      # Network communication
│   │
│   ├── ServerScriptService/       # Server-side logic
│   ├── ServerStorage/
│   │   └── WeaponTools/           # Weapon tool instances
│   │
│   └── StarterPlayer/
│       └── StarterPlayerScripts/  # Client-side logic
│
└── StarterGUI/                    # UI elements
```

### Essential Modules

| Module | Purpose | Location |
|--------|---------|----------|
| WeaponConfig | Weapon definitions | ReplicatedStorage.FPSSystem.Modules |
| VehicleConfig | Vehicle definitions | ReplicatedStorage.FPSSystem.Modules |
| BallisticsSystem | Bullet physics | ReplicatedStorage.FPSSystem.Modules |
| ViewmodelSystem | First-person rendering | ReplicatedStorage.FPSSystem.Modules |
| DamageSystem | Damage calculation | ReplicatedStorage.FPSSystem.Modules |
| AttachmentManager | Attachment handling | ReplicatedStorage.FPSSystem.Modules |
| GlobalStateManager | Centralized state | ReplicatedStorage.FPSSystem.Modules |
| DataStoreManager | Data persistence | ReplicatedStorage.FPSSystem.Modules |

### Quick Links

- **[Create a Weapon](WEAPON_SYSTEM_GUIDE.md#creating-new-weapons)**
- **[Add Attachments](ATTACHMENT_SYSTEM_GUIDE.md#creating-new-attachments)**
- **[Create a Vehicle](VEHICLE_SYSTEM_GUIDE.md#creating-new-vehicles)**
- **[Copy Example Weapon](EXAMPLE_WEAPONS.md#universal-client-script-template)**
- **[Balance Weapons](EXAMPLE_WEAPONS.md#customization-guide)**
- **[Troubleshoot Issues](#troubleshooting)**

---

## Contact & Feedback

For questions, issues, or suggestions about this documentation:

1. Check the **[Troubleshooting](#troubleshooting)** section
2. Review the relevant guide's troubleshooting section
3. Search for similar issues in project history
4. Document your findings and solutions

---

**Happy Developing!**

This documentation is maintained by the FPS System Team.
Last updated: 2025-10-12
Version: 1.0

---

**Navigation:**
- [Top](#fps-system-documentation-index)
- [Quick Start](#quick-start)
- [Documentation Structure](#documentation-structure)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Reference Tables](#reference-tables)
