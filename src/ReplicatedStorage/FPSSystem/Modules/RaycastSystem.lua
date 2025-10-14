local RaycastSystem = {}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local raycastParams = RaycastParams.new()
local bulletTracers = {}

-- Material penetration resistance (higher = harder to penetrate)
local MATERIAL_PENETRATION = {
	[Enum.Material.Wood] = 0.3,
	[Enum.Material.WoodPlanks] = 0.3,
	[Enum.Material.Plastic] = 0.5,
	[Enum.Material.Metal] = 0.8,
	[Enum.Material.Concrete] = 0.9,
	[Enum.Material.Brick] = 0.7,
	[Enum.Material.Glass] = 0.1,
	[Enum.Material.Ice] = 0.2,
	[Enum.Material.Snow] = 0.1,
	[Enum.Material.Grass] = 0.1,
	[Enum.Material.Sand] = 0.2,
	[Enum.Material.Rock] = 0.9,
	[Enum.Material.Granite] = 0.9,
	[Enum.Material.Marble] = 0.8,
	[Enum.Material.Slate] = 0.85,
	[Enum.Material.CorrodedMetal] = 0.6,
	[Enum.Material.DiamondPlate] = 0.95,
	[Enum.Material.Foil] = 0.2,
	[Enum.Material.Fabric] = 0.1,
	[Enum.Material.SmoothPlastic] = 0.4,
	[Enum.Material.Neon] = 0.3,
	[Enum.Material.ForceField] = 0.0,
	[Enum.Material.Water] = 0.1
}

-- Material damage multipliers (impact on bullet damage)
local MATERIAL_DAMAGE_REDUCTION = {
	[Enum.Material.Wood] = 0.9,
	[Enum.Material.WoodPlanks] = 0.9,
	[Enum.Material.Plastic] = 0.95,
	[Enum.Material.Metal] = 0.8,
	[Enum.Material.Concrete] = 0.75,
	[Enum.Material.Brick] = 0.8,
	[Enum.Material.Glass] = 0.98,
	[Enum.Material.Ice] = 0.95,
	[Enum.Material.Snow] = 0.98,
	[Enum.Material.Grass] = 0.99,
	[Enum.Material.Sand] = 0.97,
	[Enum.Material.Rock] = 0.7,
	[Enum.Material.Granite] = 0.65,
	[Enum.Material.Marble] = 0.75
}

-- Sound effects for different materials
local MATERIAL_SOUNDS = {
	[Enum.Material.Wood] = {142082165, 142082184, 142082170},
    [Enum.Material.Metal] = {6737582037, 131961140, 131961144},
	[Enum.Material.Concrete] = {130972023, 130985970, 130972121},
    [Enum.Material.Glass] = {9116673678, 131961140, 131961144},
	[Enum.Material.Plastic] = {142082184, 142082165}
}

function RaycastSystem:Initialize()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = false

	if RunService:IsClient() then
		local weaponFiredEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("WeaponFired")
		if weaponFiredEvent then
			weaponFiredEvent.OnClientEvent:Connect(function(shooter, fireData)
				if shooter ~= Players.LocalPlayer then
					self:CreateBulletTracer(fireData.Origin, fireData.Direction, fireData.WeaponName)
				end
			end)
		end
	end

	print("RaycastSystem initialized")
end

function RaycastSystem:CastRay(origin, direction, distance, ignoreList)
	local filterList = ignoreList or {}
	raycastParams.FilterDescendantsInstances = filterList
	
	local raycastResult = Workspace:Raycast(origin, direction * distance, raycastParams)
	
	return raycastResult
end

function RaycastSystem:FireRay(origin, direction, distance, weaponName, damage, penetration, ignoreList)
	local raycastResult = self:CastRay(origin, direction, distance, ignoreList)
	
	if raycastResult then
		local hitMultiplier = self:GetHitboxMultiplier(raycastResult.Instance, raycastResult.Position)
		local materialDamageReduction = MATERIAL_DAMAGE_REDUCTION[raycastResult.Material] or 1.0
		local finalDamage = damage * hitMultiplier * materialDamageReduction
		local player = self:GetPlayerFromHit(raycastResult.Instance)
		
		if RunService:IsClient() then
			self:CreateImpactEffect(raycastResult.Position, raycastResult.Normal, raycastResult.Material)
			self:PlayMaterialSound(raycastResult.Position, raycastResult.Material)
		end
		
		return {
			Hit = raycastResult.Instance,
			Position = raycastResult.Position,
			Normal = raycastResult.Normal,
			Distance = raycastResult.Distance,
			Material = raycastResult.Material,
			Player = player,
			Damage = finalDamage,
			IsHeadshot = self:IsHeadshot(raycastResult.Instance),
			IsWallbang = false,
			PenetrationRemaining = penetration
		}
	end
	
	return nil
