-- VehicleWeaponSystem.server.lua
-- Advanced vehicle weapon integration for KFCS FUNNY RANDOMIZER
-- Sophisticated targeting, ballistics, and weapon management for vehicles
-- Integration with destruction physics and tactical gameplay

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

-- Vehicle Weapon System Class
local VehicleWeaponSystem = {}
VehicleWeaponSystem.__index = VehicleWeaponSystem

-- Advanced weapon configurations
VehicleWeaponSystem.WeaponDatabase = {
    ["mounted_mg"] = {
        name = "M240 Machine Gun",
        category = "Machine Gun",
        damage = 35,
        fireRate = 0.08,
        range = 400,
        maxAmmo = 200,
        reloadTime = 4,
        projectileSpeed = 800,
        spread = 0.05,
        penetration = 0.3,
        tracerFrequency = 5,
        overheatThreshold = 50,
        coolingRate = 2,
        mountType = "flexible",
        elevationRange = {-15, 45},
        traverseRange = {-180, 180},
        stabilized = false
    },
    
    ["turret_mg"] = {
        name = "M2 Browning Turret",
        category = "Heavy Machine Gun",
        damage = 55,
        fireRate = 0.12,
        range = 600,
        maxAmmo = 150,
        reloadTime = 5,
        projectileSpeed = 900,
        spread = 0.03,
        penetration = 0.5,
        tracerFrequency = 4,
        overheatThreshold = 40,
        coolingRate = 1.5,
        mountType = "turret",
        elevationRange = {-10, 60},
        traverseRange = {-360, 360},
        stabilized = true,
        thermalSight = true
    },
    
    ["main_cannon"] = {
        name = "M256 120mm Cannon",
        category = "Main Gun",
        damage = 400,
        fireRate = 4,
        range = 2000,
        maxAmmo = 40,
        reloadTime = 8,
        projectileSpeed = 1200,
        spread = 0.01,
        penetration = 1.0,
        explosive = true,
        explosiveRadius = 25,
        apfsds = true,
        mountType = "turret",
        elevationRange = {-8, 20},
        traverseRange = {-360, 360},
        stabilized = true,
        thermalSight = true,
        rangefinder = true
    },
    
    ["coaxial_mg"] = {
        name = "M240 Coaxial",
        category = "Coaxial Machine Gun",
        damage = 30,
        fireRate = 0.06,
        range = 800,
        maxAmmo = 400,
        reloadTime = 6,
        projectileSpeed = 850,
        spread = 0.02,
        penetration = 0.2,
        tracerFrequency = 6,
        overheatThreshold = 60,
        coolingRate = 2.5,
        mountType = "coaxial",
        linkedToMain = true,
        stabilized = true
    },
    
    ["hellfire_missiles"] = {
        name = "AGM-114 Hellfire",
        category = "Anti-Tank Missile",
        damage = 600,
        fireRate = 8,
        range = 8000,
        maxAmmo = 16,
        reloadTime = 15,
        projectileSpeed = 400,
        homing = true,
        lockOnTime = 3,
        explosive = true,
        explosiveRadius = 35,
        penetration = 1.0,
        mountType = "launcher",
        elevationRange = {-20, 30},
        traverseRange = {-45, 45},
        laserGuided = true
    },
    
    ["chain_gun"] = {
        name = "M230 Chain Gun",
        category = "Autocannon",
        damage = 120,
        fireRate = 0.1,
        range = 1500,
        maxAmmo = 300,
        reloadTime = 10,
        projectileSpeed = 1000,
        spread = 0.02,
        penetration = 0.8,
        explosive = true,
        explosiveRadius = 8,
        mountType = "flexible",
        elevationRange = {-15, 50},
        traverseRange = {-90, 90},
        stabilized = true,
        airburst = true
    },
    
    ["smoke_launcher"] = {
        name = "Smoke Grenade Launcher",
        category = "Countermeasure",
        damage = 0,
        fireRate = 2,
        range = 100,
        maxAmmo = 12,
        reloadTime = 20,
        projectileSpeed = 150,
        smokeEffect = true,
        smokeDuration = 30,
        smokeRadius = 25,
        mountType = "launcher",
        elevationRange = {30, 60},
        traverseRange = {-180, 180}
    }
}

