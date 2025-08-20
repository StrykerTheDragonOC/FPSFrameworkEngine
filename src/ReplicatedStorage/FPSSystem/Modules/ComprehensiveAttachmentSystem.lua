-- ComprehensiveAttachmentSystem.lua
-- Advanced weapon attachment system with comprehensive features
-- Handles attachment equipping, stat modifications, and visual changes

local ComprehensiveAttachmentSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Attachment categories and types
local ATTACHMENT_CATEGORIES = {
    OPTIC = "Optic",
    BARREL = "Barrel", 
    GRIP = "Grip",
    LASER = "Laser",
    MAGAZINE = "Magazine",
    STOCK = "Stock",
    MUZZLE = "Muzzle"
}

-- Comprehensive attachment database
local ATTACHMENTS = {
    -- Optics
    ["RedDotSight"] = {
        Name = "Red Dot Sight",
        Category = ATTACHMENT_CATEGORIES.OPTIC,
        UnlockLevel = 10,
        Credits = 1200,
        Stats = {
            AimSpeed = 0.15,
            Accuracy = 0.1,
            ZoomLevel = 1.5
        },
        VisualEffects = {
            Reticle = "rbxasset://textures/ScopeReticle.png",
            GlowColor = Color3.fromRGB(255, 0, 0)
        }
    },
    ["ACOGScope"] = {
        Name = "ACOG 4x Scope",
        Category = ATTACHMENT_CATEGORIES.OPTIC,
        UnlockLevel = 25,
        Credits = 3500,
        Stats = {
            AimSpeed = -0.1,
            Accuracy = 0.25,
            ZoomLevel = 4.0,
            Range = 0.2
        },
        VisualEffects = {
            Reticle = "rbxasset://textures/ACOGReticle.png",
            Magnification = true
        }
    },
    -- Barrels
    ["Suppressor"] = {
        Name = "Sound Suppressor",
        Category = ATTACHMENT_CATEGORIES.BARREL,
        UnlockLevel = 15,
        Credits = 2000,
        Stats = {
            Damage = -0.1,
            Range = 0.1,
            SoundReduction = 0.7,
            MuzzleFlash = -0.8
        },
        VisualEffects = {
            MuzzleFlashScale = 0.2,
            SoundPitch = 0.5
        }
    },
    ["Compensator"] = {
        Name = "Muzzle Compensator",
        Category = ATTACHMENT_CATEGORIES.BARREL,
        UnlockLevel = 20,
        Credits = 1800,
        Stats = {
            Recoil = -0.3,
            HorizontalRecoil = -0.4,
            Range = -0.05
        }
    },
    -- Grips
    ["VerticalGrip"] = {
        Name = "Vertical Grip",
        Category = ATTACHMENT_CATEGORIES.GRIP,
        UnlockLevel = 8,
        Credits = 800,
        Stats = {
            Recoil = -0.2,
            AimSpeed = 0.1,
            Stability = 0.25
        }
    },
    ["AngledGrip"] = {
        Name = "Angled Grip", 
        Category = ATTACHMENT_CATEGORIES.GRIP,
        UnlockLevel = 12,
        Credits = 1000,
        Stats = {
            AimSpeed = 0.2,
            Recoil = -0.1,
            MovementSpeed = 0.05
        }
    },
    -- Lasers
    ["LaserSight"] = {
        Name = "Laser Sight",
        Category = ATTACHMENT_CATEGORIES.LASER,
        UnlockLevel = 5,
        Credits = 600,
        Stats = {
            HipAccuracy = 0.3,
            AimSpeed = 0.05
        },
        VisualEffects = {
            LaserColor = Color3.fromRGB(255, 0, 0),
            LaserRange = 200
        }
    },
    -- Magazines
    ["ExtendedMag"] = {
        Name = "Extended Magazine",
        Category = ATTACHMENT_CATEGORIES.MAGAZINE,
        UnlockLevel = 18,
        Credits = 1500,
        Stats = {
            MagSize = 15,
            ReloadTime = 0.5,
            MovementSpeed = -0.05
        }
    },
    ["FastMag"] = {
        Name = "Fast Magazine",
        Category = ATTACHMENT_CATEGORIES.MAGAZINE,
        UnlockLevel = 22,
        Credits = 2200,
        Stats = {
            ReloadTime = -0.4,
            MagSize = -5
        }
    }
}

