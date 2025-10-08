local DeployHandler = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local TeamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)
local WeaponPoolManager = require(ReplicatedStorage.FPSSystem.Modules.WeaponPoolManager)

local deployedPlayers = {}
local playerLoadouts = {}

function DeployHandler:Initialize()
	-- Initialize RemoteEventsManager if it has Initialize method
	if RemoteEventsManager.Initialize then
		RemoteEventsManager:Initialize()
	end

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
	local playerDeployEvent = RemoteEventsManager:GetEvent("PlayerDeploy")
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
	local deployPlayerEvent = RemoteEventsManager:GetEvent("DeployPlayer")
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

	-- Update deployed data with actual team
	deployedPlayers[player].Team = player.Team and player.Team.Name or "Lobby"

	-- Mark as deployed in TeamManager
	local teamData = rawget(TeamManager, "playerTeamData") or {}
	if teamData[player] then
		teamData[player].Deployed = true
	end

	-- Set up default loadout
	self:SetupPlayerLoadout(player)

	-- Wait a moment for character to exist
	if not player.Character then
		player.CharacterAdded:Wait()
		wait(0.5) -- Extra wait for character to fully load
	end

	-- Wait for TeamSpawnSystem to be ready
	local maxWait = 5
	local waited = 0
	while not _G.TeamSpawnSystem and waited < maxWait do
		wait(0.1)
		waited = waited + 0.1
	end

	-- Spawn player at team location
	local teamSpawnSystem = _G.TeamSpawnSystem
	if teamSpawnSystem then
		wait(0.2) -- Small delay to ensure team is fully assigned
		teamSpawnSystem:SpawnPlayerAtTeamSpawn(player)
		print("✓ Spawned", player.Name, "at", player.Team.Name, "spawn")
	else
		warn("TeamSpawnSystem not found - player may spawn at wrong location")
	end

	-- Wait a moment then give weapons
	wait(0.5)
	self:GivePlayerLoadout(player)

	-- Notify player
	RemoteEventsManager:FireClient(player, "PlayerDeployed", {
		Player = player.Name,
		Team = player.Team and player.Team.Name or "Lobby",
		DeployTime = tick()
	})

	-- Notify all players
	RemoteEventsManager:FireAllClients("PlayerJoinedBattle", {
		Player = player.Name,
		Team = player.Team and player.Team.Name or "Lobby"
	})

	print("✓ Deployed " .. player.Name .. " to team " .. (player.Team and player.Team.Name or "Lobby"))
end

function DeployHandler:SetupPlayerLoadout(player)
	-- Get random loadout from weapon pool
	local randomLoadout = WeaponPoolManager:GetRandomLoadout(player)

	-- Store loadout with attachments
	playerLoadouts[player] = {
		Primary = randomLoadout.Primary,
		Secondary = randomLoadout.Secondary,
		Melee = randomLoadout.Melee,
		Grenade = randomLoadout.Grenade,
		Special = randomLoadout.Special,
		Attachments = {}
	}

	print("DeployHandler: Setup loadout for", player.Name)
end

function DeployHandler:GivePlayerLoadout(player)
	if not deployedPlayers[player] or not player.Character then
		return
	end

	local loadout = playerLoadouts[player]
	if not loadout then
		self:SetupPlayerLoadout(player)
		loadout = playerLoadouts[player]
	end

	-- Clear existing tools in backpack and character
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	for _, tool in pairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	-- Give weapons from loadout (filter out nil values)
	local weaponsToGive = {}
	if loadout.Primary then table.insert(weaponsToGive, loadout.Primary) end
	if loadout.Secondary then table.insert(weaponsToGive, loadout.Secondary) end
	if loadout.Melee then table.insert(weaponsToGive, loadout.Melee) end
	if loadout.Grenade then table.insert(weaponsToGive, loadout.Grenade) end
	if loadout.Special then table.insert(weaponsToGive, loadout.Special) end

	local givenCount = 0
	for _, weaponName in pairs(weaponsToGive) do
		local success = self:GivePlayerWeapon(player, weaponName)
		if success then
			givenCount = givenCount + 1
		end
	end

	print("✓ Gave loadout to " .. player.Name .. " (" .. givenCount .. " weapons)")
end

function DeployHandler:GivePlayerWeapon(player, weaponName)
	if not player.Character then
		warn("Player has no character")
		return false
	end

	-- Try to get the weapon deployment handler
	local weaponDeploymentHandler = _G.WeaponDeploymentHandler
	if weaponDeploymentHandler and weaponDeploymentHandler.CreateWeaponTool then
		-- Determine weapon type
		local weaponType = "primary"
		if weaponName:match("M9") or weaponName:match("Glock") or weaponName:match("Desert Eagle") then
			weaponType = "secondary"
		elseif weaponName:match("Knife") or weaponName:match("Axe") or weaponName:match("Hammer") then
			weaponType = "melee"
		elseif weaponName:match("M67") or weaponName:match("M26") or weaponName:match("C4") then
			weaponType = "grenade"
		end

		local tool = weaponDeploymentHandler:CreateWeaponTool(weaponName, weaponType)
		if tool then
			tool.Parent = player.Backpack
			print("Gave weapon to", player.Name, ":", weaponName)
			return true
		end
	end

	-- Fallback: try direct clone from ServerStorage
	local function findWeaponRecursive(parent, name)
		local weapon = parent:FindFirstChild(name)
		if weapon then return weapon end

		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("Folder") then
				weapon = findWeaponRecursive(child, name)
				if weapon then return weapon end
			end
		end
		return nil
	end

	local weaponTool = findWeaponRecursive(ServerStorage.Weapons, weaponName)
	if weaponTool and weaponTool:IsA("Tool") then
		local clonedTool = weaponTool:Clone()
		clonedTool.Parent = player.Backpack
		print("Gave weapon (fallback) to", player.Name, ":", weaponName)
		return true
	end

	warn("Could not give weapon:", weaponName, "to", player.Name)
	return false
end

function DeployHandler:IsPlayerDeployed(player)
	return deployedPlayers[player] ~= nil
end

function DeployHandler:GetPlayerLoadout(player)
	return playerLoadouts[player]
end

function DeployHandler:SetPlayerLoadout(player, loadout)
	if not deployedPlayers[player] then
		warn("Player " .. player.Name .. " is not deployed")
		return false
	end
	
	playerLoadouts[player] = loadout
	
	-- If player has character, update weapons immediately
	if player.Character then
		self:GivePlayerLoadout(player)
	end
	
	return true
end

function DeployHandler:UndeployPlayer(player)
	deployedPlayers[player] = nil
	playerLoadouts[player] = nil
	
	-- Clear weapons
	if player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end
	end
	
	print("Undeployed " .. player.Name)
end

function DeployHandler:GetDeployedPlayers()
	local deployed = {}
	for player, data in pairs(deployedPlayers) do
		table.insert(deployed, {
			Player = player,
			Data = data
		})
	end
	return deployed
end

-- Global access
_G.DeployHandler = DeployHandler

DeployHandler:Initialize()

return DeployHandler