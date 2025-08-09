-- EnhancedMeleeSystem.lua
-- Advanced melee combat system with Include/Exclude raycasting
-- Place in ReplicatedStorage.FPSSystem.Modules

local MeleeSystem = {}
MeleeSystem.__index = MeleeSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Enhanced melee constants
local MELEE_SETTINGS = {
    -- Combat mechanics
    RANGE = {
        KNIFE = 4,
        SWORD = 6,
        HEAVY = 5,
        TOOL = 3.5
    },

    -- Attack timing
    ATTACK_DURATION = 0.4,          -- Duration of attack animation
    RECOVERY_TIME = 0.6,            -- Time before next attack
    COMBO_WINDOW = 1.2,             -- Time window for combo attacks
    HEAVY_CHARGE_TIME = 1.5,        -- Time to fully charge heavy attack

    -- Damage scaling
    LIGHT_DAMAGE_MODIFIER = 1.0,    -- Normal attack damage
    HEAVY_DAMAGE_MODIFIER = 2.5,    -- Heavy attack damage multiplier
    COMBO_DAMAGE_MODIFIER = 1.3,    -- Combo attack bonus
    BACKSTAB_MODIFIER = 3.0,        -- Backstab damage multiplier

    -- Movement and mechanics
    LUNGE_DISTANCE = 8,             -- Distance for lunge attacks
    LUNGE_SPEED = 50,               -- Speed of lunge
    BLOCK_REDUCTION = 0.75,         -- Damage reduction when blocking
    PARRY_WINDOW = 0.3,             -- Time window for successful parry
    STAMINA_COST = 15,              -- Stamina cost per attack

    -- Visual effects
    SLASH_EFFECT_LIFETIME = 0.8,    -- How long slash effects last
    BLOOD_EFFECT_COUNT = 5,         -- Number of blood particles
    SPARK_EFFECT_COUNT = 3,         -- Sparks when hitting metal

    -- Audio
    SOUND_RANGE = 25,               -- Range for melee sound effects
    VOLUME_MODIFIER = 0.8,          -- Global volume modifier
}

-- Melee weapon configurations
local MELEE_WEAPONS = {
    ["KNIFE"] = {
        name = "Combat Knife",
        type = "KNIFE",
        damage = 65,
        range = 4,
        speed = 1.2,                -- Attack speed multiplier
        critChance = 0.15,          -- 15% crit chance
        canBlock = false,
        canParry = true,
        weight = 0.3,               -- Affects swing speed
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            crit = "rbxassetid://131961136"
        },
        effects = {
            slashColor = Color3.fromRGB(255, 200, 200),
            sparkColor = Color3.fromRGB(255, 255, 100)
        }
    },

    ["KATANA"] = {
        name = "Katana",
        type = "SWORD",
        damage = 85,
        range = 6,
        speed = 1.0,
        critChance = 0.25,
        canBlock = true,
        canParry = true,
        weight = 0.8,
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            block = "rbxassetid://131961136"
        },
        effects = {
            slashColor = Color3.fromRGB(200, 255, 255),
            sparkColor = Color3.fromRGB(255, 255, 200)
        }
    },

    ["TOMAHAWK"] = {
        name = "Tomahawk",
        type = "HEAVY",
        damage = 120,
        range = 5,
        speed = 0.7,
        critChance = 0.10,
        canBlock = false,
        canParry = false,
        weight = 1.2,
        canThrow = true,            -- Can be thrown
        throwDamage = 150,
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            throw = "rbxassetid://131961136"
        },
        effects = {
            slashColor = Color3.fromRGB(200, 150, 100),
            sparkColor = Color3.fromRGB(255, 200, 100)
        }
    },

    ["CROWBAR"] = {
        name = "Crowbar",
        type = "TOOL",
        damage = 75,
        range = 3.5,
        speed = 0.9,
        critChance = 0.05,
        canBlock = true,
        canParry = false,
        weight = 1.0,
        canBreakObjects = true,     -- Can break certain objects
        sounds = {
            swing = "rbxassetid://131961136",
            hit = "rbxassetid://131961136",
            break = "rbxassetid://131961136"
        }
    }
}

-- Attack types
local ATTACK_TYPES = {
    LIGHT = "LIGHT",
    HEAVY = "HEAVY",
    COMBO = "COMBO",
    LUNGE = "LUNGE",
    THROW = "THROW"
}

