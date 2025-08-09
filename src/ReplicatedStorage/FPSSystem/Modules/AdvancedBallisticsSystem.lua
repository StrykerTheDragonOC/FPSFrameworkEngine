-- Advanced Ballistics System with Bullet Drop, Wind, and Realistic Physics
-- Place in ReplicatedStorage.FPSSystem.Modules.AdvancedBallisticsSystem
local AdvancedBallisticsSystem = {}
AdvancedBallisticsSystem.__index = AdvancedBallisticsSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Ballistics Configuration
local BALLISTICS_CONFIG = {
    -- Physics constants
    GRAVITY = 9.81, -- m/s²
    AIR_DENSITY = 1.225, -- kg/m³ at sea level
    TEMPERATURE = 15, -- °C
    PRESSURE = 101325, -- Pa
    HUMIDITY = 0.5, -- 50%

    -- Bullet simulation
    TIME_STEP = 0.016, -- 60 FPS simulation
    MAX_SIMULATION_TIME = 10.0, -- seconds
    MIN_VELOCITY = 50, -- m/s minimum before bullet drops

    -- Wind system
    WIND_ENABLED = true,
    WIND_STRENGTH = Vector3.new(2, 0, 1), -- m/s
    WIND_VARIATION = 0.3, -- Random variation factor
    WIND_UPDATE_RATE = 5.0, -- seconds between wind updates

    -- Visualization
    TRACER_ENABLED = true,
    TRACER_EVERY_N_BULLETS = 3,
    BULLET_TRAIL_ENABLED = true,
    IMPACT_PREDICTION = true
}

-- Bullet Data Database
local BULLET_DATA = {
    -- Rifle Cartridges
    ["5.56x45_NATO"] = {
        mass = 0.004, -- kg (4g)
        diameter = 0.00556, -- meters
        dragCoefficient = 0.295,
        muzzleVelocity = 990, -- m/s
        ballisticCoefficient = 0.307,
        energyRetention = 0.85
    },

    ["7.62x51_NATO"] = {
        mass = 0.0097, -- kg (9.7g)
        diameter = 0.00762, -- meters
        dragCoefficient = 0.248,
        muzzleVelocity = 853, -- m/s
        ballisticCoefficient = 0.505,
        energyRetention = 0.92
    },

    ["7.62x39_Soviet"] = {
        mass = 0.008, -- kg (8g)
        diameter = 0.00762, -- meters
        dragCoefficient = 0.295,
        muzzleVelocity = 715, -- m/s
        ballisticCoefficient = 0.275,
        energyRetention = 0.88
    },

    -- Sniper Cartridges
    [".338_Lapua"] = {
        mass = 0.0162, -- kg (16.2g)
        diameter = 0.00858, -- meters
        dragCoefficient = 0.228,
        muzzleVelocity = 915, -- m/s
        ballisticCoefficient = 0.78,
        energyRetention = 0.95
    },

    [".50_BMG"] = {
        mass = 0.042, -- kg (42g)
        diameter = 0.0127, -- meters
        dragCoefficient = 0.295,
        muzzleVelocity = 900, -- m/s
        ballisticCoefficient = 0.95,
        energyRetention = 0.98
    },

    -- Pistol Cartridges
    ["9x19_Parabellum"] = {
        mass = 0.008, -- kg (8g)
        diameter = 0.009, -- meters
        dragCoefficient = 0.3,
        muzzleVelocity = 380, -- m/s
        ballisticCoefficient = 0.165,
        energyRetention = 0.75
    }
}

function AdvancedBallisticsSystem.new()
    local self = setmetatable({}, AdvancedBallisticsSystem)

    -- References
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera

    -- Wind system
    self.currentWind = BALLISTICS_CONFIG.WIND_STRENGTH
    self.lastWindUpdate = 0

    -- Bullet tracking
    self.activeBullets = {}
    self.tracerCount = 0

    -- Effects folder
    self.effectsFolder = workspace:FindFirstChild("BallisticsEffects")
    if not self.effectsFolder then
        self.effectsFolder = Instance.new("Folder")
        self.effectsFolder.Name = "BallisticsEffects"
        self.effectsFolder.Parent = workspace
    end

    -- Initialize systems
    self:initializeWindSystem()

    return self
