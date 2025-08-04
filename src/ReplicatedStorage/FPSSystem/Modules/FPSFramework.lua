-- FPSFramework.lua
-- Main controller for the FPS system
-- Place in ReplicatedStorage

local FPSFramework = {}
FPSFramework.__index = FPSFramework

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

-- Constants
local SYSTEM_NAMES = {
	VIEWMODEL = "ViewmodelSystem",
	WEAPON = "WeaponSystem",
	FIRING = "FiringSystem",
	CAMERA = "CameraSystem",
	CROSSHAIR = "CrosshairSystem",
	EFFECTS = "EffectsSystem",
	GRENADE = "GrenadeSystem",
	MELEE = "MeleeSystem",
	ATTACHMENT = "AttachmentSystem",
	INPUT = "InputSystem",
	DEBUG = "DebugSystem"
}

local FOLDER_STRUCTURE = {
	FPSSystem = {
		"Modules",
		"WeaponModels",
		"ViewModels",
		"Attachments",
		"Effects",
		"Animations",
		"Config",
		"RemoteEvents"
	}
}

-- Initialize framework for a player
function FPSFramework.new()
	local self = setmetatable({}, FPSFramework)

	-- Core components
	self.player = Players.LocalPlayer
	self.camera = workspace.CurrentCamera
	self.systems = {}
	self.initialized = false
	self.debug = false

	-- Weapon state
	self.currentWeapon = nil
	self.weaponSlots = {
		PRIMARY = nil,
		SECONDARY = nil,
		MELEE = nil,
		GRENADES = nil
	}

	-- Player state
	self.isAiming = false
	self.isSprinting = false
	self.isReloading = false
	self.isCrouching = false

	-- Remote events
	self.remoteEvents = {}

	return self
end

-- Initialize the framework
function FPSFramework:init()
	print("Initializing FPS Framework...")

	-- Ensure folders exist
	self:ensureFolders()

	-- Pre-load assets
	self:preloadAssets()

	-- Initialize systems in order
	self:initSystems()

	-- Set up remote events
	self:setupRemoteEvents()

	-- Set up input handlers
	if self.systems.INPUT then
		self.systems.INPUT:setupInputHandlers()
	else
		self:setupDefaultInputHandlers()
	end

	-- Use default configuration if not overridden
	self:loadDefaultConfiguration()

	-- Load default weapons
	self:loadDefaultWeapons()

	-- Start render loop
	self:startRenderLoop()

	-- Mark as initialized
	self.initialized = true

	print("FPS Framework initialized!")
	return true
end

-- Ensure the necessary folder structure exists
function FPSFramework:ensureFolders()
	for parentName, subfolders in pairs(FOLDER_STRUCTURE) do
		local parent = ReplicatedStorage:FindFirstChild(parentName)
		if not parent then
			parent = Instance.new("Folder")
			parent.Name = parentName
			parent.Parent = ReplicatedStorage
		end

		for _, folderName in ipairs(subfolders) do
			local folder = parent:FindFirstChild(folderName)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = folderName
				folder.Parent = parent
			end
		end
	end

	print("Folder structure verified")
end

-- Preload assets for smoother experience
function FPSFramework:preloadAssets()
	local assets = {}

	-- Add weapon models to preload
	local weaponModels = ReplicatedStorage.FPSSystem.WeaponModels:GetChildren()
	for _, model in ipairs(weaponModels) do
		table.insert(assets, model)
	end

	-- Add viewmodels to preload
	local viewModels = ReplicatedStorage.FPSSystem.ViewModels:GetChildren()
	for _, model in ipairs(viewModels) do
		table.insert(assets, model)
	end

	-- Preload assets
	if #assets > 0 then
		ContentProvider:PreloadAsync(assets)
	end

	print("Assets preloaded")
end

