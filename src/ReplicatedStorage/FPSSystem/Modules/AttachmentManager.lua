local AttachmentManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

function AttachmentManager:Initialize()
	print("AttachmentManager initialized")
end

-- Attachment configurations and stat modifications
local ATTACHMENT_CONFIGS = {
	-- Sights
	RedDotSight = {
		Name = "Red Dot Sight",
		Category = "Sights",
		Description = "Improves target acquisition",
		StatModifiers = {
			AimSpread = -0.01,
			BaseSpread = -0.005
		},
		VisualEffects = {
			HasReticle = true,
			ReticleType = "RedDot",
			ZoomFactor = 1.2
		}
	},
	ACOGScope = {
		Name = "ACOG Scope",
		Category = "Sights", 
		Description = "4x magnification scope",
		StatModifiers = {
			AimSpread = -0.02,
			BaseSpread = -0.01,
			MovingSpread = 0.01
		},
		VisualEffects = {
			HasReticle = true,
			ReticleType = "ACOG",
			ZoomFactor = 4.0
		}
	},
	HolographicSight = {
		Name = "Holographic Sight",
		Category = "Sights",
		Description = "Wide field of view with precise reticle",
		StatModifiers = {
			AimSpread = -0.015,
			BaseSpread = -0.008
		},
		VisualEffects = {
			HasReticle = true,
			ReticleType = "Holographic",
			ZoomFactor = 1.5
		}
	},
	
	-- Barrels
	Suppressor = {
		Name = "Suppressor",
		Category = "Barrels",
		Description = "Reduces noise and muzzle flash",
		StatModifiers = {
			BulletVelocity = -50,
			BaseSpread = -0.01,
			MovingSpread = -0.005,
			Damage = -2
		},
		VisualEffects = {
			MuzzleFlashReduction = 0.8,
			SoundReduction = 0.6
		},
		Special = {
			HidesMuzzleFlash = true,
			ReducesSound = true,
			HidesFromRadar = true
		}
	},
	Compensator = {
		Name = "Compensator",
		Category = "Barrels",
		Description = "Reduces vertical recoil",
		StatModifiers = {
			Recoil = {
				Vertical = -0.3,
				RandomFactor = -0.1
			}
		},
		VisualEffects = {
			MuzzleFlashIncrease = 1.2
		}
	},
	FlashHider = {
		Name = "Flash Hider",
		Category = "Barrels",
		Description = "Reduces muzzle flash",
		StatModifiers = {
			BaseSpread = -0.005
		},
		VisualEffects = {
			MuzzleFlashReduction = 0.7
		}
	},
	MuzzleBrake = {
		Name = "Muzzle Brake", 
		Category = "Barrels",
		Description = "Reduces horizontal recoil",
		StatModifiers = {
			Recoil = {
				Horizontal = -0.4,
				RandomFactor = -0.15
			}
		}
	},
	
	-- Underbarrel
	VerticalGrip = {
		Name = "Vertical Grip",
		Category = "Underbarrel", 
		Description = "Improves handling and reduces recoil",
		StatModifiers = {
			Recoil = {
				Vertical = -0.2,
				Horizontal = -0.15
			},
			MovingSpread = -0.01,
			AimSpread = -0.005
		}
	},
	AngledGrip = {
		Name = "Angled Grip",
		Category = "Underbarrel",
		Description = "Faster aim down sight speed",
		StatModifiers = {
			Recoil = {
				Horizontal = -0.1
			},
			MovingSpread = -0.005
		},
		Special = {
			ADSSpeedMultiplier = 1.2
		}
	},
	Bipod = {
		Name = "Bipod",
		Category = "Underbarrel",
		Description = "Dramatically improves accuracy when prone",
		StatModifiers = {
			WalkSpeedMultiplier = -0.05
		},
		Special = {
			ProneAccuracyBonus = 0.8,
			ProneRecoilReduction = 0.6
		}
	},
	
	-- Other
	LaserSight = {
		Name = "Laser Sight",
		Category = "Other",
		Description = "Improves hip fire accuracy",
		StatModifiers = {
			BaseSpread = -0.02,
			MovingSpread = -0.015
		},
		VisualEffects = {
			HasLaserBeam = true,
			LaserColor = Color3.fromRGB(255, 0, 0)
		}
	},
	Flashlight = {
		Name = "Flashlight",
		Category = "Other",
		Description = "Illuminates dark areas",
		StatModifiers = {},
		VisualEffects = {
			HasFlashlight = true,
			LightRange = 50
		},
		Special = {
			CanToggle = true,
			ToggleKey = "F"
		}
	},
	ExtendedMag = {
		Name = "Extended Magazine",
		Category = "Other",
		Description = "Increases magazine capacity",
		StatModifiers = {
			MaxAmmo = 10,
			ReloadTime = 0.3,
			WalkSpeedMultiplier = -0.02
		}
	},
	FMJRounds = {
		Name = "FMJ Rounds",
		Category = "Other",
		Description = "Increased penetration power",
		StatModifiers = {
			Penetration = 1.5,
			Damage = 3
		}
	}
}

