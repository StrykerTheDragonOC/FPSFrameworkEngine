-- RaycastUtility.lua
-- Advanced raycast system using Include/Exclude instead of Whitelist/Blacklist
-- Place in ReplicatedStorage.FPSSystem.Modules

local RaycastUtility = {}

-- Services
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Raycast configuration
local RAYCAST_CONFIG = {
    -- Default ranges for different systems
    WEAPON_RANGE = 1000,
    MELEE_RANGE = 10,
    GRENADE_RANGE = 100,
    INTERACTION_RANGE = 20,

    -- Performance settings
    MAX_RAYS_PER_FRAME = 50,
    RAY_THROTTLE_TIME = 0.016,  -- ~60 FPS

    -- Penetration settings
    WALL_PENETRATION = {
        THIN_WALL_THICKNESS = 1,
        MEDIUM_WALL_THICKNESS = 3,
        THICK_WALL_THICKNESS = 6,
        MAX_PENETRATION_DEPTH = 10
    },

    -- Material penetration values
    MATERIAL_PENETRATION = {
        [Enum.Material.Wood] = 0.8,
        [Enum.Material.Metal] = 0.3,
        [Enum.Material.Concrete] = 0.2,
        [Enum.Material.Brick] = 0.4,
        [Enum.Material.Glass] = 0.9,
        [Enum.Material.Plastic] = 0.7,
        [Enum.Material.Fabric] = 0.95,
        [Enum.Material.CorrodedMetal] = 0.5,
        [Enum.Material.Grass] = 1.0,
        [Enum.Material.Sand] = 0.6,
        [Enum.Material.Snow] = 0.9,
        [Enum.Material.Water] = 0.1
    }
}

-- Cached raycast parameters for performance
local cachedParams = {}
local raycastCount = 0
local lastThrottleTime = 0

-- Create raycast parameters with Include/Exclude filtering
function RaycastUtility.createParams(filterType, filterInstances, respectCanCollide)
    -- Validate filter type
    if filterType ~= "Include" and filterType ~= "Exclude" then
        warn("RaycastUtility: Invalid filter type. Use 'Include' or 'Exclude'")
        return nil
    end

    local params = RaycastParams.new()

    -- Set filter type using modern Include/Exclude terminology
    if filterType == "Include" then
        params.FilterType = Enum.RaycastFilterType.Include
    else
        params.FilterType = Enum.RaycastFilterType.Exclude
    end

    -- Set filter instances
    if filterInstances and type(filterInstances) == "table" then
        params.FilterDescendantsInstances = filterInstances
    else
        params.FilterDescendantsInstances = {}
    end

    -- Set collision behavior
    params.RespectCanCollide = respectCanCollide ~= false  -- Default to true

    return params
end

-- Perform a single raycast with throttling
function RaycastUtility.cast(origin, direction, maxDistance, filterType, filterInstances, respectCanCollide)
    -- Throttle raycasts for performance
    local currentTime = tick()
    if currentTime - lastThrottleTime < RAYCAST_CONFIG.RAY_THROTTLE_TIME then
        if raycastCount >= RAYCAST_CONFIG.MAX_RAYS_PER_FRAME then
            return nil  -- Skip this raycast to maintain performance
        end
    else
        raycastCount = 0
        lastThrottleTime = currentTime
    end

    raycastCount = raycastCount + 1

    -- Create raycast parameters
    local params = RaycastUtility.createParams(filterType, filterInstances, respectCanCollide)
    if not params then return nil end

    -- Normalize direction and apply distance
    local normalizedDirection = direction.Unit * (maxDistance or RAYCAST_CONFIG.WEAPON_RANGE)

    -- Perform raycast
    return workspace:Raycast(origin, normalizedDirection, params)
end