-- Initialize all systems
function FPSFramework:initSystems()
	-- Define system initialization order for dependency management
	local initOrder = {
		SYSTEM_NAMES.VIEWMODEL,
		SYSTEM_NAMES.WEAPON,
		SYSTEM_NAMES.INPUT,
		SYSTEM_NAMES.CAMERA,
		SYSTEM_NAMES.FIRING,
		SYSTEM_NAMES.EFFECTS,
		SYSTEM_NAMES.CROSSHAIR,
		SYSTEM_NAMES.ATTACHMENT,
		SYSTEM_NAMES.GRENADE,
		SYSTEM_NAMES.MELEE,
		SYSTEM_NAMES.DEBUG
	}

	-- Initialize each system in order
	for _, systemName in ipairs(initOrder) do
		self:initSystem(systemName)
	end

	print("All systems initialized")
end

-- Initialize a specific system
function FPSFramework:initSystem(systemName)
	-- Check if already initialized
	if self.systems[systemName] then
		return self.systems[systemName]
	end

	-- Try to require the module
	local module = self:requireModule(systemName)
	if not module then
		warn("Failed to require module: " .. systemName)
		return nil
	end

	-- Initialize the system
	local system

	-- Special initialization logic based on system type
	if systemName == SYSTEM_NAMES.VIEWMODEL then
		system = module.new()
		if system then
			system:setupArms()
			system:startUpdateLoop()
		end
	elseif systemName == SYSTEM_NAMES.WEAPON then
		system = module
	elseif systemName == SYSTEM_NAMES.FIRING then
		system = module.new(self.systems[SYSTEM_NAMES.VIEWMODEL])
	elseif systemName == SYSTEM_NAMES.GRENADE then
		system = module.new(self.systems[SYSTEM_NAMES.VIEWMODEL])
	elseif systemName == SYSTEM_NAMES.MELEE then
		system = module.new(self.systems[SYSTEM_NAMES.VIEWMODEL])
	elseif systemName == SYSTEM_NAMES.INPUT then
		system = module.new(self)
	elseif systemName == SYSTEM_NAMES.DEBUG and self.debug then
		system = module:init()
		if system and self.systems[SYSTEM_NAMES.VIEWMODEL] then
			module:injectIntoViewmodelSystem(self.systems[SYSTEM_NAMES.VIEWMODEL])
		end
	else
		-- Standard initialization
		if typeof(module.new) == "function" then
			system = module.new()
		else
			system = module
		end
	end

	-- Store the initialized system
	if system then
		self.systems[systemName] = system
		print("Initialized system: " .. systemName)
	else
		warn("Failed to initialize system: " .. systemName)
	end

	return system
end

-- Safely require a module
function FPSFramework:requireModule(moduleName)
	local modulesFolder = ReplicatedStorage.FPSSystem.Modules
	local moduleScript = modulesFolder:FindFirstChild(moduleName)

	if not moduleScript then
		warn("Module not found: " .. moduleName)
		return nil
	end

	local success, result = pcall(function()
		return require(moduleScript)
	end)

	if success then
		return result
	else
		warn("Error requiring module " .. moduleName .. ": " .. tostring(result))
		return nil
	end
end

-- Set up remote events
function FPSFramework:setupRemoteEvents()
	local eventNames = {
		"WeaponFired",
		"WeaponReload",
		"WeaponEquipped",
		"CharacterAnimationEvent",
		"HitRegistration",
		"GrenadeEvent",
		"MeleeEvent"
	}

	local eventsFolder = ReplicatedStorage.FPSSystem.RemoteEvents

	for _, eventName in ipairs(eventNames) do
		local remoteEvent = eventsFolder:FindFirstChild(eventName)
		if not remoteEvent then
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = eventName
			remoteEvent.Parent = eventsFolder
		end

		self.remoteEvents[eventName] = remoteEvent
	end

	print("Remote events set up")
end

