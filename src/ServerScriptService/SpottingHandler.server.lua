local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local SpottingHandler = {}

local SPOT_DURATION = 15
local spottedPlayers = {} -- [targetPlayer] = {spotter, startTime, duration}
local mapPings = {}

function SpottingHandler:Initialize()
	
	-- Handle spot requests
	local spotPlayerEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SpotPlayer")
	if spotPlayerEvent then
		spotPlayerEvent.OnServerEvent:Connect(function(player, spotData)
			self:HandleSpotRequest(player, spotData)
		end)
	end
	
	-- Handle lose spot requests
	local loseSpotEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("LoseSpot")
	if loseSpotEvent then
		loseSpotEvent.OnServerEvent:Connect(function(player, spotData)
			self:HandleLoseSpot(player, spotData)
		end)
	end
	
	-- Handle map ping requests
	local mapPingEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("CreateMapPing")
	if mapPingEvent then
		mapPingEvent.OnServerEvent:Connect(function(player, pingData)
			self:HandleMapPing(player, pingData)
		end)
	end
	
	-- Update spotted players
	RunService.Heartbeat:Connect(function()
		self:UpdateSpottedPlayers()
	end)
	
	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerData(player)
	end)
	
	-- Global access for debugging
	if _G then
		_G.SpottingHandler = self
	end
	print("SpottingHandler initialized")
end

function SpottingHandler:HandleSpotRequest(spotter, spotData)
	local targetPlayer = spotData.TargetPlayer
	
	if not targetPlayer or not targetPlayer.Parent then
		return
	end
	
	-- Validate teams are different
	if spotter.Team and targetPlayer.Team and spotter.Team == targetPlayer.Team then
		return
	end
	
	-- Validate distance
	if not self:ValidateSpotDistance(spotter, targetPlayer) then
		return
	end
	
	-- Add to spotted players
	spottedPlayers[targetPlayer] = {
		Spotter = spotter,
		StartTime = tick(),
		Duration = SPOT_DURATION,
		Team = spotter.Team
	}
	
	-- Notify team members
	self:NotifyTeamOfSpot(spotter, targetPlayer, SPOT_DURATION)
	
	-- Award XP for spotting
	local dataStoreManager = _G and _G.DataStoreManager
	if dataStoreManager then
		dataStoreManager:AddXP(spotter, 25, "Enemy Spotted")
	end
	
	print(spotter.Name .. " spotted " .. targetPlayer.Name)
end

function SpottingHandler:HandleLoseSpot(requester, spotData)
	local targetPlayer = spotData.TargetPlayer
	
	if spottedPlayers[targetPlayer] then
		-- Remove spot
		spottedPlayers[targetPlayer] = nil
		
		-- Notify team members
		self:NotifyTeamOfSpotRemoval(requester, targetPlayer)
	end
end

function SpottingHandler:HandleMapPing(pinger, pingData)
	local position = pingData.Position
	local message = pingData.Message or "Ping"
	
	if not pinger.Team then return end
	
	-- Create ping data
	local pingId = tostring(tick())
	mapPings[pingId] = {
		Pinger = pinger,
		Position = position,
		Message = message,
		StartTime = tick(),
		Duration = 8,
		Team = pinger.Team
	}
	
	-- Notify team members
	local createMapPingEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("CreateMapPing")
	if createMapPingEvent then
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team == pinger.Team then
				createMapPingEvent:FireClient(player, {
					Position = position,
					Message = message,
					Pinger = pinger
				})
			end
		end
	end
	
	-- Auto-cleanup ping
	spawn(function()
		wait(8)
		mapPings[pingId] = nil
	end)
	
	print(pinger.Name .. " created map ping: " .. message)
end

function SpottingHandler:ValidateSpotDistance(spotter, target)
	if not spotter.Character or not target.Character then
		return false
	end
	
	local spotterRoot = spotter.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
	
	if not spotterRoot or not targetRoot then
		return false
	end
	
	local distance = (spotterRoot.Position - targetRoot.Position).Magnitude
	return distance <= 300 -- Max spot range
end

function SpottingHandler:NotifyTeamOfSpot(spotter, target, duration)
	if not spotter.Team then return end
	
	-- Notify all team members
	local spotPlayerEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SpotPlayer")
	if spotPlayerEvent then
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team == spotter.Team then
				spotPlayerEvent:FireClient(player, {
					Player = target,
					Spotter = spotter,
					Duration = duration
				})
			end
		end
	end
	
	-- Also award XP to team members who kill spotted enemies
	self:SetupSpotKillReward(spotter, target)
