-- PerkSystem.lua
-- Advanced perk system for KFCS FUNNY RANDOMIZER
-- Implements double jump, speed boost, and other gameplay-altering perks
-- Place in ReplicatedStorage/FPSSystem/Modules

local PerkSystem = {}
PerkSystem.__index = PerkSystem

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Perk definitions matching original request
local PERKS = {
    -- Tier 1 Perks (Movement & Utility)
    ["Double Time"] = {
        tier = 1,
        unlock_rank = 5,
        name = "Double Time",
        description = "Increased sprint speed and duration",
        icon = "🏃",
        effects = {
            sprint_speed_multiplier = 1.3,    -- 30% faster sprint
            sprint_duration_multiplier = 1.5,  -- 50% longer sprint
            sprint_recovery_multiplier = 1.4   -- 40% faster stamina recovery
        }
    },
    
    ["Quick Fix"] = {
        tier = 1,
        unlock_rank = 10,
        name = "Quick Fix",
        description = "Faster health regeneration",
        icon = "❤️",
        effects = {
            health_regen_speed = 2.0,         -- 2x faster health regen
            health_regen_delay = 0.7,         -- Start regen 30% sooner
            max_health_bonus = 0              -- No max health change
        }
    },
    
    ["Tactical Reload"] = {
        tier = 1,
        unlock_rank = 15,
        name = "Tactical Reload",
        description = "Faster reload speed for all weapons",
        icon = "🔄",
        effects = {
            reload_speed_multiplier = 1.25,   -- 25% faster reloads
            tactical_reload_bonus = 1.4,      -- 40% faster tactical reloads
            ammo_retention = 0.1              -- 10% chance to keep round in chamber
        }
    },
    
    -- Tier 2 Perks (Combat & Stealth)
    ["Eagle Eye"] = {
        tier = 2,
        unlock_rank = 8,
        name = "Eagle Eye",
        description = "Reduced scope sway and faster ADS",
        icon = "🦅",
        effects = {
            scope_sway_reduction = 0.6,       -- 60% less scope sway
            ads_speed_multiplier = 1.2,       -- 20% faster ADS
            breath_hold_duration = 2.0        -- 2x longer breath holding
        }
    },
    
    ["Stealth"] = {
        tier = 2,
        unlock_rank = 12,
        name = "Stealth",
        description = "Quieter movement and delayed detection",
        icon = "👤",
        effects = {
            footstep_volume = 0.3,            -- 70% quieter footsteps
            detection_delay = 1.5,            -- 1.5 second delay before appearing on radar
            crouch_speed_bonus = 1.4          -- 40% faster crouch movement
        }
    },
    
    ["Explosive Resistance"] = {
        tier = 2,
        unlock_rank = 18,
        name = "Explosive Resistance",
        description = "Reduced explosive damage and effects",
        icon = "💥",
        effects = {
            explosive_damage_reduction = 0.4,  -- 40% less explosive damage
            stun_resistance = 0.6,            -- 60% less stun duration
            flak_jacket = true                -- Immunity to own explosives
        }
    },
    
    -- Tier 3 Perks (Ultimate Abilities)
    ["Double Jump"] = {
        tier = 3,
        unlock_rank = 20,
        name = "Double Jump",
        description = "Ability to jump twice in mid-air",
        icon = "⬆️",
        effects = {
            double_jump_enabled = true,
            double_jump_force = 0.8,          -- 80% of normal jump force
            air_control = 1.2,                -- 20% better air movement control
            fall_damage_reduction = 0.3       -- 30% less fall damage
        }
    },
    
    ["Speed Boost"] = {
        tier = 3,
        unlock_rank = 22,
        name = "Speed Boost",
        description = "Permanent movement speed increase",
        icon = "⚡",
        effects = {
            walk_speed_multiplier = 1.25,     -- 25% faster walking
            run_speed_multiplier = 1.3,       -- 30% faster running
            jump_height_bonus = 1.1,          -- 10% higher jumps
            acceleration_bonus = 1.4          -- 40% faster acceleration
        }
    },
    
    ["Sixth Sense"] = {
        tier = 3,
        unlock_rank = 25,
        name = "Sixth Sense",
        description = "Briefly see enemies through walls when aiming",
        icon = "👁️",
        effects = {
            wallhack_duration = 3.0,          -- 3 seconds of wall vision
            wallhack_cooldown = 15.0,         -- 15 second cooldown
            enemy_highlight = true,           -- Highlights enemies
            detection_range = 50              -- 50 stud detection range
        }
    },
    
    ["Last Stand"] = {
        tier = 3,
        unlock_rank = 30,
        name = "Last Stand",
        description = "Continue fighting with pistol when downed",
        icon = "🔫",
        effects = {
            last_stand_duration = 10.0,       -- 10 seconds in last stand
            last_stand_health = 30,           -- 30 HP in last stand
            pistol_damage_bonus = 1.5,        -- 50% more pistol damage
            crawl_speed = 0.6                 -- 60% normal crawl speed
        }
    }
}

