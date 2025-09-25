local BulletPenetrationSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

-- Material penetration properties
local MATERIAL_PROPERTIES = {
	-- Soft materials - high penetration
	Fabric = {
		PenetrationPower = 95,
		DamageRetention = 0.95,
		RicochetChance = 0.05,
		Name = "Fabric"
	},
	ForceField = {
		PenetrationPower = 98,
		DamageRetention = 0.98,
		RicochetChance = 0.02,
		Name = "Force Field"
	},
	Grass = {
		PenetrationPower = 90,
		DamageRetention = 0.90,
		RicochetChance = 0.10,
		Name = "Grass"
	},
	Leaves = {
		PenetrationPower = 92,
		DamageRetention = 0.92,
		RicochetChance = 0.08,
		Name = "Leaves"
	},
	
	-- Wood materials - moderate penetration
	Wood = {
		PenetrationPower = 70,
		DamageRetention = 0.75,
		RicochetChance = 0.15,
		Name = "Wood"
	},
	WoodPlanks = {
		PenetrationPower = 65,
		DamageRetention = 0.70,
		RicochetChance = 0.20,
		Name = "Wood Planks"
	},
	
	-- Brick/Stone - low penetration
	Brick = {
		PenetrationPower = 40,
		DamageRetention = 0.50,
		RicochetChance = 0.35,
		Name = "Brick"
	},
	Concrete = {
		PenetrationPower = 35,
		DamageRetention = 0.45,
		RicochetChance = 0.40,
		Name = "Concrete"
	},
	Rock = {
		PenetrationPower = 30,
		DamageRetention = 0.40,
		RicochetChance = 0.45,
		Name = "Rock"
	},
	Cobblestone = {
		PenetrationPower = 32,
		DamageRetention = 0.42,
		RicochetChance = 0.43,
		Name = "Cobblestone"
	},
	
	-- Metal materials - very low penetration, high ricochet
	Metal = {
		PenetrationPower = 15,
		DamageRetention = 0.25,
		RicochetChance = 0.70,
		Name = "Metal"
	},
	CorrodedMetal = {
		PenetrationPower = 20,
		DamageRetention = 0.30,
		RicochetChance = 0.65,
		Name = "Corroded Metal"
	},
	DiamondPlate = {
		PenetrationPower = 10,
		DamageRetention = 0.20,
		RicochetChance = 0.75,
		Name = "Diamond Plate"
	},
	
	-- Glass - special case
	Glass = {
		PenetrationPower = 85,
		DamageRetention = 0.95,
		RicochetChance = 0.05,
		Name = "Glass",
		Shatters = true
	},
	
	-- Plastic materials
	Plastic = {
		PenetrationPower = 75,
		DamageRetention = 0.80,
		RicochetChance = 0.20,
		Name = "Plastic"
	},
	SmoothPlastic = {
		PenetrationPower = 78,
		DamageRetention = 0.82,
		RicochetChance = 0.18,
		Name = "Smooth Plastic"
	},
	
	-- Special materials
	Ice = {
		PenetrationPower = 60,
		DamageRetention = 0.85,
		RicochetChance = 0.25,
		Name = "Ice",
		Shatters = true
	},
	Sand = {
		PenetrationPower = 55,
		DamageRetention = 0.60,
		RicochetChance = 0.10,
		Name = "Sand"
	},
	Snow = {
		PenetrationPower = 88,
		DamageRetention = 0.90,
		RicochetChance = 0.05,
		Name = "Snow"
	},
	
	-- Default for unknown materials
	Default = {
		PenetrationPower = 50,
		DamageRetention = 0.65,
		RicochetChance = 0.25,
		Name = "Unknown"
	}
}

