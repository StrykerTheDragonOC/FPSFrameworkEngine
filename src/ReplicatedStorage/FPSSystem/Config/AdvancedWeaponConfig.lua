-- AdvancedWeaponConfig.lua
-- Phantom Forces-style weapon configuration system with advanced stats
-- Includes damage graphs, detailed recoil patterns, and comprehensive weapon data

local AdvancedWeaponConfig = {}

-- Import required modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Advanced configuration constants
AdvancedWeaponConfig.WeaponTypes = {
    -- Primary weapon types
    AR = "AssaultRifle",      -- Assault Rifles
    BR = "BattleRifle",       -- Battle Rifles  
    SMG = "SubmachineGun",    -- Submachine Guns
    LMG = "LightMachineGun",  -- Light Machine Guns
    SR = "SniperRifle",       -- Sniper Rifles
    DMR = "DMR",              -- Designated Marksman Rifles
    SG = "Shotgun",           -- Shotguns
    CB = "Carbine",           -- Carbines
    
    -- Secondary weapon types
    P = "Pistol",             -- Pistols
    REV = "Revolver",         -- Revolvers
    AP = "AutoPistol",        -- Automatic Pistols
    
    -- Other weapon types
    KNIFE = "Knife",          -- Melee weapons
    GREN = "Grenade"          -- Grenades
}

AdvancedWeaponConfig.FiringModes = {
    AUTO = 1,     -- Full automatic
    SEMI = 2,     -- Semi-automatic
    BURST_3 = 3,  -- 3-round burst
    BURST_4 = 4,  -- 4-round burst
    BOLT = 5      -- Bolt-action
}

AdvancedWeaponConfig.RecoilPatterns = {
    RISING = "rising",           -- Vertical climb pattern
    RANDOM = "random",           -- Random spread
    DIAGONAL_LEFT = "diag_left", -- Diagonal left pattern
    DIAGONAL_RIGHT = "diag_right", -- Diagonal right pattern
    T_PATTERN = "t_pattern",     -- T-shaped pattern
    CAMERA_KICK = "camera_kick"  -- Camera-based recoil
}

-- Helper functions for CFrame and angle calculations
local function cf(x, y, z)
    return CFrame.new(x, y, z)
end

local function angles(x, y, z)
    return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local function v3(x, y, z)
    return Vector3.new(x, y, z)
end

