-- Advanced Attachment System with Visual Effects and Real-Time Stat Changes
-- Place in ReplicatedStorage.FPSSystem.Modules.AdvancedAttachmentSystem
local AdvancedAttachmentSystem = {}
AdvancedAttachmentSystem.__index = AdvancedAttachmentSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modern Attachment Database with Visual Effects
local ATTACHMENT_DATABASE = {
    -- SIGHTS
    ["KOBRA_SIGHT"] = {
        name = "Kobra Sight",
        category = "SIGHT",
        type = "REFLEX",
        description = "Russian reflex sight with clear sight picture",
        statModifiers = {
            aimSpeed = 1.15,
            accuracy = 1.1,
            recoilControl = 1.05
        },
        visualEffects = {
            scopeOverlay = "rbxassetid://12345678",
            aimDownSightFOV = 70,
            enableDualRender = true
        },
        modelPath = "Assets/Attachments/Sights/Kobra",
        unlockRank = 15,
        cost = 125
    },

    ["ACOG_4X"] = {
        name = "ACOG 4x Scope",
        category = "SIGHT",
        type = "MAGNIFIED",
        description = "4x magnification tactical scope",
        statModifiers = {
            magnification = 4.0,
            aimSpeed = 0.85,
            accuracy = 1.3,
            recoilControl = 1.15
        },
        visualEffects = {
            scopeOverlay = "rbxassetid://12345679",
            aimDownSightFOV = 35,
            enableDualRender = true,
            scopeGlint = true
        },
        modelPath = "Assets/Attachments/Sights/ACOG",
        unlockRank = 35,
        cost = 250
    },

    -- BARRELS
    ["COMPENSATOR"] = {
        name = "Muzzle Compensator",
        category = "BARREL",
        type = "COMPENSATOR",
        description = "Reduces vertical recoil significantly",
        statModifiers = {
            verticalRecoil = 0.7,
            horizontalRecoil = 1.1,
            range = 1.05,
            loudness = 1.2
        },
        visualEffects = {
            muzzleFlashSize = 1.3,
            muzzleFlashColor = Color3.fromRGB(255, 150, 50),
            soundModifier = "compensator"
        },
        modelPath = "Assets/Attachments/Barrels/Compensator",
        unlockRank = 20,
        cost = 150
    },

    ["SUPPRESSOR"] = {
        name = "Suppressor",
        category = "BARREL",
        type = "SUPPRESSOR",
        description = "Reduces noise and muzzle flash",
        statModifiers = {
            loudness = 0.3,
            muzzleVelocity = 0.95,
            range = 0.9,
            damage = 0.95
        },
        visualEffects = {
            muzzleFlashSize = 0.2,
            hideMuzzleFlash = true,
            soundModifier = "suppressed",
            hideFromMinimap = true
        },
        modelPath = "Assets/Attachments/Barrels/Suppressor",
        unlockRank = 45,
        cost = 300
    },

    -- UNDERBARREL
    ["ANGLED_GRIP"] = {
        name = "Angled Grip",
        category = "UNDERBARREL",
        type = "GRIP",
        description = "Improves aim down sight speed",
        statModifiers = {
            aimSpeed = 1.25,
            recoilControl = 1.08,
            mobility = 1.05
        },
        visualEffects = {
            animationModifier = "angled_grip"
        },
        modelPath = "Assets/Attachments/Underbarrel/AngledGrip",
        unlockRank = 10,
        cost = 100
    },

    ["BIPOD"] = {
        name = "Bipod",
        category = "UNDERBARREL", 
        type = "BIPOD",
        description = "Deploy for extreme stability when prone",
        statModifiers = {
            proneRecoil = 0.4,
            proneAccuracy = 1.5,
            mobility = 0.9,
            aimSpeed = 0.95
        },
        visualEffects = {
            deployAnimation = true,
            proneEffects = true
        },
        modelPath = "Assets/Attachments/Underbarrel/Bipod",
        unlockRank = 50,
        cost = 200
    },

    -- LASER/LIGHT
    ["GREEN_LASER"] = {
        name = "Green Laser",
        category = "OTHER",
        type = "LASER",
        description = "Improves hip fire accuracy",
        statModifiers = {
            hipFireAccuracy = 1.3,
            aimSpeed = 1.1
        },
        visualEffects = {
            laserColor = Color3.fromRGB(0, 255, 0),
            laserVisible = true,
            enemyVisible = true
        },
        modelPath = "Assets/Attachments/Other/GreenLaser",
        unlockRank = 25,
        cost = 175
    },

    ["TACTICAL_LIGHT"] = {
        name = "Tactical Light",
        category = "OTHER",
        type = "LIGHT",
        description = "Illuminates dark areas and blinds enemies",
        statModifiers = {
            hipFireAccuracy = 1.15
        },
        visualEffects = {
            lightColor = Color3.fromRGB(255, 255, 200),
            lightBrightness = 2,
            lightRange = 50,
            blindingEffect = true
        },
        modelPath = "Assets/Attachments/Other/TacticalLight",
        unlockRank = 30,
        cost = 200
    }
}

