-- MeleeSystem.lua
-- Fixed melee system with PocketKnife support and proper naming
-- Renamed from AdvancedMeleeSystem
-- Place in ReplicatedStorage/FPSSystem/Modules

local MeleeSystem = {}
MeleeSystem.__index = MeleeSystem

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Melee system settings
local MELEE_SETTINGS = {
    -- Attack mechanics
    ATTACK_RATE_LIMIT = 0.5,             -- Minimum time between attacks (anti-spam)
    COMBO_WINDOW = 1.0,                  -- Time window for combo attacks
    BACKSTAB_ANGLE = 45,                 -- Angle for backstab detection (degrees)

    -- Range settings
    DEFAULT_RANGE = 3.5,                 -- Default melee range
    EXTENDED_RANGE = 5.0,                -- Range for longer weapons

    -- Damage multipliers
    HEADSHOT_MULTIPLIER = 1.5,           -- Headshot damage multiplier
    BACKSTAB_MULTIPLIER = 2.0,           -- Backstab damage multiplier

    -- Animation settings
    ATTACK_ANIMATION_TIME = 0.3,         -- Duration of attack animation
    COMBO_ANIMATION_TIME = 0.25,         -- Duration of combo attacks
}

-- Melee weapon configurations (FIXED: Added PocketKnife)
local MELEE_WEAPONS = {
    -- FIXED: PocketKnife configuration (was missing, causing KNIFE errors)
    ["PocketKnife"] = {
        name = "PocketKnife",
        displayName = "Pocket Knife",
        type = "KNIFE",
        damage = 45,
        backstabDamage = 90,
        headshotDamage = 65,
        range = 2.5,
        speed = 2.0,              -- Attacks per second
        critChance = 0.15,
        canBlock = false,
        canParry = false,
        canCombo = true,
        weight = 0.3,             -- Light weight
        sounds = {
            swing = "rbxassetid://5810753638",
            hit = "rbxassetid://3744370687",
            hitCritical = "rbxassetid://3744371342",
            equip = "rbxassetid://6842081192",
            deploy = "rbxassetid://131961136"
        },
        effects = {
            slashColor = Color3.fromRGB(255, 220, 180),
            sparkColor = Color3.fromRGB(255, 255, 200),
            bloodColor = Color3.fromRGB(200, 0, 0)
        }
    },

    -- Legacy support for old "KNIFE" references
    ["KNIFE"] = {
        name = "KNIFE",
        displayName = "Combat Knife", 
        type = "KNIFE",
        damage = 55,
        backstabDamage = 110,
        headshotDamage = 75,
        range = 3.0,
        speed = 1.8,
        critChance = 0.20,
        canBlock = false,
        canParry = false,
        canCombo = true,
        weight = 0.4,
        sounds = {
            swing = "rbxassetid://5810753638",
            hit = "rbxassetid://3744370687", 
            hitCritical = "rbxassetid://3744371342",
            equip = "rbxassetid://6842081192"
        },
        effects = {
            slashColor = Color3.fromRGB(255, 200, 200),
            sparkColor = Color3.fromRGB(255, 255, 100),
            bloodColor = Color3.fromRGB(200, 0, 0)
        }
    },

    ["Karambit"] = {
        name = "Karambit",
        displayName = "Karambit Knife",
        type = "KNIFE",
        damage = 50,
        backstabDamage = 100,
        headshotDamage = 70,
        range = 2.8,
        speed = 2.2,              -- Very fast
        critChance = 0.25,
        canBlock = false,
        canParry = false,
        canCombo = true,
        weight = 0.25,            -- Very light
        sounds = {
            swing = "rbxassetid://5810753638",
            hit = "rbxassetid://3744370687",
            hitCritical = "rbxassetid://3744371342",
            equip = "rbxassetid://6842081192"
        },
        effects = {
            slashColor = Color3.fromRGB(255, 180, 180),
            sparkColor = Color3.fromRGB(255, 255, 150)
        }
    },

    ["Machete"] = {
        name = "Machete",
        displayName = "Military Machete",
        type = "BLADE",
        damage = 75,
        backstabDamage = 130,
        headshotDamage = 95,
        range = 4.0,
        speed = 1.4,
        critChance = 0.15,
        canBlock = true,
        canParry = true,
        canCombo = true,
        weight = 0.8,
        sounds = {
            swing = "rbxassetid://5810753638",
            hit = "rbxassetid://3744370687",
            hitCritical = "rbxassetid://3744371342",
            block = "rbxassetid://131961136"
        }
    },

    ["Sledgehammer"] = {
        name = "Sledgehammer",
        displayName = "Heavy Sledgehammer",
        type = "HEAVY",
        damage = 120,
        backstabDamage = 180,
        headshotDamage = 150,
        range = 4.5,
        speed = 0.8,              -- Slow but powerful
        critChance = 0.10,
        canBlock = true,
        canParry = false,
        canCombo = false,
        weight = 1.5,             -- Heavy
        sounds = {
            swing = "rbxassetid://5810753638",
            hit = "rbxassetid://131961136",
            hitCritical = "rbxassetid://131961136"
        }
    }
}