-- Set up default input handlers if InputSystem isn't available
function FPSFramework:setupDefaultInputHandlers()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Handle basic weapons switching
		if input.KeyCode == Enum.KeyCode.One then
			self:equipWeapon("PRIMARY")
		elseif input.KeyCode == Enum.KeyCode.Two then
			self:equipWeapon("SECONDARY")
		elseif input.KeyCode == Enum.KeyCode.Three then
			self:equipWeapon("MELEE")
		elseif input.KeyCode == Enum.KeyCode.Four then
			self:equipWeapon("GRENADES")
		end
	end)

	print("Default input handlers set up")
end

-- Load default configuration
function FPSFramework:loadDefaultConfiguration()
	-- Load WeaponConfig module if available
	local WeaponConfig = self:requireModule("WeaponConfig")
	if WeaponConfig then
		self.config = WeaponConfig
	else
		-- Use default configs
		self.config = {
			DefaultWeapons = {
				PRIMARY = "G36",
				SECONDARY = "M9",
				MELEE = "PocketKnife",
				GRENADES = "FragGrenade"
			}
		}
	end

	print("Default configuration loaded")
end

-- Load default weapons
function FPSFramework:loadDefaultWeapons()
	if not self.systems[SYSTEM_NAMES.WEAPON] then
		warn("Cannot load weapons - WeaponSystem not initialized")
		return
	end

	-- Load weapons into slots
	for slot, weaponName in pairs(self.config.DefaultWeapons) do
		self:loadWeapon(slot, weaponName)
	end

	-- Equip primary weapon
	self:equipWeapon("PRIMARY")

	print("Default weapons loaded")
end

-- Load a weapon into a slot
function FPSFramework:loadWeapon(slot, weaponName)
	if not self.systems[SYSTEM_NAMES.WEAPON] then
		warn("Cannot load weapon: WeaponSystem not initialized")
		return
	end

	-- Load weapon model
	local weaponModel
	local weaponSystem = self.systems[SYSTEM_NAMES.WEAPON]

	if typeof(weaponSystem.loadWeapon) == "function" then
		weaponModel = weaponSystem.loadWeapon(weaponName, slot)
	elseif weaponName == "G36" and typeof(weaponSystem.getG36) == "function" then
		weaponModel = weaponSystem.getG36()
	else
		-- Create placeholder as fallback
		weaponModel = self:createPlaceholderWeapon(slot, weaponName)
	end

	-- Store the weapon data
	if weaponModel then
		local weaponConfig

		-- Get config from WeaponConfig if available
		if self.config.Weapons and self.config.Weapons[weaponName] then
			weaponConfig = self.config.Weapons[weaponName]
		else
			-- Use basic defaults
			weaponConfig = {
				name = weaponName,
				damage = 25,
				fireRate = 600,
				magazineSize = 30,
				reloadTime = 2.5
			}
		end

		self.weaponSlots[slot] = {
			name = weaponName,
			model = weaponModel,
			config = weaponConfig
		}

		print("Loaded " .. weaponName .. " into " .. slot .. " slot")
	else
		warn("Failed to load weapon: " .. weaponName)
	end
end

