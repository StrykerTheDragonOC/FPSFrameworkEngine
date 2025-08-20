-- WeaponAttachmentSystem.lua
-- Advanced weapon attachment system for KFCS FUNNY RANDOMIZER
-- Handles attachment effects, compatibility, and stat modifications
-- Place in ReplicatedStorage/FPSSystem/Modules

local WeaponAttachmentSystem = {}
WeaponAttachmentSystem.__index = WeaponAttachmentSystem

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Attachment slot definitions
local ATTACHMENT_SLOTS = {
    OPTIC = "optic",
    BARREL = "barrel", 
    GRIP = "grip",
    LASER = "laser",
    AMMUNITION = "ammunition",
    OTHER = "other"
}

-- Comprehensive attachment database with stat effects
local ATTACHMENTS = {
    -- Optics
    ["Red Dot Sight"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Close Range",
        effects = {
            aim_speed = 0.05,           -- 5% faster ADS
            zoom_level = 1.2,
            recoil_reduction = 0.02
        },
        compatibility = {"assault_rifles", "smgs", "lmgs", "carbines", "shotguns"},
        unlock_kills = 5,
        description = "Basic reflex sight for close-range engagements"
    },
    
    ["Holographic Sight"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Close Range",
        effects = {
            aim_speed = 0.03,
            zoom_level = 1.3,
            recoil_reduction = 0.03,
            peripheral_vision = 0.1    -- Better side visibility
        },
        compatibility = {"assault_rifles", "smgs", "lmgs", "carbines"},
        unlock_kills = 15,
        description = "Advanced holographic sight with improved clarity"
    },
    
    ["ACOG Scope"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Medium Range",
        effects = {
            aim_speed = -0.1,           -- 10% slower ADS
            zoom_level = 4.0,
            range_boost = 0.15,         -- 15% better range
            recoil_reduction = 0.05
        },
        compatibility = {"assault_rifles", "battle_rifles", "dmrs", "lmgs"},
        unlock_kills = 35,
        description = "4x magnification scope for medium-range precision"
    },
    
    ["Sniper Scope"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Long Range",
        effects = {
            aim_speed = -0.2,
            zoom_level = 8.0,
            range_boost = 0.3,
            recoil_reduction = 0.08,
            movement_penalty = -0.15    -- Slower movement when ADS
        },
        compatibility = {"sniper_rifles", "dmrs", "battle_rifles"},
        unlock_kills = 50,
        description = "High-magnification scope for long-range precision"
    },
    
    ["Thermal Scope"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Special",
        effects = {
            aim_speed = -0.15,
            zoom_level = 6.0,
            thermal_vision = true,      -- See through smoke/walls
            range_boost = 0.2,
            battery_drain = true        -- Limited use time
        },
        compatibility = {"sniper_rifles", "dmrs", "lmgs"},
        unlock_kills = 100,
        description = "Thermal imaging scope - see enemies through smoke"
    },
    
    -- Barrels
    ["Suppressor"] = {
        slot = ATTACHMENT_SLOTS.BARREL,
        category = "Stealth",
        effects = {
            sound_reduction = 0.8,      -- 80% quieter
            muzzle_flash_reduction = 0.9,
            damage_reduction = -0.05,   -- 5% less damage
            range_penalty = -0.1,       -- 10% less range
            stealth_bonus = true        -- Doesn't show on minimap
        },
        compatibility = {"assault_rifles", "smgs", "pistols", "carbines", "dmrs"},
        unlock_kills = 25,
        description = "Reduces sound and muzzle flash but decreases damage"
    },
    
    ["Heavy Barrel"] = {
        slot = ATTACHMENT_SLOTS.BARREL,
        category = "Damage",
        effects = {
            damage_boost = 0.1,         -- 10% more damage
            range_boost = 0.15,         -- 15% better range
            recoil_increase = 0.1,      -- 10% more recoil
            mobility_penalty = -0.1     -- 10% slower movement
        },
        compatibility = {"assault_rifles", "battle_rifles", "lmgs", "dmrs"},
        unlock_kills = 40,
        description = "Increases damage and range at cost of mobility"
    },
    
    ["Compensator"] = {
        slot = ATTACHMENT_SLOTS.BARREL,
        category = "Recoil Control",
        effects = {
            vertical_recoil_reduction = 0.25,  -- 25% less vertical recoil
            horizontal_recoil_increase = 0.1,  -- 10% more horizontal recoil
            sound_increase = 0.2               -- 20% louder
        },
        compatibility = {"assault_rifles", "battle_rifles", "lmgs", "smgs"},
        unlock_kills = 80,
        description = "Reduces vertical recoil but increases horizontal spread"
    },
    
    -- Grips
    ["Vertical Grip"] = {
        slot = ATTACHMENT_SLOTS.GRIP,
        category = "Stability",
        effects = {
            vertical_recoil_reduction = 0.15,
            aim_stability = 0.1,
            ads_penalty = -0.05          -- 5% slower ADS
        },
        compatibility = {"assault_rifles", "lmgs", "carbines", "battle_rifles"},
        unlock_kills = 10,
        description = "Reduces vertical recoil and improves stability"
    },
    
    ["Angled Grip"] = {
        slot = ATTACHMENT_SLOTS.GRIP,
        category = "Handling",
        effects = {
            ads_speed = 0.1,             -- 10% faster ADS
            horizontal_recoil_reduction = 0.1,
            vertical_recoil_increase = 0.05
        },
        compatibility = {"assault_rifles", "smgs", "carbines"},
        unlock_kills = 30,
        description = "Faster ADS and better horizontal control"
    },
    
    ["Bipod"] = {
        slot = ATTACHMENT_SLOTS.GRIP,
        category = "Precision",
        effects = {
            prone_recoil_reduction = 0.4,    -- 40% less recoil when prone
            prone_stability = 0.5,
            mobility_penalty = -0.2,         -- 20% slower movement
            deploy_time = 1.0               -- Takes time to deploy
        },
        compatibility = {"lmgs", "sniper_rifles", "battle_rifles"},
        unlock_kills = 75,
        description = "Dramatically improves accuracy when prone"
    },
    
    -- Lasers/Lights
    ["Laser Sight"] = {
        slot = ATTACHMENT_SLOTS.LASER,
        category = "Hip Fire",
        effects = {
            hip_fire_accuracy = 0.3,     -- 30% better hip fire
            ads_speed = 0.05,
            enemy_detection = true       -- Enemies can see laser dot
        },
        compatibility = {"assault_rifles", "smgs", "pistols", "shotguns"},
        unlock_kills = 20,
        description = "Improves hip fire accuracy but reveals position"
    },
    
    ["Flashlight"] = {
        slot = ATTACHMENT_SLOTS.LASER,
        category = "Utility",
        effects = {
            illumination = true,         -- Lights up dark areas
            enemy_blind = 0.2,          -- 20% chance to blind enemies
            stealth_penalty = true,     -- More visible to enemies
            battery_life = 300          -- 5 minutes of use
        },
        compatibility = {"assault_rifles", "smgs", "shotguns", "pistols"},
        unlock_kills = 35,
        description = "Illuminates dark areas but makes you more visible"
    },
    
    -- Ammunition Types
    ["Hollow Point"] = {
        slot = ATTACHMENT_SLOTS.AMMUNITION,
        category = "Anti-Personnel",
        effects = {
            flesh_damage = 0.2,          -- 20% more damage to unarmored
            armor_penetration = -0.3,    -- 30% less armor penetration
            stopping_power = 0.15       -- Better at stopping enemies
        },
        compatibility = {"pistols", "smgs", "assault_rifles"},
        unlock_kills = 100,
        description = "Devastating against unarmored targets"
    },
    
    ["Armor Piercing"] = {
        slot = ATTACHMENT_SLOTS.AMMUNITION,
        category = "Anti-Armor",
        effects = {
            armor_penetration = 0.4,     -- 40% better armor penetration
            flesh_damage = -0.1,         -- 10% less damage to unarmored
            wall_penetration = 0.3       -- Can shoot through more walls
        },
        compatibility = {"assault_rifles", "battle_rifles", "sniper_rifles", "lmgs"},
        unlock_kills = 150,
        description = "Penetrates armor and walls more effectively"
    },
    
    -- High-End Attachments (1000+ kills)
    ["FLIR 3.4x"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Elite",
        effects = {
            zoom_level = 3.4,
            thermal_vision = true,
            night_vision = true,
            target_highlighting = true,  -- Highlights enemies
            battery_drain = true
        },
        compatibility = {"assault_rifles", "battle_rifles", "dmrs"},
        unlock_kills = 1200,
        description = "Advanced thermal/night vision with target tracking"
    },
    
    ["Anti Sight"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Meme",
        effects = {
            zoom_level = 0.5,           -- Makes everything smaller
            confusion_factor = 0.9,     -- Confuses the user
            accuracy_penalty = -0.2,    -- 20% less accurate
            meme_value = 1.0           -- Maximum meme potential
        },
        compatibility = {"all"},
        unlock_kills = 2000,
        description = "The worst sight in the game. Use for memes only."
    },
    
    ["SUPER SCOPE"] = {
        slot = ATTACHMENT_SLOTS.OPTIC,
        category = "Ultimate",
        effects = {
            zoom_level = 20.0,          -- Extreme magnification
            perfect_accuracy = true,     -- No bullet spread
            range_boost = 1.0,          -- Double range
            movement_penalty = -0.5,    -- 50% slower movement
            legendary_status = true     -- Shows special effects
        },
        compatibility = {"sniper_rifles"},
        unlock_kills = 3000,
        description = "Ultimate sniper scope - extreme range and accuracy"
    }
}

