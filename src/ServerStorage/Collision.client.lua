-- ViewmodelCollisionFix.lua
-- This script should be placed in a LocalScript inside StarterPlayerScripts
-- It will fix collision issues with ViewmodelRig parts

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local collisionGroupName = "ViewmodelNoCollision"

-- Setup collision group using the new RegisterCollisionGroup method
local function setupCollisionGroup()
	local success, result = pcall(function()
		-- Try to register the NoCollision group
		PhysicsService:RegisterCollisionGroup(collisionGroupName)

		-- Set it to not collide with Default group
		PhysicsService:CollisionGroupSetCollidable(collisionGroupName, "Default", false)
		return true
	end)

	if not success then
		-- Group might already exist or PhysicsService not available on client
		print("Note: Could not create collision group. This is normal if it already exists.")
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

-- Fix collisions for a part
local function fixPartCollisions(part)
	if not part:IsA("BasePart") then return end

	-- Set collision properties
	part.CanCollide = false

	-- These newer properties provide better control over physics interactions
	if part:GetAttribute("NeedsCollision") ~= true then
		part.CanTouch = false
		part.CanQuery = false
	end

	-- Try to set collision group
	pcall(function()
		part.CollisionGroup = collisionGroupName
	end)

	-- Ensure part is anchored for first-person viewmodels
	part.Anchored = true
end

-- Process viewmodel parts
local function processViewmodel(viewmodel)
	if not viewmodel then return end

	-- Process all descendants
	for _, part in ipairs(viewmodel:GetDescendants()) do
		if part:IsA("BasePart") then
			fixPartCollisions(part)
		end
	end

	-- Watch for newly added parts
	viewmodel.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			task.defer(function()
				fixPartCollisions(descendant)
			end)
		end
	end)
end

-- Fix character parts to prevent clipping with the viewmodel
local function fixCharacterParts()
	if not player or not player.Character then return end

	local character = player.Character
	local characterParts = {"Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"}

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and table.find(characterParts, part.Name) then
			pcall(function()
				-- Make first-person parts non-collidable with viewmodel
				part.LocalTransparencyModifier = 1
				part.CanCollide = false

				-- Optional: assign character parts to a special collision group
				-- that won't collide with the viewmodel
				part.CollisionGroup = "Character"
			end)
		end
	end
end

-- Main function to fix viewmodel collisions
local function fixViewmodelCollisions()
	-- Setup collision group
	setupCollisionGroup()

	-- Find the viewmodel container
	local container = findViewmodelContainer()
	if container then
		processViewmodel(container)
		print("Fixed collisions for ViewmodelContainer")
	end

	-- Fix character parts
	fixCharacterParts()
end

-- Run when script loads
fixViewmodelCollisions()

-- Connect to character added event to fix character parts when character loads/respawns
player.CharacterAdded:Connect(function(character)
	task.wait(0.5) -- Wait for character to fully load
	fixCharacterParts()
end)

-- Watch for camera changes (in case the camera is recreated)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	task.wait(0.5) -- Wait for viewmodel to be created
	fixViewmodelCollisions()
end)

-- Run periodically to ensure all new parts are handled
RunService.Heartbeat:Connect(function()
	local container = findViewmodelContainer()
	if container and container:GetAttribute("LastCollisionCheck") ~= game.Workspace:GetServerTimeNow() then
		container:SetAttribute("LastCollisionCheck", game.Workspace:GetServerTimeNow())

		-- Process any new viewmodel that was created
		local viewmodelRig = container:FindFirstChild("ViewmodelRig")
		if viewmodelRig then
			processViewmodel(viewmodelRig)
		end
	end
end)