-- Create a placeholder weapon model
function FPSFramework:createPlaceholderWeapon(slot, weaponName)
	local model = Instance.new("Model")
	model.Name = weaponName

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.3, 2)
	handle.Anchored = true
	handle.CanCollide = false
	handle.Color = Color3.fromRGB(80, 80, 80)
	handle.Material = Enum.Material.Metal

	-- Configure based on weapon type
	if slot == "PRIMARY" then
		-- Add barrel for primary weapons
		local barrel = Instance.new("Part")
		barrel.Name = "Barrel"
		barrel.Size = Vector3.new(0.2, 0.2, 1)
		barrel.Position = handle.Position + Vector3.new(0, 0, -1.5)
		barrel.Anchored = true
		barrel.CanCollide = false
		barrel.Color = Color3.fromRGB(60, 60, 60)
		barrel.Parent = model

		-- Add muzzle attachment
		local muzzlePoint = Instance.new("Attachment")
		muzzlePoint.Name = "MuzzlePoint"
		muzzlePoint.Position = Vector3.new(0, 0, -0.5)
		muzzlePoint.Parent = barrel
	elseif slot == "SECONDARY" then
		handle.Size = Vector3.new(0.3, 0.8, 0.2)
	elseif slot == "MELEE" then
		handle.Size = Vector3.new(0.2, 0.8, 0.2)

		-- Add blade for melee
		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(0.05, 0.8, 0.3)
		blade.Position = handle.Position + Vector3.new(0, 0.8, 0)
		blade.Anchored = true
		blade.CanCollide = false
		blade.Color = Color3.fromRGB(200, 200, 200)
		blade.Material = Enum.Material.Metal
		blade.Parent = model
	elseif slot == "GRENADES" then
		handle.Size = Vector3.new(0.4, 0.4, 0.4)
		handle.Shape = Enum.PartType.Ball
		handle.Color = Color3.fromRGB(50, 80, 50)
	end

	handle.Parent = model
	model.PrimaryPart = handle

	-- Add attachment points
	local attachments = {
		MuzzlePoint = CFrame.new(0, 0, -handle.Size.Z/2),
		RightGripPoint = CFrame.new(0.1, -0.1, 0),
		LeftGripPoint = CFrame.new(-0.1, -0.1, 0),
		SightMount = CFrame.new(0, 0.1, 0),
		BarrelMount = CFrame.new(0, 0, -handle.Size.Z/2)
	}

	for name, cframe in pairs(attachments) do
		local attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.CFrame = cframe
		attachment.Parent = handle
	end

	return model
end

-- Equip a weapon from a slot
function FPSFramework:equipWeapon(slot)
	local weaponData = self.weaponSlots[slot]
	if not weaponData then
		warn("No weapon in slot: " .. slot)
		return
	end

	-- Update current weapon
	self.currentWeapon = weaponData
	self.isAiming = false

	-- Update viewmodel
	if self.systems[SYSTEM_NAMES.VIEWMODEL] then
		self.systems[SYSTEM_NAMES.VIEWMODEL]:equipWeapon(weaponData.model, slot)
	end

	-- Update firing system
	if self.systems[SYSTEM_NAMES.FIRING] then
		self.systems[SYSTEM_NAMES.FIRING]:setWeapon(weaponData.model, weaponData.config)
	end

	-- Update crosshair
	if self.systems[SYSTEM_NAMES.CROSSHAIR] then
		self.systems[SYSTEM_NAMES.CROSSHAIR]:updateFromWeaponState(weaponData.config, false)
	end

	-- Notify server
	if self.remoteEvents.WeaponEquipped then
		self.remoteEvents.WeaponEquipped:FireServer(slot, weaponData.name)
	end

	print("Equipped " .. weaponData.name)
end

-- Start the render loop
function FPSFramework:startRenderLoop()
	-- Connect to RenderStepped for smooth updates
	RunService.RenderStepped:Connect(function(deltaTime)
		self:update(deltaTime)
	end)

	print("Render loop started")
end

-- Main update function
function FPSFramework:update(deltaTime)
	-- Update subsystems that need per-frame updates
	if not self.initialized then return end

	-- Update movement state for crosshair
	self:updateMovementState()

	-- Add other update steps as needed
end

-- Update player movement state
function FPSFramework:updateMovementState()
	local isMoving = false
	local character = self.player.Character

	if character and character:FindFirstChild("Humanoid") then
		local humanoid = character.Humanoid
		isMoving = humanoid.MoveDirection.Magnitude > 0.1

		-- Update crosshair with movement state
		if self.systems[SYSTEM_NAMES.CROSSHAIR] then
			self.systems[SYSTEM_NAMES.CROSSHAIR]:setMovementState("moving", isMoving)
			self.systems[SYSTEM_NAMES.CROSSHAIR]:setMovementState("jumping", humanoid:GetState() == Enum.HumanoidStateType.Jumping)
			self.systems[SYSTEM_NAMES.CROSSHAIR]:setMovementState("crouching", self.isCrouching)
		end
	end
end

