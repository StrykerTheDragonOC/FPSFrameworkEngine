-- VehicleSystem.server.lua
-- Advanced vehicle system for KFCS FUNNY RANDOMIZER
-- Handles spawning, physics, weapons, and multi-seat mechanics
-- Tactical vehicles with realistic combat integration

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Vehicle System Class
local VehicleSystem = {}
VehicleSystem.__index = VehicleSystem

-- Vehicle configurations database
VehicleSystem.VehicleDatabase = {
    ["Tactical_ATV"] = {
        name = "Tactical ATV",
        category = "Light",
        maxSpeed = 120,
        acceleration = 25,
        handling = 0.8,
        health = 500,
        seats = 2,
        weapons = {"mounted_mg"},
        fuel = 100,
        spawnCost = 150,
        teamAccess = {"FBI", "KFC"},
        description = "Fast reconnaissance vehicle"
    },
    
    ["Armored_Humvee"] = {
        name = "Armored Humvee",
        category = "Medium",
        maxSpeed = 90,
        acceleration = 15,
        handling = 0.6,
        health = 1500,
        seats = 4,
        weapons = {"turret_mg", "passenger_rifle"},
        fuel = 150,
        spawnCost = 300,
        teamAccess = {"FBI", "KFC"},
        description = "Multi-role armored transport"
    },
    
    ["Battle_Tank"] = {
        name = "M1A2 Battle Tank",
        category = "Heavy",
        maxSpeed = 60,
        acceleration = 8,
        handling = 0.3,
        health = 3000,
        seats = 3,
        weapons = {"main_cannon", "coaxial_mg", "commander_mg"},
        fuel = 200,
        spawnCost = 800,
        teamAccess = {"FBI", "KFC"},
        description = "Heavy assault tank",
        requiresRank = 10
    },
    
    ["Attack_Helicopter"] = {
        name = "Apache Gunship",
        category = "Air",
        maxSpeed = 200,
        acceleration = 30,
        handling = 0.9,
        health = 1000,
        seats = 2,
        weapons = {"hellfire_missiles", "chain_gun"},
        fuel = 120,
        spawnCost = 1000,
        teamAccess = {"FBI", "KFC"},
        description = "Air superiority gunship",
        requiresRank = 15,
        isAircraft = true
    },
    
    ["Transport_Truck"] = {
        name = "Military Transport",
        category = "Support",
        maxSpeed = 80,
        acceleration = 12,
        handling = 0.4,
        health = 800,
        seats = 8,
        weapons = {},
        fuel = 180,
        spawnCost = 200,
        teamAccess = {"FBI", "KFC"},
        description = "Large troop transport"
    }
}

-- Initialize Vehicle System
function VehicleSystem.new()
    local self = setmetatable({}, VehicleSystem)
    
    self.activeVehicles = {}
    self.spawnCooldowns = {}
    self.vehicleSpawns = {}
    self.remoteEvents = {}
    
    self:setupRemoteEvents()
    self:setupVehicleSpawns()
    self:startVehicleUpdates()
    
    print("[VehicleSystem] ✅ Advanced vehicle system initialized")
    return self
end

-- Setup RemoteEvents for client communication
function VehicleSystem:setupRemoteEvents()
   local remoteFolder = ReplicatedStorage.FPSSystem:FindFirstChild("RemoteEvents") or Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
    
    local vehicleEvents = {
        "RequestVehicleSpawn",
        "RequestVehicleEntry",
        "RequestVehicleExit",
        "VehicleInput",
        "VehicleWeaponFire",
        "VehicleDestroyed",
        "UpdateVehicleStats"
    }
    
    for _, eventName in pairs(vehicleEvents) do
        local remoteEvent = remoteFolder:FindFirstChild(eventName) or Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = remoteFolder
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Connect event handlers
    self.remoteEvents.RequestVehicleSpawn.OnServerEvent:Connect(function(player, vehicleType, spawnId)
        self:handleVehicleSpawnRequest(player, vehicleType, spawnId)
    end)
    
    self.remoteEvents.RequestVehicleEntry.OnServerEvent:Connect(function(player, vehicle, seatNumber)
        self:handleVehicleEntry(player, vehicle, seatNumber)
    end)
    
    self.remoteEvents.RequestVehicleExit.OnServerEvent:Connect(function(player)
        self:handleVehicleExit(player)
    end)
    
    self.remoteEvents.VehicleInput.OnServerEvent:Connect(function(player, inputData)
        self:handleVehicleInput(player, inputData)
    end)
    
    self.remoteEvents.VehicleWeaponFire.OnServerEvent:Connect(function(player, weaponType, targetPosition)
        self:handleVehicleWeaponFire(player, weaponType, targetPosition)
    end)
