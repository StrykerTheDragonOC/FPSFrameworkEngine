local SpottingSystem = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local SPOT_RANGE = 300 -- Maximum spotting range
local SPOT_DURATION = 15 -- How long spots last
local SPOT_COOLDOWN = 1 -- Cooldown between spots
local PING_COOLDOWN = 2 -- Cooldown for map pings

local lastSpotTime = 0
local lastPingTime = 0
local spottedPlayers = {}
local mapPings = {}

function SpottingSystem:Initialize()
	self:SetupInputHandling()
	self:SetupSpottingUI()

	-- Listen for spot events from server
	local playerSpottedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PlayerSpotted")
	if playerSpottedEvent then
		playerSpottedEvent.OnClientEvent:Connect(function(spotData)
			self:HandlePlayerSpotted(spotData)
		end)
	end

	local spotRemovedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SpotRemoved")
	if spotRemovedEvent then
		spotRemovedEvent.OnClientEvent:Connect(function(spotData)
			self:HandleSpotRemoved(spotData)
		end)
	end

	local mapPingEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("MapPing")
	if mapPingEvent then
		mapPingEvent.OnClientEvent:Connect(function(pingData)
			self:HandleMapPing(pingData)
		end)
	end
	
	-- Update spotted indicators
	RunService.Heartbeat:Connect(function()
		self:UpdateSpotIndicators()
	end)
	
	print("SpottingSystem initialized")
end

function SpottingSystem:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Q then
			self:HandleQKeyPress()
		end
	end)
end

function SpottingSystem:SetupSpottingUI()
	-- Create UI for spotted player indicators
	local playerGui = player:WaitForChild("PlayerGui")
	
	local spottingGui = Instance.new("ScreenGui")
	spottingGui.Name = "SpottingGUI"
	spottingGui.ResetOnSpawn = false
	spottingGui.Parent = playerGui
	
	-- Container for spot indicators
	local spotContainer = Instance.new("Folder")
	spotContainer.Name = "SpotIndicators"
	spotContainer.Parent = spottingGui
end

function SpottingSystem:HandleQKeyPress()
	local currentTime = tick()
	
	-- Check cooldown
	if currentTime - lastSpotTime < SPOT_COOLDOWN then
		return
	end
	
	-- Try to spot player first, then ping if no player found
	local spottedPlayer = self:TrySpotPlayer()
	if spottedPlayer then
		lastSpotTime = currentTime
		self:PlaySpotSound()
	elseif currentTime - lastPingTime >= PING_COOLDOWN then
		-- No player spotted, create map ping
		self:CreateMapPing()
		lastPingTime = currentTime
	end
end

function SpottingSystem:TrySpotPlayer()
	local character = player.Character
	if not character then return nil end
	
	local head = character:FindFirstChild("Head")
	if not head then return nil end
	
	-- Raycast from camera to mouse position
	local mouse = player:GetMouse()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}
	
	local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * SPOT_RANGE, raycastParams)
	
	if rayResult then
		local hitPart = rayResult.Instance
		local hitCharacter = hitPart.Parent
		
		-- Check if hit a player
		if hitCharacter:FindFirstChild("Humanoid") then
			local targetPlayer = Players:GetPlayerFromCharacter(hitCharacter)
			
			if targetPlayer and targetPlayer ~= player then
				-- Check if player is enemy (different team)
				if self:IsEnemyPlayer(targetPlayer) then
					-- Check line of sight
					if self:HasLineOfSight(head.Position, hitCharacter.HumanoidRootPart.Position) then
						-- Send spot to server
						local spotPlayerEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SpotPlayer")
						if spotPlayerEvent then
							spotPlayerEvent:FireServer({
								TargetPlayer = targetPlayer,
								Position = rayResult.Position
							})
						end
						return targetPlayer
					end
				end
			end
		end
	end
	
	return nil
end

function SpottingSystem:IsEnemyPlayer(targetPlayer)
	-- Check if target is on different team
	local myTeam = player.Team
	local targetTeam = targetPlayer.Team
	
	if not myTeam or not targetTeam then return true end
	
	return myTeam ~= targetTeam
end

