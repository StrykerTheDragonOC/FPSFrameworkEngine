-- EnhancedGrenadeSystem.lua
-- Advanced grenade system with realistic physics and Include/Exclude raycasting
-- Place in ReplicatedStorage.FPSSystem.Modules

local GrenadeSystem = {}
GrenadeSystem.__index = GrenadeSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

-- Enhanced constants
local GRENADE_SETTINGS = {
    -- Physics constants
    GRAVITY = Vector3.new(0, -196.2, 0),  -- Roblox gravity
    AIR_RESISTANCE = 0.008,               -- Air drag coefficient
    BOUNCE_THRESHOLD = 5,                 -- Minimum velocity for bounce

    -- Cooking mechanics
    COOK_TIME = 4.5,                      -- Total cook time before explosion
    COOK_WARNING = 3.5,                   -- Warning time before explosion
    PIN_PULL_TIME = 0.3,                  -- Time to pull pin
    THROW_DELAY = 0.2,                    -- Delay after throwing

    -- Trajectory system
    TRAJECTORY = {
        ENABLED = true,
        POINTS = 35,                      -- Number of prediction points
        UPDATE_RATE = 0.05,              -- Update frequency
        FADE_DISTANCE = 0.6,             -- Where trajectory starts fading
        DOT_SIZE = Vector3.new(0.1, 0.1, 0.1),
        COLOR = Color3.fromRGB(255, 120, 120),
        MATERIAL = Enum.Material.Neon,
        MAX_DISTANCE = 100,              -- Maximum trajectory distance
    },

    -- Throwing mechanics
    MIN_FORCE = 20,                      -- Minimum throw force
    MAX_FORCE = 85,                      -- Maximum throw force
    CHARGE_TIME = 2.0,                   -- Time to reach max force
    UNDERHAND_MODIFIER = 0.6,            -- Force modifier for underhand
    ANGLE_VARIATION = 5,                 -- Random angle variation (degrees)

    -- Explosion mechanics
    EXPLOSION = {
        RADIUS = 18,                     -- Base explosion radius
        DAMAGE = 125,                    -- Maximum damage
        MIN_DAMAGE = 15,                 -- Minimum edge damage
        FORCE = 6500,                    -- Explosion force
        UPWARD_BIAS = 0.4,              -- Upward force multiplier
        PENETRATION = 3,                 -- Wall penetration studs
        SHAKE_INTENSITY = 2.5,           -- Camera shake intensity
        SHAKE_DURATION = 0.8,            -- Shake duration
        LIGHT_BRIGHTNESS = 8,            -- Explosion light
        LIGHT_RANGE = 25,                -- Light range
        SOUND_RANGE = 150,               -- Sound hearing range
    },

    -- Visual effects
    EFFECTS = {
        MUZZLE_FLASH = true,
        SMOKE_TRAIL = true,
        SPARKS = true,
        FRAGMENTS = true,
        SCREEN_SHAKE = true,
        SOUND_DOPPLER = true,
    }
}

-- Grenade types configuration
local GRENADE_TYPES = {
    ["M67 FRAG"] = {
        name = "M67 Fragmentation",
        cookTime = 4.5,
        explosionRadius = 18,
        damage = 125,
        force = 6500,
        weight = 0.4,
        bounciness = 0.35,
        sounds = {
            pin = "rbxassetid://8186569638",
            throw = "rbxassetid://8186570431",
            bounce = "rbxassetid://142082167",
            explosion = "rbxassetid://2814355743"
        },
        effects = {
            fragments = true,
            smoke = true,
            flash = true
        }
    },
    ["RGO IMPACT"] = {
        name = "RGO Impact",
        cookTime = 0.1,  -- Explodes on impact
        explosionRadius = 15,
        damage = 110,
        force = 5800,
        weight = 0.35,
        bounciness = 0.1,  -- Low bounce for impact
        impactSensitive = true,
        sounds = {
            pin = "rbxassetid://8186569638",
            throw = "rbxassetid://8186570431",
            explosion = "rbxassetid://2814355743"
        }
    },
    ["M18 SMOKE"] = {
        name = "M18 Smoke",
        cookTime = 2.0,
        explosionRadius = 25,
        damage = 0,  -- No damage, just obscures vision
        smokeTime = 30,
        weight = 0.3,
        bounciness = 0.4,
        sounds = {
            pin = "rbxassetid://8186569638",
            throw = "rbxassetid://8186570431",
            activation = "rbxassetid://131961136"
        },
        effects = {
            smoke = true,
            noFlash = true
        }
    }
}