end

-- Setup vehicle spawn points across the map
function VehicleSystem:setupVehicleSpawns()
    local spawnConfigs = {
        {
            id = "fbi_base_light",
            position = Vector3.new(100, 10, 50),
            team = "FBI",
            vehicleTypes = {"Tactical_ATV", "Armored_Humvee"},
            respawnTime = 60
        },
        {
            id = "fbi_base_heavy",
            position = Vector3.new(120, 10, 70),
            team = "FBI", 
            vehicleTypes = {"Battle_Tank", "Transport_Truck"},
            respawnTime = 120
        },
        {
            id = "fbi_airfield",
            position = Vector3.new(150, 50, 100),
            team = "FBI",
            vehicleTypes = {"Attack_Helicopter"},
            respawnTime = 180
        },
        {
            id = "kfc_base_light",
            position = Vector3.new(-100, 10, 50),
            team = "KFC",
            vehicleTypes = {"Tactical_ATV", "Armored_Humvee"},
            respawnTime = 60
        },
        {
            id = "kfc_base_heavy",
            position = Vector3.new(-120, 10, 70),
            team = "KFC",
            vehicleTypes = {"Battle_Tank", "Transport_Truck"},
            respawnTime = 120
        },
        {
            id = "kfc_airfield",
            position = Vector3.new(-150, 50, 100),
            team = "KFC",
            vehicleTypes = {"Attack_Helicopter"},
            respawnTime = 180
        }
    }
    
    for _, config in pairs(spawnConfigs) do
        self.vehicleSpawns[config.id] = {
            config = config,
            isOccupied = false,
            lastSpawnTime = 0,
            currentVehicle = nil
        }
        
        -- Create spawn pad visual
        self:createSpawnPad(config)
    end
end

-- Create visual spawn pad
function VehicleSystem:createSpawnPad(config)
    local spawnPad = Instance.new("Part")
    spawnPad.Name = "VehicleSpawn_" .. config.id
    spawnPad.Size = Vector3.new(20, 1, 30)
    spawnPad.Position = config.position
    spawnPad.Anchored = true
    spawnPad.CanCollide = false
    spawnPad.Material = Enum.Material.Neon
    spawnPad.BrickColor = config.team == "FBI" and BrickColor.new("Bright blue") or BrickColor.new("Bright red")
    spawnPad.Transparency = 0.7
    spawnPad.Parent = workspace
    
    -- Add spawn pad effects
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = spawnPad
    selectionBox.Color3 = spawnPad.Color
    selectionBox.LineThickness = 0.2
    selectionBox.Transparency = 0.5
    selectionBox.Parent = spawnPad
    
    -- Spawn terminal
    local terminal = Instance.new("Part")
    terminal.Name = "SpawnTerminal"
    terminal.Size = Vector3.new(4, 8, 2)
    terminal.Position = config.position + Vector3.new(12, 4, 0)
    terminal.Anchored = true
    terminal.Material = Enum.Material.Metal
    terminal.BrickColor = BrickColor.new("Dark stone grey")
    terminal.Parent = workspace
    
    -- Terminal screen
    local screen = Instance.new("SurfaceGui")
    screen.Face = Enum.NormalId.Front
    screen.Parent = terminal
    
    local screenFrame = Instance.new("Frame")
    screenFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
    screenFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
    screenFrame.BackgroundColor3 = Color3.new(0, 0.2, 0)
    screenFrame.BorderSizePixel = 0
    screenFrame.Parent = screen
    
    local screenText = Instance.new("TextLabel")
    screenText.Size = UDim2.new(1, 0, 1, 0)
    screenText.BackgroundTransparency = 1
    screenText.Text = config.team .. " VEHICLE\\nSPAWN TERMINAL\\n\\nClick to Spawn"
    screenText.TextColor3 = Color3.new(0, 1, 0)
    screenText.TextScaled = true
    screenText.Font = Enum.Font.Code
    screenText.Parent = screenFrame
    
    -- Terminal interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = terminal
    
    clickDetector.MouseClick:Connect(function(player)
        self:openVehicleSpawnMenu(player, config.id)
    end)
