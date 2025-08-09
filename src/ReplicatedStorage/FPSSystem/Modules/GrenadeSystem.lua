-- GrenadeSystem.lua
-- Advanced grenade throwing system for FPS game
-- Place in ReplicatedStorage/FPSSystem/Modules/GrenadeSystem.lua

local GrenadeSystem = {}
GrenadeSystem.__index = GrenadeSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

-- Constants
local GRENADE_SETTINGS = {
    MAX_COOK_TIME = 5.0,
    MIN_THROW_FORCE = 30,
    MAX_THROW_FORCE = 80,
    GRAVITY = Vector3.new(0, -196.2, 0),
    BOUNCE_DAMPENING = 0.6,
    ROLL_FRICTION = 0.9
}

-- Grenade configurations
local GRENADE_CONFIGS = {
    ["M67 Frag"] = {
        type = "fragmentation",
        damage = 100,
        blastRadius = 20,
        fuseTime = 3.5,
        maxCount = 2,
        sounds = {
            pin = "rbxassetid://131961136",
            throw = "rbxassetid://131961136",
            explode = "rbxassetid://131961136",
            bounce = "rbxassetid://131961136"
        },
        effects = {
            explosion = true,
            shrapnel = true,
            smoke = true
        }
    },
    ["M26 Frag"] = {
        type = "fragmentation",
        damage = 120,
        blastRadius = 25,
        fuseTime = 4.0,
        maxCount = 2,
        sounds = {
            pin = "rbxassetid://131961136",
            throw = "rbxassetid://131961136",
            explode = "rbxassetid://131961136",
            bounce = "rbxassetid://131961136"
        },
        effects = {
            explosion = true,
            shrapnel = true,
            smoke = true
        }
    },
    ["Flashbang"] = {
        type = "tactical",
        damage = 5,
        blastRadius = 15,
        fuseTime = 2.0,
        maxCount = 3,
        flashDuration = 4.0,
        sounds = {
            pin = "rbxassetid://131961136",
            throw = "rbxassetid://131961136",
            explode = "rbxassetid://131961136",
            bounce = "rbxassetid://131961136"
        },
        effects = {
            flash = true,
            sound = true
        }
    },
    ["Smoke"] = {
        type = "tactical",
        damage = 0,
        blastRadius = 12,
        fuseTime = 2.5,
        maxCount = 3,
        smokeDuration = 30.0,
        sounds = {
            pin = "rbxassetid://131961136",
            throw = "rbxassetid://131961136",
            explode = "rbxassetid://131961136",
            bounce = "rbxassetid://131961136"
        },
        effects = {
            smoke = true,
            continuous = true
        }
    },
    ["Impact"] = {
        type = "explosive",
        damage = 150,
        blastRadius = 18,
        fuseTime = 0.1, -- Explodes on impact
        maxCount = 1,
        sounds = {
            pin = "rbxassetid://131961136",
            throw = "rbxassetid://131961136",
            explode = "rbxassetid://131961136",
            bounce = "rbxassetid://131961136"
        },
        effects = {
            explosion = true,
            shrapnel = true
        }
    },
    ["C4"] = {
        type = "remote_explosive",
        damage = 200,
        blastRadius = 30,
        fuseTime = -1, -- Manual detonation
        maxCount = 2,
        stickToSurfaces = true,
        sounds = {
            pin = "rbxassetid://131961136",
            throw = "rbxassetid://131961136",
            explode = "rbxassetid://131961136",
            bounce = "rbxassetid://131961136",
            stick = "rbxassetid://131961136",
            beep = "rbxassetid://131961136"
        },
        effects = {
            explosion = true,
            shrapnel = true,
            debris = true
        }
    },
    ["Sticky Grenade"] = {
        type = "sticky_explosive",
        damage = 120,
        blastRadius = 22,
        fuseTime = 4.0,
        maxCount = 2,
        stickToSurfaces = true,
        stickToPlayers = true,
        sounds = {
            pin = "rbxassetid://131961136",
            throw = "rbxassetid://131961136",
            explode = "rbxassetid://131961136",
            bounce = "rbxassetid://131961136",
            stick = "rbxassetid://131961136"
        },
        effects = {
            explosion = true,
            shrapnel = true
        }
    }
}

