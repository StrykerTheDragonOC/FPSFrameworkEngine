local VehicleHandler = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Vehicle configurations
local VEHICLE_CONFIGS = {
	Tank = {
		Name = "M1A2 Abrams",
		Health = 1000,
		MaxSpeed = 50,
		TurnSpeed = 30,
		MainCannonDamage = 400,
		MainCannonRange = 500,
		MainCannonCooldown = 3,
		SeatingCapacity = 4,
		ArmorRating = 0.8, -- Damage reduction
		Parts = {
			"Hull",
			"Turret",
			"MainCannon",
			"LeftTread",
			"RightTread",
			"DriverSeat",
			"GunnerSeat",
			"LoaderSeat",
			"CommanderSeat"
		}
	},
	Helicopter = {
		Name = "AH-64 Apache",
		Health = 600,
		MaxSpeed = 120,
		TurnSpeed = 45,
		MainCannonDamage = 150,
		MainCannonRange = 300,
		MainCannonCooldown = 0.5,
		RocketDamage = 250,
		RocketRange = 400,
		SeatingCapacity = 2,
		ArmorRating = 0.3,
		Parts = {
			"Fuselage",
			"MainRotor",
			"TailRotor",
			"PilotSeat",
			"GunnerSeat",
			"MainCannon",
			"RocketPods"
		}
	}
}

-- Active vehicles tracking
local activeVehicles = {}
local vehicleConnections = {}

-- Get RemoteEvents
local spawnVehicleRemote = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SpawnVehicle")
local destroyVehicleRemote = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DestroyVehicle")
local clearVehiclesRemote = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ClearVehicles")
local vehicleActionRemote = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("VehicleAction")

function VehicleHandler:CreateTank(position, rotation)
	local tank = Instance.new("Model")
	tank.Name = "Tank_" .. tick()
	tank.Parent = Workspace

	-- Create hull (main body)
	local hull = Instance.new("Part")
	hull.Name = "Hull"
	hull.Size = Vector3.new(12, 4, 8)
	hull.Material = Enum.Material.Metal
	hull.Color = Color3.fromRGB(60, 80, 40)
	hull.Position = position
	hull.Rotation = rotation
	hull.Parent = tank

	-- Add PrimaryPart
	tank.PrimaryPart = hull

	-- Create turret
	local turret = Instance.new("Part")
	turret.Name = "Turret"
	turret.Size = Vector3.new(6, 3, 6)
	turret.Material = Enum.Material.Metal
	turret.Color = Color3.fromRGB(50, 70, 30)
	turret.Position = position + Vector3.new(0, 3.5, 0)
	turret.Parent = tank

	-- Weld turret to hull
	local turretWeld = Instance.new("WeldConstraint")
	turretWeld.Part0 = hull
	turretWeld.Part1 = turret
	turretWeld.Parent = hull

	-- Create main cannon
	local cannon = Instance.new("Part")
	cannon.Name = "MainCannon"
	cannon.Size = Vector3.new(1.5, 1.5, 8)
	cannon.Material = Enum.Material.Metal
	cannon.Color = Color3.fromRGB(40, 40, 40)
	cannon.Position = position + Vector3.new(0, 4, 4)
	cannon.Parent = tank

	-- Weld cannon to turret
	local cannonWeld = Instance.new("WeldConstraint")
	cannonWeld.Part0 = turret
	cannonWeld.Part1 = cannon
	cannonWeld.Parent = turret

	-- Create treads
	local leftTread = Instance.new("Part")
	leftTread.Name = "LeftTread"
	leftTread.Size = Vector3.new(2, 3, 10)
	leftTread.Material = Enum.Material.Plastic
	leftTread.Color = Color3.fromRGB(30, 30, 30)
	leftTread.Position = position + Vector3.new(-7, 0, 0)
	leftTread.Parent = tank

	local rightTread = Instance.new("Part")
	rightTread.Name = "RightTread"
	rightTread.Size = Vector3.new(2, 3, 10)
	rightTread.Material = Enum.Material.Plastic
	rightTread.Color = Color3.fromRGB(30, 30, 30)
	rightTread.Position = position + Vector3.new(7, 0, 0)
	rightTread.Parent = tank

	-- Weld treads to hull
	local leftTreadWeld = Instance.new("WeldConstraint")
	leftTreadWeld.Part0 = hull
	leftTreadWeld.Part1 = leftTread
	leftTreadWeld.Parent = hull

	local rightTreadWeld = Instance.new("WeldConstraint")
	rightTreadWeld.Part0 = hull
	rightTreadWeld.Part1 = rightTread
	rightTreadWeld.Parent = hull

	-- Create seats
	local driverSeat = Instance.new("VehicleSeat")
	driverSeat.Name = "DriverSeat"
	driverSeat.Size = Vector3.new(2, 1, 2)
	driverSeat.Position = position + Vector3.new(-2, 2.5, -1)
	driverSeat.Parent = tank

	local gunnerSeat = Instance.new("Seat")
	gunnerSeat.Name = "GunnerSeat"
	gunnerSeat.Size = Vector3.new(2, 1, 2)
	gunnerSeat.Position = position + Vector3.new(2, 4.5, 0)
	gunnerSeat.Parent = tank

	-- Weld seats
	local driverWeld = Instance.new("WeldConstraint")
	driverWeld.Part0 = hull
	driverWeld.Part1 = driverSeat
	driverWeld.Parent = hull

	local gunnerWeld = Instance.new("WeldConstraint")
	gunnerWeld.Part0 = turret
	gunnerWeld.Part1 = gunnerSeat
	gunnerWeld.Parent = turret

	-- Add BodyVelocity for movement
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = hull

	-- Add BodyAngularVelocity for turning
	local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
	bodyAngularVelocity.MaxTorque = Vector3.new(0, 50000, 0)
	bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
	bodyAngularVelocity.Parent = hull

	-- Add health attribute
	tank:SetAttribute("Health", VEHICLE_CONFIGS.Tank.Health)
	tank:SetAttribute("MaxHealth", VEHICLE_CONFIGS.Tank.Health)
	tank:SetAttribute("VehicleType", "Tank")

	return tank