end

-- Advanced raycast with bullet drop and velocity
function RaycastSystem:FireBallisticRay(origin, direction, distance, weaponConfig, ignoreList)
	local bulletVelocity = weaponConfig.BulletVelocity or 800
	local bulletDrop = weaponConfig.BulletDrop or 9.81
	local damage = weaponConfig.Damage or 35
	local penetrationPower = weaponConfig.PenetrationPower or 1.0
	
	-- Calculate bullet drop
	local timeToTarget = distance / bulletVelocity
	local dropAmount = 0.5 * bulletDrop * (timeToTarget * timeToTarget)
	
	-- Adjust direction for bullet drop
	local adjustedDirection = direction - Vector3.new(0, dropAmount / distance, 0)
	adjustedDirection = adjustedDirection.Unit
	
	-- Fire penetrating ray
	local penetrationResults = self:CastPenetratingRay(origin, adjustedDirection, distance, penetrationPower, ignoreList)
	
	local finalResults = {}
	for i, result in ipairs(penetrationResults) do
		local hitMultiplier = self:GetHitboxMultiplier(result.Instance, result.Position)
		local materialDamageReduction = MATERIAL_DAMAGE_REDUCTION[result.Material] or 1.0
		local distanceReduction = self:CalculateDamageDropoff(result.Distance, weaponConfig.Range or 1000)
		
		local finalDamage = damage * hitMultiplier * materialDamageReduction * distanceReduction
		local player = self:GetPlayerFromHit(result.Instance)
		
		if RunService:IsClient() then
			self:CreateImpactEffect(result.Position, result.Normal, result.Material)
			self:PlayMaterialSound(result.Position, result.Material)
		end
		
		table.insert(finalResults, {
			Hit = result.Instance,
			Position = result.Position,
			Normal = result.Normal,
			Distance = result.Distance,
			Material = result.Material,
			Player = player,
			Damage = finalDamage,
			IsHeadshot = self:IsHeadshot(result.Instance),
			IsWallbang = i > 1, -- If not the first hit, it's a wallbang
			PenetrationIndex = i
		})
		
		-- Stop at first player hit for damage calculations
		if player then
			break
		end
	end
	
	return finalResults
end

function RaycastSystem:CastMultipleRays(origin, direction, distance, rayCount, spread, ignoreList)
	local results = {}
	
	for i = 1, rayCount do
		local spreadX = (math.random() - 0.5) * spread
		local spreadY = (math.random() - 0.5) * spread
		local spreadZ = (math.random() - 0.5) * spread
		
		local spreadDirection = (direction + Vector3.new(spreadX, spreadY, spreadZ)).Unit
		local result = self:CastRay(origin, spreadDirection, distance, ignoreList)
		
		if result then
			table.insert(results, result)
		end
	end
	
	return results
end

function RaycastSystem:CastPenetratingRay(origin, direction, distance, penetrationPower, ignoreList)
	local penetrationResults = {}
	local currentOrigin = origin
	local currentDirection = direction
	local remainingDistance = distance
	local remainingPenetration = penetrationPower
	local currentIgnoreList = ignoreList or {}
	
	while remainingDistance > 0 and remainingPenetration > 0 do
		local result = self:CastRay(currentOrigin, currentDirection, remainingDistance, currentIgnoreList)
		
		if not result then
			break
		end
		
		table.insert(penetrationResults, result)
		
		local materialPenetration = MATERIAL_PENETRATION[result.Material] or 0.5
		local thickness = self:CalculatePartThickness(result.Instance, result.Position, currentDirection)
		local penetrationCost = materialPenetration * thickness
		
		if penetrationCost >= remainingPenetration then
			break
		end
		
		remainingPenetration = remainingPenetration - penetrationCost
		
		table.insert(currentIgnoreList, result.Instance)
		
		currentOrigin = result.Position + (currentDirection * 0.1)
		remainingDistance = remainingDistance - (result.Position - currentOrigin).Magnitude
	end
	
	return penetrationResults