-- Constructor
function GrenadeSystem.new(viewmodelSystem)
    local self = setmetatable({}, GrenadeSystem)

    -- References
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera
    self.viewmodelSystem = viewmodelSystem

    -- Current grenade
    self.currentGrenade = nil
    self.currentConfig = nil
    self.grenadeCount = 0

    -- Throwing state
    self.isPreparing = false
    self.isCooking = false
    self.cookStartTime = 0
    self.throwPower = 0

    -- Effects
    self.soundCache = {}
    self.activeGrenades = {}
    self.effectsFolder = workspace:FindFirstChild("GrenadeEffects")
    if not self.effectsFolder then
        self.effectsFolder = Instance.new("Folder")
        self.effectsFolder.Name = "GrenadeEffects"
        self.effectsFolder.Parent = workspace
    end

    -- Trajectory preview
    self.trajectoryPoints = {}

    -- Setup remote events
    self:setupRemoteEvents()

    print("[Grenade] System initialized")
    return self
end

-- Setup remote events
function GrenadeSystem:setupRemoteEvents()
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end

    -- Throw grenade event
    self.throwEvent = remoteEvents:FindFirstChild("ThrowGrenade")
    if not self.throwEvent then
        self.throwEvent = Instance.new("RemoteEvent")
        self.throwEvent.Name = "ThrowGrenade"
        self.throwEvent.Parent = remoteEvents
    end

    -- Explode grenade event
    self.explodeEvent = remoteEvents:FindFirstChild("ExplodeGrenade")
    if not self.explodeEvent then
        self.explodeEvent = Instance.new("RemoteEvent")
        self.explodeEvent.Name = "ExplodeGrenade"
        self.explodeEvent.Parent = remoteEvents
    end
end

-- Set current grenade type
function GrenadeSystem:setGrenade(grenadeName)
    self.currentGrenade = grenadeName
    self.currentConfig = GRENADE_CONFIGS[grenadeName] or GRENADE_CONFIGS["M67 Frag"]
    self.grenadeCount = self.currentConfig.maxCount

    -- Preload sounds
    self:preloadSounds()

    print("[Grenade] Grenade set:", grenadeName, "Count:", self.grenadeCount)
end

-- Preload sounds
function GrenadeSystem:preloadSounds()
    if not self.currentConfig or not self.currentConfig.sounds then return end

    for soundName, soundId in pairs(self.currentConfig.sounds) do
        if not self.soundCache[soundName] then
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Volume = 0.8
            sound.Parent = SoundService

            self.soundCache[soundName] = sound
            game:GetService("ContentProvider"):PreloadAsync({sound})
        end
    end
end

-- Start preparing grenade (hold G)
function GrenadeSystem:startPreparing()
    if self.grenadeCount <= 0 or self.isPreparing then return end

    self.isPreparing = true
    self.throwPower = GRENADE_SETTINGS.MIN_THROW_FORCE

    -- Play pin sound
    self:playSound("pin")

    -- Equip grenade viewmodel
    if self.viewmodelSystem then
        self.viewmodelSystem:equipWeapon(self.currentGrenade, "GRENADE")
        self.viewmodelSystem:playAnimation("grenade_prepare", 0.2)
    end

    -- Start cooking if it's a cookable grenade
    if self.currentConfig.type == "fragmentation" or self.currentConfig.type == "explosive" then
        self.isCooking = true
        self.cookStartTime = tick()
    end

    -- Show trajectory preview
    self:startTrajectoryPreview()

    print("[Grenade] Preparing grenade")
end

-- Update throw power while holding
function GrenadeSystem:updateThrowPower(deltaTime)
    if not self.isPreparing then return end

    -- Increase throw power over time
    self.throwPower = math.min(
        self.throwPower + 50 * deltaTime,
        GRENADE_SETTINGS.MAX_THROW_FORCE
    )

    -- Check cook time
    if self.isCooking then
        local cookTime = tick() - self.cookStartTime
        if cookTime >= GRENADE_SETTINGS.MAX_COOK_TIME then
            -- Grenade explodes in hand!
            self:explodeInHand()
            return
        end
    end

    -- Update trajectory preview
    self:updateTrajectoryPreview()
end