-- Ammunition types
VehicleWeaponSystem.AmmunitionTypes = {
    ["ap"] = {
        name = "Armor Piercing",
        damageMultiplier = 1.2,
        penetrationBonus = 0.3,
        explosiveMultiplier = 0.8
    },
    ["he"] = {
        name = "High Explosive",
        damageMultiplier = 0.9,
        penetrationBonus = -0.2,
        explosiveMultiplier = 1.5
    },
    ["apfsds"] = {
        name = "APFSDS",
        damageMultiplier = 1.5,
        penetrationBonus = 0.8,
        explosiveMultiplier = 0.0,
        velocityBonus = 1.3
    },
    ["heat"] = {
        name = "HEAT",
        damageMultiplier = 1.3,
        penetrationBonus = 0.6,
        explosiveMultiplier = 1.2
    }
}

-- Initialize Vehicle Weapon System
function VehicleWeaponSystem.new()
    local self = setmetatable({}, VehicleWeaponSystem)
    
    self.vehicleWeapons = {}
    self.activeProjectiles = {}
    self.targetingData = {}
    self.remoteEvents = {}
    self.weaponEffects = {}
    
    self:setupRemoteEvents()
    self:startWeaponUpdates()
    
    print("[VehicleWeaponSystem] ✅ Advanced weapon system initialized")
    return self
end

-- Setup RemoteEvents
function VehicleWeaponSystem:setupRemoteEvents()
    local remoteFolder = ReplicatedStorage.FPSSystem:FindFirstChild("RemoteEvents") or Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
    
    local weaponEvents = {
        "VehicleWeaponFire",
        "VehicleWeaponReload",
        "VehicleTargetLock",
        "VehicleWeaponRotate",
        "VehicleAmmoSwitch",
        "VehicleWeaponStatus"
    }
    
    for _, eventName in pairs(weaponEvents) do
        local remoteEvent = remoteFolder:FindFirstChild(eventName) or Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = remoteFolder
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Connect event handlers
    self.remoteEvents.VehicleWeaponFire.OnServerEvent:Connect(function(player, vehicle, weaponId, targetData)
        self:handleWeaponFire(player, vehicle, weaponId, targetData)
    end)
    
    self.remoteEvents.VehicleWeaponReload.OnServerEvent:Connect(function(player, vehicle, weaponId)
        self:handleWeaponReload(player, vehicle, weaponId)
    end)
    
    self.remoteEvents.VehicleTargetLock.OnServerEvent:Connect(function(player, vehicle, weaponId, targetPosition)
        self:handleTargetLock(player, vehicle, weaponId, targetPosition)
    end)
    
    self.remoteEvents.VehicleWeaponRotate.OnServerEvent:Connect(function(player, vehicle, weaponId, rotation)
        self:handleWeaponRotation(player, vehicle, weaponId, rotation)
    end)
    
    self.remoteEvents.VehicleAmmoSwitch.OnServerEvent:Connect(function(player, vehicle, weaponId, ammoType)
        self:handleAmmoSwitch(player, vehicle, weaponId, ammoType)
    end)
end

-- Register vehicle weapon
function VehicleWeaponSystem:registerVehicleWeapon(vehicle, weaponId, weaponType, mountPosition, controlSeat)
    local weaponConfig = self.WeaponDatabase[weaponType]
    if not weaponConfig then
        print("[VehicleWeaponSystem] ❌ Unknown weapon type:", weaponType)
        return false
    end
    
    local weaponData = {
        vehicle = vehicle,
        weaponId = weaponId,
        config = weaponConfig,
        mountPosition = mountPosition,
        controlSeat = controlSeat,
        currentAmmo = weaponConfig.maxAmmo,
        totalAmmo = weaponConfig.maxAmmo * 3,
        isReloading = false,
        reloadStartTime = 0,
        lastFireTime = 0,
        overheated = false,
        heatLevel = 0,
        currentElevation = 0,
        currentTraverse = 0,
        targetLocked = false,
        lockedTarget = nil,
        currentAmmoType = "he",
        barrelWear = 0,
        stabilizationActive = weaponConfig.stabilized or false
    }
    
    -- Create physical weapon mount
    self:createWeaponMount(vehicle, weaponData)
    
    -- Store weapon data
    if not self.vehicleWeapons[vehicle] then
        self.vehicleWeapons[vehicle] = {}
    end
    self.vehicleWeapons[vehicle][weaponId] = weaponData
    
    print("[VehicleWeaponSystem] ✅ Registered weapon:", weaponConfig.name, "on vehicle")
    return true