-- Advanced weapon raycast with penetration
function RaycastUtility.weaponRaycast(origin, direction, maxDistance, damage, penetrationPower)
    penetrationPower = penetrationPower or 1.0
    local remainingDamage = damage
    local currentOrigin = origin
    local currentDirection = direction.Unit
    local totalDistance = 0
    local hits = {}

    -- Default exclude list for weapon raycasts
    local excludeList = {
        Players.LocalPlayer.Character,
        workspace:FindFirstChild("Effects"),
        workspace:FindFirstChild("Particles"),
        workspace:FindFirstChild("Sounds")
    }

    -- Perform multiple raycasts for penetration
    for penetrationLevel = 1, 5 do  -- Max 5 penetration levels
        if totalDistance >= (maxDistance or RAYCAST_CONFIG.WEAPON_RANGE) then break end
        if remainingDamage <= 0 then break end

        local remainingDistance = (maxDistance or RAYCAST_CONFIG.WEAPON_RANGE) - totalDistance
        local result = RaycastUtility.cast(
            currentOrigin,
            currentDirection,
            remainingDistance,
            "Exclude",
            excludeList,
            true
        )

        if not result then break end

        -- Record hit
        local hitInfo = {
            instance = result.Instance,
            position = result.Position,
            normal = result.Normal,
            distance = result.Distance + totalDistance,
            damage = remainingDamage,
            penetrationLevel = penetrationLevel
        }
        table.insert(hits, hitInfo)

        -- Check if hit a character
        local character = result.Instance.Parent
        if character:FindFirstChild("Humanoid") then
            -- Hit a player/NPC, reduce damage significantly
            remainingDamage = remainingDamage * 0.2
        else
            -- Hit environment, check material penetration
            local material = result.Instance.Material
            local penetrationFactor = RAYCAST_CONFIG.MATERIAL_PENETRATION[material] or 0.1

            -- Apply penetration power modifier
            penetrationFactor = penetrationFactor * penetrationPower

            remainingDamage = remainingDamage * penetrationFactor
        end

        -- Update position for next raycast
        currentOrigin = result.Position + currentDirection * 0.1  -- Offset slightly to avoid self-intersection
        totalDistance = totalDistance + result.Distance

        -- Add hit object to exclude list to prevent hitting it again
        table.insert(excludeList, result.Instance)
    end

    return hits
end

-- Melee attack raycast with multiple directions
function RaycastUtility.meleeRaycast(origin, centerDirection, range, attackAngle, excludeList)
    local hits = {}
    attackAngle = attackAngle or 30  -- Default 30 degree attack cone

    -- Create exclude list for melee
    local meleeExcludes = excludeList or {
        Players.LocalPlayer.Character,
        workspace:FindFirstChild("MeleeEffects"),
        workspace:FindFirstChild("Effects")
    }

    -- Center ray
    local centerResult = RaycastUtility.cast(
        origin,
        centerDirection,
        range,
        "Exclude",
        meleeExcludes,
        true
    )

    if centerResult then
        table.insert(hits, {
            instance = centerResult.Instance,
            position = centerResult.Position,
            normal = centerResult.Normal,
            distance = centerResult.Distance,
            isCenter = true
        })
    end

    -- Side rays for wider attack
    local angleStep = attackAngle / 4  -- 4 rays on each side
    for i = 1, 4 do
        for _, side in ipairs({-1, 1}) do  -- Left and right
            local angle = side * angleStep * i
            local sideDirection = CFrame.Angles(0, math.rad(angle), 0) * centerDirection

            local sideResult = RaycastUtility.cast(
                origin,
                sideDirection,
                range * 0.8,  -- Slightly shorter range for side attacks
                "Exclude",
                meleeExcludes,
                true
            )

            if sideResult then
                -- Check if we already hit this object
                local alreadyHit = false
                for _, hit in ipairs(hits) do
                    if hit.instance == sideResult.Instance then
                        alreadyHit = true
                        break
                    end
                end

                if not alreadyHit then
                    table.insert(hits, {
                        instance = sideResult.Instance,
                        position = sideResult.Position,
                        normal = sideResult.Normal,
                        distance = sideResult.Distance,
                        isCenter = false,
                        angle = angle
                    })
                end
            end
        end
    end

    return hits
end

