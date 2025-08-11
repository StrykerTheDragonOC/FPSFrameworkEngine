-- ModernRaycastSystem.lua
-- Updated raycast system using Include/Exclude instead of deprecated Whitelist/Blacklist
-- Place in ReplicatedStorage.FPSSystem.Modules.ModernRaycastSystem

local ModernRaycastSystem = {}
ModernRaycastSystem.__index = ModernRaycastSystem

-- Services
local workspace = workspace
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Performance tracking
local raycastCount = 0
local lastFrameTime = 0
local MAX_RAYCASTS_PER_FRAME = 50

-- Material penetration values
local MATERIAL_PENETRATION = {
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
    self.excludeList = {} -- Clear exclude list when using include
    return self
end

-- Set filter to Exclude mode (ignore specified objects)
function RaycastConfig:setExcludeFilter(instanceList)
    self.filterType = "Exclude"
    self.excludeList = instanceList or {}
    self.includeList = {} -- Clear include list when using exclude
    return self
end

-- Add objects to include list
function RaycastConfig:addToIncludeList(instances)
    if type(instances) == "table" then
        for _, instance in ipairs(instances) do
            if instance and instance.Parent then
                table.insert(self.includeList, instance)
            end
        end
    elseif instances and instances.Parent then
        table.insert(self.includeList, instances)
    end
    return self
end

-- Add objects to exclude list
function RaycastConfig:addToExcludeList(instances)
    if type(instances) == "table" then
        for _, instance in ipairs(instances) do
            if instance and instance.Parent then
                table.insert(self.excludeList, instance)
            end
        end
    elseif instances and instances.Parent then
        table.insert(self.excludeList, instances)
    end
    return self
end

-- Remove objects from include list
function RaycastConfig:removeFromIncludeList(instances)
    if type(instances) == "table" then
        for _, instance in ipairs(instances) do
            for i = #self.includeList, 1, -1 do
                if self.includeList[i] == instance then
                    table.remove(self.includeList, i)
                end
            end
        end
    else
        for i = #self.includeList, 1, -1 do
            if self.includeList[i] == instances then
                table.remove(self.includeList, i)
            end
        end
    end
    return self
end

-- Remove objects from exclude list
function RaycastConfig:removeFromExcludeList(instances)
    if type(instances) == "table" then
        for _, instance in ipairs(instances) do
            for i = #self.excludeList, 1, -1 do
                if self.excludeList[i] == instance then
                    table.remove(self.excludeList, i)
                end
            end
        end
    else
        for i = #self.excludeList, 1, -1 do
            if self.excludeList[i] == instances then
                table.remove(self.excludeList, i)
            end
        end
    end
    return self
end

-- Convert to RaycastParams
function RaycastConfig:toRaycastParams()
    local params = RaycastParams.new()

    if self.filterType == "Include" and #self.includeList > 0 then
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = self.includeList
    else
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

    -- Performance tracking
    self.lastFrameTime = tick()
    self.frameRaycastCount = 0

    -- Add common excludes
    self:updateDefaultExcludes()

    return self
end

-- Update default excludes (call when character spawns)
function ModernRaycastSystem:updateDefaultExcludes()
    self.defaultExcludes = {}

    if self.player and self.player.Character then
        table.insert(self.defaultExcludes, self.player.Character)
    end

    -- Add camera and other common excludes
    if workspace.CurrentCamera then
        table.insert(self.defaultExcludes, workspace.CurrentCamera)
    end

    -- Add effects folders
    local effectsFolders = {
        "WeaponEffects",
        "GrenadeEffects", 
        "MeleeEffects",
        "MovementEffects",
        "Effects",
        "Particles"
    }

    for _, folderName in ipairs(effectsFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            table.insert(self.defaultExcludes, folder)
        end
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
    -- Performance throttling
    local currentTime = tick()
    if currentTime ~= self.lastFrameTime then
        self.lastFrameTime = currentTime
        self.frameRaycastCount = 0
    end

    self.frameRaycastCount = self.frameRaycastCount + 1
    if self.frameRaycastCount > MAX_RAYCASTS_PER_FRAME then
        warn("ModernRaycastSystem: Max raycasts per frame exceeded, skipping raycast")
        return nil
    end

    local raycastParams = config:toRaycastParams()
    return workspace:Raycast(origin, direction, raycastParams)
end

-- Perform multiple raycasts (for penetration, spread, etc.)
function ModernRaycastSystem:multiCast(origins, directions, config)
    local results = {}

    for i = 1, math.min(#origins, #directions) do
        local result = self:cast(origins[i], directions[i], config)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

-- Advanced weapon raycast with penetration
function ModernRaycastSystem:weaponRaycast(origin, direction, maxDistance, penetrationPower, damage)
    local results = {}
    local currentOrigin = origin
    local currentDirection = direction.Unit
    local remainingDistance = maxDistance or 1000
    local remainingPenetration = penetrationPower or 1.0
    local remainingDamage = damage or 100

    -- Create config for weapon raycast
    local config = self:createConfig()

    local penetrationCount = 0
    local maxPenetrations = 3

    while remainingDistance > 0 and remainingPenetration > 0 and penetrationCount < maxPenetrations do
        local rayDirection = currentDirection * remainingDistance
        local result = self:cast(currentOrigin, rayDirection, config)

        if not result then
            break
        end

        -- Calculate damage based on distance
        local hitDistance = (result.Position - currentOrigin).Magnitude
        local distanceFalloff = math.max(0.1, 1 - (hitDistance / maxDistance))
        local hitDamage = remainingDamage * distanceFalloff

        -- Store hit result
        table.insert(results, {
            result = result,
            damage = hitDamage,
            penetrationCount = penetrationCount,
            distance = hitDistance
        })

        -- Check for penetration
        if result.Instance and result.Instance.Material then
            local materialPenetration = MATERIAL_PENETRATION[result.Instance.Material] or 0.5
            local penetrationReduction = materialPenetration * remainingPenetration

            if penetrationReduction > 0.1 then
                -- Calculate penetration
                remainingPenetration = remainingPenetration - (1 - materialPenetration)
                remainingDamage = remainingDamage * materialPenetration

                -- Continue ray from exit point
                currentOrigin = result.Position + (currentDirection * 0.1)
                remainingDistance = remainingDistance - hitDistance
                penetrationCount = penetrationCount + 1

                -- Add hit instance to exclude list for next raycast
                config:addToExcludeList(result.Instance)
            else
                -- Not enough penetration power
                break
            end
        else
            -- Hit something that can't be penetrated
            break
        end
    end

    return results
end

-- Quick raycast for simple hit detection
function ModernRaycastSystem:quickCast(origin, direction, maxDistance)
    local config = self:createConfig()
    local rayDirection = direction.Unit * (maxDistance or 1000)
    return self:cast(origin, rayDirection, config)
end

-- Raycast with custom filter
function ModernRaycastSystem:customCast(origin, direction, maxDistance, includeList, excludeList)
    local config = RaycastConfig.new()

    if includeList and #includeList > 0 then
        config:setIncludeFilter(includeList)
    elseif excludeList and #excludeList > 0 then
        config:setExcludeFilter(excludeList)
    else
        config:setExcludeFilter(self.defaultExcludes)
    end

    local rayDirection = direction.Unit * (maxDistance or 1000)
    return self:cast(origin, rayDirection, config)
end

-- Cleanup
function ModernRaycastSystem:cleanup()
    self.defaultExcludes = {}
    self.player = nil
end

-- Create global raycast function for backward compatibility
_G.ModernRaycast = function(origin, direction, maxDistance, includeList, excludeList, respectCanCollide)
    local system = ModernRaycastSystem.new()
    local config = RaycastConfig.new()

    if includeList and #includeList > 0 then
        config:setIncludeFilter(includeList)
    elseif excludeList and #excludeList > 0 then
        config:setExcludeFilter(excludeList)
    else
        config:setExcludeFilter(system.defaultExcludes)
    end

    if respectCanCollide ~= nil then
        config.respectCanCollide = respectCanCollide
    end

    local rayDirection = direction.Unit * (maxDistance or 1000)
    return system:cast(origin, rayDirection, config)
end

return ModernRaycastSystem