end

-- Initialize wind system
function AdvancedBallisticsSystem:initializeWindSystem()
    if not BALLISTICS_CONFIG.WIND_ENABLED then return end

    -- Start wind update loop
    spawn(function()
        while true do
            self:updateWind()
            wait(BALLISTICS_CONFIG.WIND_UPDATE_RATE)
        end
    end)
end

-- Update wind conditions
function AdvancedBallisticsSystem:updateWind()
    local baseWind = BALLISTICS_CONFIG.WIND_STRENGTH
    local variation = BALLISTICS_CONFIG.WIND_VARIATION

    -- Add random variation to wind
    self.currentWind = Vector3.new(
        baseWind.X + (math.random() - 0.5) * variation * 2,
        baseWind.Y + (math.random() - 0.5) * variation * 2,
        baseWind.Z + (math.random() - 0.5) * variation * 2
    )

    print("Wind updated:", self.currentWind)
end

-- Fire bullet with advanced ballistics
function AdvancedBallisticsSystem:fireBullet(fireData)
    local bulletData = BULLET_DATA[fireData.ammunition] or BULLET_DATA["5.56x45_NATO"]

    -- Create bullet trajectory
    local trajectory = self:calculateTrajectory(
        fireData.origin,
        fireData.direction,
        bulletData,
        fireData.barrelLength or 0.4
    )

    -- Create bullet object
    local bullet = {
        id = #self.activeBullets + 1,
        startTime = tick(),
        origin = fireData.origin,
        direction = fireData.direction,
        trajectory = trajectory,
        bulletData = bulletData,
        owner = fireData.owner or self.player,
        weapon = fireData.weapon,
        currentStep = 1,
        isActive = true
    }

    -- Add to active bullets
    table.insert(self.activeBullets, bullet)

    -- Create visual effects
    if BALLISTICS_CONFIG.TRACER_ENABLED then
        self:createTracerEffect(bullet)
    end

    if BALLISTICS_CONFIG.BULLET_TRAIL_ENABLED then
        self:createBulletTrail(bullet)
    end

    -- Start bullet simulation
    self:simulateBullet(bullet)

    return bullet
end

-- Calculate complete bullet trajectory
function AdvancedBallisticsSystem:calculateTrajectory(origin, direction, bulletData, barrelLength)
    local trajectory = {}
    local currentPos = origin + direction * barrelLength
    local velocity = direction * bulletData.muzzleVelocity
    local time = 0

    -- Environmental factors
    local gravity = Vector3.new(0, -BALLISTICS_CONFIG.GRAVITY, 0)
    local airDensity = self:calculateAirDensity()

    while time < BALLISTICS_CONFIG.MAX_SIMULATION_TIME do
        -- Calculate drag force
        local dragForce = self:calculateDrag(velocity, bulletData, airDensity)

        -- Calculate wind effect
        local windForce = self:calculateWindEffect(velocity, bulletData)

        -- Apply forces to velocity
        local acceleration = (dragForce + windForce + gravity * bulletData.mass) / bulletData.mass
        velocity = velocity + acceleration * BALLISTICS_CONFIG.TIME_STEP

        -- Update position
        currentPos = currentPos + velocity * BALLISTICS_CONFIG.TIME_STEP

        -- Store trajectory point
        table.insert(trajectory, {
            position = currentPos,
            velocity = velocity,
            time = time,
            speed = velocity.Magnitude,
            energy = 0.5 * bulletData.mass * velocity.Magnitude^2
        })

        -- Check if bullet has dropped below minimum velocity
        if velocity.Magnitude < BALLISTICS_CONFIG.MIN_VELOCITY then
            break
        end

        time = time + BALLISTICS_CONFIG.TIME_STEP
    end

    return trajectory
end

-- Calculate air density based on environmental conditions
function AdvancedBallisticsSystem:calculateAirDensity()
    local temp = BALLISTICS_CONFIG.TEMPERATURE + 273.15 -- Convert to Kelvin
    local pressure = BALLISTICS_CONFIG.PRESSURE
    local humidity = BALLISTICS_CONFIG.HUMIDITY

    -- Simplified air density calculation
    local dryAirDensity = pressure / (287.058 * temp)
    local waterVaporDensity = (humidity * 0.01) * (17.62 * math.exp((17.27 * BALLISTICS_CONFIG.TEMPERATURE) / (BALLISTICS_CONFIG.TEMPERATURE + 237.3)))

    return dryAirDensity - waterVaporDensity
