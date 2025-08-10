-- GrenadeSystem.lua  
-- Fixed grenade system with proper deployment mechanics and anti-spam
-- Renamed from AdvancedGrenadeSystem
-- Place in ReplicatedStorage/FPSSystem/Modules

local GrenadeSystem = {}
GrenadeSystem.__index = GrenadeSystem

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Grenade system settings
local GRENADE_SETTINGS = {
    -- Throw mechanics
    MIN_FORCE = 25,                      -- Minimum throw force
    MAX_FORCE = 80,                      -- Maximum throw force
    CHARGE_TIME = 1.5,                   -- Time to reach max force
    COOK_TIME = 4.0,                     -- Fuse time for cooking

    -- Anti-spam settings
    COOLDOWN_TIME = 0.5,                 -- Minimum time between grenade actions
    DEPLOY_DELAY = 0.3,                  -- Delay before grenade can be used after equipping

    -- Physics
    GRAVITY_MULTIPLIER = 1.2,            -- Custom gravity for grenades
    BOUNCE_DAMPING = 0.7,                -- Energy loss on bounce
    ANGULAR_VELOCITY = 15,               -- Spin rate

    -- Safety
    MAX_GRENADES_PER_PLAYER = 3,         -- Maximum active grenades per player
    MENU_PROTECTION = true,              -- Prevent grenade usage in menu
}

-- Grenade types configuration
local GRENADE_TYPES = {
    ["M67"] = {
        name = "M67 Fragmentation",
        displayName = "M67 Frag Grenade",
        cookTime = 4.0,
        explosionRadius = 15,
        damage = 100,
        force = 50,
        weight = 0.4,
        maxCount = 3,
        sounds = {
            pin = "rbxassetid://8186569638",
            throw = "rbxassetid://8186570431", 
            bounce = "rbxassetid://142082167",
            explosion = "rbxassetid://2814355743"
        }
    },

    ["M67 FRAG"] = { -- Alias for compatibility
        name = "M67 Fragmentation",
        displayName = "M67 Frag Grenade", 
        cookTime = 4.0,
        explosionRadius = 15,
        damage = 100,
        force = 50,
        weight = 0.4,
        maxCount = 3,
        sounds = {
            pin = "rbxassetid://8186569638",
            throw = "rbxassetid://8186570431",
            bounce = "rbxassetid://142082167", 
            explosion = "rbxassetid://2814355743"
        }
    },

    ["Flashbang"] = {
        name = "M84 Flashbang",
        displayName = "M84 Stun Grenade",
        cookTime = 2.0,
        explosionRadius = 20,
        damage = 0,
        force = 35,
        weight = 0.3,
        maxCount = 2,
        effects = {
            flash = true,
            blind = true,
            deafen = true
        },
        sounds = {
            pin = "rbxassetid://8186569638",
            throw = "rbxassetid://8186570431",
            bounce = "rbxassetid://142082167",
            explosion = "rbxassetid://131961136"
        }
    },

    ["Smoke"] = {
        name = "M18 Smoke",
        displayName = "M18 Smoke Grenade",
        cookTime = 1.5,
        explosionRadius = 25,
        damage = 0,
        force = 30,
        weight = 0.35,
        maxCount = 4,
        effects = {
            smoke = true,
            duration = 30
        },
        sounds = {
            pin = "rbxassetid://8186569638",
            throw = "rbxassetid://8186570431",
            bounce = "rbxassetid://142082167",
            explosion = "rbxassetid://131961136"
        }
    }
}

