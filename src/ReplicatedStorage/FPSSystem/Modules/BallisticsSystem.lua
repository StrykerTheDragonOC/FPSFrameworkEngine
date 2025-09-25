local BallisticsSystem = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RaycastSystem = require(ReplicatedStorage.FPSSystem.Modules.RaycastSystem)
local DamageSystem = require(ReplicatedStorage.FPSSystem.Modules.DamageSystem)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local GRAVITY = 9.81
local AIR_RESISTANCE = 0.02

function BallisticsSystem:Initialize()
	RaycastSystem:Initialize()
	DamageSystem:Initialize()
	
	if RunService:IsServer() then
		RemoteEventsManager:Initialize()
		
		local weaponFiredEvent = RemoteEventsManager:GetEvent("WeaponFired")
		if weaponFiredEvent then
			weaponFiredEvent.OnServerEvent:Connect(function(player, fireData)
				self:ProcessWeaponFire(player, fireData)
			end)
		end
	end
	
	print("BallisticsSystem initialized")
end

function BallisticsSystem:ProcessWeaponFire(shooter, fireData)
	if not RunService:IsServer() then return end
	
	local weaponConfig = WeaponConfig:GetWeaponConfig(fireData.WeaponName)
	if not weaponConfig then return end
	
	local origin = fireData.Origin
	local direction = fireData.Direction
	local maxRange = weaponConfig.Range or 1000
	local penetrationPower = weaponConfig.Penetration or 1.0
	
	if weaponConfig.Category == "Primary" or weaponConfig.Category == "Secondary" then
		self:ProcessBulletFire(shooter, weaponConfig, origin, direction, maxRange, penetrationPower)
	elseif weaponConfig.Category == "Grenade" then
		self:ProcessGrenadeFire(shooter, weaponConfig, origin, direction)
	elseif weaponConfig.Category == "Melee" then
		self:ProcessMeleeAttack(shooter, weaponConfig, origin, direction)
	end
end

function BallisticsSystem:ProcessBulletFire(shooter, weaponConfig, origin, direction, maxRange, penetrationPower)
	local bulletVelocity = weaponConfig.BulletVelocity or 800
	local bulletDrop = weaponConfig.BulletDrop or GRAVITY
	
	-- Apply realistic spread based on weapon and player state
	local spreadDirection = self:ApplyWeaponSpread(direction, weaponConfig, shooter)
	
	local ballisticData = self:CalculateBallisticTrajectory(
		origin,
		spreadDirection,
		bulletVelocity,
		bulletDrop,
		maxRange
	)
	
	local penetrationResults = RaycastSystem:CastPenetratingRay(
		origin,
		direction,
		maxRange,
		penetrationPower,
		{shooter.Character}
	)
	
	if #penetrationResults > 0 then
		local hitResults = DamageSystem:ProcessPenetratingHit(shooter, weaponConfig, penetrationResults)
		
		for _, hitResult in pairs(hitResults) do
			print(shooter.Name .. " hit " .. hitResult.Victim.Name .. " for " .. hitResult.FinalDamage .. " damage")
		end
	else
		local singleResult = RaycastSystem:CastRay(origin, direction, maxRange, {shooter.Character})
		if singleResult then
			local distance = (singleResult.Position - origin).Magnitude
			local hitResult = DamageSystem:ProcessWeaponHit(shooter, weaponConfig, singleResult, distance)
			
			if hitResult and hitResult.Victim then
				print(shooter.Name .. " hit " .. hitResult.Victim.Name .. " for " .. hitResult.FinalDamage .. " damage")
			end
		end
	end
	
	RemoteEventsManager:FireAllClients("WeaponFired", shooter, {
		WeaponName = weaponConfig.Name,
		Origin = origin,
		Direction = direction,
		BallisticData = ballisticData,
		PlayerId = shooter.UserId
	})
end