function MeleeSystem.new()
    local self = setmetatable({}, MeleeSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
    self.camera = workspace.CurrentCamera

    -- Melee state
    self.weaponName = "PocketKnife" -- Default to PocketKnife
    self.weaponConfig = MELEE_WEAPONS["PocketKnife"]
    self.isEquipped = false
    self.isDeployed = false

    -- Attack state
    self.isAttacking = false
    self.lastAttackTime = 0
    self.comboCount = 0
    self.comboTimer = 0

    -- Blocking state
    self.isBlocking = false
    self.canBlock = false

    -- Return slot for quick melee
    self.returnSlot = nil

    -- Connections
    self.connections = {}

    -- UI elements
    self.meleeUI = nil

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the melee system
function MeleeSystem:initialize()
    print("[MeleeSystem] Initializing melee system...")

    -- Wait for character
    self:waitForCharacter()

    -- Setup input handling
    self:setupInputHandling()

    print("[MeleeSystem] Melee system initialized")
end

-- Wait for character spawn
function MeleeSystem:waitForCharacter()
    if self.player.Character then
        self:onCharacterSpawned(self.player.Character)
    end

    self.connections.characterAdded = self.player.CharacterAdded:Connect(function(character)
        self:onCharacterSpawned(character)
    end)
end

-- Handle character spawning
function MeleeSystem:onCharacterSpawned(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid")
    self.rootPart = character:WaitForChild("HumanoidRootPart")

    -- Reset melee state on spawn
    self:reset()

    print("[MeleeSystem] Character spawned, melee system ready")
end

-- Set weapon type and configuration
function MeleeSystem:setWeapon(weaponName, config)
    -- Handle legacy KNIFE mapping to PocketKnife
    if weaponName == "KNIFE" then
        print("[MeleeSystem] Mapping legacy KNIFE to PocketKnife")
        weaponName = "PocketKnife"
    end

    self.weaponName = weaponName

    -- Use provided config or default from MELEE_WEAPONS
    if config then
        self.weaponConfig = config
    else
        self.weaponConfig = MELEE_WEAPONS[weaponName] or MELEE_WEAPONS["PocketKnife"]
    end

    -- Update blocking capability
    self.canBlock = self.weaponConfig.canBlock or false

    print("[MeleeSystem] Set melee weapon:", weaponName)
end

-- Equip melee weapon
function MeleeSystem:equip()
    if not self.isDeployed then
        warn("[MeleeSystem] Cannot equip melee weapon - not deployed")
        return false
    end

    if self.isEquipped then
        print("[MeleeSystem] Melee weapon already equipped")
        return true
    end

    self.isEquipped = true

    -- Create melee UI
    self:createMeleeUI()

    -- Play equip sound
    self:playSound(self.weaponConfig.sounds.equip, 0.5)

    print("[MeleeSystem] Melee weapon equipped:", self.weaponName)
    return true
end

-- Unequip melee weapon
function MeleeSystem:unequip()
    if not self.isEquipped then return end

    -- Stop any active actions
    self:stopAttacking()
    self:stopBlocking()

    self.isEquipped = false

    -- Destroy melee UI
    self:destroyMeleeUI()

    print("[MeleeSystem] Melee weapon unequipped")
end

-- Setup input handling for melee
function MeleeSystem:setupInputHandling()
    -- Left click for attack
    self.connections.attack = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self:canAttack() then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:attack()
        end
    end)

    -- Right click for block (if weapon supports it)
    self.connections.blockStart = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self.isEquipped or not self.canBlock then return end

        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:startBlocking()
        end
    end)

    self.connections.blockEnd = UserInputService.InputEnded:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:stopBlocking()
        end
    end)

    -- V key for quick melee
    self.connections.quickMelee = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self:canAttack() then return end

        if input.KeyCode == Enum.KeyCode.V and self.isEquipped then
            self:quickAttack()
        end
    end)