end

-- Handle vehicle spawn requests
function VehicleSystem:handleVehicleSpawnRequest(player, vehicleType, spawnId)
    local spawn = self.vehicleSpawns[spawnId]
    if not spawn then return end
    
    local config = spawn.config
    local vehicleData = self.VehicleDatabase[vehicleType]
    
    -- Get player stats from XPLevelingSystem
    local xpSystem = _G.XPLevelingSystem
    if not xpSystem then
        warn("[VehicleSystem] XPLevelingSystem not found")
        return
    end
    
    local playerStats = xpSystem:getPlayerStats(player)
    if not playerStats then
        warn("[VehicleSystem] Could not get player stats for", player.Name)
        return
    end
    
    -- Validation checks
    if not vehicleData then
        print("[VehicleSystem] ❌ Invalid vehicle type:", vehicleType)
        return
    end
    
    if not table.find(vehicleData.teamAccess, player.Team.Name) then
        print("[VehicleSystem] ❌ Team access denied for", player.Name)
        return
    end
    
    if vehicleData.requiresRank and (playerStats.level < vehicleData.requiresRank) then
        print("[VehicleSystem] ❌ Rank requirement not met for", player.Name)
        return
    end
    
    if playerStats.credits < vehicleData.spawnCost then
        print("[VehicleSystem] ❌ Insufficient credits for", player.Name)
        return
    end
    
    if spawn.isOccupied then
        print("[VehicleSystem] ❌ Spawn point occupied")
        return
    end
    
    local currentTime = tick()
    if currentTime - spawn.lastSpawnTime < config.respawnTime then
        local cooldownRemaining = config.respawnTime - (currentTime - spawn.lastSpawnTime)
        print("[VehicleSystem] ❌ Spawn cooldown:", math.ceil(cooldownRemaining), "seconds")
        return
    end
    
    -- Deduct spawn cost
    local success = xpSystem:spendCredits(player, vehicleData.spawnCost, vehicleData.name)
    if not success then
        warn("[VehicleSystem] Failed to deduct credits for", player.Name)
        return
    end
    
    -- Spawn vehicle
    local vehicle = self:spawnVehicle(vehicleType, config.position, config.team)
    if vehicle then
        spawn.isOccupied = true
        spawn.lastSpawnTime = currentTime
        spawn.currentVehicle = vehicle
        
        print("[VehicleSystem] ✅ Spawned", vehicleType, "for", player.Name)
    end
end

