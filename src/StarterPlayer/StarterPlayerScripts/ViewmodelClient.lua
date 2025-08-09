-- ViewmodelClient.lua
-- Improved client script that properly loads your custom ViewmodelRig

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Helper function to safely require modules
local function safeRequire(modulePath)
	local success, result = pcall(function()
		return require(modulePath)
	end)

	if success then
		return result
	else
		warn("Failed to require module: " .. modulePath:GetFullName() .. " - " .. tostring(result))
		return nil
	end
end

-- Ensure folders are properly set up
local function ensureFPSFolders()
	print("Ensuring FPS folders exist...")

	-- Check for FPSSystem folder
	local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
	if not fpsSystem then
		fpsSystem = Instance.new("Folder")
		fpsSystem.Name = "FPSSystem"
		fpsSystem.Parent = ReplicatedStorage
		print("Created FPSSystem folder in ReplicatedStorage")
	end

	-- Check for Modules folder
	local modulesFolder = fpsSystem:FindFirstChild("Modules")
	if not modulesFolder then
		modulesFolder = Instance.new("Folder")
		modulesFolder.Name = "Modules"
		modulesFolder.Parent = fpsSystem
		print("Created Modules folder in FPSSystem")
	end

	-- Check for ViewModels folder
	local viewModels = fpsSystem:FindFirstChild("ViewModels")
	if not viewModels then
		viewModels = Instance.new("Folder")
		viewModels.Name = "ViewModels"
		viewModels.Parent = fpsSystem
		print("Created ViewModels folder")
	end

	-- Check for Arms folder
	local arms = viewModels:FindFirstChild("Arms")
	if not arms then
		arms = Instance.new("Folder")
		arms.Name = "Arms"
		arms.Parent = viewModels
		print("Created Arms folder")
	end

	return {
		fpsSystem = fpsSystem,
		modulesFolder = modulesFolder,
		viewModels = viewModels,
		arms = arms
	}
end

-- Find your custom ViewmodelRig
local function findCustomViewmodelRig()
	local folders = ensureFPSFolders()

	-- Look for existing ViewmodelRig in FPSSystem.ViewModels.Arms
	local customRig = folders.arms:FindFirstChild("ViewmodelRig")

	if customRig then
		print("Found custom ViewmodelRig in correct path")
		return customRig
	end

	print("Custom ViewmodelRig not found in expected path")
	return nil
end

-- Load modules with error handling
local function loadModules()
	print("Loading FPS modules...")

	-- Ensure folders exist
	local folders = ensureFPSFolders()
	local modulesFolder = folders.modulesFolder

	-- Load core modules
	local modules = {}
	local moduleNames = {
		"ViewmodelSystem",
		"CrosshairSystem",
		"FPSCamera",
		"ScopeSystem",
		"WeaponConverter",
		"FPSFramework"
	}

	for _, name in ipairs(moduleNames) do
		local moduleScript = modulesFolder:FindFirstChild(name)
		if moduleScript then
			modules[name] = safeRequire(moduleScript)
			if modules[name] then
				print("Loaded module: " .. name)
			end
		else
			warn("Module not found: " .. name)
		end
	end

	
	return modules
end

-- Initialize viewmodel systems
local function initViewmodel()
	print("Initializing viewmodel system...")

	-- Load modules
	local modules = loadModules()

	-- Exit if critical modules are missing
	if not modules.ViewmodelSystem then
		error("Critical module ViewmodelSystem is missing!")
		return nil
	end

	-- Create viewmodel instance
	local viewmodel = modules.ViewmodelSystem.new()

	-- Get the custom viewmodel rig
	local customRig = findCustomViewmodelRig()

	-- Set up arms with custom rig
	if customRig then
		print("Using custom ViewmodelRig from ReplicatedStorage path")
		viewmodel:setupArms(customRig)
	else
		print("No custom ViewmodelRig found, using default arms")
		viewmodel:setupArms()
	end

	-- Start the update loop
	viewmodel:startUpdateLoop()

	-- Setup input handlers for movement states
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			viewmodel:setSprinting(true)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			viewmodel:setAiming(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			viewmodel:setSprinting(false)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			viewmodel:setAiming(false)
		end
	end)

	-- Mouse movement for weapon sway
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			viewmodel.lastMouseDelta = input.Delta
		end
	end)

	print("Viewmodel system initialized successfully!")
	return viewmodel
end

-- Verification function to check viewmodel rig
local function verifyViewmodelRigVisibility()
	task.delay(2, function()
		local camera = workspace.CurrentCamera
		if not camera then return end

		local container = camera:FindFirstChild("ViewmodelContainer")
		if not container then
			print("ViewmodelContainer not found in verification")
			return
		end

		local rig = container:FindFirstChild("ViewmodelRig")
		if not rig then
			print("ViewmodelRig not found in verification")
			return
		end

		-- Check arm parts
		local foundArmParts = false
		local visibleArmParts = 0

		for _, descendant in ipairs(rig:GetDescendants()) do
			if descendant:IsA("BasePart") and 
				(descendant.Name == "LeftArm" or 
					descendant.Name == "RightArm" or
					descendant.Name:find("Arm") or
					descendant.Name:find("Hand")) then

				foundArmParts = true

				if descendant.Transparency < 1 then
					visibleArmParts = visibleArmParts + 1
				else
					-- Force visibility on invisible arm parts
					print("Fixing invisible arm part: " .. descendant.Name)
					descendant.Transparency = 0
					descendant.LocalTransparencyModifier = 0
				end
			end
		end

		if foundArmParts then
			if visibleArmParts > 0 then
				print("Verification: " .. visibleArmParts .. " visible arm parts found")
			else
				print("Verification: Found arm parts but they're all invisible")
			end
		else
			print("Verification: No arm parts found at all")
		end
	end)
end

-- Main initialization
local function init()
	print("Starting FPS viewmodel initialization...")

	-- Wait for character
	local function waitForCharacter()
		if player.Character then
			return player.Character
		end

		return player.CharacterAdded:Wait()
	end

	local character = waitForCharacter()
	print("Character loaded, initializing viewmodel")

	-- Initialize viewmodel with error handling
	local success, result = pcall(initViewmodel)

	if success then
		print("Viewmodel initialization complete")

		-- Run visibility verification
		verifyViewmodelRigVisibility()

		return result
	else
		warn("Failed to initialize viewmodel: " .. tostring(result))
		-- Try again after a delay if it failed
		task.delay(2, function()
			print("Retrying viewmodel initialization...")
			pcall(initViewmodel)
		end)
		return nil
	end
end

-- Run initialization
local viewmodel = init()

-- Make viewmodel accessible globally for other scripts
if viewmodel then
	_G.Viewmodel = viewmodel
end

-- Additional arm visibility fix that runs after a delay
task.delay(3, function()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local container = camera:FindFirstChild("ViewmodelContainer")
	if not container then return end

	local rig = container:FindFirstChild("ViewmodelRig")
	if not rig then return end

	print("Running additional arm visibility check...")

	-- Force visibility on all arm parts
	for _, desc in ipairs(rig:GetDescendants()) do
		if desc:IsA("BasePart") and 
			(desc.Name == "LeftArm" or 
				desc.Name == "RightArm" or
				desc.Name == "LeftHand" or
				desc.Name == "RightHand" or
				desc.Name:find("Arm") or
				desc.Name:find("Hand")) then

			desc.Transparency = 0
			desc.LocalTransparencyModifier = 0
			desc.CanCollide = false
			desc.Anchored = true

			print("Force-fixed visibility for: " .. desc.Name)
		end
	end
end)

return viewmodel