-- Throw grenade (release G)
function GrenadeSystem:throwGrenade()
    if not self.isPreparing then return end

    self.isPreparing = false
    self.grenadeCount = self.grenadeCount - 1

    -- Calculate throw parameters
    local origin = self.camera.CFrame.Position
    local direction = self.camera.CFrame.LookVector
    local cookTime = self.isCooking and (tick() - self.cookStartTime) or 0

    -- Play throw sound
    self:playSound("throw")

    -- Play throw animation and switch back to previous weapon
    if self.viewmodelSystem then
        self.viewmodelSystem:playAnimation("grenade_throw", 0.1)

        -- Switch back to previous weapon after throw
        task.spawn(function()
            task.wait(0.5)
            -- This would switch back to the previously equipped weapon
        end)
    end

    -- Hide trajectory preview
    self:hideTrajectoryPreview()

    -- Create grenade projectile
    self:createGrenadeProjectile(origin, direction, self.throwPower, cookTime)

    -- Send to server
    self.throwEvent:FireServer(origin, direction, self.throwPower, cookTime, self.currentGrenade)

    self.isCooking = false

    print("[Grenade] Threw grenade with power:", self.throwPower, "Cook time:", cookTime)
end

-- Cancel grenade preparation
function GrenadeSystem:cancelPreparing()
    if not self.isPreparing then return end

    self.isPreparing = false
    self.isCooking = false

    -- Hide trajectory preview
    self:hideTrajectoryPreview()

    -- Play cancel animation
    if self.viewmodelSystem then
        self.viewmodelSystem:playAnimation("grenade_cancel", 0.2)
    end

    print("[Grenade] Cancelled grenade preparation")
end

