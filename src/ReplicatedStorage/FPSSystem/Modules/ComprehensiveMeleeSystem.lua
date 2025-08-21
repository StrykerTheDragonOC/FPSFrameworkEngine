-- ComprehensiveMeleeSystem.lua
-- Advanced melee combat system with multiple weapon types and combat mechanics
-- Supports backstab bonuses, combos, blocking, and various melee weapons

local ComprehensiveMeleeSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

-- Melee weapon configurations
local MELEE_WEAPONS = {
    ["CombatKnife"] = {
        Name = "Combat Knife",
        Type = "Knife",
        Damage = {
            Base = 80,
            Backstab = 150,
            Headshot = 120
        },
        Stats = {
            Range = 4,
            Speed = 0.6,
            Recovery = 0.8,
            Mobility = 1.0,
            Stealth = 0.9
        },
        Animations = {
            Idle = "rbxasset://animations/Knife_Idle.rbxm",
            Attack1 = "rbxasset://animations/Knife_Slash1.rbxm",
            Attack2 = "rbxasset://animations/Knife_Stab.rbxm",
            Block = "rbxasset://animations/Knife_Block.rbxm"
        },
        Sounds = {
            Swing = "rbxasset://sounds/Sword_Swing.mp3",
            Hit = "rbxasset://sounds/Metal_Hit.mp3",
            Block = "rbxasset://sounds/Shield_Block.mp3"
        },
        UnlockLevel = 1,
        Credits = 500
    },
    
    ["TacticalTomahawk"] = {
        Name = "Tactical Tomahawk",
        Type = "Axe",
        Damage = {
            Base = 100,
            Backstab = 180,
            Headshot = 160,
            Thrown = 120
        },
        Stats = {
            Range = 5,
            Speed = 0.8,
            Recovery = 1.2,
            Mobility = 0.8,
            Stealth = 0.6
        },
        Special = {
            Throwable = true,
            ThrowRange = 25,
            ThrowDamage = 120,
            AxeReturn = true
        },
        Animations = {
            Idle = "rbxasset://animations/Axe_Idle.rbxm",
            Attack1 = "rbxasset://animations/Axe_Chop.rbxm",
            Attack2 = "rbxasset://animations/Axe_Overhead.rbxm",
            Throw = "rbxasset://animations/Axe_Throw.rbxm"
        },
        Sounds = {
            Swing = "rbxasset://sounds/Axe_Swing.mp3",
            Hit = "rbxasset://sounds/Wood_Break.mp3",
            Throw = "rbxasset://sounds/Launching_02.wav"
        },
        UnlockLevel = 10,
        Credits = 1200
    },
    
    ["RiotBaton"] = {
        Name = "Riot Baton",
        Type = "Baton",
        Damage = {
            Base = 60,
            Backstab = 90,
            Headshot = 100,
            Combo = 75
        },
        Stats = {
            Range = 4.5,
            Speed = 0.5,
            Recovery = 0.6,
            Mobility = 1.2,
            Stealth = 0.8
        },
        Special = {
            ComboAttacks = 3,
            StunChance = 0.3,
            BlockRating = 0.7
        },
        Animations = {
            Idle = "rbxasset://animations/Baton_Idle.rbxm",
            Attack1 = "rbxasset://animations/Baton_Strike1.rbxm",
            Attack2 = "rbxasset://animations/Baton_Strike2.rbxm",
            Attack3 = "rbxasset://animations/Baton_Strike3.rbxm",
            Block = "rbxasset://animations/Baton_Block.rbxm"
        },
        Sounds = {
            Swing = "rbxasset://sounds/Bat_Swing.mp3",
            Hit = "rbxasset://sounds/Punch_Hit.mp3"
        },
        UnlockLevel = 5,
        Credits = 800
    },
    
    ["Machete"] = {
        Name = "Military Machete",
        Type = "Blade",
        Damage = {
            Base = 95,
            Backstab = 170,
            Headshot = 140,
            Bleeding = 15
        },
        Stats = {
            Range = 6,
            Speed = 0.7,
            Recovery = 1.0,
            Mobility = 0.9,
            Stealth = 0.7
        },
        Special = {
            BleedEffect = true,
            BleedDuration = 5.0,
            BleedDamage = 15,
            CleaveRadius = 2
        },
        Animations = {
            Idle = "rbxasset://animations/Machete_Idle.rbxm",
            Attack1 = "rbxasset://animations/Machete_Slash.rbxm",
            Attack2 = "rbxasset://animations/Machete_Chop.rbxm"
        },
        Sounds = {
            Swing = "rbxasset://sounds/Blade_Swing.mp3",
            Hit = "rbxasset://sounds/Blade_Hit.mp3"
        },
        UnlockLevel = 15,
        Credits = 1500
    },
    
    ["Katana"] = {
        Name = "Tactical Katana",
        Type = "Sword",
        Damage = {
            Base = 110,
            Backstab = 200,
            Headshot = 180,
            Critical = 160
        },
        Stats = {
            Range = 7,
            Speed = 0.9,
            Recovery = 1.1,
            Mobility = 0.85,
            Stealth = 0.8
        },
        Special = {
            CriticalChance = 0.15,
            Deflection = 0.4,
            QuickDraw = true,
            ParryWindow = 0.3
        },
        Animations = {
            Idle = "rbxasset://animations/Katana_Idle.rbxm",
            Attack1 = "rbxasset://animations/Katana_Slash.rbxm",
            Attack2 = "rbxasset://animations/Katana_Thrust.rbxm",
            QuickDraw = "rbxasset://animations/Katana_QuickDraw.rbxm",
            Parry = "rbxasset://animations/Katana_Parry.rbxm"
        },
        Sounds = {
            Swing = "rbxasset://sounds/Katana_Swing.mp3",
            Hit = "rbxasset://sounds/Blade_Hit.mp3",
            Parry = "rbxasset://sounds/Metal_Clang.mp3"
        },
        UnlockLevel = 25,
        Credits = 2500
    }
}

