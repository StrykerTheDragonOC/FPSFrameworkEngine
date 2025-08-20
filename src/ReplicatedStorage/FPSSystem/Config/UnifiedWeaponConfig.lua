-- UnifiedWeaponConfig.lua
-- Consolidated weapon configuration system
-- This replaces WeaponConfigManager.lua and WeaponConfig.lua to eliminate duplication
-- Place in ReplicatedStorage/FPSSystem/Config/UnifiedWeaponConfig.lua

local UnifiedWeaponConfig = {}

-- Categories and constants
UnifiedWeaponConfig.Categories = {
    PRIMARY = "PRIMARY",
    SECONDARY = "SECONDARY", 
    MELEE = "MELEE",
    GRENADE = "GRENADE"
}

UnifiedWeaponConfig.Types = {
    -- Primary weapon types
    ASSAULT_RIFLE = "AssaultRifle",
    SNIPER_RIFLE = "SniperRifle",
    SMG = "SMG",
    LMG = "LMG",
    SHOTGUN = "Shotgun",
    CARBINE = "Carbine",
    DMR = "DMR",
    
    -- Secondary weapon types
    PISTOL = "Pistol",
    REVOLVER = "Revolver",
    MACHINE_PISTOL = "MachinePistol",
    
    -- Melee weapon types  
    KNIFE = "Knife",
    BLADE = "Blade",
    BLUNT = "Blunt",
    
    -- Grenade types
    FRAG = "Fragmentation",
    FLASH = "Flashbang",
    SMOKE = "Smoke",
    IMPACT = "Impact"
}

UnifiedWeaponConfig.FiringModes = {
    FULL_AUTO = "FULL_AUTO",
    SEMI_AUTO = "SEMI_AUTO", 
    BURST = "BURST",
    BOLT_ACTION = "BOLT_ACTION"
}

-- Unified sound library
UnifiedWeaponConfig.SoundLibrary = {
    -- Weapon firing sounds
    G36_FIRE = "rbxassetid://6043286676",
    M4A1_FIRE = "rbxassetid://6043286676",
    AWP_FIRE = "rbxassetid://4328614635",
    NTW20_FIRE = "rbxassetid://17787141667",
    M9_FIRE = "rbxassetid://799960407",
    
    -- Reload sounds
    RIFLE_RELOAD = "rbxassetid://18574927786",
    PISTOL_RELOAD = "rbxassetid://799960619",
    SNIPER_RELOAD = "rbxassetid://3666864180",
    
    -- Common weapon sounds
    EMPTY_CLICK = "rbxassetid://93840917543863",
    BOLT_ACTION = "rbxassetid://133693886808298",
    EQUIP_WEAPON = "rbxassetid://7405483764",
    
    -- Melee sounds
    KNIFE_SWING = "rbxassetid://7122602098",
    KNIFE_HIT = "rbxassetid://4681189562",
    KNIFE_BACKSTAB = "rbxassetid://8255306220",
    
    -- Grenade sounds
    GRENADE_THROW = "rbxassetid://0",
    GRENADE_BOUNCE = "rbxassetid://0",
    EXPLOSION = "rbxassetid://0",
    GRENADE_PIN = "rbxassetid://0"
}