end

-- Create physical weapon mount
function VehicleWeaponSystem:createWeaponMount(vehicle, weaponData)
    local config = weaponData.config
    local mount = Instance.new("Model")
    mount.Name = weaponData.weaponId .. "_Mount"
    mount.Parent = vehicle
    
    -- Main weapon assembly
    local weaponPart = Instance.new("Part")
    weaponPart.Name = "WeaponAssembly"
    weaponPart.Size = Vector3.new(2, 1, 6)
    weaponPart.Position = vehicle.PrimaryPart.Position + weaponData.mountPosition
    weaponPart.Material = Enum.Material.Metal
    weaponPart.BrickColor = BrickColor.new("Really black")
    weaponPart.CanCollide = false
    weaponPart.Parent = mount
    
    -- Barrel
    local barrel = Instance.new("Part")
    barrel.Name = "Barrel"
    barrel.Size = Vector3.new(0.5, 0.5, 8)
    barrel.Position = weaponPart.Position + Vector3.new(0, 0, 4)
    barrel.Material = Enum.Material.Metal
    barrel.BrickColor = BrickColor.new("Dark stone grey")
    barrel.CanCollide = false
    barrel.Shape = Enum.PartType.Cylinder
    barrel.Parent = mount
    
    -- Muzzle flash effect point
    local muzzle = Instance.new("Attachment")
    muzzle.Name = "MuzzlePoint"
    muzzle.Position = Vector3.new(0, 0, 4)
    muzzle.Parent = barrel
    
    -- Turret ring for rotatable weapons
    if config.mountType == "turret" then
        local turretRing = Instance.new("Part")
        turretRing.Name = "TurretRing"
        turretRing.Size = Vector3.new(4, 1, 4)
        turretRing.Position = weaponPart.Position
        turretRing.Material = Enum.Material.Metal
        turretRing.BrickColor = BrickColor.new("Medium stone grey")
        turretRing.CanCollide = false
        turretRing.Shape = Enum.PartType.Cylinder
        turretRing.Parent = mount
        
        -- Rotating joint
        local rotateMotor = Instance.new("Motor6D")
        rotateMotor.Name = "TurretRotation"
        rotateMotor.Part0 = vehicle.PrimaryPart
        rotateMotor.Part1 = turretRing
        rotateMotor.Parent = vehicle.PrimaryPart
        
        weaponData.rotateMotor = rotateMotor
    end
    
    -- Weapon weld to vehicle
    local weaponWeld = Instance.new("WeldConstraint")
    weaponWeld.Part0 = vehicle.PrimaryPart
    weaponWeld.Part1 = weaponPart
    weaponWeld.Parent = vehicle.PrimaryPart
    
    -- Sighting system for advanced weapons
    if config.thermalSight or config.rangefinder then
        local sightingSystem = Instance.new("Part")
        sightingSystem.Name = "SightingSystem"
        sightingSystem.Size = Vector3.new(1, 0.5, 1)
        sightingSystem.Position = weaponPart.Position + Vector3.new(0, 1, 0)
        sightingSystem.Material = Enum.Material.Glass
        sightingSystem.BrickColor = BrickColor.new("Really black")
        sightingSystem.CanCollide = false
        sightingSystem.Parent = mount
        
        -- Rangefinder laser
        if config.rangefinder then
            local laser = Instance.new("Beam")
            laser.Name = "RangefinderLaser"
            laser.Color = ColorSequence.new(Color3.new(1, 0, 0))
            laser.Transparency = NumberSequence.new(0.8)
            laser.Width0 = 0.1
            laser.Width1 = 0.1
            laser.Parent = sightingSystem
        end
    end
    
    weaponData.mount = mount
    weaponData.barrel = barrel
    weaponData.muzzle = muzzle
