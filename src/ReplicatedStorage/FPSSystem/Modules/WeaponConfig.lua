local WeaponConfig = {}

function WeaponConfig:Initialize()
	print("WeaponConfig initialized")
end

local ATTACHMENT_CONFIGS = {
	-- Sights
	["ACOG"] = {
		Category = "Sights",
		Type = "Scope",
		Name = "ACOG Scope",
		UnlockKills = 50,
		Cost = 150,
		StatChanges = {
			AimSpeed = -0.1,
			Range = 0.2,
			Zoom = 4.0
		},
		CompatibleWeapons = {"G36", "M4A1", "AK47"}, -- Can be "All" for universal
		Has3DScope = true,
		CanToggleModes = true
	},
	["RedDot"] = {
		Category = "Sights",
		Type = "RedDot",
		Name = "Red Dot Sight",
		UnlockKills = 5,
		Cost = 75,
		StatChanges = {
			AimSpeed = 0.05
		},
		CompatibleWeapons = "All"
	},
	-- Suppressors
	["StandardSuppressor"] = {
		Category = "Barrels",
		Type = "Suppressor",
		Name = "Standard Suppressor",
		UnlockKills = 100,
		Cost = 200,
		StatChanges = {
			Range = -0.1,
			Damage = -0.05,
			RadarRange = 0.3 -- Reduces radar detection range by 70%
		},
		CompatibleWeapons = "All",
		IncompatibleWeapons = {"NTW20"}
	},
	-- Grips
	["AngledGrip"] = {
		Category = "Underbarrel",
		Type = "Grip",
		Name = "Angled Grip",
		UnlockKills = 25,
		Cost = 100,
		StatChanges = {
			AimSpeed = 0.15,
			Recoil = -0.1
		},
		CompatibleWeapons = "All"
	}
}

local CLASS_WEAPON_ACCESS = {
	Assault = {
		Primary = {"AssaultRifles", "BattleRifles", "Carbines", "Shotguns"},
		Secondary = "All",
		Melee = "All",
		Grenade = "All",
		Magic = "All"
	},
	Scout = {
		Primary = {"Carbines", "DMRS", "PDW"},
		Secondary = "All",
		Melee = "All",
		Grenade = "All",
		Magic = "All"
	},
	Support = {
		Primary = {"LMG", "BattleRifles", "Shotguns"},
		Secondary = "All",
		Melee = "All",
		Grenade = "All",
		Magic = "All"
	},
	Recon = {
		Primary = {"SniperRifles", "BattleRifles", "DMR", "Carbines"},
		Secondary = "All",
		Melee = "All",
		Grenade = "All",
		Magic = "All"
	}
}

