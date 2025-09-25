local VehicleController = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Initialize RemoteEvents
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
RemoteEventsManager:Initialize()

-- Vehicle state
local currentVehicle = nil
local currentSeat = nil
local vehicleConnections = {}
local movementConnection = nil

-- Vehicle movement settings
local TANK_SETTINGS = {
	MaxSpeed = 50,
	TurnSpeed = 30,
	Acceleration = 5
}

local HELICOPTER_SETTINGS = {
	MaxSpeed = 120,
	TurnSpeed = 45,
	Acceleration = 8,
	MaxAltitude = 500
}

-- Input handlers
local vehicleInputs = {
	W = false,  -- Forward
	S = false,  -- Backward
	A = false,  -- Turn left
	D = false,  -- Turn right
	Space = false,  -- Up (helicopters)
	X = false,  -- Down (helicopters)
	Q = false,  -- Special action 1
	E = false   -- Special action 2
}

function VehicleController:EnterVehicle(vehicle, seat)
	if currentVehicle then
		self:ExitVehicle()
	end

	currentVehicle = vehicle
	currentSeat = seat

	local vehicleType = vehicle:GetAttribute("VehicleType")

	if vehicleType == "Tank" then
		self:StartTankControls()
	elseif vehicleType == "Helicopter" then
		self:StartHelicopterControls()
	end

	-- Set up vehicle UI
	self:CreateVehicleUI(vehicleType)

	-- Connect input handlers
	self:ConnectInputHandlers()

	print("Entered " .. vehicleType)
end