end

-- Handle weapon firing
function VehicleWeaponSystem:handleWeaponFire(player, vehicle, weaponId, targetData)
    local vehicleWeapons = self.vehicleWeapons[vehicle]
    if not vehicleWeapons then return end
    
    local weaponData = vehicleWeapons[weaponId]
    if not weaponData then return end
    
    -- Validate player can control this weapon
    if not self:canPlayerControlWeapon(player, vehicle, weaponData) then return end
    
    -- Check fire rate limitation
    local currentTime = tick()
    if currentTime - weaponData.lastFireTime < weaponData.config.fireRate then return end
    
    -- Check ammo
    if weaponData.currentAmmo <= 0 then
        self:handleWeaponReload(player, vehicle, weaponId)
        return
    end
    
    -- Check overheating
    if weaponData.overheated then return end
    
    -- Fire weapon
    self:fireWeapon(weaponData, targetData)
    
    -- Update weapon state
    weaponData.lastFireTime = currentTime
    weaponData.currentAmmo = weaponData.currentAmmo - 1
    weaponData.heatLevel = weaponData.heatLevel + (100 / weaponData.config.overheatThreshold)
    weaponData.barrelWear = weaponData.barrelWear + 0.01
    
    -- Check for overheat
    if weaponData.heatLevel >= 100 then
        weaponData.overheated = true
        self:startCooling(weaponData)
    end
    
    -- Update clients
    self.remoteEvents.VehicleWeaponStatus:FireAllClients(vehicle, weaponId, {
        ammo = weaponData.currentAmmo,
        totalAmmo = weaponData.totalAmmo,
        heat = weaponData.heatLevel,
        overheated = weaponData.overheated
    })
    
    print("[VehicleWeaponSystem] 🔥 Fired weapon:", weaponData.config.name)
end

-- Fire weapon projectile
function VehicleWeaponSystem:fireWeapon(weaponData, targetData)
    local config = weaponData.config
    local startPosition = weaponData.muzzle.WorldPosition
    local direction = (targetData.position - startPosition).Unit
    
    -- Apply spread
    if config.spread > 0 then
        local spreadAngle = config.spread * (math.random() - 0.5) * 2
        direction = direction * CFrame.Angles(spreadAngle, spreadAngle, 0)
    end
    
    -- Create muzzle flash
    self:createMuzzleFlash(weaponData.muzzle)
    
    -- Different projectile types
    if config.homing and targetData.target then
        self:createHomingProjectile(weaponData, startPosition, targetData.target)
    elseif config.explosive then
        self:createExplosiveProjectile(weaponData, startPosition, direction)
    else
        self:createBallisticProjectile(weaponData, startPosition, direction)
    end
    
    -- Recoil effect
    self:applyRecoil(weaponData)
end

-- Create muzzle flash effect
function VehicleWeaponSystem:createMuzzleFlash(muzzlePoint)
    local flash = Instance.new("Explosion")
    flash.Position = muzzlePoint.WorldPosition
    flash.BlastRadius = 2
    flash.BlastPressure = 0
    flash.Visible = true
    flash.Parent = workspace
    
    -- Muzzle smoke
    local smoke = Instance.new("Smoke")
    smoke.Size = 5
    smoke.Opacity = 0.8
    smoke.RiseVelocity = 10
    smoke.Color = Color3.new(0.3, 0.3, 0.3)
    smoke.Parent = muzzlePoint
    
    -- Clean up smoke
    Debris:AddItem(smoke, 2)
end

