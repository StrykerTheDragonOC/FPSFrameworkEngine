-- Server-Side Validation and Anti-Cheat System
-- Place in ServerScriptService.FPSServerSystems.ServerValidationSystem
local ServerValidationSystem = {}
ServerValidationSystem.__index = ServerValidationSystem

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")

-- Anti-cheat configuration
local ANTICHEAT_CONFIG = {
    -- Rate limiting
    MAX_FIRE_RATE = 25.0, -- bullets per second (max possible)
    MAX_DAMAGE_PER_SECOND = 2000,
    MAX_HITS_PER_SHOT = 5, -- For penetration

    -- Physics validation
    MAX_BULLET_SPEED = 1200, -- m/s
    MIN_BULLET_SPEED = 100, -- m/s
    MAX_DAMAGE_DISTANCE = 1000, -- studs

    -- Behavior detection
    SUSPICIOUS_ACCURACY_THRESHOLD = 0.95, -- 95%+ accuracy is suspicious
    HEADSHOT_PERCENTAGE_THRESHOLD = 0.8, -- 80%+ headshots is suspicious
    RAPID_KILL_THRESHOLD = 5, -- kills per 10 seconds

    -- Penalties
    WARNING_THRESHOLD = 3,
    KICK_THRESHOLD = 5,
    BAN_THRESHOLD = 10,

    -- Data validation
    VALIDATE_RAYCAST_RESULTS = true,
    VALIDATE_DAMAGE_CALCULATIONS = true,
    VALIDATE_WEAPON_STATS = true
}

-- Player tracking data
local playerData = {}
local suspiciousActivity = {}

function ServerValidationSystem.new()
    local self = setmetatable({}, ServerValidationSystem)

    -- Remote events
    self.remoteEvents = {}
    self.remoteFunctions = {}

    -- Weapon configurations
    self.weaponConfigs = {}

    -- Statistics tracking
    self.serverStats = {
        totalShots = 0,
        totalHits = 0,
        totalDamage = 0,
        suspiciousEvents = 0,
        playersKicked = 0
    }

    -- Initialize system
    self:initialize()

    return self
end

-- Initialize the server validation system
function ServerValidationSystem:initialize()
    print("Initializing Server Validation System...")

    -- Setup remote events
    self:setupRemoteEvents()

    -- Load weapon configurations
    self:loadWeaponConfigurations()

    -- Setup player tracking
    self:setupPlayerTracking()

    -- Start monitoring loops
    self:startMonitoring()

    print("Server Validation System initialized")
end

-- Setup remote events for client-server communication
function ServerValidationSystem:setupRemoteEvents()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "RemoteEvents"
        remoteFolder.Parent = ReplicatedStorage
    end

    -- Weapon firing event
    local weaponFiredEvent = Instance.new("RemoteEvent")
    weaponFiredEvent.Name = "WeaponFired"
    weaponFiredEvent.Parent = remoteFolder
    self.remoteEvents.weaponFired = weaponFiredEvent

    -- Weapon hit event
    local weaponHitEvent = Instance.new("RemoteEvent")
    weaponHitEvent.Name = "WeaponHit"
    weaponHitEvent.Parent = remoteFolder
    self.remoteEvents.weaponHit = weaponHitEvent

    -- Weapon reload event
    local weaponReloadEvent = Instance.new("RemoteEvent")
    weaponReloadEvent.Name = "WeaponReload"
    weaponReloadEvent.Parent = remoteFolder
    self.remoteEvents.weaponReload = weaponReloadEvent

    -- Player damage event
    local playerDamageEvent = Instance.new("RemoteEvent")
    playerDamageEvent.Name = "PlayerDamage"
    playerDamageEvent.Parent = remoteFolder
    self.remoteEvents.playerDamage = playerDamageEvent

    -- Kill feed event
    local killFeedEvent = Instance.new("RemoteEvent")
    killFeedEvent.Name = "KillFeed"
    killFeedEvent.Parent = remoteFolder
    self.remoteEvents.killFeed = killFeedEvent

    -- Connect event handlers
    self:connectEventHandlers()
end