-- Constructor
function MeleeSystem.new(viewmodelSystem)
    local self = setmetatable({}, MeleeSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = self.player.Character or self.player.CharacterAdded:Wait()
    self.humanoid = self.character:WaitForChild("Humanoid")
    self.rootPart = self.character:WaitForChild("HumanoidRootPart")
    self.camera = workspace.CurrentCamera
    self.viewmodel = viewmodelSystem

    -- Combat state
    self.currentWeapon = nil
    self.weaponType = "KNIFE"
    self.isAttacking = false
    self.isBlocking = false
    self.isCharging = false
    self.canAttack = true
    self.comboCount = 0
    self.lastAttackTime = 0
    self.chargeStartTime = 0

    -- Target tracking
    self.lastTarget = nil
    self.targetLockTime = 0

    -- Effects
    self.effectsFolder = workspace:FindFirstChild("MeleeEffects") or self:createEffectsFolder()
    self.activeEffects = {}

    -- Input handling
    self.inputConnections = {}

    -- Initialize
    self:connectInputs()

    print("Enhanced Melee System initialized")
    return self
end

-- Create effects folder
function MeleeSystem:createEffectsFolder()
    local folder = Instance.new("Folder")
    folder.Name = "MeleeEffects"
    folder.Parent = workspace
    return folder
end

-- Connect input handling
function MeleeSystem:connectInputs()
    -- Left click for attacks
    self.inputConnections.attack = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:startAttack()
        end
    end)

    self.inputConnections.attackEnd = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:endAttack()
        end
    end)

    -- Right click for blocking/special attacks
    self.inputConnections.block = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:startBlock()
        end
    end)

    self.inputConnections.blockEnd = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:endBlock()
        end
    end)

    -- F key for throwing (if weapon supports it)
    self.inputConnections.throw = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F then
            self:throwWeapon()
        end
    end)
end

-- Start attack sequence
function MeleeSystem:startAttack()
    if not self.canAttack or self.isAttacking or self.isBlocking then return end
    if not self.currentWeapon then return end

    local weaponConfig = MELEE_WEAPONS[self.weaponType]
    if not weaponConfig then return end

    -- Check for combo
    local timeSinceLastAttack = tick() - self.lastAttackTime
    local isCombo = timeSinceLastAttack < MELEE_SETTINGS.COMBO_WINDOW and self.comboCount > 0

    -- Determine attack type
    local attackType = ATTACK_TYPES.LIGHT
    if isCombo and self.comboCount < 3 then
        attackType = ATTACK_TYPES.COMBO
        self.comboCount = self.comboCount + 1
    else
        self.comboCount = 1
    end

    -- Start charging for potential heavy attack
    self.isCharging = true
    self.chargeStartTime = tick()

    -- Check for immediate light attack or start charge
    task.delay(0.2, function()  -- Short delay to differentiate between light and heavy
        if self.isCharging then
            self:performAttack(attackType)
        end
    end)
end

-- End attack (release button)
function MeleeSystem:endAttack()
    if not self.isCharging then return end

    local chargeTime = tick() - self.chargeStartTime
    local weaponConfig = MELEE_WEAPONS[self.weaponType]

    self.isCharging = false

    -- Determine if it should be a heavy attack
    if chargeTime >= MELEE_SETTINGS.HEAVY_CHARGE_TIME then
        self:performAttack(ATTACK_TYPES.HEAVY)
    elseif not self.isAttacking then
        self:performAttack(ATTACK_TYPES.LIGHT)
    end
end

