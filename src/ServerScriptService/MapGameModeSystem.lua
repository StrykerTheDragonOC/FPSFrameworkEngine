-- MapGameModeSystem.lua
-- Complete map loading and game mode management system
-- Place in ServerScriptService/MapGameModeSystem.lua

local MapGameModeSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Game state
local currentMap = nil
local currentGameMode = nil
local gameState = "WAITING" -- WAITING, COUNTDOWN, ACTIVE, ENDED
local gameData = {
    scores = {Team1 = 0, Team2 = 0},
    timeRemaining = 0,
    playerCount = 0,
    minPlayers = 2,
    maxPlayers = 20
}

-- Available maps
local availableMaps = {
    {
        name = "Metro",
        displayName = "Metro Station",
        author = "System",
        maxPlayers = 20,
        supportedModes = {"TDM", "DOM", "CTF", "KOTH"},
        spawnPoints = {
            Team1 = {
                Vector3.new(-50, 5, 0),
                Vector3.new(-45, 5, 5),
                Vector3.new(-55, 5, -5)
            },
            Team2 = {
                Vector3.new(50, 5, 0),
                Vector3.new(45, 5, 5),
                Vector3.new(55, 5, -5)
            }
        },
        objectives = {
            DOM = {
                Vector3.new(0, 5, 0),    -- A
                Vector3.new(-25, 5, 25), -- B
                Vector3.new(25, 5, -25)  -- C
            },
            CTF = {
                Team1 = Vector3.new(-50, 5, 0),
                Team2 = Vector3.new(50, 5, 0)
            },
            KOTH = Vector3.new(0, 5, 0)
        }
    },
    {
        name = "Desert",
        displayName = "Desert Storm",
        author = "System",
        maxPlayers = 16,
        supportedModes = {"TDM", "DOM", "CTF"},
        spawnPoints = {
            Team1 = {
                Vector3.new(-40, 10, 0),
                Vector3.new(-35, 10, 8),
                Vector3.new(-48, 10, -8)
            },
            Team2 = {
                Vector3.new(40, 10, 0),
                Vector3.new(35, 10, 8),
                Vector3.new(48, 10, -8)
            }
        },
        objectives = {
            DOM = {
                Vector3.new(0, 10, 0),
                Vector3.new(-20, 10, 20),
                Vector3.new(20, 10, -20)
            },
            CTF = {
                Team1 = Vector3.new(-40, 10, 0),
                Team2 = Vector3.new(40, 10, 0)
            }
        }
    }
}

-- Game modes
local gameModes = {
    TDM = {
        name = "Team Deathmatch",
        description = "First team to reach the kill limit wins",
        scoreLimit = 75,
        timeLimit = 600, -- 10 minutes
        respawnTime = 5,
        teams = 2,
        scoreOnKill = 1
    },
    DOM = {
        name = "Domination",
        description = "Control objectives to earn points",
        scoreLimit = 200,
        timeLimit = 600,
        respawnTime = 8,
        teams = 2,
        pointsPerSecond = 2,
        objectiveCount = 3
    },
    CTF = {
        name = "Capture the Flag",
        description = "Capture the enemy flag and return it to your base",
        scoreLimit = 3,
        timeLimit = 900, -- 15 minutes
        respawnTime = 10,
        teams = 2,
        flagReturnTime = 30
    },
    KOTH = {
        name = "King of the Hill",
        description = "Control the hill to earn points",
        scoreLimit = 250,
        timeLimit = 600,
        respawnTime = 8,
        teams = 2,
        pointsPerSecond = 3
    },
    FFA = {
        name = "Free For All",
        description = "Every player for themselves",
        scoreLimit = 30,
        timeLimit = 600,
        respawnTime = 3,
        teams = 0
    }
}

