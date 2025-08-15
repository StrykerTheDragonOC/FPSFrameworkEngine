-- FPSServerHandler.server.lua
-- Server-side handler for FPS system damage, hit registration, and game logic
-- Place in ServerScriptService

local FPSServerHandler = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Constants
local DEFAULT_DAMAGE = 25
local DEFAULT_HEADSHOT_MULTIPLIER = 2.0
local DEFAULT_MAX_DISTANCE = 1000
local GRENADE_DAMAGE_FALLOFF = "linear" -- linear or quadratic

-- Player data tracking
local playerData = {}

-- Remote events
local remoteEvents = {}

-- Initialize the server handler
function FPSServerHandler:init()
    print("Initializing FPS Server Handler...")
    
    -- Ensure remote events folder exists
    self:createRemoteEvents()
    
    -- Set up event connections
    self:connectRemoteEvents()
    
    -- Initialize player data tracking
    self:setupPlayerTracking()
    
    print("FPS Server Handler initialized!")
end

-- Create remote events
function FPSServerHandler:createRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        fpsSystem = Instance.new("Folder")
        fpsSystem.Name = "FPSSystem"
        fpsSystem.Parent = ReplicatedStorage
    end
    
    local remoteEventsFolder = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = fpsSystem
    end
    
    -- Weapon events
    remoteEvents.WeaponFired = self:getOrCreateRemote(remoteEventsFolder, "WeaponFired")
    remoteEvents.WeaponHit = self:getOrCreateRemote(remoteEventsFolder, "WeaponHit")  
    remoteEvents.WeaponReload = self:getOrCreateRemote(remoteEventsFolder, "WeaponReload")
    
    -- Grenade events
    remoteEvents.GrenadeEvent = self:getOrCreateRemote(remoteEventsFolder, "GrenadeEvent")
    
    -- Melee events
    remoteEvents.MeleeEvent = self:getOrCreateRemote(remoteEventsFolder, "MeleeEvent")
    
    print("Remote events created/verified")
end

-- Get or create a remote event
function FPSServerHandler:getOrCreateRemote(parent, name)
    local remote = parent:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = parent
    end
    return remote
end

-- Connect remote event handlers
function FPSServerHandler:connectRemoteEvents()
    -- Weapon firing (for validation and effects)
    remoteEvents.WeaponFired.OnServerEvent:Connect(function(player, weaponName, hitInfo)
        self:handleWeaponFired(player, weaponName, hitInfo)
    end)
    
    -- Weapon hit registration
    remoteEvents.WeaponHit.OnServerEvent:Connect(function(player, targetCharacter, hitPart, weaponName)
        self:handleWeaponHit(player, targetCharacter, hitPart, weaponName)
    end)
    
    -- Weapon reload (for validation and effects)
    remoteEvents.WeaponReload.OnServerEvent:Connect(function(player, weaponName)
        self:handleWeaponReload(player, weaponName)
    end)
    
    -- Grenade events
    remoteEvents.GrenadeEvent.OnServerEvent:Connect(function(player, eventType, data)
        self:handleGrenadeEvent(player, eventType, data)
    end)
    
    -- Melee events
    remoteEvents.MeleeEvent.OnServerEvent:Connect(function(player, eventType, data)
        self:handleMeleeEvent(player, eventType, data)
    end)
    
    print("Remote event handlers connected")
end

-- Set up player data tracking
function FPSServerHandler:setupPlayerTracking()
    -- Initialize data for existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:initializePlayerData(player)
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        self:initializePlayerData(player)
    end)
    
    -- Clean up when players leave
    Players.PlayerRemoving:Connect(function(player)
        playerData[player.UserId] = nil
    end)
end

-- Initialize data for a player
function FPSServerHandler:initializePlayerData(player)
    playerData[player.UserId] = {
        kills = 0,
        deaths = 0,
        lastWeaponFired = 0,
        lastGrenadeThrown = 0,
        health = 100,
        maxHealth = 100,
        armor = 0,
        maxArmor = 100,
        currentWeapon = nil,
        ammoData = {}
    }
    
    print("Initialized data for player:", player.Name)