-- Advanced weapon configurations
AdvancedWeaponConfig.Weapons = {
    -- Example DMR weapon based on your Phantom Forces config
    ["NTW-20X110"] = {
        -- Basic weapon info
        name = "NTW-20X110",
        displayName = "NTW-20 Anti-Material Rifle",
        description = "South African anti-material rifle chambered in 20x110mm with devastating power",
        type = AdvancedWeaponConfig.WeaponTypes.SR,
        
        -- Suppression factor (affects enemy screen shake/audio)
        suppression = 2.5,
        
        -- Shell ejection offset and angles
        shellOffset = cf(0.3, 0, -0.8) * angles(0, 0, 0),
        
        -- Audio configuration
        fireSoundId = "rbxassetid://17787141667",
        firePitch = 0.8,
        fireVolume = 1.0,
        
        -- Magazine and ammo system
        magSize = 3,
        spareRounds = 15,
        chamber = 1, -- Additional round in chamber
        
        -- Fire rate and modes
        fireRate = 480, -- RPM (rounds per minute)
        fireModes = {AdvancedWeaponConfig.FiringModes.BOLT}, -- Bolt-action only
        
        -- Crosshair configuration
        crossSize = 25,
        crossExpansion = 500,
        crossSpeed = 8,
        crossDamper = 0.85,
        
        -- Hipfire spread and stability
        hipFireSpread = 0.12,
        hipFireStability = 0.6,
        hipFireSpreadRecover = 6,
        
        -- Damage graph system (similar to PF)
        damageGraph = {
            {distance = 0, damage = 150},
            {distance = 200, damage = 150},
            {distance = 400, damage = 140},
            {distance = 800, damage = 125},
            {distance = 1200, damage = 110},
            {distance = 1500, damage = 100}
        },
        
        -- Damage multipliers for body parts
        multHead = 2.5,     -- Headshot multiplier
        multTorso = 1.0,    -- Torso multiplier
        multLimb = 0.95,    -- Limb multiplier
        
        -- Ballistics
        bulletSpeed = 3200,           -- Muzzle velocity (studs/second)
        penetrationDepth = 5.0,       -- Wall penetration power
        suppressorCompatible = true,   -- Can use suppressor
        
        -- Movement and handling
        aimWalkSpeedMult = 0.45,      -- Walk speed multiplier when aiming
        walkSpeed = 8,                -- Base walk speed
        sprintSpeed = 10,             -- Sprint speed
        zoom = 12.0,                  -- Default scope zoom level
        
        -- Advanced sway system
        walkSwayAmpHipMult = 1.2,     -- Hip sway when walking
        walkSwayAmpAimMult = 0.3,     -- Aim sway when walking  
        walkSwayRotHipMult = 1.0,     -- Rotational sway hip
        walkSwayRotAimMult = 0.2,     -- Rotational sway aim
        
        -- Idle sway
        idleSwayyCycleSpeed = 4,      -- Idle sway cycle speed
        idleSwayAmpHipMult = 3.0,     -- Idle sway amplitude hip
        idleSwayAmpAimMult = 0.4,     -- Idle sway amplitude aim
        
        -- Advanced sway parameters (physics-based)
        simpleSwayParameters = {
            posDamping = v3(0.65, 0.55, 0.65),
            posSpeed = v3(8, 15, 8),
            angDamping = v3(0.75, 0.75, 0.75),
            angSpeed = v3(5, 5, 5),
            
            posImpToPosImpMult = 1.2,
            posImpToAngImpMult = 1.1,
            angImpToPosImpMult = 0.9,
            angImpToAngImpMult = 1.0,
            
            posVelToPosTargMult = 1.0,
            posVelToAngTargMult = 0.8,
            angVelToAngTargMult = 1.0
        },
        
        -- Viewmodel positioning (CFrame offsets)
        mainOffset = cf(0.8, -1.2, -1.5) * angles(0, 0, 0),
        aimOffset = cf(-0.8, 0.15, 0.05) * angles(0, 0, 0),
        sprintOffset = cf(-0.9, -0.3, 0.2) * angles(-25, 50, 65),
        equipOffset = cf(0.3, -1.0, 0.5) * angles(-45, 55, 40),
        proneOffset = cf(0.1, 0.05, 0.15) * angles(0, 0, 0),
        
        -- Left arm positioning  
        larmOffset = cf(-0.6, -0.25, -0.8) * angles(130, -30, 25),
        larmAimOffset = cf(-0.6, -0.25, -0.8) * angles(130, -30, 25),
        larmSprintOffset = cf(-0.6, -0.25, -0.8) * angles(130, -30, 25),
        larmEquip = cf(-0.25, -0.35, 0.45) * angles(95, 0, 15),
        
        -- Right arm positioning
        rarmOffset = cf(0.2, -0.3, 1.0) * angles(100, 0, -8),
        rarmAimOffset = cf(0.35, -0.35, 0.65) * angles(108, 0, -20),
        rarmSprintOffset = cf(-0.1, -0.2, 0.9) * angles(100, -2, 6),
        rarmEquip = cf(0.15, -0.35, 0.85) * angles(95, 0, 0),
        
        -- Bolt action parameters
        boltOffset = cf(0, 0, 0) * angles(0, 0, 0),
        boltTime = 1.2, -- Time for bolt action cycle
        
        -- Animation speeds
        aimSpeed = 8,           -- Speed to aim down sights
        unAimSpeed = 12,        -- Speed to stop aiming
        sprintAnimSpeed = 6,    -- Animation speed to start sprinting
        unSprintSpeed = 10,     -- Speed to stop sprinting
        magnifySpeed = 15,      -- Scope zoom in speed
        unMagnifySpeed = 18,    -- Scope zoom out speed
        equipSpeed = 5,         -- Weapon equip speed
        
        -- Ammunition type
        ammoType = "20x110mm HE", -- High explosive rounds
        
        -- Recoil system (advanced)
        recoilPattern = AdvancedWeaponConfig.RecoilPatterns.CAMERA_KICK,
        verticalRecoil = 25.0,    -- Extreme vertical recoil
        horizontalRecoil = 8.0,   -- Significant horizontal recoil
        recoilAngle = 90,         -- Recoil angle (degrees)
        dampening = 0.3,          -- Recoil dampening factor
        rotationRecoil = 15.0,    -- Camera rotation recoil
        
        -- Advanced spread system
        spreadRecoveryRate = 0.85,    -- How fast spread recovers
        maxSpread = 5.0,              -- Maximum spread value
        spreadPerShot = 0.0,          -- Added spread per shot (bolt action = 0)
        movementSpreadMult = 4.0,     -- Movement spread multiplier
        crouchSpreadMult = 0.6,       -- Crouch spread reduction
        proneSpreadMult = 0.3,        -- Prone spread reduction
        
        -- Special features
        specialFeatures = {
            antiMaterial = true,          -- Can destroy light vehicles
            wallPenetration = true,       -- Penetrates multiple walls
            oneHitHeadshot = true,        -- Always one-hit headshot
            explosiveRounds = true,       -- Rounds explode on impact
            shockwaveEffect = true,       -- Creates shockwave on firing
            muzzleBrake = true,          -- Has built-in muzzle brake
            bipodCompatible = true        -- Can mount bipod
        },
        
        -- Attachment compatibility
        attachmentSlots = {
            optic = true,
            barrel = true,
            underbarrel = true,
            other = true,
            ammo = false -- Uses specialized ammo
        },
        
        -- Performance stats (for UI display)
        stats = {
            damage = 50,      -- Out of 50
            range = 50,       -- Out of 50  
            accuracy = 48,    -- Out of 50
            mobility = 8,     -- Out of 50
            fireRate = 5,     -- Out of 50
            penetration = 50, -- Out of 50
            recoil = 5        -- Out of 50 (lower = more recoil)
        }
    },
    
    -- G36 Assault Rifle (Enhanced)
    ["G36"] = {
        name = "G36",
        displayName = "G36 Assault Rifle",
        description = "German assault rifle with integrated carry handle and scope rail",
        type = AdvancedWeaponConfig.WeaponTypes.AR,
        
        suppression = 1.2,
        shellOffset = cf(0.15, 0, -0.4) * angles(0, 0, 0),
        
        fireSoundId = "rbxassetid://6043286676",
        firePitch = 1.0,
        fireVolume = 0.8,
        
        magSize = 30,
        spareRounds = 120,
        chamber = 1,
        
        fireRate = 750,
        fireModes = {AdvancedWeaponConfig.FiringModes.AUTO, AdvancedWeaponConfig.FiringModes.SEMI},
        
        crossSize = 30,
        crossExpansion = 400,
        crossSpeed = 12,
        crossDamper = 0.92,
        
        hipFireSpread = 0.045,
        hipFireStability = 0.85,
        hipFireSpreadRecover = 10,
        
        damageGraph = {
            {distance = 0, damage = 28},
            {distance = 60, damage = 28},
            {distance = 120, damage = 25},
            {distance = 200, damage = 22},
            {distance = 300, damage = 19}
        },
        
        multHead = 1.5,
        multTorso = 1.0,
        multLimb = 0.9,
        
        bulletSpeed = 2400,
        penetrationDepth = 1.8,
        suppressorCompatible = true,
        
        aimWalkSpeedMult = 0.75,
        walkSpeed = 14,
        sprintSpeed = 20,
        zoom = 1.8,
        
        walkSwayAmpHipMult = 0.7,
        walkSwayAmpAimMult = 0.4,
        walkSwayRotHipMult = 0.7,
        walkSwayRotAimMult = 0.25,
        
        idleSwayyCycleSpeed = 7,
        idleSwayAmpHipMult = 1.5,
        idleSwayAmpAimMult = 0.5,
        
        simpleSwayParameters = {
            posDamping = v3(0.8, 0.7, 0.8),
            posSpeed = v3(12, 25, 12),
            angDamping = v3(0.9, 0.9, 0.9),
            angSpeed = v3(8, 8, 8),
            
            posImpToPosImpMult = 1.0,
            posImpToAngImpMult = 1.0,
            angImpToPosImpMult = 1.0,
            angImpToAngImpMult = 1.0,
            
            posVelToPosTargMult = 1.0,
            posVelToAngTargMult = 1.0,
            angVelToAngTargMult = 1.0
        },
        
        mainOffset = cf(0.6, -0.9, -1.1) * angles(0, 0, 0),
        aimOffset = cf(-0.6, 0.18, 0.08) * angles(0, 0, 0),
        sprintOffset = cf(-0.7, -0.2, 0.08) * angles(-20, 40, 55),
        equipOffset = cf(0.15, -0.8, 0.3) * angles(-38, 48, 32),
        proneOffset = cf(0.03, 0.08, 0.08) * angles(0, 0, 0),
        
        larmOffset = cf(-0.45, -0.18, -0.6) * angles(120, -20, 18),
        larmAimOffset = cf(-0.45, -0.18, -0.6) * angles(120, -20, 18),
        larmSprintOffset = cf(-0.45, -0.18, -0.6) * angles(120, -20, 18),
        larmEquip = cf(-0.15, -0.25, 0.3) * angles(85, 0, 8),
        
        rarmOffset = cf(0.15, -0.2, 0.8) * angles(90, 0, -3),
        rarmAimOffset = cf(0.25, -0.25, 0.5) * angles(98, 0, -12),
        rarmSprintOffset = cf(-0.03, -0.12, 0.75) * angles(90, -0.5, 2),
        rarmEquip = cf(0.08, -0.25, 0.7) * angles(85, 0, 0),
        
        boltOffset = cf(0, 0, 0) * angles(0, 0, 0),
        boltTime = 0.0, -- No bolt action for automatic
        
        aimSpeed = 15,
        unAimSpeed = 10,
        sprintAnimSpeed = 9,
        unSprintSpeed = 16,
        magnifySpeed = 12,
        unMagnifySpeed = 15,
        equipSpeed = 12,
        
        ammoType = "5.56x45mm NATO",
        
        recoilPattern = AdvancedWeaponConfig.RecoilPatterns.RISING,
        verticalRecoil = 2.8,
        horizontalRecoil = 0.6,
        recoilAngle = 85,
        dampening = 0.85,
        rotationRecoil = 1.2,
        
        spreadRecoveryRate = 0.92,
        maxSpread = 3.5,
        spreadPerShot = 0.12,
        movementSpreadMult = 1.4,
        crouchSpreadMult = 0.7,
        proneSpreadMult = 0.5,
        
        specialFeatures = {
            burstFire = false,
            integratedOptic = false,
            quickReload = false,
            dualMag = false
        },
        
        attachmentSlots = {
            optic = true,
            barrel = true,
            underbarrel = true,
            other = true,
            ammo = true
        },
        
        stats = {
            damage = 32,
            range = 35,
            accuracy = 38,
            mobility = 42,
            fireRate = 45,
            penetration = 25,
            recoil = 35
        }
    }
}

