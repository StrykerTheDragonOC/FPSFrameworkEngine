-- WeaponAttachmentIntegration.lua
-- Complete integration of weapons, attachments, and scope systems
-- Place in ReplicatedStorage/FPSSystem/Modules/WeaponAttachmentIntegration.lua

local WeaponIntegration = {}
WeaponIntegration.__index = WeaponIntegration

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Get required systems
local AttachmentSystem = require(ReplicatedStorage.FPSSystem.Modules.AttachmentSystem)
local ScopeSystem = require(ReplicatedStorage.FPSSystem.Modules.EnhancedScopeSystem)

-- Constructor
function WeaponIntegration.new(fpsController)
    local self = setmetatable({}, WeaponIntegration)

    self.player = Players.LocalPlayer
    self.fpsController = fpsController
    self.currentWeapon = nil
    self.currentWeaponModel = nil
    self.isAiming = false

    -- Store base weapon configs for stat calculations
    self.baseWeaponConfigs = {}

    print("[WeaponIntegration] Integration system initialized")
    return self
end

-- Set current weapon
function WeaponIntegration:setWeapon(weaponName, weaponModel, weaponConfig)
    self.currentWeapon = weaponName
    self.currentWeaponModel = weaponModel

    -- Store base config
    if weaponConfig then
        self.baseWeaponConfigs[weaponName] = self:deepCopy(weaponConfig)
    end

    -- Update scope system
    if ScopeSystem then
        ScopeSystem:setWeapon(weaponModel)
    end

    print("[WeaponIntegration] Set weapon:", weaponName)
end

-- Get current weapon with attachment modifications
function WeaponIntegration:getCurrentWeaponConfig()
    if not self.currentWeapon or not self.currentWeaponModel then
        return nil
    end

    local baseConfig = self.baseWeaponConfigs[self.currentWeapon]
    if not baseConfig then
        -- Create default config if none exists
        baseConfig = self:createDefaultWeaponConfig(self.currentWeapon)
        self.baseWeaponConfigs[self.currentWeapon] = baseConfig
    end

    -- Apply attachment modifications
    if AttachmentSystem then
        return AttachmentSystem:applyAttachmentModifiers(baseConfig, self.currentWeaponModel)
    end

    return baseConfig
end

-- Create default weapon configuration
function WeaponIntegration:createDefaultWeaponConfig(weaponName)
    local weaponConfigs = {
        ["G36"] = {
            damage = 35,
            firerate = 750,
            range = 85,
            accuracy = 78,
            recoil = {
                vertical = 1.2,
                horizontal = 0.8,
                initial = 1.0
            },
            aimSpeed = 1.0,
            magazine = {
                capacity = 30,
                reloadTime = 2.5
            },
            mobility = {
                walkSpeed = 16,
                sprintSpeed = 20
            }
        },
        ["M4A1"] = {
            damage = 32,
            firerate = 780,
            range = 82,
            accuracy = 82,
            recoil = {
                vertical = 1.0,
                horizontal = 0.7,
                initial = 0.9
            },
            aimSpeed = 1.1,
            magazine = {
                capacity = 30,
                reloadTime = 2.3
            },
            mobility = {
                walkSpeed = 16,
                sprintSpeed = 20
            }
        },
        ["AK-47"] = {
            damage = 42,
            firerate = 600,
            range = 88,
            accuracy = 65,
            recoil = {
                vertical = 1.8,
                horizontal = 1.2,
                initial = 1.5
            },
            aimSpeed = 0.9,
            magazine = {
                capacity = 30,
                reloadTime = 2.8
            },
            mobility = {
                walkSpeed = 15,
                sprintSpeed = 19
            }
        },
        ["SCAR-H"] = {
            damage = 55,
            firerate = 620,
            range = 95,
            accuracy = 80,
            recoil = {
                vertical = 1.5,
                horizontal = 1.0,
                initial = 1.3
            },
            aimSpeed = 0.8,
            magazine = {
                capacity = 20,
                reloadTime = 3.0
            },
            mobility = {
                walkSpeed = 14,
                sprintSpeed = 18
            }
        }
    }

    return weaponConfigs[weaponName] or weaponConfigs["G36"] -- Default fallback