-- Constructor
function GrenadeSystem.new(viewmodelSystem)
    local self = setmetatable({}, GrenadeSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = self.player.Character or self.player.CharacterAdded:Wait()
    self.humanoid = self.character:WaitForChild("Humanoid")
    self.rootPart = self.character:WaitForChild("HumanoidRootPart")
    self.camera = workspace.CurrentCamera
    self.viewmodel = viewmodelSystem

    -- State tracking
    self.currentGrenade = nil
    self.grenadeType = "M67 FRAG"
    self.isCooking = false
    self.isPinPulled = false
    self.cookStartTime = 0
    self.chargeStartTime = 0
    self.isCharging = false
    self.throwForce = GRENADE_SETTINGS.MIN_FORCE

    -- Trajectory system
    self.showingTrajectory = false
    self.trajectoryPoints = {}
    self.trajectoryConnection = nil
    self.trajectoryFolder = nil

    -- Effects
    self.effectsFolder = workspace:FindFirstChild("GrenadeEffects") or self:createEffectsFolder()

    -- Input connections
    self.inputConnections = {}

    -- Initialize
    self:setupTrajectorySystem()
    self:connectInputs()

    print("Enhanced Grenade System initialized")
    return self
end

-- Create effects folder
function GrenadeSystem:createEffectsFolder()
    local folder = Instance.new("Folder")
    folder.Name = "GrenadeEffects"
    folder.Parent = workspace
    return folder
end

-- Setup trajectory visualization system
function GrenadeSystem:setupTrajectorySystem()
    self.trajectoryFolder = Instance.new("Folder")
    self.trajectoryFolder.Name = "GrenadeTrajectory"
    self.trajectoryFolder.Parent = self.effectsFolder

    -- Create trajectory points
    for i = 1, GRENADE_SETTINGS.TRAJECTORY.POINTS do
        local dot = Instance.new("Part")
        dot.Name = "TrajectoryPoint"
        dot.Size = GRENADE_SETTINGS.TRAJECTORY.DOT_SIZE
        dot.Shape = Enum.PartType.Ball
        dot.Material = GRENADE_SETTINGS.TRAJECTORY.MATERIAL
        dot.Color = GRENADE_SETTINGS.TRAJECTORY.COLOR
        dot.Anchored = true
        dot.CanCollide = false
        dot.Transparency = 1
        dot.Parent = self.trajectoryFolder

        table.insert(self.trajectoryPoints, dot)
    end
end

-- Connect input handling
function GrenadeSystem:connectInputs()
    -- Mouse input for trajectory and throwing
    self.inputConnections.mouse1 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:startCooking()
        end
    end)

    self.inputConnections.mouse1End = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:throwGrenade()
        end
    end)

    -- Right click for trajectory preview
    self.inputConnections.mouse2 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:showTrajectory(true)
        end
    end)

    self.inputConnections.mouse2End = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:showTrajectory(false)
        end
    end)
end

-- Start cooking grenade
function GrenadeSystem:startCooking()
    if self.isCooking then return end

    local grenadeConfig = GRENADE_TYPES[self.grenadeType]
    if not grenadeConfig then return end

    self.isCooking = true
    self.cookStartTime = tick()
    self.chargeStartTime = tick()
    self.isCharging = true

    -- Pull pin
    self:pullPin()

    -- Start cooking timer
    self.cookTimer = task.delay(grenadeConfig.cookTime, function()
        if self.isCooking then
            self:explodeInHand()
        end
    end)

    -- Start force charging
    self.chargeConnection = RunService.Heartbeat:Connect(function()
        if not self.isCharging then return end

        local chargeTime = tick() - self.chargeStartTime
        local chargeProgress = math.min(chargeTime / GRENADE_SETTINGS.CHARGE_TIME, 1)

        self.throwForce = GRENADE_SETTINGS.MIN_FORCE + 
            (GRENADE_SETTINGS.MAX_FORCE - GRENADE_SETTINGS.MIN_FORCE) * chargeProgress
    end)

    print("Cooking grenade:", self.grenadeType, "Force:", self.throwForce)