-- Perform the actual attack
function MeleeSystem:performAttack(attackType)
    if self.isAttacking then return end

    local weaponConfig = MELEE_WEAPONS[self.weaponType]
    if not weaponConfig then return end

    self.isAttacking = true
    self.canAttack = false
    self.lastAttackTime = tick()

    -- Calculate damage based on attack type
    local baseDamage = weaponConfig.damage
    local damageMultiplier = MELEE_SETTINGS.LIGHT_DAMAGE_MODIFIER

    if attackType == ATTACK_TYPES.HEAVY then
        damageMultiplier = MELEE_SETTINGS.HEAVY_DAMAGE_MODIFIER
    elseif attackType == ATTACK_TYPES.COMBO then
        damageMultiplier = MELEE_SETTINGS.COMBO_DAMAGE_MODIFIER
    end

    local finalDamage = baseDamage * damageMultiplier

    -- Perform attack raycast
    local targets = self:performAttackRaycast(weaponConfig, attackType)

    -- Process hits
    for _, target in ipairs(targets) do
        self:processHit(target, finalDamage, attackType, weaponConfig)
    end

    -- Play attack effects
    self:playAttackEffects(weaponConfig, attackType, #targets > 0)

    -- Handle attack recovery
    local recoveryTime = MELEE_SETTINGS.RECOVERY_TIME / weaponConfig.speed

    task.delay(MELEE_SETTINGS.ATTACK_DURATION, function()
        self.isAttacking = false
    end)

    task.delay(recoveryTime, function()
        self.canAttack = true
    end)

    print("Performed", attackType, "attack with", self.weaponType, "for", finalDamage, "damage")
end

-- Perform attack raycast with Include/Exclude filtering
function MeleeSystem:performAttackRaycast(weaponConfig, attackType)
    local targets = {}
    local range = weaponConfig.range

    -- Extend range for heavy attacks and lunges
    if attackType == ATTACK_TYPES.HEAVY then
        range = range * 1.3
    elseif attackType == ATTACK_TYPES.LUNGE then
        range = MELEE_SETTINGS.LUNGE_DISTANCE
    end

    -- Create multiple rays for wider attack area
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {self.character, self.effectsFolder}

    local centerDirection = self.camera.CFrame.LookVector
    local startPosition = self.rootPart.Position + Vector3.new(0, 1, 0)

    -- Center ray
    local centerRay = workspace:Raycast(startPosition, centerDirection * range, raycastParams)
    if centerRay then
        local target = self:validateTarget(centerRay)
        if target then
            table.insert(targets, {
                character = target,
                position = centerRay.Position,
                distance = centerRay.Distance,
                isCenter = true
            })
        end
    end

    -- Side rays for wider attack
    local sideAngles = {-15, 15, -30, 30}  -- Degrees
    for _, angle in ipairs(sideAngles) do
        local sideDirection = CFrame.Angles(0, math.rad(angle), 0) * centerDirection
        local sideRay = workspace:Raycast(startPosition, sideDirection * (range * 0.8), raycastParams)

        if sideRay then
            local target = self:validateTarget(sideRay)
            if target and not self:isTargetAlreadyHit(targets, target) then
                table.insert(targets, {
                    character = target,
                    position = sideRay.Position,
                    distance = sideRay.Distance,
                    isCenter = false
                })
            end
        end
    end

    return targets
end

-- Validate if raycast hit is a valid target
function MeleeSystem:validateTarget(rayResult)
    local hit = rayResult.Instance
    local character = hit.Parent

    -- Check if it's a player character
    if character:FindFirstChild("Humanoid") and character ~= self.character then
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            return character
        end
    end

    -- Check for NPCs or other valid targets
    if character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
        return character
    end

    return nil
end

-- Check if target is already in the hit list
function MeleeSystem:isTargetAlreadyHit(targets, character)
    for _, target in ipairs(targets) do
        if target.character == character then
            return true
        end
    end
    return false
end

-- Process hit on target
function MeleeSystem:processHit(target, baseDamage, attackType, weaponConfig)
    local character = target.character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then return end

    -- Calculate final damage
    local finalDamage = baseDamage

    -- Check for critical hit
    local isCritical = math.random() < weaponConfig.critChance
    if isCritical then
        finalDamage = finalDamage * 1.5
    end

    -- Check for backstab
    local isBackstab = self:checkBackstab(rootPart)
    if isBackstab then
        finalDamage = finalDamage * MELEE_SETTINGS.BACKSTAB_MODIFIER
    end

    -- Distance damage falloff for non-center hits
    if not target.isCenter then
        finalDamage = finalDamage * 0.8
    end

    -- Apply damage (implement your damage system here)
    print("Melee hit on", character.Name, "for", finalDamage, "damage", 
        isCritical and "(CRITICAL)" or "", 
        isBackstab and "(BACKSTAB)" or "")

    -- Create hit effects
    self:createHitEffects(target.position, character, isCritical, isBackstab, weaponConfig)

    -- Apply knockback
    self:applyKnockback(character, attackType, weaponConfig)

    -- Play hit sounds
    self:playHitSound(target.position, isCritical, weaponConfig)
end

-- Check if attack is a backstab
function MeleeSystem:checkBackstab(targetRootPart)
    local targetForward = targetRootPart.CFrame.LookVector
    local attackDirection = (targetRootPart.Position - self.rootPart.Position).Unit

    -- If attack comes from behind (dot product > 0.5)
    local dot = targetForward:Dot(attackDirection)
    return dot > 0.5
end

-- Apply knockback to target
function MeleeSystem:applyKnockback(character, attackType, weaponConfig)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local direction = (rootPart.Position - self.rootPart.Position).Unit
    local force = 25

    -- Increase force for heavy attacks
    if attackType == ATTACK_TYPES.HEAVY then
        force = force * 2
    end

    -- Apply force based on weapon weight
    force = force * weaponConfig.weight

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(force * 100, 0, force * 100)
    bodyVelocity.Velocity = direction * force
    bodyVelocity.Parent = rootPart

    Debris:AddItem(bodyVelocity, 0.3)
end

-- Create hit effects
function MeleeSystem:createHitEffects(position, character, isCritical, isBackstab, weaponConfig)
    -- Blood effect
    self:createBloodEffect(position, isCritical)

    -- Slash effect
    self:createSlashEffect(position, weaponConfig.effects.slashColor, isCritical)

    -- Screen effect for critical/backstab
    if isCritical or isBackstab then
        self:createScreenEffect(isCritical, isBackstab)
    end
end

-- Create blood particle effect
function MeleeSystem:createBloodEffect(position, isCritical)
    local particleCount = isCritical and (MELEE_SETTINGS.BLOOD_EFFECT_COUNT * 2) or MELEE_SETTINGS.BLOOD_EFFECT_COUNT

    for i = 1, particleCount do
        local blood = Instance.new("Part")
        blood.Name = "BloodParticle"
        blood.Size = Vector3.new(0.1, 0.1, 0.1)
        blood.Material = Enum.Material.Neon
        blood.Color = Color3.fromRGB(200, 0, 0)
        blood.Anchored = false
        blood.CanCollide = false
        blood.Position = position + Vector3.new(
            (math.random() - 0.5) * 2,
            (math.random() - 0.5) * 2,
            (math.random() - 0.5) * 2
        )

        -- Add random velocity
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
        bodyVelocity.Velocity = Vector3.new(
            (math.random() - 0.5) * 20,
            math.random() * 10,
            (math.random() - 0.5) * 20
        )
        bodyVelocity.Parent = blood

        blood.Parent = self.effectsFolder

        -- Fade out
        task.delay(0.1, function()
            if bodyVelocity then bodyVelocity:Destroy() end
        end)

        local fadeTween = TweenService:Create(blood, 
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1, Size = Vector3.new(0.05, 0.05, 0.05)}
        )
        fadeTween:Play()

        Debris:AddItem(blood, 1.2)
    end