-- Unified weapon configurations
UnifiedWeaponConfig.Weapons = {
    -- PRIMARY WEAPONS
    G36 = {
        name = "G36",
        displayName = "G36 Assault Rifle",
        description = "German assault rifle with integrated scope rail",
        category = UnifiedWeaponConfig.Categories.PRIMARY,
        type = UnifiedWeaponConfig.Types.ASSAULT_RIFLE,
        
        -- Damage system
        damage = {
            base = 25,
            ranges = {
                {distance = 0, damage = 25},
                {distance = 50, damage = 23},
                {distance = 100, damage = 20},
                {distance = 200, damage = 17}
            },
            headshotMultiplier = 1.5,
            torsoMultiplier = 1.0,
            limbMultiplier = 0.9
        },
        
        -- Fire rate and modes
        fireRate = 750, -- RPM
        firingMode = UnifiedWeaponConfig.FiringModes.FULL_AUTO,
        burstCount = 3,
        
        -- Recoil system
        recoil = {
            vertical = 1.2,
            horizontal = 0.3,
            firstShotMultiplier = 1.3,
            recovery = 0.95,
            pattern = "rising"
        },
        
        -- Spread/accuracy
        spread = {
            base = 0.5,
            moving = 1.5,
            jumping = 3.0,
            aiming = 0.2,
            sustained = 0.1,
            recovery = 0.9
        },
        
        -- Magazine system
        magazine = {
            size = 30,
            maxAmmo = 120,
            reloadTime = 2.5,
            reloadTimeEmpty = 3.0,
            ammoType = "5.56x45mm"
        },
        
        -- Mobility stats
        mobility = {
            walkSpeed = 14,
            sprintSpeed = 20,
            adsSpeed = 0.3,
            equipTime = 0.5
        },
        
        -- Attachment compatibility
        attachmentPoints = {
            sight = true,
            barrel = true,
            underbarrel = true,
            other = true,
            ammo = true
        },
        
        -- Visual effects
        muzzleFlash = {
            size = 1.0,
            brightness = 2,
            color = Color3.fromRGB(255, 200, 100)
        },
        
        tracers = {
            enabled = true,
            color = Color3.fromRGB(255, 180, 100),
            frequency = 3,
            width = 0.08
        },
        
        -- Sound configuration
        sounds = {
            fire = UnifiedWeaponConfig.SoundLibrary.G36_FIRE,
            reload = UnifiedWeaponConfig.SoundLibrary.RIFLE_RELOAD,
            reloadEmpty = UnifiedWeaponConfig.SoundLibrary.RIFLE_RELOAD,
            equip = UnifiedWeaponConfig.SoundLibrary.EQUIP_WEAPON,
            empty = UnifiedWeaponConfig.SoundLibrary.EMPTY_CLICK
        }
    },
    
    M4A1 = {
        name = "M4A1",
        displayName = "M4A1 Carbine",
        description = "American carbine with high versatility",
        category = UnifiedWeaponConfig.Categories.PRIMARY,
        type = UnifiedWeaponConfig.Types.CARBINE,
        
        damage = {
            base = 23,
            ranges = {
                {distance = 0, damage = 23},
                {distance = 40, damage = 21},
                {distance = 90, damage = 19},
                {distance = 180, damage = 16}
            },
            headshotMultiplier = 1.5,
            torsoMultiplier = 1.0,
            limbMultiplier = 0.9
        },
        
        fireRate = 800,
        firingMode = UnifiedWeaponConfig.FiringModes.FULL_AUTO,
        
        recoil = {
            vertical = 1.0,
            horizontal = 0.25,
            firstShotMultiplier = 1.2,
            recovery = 0.95
        },
        
        spread = {
            base = 0.4,
            moving = 1.3,
            jumping = 2.8,
            aiming = 0.15,
            sustained = 0.08,
            recovery = 0.92
        },
        
        magazine = {
            size = 30,
            maxAmmo = 120,
            reloadTime = 2.3,
            reloadTimeEmpty = 2.8,
            ammoType = "5.56x45mm"
        },
        
        mobility = {
            walkSpeed = 15,
            sprintSpeed = 21,
            adsSpeed = 0.25,
            equipTime = 0.4
        },
        
        attachmentPoints = {
            sight = true,
            barrel = true,
            underbarrel = true,
            other = true,
            ammo = true
        },
        
        sounds = {
            fire = UnifiedWeaponConfig.SoundLibrary.M4A1_FIRE,
            reload = UnifiedWeaponConfig.SoundLibrary.RIFLE_RELOAD,
            reloadEmpty = UnifiedWeaponConfig.SoundLibrary.RIFLE_RELOAD,
            equip = UnifiedWeaponConfig.SoundLibrary.EQUIP_WEAPON,
            empty = UnifiedWeaponConfig.SoundLibrary.EMPTY_CLICK
        }
    },
    
    AWP = {
        name = "AWP",
        displayName = "AWP Sniper Rifle",
        description = "High-powered bolt-action sniper rifle",
        category = UnifiedWeaponConfig.Categories.PRIMARY,
        type = UnifiedWeaponConfig.Types.SNIPER_RIFLE,
        
        damage = {
            base = 100,
            ranges = {
                {distance = 0, damage = 100},
                {distance = 100, damage = 95},
                {distance = 300, damage = 85},
                {distance = 500, damage = 75}
            },
            headshotMultiplier = 2.0,
            torsoMultiplier = 1.0,
            limbMultiplier = 0.95
        },
        
        fireRate = 40,
        firingMode = UnifiedWeaponConfig.FiringModes.BOLT_ACTION,
        
        recoil = {
            vertical = 5.0,
            horizontal = 0.5,
            firstShotMultiplier = 1.0,
            recovery = 0.7
        },
        
        spread = {
            base = 0.05,
            moving = 3.0,
            jumping = 10.0,
            aiming = 0.01,
            sustained = 0,
            recovery = 1.0
        },
        
        magazine = {
            size = 5,
            maxAmmo = 25,
            reloadTime = 3.5,
            reloadTimeEmpty = 3.5,
            ammoType = ".338 Lapua"
        },
        
        mobility = {
            walkSpeed = 10,
            sprintSpeed = 14,
            adsSpeed = 0.6,
            equipTime = 1.2
        },
        
        scope = {
            defaultZoom = 8.0,
            maxZoom = 12.0,
            scopeType = "MODEL",
            sensitivity = 0.4
        },
        
        sounds = {
            fire = UnifiedWeaponConfig.SoundLibrary.AWP_FIRE,
            boltAction = UnifiedWeaponConfig.SoundLibrary.BOLT_ACTION,
            reload = UnifiedWeaponConfig.SoundLibrary.SNIPER_RELOAD,
            reloadEmpty = UnifiedWeaponConfig.SoundLibrary.SNIPER_RELOAD,
            equip = UnifiedWeaponConfig.SoundLibrary.EQUIP_WEAPON,
            empty = UnifiedWeaponConfig.SoundLibrary.EMPTY_CLICK
        }
    },
    
    ["NTW-20"] = {
        name = "NTW-20",
        displayName = "NTW-20 Anti-Material Rifle",
        description = "Devastating anti-material rifle with dual ammo system",
        category = UnifiedWeaponConfig.Categories.PRIMARY,
        type = UnifiedWeaponConfig.Types.SNIPER_RIFLE,
        
        damage = {
            base = 150,
            ranges = {
                {distance = 0, damage = 150},
                {distance = 200, damage = 140},
                {distance = 500, damage = 120},
                {distance = 1000, damage = 100}
            },
            headshotMultiplier = 2.5,
            torsoMultiplier = 1.0,
            limbMultiplier = 0.95,
            penetration = 10.0
        },
        
        fireRate = 30,
        firingMode = UnifiedWeaponConfig.FiringModes.BOLT_ACTION,
        
        recoil = {
            vertical = 12.0,
            horizontal = 3.0,
            firstShotMultiplier = 1.0,
            recovery = 0.6
        },
        
        spread = {
            base = 0.05,
            moving = 8.0,
            jumping = 20.0,
            aiming = 0.005,
            sustained = 0,
            recovery = 1.0
        },
        
        magazine = {
            size = 3,
            maxAmmo = 15,
            reloadTime = 5.0,
            reloadTimeEmpty = 5.5,
            ammoType = "14.5x114mm"
        },
        
        -- Dual ammo system
        ammoTypes = {
            ["14.5x114mm"] = {
                damage = 150,
                penetration = 4.0,
                description = "Standard anti-material rounds"
            },
            ["20x110mm"] = {
                damage = 200,
                penetration = 5.0,
                recoilMultiplier = 1.3,
                description = "High-explosive rounds"
            }
        },
        
        mobility = {
            walkSpeed = 8,
            sprintSpeed = 10,
            adsSpeed = 1.0,
            equipTime = 2.0
        },
        
        sounds = {
            fire = UnifiedWeaponConfig.SoundLibrary.NTW20_FIRE,
            boltAction = UnifiedWeaponConfig.SoundLibrary.BOLT_ACTION,
            reload = UnifiedWeaponConfig.SoundLibrary.SNIPER_RELOAD,
            reloadEmpty = UnifiedWeaponConfig.SoundLibrary.SNIPER_RELOAD,
            equip = UnifiedWeaponConfig.SoundLibrary.EQUIP_WEAPON,
            empty = UnifiedWeaponConfig.SoundLibrary.EMPTY_CLICK
        }
    },
    
    -- SECONDARY WEAPONS
    M9 = {
        name = "M9",
        displayName = "M9 Beretta",
        description = "Standard semi-automatic pistol",
        category = UnifiedWeaponConfig.Categories.SECONDARY,
        type = UnifiedWeaponConfig.Types.PISTOL,
        
        damage = {
            base = 20,
            ranges = {
                {distance = 0, damage = 20},
                {distance = 30, damage = 18},
                {distance = 60, damage = 15},
                {distance = 100, damage = 12}
            },
            headshotMultiplier = 1.5,
            torsoMultiplier = 1.0,
            limbMultiplier = 0.9
        },
        
        fireRate = 450,
        firingMode = UnifiedWeaponConfig.FiringModes.SEMI_AUTO,
        
        recoil = {
            vertical = 0.8,
            horizontal = 0.2,
            firstShotMultiplier = 1.1,
            recovery = 0.98
        },
        
        spread = {
            base = 0.3,
            moving = 1.0,
            jumping = 2.0,
            aiming = 0.1,
            sustained = 0.05,
            recovery = 0.95
        },
        
        magazine = {
            size = 15,
            maxAmmo = 60,
            reloadTime = 2.0,
            reloadTimeEmpty = 2.5,
            ammoType = "9x19mm"
        },
        
        mobility = {
            walkSpeed = 16,
            sprintSpeed = 22,
            adsSpeed = 0.2,
            equipTime = 0.3
        },
        
        sounds = {
            fire = UnifiedWeaponConfig.SoundLibrary.M9_FIRE,
            reload = UnifiedWeaponConfig.SoundLibrary.PISTOL_RELOAD,
            reloadEmpty = UnifiedWeaponConfig.SoundLibrary.PISTOL_RELOAD,
            equip = UnifiedWeaponConfig.SoundLibrary.EQUIP_WEAPON,
            empty = UnifiedWeaponConfig.SoundLibrary.EMPTY_CLICK
        }
    },
    
    -- MELEE WEAPONS
    Knife = {
        name = "Knife",
        displayName = "Combat Knife",
        description = "Standard military combat knife",
        category = UnifiedWeaponConfig.Categories.MELEE,
        type = UnifiedWeaponConfig.Types.KNIFE,
        
        damage = {
            front = 55,
            backstab = 100,
            range = 5,
            attackRate = 1.5
        },
        
        mobility = {
            walkSpeed = 16,
            sprintSpeed = 23,
            equipTime = 0.2
        },
        
        sounds = {
            swing = UnifiedWeaponConfig.SoundLibrary.KNIFE_SWING,
            hit = UnifiedWeaponConfig.SoundLibrary.KNIFE_HIT,
            backstab = UnifiedWeaponConfig.SoundLibrary.KNIFE_BACKSTAB
        }
    },
    
    -- GRENADES
    ["M67 Frag"] = {
        name = "M67 Frag",
        displayName = "M67 Fragmentation Grenade",
        description = "Standard military fragmentation grenade",
        category = UnifiedWeaponConfig.Categories.GRENADE,
        type = UnifiedWeaponConfig.Types.FRAG,
        
        damage = {
            explosion = 100,
            radius = 15,
            falloff = true
        },
        
        physics = {
            throwForce = 50,
            cookTime = 5,
            fuseTime = 3,
            bounceElasticity = 0.3
        },
        
        sounds = {
            pin = UnifiedWeaponConfig.SoundLibrary.GRENADE_PIN,
            throw = UnifiedWeaponConfig.SoundLibrary.GRENADE_THROW,
            explosion = UnifiedWeaponConfig.SoundLibrary.EXPLOSION
        }
    }
}