-- Ammo type modifiers
local AMMO_MODIFIERS = {
	FMJ = {
		PenetrationMultiplier = 1.5,
		DamageRetentionMultiplier = 1.2,
		RicochetReduction = 0.1,
		Name = "Full Metal Jacket"
	},
	AP = {
		PenetrationMultiplier = 2.0,
		DamageRetentionMultiplier = 1.4,
		RicochetReduction = 0.15,
		Name = "Armor Piercing"
	},
	HP = {
		PenetrationMultiplier = 0.7,
		DamageRetentionMultiplier = 0.8,
		RicochetReduction = -0.05,
		Name = "Hollow Point"
	},
	Incendiary = {
		PenetrationMultiplier = 1.2,
		DamageRetentionMultiplier = 1.1,
		RicochetReduction = 0.05,
		Name = "Incendiary",
		Effect = "Fire"
	},
	Tracer = {
		PenetrationMultiplier = 1.0,
		DamageRetentionMultiplier = 1.0,
		RicochetReduction = 0,
		Name = "Tracer",
		Effect = "Light"
	}
}

function BulletPenetrationSystem:Initialize()
	print("BulletPenetrationSystem initialized")
end

function BulletPenetrationSystem:ProcessPenetration(raycastResult, weaponData, direction, startPosition)
	if not raycastResult or not weaponData then
		return nil
	end
	
	local hitPart = raycastResult.Instance
	local hitPosition = raycastResult.Position
	local hitNormal = raycastResult.Normal
	
	-- Get material properties
	local materialProps = self:GetMaterialProperties(hitPart.Material)
	
	-- Get ammo modifier if specified
	local ammoType = weaponData.AmmoType or "Standard"
	local ammoMod = AMMO_MODIFIERS[ammoType]
	
	-- Calculate penetration power based on weapon and ammo
	local basePenetration = weaponData.PenetrationPower or 50
	local finalPenetration = basePenetration
	
	if ammoMod then
		finalPenetration = finalPenetration * ammoMod.PenetrationMultiplier
	end
	
	-- Check if bullet can penetrate
	if finalPenetration < materialProps.PenetrationPower then
		-- Check for ricochet
		local angle = self:CalculateAngle(direction, hitNormal)
		local ricochetChance = materialProps.RicochetChance
		
		if ammoMod and ammoMod.RicochetReduction then
			ricochetChance = math.max(0, ricochetChance - ammoMod.RicochetReduction)
		end
		
		if angle > 60 and math.random() < ricochetChance then
			return self:CalculateRicochet(hitPosition, direction, hitNormal, materialProps, weaponData)
		else
			-- Bullet stops
			self:CreateImpactEffect(hitPosition, hitNormal, materialProps, weaponData)
			return nil
		end
	end
	
	-- Calculate exit point
	local exitResult = self:FindExitPoint(hitPart, hitPosition, direction)
	if not exitResult then
		-- Bullet stops inside object
		self:CreateImpactEffect(hitPosition, hitNormal, materialProps, weaponData)
		return nil
	end
	
	-- Calculate damage retention
	local damageRetention = materialProps.DamageRetention
	if ammoMod then
		damageRetention = damageRetention * ammoMod.DamageRetentionMultiplier
	end
	
	-- Create entry and exit effects
	self:CreateImpactEffect(hitPosition, hitNormal, materialProps, weaponData, "entry")
	self:CreateImpactEffect(exitResult.position, exitResult.normal, materialProps, weaponData, "exit")
	
	-- Handle special material effects
	if materialProps.Shatters then
		self:CreateShatterEffect(hitPart, hitPosition)
	end
	
	-- Apply ammo effects
	if ammoMod and ammoMod.Effect then
		self:ApplyAmmoEffect(hitPart, hitPosition, ammoMod.Effect)
	end
	
	return {
		Position = exitResult.position,
		Direction = direction, -- Could add slight deviation here
		DamageMultiplier = damageRetention,
		Material = materialProps.Name,
		Penetrated = true
	}
end

function BulletPenetrationSystem:GetMaterialProperties(material)
	return MATERIAL_PROPERTIES[tostring(material)] or MATERIAL_PROPERTIES.Default
