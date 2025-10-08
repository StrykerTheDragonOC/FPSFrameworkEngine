local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)

local TeamSpawnSystem = {}

local spawnLocations = {}
local playerRespawnTimes = {}

function TeamSpawnSystem:Initialize()
	RemoteEventsManager:Initialize()
	GameConfig:Initialize()
	
	self:LoadSpawnLocations()
	
	local getTeamSpawnsFunction = RemoteEventsManager:GetFunction("GetTeamSpawns")
	if getTeamSpawnsFunction then
		getTeamSpawnsFunction.OnServerInvoke = function(player, teamName)
			return self:GetTeamSpawnLocations(teamName)
		end
	end
	
	local playerSpawnedEvent = RemoteEventsManager:GetEvent("PlayerSpawned")
	
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:HandlePlayerSpawned(player, character)
		end)
		
		player.CharacterRemoving:Connect(function(character)
			self:HandleCharacterRemoving(player, character)
		end)
	end)
	
	print("TeamSpawnSystem initialized")
end

function TeamSpawnSystem:LoadSpawnLocations()
	spawnLocations = {
		FBI = {},
		KFC = {},
		Lobby = {}
	}
	
	local mapFolder = Workspace:FindFirstChild("Map")
	if mapFolder then
		local spawnsFolder = mapFolder:FindFirstChild("Spawns")
		if spawnsFolder then
			-- Load FBI spawns
			local fbiFolder = spawnsFolder:FindFirstChild("FBI")
			if fbiFolder then
				local fbiSpawns = spawnLocations.FBI
				if fbiSpawns then
					for _, spawn in pairs(fbiFolder:GetChildren()) do
						if spawn:IsA("SpawnLocation") then
							table.insert(fbiSpawns, spawn)
						end
					end
				end
			end
			
			-- Load KFC spawns
			local kfcFolder = spawnsFolder:FindFirstChild("KFC")
			if kfcFolder then
				local kfcSpawns = spawnLocations.KFC
				if kfcSpawns then
					for _, spawn in pairs(kfcFolder:GetChildren()) do
						if spawn:IsA("SpawnLocation") then
							table.insert(kfcSpawns, spawn)
						end
					end
				end
			end
			
			-- Load Lobby spawn
			local lobbySpawn = spawnsFolder:FindFirstChild("Lobby")
			if lobbySpawn and lobbySpawn:IsA("SpawnLocation") then
				if spawnLocations.Lobby then
					table.insert(spawnLocations.Lobby, lobbySpawn)
				end
			end
		end
	end
	
	local fbiCount = spawnLocations.FBI and #spawnLocations.FBI or 0
	local kfcCount = spawnLocations.KFC and #spawnLocations.KFC or 0
	local lobbyCount = spawnLocations.Lobby and #spawnLocations.Lobby or 0
	
	print("Loaded spawn locations - FBI: " .. fbiCount .. ", KFC: " .. kfcCount .. ", Lobby: " .. lobbyCount)
	
	if lobbyCount == 0 then
		warn("No lobby spawn found! Players need a lobby spawn location.")
	end
end


function TeamSpawnSystem:GetTeamSpawnLocations(teamName)
	local teamSpawns = spawnLocations[teamName]
	return teamSpawns or {}
end

function TeamSpawnSystem:GetRandomSpawnForTeam(teamName)
	local teamSpawns = spawnLocations[teamName]
	if not teamSpawns or type(teamSpawns) ~= "table" or #teamSpawns == 0 then
		warn("No spawn locations found for team: " .. tostring(teamName))
		return nil
	end
	
	local availableSpawns = {}
	
	for _, spawn in pairs(teamSpawns) do
		if spawn and self:IsSpawnSafe(spawn) then
			table.insert(availableSpawns, spawn)
		end
	end
	
	if #availableSpawns == 0 then
		availableSpawns = teamSpawns
	end
	
	if #availableSpawns > 0 then
		local randomIndex = math.random(1, #availableSpawns)
		return availableSpawns[randomIndex]
	end
	
	return nil
end

function TeamSpawnSystem:IsSpawnSafe(spawn)
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - spawn.Position).Magnitude
			if distance < 15 then
				return false
			end
		end
	end
	
	return true