-- Unified attachment system
UnifiedWeaponConfig.Attachments = {
    -- SIGHTS
    RedDot = {
        name = "Red Dot Sight",
        type = "SIGHT",
        description = "Basic red dot for improved accuracy",
        statModifiers = {
            spread = {aiming = 0.8},
            mobility = {adsSpeed = 0.95}
        },
        compatibleWeapons = {"G36", "M4A1", "AWP"},
        model = "RedDotModel"
    },
    
    ACOG = {
        name = "ACOG 4x",
        type = "SIGHT", 
        description = "4x magnification scope",
        statModifiers = {
            spread = {aiming = 0.6},
            mobility = {adsSpeed = 1.2}
        },
        zoom = 4.0,
        compatibleWeapons = {"G36", "M4A1"},
        model = "ACOGModel"
    },
    
    -- BARRELS
    Suppressor = {
        name = "Suppressor",
        type = "BARREL",
        description = "Reduces sound and muzzle flash",
        statModifiers = {
            damage = {base = 0.9},
            recoil = {vertical = 0.85, horizontal = 0.9}
        },
        compatibleWeapons = {"G36", "M4A1", "M9"},
        model = "SuppressorModel"
    },
    
    Compensator = {
        name = "Compensator",
        type = "BARREL",
        description = "Reduces horizontal recoil",
        statModifiers = {
            recoil = {horizontal = 0.7}
        },
        compatibleWeapons = {"G36", "M4A1"},
        model = "CompensatorModel"
    },
    
    -- UNDERBARREL
    VerticalGrip = {
        name = "Vertical Grip",
        type = "UNDERBARREL",
        description = "Reduces vertical recoil",
        statModifiers = {
            recoil = {vertical = 0.8},
            spread = {sustained = 0.9}
        },
        compatibleWeapons = {"G36", "M4A1"},
        model = "VerticalGripModel"
    },
    
    Laser = {
        name = "Laser Sight",
        type = "UNDERBARREL",
        description = "Improves hipfire accuracy",
        statModifiers = {
            spread = {base = 0.8, moving = 0.85}
        },
        hasLaser = true,
        laserColor = Color3.fromRGB(255, 0, 0),
        compatibleWeapons = {"G36", "M4A1", "M9"},
        model = "LaserModel"
    }
}

