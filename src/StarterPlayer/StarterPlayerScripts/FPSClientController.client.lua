-- FPSClientController.lua
-- Main client controller for FPS framework
-- Place this in StarterPlayerScripts

local FPSController = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Local player reference
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- System instances
local systems = {
	viewmodel = nil,
	weapons = nil,
	firing = nil,
	crosshair = nil,
	effects = nil,
	grenades = nil,
	melee = nil,
	camera = nil,
	attachments = nil
}

-- System settings
local settings = {
	defaultWeapon = "G36",
	enableDebug = true
}

-- Current state
local state = {
	currentWeapon = nil,
	currentSlot = "PRIMARY",
	isAiming = false,
	isSprinting = false,
	isReloading = false,
	slots = {
		PRIMARY = nil,
		SECONDARY = nil,
		MELEE = nil,
		GRENADE = nil
	}
}

-- Input mappings
local inputActions = {
	primaryFire = Enum.UserInputType.MouseButton1,
	aim = Enum.UserInputType.MouseButton2,
	reload = Enum.KeyCode.R,
	sprint = Enum.KeyCode.LeftShift,
	weaponPrimary = Enum.KeyCode.One,
	weaponSecondary = Enum.KeyCode.Two,
	weaponMelee = Enum.KeyCode.Three,
	weaponGrenade = Enum.KeyCode.Four,
	throwGrenade = Enum.KeyCode.G,
	toggleDebug = Enum.KeyCode.P
}

-- Remote events
local remotes = {
	weaponFired = nil,
	weaponHit = nil,
	weaponReload = nil
}

-----------------
-- CORE FUNCTIONS
-----------------

-- Initialize the system
function FPSController:init()
	print("Initializing FPS Controller...")

	-- Ensure required folders exist
	self:ensureFolders()

	-- Set up remote events
	self:setupRemoteEvents()

	-- Load all required modules
	self:loadSystems()

	-- Initialize the viewmodel system first
	if self:initViewmodelSystem() then
		-- Initialize remaining systems in order
		self:initWeaponSystem()
		self:initFiringSystem()
		self:initCrosshairSystem()
		self:initEffectsSystem()
		self:initGrenadeSystem()
		self:initMeleeSystem()
		self:initCameraSystem()
		self:initAttachmentSystem()

		-- Load default weapons into slots
		self:loadDefaultWeapons()

		-- Set up input handlers
		self:setupInputHandlers()

		-- Initialize debugger if enabled
		if settings.enableDebug then
			self:initDebugger()
		end

		print("FPS Controller initialization complete!")
		return true
	else
		warn("Failed to initialize viewmodel system - aborting FPS Controller initialization")
		return false
	end
end

-- Ensure required folders exist in ReplicatedStorage
function FPSController:ensureFolders()
	local folderStructure = {
		FPSSystem = {
			"Modules",
			"Effects",
			"ViewModels",
			"WeaponModels",
			"Animations",
			"Config",
			"RemoteEvents"
		}
	}

	-- Create top-level folders
	for folderName, subfolders in pairs(folderStructure) do
		local folder = ReplicatedStorage:FindFirstChild(folderName)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = ReplicatedStorage
			print("Created folder:", folderName)
		end

		-- Create subfolders
		for _, subfolderName in ipairs(subfolders) do
			local subfolder = folder:FindFirstChild(subfolderName)
			if not subfolder then
				subfolder = Instance.new("Folder")
				subfolder.Name = subfolderName
				subfolder.Parent = folder
				print("Created subfolder:", folderName.."/"..subfolderName)
			end
		end
	end
end

-- Set up remote events
function FPSController:setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")

	-- Create or get weapon fired event
	remotes.weaponFired = remoteEventsFolder:FindFirstChild("WeaponFired")
	if not remotes.weaponFired then
		remotes.weaponFired = Instance.new("RemoteEvent")
		remotes.weaponFired.Name = "WeaponFired"
		remotes.weaponFired.Parent = remoteEventsFolder
	end

	-- Create or get weapon hit event
	remotes.weaponHit = remoteEventsFolder:FindFirstChild("WeaponHit")
	if not remotes.weaponHit then
		remotes.weaponHit = Instance.new("RemoteEvent")
		remotes.weaponHit.Name = "WeaponHit"
		remotes.weaponHit.Parent = remoteEventsFolder
	end

	-- Create or get weapon reload event
	remotes.weaponReload = remoteEventsFolder:FindFirstChild("WeaponReload")
	if not remotes.weaponReload then
		remotes.weaponReload = Instance.new("RemoteEvent")
		remotes.weaponReload.Name = "WeaponReload"
		remotes.weaponReload.Parent = remoteEventsFolder
	end