-- Connect event handlers
function ServerValidationSystem:connectEventHandlers()
    -- Handle weapon firing
    self.remoteEvents.weaponFired.OnServerEvent:Connect(function(player, fireData)
        self:handleWeaponFired(player, fireData)
    end)

    -- Handle weapon hits
    self.remoteEvents.weaponHit.OnServerEvent:Connect(function(player, hitData)
        self:handleWeaponHit(player, hitData)
    end)

    -- Handle reloading
    self.remoteEvents.weaponReload.OnServerEvent:Connect(function(player, weaponName)
        self:handleWeaponReload(player, weaponName)
    end)
end

-- Load weapon configurations for validation
function ServerValidationSystem:loadWeaponConfigurations()
    -- This would typically load from a secure data source
    self.weaponConfigs = {
        ["G36"] = {
            damage = 34,
            fireRate = 650, -- RPM
            muzzleVelocity = 990,
            magazineSize = 30,
            maxAmmo = 120,
            reloadTime = 2.5,
            accuracy = 0.85,
            range = 150
        },
        ["AWP"] = {
            damage = 115,
            fireRate = 40,
            muzzleVelocity = 853,
            magazineSize = 10,
            maxAmmo = 30,
            reloadTime = 3.8,
            accuracy = 0.95,
            range = 300
        },
        ["M9"] = {
            damage = 26,
            fireRate = 350,
            muzzleVelocity = 380,
            magazineSize = 15,
            maxAmmo = 60,
            reloadTime = 1.8,
            accuracy = 0.75,
            range = 50
        }
        -- Add more weapon configs as needed
    }
end

-- Setup player tracking
function ServerValidationSystem:setupPlayerTracking()
    local function onPlayerAdded(player)
        playerData[player.UserId] = {
            player = player,
            joinTime = tick(),

            -- Weapon statistics
            shotsFired = 0,
            shotsHit = 0,
            damage = 0,
            kills = 0,
            deaths = 0,
            headshots = 0,

            -- Rate limiting
            lastShotTime = 0,
            shotsInLastSecond = 0,
            damageInLastSecond = 0,

            -- Suspicious activity tracking
            rapidKills = 0,
            lastKillTime = 0,
            suspiciousEvents = 0,

            -- Current weapon state
            currentWeapon = nil,
            currentAmmo = 0,
            isReloading = false,

            -- Position tracking for validation
            lastPosition = Vector3.new(0, 0, 0),
            lastUpdateTime = tick()
        }

        print("Player tracking initialized for:", player.Name)
    end

    local function onPlayerRemoving(player)
        -- Save player statistics before they leave
        self:savePlayerStatistics(player)
        playerData[player.UserId] = nil
        suspiciousActivity[player.UserId] = nil
        print("Player tracking cleaned up for:", player.Name)
    end

    -- Connect events
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
end

-- Handle weapon fired event
function ServerValidationSystem:handleWeaponFired(player, fireData)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end

    -- Validate fire data structure
    if not self:validateFireData(fireData) then
        self:flagSuspiciousActivity(player, "Invalid fire data structure")
        return
    end

    -- Validate weapon
    local weaponConfig = self.weaponConfigs[fireData.weaponName]
    if not weaponConfig then
        self:flagSuspiciousActivity(player, "Invalid weapon: " .. tostring(fireData.weaponName))
        return
    end

    -- Rate limiting validation
    local currentTime = tick()
    local timeSinceLastShot = currentTime - playerInfo.lastShotTime
    local maxFireInterval = 60 / weaponConfig.fireRate -- Convert RPM to seconds per shot

    if timeSinceLastShot < maxFireInterval * 0.8 then -- 20% tolerance
        self:flagSuspiciousActivity(player, "Fire rate too high")
        return
    end

    -- Update player statistics
    playerInfo.shotsFired = playerInfo.shotsFired + 1
    playerInfo.lastShotTime = currentTime

    -- Validate trajectory if provided
    if fireData.trajectory and ANTICHEAT_CONFIG.VALIDATE_RAYCAST_RESULTS then
        if not self:validateTrajectory(player, fireData.trajectory, weaponConfig) then
            self:flagSuspiciousActivity(player, "Invalid bullet trajectory")
            return
        end
    end

    -- Process the shot (could trigger hit detection)
    self:processValidatedShot(player, fireData, weaponConfig)

    -- Update server statistics
    self.serverStats.totalShots = self.serverStats.totalShots + 1
end