function GrenadeSystem.new()
    local self = setmetatable({}, GrenadeSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
    self.camera = workspace.CurrentCamera

    -- Grenade state
    self.grenadeType = "M67"
    self.grenadeConfig = GRENADE_TYPES["M67"]
    self.isEquipped = false
    self.isDeployed = false

    -- Throw state
    self.isCooking = false
    self.isCharging = false
    self.isPinPulled = false
    self.throwForce = GRENADE_SETTINGS.MIN_FORCE
    self.cookStartTime = 0
    self.chargeStartTime = 0

    -- Anti-spam protection
    self.lastGrenadeTime = 0
    self.equipTime = 0
    self.activeGrenades = {}

    -- Return slot for quick grenade
    self.returnSlot = nil

    -- Connections
    self.connections = {}

    -- UI elements
    self.grenadeUI = nil

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the grenade system
function GrenadeSystem:initialize()
    print("[GrenadeSystem] Initializing grenade system...")

    -- Wait for character
    self:waitForCharacter()

    -- Setup input handling (only when equipped)
    self:setupInputHandling()

    print("[GrenadeSystem] Grenade system initialized")
end

-- Wait for character spawn
function GrenadeSystem:waitForCharacter()
    if self.player.Character then
        self:onCharacterSpawned(self.player.Character)
    end

    self.connections.characterAdded = self.player.CharacterAdded:Connect(function(character)
        self:onCharacterSpawned(character)
    end)
end

-- Handle character spawning
function GrenadeSystem:onCharacterSpawned(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid")
    self.rootPart = character:WaitForChild("HumanoidRootPart")

    -- Reset grenade state on spawn
    self:reset()

    print("[GrenadeSystem] Character spawned, grenade system ready")
end

-- Set grenade type and configuration
function GrenadeSystem:setGrenadeType(grenadeType, config)
    self.grenadeType = grenadeType

    -- Use provided config or default from GRENADE_TYPES
    if config then
        self.grenadeConfig = config
    else
        self.grenadeConfig = GRENADE_TYPES[grenadeType] or GRENADE_TYPES["M67"]
    end

    print("[GrenadeSystem] Set grenade type:", grenadeType)
end

-- Equip grenade (makes it ready to use)
function GrenadeSystem:equip()
    if not self.isDeployed then
        warn("[GrenadeSystem] Cannot equip grenade - not deployed")
        return false
    end

    if self.isEquipped then
        print("[GrenadeSystem] Grenade already equipped")
        return true
    end

    self.isEquipped = true
    self.equipTime = tick()

    -- Create grenade UI
    self:createGrenadeUI()

    -- Play equip sound
    self:playSound(self.grenadeConfig.sounds.pin, 0.3)

    print("[GrenadeSystem] Grenade equipped:", self.grenadeType)
    return true
end

-- Unequip grenade
function GrenadeSystem:unequip()
    if not self.isEquipped then return end

    -- Stop any active grenade actions
    self:stopCooking()
    self:stopCharging()

    self.isEquipped = false

    -- Destroy grenade UI
    self:destroyGrenadeUI()

    print("[GrenadeSystem] Grenade unequipped")
end

-- Setup input handling for grenades
function GrenadeSystem:setupInputHandling()
    -- Mouse button handling for grenades
    self.connections.mouseDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self:canUseGrenade() then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:startCooking()
        end
    end)

    self.connections.mouseUp = UserInputService.InputEnded:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:throwGrenade()
        end
    end)

    -- G key for quick grenade throw
    self.connections.quickGrenade = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self:canUseGrenade() then return end

        if input.KeyCode == Enum.KeyCode.G and self.isEquipped then
            self:quickThrow()
        end
    end)
end

-- Check if grenade can be used (anti-spam and safety checks)
function GrenadeSystem:canUseGrenade()
    -- Check if equipped and deployed
    if not self.isEquipped or not self.isDeployed then
        return false
    end

    -- Check deploy delay
    if tick() - self.equipTime < GRENADE_SETTINGS.DEPLOY_DELAY then
        return false
    end

    -- Check cooldown
    if tick() - self.lastGrenadeTime < GRENADE_SETTINGS.COOLDOWN_TIME then
        return false
    end

    -- Check menu protection
    if GRENADE_SETTINGS.MENU_PROTECTION then
        -- Check if player is in a menu state
        if _G.MainMenuSystem and _G.MainMenuSystem.isInMenu then
            warn("[GrenadeSystem] Cannot use grenades while in menu")
            return false
        end
    end

    -- Check max grenades limit
    if #self.activeGrenades >= GRENADE_SETTINGS.MAX_GRENADES_PER_PLAYER then
        warn("[GrenadeSystem] Maximum grenades limit reached")
        return false
    end

    return true
end