-- Weapon compatibility groups
local WEAPON_COMPATIBILITY = {
    assault_rifles = {"G36", "AK74", "M4A1", "SCAR-L", "AUG", "F2000", "TAR-21", "AN-94"},
    battle_rifles = {"SCAR-H", "G3", "FAL", "AG-3", "Henry .45-70", "AK103", "HK417", "BEOWULF ECR"},
    smgs = {"MP5", "UMP45", "P90", "MP7", "Vector", "Skorpion", "PPSh-41", "MP40"},
    lmgs = {"M249", "PKM", "MG3", "L86A2", "HAMR", "AWS", "M60", "RPK"},
    sniper_rifles = {"AWM", "M98B", "DSR-1", "Intervention", "TRG-42", "SV-98", "WA2000", "BFG-50"},
    dmrs = {"MK11", "SKS", "VSS", "SCAR-SSR", "Dragunov", "Henry", "Mosin", "BEOWULF TCR"},
    carbines = {"M4", "AKU12", "Honey Badger", "SR-3M", "AS VAL", "Groza-1", "X95R", "K2C1"},
    shotguns = {"M870", "KSG", "SPAS-12", "AA-12", "Saiga-12", "M1014", "Serbu", "DBV12"},
    pistols = {"M9", "M1911", "Deagle 44", "Five seveN", "ZIP 22", "M45A1", "USP45", "1858 New Army"}
}

