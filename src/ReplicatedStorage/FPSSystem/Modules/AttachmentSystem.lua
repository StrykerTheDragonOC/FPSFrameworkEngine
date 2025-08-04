-- AttachmentSystem.lua
-- Enhanced attachment system with proper weapon modification support
-- Place in ReplicatedStorage.FPSSystem.Modules

local AttachmentSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants for attachment types and categories
local ATTACHMENT_TYPES = {
	SIGHT = "SIGHT",
	BARREL = "BARREL",
	UNDERBARREL = "UNDERBARREL",
	OTHER = "OTHER",
	AMMO = "AMMO"
}

-- Attachment category data - defines which slot each type corresponds to
local ATTACHMENT_CATEGORIES = {
	["Red Dot"] = ATTACHMENT_TYPES.SIGHT,
	["Holographic"] = ATTACHMENT_TYPES.SIGHT,
	["ACOG"] = ATTACHMENT_TYPES.SIGHT,
	["Scope"] = ATTACHMENT_TYPES.SIGHT,

	["Suppressor"] = ATTACHMENT_TYPES.BARREL,
	["Flash Hider"] = ATTACHMENT_TYPES.BARREL,
	["Compensator"] = ATTACHMENT_TYPES.BARREL,
	["Muzzle Brake"] = ATTACHMENT_TYPES.BARREL,

	["Vertical Grip"] = ATTACHMENT_TYPES.UNDERBARREL,
	["Angled Grip"] = ATTACHMENT_TYPES.UNDERBARREL,
	["Laser"] = ATTACHMENT_TYPES.UNDERBARREL,
	["Bipod"] = ATTACHMENT_TYPES.UNDERBARREL,

	["Extended Mag"] = ATTACHMENT_TYPES.OTHER,
	["Quick Mag"] = ATTACHMENT_TYPES.OTHER,
	["Tactical"] = ATTACHMENT_TYPES.OTHER,

	["Armor Piercing"] = ATTACHMENT_TYPES.AMMO,
	["Hollow Point"] = ATTACHMENT_TYPES.AMMO,
	["Subsonic"] = ATTACHMENT_TYPES.AMMO,
	["Incendiary"] = ATTACHMENT_TYPES.AMMO
}

-- Attachment mount positions (relative to weapon parts)
local ATTACHMENT_MOUNTS = {
	[ATTACHMENT_TYPES.SIGHT] = {
		attachmentPoint = "SightMount",
		defaultOffset = CFrame.new(0, 0.15, 0)
	},
	[ATTACHMENT_TYPES.BARREL] = {
		attachmentPoint = "BarrelMount",
		defaultOffset = CFrame.new(0, 0, -0.5)
	},
	[ATTACHMENT_TYPES.UNDERBARREL] = {
		attachmentPoint = "UnderbarrelMount",
		defaultOffset = CFrame.new(0, -0.15, -0.2)
	},
	[ATTACHMENT_TYPES.OTHER] = {
		attachmentPoint = "OtherMount",
		defaultOffset = CFrame.new(0, 0, 0)
	},
	[ATTACHMENT_TYPES.AMMO] = {
		attachmentPoint = "AmmoMount",
		defaultOffset = CFrame.new(0, 0, 0)
	}
}

-- Cache for attachment asset models
local attachmentModelCache = {}

-- Initialize attachment database
function AttachmentSystem.init()
	print("Initializing AttachmentSystem...")

	-- Create a folder to hold attachment definitions if it doesn't exist
	local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
	if not fpsSystem then
		fpsSystem = Instance.new("Folder")
		fpsSystem.Name = "FPSSystem"
		fpsSystem.Parent = ReplicatedStorage
	end

	local configFolder = fpsSystem:FindFirstChild("Config")
	if not configFolder then
		configFolder = Instance.new("Folder")
		configFolder.Name = "Config"
		configFolder.Parent = fpsSystem
	end

	print("AttachmentSystem initialized successfully!")
	return AttachmentSystem
end