function AdvancedAttachmentSystem.new()
    local self = setmetatable({}, AdvancedAttachmentSystem)

    -- References
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera

    -- Attachment state
    self.currentAttachments = {}
    self.attachmentModels = {}
    self.activeEffects = {}

    -- Visual effects
    self.scopeGui = nil
    self.laserBeams = {}
    self.lights = {}

    return self
end

-- Apply attachment to weapon with visual effects
function AdvancedAttachmentSystem:attachToWeapon(weaponModel, attachmentName, mountPoint)
    local attachment = ATTACHMENT_DATABASE[attachmentName]
    if not attachment then
        warn("Attachment not found: " .. attachmentName)
        return false
    end

    -- Remove existing attachment of same category
    self:removeAttachmentByCategory(weaponModel, attachment.category)

    -- Create and attach the visual model
    local attachmentModel = self:createAttachmentModel(attachment, weaponModel, mountPoint)
    if not attachmentModel then
        warn("Failed to create attachment model: " .. attachmentName)
        return false
    end

    -- Store attachment info
    self.currentAttachments[attachment.category] = {
        name = attachmentName,
        data = attachment,
        model = attachmentModel,
        mountPoint = mountPoint
    }

    -- Apply visual effects
    self:applyVisualEffects(attachment, weaponModel, attachmentModel)

    -- Apply stat modifiers to weapon
    self:applyStatModifiers(weaponModel, attachment.statModifiers)

    print("Attached " .. attachment.name .. " to weapon")
    return true
end

-- Create attachment 3D model
function AdvancedAttachmentSystem:createAttachmentModel(attachment, weaponModel, mountPoint)
    -- Try to load from assets
    local model = self:loadAttachmentModel(attachment.modelPath)

    if not model then
        -- Create procedural model if asset not found
        model = self:createProceduralAttachment(attachment)
    end

    if not model then
        return nil
    end

    -- Find mount point on weapon
    local mount = self:findMountPoint(weaponModel, mountPoint or attachment.category)
    if not mount then
        warn("Mount point not found for " .. attachment.category)
        return nil
    end

    -- Attach to weapon
    model.Parent = weaponModel

    -- Position at mount point
    if model.PrimaryPart then
        model:SetPrimaryPartCFrame(mount.WorldCFrame)
    end

    -- Create weld to weapon
    self:weldToWeapon(model, mount)

    return model
end

-- Load attachment model from assets
function AdvancedAttachmentSystem:loadAttachmentModel(modelPath)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return nil end

    local pathParts = modelPath:split("/")
    local current = fpsSystem

    for _, part in ipairs(pathParts) do
        current = current:FindFirstChild(part)
        if not current then return nil end
    end

    return current:IsA("Model") and current:Clone() or nil
end

-- Create procedural attachment if model not found
function AdvancedAttachmentSystem:createProceduralAttachment(attachment)
    local model = Instance.new("Model")
    model.Name = attachment.name

    local part = Instance.new("Part")
    part.Name = "AttachmentBody"
    part.Size = Vector3.new(0.2, 0.2, 0.5)
    part.Color = Color3.fromRGB(50, 50, 50)
    part.Material = Enum.Material.Metal
    part.CanCollide = false
    part.Parent = model

    model.PrimaryPart = part

    -- Add category-specific details
    if attachment.category == "SIGHT" then
        part.Size = Vector3.new(0.3, 0.3, 0.4)
        part.Color = Color3.fromRGB(20, 20, 20)

        -- Create lens
        local lens = Instance.new("Part")
        lens.Name = "Lens"
        lens.Size = Vector3.new(0.25, 0.25, 0.1)
        lens.Color = Color3.fromRGB(100, 150, 255)
        lens.Material = Enum.Material.Glass
        lens.Transparency = 0.3
        lens.CanCollide = false
        lens.CFrame = part.CFrame * CFrame.new(0, 0, -0.15)
        lens.Parent = model

    elseif attachment.category == "BARREL" then
        part.Size = Vector3.new(0.15, 0.15, 0.8)
        part.Shape = Enum.PartType.Cylinder

    elseif attachment.category == "UNDERBARREL" then
        part.Size = Vector3.new(0.2, 0.3, 0.6)
        part.Color = Color3.fromRGB(40, 40, 40)
    end

    return model
end