local WEAPON_CONFIGS = {
	-- Primary Weapons
	G36 = {
		-- Basic Information
		Name = "G36",
		Type = "AssaultRifles",
		Category = "Primary",
		Class = "Assault",
		UnlockLevel = 0,
		UnlockCost = 0,
		PreBuyCost = 0,
		
		-- Damage Stats
		Damage = 35,
		HeadshotMultiplier = 2.0,
		BodyMultiplier = 1.0,
		LimbMultiplier = 0.8,
		
		-- Range and Ballistics
		Range = 1000,
		MinRange = 100,
		MaxRange = 1500,
		BulletVelocity = 800,
		BulletDrop = 9.81,
		Penetration = 2.5,
		PenetrationPower = 65,
		
		-- Ammo Types and Effects
		AmmoType = "556",
		AvailableAmmoTypes = {
			Standard = {Damage = 1.0, Penetration = 1.0, Velocity = 1.0},
			FMJ = {Damage = 0.95, Penetration = 1.5, Velocity = 1.1},
			AP = {Damage = 0.85, Penetration = 2.0, Velocity = 1.2, HeadshotMultiplier = 0.8},
			HP = {Damage = 1.2, Penetration = 0.5, Velocity = 0.9},
			Tracer = {Damage = 1.0, Penetration = 1.0, Velocity = 1.0, HasTracer = true},
			Incendiary = {Damage = 1.1, Penetration = 0.8, Velocity = 0.95, StatusEffect = "Burn"}
		},
		DefaultAmmoType = "Standard",
		
		-- Fire Rate and Ammo
		FireRate = 750,
		MaxAmmo = 30,
		MaxReserveAmmo = 120,
		ReloadTime = 2.8,
		EmptyReloadTime = 3.2,
		
		-- Accuracy and Recoil
		BaseSpread = 0.05,
		AimSpread = 0.025,
		MovingSpread = 0.08,
		
		Recoil = {
			Vertical = 0.8,
			Horizontal = 0.4,
			RandomFactor = 0.3,
			FirstShotMultiplier = 0.7,
			DecayRate = 0.95
		},
		
		-- Fire Modes
		FireModes = {"Auto", "Semi"},
		DefaultFireMode = "Auto",
		
		-- Detailed Attachment Compatibility
		AttachmentSlots = {
			Sights = {
				Compatible = {"RedDot", "Holographic", "ACOG", "Scope", "IronSights"},
				Default = "IronSights"
			},
			Barrels = {
				Compatible = {"StandardSuppressor", "HeavySuppressor", "Compensator", "FlashHider", "MuzzleBrake"},
				Default = nil
			},
			Underbarrel = {
				Compatible = {"VerticalGrip", "AngledGrip", "Bipod", "Laser", "Flashlight"},
				Default = nil
			},
			Other = {
				Compatible = {"LaserSight", "Flashlight", "CantedSight"},
				Default = nil
			}
		},
		
		-- Mastery System
		MasteryRequirements = {
			{Level = 1, Kills = 50, Reward = "RedDot"},
			{Level = 2, Kills = 150, Reward = "Compensator"},
			{Level = 3, Kills = 300, Reward = "VerticalGrip"},
			{Level = 4, Kills = 500, Reward = "ACOG"},
			{Level = 5, Kills = 750, Reward = "StandardSuppressor"},
			{Level = 6, Kills = 1000, Reward = "HolographicSight"},
			{Level = 7, Kills = 1500, Reward = "HeavySuppressor"},
			{Level = 8, Kills = 2000, Reward = "Bipod"},
			{Level = 9, Kills = 2500, Reward = "LaserSight"},
			{Level = 10, Kills = 3000, Reward = "MasterySkin"}
		},
		
		-- Movement and Handling
		WalkSpeedMultiplier = 0.85,
		AimWalkSpeedMultiplier = 0.4,
		AimDownSightTime = 0.35,
		SprintToFireTime = 0.25,
		
		-- Special Properties
		CanWallbang = true,
		HasBurstFire = false,
		HasFullAuto = true,
		SupportsSpecialAmmo = true,
		IsDefault = true
	},
	
	-- Secondary Weapons
	M9 = {
		-- Basic Information
		Name = "M9",
		Type = "Pistols",
		Category = "Secondary",
		Class = "Universal",
		UnlockLevel = 0,
		UnlockCost = 0,
		PreBuyCost = 0,
		
		-- Damage Stats
		Damage = 25,
		HeadshotMultiplier = 2.5,
		BodyMultiplier = 1.0,
		LimbMultiplier = 0.7,
		
		-- Range and Ballistics
		Range = 600,
		MinRange = 50,
		MaxRange = 800,
		BulletVelocity = 600,
		BulletDrop = 9.81,
		Penetration = 1.5,
		PenetrationPower = 40,
		
		-- Ammo Types and Effects
		AmmoType = "9mm",
		AvailableAmmoTypes = {
			Standard = {Damage = 1.0, Penetration = 1.0, Velocity = 1.0},
			FMJ = {Damage = 0.9, Penetration = 1.3, Velocity = 1.05},
			AP = {Damage = 0.8, Penetration = 1.8, Velocity = 1.1},
			HP = {Damage = 1.3, Penetration = 0.4, Velocity = 0.85}
		},
		DefaultAmmoType = "Standard",
		
		-- Fire Rate and Ammo
		FireRate = 450,
		MaxAmmo = 15,
		MaxReserveAmmo = 60,
		ReloadTime = 2.0,
		EmptyReloadTime = 2.5,
		
		-- Accuracy and Recoil
		BaseSpread = 0.08,
		AimSpread = 0.04,
		MovingSpread = 0.12,
		
		Recoil = {
			Vertical = 0.5,
			Horizontal = 0.3,
			RandomFactor = 0.2,
			FirstShotMultiplier = 0.8,
			DecayRate = 0.9
		},
		
		-- Fire Modes
		FireModes = {"Semi"},
		DefaultFireMode = "Semi",
		
		-- Attachment Slots
		AttachmentSlots = {
			Sight = {Compatible = {"RedDot", "IronSights"}},
			Barrel = {Compatible = {"StandardSuppressor"}},
			Underbarrel = {Compatible = {"None"}},
			Other = {Compatible = {"None"}}
		},
		
		-- Movement
		MovementSpeedMultiplier = 1.05,
		AimSpeedMultiplier = 1.1,
		QuickSwapTime = 0.5,
		
		-- Special Properties
		CanQuickSwap = true,
		SwapKey = "F"
	},
	
	-- Grenades
	M67 = {
		-- Basic Information
		Name = "M67 Frag Grenade",
		Type = "Explosive",
		Category = "Grenade",
		Class = "Universal",
		UnlockLevel = 0,
		UnlockCost = 0,

		-- Damage Stats
		Damage = 120,
		ExplosionRadius = 15,
		MinDamageRadius = 5,
		DamageDropoff = true,

		-- Grenade Stats
		FuseTime = 4.0,
		ThrowForce = 50,
		CanCook = true,
		MaxCookTime = 3.5,
		CookTickTime = 1.0,
		MaxUses = 3, -- Limited uses before tool is removed

		-- Movement
		MovementSpeedMultiplier = 1.0,
		ThrowSpeedMultiplier = 0.8,
		QuickSwapTime = 0.8,

		-- Special Properties
		CanQuickSwap = true,
		SwapKey = "G",
		HasExplosionEffects = true,
		CanBounce = true,
		RemoveOnEmpty = true
	},

	-- Impact Grenade
	ImpactGrenade = {
		-- Basic Information
		Name = "Impact Grenade",
		Type = "Impact",
		Category = "Grenade",
		Class = "Universal",
		UnlockLevel = 8,
		UnlockCost = 500,
		PreBuyCost = 1200,

		-- Damage Stats
		Damage = 90,
		ExplosionRadius = 10,
		MinDamageRadius = 3,
		DamageDropoff = true,

		-- Grenade Stats
		FuseTime = 0.0, -- Instant detonation on impact
		ThrowForce = 60,
		CanCook = false,
		MaxUses = 5, -- Can throw 5 times

		-- Movement
		MovementSpeedMultiplier = 1.0,
		ThrowSpeedMultiplier = 0.9,
		QuickSwapTime = 0.6,

		-- Special Properties
		CanQuickSwap = true,
		SwapKey = "G",
		HasExplosionEffects = true,
		CanBounce = false,
		RemoveOnEmpty = true,
		DetonateOnContact = true
	},

	-- Flare Grenade
	FlareGrenade = {
		-- Basic Information
		Name = "Blinding Flare",
		Type = "Utility",
		Category = "Grenade",
		Class = "Universal",
		UnlockLevel = 12,
		UnlockCost = 800,
		PreBuyCost = 1500,

		-- Effect Stats
		Damage = 0, -- No damage
		BlindRadius = 20,
		BlindDuration = 8,
		LightRadius = 50,

		-- Grenade Stats
		FuseTime = 2.0,
		ThrowForce = 40,
		CanCook = false,
		MaxUses = 1, -- Single use only

		-- Movement
		MovementSpeedMultiplier = 1.0,
		ThrowSpeedMultiplier = 1.0,
		QuickSwapTime = 0.5,

		-- Special Properties
		CanQuickSwap = true,
		SwapKey = "G",
		HasFlareEffects = true,
		CanBounce = true,
		RemoveOnEmpty = true,
		CausesBlindness = true
	},
	
	-- Magic/Extra Weapons
	ViciousStinger = {
		-- Basic Information
		Name = "Vicious Stinger",
		Type = "MagicWeapons",
		Category = "Magic",
		Class = "Universal",
		UnlockLevel = 5,
		UnlockCost = 0,
		PreBuyCost = 2500,

		-- Tool Location
		ToolPath = "ServerStorage.Extra.Vicious Stinger",

		-- Damage Stats
		Damage = 45,
		HeadshotMultiplier = 1.8,
		BodyMultiplier = 1.0,
		LimbMultiplier = 0.9,

		-- Special Melee Stats
		BackstabDamage = 100,
		BackstabMultiplier = 2.2,
		Range = 6,
		AttackSpeed = 1.2,
		WindupTime = 0.4,
		RecoveryTime = 0.9,

		-- Movement
		MovementSpeedMultiplier = 1.15,
		QuickSwapTime = 0.3,

		-- Special Abilities with Keybinds
		SpecialAbilities = {
			ViciousOverdrive = {
				Key = "G",
				Cooldown = 45,
				Description = "Dash attack sequence with cinematic effect",
				RequiresMeter = true,
				MeterCost = 100
			},
			HoneyFog = {
				Key = "T",
				Cooldown = 25,
				Description = "Creates atmospheric honey fog zone",
				Duration = 7,
				Radius = 8,
				DamagePerSecond = 5
			},
			Earthquake = {
				Key = "R",
				Cooldown = 30,
				Description = "Ground disruption with camera shake",
				Duration = 5,
				Radius = 12
			}
		},

		-- Passive Abilities
		PassiveAbilities = {
			BloodFrenzy = {
				Description = "Lifesteal on damage dealt",
				LifestealPercent = 0.07,
				LowHealthBonus = 0.5,
				LowHealthThreshold = 0.3
			},
			ViciousMeter = {
				Description = "Meter system that fills on hits",
				MaxMeter = 100,
				MeterPerHit = 10,
				RequiredForFinisher = true
			}
		},

		-- Custom keybinds
		CustomKeybinds = {
			{Key = "E", Action = "PingSystem"},
			{Key = "R", Action = "Earthquake"},
			{Key = "T", Action = "HoneyFog"},
			{Key = "G", Action = "ViciousOverdrive"}
		},

		-- Special Properties
		IsOneHanded = true,
		CanBackstab = true,
		HasCustomUI = true,
		UsesAbilitiesFolder = true,
		AbilitiesFolderPath = "ReplicatedStorage.Abilities.ViciousStingerEvents",

		-- No traditional attachments
		AttachmentSlots = {
			Sights = {Compatible = {}},
			Barrels = {Compatible = {}},
			Underbarrel = {Compatible = {}},
			Other = {Compatible = {}}
		}
	},

	NTW20_Admin = {
		-- Basic Information
		Name = "NTW-20 Admin",
		Type = "AdminWeapons",
		Category = "Magic",
		Class = "Universal",
		UnlockLevel = 999,
		UnlockCost = 0,
		PreBuyCost = 0,
		IsAdminOnly = true,

		-- Damage Stats
		Damage = 200,
		HeadshotMultiplier = 1.0, -- Already one-shot
		BodyMultiplier = 1.0,
		LimbMultiplier = 1.0,

		-- Special Properties
		HasSuppressor = true,
		KillsBothPlayers = true, -- Sends both to orbit
		KnockbackForce = 100,
		SpecialEffect = "OrbitLaunch",

		-- Range and Ballistics
		Range = 5000,
		BulletVelocity = 1200,
		Penetration = 10.0,

		-- Fire Rate and Ammo
		FireRate = 30, -- Very slow
		MaxAmmo = 1,
		MaxReserveAmmo = 10,
		ReloadTime = 5.0,

		-- Movement penalty
		WalkSpeedMultiplier = 0.5,
		AimDownSightTime = 2.0,

		-- Fire Modes
		FireModes = {"Semi"},
		DefaultFireMode = "Semi",

		-- No attachments (already has suppressor)
		AttachmentSlots = {
			Sights = {Compatible = {"IronSights"}},
			Barrels = {Compatible = {}}, -- No barrel attachments
			Underbarrel = {Compatible = {}},
			Other = {Compatible = {}}
		},

		-- Special keybinds
		CustomKeybinds = {
			{Key = "Z", Action = "SpecialAbility"}
		}
	},

	-- Melee Weapons
	PocketKnife = {
		-- Basic Information
		Name = "Pocket Knife",
		Type = "OneHandedBlades",
		Category = "Melee",
		Class = "Universal",
		UnlockLevel = 0,
		UnlockCost = 0,

		-- Damage Stats
		Damage = 35,
		HeadshotMultiplier = 1.0,
		BodyMultiplier = 1.0,
		LimbMultiplier = 1.0,
		BackstabDamage = 100, -- Instant kill on backstab
		BackstabMultiplier = 2.85, -- 35 * 2.85 = ~100 damage

		-- Melee Stats
		Range = 4,
		AttackSpeed = 1.5,
		WindupTime = 0.3,
		RecoveryTime = 0.8,
		BackstabDetectionAngle = 60, -- Degrees behind target

		-- Movement Modifications
		MovementSpeedMultiplier = 1.15, -- 15% speed boost when equipped
		QuickSwapTime = 0.4,
		AimWalkSpeedMultiplier = 1.1,

		-- Special Properties
		IsOneHanded = true,
		CanBackstab = true,
		CanQuickSwap = true,
		SwapKey = "F",
		HasLungeAttack = true, -- Right-click special attack
		LungeRange = 8,
		LungeCooldown = 3.0,

		-- Custom Keybinds
		CustomKeybinds = {
			{Key = "F", Action = "QuickSwap"},
			{Key = "RightClick", Action = "LungeAttack"}
		},

		-- No attachments for melee
		AttachmentSlots = {
			Sights = {Compatible = {}},
			Barrels = {Compatible = {}},
			Underbarrel = {Compatible = {}},
			Other = {Compatible = {}}
		}
	},

	-- Two-Handed Melee Example
	Machete = {
		-- Basic Information
		Name = "Machete",
		Type = "TwoHandedBlades",
		Category = "Melee",
		Class = "Universal",
		UnlockLevel = 15,
		UnlockCost = 1200,
		PreBuyCost = 2800,

		-- Damage Stats
		Damage = 65,
		HeadshotMultiplier = 1.2,
		BodyMultiplier = 1.0,
		LimbMultiplier = 0.9,
		BackstabDamage = 130,
		BackstabMultiplier = 2.0,

		-- Melee Stats
		Range = 7,
		AttackSpeed = 0.8,
		WindupTime = 0.6,
		RecoveryTime = 1.2,
		BackstabDetectionAngle = 45,

		-- Movement Modifications (slower due to two-handed)
		MovementSpeedMultiplier = 0.92, -- 8% speed reduction
		QuickSwapTime = 0.8,
		AimWalkSpeedMultiplier = 0.85,

		-- Special Properties
		IsOneHanded = false,
		IsTwoHanded = true,
		CanBackstab = true,
		CanQuickSwap = true,
		SwapKey = "F",
		HasHeavyAttack = true,
		HeavyAttackDamageMultiplier = 1.8,
		HeavyAttackCooldown = 4.0,
		CanHitMultipleTargets = true,
		MaxTargetsPerSwing = 3,

		-- Custom Keybinds
		CustomKeybinds = {
			{Key = "F", Action = "QuickSwap"},
			{Key = "RightClick", Action = "HeavyAttack"}
		},

		-- No attachments for melee
		AttachmentSlots = {
			Sights = {Compatible = {}},
			Barrels = {Compatible = {}},
			Underbarrel = {Compatible = {}},
			Other = {Compatible = {}}
		}
	}
}