-- Grenade trajectory simulation raycast
function RaycastUtility.grenadeTrajectoryRaycast(startPos, velocity, timeStep, maxTime, excludeList)
    local trajectoryPoints = {}
    local currentPos = startPos
    local currentVel = velocity
    local gravity = Vector3.new(0, -196.2, 0)  -- Roblox gravity
    local time = 0

    -- Default exclude list for grenades
    local grenadeExcludes = excludeList or {
        Players.LocalPlayer.Character,
        workspace:FindFirstChild("GrenadeEffects"),
        workspace:FindFirstChild("Effects")
    }

    while time < maxTime do
        -- Apply physics
        currentVel = currentVel + gravity * timeStep
        local nextPos = currentPos + currentVel * timeStep

        -- Check for collision
        local result = RaycastUtility.cast(
            currentPos,
            nextPos - currentPos,
            (nextPos - currentPos).Magnitude,
            "Exclude",
            grenadeExcludes,
            true
        )

        if result then
            -- Hit something
            table.insert(trajectoryPoints, {
                position = result.Position,
                normal = result.Normal,
                hit = result.Instance,
                time = time,
                velocity = currentVel,
                isHit = true
            })
            break
        else
            -- No hit, continue trajectory
            table.insert(trajectoryPoints, {
                position = nextPos,
                time = time,
                velocity = currentVel,
                isHit = false
            })
            currentPos = nextPos
        end

        time = time + timeStep
    end

    return trajectoryPoints
end

-- Line of sight check between two points
function RaycastUtility.lineOfSight(startPos, endPos, includeList, respectCanCollide)
    local direction = endPos - startPos
    local distance = direction.Magnitude

    local result = RaycastUtility.cast(
        startPos,
        direction,
        distance,
        "Include",
        includeList or {workspace.Terrain},
        respectCanCollide
    )

    -- If no hit, line of sight is clear
    -- If hit and distance is less than target distance, something is blocking
    return result == nil or result.Distance >= distance * 0.95
end

-- Ground check raycast
function RaycastUtility.groundCheck(character, maxDistance)
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false, nil
    end

    local rootPart = character.HumanoidRootPart
    local startPos = rootPart.Position
    local direction = Vector3.new(0, -1, 0)

    local excludeList = {character}

    local result = RaycastUtility.cast(
        startPos,
        direction,
        maxDistance or 10,
        "Exclude",
        excludeList,
        true
    )

    if result then
        return true, {
            position = result.Position,
            normal = result.Normal,
            material = result.Instance.Material,
            distance = result.Distance,
            instance = result.Instance
        }
    end

    return false, nil
end

-- Wall check for movement systems
function RaycastUtility.wallCheck(origin, direction, maxDistance, character)
    local excludeList = {
        character,
        workspace:FindFirstChild("Effects"),
        workspace:FindFirstChild("Particles")
    }

    local result = RaycastUtility.cast(
        origin,
        direction,
        maxDistance or 5,
        "Exclude",
        excludeList,
        true
    )

    if result then
        return true, {
            position = result.Position,
            normal = result.Normal,
            distance = result.Distance,
            instance = result.Instance,
            canClimb = RaycastUtility.canClimbSurface(result.Normal),
            canWallRun = RaycastUtility.canWallRun(result.Normal)
        }
    end

    return false, nil
end

-- Check if surface can be climbed
function RaycastUtility.canClimbSurface(surfaceNormal)
    local climbAngle = math.deg(math.acos(surfaceNormal:Dot(Vector3.new(0, 1, 0))))
    return climbAngle > 45 and climbAngle < 85  -- Can climb walls between 45-85 degrees
end

-- Check if surface can be wall-run on
function RaycastUtility.canWallRun(surfaceNormal)
    local wallAngle = math.deg(math.acos(surfaceNormal:Dot(Vector3.new(0, 1, 0))))
    return wallAngle > 75 and wallAngle < 105  -- Can wall-run on near-vertical surfaces
end

-- Advanced multi-ray spread pattern (for shotguns, etc.)
function RaycastUtility.spreadRaycast(origin, centerDirection, spread, pelletCount, maxDistance, damage, excludeList)
    local hits = {}

    for i = 1, pelletCount do
        -- Calculate random spread
        local spreadX = (math.random() - 0.5) * 2 * spread
        local spreadY = (math.random() - 0.5) * 2 * spread

        -- Apply spread to direction
        local spreadDirection = CFrame.Angles(math.rad(spreadY), math.rad(spreadX), 0) * centerDirection

        -- Perform raycast for this pellet
        local result = RaycastUtility.cast(
            origin,
            spreadDirection,
            maxDistance,
            "Exclude",
            excludeList,
            true
        )

        if result then
            table.insert(hits, {
                instance = result.Instance,
                position = result.Position,
                normal = result.Normal,
                distance = result.Distance,
                damage = damage / pelletCount,  -- Distribute damage across pellets
                pelletIndex = i
            })
        end
    end

    return hits
