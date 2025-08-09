-- MeleeSystem.lua
-- Advanced melee combat system for FPS game
-- Place in ReplicatedStorage/FPSSystem/Modules/MeleeSystem.lua

local MeleeSystem = {}
MeleeSystem.__index = MeleeSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

-- Constants
local MELEE_SETTINGS = {
    DEFAULT_RANGE = 8,
    BACKSTAB_ANGLE = 45, -- Degrees for backstab detection
    COMBO_WINDOW = 1.5,  -- Seconds to chain attacks
    LUNGE_FORCE = 50,
    BLOCK_REDUCTION = 0.7, -- Damage reduction when blocking
}

-- Melee weapon configurations
local MELEE_CONFIGS = {
    Knife = {
        damage = 55,
        backstabDamage = 100,
        range = 6,
        attackSpeed = 0.8,
        lungePower = 30,
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            backstab = "rbxassetid://131961136"
        },
        animations = {
            swing = "MeleeSwing",
            stab = "MeleeStab",
            block = "MeleeBlock"
        }
    },
    Machete = {
        damage = 70,
        backstabDamage = 120,
        range = 8,
        attackSpeed = 1.0,
        lungePower = 40,
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            backstab = "rbxassetid://131961136"
        },
        animations = {
            swing = "MeleeSwing",
            stab = "MeleeStab",
            block = "MeleeBlock"
        }
    },
    Katana = {
        damage = 80,
        backstabDamage = 140,
        range = 10,
        attackSpeed = 1.2,
        lungePower = 50,
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            backstab = "rbxassetid://131961136"
        },
        animations = {
            swing = "MeleeSwing",
            stab = "MeleeStab",
            block = "MeleeBlock"
        }
    },
    ["Baseball Bat"] = {
        damage = 65,
        backstabDamage = 110,
        range = 7,
        attackSpeed = 1.1,
        lungePower = 60,
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            backstab = "rbxassetid://131961136"
        },
        animations = {
            swing = "MeleeSwing",
            stab = "MeleeStab",
            block = "MeleeBlock"
        }
    }
}

-- Constructor
function MeleeSystem.new(viewmodelSystem)
    local self = setmetatable({}, MeleeSystem)

    -- References
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera
    self.viewmodelSystem = viewmodelSystem

    -- Current weapon
    self.currentWeapon = nil
    self.currentConfig = nil

    -- Combat state
    self.isAttacking = false
    self.isBlocking = false
    self.lastAttackTime = 0
    self.comboCount = 0

    -- Effects
    self.soundCache = {}
    self.effectsFolder = workspace:FindFirstChild("MeleeEffects")
    if not self.effectsFolder then
        self.effectsFolder = Instance.new("Folder")
        self.effectsFolder.Name = "MeleeEffects"
        self.effectsFolder.Parent = workspace
    end

    -- Setup remote events
    self:setupRemoteEvents()

    print("[Melee] System initialized")
    return self
end

-- Setup remote events
function MeleeSystem:setupRemoteEvents()
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end

    -- Melee attack event
    self.attackEvent = remoteEvents:FindFirstChild("MeleeAttack")
    if not self.attackEvent then
        self.attackEvent = Instance.new("RemoteEvent")
        self.attackEvent.Name = "MeleeAttack"
        self.attackEvent.Parent = remoteEvents
    end

    -- Melee hit event
    self.hitEvent = remoteEvents:FindFirstChild("MeleeHit")
    if not self.hitEvent then
        self.hitEvent = Instance.new("RemoteEvent")
        self.hitEvent.Name = "MeleeHit"
        self.hitEvent.Parent = remoteEvents
    end
end

-- Set current melee weapon
function MeleeSystem:setWeapon(weaponName)
    self.currentWeapon = weaponName
    self.currentConfig = MELEE_CONFIGS[weaponName] or MELEE_CONFIGS.Knife

    -- Preload sounds
    self:preloadSounds()

    print("[Melee] Weapon set:", weaponName)
end