-- Constructor
function PerkSystem.new()
    local self = setmetatable({}, PerkSystem)
    
    -- Player perk tracking
    self.playerPerks = {}
    self.activePerkEffects = {}
    self.perkCooldowns = {}
    self.doubleJumpStates = {}
    
    -- Update connections
    self.connections = {}
    
    return self
end

-- Initialize perk system
function PerkSystem:initialize()
    print("[PerkSystem] Initializing advanced perk system...")
    
    -- Setup player connections
    Players.PlayerAdded:Connect(function(player)
        self:initializePlayer(player)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:initializePlayer(player)
    end
    
    -- Start update loops
    self:startPerkUpdateLoop()
    
    -- Count perks in the dictionary
    local perkCount = 0
    for _ in pairs(PERKS) do
        perkCount = perkCount + 1
    end
    
    print("[PerkSystem] Perk system initialized with", perkCount, "perks including Double Jump and Speed Boost")
    return true
end

-- Initialize player perk data
function PerkSystem:initializePlayer(player)
    local userId = player.UserId
    
    self.playerPerks[userId] = {
        equipped = {tier1 = nil, tier2 = nil, tier3 = nil},
        unlocked = {},
        effects_active = {}
    }
    
    self.activePerkEffects[userId] = {}
    self.perkCooldowns[userId] = {}
    self.doubleJumpStates[userId] = {
        hasDoubleJump = false,
        doubleJumpUsed = false
    }
    
    print("[PerkSystem] Initialized perks for player:", player.Name)
end

-- Equip perk for player
function PerkSystem:equipPerk(player, perkName, tier)
    local userId = player.UserId
    if not self.playerPerks[userId] then
        self:initializePlayer(player)
    end
    
    local perk = PERKS[perkName]
    if not perk then
        warn("[PerkSystem] Unknown perk:", perkName)
        return false
    end
    
    if perk.tier ~= tier then
        warn("[PerkSystem] Perk tier mismatch for", perkName)
        return false
    end
    
    -- Check if perk is unlocked
    if not self:isPerkUnlocked(player, perkName) then
        warn("[PerkSystem] Perk not unlocked:", perkName, "for player:", player.Name)
        return false
    end
    
    -- Unequip current perk in this tier
    local currentPerk = self.playerPerks[userId].equipped["tier" .. tier]
    if currentPerk then
        self:removePerkEffects(player, currentPerk)
    end
    
    -- Equip new perk
    self.playerPerks[userId].equipped["tier" .. tier] = perkName
    self:applyPerkEffects(player, perkName)
    
    print("[PerkSystem] Equipped perk", perkName, "for player:", player.Name)
    return true
end

-- Check if perk is unlocked for player
function PerkSystem:isPerkUnlocked(player, perkName)
    local perk = PERKS[perkName]
    if not perk then return false end
    
    -- Get player rank from LoadoutSystem if available
    local loadoutSystem = _G.LoadoutSystem
    if loadoutSystem then
        local stats = loadoutSystem:getPlayerStats(player)
        return stats.rank >= perk.unlock_rank
    end
    
    -- Fallback: assume unlocked for testing
    return true
end

-- Apply perk effects to player
function PerkSystem:applyPerkEffects(player, perkName)
    local userId = player.UserId
    local perk = PERKS[perkName]
    if not perk then return end
    
    self.activePerkEffects[userId][perkName] = true
    
    -- Apply specific perk effects
    if perkName == "Double Jump" then
        self:enableDoubleJump(player)
    elseif perkName == "Speed Boost" then
        self:applySpeedBoost(player)
    elseif perkName == "Quick Fix" then
        self:enableQuickHealthRegen(player)
    elseif perkName == "Sixth Sense" then
        self:enableSixthSense(player)
    end
    
    print("[PerkSystem] Applied effects for perk:", perkName, "to player:", player.Name)
end

-- Remove perk effects from player
function PerkSystem:removePerkEffects(player, perkName)
    local userId = player.UserId
    
    self.activePerkEffects[userId][perkName] = nil
    
    -- Remove specific perk effects
    if perkName == "Double Jump" then
        self:disableDoubleJump(player)
    elseif perkName == "Speed Boost" then
        self:removeSpeedBoost(player)
    elseif perkName == "Quick Fix" then
        self:disableQuickHealthRegen(player)
    elseif perkName == "Sixth Sense" then
        self:disableSixthSense(player)
    end
    
    print("[PerkSystem] Removed effects for perk:", perkName, "from player:", player.Name)
end

-- Enable double jump for player
function PerkSystem:enableDoubleJump(player)
    local userId = player.UserId
    self.doubleJumpStates[userId].hasDoubleJump = true
    
    -- Setup double jump input handling
    if player == Players.LocalPlayer then
        local connection = UserInputService.JumpRequest:Connect(function()
            self:handleDoubleJumpInput(player)
        end)
        
        self.connections[userId] = self.connections[userId] or {}
        table.insert(self.connections[userId], connection)
        
        -- Reset double jump on landing
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        
        local landConnection = humanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Landed then
                self.doubleJumpStates[userId].doubleJumpUsed = false
            end
        end)
        
        table.insert(self.connections[userId], landConnection)
    end