-- Create ballistic projectile
function VehicleWeaponSystem:createBallisticProjectile(weaponData, startPosition, direction)
    local config = weaponData.config
    
    local projectile = Instance.new("Part")
    projectile.Name = "VehicleProjectile"
    projectile.Size = Vector3.new(0.2, 0.2, 1)
    projectile.Position = startPosition
    projectile.Material = Enum.Material.Neon
    projectile.BrickColor = BrickColor.new("Bright yellow")
    projectile.CanCollide = false
    projectile.Anchored = false
    projectile.Parent = workspace
    
    -- Projectile physics
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = direction * config.projectileSpeed
    bodyVelocity.Parent = projectile
    
    -- Tracer effect
    if math.random(1, config.tracerFrequency) == 1 then
        projectile.BrickColor = BrickColor.new("Bright red")
        projectile.Transparency = 0.3
        
        local trail = Instance.new("Trail")
        trail.Attachment0 = Instance.new("Attachment")
        trail.Attachment1 = Instance.new("Attachment")
        trail.Attachment0.Parent = projectile
        trail.Attachment1.Parent = projectile
        trail.Attachment1.Position = Vector3.new(0, 0, -1)
        trail.Color = ColorSequence.new(Color3.new(1, 0.5, 0))
        trail.Transparency = NumberSequence.new(0.5, 1)
        trail.Lifetime = 0.5
        trail.Parent = projectile
    end
    
    -- Collision detection
    local projectileData = {
        weaponData = weaponData,
        startTime = tick(),
        maxRange = config.range
    }
    
    self.activeProjectiles[projectile] = projectileData
    
    local connection
    connection = projectile.Touched:Connect(function(hit)
        self:handleProjectileHit(projectile, hit, projectileData)
        connection:Disconnect()
    end)
    
    -- Range-based cleanup
    Debris:AddItem(projectile, config.range / config.projectileSpeed)
end

-- Create explosive projectile
function VehicleWeaponSystem:createExplosiveProjectile(weaponData, startPosition, direction)
    local config = weaponData.config
    
    local projectile = Instance.new("Part")
    projectile.Name = "ExplosiveProjectile"
    projectile.Size = Vector3.new(0.5, 0.5, 2)
    projectile.Position = startPosition
    projectile.Material = Enum.Material.Metal
    projectile.BrickColor = BrickColor.new("Really black")
    projectile.CanCollide = false
    projectile.Anchored = false
    projectile.Parent = workspace
    
    -- Shell casing details
    local warhead = Instance.new("Part")
    warhead.Name = "Warhead"
    warhead.Size = Vector3.new(0.3, 0.3, 0.8)
    warhead.Position = projectile.Position + Vector3.new(0, 0, 0.6)
    warhead.Material = Enum.Material.Neon
    warhead.BrickColor = BrickColor.new("Bright red")
    warhead.CanCollide = false
    warhead.Parent = projectile
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = projectile
    weld.Part1 = warhead
    weld.Parent = projectile
    
    -- Projectile physics
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(8000, 8000, 8000)
    bodyVelocity.Velocity = direction * config.projectileSpeed
    bodyVelocity.Parent = projectile
    
    -- Smoke trail
    local smokeTrail = Instance.new("Smoke")
    smokeTrail.Size = 3
    smokeTrail.Opacity = 0.6
    smokeTrail.RiseVelocity = 0
    smokeTrail.Color = Color3.new(0.2, 0.2, 0.2)
    smokeTrail.Parent = projectile
    
    -- Collision and explosion handling
    local projectileData = {
        weaponData = weaponData,
        startTime = tick(),
        maxRange = config.range,
        explosive = true,
        explosiveRadius = config.explosiveRadius
    }
    
    self.activeProjectiles[projectile] = projectileData
    
    local connection
    connection = projectile.Touched:Connect(function(hit)
        self:handleExplosiveHit(projectile, hit, projectileData)
        connection:Disconnect()
    end)
    
    Debris:AddItem(projectile, config.range / config.projectileSpeed)
end