-- Start cooking grenade (pull pin, start fuse)
function GrenadeSystem:startCooking()
    if self.isCooking then return end

    if not self:canUseGrenade() then
        return
    end

    print("[GrenadeSystem] Started cooking grenade")

    self.isCooking = true
    self.isPinPulled = true
    self.cookStartTime = tick()

    -- Play pin pull sound
    self:playSound(self.grenadeConfig.sounds.pin, 0.8)

    -- Start charge buildup
    self:startCharging()

    -- Create cook timer (auto-explode if held too long)
    self.connections.cookTimer = task.delay(self.grenadeConfig.cookTime, function()
        if self.isCooking then
            warn("[GrenadeSystem] Grenade cooked too long - auto throwing!")
            self:throwGrenade()
        end
    end)

    -- Update UI
    self:updateGrenadeUI()
end

-- Start charging throw force
function GrenadeSystem:startCharging()
    if self.isCharging then return end

    self.isCharging = true
    self.chargeStartTime = tick()
    self.throwForce = GRENADE_SETTINGS.MIN_FORCE

    -- Charge buildup over time
    self.connections.chargeLoop = RunService.Heartbeat:Connect(function()
        if not self.isCharging then return end

        local chargeTime = tick() - self.chargeStartTime
        local chargeProgress = math.min(chargeTime / GRENADE_SETTINGS.CHARGE_TIME, 1)

        -- Calculate throw force
        self.throwForce = GRENADE_SETTINGS.MIN_FORCE + 
            (GRENADE_SETTINGS.MAX_FORCE - GRENADE_SETTINGS.MIN_FORCE) * chargeProgress

        -- Update UI
        self:updateGrenadeUI()
    end)
end

-- Stop cooking (if cancelled)
function GrenadeSystem:stopCooking()
    if not self.isCooking then return end

    self.isCooking = false
    self.isPinPulled = false

    -- Disconnect cook timer
    if self.connections.cookTimer then
        task.cancel(self.connections.cookTimer)
        self.connections.cookTimer = nil
    end

    self:stopCharging()

    print("[GrenadeSystem] Stopped cooking grenade")
end

-- Stop charging
function GrenadeSystem:stopCharging()
    if not self.isCharging then return end

    self.isCharging = false

    if self.connections.chargeLoop then
        self.connections.chargeLoop:Disconnect()
        self.connections.chargeLoop = nil
    end
end

-- Throw grenade
function GrenadeSystem:throwGrenade()
    if not self.isCooking then return end

    print("[GrenadeSystem] Throwing grenade with force:", self.throwForce)

    -- Stop cooking and charging
    self:stopCooking()

    -- Calculate throw parameters
    local throwDirection = self:calculateThrowDirection()
    local cookTime = tick() - self.cookStartTime

    -- Create and launch physical grenade
    local grenade = self:createPhysicalGrenade(cookTime)
    if grenade then
        self:launchGrenade(grenade, throwDirection, self.throwForce)

        -- Track active grenade
        table.insert(self.activeGrenades, grenade)
    end

    -- Play throw sound
    self:playSound(self.grenadeConfig.sounds.throw, 0.9)

    -- Update cooldown
    self.lastGrenadeTime = tick()

    -- Auto-switch back if using quick grenade
    if self.returnSlot then
        task.delay(0.5, function()
            if _G.EnhancedWeaponSystem then
                _G.EnhancedWeaponSystem:equipWeapon(self.returnSlot)
            end
            self.returnSlot = nil
        end)
    end

    -- Reset throw force
    self.throwForce = GRENADE_SETTINGS.MIN_FORCE

    -- Update UI
    self:updateGrenadeUI()
end

-- Quick throw (G key) - instant throw without cooking
function GrenadeSystem:quickThrow()
    if not self:canUseGrenade() then return end

    print("[GrenadeSystem] Quick throwing grenade")

    -- Set quick throw parameters
    self.throwForce = GRENADE_SETTINGS.MAX_FORCE * 0.7 -- 70% force for quick throw
    local throwDirection = self:calculateThrowDirection()

    -- Create and launch grenade immediately
    local grenade = self:createPhysicalGrenade(0) -- No cook time
    if grenade then
        self:launchGrenade(grenade, throwDirection, self.throwForce)

        -- Track active grenade
        table.insert(self.activeGrenades, grenade)
    end

    -- Play throw sound
    self:playSound(self.grenadeConfig.sounds.throw, 0.9)

    -- Update cooldown
    self.lastGrenadeTime = tick()

    -- Auto-switch back
    if self.returnSlot then
        task.delay(0.3, function()
            if _G.EnhancedWeaponSystem then
                _G.EnhancedWeaponSystem:equipWeapon(self.returnSlot)
            end
            self.returnSlot = nil
        end)
    end