end

-- Handle aiming down sights
function WeaponIntegration:startAiming()
    if not self.currentWeaponModel or self.isAiming then return end

    self.isAiming = true

    -- Use scope system for aiming
    if ScopeSystem then
        ScopeSystem:scope(self.currentWeaponModel, true)
    end

    -- Apply ADS movement penalties
    if self.fpsController then
        local weaponConfig = self:getCurrentWeaponConfig()
        local adsMultiplier = 0.5 -- Base ADS movement penalty

        -- Apply scope-specific multipliers
        if ScopeSystem then
            adsMultiplier = adsMultiplier * ScopeSystem:getSensitivityMultiplier()
        end

        -- Reduce movement speed
        self.fpsController:setMovementMultiplier(adsMultiplier)
    end

    print("[WeaponIntegration] Started aiming")
end

-- Stop aiming down sights
function WeaponIntegration:stopAiming()
    if not self.isAiming then return end

    self.isAiming = false

    -- Exit scope mode
    if ScopeSystem then
        ScopeSystem:scope(self.currentWeaponModel, false)
    end

    -- Restore normal movement
    if self.fpsController then
        self.fpsController:setMovementMultiplier(1.0)
    end

    print("[WeaponIntegration] Stopped aiming")
end

-- Handle weapon firing with attachment effects
function WeaponIntegration:fireWeapon()
    if not self.currentWeaponModel then return false end

    local weaponConfig = self:getCurrentWeaponConfig()
    if not weaponConfig then return false end

    -- Apply recoil based on modified config
    self:applyRecoil(weaponConfig)

    -- Handle muzzle flash (affected by attachments)
    self:handleMuzzleEffects(weaponConfig)

    -- Update ammo count
    self:updateAmmoCount(weaponConfig)

    return true
end

-- Apply recoil with attachment modifications
function WeaponIntegration:applyRecoil(weaponConfig)
    if not self.fpsController or not weaponConfig.recoil then return end

    local recoilMultiplier = self.isAiming and 0.7 or 1.0 -- Less recoil when aiming

    -- Apply scope-specific recoil reduction
    if self.isAiming and ScopeSystem then
        local mag = ScopeSystem:getCurrentMagnification()
        if mag > 1 then
            recoilMultiplier = recoilMultiplier * (1 - (mag - 1) * 0.1) -- More magnification = more recoil reduction
        end
    end

    local verticalRecoil = (weaponConfig.recoil.vertical or 1.0) * recoilMultiplier
    local horizontalRecoil = (weaponConfig.recoil.horizontal or 1.0) * recoilMultiplier

    -- Apply recoil to camera (this would connect to your FPS camera system)
    if self.fpsController.addRecoil then
        self.fpsController:addRecoil(verticalRecoil, horizontalRecoil)
    end
end

-- Handle muzzle effects (flash, sound) with attachment modifications
function WeaponIntegration:handleMuzzleEffects(weaponConfig)
    if not self.currentWeaponModel then return end

    -- Muzzle flash intensity (affected by attachments like suppressors)
    local flashIntensity = weaponConfig.muzzleFlash or 1.0
    local soundIntensity = weaponConfig.sound or 1.0

    -- Find muzzle point
    local muzzlePoint = self.currentWeaponModel:FindFirstChild("Muzzle", true) or 
        self.currentWeaponModel:FindFirstChild("Barrel", true)

    if muzzlePoint and flashIntensity > 0.1 then
        self:createMuzzleFlash(muzzlePoint, flashIntensity)
    end

    -- Play firing sound with volume based on suppressor
    if soundIntensity > 0.1 then
        self:playFireSound(soundIntensity)
    end
end

