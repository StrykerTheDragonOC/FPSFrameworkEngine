-- MeleeSystem.lua
-- Place this in ReplicatedStorage.FPSSystem.Modules
local MeleeSystem = {}
MeleeSystem.__index = MeleeSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- FastCast setup
local FastCast = require(ReplicatedStorage:WaitForChild("FastCastRedux"))

-- Constants
local MELEE_SETTINGS = {
	ATTACK_RANGE = 4,           -- How far the melee attack reaches
	ATTACK_RADIUS = 1.5,        -- Radius of the attack cone
	ATTACK_DAMAGE = 85,         -- Base damage
	ATTACK_COOLDOWN = 0.6,      -- Time between attacks
	ATTACK_DURATION = 0.4,      -- Time for attack animation
	BACKSTAB_MULTIPLIER = 2,    -- Damage multiplier for backstabs
	HIT_EFFECT_DURATION = 0.3   -- Duration of hit effect
}

-- Create a new MeleeSystem
function MeleeSystem.new(viewmodelSystem)
	local self = setmetatable({}, MeleeSystem)

	-- Core references
	self.player = Players.LocalPlayer
	self.viewmodelSystem = viewmodelSystem
	self.camera = workspace.CurrentCamera
	self.remoteEvent = nil

	-- State tracking
	self.isAttacking = false
	self.lastAttackTime = 0
	self.attackCooldown = MELEE_SETTINGS.ATTACK_COOLDOWN

	-- FastCast setup
	self.fastCast = FastCast.new()
	self:setupFastCast()

	-- Find or create remote event
	self:setupRemoteEvent()

	print("MeleeSystem initialized")
	return self
end

-- Set up FastCast for melee detection
function MeleeSystem:setupFastCast()
	-- Create behavior for melee "projectile"
	local behavior = FastCast.newBehavior()
	behavior.RaycastParams = RaycastParams.new()
	behavior.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	behavior.RaycastParams.FilterDescendantsInstances = {self.player.Character}
	behavior.MaxDistance = MELEE_SETTINGS.ATTACK_RANGE
	behavior.Acceleration = Vector3.new(0, 0, 0) -- No gravity for melee
	behavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default

	self.meleeBehavior = behavior

	-- Set up hit detection
	self.fastCast.LengthChanged:Connect(function(cast, lastPoint, rayDir, displacement, velocity, cosmeticBulletObject)
		-- This fires continuously as the "projectile" travels
	end)

	self.fastCast.RayHit:Connect(function(cast, raycastResult, velocity, cosmeticBulletObject)
		self:handleMeleeHit(raycastResult, velocity)
	end)

	self.fastCast.CastTerminating:Connect(function(cast)
		-- Clean up when cast ends
	end)
end

-- Set up remote event for server communication
function MeleeSystem:setupRemoteEvent()
	-- Find existing or create remote event
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	self.remoteEvent = remoteFolder:FindFirstChild("MeleeEvent")
	if not self.remoteEvent then
		self.remoteEvent = Instance.new("RemoteEvent")
		self.remoteEvent.Name = "MeleeEvent"
		self.remoteEvent.Parent = remoteFolder
		print("Created MeleeEvent RemoteEvent")
	end
end

-- Perform a melee attack
function MeleeSystem:attack()
	-- Check cooldown
	local now = tick()
	if now - self.lastAttackTime < self.attackCooldown then
		return false
	end

	-- Set attacking state
	self.isAttacking = true
	self.lastAttackTime = now

	print("Melee attack started")

	-- Play attack animation
	self:playAttackAnimation(function()
		-- Perform hit detection in the middle of the animation
		self:performHitDetection()

		-- Reset state after animation
		self.isAttacking = false
	end)

	return true
end

-- Play the attack animation
function MeleeSystem:playAttackAnimation(callback)
	-- Ensure we have a weapon and viewmodel
	if not self.viewmodelSystem or not self.viewmodelSystem.currentWeapon then
		if callback then callback() end
		return
	end

	local weapon = self.viewmodelSystem.currentWeapon

	-- Create animation sequence
	self:animateSlash(weapon, callback)
end

