-- ComprehensiveGrenadeSystem.lua
-- Advanced grenade system with cooking, multiple types, and realistic physics
-- Supports all major grenade types with comprehensive features

local ComprehensiveGrenadeSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Grenade types and configurations
local GRENADE_TYPES = {
    ["FragGrenade"] = {
        Name = "M67 Fragmentation Grenade",
        FuseTime = 4.0,
        CookTime = 3.5,
        Damage = {
            MaxDamage = 150,
            MinDamage = 25,
            DamageRadius = 15,
            MaxRadius = 25
        },
        Physics = {
            ThrowForce = 50,
            Mass = 0.4,
            Bounce = 0.6,
            Friction = 0.7
        },
        Effects = {
            ExplosionSize = 20,
            ShockwaveRadius = 30,
            SmokeColor = Color3.fromRGB(80, 80, 80),
            FlashIntensity = 2.0
        },
        Sounds = {
            Pin = "rbxasset://sounds/Metal_Click.mp3",
            Throw = "rbxasset://sounds/Launching_02.wav", 
            Explosion = "rbxasset://sounds/Rocket_Launcher_Explosion.mp3"
        },
        UnlockLevel = 1,
        Credits = 100
    },
    
    ["FlashBang"] = {
        Name = "M84 Stun Grenade",
        FuseTime = 2.0,
        CookTime = 1.8,
        Damage = {
            MaxDamage = 5,
            MinDamage = 1,
            DamageRadius = 8,
            MaxRadius = 20
        },
        Effects = {
            FlashDuration = 8.0,
            FlashIntensity = 5.0,
            BlindRadius = 25,
            DeafenDuration = 6.0,
            ExplosionSize = 10
        },
        Physics = {
            ThrowForce = 45,
            Mass = 0.3,
            Bounce = 0.8,
            Friction = 0.5
        },
        Sounds = {
            Pin = "rbxasset://sounds/Metal_Click.mp3",
            Explosion = "rbxasset://sounds/Flashbang.mp3"
        },
        UnlockLevel = 8,
        Credits = 150
    },
    
    ["SmokeGrenade"] = {
        Name = "M18 Smoke Grenade",
        FuseTime = 1.5,
        CookTime = 1.0,
        Damage = {
            MaxDamage = 2,
            MinDamage = 0,
            DamageRadius = 3,
            MaxRadius = 5
        },
        Effects = {
            SmokeRadius = 35,
            SmokeDuration = 45.0,
            SmokeColor = Color3.fromRGB(200, 200, 200),
            SmokeOpacity = 0.8,
            ExplosionSize = 5
        },
        Physics = {
            ThrowForce = 40,
            Mass = 0.35,
            Bounce = 0.4,
            Friction = 0.8
        },
        Sounds = {
            Pin = "rbxasset://sounds/Metal_Click.mp3",
            Hiss = "rbxasset://sounds/Fire_Crackle.mp3"
        },
        UnlockLevel = 5,
        Credits = 75
    },
    
    ["IncendiaryGrenade"] = {
        Name = "AN-M14 TH3 Incendiary",
        FuseTime = 3.0,
        CookTime = 2.5,
        Damage = {
            MaxDamage = 100,
            MinDamage = 15,
            DamageRadius = 12,
            MaxRadius = 18,
            FireDamage = 25,
            FireDuration = 8.0
        },
        Effects = {
            FireRadius = 20,
            FireDuration = 15.0,
            FireColor = Color3.fromRGB(255, 100, 0),
            SmokeColor = Color3.fromRGB(40, 40, 40),
            ExplosionSize = 15
        },
        Physics = {
            ThrowForce = 48,
            Mass = 0.5,
            Bounce = 0.5,
            Friction = 0.6
        },
        Sounds = {
            Pin = "rbxasset://sounds/Metal_Click.mp3",
            Explosion = "rbxasset://sounds/Fire_Whoosh.mp3",
            Fire = "rbxasset://sounds/Fire_Crackle.mp3"
        },
        UnlockLevel = 15,
        Credits = 200
    },
    
    ["ConcussionGrenade"] = {
        Name = "MK3A2 Concussion Grenade",
        FuseTime = 4.5,
        CookTime = 4.0,
        Damage = {
            MaxDamage = 80,
            MinDamage = 10,
            DamageRadius = 18,
            MaxRadius = 30
        },
        Effects = {
            ShockwaveRadius = 35,
            ShockwaveForce = 500,
            StunDuration = 4.0,
            ScreenShake = 3.0,
            ExplosionSize = 25
        },
        Physics = {
            ThrowForce = 55,
            Mass = 0.6,
            Bounce = 0.3,
            Friction = 0.9
        },
        Sounds = {
            Pin = "rbxasset://sounds/Metal_Click.mp3",
            Explosion = "rbxasset://sounds/Explosion_Large.mp3"
        },
        UnlockLevel = 20,
        Credits = 250
    }
}