-- Handle aiming state
function FPSFramework:setAiming(isAiming)
	self.isAiming = isAiming

	-- Update viewmodel
	if self.systems[SYSTEM_NAMES.VIEWMODEL] then
		self.systems[SYSTEM_NAMES.VIEWMODEL]:setAiming(isAiming)
	end

	-- Update camera
	if self.systems[SYSTEM_NAMES.CAMERA] then
		self.systems[SYSTEM_NAMES.CAMERA]:setAiming(isAiming)
	end

	-- Update crosshair
	if self.systems[SYSTEM_NAMES.CROSSHAIR] and self.currentWeapon then
		self.systems[SYSTEM_NAMES.CROSSHAIR]:updateFromWeaponState(self.currentWeapon.config, isAiming)
	end

	return true
end

-- Handle sprinting state
function FPSFramework:setSprinting(isSprinting)
	-- Can't sprint while aiming
	if isSprinting and self.isAiming then
		return false
	end

	self.isSprinting = isSprinting

	-- Update viewmodel
	if self.systems[SYSTEM_NAMES.VIEWMODEL] then
		self.systems[SYSTEM_NAMES.VIEWMODEL]:setSprinting(isSprinting)
	end

	-- Update camera
	if self.systems[SYSTEM_NAMES.CAMERA] then
		self.systems[SYSTEM_NAMES.CAMERA]:setSprinting(isSprinting)
	end

	return true
end

-- Handle crouching state
function FPSFramework:setCrouching(isCrouching)
	self.isCrouching = isCrouching

	-- Update character
	local character = self.player.Character
	if character and character:FindFirstChild("Humanoid") then
		-- Toggle between standing and crouching height
		if isCrouching then
			character.Humanoid.CameraOffset = Vector3.new(0, -1, 0)
			character.Humanoid.WalkSpeed = 8 -- Reduced speed when crouched
		else
			character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
			character.Humanoid.WalkSpeed = 16 -- Normal speed
		end
	end

	return true
end

-- Fire the current weapon
function FPSFramework:fireWeapon(isPressed)
	if not self.currentWeapon then return false end

	local slot = self:getCurrentWeaponSlot()

	if slot == "PRIMARY" or slot == "SECONDARY" then
		-- Handle gun firing
		if self.systems[SYSTEM_NAMES.FIRING] then
			return self.systems[SYSTEM_NAMES.FIRING]:handleFiring(isPressed)
		end
	elseif slot == "MELEE" and isPressed then
		-- Handle melee attack
		if self.systems[SYSTEM_NAMES.MELEE] then
			return self.systems[SYSTEM_NAMES.MELEE]:attack()
		end
	elseif slot == "GRENADES" then
		-- Handle grenade
		if self.systems[SYSTEM_NAMES.GRENADE] then
			if isPressed then
				return self.systems[SYSTEM_NAMES.GRENADE]:startCooking()
			else
				return self.systems[SYSTEM_NAMES.GRENADE]:stopCooking(true) -- Throw
			end
		end
	end

	return false
end

-- Handle reload action
function FPSFramework:reloadWeapon()
	if not self.currentWeapon then return false end

	local slot = self:getCurrentWeaponSlot()

	if (slot == "PRIMARY" or slot == "SECONDARY") and self.systems[SYSTEM_NAMES.FIRING] then
		return self.systems[SYSTEM_NAMES.FIRING]:reload()
	end

	return false
end

-- Get current weapon slot
function FPSFramework:getCurrentWeaponSlot()
	if not self.currentWeapon then return nil end

	for slot, weaponData in pairs(self.weaponSlots) do
		if weaponData == self.currentWeapon then
			return slot
		end
	end

	return nil
end

-- Clean up and destroy framework
function FPSFramework:destroy()
	-- Clean up systems in reverse creation order
	for systemName, system in pairs(self.systems) do
		if typeof(system) == "table" and typeof(system.cleanup) == "function" then
			system:cleanup()
		end
	end

	-- Clear all systems
	self.systems = {}
	self.initialized = false

	print("FPS Framework cleaned up")
end

return FPSFramework