end

-- Pull pin with audio/visual feedback
function GrenadeSystem:pullPin()
    if self.isPinPulled then return end

    self.isPinPulled = true

    -- Play pin sound
    local grenadeConfig = GRENADE_TYPES[self.grenadeType]
    if grenadeConfig.sounds.pin then
        self:playSound(grenadeConfig.sounds.pin, 0.8)
    end

    -- TODO: Add viewmodel animation for pin pulling
    print("Pin pulled!")
end

-- Throw grenade
function GrenadeSystem:throwGrenade()
    if not self.isCooking then return end

    -- Stop cooking and charging
    self.isCooking = false
    self.isCharging = false

    if self.cookTimer then
        task.cancel(self.cookTimer)
        self.cookTimer = nil
    end

    if self.chargeConnection then
        self.chargeConnection:Disconnect()
        self.chargeConnection = nil
    end

    -- Calculate throw direction and force
    local throwDirection = self:calculateThrowDirection()
    local finalForce = self.throwForce

    -- Create physical grenade
    local grenade = self:createPhysicalGrenade()
    if grenade then
        self:launchGrenade(grenade, throwDirection, finalForce)
    end

    -- Play throw sound
    local grenadeConfig = GRENADE_TYPES[self.grenadeType]
    if grenadeConfig.sounds.throw then
        self:playSound(grenadeConfig.sounds.throw, 0.9)
    end

    -- Reset state
    self.isPinPulled = false
    self.throwForce = GRENADE_SETTINGS.MIN_FORCE

    print("Grenade thrown with force:", finalForce)
end

-- Calculate throw direction with slight randomization
function GrenadeSystem:calculateThrowDirection()
    local camera = self.camera
    local direction = camera.CFrame.LookVector

    -- Add slight randomization for realism
    local variation = GRENADE_SETTINGS.ANGLE_VARIATION
    local randomX = (math.random() - 0.5) * 2 * variation
    local randomY = (math.random() - 0.5) * 2 * variation

    local cframe = CFrame.Angles(math.rad(randomX), math.rad(randomY), 0)
    direction = (cframe * CFrame.lookAt(Vector3.new(), direction)).LookVector

    return direction
end

-- Create physical grenade object
function GrenadeSystem:createPhysicalGrenade()
    local grenadeConfig = GRENADE_TYPES[self.grenadeType]

    -- Create grenade part
    local grenade = Instance.new("Part")
    grenade.Name = "Grenade_" .. self.grenadeType:gsub(" ", "_")
    grenade.Size = Vector3.new(0.6, 0.8, 0.6)
    grenade.Shape = Enum.PartType.Cylinder
    grenade.Material = Enum.Material.Metal
    grenade.Color = Color3.fromRGB(60, 80, 50)
    grenade.CanCollide = true
    grenade.TopSurface = Enum.SurfaceType.Smooth
    grenade.BottomSurface = Enum.SurfaceType.Smooth

    -- Set mass based on grenade type
    local mass = Instance.new("SpecialMesh")
    mass.Parent = grenade
    mass.MeshType = Enum.MeshType.Cylinder

    -- Add BodyVelocity for physics
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = grenade

    -- Store grenade data
    grenade:SetAttribute("GrenadeType", self.grenadeType)
    grenade:SetAttribute("CookTime", tick() - self.cookStartTime)
    grenade:SetAttribute("TotalCookTime", grenadeConfig.cookTime)
    grenade:SetAttribute("Owner", self.player.Name)

    -- Add to effects folder
    grenade.Parent = self.effectsFolder

    return grenade
end