-- Animate a slashing motion
function MeleeSystem:animateSlash(weapon, callback)
	if not weapon or not weapon.PrimaryPart then
		if callback then callback() end
		return
	end

	-- Original position and rotation
	local originalCFrame = weapon.PrimaryPart.CFrame

	-- Wind-up position (pulled back)
	local windupCFrame = originalCFrame * 
		CFrame.Angles(0, math.rad(-30), math.rad(20)) * 
		CFrame.new(-0.2, 0.1, 0)

	-- Slash position (extended forward)
	local slashCFrame = originalCFrame * 
		CFrame.Angles(0, math.rad(60), math.rad(-40)) * 
		CFrame.new(0.4, -0.2, 0.3)

	-- Recovery position (slightly off center)
	local recoveryCFrame = originalCFrame * 
		CFrame.Angles(0, math.rad(20), math.rad(-10)) * 
		CFrame.new(0.1, -0.05, 0.1)

	-- Animation phases
	local phases = {
		-- Wind-up
		{
			target = windupCFrame,
			duration = MELEE_SETTINGS.ATTACK_DURATION * 0.2,
			easing = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.Out
		},
		-- Slash 
		{
			target = slashCFrame,
			duration = MELEE_SETTINGS.ATTACK_DURATION * 0.3,
			easing = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.In,
			halfway = true -- Perform hit detection at halfway point
		},
		-- Recovery
		{
			target = recoveryCFrame,
			duration = MELEE_SETTINGS.ATTACK_DURATION * 0.2,
			easing = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.Out
		},
		-- Return to original
		{
			target = originalCFrame,
			duration = MELEE_SETTINGS.ATTACK_DURATION * 0.3,
			easing = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.InOut
		}
	}

	-- Execute animation phases
	self:animatePhases(weapon, phases, callback)
end

-- Animate through a series of phases
function MeleeSystem:animatePhases(weapon, phases, callback, currentPhase)
	currentPhase = currentPhase or 1

	if currentPhase > #phases then
		-- Animation complete
		if callback then callback() end
		return
	end

	-- Get current phase
	local phase = phases[currentPhase]

	-- Create tween info
	local tweenInfo = TweenInfo.new(
		phase.duration,
		phase.easing,
		phase.direction
	)

	-- Create dummy part to tween
	local dummy = Instance.new("Part")
	dummy.Anchored = true
	dummy.CanCollide = false
	dummy.Transparency = 1
	dummy.CFrame = weapon.PrimaryPart.CFrame
	dummy.Parent = workspace

	-- Create tween
	local tween = TweenService:Create(
		dummy,
		tweenInfo,
		{CFrame = phase.target}
	)

	-- Connect update (fix connection scope)
	local updateConnection
	updateConnection = RunService.RenderStepped:Connect(function()
		if weapon and weapon.Parent then
			weapon:PivotTo(dummy.CFrame)
		else
			if updateConnection then
				updateConnection:Disconnect()
			end
		end
	end)

	-- Check if we need to perform hit detection at halfway point
	if phase.halfway then
		task.delay(phase.duration * 0.5, function()
			self:performHitDetection()
		end)
	end

	-- Move to next phase when done
	tween.Completed:Connect(function()
		if updateConnection then
			updateConnection:Disconnect()
		end
		dummy:Destroy()

		self:animatePhases(weapon, phases, callback, currentPhase + 1)
	end)

	-- Play the tween
	tween:Play()
end

-- Perform hit detection using FastCast
function MeleeSystem:performHitDetection()
	-- Calculate attack properties
	local attackOrigin = self.camera.CFrame.Position
	local attackDirection = self.camera.CFrame.LookVector

	-- Update behavior filter to exclude current character
	if self.player.Character then
		self.meleeBehavior.RaycastParams.FilterDescendantsInstances = {self.player.Character}
	end

	-- Fire FastCast "projectile" for melee detection
	-- Use high speed to simulate instant melee attack
	local meleeVelocity = attackDirection * 1000 -- Very fast to simulate instant hit

	self.fastCast:Fire(attackOrigin, meleeVelocity, self.meleeBehavior)

	print("Melee attack cast fired")
end