end

-- Safely require a module
function FPSController:requireModule(name)
	local modulesFolder = ReplicatedStorage.FPSSystem.Modules
	local moduleScript = modulesFolder:FindFirstChild(name)

	if not moduleScript then
		warn("Module not found:", name)
		return nil
	end

	local success, module = pcall(function()
		return require(moduleScript)
	end)

	if success then
		return module
	else
		warn("Failed to require module:", name, module)
		return nil
	end
end

-- Load all systems
function FPSController:loadSystems()
	local requiredSystems = {
		viewmodel = "ViewmodelSystem",
		weapons = "WeaponManager",
		firing = "WeaponFiringSystem",
		crosshair = "CrosshairSystem",
		effects = "FPSEffectsSystem",
		grenades = "GrenadeSystem",
		melee = "MeleeSystem",
		camera = "FPSCamera",
		attachments = "AttachmentSystem"
	}

	for key, moduleName in pairs(requiredSystems) do
		local module = self:requireModule(moduleName)
		if module then
			print("Loaded system:", moduleName)
		else
			warn("Failed to load system:", moduleName)
		end
	end
end

-----------------
-- SYSTEM INITIALIZERS
-----------------

-- Initialize the viewmodel system
function FPSController:initViewmodelSystem()
	local ViewmodelSystem = self:requireModule("ViewmodelSystem")
	if not ViewmodelSystem then
		warn("ViewmodelSystem module not found")
		return false
	end

	-- Create viewmodel instance
	systems.viewmodel = ViewmodelSystem.new()
	if not systems.viewmodel then
		warn("Failed to create ViewmodelSystem instance")
		return false
	end

	-- Set up arms
	systems.viewmodel:setupArms()

	-- Start the update loop
	systems.viewmodel:startUpdateLoop()

	print("Viewmodel system initialized")
	return true
end

-- Initialize weapon system
function FPSController:initWeaponSystem()
	local WeaponManager = self:requireModule("WeaponManager")
	if not WeaponManager then
		warn("WeaponManager module not found")
		return false
	end

	systems.weapons = WeaponManager
	print("Weapon system initialized")
	return true
end

-- Initialize firing system
function FPSController:initFiringSystem()
	local WeaponFiringSystem = self:requireModule("WeaponFiringSystem")
	if not WeaponFiringSystem then
		warn("WeaponFiringSystem module not found")
		return false
	end

	systems.firing = WeaponFiringSystem.new(systems.viewmodel)
	print("Firing system initialized")
	return true
end

-- Initialize crosshair system
function FPSController:initCrosshairSystem()
	local CrosshairSystem = self:requireModule("CrosshairSystem")
	if not CrosshairSystem then
		warn("CrosshairSystem module not found")
		return false
	end

	systems.crosshair = CrosshairSystem.new()
	print("Crosshair system initialized")
	return true
end

-- Initialize effects system
function FPSController:initEffectsSystem()
	local FPSEffectsSystem = self:requireModule("FPSEffectsSystem")
	if not FPSEffectsSystem then
		warn("FPSEffectsSystem module not found")
		return false
	end

	systems.effects = FPSEffectsSystem.new()
	print("Effects system initialized")
	return true
end

-- Initialize grenade system
function FPSController:initGrenadeSystem()
	local GrenadeSystem = self:requireModule("GrenadeSystem")
	if not GrenadeSystem then
		warn("GrenadeSystem module not found")
		return false
	end

	systems.grenades = GrenadeSystem.new(systems.viewmodel)
	print("Grenade system initialized")
	return true
end

-- Initialize melee system
function FPSController:initMeleeSystem()
	local MeleeSystem = self:requireModule("MeleeSystem")
	if not MeleeSystem then
		warn("MeleeSystem module not found")
		return false
	end

	systems.melee = MeleeSystem.new(systems.viewmodel)
	print("Melee system initialized")
	return true
end

-- Initialize camera system
function FPSController:initCameraSystem()
	local FPSCamera = self:requireModule("FPSCamera")
	if not FPSCamera then
		warn("FPSCamera module not found")
		return false
	end

	systems.camera = FPSCamera.new()
	print("Camera system initialized")
	return true