-- Launch grenade with physics
function GrenadeSystem:launchGrenade(grenade, direction, force)
    local grenadeConfig = GRENADE_TYPES[self.grenadeType]

    -- Calculate initial velocity
    local velocity = direction * force

    -- Apply initial velocity
    local bodyVelocity = grenade:FindFirstChild("BodyVelocity")
    if bodyVelocity then
        bodyVelocity.Velocity = velocity

        -- Remove BodyVelocity after brief moment to let physics take over
        Debris:AddItem(bodyVelocity, 0.1)
    end

    -- Set position slightly in front of player
    local startPosition = self.rootPart.Position + self.camera.CFrame.LookVector * 2 + Vector3.new(0, 1, 0)
    grenade.Position = startPosition

    -- Setup collision handling
    self:setupGrenadePhysics(grenade)

    -- Setup timer for explosion
    local remainingTime = grenadeConfig.cookTime - (tick() - self.cookStartTime)
    if remainingTime > 0 then
        task.delay(remainingTime, function()
            if grenade.Parent then
                self:explodeGrenade(grenade)
            end
        end)
    else
        -- Should explode immediately or very soon
        task.delay(0.1, function()
            if grenade.Parent then
                self:explodeGrenade(grenade)
            end
        end)
    end
end

-- Setup grenade physics and collision handling
function GrenadeSystem:setupGrenadePhysics(grenade)
    local grenadeConfig = GRENADE_TYPES[self.grenadeType]

    -- Collision detection for bounces and impact grenades
    local connection
    connection = grenade.Touched:Connect(function(hit)
        if hit.Parent == self.character then return end
        if hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= self.character then return end

        -- Check if impact sensitive
        if grenadeConfig.impactSensitive then
            connection:Disconnect()
            self:explodeGrenade(grenade)
            return
        end

        -- Handle bounce
        local velocity = grenade.Velocity
        if velocity.Magnitude > GRENADE_SETTINGS.BOUNCE_THRESHOLD then
            self:handleBounce(grenade, hit, velocity)
        end
    end)

    -- Apply continuous physics
    local physicsConnection
    physicsConnection = RunService.Heartbeat:Connect(function()
        if not grenade.Parent then
            physicsConnection:Disconnect()
            return
        end

        -- Apply air resistance
        local velocity = grenade.Velocity
        local drag = velocity * velocity.Magnitude * GRENADE_SETTINGS.AIR_RESISTANCE
        grenade.Velocity = velocity - drag * RunService.Heartbeat:Wait()
    end)
end

-- Handle grenade bounce physics
function GrenadeSystem:handleBounce(grenade, hit, velocity)
    local grenadeConfig = GRENADE_TYPES[self.grenadeType]

    -- Play bounce sound
    if grenadeConfig.sounds.bounce then
        self:playSound(grenadeConfig.sounds.bounce, math.min(0.8, velocity.Magnitude / 50))
    end

    -- Calculate bounce with energy loss
    local bounciness = grenadeConfig.bounciness or 0.3
    grenade.Velocity = velocity * bounciness

    print("Grenade bounced with velocity:", grenade.Velocity.Magnitude)
end

-- Explode grenade
function GrenadeSystem:explodeGrenade(grenade)
    if not grenade.Parent then return end

    local grenadeConfig = GRENADE_TYPES[self.grenadeType]
    local position = grenade.Position

    -- Create explosion effects
    self:createExplosionEffects(position, grenadeConfig)

    -- Deal damage to nearby players/objects
    self:handleExplosionDamage(position, grenadeConfig)

    -- Remove grenade
    grenade:Destroy()

    print("Grenade exploded at:", position)
end

-- Create explosion effects
function GrenadeSystem:createExplosionEffects(position, grenadeConfig)
    -- Play explosion sound
    if grenadeConfig.sounds.explosion then
        self:playSound(grenadeConfig.sounds.explosion, 1.5, position)
    end

    -- Create explosion light
    local light = Instance.new("PointLight")
    light.Brightness = GRENADE_SETTINGS.EXPLOSION.LIGHT_BRIGHTNESS
    light.Range = GRENADE_SETTINGS.EXPLOSION.LIGHT_RANGE
    light.Color = Color3.fromRGB(255, 150, 50)

    local lightPart = Instance.new("Part")
    lightPart.Transparency = 1
    lightPart.Anchored = true
    lightPart.CanCollide = false
    lightPart.Position = position
    lightPart.Parent = self.effectsFolder
    light.Parent = lightPart

    -- Fade out light
    local lightTween = TweenService:Create(light, 
        TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {Brightness = 0}
    )
    lightTween:Play()

    Debris:AddItem(lightPart, 1)

    -- Create explosion particles (simplified)
    self:createExplosionParticles(position, grenadeConfig)

    -- Camera shake for nearby players
    self:createCameraShake(position)
end