-- Handle melee hit using FastCast result
function MeleeSystem:handleMeleeHit(raycastResult, velocity)
	if not raycastResult then
		print("Melee attack missed")
		return
	end

	-- Check if we hit a player's character
	local hitPart = raycastResult.Instance
	local hitPosition = raycastResult.Position

	-- Find character and humanoid
	local character = hitPart:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		-- Check if this is a backstab
		local attackDirection = velocity.Unit
		local isBackstab = self:checkBackstab(character, attackDirection)

		-- Apply damage multiplier for backstab
		local damage = MELEE_SETTINGS.ATTACK_DAMAGE
		if isBackstab then
			damage = damage * MELEE_SETTINGS.BACKSTAB_MULTIPLIER
			print("BACKSTAB!")
		end

		print("Melee hit detected on " .. (character.Name or "character"))

		-- Notify server of hit
		if self.remoteEvent then
			self.remoteEvent:FireServer("MeleeHit", {
				Target = character,
				HitPart = hitPart,
				HitPosition = hitPosition,
				Damage = damage,
				IsBackstab = isBackstab
			})
		end

		-- Create local hit effect
		self:createHitEffect(hitPosition, isBackstab)
	else
		-- Hit something that's not a character
		print("Melee hit terrain or object")

		-- Create impact effect
		self:createImpactEffect(hitPosition, raycastResult.Normal)
	end
end

-- Check if this is a backstab
function MeleeSystem:checkBackstab(character, attackDirection)
	-- Need HumanoidRootPart to check facing
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Get character look direction
	local characterLookVector = rootPart.CFrame.LookVector

	-- Dot product > 0.5 means attack is coming from behind
	local dot = attackDirection:Dot(characterLookVector)

	return dot > 0.5 -- Attacking from behind
end

-- Create a hit effect at the point of impact
function MeleeSystem:createHitEffect(position, isBackstab)
	-- Create a part to hold effects
	local effectPart = Instance.new("Part")
	effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
	effectPart.Transparency = 1
	effectPart.CanCollide = false
	effectPart.Anchored = true
	effectPart.Position = position
	effectPart.Parent = workspace

	-- Create blood particle effect
	local bloodEffect = Instance.new("ParticleEmitter")
	bloodEffect.Color = ColorSequence.new(Color3.new(0.8, 0, 0))
	bloodEffect.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	bloodEffect.Lifetime = NumberRange.new(0.3, 0.6)
	bloodEffect.Rate = 0
	bloodEffect.Speed = NumberRange.new(3, 6)
	bloodEffect.SpreadAngle = Vector2.new(50, 50)
	bloodEffect.Parent = effectPart

	-- Emit more particles for backstab
	local particleCount = isBackstab and 20 or 10
	bloodEffect:Emit(particleCount)

	-- Create sound effect
	local sound = Instance.new("Sound")
	sound.SoundId = isBackstab and "rbxassetid://4471648128" or "rbxassetid://5951833277"
	sound.Volume = 0.5
	sound.Parent = effectPart
	sound:Play()

	-- Clean up after effect completes
	task.delay(MELEE_SETTINGS.HIT_EFFECT_DURATION, function()
		effectPart:Destroy()
	end)
end

-- Create an impact effect for hitting non-character objects
function MeleeSystem:createImpactEffect(position, normal)
	-- Create a part to hold effects
	local effectPart = Instance.new("Part")
	effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
	effectPart.Transparency = 1
	effectPart.CanCollide = false
	effectPart.Anchored = true
	effectPart.Position = position
	effectPart.Parent = workspace

	-- Create spark particle effect
	local sparkEffect = Instance.new("ParticleEmitter")
	sparkEffect.Color = ColorSequence.new(Color3.new(1, 0.8, 0.5))
	sparkEffect.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 0.02)
	})
	sparkEffect.Lifetime = NumberRange.new(0.2, 0.4)
	sparkEffect.Rate = 0
	sparkEffect.Speed = NumberRange.new(2, 5)
	sparkEffect.SpreadAngle = Vector2.new(60, 60)
	sparkEffect.Parent = effectPart

	-- Emit particles
	sparkEffect:Emit(8)

	-- Create sound effect
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://142082167" -- Metal impact sound
	sound.Volume = 0.3
	sound.Parent = effectPart
	sound:Play()

	-- Clean up after effect completes
	task.delay(MELEE_SETTINGS.HIT_EFFECT_DURATION, function()
		effectPart:Destroy()
	end)
end

-- Handle mouse button input
function MeleeSystem:handleMouseButton1(isDown)
	if isDown and not self.isAttacking then
		return self:attack()
	end
	return false
end

-- Clean up system
function MeleeSystem:cleanup()
	if self.fastCast then
		-- Clean up any active casts
		self.fastCast:Destroy()
	end
	print("MeleeSystem cleaned up")
end

return MeleeSystem