function BallisticsSystem:CalculateBallisticTrajectory(origin, direction, velocity, gravity, maxRange)
	local trajectory = {}
	local currentPosition = origin
	local currentVelocity = direction * velocity
	local timeStep = 0.01 -- Smaller timestep for more accuracy
	local totalTime = 0
	local totalDistance = 0
	local maxTime = maxRange / velocity * 3 -- Increased buffer
	
	-- Enhanced ballistics with wind resistance and more realistic physics
	local windResistance = AIR_RESISTANCE * 1.5 -- More realistic air resistance
	local massEffect = 0.98 -- Bullet mass effect on trajectory
	
	while totalTime < maxTime and totalDistance < maxRange do
		local previousPosition = currentPosition
		
		-- Calculate forces acting on bullet
		local gravityEffect = Vector3.new(0, -gravity * timeStep, 0)
		local velocityMagnitude = currentVelocity.Magnitude
		local windResistanceEffect = currentVelocity * (-windResistance * velocityMagnitude * timeStep * massEffect)
		
		-- Apply Magnus effect (simplified) for spinning bullets
		local magnusEffect = Vector3.new(0, 0, 0)
		if velocityMagnitude > 100 then
			local crossWind = Vector3.new(0, 1, 0):Cross(currentVelocity.Unit)
			magnusEffect = crossWind * (velocityMagnitude * 0.0001 * timeStep)
		end
		
		-- Update velocity with all forces
		currentVelocity = currentVelocity + gravityEffect + windResistanceEffect + magnusEffect
		currentPosition = currentPosition + (currentVelocity * timeStep)
		
		-- Calculate distance traveled this step
		local stepDistance = (currentPosition - previousPosition).Magnitude
		totalDistance = totalDistance + stepDistance
		
		-- Store trajectory point every few steps to reduce memory usage
		if math.fmod(totalTime, 0.05) < timeStep then
			table.insert(trajectory, {
				Position = currentPosition,
				Velocity = currentVelocity,
				Time = totalTime,
				Distance = totalDistance
			})
		end
		
		totalTime = totalTime + timeStep
		
		-- Break if bullet has dropped too far below starting height
		if currentPosition.Y < origin.Y - 1000 then
			break
		end
		
		-- Break if velocity becomes too low (bullet loses effectiveness)
		if velocityMagnitude < 50 then
			break
		end
	end
	
	return trajectory
end

function BallisticsSystem:CalculateBulletDrop(distance, velocity, gravity)
	local timeToTarget = distance / velocity
	local drop = 0.5 * gravity * (timeToTarget ^ 2)
	return drop
end

function BallisticsSystem:CalculateLeadTarget(targetPosition, targetVelocity, shooterPosition, bulletVelocity)
	local relativePosition = targetPosition - shooterPosition
	local distance = relativePosition.Magnitude
	local timeToHit = distance / bulletVelocity
	
	local predictedPosition = targetPosition + (targetVelocity * timeToHit)
	local aimDirection = (predictedPosition - shooterPosition).Unit
	
	return aimDirection, timeToHit
end

function BallisticsSystem:ApplyWeaponSpread(direction, weaponConfig, shooter)
	local isAiming = false -- TODO: Get from player state
	local isMoving = false -- TODO: Get from player state
	local consecutiveShots = 0 -- TODO: Track this per player
	
	local totalSpread = self:CalculateSpread(weaponConfig, isAiming, isMoving, consecutiveShots)
	
	-- Apply random spread to direction
	local spreadX = (math.random() - 0.5) * totalSpread
	local spreadY = (math.random() - 0.5) * totalSpread
	local spreadZ = (math.random() - 0.5) * totalSpread
	
	local spreadDirection = (direction + Vector3.new(spreadX, spreadY, spreadZ)).Unit
	return spreadDirection
end