-- Player attachment data
local playerAttachments = {}

function ComprehensiveAttachmentSystem:init()
    print("[ComprehensiveAttachmentSystem] Initializing comprehensive attachment system...")
    
    -- Initialize player data
    Players.PlayerAdded:Connect(function(player)
        self:initializePlayerData(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:initializePlayerData(player)
    end
    
    -- Setup remote events
    self:setupRemoteEvents()
    
    print("[ComprehensiveAttachmentSystem] System initialized")
    return true
end

function ComprehensiveAttachmentSystem:initializePlayerData(player)
    playerAttachments[player.UserId] = {
        equipped = {},
        unlocked = {"RedDotSight", "LaserSight"}, -- Default unlocked
        loadouts = {
            primary = {},
            secondary = {},
            melee = {}
        }
    }
end

function ComprehensiveAttachmentSystem:getAttachmentData(attachmentName)
    return ATTACHMENTS[attachmentName]
end

function ComprehensiveAttachmentSystem:getAllAttachments()
    return ATTACHMENTS
end

function ComprehensiveAttachmentSystem:getAttachmentsByCategory(category)
    local categoryAttachments = {}
    for name, data in pairs(ATTACHMENTS) do
        if data.Category == category then
            categoryAttachments[name] = data
        end
    end
    return categoryAttachments
end

function ComprehensiveAttachmentSystem:isAttachmentUnlocked(player, attachmentName)
    local playerData = playerAttachments[player.UserId]
    if not playerData then return false end
    
    for _, unlockedAttachment in pairs(playerData.unlocked) do
        if unlockedAttachment == attachmentName then
            return true
        end
    end
    return false
end

function ComprehensiveAttachmentSystem:unlockAttachment(player, attachmentName)
    local playerData = playerAttachments[player.UserId]
    if not playerData then return false end
    
    local attachment = ATTACHMENTS[attachmentName]
    if not attachment then return false end
    
    -- Check if already unlocked
    if self:isAttachmentUnlocked(player, attachmentName) then
        return true
    end
    
    -- Add to unlocked list
    table.insert(playerData.unlocked, attachmentName)
    
    print("[ComprehensiveAttachmentSystem] Unlocked attachment:", attachmentName, "for", player.Name)
    return true
end

function ComprehensiveAttachmentSystem:equipAttachment(player, weaponSlot, attachmentSlot, attachmentName)
    local playerData = playerAttachments[player.UserId]
    if not playerData then return false end
    
    -- Validate attachment exists and is unlocked
    if not ATTACHMENTS[attachmentName] then return false end
    if not self:isAttachmentUnlocked(player, attachmentName) then return false end
    
    -- Initialize weapon slot if needed
    if not playerData.equipped[weaponSlot] then
        playerData.equipped[weaponSlot] = {}
    end
    
    -- Equip the attachment
    playerData.equipped[weaponSlot][attachmentSlot] = attachmentName
    
    print("[ComprehensiveAttachmentSystem] Equipped", attachmentName, "to", weaponSlot, attachmentSlot)
    return true
end

function ComprehensiveAttachmentSystem:getEquippedAttachments(player, weaponSlot)
    local playerData = playerAttachments[player.UserId]
    if not playerData or not playerData.equipped[weaponSlot] then
        return {}
    end
    
    return playerData.equipped[weaponSlot]
end

function ComprehensiveAttachmentSystem:calculateWeaponStats(baseStats, equippedAttachments)
    local modifiedStats = {}
    
    -- Copy base stats
    for stat, value in pairs(baseStats) do
        modifiedStats[stat] = value
    end
    
    -- Apply attachment modifications
    for attachmentSlot, attachmentName in pairs(equippedAttachments) do
        local attachment = ATTACHMENTS[attachmentName]
        if attachment and attachment.Stats then
            for stat, modifier in pairs(attachment.Stats) do
                if modifiedStats[stat] then
                    if stat == "MagSize" then
                        -- Additive for magazine size
                        modifiedStats[stat] = modifiedStats[stat] + modifier
                    else
                        -- Multiplicative for most stats
                        modifiedStats[stat] = modifiedStats[stat] * (1 + modifier)
                    end
                end
            end
        end
    end
    
    return modifiedStats
end

function ComprehensiveAttachmentSystem:applyVisualEffects(weapon, equippedAttachments)
    if not weapon then return end
    
    for attachmentSlot, attachmentName in pairs(equippedAttachments) do
        local attachment = ATTACHMENTS[attachmentName]
        if attachment and attachment.VisualEffects then
            self:applyAttachmentVisuals(weapon, attachment)
        end
    end
end

function ComprehensiveAttachmentSystem:applyAttachmentVisuals(weapon, attachment)
    -- Apply muzzle flash effects
    if attachment.VisualEffects.MuzzleFlashScale then
        local muzzleFlash = weapon:FindFirstChild("MuzzleFlash")
        if muzzleFlash then
            muzzleFlash.Size = muzzleFlash.Size * attachment.VisualEffects.MuzzleFlashScale
        end
    end
    
    -- Apply laser sight
    if attachment.VisualEffects.LaserColor and attachment.VisualEffects.LaserRange then
        self:createLaserSight(weapon, attachment.VisualEffects.LaserColor, attachment.VisualEffects.LaserRange)
    end
    
    -- Apply scope reticle
    if attachment.VisualEffects.Reticle then
        self:applyScopeReticle(weapon, attachment.VisualEffects.Reticle)
    end
end

function ComprehensiveAttachmentSystem:createLaserSight(weapon, laserColor, laserRange)
    local laser = weapon:FindFirstChild("LaserSight")
    if laser then laser:Destroy() end
    
    laser = Instance.new("Part")
    laser.Name = "LaserSight"
    laser.Size = Vector3.new(0.1, 0.1, laserRange)
    laser.Material = Enum.Material.Neon
    laser.Color = laserColor
    laser.CanCollide = false
    laser.Anchored = true
    laser.Parent = weapon
    
    -- Position laser
    local barrel = weapon:FindFirstChild("Barrel") or weapon:FindFirstChild("Handle")
    if barrel then
        laser.CFrame = barrel.CFrame * CFrame.new(0, -0.5, -laserRange/2)
    end
end

function ComprehensiveAttachmentSystem:applyScopeReticle(weapon, reticleImage)
    -- This would be implemented with GUI elements for scoped weapons
    print("[ComprehensiveAttachmentSystem] Applied scope reticle:", reticleImage)
end

function ComprehensiveAttachmentSystem:setupRemoteEvents()
    local remoteEvents = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    -- Create attachment remote events
    local equipAttachmentEvent = remoteEvents:FindFirstChild("EquipAttachment") or Instance.new("RemoteEvent")
    equipAttachmentEvent.Name = "EquipAttachment"
    equipAttachmentEvent.Parent = remoteEvents
    
    local unlockAttachmentEvent = remoteEvents:FindFirstChild("UnlockAttachment") or Instance.new("RemoteEvent")
    unlockAttachmentEvent.Name = "UnlockAttachment"
    unlockAttachmentEvent.Parent = remoteEvents
    
    -- Handle remote events
    if RunService:IsServer() then
        equipAttachmentEvent.OnServerEvent:Connect(function(player, weaponSlot, attachmentSlot, attachmentName)
            self:equipAttachment(player, weaponSlot, attachmentSlot, attachmentName)
        end)
        
        unlockAttachmentEvent.OnServerEvent:Connect(function(player, attachmentName)
            self:unlockAttachment(player, attachmentName)
        end)
    end
end

function ComprehensiveAttachmentSystem:getPlayerAttachmentData(player)
    return playerAttachments[player.UserId]
end

function ComprehensiveAttachmentSystem:savePlayerData(player)
    -- This would integrate with a data store system
    local playerData = playerAttachments[player.UserId]
    if playerData then
        print("[ComprehensiveAttachmentSystem] Saving attachment data for", player.Name)
        -- DataStore save logic would go here
    end
end

return ComprehensiveAttachmentSystem