-- Get attachment database
function AttachmentSystem.getAttachmentDatabase()
	-- Load from the attachment config object or create default database
	local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
	local configFolder = fpsSystem and fpsSystem:FindFirstChild("Config")
	local attachmentsConfig = configFolder and configFolder:FindFirstChild("AttachmentConfig")

	if attachmentsConfig and attachmentsConfig:IsA("ModuleScript") then
		local success, result = pcall(function()
			return require(attachmentsConfig)
		end)

		if success and type(result) == "table" then
			return result
		end
	end

	-- Return default attachment database
	return AttachmentSystem.getDefaultAttachments()
end

-- Create default attachment database
function AttachmentSystem.getDefaultAttachments()
	return {
		-- Sights
		["Red Dot"] = {
			name = "Red Dot Sight",
			description = "Basic red dot for improved accuracy",
			type = ATTACHMENT_TYPES.SIGHT,
			modelId = "rbxassetid://7548348915", -- Example ID, replace with actual asset
			compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol"},
			statModifiers = {
				aimSpeed = 0.95, -- 5% faster ADS
				recoil = {
					vertical = 0.95, -- 5% less vertical recoil
					horizontal = 0.95 -- 5% less horizontal recoil
				}
			},
			scopeSettings = {
				fov = 65,
				guiScoped = false,
				sensitivity = 0.9
			}
		},
		["ACOG"] = {
			name = "ACOG Sight",
			description = "4x magnification scope for medium range",
			type = ATTACHMENT_TYPES.SIGHT,
			modelId = "rbxassetid://7548348927", -- Example ID, replace with actual asset
			compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
			statModifiers = {
				aimSpeed = 0.8, -- 20% slower ADS
				recoil = {
					vertical = 0.9, -- 10% less vertical recoil
					horizontal = 0.9 -- 10% less horizontal recoil
				}
			},
			scopeSettings = {
				fov = 40,
				guiScoped = false,
				sensitivity = 0.7
			}
		},
		["Sniper Scope"] = {
			name = "Sniper Scope",
			description = "8x magnification scope for long range",
			type = ATTACHMENT_TYPES.SIGHT,
			modelId = "rbxassetid://7548348940", -- Example ID, replace with actual asset
			compatibleWeapons = {"AWP", "M24", "Dragunov", "SCAR-H"},
			statModifiers = {
				aimSpeed = 0.7, -- 30% slower ADS
				recoil = {
					vertical = 0.8, -- 20% less vertical recoil
					horizontal = 0.8 -- 20% less horizontal recoil
				}
			},
			scopeSettings = {
				fov = 20,
				guiScoped = true, -- Use GUI-based scope
				sensitivity = 0.5,
				scopeImage = "rbxassetid://7548348960" -- Scope overlay image
			}
		},

		-- Barrels
		["Suppressor"] = {
			name = "Suppressor",
			description = "Reduces sound and muzzle flash",
			type = ATTACHMENT_TYPES.BARREL,
			modelId = "rbxassetid://7548348980", -- Example ID, replace with actual asset
			compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "AWP"},
			statModifiers = {
				damage = 0.9, -- 10% less damage
				recoil = {
					vertical = 0.85, -- 15% less vertical recoil
					horizontal = 0.9 -- 10% less horizontal recoil
				},
				sound = 0.3, -- 70% quieter
				muzzleFlash = 0.2 -- 80% less visible muzzle flash
			}
		},
		["Compensator"] = {
			name = "Compensator",
			description = "Reduces horizontal recoil",
			type = ATTACHMENT_TYPES.BARREL,
			modelId = "rbxassetid://7548348990", -- Example ID, replace with actual asset
			compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
			statModifiers = {
				recoil = {
					horizontal = 0.7 -- 30% less horizontal recoil
				}
			}
		},

		-- Underbarrel
		["Vertical Grip"] = {
			name = "Vertical Grip",
			description = "Reduces vertical recoil",
			type = ATTACHMENT_TYPES.UNDERBARREL,
			modelId = "rbxassetid://7548349000", -- Example ID, replace with actual asset
			compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "SCAR-H"},
			statModifiers = {
				recoil = {
					vertical = 0.75 -- 25% less vertical recoil
				},
				aimSpeed = 0.95 -- 5% slower ADS
			}
		},
		["Angled Grip"] = {
			name = "Angled Grip",
			description = "Faster ADS time",
			type = ATTACHMENT_TYPES.UNDERBARREL,
			modelId = "rbxassetid://7548349010", -- Example ID, replace with actual asset
			compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
			statModifiers = {
				aimSpeed = 1.15, -- 15% faster ADS
				recoil = {
					initial = 0.85 -- 15% less initial recoil
				}
			}
		},
		["Laser"] = {
			name = "Laser Sight",
			description = "Improves hipfire accuracy",
			type = ATTACHMENT_TYPES.UNDERBARREL,
			modelId = "rbxassetid://7548349020", -- Example ID, replace with actual asset
			compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "SCAR-H"},
			statModifiers = {
				hipfireSpread = 0.7 -- 30% better hipfire accuracy
			},
			hasLaser = true,
			laserColor = Color3.fromRGB(255, 0, 0)
		},

		-- Ammo Types
		["Hollow Point"] = {
			name = "Hollow Point Rounds",
			description = "More damage to unarmored targets, less penetration",
			type = ATTACHMENT_TYPES.AMMO,
			compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "SCAR-H"},
			statModifiers = {
				damage = 1.2, -- 20% more damage
				penetration = 0.6 -- 40% less penetration
			}
		},
		["Armor Piercing"] = {
			name = "Armor Piercing Rounds",
			description = "Better penetration, slightly less damage",
			type = ATTACHMENT_TYPES.AMMO,
			compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H", "AWP"},
			statModifiers = {
				damage = 0.9, -- 10% less damage
				penetration = 1.5, -- 50% more penetration
				armorDamage = 1.4 -- 40% more damage to armored targets
			}
		}
	}
