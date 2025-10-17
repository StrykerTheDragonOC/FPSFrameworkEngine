local DamageSystem = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RaycastSystem = require(ReplicatedStorage.FPSSystem.Modules.RaycastSystem)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)

local HITBOX_MULTIPLIERS = {
	Head = 2.5,
	UpperTorso = 1.0,
	LowerTorso = 1.0,
	Torso = 1.0,
	LeftUpperArm = 0.8,
	RightUpperArm = 0.8,
	LeftLowerArm = 0.8,
	RightLowerArm = 0.8,
	LeftHand = 0.7,
	RightHand = 0.7,
	LeftUpperLeg = 0.9,
	RightUpperLeg = 0.9,
	LeftLowerLeg = 0.9,
	RightLowerLeg = 0.9,
	LeftFoot = 0.8,
	RightFoot = 0.8
}

local DAMAGE_TYPES = {
	Bullet = "Bullet",
	Explosion = "Explosion",
	Melee = "Melee",
	Fall = "Fall",
	Burn = "Burn",
	Poison = "Poison"
}

function DamageSystem:Initialize()
	RaycastSystem:Initialize()
	GameConfig:Initialize()

	if RunService:IsServer() then
		print("DamageSystem initialized on server")
	else
		print("DamageSystem initialized on client")
	end
end

function DamageSystem:CalculateDamage(weaponConfig, hitInfo, distance)
	local baseDamage = weaponConfig.Damage or 30
	local hitboxMultiplier = self:GetHitboxMultiplier(hitInfo.Hit)
	local distanceMultiplier = self:CalculateDistanceMultiplier(distance, weaponConfig.Range)
	local penetrationMultiplier = self:CalculatePenetrationMultiplier(hitInfo.PenetrationDepth or 0)
	
	local finalDamage = baseDamage * hitboxMultiplier * distanceMultiplier * penetrationMultiplier
	
	local damageInfo = {
		BaseDamage = baseDamage,
		HitboxMultiplier = hitboxMultiplier,
		DistanceMultiplier = distanceMultiplier,
		PenetrationMultiplier = penetrationMultiplier,
		FinalDamage = math.floor(finalDamage),
		IsHeadshot = self:IsHeadshot(hitInfo.Hit),
		IsWallbang = (hitInfo.PenetrationDepth or 0) > 0,
		Distance = distance,
		HitPart = hitInfo.Hit.Name
	}
	
	return damageInfo
end

function DamageSystem:GetHitboxMultiplier(hitPart)
	if not hitPart then return 1.0 end
	
	local partName = hitPart.Name
	return HITBOX_MULTIPLIERS[partName] or 1.0
end

function DamageSystem:IsHeadshot(hitPart)
	return hitPart and hitPart.Name == "Head"
end

function DamageSystem:CalculateDistanceMultiplier(distance, maxRange)
	if not distance or not maxRange then return 1.0 end
	
	local shortRange = maxRange * 0.2
	local mediumRange = maxRange * 0.6
	
	if distance <= shortRange then
		return 1.0
	elseif distance <= mediumRange then
		local dropoff = (distance - shortRange) / (mediumRange - shortRange)
		return 1.0 - (dropoff * 0.2)
	else
		local dropoff = (distance - mediumRange) / (maxRange - mediumRange)
		return 0.8 - (dropoff * 0.5)
	end
end

function DamageSystem:CalculatePenetrationMultiplier(penetrationDepth)
	if penetrationDepth <= 0 then
		return 1.0
	elseif penetrationDepth <= 1 then
		return 0.8
	elseif penetrationDepth <= 2 then
		return 0.6
	else
		return 0.4
	end
end

function DamageSystem:ProcessWeaponHit(shooter, weaponConfig, raycastResult, distance)
    if not raycastResult or not raycastResult.Instance then
        return nil
    end
	
	local hit = raycastResult.Instance
	local position = raycastResult.Position
    local normal = raycastResult.Normal or Vector3.new(0, 1, 0)
	
	local targetPlayer = RaycastSystem:GetPlayerFromHit(hit)
	if not targetPlayer or not targetPlayer.Character then
		return self:ProcessEnvironmentHit(raycastResult, weaponConfig)
	end
	
	if RunService:IsServer() then
		local teamManager = _G.TeamManager
		if teamManager and teamManager:IsOnSameTeam(shooter, targetPlayer) then
			if not GameConfig:IsFriendlyFireEnabled() then
				return nil
			end
		end
	end
	
	local hitInfo = {
		Hit = hit,
		Position = position,
		Normal = normal,
		Player = targetPlayer,
		PenetrationDepth = 0
	}
	
	local damageInfo = self:CalculateDamage(weaponConfig, hitInfo, distance)
	damageInfo.Attacker = shooter
	damageInfo.Victim = targetPlayer
	damageInfo.WeaponName = weaponConfig.Name
	damageInfo.DamageType = DAMAGE_TYPES.Bullet
	
	if RunService:IsServer() then
		self:ApplyDamage(targetPlayer, damageInfo)
	end
	
	return damageInfo
end