function VehicleController:ExitVehicle()
	if not currentVehicle then return end

	-- Disconnect all connections
	for _, connection in pairs(vehicleConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	vehicleConnections = {}

	if movementConnection then
		movementConnection:Disconnect()
		movementConnection = nil
	end

	-- Clean up UI
	self:CleanupVehicleUI()

	local vehicleType = currentVehicle:GetAttribute("VehicleType")
	currentVehicle = nil
	currentSeat = nil

	print("Exited " .. vehicleType)
end

function VehicleController:StartTankControls()
	movementConnection = RunService.Heartbeat:Connect(function()
		if not currentVehicle or not currentVehicle.PrimaryPart then return end

		local hull = currentVehicle.PrimaryPart
		local bodyVelocity = hull:FindFirstChild("BodyVelocity")
		local bodyAngularVelocity = hull:FindFirstChild("BodyAngularVelocity")

		if not bodyVelocity or not bodyAngularVelocity then return end

		local settings = TANK_SETTINGS
		local moveVector = Vector3.new(0, 0, 0)
		local turnVector = Vector3.new(0, 0, 0)

		-- Forward/Backward movement
		if vehicleInputs.W then
			moveVector = moveVector + hull.CFrame.LookVector * settings.MaxSpeed
		end
		if vehicleInputs.S then
			moveVector = moveVector - hull.CFrame.LookVector * (settings.MaxSpeed * 0.7) -- Reverse slower
		end

		-- Turning
		if vehicleInputs.A then
			turnVector = turnVector + Vector3.new(0, settings.TurnSpeed, 0)
		end
		if vehicleInputs.D then
			turnVector = turnVector - Vector3.new(0, settings.TurnSpeed, 0)
		end

		-- Apply movement
		bodyVelocity.Velocity = moveVector
		bodyAngularVelocity.AngularVelocity = turnVector
	end)
end

function VehicleController:StartHelicopterControls()
	movementConnection = RunService.Heartbeat:Connect(function()
		if not currentVehicle or not currentVehicle.PrimaryPart then return end

		local fuselage = currentVehicle.PrimaryPart
		local bodyVelocity = fuselage:FindFirstChild("BodyVelocity")
		local bodyAngularVelocity = fuselage:FindFirstChild("BodyAngularVelocity")

		if not bodyVelocity or not bodyAngularVelocity then return end

		local settings = HELICOPTER_SETTINGS
		local moveVector = Vector3.new(0, 0, 0)
		local turnVector = Vector3.new(0, 0, 0)

		-- Forward/Backward movement
		if vehicleInputs.W then
			moveVector = moveVector + fuselage.CFrame.LookVector * settings.MaxSpeed
		end
		if vehicleInputs.S then
			moveVector = moveVector - fuselage.CFrame.LookVector * (settings.MaxSpeed * 0.8)
		end

		-- Left/Right movement
		if vehicleInputs.A then
			moveVector = moveVector - fuselage.CFrame.RightVector * (settings.MaxSpeed * 0.6)
		end
		if vehicleInputs.D then
			moveVector = moveVector + fuselage.CFrame.RightVector * (settings.MaxSpeed * 0.6)
		end

		-- Up/Down movement
		if vehicleInputs.Space then
			moveVector = moveVector + Vector3.new(0, settings.MaxSpeed * 0.8, 0)
		end
		if vehicleInputs.X then
			moveVector = moveVector - Vector3.new(0, settings.MaxSpeed * 0.6, 0)
		end

		-- Rotation (Q/E for yaw)
		if vehicleInputs.Q then
			turnVector = turnVector + Vector3.new(0, settings.TurnSpeed, 0)
		end
		if vehicleInputs.E then
			turnVector = turnVector - Vector3.new(0, settings.TurnSpeed, 0)
		end

		-- Apply movement
		bodyVelocity.Velocity = moveVector
		bodyAngularVelocity.AngularVelocity = turnVector
	end)
end

function VehicleController:ConnectInputHandlers()
	-- Key down events
	vehicleConnections[#vehicleConnections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		local key = input.KeyCode.Name
		if vehicleInputs[key] ~= nil then
			vehicleInputs[key] = true
		end
	end)

	-- Key up events
	vehicleConnections[#vehicleConnections + 1] = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		local key = input.KeyCode.Name
		if vehicleInputs[key] ~= nil then
			vehicleInputs[key] = false
		end
	end)
end

function VehicleController:CreateVehicleUI(vehicleType)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create main UI frame
	local vehicleGui = Instance.new("ScreenGui")
	vehicleGui.Name = "VehicleHUD"
	vehicleGui.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 150)
	mainFrame.Position = UDim2.new(0, 20, 1, -170)
	mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	mainFrame.BackgroundTransparency = 0.3
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = vehicleGui

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame

	-- Vehicle name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "VehicleName"
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = vehicleType
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = mainFrame

	-- Health bar
	local healthFrame = Instance.new("Frame")
	healthFrame.Name = "HealthFrame"
	healthFrame.Size = UDim2.new(1, -20, 0, 20)
	healthFrame.Position = UDim2.new(0, 10, 0, 35)
	healthFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthFrame.BorderSizePixel = 0
	healthFrame.Parent = mainFrame

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthFrame

	-- Health corner radius
	local healthCorner1 = Instance.new("UICorner")
	healthCorner1.CornerRadius = UDim.new(0, 4)
	healthCorner1.Parent = healthFrame

	local healthCorner2 = Instance.new("UICorner")
	healthCorner2.CornerRadius = UDim.new(0, 4)
	healthCorner2.Parent = healthBar

	-- Controls info
	local controlsLabel = Instance.new("TextLabel")
	controlsLabel.Name = "ControlsInfo"
	controlsLabel.Size = UDim2.new(1, 0, 0, 80)
	controlsLabel.Position = UDim2.new(0, 0, 0, 60)
	controlsLabel.BackgroundTransparency = 1
	controlsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	controlsLabel.TextSize = 12
	controlsLabel.Font = Enum.Font.Gotham
	controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
	controlsLabel.TextYAlignment = Enum.TextYAlignment.Top
	controlsLabel.Parent = mainFrame

	if vehicleType == "Tank" then
		controlsLabel.Text = "WASD - Move/Turn\nF - Exit Vehicle"
	elseif vehicleType == "Helicopter" then
		controlsLabel.Text = "WASD - Move\nSpace/X - Up/Down\nQE - Turn\nF - Exit Vehicle"
	end

	-- Update health bar
	if currentVehicle then
		local updateHealthConnection = RunService.Heartbeat:Connect(function()
			if not currentVehicle then return end

			local currentHealth = currentVehicle:GetAttribute("Health") or 0
			local maxHealth = currentVehicle:GetAttribute("MaxHealth") or 1
			local healthPercent = currentHealth / maxHealth

			healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)

			-- Change color based on health
			if healthPercent > 0.6 then
				healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			elseif healthPercent > 0.3 then
				healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
			else
				healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end
		end)

		vehicleConnections[#vehicleConnections + 1] = updateHealthConnection
	end
end

function VehicleController:CleanupVehicleUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local vehicleGui = playerGui:FindFirstChild("VehicleHUD")

	if vehicleGui then
		vehicleGui:Destroy()
	end
end

-- Handle seat events
local function connectSeatEvents()
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Seated:Connect(function(active, seat)
			if active and seat then
				-- Check if this seat belongs to a vehicle
				local vehicle = seat.Parent
				if vehicle and (vehicle:GetAttribute("VehicleType") == "Tank" or vehicle:GetAttribute("VehicleType") == "Helicopter") then
					VehicleController:EnterVehicle(vehicle, seat)
				end
			else
				-- Player exited seat
				if currentVehicle then
					VehicleController:ExitVehicle()
				end
			end
		end)
	else
		-- Wait for humanoid and retry
		spawn(function()
			local waitHumanoid = character:WaitForChild("Humanoid", 5)
			if waitHumanoid then
				connectSeatEvents()
			else
				warn("VehicleController: Could not find Humanoid in character")
			end
		end)
	end
end

-- Connect seat events with safety check
connectSeatEvents()

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	if currentVehicle then
		VehicleController:ExitVehicle()
	end
	-- Reconnect seat events for new character
	connectSeatEvents()
end)

return VehicleController