-- Modern Raycast System with Include/Exclude Terminology
-- Place in ReplicatedStorage.FPSSystem.Modules.ModernRaycastSystem
local ModernRaycastSystem = {}
ModernRaycastSystem.__index = ModernRaycastSystem

-- Services
local workspace = workspace
local Players = game:GetService("Players")

-- Modern RaycastConfig class using Include/Exclude terminology
local RaycastConfig = {}
RaycastConfig.__index = RaycastConfig

function RaycastConfig.new()
    local self = setmetatable({}, RaycastConfig)

    -- Using modern Include/Exclude terminology instead of Whitelist/Blacklist
    self.filterType = "Exclude" -- "Include" or "Exclude"
    self.includeList = {} -- Objects to INCLUDE in raycast (only these will be hit)
    self.excludeList = {} -- Objects to EXCLUDE from raycast (these will be ignored)
    self.respectCanCollide = true
    self.ignoreWater = false
    self.collisionGroup = "Default"

    return self
end

-- Set filter to Include mode (only hit specified objects)
function RaycastConfig:setIncludeFilter(instanceList)
    self.filterType = "Include"
    self.includeList = instanceList or {}
    return self
end

-- Set filter to Exclude mode (ignore specified objects)
function RaycastConfig:setExcludeFilter(instanceList)
    self.filterType = "Exclude"
    self.excludeList = instanceList or {}
    return self
end

-- Add objects to include list
function RaycastConfig:addToIncludeList(instances)
    if type(instances) == "table" then
        for _, instance in ipairs(instances) do
            table.insert(self.includeList, instance)
        end
    else
        table.insert(self.includeList, instances)
    end
    return self
end

-- Add objects to exclude list
function RaycastConfig:addToExcludeList(instances)
    if type(instances) == "table" then
        for _, instance in ipairs(instances) do
            table.insert(self.excludeList, instance)
        end
    else
        table.insert(self.excludeList, instances)
    end
    return self
end

-- Remove objects from include list
function RaycastConfig:removeFromIncludeList(instances)
    if type(instances) ~= "table" then
        instances = {instances}
    end

    for _, instanceToRemove in ipairs(instances) do
        for i, instance in ipairs(self.includeList) do
            if instance == instanceToRemove then
                table.remove(self.includeList, i)
                break
            end
        end
    end
    return self
end

-- Remove objects from exclude list
function RaycastConfig:removeFromExcludeList(instances)
    if type(instances) ~= "table" then
        instances = {instances}
    end

    for _, instanceToRemove in ipairs(instances) do
        for i, instance in ipairs(self.excludeList) do
            if instance == instanceToRemove then
                table.remove(self.excludeList, i)
                break
            end
        end
    end
    return self
end

-- Convert to Roblox RaycastParams
function RaycastConfig:toRaycastParams()
    local params = RaycastParams.new()

    if self.filterType == "Include" then
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = self.includeList
    else -- Exclude
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = self.excludeList
    end

    params.RespectCanCollide = self.respectCanCollide
    params.IgnoreWater = self.ignoreWater
    params.CollisionGroup = self.collisionGroup

    return params
end

-- Main ModernRaycastSystem
function ModernRaycastSystem.new()
    local self = setmetatable({}, ModernRaycastSystem)

    -- Default exclude list for FPS games
    self.defaultExcludes = {}

    -- Player reference
    self.player = Players.LocalPlayer

    -- Add common excludes
    self:addDefaultExcludes()

    return self
end

-- Add common objects to exclude by default
function ModernRaycastSystem:addDefaultExcludes()
    if self.player and self.player.Character then
        table.insert(self.defaultExcludes, self.player.Character)
    end

    -- Add camera and other common excludes
    table.insert(self.defaultExcludes, workspace.CurrentCamera)

    -- Add effects folders
    local effectsFolder = workspace:FindFirstChild("WeaponEffects")
    if effectsFolder then
        table.insert(self.defaultExcludes, effectsFolder)
    end
end

-- Create a new raycast config with default excludes
function ModernRaycastSystem:createConfig()
    local config = RaycastConfig.new()
    config:setExcludeFilter(self.defaultExcludes)
    return config
end

-- Perform a single raycast with modern config
function ModernRaycastSystem:cast(origin, direction, config)
    local raycastParams = config:toRaycastParams()
    return workspace:Raycast(origin, direction, raycastParams)
end

-- Perform multiple raycasts (for penetration, spread, etc.)
function ModernRaycastSystem:multiCast(origin, directions, config)
    local results = {}
    local raycastParams = config:toRaycastParams()

    for i, direction in ipairs(directions) do
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result then
            table.insert(results, {
                index = i,
                result = result,
                direction = direction
            })
        end
    end

    return results
end