-- Combat states
local COMBAT_STATES = {
    IDLE = "Idle",
    ATTACKING = "Attacking", 
    BLOCKING = "Blocking",
    STUNNED = "Stunned",
    RECOVERING = "Recovery"
}

-- Player combat data
local playerCombatData = {}
local activeMeleeAttacks = {}

function ComprehensiveMeleeSystem:init()
    print("[ComprehensiveMeleeSystem] Initializing comprehensive melee system...")
    
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
    
    -- Start combat update loop
    self:startCombatUpdateLoop()
    
    -- Setup client input if on client
    if RunService:IsClient() then
        self:setupClientInput()
    end
    
    print("[ComprehensiveMeleeSystem] System initialized")
    return true
end

function ComprehensiveMeleeSystem:initializePlayerData(player)
    playerCombatData[player.UserId] = {
        equipped = "CombatKnife",
        state = COMBAT_STATES.IDLE,
        combo = 0,
        lastAttackTime = 0,
        isBlocking = false,
        stamina = 100,
        effects = {
            bleeding = false,
            stunned = false,
            stunnedUntil = 0
        }
    }
end

function ComprehensiveMeleeSystem:getMeleeWeapon(weaponName)
    return MELEE_WEAPONS[weaponName]
end

function ComprehensiveMeleeSystem:getAllMeleeWeapons()
    return MELEE_WEAPONS
end

function ComprehensiveMeleeSystem:equipMeleeWeapon(player, weaponName)
    local playerData = playerCombatData[player.UserId]
    if not playerData then return false end
    
    local weapon = MELEE_WEAPONS[weaponName]
    if not weapon then return false end
    
    playerData.equipped = weaponName
    playerData.state = COMBAT_STATES.IDLE
    playerData.combo = 0
    
    print("[ComprehensiveMeleeSystem]", player.Name, "equipped", weapon.Name)
    return true
end