-- Utility functions
function AdvancedWeaponConfig:getWeapon(weaponName)
    return self.Weapons[weaponName]
end

function AdvancedWeaponConfig:calculateDamageAtRange(weaponName, distance)
    local weapon = self:getWeapon(weaponName)
    if not weapon or not weapon.damageGraph then
        return 0
    end
    
    local damageGraph = weapon.damageGraph
    
    -- If distance is before first point, use first point damage
    if distance <= damageGraph[1].distance then
        return damageGraph[1].damage
    end
    
    -- If distance is after last point, use last point damage
    if distance >= damageGraph[#damageGraph].distance then
        return damageGraph[#damageGraph].damage
    end
    
    -- Interpolate between two points
    for i = 1, #damageGraph - 1 do
        local point1 = damageGraph[i]
        local point2 = damageGraph[i + 1]
        
        if distance >= point1.distance and distance <= point2.distance then
            local ratio = (distance - point1.distance) / (point2.distance - point1.distance)
            return point1.damage + (point2.damage - point1.damage) * ratio
        end
    end
    
    return 0
end

function AdvancedWeaponConfig:getDamageGraphPoints(weaponName)
    local weapon = self:getWeapon(weaponName)
    if not weapon or not weapon.damageGraph then
        return {}
    end
    
    return weapon.damageGraph
end

function AdvancedWeaponConfig:getWeaponStats(weaponName)
    local weapon = self:getWeapon(weaponName)
    if not weapon then
        return nil
    end
    
    return weapon.stats or {}
end

function AdvancedWeaponConfig:isAttachmentCompatible(weaponName, attachmentType)
    local weapon = self:getWeapon(weaponName)
    if not weapon or not weapon.attachmentSlots then
        return false
    end
    
    return weapon.attachmentSlots[attachmentType] == true
end

return AdvancedWeaponConfig