function WeaponConfig:GetWeaponConfig(weaponName)
	return WEAPON_CONFIGS[weaponName]
end

function WeaponConfig.GetWeaponData(weaponName)
	return WEAPON_CONFIGS[weaponName]
end

function WeaponConfig:GetAllConfigs()
	return WEAPON_CONFIGS
end

function WeaponConfig:IsValidWeapon(weaponName)
	return WEAPON_CONFIGS[weaponName] ~= nil
end

function WeaponConfig:GetWeaponsByCategory(category)
	local weapons = {}
	for name, config in pairs(WEAPON_CONFIGS) do
		if config.Category == category then
			weapons[name] = config
		end
	end
	return weapons
end

function WeaponConfig:GetWeaponsByClass(class)
	local weapons = {}
	for name, config in pairs(WEAPON_CONFIGS) do
		if config.Class == class then
			weapons[name] = config
		end
	end
	return weapons
end

function WeaponConfig:GetWeaponsByType(weaponType)
	local weapons = {}
	for name, config in pairs(WEAPON_CONFIGS) do
		if config.Type == weaponType then
			weapons[name] = config
		end
	end
	return weapons
end

function WeaponConfig:GetWeaponsByUnlockLevel(level)
	local weapons = {}
	for name, config in pairs(WEAPON_CONFIGS) do
		if config.UnlockLevel and config.UnlockLevel <= level then
			weapons[name] = config
		end
	end
	return weapons