-- Active grenades tracking
local activeGrenades = {}
local playerGrenadeData = {}

function ComprehensiveGrenadeSystem.init()
    print("[ComprehensiveGrenadeSystem] Initializing comprehensive grenade system...")
    
    -- Initialize player data
    Players.PlayerAdded:Connect(function(player)
        ComprehensiveGrenadeSystem.initializePlayerData(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        ComprehensiveGrenadeSystem.initializePlayerData(player)
    end
    
    -- Setup remote events
    ComprehensiveGrenadeSystem.setupRemoteEvents()
    
    -- Start update loop for cooking grenades
    ComprehensiveGrenadeSystem.startUpdateLoop()
    
    print("[ComprehensiveGrenadeSystem] System initialized")
    return true
end

function ComprehensiveGrenadeSystem.initializePlayerData(player)
    playerGrenadeData[player.UserId] = {
        inventory = {
            FragGrenade = 3,
            FlashBang = 2,
            SmokeGrenade = 2
        },
        equipped = "FragGrenade",
        cooking = nil
    }
end

function ComprehensiveGrenadeSystem:getGrenadeConfig(grenadeType)
    return GRENADE_TYPES[grenadeType]
end

function ComprehensiveGrenadeSystem:getAllGrenadeTypes()
    return GRENADE_TYPES
end

function ComprehensiveGrenadeSystem:throwGrenade(player, grenadeType, throwDirection, cookTime)
    local config = GRENADE_TYPES[grenadeType]
    if not config then return false end
    
    local playerData = playerGrenadeData[player.UserId]
    if not playerData then return false end
    
    -- Check inventory
    if not playerData.inventory[grenadeType] or playerData.inventory[grenadeType] <= 0 then
        return false
    end
    
    -- Consume grenade from inventory
    playerData.inventory[grenadeType] = playerData.inventory[grenadeType] - 1
    
    -- Create grenade object
    local grenade = ComprehensiveGrenadeSystem.createGrenadeObject(grenadeType, config)
    if not grenade then return false end
    
    -- Position grenade
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        grenade.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(1, 1, -2)
    end
    
    -- Apply physics
    ComprehensiveGrenadeSystem.applyGrenadePhysics(grenade, config, throwDirection)
    
    -- Start fuse timer (reduced by cook time)
    local fuseTime = math.max(0.1, config.FuseTime - (cookTime or 0))
    
    -- Track active grenade
    local grenadeData = {
        grenade = grenade,
        config = config,
        fuseTime = fuseTime,
        startTime = tick(),
        thrower = player
    }
    
    activeGrenades[grenade] = grenadeData
    
    -- Schedule explosion
    task.spawn(function()
        task.wait(fuseTime)
        if activeGrenades[grenade] then
            ComprehensiveGrenadeSystem.detonateGrenade(grenadeData)
        end
    end)
    
    print("[ComprehensiveGrenadeSystem]", player.Name, "threw", grenadeType, "with", fuseTime, "second fuse")
    return true
end

function ComprehensiveGrenadeSystem:createGrenadeObject(grenadeType, config)
    local grenade = Instance.new("Part")
    grenade.Name = grenadeType
    grenade.Shape = Enum.PartType.Ball
    grenade.Size = Vector3.new(0.8, 0.8, 0.8)
    grenade.Material = Enum.Material.Metal
    grenade.Color = Color3.fromRGB(60, 70, 60)
    grenade.TopSurface = Enum.SurfaceType.Smooth
    grenade.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Add mass
    grenade.AssemblyMass = config.Physics.Mass
    
    -- Add body velocity for throwing
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = grenade
    
    -- Add body angular velocity for spin
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 10, 0)
    bodyAngularVelocity.Parent = grenade
    
    -- Add collision detection
    local function onTouched(hit)
        if hit.Parent:FindFirstChildOfClass("Humanoid") then
            return -- Don't bounce off players
        end
        
        -- Apply bounce
        if bodyVelocity then
            bodyVelocity.Velocity = bodyVelocity.Velocity * config.Physics.Bounce
        end
        
        -- Play bounce sound
        ComprehensiveGrenadeSystem.playSound("Bounce", grenade.Position)
    end
    
    grenade.Touched:Connect(onTouched)
    
    grenade.Parent = Workspace
    return grenade
end

function ComprehensiveGrenadeSystem:applyGrenadePhysics(grenade, config, throwDirection)
    local bodyVelocity = grenade:FindFirstChild("BodyVelocity")
    if bodyVelocity then
        local throwForce = config.Physics.ThrowForce
        bodyVelocity.Velocity = throwDirection.LookVector * throwForce + Vector3.new(0, throwForce * 0.3, 0)
        
        -- Remove body velocity after initial throw
        task.spawn(function()
            task.wait(0.5)
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
        end)
    end
end

function ComprehensiveGrenadeSystem:detonateGrenade(grenadeData)
    local grenade = grenadeData.grenade
    local config = grenadeData.config
    local position = grenade.Position
    
    -- Remove from active grenades
    activeGrenades[grenade] = nil
    
    -- Create explosion effects
    ComprehensiveGrenadeSystem.createExplosionEffects(position, config)
    
    -- Apply damage and special effects
    ComprehensiveGrenadeSystem.applyGrenadeEffects(position, config, grenadeData.thrower)
    
    -- Play explosion sound
    ComprehensiveGrenadeSystem.playSound("Explosion", position, config.Sounds.Explosion)
    
    -- Remove grenade object
    grenade:Destroy()
    
    print("[ComprehensiveGrenadeSystem] Detonated", config.Name, "at", position)
end

function ComprehensiveGrenadeSystem:createExplosionEffects(position, config)
    -- Create explosion
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = config.Effects.ExplosionSize
    explosion.BlastPressure = 500000
    explosion.Parent = Workspace
    
    -- Create specific effects based on grenade type
    if config.Effects.SmokeColor then
        ComprehensiveGrenadeSystem.createSmokeEffect(position, config)
    end
    
    if config.Effects.FireColor then
        ComprehensiveGrenadeSystem.createFireEffect(position, config)
    end
    
    if config.Effects.FlashIntensity then
        ComprehensiveGrenadeSystem.createFlashEffect(position, config)
    end
end

function ComprehensiveGrenadeSystem:createSmokeEffect(position, config)
    local smokeEmitter = Instance.new("Part")
    smokeEmitter.Name = "SmokeEmitter"
    smokeEmitter.Size = Vector3.new(1, 1, 1)
    smokeEmitter.Position = position
    smokeEmitter.Anchored = true
    smokeEmitter.Transparency = 1
    smokeEmitter.CanCollide = false
    smokeEmitter.Parent = Workspace
    
    local smoke = Instance.new("ParticleEmitter")
    smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
    smoke.Lifetime = NumberRange.new(8, 12)
    smoke.Rate = 100
    smoke.SpreadAngle = Vector2.new(45, 45)
    smoke.Speed = NumberRange.new(5, 15)
    smoke.Color = ColorSequence.new(config.Effects.SmokeColor)
    smoke.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 4),
        NumberSequenceKeypoint.new(1, 8)
    }
    smoke.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.8, 0.6),
        NumberSequenceKeypoint.new(1, 1)
    }
    smoke.Parent = smokeEmitter
    
    -- Clean up after smoke duration
    Debris:AddItem(smokeEmitter, config.Effects.SmokeDuration or 30)