end

-- Check if can attack
function MeleeSystem:canAttack()
    if not self.isEquipped or not self.isDeployed then
        return false
    end

    if self.isAttacking then
        return false
    end

    -- Check attack rate limit
    if tick() - self.lastAttackTime < (1 / self.weaponConfig.speed) then
        return false
    end

    -- Check if in menu
    if _G.MainMenuSystem and _G.MainMenuSystem.isInMenu then
        return false
    end

    return true
end

-- Perform melee attack
function MeleeSystem:attack()
    if not self:canAttack() then return false end

    print("[MeleeSystem] Performing melee attack with:", self.weaponName)

    self.isAttacking = true
    self.lastAttackTime = tick()

    -- Determine attack type
    local attackType = "normal"
    if self.weaponConfig.canCombo and self.comboCount > 0 and tick() - self.comboTimer < MELEE_SETTINGS.COMBO_WINDOW then
        attackType = "combo"
        self.comboCount = self.comboCount + 1
    else
        self.comboCount = 1
    end

    self.comboTimer = tick()

    -- Perform raycast to find targets
    local targets = self:performMeleeRaycast()

    -- Process hits
    for _, target in ipairs(targets) do
        self:processHit(target, attackType)
    end

    -- Play attack sound
    local soundId = self.weaponConfig.sounds.swing
    if #targets > 0 then
        soundId = self.weaponConfig.sounds.hit
    end
    self:playSound(soundId, 0.8)

    -- Create attack effects
    self:createAttackEffects(attackType)

    -- Attack animation timing
    local animationTime = attackType == "combo" and MELEE_SETTINGS.COMBO_ANIMATION_TIME or MELEE_SETTINGS.ATTACK_ANIMATION_TIME

    task.delay(animationTime, function()
        self.isAttacking = false
    end)

    -- Auto-switch back if using quick melee
    if self.returnSlot then
        task.delay(animationTime + 0.2, function()
            if _G.EnhancedWeaponSystem then
                _G.EnhancedWeaponSystem:equipWeapon(self.returnSlot)
            end
            self.returnSlot = nil
        end)
    end

    return true
end

-- Quick attack (V key)
function MeleeSystem:quickAttack()
    return self:attack()
end

-- Perform melee raycast to find targets
function MeleeSystem:performMeleeRaycast()
    local targets = {}

    if not self.character or not self.rootPart then
        return targets
    end

    -- Create raycast parameters
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {self.character}

    -- Calculate raycast origin and direction
    local origin = self.camera.CFrame.Position
    local direction = self.camera.CFrame.LookVector * self.weaponConfig.range

    -- Perform multiple raycasts in a cone for better hit detection
    local raycastDirections = {
        direction,
        (self.camera.CFrame * CFrame.Angles(0, math.rad(-15), 0)).LookVector * self.weaponConfig.range,
        (self.camera.CFrame * CFrame.Angles(0, math.rad(15), 0)).LookVector * self.weaponConfig.range,
        (self.camera.CFrame * CFrame.Angles(math.rad(-10), 0, 0)).LookVector * self.weaponConfig.range,
        (self.camera.CFrame * CFrame.Angles(math.rad(10), 0, 0)).LookVector * self.weaponConfig.range
    }

    for _, rayDirection in ipairs(raycastDirections) do
        local raycastResult = workspace:Raycast(origin, rayDirection, raycastParams)

        if raycastResult then
            local hitPart = raycastResult.Instance
            local hitCharacter = hitPart.Parent

            -- Check if hit a player character
            if hitCharacter:FindFirstChild("Humanoid") and hitCharacter ~= self.character then
                local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
                if hitPlayer then
                    -- Avoid duplicate targets
                    local alreadyHit = false
                    for _, existingTarget in ipairs(targets) do
                        if existingTarget.player == hitPlayer then
                            alreadyHit = true
                            break
                        end
                    end

                    if not alreadyHit then
                        table.insert(targets, {
                            player = hitPlayer,
                            character = hitCharacter,
                            hitPart = hitPart,
                            hitPosition = raycastResult.Position,
                            distance = raycastResult.Distance
                        })
                    end
                end
            end
        end
    end

    return targets