-- API Functions
function UnifiedWeaponConfig:getWeaponConfig(weaponName)
    return self.Weapons[weaponName]
end

function UnifiedWeaponConfig:getAttachmentConfig(attachmentName)
    return self.Attachments[attachmentName]
end

function UnifiedWeaponConfig:applyAttachment(weaponConfig, attachmentName)
    local attachment = self.Attachments[attachmentName]
    if not attachment then return weaponConfig end
    
    -- Deep clone to avoid modifying original
    local modifiedConfig = {}
    for k, v in pairs(weaponConfig) do
        if type(v) == "table" then
            modifiedConfig[k] = {}
            for k2, v2 in pairs(v) do
                if type(v2) == "table" then
                    modifiedConfig[k][k2] = {}
                    for k3, v3 in pairs(v2) do
                        modifiedConfig[k][k2][k3] = v3
                    end
                else
                    modifiedConfig[k][k2] = v2
                end
            end
        else
            modifiedConfig[k] = v
        end
    end
    
    -- Apply stat modifiers
    if attachment.statModifiers then
        for category, mods in pairs(attachment.statModifiers) do
            if modifiedConfig[category] then
                for stat, value in pairs(mods) do
                    if type(value) == "number" then
                        if type(modifiedConfig[category][stat]) == "number" then
                            modifiedConfig[category][stat] = modifiedConfig[category][stat] * value
                        end
                    end
                end
            end
        end
    end
    
    return modifiedConfig