end

-- Create slash effect
function MeleeSystem:createSlashEffect(position, color, isCritical)
    local slash = Instance.new("Part")
    slash.Name = "SlashEffect"
    slash.Size = isCritical and Vector3.new(3, 0.1, 0.5) or Vector3.new(2, 0.1, 0.3)
    slash.Material = Enum.Material.Neon
    slash.Color = color
    slash.Anchored = true
    slash.CanCollide = false
    slash.CFrame = CFrame.lookAt(position, position + self.camera.CFrame.LookVector)
    slash.Parent = self.effectsFolder

    -- Animate slash
    local expandTween = TweenService:Create(slash,
        TweenInfo.new(MELEE_SETTINGS.SLASH_EFFECT_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = 1, Size = slash.Size * 1.5}
    )
    expandTween:Play()

    Debris:AddItem(slash, MELEE_SETTINGS.SLASH_EFFECT_LIFETIME + 0.1)
end

-- Create screen effect for critical hits
function MeleeSystem:createScreenEffect(isCritical, isBackstab)
    -- Screen flash effect (implement based on your UI system)
    if isCritical then
        print("CRITICAL HIT screen effect")
    end

    if isBackstab then
        print("BACKSTAB screen effect")
    end
end

-- Start blocking
function MeleeSystem:startBlock()
    local weaponConfig = MELEE_WEAPONS[self.weaponType]
    if not weaponConfig or not weaponConfig.canBlock then return end
    if self.isAttacking then return end

    self.isBlocking = true
    print("Started blocking with", self.weaponType)

    -- TODO: Add blocking animation and effects
end

-- End blocking
function MeleeSystem:endBlock()
    if not self.isBlocking then return end

    self.isBlocking = false
    print("Stopped blocking")
end

-- Throw weapon (if supported)
function MeleeSystem:throwWeapon()
    local weaponConfig = MELEE_WEAPONS[self.weaponType]
    if not weaponConfig or not weaponConfig.canThrow then return end
    if self.isAttacking or self.isBlocking then return end

    print("Throwing", self.weaponType)

    -- Create thrown weapon projectile
    local projectile = self:createThrownWeapon(weaponConfig)
    if projectile then
        self:launchProjectile(projectile, weaponConfig)
    end
end

-- Create thrown weapon projectile
function MeleeSystem:createThrownWeapon(weaponConfig)
    local projectile = Instance.new("Part")
    projectile.Name = "Thrown_" .. self.weaponType
    projectile.Size = Vector3.new(0.2, 0.8, 2.5)
    projectile.Material = Enum.Material.Metal
    projectile.Color = Color3.fromRGB(100, 100, 100)
    projectile.CanCollide = false

    -- Add BodyVelocity for physics
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Parent = projectile

    -- Add spinning effect
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(0, 0, 4000)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 20)
    bodyAngularVelocity.Parent = projectile

    projectile.Parent = self.effectsFolder
    return projectile