-- Perform penetration raycast (multiple hits through objects)
function ModernRaycastSystem:penetrationCast(origin, direction, maxPenetrations, config)
    local hits = {}
    local currentOrigin = origin
    local currentDirection = direction
    local penetrationCount = 0

    -- Clone config to avoid modifying original
    local workingConfig = RaycastConfig.new()
    workingConfig.filterType = config.filterType
    workingConfig.includeList = {table.unpack(config.includeList)}
    workingConfig.excludeList = {table.unpack(config.excludeList)}
    workingConfig.respectCanCollide = config.respectCanCollide
    workingConfig.ignoreWater = config.ignoreWater
    workingConfig.collisionGroup = config.collisionGroup

    while penetrationCount < maxPenetrations do
        local raycastParams = workingConfig:toRaycastParams()
        local result = workspace:Raycast(currentOrigin, currentDirection, raycastParams)

        if result then
            table.insert(hits, {
                hitPart = result.Instance,
                hitPosition = result.Position,
                hitNormal = result.Normal,
                material = result.Material,
                distance = result.Distance,
                penetrationIndex = penetrationCount
            })

            -- Add hit part to exclude list for next raycast
            workingConfig:addToExcludeList(result.Instance)

            -- Calculate exit point (simplified)
            local thickness = self:estimateThickness(result.Instance)
            currentOrigin = result.Position + currentDirection * (thickness + 0.1)

            penetrationCount = penetrationCount + 1
        else
            break
        end
    end

    return hits
end

-- Perform area raycast (multiple rays in a pattern)
function ModernRaycastSystem:areaCast(origin, centerDirection, radius, rayCount, config)
    local hits = {}
    local raycastParams = config:toRaycastParams()

    -- Generate ray directions in a circle pattern
    for i = 1, rayCount do
        local angle = (i / rayCount) * 2 * math.pi
        local offset = Vector3.new(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
            0
        )

        local rayDirection = (centerDirection + offset).Unit * centerDirection.Magnitude
        local result = workspace:Raycast(origin, rayDirection, raycastParams)

        if result then
            table.insert(hits, {
                rayIndex = i,
                angle = angle,
                hitPart = result.Instance,
                hitPosition = result.Position,
                hitNormal = result.Normal,
                material = result.Material,
                distance = result.Distance
            })
        end
    end

    return hits
end

-- Perform shotgun-style raycast (random spread pattern)
function ModernRaycastSystem:shotgunCast(origin, centerDirection, spreadAngle, pelletCount, config)
    local hits = {}
    local raycastParams = config:toRaycastParams()

    for i = 1, pelletCount do
        -- Generate random spread
        local spreadX = (math.random() - 0.5) * spreadAngle
        local spreadY = (math.random() - 0.5) * spreadAngle

        local spreadDirection = centerDirection + Vector3.new(spreadX, spreadY, 0)
        spreadDirection = spreadDirection.Unit * centerDirection.Magnitude

        local result = workspace:Raycast(origin, spreadDirection, raycastParams)

        if result then
            table.insert(hits, {
                pelletIndex = i,
                spreadX = spreadX,
                spreadY = spreadY,
                hitPart = result.Instance,
                hitPosition = result.Position,
                hitNormal = result.Normal,
                material = result.Material,
                distance = result.Distance
            })
        end
    end

    return hits
end

-- Check line of sight between two points
function ModernRaycastSystem:hasLineOfSight(startPos, endPos, config)
    local direction = endPos - startPos
    local raycastParams = config:toRaycastParams()
    local result = workspace:Raycast(startPos, direction, raycastParams)

    -- If no hit, or hit is very close to end position, line of sight exists
    if not result then
        return true
    end

    local distanceToHit = (result.Position - startPos).Magnitude
    local totalDistance = direction.Magnitude

    -- Allow small tolerance for floating point errors
    return (totalDistance - distanceToHit) < 0.1
end

-- Get all objects within radius using raycast
function ModernRaycastSystem:getObjectsInRadius(center, radius, rayCount, config)
    local objects = {}
    local objectSet = {} -- To avoid duplicates

    -- Cast rays in all directions
    for i = 1, rayCount do
        local theta = (i / rayCount) * 2 * math.pi
        local phi = math.acos(2 * math.random() - 1) -- Random elevation

        local direction = Vector3.new(
            radius * math.sin(phi) * math.cos(theta),
            radius * math.sin(phi) * math.sin(theta),
            radius * math.cos(phi)
        )

        local raycastParams = config:toRaycastParams()
        local result = workspace:Raycast(center, direction, raycastParams)

        if result and not objectSet[result.Instance] then
            objectSet[result.Instance] = true
            table.insert(objects, {
                object = result.Instance,
                distance = result.Distance,
                position = result.Position,
                normal = result.Normal
            })
        end
    end

    return objects
end

-- Estimate object thickness (helper function)
function ModernRaycastSystem:estimateThickness(part)
    if not part or not part:IsA("BasePart") then
        return 0.5
    end

    local size = part.Size
    local avgSize = (size.X + size.Y + size.Z) / 3
    return math.min(avgSize * 0.3, 5) -- Cap at 5 studs
end

-- Create config for weapon firing
function ModernRaycastSystem:createWeaponConfig(player, weapon, viewmodel)
    local config = self:createConfig()

    -- Exclude player character
    if player and player.Character then
        config:addToExcludeList(player.Character)
    end

    -- Exclude viewmodel
    if viewmodel and viewmodel.container then
        config:addToExcludeList(viewmodel.container)
    end

    -- Exclude weapon if it's separate
    if weapon then
        config:addToExcludeList(weapon)
    end

    return config
end

-- Create config for player detection (for AI or hit detection)
function ModernRaycastSystem:createPlayerDetectionConfig(excludePlayers)
    local config = RaycastConfig.new()

    -- Include only players
    local playerCharacters = {}
    for _, player in pairs(Players:GetPlayers()) do