-- Handle weapon hit event
function ServerValidationSystem:handleWeaponHit(player, hitData)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end

    -- Validate hit data
    if not self:validateHitData(player, hitData) then
        self:flagSuspiciousActivity(player, "Invalid hit data")
        return
    end

    -- Validate damage calculation
    local calculatedDamage = self:calculateDamage(hitData)
    if math.abs(hitData.damage - calculatedDamage) > 5 then -- 5 damage tolerance
        self:flagSuspiciousActivity(player, "Invalid damage calculation")
        return
    end

    -- Validate hit distance
    local distance = self:calculateHitDistance(player, hitData.hitPosition)
    if distance > ANTICHEAT_CONFIG.MAX_DAMAGE_DISTANCE then
        self:flagSuspiciousActivity(player, "Hit distance too far")
        return
    end

    -- Apply damage if valid
    self:applyValidatedDamage(player, hitData)

    -- Update statistics
    playerInfo.shotsHit = playerInfo.shotsHit + 1
    playerInfo.damage = playerInfo.damage + hitData.damage

    if hitData.hitPart == "Head" then
        playerInfo.headshots = playerInfo.headshots + 1
    end

    -- Check for suspicious accuracy
    local accuracy = playerInfo.shotsHit / math.max(playerInfo.shotsFired, 1)
    if accuracy > ANTICHEAT_CONFIG.SUSPICIOUS_ACCURACY_THRESHOLD and playerInfo.shotsFired > 50 then
        self:flagSuspiciousActivity(player, "Suspiciously high accuracy: " .. tostring(accuracy))
    end

    -- Check for suspicious headshot percentage
    local headshotPercentage = playerInfo.headshots / math.max(playerInfo.shotsHit, 1)
    if headshotPercentage > ANTICHEAT_CONFIG.HEADSHOT_PERCENTAGE_THRESHOLD and playerInfo.shotsHit > 20 then
        self:flagSuspiciousActivity(player, "Suspiciously high headshot percentage: " .. tostring(headshotPercentage))
    end

    self.serverStats.totalHits = self.serverStats.totalHits + 1
    self.serverStats.totalDamage = self.serverStats.totalDamage + hitData.damage
end

-- Handle weapon reload event
function ServerValidationSystem:handleWeaponReload(player, weaponName)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end

    local weaponConfig = self.weaponConfigs[weaponName]
    if not weaponConfig then return end

    -- Validate reload timing
    if playerInfo.isReloading then
        self:flagSuspiciousActivity(player, "Reload spam detected")
        return
    end

    -- Set reload state
    playerInfo.isReloading = true
    playerInfo.currentAmmo = weaponConfig.magazineSize

    -- Clear reload state after reload time
    wait(weaponConfig.reloadTime)
    playerInfo.isReloading = false
end

-- Validate fire data structure
function ServerValidationSystem:validateFireData(fireData)
    if type(fireData) ~= "table" then return false end

    local requiredFields = {"weaponName", "origin", "direction", "timestamp"}
    for _, field in ipairs(requiredFields) do
        if fireData[field] == nil then
            return false
        end
    end

    -- Validate data types
    if type(fireData.weaponName) ~= "string" then return false end
    if typeof(fireData.origin) ~= "Vector3" then return false end
    if typeof(fireData.direction) ~= "Vector3" then return false end
    if type(fireData.timestamp) ~= "number" then return false end

    return true
end

-- Validate hit data
function ServerValidationSystem:validateHitData(player, hitData)
    if type(hitData) ~= "table" then return false end

    local requiredFields = {"victim", "damage", "hitPosition", "hitPart", "weaponName"}
    for _, field in ipairs(requiredFields) do
        if hitData[field] == nil then
            return false
        end
    end

    -- Validate victim is a valid player
    if not hitData.victim or not hitData.victim:IsA("Player") then
        return false
    end

    -- Prevent self-damage (unless friendly fire is enabled)
    if hitData.victim == player and not ANTICHEAT_CONFIG.FRIENDLY_FIRE then
        return false
    end

    -- Validate damage range
    local weaponConfig = self.weaponConfigs[hitData.weaponName]
    if weaponConfig then
        if hitData.damage > weaponConfig.damage * 3 then -- Max 3x damage for headshots
            return false
        end
    end

    return true
end