end

-- Process hit on target
function MeleeSystem:processHit(target, attackType)
    local damage = self.weaponConfig.damage
    local isHeadshot = false
    local isBackstab = false
    local isCritical = false

    -- Check for headshot
    if target.hitPart.Name == "Head" then
        isHeadshot = true
        damage = damage * MELEE_SETTINGS.HEADSHOT_MULTIPLIER
    end

    -- Check for backstab
    if self:isBackstab(target) then
        isBackstab = true
        damage = self.weaponConfig.backstabDamage or (damage * MELEE_SETTINGS.BACKSTAB_MULTIPLIER)
    end

    -- Check for critical hit
    if math.random() < self.weaponConfig.critChance then
        isCritical = true
        damage = damage * 1.5
    end

    -- Apply combo multiplier
    if attackType == "combo" and self.comboCount > 1 then
        damage = damage * (1 + (self.comboCount - 1) * 0.1) -- 10% bonus per combo hit
    end

    -- Round damage
    damage = math.floor(damage)

    print("[MeleeSystem] Hit", target.player.Name, "for", damage, "damage", 
        isHeadshot and "(headshot)" or "",
        isBackstab and "(backstab)" or "",
        isCritical and "(critical)" or "")

    -- Send damage to server
    local remoteEvent = ReplicatedStorage:FindFirstChild("MeleeAttack")
    if remoteEvent then
        remoteEvent:FireServer({
            targetCharacter = target.character,
            hitPart = target.hitPart,
            damage = damage,
            weaponName = self.weaponName,
            isBackstab = isBackstab,
            isHeadshot = isHeadshot,
            isCritical = isCritical,
            attackType = attackType
        })
    end

    -- Play hit sound
    local soundId = isCritical and self.weaponConfig.sounds.hitCritical or self.weaponConfig.sounds.hit
    self:playSound(soundId, 1.0)

    -- Create hit effects
    self:createHitEffects(target, isHeadshot, isBackstab, isCritical)
end

-- Check if attack is a backstab
function MeleeSystem:isBackstab(target)
    if not target.character or not target.character.PrimaryPart then
        return false
    end

    local targetForward = target.character.PrimaryPart.CFrame.LookVector
    local attackDirection = (target.hitPosition - self.rootPart.Position).Unit

    -- Calculate angle between target's forward direction and attack direction
    local dotProduct = targetForward:Dot(-attackDirection)
    local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))

    return angle <= MELEE_SETTINGS.BACKSTAB_ANGLE
end

-- Start blocking
function MeleeSystem:startBlocking()
    if not self.canBlock or self.isBlocking then return end

    self.isBlocking = true

    -- Play block sound
    if self.weaponConfig.sounds.block then
        self:playSound(self.weaponConfig.sounds.block, 0.6)
    end

    -- Update UI
    self:updateMeleeUI()

    print("[MeleeSystem] Started blocking")
end

-- Stop blocking
function MeleeSystem:stopBlocking()
    if not self.isBlocking then return end

    self.isBlocking = false

    -- Update UI
    self:updateMeleeUI()

    print("[MeleeSystem] Stopped blocking")
end

-- Stop attacking
function MeleeSystem:stopAttacking()
    self.isAttacking = false
    self.comboCount = 0
end

-- Create attack visual effects
function MeleeSystem:createAttackEffects(attackType)
    if not self.rootPart then return end

    -- Create slash effect
    local effect = Instance.new("Part")
    effect.Name = "MeleeEffect"
    effect.Size = Vector3.new(0.1, 0.1, 0.1)
    effect.Position = self.rootPart.Position + self.camera.CFrame.LookVector * 2
    effect.Anchored = true
    effect.CanCollide = false
    effect.Transparency = 0.5
    effect.BrickColor = BrickColor.new(self.weaponConfig.effects.slashColor)
    effect.Parent = workspace

    -- Animate effect
    local tween = TweenService:Create(effect, TweenInfo.new(0.3), {
        Transparency = 1,
        Size = Vector3.new(3, 3, 0.1)
    })
    tween:Play()

    -- Cleanup
    task.delay(0.5, function()
        if effect then
            effect:Destroy()
        end
    end)