-- Find mount point on weapon
function AdvancedAttachmentSystem:findMountPoint(weaponModel, category)
    local mountNames = {
        SIGHT = {"SightMount", "TopRail", "OpticMount"},
        BARREL = {"BarrelMount", "MuzzlePoint", "BarrelEnd"},
        UNDERBARREL = {"UnderbarrelMount", "BottomRail", "ForeGrip"},
        OTHER = {"SideRail", "LaserMount", "LightMount"}
    }

    local names = mountNames[category] or {category .. "Mount"}

    for _, name in ipairs(names) do
        local mount = weaponModel:FindFirstChild(name, true)
        if mount then
            return mount
        end
    end

    -- Fallback to weapon center
    return weaponModel.PrimaryPart
end

-- Weld attachment to weapon
function AdvancedAttachmentSystem:weldToWeapon(attachmentModel, mountPoint)
    if not attachmentModel.PrimaryPart or not mountPoint then return end

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = mountPoint
    weld.Part1 = attachmentModel.PrimaryPart
    weld.Parent = attachmentModel.PrimaryPart
end

-- Apply visual effects
function AdvancedAttachmentSystem:applyVisualEffects(attachment, weaponModel, attachmentModel)
    local effects = attachment.visualEffects
    if not effects then return end

    -- Laser effects
    if effects.laserColor and effects.laserVisible then
        self:createLaserEffect(attachmentModel, effects.laserColor)
    end

    -- Light effects
    if effects.lightColor and effects.lightBrightness then
        self:createLightEffect(attachmentModel, effects.lightColor, effects.lightBrightness, effects.lightRange)
    end

    -- Scope effects
    if effects.scopeOverlay then
        self:setupScopeOverlay(effects.scopeOverlay, effects.aimDownSightFOV)
    end

    -- Muzzle flash modifications
    if effects.muzzleFlashSize or effects.muzzleFlashColor then
        self:modifyMuzzleFlash(weaponModel, effects)
    end
end

-- Create laser effect
function AdvancedAttachmentSystem:createLaserEffect(attachmentModel, color)
    local laserEmitter = attachmentModel:FindFirstChild("LaserEmitter") or attachmentModel.PrimaryPart
    if not laserEmitter then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "LaserStart"
    attachment.Parent = laserEmitter

    local beam = Instance.new("Beam")
    beam.Name = "LaserBeam"
    beam.Color = ColorSequence.new(color)
    beam.Transparency = NumberSequence.new(0.2)
    beam.Width0 = 0.02
    beam.Width1 = 0.02
    beam.FaceCamera = true
    beam.Attachment0 = attachment
    beam.Parent = attachment

    -- Create endpoint
    local endpoint = Instance.new("Attachment")
    endpoint.Name = "LaserEnd"
    endpoint.Parent = workspace.Terrain
    beam.Attachment1 = endpoint

    -- Update laser position
    local updateConnection
    updateConnection = RunService.Heartbeat:Connect(function()
        if not attachmentModel.Parent then
            updateConnection:Disconnect()
            endpoint:Destroy()
            return
        end

        -- Cast ray to find laser endpoint
        local rayOrigin = attachment.WorldPosition
        local rayDirection = attachment.WorldCFrame.LookVector * 1000

        local ModernRaycastSystem = require(script.Parent.ModernRaycastSystem)
        local raycastSystem = ModernRaycastSystem.new()
        local config = raycastSystem:createConfig()
        config:addToExcludeList({self.player.Character, attachmentModel})

        local result = raycastSystem:cast(rayOrigin, rayDirection, config)

        if result then
            endpoint.WorldPosition = result.Position
        else
            endpoint.WorldPosition = rayOrigin + rayDirection
        end
    end)

    table.insert(self.laserBeams, {beam = beam, connection = updateConnection})
end

-- Create light effect
function AdvancedAttachmentSystem:createLightEffect(attachmentModel, color, brightness, range)
    local lightEmitter = attachmentModel:FindFirstChild("LightEmitter") or attachmentModel.PrimaryPart
    if not lightEmitter then return end

    local spotLight = Instance.new("SpotLight")
    spotLight.Name = "TacticalLight"
    spotLight.Color = color
    spotLight.Brightness = brightness
    spotLight.Range = range or 50
    spotLight.Angle = 45
    spotLight.Face = Enum.NormalId.Front
    spotLight.Parent = lightEmitter

    table.insert(self.lights, spotLight)
end

-- Setup scope overlay
function AdvancedAttachmentSystem:setupScopeOverlay(overlayId, fov)
    -- Create scope GUI
    if self.scopeGui then
        self.scopeGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScopeOverlay"
    screenGui.DisplayOrder = 100
    screenGui.Parent = self.player.PlayerGui

    local scopeFrame = Instance.new("ImageLabel")
    scopeFrame.Name = "ScopeReticle"
    scopeFrame.Size = UDim2.new(1, 0, 1, 0)
    scopeFrame.Position = UDim2.new(0, 0, 0, 0)
    scopeFrame.BackgroundTransparency = 1
    scopeFrame.Image = overlayId
    scopeFrame.Visible = false
    scopeFrame.Parent = screenGui

    self.scopeGui = screenGui
    self.scopeFOV = fov
