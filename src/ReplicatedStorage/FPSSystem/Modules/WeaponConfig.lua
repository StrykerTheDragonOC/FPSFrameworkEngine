-- WeaponConfig.lua
-- Modular weapon configuration system
-- Place in ReplicatedStorage.FPSSystem.Config

local WeaponConfig = {}

-- Weapon Categories
WeaponConfig.Categories = {
	PRIMARY = "PRIMARY",
	SECONDARY = "SECONDARY",
	MELEE = "MELEE",
	GRENADES = "GRENADES"
}

-- Weapon Types
WeaponConfig.Types = {
	ASSAULT_RIFLE = "AssaultRifles",
	SNIPER_RIFLE = "SniperRifles",
	SHOTGUN = "Shotguns",
	SMG = "SMGS",
	LMG = "LMGS",
	DMR = "DMRS",
	PISTOL = "Pistols",
	REVOLVER = "Revolvers",
	MACHINE_PISTOL = "AutomaticPistols",
	CARBINES = "Carbines",
	BLADEONEHAND = "BladeOneHand",
	BLADETWOHAND = "BladeTwoHand",
	BLUNTONEHAND = "BluntOneHand",
	BLUNTTWOHAND = "BluntTwoHand",
	EXPLOSIVE = "Explosive",
	TACTICAL = "Tactical",
	IMPACT = "Impact", 

	
}

-- Firing Modes
WeaponConfig.FiringModes = {
	FULL_AUTO = "FULL_AUTO",
	SEMI_AUTO = "SEMI_AUTO",
	BURST = "BURST",
	BOLT_ACTION = "BOLT_ACTION",
	PUMP_ACTION = "PUMP_ACTION"
}

-- Crosshair Styles
WeaponConfig.CrosshairStyles = {
	DEFAULT = 1,
	DOT = 2,
	CIRCLE = 3,
	CORNERS = 4,
	CHEVRON = 5
}

-- Default Weapons
WeaponConfig.DefaultWeapons = {
	PRIMARY = "G36",
	SECONDARY = "M9",
	MELEE = "Knife",
	GRENADES = "FragGrenade"
}

-- Weapon Definitions
WeaponConfig.Weapons = {
	-- ASSAULT RIFLES
	G36 = {
		name = "G36",
		displayName = "G36",
		description = "Standard assault rifle with balanced stats",
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
			idle = "rbxassetid://110622472219213",
			fire = "rbxassetid://9949926480",
			reload = "rbxassetid://9949926480",
			reloadEmpty = "rbxassetid://9949926480",
			equip = "rbxassetid://9949926480",
			sprint = "rbxassetid://9949926480"
		}
	},

	-- SNIPER RIFLES
	AWP = {
		name = "AWP",
		displayName = "AWP Sniper",
		description = "Powerful bolt-action sniper rifle",
		category = WeaponConfig.Categories.PRIMARY,
		type = WeaponConfig.Types.SNIPER_RIFLE,

		-- Basic Stats
		damage = 100,
		firerate = 50, -- Rounds per minute
		velocity = 2000, -- Bullet velocity

		-- Damage Range
		damageRanges = {
			{distance = 0, damage = 100},
			{distance = 150, damage = 95},
			{distance = 300, damage = 85}
		},

		-- Recoil Properties
		recoil = {
			vertical = 8.0,       -- Vertical kick
			horizontal = 2.0,     -- Horizontal sway
			recovery = 0.9,      -- Recovery rate
			initial = 1.0        -- First shot recoil multiplier
		},

		-- Spread/Accuracy
		spread = {
			base = 0.1,          -- Base spread multiplier
			moving = 4.0,        -- Multiplier when moving
			jumping = 10.0,      -- Multiplier when jumping
			recovery = 0.8       -- Recovery rate (lower is faster)
		},

		-- Mobility
		mobility = {
			adsSpeed = 0.6,      -- ADS time in seconds
			walkSpeed = 12,      -- Walking speed
			sprintSpeed = 16,    -- Sprint speed
			equipTime = 1.2      -- Weapon draw time
		},

		-- Magazine
		magazine = {
			size = 5,           -- Rounds per magazine
			maxAmmo = 25,       -- Maximum reserve ammo
			reloadTime = 3.5,   -- Regular reload time
			reloadTimeEmpty = 3.5, -- Reload time when empty
			ammoType = ".338 Lapua Magnum"
		},

		-- Advanced Ballistics
		penetration = 3.0,       -- Material penetration power
		bulletDrop = 0.04,       -- Bullet drop factor

		-- Firing Mode
		firingMode = WeaponConfig.FiringModes.BOLT_ACTION,

		-- Scope Settings
		scope = {
			defaultZoom = 8.0,    -- Default zoom level
			maxZoom = 10.0,       -- Maximum zoom level
			scopeType = "GUI",    -- "Model" or "GUI"
			scopeImage = "rbxassetid://6918290101", -- Scope overlay image
			scopeRenderScale = 0.8, -- Render scale when scoped (performance)
			scopeBlur = true,      -- Blur around scope
			scopeSensitivity = 0.4, -- Sensitivity multiplier when scoped
			scopeHoldBreath = true, -- Allow hold breath with shift
			holdBreathDuration = 5.0, -- Seconds player can hold breath
			breathRecovery = 0.8    -- Recovery rate after holding breath
		},

		-- Visual Effects
		muzzleFlash = {
			size = 1.5,
			brightness = 1.2,
			color = Color3.fromRGB(255, 200, 100)
		},

		tracers = {
			enabled = true,
			color = Color3.fromRGB(255, 180, 100),
			width = 0.07,
			frequency = 1 -- Show tracer on every round
		},

		-- Audio
		sounds = {
			fire = "rbxassetid://168143115",
			reload = "rbxassetid://1659380685",
			reloadEmpty = "rbxassetid://1659380685",
			equip = "rbxassetid://4743275867",
			empty = "rbxassetid://3744371342",
			boltAction = "rbxassetid://3599663417"
		},

		-- Crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.DOT,
			size = 2,
			thickness = 2,
			dot = true,
			color = Color3.fromRGB(0, 255, 0),
			hideWhenADS = true
		}
	},

	-- PISTOLS
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

	-- MELEE WEAPONS
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

	-- GRENADES
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
			throw = "rbxassetid://3744370687",
			bounce = "rbxassetid://6842081192",
			explosion = "rbxassetid://5801257793",
			pin = "rbxassetid://3744370687"
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