-- Create grenade projectile
function GrenadeSystem:createGrenadeProjectile(origin, direction, throwPower, cookTime)
    -- Create grenade model
    local grenade = Instance.new("Part")
    grenade.Name = "Grenade_" .. self.currentGrenade
    grenade.Size = Vector3.new(0.5, 0.8, 0.5)
    grenade.Shape = self.currentConfig.type == "remote_explosive" and Enum.PartType.Block or Enum.PartType.Cylinder
    grenade.Material = Enum.Material.Metal
    grenade.Color = Color3.fromRGB(60, 60, 60)
    grenade.CanCollide = true
    grenade.Position = origin
    grenade.Parent = self.effectsFolder

    -- Special handling for C4 and sticky grenades
    if self.currentConfig.stickToSurfaces then
        local weldConstraint = nil

        -- Add touch detection for sticking
        local touchConnection
        touchConnection = grenade.Touched:Connect(function(hit)
            if hit.Parent ~= self.player.Character and hit.Name ~= "Grenade" and not weldConstraint then
                -- Check if it's a player for sticky grenades
                local humanoid = hit.Parent:FindFirstChild("Humanoid")

                if self.currentConfig.stickToPlayers and humanoid then
                    -- Stick to player
                    weldConstraint = Instance.new("WeldConstraint")
                    weldConstraint.Part0 = grenade
                    weldConstraint.Part1 = hit
                    weldConstraint.Parent = grenade

                    -- Play stick sound
                    self:playSound("stick")

                    -- Cancel physics
                    grenade.CanCollide = false
                    grenade.Anchored = true

                    touchConnection:Disconnect()

                elseif not humanoid then
                    -- Stick to surface
                    weldConstraint = Instance.new("WeldConstraint")
                    weldConstraint.Part0 = grenade
                    weldConstraint.Part1 = hit
                    weldConstraint.Parent = grenade

                    -- Play stick sound
                    self:playSound("stick")

                    -- Cancel physics
                    grenade.CanCollide = false
                    grenade.Anchored = true

                    touchConnection:Disconnect()
                end
            end
        end)
    else
        -- Regular bounce sound for non-sticky grenades
        local function onTouch(hit)
            if hit.Parent ~= self.player.Character and hit.Name ~= "Grenade" then
                self:playSound("bounce")
            end
        end
        grenade.Touched:Connect(onTouch)
    end

    -- Add physics (only if not C4, which should drop more gently)
    if self.currentConfig.type ~= "remote_explosive" then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Velocity = direction * throwPower + Vector3.new(0, throwPower * 0.3, 0)
        bodyVelocity.Parent = grenade

        -- Remove body velocity after initial throw
        Debris:AddItem(bodyVelocity, 0.2)
    else
        -- C4 gets gentler physics
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(2000, 2000, 2000)
        bodyVelocity.Velocity = direction * (throwPower * 0.5) + Vector3.new(0, throwPower * 0.2, 0)
        bodyVelocity.Parent = grenade

        Debris:AddItem(bodyVelocity, 0.3)
    end

    -- Store grenade info
    local grenadeInfo = {
        part = grenade,
        config = self.currentConfig,
        fuseTime = self.currentConfig.fuseTime > 0 and (self.currentConfig.fuseTime - cookTime) or -1,
        startTime = tick(),
        isC4 = self.currentConfig.type == "remote_explosive"
    }

    table.insert(self.activeGrenades, grenadeInfo)

    -- Start fuse timer (unless it's C4 which is manually detonated)
    if self.currentConfig.fuseTime > 0 then
        task.spawn(function()
            task.wait(grenadeInfo.fuseTime)
            if grenade.Parent then
                self:explodeGrenade(grenadeInfo)
            end
        end)
    elseif self.currentConfig.type == "remote_explosive" then
        -- Add C4 beeping
        self:startC4Beeping(grenade)

        -- Store for manual detonation
        grenadeInfo.canDetonate = true
    end
end

-- Start C4 beeping sound
function GrenadeSystem:startC4Beeping(c4Part)
    task.spawn(function()
        while c4Part.Parent do
            self:playSound("beep")
            task.wait(2) -- Beep every 2 seconds
        end
    end)
end

-- Manual C4 detonation
function GrenadeSystem:detonateC4()
    for i, grenadeInfo in ipairs(self.activeGrenades) do
        if grenadeInfo.isC4 and grenadeInfo.canDetonate and grenadeInfo.part.Parent then
            self:explodeGrenade(grenadeInfo)
        end
    end
end

-- Explode grenade
function GrenadeSystem:explodeGrenade(grenadeInfo)
    local grenade = grenadeInfo.part
    local config = grenadeInfo.config

    if not grenade or not grenade.Parent then return end

    local position = grenade.Position

    -- Remove grenade from active list
    for i, info in ipairs(self.activeGrenades) do
        if info == grenadeInfo then
            table.remove(self.activeGrenades, i)
            break
        end
    end

    -- Destroy grenade part
    grenade:Destroy()

    -- Create explosion effect based on type
    if config.type == "fragmentation" or config.type == "explosive" or config.type == "remote_explosive" or config.type == "sticky_explosive" then
        self:createExplosionEffect(position, config)
    elseif config.type == "tactical" then
        if config.effects.flash then
            self:createFlashEffect(position, config)
        elseif config.effects.smoke then
            self:createSmokeEffect(position, config)
        end
    end

    -- Play explosion sound
    self:playSound("explode")

    -- Send explosion to server for damage
    self.explodeEvent:FireServer(position, config.damage, config.blastRadius, config.type)

    print("[Grenade] Exploded at:", position)
end

-- Explode grenade in hand (cooking too long)
function GrenadeSystem:explodeInHand()
    self.isPreparing = false
    self.isCooking = false
    self:hideTrajectoryPreview()

    -- Damage player
    if self.player.Character and self.player.Character:FindFirstChild("Humanoid") then
        self.player.Character.Humanoid:TakeDamage(self.currentConfig.damage)
    end

    print("[Grenade] Exploded in hand!")
end

-- Enhanced explosion effect for different grenade types
function GrenadeSystem:createExplosionEffect(position, config)
    -- Main explosion
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = config.blastRadius
    explosion.BlastPressure = config.type == "remote_explosive" and 800000 or 500000
    explosion.Parent = workspace

    -- Custom particle effects
    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = workspace.Terrain

    -- Enhanced effects for C4
    local particleCount = config.type == "remote_explosive" and 100 or 50
    local smokeCount = config.type == "remote_explosive" and 60 or 30

    -- Fire particles
    local fireParticle = Instance.new("ParticleEmitter")
    fireParticle.Texture = "rbxasset://textures/particles/fire_main.dds"
    fireParticle.Rate = 0
    fireParticle.Lifetime = NumberRange.new(1.0, 2.0)
    fireParticle.Speed = NumberRange.new(30, 60)
    fireParticle.SpreadAngle = Vector2.new(360, 360)
    fireParticle.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    fireParticle.Parent = attachment
    fireParticle:Emit(particleCount)

    -- Smoke particles
    local smokeParticle = Instance.new("ParticleEmitter")
    smokeParticle.Texture = "rbxasset://textures/particles/smoke_main.dds"
    smokeParticle.Rate = 0
    smokeParticle.Lifetime = NumberRange.new(3.0, 5.0)
    smokeParticle.Speed = NumberRange.new(20, 40)
    smokeParticle.SpreadAngle = Vector2.new(180, 180)
    smokeParticle.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100))
    smokeParticle.Parent = attachment
    smokeParticle:Emit(smokeCount)

    -- Enhanced shrapnel for C4
    if config.effects.shrapnel then
        local shrapnelCount = config.type == "remote_explosive" and 40 or 20

        for i = 1, shrapnelCount do
            local shrapnel = Instance.new("Part")
            shrapnel.Size = Vector3.new(0.1, 0.1, 0.5)
            shrapnel.Material = Enum.Material.Metal
            shrapnel.Color = Color3.fromRGB(150, 150, 150)
            shrapnel.CanCollide = false
            shrapnel.Position = position
            shrapnel.Parent = self.effectsFolder

            -- Random velocity
            local direction = Vector3.new(
                math.random(-1, 1),
                math.random(0, 1),
                math.random(-1, 1)
            ).Unit

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyVelocity.Velocity = direction * math.random(50, config.type == "remote_explosive" and 150 or 100)
            bodyVelocity.Parent = shrapnel

            Debris:AddItem(shrapnel, 3)
            Debris:AddItem(bodyVelocity, 0.5)
        end
    end

    -- Debris for C4
    if config.effects.debris and config.type == "remote_explosive" then
        for i = 1, 15 do
            local debris = Instance.new("Part")
            debris.Size = Vector3.new(
                math.random(2, 6) / 10,
                math.random(2, 6) / 10,
                math.random(2, 6) / 10
            )
            debris.Material = Enum.Material.Concrete
            debris.Color = Color3.fromRGB(
                math.random(80, 120),
                math.random(80, 120),
                math.random(80, 120)
            )
            debris.Shape = Enum.PartType.Block
            debris.CanCollide = true
            debris.Position = position + Vector3.new(
                math.random(-2, 2),
                math.random(0, 3),
                math.random(-2, 2)
            )
            debris.Parent = self.effectsFolder

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyVelocity.Velocity = Vector3.new(
                math.random(-30, 30),
                math.random(20, 50),
                math.random(-30, 30)
            )
            bodyVelocity.Parent = debris

            Debris:AddItem(debris, 10)
            Debris:AddItem(bodyVelocity, 1)
        end
    end

    Debris:AddItem(attachment, 8)