end

function BulletPenetrationSystem:CalculateAngle(direction, normal)
	local dot = direction:Dot(normal)
	return math.deg(math.acos(math.abs(dot)))
end

function BulletPenetrationSystem:FindExitPoint(part, entryPoint, direction)
	-- Cast ray from inside the part to find exit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {part}
	
	-- Start slightly inside the part
	local startPos = entryPoint + direction * 0.1
	local rayLength = part.Size.Magnitude * 2 -- Maximum possible thickness
	
	local result = Workspace:Raycast(startPos, direction * rayLength, raycastParams)
	
	if result then
		return {
			position = result.Position,
			normal = result.Normal
		}
	end
	
	return nil
end

function BulletPenetrationSystem:CalculateRicochet(hitPosition, direction, normal, materialProps, weaponData)
	-- Calculate ricochet direction
	local ricochetDir = direction - 2 * direction:Dot(normal) * normal
	
	-- Add some random deviation
	local deviation = Vector3.new(
		(math.random() - 0.5) * 0.2,
		(math.random() - 0.5) * 0.2,
		(math.random() - 0.5) * 0.2
	)
	ricochetDir = (ricochetDir + deviation).Unit
	
	-- Create ricochet spark effect
	self:CreateRicochetEffect(hitPosition, ricochetDir)
	
	return {
		Position = hitPosition + normal * 0.1, -- Offset from surface
		Direction = ricochetDir,
		DamageMultiplier = 0.6, -- Ricochets do less damage
		Material = materialProps.Name,
		Ricocheted = true
	}
end

function BulletPenetrationSystem:CreateImpactEffect(position, normal, materialProps, weaponData, effectType)
	-- Create impact particle effect based on material
	local effectPart = Instance.new("Part")
	effectPart.Name = "ImpactEffect"
	effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
	effectPart.Transparency = 1
	effectPart.CanCollide = false
	effectPart.Anchored = true
	effectPart.Position = position
	effectPart.Parent = Workspace
	
	-- Material-specific effects
	if materialProps.Name:find("Wood") then
		self:CreateWoodChipEffect(effectPart, normal)
	elseif materialProps.Name:find("Metal") then
		self:CreateSparkEffect(effectPart, normal)
	elseif materialProps.Name:find("Concrete") or materialProps.Name:find("Brick") then
		self:CreateDustEffect(effectPart, normal)
	elseif materialProps.Name == "Glass" then
		self:CreateGlassShardEffect(effectPart, normal)
	else
		self:CreateGenericImpactEffect(effectPart, normal)
	end
	
	-- Create bullet hole decal (entry only)
	if effectType == "entry" or not effectType then
		self:CreateBulletHole(position, normal)
	end
	
	-- Cleanup effect
	game:GetService("Debris"):AddItem(effectPart, 5)
end

function BulletPenetrationSystem:CreateWoodChipEffect(parent, normal)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
    particles.Texture = "rbxassetid://112124960561378" -- Wood chip texture
	particles.Lifetime = NumberRange.new(0.5, 1.0)
	particles.Rate = 50
	particles.SpreadAngle = Vector2.new(30, 30)
	particles.Speed = NumberRange.new(10, 25)
	particles.Color = ColorSequence.new(Color3.new(0.4, 0.25, 0.1))
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.05)
	}
	particles.Acceleration = Vector3.new(0, -50, 0)
	
	particles:Emit(15)
end

function BulletPenetrationSystem:CreateSparkEffect(parent, normal)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
    particles.Texture = "rbxassetid://4911290894" -- Spark texture
	particles.Lifetime = NumberRange.new(0.2, 0.5)
	particles.Rate = 100
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Speed = NumberRange.new(20, 40)
	particles.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0.5)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.5, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(0.5, 0, 0))
	}
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.02)
	}
	particles.Acceleration = Vector3.new(0, -100, 0)
	particles.LightEmission = 1
	
	particles:Emit(25)