-- Attachments Configuration
WeaponConfig.Attachments = {
	-- Sights
	RedDot = {
		name = "Red Dot Sight",
		description = "Improved target acquisition with minimal zoom",
		type = "SIGHT",
		modelId = "rbxassetid://7548348915",
		compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol"},
		statModifiers = {
			adsSpeed = 0.95, -- 5% faster ADS
			recoil = {
				vertical = 0.95, -- 5% less vertical recoil
				horizontal = 0.95 -- 5% less horizontal recoil
			}
		},
		scopeSettings = {
			fov = 65,
			modelBased = true,
			sensitivity = 0.9
		}
	},

	ACOG = {
		name = "ACOG Scope",
		description = "4x magnification scope for medium range",
		type = "SIGHT",
		modelId = "rbxassetid://7548348927",
		compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
		statModifiers = {
			adsSpeed = 0.8, -- 20% slower ADS
			recoil = {
				vertical = 0.9, -- 10% less vertical recoil
				horizontal = 0.9 -- 10% less horizontal recoil
			}
		},
		scopeSettings = {
			fov = 40,
			modelBased = true,
			sensitivity = 0.7
		}
	},

	SniperScope = {
		name = "Sniper Scope",
		description = "8x magnification scope for long range",
		type = "SIGHT",
		modelId = "rbxassetid://7548348940",
		compatibleWeapons = {"AWP", "M24", "Dragunov", "SCAR-H"},
		statModifiers = {
			adsSpeed = 0.7, -- 30% slower ADS
			recoil = {
				vertical = 0.8, -- 20% less vertical recoil
				horizontal = 0.8 -- 20% less horizontal recoil
			}
		},
		scopeSettings = {
			fov = 20,
			modelBased = false, -- Use GUI scope
			guiImage = "rbxassetid://7548348960",
			sensitivity = 0.5
		}
	},

	-- Barrels
	Suppressor = {
		name = "Suppressor",
		description = "Reduces sound and muzzle flash",
		type = "BARREL",
		modelId = "rbxassetid://7548348980",
		compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "AWP"},
		statModifiers = {
			damage = 0.9, -- 10% less damage
			recoil = {
				vertical = 0.85, -- 15% less vertical recoil
				horizontal = 0.9 -- 10% less horizontal recoil
			}
		},
		soundEffects = {
			volume = 0.3, -- 70% quieter
			fire = "rbxassetid://1234567" -- Suppressed fire sound
		},
		visualEffects = {
			muzzleFlash = {
				size = 0.2, -- 80% smaller muzzle flash
				brightness = 0.2
			}
		}
	},

	Compensator = {
		name = "Compensator",
		description = "Reduces horizontal recoil",
		type = "BARREL",
		modelId = "rbxassetid://7548348990",
		compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
		statModifiers = {
			recoil = {
				horizontal = 0.7 -- 30% less horizontal recoil
			}
		}
	},

	-- Underbarrel
	VerticalGrip = {
		name = "Vertical Grip",
		description = "Reduces vertical recoil",
		type = "UNDERBARREL",
		modelId = "rbxassetid://7548349000",
		compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "SCAR-H"},
		statModifiers = {
			recoil = {
				vertical = 0.75 -- 25% less vertical recoil
			},
			adsSpeed = 0.95 -- 5% slower ADS
		}
	},

	AngledGrip = {
		name = "Angled Grip",
		description = "Faster ADS time",
		type = "UNDERBARREL",
		modelId = "rbxassetid://7548349010",
		compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
		statModifiers = {
			adsSpeed = 1.15, -- 15% faster ADS
			recoil = {
				initial = 0.85 -- 15% less initial recoil
			}
		}
	},

	Laser = {
		name = "Laser Sight",
		description = "Improves hipfire accuracy",
		type = "UNDERBARREL",
		modelId = "rbxassetid://7548349020",
		compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "SCAR-H"},
		statModifiers = {
			spread = {
				base = 0.7 -- 30% better hipfire accuracy
			}
		},
		hasLaser = true,
		laserColor = Color3.fromRGB(255, 0, 0)
	},

	-- Ammo Types
	HollowPoint = {
		name = "Hollow Point Rounds",
		description = "More damage to unarmored targets, less penetration",
		type = "AMMO",
		compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "SCAR-H"},
		statModifiers = {
			damage = 1.2, -- 20% more damage
			penetration = 0.6 -- 40% less penetration
		}
	},

	ArmorPiercing = {
		name = "Armor Piercing Rounds",
		description = "Better penetration, slightly less damage",
		type = "AMMO",
		compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H", "AWP"},
		statModifiers = {
			damage = 0.9, -- 10% less damage
			penetration = 1.5 -- 50% more penetration
		}
	}
}

