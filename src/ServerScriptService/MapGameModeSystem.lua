local MapGameModeSystem = {}

-- Services
local Workspace = game:GetService("Workspace")

-- Missing global functions (these were causing the errors)
function createMetroMap()
    print("Creating Metro map...")
    -- Create basic metro map structure
    local metroMap = Instance.new("Folder")
    metroMap.Name = "MetroMap"
    metroMap.Parent = Workspace

    -- Add some basic geometry
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Size = Vector3.new(50, 1, 20)
    platform.Position = Vector3.new(0, 0, 0)
    platform.Anchored = true
    platform.BrickColor = BrickColor.new("Dark stone grey")
    platform.Parent = metroMap

    return metroMap
end

function createDesertMap()
    print("Creating Desert map...")
    -- Create basic desert map structure
    local desertMap = Instance.new("Folder")
    desertMap.Name = "DesertMap"
    desertMap.Parent = Workspace

    -- Add some basic geometry
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(200, 1, 200)
    ground.Position = Vector3.new(0, -1, 0)
    ground.Anchored = true
    ground.BrickColor = BrickColor.new("Bright yellow")
    ground.Parent = desertMap

    return desertMap
end

function createSpawnPoints()
    print("Creating spawn points...")
    local spawnPoints = {}

    -- Create team A spawn points
    for i = 1, 5 do
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "TeamASpawn" .. i
        spawn.Position = Vector3.new(-20 + (i * 2), 5, -30)
        spawn.TeamColor = BrickColor.new("Bright blue")
        spawn.Parent = Workspace
        table.insert(spawnPoints, spawn)
    end

    -- Create team B spawn points  
    for i = 1, 5 do
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "TeamBSpawn" .. i
        spawn.Position = Vector3.new(-20 + (i * 2), 5, 30)
        spawn.TeamColor = BrickColor.new("Bright red")
        spawn.Parent = Workspace
        table.insert(spawnPoints, spawn)
    end

    return spawnPoints
end

function createObjectives()
    print("Creating objectives...")
    local objectives = {}

    -- Create capture points
    for i = 1, 3 do
        local objective = Instance.new("Part")
        objective.Name = "CapturePoint" .. i
        objective.Size = Vector3.new(10, 1, 10)
        objective.Position = Vector3.new((i - 2) * 30, 1, 0)
        objective.Anchored = true
        objective.BrickColor = BrickColor.new("Bright green")
        objective.Parent = Workspace

        -- Add capture zone
        local zone = Instance.new("Part")
        zone.Name = "CaptureZone"
        zone.Size = Vector3.new(15, 20, 15)
        zone.Position = objective.Position + Vector3.new(0, 10, 0)
        zone.Anchored = true
        zone.CanCollide = false
        zone.Transparency = 0.7
        zone.BrickColor = BrickColor.new("Bright green")
        zone.Parent = objective

        table.insert(objectives, objective)
    end

    return objectives
end

-- Make functions global so other scripts can access them
_G.createMetroMap = createMetroMap
_G.createDesertMap = createDesertMap  
_G.createSpawnPoints = createSpawnPoints
_G.createObjectives = createObjectives

-- MapGameModeSystem main functions
function MapGameModeSystem.initializeMap(mapName)
    print("Initializing map:", mapName)

    if mapName == "Metro" then
        return createMetroMap()
    elseif mapName == "Desert" then
        return createDesertMap()
    else
        warn("Unknown map:", mapName)
        return nil
    end
end

function MapGameModeSystem.setupGameMode(gameMode)
    print("Setting up game mode:", gameMode)

    -- Create spawn points and objectives for any game mode
    local spawns = createSpawnPoints()
    local objectives = createObjectives()

    return {
        spawns = spawns,
        objectives = objectives
    }
end

return MapGameModeSystem