end

function BulletPenetrationSystem:CreateDustEffect(parent, normal)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
    particles.Texture = "rbxassetid://4449493087" -- Dust texture
	particles.Lifetime = NumberRange.new(1.0, 2.0)
	particles.Rate = 30
	particles.SpreadAngle = Vector2.new(60, 60)
	particles.Speed = NumberRange.new(5, 15)
	particles.Color = ColorSequence.new(Color3.new(0.7, 0.7, 0.6))
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.5)
	}
	particles.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	}
	particles.Acceleration = Vector3.new(0, -20, 0)
	
	particles:Emit(20)
end

function BulletPenetrationSystem:CreateGlassShardEffect(parent, normal)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
    particles.Texture = "rbxassetid://3627661626" -- Glass shard texture
	particles.Lifetime = NumberRange.new(0.8, 1.5)
	particles.Rate = 40
	particles.SpreadAngle = Vector2.new(90, 90)
	particles.Speed = NumberRange.new(10, 30)
	particles.Color = ColorSequence.new(Color3.new(0.9, 0.9, 1))
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 0.03)
	}
	particles.Acceleration = Vector3.new(0, -80, 0)
	particles.LightEmission = 0.5
	
	particles:Emit(30)
end

function BulletPenetrationSystem:CreateGenericImpactEffect(parent, normal)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
    particles.Texture = "rbxassetid://4449493087"
	particles.Lifetime = NumberRange.new(0.3, 0.8)
	particles.Rate = 25
	particles.SpreadAngle = Vector2.new(30, 30)
	particles.Speed = NumberRange.new(8, 20)
	particles.Color = ColorSequence.new(Color3.new(0.5, 0.5, 0.5))
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.05)
	}
	particles.Acceleration = Vector3.new(0, -30, 0)
	
	particles:Emit(10)
end

function BulletPenetrationSystem:CreateRicochetEffect(position, direction)
	local effectPart = Instance.new("Part")
	effectPart.Name = "RicochetEffect"
	effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
	effectPart.Transparency = 1
	effectPart.CanCollide = false
	effectPart.Anchored = true
	effectPart.Position = position
	effectPart.Parent = Workspace
	
	-- Ricochet spark trail
	local attachment = Instance.new("Attachment")
	attachment.Parent = effectPart
	
	local trail = Instance.new("Trail")
	trail.Parent = effectPart
	trail.Attachment0 = attachment
	trail.Attachment1 = attachment
	trail.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
	}
	trail.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	}
	trail.Lifetime = 0.3
	trail.MinLength = 0
	trail.FaceCamera = true
	
	-- Animate trail
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
	local tween = game:GetService("TweenService"):Create(effectPart, tweenInfo, {
		Position = position + direction * 5
	})
	tween:Play()
	
	-- Play ricochet sound
	local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://7842386350" -- Ricochet sound
	sound.Volume = 0.5
	sound.Pitch = math.random(8, 12) / 10
	sound.Parent = effectPart
	sound:Play()
	
	game:GetService("Debris"):AddItem(effectPart, 2)
end

function BulletPenetrationSystem:CreateShatterEffect(part, position)
	-- Create glass shatter effect for glass/ice
	if part.Material == Enum.Material.Glass or part.Material == Enum.Material.Ice then
		-- Create multiple smaller fragments
		for i = 1, 5 do
			local fragment = part:Clone()
			fragment.Size = part.Size / 3
			fragment.Position = position + Vector3.new(
				(math.random() - 0.5) * part.Size.X,
				(math.random() - 0.5) * part.Size.Y,
				(math.random() - 0.5) * part.Size.Z
			)
			fragment.CanCollide = false
			fragment.Anchored = false
			fragment.Parent = Workspace
			
			-- Add random velocity
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = Vector3.new(
				(math.random() - 0.5) * 50,
				math.random() * 30,
				(math.random() - 0.5) * 50
			)
			bodyVelocity.Parent = fragment
			
			game:GetService("Debris"):AddItem(fragment, 10)
		end
		
		-- Play shatter sound
		local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://9114590269" -- Glass shatter sound
		sound.Volume = 0.8
		sound.Pitch = 1.2
		sound.Parent = part
		sound:Play()
	end