-- Create explosion particle effects
function GrenadeSystem:createExplosionParticles(position, grenadeConfig)
    -- Create explosion sphere
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = grenadeConfig.explosionRadius
    explosion.BlastPressure = grenadeConfig.force / 100
    explosion.Parent = workspace

    -- Additional custom effects can be added here
end

-- Handle explosion damage
function GrenadeSystem:handleExplosionDamage(position, grenadeConfig)
    local explosionRadius = grenadeConfig.explosionRadius
    local maxDamage = grenadeConfig.damage
    local minDamage = GRENADE_SETTINGS.EXPLOSION.MIN_DAMAGE

    -- Find all characters in range
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = player.Character.HumanoidRootPart.Position
            local distance = (position - targetPosition).Magnitude

            if distance <= explosionRadius then
                -- Calculate damage based on distance
                local damageFactor = 1 - (distance / explosionRadius)
                local damage = minDamage + (maxDamage - minDamage) * damageFactor

                -- Check for line of sight with Include/Exclude filter
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Include
                raycastParams.FilterDescendantsInstances = {workspace.Terrain, workspace:FindFirstChild("Map")}

                local rayResult = workspace:Raycast(position, targetPosition - position, raycastParams)

                -- Reduce damage if behind cover
                if rayResult then
                    damage = damage * 0.3  -- 70% damage reduction through cover
                end

                -- Apply damage (implement your damage system here)
                print("Explosion damage to", player.Name, ":", damage, "at distance:", distance)

                -- Apply knockback
                self:applyExplosionKnockback(player.Character, position, grenadeConfig.force, distance, explosionRadius)
            end
        end
    end
end

-- Apply explosion knockback
function GrenadeSystem:applyExplosionKnockback(character, explosionPos, force, distance, maxRadius)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local direction = (humanoidRootPart.Position - explosionPos).Unit
    local forceFactor = 1 - (distance / maxRadius)
    local knockbackForce = force * forceFactor

    -- Add upward bias
    direction = direction + Vector3.new(0, GRENADE_SETTINGS.EXPLOSION.UPWARD_BIAS, 0)
    direction = direction.Unit

    -- Apply force
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(knockbackForce, knockbackForce, knockbackForce)
    bodyVelocity.Velocity = direction * knockbackForce / 50
    bodyVelocity.Parent = humanoidRootPart

    Debris:AddItem(bodyVelocity, 0.5)
end

-- Create camera shake effect
function GrenadeSystem:createCameraShake(position)
    local distance = (position - self.camera.CFrame.Position).Magnitude
    if distance > GRENADE_SETTINGS.EXPLOSION.SHAKE_DISTANCE then return end

    local shakeFactor = 1 - (distance / GRENADE_SETTINGS.EXPLOSION.SHAKE_DISTANCE)
    local intensity = GRENADE_SETTINGS.EXPLOSION.SHAKE_INTENSITY * shakeFactor

    -- Implement camera shake (placeholder)
    print("Camera shake intensity:", intensity)
end

-- Show/hide trajectory preview
function GrenadeSystem:showTrajectory(show)
    self.showingTrajectory = show

    if show then
        if self.trajectoryConnection then
            self.trajectoryConnection:Disconnect()
        end

        self.trajectoryConnection = RunService.Heartbeat:Connect(function()
            self:updateTrajectoryVisualization()
        end)
    else
        if self.trajectoryConnection then
            self.trajectoryConnection:Disconnect()
            self.trajectoryConnection = nil
        end

        -- Hide all trajectory points
        for _, point in ipairs(self.trajectoryPoints) do
            point.Transparency = 1
        end
    end
end

