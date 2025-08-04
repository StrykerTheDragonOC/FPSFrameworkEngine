-- Weapon Setup and Management System
local WeaponSetup = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import existing weapon systems
local WeaponBase = require(ReplicatedStorage.FPSSystem.Modules.WeaponBase)
local WeaponModelHandler = require(ReplicatedStorage.FPSSystem.Modules.WeaponModelHandler)
local WeaponConverter = require(ReplicatedStorage.FPSSystem.Modules.WeaponConverter)

-- Weapon Configuration Template
local WEAPON_CONFIGS = {
	G36 = {
		name = "G36",
		type = "AssaultRifle",
		damage = 25,
		fireRate = 600,  -- Rounds per minute
		magazine = {
			size = 30,
			maxAmmo = 120,
			reloadTime = 2.5
		},
		recoil = {
			vertical = 1.2,
			horizontal = 0.3,
			recovery = 0.95
		},
		mobility = {
			adsSpeed = 0.3,
			walkSpeed = 14,
			sprintSpeed = 20
		}
	}
}

-- Grenade Configuration
local GRENADE_CONFIGS = {
	Frag = {
		name = "FragGrenade",
		throwForce = 50,
		explosionRadius = 10,
		damage = 50,
		fuseTime = 3
	}
}

-- Melee Weapon Configurations
local MELEE_CONFIGS = {
	Knife = {
		name = "Combat Knife",
		damage = 50,
		range = 3,
		cooldown = 0.5
	}
}

-- Create a weapon instance
function WeaponSetup.createWeapon(weaponName, category, subcategory)
	-- Load weapon model
	local weaponModel = WeaponModelHandler.loadWeaponFromPath(category, subcategory, weaponName)
	if not weaponModel then
		warn("Failed to load weapon model:", weaponName)
		return nil
	end

	-- Get weapon configuration
	local config = WEAPON_CONFIGS[weaponName]
	if not config then
		warn("No configuration found for weapon:", weaponName)
		config = WEAPON_CONFIGS.G36  -- Fallback to default
	end

	-- Create weapon base instance
	local weapon = WeaponBase.new(config)

	-- Optional: Customize weapon model
	weapon.worldModel = weaponModel
	local convertedModel = WeaponConverter.convertFromCharacter(game.Workspace, weaponName)
	weapon.viewModel = convertedModel and convertedModel.viewModel or nil

	return weapon
end

-- Create a grenade
function WeaponSetup.createGrenade(grenadeName)
	local config = GRENADE_CONFIGS[grenadeName] or GRENADE_CONFIGS.Frag

	-- Create a basic grenade model
	local grenadeModel = Instance.new("Model")
	grenadeModel.Name = config.name

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.5, 0.5)
	handle.Shape = Enum.PartType.Ball
	handle.Color = Color3.fromRGB(50, 50, 50)
	handle.Parent = grenadeModel
	grenadeModel.PrimaryPart = handle

	return {
		model = grenadeModel,
		config = config
	}
end

-- Create a melee weapon
function WeaponSetup.createMeleeWeapon(meleeName)
	local config = MELEE_CONFIGS[meleeName] or MELEE_CONFIGS.Knife

	-- Create a basic melee weapon model
	local meleeModel = Instance.new("Model")
	meleeModel.Name = config.name

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.1, 0.1, 0.5)
	handle.Color = Color3.fromRGB(100, 100, 100)
	handle.Parent = meleeModel
	meleeModel.PrimaryPart = handle

	return {
		model = meleeModel,
		config = config
	}
end

-- Get weapon configuration
function WeaponSetup.getWeaponConfig(weaponName)
	return WEAPON_CONFIGS[weaponName] or WEAPON_CONFIGS.G36
end

return WeaponSetup