function BallisticsSystem:ApplyRecoil(weaponConfig, currentRecoil)
	local recoilConfig = weaponConfig.Recoil or {}
	local vertical = recoilConfig.Vertical or 0.5
	local horizontal = recoilConfig.Horizontal or 0.3
	local randomFactor = recoilConfig.RandomFactor or 0.2
	local firstShotMultiplier = recoilConfig.FirstShotMultiplier or 1.0
	local decayRate = recoilConfig.DecayRate or 0.95
	
	-- Apply first shot multiplier if this is the first shot
	local isFirstShot = (currentRecoil.X or 0) == 0 and (currentRecoil.Y or 0) == 0
	local shotMultiplier = isFirstShot and firstShotMultiplier or 1.0
	
	local recoilVertical = vertical * shotMultiplier + (math.random() - 0.5) * randomFactor
	local recoilHorizontal = (math.random() - 0.5) * horizontal * shotMultiplier
	
	-- Apply recoil decay to previous recoil
	local previousX = (currentRecoil.X or 0) * decayRate
	local previousY = (currentRecoil.Y or 0) * decayRate
	
	local newRecoil = {
		X = previousX + recoilHorizontal,
		Y = previousY + recoilVertical
	}
	
	return newRecoil
end

function BallisticsSystem:CalculateSpread(weaponConfig, isAiming, isMoving, consecutiveShots)
	local baseSpread = weaponConfig.BaseSpread or 0.1
	local aimSpread = weaponConfig.AimSpread or (baseSpread * 0.5)
	local movingSpread = weaponConfig.MovingSpread or (baseSpread * 1.5)
	
	-- Use specific spread values instead of multipliers
	local currentSpread = baseSpread
	if isAiming then
		currentSpread = aimSpread
	elseif isMoving then
		currentSpread = movingSpread
	end
	
	-- Add consecutive shot spread buildup
	local rapidFireSpreadMultiplier = 1.0 + (consecutiveShots * 0.08)
	local totalSpread = currentSpread * rapidFireSpreadMultiplier
	
	-- Cap maximum spread
	return math.min(totalSpread, 0.5)
end

function BallisticsSystem:CalculatePenetrationDamage(baseDamage, penetrationDepth, material)
	-- More realistic penetration damage calculation
	local materialResistance = {
		[Enum.Material.Wood] = 0.15,
		[Enum.Material.WoodPlanks] = 0.15,
		[Enum.Material.Plastic] = 0.10,
		[Enum.Material.Glass] = 0.05,
		[Enum.Material.Metal] = 0.35,
		[Enum.Material.Concrete] = 0.45,
		[Enum.Material.Brick] = 0.30,
		[Enum.Material.Rock] = 0.50,
		[Enum.Material.Granite] = 0.55
	}
	
	local resistance = materialResistance[material] or 0.25
	local damageReduction = penetrationDepth * resistance
	local finalDamage = baseDamage * (1.0 - damageReduction)
	
	return math.max(finalDamage, baseDamage * 0.2) -- Minimum 20% damage
end

function BallisticsSystem:ProcessGrenadeFire(shooter, weaponConfig, origin, direction)
	local throwForce = weaponConfig.ThrowForce or 50
	local fuseTime = weaponConfig.FuseTime or 4.0
	local explosionRadius = weaponConfig.ExplosionRadius or 10
	local damage = weaponConfig.Damage or 100
	
	RemoteEventsManager:FireAllClients("GrenadeThrown", shooter, {
		GrenadeType = weaponConfig.Name,
		Origin = origin,
		Direction = direction,
		ThrowForce = throwForce,
		FuseTime = fuseTime,
		PlayerId = shooter.UserId
	})
	
	spawn(function()
		local grenadeTrajectory = self:CalculateGrenadeTrajectory(origin, direction, throwForce, fuseTime)
		local explosionPosition = grenadeTrajectory[#grenadeTrajectory].Position
		
		wait(fuseTime)
		
		self:ProcessGrenadeExplosion(shooter, weaponConfig, explosionPosition, explosionRadius, damage)
	end)
end

function BallisticsSystem:CalculateGrenadeTrajectory(origin, direction, throwForce, fuseTime)
	local trajectory = {}
	local currentPosition = origin
	local currentVelocity = direction * throwForce
	local timeStep = 0.1
	local totalTime = 0
	
	while totalTime < fuseTime do
		local previousPosition = currentPosition
		
		local gravityEffect = Vector3.new(0, -GRAVITY * timeStep, 0)
		currentVelocity = currentVelocity + gravityEffect
		currentPosition = currentPosition + (currentVelocity * timeStep)
		
		local rayResult = RaycastSystem:CastRay(
			previousPosition,
			(currentPosition - previousPosition).Unit,
			(currentPosition - previousPosition).Magnitude
		)
		
		if rayResult then
			currentPosition = rayResult.Position
			currentVelocity = currentVelocity * 0.7
			
			local normalBounce = rayResult.Normal * currentVelocity:Dot(rayResult.Normal) * 2
			currentVelocity = currentVelocity - normalBounce * 0.6
		end
		
		table.insert(trajectory, {
			Position = currentPosition,
			Velocity = currentVelocity,
			Time = totalTime
		})
		
		totalTime = totalTime + timeStep
	end
	
	return trajectory
end

function BallisticsSystem:ProcessGrenadeExplosion(shooter, weaponConfig, position, radius, damage)
	local playersInRange = {}
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - position).Magnitude
			if distance <= radius then
				table.insert(playersInRange, player)
			end
		end
	end
	
	local explosionResults = DamageSystem:CalculateExplosiveDamage(position, radius, damage, playersInRange)
	
	for _, result in pairs(explosionResults) do
		result.Damage.Attacker = shooter
		result.Damage.WeaponName = weaponConfig.Name
		DamageSystem:ApplyDamage(result.Player, result.Damage)
	end
	
	RemoteEventsManager:FireAllClients("GrenadeExplosion", {
		Position = position,
		Radius = radius,
		GrenadeType = weaponConfig.Name,
		Damage = damage
	})