end

-- Get an attachment by name
function AttachmentSystem.getAttachment(attachmentName)
	local attachments = AttachmentSystem.getAttachmentDatabase()
	return attachments[attachmentName]
end

-- Check if an attachment is compatible with a weapon
function AttachmentSystem.isCompatible(attachmentName, weaponName)
	local attachment = AttachmentSystem.getAttachment(attachmentName)
	if not attachment then return false end

	if attachment.compatibleWeapons then
		for _, compatibleWeapon in ipairs(attachment.compatibleWeapons) do
			if compatibleWeapon == weaponName then
				return true
			end
		end
		return false
	end

	-- If no compatibility list is specified, assume compatible
	return true
end

-- Get the attachment category
function AttachmentSystem.getAttachmentCategory(attachmentName)
	return ATTACHMENT_CATEGORIES[attachmentName] or ATTACHMENT_TYPES.OTHER
end

-- Apply attachment to weapon config
function AttachmentSystem.applyAttachmentToConfig(weaponConfig, attachmentName)
	local attachment = AttachmentSystem.getAttachment(attachmentName)
	if not attachment or not attachment.statModifiers then 
		return weaponConfig 
	end

	local newConfig = table.clone(weaponConfig)

	-- Apply stat modifiers
	for stat, modifier in pairs(attachment.statModifiers) do
		if stat == "recoil" then
			-- Handle recoil subfields
			for recoilType, recoilMod in pairs(modifier) do
				if newConfig.recoil and newConfig.recoil[recoilType] then
					newConfig.recoil[recoilType] = newConfig.recoil[recoilType] * recoilMod
				end
			end
		elseif stat == "mobility" then
			-- Handle mobility subfields
			for mobilityType, mobilityMod in pairs(modifier) do
				if newConfig.mobility and newConfig.mobility[mobilityType] then
					newConfig.mobility[mobilityType] = newConfig.mobility[mobilityType] * mobilityMod
				end
			end
		elseif stat == "magazine" then
			-- Handle magazine subfields
			for magType, magMod in pairs(modifier) do
				if newConfig.magazine and newConfig.magazine[magType] then
					newConfig.magazine[magType] = newConfig.magazine[magType] * magMod
				end
			end
		else
			-- Handle direct stats like damage, range, etc.
			if type(newConfig[stat]) == "number" then
				newConfig[stat] = newConfig[stat] * modifier
			elseif type(modifier) == "table" and type(newConfig[stat]) == "table" then
				-- For complex stats that are tables
				for subStat, subMod in pairs(modifier) do
					if type(newConfig[stat][subStat]) == "number" then
						newConfig[stat][subStat] = newConfig[stat][subStat] * subMod
					end
				end
			end
		end
	end

	-- Add scope settings if present
	if attachment.scopeSettings then
		newConfig.scope = attachment.scopeSettings
	end

	-- Add laser settings if present
	if attachment.hasLaser then
		newConfig.laser = {
			enabled = true,
			color = attachment.laserColor or Color3.fromRGB(255, 0, 0)
		}
	end

	return newConfig