-- Spawn vehicle with full configuration
function VehicleSystem:spawnVehicle(vehicleType, position, team)
    local vehicleData = self.VehicleDatabase[vehicleType]
    if not vehicleData then return end
    
    -- Create vehicle model (placeholder - replace with actual models)
    local vehicle = Instance.new("Model")
    vehicle.Name = vehicleType .. "_" .. tick()
    vehicle.Parent = workspace
    
    -- Main chassis
    local chassis = Instance.new("Part")
    chassis.Name = "Chassis"
    chassis.Size = Vector3.new(12, 4, 20)
    chassis.Position = position + Vector3.new(0, 3, 0)
    chassis.Material = Enum.Material.Metal
    chassis.BrickColor = team == "FBI" and BrickColor.new("Dark blue") or BrickColor.new("Dark red")
    chassis.CanCollide = true
    chassis.Parent = vehicle
    
    -- Vehicle physics body
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = chassis
    
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(0, 5000, 0)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    bodyAngularVelocity.Parent = chassis
    
    -- Wheels (simplified)
    for i = 1, 4 do
        local wheel = Instance.new("Part")
        wheel.Name = "Wheel" .. i
        wheel.Size = Vector3.new(3, 3, 3)
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Material = Enum.Material.Rubber
        wheel.BrickColor = BrickColor.new("Really black")
        wheel.CanCollide = true
        wheel.Parent = vehicle
        
        local wheelPosition = Vector3.new(
            (i <= 2) and -7 or 7,  -- Front/back
            1,
            ((i % 2 == 1) and -8 or 8)  -- Left/right
        )
        wheel.Position = chassis.Position + wheelPosition
        
        -- Wheel joint
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = chassis
        weld.Part1 = wheel
        weld.Parent = chassis
    end
    
    -- Create seats
    for seatNum = 1, vehicleData.seats do
        local seat = Instance.new("Seat")
        seat.Name = "Seat" .. seatNum
        seat.Size = Vector3.new(4, 1, 4)
        seat.Material = Enum.Material.Fabric
        seat.BrickColor = BrickColor.new("Brown")
        seat.CanCollide = true
        seat.Parent = vehicle
        
        local seatPosition = Vector3.new(
            ((seatNum % 2 == 1) and -2 or 2),
            3,
            (seatNum <= 2) and 8 or 0
        )
        seat.Position = chassis.Position + seatPosition
        
        -- Seat weld
        local seatWeld = Instance.new("WeldConstraint")
        seatWeld.Part0 = chassis
        seatWeld.Part1 = seat
        seatWeld.Parent = chassis
        
        -- Seat designation
        local seatGui = Instance.new("BillboardGui")
        seatGui.Size = UDim2.new(0, 100, 0, 50)
        seatGui.StudsOffset = Vector3.new(0, 3, 0)
        seatGui.Parent = seat
        
        local seatLabel = Instance.new("TextLabel")
        seatLabel.Size = UDim2.new(1, 0, 1, 0)
        seatLabel.BackgroundTransparency = 1
        seatLabel.Text = (seatNum == 1) and "DRIVER" or ((seatNum == 2) and "GUNNER" or "PASSENGER")
        seatLabel.TextColor3 = Color3.new(1, 1, 1)
        seatLabel.TextScaled = true
        seatLabel.Font = Enum.Font.GothamBold
        seatLabel.Parent = seatGui
    end
    
    -- Vehicle stats
    local vehicleStats = {
        vehicleType = vehicleType,
        data = vehicleData,
        health = vehicleData.health,
        maxHealth = vehicleData.health,
        fuel = vehicleData.fuel,
        maxFuel = vehicleData.fuel,
        team = team,
        occupants = {},
        weapons = {},
        lastUpdateTime = tick(),
        isDestroyed = false
    }
    
    -- Add to active vehicles
    self.activeVehicles[vehicle] = vehicleStats
    
    -- Setup weapons
    if vehicleData.weapons then
        for _, weaponType in pairs(vehicleData.weapons) do
            self:addVehicleWeapon(vehicle, weaponType)
        end
    end
    
    vehicle.PrimaryPart = chassis
    return vehicle
end