end

-- Calculate drag force on bullet
function AdvancedBallisticsSystem:calculateDrag(velocity, bulletData, airDensity)
    local speed = velocity.Magnitude
    if speed <= 0 then return Vector3.new(0, 0, 0) end

    -- Drag equation: F = 0.5 * ? * v² * Cd * A
    local crossSectionalArea = math.pi * (bulletData.diameter / 2)^2
    local dragMagnitude = 0.5 * airDensity * speed^2 * bulletData.dragCoefficient * crossSectionalArea

    -- Drag opposes velocity direction
    local dragDirection = -velocity.Unit

    return dragDirection * dragMagnitude
end

-- Calculate wind effect on bullet
function AdvancedBallisticsSystem:calculateWindEffect(velocity, bulletData)
    if not BALLISTICS_CONFIG.WIND_ENABLED then
        return Vector3.new(0, 0, 0)
    end

    -- Relative velocity between bullet and wind
    local relativeVelocity = velocity - self.currentWind
    local relativeSpeed = relativeVelocity.Magnitude

    if relativeSpeed <= 0 then return Vector3.new(0, 0, 0) end

    -- Calculate wind resistance
    local crossSectionalArea = math.pi * (bulletData.diameter / 2)^2
    local airDensity = self:calculateAirDensity()

    -- Simplified wind effect (perpendicular component)
    local windEffect = self.currentWind * 0.1 * (bulletData.dragCoefficient * crossSectionalArea)

    return windEffect
end

-- Simulate bullet flight
function AdvancedBallisticsSystem:simulateBullet(bullet)
    spawn(function()
        local ModernRaycastSystem = require(script.Parent.ModernRaycastSystem)
        local raycastSystem = ModernRaycastSystem.new()

        -- Create raycast config
        local config = raycastSystem:createConfig()
        config:addToExcludeList({bullet.owner.Character, self.effectsFolder})

        local lastPos = bullet.origin
        local currentTrajectoryIndex = 1

        while bullet.isActive and currentTrajectoryIndex <= #bullet.trajectory do
            local trajectoryPoint = bullet.trajectory[currentTrajectoryIndex]
            local currentPos = trajectoryPoint.position

            -- Raycast between last position and current position
            local direction = currentPos - lastPos
            local distance = direction.Magnitude

            if distance > 0 then
                local result = raycastSystem:cast(lastPos, direction, config)

                if result then
                    -- Bullet hit something
                    self:handleBulletHit(bullet, result, trajectoryPoint)
                    bullet.isActive = false
                    break
                end
            end

            lastPos = currentPos
            currentTrajectoryIndex = currentTrajectoryIndex + 1

            -- Update visual effects
            self:updateBulletVisuals(bullet, trajectoryPoint)

            wait(BALLISTICS_CONFIG.TIME_STEP)
        end

        -- Remove bullet from active list
        self:removeBullet(bullet)
    end)
end

-- Handle bullet hit
function AdvancedBallisticsSystem:handleBulletHit(bullet, raycastResult, trajectoryPoint)
    local hitPart = raycastResult.Instance
    local hitPosition = raycastResult.Position
    local hitNormal = raycastResult.Normal

    -- Calculate remaining energy
    local impactEnergy = trajectoryPoint.energy
    local impactVelocity = trajectoryPoint.velocity.Magnitude

    -- Calculate damage based on energy
    local damage = self:calculateDamage(bullet, impactEnergy, impactVelocity)

    -- Check for character hit
    local character = hitPart:FindFirstAncestorOfClass("Model")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and character ~= bullet.owner.Character then
        -- Apply damage
        self:applyBallisticDamage(character, hitPart, damage, trajectoryPoint)
    end

    -- Create impact effects
    self:createImpactEffects(hitPosition, hitNormal, raycastResult.Material, impactEnergy)

    -- Check for penetration
    if self:canPenetrate(bullet, raycastResult, impactEnergy) then
        self:handlePenetration(bullet, raycastResult, trajectoryPoint)
    end

    print("Bullet hit at", hitPosition, "with energy", impactEnergy, "damage", damage)
