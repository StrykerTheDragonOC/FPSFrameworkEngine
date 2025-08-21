-- TeamManagementSystem.server.lua
-- Handles team selection, spawning, and prevents auto-team changes
-- Place in ServerScriptService

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TeamManagementSystem = {}

-- Team configuration
local TEAM_CONFIG = {
    FBI = {
        name = "FBI",
        color = Color3.fromRGB(0, 100, 255),
        spawnLocations = {}
    },
    KFC = {
        name = "KFC", 
        color = Color3.fromRGB(255, 100, 100),
        spawnLocations = {}
    }
}

-- Player team data
local playerTeams = {}
local playerSpawnData = {}

-- Initialize team system
function TeamManagementSystem.init()
    print("[TeamManagementSystem] Initializing team system...")
    
    -- Create teams
    TeamManagementSystem.createTeams()
    
    -- Setup team selection remote
    TeamManagementSystem.setupTeamSelection()
    
    -- Setup spawn management
    TeamManagementSystem.setupSpawnManagement()
    
    -- Setup player management
    TeamManagementSystem.setupPlayerManagement()
    
    print("[TeamManagementSystem] Team system initialized")
end

-- Create FBI and KFC teams
function TeamManagementSystem.createTeams()
    print("[TeamManagementSystem] Creating teams...")
    
    -- Remove existing teams (except default ones)
    for _, team in pairs(Teams:GetChildren()) do
        if team:IsA("Team") and team.Name ~= "Bright red" and team.Name ~= "Bright blue" then
            team:Destroy()
        end
    end
    
    -- Create FBI team
    local fbiTeam = Instance.new("Team")
    fbiTeam.Name = "FBI"
    fbiTeam.TeamColor = BrickColor.new("Really blue")
    fbiTeam.AutoAssignable = false
    fbiTeam.Parent = Teams
    
    -- Create KFC team
    local kfcTeam = Instance.new("Team")
    kfcTeam.Name = "KFC"
    kfcTeam.TeamColor = BrickColor.new("Really red")
    kfcTeam.AutoAssignable = false
    kfcTeam.Parent = Teams
    
    print("[TeamManagementSystem] Teams created: FBI, KFC")
end

-- Setup team selection remote event
function TeamManagementSystem.setupTeamSelection()
    -- Use centralized RemoteEvents manager
    local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.Modules.RemoteEventsManager)
    local teamRemote = RemoteEventsManager.getOrCreateRemoteEvent("TeamSelection", "Player team selection")
    
    teamRemote.OnServerEvent:Connect(function(player, teamName)
        TeamManagementSystem.assignPlayerToTeam(player, teamName)
    end)
    
    print("[TeamManagementSystem] Team selection remote setup")
end

-- Assign player to team
function TeamManagementSystem.assignPlayerToTeam(player, teamName)
    if not player or not player.Parent then return end
    
    local team = Teams:FindFirstChild(teamName)
    if not team then
        warn("[TeamManagementSystem] Team not found:", teamName)
        return
    end
    
    -- Assign to team
    player.Team = team
    playerTeams[player] = teamName
    
    print(string.format("[TeamManagementSystem] %s assigned to team %s", player.Name, teamName))
    
    -- Spawn player
    TeamManagementSystem.spawnPlayer(player)
end

-- Setup spawn management
function TeamManagementSystem.setupSpawnManagement()
    print("[TeamManagementSystem] Setting up spawn management...")
    
    -- Find spawn locations
    TeamManagementSystem.findSpawnLocations()
    
    -- Disable auto-spawn
    for _, team in pairs(Teams:GetChildren()) do
        if team:IsA("Team") then
            team.AutoAssignable = false
        end
    end
end