end

-- Get attachment model from cache or load it
function AttachmentSystem.getAttachmentModel(attachmentName)
	local attachment = AttachmentSystem.getAttachment(attachmentName)
	if not attachment or not attachment.modelId then return nil end

	-- Check cache first
	if attachmentModelCache[attachmentName] then
		return attachmentModelCache[attachmentName]:Clone()
	end

	-- Try to load from Assets folder
	local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
	local assetsFolder = fpsSystem and fpsSystem:FindFirstChild("Assets")
	local attachmentsFolder = assetsFolder and assetsFolder:FindFirstChild("Attachments")

	if attachmentsFolder then
		local model = attachmentsFolder:FindFirstChild(attachmentName)
		if model then
			attachmentModelCache[attachmentName] = model
			return model:Clone()
		end
	end

	-- Try to load from asset ID
	local success, model = pcall(function()
		return game:GetService("InsertService"):LoadAsset(attachment.modelId)
	end)

	if success and model then
		-- Cache the model
		attachmentModelCache[attachmentName] = model
		return model:Clone()
	end

	-- Fallback to creating a simple model
	return AttachmentSystem.createPlaceholderAttachment(attachmentName, attachment.type)
end

-- Create a placeholder attachment model
function AttachmentSystem.createPlaceholderAttachment(attachmentName, attachmentType)
	local model = Instance.new("Model")
	model.Name = attachmentName

	local part = Instance.new("Part")
	part.Name = "AttachmentPart"
	part.Anchored = true
	part.CanCollide = false

	-- Configure based on attachment type
	if attachmentType == ATTACHMENT_TYPES.SIGHT then
		part.Size = Vector3.new(0.2, 0.15, 0.3)
		part.Color = Color3.fromRGB(40, 40, 40)

		-- Add sight dot
		local dot = Instance.new("Part")
		dot.Name = "SightDot"
		dot.Size = Vector3.new(0.05, 0.05, 0.05)
		dot.Shape = Enum.PartType.Ball
		dot.Color = Color3.fromRGB(255, 0, 0)
		dot.Material = Enum.Material.Neon
		dot.Anchored = true
		dot.CanCollide = false
		dot.CFrame = part.CFrame * CFrame.new(0, 0.1, 0)
		dot.Parent = model
	elseif attachmentType == ATTACHMENT_TYPES.BARREL then
		part.Size = Vector3.new(0.15, 0.15, 0.5)
		part.Color = Color3.fromRGB(60, 60, 60)
	elseif attachmentType == ATTACHMENT_TYPES.UNDERBARREL then
		part.Size = Vector3.new(0.15, 0.25, 0.3)
		part.Color = Color3.fromRGB(50, 50, 50)
	else
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.Color = Color3.fromRGB(80, 80, 80)
	end

	part.Parent = model
	model.PrimaryPart = part

	return model
end