end

-- Calculate damage based on ballistic energy
function AdvancedBallisticsSystem:calculateDamage(bullet, energy, velocity)
    local bulletData = bullet.bulletData

    -- Base damage calculation using kinetic energy
    local baseDamage = energy * 0.001 -- Scale factor

    -- Velocity threshold for effectiveness
    local velocityFactor = math.min(velocity / bulletData.muzzleVelocity, 1.0)

    -- Apply bullet-specific modifiers
    local damage = baseDamage * velocityFactor * bulletData.energyRetention

    return math.floor(damage)
end

-- Apply ballistic damage to character
function AdvancedBallisticsSystem:applyBallisticDamage(character, hitPart, damage, trajectoryPoint)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Apply hit location multipliers
    local multiplier = 1.0
    if hitPart.Name == "Head" then
        multiplier = 2.5
    elseif hitPart.Name:find("Arm") or hitPart.Name:find("Leg") then
        multiplier = 0.8
    elseif hitPart.Name == "Torso" or hitPart.Name == "UpperTorso" then
        multiplier = 1.2
    end

    local finalDamage = damage * multiplier

    -- Apply damage
    humanoid:TakeDamage(finalDamage)

    -- Create damage indicator
    self:createDamageIndicator(hitPart.Position, finalDamage)

    print("Applied", finalDamage, "damage to", character.Name, "at", hitPart.Name)
end

-- Check if bullet can penetrate material
function AdvancedBallisticsSystem:canPenetrate(bullet, raycastResult, energy)
    local materialPenetration = {
        [Enum.Material.Glass] = 500,
        [Enum.Material.Plastic] = 800,
        [Enum.Material.Wood] = 1500,
        [Enum.Material.Concrete] = 3000,
        [Enum.Material.Metal] = 4000,
        [Enum.Material.DiamondPlate] = 6000
    }

    local requiredEnergy = materialPenetration[raycastResult.Material] or 2000
    return energy > requiredEnergy
end

-- Handle bullet penetration
function AdvancedBallisticsSystem:handlePenetration(bullet, raycastResult, trajectoryPoint)
    -- Reduce bullet energy
    local energyLoss = 0.3 -- 30% energy loss on penetration
    local newVelocity = trajectoryPoint.velocity * (1 - energyLoss)

    -- Calculate new trajectory from penetration point
    local penetrationPoint = raycastResult.Position + raycastResult.Normal * 0.1

    -- Continue simulation with reduced energy
    print("Bullet penetrated", raycastResult.Material, "continuing with reduced energy")
end

-- Create tracer effect
function AdvancedBallisticsSystem:createTracerEffect(bullet)
    self.tracerCount = self.tracerCount + 1

    if self.tracerCount % BALLISTICS_CONFIG.TRACER_EVERY_N_BULLETS ~= 0 then
        return
    end

    -- Create tracer visual
    local tracer = Instance.new("Part")
    tracer.Name = "BulletTracer"
    tracer.Size = Vector3.new(0.1, 0.1, 2)
    tracer.Shape = Enum.PartType.Cylinder
    tracer.Material = Enum.Material.Neon
    tracer.Color = Color3.fromRGB(255, 100, 0)
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Parent = self.effectsFolder

    bullet.tracerPart = tracer
end

-- Create bullet trail effect
function AdvancedBallisticsSystem:createBulletTrail(bullet)
    -- Create attachment for trail
    local attachment0 = Instance.new("Attachment")
    attachment0.Name = "TrailStart"

    local attachment1 = Instance.new("Attachment")
    attachment1.Name = "TrailEnd"

    -- Create trail
    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
    trail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    trail.Lifetime = 0.3
    trail.MinLength = 0
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Parent = self.effectsFolder

    bullet.trail = {
        trail = trail,
        attachment0 = attachment0,
        attachment1 = attachment1
    }
end

