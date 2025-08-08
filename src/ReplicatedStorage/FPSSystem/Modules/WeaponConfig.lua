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
	MELEE = "PocketKnife", 
	GRENADES = "M67"
}

-- Weapon Definitions
WeaponConfig.Weapons = {
	-- ASSAULT RIFLES
	G36 = {
		name = "G36",
		displayName = "G36 Assault Rifle",
		description = "German assault rifle with integrated scope",
		category = WeaponConfig.Categories.PRIMARY,
		type = WeaponConfig.Types.ASSAULT_RIFLE,

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

	-- NTW-20 Anti-Material Rifle
	NTW20 = {
		name = "NTW20",
		displayName = "NTW-20 Anti-Material Rifle",
		description = "South African anti-material rifle with dual ammo support",
		category = WeaponConfig.Categories.PRIMARY,
		type = WeaponConfig.Types.SNIPER_RIFLE,

		-- Basic Stats
		damage = 150,
		firerate = 30, -- Rounds per minute
		velocity = 2500, -- Bullet velocity

		-- Damage Range
		damageRanges = {
			{distance = 0, damage = 150},
			{distance = 200, damage = 140},
			{distance = 500, damage = 120},
			{distance = 1000, damage = 100}
		},

		-- Recoil Properties
		recoil = {
			vertical = 12.0,       -- Massive vertical kick
			horizontal = 3.0,      -- Significant horizontal sway
			recovery = 0.8,        -- Slower recovery rate
			initial = 1.5          -- High first shot recoil multiplier
		},

		-- Spread/Accuracy
		spread = {
			base = 0.05,           -- Very accurate
			moving = 8.0,          -- Huge penalty when moving
			jumping = 20.0,        -- Massive penalty when jumping
			recovery = 0.7         -- Slower recovery rate
		},

		-- Mobility
		mobility = {
			adsSpeed = 1.0,        -- Very slow ADS
			walkSpeed = 10,        -- Very slow walking speed
			sprintSpeed = 12,      -- Very slow sprint speed
			equipTime = 2.0        -- Very slow weapon draw time
		},

		-- Magazine
		magazine = {
			size = 3,             -- Small magazine
			maxAmmo = 15,         -- Limited reserve ammo
			reloadTime = 5.0,     -- Very slow reload
			reloadTimeEmpty = 5.5, -- Even slower empty reload
			ammoType = "14.5x114mm" -- Default ammo type
		},

		-- Dual ammo system
		ammoTypes = {
			["14.5x114mm"] = {
				damage = 150,
				velocity = 2500,
				penetration = 4.0,
				description = "Standard anti-material rounds"
			},
			["20x110mm"] = {
				damage = 200,
				velocity = 2200,
				penetration = 5.0,
				recoil = {
					vertical = 15.0,
					horizontal = 4.0
				},
				description = "High-explosive rounds with massive damage"
			}
		},

		-- Advanced Ballistics
		penetration = 4.0,         -- Extreme material penetration
		bulletDrop = 0.02,         -- Minimal bullet drop
		destructibleTerrain = true, -- Can destroy cover

		-- Firing Mode
		firingMode = WeaponConfig.FiringModes.BOLT_ACTION,

		-- Special Features
		specialFeatures = {
			canDestroyVehicles = true,
			wallPenetration = 3,      -- Can shoot through multiple walls
			suppressorCompatible = true,
			bipodRequired = false     -- Can be fired without bipod but with penalties
		},

		-- Scope Settings
		scope = {
			defaultZoom = 12.0,       -- High zoom level
			maxZoom = 16.0,           -- Maximum zoom level
			scopeType = "GUI",        -- GUI-based scope
			scopeImage = "rbxassetid://6918290101",
			scopeRenderScale = 0.7,   -- Performance optimization
			scopeBlur = true,
			scopeSensitivity = 0.3,   -- Very low sensitivity when scoped
			scopeHoldBreath = true,
			holdBreathDuration = 8.0, -- Longer hold breath
			breathRecovery = 0.6
		},

		-- Visual Effects
		muzzleFlash = {
			size = 2.0,              -- Massive muzzle flash
			brightness = 1.5,
			color = Color3.fromRGB(255, 180, 100),
			shockwave = true         -- Create visible shockwave
		},

		tracers = {
			enabled = true,
			color = Color3.fromRGB(255, 100, 100),
			width = 0.1,             -- Thick tracers
			frequency = 1            -- Every shot is a tracer
		},

		-- Audio
		sounds = {
			fire = "rbxassetid://168143115",
			reload = "rbxassetid://1659380685", 
			reloadEmpty = "rbxassetid://1659380685",
			equip = "rbxassetid://4743275867",
			empty = "rbxassetid://3744371342",
			boltAction = "rbxassetid://3599663417",
			shockwave = "rbxassetid://168143115" -- Shockwave sound effect
		},

		-- Crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.DOT,
			size = 1,
			thickness = 1,
			dot = true,
			color = Color3.fromRGB(255, 0, 0),
			hideWhenADS = true
		},

		-- Animation IDs
		animations = {
			idle = "rbxassetid://9949926480",
			fire = "rbxassetid://9949926480",
			reload = "rbxassetid://9949926480",
			reloadEmpty = "rbxassetid://9949926480",
			equip = "rbxassetid://9949926480",
			sprint = "rbxassetid://9949926480",
			boltAction = "rbxassetid://9949926480"
		}
	},

	-- NTW-20 Custom "Chaos Cannon" Variant (Admin/Exclusive)
	NTW20_Chaos = {
		name = "NTW20_Chaos",
		displayName = "NTW-20 \"Chaos Cannon\"",
		description = "Modified NTW-20 with experimental physics-defying ammunition",
		category = WeaponConfig.Categories.PRIMARY,
		type = WeaponConfig.Types.SNIPER_RIFLE,
		isExclusive = true,          -- Mark as admin/exclusive weapon
		isAdminOnly = true,

		-- Inherits from base NTW-20 but with modifications
		damage = 250,                -- Even higher damage
		firerate = 25,               -- Slightly slower
		velocity = 3000,             -- Faster velocity

		-- Damage Range (longer effective range)
		damageRanges = {
			{distance = 0, damage = 250},
			{distance = 300, damage = 240},
			{distance = 800, damage = 220},
			{distance = 1500, damage = 200}
		},

		-- Extreme Recoil with physics effects
		recoil = {
			vertical = 20.0,         -- Extreme vertical kick
			horizontal = 5.0,        -- High horizontal sway
			recovery = 0.6,          -- Even slower recovery
			initial = 2.0,           -- Massive first shot recoil
			playerKnockback = true   -- Knocks player backwards
		},

		-- Physics Effects
		physicsEffects = {
			shooterFling = {
				onHit = Vector3.new(0, 50, -100),    -- Fling shooter backwards and up on hit
				onMiss = Vector3.new(0, 10, -20)     -- Slight fling on miss
			},
			targetFling = {
				force = Vector3.new(0, 100, 100),    -- Fling target across map
				ragdoll = true                        -- Ragdoll the target
			},
			fallDamage = false,      -- Disable fall damage for this weapon's effects
			shockwaveRadius = 20     -- Create shockwave effect on impact
		},

		-- Built-in suppressor
		builtInAttachments = {"ChaosSupressor"},

		-- Mobility (even slower due to modifications)
		mobility = {
			adsSpeed = 1.5,          -- Extremely slow ADS
			walkSpeed = 8,           -- Very slow walking
			sprintSpeed = 10,        -- Very slow sprinting
			equipTime = 3.0          -- Very slow equip time
		},

		-- Magazine
		magazine = {
			size = 1,                -- Single shot
			maxAmmo = 5,             -- Very limited ammo
			reloadTime = 8.0,        -- Extremely slow reload
			reloadTimeEmpty = 8.0,
			ammoType = "Chaos Rounds"
		},

		-- Special ammo type
		ammoTypes = {
			["Chaos Rounds"] = {
				damage = 250,
				velocity = 3000,
				penetration = 10.0,    -- Penetrates everything
				description = "Experimental rounds that defy physics",
				effectRadius = 10,     -- Damage radius around impact
				chainReaction = true   -- Can cause chain explosions
			}
		},

		-- Enhanced visual effects
		muzzleFlash = {
			size = 3.0,              -- Massive muzzle flash
			brightness = 2.0,
			color = Color3.fromRGB(255, 0, 255), -- Purple flash
			shockwave = true,
			particles = true         -- Enhanced particle effects
		},

		tracers = {
			enabled = true,
			color = Color3.fromRGB(255, 0, 255), -- Purple tracers
			width = 0.2,             -- Very thick tracers
			frequency = 1,
			glowEffect = true        -- Tracers glow
		},

		-- Enhanced audio
		sounds = {
			fire = "rbxassetid://168143115",     -- Different fire sound
			reload = "rbxassetid://1659380685",
			reloadEmpty = "rbxassetid://1659380685", 
			equip = "rbxassetid://4743275867",
			empty = "rbxassetid://3744371342",
			boltAction = "rbxassetid://3599663417",
			shockwave = "rbxassetid://2814355743", -- Explosion sound for shockwave
			chaos = "rbxassetid://131961136"       -- Special chaos sound
		},

		-- Special crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.CORNERS,
			size = 3,
			thickness = 2,
			dot = true,
			color = Color3.fromRGB(255, 0, 255), -- Purple crosshair
			hideWhenADS = false,
			animated = true          -- Animated crosshair
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
	},

	-- M67 GRENADE (Updated default)
	M67 = {
		name = "M67",
		displayName = "M67 Fragmentation Grenade",
		description = "Standard military fragmentation grenade",
		category = WeaponConfig.Categories.GRENADES,
		type = WeaponConfig.Types.EXPLOSIVE,

		-- Damage
		damage = 100,            -- Maximum damage
		damageRadius = 12,       -- Full damage radius (slightly larger than FragGrenade)
		maxRadius = 25,          -- Maximum effect radius
		falloffType = "linear",  -- How damage decreases with distance

		-- Throw properties
		throwForce = 55,         -- Base throw force (slightly more than FragGrenade)
		throwForceCharged = 85,  -- Max throw force (when held)
		throwChargeTime = 1.2,   -- Time to reach max throw

		-- Explosion properties
		fuseTime = 4.0,          -- Time until detonation (4 seconds like real M67)
		bounciness = 0.2,        -- How bouncy the grenade is
		cookingTime = 4.0,       -- Max cooking time before exploding in hand

		-- Effects
		effects = {
			explosion = {
				size = 3.5,
				particles = 40,
				light = true,
				lightBrightness = 1.2,
				lightRange = 25
			},
			cookingIndicator = true, -- Show visual indicator when cooking
			smokeTrail = true        -- Leave smoke trail when thrown
		},

		-- Mobility
		mobility = {
			walkSpeed = 15,     -- Walking speed
			sprintSpeed = 20,   -- Sprint speed (slightly slower than FragGrenade)
			equipTime = 0.4     -- Weapon draw time
		},

		-- Audio
		sounds = {
			throw = "rbxassetid://5564314786",
			bounce = "rbxassetid://6842081192", 
			explosion = "rbxassetid://131961136", -- Different explosion sound
			pin = "rbxassetid://131961136",
			cooking = "rbxassetid://131961136"
		},

		-- Inventory
		maxCount = 3,           -- Maximum number player can carry

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
			pointCount = 35,
			lineColor = Color3.fromRGB(255, 150, 100),
			showOnRightClick = true
		},

		-- Crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.CIRCLE,
			size = 5,
			thickness = 2,
			dot = true,
			color = Color3.fromRGB(255, 200, 100)
		}
	},

	-- Impact Grenade
	ImpactGrenade = {
		name = "ImpactGrenade",
		displayName = "Impact Grenade",
		description = "Explodes on first contact - no fuse timer",
		category = WeaponConfig.Categories.GRENADES,
		type = WeaponConfig.Types.IMPACT,

		-- Damage
		damage = 80,             -- Slightly less than frag
		damageRadius = 8,        -- Smaller radius 
		maxRadius = 15,          -- Maximum effect radius
		falloffType = "linear",

		-- Throw properties
		throwForce = 45,         -- Slightly less throw force
		throwForceCharged = 75,  -- Max throw force
		throwChargeTime = 0.8,   -- Faster charge time

		-- Impact properties
		fuseTime = 0,            -- No fuse - explodes on impact
		impactSensitivity = 1.0, -- How sensitive to impact
		bounces = 0,             -- No bouncing - explodes immediately
		
		-- Effects
		effects = {
			explosion = {
				size = 2.5,
				particles = 25,
				light = true,
				lightBrightness = 1.0,
				lightRange = 18
			},
			impactSpark = true       -- Spark effect on impact
		},

		-- Mobility  
		mobility = {
			walkSpeed = 15,
			sprintSpeed = 21,
			equipTime = 0.25         -- Faster equip
		},

		-- Audio
		sounds = {
			throw = "rbxassetid://5564314786",
			explosion = "rbxassetid://2814355743",
			impact = "rbxassetid://131961136"
		},

		-- Inventory
		maxCount = 3,

		-- Crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.CORNERS,
			size = 3,
			thickness = 2,
			dot = true,
			color = Color3.fromRGB(255, 100, 100)
		}
	},

	-- Flashbang
	Flashbang = {
		name = "Flashbang",
		displayName = "M84 Flashbang",
		description = "Blinds and deafens enemies without lethal damage",
		category = WeaponConfig.Categories.GRENADES,
		type = WeaponConfig.Types.TACTICAL,

		-- Non-lethal effects
		damage = 5,              -- Minimal damage
		damageRadius = 2,        -- Very small damage radius
		maxRadius = 25,          -- Large effect radius for flash/sound

		-- Flash/stun effects
		flashEffects = {
			blindDuration = 3.0,     -- How long players are blinded
			blindRadius = 15,        -- Radius for full blind effect
			deafenDuration = 5.0,    -- How long hearing is affected
			deafenRadius = 20,       -- Radius for audio effects
			orientationEffect = 2.0   -- Disorientation duration
		},

		-- Throw properties
		throwForce = 40,
		throwForceCharged = 70,
		throwChargeTime = 0.8,

		-- Explosion properties
		fuseTime = 2.0,          -- Short fuse
		bounciness = 0.3,        -- Can bounce around corners

		-- Effects
		effects = {
			explosion = {
				size = 4.0,          -- Large visual flash
				particles = 50,
				light = true,
				lightBrightness = 5.0, -- Very bright
				lightRange = 40,
				flashEffect = true    -- Special flash effect
			}
		},

		-- Audio  
		sounds = {
			throw = "rbxassetid://5564314786",
			explosion = "rbxassetid://131961136", -- Loud bang sound
			bounce = "rbxassetid://6842081192"
		},

		-- Inventory
		maxCount = 2,

		-- Crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.CIRCLE,
			size = 4,
			thickness = 1,
			dot = true,
			color = Color3.fromRGB(255, 255, 100)
		}
	},

	-- Smoke Grenade
	SmokeGrenade = {
		name = "SmokeGrenade",
		displayName = "M18 Smoke Grenade", 
		description = "Creates dense smoke screen for cover and concealment",
		category = WeaponConfig.Categories.GRENADES,
		type = WeaponConfig.Types.TACTICAL,

		-- Smoke effects
		damage = 0,              -- No damage
		smokeEffects = {
			duration = 30.0,         -- How long smoke lasts
			radius = 20,             -- Smoke coverage radius
			density = 0.8,           -- How thick the smoke is
			color = Color3.fromRGB(200, 200, 200), -- Smoke color
			particleCount = 100      -- Number of smoke particles
		},

		-- Throw properties
		throwForce = 35,
		throwForceCharged = 60,
		throwChargeTime = 1.0,

		-- Deployment properties
		fuseTime = 1.5,          -- Time before smoke starts
		bounciness = 0.4,        -- Can roll around

		-- Effects
		effects = {
			smokeCloud = true,
			continuousSmoke = true   -- Smoke continues to emit
		},

		-- Audio
		sounds = {
			throw = "rbxassetid://5564314786",
			deploy = "rbxassetid://131961136", -- Hissing sound
			bounce = "rbxassetid://6842081192"
		},

		-- Inventory
		maxCount = 4,

		-- Crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.CIRCLE,
			size = 5,
			thickness = 1,
			dot = false,
			color = Color3.fromRGB(150, 150, 150)
		}
	},

	-- MELEE WEAPONS
	PocketKnife = {
		name = "PocketKnife",
		displayName = "Pocket Knife",
		description = "Small folding knife for stealth attacks",
		category = WeaponConfig.Categories.MELEE,
		type = WeaponConfig.Types.BLADEONEHAND,

		-- Damage
		damage = 45,             -- Front damage (less than combat knife)
		backstabDamage = 90,     -- Backstab damage
		headshotDamage = 65,     -- Headshot damage

		-- Attack properties
		attackRate = 2.0,        -- Attacks per second (faster than combat knife)
		attackDelay = 0.08,      -- Delay before damage registers
		attackRange = 2.5,       -- Range in studs (shorter than combat knife)
		attackType = "stab",     -- stab or slash
		canCombo = true,         -- Can perform combo attacks

		-- Mobility
		mobility = {
			walkSpeed = 17,      -- Walking speed (faster than combat knife)
			sprintSpeed = 23,    -- Sprint speed
			equipTime = 0.15     -- Weapon draw time (very fast)
		},

		-- Audio
		sounds = {
			swing = "rbxassetid://5810753638",
			hit = "rbxassetid://3744370687",
			hitCritical = "rbxassetid://3744371342",
			equip = "rbxassetid://6842081192",
			deploy = "rbxassetid://131961136" -- Folding knife deploy sound
		},

		-- Handling
		canBlock = false,        -- Cannot block attacks
		stealthBonus = 1.5,      -- Damage multiplier for stealth attacks
		silentKill = true,       -- Doesn't alert other players on backstab

		-- Animations
		animations = {
			idle = "rbxassetid://9949926480",
			attack = "rbxassetid://9949926480",
			attackAlt = "rbxassetid://9949926480",
			combo1 = "rbxassetid://9949926480",
			combo2 = "rbxassetid://9949926480",
			equip = "rbxassetid://9949926480",
			sprint = "rbxassetid://9949926480"
		},

		-- Crosshair
		crosshair = {
			style = WeaponConfig.CrosshairStyles.DOT,
			size = 1,
			thickness = 1,
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