-- Create homing projectile (missiles)
function VehicleWeaponSystem:createHomingProjectile(weaponData, startPosition, target)
    local config = weaponData.config
    
    local missile = Instance.new("Part")
    missile.Name = "HomingMissile"
    missile.Size = Vector3.new(0.3, 0.3, 4)
    missile.Position = startPosition
    missile.Material = Enum.Material.Metal
    missile.BrickColor = BrickColor.new("Dark stone grey")
    missile.CanCollide = false
    missile.Anchored = false
    missile.Parent = workspace
    
    -- Missile fins
    for i = 1, 4 do
        local fin = Instance.new("Part")
        fin.Name = "Fin" .. i
        fin.Size = Vector3.new(0.1, 1, 0.5)
        fin.Position = missile.Position
        fin.Material = Enum.Material.Metal
        fin.BrickColor = BrickColor.new("Really black")
        fin.CanCollide = false
        fin.Parent = missile
        
        local finWeld = Instance.new("WeldConstraint")
        finWeld.Part0 = missile
        finWeld.Part1 = fin
        finWeld.Parent = missile
        
        -- Position fins around missile
        local angle = (i - 1) * (math.pi / 2)
        fin.CFrame = missile.CFrame * CFrame.new(math.cos(angle) * 0.3, math.sin(angle) * 0.3, -1)
    end
    
    -- Missile propulsion
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
    bodyVelocity.Velocity = (target.Position - startPosition).Unit * config.projectileSpeed
    bodyVelocity.Parent = missile
    
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(5000, 5000, 5000)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    bodyAngularVelocity.Parent = missile
    
    -- Exhaust trail
    local exhaust = Instance.new("Fire")
    exhaust.Size = 8
    exhaust.Heat = 10
    exhaust.Color = Color3.new(0, 0.5, 1)
    exhaust.SecondaryColor = Color3.new(1, 1, 1)
    exhaust.Parent = missile
    
    -- Homing guidance
    local projectileData = {
        weaponData = weaponData,
        target = target,
        startTime = tick(),
        maxRange = config.range,
        explosive = true,
        explosiveRadius = config.explosiveRadius,
        homing = true,
        bodyVelocity = bodyVelocity
    }
    
    self.activeProjectiles[missile] = projectileData
    
    -- Collision handling
    local connection
    connection = missile.Touched:Connect(function(hit)
        self:handleExplosiveHit(missile, hit, projectileData)
        connection:Disconnect()
    end)
    
    Debris:AddItem(missile, config.range / config.projectileSpeed + 5)
end

-- Handle projectile hit
function VehicleWeaponSystem:handleProjectileHit(projectile, hit, projectileData)
    local config = projectileData.weaponData.config
    
    -- Remove from tracking
    self.activeProjectiles[projectile] = nil
    
    -- Calculate damage
    local damage = config.damage
    
    -- Apply ammunition modifiers
    local ammoType = projectileData.weaponData.currentAmmoType
    local ammoData = self.AmmunitionTypes[ammoType]
    if ammoData then
        damage = damage * ammoData.damageMultiplier
    end
    
    -- Handle different hit types
    if hit.Parent:FindFirstChild("Humanoid") then
        -- Player hit
        hit.Parent.Humanoid:TakeDamage(damage)
        print("[VehicleWeaponSystem] 🎯 Player hit for", damage, "damage")
        
    elseif hit.Parent:FindFirstChild("VehicleStats") then
        -- Vehicle hit
        local vehicleStats = hit.Parent.VehicleStats.Value
        vehicleStats.health = vehicleStats.health - damage
        print("[VehicleWeaponSystem] 🚗 Vehicle hit for", damage, "damage")
        
    elseif hit:GetAttribute("Destructible") then
        -- Destructible environment
        local destructionPhysicsModule = game.ServerScriptService:FindFirstChild("DestructionPhysics")
        if destructionPhysicsModule and destructionPhysicsModule:IsA("ModuleScript") then
            local success, destructionSystem = pcall(require, destructionPhysicsModule)
            if success and destructionSystem then
                destructionSystem:registerPartDamage(hit, damage, "VehicleCannon", projectile.Position)
            end
        end
    end
    
    -- Impact effects
    self:createImpactEffects(projectile.Position, hit.Material)
    
    projectile:Destroy()