-- Update bullet visuals
function AdvancedBallisticsSystem:updateBulletVisuals(bullet, trajectoryPoint)
    -- Update tracer position
    if bullet.tracerPart then
        bullet.tracerPart.CFrame = CFrame.lookAt(
            trajectoryPoint.position,
            trajectoryPoint.position + trajectoryPoint.velocity.Unit
        )
    end

    -- Update trail
    if bullet.trail then
        bullet.trail.attachment0.WorldPosition = trajectoryPoint.position
        bullet.trail.attachment1.WorldPosition = trajectoryPoint.position + trajectoryPoint.velocity.Unit * 2
    end
end

-- Create impact effects
function AdvancedBallisticsSystem:createImpactEffects(position, normal, material, energy)
    -- Create impact spark
    local impact = Instance.new("Part")
    impact.Size = Vector3.new(0.2, 0.2, 0.2)
    impact.Shape = Enum.PartType.Ball
    impact.Material = Enum.Material.Neon
    impact.Color = Color3.fromRGB(255, 255, 0)
    impact.Anchored = true
    impact.CanCollide = false
    impact.CFrame = CFrame.new(position)
    impact.Parent = self.effectsFolder

    -- Scale based on energy
    local scale = math.min(energy / 1000, 3)
    impact.Size = impact.Size * scale

    -- Animate impact
    TweenService:Create(impact, TweenInfo.new(0.3), {
        Size = Vector3.new(0, 0, 0),
        Transparency = 1
    }):Play()

    game:GetService("Debris"):AddItem(impact, 0.5)
end

-- Create damage indicator
function AdvancedBallisticsSystem:createDamageIndicator(position, damage)
    local indicator = Instance.new("BillboardGui")
    indicator.Size = UDim2.new(0, 100, 0, 50)
    indicator.StudsOffset = Vector3.new(0, 3, 0)
    indicator.Parent = self.effectsFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "-" .. damage
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = indicator

    -- Animate damage indicator
    TweenService:Create(indicator, TweenInfo.new(1.5), {
        StudsOffset = Vector3.new(0, 6, 0)
    }):Play()

    TweenService:Create(label, TweenInfo.new(1.5), {
        TextTransparency = 1
    }):Play()

    game:GetService("Debris"):AddItem(indicator, 2)
end

-- Remove bullet from simulation
function AdvancedBallisticsSystem:removeBullet(bullet)
    -- Clean up visual effects
    if bullet.tracerPart then
        bullet.tracerPart:Destroy()
    end

    if bullet.trail then
        bullet.trail.trail:Destroy()
        bullet.trail.attachment0:Destroy()
        bullet.trail.attachment1:Destroy()
    end

    -- Remove from active bullets
    for i, activeBullet in ipairs(self.activeBullets) do
        if activeBullet.id == bullet.id then
            table.remove(self.activeBullets, i)
            break
        end
    end
end

-- Get bullet drop for distance (for scope zeroing)
function AdvancedBallisticsSystem:getBulletDrop(ammunition, distance)
    local bulletData = BULLET_DATA[ammunition] or BULLET_DATA["5.56x45_NATO"]

    -- Simplified drop calculation
    local timeOfFlight = distance / bulletData.muzzleVelocity
    local drop = 0.5 * BALLISTICS_CONFIG.GRAVITY * timeOfFlight^2

    return drop
end

-- Get wind drift for distance
function AdvancedBallisticsSystem:getWindDrift(ammunition, distance)
    local bulletData = BULLET_DATA[ammunition] or BULLET_DATA["5.56x45_NATO"]
    local timeOfFlight = distance / bulletData.muzzleVelocity

    -- Calculate wind drift
    local windEffect = self.currentWind * timeOfFlight * 0.1

    return windEffect
end

-- Get current environmental conditions
function AdvancedBallisticsSystem:getEnvironmentalConditions()
    return {
        wind = self.currentWind,
        temperature = BALLISTICS_CONFIG.TEMPERATURE,
        pressure = BALLISTICS_CONFIG.PRESSURE,
        humidity = BALLISTICS_CONFIG.HUMIDITY,
        airDensity = self:calculateAirDensity()
    }
end

-- Cleanup
function AdvancedBallisticsSystem:cleanup()
    -- Clean up all active bullets
    for _, bullet in ipairs(self.activeBullets) do
        self:removeBullet(bullet)
    end

    if self.effectsFolder then
        self.effectsFolder:Destroy()
    end
end

return AdvancedBallisticsSystem