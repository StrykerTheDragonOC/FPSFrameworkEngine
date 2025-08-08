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
	attachments = nil,
	movement = nil,
	damage = nil
}

-- System settings
local settings = {
	defaultWeapon = "G36",
	enableDebug = false
}

-- Current state
local state = {
	currentWeapon = nil,
	currentSlot = "PRIMARY",
	isAiming = false,
	isSprinting = false,
	isReloading = false,
	attachmentModeActive = false,
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
	toggleDebug = Enum.KeyCode.P,
	toggleAttachments = Enum.KeyCode.T,
	spotEnemy = Enum.KeyCode.Q
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
		self:initMovementSystem()
		self:initDamageSystem()

		-- Load default weapons into slots
		self:loadDefaultWeapons()

		-- Set up input handlers
		self:setupInputHandlers()

		-- Debug mode disabled (debugger module removed)

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
		attachments = "AttachmentSystem",
		movement = "AdvancedMovementSystem",
		damage = "DamageSystem"
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

-- Initialize movement system
function FPSController:initMovementSystem()
	local AdvancedMovementSystem = self:requireModule("AdvancedMovementSystem")
	if not AdvancedMovementSystem then
		warn("AdvancedMovementSystem module not found")
		return false
	end

	systems.movement = AdvancedMovementSystem.new()
	print("Movement system initialized")
	return true
end

-- Initialize damage system
function FPSController:initDamageSystem()
	local DamageSystem = self:requireModule("DamageSystem")
	if not DamageSystem then
		warn("DamageSystem module not found")
		return false
	end

	systems.damage = DamageSystem.new()
	print("Damage system initialized (test rigs handled by server)")
	return true
end

-- Debugger removed

-----------------
-- WEAPON MANAGEMENT
-----------------

-- Load default weapons into slots
function FPSController:loadDefaultWeapons()
	-- Load primary weapon (G36)
	self:loadWeapon("PRIMARY", settings.defaultWeapon)

	-- Load secondary weapon (M9)
	self:loadWeapon("SECONDARY", "M9")

	-- Load melee weapon (PocketKnife)
	self:loadWeapon("MELEE", "PocketKnife")

	-- Load grenade (M67)
	self:loadWeapon("GRENADE", "M67")

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
	
	-- First try to find the weapon model using WeaponManager
	if systems.weapons and systems.weapons.findWeaponModel then
		weaponModel = systems.weapons.findWeaponModel(weaponName, slot)
	end
	
	-- If no model found, create a placeholder for now
	if not weaponModel then
		print("No weapon model found for " .. weaponName .. ", creating placeholder")
		weaponModel = self:createPlaceholderWeapon(slot, weaponName)
	else
		print("Found weapon model for " .. weaponName)
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
            displayName = "G36",
            description = "Standard PDW with balanced stats",
            category = WeaponConfig.Categories.PRIMARY,
            type = WeaponConfig.Types.SMG,

            -- Basic Stats
            damage = 25,
            firerate = 600, -- Rounds per minute
            velocity = 1000, -- Bullet velocity

            -- Damage Range
            damageRanges = {
                {distance = 0, damage = 25},
                {distance = 50, damage = 22},
                {distance = 100, damage = 18},
                {distance = 150, damage = 15}
            },

            -- Recoil Properties
            recoil = {
                vertical = 1.2,     -- Vertical kick
                horizontal = 0.3,   -- Horizontal sway
                recovery = 0.95,    -- Recovery rate
                initial = 0.8,      -- First shot recoil multiplier
                maxRising = 8.0,    -- Maximum vertical rise before pattern changes
                pattern = "rising"  -- Recoil pattern (rising, random, diagonal)
            },

            -- Spread/Accuracy
            spread = {
                base = 1.0,          -- Base spread multiplier
                moving = 1.5,        -- Multiplier when moving
                jumping = 2.5,       -- Multiplier when jumping
                sustained = 0.1,     -- Added spread per continuous shot
                maxSustained = 2.0,  -- Maximum sustained fire spread
                recovery = 0.95      -- Recovery rate (lower is faster)
            },

            -- Mobility
            mobility = {
                adsSpeed = 0.3,      -- ADS time in seconds
                walkSpeed = 14,      -- Walking speed
                sprintSpeed = 20,    -- Sprint speed
                equipTime = 0.4,     -- Weapon draw time
                aimWalkMult = 0.8    -- Movement speed multiplier when aiming
            },

            -- Magazine
            magazine = {
                size = 30,           -- Rounds per magazine
                maxAmmo = 120,       -- Maximum reserve ammo
                reloadTime = 2.5,    -- Regular reload time
                reloadTimeEmpty = 3.0, -- Reload time when empty (bolt catch)
                ammoType = "5.56x45mm"
            },

            -- Advanced Ballistics
            penetration = 1.5,       -- Material penetration power (multiplier)
            bulletDrop = 0.1,        -- Bullet drop factor

            -- Firing Mode
            firingMode = WeaponConfig.FiringModes.FULL_AUTO,
            burstCount = 3,          -- For burst mode

            -- Attachments Support
            attachments = {
                sights = true,
                barrels = true,
                underbarrel = true,
                other = true,
                ammo = true
            },

            -- Scope/Sights
            defaultSight = "IronSight", -- Default sight type
            scopePositioning = CFrame.new(0, 0.05, 0.2), -- Fine-tuning of ADS position

            -- Visual Effects
            muzzleFlash = {
                size = 1.0,
                brightness = 1.0,
                color = Color3.fromRGB(255, 200, 100)
            },

            tracers = {
                enabled = true,
                color = Color3.fromRGB(255, 180, 100),
                width = 0.05,
                frequency = 3 -- Show tracer every X rounds
            },

            -- Audio
            sounds = {
                fire = "rbxassetid://4759267374",
                reload = "rbxassetid://799954844",
                reloadEmpty = "rbxassetid://799954844",
                equip = "rbxassetid://83331726258332",
                empty = "rbxassetid://91170486"
            },

            -- Crosshair
            crosshair = {
                style = WeaponConfig.CrosshairStyles.DEFAULT,
                size = 4,
                thickness = 2,
                dot = false,
                color = Color3.fromRGB(255, 255, 255)
            },

            -- Animation IDs (if using custom animations)
            animations = {
                idle = "rbxassetid://82993551235368",
                fire = "rbxassetid://9949926480",
                reload = "rbxassetid://9949926480",
                reloadEmpty = "rbxassetid://9949926480",
                equip = "rbxassetid://9949926480",
                sprint = "rbxassetid://9949926480"
            }
        },
        M9 = {
            name = "M9",
            displayName = "M9",
            description = "Standard semi-automatic pistol",
            category = WeaponConfig.Categories.SECONDARY,
            type = WeaponConfig.Types.PISTOL,

            -- Basic Stats
            damage = 25,
            firerate = 450, -- Rounds per minute
            velocity = 550, -- Bullet velocity

            -- Damage Range
            damageRanges = {
                {distance = 0, damage = 25},
                {distance = 20, damage = 20},
                {distance = 40, damage = 15}
            },

            -- Recoil Properties
            recoil = {
                vertical = 1.5,      -- Vertical kick
                horizontal = 0.8,    -- Horizontal sway
                recovery = 0.9,      -- Recovery rate
                initial = 1.0        -- First shot recoil multiplier
            },

            -- Spread/Accuracy
            spread = {
                base = 1.2,          -- Base spread multiplier
                moving = 1.3,        -- Multiplier when moving
                jumping = 2.0,       -- Multiplier when jumping
                recovery = 0.9       -- Recovery rate (lower is faster)
            },

            -- Mobility
            mobility = {
                adsSpeed = 0.2,      -- ADS time in seconds
                walkSpeed = 15,      -- Walking speed
                sprintSpeed = 21     -- Sprint speed
            },

            -- Magazine
            magazine = {
                size = 15,           -- Rounds per magazine
                maxAmmo = 9000,        -- Maximum reserve ammo
                reloadTime = 1.8,    -- Regular reload time
                reloadTimeEmpty = 2.2 -- Reload time when empty (slide lock)
            },

            -- Advanced Ballistics
            penetration = 0.8,       -- Material penetration power
            bulletDrop = 0.15,       -- Bullet drop factor

            -- Firing Mode
            firingMode = WeaponConfig.FiringModes.SEMI_AUTO,

            -- Attachments Support
            attachments = {
                sights = true,
                barrels = true,
                underbarrel = false,
                other = true,
                ammo = true
            },

            -- Visual Effects
            muzzleFlash = {
                size = 0.8,
                brightness = 1.0,
                color = Color3.fromRGB(255, 200, 100)
            },

            tracers = {
                enabled = true,
                color = Color3.fromRGB(255, 180, 100),
                width = 0.04,
                frequency = 3 -- Show tracer every X rounds
            },

            -- Audio
            sounds = {
                fire = "rbxassetid://3398620209",
                reload = "rbxassetid://6805664397",
                reloadEmpty = "rbxassetid://6842081192",
                equip = "rbxassetid://6805664253",
                empty = "rbxassetid://3744371342"
            },

            -- Crosshair
            crosshair = {
                style = WeaponConfig.CrosshairStyles.DEFAULT,
                size = 4,
                thickness = 2,
                dot = true,
                color = Color3.fromRGB(255, 255, 255)
            }
        },

        Knife = {
            name = "Knife",
            displayName = "Combat Knife",
            description = "Standard combat knife for close quarters",
            category = WeaponConfig.Categories.MELEE,
            type = WeaponConfig.Types.BLADEONEHAND,

            -- Damage
            damage = 55,           -- Front damage
            backstabDamage = 100,  -- Backstab damage

            -- Attack properties
            attackRate = 1.5,      -- Attacks per second
            attackDelay = 0.1,     -- Delay before damage registers
            attackRange = 3.0,     -- Range in studs
            attackType = "stab",   -- stab or slash

            -- Mobility
            mobility = {
                walkSpeed = 16,    -- Walking speed
                sprintSpeed = 22,  -- Sprint speed
                equipTime = 0.2    -- Weapon draw time
            },

            -- Audio
            sounds = {
                swing = "rbxassetid://5810753638",
                hit = "rbxassetid://3744370687",
                hitCritical = "rbxassetid://3744371342",
                equip = "rbxassetid://6842081192"
            },

            -- Handling
            canBlock = false,      -- Can block attacks
            blockDamageReduction = 0.5, -- Damage reduction when blocking

            -- Animations
            animations = {
                idle = "rbxassetid://9949926480",
                attack = "rbxassetid://9949926480",
                attackAlt = "rbxassetid://9949926480",
                equip = "rbxassetid://9949926480",
                sprint = "rbxassetid://9949926480"
            },

            -- Crosshair
            crosshair = {
                style = WeaponConfig.CrosshairStyles.DOT,
                size = 2,
                thickness = 2,
                dot = true,
                color = Color3.fromRGB(255, 255, 255)
            }
        },
        FragGrenade = {
            name = "FragGrenade",
            displayName = "Frag Grenade",
            description = "Standard fragmentation grenade",
            category = WeaponConfig.Categories.GRENADES,
            type = WeaponConfig.Types.EXPLOSIVE,

            -- Damage
            damage = 100,            -- Maximum damage
            damageRadius = 10,       -- Full damage radius
            maxRadius = 20,          -- Maximum effect radius
            falloffType = "linear",  -- How damage decreases with distance

            -- Throw properties
            throwForce = 50,         -- Base throw force
            throwForceCharged = 80,  -- Max throw force (when held)
            throwChargeTime = 1.0,   -- Time to reach max throw

            -- Explosion properties
            fuseTime = 3.0,          -- Time until detonation
            bounciness = 0.15,        -- How bouncy the grenade is

            -- Effects
            effects = {
                explosion = {
                    size = 3.0,
                    particles = 30,
                    light = true,
                    lightBrightness = 1.0,
                    lightRange = 20
                },
                cookingIndicator = true -- Show visual indicator when cooking
            },

            -- Mobility
            mobility = {
                walkSpeed = 15,     -- Walking speed
                sprintSpeed = 21,   -- Sprint speed
                equipTime = 0.3     -- Weapon draw time
            },

            -- Audio
            sounds = {
                throw = "rbxassetid://5564314786",
                bounce = "rbxassetid://6842081192",
                explosion = "rbxassetid://2814355743",
                pin = "rbxassetid://8186569638"
            },

            -- Inventory
            maxCount = 2,           -- Maximum number player can carry

            -- Animations
            animations = {
                idle = "rbxassetid://9949926480",
                throw = "rbxassetid://9949926480",
                equip = "rbxassetid://9949926480",
                sprint = "rbxassetid://9949926480",
                cooking = "rbxassetid://9949926480"
            },

            -- Trajectory visualization
            trajectory = {
                enabled = true,
                pointCount = 30,
                lineColor = Color3.fromRGB(255, 100, 100),
                showOnRightClick = true
            },

            -- Crosshair
            crosshair = {
                style = WeaponConfig.CrosshairStyles.CIRCLE,
                size = 4,
                thickness = 2,
                dot = true,
                color = Color3.fromRGB(255, 255, 255)
            }
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
	
	-- T key (toggle attachments)
	elseif input.KeyCode == inputActions.toggleAttachments then
		self:toggleAttachmentMode()
	
	-- Q key (spot enemy)
	elseif input.KeyCode == inputActions.spotEnemy then
		self:handleSpotting()
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
	-- Don't handle firing when in attachment mode
	if state.attachmentModeActive then
		return
	end
	
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

-- Toggle attachment mode
function FPSController:toggleAttachmentMode()
	state.attachmentModeActive = not state.attachmentModeActive
	
	if state.attachmentModeActive then
		-- Unlock mouse for attachment selection
		if _G.FPSCameraMouseControl then
			_G.FPSCameraMouseControl.unlockMouse()
		end
		print("Attachment mode activated - mouse unlocked")
		
		-- Stop firing if currently firing
		if systems.firing then
			systems.firing:handleFiring(false)
		end
		
		-- TODO: Create attachment UI when implemented
		print("Attachment UI would open here - not yet implemented")
		
	else
		-- Lock mouse back
		if _G.FPSCameraMouseControl then
			_G.FPSCameraMouseControl.lockMouse()
		end
		print("Attachment mode deactivated - mouse locked")
		
		-- TODO: Close attachment UI when implemented
	end
end

-- Handle enemy spotting
function FPSController:handleSpotting()
	-- Cast a ray from camera to spot enemies
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	
	if raycastResult then
		local hit = raycastResult.Instance
		local character = hit.Parent
		
		-- Check if we hit a player character
		if character:FindFirstChild("Humanoid") then
			local targetPlayer = Players:GetPlayerFromCharacter(character)
			if targetPlayer then
				print("Spotted player:", targetPlayer.Name, "at", raycastResult.Position)
				-- TODO: Implement actual spotting mechanics (markers, etc.)
			else
				-- Check if it's a test rig
				if character.Name:find("TestRig") then
					print("Spotted test rig:", character.Name, "at", raycastResult.Position)
					-- TODO: Add test rig spotting visual
				end
			end
		end
	end
end

-- Expose globally for other scripts
_G.FPSController = FPSController
_G.FPSController.state = state
_G.FPSController.systems = systems

-- Initialize the controller when the character loads
if player.Character then
	FPSController:init()
else
	player.CharacterAdded:Connect(function()
		FPSController:init()
	end)
end

return FPSController