-- Find spawn locations for teams
function TeamManagementSystem.findSpawnLocations()
    -- Look for spawn points in workspace
    local function findSpawns(teamName)
        local spawns = {}
        
        -- Look for SpawnLocation parts
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("SpawnLocation") then
                if obj.Name:lower():find(teamName:lower()) or 
                   obj.TeamColor == Teams[teamName].TeamColor then
                    table.insert(spawns, obj)
                end
            end
        end
        
        -- If no specific spawns found, create default ones
        if #spawns == 0 then
            local defaultSpawn = workspace:FindFirstChild("SpawnLocation")
            if defaultSpawn then
                table.insert(spawns, defaultSpawn)
            end
        end
        
        TEAM_CONFIG[teamName].spawnLocations = spawns
        print(string.format("[TeamManagementSystem] Found %d spawn locations for %s", #spawns, teamName))
    end
    
    findSpawns("FBI")
    findSpawns("KFC")
end

-- Spawn player at team location
function TeamManagementSystem.spawnPlayer(player)
    if not player or not player.Parent then return end
    
    local teamName = playerTeams[player]
    if not teamName then
        warn("[TeamManagementSystem] No team assigned for player:", player.Name)
        return
    end
    
    -- Get spawn locations for team
    local spawnLocations = TEAM_CONFIG[teamName].spawnLocations
    if #spawnLocations == 0 then
        warn("[TeamManagementSystem] No spawn locations for team:", teamName)
        player:LoadCharacter() -- Default spawn
        return
    end
    
    -- Choose random spawn location
    local spawnLocation = spawnLocations[math.random(1, #spawnLocations)]
    
    -- Spawn player
    player:LoadCharacter()
    
    -- Wait for character to load and move to spawn
    player.CharacterAdded:Connect(function(character)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        task.wait(0.1) -- Brief delay to ensure character is ready
        
        -- Move to spawn location
        if spawnLocation then
            humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
        end
        
        print(string.format("[TeamManagementSystem] %s spawned for team %s", player.Name, teamName))
    end)
end

-- Setup player management
function TeamManagementSystem.setupPlayerManagement()
    print("[TeamManagementSystem] Setting up player management...")
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        TeamManagementSystem.onPlayerAdded(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        TeamManagementSystem.onPlayerAdded(player)
    end
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        TeamManagementSystem.onPlayerRemoving(player)
    end)
end

-- Handle new player joining
function TeamManagementSystem.onPlayerAdded(player)
    print("[TeamManagementSystem] Player joined:", player.Name)
    
    -- Don't auto-assign to team - wait for manual selection
    player.Team = nil
    
    -- Track player
    playerTeams[player] = nil
    playerSpawnData[player] = {
        lastSpawnTime = 0,
        spawnCount = 0
    }
    
    -- Handle character spawning
    player.CharacterAdded:Connect(function(character)
        TeamManagementSystem.onCharacterAdded(player, character)
    end)
    
    -- Handle death
    player.CharacterRemoving:Connect(function()
        TeamManagementSystem.onCharacterRemoving(player)
    end)
end

-- Handle player leaving
function TeamManagementSystem.onPlayerRemoving(player)
    print("[TeamManagementSystem] Player left:", player.Name)
    
    -- Clean up data
    playerTeams[player] = nil
    playerSpawnData[player] = nil
end

-- Handle character spawning
function TeamManagementSystem.onCharacterAdded(player, character)
    local spawnData = playerSpawnData[player]
    if spawnData then
        spawnData.spawnCount = spawnData.spawnCount + 1
        spawnData.lastSpawnTime = tick()
    end
    
    -- Set up death handling
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        -- Don't auto-respawn - let client handle return to menu
        print(string.format("[TeamManagementSystem] %s died", player.Name))
    end)
end

-- Handle character removal
function TeamManagementSystem.onCharacterRemoving(player)
    -- Player character is being removed
end

-- Get team balance
function TeamManagementSystem.getTeamBalance()
    local balance = {
        FBI = 0,
        KFC = 0
    }
    
    for _, player in pairs(Players:GetPlayers()) do
        local teamName = playerTeams[player]
        if teamName and balance[teamName] then
            balance[teamName] = balance[teamName] + 1
        end
    end
    
    return balance
end

-- Get recommended team for balance
function TeamManagementSystem.getRecommendedTeam()
    local balance = TeamManagementSystem.getTeamBalance()
    
    if balance.FBI < balance.KFC then
        return "FBI"
    elseif balance.KFC < balance.FBI then
        return "KFC"
    else
        -- Teams are balanced, randomly choose
        return math.random() > 0.5 and "FBI" or "KFC"
    end
end

-- Force assign player to team (for balancing)
function TeamManagementSystem.forceAssignTeam(player, teamName)
    if not teamName then
        teamName = TeamManagementSystem.getRecommendedTeam()
    end
    
    TeamManagementSystem.assignPlayerToTeam(player, teamName)
end

-- Initialize the system
TeamManagementSystem.init()

-- Export for other scripts
_G.TeamManagementSystem = TeamManagementSystem

return TeamManagementSystem