end

-- Create flash effect
function GrenadeSystem:createFlashEffect(position, config)
    -- Bright flash
    local flash = Instance.new("PointLight")
    flash.Brightness = 10
    flash.Color = Color3.new(1, 1, 1)
    flash.Range = config.blastRadius * 2
    flash.Position = position
    flash.Parent = workspace.Terrain

    -- Fade out flash
    local tween = TweenService:Create(
        flash,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad),
        {Brightness = 0}
    )
    tween:Play()

    Debris:AddItem(flash, 1)

    -- Screen flash effect for nearby players
    self:createScreenFlash(position, config)
end

-- Create smoke effect
function GrenadeSystem:createSmokeEffect(position, config)
    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = workspace.Terrain

    -- Continuous smoke
    local smokeParticle = Instance.new("ParticleEmitter")
    smokeParticle.Texture = "rbxasset://textures/particles/smoke_main.dds"
    smokeParticle.Rate = 50
    smokeParticle.Lifetime = NumberRange.new(5.0, 8.0)
    smokeParticle.Speed = NumberRange.new(5, 15)
    smokeParticle.SpreadAngle = Vector2.new(90, 90)
    smokeParticle.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
    smokeParticle.Parent = attachment

    -- Stop smoke after duration
    task.spawn(function()
        task.wait(config.smokeDuration or 30)
        smokeParticle.Enabled = false
        Debris:AddItem(attachment, 10)
    end)
end

-- Create screen flash effect
function GrenadeSystem:createScreenFlash(position, config)
    if not self.player.Character or not self.player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local distance = (self.player.Character.HumanoidRootPart.Position - position).Magnitude

    if distance <= config.blastRadius * 1.5 then
        -- Create screen flash GUI
        local screenFlash = Instance.new("Frame")
        screenFlash.Size = UDim2.new(1, 0, 1, 0)
        screenFlash.Position = UDim2.new(0, 0, 0, 0)
        screenFlash.BackgroundColor3 = Color3.new(1, 1, 1)
        screenFlash.BackgroundTransparency = 0
        screenFlash.BorderSizePixel = 0
        screenFlash.Parent = self.player.PlayerGui

        -- Fade out
        local tween = TweenService:Create(
            screenFlash,
            TweenInfo.new(config.flashDuration or 4, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 1}
        )
        tween:Play()

        tween.Completed:Connect(function()
            screenFlash:Destroy()
        end)
    end