function SpottingSystem:HasLineOfSight(fromPosition, toPosition)
	local direction = (toPosition - fromPosition).Unit
	local distance = (toPosition - fromPosition).Magnitude
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local rayResult = Workspace:Raycast(fromPosition, direction * distance, raycastParams)
	
	-- If ray hits target player, we have line of sight
	if rayResult then
		local hitCharacter = rayResult.Instance.Parent
		return hitCharacter and hitCharacter:FindFirstChild("Humanoid") and Players:GetPlayerFromCharacter(hitCharacter)
	end
	
	return false
end

function SpottingSystem:CreateMapPing()
	local mouse = player:GetMouse()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)


	if rayResult then
		-- Send ping to server
		local createMapPingEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("CreateMapPing")
		if createMapPingEvent then
			createMapPingEvent:FireServer({
				Position = rayResult.Position,
				Message = "Spotted Here"
			})
		end
	end
end

function SpottingSystem:HandlePlayerSpotted(spotData)
	local targetPlayer = spotData.Player
	local spotter = spotData.Spotter
	local duration = spotData.Duration or SPOT_DURATION
	
	-- Only show spots from teammates
	if spotter.Team == player.Team or spotter == player then
		self:CreateSpotIndicator(targetPlayer, duration)
		
		-- Add to spotted players list
		spottedPlayers[targetPlayer] = {
			StartTime = tick(),
			Duration = duration,
			Spotter = spotter
		}
	end
end

function SpottingSystem:HandleSpotRemoved(spotData)
	local targetPlayer = spotData.Player
	
	-- Remove from spotted list
	spottedPlayers[targetPlayer] = nil
	
	-- Remove visual indicator
	self:RemoveSpotIndicator(targetPlayer)
end