end

-- Apply stat modifiers to weapon
function AdvancedAttachmentSystem:applyStatModifiers(weaponModel, modifiers)
    if not modifiers then return end

    for stat, multiplier in pairs(modifiers) do
        local currentValue = weaponModel:GetAttribute(stat)
        if currentValue and type(currentValue) == "number" then
            weaponModel:SetAttribute(stat, currentValue * multiplier)
        end
    end
end

-- Remove attachment by category
function AdvancedAttachmentSystem:removeAttachmentByCategory(weaponModel, category)
    local currentAttachment = self.currentAttachments[category]
    if not currentAttachment then return end

    -- Remove visual model
    if currentAttachment.model then
        currentAttachment.model:Destroy()
    end

    -- Remove stat modifiers
    if currentAttachment.data.statModifiers then
        self:removeStatModifiers(weaponModel, currentAttachment.data.statModifiers)
    end

    -- Clean up effects
    self:cleanupAttachmentEffects(currentAttachment)

    self.currentAttachments[category] = nil
end

-- Remove stat modifiers
function AdvancedAttachmentSystem:removeStatModifiers(weaponModel, modifiers)
    for stat, multiplier in pairs(modifiers) do
        local currentValue = weaponModel:GetAttribute(stat)
        if currentValue and type(currentValue) == "number" then
            weaponModel:SetAttribute(stat, currentValue / multiplier)
        end
    end
end

-- Clean up attachment effects
function AdvancedAttachmentSystem:cleanupAttachmentEffects(attachment)
    -- Remove lasers
    for i = #self.laserBeams, 1, -1 do
        local laser = self.laserBeams[i]
        if laser.beam.Parent == attachment.model then
            laser.connection:Disconnect()
            laser.beam:Destroy()
            table.remove(self.laserBeams, i)
        end
    end

    -- Remove lights
    for i = #self.lights, 1, -1 do
        local light = self.lights[i]
        if light.Parent and light.Parent.Parent == attachment.model then
            light:Destroy()
            table.remove(self.lights, i)
        end
    end
end

-- Toggle scope overlay (for aiming)
function AdvancedAttachmentSystem:toggleScopeOverlay(isAiming)
    if self.scopeGui then
        local scopeFrame = self.scopeGui:FindFirstChild("ScopeReticle")
        if scopeFrame then
            scopeFrame.Visible = isAiming

            -- Adjust camera FOV
            if isAiming and self.scopeFOV then
                self.camera.FieldOfView = self.scopeFOV
            else
                self.camera.FieldOfView = 70 -- Default FOV
            end
        end
    end
end

-- Get attachment database
function AdvancedAttachmentSystem.getAttachmentDatabase()
    return ATTACHMENT_DATABASE
end

-- Get attachments by category
function AdvancedAttachmentSystem.getAttachmentsByCategory(category)
    local result = {}
    for name, data in pairs(ATTACHMENT_DATABASE) do
        if data.category == category then
            result[name] = data
        end
    end
    return result
end

-- Check if player has unlocked attachment
function AdvancedAttachmentSystem:isUnlocked(attachmentName, playerRank)
    local attachment = ATTACHMENT_DATABASE[attachmentName]
    if not attachment then return false end

    return (playerRank or 0) >= (attachment.unlockRank or 0)
end

-- Get total stat modifications for current attachments
function AdvancedAttachmentSystem:getTotalStatModifications()
    local totalMods = {}

    for category, attachment in pairs(self.currentAttachments) do
        if attachment.data.statModifiers then
            for stat, modifier in pairs(attachment.data.statModifiers) do
                if not totalMods[stat] then
                    totalMods[stat] = modifier
                else
                    totalMods[stat] = totalMods[stat] * modifier
                end
            end
        end
    end

    return totalMods
end

-- Cleanup
function AdvancedAttachmentSystem:cleanup()
    -- Clean up laser effects
    for _, laser in pairs(self.laserBeams) do
        if laser.connection then
            laser.connection:Disconnect()
        end
        if laser.beam then
            laser.beam:Destroy()
        end
    end

    -- Clean up lights
    for _, light in pairs(self.lights) do
        if light and light.Parent then
            light:Destroy()
        end
    end

    -- Clean up scope GUI
    if self.scopeGui then
        self.scopeGui:Destroy()
    end

    self.laserBeams = {}
    self.lights = {}
    self.currentAttachments = {}
end

return AdvancedAttachmentSystem