-- Validate bullet trajectory
function ServerValidationSystem:validateTrajectory(player, trajectory, weaponConfig)
    if not trajectory or #trajectory == 0 then return false end

    local startPoint = trajectory[1]
    local endPoint = trajectory[#trajectory]

    -- Validate bullet speed
    local totalDistance = 0
    local totalTime = 0

    for i = 2, #trajectory do
        local segment = trajectory[i]
        local prevSegment = trajectory[i-1]

        local distance = (segment.position - prevSegment.position).Magnitude
        local timeStep = segment.time - prevSegment.time

        if timeStep > 0 then
            local speed = distance / timeStep

            if speed > ANTICHEAT_CONFIG.MAX_BULLET_SPEED or speed < ANTICHEAT_CONFIG.MIN_BULLET_SPEED then
                return false
            end
        end

        totalDistance = totalDistance + distance
        totalTime = totalTime + timeStep
    end

    -- Validate overall trajectory makes sense
    local averageSpeed = totalDistance / math.max(totalTime, 0.001)
    local expectedSpeed = weaponConfig.muzzleVelocity or 500

    if math.abs(averageSpeed - expectedSpeed) > expectedSpeed * 0.5 then -- 50% tolerance
        return false
    end

    return true
end

-- Calculate expected damage
function ServerValidationSystem:calculateDamage(hitData)
    local weaponConfig = self.weaponConfigs[hitData.weaponName]
    if not weaponConfig then return 0 end

    local baseDamage = weaponConfig.damage
    local multiplier = 1.0

    -- Apply hit location multipliers
    if hitData.hitPart == "Head" then
        multiplier = 2.5
    elseif hitData.hitPart:find("Arm") or hitData.hitPart:find("Leg") then
        multiplier = 0.8
    elseif hitData.hitPart == "Torso" or hitData.hitPart == "UpperTorso" then
        multiplier = 1.2
    end

    return math.floor(baseDamage * multiplier)
end

-- Calculate hit distance
function ServerValidationSystem:calculateHitDistance(player, hitPosition)
    if not player.Character or not player.Character.PrimaryPart then
        return 1000 -- Return max distance if can't calculate
    end

    local playerPosition = player.Character.PrimaryPart.Position
    return (hitPosition - playerPosition).Magnitude
end

-- Apply validated damage
function ServerValidationSystem:applyValidatedDamage(attacker, hitData)
    local victim = hitData.victim
    if not victim or not victim.Character then return end

    local humanoid = victim.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Apply damage
    humanoid:TakeDamage(hitData.damage)

    -- Check for kill
    if humanoid.Health <= 0 then
        self:handlePlayerKill(attacker, victim, hitData)
    end

    -- Broadcast damage event to all clients for effects
    self.remoteEvents.playerDamage:FireAllClients(victim, hitData.damage, hitData.hitPosition)
end

-- Handle player kill
function ServerValidationSystem:handlePlayerKill(killer, victim, hitData)
    local killerInfo = playerData[killer.UserId]
    local victimInfo = playerData[victim.UserId]

    if killerInfo then
        killerInfo.kills = killerInfo.kills + 1

        -- Check for rapid kills
        local currentTime = tick()
        if currentTime - killerInfo.lastKillTime < 2.0 then -- 2 seconds
            killerInfo.rapidKills = killerInfo.rapidKills + 1

            if killerInfo.rapidKills >= ANTICHEAT_CONFIG.RAPID_KILL_THRESHOLD then
                self:flagSuspiciousActivity(killer, "Rapid kills detected")
            end
        else
            killerInfo.rapidKills = 0
        end

        killerInfo.lastKillTime = currentTime
    end

    if victimInfo then
        victimInfo.deaths = victimInfo.deaths + 1
    end

    -- Broadcast kill to all clients for kill feed
    local isHeadshot = hitData.hitPart == "Head"
    self.remoteEvents.killFeed:FireAllClients(killer.Name, victim.Name, hitData.weaponName, isHeadshot)

    print(killer.Name .. " killed " .. victim.Name .. " with " .. hitData.weaponName)
end

-- Flag suspicious activity
function ServerValidationSystem:flagSuspiciousActivity(player, reason)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end

    playerInfo.suspiciousEvents = playerInfo.suspiciousEvents + 1

    if not suspiciousActivity[player.UserId] then
        suspiciousActivity[player.UserId] = {}
    end

    table.insert(suspiciousActivity[player.UserId], {
        reason = reason,
        timestamp = tick(),
        evidence = {} -- Could store additional evidence
    })

    print("SUSPICIOUS ACTIVITY - " .. player.Name .. ": " .. reason)

    -- Apply penalties based on severity
    if playerInfo.suspiciousEvents >= ANTICHEAT_CONFIG.BAN_THRESHOLD then
        self:banPlayer(player, "Multiple suspicious activities detected")
    elseif playerInfo.suspiciousEvents >= ANTICHEAT_CONFIG.KICK_THRESHOLD then
        self:kickPlayer(player, "Suspicious activity detected")
    elseif playerInfo.suspiciousEvents >= ANTICHEAT_CONFIG.WARNING_THRESHOLD then
        self:warnPlayer(player, "Suspicious activity detected")
    end

    self.serverStats.suspiciousEvents = self.serverStats.suspiciousEvents + 1
end

-- Warn player
function ServerValidationSystem:warnPlayer(player, reason)
    -- Send warning to player
    local message = "WARNING: " .. reason .. ". Further violations may result in a kick or ban."
    player:Kick(message) -- For now, just kick. In a real game, you'd show a warning GUI
end

-- Kick player
function ServerValidationSystem:kickPlayer(player, reason)
    local message = "You have been kicked for: " .. reason
    player:Kick(message)
    self.serverStats.playersKicked = self.serverStats.playersKicked + 1
end

-- Ban player (in a real game, this would interface with a ban system)
function ServerValidationSystem:banPlayer(player, reason)
    local message = "You have been banned for: " .. reason
    -- In a real game, you'd add them to a ban database
    player:Kick(message)
    print("BANNED PLAYER: " .. player.Name .. " for " .. reason)
end

-- Process validated shot
function ServerValidationSystem:processValidatedShot(player, fireData, weaponConfig)
    -- Here you could implement server-side hit detection if needed
    -- For now, we trust client hit detection but validate the results

    -- You could also replicate muzzle flash and other effects to all clients
    -- self.remoteEvents.weaponFired:FireAllClients(player, fireData)
end

-- Save player statistics
function ServerValidationSystem:savePlayerStatistics(player)
    local playerInfo = playerData[player.UserId]
    if not playerInfo then return end

    -- In a real game, you'd save to a DataStore
    local stats = {
        shotsFired = playerInfo.shotsFired,
        shotsHit = playerInfo.shotsHit,
        damage = playerInfo.damage,
        kills = playerInfo.kills,
        deaths = playerInfo.deaths,
        headshots = playerInfo.headshots,
        suspiciousEvents = playerInfo.suspiciousEvents,
        playTime = tick() - playerInfo.joinTime
    }

    print("Saved statistics for " .. player.Name .. ":", stats)
end

-- Start monitoring loops
function ServerValidationSystem:startMonitoring()
    -- Performance monitoring
    spawn(function()
        while true do
            wait(60) -- Check every minute

            -- Monitor server performance
            local memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
            print("Server Memory Usage: " .. memoryUsage .. " MB")

            -- Monitor suspicious activity
            local suspiciousPlayers = 0
            for userId, activities in pairs(suspiciousActivity) do
                if #activities > 0 then
                    suspiciousPlayers = suspiciousPlayers + 1
                end
            end

            if suspiciousPlayers > 0 then
                print("Players with suspicious activity: " .. suspiciousPlayers)
            end
        end
    end)

    -- Statistics reporting
    spawn(function()
        while true do
            wait(300) -- Report every 5 minutes

            print("=== SERVER STATISTICS ===")
            print("Total shots fired: " .. self.serverStats.totalShots)
            print("Total hits: " .. self.serverStats.totalHits)
            print("Hit ratio: " .. (self.serverStats.totalHits / math.max(self.serverStats.totalShots, 1)))
            print("Total damage: " .. self.serverStats.totalDamage)
            print("Suspicious events: " .. self.serverStats.suspiciousEvents)
            print("Players kicked: " .. self.serverStats.playersKicked)
            print("========================")
        end
    end)
end

-- Get player statistics
function ServerValidationSystem:getPlayerStatistics(player)
    return playerData[player.UserId]
end

-- Get server statistics
function ServerValidationSystem:getServerStatistics()
    return self.serverStats
end

-- Cleanup
function ServerValidationSystem:cleanup()
    -- Save all player statistics
    for _, player in pairs(Players:GetPlayers()) do
        self:savePlayerStatistics(player)
    end

    -- Clear data
    playerData = {}
    suspiciousActivity = {}
end

-- Initialize the system
local serverValidation = ServerValidationSystem.new()

-- Export for other server scripts
_G.ServerValidationSystem = serverValidation

return ServerValidationSystem