-- Create muzzle flash effect
function WeaponIntegration:createMuzzleFlash(muzzlePoint, intensity)
    local flash = Instance.new("PointLight")
    flash.Brightness = 10 * intensity
    flash.Range = 15 * intensity
    flash.Color = Color3.fromRGB(255, 200, 100)
    flash.Parent = muzzlePoint

    -- Flash particle effect
    local attachment = Instance.new("Attachment")
    attachment.Parent = muzzlePoint

    local particle = Instance.new("ParticleEmitter")
    particle.Texture = "rbxasset://textures/particles/fire_main.dds"
    particle.Rate = 0
    particle.Lifetime = NumberRange.new(0.1, 0.2)
    particle.Speed = NumberRange.new(10, 20)
    particle.Parent = attachment
    particle:Emit(math.floor(20 * intensity))

    -- Clean up after brief moment
    game:GetService("Debris"):AddItem(flash, 0.1)
    game:GetService("Debris"):AddItem(attachment, 1)
end

-- Play firing sound
function WeaponIntegration:playFireSound(intensity)
    if not self.currentWeaponModel then return end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://131961136" -- Replace with actual fire sound
    sound.Volume = 0.8 * intensity
    sound.Pitch = math.random(95, 105) / 100 -- Slight pitch variation
    sound.Parent = self.currentWeaponModel
    sound:Play()

    game:GetService("Debris"):AddItem(sound, 2)
end

-- Update ammo count
function WeaponIntegration:updateAmmoCount(weaponConfig)
    -- This would integrate with your ammo system
    if self.fpsController and self.fpsController.updateAmmo then
        self.fpsController:updateAmmo(-1) -- Subtract one bullet
    end
end

-- Equip attachment to current weapon
function WeaponIntegration:equipAttachment(attachmentName)
    if not self.currentWeaponModel or not AttachmentSystem then 
        return false 
    end

    local success = AttachmentSystem:attachAttachment(self.currentWeaponModel, attachmentName)

    if success then
        -- Update weapon stats
        self:updateWeaponStats()

        -- If it's a sight attachment and we're aiming, update scope
        local attachment = AttachmentSystem:getAttachment(attachmentName)
        if attachment and attachment.type == "SIGHT" and self.isAiming then
            self:stopAiming()
            task.wait(0.1)
            self:startAiming()
        end

        print("[WeaponIntegration] Equipped attachment:", attachmentName)
    end

    return success
end

-- Remove attachment from current weapon
function WeaponIntegration:removeAttachment(attachmentType)
    if not self.currentWeaponModel or not AttachmentSystem then 
        return false 
    end

    local success = AttachmentSystem:removeAttachment(self.currentWeaponModel, attachmentType)

    if success then
        -- Update weapon stats
        self:updateWeaponStats()

        -- If it was a sight attachment and we're aiming, update scope
        if attachmentType == "SIGHT" and self.isAiming then
            self:stopAiming()
            task.wait(0.1)
            self:startAiming()
        end

        print("[WeaponIntegration] Removed attachment type:", attachmentType)
    end

    return success
end

-- Update weapon stats display
function WeaponIntegration:updateWeaponStats()
    local weaponConfig = self:getCurrentWeaponConfig()
    if not weaponConfig then return end

    -- This would update your weapon stats UI
    if self.fpsController and self.fpsController.updateWeaponStats then
        self.fpsController:updateWeaponStats(weaponConfig)
    end
end

-- Get available attachments for current weapon
function WeaponIntegration:getAvailableAttachments()
    if not self.currentWeapon or not AttachmentSystem then
        return {}
    end

    return AttachmentSystem:getAvailableAttachments(self.currentWeapon)
end