end

-- Start trajectory preview
function GrenadeSystem:startTrajectoryPreview()
    self:hideTrajectoryPreview()

    -- Create trajectory points
    for i = 1, 20 do
        local point = Instance.new("Part")
        point.Name = "TrajectoryPoint"
        point.Size = Vector3.new(0.2, 0.2, 0.2)
        point.Material = Enum.Material.Neon
        point.Color = Color3.fromRGB(255, 255, 0)
        point.CanCollide = false
        point.Anchored = true
        point.Parent = self.effectsFolder

        table.insert(self.trajectoryPoints, point)
    end
end

-- Update trajectory preview
function GrenadeSystem:updateTrajectoryPreview()
    if #self.trajectoryPoints == 0 then return end

    local origin = self.camera.CFrame.Position
    local direction = self.camera.CFrame.LookVector
    local velocity = direction * self.throwPower + Vector3.new(0, self.throwPower * 0.3, 0)

    -- Calculate trajectory points
    for i, point in ipairs(self.trajectoryPoints) do
        local t = i * 0.1
        local pos = origin + velocity * t + 0.5 * GRENADE_SETTINGS.GRAVITY * t * t
        point.Position = pos

        -- Fade points over distance
        point.Transparency = math.min(0.9, i * 0.05)
    end
end

-- Hide trajectory preview
function GrenadeSystem:hideTrajectoryPreview()
    for _, point in ipairs(self.trajectoryPoints) do
        point:Destroy()
    end
    self.trajectoryPoints = {}
end

-- Play sound
function GrenadeSystem:playSound(soundName)
    local sound = self.soundCache[soundName]
    if sound then
        sound:Play()
    end
end

-- Get grenade info
function GrenadeSystem:getInfo()
    local c4Count = 0
    local canDetonateC4 = false

    -- Count active C4 charges
    for _, grenadeInfo in ipairs(self.activeGrenades) do
        if grenadeInfo.isC4 and grenadeInfo.part.Parent then
            c4Count = c4Count + 1
            if grenadeInfo.canDetonate then
                canDetonateC4 = true
            end
        end
    end

    return {
        type = self.currentGrenade,
        count = self.grenadeCount,
        maxCount = self.currentConfig and self.currentConfig.maxCount or 0,
        isPreparing = self.isPreparing,
        isCooking = self.isCooking,
        throwPower = self.throwPower,
        cookTime = self.isCooking and (tick() - self.cookStartTime) or 0,
        activeC4Count = c4Count,
        canDetonateC4 = canDetonateC4
    }
end

-- Add input handler for C4 detonation
function GrenadeSystem:handleInput(input, gameProcessed)
    if gameProcessed then return end

    -- F key to detonate C4
    if input.KeyCode == Enum.KeyCode.F and input.UserInputState == Enum.UserInputState.Begin then
        if self.currentGrenade == "C4" then
            self:detonateC4()
        end
    end
end

-- Update method
function GrenadeSystem:update(deltaTime)
    if self.isPreparing then
        self:updateThrowPower(deltaTime)
    end

    -- Update active grenades
    for i = #self.activeGrenades, 1, -1 do
        local grenadeInfo = self.activeGrenades[i]

        -- Remove grenades that no longer exist
        if not grenadeInfo.part or not grenadeInfo.part.Parent then
            table.remove(self.activeGrenades, i)
        end
    end
end

-- Cleanup
function GrenadeSystem:cleanup()
    self.isPreparing = false
    self.isCooking = false

    -- Hide trajectory
    self:hideTrajectoryPreview()

    -- Clear active grenades
    for _, grenadeInfo in ipairs(self.activeGrenades) do
        if grenadeInfo.part and grenadeInfo.part.Parent then
            grenadeInfo.part:Destroy()
        end
    end
    self.activeGrenades = {}

    -- Clear sound cache
    for _, sound in pairs(self.soundCache) do
        sound:Destroy()
    end
    self.soundCache = {}

    print("[Grenade] Cleanup complete")
end

return GrenadeSystem