end

function ComprehensiveGrenadeSystem:createFireEffect(position, config)
    local fireEmitter = Instance.new("Part")
    fireEmitter.Name = "FireEmitter"
    fireEmitter.Size = Vector3.new(1, 1, 1)
    fireEmitter.Position = position
    fireEmitter.Anchored = true
    fireEmitter.Transparency = 1
    fireEmitter.CanCollide = false
    fireEmitter.Parent = Workspace
    
    local fire = Instance.new("ParticleEmitter")
    fire.Texture = "rbxasset://textures/particles/fire_main.dds"
    fire.Lifetime = NumberRange.new(0.5, 2.0)
    fire.Rate = 200
    fire.SpreadAngle = Vector2.new(30, 30)
    fire.Speed = NumberRange.new(3, 8)
    fire.Color = ColorSequence.new(config.Effects.FireColor)
    fire.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 0)
    }
    fire.Parent = fireEmitter
    
    -- Apply fire damage over time
    task.spawn(function()
        for i = 1, config.Effects.FireDuration or 10 do
            task.wait(1)
            ComprehensiveGrenadeSystem.applyFireDamage(position, config)
        end
    end)
    
    Debris:AddItem(fireEmitter, config.Effects.FireDuration or 15)
end

function ComprehensiveGrenadeSystem:createFlashEffect(position, config)
    -- Create bright light
    local flashLight = Instance.new("PointLight")
    flashLight.Brightness = config.Effects.FlashIntensity * 2
    flashLight.Range = config.Effects.BlindRadius or 25
    flashLight.Color = Color3.fromRGB(255, 255, 255)
    
    local lightPart = Instance.new("Part")
    lightPart.Size = Vector3.new(1, 1, 1)
    lightPart.Position = position
    lightPart.Anchored = true
    lightPart.Transparency = 1
    lightPart.CanCollide = false
    lightPart.Parent = Workspace
    flashLight.Parent = lightPart
    
    -- Fade out the light
    local fadeInfo = TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeTween = TweenService:Create(flashLight, fadeInfo, {Brightness = 0})
    fadeTween:Play()
    
    Debris:AddItem(lightPart, 3)
