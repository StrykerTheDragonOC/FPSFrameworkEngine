-- WeaponConfigManager.lua
-- Complete weapon configuration system
-- Place in ReplicatedStorage/FPSSystem/Config/WeaponConfigManager.lua

local WeaponConfigManager = {}

-- Weapon configurations with all stats
WeaponConfigManager.Weapons = {
    -- PRIMARY WEAPONS
    G36 = {
        name = "G36",
        displayName = "G36 Assault Rifle",
        category = "PRIMARY",
        subcategory = "AssaultRifles",

        -- Damage
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

        -- Fire rate and mode
        fireRate = 750, -- RPM
        fireMode = "AUTO",  -- AUTO, BURST, SEMI
        burstCount = 3,

        -- Recoil
        recoil = {
            vertical = 1.2,
            horizontal = 0.3,
            firstShotMultiplier = 1.3,
            recovery = 0.95
        },

        -- Spread/Accuracy
        spread = {
            base = 0.5,
            moving = 1.5,
            jumping = 3.0,
            aiming = 0.2,
            sustained = 0.1,
            recovery = 0.9
        },

        -- Magazine
        magazine = {
            size = 30,
            maxAmmo = 120,
            reloadTime = 2.5,
            reloadTimeEmpty = 3.0,
            ammoType = "5.56x45mm"
        },

        -- Mobility
        mobility = {
            walkSpeed = 14,
            sprintSpeed = 20,
            adsSpeed = 0.3,
            equipTime = 0.5
        },

        -- Attachments
        attachmentPoints = {
            sight = true,
            barrel = true,
            underbarrel = true,
            other = true,
            ammo = true
        },

        -- Effects
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

        -- Sounds
        sounds = {
            fire = "rbxassetid://6043286676",
            fireSupressed = "rbxassetid://153230559",
            reload = "rbxassetid://18574927786",
            reloadEmpty = "rbxassetid://18574927786",
            equip = "rbxassetid://7405483764",
            empty = "rbxassetid://93840917543863"
        },

        -- Animation IDs (if not using model-embedded animations)
        animations = {
            idle = "rbxassetid://9949926480",
            fire = "rbxassetid://9949926480",
            reload = "rbxassetid://9949926480",
            reloadEmpty = "rbxassetid://9949926480",
            aim = "rbxassetid://9949926480",
            sprint = "rbxassetid://9949926480",
            equip = "rbxassetid://9949926480"
        }
    },

    M4A1 = {
        name = "M4A1",
        displayName = "M4A1 Carbine",
        category = "PRIMARY",
        subcategory = "Carbines",

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
        fireMode = "AUTO",

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

        sounds = {
            fire = "rbxassetid://6043286676",
            reload = "rbxassetid://18574927786",
            empty = "rbxassetid://93840917543863"
        }
    },

    AWP = {
        name = "AWP",
        displayName = "AWP Sniper Rifle",
        category = "PRIMARY",
        subcategory = "SniperRifles",

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
        fireMode = "BOLT",

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
            fire = "rbxassetid://4328614635",
            boltAction = "rbxassetid://133693886808298",
            reload = "rbxassetid://3666864180",
            empty = "rbxassetid://93840917543863"
        }
    },

    ["NTW-20"] = {
        name = "NTW-20",
        displayName = "NTW-20 Anti-Material Rifle",
        category = "PRIMARY",
        subcategory = "SniperRifles",

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
        fireMode = "BOLT",

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
            fire = "rbxassetid://17787141667",
            boltAction = "rbxassetid://133693886808298",
            reload = "rbxassetid://133693886808298"
        }
    },

    -- SECONDARY WEAPONS
    M9 = {
        name = "M9",
        displayName = "M9 Beretta",
        category = "SECONDARY",
        subcategory = "Pistols",

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
        fireMode = "SEMI",

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
            fire = "rbxassetid://799960407",
            reload = "rbxassetid://799960619",
            empty = "rbxassetid://93840917543863"
        }
    },

    -- MELEE WEAPONS
    Knife = {
        name = "Knife",
        displayName = "Combat Knife",
        category = "MELEE",
        subcategory = "Blades",

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

        animations = {
            idle = "rbxassetid://9949926480",
            attack1 = "rbxassetid://9949926480",
            attack2 = "rbxassetid://9949926480",
            backstab = "rbxassetid://9949926480"
        },

        sounds = {
            swing = "rbxassetid://7122602098",
            hit = "rbxassetid://4681189562",
            backstab = "rbxassetid://8255306220"
        }
    },

    -- GRENADES
    ["M67 Frag"] = {
        name = "M67 Frag",
        displayName = "M67 Fragmentation Grenade",
        category = "GRENADE",
        subcategory = "Lethal",

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
            pin = "rbxassetid://0",
            throw = "rbxassetid://0",
            explosion = "rbxassetid://0"
        }
    }
}

-- Attachment configurations
WeaponConfigManager.Attachments = {
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
            recoil = {vertical = 0.85, horizontal = 0.9},
            sounds = {fire = "fireSupressed"}
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

    AngledGrip = {
        name = "Angled Grip",
        type = "UNDERBARREL",
        description = "Faster ADS speed",
        statModifiers = {
            mobility = {adsSpeed = 0.8},
            recoil = {firstShotMultiplier = 0.9}
        },
        compatibleWeapons = {"G36", "M4A1"},
        model = "AngledGripModel"
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
    },

    -- AMMO
    ArmorPiercing = {
        name = "Armor Piercing",
        type = "AMMO",
        description = "Increased penetration",
        statModifiers = {
            damage = {penetration = 1.5}
        },
        compatibleWeapons = {"G36", "M4A1", "AWP", "NTW-20"}
    },

    HollowPoint = {
        name = "Hollow Point",
        type = "AMMO",
        description = "Increased damage, reduced penetration",
        statModifiers = {
            damage = {base = 1.15, penetration = 0.5}
        },
        compatibleWeapons = {"M9"}
    }
}

-- Get weapon config
function WeaponConfigManager:getWeaponConfig(weaponName)
    return self.Weapons[weaponName]
end

-- Get attachment config
function WeaponConfigManager:getAttachmentConfig(attachmentName)
    return self.Attachments[attachmentName]
end

-- Apply attachment to weapon config
function WeaponConfigManager:applyAttachment(weaponConfig, attachmentName)
    local attachment = self.Attachments[attachmentName]
    if not attachment then return weaponConfig end

    -- Clone config to avoid modifying original
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
                        elseif type(modifiedConfig[category]) == "number" then
                            modifiedConfig[category] = modifiedConfig[category] * value
                        end
                    elseif type(value) == "string" then
                        modifiedConfig[category][stat] = value
                    end
                end
            end
        end
    end

    -- Add special properties
    if attachment.zoom then
        modifiedConfig.scope = modifiedConfig.scope or {}
        modifiedConfig.scope.zoom = attachment.zoom
    end

    if attachment.hasLaser then
        modifiedConfig.hasLaser = true
        modifiedConfig.laserColor = attachment.laserColor
    end

    return modifiedConfig
end

-- Check if attachment is compatible
function WeaponConfigManager:isAttachmentCompatible(weaponName, attachmentName)
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

-- Get all compatible attachments for weapon
function WeaponConfigManager:getCompatibleAttachments(weaponName)
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

-- Export globally
_G.WeaponConfigManager = WeaponConfigManager

return WeaponConfigManager