end

-- Handle weapon fired event
function FPSServerHandler:handleWeaponFired(player, weaponName, hitInfo)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end
    
    -- Get weapon config for rate validation
    local weaponConfig = self:getWeaponConfig(weaponName)
    local expectedFireRate = weaponConfig and weaponConfig.firerate or 600
    local minTimeBetweenShots = 60 / expectedFireRate
    
    -- Validate firing rate with tolerance
    local now = tick()
    local timeSinceLastShot = now - playerInfo.lastWeaponFired
    
    -- Allow small tolerance for network latency (5% tolerance)
    local tolerance = minTimeBetweenShots * 0.05
    local minAllowedTime = minTimeBetweenShots - tolerance
    
    if timeSinceLastShot < minAllowedTime then
        warn(string.format("Player %s firing too fast with %s: %.3fs between shots (min: %.3fs)", 
            player.Name, weaponName, timeSinceLastShot, minTimeBetweenShots))
        
        -- Kick player if excessive rate of fire (more than 50% too fast)
        if timeSinceLastShot < minTimeBetweenShots * 0.5 then
            player:Kick("Suspected rate of fire exploit")
        end
        return
    end
    
    -- Anti-spam protection (absolute minimum - 30 rounds per second max)
    if timeSinceLastShot < 0.033 then
        warn("Player", player.Name, "firing too rapidly - possible exploit")
        player:Kick("Suspected rapid fire exploit")
        return
    end
    
    -- Update last fire time after validation
    playerInfo.lastWeaponFired = now
    
    print("Player", player.Name, "fired", weaponName, "- time between shots:", string.format("%.3fs", timeSinceLastShot))
end

-- Handle weapon hit
function FPSServerHandler:handleWeaponHit(player, targetCharacter, hitPart, weaponName)
    if not targetCharacter or not targetCharacter:FindFirstChild("Humanoid") then
        return
    end
    
    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer then return end
    
    -- Don't allow self-damage for now
    if targetPlayer == player then return end
    
    -- Get weapon config for damage calculation
    local weaponConfig = self:getWeaponConfig(weaponName)
    local baseDamage = weaponConfig and weaponConfig.damage or DEFAULT_DAMAGE
    
    -- Calculate damage based on hit location
    local damage = baseDamage
    local isHeadshot = false
    
    if hitPart and hitPart.Name == "Head" then
        damage = damage * DEFAULT_HEADSHOT_MULTIPLIER
        isHeadshot = true
    end
    
    -- Apply damage
    self:applyDamage(targetPlayer, damage, player, weaponName, isHeadshot)
    
    print(string.format("%s hit %s with %s for %d damage (headshot: %s)", 
        player.Name, targetPlayer.Name, weaponName, damage, tostring(isHeadshot)))
end

-- Handle weapon reload
function FPSServerHandler:handleWeaponReload(player, weaponName)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end
    
    print("Player", player.Name, "reloading", weaponName)
    
    -- Could add ammo validation here
end

-- Handle grenade events
function FPSServerHandler:handleGrenadeEvent(player, eventType, data)
    if eventType == "ThrowGrenade" then
        self:handleGrenadeThrow(player, data)
    elseif eventType == "ExplodeInHand" then
        self:handleGrenadeExplodeInHand(player)
    end
end

-- Handle grenade throw
function FPSServerHandler:handleGrenadeThrow(player, data)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end
    
    -- Anti-spam protection
    local now = tick()
    if now - playerInfo.lastGrenadeThrown < 1.0 then -- Max 1 grenade per second
        warn("Player", player.Name, "throwing grenades too rapidly")
        return
    end
    playerInfo.lastGrenadeThrown = now
    
    if not data or not data.Position or not data.Direction or not data.Force then
        warn("Invalid grenade throw data from", player.Name)
        return
    end
    
    -- Create server-side grenade
    self:createServerGrenade(player, data)
    
    print("Player", player.Name, "threw grenade")
end

