-- ViewmodelCollisionFix.lua
-- Script to fix collision and transparency issues with viewmodels
-- Place in StarterPlayerScripts as a LocalScript

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local collisionGroupName = "ViewmodelNoCollision"

-- Setup collision groups for the new CollisionGroup API
local function setupCollisionGroup()
	local success, result = pcall(function()
		-- Register the collision group 
		PhysicsService:RegisterCollisionGroup(collisionGroupName)

		-- Make viewmodels not collide with characters
		PhysicsService:CollisionGroupSetCollidable(collisionGroupName, "Default", false)

		-- Create character collision group if it doesn't exist
		pcall(function()
			PhysicsService:RegisterCollisionGroup("Characters")
			PhysicsService:CollisionGroupSetCollidable(collisionGroupName, "Characters", false)
		end)

		return true
	end)

	if not success then
		warn("Collision group setup failed. This is expected on clients that can't modify PhysicsService.")
		warn("Error details: " .. tostring(result))
	end

	return collisionGroupName
end

-- Find the viewmodel container
local function findViewmodelContainer()
	if not camera then 
		camera = workspace.CurrentCamera
		if not camera then return nil end
	end

	local container = camera:FindFirstChild("ViewmodelContainer")
	return container
end

-- Fix part transparency and collisions
local function fixPartTransparency(part)
	if not part:IsA("BasePart") then return end

	-- Handle viewmodel parts
	if part.Name == "ViewmodelRoot" or part.Name == "CameraBone" or part.Name == "HumanoidRootPart" then
		-- Core parts should be invisible
		part.Transparency = 1
	elseif part.Name:find("Arm") or part.Name:find("Hand") then
		-- Arm and hand parts should be visible
		part.Transparency = 0
		part.LocalTransparencyModifier = 0
	end

	-- Fix collision properties for all parts
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false

	-- Set collision group
	pcall(function()
		part.CollisionGroup = collisionGroupName
	end)

	-- Ensure anchored
	part.Anchored = true
end

-- Make character parts invisible in first person
local function fixCharacterTransparency()
	if not player or not player.Character then return end

	-- Make character parts invisible from first person view
	for _, part in pairs(player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
		end
	end
end

-- Process all viewmodel parts
local function processViewmodel(viewmodel)
	if not viewmodel then return end

	-- Process all descendants
	for _, part in pairs(viewmodel:GetDescendants()) do
		if part:IsA("BasePart") then
			fixPartTransparency(part)
		end
	end

	-- Connect to DescendantAdded to handle new parts
	viewmodel.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			task.defer(function()
				fixPartTransparency(descendant)
			end)
		end
	end)
end

-- Main collision fixing function
local function fixViewmodelCollisions()
	print("Fixing viewmodel collisions...")

	-- Setup collision groups
	setupCollisionGroup()

	-- Find container and fix it
	local container = findViewmodelContainer()
	if container then
		processViewmodel(container)

		-- Set a flag to prevent redundant updates
		container:SetAttribute("CollisionFixed", true)
		print("Fixed collision for ViewmodelContainer")
	end

	-- Fix character transparency
	fixCharacterTransparency()

	print("Viewmodel collision fix complete")
end

-- Run the fix immediately
fixViewmodelCollisions()

-- Connect to events to handle character changes
player.CharacterAdded:Connect(function(character)
	-- Wait for character to load
	task.wait(0.5)

	-- Fix character transparency
	fixCharacterTransparency()

	-- Check for viewmodel changes
	fixViewmodelCollisions()
end)

-- Watch for camera changes
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	task.wait(0.5) -- Wait for viewmodel to be created
	fixViewmodelCollisions()
end)

-- Monitor for new viewmodels
RunService.Heartbeat:Connect(function()
	local container = findViewmodelContainer()
	if container and not container:GetAttribute("CollisionFixed") then
		processViewmodel(container)
		container:SetAttribute("CollisionFixed", true)
		print("Fixed collision for new ViewmodelContainer")
	end
end)

-- When player dies, make sure to reset collision flag
player.CharacterRemoving:Connect(function()
	local container = findViewmodelContainer()
	if container then
		container:SetAttribute("CollisionFixed", false)
	end
end)

print("ViewmodelCollisionFix script started")