end

-- Launch thrown weapon projectile
function MeleeSystem:launchProjectile(projectile, weaponConfig)
    local direction = self.camera.CFrame.LookVector
    local force = 60

    -- Set initial position and velocity
    local startPos = self.rootPart.Position + direction * 2 + Vector3.new(0, 1, 0)
    projectile.Position = startPos

    local bodyVelocity = projectile:FindFirstChild("BodyVelocity")
    if bodyVelocity then
        bodyVelocity.Velocity = direction * force
    end

    -- Set up collision detection
    local connection
    connection = projectile.Touched:Connect(function(hit)
        local character = hit.Parent
        if character == self.character then return end

        -- Check if hit a valid target
        if character:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player then
                -- Deal throw damage
                print("Thrown weapon hit", player.Name, "for", weaponConfig.throwDamage, "damage")

                -- Create hit effects
                self:createHitEffects(projectile.Position, character, false, false, weaponConfig)

                connection:Disconnect()
                projectile:Destroy()
                return
            end
        end

        -- Hit environment
        connection:Disconnect()

        -- Stick in surface briefly
        projectile.Anchored = true
        local bodyVelocity = projectile:FindFirstChild("BodyVelocity")
        local bodyAV = projectile:FindFirstChild("BodyAngularVelocity")
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyAV then bodyAV:Destroy() end

        Debris:AddItem(projectile, 3)
    end)

    -- Auto-cleanup if doesn't hit anything
    Debris:AddItem(projectile, 5)
end

-- Play attack effects (sounds, etc.)
function MeleeSystem:playAttackEffects(weaponConfig, attackType, hasHit)
    -- Play swing sound
    if weaponConfig.sounds.swing then
        self:playSound(weaponConfig.sounds.swing, 0.7)
    end

    -- Additional effects based on attack type
    if attackType == ATTACK_TYPES.HEAVY then
        -- Heavy attack whoosh sound
        print("Heavy attack whoosh effect")
    end
end

-- Play hit sound
function MeleeSystem:playHitSound(position, isCritical, weaponConfig)
    local soundId = weaponConfig.sounds.hit or weaponConfig.sounds.swing
    local volume = isCritical and 1.0 or 0.8

    self:playSound(soundId, volume, position)
end

-- Play sound effect
function MeleeSystem:playSound(soundId, volume, position)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = (volume or 1) * MELEE_SETTINGS.VOLUME_MODIFIER
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 5
    sound.RollOffMaxDistance = MELEE_SETTINGS.SOUND_RANGE

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

-- Set melee weapon type
function MeleeSystem:setWeaponType(weaponType)
    if MELEE_WEAPONS[weaponType] then
        self.weaponType = weaponType
        print("Melee weapon changed to:", weaponType)

        -- Reset combat state when switching weapons
        self.isAttacking = false
        self.isBlocking = false
        self.isCharging = false
        self.comboCount = 0
    else
        warn("Unknown melee weapon type:", weaponType)
    end
end

-- Get available melee weapons
function MeleeSystem:getAvailableWeapons()
    local weapons = {}
    for name, config in pairs(MELEE_WEAPONS) do
        table.insert(weapons, {
            name = name,
            displayName = config.name,
            type = config.type,
            damage = config.damage,
            range = config.range
        })
    end
    return weapons
end

-- Check if player can perform action
function MeleeSystem:canPerformAction()
    return self.canAttack and not self.isAttacking and not self.isBlocking
end

-- Get current weapon info
function MeleeSystem:getCurrentWeaponInfo()
    local config = MELEE_WEAPONS[self.weaponType]
    if not config then return nil end

    return {
        name = config.name,
        type = config.type,
        damage = config.damage,
        range = config.range,
        speed = config.speed,
        canBlock = config.canBlock,
        canThrow = config.canThrow
    }
end

-- Cleanup system
function MeleeSystem:cleanup()
    print("Cleaning up Enhanced Melee System")

    -- Disconnect input connections
    for name, connection in pairs(self.inputConnections) do
        connection:Disconnect()
    end

    -- Clean up active effects
    for _, effect in ipairs(self.activeEffects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end

    -- Reset state
    self.isAttacking = false
    self.isBlocking = false
    self.isCharging = false

    print("Enhanced Melee System cleanup complete")
end

return MeleeSystem