end

-- Calculate throw direction
function GrenadeSystem:calculateThrowDirection()
    local camera = self.camera
    local direction = camera.CFrame.LookVector

    -- Add slight upward arc for better trajectory
    local arcAngle = math.rad(15) -- 15 degree upward arc
    local rightVector = camera.CFrame.RightVector
    local upVector = camera.CFrame.UpVector

    -- Apply arc
    direction = (direction * math.cos(arcAngle) + upVector * math.sin(arcAngle)).Unit

    return direction
end

-- Create physical grenade object
function GrenadeSystem:createPhysicalGrenade(cookTime)
    -- Create grenade part
    local grenade = Instance.new("Part")
    grenade.Name = "Grenade_" .. self.grenadeType:gsub(" ", "_")
    grenade.Size = Vector3.new(0.5, 0.8, 0.5)
    grenade.Shape = Enum.PartType.Cylinder
    grenade.Material = Enum.Material.Metal
    grenade.Color = Color3.fromRGB(60, 80, 50)
    grenade.CanCollide = true
    grenade.TopSurface = Enum.SurfaceType.Smooth
    grenade.BottomSurface = Enum.SurfaceType.Smooth

    -- Set initial position (in front of player)
    local spawnPosition = self.rootPart.Position + self.camera.CFrame.LookVector * 2
    grenade.Position = spawnPosition
    grenade.Parent = workspace

    -- Add BodyVelocity for physics
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = grenade

    -- Add BodyAngularVelocity for spin
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, GRENADE_SETTINGS.ANGULAR_VELOCITY, 0)
    bodyAngularVelocity.Parent = grenade

    -- Store grenade data
    local grenadeData = {
        type = self.grenadeType,
        config = self.grenadeConfig,
        cookTime = cookTime,
        throwTime = tick(),
        thrower = self.player
    }

    -- Store data in grenade
    local objectValue = Instance.new("ObjectValue")
    objectValue.Name = "GrenadeData"
    objectValue.Value = self.player
    objectValue.Parent = grenade

    local stringValue = Instance.new("StringValue")
    stringValue.Name = "GrenadeType"
    stringValue.Value = self.grenadeType
    stringValue.Parent = grenade

    local numberValue = Instance.new("NumberValue")
    numberValue.Name = "CookTime" 
    numberValue.Value = cookTime
    numberValue.Parent = grenade

    -- Setup explosion timer
    local fuseTime = self.grenadeConfig.cookTime - cookTime
    task.delay(fuseTime, function()
        if grenade.Parent then
            self:explodeGrenade(grenade)
        end
    end)

    -- Bounce sound handling
    local lastBounceTime = 0
    grenade.Touched:Connect(function(hit)
        if hit.Parent == self.character then return end

        local currentTime = tick()
        if currentTime - lastBounceTime > 0.2 then -- Prevent spam
            lastBounceTime = currentTime
            self:playSound(self.grenadeConfig.sounds.bounce, 0.5)

            -- Apply bounce damping
            if bodyVelocity then
                bodyVelocity.Velocity = bodyVelocity.Velocity * GRENADE_SETTINGS.BOUNCE_DAMPING
            end
        end
    end)

    return grenade
end

-- Launch grenade with physics
function GrenadeSystem:launchGrenade(grenade, direction, force)
    local bodyVelocity = grenade:FindFirstChild("BodyVelocity")
    if not bodyVelocity then return end

    -- Calculate velocity based on force and direction
    local velocity = direction * force

    -- Apply gravity compensation
    velocity = velocity + Vector3.new(0, force * 0.3, 0)

    bodyVelocity.Velocity = velocity

    -- Remove body velocity after initial throw
    task.delay(0.1, function()
        if bodyVelocity then
            bodyVelocity:Destroy()
        end
    end)

    print("[GrenadeSystem] Launched grenade with velocity:", velocity)
end