end

-- Initialize attachment system
function FPSController:initAttachmentSystem()
	local AttachmentSystem = self:requireModule("AttachmentSystem")
	if not AttachmentSystem then
		warn("AttachmentSystem module not found")
		return false
	end

	systems.attachments = AttachmentSystem
	print("Attachment system initialized")
	return true
end

-- Initialize debugger
function FPSController:initDebugger()
	local ViewmodelOffsetDebugger = self:requireModule("ViewmodelOffsetDebugger")
	if not ViewmodelOffsetDebugger then
		warn("ViewmodelOffsetDebugger module not found")
		return false
	end

	local debugger = ViewmodelOffsetDebugger:init()
	if debugger then
		-- Inject debugger into viewmodel system
		ViewmodelOffsetDebugger:injectIntoViewmodelSystem(systems.viewmodel)
		print("Debugger initialized - press P to toggle")
	end

	return true
end

-----------------
-- WEAPON MANAGEMENT
-----------------

-- Load default weapons into slots
function FPSController:loadDefaultWeapons()
	-- Load primary weapon (G36)
	self:loadWeapon("PRIMARY", settings.defaultWeapon)

	-- Load secondary weapon (Pistol)
	self:loadWeapon("SECONDARY", "Pistol")

	-- Load melee weapon
	self:loadWeapon("MELEE", "Knife")

	-- Load grenade
	self:loadWeapon("GRENADE", "FragGrenade")

	-- Equip the primary weapon by default
	self:equipWeapon("PRIMARY")
end

-- Load a weapon into a slot
function FPSController:loadWeapon(slot, weaponName)
	if not systems.weapons then
		warn("Cannot load weapon: Weapon system not initialized")
		return
	end

	-- Load the weapon model
	local weaponModel

	-- Try to use weapons system to load model
	if typeof(systems.weapons.loadWeapon) == "function" then
		weaponModel = systems.weapons.loadWeapon(weaponName, slot)
	elseif slot == "PRIMARY" and typeof(systems.weapons.getG36) == "function" and weaponName == "G36" then
		weaponModel = systems.weapons.getG36()
	else
		-- Fallback to create a placeholder
		weaponModel = self:createPlaceholderWeapon(slot, weaponName)
	end

	if not weaponModel then
		warn("Failed to load weapon:", weaponName)
		return
	end

	-- Store in slot
	state.slots[slot] = {
		name = weaponName,
		model = weaponModel,
		config = self:getWeaponConfig(weaponName)
	}

	print("Loaded", weaponName, "into", slot, "slot")
end

-- Create a placeholder weapon model
function FPSController:createPlaceholderWeapon(slot, weaponName)
	print("Creating placeholder weapon for", slot, weaponName)

	local model = Instance.new("Model")
	model.Name = weaponName

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = true
	handle.CanCollide = false

	-- Configure based on weapon type
	if slot == "PRIMARY" then
		handle.Size = Vector3.new(0.4, 0.3, 2)
		handle.Color = Color3.fromRGB(60, 60, 60)

		-- Add barrel
		local barrel = Instance.new("Part")
		barrel.Name = "Barrel"
		barrel.Size = Vector3.new(0.15, 0.15, 0.8)
		barrel.Color = Color3.fromRGB(40, 40, 40)
		barrel.CFrame = handle.CFrame * CFrame.new(0, 0, -handle.Size.Z/2 - barrel.Size.Z/2)
		barrel.Anchored = true
		barrel.CanCollide = false
		barrel.Parent = model

		-- Add muzzle attachment
		local muzzlePoint = Instance.new("Attachment")
		muzzlePoint.Name = "MuzzlePoint"
		muzzlePoint.Position = Vector3.new(0, 0, -barrel.Size.Z/2)
		muzzlePoint.Parent = barrel

	elseif slot == "SECONDARY" then
		handle.Size = Vector3.new(0.3, 0.2, 0.8)
		handle.Color = Color3.fromRGB(40, 40, 40)

		-- Add barrel
		local barrel = Instance.new("Part")
		barrel.Name = "Barrel"
		barrel.Size = Vector3.new(0.1, 0.1, 0.4)
		barrel.Color = Color3.fromRGB(30, 30, 30)
		barrel.CFrame = handle.CFrame * CFrame.new(0, 0, -handle.Size.Z/2 - barrel.Size.Z/2)
		barrel.Anchored = true
		barrel.CanCollide = false
		barrel.Parent = model

		-- Add muzzle attachment
		local muzzlePoint = Instance.new("Attachment")
		muzzlePoint.Name = "MuzzlePoint"
		muzzlePoint.Position = Vector3.new(0, 0, -barrel.Size.Z/2)
		muzzlePoint.Parent = barrel

	elseif slot == "MELEE" then
		handle.Size = Vector3.new(0.2, 0.8, 0.2)
		handle.Color = Color3.fromRGB(50, 50, 50)

		-- Add blade
		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(0.05, 0.8, 0.3)
		blade.Color = Color3.fromRGB(180, 180, 180)
		blade.CFrame = handle.CFrame * CFrame.new(0, 0.8, 0)
		blade.Anchored = true
		blade.CanCollide = false
		blade.Parent = model

	elseif slot == "GRENADE" then
		handle.Size = Vector3.new(0.3, 0.3, 0.3)
		handle.Shape = Enum.PartType.Ball
		handle.Color = Color3.fromRGB(30, 50, 30)
	end

	-- Parent handle to model
	handle.Parent = model
	model.PrimaryPart = handle

	-- Add attachment points
	local attachPoints = {
		RightGripPoint = CFrame.new(0.15, -0.1, 0),
		LeftGripPoint = CFrame.new(-0.15, -0.1, 0),
		AimPoint = CFrame.new(0, 0.1, 0)
	}

	for name, offset in pairs(attachPoints) do
		local attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.CFrame = offset
		attachment.Parent = handle
	end

	return model