end

function VehicleHandler:CreateHelicopter(position, rotation)
	local helicopter = Instance.new("Model")
	helicopter.Name = "Helicopter_" .. tick()
	helicopter.Parent = Workspace

	-- Create fuselage (main body)
	local fuselage = Instance.new("Part")
	fuselage.Name = "Fuselage"
	fuselage.Size = Vector3.new(3, 2, 8)
	fuselage.Material = Enum.Material.Metal
	fuselage.Color = Color3.fromRGB(40, 80, 40)
	fuselage.Position = position
	fuselage.Rotation = rotation
	fuselage.Parent = helicopter

	-- Add PrimaryPart
	helicopter.PrimaryPart = fuselage

	-- Create main rotor
	local mainRotor = Instance.new("Part")
	mainRotor.Name = "MainRotor"
	mainRotor.Size = Vector3.new(0.2, 0.2, 12)
	mainRotor.Material = Enum.Material.Metal
	mainRotor.Color = Color3.fromRGB(20, 20, 20)
	mainRotor.Position = position + Vector3.new(0, 3, 0)
	mainRotor.CanCollide = false
	mainRotor.Parent = helicopter

	-- Create tail rotor
	local tailRotor = Instance.new("Part")
	tailRotor.Name = "TailRotor"
	tailRotor.Size = Vector3.new(2, 0.2, 0.2)
	tailRotor.Material = Enum.Material.Metal
	tailRotor.Color = Color3.fromRGB(20, 20, 20)
	tailRotor.Position = position + Vector3.new(0, 1, -5)
	tailRotor.CanCollide = false
	tailRotor.Parent = helicopter

	-- Create seats
	local pilotSeat = Instance.new("VehicleSeat")
	pilotSeat.Name = "PilotSeat"
	pilotSeat.Size = Vector3.new(1.5, 1, 1.5)
	pilotSeat.Position = position + Vector3.new(-0.8, 0.5, 1)
	pilotSeat.Parent = helicopter

	local gunnerSeat = Instance.new("Seat")
	gunnerSeat.Name = "GunnerSeat"
	gunnerSeat.Size = Vector3.new(1.5, 1, 1.5)
	gunnerSeat.Position = position + Vector3.new(0.8, 0.5, 1)
	gunnerSeat.Parent = helicopter

	-- Weld parts
	local rotorWeld = Instance.new("WeldConstraint")
	rotorWeld.Part0 = fuselage
	rotorWeld.Part1 = mainRotor
	rotorWeld.Parent = fuselage

	local tailRotorWeld = Instance.new("WeldConstraint")
	tailRotorWeld.Part0 = fuselage
	tailRotorWeld.Part1 = tailRotor
	tailRotorWeld.Parent = fuselage

	local pilotWeld = Instance.new("WeldConstraint")
	pilotWeld.Part0 = fuselage
	pilotWeld.Part1 = pilotSeat
	pilotWeld.Parent = fuselage

	local gunnerWeld = Instance.new("WeldConstraint")
	gunnerWeld.Part0 = fuselage
	gunnerWeld.Part1 = gunnerSeat
	gunnerWeld.Parent = fuselage

	-- Add BodyVelocity for movement (including vertical)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(30000, 30000, 30000)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = fuselage

	-- Add BodyAngularVelocity for rotation
	local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
	bodyAngularVelocity.MaxTorque = Vector3.new(30000, 30000, 30000)
	bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
	bodyAngularVelocity.Parent = fuselage

	-- Add rotor spin effects
	local rotorSpin = RunService.Heartbeat:Connect(function()
		if mainRotor and mainRotor.Parent then
			mainRotor.Rotation = mainRotor.Rotation + Vector3.new(0, 20, 0)
		end
		if tailRotor and tailRotor.Parent then
			tailRotor.Rotation = tailRotor.Rotation + Vector3.new(30, 0, 0)
		end
	end)

	-- Store connection for cleanup
	vehicleConnections[helicopter] = {rotorSpin}

	-- Add health attribute
	helicopter:SetAttribute("Health", VEHICLE_CONFIGS.Helicopter.Health)
	helicopter:SetAttribute("MaxHealth", VEHICLE_CONFIGS.Helicopter.Health)
	helicopter:SetAttribute("VehicleType", "Helicopter")

	return helicopter