end

function SpottingHandler:NotifyTeamOfSpotRemoval(requester, target)
	if not requester.Team then return end
	
	-- Notify all team members
	local loseSpotEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("LoseSpot")
	if loseSpotEvent then
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team == requester.Team then
				loseSpotEvent:FireClient(player, {
					Player = target
				})
			end
		end
	end
end

function SpottingHandler:SetupSpotKillReward(spotter, target)
	-- Listen for this target's death while spotted
	local humanoid = target.Character and target.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	local connection
	connection = humanoid.Died:Connect(function()
		-- Check if still spotted
		if spottedPlayers[target] then
			local dataStoreManager = _G and _G.DataStoreManager
			if dataStoreManager then
				-- Award spot assist XP to spotter
				dataStoreManager:AddXP(spotter, 50, "Spot Assist")
			end
		end
		connection:Disconnect()
	end)
	
	-- Cleanup connection if spot expires
	spawn(function()
		wait(SPOT_DURATION)
		if connection then
			connection:Disconnect()
		end
	end)
end

function SpottingHandler:UpdateSpottedPlayers()
	local currentTime = tick()
	
	-- Check for expired spots
	for targetPlayer, spotData in pairs(spottedPlayers) do
		if (currentTime - spotData.StartTime >= spotData.Duration) or 
		   (not targetPlayer.Parent or not targetPlayer.Character) then
			spottedPlayers[targetPlayer] = nil
			self:NotifyTeamOfSpotRemoval(spotData.Spotter, targetPlayer)
		end
	end
end

function SpottingHandler:CleanupPlayerData(player)
	-- Remove any spots they were responsible for
	for targetPlayer, spotData in pairs(spottedPlayers) do
		if spotData.Spotter == player then
			spottedPlayers[targetPlayer] = nil
			self:NotifyTeamOfSpotRemoval(player, targetPlayer)
		end
	end
	
	-- Remove spots on this player
	if spottedPlayers[player] then
		spottedPlayers[player] = nil
	end
	
	-- Remove their map pings
	for pingId, pingData in pairs(mapPings) do
		if pingData.Pinger == player then
			mapPings[pingId] = nil
		end
	end
end

function SpottingHandler:GetSpottedPlayers()
	return spottedPlayers
end

function SpottingHandler:IsPlayerSpotted(player)
	return spottedPlayers[player] ~= nil
end

function SpottingHandler:ForceSpotPlayer(spotter, target, duration)
	-- Admin/debug function to force spot a player
	spottedPlayers[target] = {
		Spotter = spotter,
		StartTime = tick(),
		Duration = duration or SPOT_DURATION,
		Team = spotter.Team
	}
	
	self:NotifyTeamOfSpot(spotter, target, duration or SPOT_DURATION)
end

-- Console commands
if _G then
	_G.SpottingCommands = {
	forceSpot = function(spotterName, targetName, duration)
		local spotter = Players:FindFirstChild(spotterName)
		local target = Players:FindFirstChild(targetName)
		
		if spotter and target then
			SpottingHandler:ForceSpotPlayer(spotter, target, tonumber(duration) or 15)
			print("Force spotted " .. targetName .. " by " .. spotterName)
		end
	end,
	
	clearSpots = function()
		spottedPlayers = {}
		print("Cleared all spots")
	end,
	
	listSpots = function()
		print("Currently spotted players:")
		for player, data in pairs(spottedPlayers) do
			local timeLeft = math.ceil(data.Duration - (tick() - data.StartTime))
			print("- " .. player.Name .. " (spotted by " .. data.Spotter.Name .. ", " .. timeLeft .. "s left)")
		end
	end,
	
	createTestPing = function(playerName, message)
		local player = Players:FindFirstChild(playerName)
		if player and player.Character then
			local position = player.Character.HumanoidRootPart.Position + Vector3.new(10, 5, 0)
			SpottingHandler:HandleMapPing(player, {
				Position = position,
				Message = message or "Test Ping"
			})
			print("Created test ping for " .. playerName)
		end
	end
}
end

SpottingHandler:Initialize()

return SpottingHandler