end

function ComprehensiveGrenadeSystem:applyGrenadeEffects(position, config, thrower)
    local playersInRange = ComprehensiveGrenadeSystem.getPlayersInRange(position, config.Damage.MaxRadius)
    
    for _, player in pairs(playersInRange) do
        local distance = ComprehensiveGrenadeSystem.getDistanceToPlayer(position, player)
        
        if distance <= config.Damage.DamageRadius then
            -- Apply main damage
            local damage = ComprehensiveGrenadeSystem.calculateDamage(distance, config.Damage)
            ComprehensiveGrenadeSystem.applyDamage(player, damage, thrower)
        end
        
        -- Apply special effects based on grenade type
        if config.Effects.FlashDuration and distance <= (config.Effects.BlindRadius or 25) then
            ComprehensiveGrenadeSystem.applyFlashEffect(player, config.Effects)
        end
        
        if config.Effects.StunDuration and distance <= (config.Effects.ShockwaveRadius or 30) then
            ComprehensiveGrenadeSystem.applyStunEffect(player, config.Effects)
        end
    end
end

function ComprehensiveGrenadeSystem:startCooking(player, grenadeType)
    local playerData = playerGrenadeData[player.UserId]
    if not playerData then return false end
    
    local config = GRENADE_TYPES[grenadeType]
    if not config then return false end
    
    -- Check if player has grenades
    if not playerData.inventory[grenadeType] or playerData.inventory[grenadeType] <= 0 then
        return false
    end
    
    -- Start cooking
    playerData.cooking = {
        grenadeType = grenadeType,
        startTime = tick(),
        maxCookTime = config.CookTime
    }
    
    -- Play pin pull sound
    ComprehensiveGrenadeSystem.playSound("Pin", player.Character and player.Character.HumanoidRootPart.Position, config.Sounds.Pin)
    
    print("[ComprehensiveGrenadeSystem]", player.Name, "started cooking", grenadeType)
    return true
end

function ComprehensiveGrenadeSystem:getPlayersInRange(position, radius)
    local playersInRange = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - position).Magnitude
            if distance <= radius then
                table.insert(playersInRange, player)
            end
        end
    end
    
    return playersInRange
end

function ComprehensiveGrenadeSystem:calculateDamage(distance, damageConfig)
    local maxDamage = damageConfig.MaxDamage
    local minDamage = damageConfig.MinDamage
    local damageRadius = damageConfig.DamageRadius
    
    if distance <= damageRadius then
        local falloff = distance / damageRadius
        return maxDamage - (maxDamage - minDamage) * falloff
    end
    
    return 0
end

function ComprehensiveGrenadeSystem.setupRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    -- Create grenade remote events
    -- Use centralized RemoteEvents manager
    local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.Modules.RemoteEventsManager)
    
    local throwGrenadeEvent = RemoteEventsManager.getOrCreateRemoteEvent("ThrowGrenade", "Grenade throwing")
    local cookGrenadeEvent = RemoteEventsManager.getOrCreateRemoteEvent("CookGrenade", "Grenade cooking")
    
    -- Handle remote events on server
    if RunService:IsServer() then
        throwGrenadeEvent.OnServerEvent:Connect(function(player, grenadeType, throwDirection, cookTime)
            ComprehensiveGrenadeSystem.throwGrenade(player, grenadeType, throwDirection, cookTime)
        end)
        
        cookGrenadeEvent.OnServerEvent:Connect(function(player, grenadeType)
            ComprehensiveGrenadeSystem.startCooking(player, grenadeType)
        end)
    end
end

function ComprehensiveGrenadeSystem.startUpdateLoop()
    RunService.Heartbeat:Connect(function()
        -- Update cooking grenades
        for userId, playerData in pairs(playerGrenadeData) do
            if playerData.cooking then
                local cookTime = tick() - playerData.cooking.startTime
                local maxCookTime = playerData.cooking.maxCookTime
                
                -- Check if grenade should explode in hand
                if cookTime >= maxCookTime then
                    local player = Players:GetPlayerByUserId(userId)
                    if player and player.Character then
                        print("[ComprehensiveGrenadeSystem] Grenade exploded in", player.Name, "'s hand!")
                        -- Apply damage to player who cooked too long
                        ComprehensiveGrenadeSystem.applyDamage(player, 100, player)
                        playerData.cooking = nil
                    end
                end
            end
        end
    end)
end

function ComprehensiveGrenadeSystem:playSound(soundType, position, soundId)
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.5
        sound.Parent = Workspace
        sound:Play()
        
        Debris:AddItem(sound, 5)
    end
end

return ComprehensiveGrenadeSystem