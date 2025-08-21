-- TeamSpawnSystem.server.lua
-- Manages team assignment and spawning for FBI vs KFC
-- Place in ServerScriptService

-- Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Team configuration
local TEAM_CONFIG = {
    FBI = {
        name = "FBI",
        color = Color3.fromRGB(0, 100, 255),
        spawnFolder = "FBI"
    },
    KFC = {
        name = "KFC", 
        color = Color3.fromRGB(255, 50, 50),
        spawnFolder = "KFC"
    }
}

-- Team spawn system
local TeamSpawnSystem = {}
TeamSpawnSystem.teams = {}
TeamSpawnSystem.spawnLocations = {FBI = {}, KFC = {}}
TeamSpawnSystem.teamBalance = {FBI = 0, KFC = 0}

function TeamSpawnSystem.initialize()
    print("[TeamSpawnSystem] Initializing team spawn system...")
    
    -- Create teams
    TeamSpawnSystem.createTeams()
    
    -- Load spawn locations
    TeamSpawnSystem.loadSpawnLocations()
    
    -- Create remote events for client communication
    TeamSpawnSystem.createRemoteEvents()
    
    -- Setup player connections
    TeamSpawnSystem.setupPlayerConnections()
    
    print("[TeamSpawnSystem] Team spawn system initialized")
    print(string.format("[TeamSpawnSystem] Loaded %d FBI spawns, %d KFC spawns", 
        #TeamSpawnSystem.spawnLocations.FBI, #TeamSpawnSystem.spawnLocations.KFC))
end

function TeamSpawnSystem.createTeams()
    -- Remove existing teams with same names
    for _, team in pairs(Teams:GetChildren()) do
        if team.Name == "FBI" or team.Name == "KFC" then
            team:Destroy()
        end
    end
    
    -- Create FBI team
    local fbiTeam = Instance.new("Team")
    fbiTeam.Name = "FBI"
    fbiTeam.TeamColor = BrickColor.new(TEAM_CONFIG.FBI.color)
    fbiTeam.AutoAssignable = false
    fbiTeam.Parent = Teams
    
    -- Create KFC team
    local kfcTeam = Instance.new("Team")
    kfcTeam.Name = "KFC"
    kfcTeam.TeamColor = BrickColor.new(TEAM_CONFIG.KFC.color)
    kfcTeam.AutoAssignable = false
    kfcTeam.Parent = Teams
    
    -- Wait for teams to be properly parented before storing references
    wait()
    
    TeamSpawnSystem.teams.FBI = fbiTeam
    TeamSpawnSystem.teams.KFC = kfcTeam
    
    print("[TeamSpawnSystem] Teams created: FBI and KFC")
end

function TeamSpawnSystem.createRemoteEvents()
    -- Ensure FPSSystem folder exists
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        fpsSystem = Instance.new("Folder")
        fpsSystem.Name = "FPSSystem"
        fpsSystem.Parent = ReplicatedStorage
    end
    
    -- Ensure RemoteEvents folder exists
    local remoteEventsFolder = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = fpsSystem
    end
    
    -- Use centralized RemoteEvents manager
    local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.Modules.RemoteEventsManager)
    
    -- Create PreventAutoSpawn remote event
    local preventAutoSpawnEvent = RemoteEventsManager.getOrCreateRemoteEvent("PreventAutoSpawn", "Prevent automatic player spawning")
    
    -- Handle the remote event
    preventAutoSpawnEvent.OnServerEvent:Connect(function(player)
        TeamSpawnSystem.preventPlayerAutoSpawn(player)
    end)
    
    -- Create ManualSpawn remote event
    local manualSpawnEvent = RemoteEventsManager.getOrCreateRemoteEvent("ManualSpawn", "Manual player spawning")
        
        -- Handle manual spawn requests
        manualSpawnEvent.OnServerEvent:Connect(function(player)
            TeamSpawnSystem.manualSpawnPlayer(player)
        end)
    
    print("[TeamSpawnSystem] Remote events created")
end

function TeamSpawnSystem.preventPlayerAutoSpawn(player)
    -- Alternative approach: destroy character and track manual spawn requests
    if player.Character then
        player.Character:Destroy()
    end
    
    -- Store player as requiring manual spawn
    if not TeamSpawnSystem.manualSpawnPlayers then
        TeamSpawnSystem.manualSpawnPlayers = {}
    end
    TeamSpawnSystem.manualSpawnPlayers[player.UserId] = true
    
    print("[TeamSpawnSystem] Manual spawn mode enabled for player:", player.Name)
end

function TeamSpawnSystem.manualSpawnPlayer(player)
    -- Always allow manual spawn (remove the check that was causing issues)
    print("[TeamSpawnSystem] Manual spawn requested for player:", player.Name)
    
    -- Remove from manual spawn mode if they were in it
    if TeamSpawnSystem.manualSpawnPlayers then
        TeamSpawnSystem.manualSpawnPlayers[player.UserId] = nil
    end
    
    -- Spawn the player
    player:LoadCharacter()
    
    print("[TeamSpawnSystem] Manual spawn completed for player:", player.Name)
end

function TeamSpawnSystem.loadSpawnLocations()
    -- Find spawn locations in workspace
    local spawnsFolder = Workspace:FindFirstChild("Map")
    if spawnsFolder then
        spawnsFolder = spawnsFolder:FindFirstChild("Spawns")
    end
    
    if not spawnsFolder then
        warn("[TeamSpawnSystem] Spawns folder not found in Workspace.Map.Spawns")
        return
    end
    
    -- Load FBI spawns
    local fbiFolder = spawnsFolder:FindFirstChild("FBI")
    if fbiFolder then
        for _, spawn in pairs(fbiFolder:GetChildren()) do
            if spawn:IsA("SpawnLocation") or spawn:IsA("Part") then
                table.insert(TeamSpawnSystem.spawnLocations.FBI, spawn)
            end
        end
    else
        warn("[TeamSpawnSystem] FBI spawn folder not found")
    end
    
    -- Load KFC spawns
    local kfcFolder = spawnsFolder:FindFirstChild("KFC")
    if kfcFolder then
        for _, spawn in pairs(kfcFolder:GetChildren()) do
            if spawn:IsA("SpawnLocation") or spawn:IsA("Part") then
                table.insert(TeamSpawnSystem.spawnLocations.KFC, spawn)
            end
        end
    else
        warn("[TeamSpawnSystem] KFC spawn folder not found")
    end
    
    -- Ensure we have spawn locations
    if #TeamSpawnSystem.spawnLocations.FBI == 0 then
        warn("[TeamSpawnSystem] No FBI spawn locations found!")
        TeamSpawnSystem.createDefaultSpawns("FBI", Vector3.new(0, 10, 0))
    end
    
    if #TeamSpawnSystem.spawnLocations.KFC == 0 then
        warn("[TeamSpawnSystem] No KFC spawn locations found!")
        TeamSpawnSystem.createDefaultSpawns("KFC", Vector3.new(50, 10, 0))
    end
end

function TeamSpawnSystem.createDefaultSpawns(teamName, basePosition)
    print(string.format("[TeamSpawnSystem] Creating default spawns for %s at %s", teamName, tostring(basePosition)))
    
    for i = 1, 8 do
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = teamName .. "Spawn" .. i
        spawn.Size = Vector3.new(4, 1, 4)
        spawn.Position = basePosition + Vector3.new((i-1) * 6, 0, 0)
        spawn.BrickColor = BrickColor.new(TEAM_CONFIG[teamName].color)
        spawn.Material = Enum.Material.Neon
        spawn.Anchored = true
        spawn.CanCollide = false
        spawn.TeamColor = TeamSpawnSystem.teams[teamName].TeamColor
        spawn.Parent = Workspace
        
        table.insert(TeamSpawnSystem.spawnLocations[teamName], spawn)
    end
end

function TeamSpawnSystem.setupPlayerConnections()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        TeamSpawnSystem.onPlayerAdded(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        TeamSpawnSystem.onPlayerAdded(player)
    end
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        TeamSpawnSystem.onPlayerLeaving(player)
    end)
end

function TeamSpawnSystem.onPlayerAdded(player)
    print("[TeamSpawnSystem] Player joined:", player.Name)
    
    -- Assign team on spawn
    player.CharacterAdded:Connect(function(character)
        -- Check if player is in manual spawn mode
        if TeamSpawnSystem.manualSpawnPlayers and TeamSpawnSystem.manualSpawnPlayers[player.UserId] then
            print("[TeamSpawnSystem] Player in manual spawn mode, skipping auto-spawn:", player.Name)
            return
        end
        
        -- Small delay to ensure character is fully loaded
        task.wait(0.1)
        TeamSpawnSystem.assignPlayerTeam(player)
        TeamSpawnSystem.spawnPlayerOnTeam(player, character)
    end)
    
    -- Handle respawning
    player.CharacterRemoving:Connect(function(character)
        -- Handle any cleanup needed
    end)
end

function TeamSpawnSystem.onPlayerLeaving(player)
    -- Update team balance
    if player.Team then
        local teamName = player.Team.Name
        if TeamSpawnSystem.teamBalance[teamName] then
            TeamSpawnSystem.teamBalance[teamName] = math.max(0, TeamSpawnSystem.teamBalance[teamName] - 1)
        end
    end
    
    print(string.format("[TeamSpawnSystem] Player left: %s | FBI: %d, KFC: %d", 
        player.Name, TeamSpawnSystem.teamBalance.FBI, TeamSpawnSystem.teamBalance.KFC))
end

function TeamSpawnSystem.assignPlayerTeam(player)
    -- Assign to team with fewer players for balance
    local targetTeam
    
    if TeamSpawnSystem.teamBalance.FBI <= TeamSpawnSystem.teamBalance.KFC then
        targetTeam = "FBI"
    else
        targetTeam = "KFC"
    end
    
    -- Update old team balance
    if player.Team then
        local oldTeamName = player.Team.Name
        if TeamSpawnSystem.teamBalance[oldTeamName] then
            TeamSpawnSystem.teamBalance[oldTeamName] = math.max(0, TeamSpawnSystem.teamBalance[oldTeamName] - 1)
        end
    end
    
    -- Assign new team (with safety check)
    if TeamSpawnSystem.teams[targetTeam] and TeamSpawnSystem.teams[targetTeam].Parent == Teams then
        player.Team = TeamSpawnSystem.teams[targetTeam]
        TeamSpawnSystem.teamBalance[targetTeam] = TeamSpawnSystem.teamBalance[targetTeam] + 1
    else
        warn("[TeamSpawnSystem] Team not found or not properly parented:", targetTeam)
        -- Try to recreate teams if they're missing
        TeamSpawnSystem.createTeams()
        if TeamSpawnSystem.teams[targetTeam] then
            player.Team = TeamSpawnSystem.teams[targetTeam]
            TeamSpawnSystem.teamBalance[targetTeam] = TeamSpawnSystem.teamBalance[targetTeam] + 1
        end
    end
    
    print(string.format("[TeamSpawnSystem] %s assigned to %s | FBI: %d, KFC: %d", 
        player.Name, targetTeam, TeamSpawnSystem.teamBalance.FBI, TeamSpawnSystem.teamBalance.KFC))
end

function TeamSpawnSystem.spawnPlayerOnTeam(player, character)
    if not player.Team then
        warn("[TeamSpawnSystem] Player has no team assigned:", player.Name)
        return
    end
    
    local teamName = player.Team.Name
    local spawnLocations = TeamSpawnSystem.spawnLocations[teamName]
    
    if not spawnLocations or #spawnLocations == 0 then
        warn("[TeamSpawnSystem] No spawn locations for team:", teamName)
        return
    end
    
    -- Choose random spawn location
    local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
    
    -- Teleport player to spawn
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart and randomSpawn then
        local spawnPosition = randomSpawn.Position + Vector3.new(0, 5, 0)
        humanoidRootPart.CFrame = CFrame.new(spawnPosition)
        
        print(string.format("[TeamSpawnSystem] Spawned %s (%s) at %s", 
            player.Name, teamName, tostring(spawnPosition)))
    end
end

function TeamSpawnSystem.forceRespawn(player)
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end
end

function TeamSpawnSystem.switchPlayerTeam(player, newTeamName)
    if not TeamSpawnSystem.teams[newTeamName] then
        warn("[TeamSpawnSystem] Invalid team name:", newTeamName)
        return false
    end
    
    -- Update team balance
    if player.Team then
        local oldTeamName = player.Team.Name
        if TeamSpawnSystem.teamBalance[oldTeamName] then
            TeamSpawnSystem.teamBalance[oldTeamName] = math.max(0, TeamSpawnSystem.teamBalance[oldTeamName] - 1)
        end
    end
    
    -- Switch team
    player.Team = TeamSpawnSystem.teams[newTeamName]
    TeamSpawnSystem.teamBalance[newTeamName] = TeamSpawnSystem.teamBalance[newTeamName] + 1
    
    -- Force respawn
    TeamSpawnSystem.forceRespawn(player)
    
    print(string.format("[TeamSpawnSystem] %s switched to %s | FBI: %d, KFC: %d", 
        player.Name, newTeamName, TeamSpawnSystem.teamBalance.FBI, TeamSpawnSystem.teamBalance.KFC))
    
    return true
end

function TeamSpawnSystem.getTeamBalance()
    return {
        FBI = TeamSpawnSystem.teamBalance.FBI,
        KFC = TeamSpawnSystem.teamBalance.KFC
    }
end

function TeamSpawnSystem.balanceTeams()
    local players = Players:GetPlayers()
    local halfSize = math.ceil(#players / 2)
    
    -- Reset team balance
    TeamSpawnSystem.teamBalance.FBI = 0
    TeamSpawnSystem.teamBalance.KFC = 0
    
    -- Shuffle players
    for i = #players, 2, -1 do
        local j = math.random(i)
        players[i], players[j] = players[j], players[i]
    end
    
    -- Assign teams
    for i, player in pairs(players) do
        local targetTeam = (i <= halfSize) and "FBI" or "KFC"
        player.Team = TeamSpawnSystem.teams[targetTeam]
        TeamSpawnSystem.teamBalance[targetTeam] = TeamSpawnSystem.teamBalance[targetTeam] + 1
        
        -- Force respawn
        TeamSpawnSystem.forceRespawn(player)
    end
    
    print(string.format("[TeamSpawnSystem] Teams balanced | FBI: %d, KFC: %d", 
        TeamSpawnSystem.teamBalance.FBI, TeamSpawnSystem.teamBalance.KFC))
end

-- Admin commands
function TeamSpawnSystem.handleAdminCommand(player, command, args)
    if not (player:GetRankInGroup(0) >= 100) then -- Adjust group/rank as needed
        return false, "Insufficient permissions"
    end
    
    if command == "balance" then
        TeamSpawnSystem.balanceTeams()
        return true, "Teams balanced"
        
    elseif command == "switch" and args[1] and args[2] then
        local targetPlayer = Players:FindFirstChild(args[1])
        local targetTeam = args[2]:upper()
        
        if not targetPlayer then
            return false, "Player not found: " .. args[1]
        end
        
        if not (targetTeam == "FBI" or targetTeam == "KFC") then
            return false, "Invalid team: " .. targetTeam
        end
        
        TeamSpawnSystem.switchPlayerTeam(targetPlayer, targetTeam)
        return true, string.format("Switched %s to %s", targetPlayer.Name, targetTeam)
        
    elseif command == "status" then
        local balance = TeamSpawnSystem.getTeamBalance()
        return true, string.format("FBI: %d players, KFC: %d players", balance.FBI, balance.KFC)
    end
    
    return false, "Unknown command"
end

-- Initialize the system
TeamSpawnSystem.initialize()

-- Global access for other scripts
_G.TeamSpawnSystem = TeamSpawnSystem

return TeamSpawnSystem