end

-- Create hit visual effects
function MeleeSystem:createHitEffects(target, isHeadshot, isBackstab, isCritical)
    if not target.hitPosition then return end

    -- Create spark effect
    local spark = Instance.new("Part")
    spark.Name = "HitSpark"
    spark.Size = Vector3.new(0.2, 0.2, 0.2)
    spark.Position = target.hitPosition
    spark.Anchored = true
    spark.CanCollide = false
    spark.Transparency = 0.3
    spark.BrickColor = BrickColor.new(self.weaponConfig.effects.sparkColor)
    spark.Parent = workspace

    -- Special effects for critical hits
    if isCritical or isBackstab then
        spark.BrickColor = BrickColor.new("Bright red")
        spark.Size = Vector3.new(0.4, 0.4, 0.4)
    end

    -- Animate spark
    local sparkTween = TweenService:Create(spark, TweenInfo.new(0.2), {
        Transparency = 1,
        Size = Vector3.new(0.1, 0.1, 0.1)
    })
    sparkTween:Play()

    -- Cleanup
    task.delay(0.3, function()
        if spark then
            spark:Destroy()
        end
    end)
end

-- Create melee UI
function MeleeSystem:createMeleeUI()
    if self.meleeUI then
        self.meleeUI:Destroy()
    end

    local playerGui = self.player:WaitForChild("PlayerGui")

    -- Create main UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MeleeUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    self.meleeUI = screenGui

    -- Melee indicator frame
    local frame = Instance.new("Frame")
    frame.Name = "MeleeFrame"
    frame.Size = UDim2.new(0.12, 0, 0.06, 0)
    frame.Position = UDim2.new(0.44, 0, 0.88, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame

    -- Weapon name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = self.weaponConfig.displayName or self.weaponName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = frame

    -- Status label (blocking, combo, etc.)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.6, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.Parent = frame
end

-- Update melee UI
function MeleeSystem:updateMeleeUI()
    if not self.meleeUI then return end

    local frame = self.meleeUI:FindFirstChild("MeleeFrame")
    if not frame then return end

    local statusLabel = frame:FindFirstChild("StatusLabel")
    if not statusLabel then return end

    -- Update status
    if self.isBlocking then
        statusLabel.Text = "BLOCKING"
        statusLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
    elseif self.isAttacking then
        statusLabel.Text = "ATTACKING"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
    elseif self.comboCount > 1 then
        statusLabel.Text = "COMBO x" .. self.comboCount
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    end
end

-- Destroy melee UI
function MeleeSystem:destroyMeleeUI()
    if self.meleeUI then
        self.meleeUI:Destroy()
        self.meleeUI = nil
    end
end

-- Play sound effect
function MeleeSystem:playSound(soundId, volume)
    if not soundId or not self.rootPart then return end

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

-- Set return slot for quick melee
function MeleeSystem:setReturnSlot(slot)
    self.returnSlot = slot
end

-- Reset melee system state
function MeleeSystem:reset()
    print("[MeleeSystem] Resetting melee system...")

    -- Stop all actions
    self:stopAttacking()
    self:stopBlocking()
    self:unequip()

    -- Reset state
    self.isDeployed = false
    self.isEquipped = false
    self.comboCount = 0
    self.returnSlot = nil

    print("[MeleeSystem] Reset complete")
end

-- Set deployed state
function MeleeSystem:setDeployed(deployed)
    self.isDeployed = deployed
    print("[MeleeSystem] Deployment state:", deployed)
end

-- Cleanup
function MeleeSystem:cleanup()
    print("[MeleeSystem] Cleaning up melee system...")

    -- Reset state
    self:reset()

    -- Disconnect all connections
    for name, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    -- Destroy UI
    self:destroyMeleeUI()

    -- Clear references
    self.connections = {}
    self.weaponConfig = nil

    print("[MeleeSystem] Melee system cleanup complete")
end

return MeleeSystem