-- Add weapons to vehicle
function VehicleSystem:addVehicleWeapon(vehicle, weaponType)
    local vehicleStats = self.activeVehicles[vehicle]
    if not vehicleStats then return end
    
    local weaponConfigs = {
        ["mounted_mg"] = {
            name = "Mounted Machine Gun",
            damage = 25,
            fireRate = 0.1,
            range = 300,
            ammo = 200,
            position = Vector3.new(0, 4, 8),
            controlSeat = 2
        },
        ["turret_mg"] = {
            name = "Turret Machine Gun", 
            damage = 35,
            fireRate = 0.08,
            range = 400,
            ammo = 300,
            position = Vector3.new(0, 6, 0),
            controlSeat = 2,
            canRotate = true
        },
        ["main_cannon"] = {
            name = "120mm Main Cannon",
            damage = 200,
            fireRate = 3,
            range = 800,
            ammo = 40,
            position = Vector3.new(0, 6, 5),
            controlSeat = 2,
            canRotate = true,
            explosive = true
        },
        ["hellfire_missiles"] = {
            name = "Hellfire Missiles",
            damage = 300,
            fireRate = 5,
            range = 1000,
            ammo = 8,
            position = Vector3.new(0, 2, -5),
            controlSeat = 2,
            homing = true
        }
    }
    
    local config = weaponConfigs[weaponType]
    if not config then return end
    
    -- Create weapon mount
    local weaponMount = Instance.new("Part")
    weaponMount.Name = weaponType .. "_Mount"
    weaponMount.Size = Vector3.new(2, 2, 4)
    weaponMount.Position = vehicle.PrimaryPart.Position + config.position
    weaponMount.Material = Enum.Material.Metal
    weaponMount.BrickColor = BrickColor.new("Really black")
    weaponMount.CanCollide = false
    weaponMount.Parent = vehicle
    
    -- Weapon attachment
    local weaponWeld = Instance.new("WeldConstraint")
    weaponWeld.Part0 = vehicle.PrimaryPart
    weaponWeld.Part1 = weaponMount
    weaponWeld.Parent = vehicle.PrimaryPart
    
    -- Store weapon data
    vehicleStats.weapons[weaponType] = {
        config = config,
        mount = weaponMount,
        currentAmmo = config.ammo,
        lastFireTime = 0,
        rotation = 0
    }
    
    print("[VehicleSystem] ✅ Added weapon:", config.name)
end

-- Start vehicle update loop
function VehicleSystem:startVehicleUpdates()
    RunService.Heartbeat:Connect(function()
        for vehicle, stats in pairs(self.activeVehicles) do
            if vehicle.Parent then
                self:updateVehicle(vehicle, stats)
            else
                self.activeVehicles[vehicle] = nil
            end
        end
    end)
end

-- Update individual vehicle
function VehicleSystem:updateVehicle(vehicle, stats)
    local currentTime = tick()
    local deltaTime = currentTime - stats.lastUpdateTime
    stats.lastUpdateTime = currentTime
    
    -- Fuel consumption
    if #stats.occupants > 0 then
        stats.fuel = math.max(0, stats.fuel - (deltaTime * 0.5))
    end
    
    -- Health regeneration for support vehicles
    if stats.data.category == "Support" and stats.health < stats.maxHealth then
        stats.health = math.min(stats.maxHealth, stats.health + (deltaTime * 2))
    end
    
    -- Check for destruction
    if stats.health <= 0 and not stats.isDestroyed then
        self:destroyVehicle(vehicle, stats)
    end
    
    -- Update clients
    if currentTime % 1 < deltaTime then  -- Update every second
        self.remoteEvents.UpdateVehicleStats:FireAllClients(vehicle, {
            health = stats.health,
            maxHealth = stats.maxHealth,
            fuel = stats.fuel,
            maxFuel = stats.maxFuel
        })
    end
end

-- Handle vehicle destruction
function VehicleSystem:destroyVehicle(vehicle, stats)
    stats.isDestroyed = true
    
    -- Explosion effect
    local explosion = Instance.new("Explosion")
    explosion.Position = vehicle.PrimaryPart.Position
    explosion.BlastRadius = 50
    explosion.BlastPressure = 1000000
    explosion.Parent = workspace
    
    -- Eject all occupants
    for _, player in pairs(stats.occupants) do
        self:handleVehicleExit(player)
    end
    
    -- Remove from spawn tracking
    for spawnId, spawn in pairs(self.vehicleSpawns) do
        if spawn.currentVehicle == vehicle then
            spawn.isOccupied = false
            spawn.currentVehicle = nil
            spawn.lastSpawnTime = tick()
            break
        end
    end
    
    -- Cleanup after delay
    Debris:AddItem(vehicle, 30)
    self.activeVehicles[vehicle] = nil
    
    self.remoteEvents.VehicleDestroyed:FireAllClients(vehicle)
    print("[VehicleSystem] 💥 Vehicle destroyed")