-- Preload sounds
function MeleeSystem:preloadSounds()
    if not self.currentConfig.sounds then return end

    for soundName, soundId in pairs(self.currentConfig.sounds) do
        if not self.soundCache[soundName] then
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Volume = 0.7
            sound.Parent = SoundService

            self.soundCache[soundName] = sound
            game:GetService("ContentProvider"):PreloadAsync({sound})
        end
    end
end

-- Primary attack (left click)
function MeleeSystem:primaryAttack()
    if self.isAttacking or self.isBlocking then return end

    local currentTime = tick()

    -- Check combo timing
    if currentTime - self.lastAttackTime <= MELEE_SETTINGS.COMBO_WINDOW then
        self.comboCount = self.comboCount + 1
    else
        self.comboCount = 1
    end

    self.lastAttackTime = currentTime
    self.isAttacking = true

    -- Play animation
    if self.viewmodelSystem then
        self.viewmodelSystem:playAnimation(self.currentConfig.animations.swing, 0.1)
    end

    -- Play sound
    self:playSound("swing")

    -- Perform attack after brief delay
    task.wait(0.2)
    self:performAttack("swing")

    -- Reset attack state
    task.wait(self.currentConfig.attackSpeed)
    self.isAttacking = false
end

-- Secondary attack (right click - stab/lunge)
function MeleeSystem:secondaryAttack()
    if self.isAttacking or self.isBlocking then return end

    self.isAttacking = true

    -- Play stab animation
    if self.viewmodelSystem then
        self.viewmodelSystem:playAnimation(self.currentConfig.animations.stab, 0.1)
    end

    -- Play sound
    self:playSound("swing")

    -- Lunge forward
    if self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart") then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
        bodyVelocity.Velocity = self.camera.CFrame.LookVector * self.currentConfig.lungePower
        bodyVelocity.Parent = self.player.Character.HumanoidRootPart

        Debris:AddItem(bodyVelocity, 0.3)
    end

    -- Perform attack
    task.wait(0.3)
    self:performAttack("stab")

    -- Reset attack state
    task.wait(self.currentConfig.attackSpeed * 1.5)
    self.isAttacking = false
end

-- Block (hold right click)
function MeleeSystem:startBlocking()
    if self.isAttacking then return end

    self.isBlocking = true

    -- Play block animation
    if self.viewmodelSystem then
        self.viewmodelSystem:playAnimation(self.currentConfig.animations.block, 0.2)
    end

    print("[Melee] Blocking started")
end

-- Stop blocking
function MeleeSystem:stopBlocking()
    self.isBlocking = false

    -- Stop block animation
    if self.viewmodelSystem then
        self.viewmodelSystem:stopAnimation(self.currentConfig.animations.block)
        self.viewmodelSystem:playAnimation("idle", 0.2)
    end

    print("[Melee] Blocking stopped")
end

-- Perform the actual attack
function MeleeSystem:performAttack(attackType)
    local origin = self.camera.CFrame.Position
    local direction = self.camera.CFrame.LookVector
    local range = self.currentConfig.range

    -- Perform raycast
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {
        self.player.Character,
        self.effectsFolder,
        self.camera
    }

    local hitResult = workspace:Raycast(origin, direction * range, raycastParams)

    if hitResult then
        self:handleHit(hitResult, attackType)
    else
        -- Miss effect
        self:createMissEffect()
    end

    -- Send to server
    self.attackEvent:FireServer(origin, direction, range, attackType, self.comboCount)
end

