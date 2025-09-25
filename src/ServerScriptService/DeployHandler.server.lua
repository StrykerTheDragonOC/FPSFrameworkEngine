local DeployHandler = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local TeamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)

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
	
	self:SetupEventConnections()
	
	print("DeployHandler initialized")
end

function DeployHandler:SetupEventConnections()
	-- Handle deploy requests
	local deployPlayerEvent = RemoteEventsManager:GetEvent("DeployPlayer")
	if deployPlayerEvent then
		deployPlayerEvent.OnServerEvent:Connect(function(player)
			self:DeployPlayer(player)
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

function DeployHandler:DeployPlayer(player)
	if deployedPlayers[player] then
		warn(player.Name .. " is already deployed")
		return
	end
	
	-- Assign to team if not already assigned
	if not player.Team or player.Team.Name == "Lobby" then
		TeamManager:BalanceTeams(player)
	end
	
	-- Mark as deployed
	deployedPlayers[player] = {
		DeployTime = tick(),
		Team = player.Team and player.Team.Name or "Lobby"
	}
	
	-- Set up default loadout
	self:SetupPlayerLoadout(player)
	
	-- Spawn player at team location
	local teamSpawnSystem = _G.TeamSpawnSystem
	if teamSpawnSystem then
		teamSpawnSystem:SpawnPlayerAtTeamSpawn(player)
	end
	
	-- Give weapons
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
	
	print("Deployed " .. player.Name .. " to team " .. (player.Team and player.Team.Name or "Lobby"))
end

function DeployHandler:SetupPlayerLoadout(player)
	-- Default loadout
	playerLoadouts[player] = {
		Primary = "G36",
		Secondary = "M9",
		Melee = "PocketKnife",
		Grenade = "M67",
		Attachments = {
			G36 = {},
			M9 = {},
			PocketKnife = {},
			M67 = {}
		}
	}
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
	
	-- Clear existing tools
	for _, tool in pairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end
	
	-- Give weapons from loadout
	local weaponsToGive = {loadout.Primary, loadout.Secondary, loadout.Melee, loadout.Grenade}
	
	for _, weaponName in pairs(weaponsToGive) do
		if weaponName and WeaponConfig:IsValidWeapon(weaponName) then
			self:GivePlayerWeapon(player, weaponName)
		end
	end
	
	print("Gave loadout to " .. player.Name)
end

function DeployHandler:GivePlayerWeapon(player, weaponName)
	if not WeaponConfig:IsValidWeapon(weaponName) then
		warn("Unknown weapon: " .. weaponName)
		return false
	end
	
	local weaponTool = ServerStorage.Weapons:FindFirstChild(weaponName)
	if not weaponTool then
		warn("Weapon tool not found: " .. weaponName)
		return false
	end
	
	if player.Character then
		local clonedTool = weaponTool:Clone()
		clonedTool.Parent = player.Character
		return true
	end
	
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