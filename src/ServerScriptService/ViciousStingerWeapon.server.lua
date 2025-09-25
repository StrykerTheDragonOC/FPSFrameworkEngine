print("ViciousWeapon system loaded!")-- ViciousWeapon.server.lua
-- Server-side script for handling Vicious Bee weapon special abilities
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Create RemoteEvents folder if it doesn't exist
local remoteEvents = ReplicatedStorage:FindFirstChild("ViciousWeaponEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "ViciousWeaponEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local weaponHitEvent = remoteEvents:FindFirstChild("WeaponHit")
if not weaponHitEvent then
    weaponHitEvent = Instance.new("RemoteEvent")
    weaponHitEvent.Name = "WeaponHit"
    weaponHitEvent.Parent = remoteEvents
end

local overdriveEvent = remoteEvents:FindFirstChild("TriggerViciousOverdrive")
if not overdriveEvent then
    overdriveEvent = Instance.new("RemoteEvent")
    overdriveEvent.Name = "TriggerViciousOverdrive"
    overdriveEvent.Parent = remoteEvents
end

local honeyFogEvent = remoteEvents:FindFirstChild("TriggerHoneyFog")
if not honeyFogEvent then
    honeyFogEvent = Instance.new("RemoteEvent")
    honeyFogEvent.Name = "TriggerHoneyFog"
    honeyFogEvent.Parent = remoteEvents
end

local earthquakeEvent = remoteEvents:FindFirstChild("TriggerEarthquake")
if not earthquakeEvent then
    earthquakeEvent = Instance.new("RemoteEvent")
    earthquakeEvent.Name = "TriggerEarthquake"
    earthquakeEvent.Parent = remoteEvents
end

-- Weapon configuration
local WEAPON_CONFIG = {
    MAX_METER = 100,
    METER_PER_HIT = 10,
    OVERDRIVE_COOLDOWN = 45,
    HONEY_FOG_COOLDOWN = 25,
    HONEY_FOG_RADIUS = 8,
    HONEY_FOG_DURATION = 7,
    EARTHQUAKE_COOLDOWN = 30,
    EARTHQUAKE_RADIUS = 12,
    EARTHQUAKE_DURATION = 5,
    EARTHQUAKE_DAMAGE = 15,
    BLOOD_FRENZY_HEAL_PERCENT = 0.07,
    BLOOD_FRENZY_LOW_HEALTH_THRESHOLD = 0.3,
    BLOOD_FRENZY_LOW_HEALTH_BONUS = 0.5,
}

-- Player data storage
local playerData = {}
local activeFogs = {}
local activeEarthquakes = {}

local function getPlayerData(player)
    if not playerData[player.UserId] then
        playerData[player.UserId] = {
            viciousMeter = 0,
            overdriveCooldown = 0,
            honeyFogCooldown = 0,
            earthquakeCooldown = 0,
            lastOverdriveTime = 0,
            lastHoneyFogTime = 0,
            lastEarthquakeTime = 0
        }
    end
    return playerData[player.UserId]
end

local function updateViciousMeter(player, amount)
    local data = getPlayerData(player)
    data.viciousMeter = math.min(data.viciousMeter + amount, WEAPON_CONFIG.MAX_METER)
    return data.viciousMeter >= WEAPON_CONFIG.MAX_METER
end

local function findPlayersInRadius(position, radius)
    local targetsInRange = {}
    
    -- Check players
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - position).Magnitude
            if distance <= radius then
                table.insert(targetsInRange, player)
                print("Found player in range:", player.Name, "Distance:", distance)
            end
        end
    end
    
    -- Check NPCs (characters without players) - improved detection
    for _, child in pairs(workspace:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
            local npcPlayer = Players:GetPlayerFromCharacter(child)
            if not npcPlayer then -- This is an NPC
                local distance = (child.HumanoidRootPart.Position - position).Magnitude
                if distance <= radius then
                    -- Create a fake player object for NPCs
                    local fakePlayer = {
                        Character = child,
                        Name = child.Name,
                        UserId = -math.random(10000, 99999) -- Random negative ID to distinguish from real players
                    }
                    table.insert(targetsInRange, fakePlayer)
                    print("Found NPC in range:", child.Name, "Distance:", distance)
                end
            end
        end
    end
    
    print("Total targets found in radius", radius, ":", #targetsInRange)
    return targetsInRange
end

local function performViciousOverdrive(player, enemyPosition)
    local data = getPlayerData(player)
    local currentTime = tick()
    
    print("Server: Vicious Overdrive requested by", player.Name)
    
    -- Check cooldown
    if currentTime - data.lastOverdriveTime < WEAPON_CONFIG.OVERDRIVE_COOLDOWN then
        print("Server: Vicious Overdrive on cooldown for", player.Name)
        return false
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        print("Server: No character/HumanoidRootPart found for", player.Name)
        return false 
    end
    
    if not enemyPosition then 
        print("Server: No enemy position provided for", player.Name)
        return false 
    end
    
    print("Server: Executing Vicious Overdrive for", player.Name)
    
    -- Update cooldown and reset meter
    data.lastOverdriveTime = currentTime
    data.viciousMeter = 0
    
    -- Fire to all clients for visual effects
    overdriveEvent:FireAllClients(enemyPosition)
    
    -- Server-side cutscene and damage logic
    spawn(function()
        -- Find the target enemy
        local targetsInRange = findPlayersInRadius(enemyPosition, 4)
        local targetEnemy = nil
        for _, target in pairs(targetsInRange) do
            if target ~= player and target.Character then
                targetEnemy = target
                break
            end
        end
        
        if not targetEnemy or not targetEnemy.Character then
            print("No valid target found for Vicious Overdrive")
            return
        end
        
        local targetHumanoid = targetEnemy.Character:FindFirstChild("Humanoid")
        local targetRootPart = targetEnemy.Character:FindFirstChild("HumanoidRootPart")
        
        if not targetHumanoid or not targetRootPart then
            print("Target missing Humanoid or HumanoidRootPart")
            return
        end
        
        print("Freezing enemy and disabling tools for cutscene:", targetEnemy.Name)
        
        -- Phase 1: Freeze enemy and disable tools immediately
        local originalWalkSpeed = targetHumanoid.WalkSpeed
        local originalJumpPower = targetHumanoid.JumpPower
        local originalPlatformStand = targetHumanoid.PlatformStand
        
        targetHumanoid.WalkSpeed = 0
        targetHumanoid.JumpPower = 0
        targetHumanoid.PlatformStand = true
        
        -- Disable all tools for the target
        local disabledTools = {}
        if targetEnemy.Character:FindFirstChild("Backpack") then
            for _, tool in pairs(targetEnemy.Character.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    tool.Parent = targetEnemy.Character -- Move to character to disable
                    table.insert(disabledTools, tool)
                end
            end
        end
        
        -- Also disable tools in character
        for _, tool in pairs(targetEnemy.Character:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(disabledTools, tool)
            end
        end
        
        -- Disable tool activation
        for _, tool in ipairs(disabledTools) do
            tool.RequiresHandle = true
            tool.CanBeDropped = false
        end
        
        -- Phase 2: Wait for cutscene to complete (6.5 seconds total: 1s charge + 4s star + 1.5s beam)
        wait(6.5)
        
        -- Phase 3: Execute instant kill beam attack
        print("Vicious Overdrive beam hit:", targetEnemy.Name, "- INSTANT KILL!")
        
        -- Instant kill - set health to 0
        targetHumanoid.Health = 0
        
        -- Dramatic death effect
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Velocity = Vector3.new(0, 30, 0)
        bodyVelocity.Parent = targetRootPart
        
        -- Add some spin
        local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.MaxTorque = Vector3.new(4000, 4000, 4000)
        bodyAngularVelocity.AngularVelocity = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
        bodyAngularVelocity.Parent = targetRootPart
        
        -- Restore tool functionality for other tools (if target respawns)
        spawn(function()
            wait(3)
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
            if bodyAngularVelocity and bodyAngularVelocity.Parent then
                bodyAngularVelocity:Destroy()
            end
            
            -- Restore original properties (in case of respawn)
            if targetHumanoid and targetHumanoid.Parent then
                targetHumanoid.WalkSpeed = originalWalkSpeed
                targetHumanoid.JumpPower = originalJumpPower
                targetHumanoid.PlatformStand = originalPlatformStand
            end
            
            -- Restore tool functionality
            for _, tool in ipairs(disabledTools) do
                if tool and tool.Parent then
                    tool.RequiresHandle = false
                    tool.CanBeDropped = true
                end
            end
        end)
    end)
    
    return true
end

local function performHoneyFog(player, position)
    local data = getPlayerData(player)
    local currentTime = tick()
    
    print("Server: Honey Fog requested by", player.Name)
    
    -- Check cooldown
    if currentTime - data.lastHoneyFogTime < WEAPON_CONFIG.HONEY_FOG_COOLDOWN then
        print("Server: Honey Fog on cooldown for", player.Name)
        return false
    end
    
    if not position then 
        print("Server: No position provided for Honey Fog", player.Name)
        return false 
    end
    
    print("Server: Executing Honey Fog for", player.Name)
    
    -- Update cooldown
    data.lastHoneyFogTime = currentTime
    
    -- Fire to all clients for visual effects
    honeyFogEvent:FireAllClients(position)
    
    -- Create fog data for server tracking
    local fogData = {
        position = position,
        owner = player,
        startTime = currentTime,
        active = true
    }
    table.insert(activeFogs, fogData)
    
    -- Server-side fog effects
    spawn(function()
        for i = 1, WEAPON_CONFIG.HONEY_FOG_DURATION do
            if not fogData.active then break end
            
            -- Increased radius for better coverage
            local playersInRange = findPlayersInRadius(position, WEAPON_CONFIG.HONEY_FOG_RADIUS * 2)
            for _, targetPlayer in pairs(playersInRange) do
                -- Exclude the weapon owner from damage (immunity)
                if targetPlayer ~= player and targetPlayer.Character then
                    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
                    local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoid and rootPart then
                        -- Calculate distance from center for damage scaling
                        local distance = (rootPart.Position - position).Magnitude
                        local maxRadius = WEAPON_CONFIG.HONEY_FOG_RADIUS * 2
                        local distanceRatio = math.max(0, 1 - (distance / maxRadius))
                        
                        -- Scale damage based on distance (closer = more damage)
                        local baseDamage = 5
                        local scaledDamage = baseDamage + (baseDamage * distanceRatio * 2) -- 5-15 damage range
                        
                        -- Damage over time with scaling
                        humanoid:TakeDamage(scaledDamage)
                        
                        -- Slow effect (stronger when closer)
                        local slowMultiplier = 0.5 + (0.3 * distanceRatio) -- 0.5-0.8 range
                        local currentWalkSpeed = humanoid.WalkSpeed
                        humanoid.WalkSpeed = math.max(8, currentWalkSpeed * slowMultiplier)
                        
                        -- Restore speed after a short delay
                        spawn(function()
                            wait(0.5)
                            if humanoid and humanoid.Parent then
                                humanoid.WalkSpeed = 16 -- Default speed
                            end
                        end)
                        
                        print("Honey Fog hit:", targetPlayer.Name, "- Distance:", distance, "- Damage:", scaledDamage)
                    end
                end
            end
            wait(1)
        end
        
        -- Clean up fog data
        fogData.active = false
        for j = #activeFogs, 1, -1 do
            if activeFogs[j] == fogData then
                table.remove(activeFogs, j)
                break
            end
        end
    end)
    
    return true
end

local function performEarthquake(player, position)
    local data = getPlayerData(player)
    local currentTime = tick()
    
    print("Server: Earthquake requested by", player.Name)
    
    -- Check cooldown
    if currentTime - data.lastEarthquakeTime < WEAPON_CONFIG.EARTHQUAKE_COOLDOWN then
        print("Server: Earthquake on cooldown for", player.Name)
        return false
    end
    
    if not position then 
        print("Server: No position provided for Earthquake", player.Name)
        return false 
    end
    
    print("Server: Executing Earthquake for", player.Name)
    
    -- Update cooldown
    data.lastEarthquakeTime = currentTime
    
    -- Fire to all clients for visual effects
    earthquakeEvent:FireAllClients(position)
    
    -- Create earthquake data for server tracking
    local earthquakeData = {
        position = position,
        owner = player,
        startTime = currentTime,
        active = true
    }
    table.insert(activeEarthquakes, earthquakeData)
    
    -- Server-side earthquake effects
    spawn(function()
        for i = 1, WEAPON_CONFIG.EARTHQUAKE_DURATION do
            if not earthquakeData.active then break end
            
            local playersInRange = findPlayersInRadius(position, WEAPON_CONFIG.EARTHQUAKE_RADIUS)
            for _, targetPlayer in pairs(playersInRange) do
                if targetPlayer ~= player and targetPlayer.Character then
                    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
                    local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoid and rootPart then
                        -- Damage over time
                        humanoid:TakeDamage(WEAPON_CONFIG.EARTHQUAKE_DAMAGE)
                        
                        -- Knockback effect
                        local bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                        bodyVelocity.Velocity = Vector3.new(
                            math.random(-10, 10), 
                            math.random(5, 15), 
                            math.random(-10, 10)
                        )
                        bodyVelocity.Parent = rootPart
                        
                        -- Ragdoll effect - disable humanoid temporarily
                        local originalPlatformStand = humanoid.PlatformStand
                        humanoid.PlatformStand = true
                        
                        -- Remove knockback and restore control after short time
                        spawn(function()
                            wait(1.5) -- Longer ragdoll time
                            if bodyVelocity and bodyVelocity.Parent then
                                bodyVelocity:Destroy()
                            end
                            humanoid.PlatformStand = originalPlatformStand
                        end)
                    end
                end
            end
            wait(1)
        end
        
        -- Clean up earthquake data
        earthquakeData.active = false
        for j = #activeEarthquakes, 1, -1 do
            if activeEarthquakes[j] == earthquakeData then
                table.remove(activeEarthquakes, j)
                break
            end
        end
    end)
    
    return true
end

local function applyBloodFrenzy(player, damageDealt)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local currentHealth = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local healthPercent = currentHealth / maxHealth
    
    local healPercent = WEAPON_CONFIG.BLOOD_FRENZY_HEAL_PERCENT
    
    -- Bonus lifesteal when health is low
    if healthPercent <= WEAPON_CONFIG.BLOOD_FRENZY_LOW_HEALTH_THRESHOLD then
        healPercent = healPercent * (1 + WEAPON_CONFIG.BLOOD_FRENZY_LOW_HEALTH_BONUS)
    end
    
    local healAmount = damageDealt * healPercent
    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
    
    print("Blood Frenzy heal for", player.Name, ":", healAmount)
end

-- Handle weapon hit from client
weaponHitEvent.OnServerEvent:Connect(function(player, actionType, ...)
    print("Server received:", actionType, "from", player.Name)
    
    if actionType == "WEAPON_HIT" then
        local damage, hitCharacter = ...
        local data = getPlayerData(player)
        
        -- Update vicious meter
        local meterFull = updateViciousMeter(player, WEAPON_CONFIG.METER_PER_HIT)
        print("Meter updated for", player.Name, ":", data.viciousMeter, "Full:", meterFull)
        
        -- Apply Blood Frenzy healing
        applyBloodFrenzy(player, damage or 25)
        
    elseif actionType == "VICIOUS_OVERDRIVE" then
        local enemyPosition = ...
        performViciousOverdrive(player, enemyPosition)
        
    elseif actionType == "HONEY_FOG" then
        local position = ...
        performHoneyFog(player, position)
        
    elseif actionType == "EARTHQUAKE" then
        local position = ...
        performEarthquake(player, position)
    end
end)

-- Initialize player data when they join
Players.PlayerAdded:Connect(function(player)
    getPlayerData(player) -- Initialize data
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    -- Clean up player data
    playerData[player.UserId] = nil
    
    -- Clean up active effects owned by this player
    for i = #activeFogs, 1, -1 do
        if activeFogs[i].owner == player then
            activeFogs[i].active = false
            table.remove(activeFogs, i)
        end
    end
    
    for i = #activeEarthquakes, 1, -1 do
        if activeEarthquakes[i].owner == player then
            activeEarthquakes[i].active = false
            table.remove(activeEarthquakes, i)
        end
    end
end)