end

function TeamSpawnSystem:SpawnPlayerAtTeamSpawn(player)
	if not player.Team then
		warn("Player " .. player.Name .. " has no team assigned")
		return false
	end
	
	local teamName = player.Team.Name
	local spawnLocation = self:GetRandomSpawnForTeam(teamName)
	
	if not spawnLocation then
		warn("Could not find spawn location for " .. player.Name .. " on team " .. teamName)
		return false
	end
	
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local spawnCFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
		player.Character.HumanoidRootPart.CFrame = spawnCFrame
		
		print("Spawned " .. player.Name .. " at " .. teamName .. " spawn")
		return true
	end
	
	return false
end

function TeamSpawnSystem:HandlePlayerSpawned(player, character)
	local respawnTime = GameConfig:GetRespawnTime() or 5
	
	if playerRespawnTimes[player] then
		local timeSinceDeath = tick() - playerRespawnTimes[player]
		if timeSinceDeath < respawnTime then
			local waitTime = respawnTime - timeSinceDeath
			wait(waitTime)
		end
	end
	
	wait(1)
	
	if not player.Team then
		local teamManager = _G.TeamManager
		if teamManager then
			teamManager:BalanceTeams(player)
		end
	end
	
	self:SpawnPlayerAtTeamSpawn(player)
	
	RemoteEventsManager:FireClient(player, "PlayerSpawned", {
		TeamName = player.Team and player.Team.Name or "None",
		SpawnTime = tick()
	})
	
	playerRespawnTimes[player] = nil
end

function TeamSpawnSystem:HandleCharacterRemoving(player, character)
	playerRespawnTimes[player] = tick()
end

function TeamSpawnSystem:ForceRespawnPlayer(player)
	if player.Character then
		player.Character:Remove()
	end
	
	player:LoadCharacter()
end

function TeamSpawnSystem:GetNearestSpawnToPosition(teamName, position)
	local teamSpawns = spawnLocations[teamName]
	if not teamSpawns or type(teamSpawns) ~= "table" or #teamSpawns == 0 then
		return nil
	end
	
	local nearestSpawn = nil
	local nearestDistance = math.huge
	
	for _, spawn in pairs(teamSpawns) do
		if spawn and spawn.Position then
			local distance = (spawn.Position - position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestSpawn = spawn
			end
		end
	end
	
	return nearestSpawn
end

function TeamSpawnSystem:GetSpawnAwayFromEnemies(teamName)
	local teamSpawns = spawnLocations[teamName]
	if not teamSpawns or type(teamSpawns) ~= "table" or #teamSpawns == 0 then
		return nil
	end
	
	local enemyTeamName = teamName == "FBI" and "KFC" or "FBI"
	local enemyPositions = {}
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == enemyTeamName and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(enemyPositions, player.Character.HumanoidRootPart.Position)
		end
	end
	
	local bestSpawn = nil
	local bestDistance = 0
	
	for _, spawn in pairs(teamSpawns) do
		if spawn and spawn.Position then
			local minDistanceToEnemy = math.huge
			
			for _, enemyPos in pairs(enemyPositions) do
				if enemyPos then
					local distance = (spawn.Position - enemyPos).Magnitude
					minDistanceToEnemy = math.min(minDistanceToEnemy, distance)
				end
			end
			
			if minDistanceToEnemy > bestDistance then
				bestDistance = minDistanceToEnemy
				bestSpawn = spawn
			end
		end
	end
	
	if bestSpawn then
		return bestSpawn
	elseif #teamSpawns > 0 then
		return teamSpawns[math.random(1, #teamSpawns)]
	else
		return nil
	end
end

-- Make globally accessible
_G.TeamSpawnSystem = TeamSpawnSystem

TeamSpawnSystem:Initialize()

return TeamSpawnSystem