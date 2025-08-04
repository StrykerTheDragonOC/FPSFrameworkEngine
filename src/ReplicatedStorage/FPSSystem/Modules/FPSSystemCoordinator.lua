-- FPSSystemCoordinator
-- This module coordinates the initialization of all FPS systems to prevent conflicts

local Coordinator = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Track initialization state
local initialized = false
local systems = {}
local activeScripts = {}

-- Log system activity for debugging
local function log(message)
	print("[FPS Coordinator] " .. message)
end

-- Register a script that's trying to initialize FPS systems
function Coordinator.registerScript(scriptName)
	if activeScripts[scriptName] then
		log("Script already registered: " .. scriptName)
		return false
	end

	activeScripts[scriptName] = true
	log("Registered script: " .. scriptName)
	return true
end

-- Unregister a script when it's done or destroyed
function Coordinator.unregisterScript(scriptName)
	if activeScripts[scriptName] then
		activeScripts[scriptName] = nil
		log("Unregistered script: " .. scriptName)
		return true
	end
	return false
end

-- Safely require a module with error handling
function Coordinator.requireModule(modulePath)
	if type(modulePath) ~= "string" then
		warn("Invalid module path: " .. tostring(modulePath))
		return nil
	end

	-- Check if the module exists
	local success, result = pcall(function()
		return ReplicatedStorage.FPSSystem.Modules:FindFirstChild(modulePath)
	end)

	if not success or not result then
		warn("Module not found: " .. modulePath)
		return nil
	end

	-- Try to require the module
	success, result = pcall(function()
		return require(result)
	end)

	if success then
		log("Successfully loaded module: " .. modulePath)
		return result
	else
		warn("Failed to require module: " .. modulePath .. " - " .. tostring(result))
		return nil
	end
end

-- Initialize a specific system
function Coordinator.initSystem(systemName, initFunction)
	if systems[systemName] then
		log("System already initialized: " .. systemName)
		return systems[systemName]
	end

	local system
	local success, result = pcall(function()
		return initFunction()
	end)

	if success then
		system = result
		systems[systemName] = system
		log("Initialized system: " .. systemName)
	else
		warn("Failed to initialize system: " .. systemName .. " - " .. tostring(result))
	end

	return system
end

-- Get an already initialized system
function Coordinator.getSystem(systemName)
	return systems[systemName]
end

-- Check if all systems are initialized
function Coordinator.isInitialized()
	return initialized
end

-- Set the initialization state
function Coordinator.setInitialized(state)
	initialized = state
	log("FPS systems initialized: " .. tostring(state))
end

-- Clean up all systems
function Coordinator.cleanup()
	log("Cleaning up all FPS systems...")

	for name, system in pairs(systems) do
		if type(system) == "table" and type(system.cleanup) == "function" then
			local success, result = pcall(function()
				system:cleanup()
			end)

			if success then
				log("Cleaned up system: " .. name)
			else
				warn("Failed to clean up system: " .. name .. " - " .. tostring(result))
			end
		end
	end

	-- Reset systems table
	systems = {}
	initialized = false
	log("All FPS systems cleaned up")
end

-- Initialize all required modules for the FPS framework
function Coordinator.initializeAllSystems()
	if initialized then
		log("Systems already initialized, cleaning up first...")
		Coordinator.cleanup()
	end

	log("Initializing all FPS systems...")

	-- Load all required modules
	local ViewmodelSystem = Coordinator.requireModule("ViewmodelSystem")
	local CrosshairSystem = Coordinator.requireModule("CrosshairSystem")
	local FPSCamera = Coordinator.requireModule("FPSCamera")
	local ScopeSystem = Coordinator.requireModule("ScopeSystem")
	local EffectsSystem = Coordinator.requireModule("FPSEffectsSystem")
	local GrenadeSystem = Coordinator.requireModule("GrenadeSystem")
	local WeaponManager = Coordinator.requireModule("WeaponManager")
	local FPSFramework = Coordinator.requireModule("FPSFramework")
	local WeaponFiringSystem = Coordinator.requireModule("WeaponFiringSystem")

	-- Check if critical modules are loaded
	if not ViewmodelSystem or not FPSFramework then
		log("Critical modules are missing, aborting initialization")
		return false
	end

	-- Initialize viewmodel system
	local viewmodel = Coordinator.initSystem("ViewmodelSystem", function()
		local vm = ViewmodelSystem.new()
		vm:setupArms()
		vm:startUpdateLoop()
		return vm
	end)

	-- Initialize FPS framework
	local framework = Coordinator.initSystem("FPSFramework", function()
		local fw = FPSFramework.new()
		return fw
	end)

	-- Initialize crosshair system
	if CrosshairSystem then
		Coordinator.initSystem("CrosshairSystem", function()
			return CrosshairSystem.new()
		end)
	end

	-- Initialize camera system
	if FPSCamera then
		Coordinator.initSystem("FPSCamera", function()
			return FPSCamera.new()
		end)
	end

	-- Initialize scope system
	if ScopeSystem then
		Coordinator.initSystem("ScopeSystem", function()
			return ScopeSystem.new()
		end)
	end

	-- Initialize effects system
	if EffectsSystem then
		Coordinator.initSystem("EffectsSystem", function()
			return EffectsSystem.new()
		end)
	end

	-- Initialize grenade system
	if GrenadeSystem then
		Coordinator.initSystem("GrenadeSystem", function()
			return GrenadeSystem.new()
		end)
	end

	-- Initialize weapon manager
	if WeaponManager then
		Coordinator.initSystem("WeaponManager", function()
			return WeaponManager
		end)
	end

	-- Initialize weapon firing system
	if WeaponFiringSystem and viewmodel then
		Coordinator.initSystem("WeaponFiringSystem", function()
			return WeaponFiringSystem.new(viewmodel)
		end)
	end

	-- Mark as initialized
	initialized = true
	log("All FPS systems initialized successfully")
	return true
end

-- Handle player removal
Players.PlayerRemoving:Connect(function(player)
	if player == Players.LocalPlayer then
		Coordinator.cleanup()
	end
end)

return Coordinator