end

-- Get weapon configuration
function FPSController:getWeaponConfig(weaponName)
	-- Try to use WeaponConfig if available
	local WeaponConfig = self:requireModule("WeaponConfig")
	if WeaponConfig and WeaponConfig.Weapons and WeaponConfig.Weapons[weaponName] then
		return WeaponConfig.Weapons[weaponName]
	end

	-- Fallback to default configs
	local defaultConfigs = {
		G36 = {
			name = "G36",
			damage = 25,
			fireRate = 600,
			recoil = {
				vertical = 1.2,
				horizontal = 0.3,
				recovery = 0.95
			},
			mobility = {
				adsSpeed = 0.3,
				walkSpeed = 14,
				sprintSpeed = 20
			},
			magazine = {
				size = 30,
				maxAmmo = 120,
				reloadTime = 2.5
			}
		},
		M9 = {
			name = "M9",
			damage = 18,
			fireRate = 400,
			recoil = {
				vertical = 0.9,
				horizontal = 0.4,
				recovery = 0.98
			},
			mobility = {
				adsSpeed = 0.2,
				walkSpeed = 16,
				sprintSpeed = 21
			},
			magazine = {
				size = 12,
				maxAmmo = 60,
				reloadTime = 1.8
			}
		},
		Knife = {
			name = "Knife",
			damage = 55,
			backstabDamage = 100,
			attackRate = 2,
			range = 3
		},
		FragGrenade = {
			name = "FragGrenade",
			damage = 100,
			damageRadius = 15,
			cookTime = 3,
			throwForce = 50
		}
	}

	return defaultConfigs[weaponName] or defaultConfigs.G36
end

-- Equip a weapon from a slot
function FPSController:equipWeapon(slot)
	local weaponData = state.slots[slot]
	if not weaponData then
		warn("No weapon in slot:", slot)
		return
	end

	-- Update current state
	state.currentSlot = slot
	state.currentWeapon = weaponData
	state.isAiming = false

	-- Equip in viewmodel
	if systems.viewmodel then
		systems.viewmodel:equipWeapon(weaponData.model, slot)
	end

	-- Update crosshair
	if systems.crosshair then
		systems.crosshair:updateFromWeaponState(weaponData.config, false)
	end

	-- Set weapon in firing system
	if systems.firing then
		systems.firing:setWeapon(weaponData.model, weaponData.config)
	end

	print("Equipped", weaponData.name, "from", slot, "slot")
end

-----------------
-- INPUT HANDLING
-----------------

-- Set up input handlers
function FPSController:setupInputHandlers()
	print("Setting up input handlers...")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:handleInputBegan(input)
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:handleInputEnded(input)
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:handleInputChanged(input)
	end)
end