-- Helper functions
function WeaponConfig.getWeapon(weaponName)
	return WeaponConfig.Weapons[weaponName]
end

function WeaponConfig.getAttachment(attachmentName)
	return WeaponConfig.Attachments[attachmentName]
end

function WeaponConfig.isAttachmentCompatible(attachmentName, weaponName)
	local attachment = WeaponConfig.getAttachment(attachmentName)
	if not attachment or not attachment.compatibleWeapons then
		return false
	end

	for _, compatible in ipairs(attachment.compatibleWeapons) do
		if compatible == weaponName then
			return true
		end
	end

	return false
end

function WeaponConfig.applyAttachmentToWeapon(weaponConfig, attachmentName)
	local attachment = WeaponConfig.getAttachment(attachmentName)
	if not attachment or not attachment.statModifiers then
		return weaponConfig
	end

	-- Clone weapon config to avoid modifying the original
	local newConfig = table.clone(weaponConfig)

	-- Apply stat modifiers
	for stat, modifier in pairs(attachment.statModifiers) do
		if type(modifier) == "table" and type(newConfig[stat]) == "table" then
			-- Handle nested tables like recoil
			for subStat, value in pairs(modifier) do
				if newConfig[stat][subStat] then
					newConfig[stat][subStat] = newConfig[stat][subStat] * value
				end
			end
		elseif type(newConfig[stat]) == "number" then
			-- Handle direct number stats
			newConfig[stat] = newConfig[stat] * modifier
		end
	end

	-- Apply scope settings if present
	if attachment.scopeSettings then
		newConfig.scope = attachment.scopeSettings
	end

	-- Apply sound effects if present
	if attachment.soundEffects then
		newConfig.soundEffects = attachment.soundEffects
	end

	-- Apply visual effects if present
	if attachment.visualEffects then
		for effectType, effect in pairs(attachment.visualEffects) do
			if not newConfig[effectType] then
				newConfig[effectType] = {}
			end

			for prop, value in pairs(effect) do
				newConfig[effectType][prop] = value
			end
		end
	end

	-- Add laser if the attachment has one
	if attachment.hasLaser then
		newConfig.hasLaser = true
		newConfig.laserColor = attachment.laserColor or Color3.fromRGB(255, 0, 0)
	end

	return newConfig
end

-- Get all available weapons of a category
function WeaponConfig.getWeaponsByCategory(category)
	local result = {}

	for name, weapon in pairs(WeaponConfig.Weapons) do
		if weapon.category == category then
			table.insert(result, name)
		end
	end

	return result
end

-- Get all compatible attachments for a weapon
function WeaponConfig.getCompatibleAttachments(weaponName)
	local result = {
		SIGHT = {},
		BARREL = {},
		UNDERBARREL = {},
		AMMO = {},
		OTHER = {}
	}

	for name, attachment in pairs(WeaponConfig.Attachments) do
		if WeaponConfig.isAttachmentCompatible(name, weaponName) then
			table.insert(result[attachment.type], {
				name = name,
				displayName = attachment.name,
				description = attachment.description
			})
		end
	end

	return result
end

return WeaponConfig