-- Handle grenade exploding in hand
function FPSServerHandler:handleGrenadeExplodeInHand(player)
    -- Apply damage to player who cooked grenade too long
    self:applyDamage(player, 100, player, "FragGrenade", false, "Cooked grenade too long")
    
    print("Player", player.Name, "blew themselves up with a grenade")
end

-- Create server-side grenade
function FPSServerHandler:createServerGrenade(player, data)
    -- Create grenade part
    local grenade = Instance.new("Part")
    grenade.Name = "ServerGrenade"
    grenade.Shape = Enum.PartType.Ball
    grenade.Size = Vector3.new(0.6, 0.6, 0.6)  -- Make smaller
    grenade.Color = Color3.fromRGB(50, 100, 50)
    grenade.Material = Enum.Material.Metal
    grenade.Position = data.Position
    grenade.CanCollide = true
    grenade.Anchored = false
    
    -- Set physics properties (lighter and bouncier)
    -- Density, Friction, Elasticity, ElasticityWeight, FrictionWeight
    grenade.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.4, 1, 1)
    
    -- Apply velocity with multiplier for better throwing
    local throwForce = data.Force * 1.5  -- Make grenades throw farther
    grenade.Velocity = data.Direction * throwForce
    
    -- Add random spin
    grenade.RotVelocity = Vector3.new(
        math.random(-20, 20),
        math.random(-20, 20), 
        math.random(-20, 20)
    )
    
    grenade.Parent = workspace
    
    -- Store grenade data
    grenade:SetAttribute("ThrownBy", player.UserId)
    grenade:SetAttribute("RemainingTime", data.RemainingTime or 3.0)
    grenade:SetAttribute("GrenadeType", data.GrenadeType or "FragGrenade")
    
    -- Schedule explosion
    task.delay(data.RemainingTime or 3.0, function()
        if grenade and grenade.Parent then
            self:explodeGrenade(grenade, player)
        end
    end)
    
    -- Clean up after safety timeout
    Debris:AddItem(grenade, (data.RemainingTime or 3.0) + 2)
end

-- Explode grenade and apply damage
function FPSServerHandler:explodeGrenade(grenade, thrower)
    local position = grenade.Position
    
    -- Get grenade config (default to FragGrenade)
    local grenadeConfig = self:getWeaponConfig("FragGrenade") or {
        damage = 100,
        damageRadius = 10,
        maxRadius = 20
    }
    
    -- Create server-side explosion effect
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = grenadeConfig.maxRadius or 20
    explosion.BlastPressure = 0 -- We'll handle damage manually
    explosion.Parent = workspace
    
    -- Find all players in range and apply damage
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - position).Magnitude
            
            if distance <= (grenadeConfig.maxRadius or 20) then
                -- Calculate damage based on distance
                local damageMultiplier = 1.0
                if distance > (grenadeConfig.damageRadius or 10) then
                    -- Linear falloff outside damage radius
                    local falloffDistance = distance - (grenadeConfig.damageRadius or 10)
                    local maxFalloffDistance = (grenadeConfig.maxRadius or 20) - (grenadeConfig.damageRadius or 10)
                    damageMultiplier = 1.0 - (falloffDistance / maxFalloffDistance)
                end
                
                local damage = math.floor((grenadeConfig.damage or 100) * damageMultiplier)
                if damage > 0 then
                    self:applyDamage(player, damage, thrower, "FragGrenade", false, "Grenade explosion")
                end
            end
        end
    end
    
    -- Destroy the grenade
    grenade:Destroy()
    
    print("Grenade exploded at", position, "thrown by", thrower.Name)
end

-- Handle melee events
function FPSServerHandler:handleMeleeEvent(player, eventType, data)
    if eventType == "MeleeAttack" then
        self:handleMeleeAttack(player, data)
    end
end