function ComprehensiveMeleeSystem:performMeleeAttack(player, attackType)
    local playerData = playerCombatData[player.UserId]
    if not playerData then return false end
    
    -- Check if player can attack
    if playerData.state ~= COMBAT_STATES.IDLE then
        return false
    end
    
    local weapon = MELEE_WEAPONS[playerData.equipped]
    if not weapon then return false end
    
    -- Check stamina
    if playerData.stamina < 20 then
        return false
    end
    
    -- Consume stamina
    playerData.stamina = math.max(0, playerData.stamina - 20)
    
    -- Set attack state
    playerData.state = COMBAT_STATES.ATTACKING
    playerData.lastAttackTime = tick()
    
    -- Handle combo attacks
    if attackType == "combo" and weapon.Special and weapon.Special.ComboAttacks then
        playerData.combo = (playerData.combo % weapon.Special.ComboAttacks) + 1
    else
        playerData.combo = 1
    end
    
    -- Perform attack
    self:executeAttack(player, weapon, attackType)
    
    -- Schedule recovery
    local recoveryTime = weapon.Stats.Recovery
    task.spawn(function()
        task.wait(recoveryTime)
        if playerData.state == COMBAT_STATES.ATTACKING then
            playerData.state = COMBAT_STATES.IDLE
        end
    end)
    
    return true
end

function ComprehensiveMeleeSystem:executeAttack(player, weapon, attackType)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create attack hitbox
    local hitbox = self:createAttackHitbox(humanoidRootPart, weapon)
    
    -- Track active attack
    local attackData = {
        player = player,
        weapon = weapon,
        attackType = attackType,
        hitbox = hitbox,
        startTime = tick(),
        duration = 0.3,
        hasHit = {}
    }
    
    activeMeleeAttacks[hitbox] = attackData
    
    -- Play attack animation
    self:playAttackAnimation(character, weapon, attackType)
    
    -- Play attack sound
    self:playSound(weapon.Sounds.Swing, humanoidRootPart.Position)
    
    -- Clean up hitbox
    task.spawn(function()
        task.wait(attackData.duration)
        if activeMeleeAttacks[hitbox] then
            activeMeleeAttacks[hitbox] = nil
            hitbox:Destroy()
        end
    end)
end

function ComprehensiveMeleeSystem:createAttackHitbox(rootPart, weapon)
    local hitbox = Instance.new("Part")
    hitbox.Name = "MeleeHitbox"
    hitbox.Size = Vector3.new(weapon.Stats.Range, 6, weapon.Stats.Range)
    hitbox.CFrame = rootPart.CFrame * CFrame.new(0, 0, -weapon.Stats.Range/2)
    hitbox.Transparency = 1
    hitbox.CanCollide = false
    hitbox.Anchored = true
    hitbox.Parent = workspace
    
    -- Visualize hitbox in testing (remove in production)
    if game:GetService("RunService"):IsStudio() then
        hitbox.Transparency = 0.8
        hitbox.Color = Color3.fromRGB(255, 0, 0)
    end
    
    -- Handle hit detection
    local connection
    connection = hitbox.Touched:Connect(function(hit)
        self:handleHitboxTouch(hitbox, hit)
    end)
    
    return hitbox
end

function ComprehensiveMeleeSystem:handleHitboxTouch(hitbox, hit)
    local attackData = activeMeleeAttacks[hitbox]
    if not attackData then return end
    
    local hitCharacter = hit.Parent
    local hitHumanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
    local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
    
    if not hitHumanoid or not hitPlayer then return end
    if hitPlayer == attackData.player then return end -- Don't hit self
    if attackData.hasHit[hitPlayer.UserId] then return end -- Don't hit same player twice
    
    -- Mark as hit
    attackData.hasHit[hitPlayer.UserId] = true
    
    -- Calculate damage
    local damage = self:calculateMeleeDamage(attackData, hitPlayer, hit)
    
    -- Apply damage
    self:applyMeleeDamage(hitPlayer, damage, attackData.player, attackData.weapon)
    
    -- Apply special effects
    self:applyMeleeEffects(hitPlayer, attackData.weapon, damage.isBackstab, damage.isCritical)
    
    -- Play hit effects
    self:playHitEffects(hit.Position, attackData.weapon, damage.amount)
    
    print("[ComprehensiveMeleeSystem]", attackData.player.Name, "hit", hitPlayer.Name, "for", damage.amount, "damage")