-- Explode grenade
function GrenadeSystem:explodeGrenade(grenade)
    if not grenade or not grenade.Parent then return end

    local position = grenade.Position
    local grenadeType = grenade:FindFirstChild("GrenadeType")
    local config = self.grenadeConfig

    if grenadeType then
        config = GRENADE_TYPES[grenadeType.Value] or self.grenadeConfig
    end

    print("[GrenadeSystem] Exploding grenade at:", position)

    -- Create explosion effects
    self:createExplosionEffects(position, config)

    -- Play explosion sound
    self:playSound(config.sounds.explosion, 1.0)

    -- Send explosion to server for damage
    local remoteEvent = ReplicatedStorage:FindFirstChild("GrenadeExplosion")
    if remoteEvent then
        remoteEvent:FireServer(position, config.damage, config.explosionRadius, self.grenadeType)
    end

    -- Remove from active grenades list
    for i, activeGrenade in ipairs(self.activeGrenades) do
        if activeGrenade == grenade then
            table.remove(self.activeGrenades, i)
            break
        end
    end

    -- Destroy grenade
    grenade:Destroy()
end

-- Create explosion visual effects
function GrenadeSystem:createExplosionEffects(position, config)
    -- Create explosion part
    local explosion = Instance.new("Part")
    explosion.Name = "GrenadeExplosion"
    explosion.Size = Vector3.new(1, 1, 1)
    explosion.Position = position
    explosion.Anchored = true
    explosion.CanCollide = false
    explosion.Transparency = 1
    explosion.Parent = workspace

    -- Create explosion light
    local light = Instance.new("PointLight")
    light.Brightness = 5
    light.Range = config.explosionRadius * 2
    light.Color = Color3.fromRGB(255, 200, 100)
    light.Parent = explosion

    -- Flash effect
    local flash = Instance.new("Explosion")
    flash.Position = position
    flash.BlastRadius = config.explosionRadius
    flash.BlastPressure = 0 -- No physics, just visual
    flash.Parent = workspace

    -- Camera shake for nearby players
    if (position - self.camera.CFrame.Position).Magnitude < 50 then
        self:createCameraShake(position)
    end

    -- Cleanup explosion part
    task.delay(2, function()
        if explosion then
            explosion:Destroy()
        end
    end)
end

-- Create camera shake effect
function GrenadeSystem:createCameraShake(explosionPosition)
    local distance = (explosionPosition - self.camera.CFrame.Position).Magnitude
    local intensity = math.max(0, 1 - (distance / 30)) -- Shake intensity based on distance

    if intensity <= 0 then return end

    -- Simple camera shake
    local originalCFrame = self.camera.CFrame
    local shakeIntensity = intensity * 2

    for i = 1, 10 do
        task.delay(i * 0.05, function()
            if self.camera then
                local randomOffset = Vector3.new(
                    (math.random() - 0.5) * shakeIntensity,
                    (math.random() - 0.5) * shakeIntensity,
                    (math.random() - 0.5) * shakeIntensity
                )
                self.camera.CFrame = self.camera.CFrame + randomOffset
            end
        end)
    end
end