end

-- Handle double jump input
function PerkSystem:handleDoubleJumpInput(player)
    local userId = player.UserId
    local doubleJumpState = self.doubleJumpStates[userId]
    
    if not doubleJumpState.hasDoubleJump then return end
    if doubleJumpState.doubleJumpUsed then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Check if player is in the air
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall or 
       humanoid:GetState() == Enum.HumanoidStateType.Jumping then
        
        -- Perform double jump
        local perk = PERKS["Double Jump"]
        local jumpForce = perk.effects.double_jump_force * 50 -- Roblox jump force scaling
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        bodyVelocity.Velocity = Vector3.new(0, jumpForce, 0)
        bodyVelocity.Parent = rootPart
        
        -- Remove the force after a short time
        game:GetService("Debris"):AddItem(bodyVelocity, 0.2)
        
        doubleJumpState.doubleJumpUsed = true
        
        print("[PerkSystem] Double jump executed for player:", player.Name)
    end
end

-- Apply speed boost to player
function PerkSystem:applySpeedBoost(player)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local perk = PERKS["Speed Boost"]
    
    -- Apply speed multipliers
    humanoid.WalkSpeed = humanoid.WalkSpeed * perk.effects.walk_speed_multiplier
    humanoid.JumpPower = humanoid.JumpPower * perk.effects.jump_height_bonus
    
    print("[PerkSystem] Speed boost applied to player:", player.Name)
end

-- Remove speed boost from player
function PerkSystem:removeSpeedBoost(player)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local perk = PERKS["Speed Boost"]
    
    -- Remove speed multipliers
    humanoid.WalkSpeed = humanoid.WalkSpeed / perk.effects.walk_speed_multiplier
    humanoid.JumpPower = humanoid.JumpPower / perk.effects.jump_height_bonus
    
    print("[PerkSystem] Speed boost removed from player:", player.Name)
end

-- Enable quick health regeneration
function PerkSystem:enableQuickHealthRegen(player)
    local userId = player.UserId
    
    -- This would integrate with the health system
    -- For now, just mark as active
    print("[PerkSystem] Quick health regen enabled for player:", player.Name)
end