end

function ComprehensiveMeleeSystem:calculateMeleeDamage(attackData, targetPlayer, hitPart)
    local weapon = attackData.weapon
    local attacker = attackData.player
    local baseDamage = weapon.Damage.Base
    
    local damage = {
        amount = baseDamage,
        isBackstab = false,
        isCritical = false,
        isHeadshot = false
    }
    
    -- Check for backstab
    if self:isBackstabAttack(attacker, targetPlayer) then
        damage.amount = weapon.Damage.Backstab
        damage.isBackstab = true
    end
    
    -- Check for headshot
    if hitPart.Name == "Head" then
        damage.amount = weapon.Damage.Headshot or damage.amount * 1.5
        damage.isHeadshot = true
    end
    
    -- Check for critical hit
    if weapon.Special and weapon.Special.CriticalChance then
        if math.random() < weapon.Special.CriticalChance then
            damage.amount = weapon.Damage.Critical or damage.amount * 1.4
            damage.isCritical = true
        end
    end
    
    -- Apply combo multiplier
    local playerData = playerCombatData[attacker.UserId]
    if playerData and playerData.combo > 1 then
        local comboMultiplier = 1 + (playerData.combo - 1) * 0.1
        damage.amount = damage.amount * comboMultiplier
    end
    
    return damage
end

function ComprehensiveMeleeSystem:isBackstabAttack(attacker, target)
    local attackerChar = attacker.Character
    local targetChar = target.Character
    
    if not attackerChar or not targetChar then return false end
    
    local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not attackerRoot or not targetRoot then return false end
    
    -- Calculate angle between attacker and target's back
    local toTarget = (targetRoot.Position - attackerRoot.Position).Unit
    local targetLookDirection = targetRoot.CFrame.LookVector
    
    local dot = toTarget:Dot(-targetLookDirection)
    
    -- Backstab if attacking from behind (dot > 0.5 means within 60 degrees of directly behind)
    return dot > 0.5
end

function ComprehensiveMeleeSystem:applyMeleeDamage(player, damage, attacker, weapon)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Apply main damage
    humanoid.Health = math.max(0, humanoid.Health - damage.amount)
    
    -- Apply weapon-specific effects
    if weapon.Special then
        if weapon.Special.BleedEffect and not damage.isHeadshot then
            self:applyBleedingEffect(player, weapon.Special)
        end
        
        if weapon.Special.StunChance and math.random() < weapon.Special.StunChance then
            self:applyStunEffect(player, 2.0)
        end
    end
    
    -- Create damage indicator
    self:createDamageIndicator(character:FindFirstChild("Head"), damage)
end

function ComprehensiveMeleeSystem:applyBleedingEffect(player, weaponSpecial)
    local playerData = playerCombatData[player.UserId]
    if not playerData then return end
    
    playerData.effects.bleeding = true
    
    task.spawn(function()
        for i = 1, weaponSpecial.BleedDuration do
            task.wait(1)
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = math.max(0, humanoid.Health - weaponSpecial.BleedDamage)
                end
            end
        end
        playerData.effects.bleeding = false
    end)
end

function ComprehensiveMeleeSystem:applyStunEffect(player, duration)
    local playerData = playerCombatData[player.UserId]
    if not playerData then return end
    
    playerData.effects.stunned = true
    playerData.effects.stunnedUntil = tick() + duration
    playerData.state = COMBAT_STATES.STUNNED
    
    -- Disable player movement temporarily
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            
            task.spawn(function()
                task.wait(duration)
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
                playerData.effects.stunned = false
                if playerData.state == COMBAT_STATES.STUNNED then
                    playerData.state = COMBAT_STATES.IDLE
                end
            end)
        end
    end
end

function ComprehensiveMeleeSystem:startBlocking(player)
    local playerData = playerCombatData[player.UserId]
    if not playerData then return false end
    
    if playerData.state ~= COMBAT_STATES.IDLE then return false end
    
    local weapon = MELEE_WEAPONS[playerData.equipped]
    if not weapon or not weapon.Special or not weapon.Special.BlockRating then return false end
    
    playerData.isBlocking = true
    playerData.state = COMBAT_STATES.BLOCKING
    
    -- Play block animation
    local character = player.Character
    if character then
        self:playAnimation(character, weapon.Animations.Block)
    end
    
    return true