-- Attach an attachment to a weapon model
function AttachmentSystem.attachToWeapon(weaponModel, attachmentName)
	if not weaponModel then return nil end

	local attachment = AttachmentSystem.getAttachment(attachmentName)
	if not attachment then return nil end

	-- Get attachment type and mounting info
	local attachmentType = attachment.type or AttachmentSystem.getAttachmentCategory(attachmentName)
	local mountInfo = ATTACHMENT_MOUNTS[attachmentType]

	if not mountInfo then return nil end

	-- Get or create attachment model
	local attachmentModel = AttachmentSystem.getAttachmentModel(attachmentName)
	if not attachmentModel then return nil end

	-- Find attachment point on weapon
	local attachmentPoint = weaponModel:FindFirstChild(mountInfo.attachmentPoint, true)
	local mountPosition

	if attachmentPoint and attachmentPoint:IsA("Attachment") then
		mountPosition = attachmentPoint.WorldCFrame
	else
		-- Use default position if no attachment point found
		mountPosition = weaponModel.PrimaryPart.CFrame * mountInfo.defaultOffset
	end

	-- Position attachment
	attachmentModel:SetPrimaryPartCFrame(mountPosition)
	attachmentModel.Parent = weaponModel

	-- Connect parts to weapon
	for _, part in ipairs(attachmentModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false

			-- Add weld constraints if needed
			if not part.Anchored then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = weaponModel.PrimaryPart
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end

	-- Create special effects (laser, etc.)
	if attachment.hasLaser then
		AttachmentSystem.createLaserEffect(attachmentModel, attachment.laserColor)
	end

	return attachmentModel
end

-- Create laser effect for laser attachments
function AttachmentSystem.createLaserEffect(attachmentModel, color)
	local laserColor = color or Color3.fromRGB(255, 0, 0)

	-- Create laser emitter
	local emitter = attachmentModel:FindFirstChild("LaserEmitter")
	if not emitter then
		emitter = Instance.new("Attachment")
		emitter.Name = "LaserEmitter"
		emitter.Parent = attachmentModel.PrimaryPart
	end

	-- Create laser beam
	local beam = Instance.new("Beam")
	beam.Name = "LaserBeam"
	beam.Color = ColorSequence.new(laserColor)
	beam.Transparency = NumberSequence.new(0.2)
	beam.Width0 = 0.02
	beam.Width1 = 0.02
	beam.FaceCamera = true
	beam.Attachment0 = emitter

	-- Create endpoint attachment
	local endpoint = Instance.new("Attachment")
	endpoint.Name = "LaserEndpoint"
	endpoint.Parent = workspace.Terrain
	beam.Attachment1 = endpoint

	beam.Parent = emitter

	-- Set up laser update
	local updateFunction
	updateFunction = RunService.RenderStepped:Connect(function()
		if not emitter.Parent then
			updateFunction:Disconnect()
			endpoint:Destroy()
			return
		end

		-- Cast ray to find endpoint
		local origin = emitter.WorldPosition
		local direction = emitter.WorldCFrame.LookVector * 1000

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = {attachmentModel, Players.LocalPlayer.Character}

		local raycastResult = workspace:Raycast(origin, direction, raycastParams)

		if raycastResult then
			endpoint.WorldPosition = raycastResult.Position
		else
			endpoint.WorldPosition = origin + direction
		end
	end)

	-- Store update function for cleanup
	attachmentModel:SetAttribute("LaserUpdateConnection", true)

	return beam
end

-- Get available attachments for a weapon
function AttachmentSystem.getAvailableAttachments(weaponName)
	local attachments = AttachmentSystem.getAttachmentDatabase()
	local available = {}

	for name, attachment in pairs(attachments) do
		if AttachmentSystem.isCompatible(name, weaponName) then
			table.insert(available, {
				name = name,
				displayName = attachment.name,
				description = attachment.description,
				type = attachment.type or AttachmentSystem.getAttachmentCategory(name)
			})
		end
	end

	-- Sort by type
	table.sort(available, function(a, b)
		return a.type < b.type
	end)

	return available
end

-- Initialize the system
AttachmentSystem.init()

return AttachmentSystem