-- Attachment slots for each weapon category
local ATTACHMENT_SLOTS = {
	Primary = {
		Sight = "Sights",
		Barrel = "Barrels", 
		Underbarrel = "Underbarrel",
		Other = "Other"
	},
	Secondary = {
		Sight = "Sights",
		Barrel = "Barrels",
		Other = "Other"
	}
}

function AttachmentManager:GetAttachmentConfig(attachmentName)
	return ATTACHMENT_CONFIGS[attachmentName]
end

function AttachmentManager:GetAttachmentsByCategory(category)
	local attachments = {}
	for name, config in pairs(ATTACHMENT_CONFIGS) do
		if config.Category == category then
			attachments[name] = config
		end
	end
	return attachments
end

function AttachmentManager:IsValidAttachment(attachmentName)
	return ATTACHMENT_CONFIGS[attachmentName] ~= nil
end

function AttachmentManager:CanAttachToWeapon(weaponName, attachmentName)
	local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
	local attachmentConfig = ATTACHMENT_CONFIGS[attachmentName]
	
	if not weaponConfig or not attachmentConfig then
		return false
	end
	
	return WeaponConfig:CanAttachAttachment(weaponName, attachmentConfig.Category)
end

function AttachmentManager:GetAvailableSlots(weaponName)
	local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not weaponConfig then return {} end
	
	return ATTACHMENT_SLOTS[weaponConfig.Category] or {}
end

function AttachmentManager:ApplyAttachmentModifiers(weaponConfig, attachments)
	if not attachments or #attachments == 0 then
		return weaponConfig
	end
	
	local modifiedConfig = {}
	for key, value in pairs(weaponConfig) do
		if type(value) == "table" then
			modifiedConfig[key] = {}
			for subKey, subValue in pairs(value) do
				modifiedConfig[key][subKey] = subValue
			end
		else
			modifiedConfig[key] = value
		end
	end
	
	for _, attachmentName in pairs(attachments) do
		local attachmentConfig = ATTACHMENT_CONFIGS[attachmentName]
		if attachmentConfig and attachmentConfig.StatModifiers then
			self:ApplyStatModifiers(modifiedConfig, attachmentConfig.StatModifiers)
		end
	end
	
	return modifiedConfig
end

function AttachmentManager:ApplyStatModifiers(weaponConfig, modifiers)
	for statName, modifier in pairs(modifiers) do
		if statName == "Recoil" and type(modifier) == "table" then
			for recoilStat, recoilModifier in pairs(modifier) do
				if weaponConfig.Recoil and weaponConfig.Recoil[recoilStat] then
					weaponConfig.Recoil[recoilStat] = math.max(0, weaponConfig.Recoil[recoilStat] + recoilModifier)
				end
			end
		elseif weaponConfig[statName] then
			if type(weaponConfig[statName]) == "number" then
				weaponConfig[statName] = weaponConfig[statName] + modifier
			end
		end
	end
end

function AttachmentManager:GetAttachmentVisualEffects(attachmentName)
	local config = ATTACHMENT_CONFIGS[attachmentName]
	return config and config.VisualEffects or {}
end

function AttachmentManager:GetAttachmentSpecialProperties(attachmentName)
	local config = ATTACHMENT_CONFIGS[attachmentName]
	return config and config.Special or {}
end

function AttachmentManager:ValidateLoadout(weaponName, attachments)
	local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not weaponConfig then
		return false, "Invalid weapon"
	end
	
	local availableSlots = self:GetAvailableSlots(weaponName)
	local usedSlots = {}
	
	for _, attachmentName in pairs(attachments) do
		local attachmentConfig = ATTACHMENT_CONFIGS[attachmentName]
		if not attachmentConfig then
			return false, "Invalid attachment: " .. attachmentName
		end
		
		if not self:CanAttachToWeapon(weaponName, attachmentName) then
			return false, "Incompatible attachment: " .. attachmentName
		end
		
		-- Check if slot is already used
		local slotName = nil
		for slot, category in pairs(availableSlots) do
			if category == attachmentConfig.Category then
				slotName = slot
				break
			end
		end
		
		if not slotName then
			return false, "No slot available for: " .. attachmentName
		end
		
		if usedSlots[slotName] then
			return false, "Slot conflict: " .. slotName
		end
		
		usedSlots[slotName] = attachmentName
	end
	
	return true