end

function RaycastSystem:CalculatePartThickness(part, hitPosition, direction)
	if not part or not part:IsA("BasePart") then
		return 1
	end
	
	local size = part.Size
	local avgThickness = (size.X + size.Y + size.Z) / 3
	
	return math.min(avgThickness, 10)
end

function RaycastSystem:GetHitboxMultiplier(hit, position)
	if not hit or not hit.Parent then
		return 1.0
	end
	
	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if not humanoid then
		return 1.0
	end
	
	if hit.Name == "Head" then
		return 2.0
	elseif hit.Name == "Torso" or hit.Name == "UpperTorso" or hit.Name == "LowerTorso" then
		return 1.0
	elseif hit.Name:find("Arm") or hit.Name:find("Hand") then
		return 0.8
	elseif hit.Name:find("Leg") or hit.Name:find("Foot") then
		return 0.9
	end
	
	return 1.0
end

function RaycastSystem:GetPlayerFromHit(hit)
	if not hit or not hit.Parent then
		return nil
	end
	
	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if humanoid then
		return Players:GetPlayerFromCharacter(hit.Parent)
	end
	
	return nil
end

function RaycastSystem:IsHeadshot(hit)
	return hit and hit.Name == "Head"
end

function RaycastSystem:CalculateDamageDropoff(distance, maxRange, minDamagePercent)
	minDamagePercent = minDamagePercent or 0.3
	
	if distance <= maxRange * 0.3 then
		return 1.0
	elseif distance >= maxRange then
		return minDamagePercent
	else
		local dropoffRange = maxRange - (maxRange * 0.3)
		local dropoffDistance = distance - (maxRange * 0.3)
		local dropoffPercent = dropoffDistance / dropoffRange
		
		return 1.0 - (dropoffPercent * (1.0 - minDamagePercent))
	end
end