-- Constructor
function WeaponAttachmentSystem.new()
    local self = setmetatable({}, WeaponAttachmentSystem)
    
    -- Track equipped attachments per player/weapon
    self.playerAttachments = {}
    
    return self
end

-- Initialize attachment system
function WeaponAttachmentSystem:initialize()
    print("[WeaponAttachmentSystem] Initializing advanced attachment system...")
    print("[WeaponAttachmentSystem] Loaded", #ATTACHMENTS, "attachment types with stat modifications")
    return true
end

-- Check if attachment is compatible with weapon
function WeaponAttachmentSystem:isCompatible(weaponName, attachmentName)
    local attachment = ATTACHMENTS[attachmentName]
    if not attachment then return false end
    
    -- Check if weapon is in compatibility list
    for _, compatGroup in pairs(attachment.compatibility) do
        if compatGroup == "all" then return true end
        
        local weaponList = WEAPON_COMPATIBILITY[compatGroup]
        if weaponList then
            for _, weapon in pairs(weaponList) do
                if weapon == weaponName then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Get all compatible attachments for a weapon
function WeaponAttachmentSystem:getCompatibleAttachments(weaponName)
    local compatible = {}
    
    for attachmentName, attachmentData in pairs(ATTACHMENTS) do
        if self:isCompatible(weaponName, attachmentName) then
            table.insert(compatible, {
                name = attachmentName,
                data = attachmentData
            })
        end
    end
    
    return compatible
end

-- Apply attachment effects to weapon stats
function WeaponAttachmentSystem:applyAttachmentEffects(baseStats, attachments)
    local modifiedStats = {}
    
    -- Copy base stats
    for key, value in pairs(baseStats) do
        modifiedStats[key] = value
    end
    
    -- Apply each attachment's effects
    for _, attachmentName in pairs(attachments) do
        local attachment = ATTACHMENTS[attachmentName]
        if attachment and attachment.effects then
            for effect, value in pairs(attachment.effects) do
                self:applyStatModification(modifiedStats, effect, value)
            end
        end
    end
    
    return modifiedStats
end

-- Apply individual stat modification
function WeaponAttachmentSystem:applyStatModification(stats, effect, value)
    if effect == "damage_boost" then
        stats.damage = stats.damage * (1 + value)
    elseif effect == "damage_reduction" then
        stats.damage = stats.damage * (1 + value)
    elseif effect == "range_boost" then
        stats.range = stats.range * (1 + value)
    elseif effect == "range_penalty" then
        stats.range = stats.range * (1 + value)
    elseif effect == "recoil_reduction" then
        if stats.recoil then
            for i, recoilValue in pairs(stats.recoil) do
                stats.recoil[i] = recoilValue * (1 - value)
            end
        end
    elseif effect == "vertical_recoil_reduction" then
        if stats.recoil and stats.recoil[1] then
            stats.recoil[1] = stats.recoil[1] * (1 - value)
        end
    elseif effect == "horizontal_recoil_reduction" then
        if stats.recoil and stats.recoil[2] then
            stats.recoil[2] = stats.recoil[2] * (1 - value)
        end
    elseif effect == "aim_speed" then
        stats.aimTime = (stats.aimTime or 1.0) * (1 - value)
    elseif effect == "mobility_penalty" then
        stats.walkSpeed = (stats.walkSpeed or 16) * (1 + value)
    elseif effect == "sound_reduction" then
        stats.soundLevel = (stats.soundLevel or 1.0) * (1 - value)
    end
    
    -- Add special effects flags
    if effect == "thermal_vision" then
        stats.hasThermalsight = value
    elseif effect == "stealth_bonus" then
        stats.suppressedShots = value
    elseif effect == "perfect_accuracy" then
        stats.spread = {min = 0, max = 0, increase = 0}
    end
end

-- Get attachment unlock requirement
function WeaponAttachmentSystem:getAttachmentUnlockKills(attachmentName)
    local attachment = ATTACHMENTS[attachmentName]
    return attachment and attachment.unlock_kills or 0
end

-- Get attachment by slot for weapon
function WeaponAttachmentSystem:getAttachmentsBySlot(weaponName, slot)
    local slotAttachments = {}
    
    for attachmentName, attachmentData in pairs(ATTACHMENTS) do
        if attachmentData.slot == slot and self:isCompatible(weaponName, attachmentName) then
            table.insert(slotAttachments, {
                name = attachmentName,
                data = attachmentData
            })
        end
    end
    
    -- Sort by unlock requirement
    table.sort(slotAttachments, function(a, b)
        return a.data.unlock_kills < b.data.unlock_kills
    end)
    
    return slotAttachments
end

-- Validate attachment combination
function WeaponAttachmentSystem:validateAttachmentCombination(weaponName, attachments)
    local slotUsage = {}
    
    for _, attachmentName in pairs(attachments) do
        local attachment = ATTACHMENTS[attachmentName]
        if not attachment then
            return false, "Unknown attachment: " .. attachmentName
        end
        
        -- Check compatibility
        if not self:isCompatible(weaponName, attachmentName) then
            return false, "Incompatible attachment: " .. attachmentName
        end
        
        -- Check slot conflicts
        local slot = attachment.slot
        if slotUsage[slot] then
            return false, "Slot conflict: " .. slot .. " already used"
        end
        slotUsage[slot] = true
    end
    
    return true, "Valid combination"
end

-- Get attachment description with stats
function WeaponAttachmentSystem:getAttachmentInfo(attachmentName)
    local attachment = ATTACHMENTS[attachmentName]
    if not attachment then return nil end
    
    local info = {
        name = attachmentName,
        description = attachment.description,
        category = attachment.category,
        slot = attachment.slot,
        unlock_kills = attachment.unlock_kills,
        effects = {}
    }
    
    -- Format effects for display
    for effect, value in pairs(attachment.effects or {}) do
        local displayText = self:formatEffectForDisplay(effect, value)
        if displayText then
            table.insert(info.effects, displayText)
        end
    end
    
    return info
end

-- Format effect for UI display
function WeaponAttachmentSystem:formatEffectForDisplay(effect, value)
    local isPositive = value > 0
    local symbol = isPositive and "+" or ""
    local color = isPositive and "Green" or "Red"
    
    if effect == "damage_boost" or effect == "damage_reduction" then
        return string.format("%s%d%% Damage", symbol, math.floor(value * 100))
    elseif effect == "range_boost" or effect == "range_penalty" then
        return string.format("%s%d%% Range", symbol, math.floor(value * 100))
    elseif effect == "recoil_reduction" then
        return string.format("-%d%% Recoil", math.floor(value * 100))
    elseif effect == "aim_speed" then
        return string.format("%s%d%% ADS Speed", symbol, math.floor(value * 100))
    elseif effect == "sound_reduction" then
        return string.format("-%d%% Sound", math.floor(value * 100))
    elseif effect == "thermal_vision" then
        return "Thermal Vision"
    elseif effect == "stealth_bonus" then
        return "Stealth Shots"
    elseif effect == "perfect_accuracy" then
        return "Perfect Accuracy"
    end
    
    return nil
end

-- Get all attachment data
function WeaponAttachmentSystem:getAllAttachments()
    return ATTACHMENTS
end

-- Get attachment slots
function WeaponAttachmentSystem:getAttachmentSlots()
    return ATTACHMENT_SLOTS
end

return WeaponAttachmentSystem