-- Remote events setup
local function setupRemoteEvents()
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end

    -- Game state updates
    local gameStateEvent = Instance.new("RemoteEvent")
    gameStateEvent.Name = "GameStateUpdate"
    gameStateEvent.Parent = remoteEvents

    -- Map voting
    local mapVoteEvent = Instance.new("RemoteEvent")
    mapVoteEvent.Name = "MapVote"
    mapVoteEvent.Parent = remoteEvents

    -- Mode voting
    local modeVoteEvent = Instance.new("RemoteEvent")
    modeVoteEvent.Name = "ModeVote"
    modeVoteEvent.Parent = remoteEvents

    return {
        gameState = gameStateEvent,
        mapVote = mapVoteEvent,
        modeVote = modeVoteEvent
    }
end

-- Create basic map geometry
local function createMapGeometry(mapData)
    -- Clear existing map
    local existingMap = workspace:FindFirstChild("CurrentMap")
    if existingMap then
        existingMap:Destroy()
    end

    -- Create map container
    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "CurrentMap"
    mapFolder.Parent = workspace

    if mapData.name == "Metro" then
        createMetroMap(mapFolder)
    elseif mapData.name == "Desert" then
        createDesertMap(mapFolder)
    end

    -- Create spawn points
    createSpawnPoints(mapData, mapFolder)

    -- Create objectives based on game mode
    if currentGameMode and mapData.objectives[currentGameMode.name] then
        createObjectives(mapData.objectives[currentGameMode.name], mapFolder)
    end

    print("[Map] Created map:", mapData.displayName)
end

-- Create Metro map
local function createMetroMap(parent)
    -- Platform
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Size = Vector3.new(120, 4, 60)
    platform.Position = Vector3.new(0, 2, 0)
    platform.Material = Enum.Material.Concrete
    platform.Color = Color3.fromRGB(80, 80, 80)
    platform.Anchored = true
    platform.Parent = parent

    -- Walls
    local wall1 = Instance.new("Part")
    wall1.Name = "Wall1"
    wall1.Size = Vector3.new(4, 20, 60)
    wall1.Position = Vector3.new(-62, 14, 0)
    wall1.Material = Enum.Material.Concrete
    wall1.Color = Color3.fromRGB(60, 60, 60)
    wall1.Anchored = true
    wall1.Parent = parent

    local wall2 = Instance.new("Part")
    wall2.Name = "Wall2"
    wall2.Size = Vector3.new(4, 20, 60)
    wall2.Position = Vector3.new(62, 14, 0)
    wall2.Material = Enum.Material.Concrete
    wall2.Color = Color3.fromRGB(60, 60, 60)
    wall2.Anchored = true
    wall2.Parent = parent

    -- Cover objects
    for i = 1, 6 do
        local cover = Instance.new("Part")
        cover.Name = "Cover" .. i
        cover.Size = Vector3.new(6, 8, 2)
        cover.Position = Vector3.new(
            math.random(-50, 50),
            8,
            math.random(-25, 25)
        )
        cover.Material = Enum.Material.Metal
        cover.Color = Color3.fromRGB(100, 100, 100)
        cover.Anchored = true
        cover.Parent = parent
    end

    -- Lighting
    Lighting.Ambient = Color3.fromRGB(50, 50, 70)
    Lighting.Brightness = 1.5

    print("[Map] Created Metro geometry")
end

-- Create Desert map
local function createDesertMap(parent)
    -- Sand terrain
    local sand = Instance.new("Part")
    sand.Name = "Sand"
    sand.Size = Vector3.new(100, 4, 80)
    sand.Position = Vector3.new(0, 8, 0)
    sand.Material = Enum.Material.Sand
    sand.Color = Color3.fromRGB(194, 154, 108)
    sand.Anchored = true
    sand.Parent = parent

    -- Rocks for cover
    for i = 1, 8 do
        local rock = Instance.new("Part")
        rock.Name = "Rock" .. i
        rock.Size = Vector3.new(
            math.random(4, 8),
            math.random(6, 12),
            math.random(4, 8)
        )
        rock.Position = Vector3.new(
            math.random(-40, 40),
            12,
            math.random(-30, 30)
        )
        rock.Material = Enum.Material.Rock
        rock.Color = Color3.fromRGB(120, 100, 80)
        rock.Shape = Enum.PartType.Block
        rock.Anchored = true
        rock.Parent = parent

        -- Make rocks look more natural
        rock.Rotation = Vector3.new(
            math.random(-15, 15),
            math.random(0, 360),
            math.random(-15, 15)
        )
    end

    -- Lighting for desert
    Lighting.Ambient = Color3.fromRGB(100, 90, 70)
    Lighting.Brightness = 2.5

    print("[Map] Created Desert geometry")