function RaycastSystem:CreateBulletTracer(origin, direction, weaponName)
	if not RunService:IsClient() then return end
	
	local endPosition = origin + (direction * 1000)
	
	local rayResult = self:CastRay(origin, direction, 1000)
	if rayResult then
		endPosition = rayResult.Position
	end
	
	local tracer = Instance.new("Part")
	tracer.Name = "BulletTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Material = Enum.Material.Neon
	tracer.BrickColor = BrickColor.new("Bright yellow")
	tracer.Size = Vector3.new(0.1, 0.1, (endPosition - origin).Magnitude)
	tracer.CFrame = CFrame.lookAt(origin + (endPosition - origin) / 2, endPosition)
	tracer.Parent = Workspace
	
	local tween = TweenService:Create(tracer, TweenInfo.new(0.1), {
		Transparency = 1
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		tracer:Destroy()
	end)
	
	if rayResult then
		self:CreateImpactEffect(rayResult.Position, rayResult.Normal, rayResult.Material)
	end
end

function RaycastSystem:CreateImpactEffect(position, normal, material)
	if not RunService:IsClient() then return end
	
	-- Create material-specific impact effects
	local effectColor = Color3.new(1, 0.5, 0) -- Default orange
	local effectSize = 0.5
	
	-- Customize effect based on material
	if material == Enum.Material.Metal or material == Enum.Material.DiamondPlate then
		effectColor = Color3.new(1, 1, 0.5) -- Yellow sparks for metal
		effectSize = 0.8
	elseif material == Enum.Material.Wood or material == Enum.Material.WoodPlanks then
		effectColor = Color3.new(0.8, 0.4, 0.2) -- Brown wood chips
		effectSize = 0.6
	elseif material == Enum.Material.Concrete or material == Enum.Material.Brick then
		effectColor = Color3.new(0.7, 0.7, 0.7) -- Gray dust
		effectSize = 0.7
	elseif material == Enum.Material.Glass then
		effectColor = Color3.new(0.8, 0.9, 1) -- Light blue glass shards
		effectSize = 0.4
	end
	
	-- Main impact spark
	local sparks = Instance.new("Part")
	sparks.Name = "ImpactSparks"
	sparks.Anchored = true
	sparks.CanCollide = false
	sparks.Material = Enum.Material.Neon
	sparks.Color = effectColor
	sparks.Size = Vector3.new(effectSize, effectSize, effectSize)
	sparks.Shape = Enum.PartType.Ball
	sparks.Position = position
	sparks.Parent = Workspace
	
	-- Impact particles
	for i = 1, 3 do
		local particle = Instance.new("Part")
		particle.Name = "ImpactParticle"
		particle.Anchored = true
		particle.CanCollide = false
		particle.Material = Enum.Material.Neon
		particle.Color = effectColor
		particle.Size = Vector3.new(0.1, 0.1, 0.1)
		particle.Shape = Enum.PartType.Ball
		particle.Position = position + Vector3.new(
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2
		)
		particle.Parent = Workspace
		
		local particleTween = TweenService:Create(particle, TweenInfo.new(0.5), {
			Size = Vector3.new(0, 0, 0),
			Transparency = 1,
			Position = particle.Position + Vector3.new(
				(math.random() - 0.5) * 10,
				(math.random() - 0.5) * 10,
				(math.random() - 0.5) * 10
			)
		})
		particleTween:Play()
		
		particleTween.Completed:Connect(function()
			particle:Destroy()
		end)
	end
	
	local sparkTween = TweenService:Create(sparks, TweenInfo.new(0.3), {
		Size = Vector3.new(0, 0, 0),
		Transparency = 1
	})
	sparkTween:Play()
	
	sparkTween.Completed:Connect(function()
		sparks:Destroy()
	end)
end

-- Play material-specific impact sounds
function RaycastSystem:PlayMaterialSound(position, material)
	if not RunService:IsClient() then return end
	
	local soundIds = MATERIAL_SOUNDS[material]
	if not soundIds then return end
	
	local randomSoundId = soundIds[math.random(1, #soundIds)]
	
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. randomSoundId
	sound.Volume = 0.5
	sound.Pitch = math.random(80, 120) / 100
	sound.Parent = Workspace
	
	-- Position sound at impact location
	local soundPart = Instance.new("Part")
	soundPart.Name = "SoundEmitter"
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new(1, 1, 1)
	soundPart.Position = position
	soundPart.Parent = Workspace
	
	sound.Parent = soundPart
	sound:Play()
	
	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)
	
	-- Cleanup after 2 seconds if sound doesn't end
	Debris:AddItem(soundPart, 2)
end

function RaycastSystem:CreateMuzzleFlash(origin, direction, weaponName)
	if not RunService:IsClient() then return end
	
	local muzzleFlash = Instance.new("Part")
	muzzleFlash.Name = "MuzzleFlash"
	muzzleFlash.Anchored = true
	muzzleFlash.CanCollide = false
	muzzleFlash.Material = Enum.Material.Neon
	muzzleFlash.BrickColor = BrickColor.new("Bright yellow")
	muzzleFlash.Size = Vector3.new(2, 2, 0.1)
	muzzleFlash.CFrame = CFrame.lookAt(origin, origin + direction)
	muzzleFlash.Parent = Workspace
	
	local flashTween = TweenService:Create(muzzleFlash, TweenInfo.new(0.05), {
		Transparency = 1,
		Size = Vector3.new(3, 3, 0.1)
	})
	flashTween:Play()
	
	flashTween.Completed:Connect(function()
		muzzleFlash:Destroy()
	end)
end

function RaycastSystem:ValidateRaycast(shooter, origin, direction, maxDistance)
	if not shooter or not shooter.Character then
		return false
	end
	
	local head = shooter.Character:FindFirstChild("Head")
	if not head then
		return false
	end
	
	local distanceFromHead = (origin - head.Position).Magnitude
	if distanceFromHead > 10 then
		return false
	end
	
	local rayLength = direction.Magnitude
	if rayLength > maxDistance then
		return false
	end
	
	return true
end

function RaycastSystem:CleanupTracers()
	for i = #bulletTracers, 1, -1 do
		local tracer = bulletTracers[i]
		if not tracer.Parent or tracer.Transparency >= 1 then
			table.remove(bulletTracers, i)
		end
	end
end

return RaycastSystem