end

function ComprehensiveMeleeSystem:stopBlocking(player)
    local playerData = playerCombatData[player.UserId]
    if not playerData then return false end
    
    playerData.isBlocking = false
    playerData.state = COMBAT_STATES.IDLE
    
    return true
end

function ComprehensiveMeleeSystem:startCombatUpdateLoop()
    RunService.Heartbeat:Connect(function()
        -- Update player stamina
        for userId, playerData in pairs(playerCombatData) do
            if playerData.stamina < 100 then
                playerData.stamina = math.min(100, playerData.stamina + 0.5)
            end
            
            -- Check stun expiry
            if playerData.effects.stunned and tick() > playerData.effects.stunnedUntil then
                playerData.effects.stunned = false
                if playerData.state == COMBAT_STATES.STUNNED then
                    playerData.state = COMBAT_STATES.IDLE
                end
            end
        end
    end)
end

function ComprehensiveMeleeSystem:setupClientInput()
    local player = Players.LocalPlayer
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Primary attack
            local remoteEvents = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")
            local meleeAttackEvent = remoteEvents:FindFirstChild("MeleeAttack")
            if meleeAttackEvent then
                meleeAttackEvent:FireServer("primary")
            end
        elseif input.KeyCode == Enum.KeyCode.V then
            -- Secondary attack
            local remoteEvents = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")
            local meleeAttackEvent = remoteEvents:FindFirstChild("MeleeAttack")
            if meleeAttackEvent then
                meleeAttackEvent:FireServer("secondary")
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            -- Start blocking
            local remoteEvents = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")
            local meleeBlockEvent = remoteEvents:FindFirstChild("MeleeBlock")
            if meleeBlockEvent then
                meleeBlockEvent:FireServer("start")
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            -- Stop blocking
            local remoteEvents = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")
            local meleeBlockEvent = remoteEvents:FindFirstChild("MeleeBlock")
            if meleeBlockEvent then
                meleeBlockEvent:FireServer("stop")
            end
        end
    end)
end

function ComprehensiveMeleeSystem:setupRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    -- Use centralized RemoteEvents manager
    local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.Modules.RemoteEventsManager)
    
    -- Create melee remote events
    local meleeAttackEvent = RemoteEventsManager.getOrCreateRemoteEvent("MeleeAttack", "Melee weapon attacks")
    local meleeBlockEvent = RemoteEventsManager.getOrCreateRemoteEvent("MeleeBlock", "Melee weapon blocking")
    local equipMeleeEvent = RemoteEventsManager.getOrCreateRemoteEvent("EquipMelee", "Melee weapon equipping")
    
    -- Handle remote events on server
    if RunService:IsServer() then
        meleeAttackEvent.OnServerEvent:Connect(function(player, attackType)
            self:performMeleeAttack(player, attackType)
        end)
        
        meleeBlockEvent.OnServerEvent:Connect(function(player, action)
            if action == "start" then
                self:startBlocking(player)
            elseif action == "stop" then
                self:stopBlocking(player)
            end
        end)
        
        equipMeleeEvent.OnServerEvent:Connect(function(player, weaponName)
            self:equipMeleeWeapon(player, weaponName)
        end)
    end
end

function ComprehensiveMeleeSystem:playSound(soundId, position)
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.5
        sound.Parent = workspace
        sound:Play()
        
        Debris:AddItem(sound, 3)
    end
end

function ComprehensiveMeleeSystem:createDamageIndicator(head, damage)
    if not head then return end
    
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.Adornee = head
    gui.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "-" .. math.floor(damage.amount)
    label.TextColor3 = damage.isCritical and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 100, 100)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    
    -- Animate damage indicator
    local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(label, tweenInfo, {
        Position = UDim2.new(0, 0, -1, 0),
        TextTransparency = 1
    })
    tween:Play()
    
    Debris:AddItem(gui, 2)
end

return ComprehensiveMeleeSystem