-- Update trajectory visualization
function GrenadeSystem:updateTrajectoryVisualization()
    if not self.showingTrajectory then return end

    local startPos = self.rootPart.Position + Vector3.new(0, 1, 0)
    local direction = self.camera.CFrame.LookVector
    local force = self.isCharging and self.throwForce or GRENADE_SETTINGS.MIN_FORCE
    local velocity = direction * force

    -- Simulate trajectory
    local currentPos = startPos
    local currentVel = velocity
    local dt = GRENADE_SETTINGS.TRAJECTORY.UPDATE_RATE

    for i, point in ipairs(self.trajectoryPoints) do
        -- Apply physics
        currentVel = currentVel + GRENADE_SETTINGS.GRAVITY * dt
        currentPos = currentPos + currentVel * dt

        -- Update point position
        point.Position = currentPos

        -- Calculate transparency based on distance
        local progress = i / #self.trajectoryPoints
        local fadeStart = GRENADE_SETTINGS.TRAJECTORY.FADE_DISTANCE

        if progress < fadeStart then
            point.Transparency = 0.3
        else
            local fadeProgress = (progress - fadeStart) / (1 - fadeStart)
            point.Transparency = 0.3 + (0.7 * fadeProgress)
        end

        -- Check for collision
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {self.character, self.effectsFolder, self.trajectoryFolder}

        local prevPos = i > 1 and self.trajectoryPoints[i-1].Position or startPos
        local rayResult = workspace:Raycast(prevPos, currentPos - prevPos, raycastParams)

        if rayResult then
            -- Hit something, stop trajectory here
            point.Position = rayResult.Position
            point.Color = Color3.fromRGB(255, 255, 100)  -- Different color for impact

            -- Hide remaining points
            for j = i + 1, #self.trajectoryPoints do
                self.trajectoryPoints[j].Transparency = 1
            end
            break
        else
            point.Color = GRENADE_SETTINGS.TRAJECTORY.COLOR
        end

        -- Stop if too far
        if (currentPos - startPos).Magnitude > GRENADE_SETTINGS.TRAJECTORY.MAX_DISTANCE then
            for j = i + 1, #self.trajectoryPoints do
                self.trajectoryPoints[j].Transparency = 1
            end
            break
        end
    end
end

-- Explode in hand (if cooked too long)
function GrenadeSystem:explodeInHand()
    print("Grenade exploded in hand!")

    local grenadeConfig = GRENADE_TYPES[self.grenadeType]
    local position = self.rootPart.Position

    -- Create explosion at player position
    self:createExplosionEffects(position, grenadeConfig)

    -- Deal damage to self (implement your damage system)
    print("Player takes", grenadeConfig.damage, "damage from cooking grenade too long")

    -- Reset state
    self.isCooking = false
    self.isPinPulled = false

    if self.cookTimer then
        task.cancel(self.cookTimer)
        self.cookTimer = nil
    end
end

-- Play sound effect
function GrenadeSystem:playSound(soundId, volume, position)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 1
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 10
    sound.RollOffMaxDistance = 100

    if position then
        -- 3D positioned sound
        local soundPart = Instance.new("Part")
        soundPart.Transparency = 1
        soundPart.Anchored = true
        soundPart.CanCollide = false
        soundPart.Position = position
        soundPart.Parent = self.effectsFolder

        sound.Parent = soundPart
        sound:Play()

        Debris:AddItem(soundPart, sound.TimeLength + 0.5)
    else
        -- 2D sound
        sound.Parent = self.camera
        sound:Play()

        Debris:AddItem(sound, sound.TimeLength + 0.1)
    end
end

-- Cleanup system
function GrenadeSystem:cleanup()
    print("Cleaning up Enhanced Grenade System")

    -- Stop cooking if active
    if self.isCooking then
        self.isCooking = false
        if self.cookTimer then
            task.cancel(self.cookTimer)
        end
    end

    -- Disconnect connections
    for name, connection in pairs(self.inputConnections) do
        connection:Disconnect()
    end

    if self.trajectoryConnection then
        self.trajectoryConnection:Disconnect()
    end

    if self.chargeConnection then
        self.chargeConnection:Disconnect()
    end

    -- Clean up trajectory
    if self.trajectoryFolder then
        self.trajectoryFolder:Destroy()
    end

    print("Enhanced Grenade System cleanup complete")
end

-- Change grenade type
function GrenadeSystem:setGrenadeType(grenadeType)
    if GRENADE_TYPES[grenadeType] then
        self.grenadeType = grenadeType
        print("Grenade type changed to:", grenadeType)
    else
        warn("Unknown grenade type:", grenadeType)
    end
end

-- Get available grenade types
function GrenadeSystem:getAvailableGrenades()
    local grenades = {}
    for name, config in pairs(GRENADE_TYPES) do
        table.insert(grenades, {name = name, displayName = config.name})
    end
    return grenades
end

return GrenadeSystem