function DamageSystem:ProcessPenetratingHit(shooter, weaponConfig, penetrationResults)
	local hitResults = {}
	
	for i, raycastResult in ipairs(penetrationResults) do
		local hit = raycastResult.Instance
		local targetPlayer = RaycastSystem:GetPlayerFromHit(hit)
		
		if targetPlayer and targetPlayer.Character then
			local hitInfo = {
				Hit = hit,
				Position = raycastResult.Position,
				Normal = raycastResult.Normal,
				Player = targetPlayer,
				PenetrationDepth = i - 1
			}
			
			local distance = (raycastResult.Position - penetrationResults[1].Position).Magnitude
			local damageInfo = self:CalculateDamage(weaponConfig, hitInfo, distance)
			damageInfo.Attacker = shooter
			damageInfo.Victim = targetPlayer
			damageInfo.WeaponName = weaponConfig.Name
			damageInfo.DamageType = DAMAGE_TYPES.Bullet
			
			table.insert(hitResults, damageInfo)
			
			if RunService:IsServer() then
				self:ApplyDamage(targetPlayer, damageInfo)
			end
		end
	end
	
	return hitResults
end

function DamageSystem:ProcessEnvironmentHit(raycastResult, weaponConfig)
	local hit = raycastResult.Instance
	local position = raycastResult.Position
	local material = raycastResult.Material
	
	local environmentInfo = {
		Hit = hit,
		Position = position,
		Material = material,
		CanPenetrate = self:CanPenetrateMaterial(material),
		PenetrationResistance = self:GetMaterialPenetrationResistance(material)
	}
	
	return environmentInfo
end

function DamageSystem:CanPenetrateMaterial(material)
	local penetrableMaterials = {
		[Enum.Material.Wood] = true,
		[Enum.Material.WoodPlanks] = true,
		[Enum.Material.Plastic] = true,
		[Enum.Material.Glass] = true,
		[Enum.Material.Ice] = true,
		[Enum.Material.Snow] = true,
		[Enum.Material.Grass] = true,
		[Enum.Material.Sand] = true
	}
	
	return penetrableMaterials[material] or false
end

function DamageSystem:GetMaterialPenetrationResistance(material)
	local resistance = {
		[Enum.Material.Wood] = 0.3,
		[Enum.Material.WoodPlanks] = 0.3,
		[Enum.Material.Plastic] = 0.2,
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
		[Enum.Material.Marble] = 0.8
	}
	
	return resistance[material] or 0.5
end

function DamageSystem:ApplyDamage(player, damageInfo)
	if not RunService:IsServer() then return end
	
	local healthSystem = _G.HealthSystem
	if healthSystem then
		healthSystem:DamagePlayer(player, damageInfo.FinalDamage, damageInfo)
	end
end

function DamageSystem:DamagePlayer(player, damage, damageInfo)
	if not RunService:IsServer() then return false end
	
	-- Create proper damage info structure if not provided
	local finalDamageInfo = damageInfo or {}
	finalDamageInfo.FinalDamage = damage
	
	-- Apply the damage
	self:ApplyDamage(player, finalDamageInfo)
	return true
end

function DamageSystem:CalculateExplosiveDamage(position, explosionRadius, maxDamage, players)
	local damageResults = {}
	
	for _, player in pairs(players) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - position).Magnitude
			
			if distance <= explosionRadius then
				local damageMultiplier = 1 - (distance / explosionRadius)
				local damage = maxDamage * damageMultiplier
				
				local raycastResult = RaycastSystem:CastRay(
					position,
					(player.Character.HumanoidRootPart.Position - position).Unit,
					distance
				)
				
				if raycastResult and RaycastSystem:GetPlayerFromHit(raycastResult.Instance) == player then
					local damageInfo = {
						FinalDamage = math.floor(damage),
						DamageType = DAMAGE_TYPES.Explosion,
						Distance = distance,
						ExplosionRadius = explosionRadius,
						IsHeadshot = false,
						IsWallbang = false
					}
					
					table.insert(damageResults, {Player = player, Damage = damageInfo})
				end
			end
		end
	end
	
	return damageResults
end

function DamageSystem:CalculateMeleeDamage(weaponConfig, hitInfo, isBackstab)
	local baseDamage = weaponConfig.Damage or 50
	local finalDamage = baseDamage
	
	if isBackstab and weaponConfig.BackstabDamage then
		finalDamage = weaponConfig.BackstabDamage
	else
		local hitboxMultiplier = self:GetHitboxMultiplier(hitInfo.Hit)
		finalDamage = baseDamage * hitboxMultiplier
	end
	
	local damageInfo = {
		BaseDamage = baseDamage,
		FinalDamage = math.floor(finalDamage),
		IsBackstab = isBackstab,
		IsHeadshot = self:IsHeadshot(hitInfo.Hit),
		DamageType = DAMAGE_TYPES.Melee,
		WeaponName = weaponConfig.Name
	}
	
	return damageInfo
end

function DamageSystem:ValidateDamage(attacker, victim, damageAmount, weaponConfig)
	if not attacker or not victim then return false end
	
	if not weaponConfig then return false end
	
	if damageAmount <= 0 or damageAmount > (weaponConfig.Damage * 3) then
		return false
	end
	
	if attacker == victim then
		return weaponConfig.SelfDamage or false
	end
	
	return true
end

return DamageSystem