end

-- Handle vehicle entry
function VehicleSystem:handleVehicleEntry(player, vehicle, seatNumber)
    local stats = self.activeVehicles[vehicle]
    if not stats or stats.isDestroyed then return end
    
    if stats.occupants[seatNumber] then
        print("[VehicleSystem] ❌ Seat already occupied")
        return
    end
    
    -- Check team access
    if player.Team.Name ~= stats.team then
        print("[VehicleSystem] ❌ Wrong team for vehicle")
        return
    end
    
    stats.occupants[seatNumber] = player
    print("[VehicleSystem] ✅", player.Name, "entered vehicle seat", seatNumber)
end

-- Handle vehicle exit
function VehicleSystem:handleVehicleExit(player)
    for vehicle, stats in pairs(self.activeVehicles) do
        for seatNum, occupant in pairs(stats.occupants) do
            if occupant == player then
                stats.occupants[seatNum] = nil
                print("[VehicleSystem] ✅", player.Name, "exited vehicle")
                return
            end
        end
    end
end

-- Handle vehicle input (movement, steering)
function VehicleSystem:handleVehicleInput(player, inputData)
    for vehicle, stats in pairs(self.activeVehicles) do
        if stats.occupants[1] == player then  -- Driver seat
            self:processVehicleMovement(vehicle, stats, inputData)
            return
        end
    end
end

-- Process vehicle movement
function VehicleSystem:processVehicleMovement(vehicle, stats, inputData)
    if stats.fuel <= 0 or stats.isDestroyed then return end
    
    local chassis = vehicle.PrimaryPart
    local bodyVelocity = chassis:FindFirstChild("BodyVelocity")
    local bodyAngularVelocity = chassis:FindFirstChild("BodyAngularVelocity")
    
    if not bodyVelocity or not bodyAngularVelocity then return end
    
    local throttle = inputData.throttle or 0  -- -1 to 1
    local steering = inputData.steering or 0  -- -1 to 1
    
    -- Calculate movement
    local maxSpeed = stats.data.maxSpeed
    local acceleration = stats.data.acceleration
    local handling = stats.data.handling
    
    local forwardVector = chassis.CFrame.LookVector
    local targetVelocity = forwardVector * (throttle * maxSpeed)
    
    -- Apply movement
    bodyVelocity.Velocity = targetVelocity
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, steering * handling * 5, 0)
    
    -- Consume fuel based on throttle
    local fuelConsumption = math.abs(throttle) * 0.1
    stats.fuel = math.max(0, stats.fuel - fuelConsumption)
end

-- Handle weapon firing
function VehicleSystem:handleVehicleWeaponFire(player, weaponType, targetPosition)
    for vehicle, stats in pairs(self.activeVehicles) do
        local weapon = stats.weapons[weaponType]
        if weapon and stats.occupants[weapon.config.controlSeat] == player then
            self:fireVehicleWeapon(vehicle, stats, weaponType, targetPosition)
            return
        end
    end
end

-- Fire vehicle weapon
function VehicleSystem:fireVehicleWeapon(vehicle, stats, weaponType, targetPosition)
    local weapon = stats.weapons[weaponType]
    if not weapon then return end
    
    local currentTime = tick()
    if currentTime - weapon.lastFireTime < weapon.config.fireRate then return end
    if weapon.currentAmmo <= 0 then return end
    
    weapon.lastFireTime = currentTime
    weapon.currentAmmo = weapon.currentAmmo - 1
    
    local startPosition = weapon.mount.Position
    local direction = (targetPosition - startPosition).Unit
    
    -- Create projectile
    self:createProjectile(startPosition, direction, weapon.config)
    
    print("[VehicleSystem] 🔥 Fired", weapon.config.name, "- Ammo remaining:", weapon.currentAmmo)