function SpottingSystem:CreateSpotIndicator(targetPlayer, duration)
	if not targetPlayer.Character then return end
	
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end
	
	-- Create 3D spot indicator
	local indicator = Instance.new("BillboardGui")
	indicator.Name = "SpotIndicator_" .. targetPlayer.Name
	indicator.Size = UDim2.new(0, 60, 0, 60)
	indicator.StudsOffset = Vector3.new(0, 4, 0)
	indicator.Parent = targetRoot
	
	-- Red diamond shape
	local diamond = Instance.new("Frame")
	diamond.Size = UDim2.new(1, 0, 1, 0)
	diamond.BackgroundColor3 = Color3.new(1, 0, 0)
	diamond.BorderSizePixel = 2
	diamond.BorderColor3 = Color3.new(1, 1, 1)
	diamond.Rotation = 45
	diamond.Parent = indicator
	
	-- Pulsing animation
	local pulseAnimation = TweenService:Create(diamond, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Size = UDim2.new(1.2, 0, 1.2, 0)
	})
	pulseAnimation:Play()
	
	-- Player name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(2, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(-0.5, 0, 1, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = targetPlayer.Name
	nameLabel.TextColor3 = Color3.new(1, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Parent = indicator
	
	-- Distance indicator
	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Size = UDim2.new(2, 0, 0.3, 0)
	distanceLabel.Position = UDim2.new(-0.5, 0, 1.5, 5)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Text = "0m"
	distanceLabel.TextColor3 = Color3.new(1, 1, 1)
	distanceLabel.TextScaled = true
	distanceLabel.Font = Enum.Font.SourceSans
	distanceLabel.TextStrokeTransparency = 0
	distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	distanceLabel.Parent = indicator
	
	-- Auto-remove after duration
	spawn(function()
		wait(duration)
		if indicator.Parent then
			pulseAnimation:Cancel()
			indicator:Destroy()
		end
		spottedPlayers[targetPlayer] = nil
	end)
end

function SpottingSystem:RemoveSpotIndicator(targetPlayer)
	if not targetPlayer.Character then return end
	
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end
	
	local indicator = targetRoot:FindFirstChild("SpotIndicator_" .. targetPlayer.Name)
	if indicator then
		indicator:Destroy()
	end
end

function SpottingSystem:UpdateSpotIndicators()
	local myCharacter = player.Character
	if not myCharacter or not myCharacter:FindFirstChild("HumanoidRootPart") then return end
	
	local myPosition = myCharacter.HumanoidRootPart.Position
	
	-- Update distance labels and check for removal conditions
	for targetPlayer, spotData in pairs(spottedPlayers) do
		if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
			local distance = math.floor((myPosition - targetPosition).Magnitude)
			
			-- Update distance label
			local indicator = targetPlayer.Character.HumanoidRootPart:FindFirstChild("SpotIndicator_" .. targetPlayer.Name)
			if indicator then
				local distanceLabel = indicator:FindFirstChild("TextLabel")
				if distanceLabel and distanceLabel.Name ~= "TextLabel" then -- Find the distance label specifically
					for _, child in pairs(indicator:GetChildren()) do
						if child:IsA("TextLabel") and child.Text:find("m") then
							child.Text = distance .. "m"
							break
						end
					end
				end
				
				-- Check if player should lose spot (in cover)
				if not self:HasLineOfSight(myPosition, targetPosition) then
					-- Start cover timer
					if not spotData.CoverStartTime then
						spotData.CoverStartTime = tick()
					elseif tick() - spotData.CoverStartTime > 3 then
						-- Lost spot after 3 seconds in cover
						local loseSpotEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("LoseSpot")
						if loseSpotEvent then
							loseSpotEvent:FireServer({
								TargetPlayer = targetPlayer
							})
						end
					end
				else
					-- Reset cover timer
					spotData.CoverStartTime = nil
				end
			end
		end
	end
end

function SpottingSystem:HandleMapPing(pingData)
	local position = pingData.Position
	local message = pingData.Message
	local pinger = pingData.Pinger
	
	-- Only show pings from teammates
	if pinger.Team ~= player.Team and pinger ~= player then
		return
	end
	
	-- Create world ping indicator
	local pingPart = Instance.new("Part")
	pingPart.Name = "MapPing"
	pingPart.Size = Vector3.new(0.1, 0.1, 0.1)
	pingPart.Transparency = 1
	pingPart.CanCollide = false
	pingPart.Anchored = true
	pingPart.Position = position
	pingPart.Parent = Workspace
	
	local pingGui = Instance.new("BillboardGui")
	pingGui.Size = UDim2.new(0, 100, 0, 50)
	pingGui.StudsOffset = Vector3.new(0, 5, 0)
	pingGui.Parent = pingPart
	
	-- Ping icon
	local pingIcon = Instance.new("Frame")
	pingIcon.Size = UDim2.new(0, 40, 0, 40)
	pingIcon.Position = UDim2.new(0.5, -20, 0, 0)
	pingIcon.BackgroundColor3 = Color3.new(1, 1, 0)
	pingIcon.BorderSizePixel = 2
	pingIcon.BorderColor3 = Color3.new(0, 0, 0)
	pingIcon.Rotation = 45
	pingIcon.Parent = pingGui
	
	-- Ping message
	local pingLabel = Instance.new("TextLabel")
	pingLabel.Size = UDim2.new(2, 0, 0, 20)
	pingLabel.Position = UDim2.new(-0.5, 0, 1, 5)
	pingLabel.BackgroundTransparency = 1
	pingLabel.Text = message
	pingLabel.TextColor3 = Color3.new(1, 1, 0)
	pingLabel.TextScaled = true
	pingLabel.Font = Enum.Font.SourceSansBold
	pingLabel.TextStrokeTransparency = 0
	pingLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	pingLabel.Parent = pingGui
	
	-- Animate and remove
	local pulseAnimation = TweenService:Create(pingIcon, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0.5, -25, 0, 0)
	})
	pulseAnimation:Play()
	
	spawn(function()
		wait(8) -- Ping lasts 8 seconds
		pulseAnimation:Cancel()
		pingPart:Destroy()
	end)
end

function SpottingSystem:PlaySpotSound()
	local character = player.Character
	if not character then return end
	
	local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://18865989002" -- Spot sound ID
	sound.Volume = 0.7
	sound.Parent = character:FindFirstChild("Head") or character
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function SpottingSystem:GetSpottedPlayers()
	return spottedPlayers
end

function SpottingSystem:IsPlayerSpotted(targetPlayer)
	return spottedPlayers[targetPlayer] ~= nil
end

return SpottingSystem