end

function VehicleHandler:SpawnVehicle(vehicleType, position, rotation)
	local vehicle

	if vehicleType == "Tank" then
		vehicle = self:CreateTank(position, rotation or Vector3.new(0, 0, 0))
	elseif vehicleType == "Helicopter" then
		vehicle = self:CreateHelicopter(position, rotation or Vector3.new(0, 0, 0))
	else
		warn("Unknown vehicle type: " .. tostring(vehicleType))
		return nil
	end

	-- Register vehicle
	activeVehicles[vehicle] = {
		Type = vehicleType,
		SpawnTime = tick(),
		Config = VEHICLE_CONFIGS[vehicleType]
	}

	-- Auto-cleanup after 10 minutes
	task.spawn(function()
		task.wait(600) -- 10 minutes
		if vehicle and vehicle.Parent then
			self:DestroyVehicle(vehicle)
		end
	end)

	print("Spawned " .. vehicleType .. " at " .. tostring(position))
	return vehicle
end

function VehicleHandler:DestroyVehicle(vehicle)
	if activeVehicles[vehicle] then
		activeVehicles[vehicle] = nil
	end

	-- Clean up connections
	if vehicleConnections[vehicle] then
		for _, connection in pairs(vehicleConnections[vehicle]) do
			if connection then
				connection:Disconnect()
			end
		end
		vehicleConnections[vehicle] = nil
	end

	-- Create destruction effect
	local explosion = Instance.new("Explosion")
	explosion.Position = vehicle.PrimaryPart.Position
	explosion.BlastRadius = 50
	explosion.BlastPressure = 500000
	explosion.Parent = Workspace

	-- Remove vehicle
	vehicle:Destroy()
end

function VehicleHandler:GetActiveVehicles()
	return activeVehicles
end

-- Admin check function
local function isAdmin(player)
	return player.UserId == 1500556418 or player:GetAttribute("IsAdmin") == true
end

-- RemoteEvent handlers
if spawnVehicleRemote then
	spawnVehicleRemote.OnServerEvent:Connect(function(player, vehicleType, position)
		if isAdmin(player) then
			VehicleHandler:SpawnVehicle(vehicleType, position)
		else
			warn(player.Name .. " (ID: " .. player.UserId .. ") attempted to spawn vehicle without admin privileges")
		end
	end)
else
	warn("SpawnVehicle RemoteEvent not found - vehicle spawning disabled")
end

if destroyVehicleRemote then
	destroyVehicleRemote.OnServerEvent:Connect(function(player, vehicle)
		if isAdmin(player) then
			if activeVehicles[vehicle] then
				VehicleHandler:DestroyVehicle(vehicle)
			end
		else
			warn(player.Name .. " (ID: " .. player.UserId .. ") attempted to destroy vehicle without admin privileges")
		end
	end)
else
	warn("DestroyVehicle RemoteEvent not found - vehicle destruction disabled")
end

local clearVehiclesEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ClearVehicles")
if clearVehiclesEvent then
	clearVehiclesEvent.OnServerEvent:Connect(function(player)
		if isAdmin(player) then
			for vehicle, _ in pairs(activeVehicles) do
				VehicleHandler:DestroyVehicle(vehicle)
			end
			print("Cleared all vehicles by " .. player.Name)
		else
			warn(player.Name .. " (ID: " .. player.UserId .. ") attempted to clear vehicles without admin privileges")
		end
	end)
else
	warn("ClearVehicles RemoteEvent not found - vehicle clearing disabled")
end

-- Console commands for vehicle spawning
local function executeCommand(player, command)
	local args = string.split(command, " ")
	local cmd = string.lower(args[1])

	if cmd == "spawntank" or cmd == "tank" then
		local position = player.Character and player.Character.PrimaryPart.Position + Vector3.new(0, 5, 10) or Vector3.new(0, 10, 0)
		VehicleHandler:SpawnVehicle("Tank", position)

	elseif cmd == "spawnheli" or cmd == "helicopter" or cmd == "heli" then
		local position = player.Character and player.Character.PrimaryPart.Position + Vector3.new(0, 15, 10) or Vector3.new(0, 20, 0)
		VehicleHandler:SpawnVehicle("Helicopter", position)

	elseif cmd == "clearvehicles" then
		for vehicle, _ in pairs(activeVehicles) do
			VehicleHandler:DestroyVehicle(vehicle)
		end
		print("Cleared all vehicles")

	elseif cmd == "listvehicles" then
		print("Active vehicles:")
		for vehicle, data in pairs(activeVehicles) do
			print("- " .. data.Type .. " (Age: " .. math.floor(tick() - data.SpawnTime) .. "s)")
		end
	end
end

-- Hook into chat commands (basic implementation)
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if string.sub(message, 1, 1) == "/" then
			executeCommand(player, string.sub(message, 2))
		end
	end)
end)

return VehicleHandler