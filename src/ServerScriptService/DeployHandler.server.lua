-- Deploy Handler (FIXED)
-- Manages player deployment and weapon loadouts

local DeployHandler = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local TeamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)
local WeaponPoolManager = require(ReplicatedStorage.FPSSystem.Modules.WeaponPoolManager)

local deployedPlayers = {}
local playerLoadouts = {}

function DeployHandler:Initialize()
	-- TeamManager might not have Initialize method either
	if TeamManager.Initialize then
		TeamManager:Initialize()
	end

	-- Initialize WeaponPoolManager
	if WeaponPoolManager.Initialize then
		WeaponPoolManager:Initialize()
	end

	self:SetupEventConnections()

	print("DeployHandler initialized")
end

function DeployHandler:SetupEventConnections()
	-- Handle deploy requests (PlayerDeploy event from menu)
	local playerDeployEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PlayerDeploy")
	if playerDeployEvent then
		playerDeployEvent.OnServerEvent:Connect(function(player, data)
			local teamName = nil
			if data and type(data) == "table" then
				teamName = data.Team
			end
			print("Received PlayerDeploy request from:", player.Name, "Team:", teamName or "auto-balance")
			self:DeployPlayer(player, teamName)
		end)
	else
		warn("PlayerDeploy event not found - players won't be able to deploy")
	end

	-- Also listen for legacy DeployPlayer event (if exists)
	local deployPlayerEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DeployPlayer")
	if deployPlayerEvent then
		deployPlayerEvent.OnServerEvent:Connect(function(player)
			self:DeployPlayer(player, nil)
		end)
	end

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		deployedPlayers[player] = nil
		playerLoadouts[player] = nil
	end)

	-- Handle character spawning
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			-- Only give weapons if player is deployed
			if deployedPlayers[player] then
				wait(1) -- Wait for character to load
				self:GivePlayerLoadout(player)
			end
		end)
	end)
end

function DeployHandler:DeployPlayer(player, requestedTeam)
	if deployedPlayers[player] then
		warn(player.Name .. " is already deployed")
		return
	end

	print("DeployHandler: Deploying", player.Name, "to team:", requestedTeam or "auto")

	-- Mark as deployed BEFORE team assignment
	deployedPlayers[player] = {
		DeployTime = tick(),
		Team = requestedTeam or "Auto"
	}

	-- Assign to team using TeamManager
	if requestedTeam and (requestedTeam == "KFC" or requestedTeam == "FBI") then
		-- Specific team requested
		TeamManager:AssignPlayerToTeam(player, requestedTeam)
	else
		-- Auto-balance to team
		TeamManager:BalanceTeams(player)
	end

	-- Wait a moment for team assignment to take effect
	wait(0.2)

	-- Update deployed data with actual team
	deployedPlayers[player].Team = player.Team and player.Team.Name or "Lobby"
	print("✓ Player team after assignment:", player.Team and player.Team.Name or "nil")

	-- Mark as deployed in TeamManager
	local teamData = rawget(TeamManager, "playerTeamData") or {}
	if teamData[player] then
		teamData[player].Deployed = true
	end

	-- Set up default loadout
	self:SetupPlayerLoadout(player)

	-- Wait for TeamSpawnSystem to be ready (FIXED: Complete while loop)
	local maxWait = 5
	local waited = 0
	while not _G.TeamSpawnSystem and waited < maxWait do
		wait(0.1)
		waited = waited + 0.1
	end

	if not _G.TeamSpawnSystem then
		warn("TeamSpawnSystem not available - spawning may not work correctly")
	else
		print("✓ TeamSpawnSystem ready, spawning player...")
	end

	-- Kill player if they have a character to force respawn at team spawn
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		print("Respawning", player.Name, "at team spawn for team:", player.Team and player.Team.Name or "nil")
		player.Character.Humanoid.Health = 0
	else
		-- If no character exists, load one
		print("Loading character for", player.Name, "team:", player.Team and player.Team.Name or "nil")
		player:LoadCharacter()
	end

	-- Notify client of successful deployment
	local deploymentSuccessEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DeploymentSuccessful")
	if deploymentSuccessEvent then
		deploymentSuccessEvent:FireClient(player, {
			Team = deployedPlayers[player].Team,
			Deployed = true
		})
	end

	print("✓ Successfully deployed", player.Name, "to", deployedPlayers[player].Team)
end

function DeployHandler:SetupPlayerLoadout(player)
	local playerLevel = player:GetAttribute("Level") or 0
	local unlockedWeapons = {} -- This should load from DataStore in production

	-- Get default weapon pool
	local weaponPool = WeaponConfig:GetDefaultWeaponPool()

	-- Store loadout
	playerLoadouts[player] = {
		Primary = weaponPool.Primary,
		Secondary = weaponPool.Secondary,
		Melee = weaponPool.Melee,
		Grenade = weaponPool.Grenade,
		Special = weaponPool.Special
	}

	print("Set up loadout for", player.Name, ":", playerLoadouts[player].Primary, playerLoadouts[player].Secondary)
end

function DeployHandler:GivePlayerLoadout(player)
	if not player or not player.Character then return end
	if not playerLoadouts[player] then
		self:SetupPlayerLoadout(player)
	end

	local loadout = playerLoadouts[player]
	print("Giving weapons to", player.Name, "...")

	-- In a full implementation, this would create and equip actual weapon tools
	-- For now, just log it
	print("  Primary:", loadout.Primary)
	print("  Secondary:", loadout.Secondary)
	print("  Melee:", loadout.Melee)
	print("  Grenade:", loadout.Grenade)
end

function DeployHandler:IsPlayerDeployed(player)
	return deployedPlayers[player] ~= nil
end

function DeployHandler:GetPlayerLoadout(player)
	return playerLoadouts[player]
end

-- Make globally accessible
_G.DeployHandler = DeployHandler

-- Initialize
DeployHandler:Initialize()

return DeployHandler