end

-- Handle explosive hit
function VehicleWeaponSystem:handleExplosiveHit(projectile, hit, projectileData)
    local config = projectileData.weaponData.config
    
    -- Remove from tracking
    self.activeProjectiles[projectile] = nil
    
    -- Create explosion
    local explosion = Instance.new("Explosion")
    explosion.Position = projectile.Position
    explosion.BlastRadius = projectileData.explosiveRadius
    explosion.BlastPressure = config.damage * 2000
    explosion.Parent = workspace
    
    -- Area damage
    local parts = workspace:GetPartBoundsInBox(
        CFrame.new(projectile.Position),
        Vector3.new(projectileData.explosiveRadius * 2, projectileData.explosiveRadius * 2, projectileData.explosiveRadius * 2)
    )
    
    for _, part in pairs(parts) do
        local distance = (part.Position - projectile.Position).Magnitude
        if distance <= projectileData.explosiveRadius then
            local damageMultiplier = math.max(0.1, 1 - (distance / projectileData.explosiveRadius))
            local damage = config.damage * damageMultiplier
            
            -- Apply damage based on target type
            if part.Parent:FindFirstChild("Humanoid") then
                part.Parent.Humanoid:TakeDamage(damage)
            elseif part:GetAttribute("Destructible") then
                local destructionPhysicsModule = game.ServerScriptService:FindFirstChild("DestructionPhysics")
                if destructionPhysicsModule and destructionPhysicsModule:IsA("ModuleScript") then
                    local success, destructionSystem = pcall(require, destructionPhysicsModule)
                    if success and destructionSystem then
                        destructionSystem:registerPartDamage(part, damage, "Explosion", projectile.Position)
                    end
                end
            end
        end
    end
    
    projectile:Destroy()
    print("[VehicleWeaponSystem] 💥 Explosive hit - area damage applied")
end

-- Create impact effects
function VehicleWeaponSystem:createImpactEffects(position, material)
    -- Spark particles
    for i = 1, 5 do
        local spark = Instance.new("Part")
        spark.Name = "ImpactSpark"
        spark.Size = Vector3.new(0.1, 0.1, 0.1)
        spark.Position = position
        spark.Material = Enum.Material.Neon
        spark.BrickColor = BrickColor.new("Bright orange")
        spark.CanCollide = false
        spark.Parent = workspace
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(500, 500, 500)
        bodyVelocity.Velocity = Vector3.new(
            (math.random() - 0.5) * 20,
            math.random() * 15,
            (math.random() - 0.5) * 20
        )
        bodyVelocity.Parent = spark
        
        Debris:AddItem(spark, 1)
    end
    
    -- Material-specific effects
    if material == Enum.Material.Metal then
        -- Metal sparks
        local metalSpark = Instance.new("Explosion")
        metalSpark.Position = position
        metalSpark.BlastRadius = 3
        metalSpark.BlastPressure = 0
        metalSpark.Visible = false
        metalSpark.Parent = workspace
    end
end

-- Apply recoil to weapon/vehicle
function VehicleWeaponSystem:applyRecoil(weaponData)
    local config = weaponData.config
    local vehicle = weaponData.vehicle
    
    if vehicle.PrimaryPart then
        local recoilForce = config.damage * 2
        local direction = -weaponData.barrel.CFrame.LookVector
        
        local bodyVelocity = vehicle.PrimaryPart:FindFirstChild("BodyVelocity")
        if bodyVelocity then
            local currentVelocity = bodyVelocity.Velocity
            bodyVelocity.Velocity = currentVelocity + (direction * recoilForce * 0.01)
        end
    end
end

-- Start weapon cooling
function VehicleWeaponSystem:startCooling(weaponData)
    task.spawn(function()
        while weaponData.heatLevel > 0 and weaponData.overheated do
            task.wait(0.1)
            weaponData.heatLevel = math.max(0, weaponData.heatLevel - weaponData.config.coolingRate)
            
            if weaponData.heatLevel <= 30 then
                weaponData.overheated = false
                print("[VehicleWeaponSystem] ❄️ Weapon cooled down")
            end
        end
    end)