end

function AttachmentManager:GetLoadoutDescription(weaponName, attachments)
	local descriptions = {}
	
	for _, attachmentName in pairs(attachments) do
		local config = ATTACHMENT_CONFIGS[attachmentName]
		if config then
			table.insert(descriptions, config.Name .. ": " .. config.Description)
		end
	end
	
	return descriptions
end

-- Advanced stat calculation with attachment combinations
function AttachmentManager:CalculateModifiedStats(weaponName, attachments)
	local baseConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not baseConfig then
		return nil
	end
	
	local modifiedStats = self:ApplyAttachmentModifiers(baseConfig, attachments)
	
	-- Calculate derived stats
	local stats = {
		-- Core stats
		Damage = modifiedStats.Damage,
		FireRate = modifiedStats.FireRate,
		Range = modifiedStats.Range,
		MaxAmmo = modifiedStats.MaxAmmo,
		ReloadTime = modifiedStats.ReloadTime,
		
		-- Accuracy stats (lower is better)
		BaseSpread = modifiedStats.BaseSpread,
		AimSpread = modifiedStats.AimSpread,
		MovingSpread = modifiedStats.MovingSpread,
		
		-- Recoil stats (lower is better)
		VerticalRecoil = modifiedStats.Recoil and modifiedStats.Recoil.Vertical or 0,
		HorizontalRecoil = modifiedStats.Recoil and modifiedStats.Recoil.Horizontal or 0,
		
		-- Movement stats
		WalkSpeedMultiplier = modifiedStats.WalkSpeedMultiplier,
		AimWalkSpeedMultiplier = modifiedStats.AimWalkSpeedMultiplier,
		
		-- Ballistics
		BulletVelocity = modifiedStats.BulletVelocity,
		BulletDrop = modifiedStats.BulletDrop,
		Penetration = modifiedStats.Penetration,
		PenetrationPower = modifiedStats.PenetrationPower
	}
	
	-- Calculate composite stats
	stats.Accuracy = self:CalculateAccuracyRating(stats)
	stats.Recoil = self:CalculateRecoilRating(stats)
	stats.Mobility = self:CalculateMobilityRating(stats)
	stats.DPS = self:CalculateDPS(stats)
	
	return stats, modifiedStats
end

-- Calculate accuracy rating (0-100, higher is better)
function AttachmentManager:CalculateAccuracyRating(stats)
	local baseSpreadPenalty = (stats.BaseSpread or 0.05) * 1000
	local aimSpreadPenalty = (stats.AimSpread or 0.025) * 2000
	local movingSpreadPenalty = (stats.MovingSpread or 0.08) * 625
	
	local accuracy = 100 - math.min(100, baseSpreadPenalty + aimSpreadPenalty + movingSpreadPenalty)
	return math.max(0, math.floor(accuracy))
end

-- Calculate recoil rating (0-100, higher is better/lower recoil)
function AttachmentManager:CalculateRecoilRating(stats)
	local verticalPenalty = (stats.VerticalRecoil or 0.8) * 50
	local horizontalPenalty = (stats.HorizontalRecoil or 0.4) * 100
	
	local recoil = 100 - math.min(100, verticalPenalty + horizontalPenalty)
	return math.max(0, math.floor(recoil))
end

-- Calculate mobility rating (0-100, higher is better)
function AttachmentManager:CalculateMobilityRating(stats)
	local walkSpeedFactor = (stats.WalkSpeedMultiplier or 1.0) * 60
	local aimSpeedFactor = (stats.AimWalkSpeedMultiplier or 0.6) * 40
	
	local mobility = walkSpeedFactor + aimSpeedFactor
	return math.max(0, math.min(100, math.floor(mobility)))
end

-- Calculate damage per second
function AttachmentManager:CalculateDPS(stats)
	local damage = stats.Damage or 35
	local fireRate = stats.FireRate or 600
	
	return math.floor((damage * fireRate) / 60)
end