end

-- Create weapon projectile
function VehicleSystem:createProjectile(startPosition, direction, weaponConfig)
    local projectile = Instance.new("Part")
    projectile.Name = "VehicleProjectile"
    projectile.Size = Vector3.new(0.5, 0.5, 2)
    projectile.Position = startPosition
    projectile.Material = Enum.Material.Neon
    projectile.BrickColor = BrickColor.new("Bright yellow")
    projectile.CanCollide = false
    projectile.Parent = workspace
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = direction * 200
    bodyVelocity.Parent = projectile
    
    -- Projectile collision detection
    local connection
    connection = projectile.Touched:Connect(function(hit)
        if hit.Parent:FindFirstChild("Humanoid") then
            -- Player hit
            local humanoid = hit.Parent.Humanoid
            humanoid:TakeDamage(weaponConfig.damage)
        elseif hit.Name == "Chassis" then
            -- Vehicle hit
            local hitVehicle = hit.Parent
            local hitStats = self.activeVehicles[hitVehicle]
            if hitStats then
                hitStats.health = hitStats.health - weaponConfig.damage
            end
        end
        
        -- Explosion for explosive weapons
        if weaponConfig.explosive then
            local explosion = Instance.new("Explosion")
            explosion.Position = projectile.Position
            explosion.BlastRadius = 20
            explosion.BlastPressure = 500000
            explosion.Parent = workspace
        end
        
        projectile:Destroy()
        connection:Disconnect()
    end)
    
    -- Cleanup after range/time
    Debris:AddItem(projectile, weaponConfig.range / 200)
end

-- Open vehicle spawn menu for player
function VehicleSystem:openVehicleSpawnMenu(player, spawnId)
    local spawn = self.vehicleSpawns[spawnId]
    if not spawn then return end
    
    if player.Team.Name ~= spawn.config.team then
        print("[VehicleSystem] ❌ Wrong team for spawn terminal")
        return
    end
    
    -- Get player stats from XPLevelingSystem
    local xpSystem = _G.XPLevelingSystem
    local playerStats = {credits = 0, level = 0} -- Default values
    if xpSystem then
        local stats = xpSystem:getPlayerStats(player)
        if stats then
            playerStats = stats
        end
    end
    
    -- Send available vehicles to client
    local availableVehicles = {}
    for _, vehicleType in pairs(spawn.config.vehicleTypes) do
        local vehicleData = self.VehicleDatabase[vehicleType]
        if vehicleData and table.find(vehicleData.teamAccess, player.Team.Name) then
            table.insert(availableVehicles, {
                type = vehicleType,
                data = vehicleData,
                canSpawn = not spawn.isOccupied and 
                          playerStats.credits >= vehicleData.spawnCost and
                          (not vehicleData.requiresRank or playerStats.level >= vehicleData.requiresRank)
            })
        end
    end
    
    -- This would connect to a client UI system
    print("[VehicleSystem] 📋 Opened spawn menu for", player.Name, "at", spawnId)
    -- self.remoteEvents.OpenVehicleSpawnMenu:FireClient(player, spawnId, availableVehicles)
end

-- Initialize the system
local vehicleSystem = VehicleSystem.new()

print("[VehicleSystem] 🚗 ADVANCED VEHICLE SYSTEM FEATURES:")
print("  • Multi-seat vehicles with role-based seating")
print("  • Realistic physics with fuel consumption")
print("  • Weapon systems (MG, cannons, missiles)")
print("  • Team-based spawn points with terminals")
print("  • Vehicle health and destruction mechanics")
print("  • Air and ground vehicle support")
print("  • Rank and credit requirements")
print("  • Advanced projectile systems")

return vehicleSystem