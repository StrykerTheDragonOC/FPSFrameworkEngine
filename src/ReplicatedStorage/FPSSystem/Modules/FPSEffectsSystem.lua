local EffectsSystem = {}
EffectsSystem.__index = EffectsSystem

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Constants
local EFFECT_SETTINGS = {
	MUZZLE_FLASH_DURATION = 0.05,
	SHELL_LIFETIME = 2,
	IMPACT_LIFETIME = 3,
	BULLET_SPEED = 300
}

function EffectsSystem.new()
	local self = setmetatable({}, EffectsSystem)

	-- Effects storage
	self.activeEffects = {}
	self.cachedEffects = {}

	return self
end

function EffectsSystem:createMuzzleFlash(attachment)
	-- Create muzzle flash effect
	local flash = Instance.new("ParticleEmitter")
	flash.Size = NumberSequence.new(0.2)
	flash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	flash.Lifetime = NumberRange.new(EFFECT_SETTINGS.MUZZLE_FLASH_DURATION)
	flash.Rate = 0
	flash.Parent = attachment

	-- Emit particles
	flash:Emit(1)

	-- Create light effect
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 10
	light.Color = Color3.new(1, 0.8, 0.5)
	light.Parent = attachment

	-- Cleanup
	Debris:AddItem(flash, EFFECT_SETTINGS.MUZZLE_FLASH_DURATION)
	Debris:AddItem(light, EFFECT_SETTINGS.MUZZLE_FLASH_DURATION)
end

function EffectsSystem:createBulletTracer(startPos, endPos)
	-- Create tracer part
	local tracer = Instance.new("Part")
	tracer.Size = Vector3.new(0.1, 0.1, (endPos - startPos).Magnitude)
	tracer.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -tracer.Size.Z/2)
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.new(1, 0.8, 0.5)
	tracer.Parent = workspace

	-- Fade out tracer
	TweenService:Create(
		tracer, 
		TweenInfo.new(0.1), 
		{Transparency = 1}
	):Play()

	-- Cleanup
	Debris:AddItem(tracer, 0.1)
end

function EffectsSystem:createImpactEffect(position, normal, material)
	-- Create impact particles based on material
	local particles = Instance.new("ParticleEmitter")
	particles.Size = NumberSequence.new(0.1)
	particles.Speed = NumberRange.new(10, 20)
	particles.Lifetime = NumberRange.new(0.2, 0.4)
	particles.Rate = 0

	-- Set particle properties based on material
	if material == Enum.Material.Concrete then
		particles.Color = ColorSequence.new(Color3.new(0.5, 0.5, 0.5))
	elseif material == Enum.Material.Metal then
		particles.Color = ColorSequence.new(Color3.new(0.7, 0.7, 0.7))
	else
		particles.Color = ColorSequence.new(Color3.new(0.3, 0.3, 0.3))
	end

	-- Create effect part
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.CFrame = CFrame.new(position, position + normal)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	particles.Parent = part
	particles:Emit(10)

	-- Create decal
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://..." -- Replace with bullet hole texture
	decal.Face = Enum.NormalId.Front
	decal.Parent = part

	-- Fade out decal
	TweenService:Create(
		decal, 
		TweenInfo.new(EFFECT_SETTINGS.IMPACT_LIFETIME), 
		{Transparency = 1}
	):Play()

	-- Cleanup
	Debris:AddItem(part, EFFECT_SETTINGS.IMPACT_LIFETIME)
end

function EffectsSystem:createShellEject(position, direction)
	-- Create shell part
	local shell = Instance.new("Part")
	shell.Size = Vector3.new(0.1, 0.2, 0.1)
	shell.CFrame = CFrame.new(position)
	shell.Velocity = direction * 10
	shell.RotVelocity = Vector3.new(
		math.random(-20, 20),
		math.random(-20, 20),
		math.random(-20, 20)
	)
	shell.CanCollide = true
	shell.Material = Enum.Material.Metal
	shell.Color = Color3.new(0.8, 0.7, 0.1)
	shell.Parent = workspace

	-- Cleanup
	Debris:AddItem(shell, EFFECT_SETTINGS.SHELL_LIFETIME)
end

function EffectsSystem:playSound(soundId, position, properties)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Position = position

	-- Apply properties if provided
	if properties then
		for property, value in pairs(properties) do
			sound[property] = value
		end
	end

	sound.Parent = workspace
	sound:Play()

	-- Cleanup
	Debris:AddItem(sound, sound.TimeLength)
end

return EffectsSystem