-- Create grenade UI
function GrenadeSystem:createGrenadeUI()
    if self.grenadeUI then
        self.grenadeUI:Destroy()
    end

    local playerGui = self.player:WaitForChild("PlayerGui")

    -- Create main UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GrenadeUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    self.grenadeUI = screenGui

    -- Grenade indicator frame
    local frame = Instance.new("Frame")
    frame.Name = "GrenadeFrame"
    frame.Size = UDim2.new(0.15, 0, 0.08, 0)
    frame.Position = UDim2.new(0.425, 0, 0.85, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    -- Grenade type label
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Name = "TypeLabel"
    typeLabel.Size = UDim2.new(1, 0, 0.4, 0)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = self.grenadeConfig.displayName or self.grenadeType
    typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    typeLabel.TextScaled = true
    typeLabel.Font = Enum.Font.SourceSansBold
    typeLabel.Parent = frame

    -- Force indicator bar
    local forceBarBg = Instance.new("Frame")
    forceBarBg.Name = "ForceBarBackground"
    forceBarBg.Size = UDim2.new(0.9, 0, 0.15, 0)
    forceBarBg.Position = UDim2.new(0.05, 0, 0.45, 0)
    forceBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    forceBarBg.BorderSizePixel = 0
    forceBarBg.Parent = frame

    local forceBar = Instance.new("Frame")
    forceBar.Name = "ForceBar"
    forceBar.Size = UDim2.new(0, 0, 1, 0)
    forceBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    forceBar.BorderSizePixel = 0
    forceBar.Parent = forceBarBg

    -- Cook timer indicator
    local cookBarBg = Instance.new("Frame")
    cookBarBg.Name = "CookBarBackground"
    cookBarBg.Size = UDim2.new(0.9, 0, 0.15, 0)
    cookBarBg.Position = UDim2.new(0.05, 0, 0.7, 0)
    cookBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    cookBarBg.BorderSizePixel = 0
    cookBarBg.Parent = frame

    local cookBar = Instance.new("Frame")
    cookBar.Name = "CookBar"
    cookBar.Size = UDim2.new(0, 0, 1, 0)
    cookBar.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    cookBar.BorderSizePixel = 0
    cookBar.Parent = cookBarBg

    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, 0, 0.2, 0)
    instructions.Position = UDim2.new(0, 0, 0.8, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Hold to cook • G for quick throw"
    instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.SourceSans
    instructions.Parent = frame
end

-- Update grenade UI
function GrenadeSystem:updateGrenadeUI()
    if not self.grenadeUI then return end

    local frame = self.grenadeUI:FindFirstChild("GrenadeFrame")
    if not frame then return end

    -- Update force bar
    local forceBar = frame:FindFirstChild("ForceBarBackground"):FindFirstChild("ForceBar")
    if forceBar then
        local forcePercent = (self.throwForce - GRENADE_SETTINGS.MIN_FORCE) / 
            (GRENADE_SETTINGS.MAX_FORCE - GRENADE_SETTINGS.MIN_FORCE)
        forceBar.Size = UDim2.new(forcePercent, 0, 1, 0)
    end

    -- Update cook bar
    local cookBar = frame:FindFirstChild("CookBarBackground"):FindFirstChild("CookBar")
    if cookBar and self.isCooking then
        local cookPercent = (tick() - self.cookStartTime) / self.grenadeConfig.cookTime
        cookBar.Size = UDim2.new(cookPercent, 0, 1, 0)

        -- Change color based on danger level
        if cookPercent > 0.8 then
            cookBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red danger
        elseif cookPercent > 0.6 then
            cookBar.BackgroundColor3 = Color3.fromRGB(255, 100, 0) -- Orange warning
        else
            cookBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Yellow safe
        end
    end
end

-- Destroy grenade UI
function GrenadeSystem:destroyGrenadeUI()
    if self.grenadeUI then
        self.grenadeUI:Destroy()
        self.grenadeUI = nil
    end
end

-- Play sound effect
function GrenadeSystem:playSound(soundId, volume)
    if not soundId then return end

    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = self.rootPart

    sound:Play()

    -- Cleanup sound after playing
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Set return slot for quick grenade
function GrenadeSystem:setReturnSlot(slot)
    self.returnSlot = slot
end

-- Reset grenade system state
function GrenadeSystem:reset()
    print("[GrenadeSystem] Resetting grenade system...")

    -- Stop all active actions
    self:stopCooking()
    self:unequip()

    -- Clear active grenades
    for _, grenade in ipairs(self.activeGrenades) do
        if grenade and grenade.Parent then
            grenade:Destroy()
        end
    end
    self.activeGrenades = {}

    -- Reset state
    self.isDeployed = false
    self.isEquipped = false
    self.returnSlot = nil
    self.lastGrenadeTime = 0

    print("[GrenadeSystem] Reset complete")
end

-- Set deployed state
function GrenadeSystem:setDeployed(deployed)
    self.isDeployed = deployed
    print("[GrenadeSystem] Deployment state:", deployed)
end

-- Cleanup
function GrenadeSystem:cleanup()
    print("[GrenadeSystem] Cleaning up grenade system...")

    -- Reset state
    self:reset()

    -- Disconnect all connections
    for name, connection in pairs(self.connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        elseif typeof(connection) == "thread" then
            task.cancel(connection)
        end
    end

    -- Destroy UI
    self:destroyGrenadeUI()

    -- Clear references
    self.connections = {}
    self.grenadeConfig = nil

    print("[GrenadeSystem] Grenade system cleanup complete")
end

return GrenadeSystem