-- Handle melee attack
function FPSServerHandler:handleMeleeAttack(player, data)
    if not data or not data.targetCharacter or not data.hitPart then
        return
    end
    
    local targetCharacter = data.targetCharacter
    if not targetCharacter:FindFirstChild("Humanoid") then
        return
    end
    
    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer or targetPlayer == player then
        return
    end
    
    -- Get melee weapon config
    local meleeConfig = self:getWeaponConfig(data.weaponName or "Knife") or {
        damage = 55,
        backstabDamage = 100
    }
    
    -- Check if it's a backstab
    local damage = meleeConfig.damage or 55
    local isBackstab = data.isBackstab or false
    
    if isBackstab then
        damage = meleeConfig.backstabDamage or 100
    end
    
    -- Apply melee damage
    self:applyDamage(targetPlayer, damage, player, data.weaponName or "Knife", false, isBackstab and "Backstab" or "Melee attack")
    
    print(string.format("%s hit %s with melee for %d damage (backstab: %s)", 
        player.Name, targetPlayer.Name, damage, tostring(isBackstab)))
end

-- Get weapon configuration
function FPSServerHandler:getWeaponConfig(weaponName)
    -- Try to get WeaponConfig module
    local success, WeaponConfig = pcall(function()
        return require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
    end)
    
    if success and WeaponConfig.Weapons and WeaponConfig.Weapons[weaponName] then
        return WeaponConfig.Weapons[weaponName]
    end
    
    -- Fallback configurations
    local fallbackConfigs = {
        G36 = { damage = 25, firerate = 600 },
        M9 = { damage = 25, firerate = 450 },
        FragGrenade = { damage = 100, damageRadius = 10, maxRadius = 20 },
        Knife = { damage = 55, backstabDamage = 100 }
    }
    
    return fallbackConfigs[weaponName]
end

-- Apply damage to a player
function FPSServerHandler:applyDamage(targetPlayer, damage, attacker, weaponName, isHeadshot, reason)
    if not targetPlayer or not targetPlayer.Character then
        return
    end
    
    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end
    
    local playerInfo = playerData[targetPlayer.UserId]
    if not playerInfo then
        self:initializePlayerData(targetPlayer)
        playerInfo = playerData[targetPlayer.UserId]
    end
    
    -- Apply damage
    local finalDamage = math.min(damage, humanoid.Health)
    humanoid.Health = humanoid.Health - finalDamage
    
    -- Update player data
    playerInfo.health = humanoid.Health
    
    -- Check for death
    if humanoid.Health <= 0 then
        self:handlePlayerDeath(targetPlayer, attacker, weaponName, isHeadshot, reason)
    end
    
    -- Create damage indicator
    self:createDamageIndicator(targetPlayer, finalDamage, isHeadshot)
end

-- Handle player death
function FPSServerHandler:handlePlayerDeath(deadPlayer, killer, weaponName, isHeadshot, reason)
    local deadPlayerInfo = playerData[deadPlayer.UserId]
    local killerInfo = killer and playerData[killer.UserId]
    
    if deadPlayerInfo then
        deadPlayerInfo.deaths = deadPlayerInfo.deaths + 1
    end
    
    if killerInfo and killer ~= deadPlayer then
        killerInfo.kills = killerInfo.kills + 1
    end
    
    -- Create death message
    local deathMessage = ""
    if killer and killer ~= deadPlayer then
        deathMessage = string.format("%s killed %s with %s", killer.Name, deadPlayer.Name, weaponName or "unknown weapon")
        if isHeadshot then
            deathMessage = deathMessage .. " (HEADSHOT!)"
        end
    else
        deathMessage = string.format("%s died (%s)", deadPlayer.Name, reason or "unknown cause")
    end
    
    print(deathMessage)
    
    -- Could send this to all players via a GUI later
    -- For now, just print to server console
end

-- Create damage indicator (for future GUI implementation)
function FPSServerHandler:createDamageIndicator(player, damage, isHeadshot)
    -- This could create a GUI element showing damage numbers
    -- For now, we'll just print it
    local damageText = tostring(damage)
    if isHeadshot then
        damageText = damageText .. " (HEADSHOT!)"
    end
    
    print("Damage indicator for", player.Name, ":", damageText)
end

-- Initialize the server handler
FPSServerHandler:init()

return FPSServerHandler