end

-- Sphere cast simulation using multiple rays
function RaycastUtility.sphereCast(origin, direction, radius, maxDistance, excludeList)
    local hits = {}
    local centerHit = RaycastUtility.cast(origin, direction, maxDistance, "Exclude", excludeList, true)

    if centerHit then
        table.insert(hits, centerHit)
    end

    -- Create rays around the sphere
    local rayCount = 8
    for i = 1, rayCount do
        local angle = (i / rayCount) * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)

        -- Rotate offset to match direction
        local rotatedOffset = CFrame.lookAt(Vector3.new(), direction) * offset
        local rayOrigin = origin + rotatedOffset

        local result = RaycastUtility.cast(rayOrigin, direction, maxDistance, "Exclude", excludeList, true)
        if result then
            -- Check if we already have this hit
            local isDuplicate = false
            for _, hit in ipairs(hits) do
                if hit.Instance == result.Instance and (hit.Position - result.Position).Magnitude < 1 then
                    isDuplicate = true
                    break
                end
            end

            if not isDuplicate then
                table.insert(hits, result)
            end
        end
    end

    return hits
end

-- Get all players/characters in a radius using raycasts
function RaycastUtility.getTargetsInRadius(origin, radius, excludeCharacters)
    local targets = {}
    excludeCharacters = excludeCharacters or {}

    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character

            -- Skip excluded characters
            local isExcluded = false
            for _, excluded in ipairs(excludeCharacters) do
                if excluded == character then
                    isExcluded = true
                    break
                end
            end

            if not isExcluded then
                local targetPos = character.HumanoidRootPart.Position
                local distance = (origin - targetPos).Magnitude

                if distance <= radius then
                    -- Check line of sight
                    local hasLineOfSight = RaycastUtility.lineOfSight(
                        origin,
                        targetPos,
                        {workspace.Terrain, workspace:FindFirstChild("Map")},
                        true
                    )

                    table.insert(targets, {
                        character = character,
                        player = player,
                        position = targetPos,
                        distance = distance,
                        lineOfSight = hasLineOfSight
                    })
                end
            end
        end
    end

    return targets
end

-- Debug visualization for raycasts (development only)
function RaycastUtility.visualizeRay(origin, direction, maxDistance, color, lifetime)
    if not game:GetService("RunService"):IsStudio() then return end  -- Only in studio

    local part = Instance.new("Part")
    part.Name = "RayVisualization"
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = color or Color3.fromRGB(255, 0, 0)
    part.Size = Vector3.new(0.1, 0.1, maxDistance or RAYCAST_CONFIG.WEAPON_RANGE)
    part.CFrame = CFrame.lookAt(origin, origin + direction.Unit * (maxDistance or RAYCAST_CONFIG.WEAPON_RANGE)) * CFrame.new(0, 0, -part.Size.Z/2)
    part.Parent = workspace

    game:GetService("Debris"):AddItem(part, lifetime or 1)
end

-- Validate raycast result
function RaycastUtility.validateResult(result, expectedTypes)
    if not result then return false end

    expectedTypes = expectedTypes or {"Part", "MeshPart", "UnionOperation"}

    local instanceType = result.Instance.ClassName
    for _, validType in ipairs(expectedTypes) do
        if instanceType == validType then
            return true
        end
    end

    return false
end

-- Performance monitoring
function RaycastUtility.getPerformanceStats()
    return {
        raysThisFrame = raycastCount,
        lastThrottleTime = lastThrottleTime,
        maxRaysPerFrame = RAYCAST_CONFIG.MAX_RAYS_PER_FRAME,
        throttleTime = RAYCAST_CONFIG.RAY_THROTTLE_TIME
    }
end

-- Configuration functions
function RaycastUtility.setMaxRaysPerFrame(maxRays)
    RAYCAST_CONFIG.MAX_RAYS_PER_FRAME = maxRays
end

function RaycastUtility.setThrottleTime(time)
    RAYCAST_CONFIG.RAY_THROTTLE_TIME = time
end

return RaycastUtility