-- Enable sixth sense ability
function PerkSystem:enableSixthSense(player)
    local userId = player.UserId
    
    -- Setup sixth sense activation (right-click while aiming)
    if player == Players.LocalPlayer then
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                self:activateSixthSense(player)
            end
        end)
        
        self.connections[userId] = self.connections[userId] or {}
        table.insert(self.connections[userId], connection)
    end
end

-- Activate sixth sense ability
function PerkSystem:activateSixthSense(player)
    local userId = player.UserId
    
    -- Check cooldown
    if self.perkCooldowns[userId]["Sixth Sense"] and 
       tick() < self.perkCooldowns[userId]["Sixth Sense"] then
        return
    end
    
    local perk = PERKS["Sixth Sense"]
    
    -- Set cooldown
    self.perkCooldowns[userId]["Sixth Sense"] = tick() + perk.effects.wallhack_cooldown
    
    -- Activate wallhack effect (would integrate with rendering system)
    print("[PerkSystem] Sixth Sense activated for player:", player.Name)
    
    -- TODO: Implement actual wallhack rendering
    
    -- Deactivate after duration
    task.delay(perk.effects.wallhack_duration, function()
        print("[PerkSystem] Sixth Sense deactivated for player:", player.Name)
    end)
end

-- Start perk update loop
function PerkSystem:startPerkUpdateLoop()
    local connection = RunService.Heartbeat:Connect(function()
        self:updatePerkEffects()
    end)
    
    table.insert(self.connections, connection)
end

-- Update perk effects
function PerkSystem:updatePerkEffects()
    for userId, perkData in pairs(self.playerPerks) do
        local player = Players:GetPlayerByUserId(userId)
        if player and player.Character then
            -- Update continuous perk effects
            self:updateContinuousEffects(player)
        end
    end
end

-- Update continuous perk effects
function PerkSystem:updateContinuousEffects(player)
    local userId = player.UserId
    local activeEffects = self.activePerkEffects[userId]
    
    if not activeEffects then return end
    
    -- Update health regeneration
    if activeEffects["Quick Fix"] then
        self:updateQuickHealthRegen(player)
    end
    
    -- Update stealth effects
    if activeEffects["Stealth"] then
        self:updateStealthEffects(player)
    end
end

-- Update quick health regeneration
function PerkSystem:updateQuickHealthRegen(player)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local perk = PERKS["Quick Fix"]
    local maxHealth = humanoid.MaxHealth
    local currentHealth = humanoid.Health
    
    -- Regenerate health faster
    if currentHealth < maxHealth then
        local regenAmount = maxHealth * 0.02 * perk.effects.health_regen_speed -- 2% per frame * multiplier
        humanoid.Health = math.min(maxHealth, currentHealth + regenAmount)
    end
end

-- Get perk info for UI
function PerkSystem:getPerkInfo(perkName)
    return PERKS[perkName]
end

-- Get all perks
function PerkSystem:getAllPerks()
    return PERKS
end

-- Get player's equipped perks
function PerkSystem:getEquippedPerks(player)
    local userId = player.UserId
    return self.playerPerks[userId] and self.playerPerks[userId].equipped or {}
end

-- Cleanup player data
function PerkSystem:cleanupPlayer(player)
    local userId = player.UserId
    
    -- Disconnect all connections for this player
    if self.connections[userId] then
        for _, connection in pairs(self.connections[userId]) do
            connection:Disconnect()
        end
        self.connections[userId] = nil
    end
    
    -- Clear player data
    self.playerPerks[userId] = nil
    self.activePerkEffects[userId] = nil
    self.perkCooldowns[userId] = nil
    self.doubleJumpStates[userId] = nil
    
    print("[PerkSystem] Cleaned up data for player:", player.Name)
end

-- Cleanup
function PerkSystem:cleanup()
    print("[PerkSystem] Cleaning up perk system...")
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        elseif typeof(connection) == "table" then
            for _, subConnection in pairs(connection) do
                subConnection:Disconnect()
            end
        end
    end
    
    self.connections = {}
    self.playerPerks = {}
    self.activePerkEffects = {}
    self.perkCooldowns = {}
    self.doubleJumpStates = {}
    
    print("[PerkSystem] Cleanup complete")
end

return PerkSystem