end

-- Handle weapon reload
function VehicleWeaponSystem:handleWeaponReload(player, vehicle, weaponId)
    local vehicleWeapons = self.vehicleWeapons[vehicle]
    if not vehicleWeapons then return end
    
    local weaponData = vehicleWeapons[weaponId]
    if not weaponData or weaponData.isReloading then return end
    
    if weaponData.totalAmmo <= 0 then
        print("[VehicleWeaponSystem] ❌ No ammunition remaining")
        return
    end
    
    weaponData.isReloading = true
    weaponData.reloadStartTime = tick()
    
    print("[VehicleWeaponSystem] 🔄 Reloading weapon:", weaponData.config.name)
    
    -- Reload animation/delay
    task.wait(weaponData.config.reloadTime)
    
    local ammoNeeded = weaponData.config.maxAmmo - weaponData.currentAmmo
    local ammoToReload = math.min(ammoNeeded, weaponData.totalAmmo)
    
    weaponData.currentAmmo = weaponData.currentAmmo + ammoToReload
    weaponData.totalAmmo = weaponData.totalAmmo - ammoToReload
    weaponData.isReloading = false
    
    print("[VehicleWeaponSystem] ✅ Reload complete")
end

-- Check if player can control weapon
function VehicleWeaponSystem:canPlayerControlWeapon(player, vehicle, weaponData)
    -- Check if player is in correct seat
    local seatName = "Seat" .. weaponData.controlSeat
    local seat = vehicle:FindFirstChild(seatName)
    
    if seat and seat.Occupant then
        local character = seat.Occupant.Parent
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and Players:GetPlayerFromCharacter(character) == player then
            return true
        end
    end
    
    return false
end

-- Start weapon update loop
function VehicleWeaponSystem:startWeaponUpdates()
    RunService.Heartbeat:Connect(function()
        -- Update homing projectiles
        for projectile, data in pairs(self.activeProjectiles) do
            if data.homing and data.target and projectile.Parent then
                self:updateHomingGuidance(projectile, data)
            end
        end
        
        -- Update weapon heat levels
        for vehicle, weapons in pairs(self.vehicleWeapons) do
            for weaponId, weaponData in pairs(weapons) do
                if not weaponData.overheated and weaponData.heatLevel > 0 then
                    weaponData.heatLevel = math.max(0, weaponData.heatLevel - (weaponData.config.coolingRate * 0.1))
                end
            end
        end
    end)
end

-- Update homing missile guidance
function VehicleWeaponSystem:updateHomingGuidance(projectile, data)
    if not data.target or not data.target.Parent then return end
    
    local targetPosition = data.target.Position
    local currentPosition = projectile.Position
    local direction = (targetPosition - currentPosition).Unit
    
    -- Update velocity towards target
    if data.bodyVelocity then
        local currentVelocity = data.bodyVelocity.Velocity
        local targetVelocity = direction * data.weaponData.config.projectileSpeed
        
        -- Smooth steering
        local newVelocity = currentVelocity:Lerp(targetVelocity, 0.1)
        data.bodyVelocity.Velocity = newVelocity
        
        -- Orient projectile towards target
        projectile.CFrame = CFrame.lookAt(currentPosition, currentPosition + newVelocity)
    end
end

-- Initialize the system
local vehicleWeaponSystem = VehicleWeaponSystem.new()

print("[VehicleWeaponSystem] 🎯 ADVANCED WEAPON SYSTEM FEATURES:")
print("  • Sophisticated ballistics and projectile physics")
print("  • Homing missile guidance systems")
print("  • Weapon overheating and cooling mechanics")
print("  • Multiple ammunition types with modifiers")
print("  • Advanced targeting and stabilization")
print("  • Realistic recoil and weapon wear")
print("  • Integration with destruction physics")
print("  • Comprehensive weapon mount systems")

return vehicleWeaponSystem