end

-- Create spawn points
local function createSpawnPoints(mapData, parent)
    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "SpawnPoints"
    spawnFolder.Parent = parent

    for teamName, positions in pairs(mapData.spawnPoints) do
        local teamFolder = Instance.new("Folder")
        teamFolder.Name = teamName
        teamFolder.Parent = spawnFolder

        for i, position in ipairs(positions) do
            local spawn = Instance.new("SpawnLocation")
            spawn.Name = teamName .. "_Spawn_" .. i
            spawn.Position = position
            spawn.TeamColor = teamName == "Team1" and BrickColor.new("Really blue") or BrickColor.new("Really red")
            spawn.Parent = teamFolder
        end
    end

    print("[Map] Created spawn points")
end

-- Create objectives for game modes
local function createObjectives(objectiveData, parent)
    local objectiveFolder = Instance.new("Folder")
    objectiveFolder.Name = "Objectives"
    objectiveFolder.Parent = parent

    if currentGameMode.name == "DOM" then
        -- Domination points
        for i, position in ipairs(objectiveData) do
            local objective = Instance.new("Part")
            objective.Name = "DominationPoint_" .. string.char(64 + i) -- A, B, C
            objective.Size = Vector3.new(8, 1, 8)
            objective.Position = position
            objective.Material = Enum.Material.Neon
            objective.Color = Color3.fromRGB(255, 255, 255)
            objective.Anchored = true
            objective.CanCollide = false
            objective.Shape = Enum.PartType.Cylinder
            objective.Parent = objectiveFolder

            -- Add capture zone
            local captureZone = Instance.new("Part")
            captureZone.Name = "CaptureZone"
            captureZone.Size = Vector3.new(12, 15, 12)
            captureZone.Position = position + Vector3.new(0, 7, 0)
            captureZone.Transparency = 0.8
            captureZone.CanCollide = false
            captureZone.Anchored = true
            captureZone.Parent = objective
        end

    elseif currentGameMode.name == "CTF" then
        -- Flag stands
        for teamName, position in pairs(objectiveData) do
            local flagStand = Instance.new("Part")
            flagStand.Name = teamName .. "_FlagStand"
            flagStand.Size = Vector3.new(2, 8, 2)
            flagStand.Position = position
            flagStand.Material = Enum.Material.Metal
            flagStand.Color = teamName == "Team1" and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)
            flagStand.Anchored = true
            flagStand.Parent = objectiveFolder

            -- Flag
            local flag = Instance.new("Part")
            flag.Name = teamName .. "_Flag"
            flag.Size = Vector3.new(0.2, 6, 4)
            flag.Position = position + Vector3.new(2, 3, 0)
            flag.Material = Enum.Material.Fabric
            flag.Color = teamName == "Team1" and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)
            flag.Anchored = true
            flag.Parent = flagStand
        end

    elseif currentGameMode.name == "KOTH" then
        -- Hill area
        local hill = Instance.new("Part")
        hill.Name = "Hill"
        hill.Size = Vector3.new(15, 1, 15)
        hill.Position = objectiveData
        hill.Material = Enum.Material.Neon
        hill.Color = Color3.fromRGB(255, 255, 0)
        hill.Anchored = true
        hill.CanCollide = false
        hill.Transparency = 0.5
        hill.Parent = objectiveFolder

        -- Hill control zone
        local controlZone = Instance.new("Part")
        controlZone.Name = "ControlZone"
        controlZone.Size = Vector3.new(15, 20, 15)
        controlZone.Position = objectiveData + Vector3.new(0, 10, 0)
        controlZone.Transparency = 1
        controlZone.CanCollide = false
        controlZone.Anchored = true
        controlZone.Parent = hill
    end

    print("[Map] Created objectives for", currentGameMode.name)
end