end

function WeaponConfig:GetDefaultWeapons()
	return self:GetWeaponsByUnlockLevel(0)
end

function WeaponConfig:GetWeaponStats(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config then
		warn("Weapon config not found for: " .. weaponName)
		return {}
	end
	
	-- Return stats in format expected by weapon scripts
	return {
		FireRate = config.FireRate or 600,
		Damage = config.Damage or 35,
		HeadshotMultiplier = config.HeadshotMultiplier or 2.0,
		ClipSize = config.MaxAmmo or 30,
		TotalAmmo = config.MaxReserveAmmo or 120,
		ReloadTime = config.ReloadTime or 2.5,
		Range = config.Range or 1000,
		Recoil = config.Recoil and config.Recoil.Vertical or 1.0
	}
end

function WeaponConfig:CanAttachAttachment(weaponName, attachmentCategory)
	local config = WEAPON_CONFIGS[weaponName]
	if not config or not config.CanAttach then return false end
	
	return config.CanAttach[attachmentCategory] == true
end

function WeaponConfig:HasFireMode(weaponName, fireMode)
	local config = WEAPON_CONFIGS[weaponName]
	if not config or not config.FireModes then return false end
	
	for _, mode in pairs(config.FireModes) do
		if mode == fireMode then
			return true
		end
	end
	return false
end

-- Attachment System Functions
function WeaponConfig:GetAttachmentConfig(attachmentName)
	return ATTACHMENT_CONFIGS[attachmentName]
end

function WeaponConfig:GetAllAttachments()
	return ATTACHMENT_CONFIGS
end

function WeaponConfig:IsAttachmentCompatible(weaponName, attachmentName)
	local weaponConfig = WEAPON_CONFIGS[weaponName]
	local attachmentConfig = ATTACHMENT_CONFIGS[attachmentName]
	
	if not weaponConfig or not attachmentConfig then
		return false
	end
	
	-- Check if attachment is universally compatible
	if attachmentConfig.CompatibleWeapons == "All" then
		-- Check if weapon is in incompatible list
		if attachmentConfig.IncompatibleWeapons then
			for _, incompatibleWeapon in pairs(attachmentConfig.IncompatibleWeapons) do
				if incompatibleWeapon == weaponName then
					return false
				end
			end
		end
		return true
	end
	
	-- Check specific weapon compatibility
	if attachmentConfig.CompatibleWeapons then
		for _, compatibleWeapon in pairs(attachmentConfig.CompatibleWeapons) do
			if compatibleWeapon == weaponName then
				return true
			end
		end
	end
	
	return false
end

function WeaponConfig:GetWeaponAttachmentSlots(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config or not config.AttachmentSlots then
		return {}
	end
	return config.AttachmentSlots
end

function WeaponConfig:ApplyAttachmentStats(weaponName, attachmentName, baseStats)
	local attachmentConfig = ATTACHMENT_CONFIGS[attachmentName]
	if not attachmentConfig or not attachmentConfig.StatChanges then
		return baseStats
	end
	
	local modifiedStats = {}
	for stat, value in pairs(baseStats) do
		modifiedStats[stat] = value
	end
	
	for stat, modifier in pairs(attachmentConfig.StatChanges) do
		if modifiedStats[stat] then
			if type(modifiedStats[stat]) == "number" then
				modifiedStats[stat] = modifiedStats[stat] * (1 + modifier)
			end
		end
	end
	
	return modifiedStats
end

-- Class System Functions
function WeaponConfig:GetClassWeaponAccess(className)
	return CLASS_WEAPON_ACCESS[className]
end

function WeaponConfig:CanClassUseWeapon(className, weaponName)
	local classAccess = CLASS_WEAPON_ACCESS[className]
	local weaponConfig = WEAPON_CONFIGS[weaponName]
	
	if not classAccess or not weaponConfig then
		return false
	end
	
	local category = weaponConfig.Category
	local weaponType = weaponConfig.Type
	
	if classAccess[category] == "All" then
		return true
	end
	
	if classAccess[category] then
		for _, allowedType in pairs(classAccess[category]) do
			if allowedType == weaponType then
				return true
			end
		end
	end
	
	return false
end

function WeaponConfig:GetAvailableWeaponsForClass(className)
	local availableWeapons = {}
	
	for weaponName, weaponConfig in pairs(WEAPON_CONFIGS) do
		if self:CanClassUseWeapon(className, weaponName) then
			availableWeapons[weaponName] = weaponConfig
		end
	end
	
	return availableWeapons
end

-- Mastery System Functions  
function WeaponConfig:GetWeaponMasteryRequirements(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config or not config.MasteryRequirements then
		return {}
	end
	return config.MasteryRequirements
end

function WeaponConfig:GetMasteryRewardForKills(weaponName, kills)
	local requirements = self:GetWeaponMasteryRequirements(weaponName)
	local highestReward = nil
	
	for _, requirement in pairs(requirements) do
		if kills >= requirement.Kills then
			highestReward = requirement.Reward
		else
			break
		end
	end
	
	return highestReward
end

function WeaponConfig:GetNextMasteryRequirement(weaponName, currentKills)
	local requirements = self:GetWeaponMasteryRequirements(weaponName)
	
	for _, requirement in pairs(requirements) do
		if currentKills < requirement.Kills then
			return requirement
		end
	end
	
	return nil -- Max mastery reached
end

-- Magic/Extra Weapon Functions
function WeaponConfig:GetMagicWeapons()
	local magicWeapons = {}
	for weaponName, config in pairs(WEAPON_CONFIGS) do
		if config.Category == "Magic" then
			magicWeapons[weaponName] = config
		end
	end
	return magicWeapons
end

function WeaponConfig:IsMagicWeapon(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.Category == "Magic"
end

function WeaponConfig:IsAdminOnlyWeapon(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.IsAdminOnly == true
end

function WeaponConfig:GetWeaponKeybinds(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if config and config.CustomKeybinds then
		return config.CustomKeybinds
	end
	return {}
end

-- Weapon Pool Functions
function WeaponConfig:GetRandomWeaponPool(playerLevel, unlockedWeapons)
	local weaponPool = {
		Primary = nil,
		Secondary = nil,
		Melee = nil,
		Grenade = nil,
		Magic = nil
	}

	-- Get available weapons for each category
	local availableWeapons = {
		Primary = {},
		Secondary = {},
		Melee = {},
		Grenade = {},
		Magic = {}
	}

	for weaponName, config in pairs(WEAPON_CONFIGS) do
		-- Skip admin weapons unless player is admin (will be handled by calling code)
		if not config.IsAdminOnly then
			local category = config.Category
			if availableWeapons[category] then
				-- Check if weapon is unlocked
				if config.UnlockLevel <= playerLevel or unlockedWeapons[weaponName] then
					table.insert(availableWeapons[category], weaponName)
				end
			end
		end
	end

	-- Select random weapon from each category
	for category, weapons in pairs(availableWeapons) do
		if #weapons > 0 then
			local randomIndex = math.random(1, #weapons)
			weaponPool[category] = weapons[randomIndex]
		end
	end

	return weaponPool
end

function WeaponConfig:GetDefaultWeaponPool()
	-- Return default weapons for rank 0 players
	return {
		Primary = "G36", -- Default assault rifle
		Secondary = "M9", -- Default pistol
		Melee = "PocketKnife", -- Default melee
		Grenade = "M67", -- Default grenade
		Magic = nil -- No magic weapons at rank 0
	}
end

-- 3D Preview Functions
function WeaponConfig:GetWeaponModelPath(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config then return nil end

	local category = config.Category
	local weaponType = config.Type

	-- Build model path for weapon previews
	if category == "Primary" then
		return "ReplicatedStorage.FPSSystem.WeaponModels.Primary." .. weaponType .. "." .. weaponName
	elseif category == "Secondary" then
		return "ReplicatedStorage.FPSSystem.WeaponModels.Secondary." .. weaponType .. "." .. weaponName
	elseif category == "Melee" then
		return "ReplicatedStorage.FPSSystem.WeaponModels.Melee." .. weaponType .. "." .. weaponName
	elseif category == "Grenade" then
		return "ReplicatedStorage.FPSSystem.WeaponModels.Grenades." .. weaponType .. "." .. weaponName
	elseif category == "Magic" then
		return "ReplicatedStorage.FPSSystem.WeaponModels.Magic." .. weaponType .. "." .. weaponName
	end

	return nil
end

function WeaponConfig:GetViewmodelPath(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config then return nil end

	local category = config.Category
	local weaponType = config.Type

	-- Build viewmodel path
	if category == "Primary" then
		return "ReplicatedStorage.FPSSystem.ViewModels.Primary." .. weaponType .. "." .. weaponName
	elseif category == "Secondary" then
		return "ReplicatedStorage.FPSSystem.ViewModels.Secondary." .. weaponType .. "." .. weaponName
	elseif category == "Melee" then
		return "ReplicatedStorage.FPSSystem.ViewModels.Melee." .. weaponType .. "." .. weaponName
	elseif category == "Grenade" then
		return "ReplicatedStorage.FPSSystem.ViewModels.Grenades." .. weaponType .. "." .. weaponName
	elseif category == "Magic" then
		return "ReplicatedStorage.FPSSystem.ViewModels.Magic." .. weaponType .. "." .. weaponName
	end

	return nil
end

-- Enhanced Weapon System Functions
function WeaponConfig:GetWeaponAbilities(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config then return {} end

	return {
		SpecialAbilities = config.SpecialAbilities or {},
		PassiveAbilities = config.PassiveAbilities or {},
		CustomKeybinds = config.CustomKeybinds or {}
	}
end

function WeaponConfig:HasSpecialAbility(weaponName, abilityName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.SpecialAbilities and config.SpecialAbilities[abilityName] ~= nil
end

function WeaponConfig:GetGrenadeUses(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if config and config.Category == "Grenade" then
		return config.MaxUses or math.huge
	end
	return 0
end

function WeaponConfig:ShouldRemoveOnEmpty(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.RemoveOnEmpty == true
end

function WeaponConfig:GetBackstabInfo(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config or not config.CanBackstab then
		return nil
	end

	return {
		BackstabDamage = config.BackstabDamage or config.Damage * 2,
		BackstabMultiplier = config.BackstabMultiplier or 2.0,
		BackstabDetectionAngle = config.BackstabDetectionAngle or 45
	}
end

function WeaponConfig:GetMovementModifiers(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config then return {} end

	return {
		MovementSpeedMultiplier = config.MovementSpeedMultiplier or 1.0,
		AimWalkSpeedMultiplier = config.AimWalkSpeedMultiplier or 0.5,
		QuickSwapTime = config.QuickSwapTime or 0.5
	}
end

function WeaponConfig:IsOneHandedMelee(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.Category == "Melee" and config.IsOneHanded == true
end

function WeaponConfig:IsTwoHandedMelee(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.Category == "Melee" and config.IsTwoHanded == true
end

function WeaponConfig:GetAbilityKeybinds()
	-- Return the standard ability keybinds that can be used by weapons
	return {
		"E", "R", "T", "Y", "H", "Z", "X", "C", "V" -- Q is reserved for perks
	}
end

function WeaponConfig:GetPerkKeybind()
	return "Q" -- Universal perk activation key
end

function WeaponConfig:HasCustomUI(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.HasCustomUI == true
end

function WeaponConfig:UsesAbilitiesFolder(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	return config and config.UsesAbilitiesFolder == true
end

function WeaponConfig:GetAbilitiesFolderPath(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if config and config.AbilitiesFolderPath then
		return config.AbilitiesFolderPath
	end
	return nil
end

-- Unlock System Functions
function WeaponConfig:CanPlayerUnlockWeapon(playerLevel, playerCredits, weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config then
		return false, "Weapon not found"
	end
	
	if playerLevel >= config.UnlockLevel then
		return true, "Available"
	end
	
	if playerCredits >= config.PreBuyCost and config.PreBuyCost > 0 then
		return true, "Can Pre-Buy"
	end
	
	return false, "Level " .. config.UnlockLevel .. " required"
end

function WeaponConfig:GetWeaponUnlockInfo(weaponName)
	local config = WEAPON_CONFIGS[weaponName]
	if not config then
		return nil
	end
	
	return {
		UnlockLevel = config.UnlockLevel,
		UnlockCost = config.UnlockCost,
		PreBuyCost = config.PreBuyCost,
		IsDefault = config.IsDefault or false
	}
end

-- Ammo System Functions
function WeaponConfig:GetAmmoTypeStats(weaponName, ammoType)
	local config = WEAPON_CONFIGS[weaponName]
	if not config or not config.AvailableAmmoTypes or not config.AvailableAmmoTypes[ammoType] then
		return nil
	end
	
	return config.AvailableAmmoTypes[ammoType]
end

function WeaponConfig:ApplyAmmoTypeModifiers(weaponName, ammoType, baseStats)
	local ammoStats = self:GetAmmoTypeStats(weaponName, ammoType)
	if not ammoStats then
		return baseStats
	end
	
	local modifiedStats = {}
	for stat, value in pairs(baseStats) do
		modifiedStats[stat] = value
	end
	
	-- Apply ammo modifiers
	if ammoStats.Damage then
		modifiedStats.Damage = modifiedStats.Damage * ammoStats.Damage
	end
	if ammoStats.Penetration then
		modifiedStats.Penetration = modifiedStats.Penetration * ammoStats.Penetration
	end
	if ammoStats.Velocity then
		modifiedStats.BulletVelocity = modifiedStats.BulletVelocity * ammoStats.Velocity
	end
	if ammoStats.HeadshotMultiplier then
		modifiedStats.HeadshotMultiplier = modifiedStats.HeadshotMultiplier * ammoStats.HeadshotMultiplier
	end
	
	return modifiedStats, ammoStats
end

return WeaponConfig