-- Handle when input begins
function FPSController:handleInputBegan(input)
	-- Mouse button 1 (primary fire)
	if input.UserInputType == inputActions.primaryFire then
		self:handlePrimaryFire(true)

		-- Mouse button 2 (aim)
	elseif input.UserInputType == inputActions.aim then
		self:handleAiming(true)

		-- R key (reload)
	elseif input.KeyCode == inputActions.reload then
		self:handleReload()

		-- Left Shift (sprint)
	elseif input.KeyCode == inputActions.sprint then
		self:handleSprinting(true)

		-- Number keys (weapon switching)
	elseif input.KeyCode == inputActions.weaponPrimary then
		self:equipWeapon("PRIMARY")
	elseif input.KeyCode == inputActions.weaponSecondary then
		self:equipWeapon("SECONDARY")
	elseif input.KeyCode == inputActions.weaponMelee then
		self:equipWeapon("MELEE")
	elseif input.KeyCode == inputActions.weaponGrenade then
		self:equipWeapon("GRENADE")

		-- G key (throw grenade)
	elseif input.KeyCode == inputActions.throwGrenade then
		self:handleGrenade()
	end
end

-- Handle when input ends
function FPSController:handleInputEnded(input)
	-- Mouse button 1 (primary fire)
	if input.UserInputType == inputActions.primaryFire then
		self:handlePrimaryFire(false)

		-- Mouse button 2 (aim)
	elseif input.UserInputType == inputActions.aim then
		self:handleAiming(false)

		-- Left Shift (sprint)
	elseif input.KeyCode == inputActions.sprint then
		self:handleSprinting(false)
	end
end

-- Handle mouse movement
function FPSController:handleInputChanged(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		-- Update viewmodel sway
		if systems.viewmodel then
			systems.viewmodel.lastMouseDelta = input.Delta
		end
	end
end

-----------------
-- WEAPON ACTIONS
-----------------

-- Handle primary fire
function FPSController:handlePrimaryFire(isPressed)
	if state.currentSlot == "PRIMARY" or state.currentSlot == "SECONDARY" then
		-- Gun firing
		if systems.firing then
			systems.firing:handleFiring(isPressed)
		end
	elseif state.currentSlot == "MELEE" and isPressed then
		-- Melee attack
		if systems.melee then
			systems.melee:handleMouseButton1(isPressed)
		end
	elseif state.currentSlot == "GRENADE" then
		-- Grenade throw
		if systems.grenades then
			systems.grenades:handleMouseButton1(isPressed)
		end
	end
end

-- Handle aiming
function FPSController:handleAiming(isAiming)
	state.isAiming = isAiming

	if systems.viewmodel then
		systems.viewmodel:setAiming(isAiming)
	end

	if state.currentSlot == "GRENADE" and systems.grenades then
		systems.grenades:handleMouseButton2(isAiming)
	end

	if systems.crosshair then
		systems.crosshair:updateFromWeaponState(state.currentWeapon.config, isAiming)
	end
end

-- Handle sprinting
function FPSController:handleSprinting(isSprinting)
	state.isSprinting = isSprinting

	if systems.viewmodel then
		systems.viewmodel:setSprinting(isSprinting)
	end

	if systems.crosshair then
		systems.crosshair:updateFromWeaponState(state.currentWeapon.config, state.isAiming)
	end
end

-- Handle reloading
function FPSController:handleReload()
	if state.currentSlot ~= "PRIMARY" and state.currentSlot ~= "SECONDARY" then
		return
	end

	if systems.firing then
		systems.firing:reload()
	end
end

-- Handle grenade throw
function FPSController:handleGrenade()
	-- If not currently holding grenade, quickly throw one without switching
	if state.currentSlot ~= "GRENADE" and systems.grenades then
		-- Remember current weapon
		local previousSlot = state.currentSlot

		-- Quickly switch to grenade
		self:equipWeapon("GRENADE")

		-- Start cooking
		systems.grenades:startCooking()

		-- Throw after a short delay
		task.delay(0.5, function()
			systems.grenades:stopCooking(true)

			-- Switch back to previous weapon
			task.delay(0.5, function()
				self:equipWeapon(previousSlot)
			end)
		end)
	end
end

-- Initialize the controller when the character loads
if player.Character then
	FPSController:init()
else
	player.CharacterAdded:Connect(function()
		FPSController:init()
	end)
end

return FPSController