-- Initialize game mode
function MapGameModeSystem:initGameMode(modeName, mapName)
    -- Validate inputs
    local modeConfig = gameModes[modeName]
    local mapConfig = nil

    for _, map in ipairs(availableMaps) do
        if map.name == mapName then
            mapConfig = map
            break
        end
    end

    if not modeConfig then
        warn("[GameMode] Invalid game mode:", modeName)
        return false
    end

    if not mapConfig then
        warn("[GameMode] Invalid map:", mapName)
        return false
    end

    -- Check if map supports the game mode
    local modeSupported = false
    for _, supportedMode in ipairs(mapConfig.supportedModes) do
        if supportedMode == modeName then
            modeSupported = true
            break
        end
    end

    if not modeSupported then
        warn("[GameMode] Map", mapName, "does not support mode", modeName)
        return false
    end

    -- Set current configuration
    currentGameMode = modeConfig
    currentMap = mapConfig

    -- Reset game data
    gameData.scores = {Team1 = 0, Team2 = 0}
    gameData.timeRemaining = modeConfig.timeLimit
    gameData.playerCount = #Players:GetPlayers()

    -- Create map
    createMapGeometry(mapConfig)

    -- Setup teams
    self:setupTeams()

    -- Start game
    self:startGame()

    print("[GameMode] Initialized", modeConfig.name, "on", mapConfig.displayName)
    return true
end

-- Setup teams
function MapGameModeSystem:setupTeams()
    -- Clear existing teams
    for _, team in pairs(Teams:GetTeams()) do
        team:Destroy()
    end

    if currentGameMode.teams >= 2 then
        -- Team 1
        local team1 = Instance.new("Team")
        team1.Name = "Team1"
        team1.TeamColor = BrickColor.new("Really blue")
        team1.AutoAssignable = true
        team1.Parent = Teams

        -- Team 2
        local team2 = Instance.new("Team")
        team2.Name = "Team2"
        team2.TeamColor = BrickColor.new("Really red")
        team2.AutoAssignable = true
        team2.Parent = Teams

        -- Balance teams
        local players = Players:GetPlayers()
        for i, player in ipairs(players) do
            if i % 2 == 1 then
                player.Team = team1
            else
                player.Team = team2
            end
        end
    end

    print("[GameMode] Teams setup complete")
end

-- Start game
function MapGameModeSystem:startGame()
    gameState = "COUNTDOWN"

    -- Countdown
    for i = 5, 1, -1 do
        -- Broadcast countdown
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEvents and remoteEvents:FindFirstChild("GameStateUpdate") then
            remoteEvents.GameStateUpdate:FireAllClients({
                state = "COUNTDOWN",
                countdown = i,
                mode = currentGameMode.name,
                map = currentMap.displayName
            })
        end

        wait(1)
    end

    -- Start active game
    gameState = "ACTIVE"
    self:runGameLoop()
end

-- Main game loop
function MapGameModeSystem:runGameLoop()
    local lastUpdate = tick()

    while gameState == "ACTIVE" do
        local currentTime = tick()
        local deltaTime = currentTime - lastUpdate
        lastUpdate = currentTime

        -- Update timer
        gameData.timeRemaining = math.max(0, gameData.timeRemaining - deltaTime)

        -- Update game mode specific logic
        if currentGameMode.name == "DOM" then
            self:updateDomination(deltaTime)
        elseif currentGameMode.name == "KOTH" then
            self:updateKingOfTheHill(deltaTime)
        elseif currentGameMode.name == "CTF" then
            self:updateCaptureTheFlag(deltaTime)
        end

        -- Check win conditions
        if self:checkWinCondition() then
            self:endGame()
            break
        end

        -- Broadcast game state
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEvents and remoteEvents:FindFirstChild("GameStateUpdate") then
            remoteEvents.GameStateUpdate:FireAllClients({
                state = "ACTIVE",
                scores = gameData.scores,
                timeRemaining = gameData.timeRemaining,
                mode = currentGameMode.name,
                map = currentMap.displayName
            })
        end

        wait(1) -- Update every second
    end
end