-- Handle hit detection
function MeleeSystem:handleHit(hitResult, attackType)
    local hit = hitResult.Instance
    local humanoid = hit.Parent:FindFirstChild("Humanoid") or 
        hit.Parent.Parent:FindFirstChild("Humanoid")

    if humanoid and humanoid.Parent ~= self.player.Character then
        local damage = self.currentConfig.damage
        local isBackstab = false

        -- Check for backstab
        if attackType == "stab" then
            isBackstab = self:checkBackstab(humanoid.Parent)
            if isBackstab then
                damage = self.currentConfig.backstabDamage
            end
        end

        -- Apply combo multiplier
        local comboMultiplier = 1 + (self.comboCount - 1) * 0.1
        damage = damage * comboMultiplier

        -- Send hit to server
        self.hitEvent:FireServer(humanoid, damage, isBackstab, hitResult.Position, attackType)

        -- Play hit sound
        if isBackstab then
            self:playSound("backstab")
        else
            self:playSound("hit")
        end

        -- Create hit effect
        self:createHitEffect(hitResult.Position, isBackstab)

        print("[Melee] Hit for " .. damage .. " damage" .. (isBackstab and " (BACKSTAB!)" or ""))
    else
        -- Hit environment
        self:createImpactEffect(hitResult.Position, hitResult.Normal)
    end
end

-- Check if attack is a backstab
function MeleeSystem:checkBackstab(targetCharacter)
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
        return false
    end

    local attackerPos = self.player.Character.HumanoidRootPart.Position
    local targetPos = targetCharacter.HumanoidRootPart.Position
    local targetLook = targetCharacter.HumanoidRootPart.CFrame.LookVector

    -- Vector from target to attacker
    local attackVector = (attackerPos - targetPos).Unit

    -- Check if attacker is behind target
    local angle = math.deg(math.acos(targetLook:Dot(attackVector)))

    return angle <= MELEE_SETTINGS.BACKSTAB_ANGLE
end

-- Create hit effect
function MeleeSystem:createHitEffect(position, isBackstab)
    -- Blood splatter effect
    local effect = Instance.new("Explosion")
    effect.Position = position
    effect.BlastRadius = isBackstab and 15 or 10
    effect.BlastPressure = 0
    effect.Parent = workspace

    -- Remove explosion sound
    effect.Visible = false

    -- Create custom particle effect
    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = workspace.Terrain

    local particle = Instance.new("ParticleEmitter")
    particle.Texture = "rbxasset://textures/particles/smoke_main.dds"
    particle.Rate = 0
    particle.Lifetime = NumberRange.new(0.5, 1.0)
    particle.Speed = NumberRange.new(20)
    particle.SpreadAngle = Vector2.new(45, 45)
    particle.Color = ColorSequence.new(Color3.fromRGB(139, 0, 0))
    particle.Parent = attachment

    particle:Emit(isBackstab and 30 or 15)

    Debris:AddItem(attachment, 2)
end

-- Create miss effect
function MeleeSystem:createMissEffect()
    -- Whoosh sound effect or visual
    print("[Melee] Attack missed")
end

-- Create impact effect for environment hits
function MeleeSystem:createImpactEffect(position, normal)
    -- Sparks for metal, dust for concrete, etc.
    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = workspace.Terrain

    local particle = Instance.new("ParticleEmitter")
    particle.Texture = "rbxasset://textures/particles/smoke_main.dds"
    particle.Rate = 0
    particle.Lifetime = NumberRange.new(0.3, 0.6)
    particle.Speed = NumberRange.new(10)
    particle.SpreadAngle = Vector2.new(30, 30)
    particle.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
    particle.Parent = attachment

    particle:Emit(10)

    Debris:AddItem(attachment, 1)
end

-- Play sound
function MeleeSystem:playSound(soundName)
    local sound = self.soundCache[soundName]
    if sound then
        sound:Play()
    end
end

-- Get melee info
function MeleeSystem:getInfo()
    return {
        weapon = self.currentWeapon,
        damage = self.currentConfig.damage,
        range = self.currentConfig.range,
        isAttacking = self.isAttacking,
        isBlocking = self.isBlocking,
        comboCount = self.comboCount
    }
end

-- Cleanup
function MeleeSystem:cleanup()
    self.isAttacking = false
    self.isBlocking = false

    -- Clear sound cache
    for _, sound in pairs(self.soundCache) do
        sound:Destroy()
    end
    self.soundCache = {}

    print("[Melee] Cleanup complete")
end

return MeleeSystem