-- Get comprehensive attachment statistics for UI display
function AttachmentManager:GetAttachmentStatChanges(weaponName, currentAttachments, newAttachment)
	local baseStats, _ = self:CalculateModifiedStats(weaponName, currentAttachments)
	
	local newAttachments = {}
	for _, att in pairs(currentAttachments) do
		table.insert(newAttachments, att)
	end
	table.insert(newAttachments, newAttachment)
	
	local modifiedStats, _ = self:CalculateModifiedStats(weaponName, newAttachments)
	
	if not baseStats or not modifiedStats then
		return {}
	end
	
	local changes = {}
	
	-- Compare key stats
	local statsToCompare = {
		"Damage", "FireRate", "Range", "MaxAmmo", "ReloadTime",
		"Accuracy", "Recoil", "Mobility", "DPS",
		"BulletVelocity", "Penetration"
	}
	
	for _, statName in pairs(statsToCompare) do
		local baseStat = baseStats[statName]
		local newStat = modifiedStats[statName]
		
		if baseStat and newStat and baseStat ~= newStat then
			local change = newStat - baseStat
			local percentChange = (change / baseStat) * 100
			
			changes[statName] = {
				BaseValue = baseStat,
				NewValue = newStat,
				Change = change,
				PercentChange = percentChange,
				IsPositive = change > 0
			}
		end
	end
	
	return changes
end

-- Check if specific attachment combinations have conflicts or synergies
function AttachmentManager:CheckAttachmentSynergy(attachments)
	local synergies = {}
	local conflicts = {}
	
	-- Define synergies and conflicts
	local synergyRules = {
		{{"Suppressor", "LaserSight"}, "Stealth build - reduced signature with improved hip fire"},
		{{"ACOGScope", "Bipod"}, "Marksman build - long range accuracy with stability"},
		{{"VerticalGrip", "Compensator"}, "Recoil control - excellent stability"},
		{{"ExtendedMag", "FMJRounds"}, "Sustained fire - more ammo with better penetration"}
	}
	
	local conflictRules = {
		{{"Suppressor", "Compensator"}, "Barrel attachments conflict"},
		{{"FlashHider", "MuzzleBrake"}, "Cannot use multiple barrel attachments"}
	}
	
	-- Check for synergies
	for _, rule in pairs(synergyRules) do
		local requiredAttachments, description = rule[1], rule[2]
		local hasAllAttachments = true
		
		for _, required in pairs(requiredAttachments) do
			local found = false
			for _, attached in pairs(attachments) do
				if attached == required then
					found = true
					break
				end
			end
			if not found then
				hasAllAttachments = false
				break
			end
		end
		
		if hasAllAttachments then
			table.insert(synergies, {
				Attachments = requiredAttachments,
				Description = description
			})
		end
	end
	
	-- Check for conflicts
	for _, rule in pairs(conflictRules) do
		local conflictingAttachments, description = rule[1], rule[2]
		local conflictCount = 0
		
		for _, conflicting in pairs(conflictingAttachments) do
			for _, attached in pairs(attachments) do
				if attached == conflicting then
					conflictCount = conflictCount + 1
					break
				end
			end
		end
		
		if conflictCount >= 2 then
			table.insert(conflicts, {
				Attachments = conflictingAttachments,
				Description = description
			})
		end
	end
	
	return synergies, conflicts
end

-- Generate attachment unlock requirements based on weapon mastery
function AttachmentManager:GetAttachmentUnlockRequirement(weaponName, attachmentName)
	local attachmentConfig = ATTACHMENT_CONFIGS[attachmentName]
	if not attachmentConfig then
		return nil
	end
	
	-- Different unlock requirements based on attachment rarity/power
	local unlockRequirements = {
		-- Basic attachments (low kills requirement)
		RedDotSight = {Kills = 50, Cost = 0},
		FlashHider = {Kills = 25, Cost = 0},
		VerticalGrip = {Kills = 75, Cost = 0},
		
		-- Intermediate attachments
		HolographicSight = {Kills = 150, Cost = 100},
		Compensator = {Kills = 200, Cost = 150},
		AngledGrip = {Kills = 125, Cost = 75},
		LaserSight = {Kills = 100, Cost = 50},
		
		-- Advanced attachments
		ACOGScope = {Kills = 300, Cost = 200},
		Suppressor = {Kills = 400, Cost = 300},
		Bipod = {Kills = 500, Cost = 250},
		
		-- High-tier attachments
		ExtendedMag = {Kills = 250, Cost = 200},
		FMJRounds = {Kills = 350, Cost = 250},
		Flashlight = {Kills = 10, Cost = 25}, -- Utility item
		MuzzleBrake = {Kills = 300, Cost = 175}
	}
	
	return unlockRequirements[attachmentName] or {Kills = 100, Cost = 100}
end

-- Get all attachments available for a specific weapon
function AttachmentManager:GetCompatibleAttachments(weaponName)
	local compatible = {}
	
	for attachmentName, config in pairs(ATTACHMENT_CONFIGS) do
		if self:CanAttachToWeapon(weaponName, attachmentName) then
			compatible[attachmentName] = {
				Config = config,
				UnlockRequirement = self:GetAttachmentUnlockRequirement(weaponName, attachmentName)
			}
		end
	end
	
	return compatible
end

return AttachmentManager