end

function BulletPenetrationSystem:CreateBulletHole(position, normal)
	-- Create bullet hole decal
	local bulletHole = Instance.new("Part")
	bulletHole.Name = "BulletHole"
	bulletHole.Size = Vector3.new(0.1, 0.1, 0.1)
	bulletHole.Transparency = 1
	bulletHole.CanCollide = false
	bulletHole.Anchored = true
	bulletHole.CFrame = CFrame.lookAt(position + normal * 0.01, position + normal)
	bulletHole.Parent = Workspace
	
	local decal = Instance.new("Decal")
    decal.Texture = "rbxassetid://11543553311" -- Bullet hole texture
	decal.Face = Enum.NormalId.Back
	decal.Color3 = Color3.new(0.2, 0.2, 0.2)
	decal.Parent = bulletHole
	
	game:GetService("Debris"):AddItem(bulletHole, 30) -- Remove after 30 seconds
end

function BulletPenetrationSystem:ApplyAmmoEffect(part, position, effect)
	if effect == "Fire" then
		-- Create fire effect for incendiary rounds
		local fire = Instance.new("Fire")
		fire.Size = 5
		fire.Heat = 10
		fire.Parent = part
		
		-- Remove fire after a few seconds
		game:GetService("Debris"):AddItem(fire, 8)
		
	elseif effect == "Light" then
		-- Create light for tracer rounds
		local light = Instance.new("PointLight")
		light.Color = Color3.new(1, 1, 0.5)
		light.Brightness = 2
		light.Range = 10
		light.Parent = part
		
		game:GetService("Debris"):AddItem(light, 0.5)
	end
end

-- Get penetration info for UI/debugging
function BulletPenetrationSystem:GetMaterialInfo(material)
	local props = self:GetMaterialProperties(material)
	return {
		Name = props.Name,
		PenetrationPower = props.PenetrationPower,
		DamageRetention = props.DamageRetention * 100,
		RicochetChance = props.RicochetChance * 100
	}
end

function BulletPenetrationSystem:GetAmmoInfo(ammoType)
	local ammo = AMMO_MODIFIERS[ammoType]
	if ammo then
		return {
			Name = ammo.Name,
			PenetrationMultiplier = ammo.PenetrationMultiplier,
			DamageRetentionMultiplier = ammo.DamageRetentionMultiplier,
			Effect = ammo.Effect
		}
	end
	return nil
end

-- Console commands for testing
_G.PenetrationCommands = {
	testMaterial = function(materialName)
		local material = Enum.Material[materialName]
		if material then
			local info = BulletPenetrationSystem:GetMaterialInfo(material)
			print("Material: " .. info.Name)
			print("Penetration Power: " .. info.PenetrationPower)
			print("Damage Retention: " .. info.DamageRetention .. "%")
			print("Ricochet Chance: " .. info.RicochetChance .. "%")
		else
			print("Invalid material. Available materials:")
			for name, _ in pairs(MATERIAL_PROPERTIES) do
				print("- " .. name)
			end
		end
	end,
	
	listMaterials = function()
		print("Material penetration properties:")
		for name, props in pairs(MATERIAL_PROPERTIES) do
			print(name .. ": " .. props.PenetrationPower .. "% penetration, " .. (props.RicochetChance * 100) .. "% ricochet")
		end
	end,
	
	listAmmoTypes = function()
		print("Available ammo types:")
		for name, ammo in pairs(AMMO_MODIFIERS) do
			print(name .. ": " .. ammo.Name .. " (x" .. ammo.PenetrationMultiplier .. " penetration)")
		end
	end
}

return BulletPenetrationSystem