end

function BallisticsSystem:ProcessMeleeAttack(shooter, weaponConfig, origin, direction)
	local range = weaponConfig.Range or 5
	local damage = weaponConfig.Damage or 50
	
	local rayResult = RaycastSystem:CastRay(origin, direction, range, {shooter.Character})
	
	if rayResult and rayResult.Instance then
		local targetPlayer = RaycastSystem:GetPlayerFromHit(rayResult.Instance)
		
		if targetPlayer and targetPlayer.Character then
			local isBackstab = self:IsBackstabAttack(shooter, targetPlayer, direction)
			
			local hitInfo = {
				Hit = rayResult.Instance,
				Position = rayResult.Position,
				Normal = rayResult.Normal,
				Player = targetPlayer
			}
			
			local damageInfo = DamageSystem:CalculateMeleeDamage(weaponConfig, hitInfo, isBackstab)
			damageInfo.Attacker = shooter
			damageInfo.Victim = targetPlayer
			
			DamageSystem:ApplyDamage(targetPlayer, damageInfo)
			
			print(shooter.Name .. " melee attacked " .. targetPlayer.Name .. " for " .. damageInfo.FinalDamage .. " damage")
		end
	end
	
	RemoteEventsManager:FireAllClients("MeleeAttack", shooter, {
		WeaponName = weaponConfig.Name,
		Origin = origin,
		Direction = direction,
		Range = range,
		PlayerId = shooter.UserId
	})
end

function BallisticsSystem:IsBackstabAttack(attacker, victim, attackDirection)
	if not attacker.Character or not victim.Character then return false end
	
	local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	local victimRoot = victim.Character:FindFirstChild("HumanoidRootPart")
	
	if not attackerRoot or not victimRoot then return false end
	
	local victimLookDirection = victimRoot.CFrame.LookVector
	local attackVector = (attackerRoot.Position - victimRoot.Position).Unit
	
	local dotProduct = victimLookDirection:Dot(attackVector)
	
	return dotProduct > 0.7
end

function BallisticsSystem:GetBallisticArc(origin, target, velocity, gravity)
	local displacement = target - origin
	local horizontalDistance = Vector3.new(displacement.X, 0, displacement.Z).Magnitude
	local verticalDistance = displacement.Y
	
	local timeToTarget = horizontalDistance / velocity
	local requiredVerticalVelocity = (verticalDistance + 0.5 * gravity * timeToTarget^2) / timeToTarget
	
	local launchAngle = math.atan2(requiredVerticalVelocity, velocity)
	local launchDirection = Vector3.new(displacement.X, 0, displacement.Z).Unit
	
	return launchDirection, launchAngle, timeToTarget
end

return BallisticsSystem