end

function UnifiedWeaponConfig:isAttachmentCompatible(weaponName, attachmentName)
    local attachment = self.Attachments[attachmentName]
    if not attachment or not attachment.compatibleWeapons then
        return false
    end
    
    for _, compatible in ipairs(attachment.compatibleWeapons) do
        if compatible == weaponName then
            return true
        end
    end
    
    return false
end

function UnifiedWeaponConfig:getCompatibleAttachments(weaponName)
    local compatible = {
        SIGHT = {},
        BARREL = {},
        UNDERBARREL = {},
        OTHER = {},
        AMMO = {}
    }
    
    for attachmentName, attachment in pairs(self.Attachments) do
        if self:isAttachmentCompatible(weaponName, attachmentName) then
            table.insert(compatible[attachment.type], {
                name = attachmentName,
                displayName = attachment.name,
                description = attachment.description
            })
        end
    end
    
    return compatible
end

function UnifiedWeaponConfig:getWeaponsByCategory(category)
    local weapons = {}
    for name, weapon in pairs(self.Weapons) do
        if weapon.category == category then
            table.insert(weapons, name)
        end
    end
    return weapons
end

-- Export globally for compatibility
_G.UnifiedWeaponConfig = UnifiedWeaponConfig

return UnifiedWeaponConfig