-- Get currently equipped attachments
function WeaponIntegration:getEquippedAttachments()
    if not self.currentWeaponModel or not AttachmentSystem then
        return {}
    end

    local equipped = {}
    local attachmentTypes = {"SIGHT", "BARREL", "UNDERBARREL", "OTHER"}

    for _, attachmentType in ipairs(attachmentTypes) do
        local attachment = AttachmentSystem:getActiveAttachment(self.currentWeaponModel, attachmentType)
        if attachment then
            equipped[attachmentType] = attachment.name
        end
    end

    return equipped
end

-- Handle input for weapon and attachment controls
function WeaponIntegration:handleInput(input, gameProcessed)
    if gameProcessed then return end

    -- Right mouse button for aiming
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if input.UserInputState == Enum.UserInputState.Begin then
            self:startAiming()
        elseif input.UserInputState == Enum.UserInputState.End then
            self:stopAiming()
        end
    end

    -- Left mouse button for firing
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if input.UserInputState == Enum.UserInputState.Begin then
            self:fireWeapon()
        end
    end

    -- T key to open attachment menu (if available)
    if input.KeyCode == Enum.KeyCode.T and input.UserInputState == Enum.UserInputState.Begin then
        if _G.AttachmentTester and _G.AttachmentTester.gui then
            _G.AttachmentTester.gui.Enabled = not _G.AttachmentTester.gui.Enabled
        end
    end
end

-- Update function (call from main game loop)
function WeaponIntegration:update(deltaTime)
    -- Update scope system
    if ScopeSystem then
        ScopeSystem:update(deltaTime)
    end

    -- Update any other systems here
end

-- Deep copy utility function
function WeaponIntegration:deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:deepCopy(orig_key)] = self:deepCopy(orig_value)
        end
        setmetatable(copy, self:deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Cleanup
function WeaponIntegration:cleanup()
    -- Stop aiming if currently aiming
    if self.isAiming then
        self:stopAiming()
    end

    -- Clear current weapon
    self.currentWeapon = nil
    self.currentWeaponModel = nil

    print("[WeaponIntegration] Cleaned up")
end

-- Example usage and setup function
function WeaponIntegration.setupExampleWeapon()
    -- This shows how to integrate everything together
    local integration = WeaponIntegration.new()

    -- Create a test weapon
    local tool = Instance.new("Tool")
    tool.Name = "G36"
    tool.RequiresHandle = true

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.3, 0.3, 2)
    handle.Material = Enum.Material.Metal
    handle.Color = Color3.fromRGB(60, 60, 60)
    handle.Parent = tool

    -- Add attachment points
    local attachmentPoints = {
        {name = "Optic", type = "Attachment", cframe = CFrame.new(0, 0.2, -0.5)},
        {name = "Barrel", type = "Attachment", cframe = CFrame.new(0, 0, -1)},
        {name = "Muzzle", type = "Attachment", cframe = CFrame.new(0, 0, -1)},
        {name = "Underbarrel", type = "Attachment", cframe = CFrame.new(0, -0.15, -0.3)},
        {name = "Stock", type = "Attachment", cframe = CFrame.new(0, 0, 0.8)}
    }

    for _, point in ipairs(attachmentPoints) do
        local attachment = Instance.new("Attachment")
        attachment.Name = point.name
        attachment.CFrame = point.cframe
        attachment.Parent = handle
    end

    tool.PrimaryPart = handle

    -- Set up the weapon in integration system
    integration:setWeapon("G36", tool, nil)

    -- Equip tool
    tool.Parent = Players.LocalPlayer.Backpack
    Players.LocalPlayer.Character.Humanoid:EquipTool(tool)

    -- Setup input handling
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        integration:handleInput(input, gameProcessed)
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        integration:handleInput(input, gameProcessed)
    end)

    -- Setup update loop
    RunService.RenderStepped:Connect(function(deltaTime)
        integration:update(deltaTime)
    end)

    print("Example weapon setup complete! Right-click to aim, left-click to fire, T for attachments")
    return integration
end

-- Global access
_G.WeaponIntegration = WeaponIntegration
_G.setupExampleWeapon = WeaponIntegration.setupExampleWeapon

return WeaponIntegration