-- Update domination mode
function MapGameModeSystem:updateDomination(deltaTime)
    -- This would check objective control and award points
    -- Simplified for now
    local team1Control = 0
    local team2Control = 0

    -- Check each objective (simplified)
    for i = 1, currentGameMode.objectiveCount do
        -- Random control for demo (replace with actual capture logic)
        if math.random() > 0.5 then
            team1Control = team1Control + 1
        else
            team2Control = team2Control + 1
        end
    end

    -- Award points
    gameData.scores.Team1 = gameData.scores.Team1 + (team1Control * currentGameMode.pointsPerSecond * deltaTime)
    gameData.scores.Team2 = gameData.scores.Team2 + (team2Control * currentGameMode.pointsPerSecond * deltaTime)
end

-- Update king of the hill mode
function MapGameModeSystem:updateKingOfTheHill(deltaTime)
    -- Check hill control (simplified)
    local controllingTeam = math.random() > 0.5 and "Team1" or "Team2"

    if controllingTeam then
        gameData.scores[controllingTeam] = gameData.scores[controllingTeam] + (currentGameMode.pointsPerSecond * deltaTime)
    end
end

-- Update capture the flag mode
function MapGameModeSystem:updateCaptureTheFlag(deltaTime)
    -- CTF logic would go here
    -- For now, just placeholder
end

-- Check win condition
function MapGameModeSystem:checkWinCondition()
    -- Time limit
    if gameData.timeRemaining <= 0 then
        return true
    end

    -- Score limit
    if gameData.scores.Team1 >= currentGameMode.scoreLimit or 
        gameData.scores.Team2 >= currentGameMode.scoreLimit then
        return true
    end

    return false
end

-- End game
function MapGameModeSystem:endGame()
    gameState = "ENDED"

    local winner = gameData.scores.Team1 > gameData.scores.Team2 and "Team1" or 
        gameData.scores.Team2 > gameData.scores.Team1 and "Team2" or "TIE"

    print("[GameMode] Game ended! Winner:", winner)

    -- Award XP to players
    if _G.LevelingSystem then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Team then
                if player.Team.Name == winner then
                    _G.LevelingSystem:awardXP(player, 500, "Victory")
                elseif winner ~= "TIE" then
                    _G.LevelingSystem:awardXP(player, 200, "Defeat")
                else
                    _G.LevelingSystem:awardXP(player, 300, "Draw")
                end
            end
        end
    end

    -- Broadcast end game
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEvents and remoteEvents:FindFirstChild("GameStateUpdate") then
        remoteEvents.GameStateUpdate:FireAllClients({
            state = "ENDED",
            winner = winner,
            finalScores = gameData.scores,
            mode = currentGameMode.name,
            map = currentMap.displayName
        })
    end

    -- Reset after delay
    wait(10)
    self:reset()
end

-- Reset game
function MapGameModeSystem:reset()
    gameState = "WAITING"
    currentGameMode = nil
    currentMap = nil
    gameData = {
        scores = {Team1 = 0, Team2 = 0},
        timeRemaining = 0,
        playerCount = 0,
        minPlayers = 2,
        maxPlayers = 20
    }

    -- Clear map
    local existingMap = workspace:FindFirstChild("CurrentMap")
    if existingMap then
        existingMap:Destroy()
    end

    print("[GameMode] Game reset complete")
end

-- Initialize the system
function MapGameModeSystem:init()
    print("[MapGameMode] System initializing...")

    -- Setup remote events
    local remoteEvents = setupRemoteEvents()

    -- Handle player connections
    Players.PlayerAdded:Connect(function(player)
        gameData.playerCount = #Players:GetPlayers()

        -- Auto-start game if enough players
        if gameState == "WAITING" and gameData.playerCount >= gameData.minPlayers then
            -- Start with default mode and map
            task.wait(2)
            self:initGameMode("TDM", "Metro")
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        gameData.playerCount = #Players:GetPlayers()
    end)

    print("[MapGameMode] System initialized")
end

-- Export for global access
_G.MapGameModeSystem = MapGameModeSystem

-- Auto-initialize
MapGameModeSystem:init()

return MapGameModeSystem