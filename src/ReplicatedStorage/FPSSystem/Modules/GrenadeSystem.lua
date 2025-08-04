-- GrenadeSystem.lua
-- Advanced grenade system with cooking, trajectory preview, and physics
-- Place in ReplicatedStorage.FPSSystem.Modules

local GrenadeSystem = {}
GrenadeSystem.__index = GrenadeSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")

-- Constants
local GRENADE_SETTINGS = {
	-- Grenade properties
	DEFAULT_COOK_TIME = 3.0,       -- Time until explosion when cooking
	DEFAULT_MAX_THROW_FORCE = 60,  -- Maximum throw force
	DEFAULT_MIN_THROW_FORCE = 25,  -- Minimum throw force
	DEFAULT_CHARGE_TIME = 1.0,     -- Time to reach max throw force
	DEFAULT_BOUNCINESS = 0.3,      -- Default bounce factor

	-- Physics
	GRAVITY = Vector3.new(0, -workspace.Gravity, 0), -- Physics gravity
	DRAG_COEFFICIENT = 0.1,         -- Air resistance factor

	-- Trajectory preview
	TRAJECTORY = {
		POINTS = 30,                -- Number of points in trajectory line
		STEP_TIME = 0.1,            -- Time step for trajectory prediction
		MAX_TIME = 3.0,             -- Maximum trajectory prediction time
		DOT_SIZE = 0.15,            -- Size of trajectory dots
		LINE_THICKNESS = 0.03,      -- Thickness of trajectory line
		COLOR = Color3.fromRGB(255, 80, 80), -- Color of trajectory
		FADE_START = 0.3,           -- Start fading at this point (0-1)
		MATERIAL = Enum.Material.Neon
	},

	-- Explosion settings
	EXPLOSION = {
		DEFAULT_RADIUS = 15,        -- Default explosion radius
		DEFAULT_DAMAGE = 100,       -- Default damage at center
		DEFAULT_MIN_DAMAGE = 20,    -- Default minimum damage at edge
		FALLOFF = "LINEAR",         -- Damage falloff type (LINEAR or QUADRATIC)
		FORCE = 5000,               -- Explosion force
		UPWARD_BIAS = 0.3,          -- Upward force bias (0-1)
		PARTICLE_COUNT = 50,        -- Number of particles in explosion
		LIGHT_BRIGHTNESS = 5,       -- Explosion light brightness
		LIGHT_RANGE = 15,           -- Explosion light range
		LIGHT_DURATION = 0.5,       -- Duration of explosion light
		SHAKE_INTENSITY = 1.0,      -- Camera shake intensity
		SHAKE_DURATION = 0.5,       -- Camera shake duration
		SHAKE_DISTANCE = 30         -- Maximum distance for camera shake
	},

	-- Cooking indicator
	INDICATOR = {
		USE_GUI = true,             -- Use GUI for cooking indicator
		USE_COLOR = true,           -- Change grenade color while cooking
		START_COLOR = Color3.fromRGB(0, 255, 0), -- Safe color
		END_COLOR = Color3.fromRGB(255, 0, 0),   -- About to explode color
		PULSE_RATE = 1.0            -- Rate of pulsing when close to explosion
	}
}

-- Constructor
function GrenadeSystem.new(viewmodelSystem)
	local self = setmetatable({}, GrenadeSystem)

	-- Core references
	self.player = Players.LocalPlayer
	self.viewmodel = viewmodelSystem
	self.camera = workspace.CurrentCamera

	-- Grenade state
	self.isCooking = false          -- Currently cooking a grenade
	self.cookStartTime = 0          -- When cooking started
	self.chargeStartTime = 0        -- When charge started
	self.chargeAmount = 0           -- Current throw charge (0-1)
	self.showingTrajectory = false  -- Currently showing trajectory
	self.currentGrenade = nil       -- Current grenade data
	self.effectsFolder = nil        -- Folder for effects

	-- Trajectory visualization
	self.trajectoryParts = {}       -- Trajectory preview parts
	self.trajectoryLine = nil       -- Trajectory line

	-- Ensure remote events
	self:setupRemoteEvents()

	-- Create effects folder
	self:createEffectsFolder()

	-- Set up collision group
	self:setupCollisionGroup()

	-- Create trajectory visualization
	self:createTrajectoryVisualization()

	-- Create cooking indicator
	if GRENADE_SETTINGS.INDICATOR.USE_GUI then
		self:createCookingIndicator()
	end

	print("Grenade System initialized")
	return self
end

-- Setup remote events
function GrenadeSystem:setupRemoteEvents()
	-- Get or create remote events folder
	local remotesFolder = ReplicatedStorage:FindFirstChild("FPSSystem")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "FPSSystem"
		remotesFolder.Parent = ReplicatedStorage
	end

	local remoteEvents = remotesFolder:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = remotesFolder
	end

	-- Get or create grenade event
	self.grenadeEvent = remoteEvents:FindFirstChild("GrenadeEvent")
	if not self.grenadeEvent then
		self.grenadeEvent = Instance.new("RemoteEvent")
		self.grenadeEvent.Name = "GrenadeEvent"
		self.grenadeEvent.Parent = remoteEvents
	end
end

-- Create effects folder
function GrenadeSystem:createEffectsFolder()
	-- Create effects folder for grenades
	self.effectsFolder = workspace:FindFirstChild("GrenadeEffects")
	if not self.effectsFolder then
		self.effectsFolder = Instance.new("Folder")
		self.effectsFolder.Name = "GrenadeEffects"
		self.effectsFolder.Parent = workspace
	end
end

-- Setup collision group for grenades
function GrenadeSystem:setupCollisionGroup()
	pcall(function()
		-- Set up collision groups
		PhysicsService:RegisterCollisionGroup("Grenades")

		-- Make grenades collide with environment but not players
		PhysicsService:CollisionGroupSetCollidable("Grenades", "Default", true)
		PhysicsService:CollisionGroupSetCollidable("Grenades", "Players", false)
	end)
end

-- Create trajectory visualization parts
function GrenadeSystem:createTrajectoryVisualization()
	-- Create dots for trajectory
	for i = 1, GRENADE_SETTINGS.TRAJECTORY.POINTS do
		local part = Instance.new("Part")
		part.Name = "TrajectoryPoint" .. i
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(GRENADE_SETTINGS.TRAJECTORY.DOT_SIZE, GRENADE_SETTINGS.TRAJECTORY.DOT_SIZE, GRENADE_SETTINGS.TRAJECTORY.DOT_SIZE)
		part.Material = GRENADE_SETTINGS.TRAJECTORY.MATERIAL
		part.Color = GRENADE_SETTINGS.TRAJECTORY.COLOR
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false

		-- Start with full transparency (invisible)
		part.Transparency = 1

		-- Store in array
		self.trajectoryParts[i] = part
		part.Parent = self.effectsFolder
	end

	-- Create trajectory line
	self.trajectoryLine = Instance.new("Part")
	self.trajectoryLine.Name = "TrajectoryLine"
	self.trajectoryLine.Size = Vector3.new(GRENADE_SETTINGS.TRAJECTORY.LINE_THICKNESS, GRENADE_SETTINGS.TRAJECTORY.LINE_THICKNESS, 1)
	self.trajectoryLine.Material = GRENADE_SETTINGS.TRAJECTORY.MATERIAL
	self.trajectoryLine.Color = GRENADE_SETTINGS.TRAJECTORY.COLOR
	self.trajectoryLine.Anchored = true
	self.trajectoryLine.CanCollide = false
	self.trajectoryLine.CastShadow = false
	self.trajectoryLine.Transparency = 1 -- Start invisible
	self.trajectoryLine.Parent = self.effectsFolder
end

-- Create cooking indicator GUI
function GrenadeSystem:createCookingIndicator()
	-- Create indicator GUI
	local cookIndicator = Instance.new("ScreenGui")
	cookIndicator.Name = "GrenadeCookingIndicator"
	cookIndicator.ResetOnSpawn = false
	cookIndicator.Enabled = false

	-- Create outer frame
	local outerFrame = Instance.new("Frame")
	outerFrame.Size = UDim2.new(0, 50, 0, 200)
	outerFrame.Position = UDim2.new(0.96, 0, 0.4, 0)
	outerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	outerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	outerFrame.BorderSizePixel = 0
	outerFrame.Parent = cookIndicator

	-- Create indicator bar
	local indicatorBar = Instance.new("Frame")
	indicatorBar.Name = "IndicatorBar"
	indicatorBar.Size = UDim2.new(0.8, 0, 0.95, 0)
	indicatorBar.Position = UDim2.new(0.5, 0, 0.5, 0)
	indicatorBar.AnchorPoint = Vector2.new(0.5, 0.5)
	indicatorBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	indicatorBar.BorderSizePixel = 0
	indicatorBar.Parent = outerFrame

	-- Create fill gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
	})
	gradient.Rotation = 180
	gradient.Parent = indicatorBar

	-- Create force label
	local forceLabel = Instance.new("TextLabel")
	forceLabel.Name = "ForceLabel"
	forceLabel.Size = UDim2.new(0, 100, 0, 20)
	forceLabel.Position = UDim2.new(0, -110, 0.5, 0)
	forceLabel.AnchorPoint = Vector2.new(0, 0.5)
	forceLabel.BackgroundTransparency = 1
	forceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	forceLabel.TextSize = 16
	forceLabel.Text = "Throw Force: 0%"
	forceLabel.TextXAlignment = Enum.TextXAlignment.Left
	forceLabel.Parent = outerFrame

	-- Create time label
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0, 100, 0, 20)
	timeLabel.Position = UDim2.new(0, -110, 0.3, 0)
	timeLabel.AnchorPoint = Vector2.new(0, 0.5)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeLabel.TextSize = 16
	timeLabel.Text = "Time Left: 3.0s"
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = outerFrame

	-- Add to player GUI
	cookIndicator.Parent = self.player.PlayerGui
	self.cookIndicator = cookIndicator
	self.indicatorBar = indicatorBar
	self.forceLabel = forceLabel
	self.timeLabel = timeLabel
end

-- Update cooking indicator
function GrenadeSystem:updateCookingIndicator()
	if not self.cookIndicator or not self.indicatorBar then return end

	-- Calculate time progress
	local grenadeConfig = self.currentGrenade or {}
	local cookTime = grenadeConfig.fuseTime or GRENADE_SETTINGS.DEFAULT_COOK_TIME
	local elapsed = tick() - self.cookStartTime
	local timeRatio = math.clamp(elapsed / cookTime, 0, 1)

	-- Calculate charge progress
	local chargeTime = grenadeConfig.throwChargeTime or GRENADE_SETTINGS.DEFAULT_CHARGE_TIME
	local chargeElapsed = tick() - self.chargeStartTime
	local chargeRatio = math.clamp(chargeElapsed / chargeTime, 0, 1)

	-- Update indicators
	self.indicatorBar.Size = UDim2.new(0.8, 0, 0.95 * (1 - timeRatio), 0)
	self.indicatorBar.Position = UDim2.new(0.5, 0, 0.5 + 0.475 * timeRatio, 0)
	self.forceLabel.Text = string.format("Throw Force: %d%%", math.floor(chargeRatio * 100))
	self.timeLabel.Text = string.format("Time Left: %.1fs", cookTime - elapsed)

	-- Make indicator pulse when close to exploding
	if timeRatio > 0.7 then
		local pulseSpeed = GRENADE_SETTINGS.INDICATOR.PULSE_RATE * (1 + timeRatio)
		local pulse = 0.7 + 0.3 * math.abs(math.sin(elapsed * pulseSpeed * math.pi))
		self.indicatorBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		self.indicatorBar.Transparency = 1 - pulse
	else
		self.indicatorBar.Transparency = 0
	end
end

-- Set current grenade config
function GrenadeSystem:setGrenadeConfig(config)
	self.currentGrenade = config
end

-- Start cooking a grenade
function GrenadeSystem:startCooking()
	if self.isCooking then return false end

	-- Get grenade config
	local grenadeConfig = self.currentGrenade or {}

	-- Set cooking state
	self.isCooking = true
	self.cookStartTime = tick()
	self.chargeStartTime = tick()
	self.chargeAmount = 0

	-- Show cooking indicator
	if self.cookIndicator then
		self.cookIndicator.Enabled = true
	end

	-- Update charging and cooking
	self.cookingConnection = RunService.Heartbeat:Connect(function()
		-- Update charge amount
		local chargeTime = grenadeConfig.throwChargeTime or GRENADE_SETTINGS.DEFAULT_CHARGE_TIME
		local chargeElapsed = tick() - self.chargeStartTime
		self.chargeAmount = math.clamp(chargeElapsed / chargeTime, 0, 1)

		-- Update cooking indicator
		self:updateCookingIndicator()

		-- Check if grenade would explode
		local cookTime = grenadeConfig.fuseTime or GRENADE_SETTINGS.DEFAULT_COOK_TIME
		local cookElapsed = tick() - self.cookStartTime
		if cookElapsed >= cookTime then
			-- Grenade explodes in hand!
			self:explodeInHand()
			self:stopCooking(false) -- Don't throw
		end
	end)

	-- Create cook visual effect
	self:createCookEffect()

	-- Play pin pull sound
	self:playSound("Pin")

	return true
end

-- Create visual effect for cooking
function GrenadeSystem:createCookEffect()
	if not self.viewmodel or not self.viewmodel.currentWeapon then return end

	local grenadeConfig = self.currentGrenade or {}
	local cookTime = grenadeConfig.fuseTime or GRENADE_SETTINGS.DEFAULT_COOK_TIME

	-- Get grenade part
	local grenade = self.viewmodel.currentWeapon.PrimaryPart
	if not grenade then return end

	-- Store original color
	self.originalGrenadeColor = grenade.Color

	-- Create flash effect
	if GRENADE_SETTINGS.INDICATOR.USE_COLOR then
		self.colorConnection = RunService.Heartbeat:Connect(function()
			local elapsedTime = tick() - self.cookStartTime
			local timeRatio = math.clamp(elapsedTime / cookTime, 0, 1)

			-- Interpolate between start and end colors
			local startColor = GRENADE_SETTINGS.INDICATOR.START_COLOR
			local endColor = GRENADE_SETTINGS.INDICATOR.END_COLOR

			-- Color shifts from green to yellow to red
			local r = startColor.R + (endColor.R - startColor.R) * timeRatio
			local g = startColor.G + (endColor.G - startColor.G) * timeRatio
			local b = startColor.B + (endColor.B - startColor.B) * timeRatio

			-- Make grenade flash when close to exploding
			if timeRatio > 0.7 then
				local pulseSpeed = GRENADE_SETTINGS.INDICATOR.PULSE_RATE * (1 + timeRatio)
				local pulse = 0.5 + 0.5 * math.abs(math.sin(elapsedTime * pulseSpeed * math.pi))

				r = r * pulse
				g = g * pulse
				b = b * pulse
			end

			grenade.Color = Color3.new(r, g, b)
		end)
	end

	-- Add point light
	local light = Instance.new("PointLight")
	light.Name = "CookingLight"
	light.Range = 5
	light.Brightness = 0.5
	light.Color = GRENADE_SETTINGS.INDICATOR.START_COLOR
	light.Parent = grenade

	self.cookingLight = light

	-- Animate light color
	if self.cookingLight then
		self.lightConnection = RunService.Heartbeat:Connect(function()
			local elapsedTime = tick() - self.cookStartTime
			local timeRatio = math.clamp(elapsedTime / cookTime, 0, 1)

			-- Calculate color
			local startColor = GRENADE_SETTINGS.INDICATOR.START_COLOR
			local endColor = GRENADE_SETTINGS.INDICATOR.END_COLOR

			local r = startColor.R + (endColor.R - startColor.R) * timeRatio
			local g = startColor.G + (endColor.G - startColor.G) * timeRatio
			local b = startColor.B + (endColor.B - startColor.B) * timeRatio

			-- Update light
			self.cookingLight.Color = Color3.new(r, g, b)

			-- Make light flash when close to exploding
			if timeRatio > 0.7 then
				local pulseSpeed = GRENADE_SETTINGS.INDICATOR.PULSE_RATE * (1 + timeRatio)
				local pulse = 0.5 + 0.5 * math.abs(math.sin(elapsedTime * pulseSpeed * math.pi))

				self.cookingLight.Brightness = pulse
			else
				self.cookingLight.Brightness = 0.5
			end
		end)
	end
end

-- Handle grenade exploding in hand
function GrenadeSystem:explodeInHand()
	-- Notify the server
	if self.grenadeEvent then
		self.grenadeEvent:FireServer("ExplodeInHand", nil)
	end

	print("Grenade exploded in hand!")

	-- Create local explosion effect at player's position
	local character = self.player and self.player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		self:createExplosionEffect(character.HumanoidRootPart.Position)
	end

	-- Reset viewmodel color if needed
	if self.viewmodel and self.viewmodel.currentWeapon and self.viewmodel.currentWeapon.PrimaryPart and self.originalGrenadeColor then
		self.viewmodel.currentWeapon.PrimaryPart.Color = self.originalGrenadeColor
	end
end

-- Stop cooking and possibly throw
function GrenadeSystem:stopCooking(shouldThrow)
	if not self.isCooking then return end

	-- Clean up connections
	if self.cookingConnection then
		self.cookingConnection:Disconnect()
		self.cookingConnection = nil
	end

	if self.colorConnection then
		self.colorConnection:Disconnect()
		self.colorConnection = nil
	end

	if self.lightConnection then
		self.lightConnection:Disconnect()
		self.lightConnection = nil
	end

	-- Hide cooking indicator
	if self.cookIndicator then
		self.cookIndicator.Enabled = false
	end

	-- Get cook time
	local cookTime = tick() - self.cookStartTime

	-- Reset grenade color if needed
	if self.viewmodel and self.viewmodel.currentWeapon and self.viewmodel.currentWeapon.PrimaryPart and self.originalGrenadeColor then
		self.viewmodel.currentWeapon.PrimaryPart.Color = self.originalGrenadeColor
	end

	-- Remove cooking light
	if self.cookingLight then
		self.cookingLight:Destroy()
		self.cookingLight = nil
	end

	-- If we should throw the grenade
	if shouldThrow then
		self:throwGrenade(cookTime)
	end

	-- Reset state
	self.isCooking = false
	self.cookStartTime = 0

	print("Stopped cooking grenade")
end

-- Throw the grenade
function GrenadeSystem:throwGrenade(cookTime)
	-- Get grenade config
	local grenadeConfig = self.currentGrenade or {}

	-- Calculate throw force based on charge amount
	local minForce = grenadeConfig.throwForce or GRENADE_SETTINGS.DEFAULT_MIN_THROW_FORCE
	local maxForce = grenadeConfig.throwForceCharged or GRENADE_SETTINGS.DEFAULT_MAX_THROW_FORCE
	local throwForce = minForce + (self.chargeAmount * (maxForce - minForce))

	-- Calculate remaining time until explosion
	local totalFuseTime = grenadeConfig.fuseTime or GRENADE_SETTINGS.DEFAULT_COOK_TIME
	local remainingTime = totalFuseTime - cookTime

	-- Get throw direction from camera
	local throwDirection = self.camera.CFrame.LookVector

	-- Get throw position (slightly in front of camera)
	local throwPosition = self.camera.CFrame.Position + (throwDirection * 2)

	print("Throwing grenade with force:", throwForce, "Remaining time:", remainingTime)

	-- Notify server about throw
	if self.grenadeEvent then
		self.grenadeEvent:FireServer("ThrowGrenade", {
			Position = throwPosition,
			Direction = throwDirection,
			Force = throwForce,
			RemainingTime = remainingTime
		})
	end

	-- Create physical grenade locally
	self:createThrownGrenade(throwPosition, throwDirection, throwForce, remainingTime)

	-- Play throw sound
	self:playSound("Throw")
end

-- Create a physical thrown grenade
function GrenadeSystem:createThrownGrenade(position, direction, force, remainingTime)
	-- Get grenade config
	local grenadeConfig = self.currentGrenade or {}

	-- Create grenade part
	local grenade = Instance.new("Part")
	grenade.Name = "ThrownGrenade"

	-- Set shape and size
	if grenadeConfig.shape == "cylinder" then
		grenade.Shape = Enum.PartType.Cylinder
		grenade.Size = Vector3.new(0.5, 1, 0.5)
	else
		-- Default to sphere
		grenade.Shape = Enum.PartType.Ball
		grenade.Size = Vector3.new(0.8, 0.8, 0.8)
	end

	-- Set appearance
	grenade.Color = grenadeConfig.color or Color3.fromRGB(50, 100, 50)
	grenade.Material = grenadeConfig.material or Enum.Material.Metal
	grenade.Position = position
	grenade.CanCollide = true
	grenade.Anchored = false

	-- Add physics properties
	grenade.CustomPhysicalProperties = PhysicalProperties.new(
		grenadeConfig.density or 2,
		grenadeConfig.friction or 0.3,
		grenadeConfig.elasticity or GRENADE_SETTINGS.DEFAULT_BOUNCINESS,
		grenadeConfig.frictionWeight or 1,
		grenadeConfig.elasticityWeight or 1
	)

	-- Set collision group
	pcall(function()
		grenade.CollisionGroup = "Grenades"
	end)

	-- Create a light to make the grenade more visible
	local light = Instance.new("PointLight")
	light.Color = grenadeConfig.cookColor or GRENADE_SETTINGS.INDICATOR.END_COLOR
	light.Range = 4
	light.Brightness = 0.5
	light.Parent = grenade

	-- Parent to workspace
	grenade.Parent = self.effectsFolder

	-- Apply velocity in throw direction
	grenade.Velocity = direction * force

	-- Add random spin
	grenade.RotVelocity = Vector3.new(
		math.random(-20, 20),
		math.random(-20, 20),
		math.random(-20, 20)
	)

	-- Schedule local explosion after remaining time
	task.delay(remainingTime, function()
		if grenade and grenade.Parent then
			self:createExplosionEffect(grenade.Position)
			grenade:Destroy()
		end
	end)

	-- Connect to touched event for bounce sound
	grenade.Touched:Connect(function(hit)
		-- Check if this is the first touch (to avoid spamming sounds)
		if grenade:GetAttribute("LastBounce") and 
			tick() - grenade:GetAttribute("LastBounce") < 0.2 then
			return
		end

		-- Play bounce sound
		local bounceVelocity = grenade.Velocity.Magnitude
		if bounceVelocity > 5 then
			self:playBounceSound(grenade.Position, bounceVelocity)
			grenade:SetAttribute("LastBounce", tick())
		end
	end)

	-- Clean up grenade after a safety timeout
	Debris:AddItem(grenade, remainingTime + 1)

	return grenade
end

-- Create an explosion effect
function GrenadeSystem:createExplosionEffect(position)
	-- Get grenade config
	local grenadeConfig = self.currentGrenade or {}

	-- Create explosion visual
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = grenadeConfig.damageRadius or GRENADE_SETTINGS.EXPLOSION.DEFAULT_RADIUS
	explosion.BlastPressure = 0 -- No physics effect locally
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace

	-- Create light effect
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 175, 50)
	light.Range = grenadeConfig.lightRange or GRENADE_SETTINGS.EXPLOSION.LIGHT_RANGE
	light.Brightness = grenadeConfig.lightBrightness or GRENADE_SETTINGS.EXPLOSION.LIGHT_BRIGHTNESS
	light.Parent = self.effectsFolder

	-- Create fire effect
	local fireContainer = Instance.new("Part")
	fireContainer.Anchored = true
	fireContainer.CanCollide = false
	fireContainer.Transparency = 1
	fireContainer.Position = position
	fireContainer.Size = Vector3.new(1, 1, 1)
	fireContainer.Parent = self.effectsFolder

	local fire = Instance.new("Fire")
	fire.Size = 10
	fire.Heat = 5
	fire.Color = Color3.fromRGB(255, 120, 20)
	fire.SecondaryColor = Color3.fromRGB(255, 80, 0)
	fire.Parent = fireContainer

	-- Create explosion particles
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 220)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100))
	})
	particleEmitter.LightEmission = 1
	particleEmitter.LightInfluence = 0
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 5),
		NumberSequenceKeypoint.new(1, 15)
	})
	particleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	particleEmitter.Lifetime = NumberRange.new(1, 2)
	particleEmitter.Speed = NumberRange.new(30, 50)
	particleEmitter.SpreadAngle = Vector2.new(180, 180)
	particleEmitter.Acceleration = Vector3.new(0, 15, 0)
	particleEmitter.Rate = 0
	particleEmitter.Enabled = true
	particleEmitter.Parent = fireContainer

	-- Emit a burst of particles
	particleEmitter:Emit(grenadeConfig.particleCount or GRENADE_SETTINGS.EXPLOSION.PARTICLE_COUNT)

	-- Create smoke
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 5),
		NumberSequenceKeypoint.new(0.5, 10),
		NumberSequenceKeypoint.new(1, 20)
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Lifetime = NumberRange.new(2, 5)
	smoke.Speed = NumberRange.new(5, 10)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Acceleration = Vector3.new(0, 5, 0)
	smoke.Rate = 0
	smoke.Enabled = true
	smoke.Parent = fireContainer

	-- Emit smoke
	smoke:Emit(grenadeConfig.particleCount or GRENADE_SETTINGS.EXPLOSION.PARTICLE_COUNT)

	-- Play explosion sound
	self:playSound("Explosion", position)

	-- Apply camera shake to nearby players
	self:applyCameraShake(position)

	-- Clean up effects over time
	task.delay(0.3, function()
		TweenService:Create(light, TweenInfo.new(0.5), {
			Brightness = 0,
			Range = 0
		}):Play()
	end)

	task.delay(0.8, function()
		TweenService:Create(fire, TweenInfo.new(0.5), {
			Size = 0,
			Heat = 0
		}):Play()
	end)

	-- Auto-cleanup
	Debris:AddItem(light, 1)
	Debris:AddItem(fireContainer, 5)
end

-- Apply camera shake to nearby players
function GrenadeSystem:applyCameraShake(position)
	-- Calculate distance to explosion
	local character = self.player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local distance = (character.HumanoidRootPart.Position - position).Magnitude
	local maxDistance = GRENADE_SETTINGS.EXPLOSION.SHAKE_DISTANCE

	-- Only shake if within range
	if distance > maxDistance then return end

	-- Calculate intensity based on distance
	local intensity = GRENADE_SETTINGS.EXPLOSION.SHAKE_INTENSITY * (1 - (distance / maxDistance))
	local duration = GRENADE_SETTINGS.EXPLOSION.SHAKE_DURATION

	-- Apply shake if camera system is available
	local cameraSystem = _G.FPSCameraSystem
	if cameraSystem and cameraSystem.shake then
		cameraSystem:shake(intensity, duration)
	else
		-- Fallback to simple camera shake
		local camera = workspace.CurrentCamera
		if not camera then return end

		local startTime = tick()
		local shakeConnection

		shakeConnection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startTime
			if elapsed > duration then
				shakeConnection:Disconnect()
				return
			end

			-- Fade out shake over time
			local fadeout = 1 - (elapsed / duration)
			local shakeIntensity = intensity * fadeout

			-- Calculate random shake offset
			local shakeX = (math.random() - 0.5) * shakeIntensity
			local shakeY = (math.random() - 0.5) * shakeIntensity

			-- Apply shake
			camera.CFrame = camera.CFrame * CFrame.new(shakeX, shakeY, 0)
		end)
	end
end

-- Show trajectory preview
function GrenadeSystem:showTrajectory(show)
	self.showingTrajectory = show

	if show then
		-- Make trajectory visible
		for i, part in ipairs(self.trajectoryParts) do
			part.Transparency = i / #self.trajectoryParts * 0.8
		end
		self.trajectoryLine.Transparency = 0.3

		-- Start trajectory update
		if not self.trajectoryConnection then
			self.trajectoryConnection = RunService.RenderStepped:Connect(function()
				self:updateTrajectory()
			end)
		end
	else
		-- Hide trajectory
		for _, part in ipairs(self.trajectoryParts) do
			part.Transparency = 1
		end

		self.trajectoryLine.Transparency = 1

		-- Stop trajectory update
		if self.trajectoryConnection then
			self.trajectoryConnection:Disconnect()
			self.trajectoryConnection = nil
		end
	end
end

-- Update trajectory preview
function GrenadeSystem:updateTrajectory()
	if not self.isCooking then return end

	-- Get grenade config
	local grenadeConfig = self.currentGrenade or {}

	-- Calculate throw force based on charge
	local minForce = grenadeConfig.throwForce or GRENADE_SETTINGS.DEFAULT_MIN_THROW_FORCE
	local maxForce = grenadeConfig.throwForceCharged or GRENADE_SETTINGS.DEFAULT_MAX_THROW_FORCE
	local throwForce = minForce + (self.chargeAmount * (maxForce - minForce))

	-- Get throw direction from camera
	local throwDirection = self.camera.CFrame.LookVector

	-- Get throw position (slightly in front of camera)
	local throwPosition = self.camera.CFrame.Position + (throwDirection * 2)

	-- Simulate grenade path
	local points = self:simulateGrenadePath(throwPosition, throwDirection, throwForce)

	-- Update trajectory visualization
	self:updateTrajectoryVisualization(points)
end

-- Simulate grenade path physics
function GrenadeSystem:simulateGrenadePath(position, direction, force)
	-- Get grenade config
	local grenadeConfig = self.currentGrenade or {}

	-- Initial velocity
	local velocity = direction * force

	-- Physics simulation parameters
	local gravity = GRENADE_SETTINGS.GRAVITY
	local dragCoefficient = GRENADE_SETTINGS.DRAG_COEFFICIENT
	local timeStep = GRENADE_SETTINGS.TRAJECTORY.STEP_TIME
	local maxTime = GRENADE_SETTINGS.TRAJECTORY.MAX_TIME
	local numPoints = GRENADE_SETTINGS.TRAJECTORY.POINTS
	local points = {}

	-- Start with current position
	local currentPosition = position
	table.insert(points, {position = currentPosition, hit = false, normal = nil})

	-- Raycast parameters
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {self.player.Character, self.camera, self.effectsFolder}

	-- Simulate path
	for i = 2, numPoints do
		-- Apply physics to velocity (gravity and drag)
		local drag = velocity * velocity.Magnitude * dragCoefficient
		velocity = velocity + (gravity - drag) * timeStep

		-- Calculate new position
		local newPosition = currentPosition + velocity * timeStep

		-- Raycast to check for collisions
		local raycastResult = workspace:Raycast(currentPosition, newPosition - currentPosition, raycastParams)

		if raycastResult then
			-- Hit something, bounce or stop
			local hitPosition = raycastResult.Position
			local hitNormal = raycastResult.Normal
			local hitMaterial = raycastResult.Material

			-- Add hit point
			table.insert(points, {position = hitPosition, hit = true, normal = hitNormal})

			-- Calculate bounce direction
			local bounciness = grenadeConfig.bounciness or GRENADE_SETTINGS.DEFAULT_BOUNCINESS

			-- If bounce factor is very low, stop simulation
			if bounciness < 0.1 then
				break
			end

			-- Calculate reflection vector for bounce
			local dot = velocity:Dot(hitNormal)
			local reflection = velocity - (2 * dot * hitNormal)

			-- Apply bounce with energy loss
			velocity = reflection * bounciness

			-- Continue from hit position
			currentPosition = hitPosition + hitNormal * 0.1 -- Offset slightly to avoid getting stuck
		else
			-- No hit, continue trajectory
			table.insert(points, {position = newPosition, hit = false, normal = nil})
			currentPosition = newPosition
		end

		-- Check if we've reached max simulation time
		if i * timeStep >= maxTime then
			break
		end
	end

	return points
end

-- Update trajectory visualization with simulated path
function GrenadeSystem:updateTrajectoryVisualization(points)
	-- Update trajectory dots
	for i, part in ipairs(self.trajectoryParts) do
		if i <= #points then
			local pointData = points[i]
			part.Position = pointData.position

			-- Fade transparency over distance
			local fadeFactor = i / #self.trajectoryParts
			local baseTransparency = math.max(0.2, fadeFactor)

			if pointData.hit then
				-- Show hit points more clearly
				part.Transparency = baseTransparency * 0.5
				part.Color = Color3.fromRGB(255, 100, 100)
			else
				part.Transparency = baseTransparency
				part.Color = GRENADE_SETTINGS.TRAJECTORY.COLOR
			end
		else
			-- Hide unused points
			part.Transparency = 1
		end
	end

	-- Update trajectory line
	if #points >= 2 then
		-- Get first and last visible points
		local startPos = points[1].position
		local endPos = points[math.min(#points, #self.trajectoryParts)].position

		-- Calculate center and size
		local distance = (endPos - startPos).Magnitude
		local center = (startPos + endPos) / 2

		-- Orient line along trajectory
		self.trajectoryLine.Size = Vector3.new(
			GRENADE_SETTINGS.TRAJECTORY.LINE_THICKNESS,
			GRENADE_SETTINGS.TRAJECTORY.LINE_THICKNESS,
			distance
		)
		self.trajectoryLine.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance/2)
	end
end

-- Handle mouse button 1 (throw/cook grenade)
function GrenadeSystem:handleMouseButton1(isDown)
	if isDown then
		-- Start cooking
		return self:startCooking()
	else
		-- Throw if was cooking
		if self.isCooking then
			self:stopCooking(true) -- Throw
			return true
		end
	end

	return false
end

-- Handle mouse button 2 (show trajectory)
function GrenadeSystem:handleMouseButton2(isDown)
	-- Show trajectory visualization
	self:showTrajectory(isDown)
	return isDown
end

-- Play sound effects
function GrenadeSystem:playSound(soundType, position)
	-- Get grenade config
	local grenadeConfig = self.currentGrenade or {}

	-- Get sound ID
	local soundId
	if grenadeConfig.sounds and grenadeConfig.sounds[soundType] then
		soundId = grenadeConfig.sounds[soundType]
	else
		-- Default sounds
		local defaultSounds = {
			Pin = "rbxassetid://8186569638",
			Throw = "rbxassetid://8186570431",
			Bounce = "rbxassetid://142082167",
			Explosion = "rbxassetid://2814355743"
		}

		soundId = defaultSounds[soundType]
	end

	if not soundId then return end

	-- Create sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId

	-- Configure sound based on type
	if soundType == "Explosion" then
		sound.Volume = 1.5
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 5
		sound.RollOffMaxDistance = 100

		-- Position sound at explosion location
		if position then
			local soundPart = Instance.new("Part")
			soundPart.Anchored = true
			soundPart.CanCollide = false
			soundPart.Transparency = 1
			soundPart.Position = position
			soundPart.Parent = self.effectsFolder

			sound.Parent = soundPart
			Debris:AddItem(soundPart, 5)
		else
			sound.Parent = self.effectsFolder
		end
	elseif soundType == "Bounce" then
		sound.Volume = 0.6
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 5
		sound.RollOffMaxDistance = 50

		-- Position sound at bounce location
		if position then
			local soundPart = Instance.new("Part")
			soundPart.Anchored = true
			soundPart.CanCollide = false
			soundPart.Transparency = 1
			soundPart.Position = position
			soundPart.Parent = self.effectsFolder

			sound.Parent = soundPart
			Debris:AddItem(soundPart, 2)
		else
			sound.Parent = self.effectsFolder
		end
	else
		sound.Volume = 0.8
		sound.Parent = self.camera
	end

	-- Play sound
	sound:Play()

	-- Cleanup non-positioned sounds
	if not position then
		Debris:AddItem(sound, sound.TimeLength + 0.1)
	end
end

-- Play bounce sound with volume based on velocity
function GrenadeSystem:playBounceSound(position, velocity)
	local volume = math.min(0.2 + (velocity / 50), 0.8)

	-- Create sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://142082167" -- Default bounce sound
	sound.Volume = volume
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 5
	sound.RollOffMaxDistance = 50

	-- Position sound
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.Position = position
	soundPart.Parent = self.effectsFolder

	sound.Parent = soundPart
	sound:Play()

	-- Cleanup
	Debris:AddItem(soundPart, 2)
end

-- Clean up
function GrenadeSystem:cleanup()
	print("Cleaning up Grenade System")

	-- Stop any active cooking
	if self.isCooking then
		self:stopCooking(false)
	end

	-- Stop showing trajectory
	if self.showingTrajectory then
		self:showTrajectory(false)
	end

	-- Clean up connections
	if self.trajectoryConnection then
		self.trajectoryConnection:Disconnect()
		self.trajectoryConnection = nil
	end

	-- Clean up trajectory parts
	for _, part in ipairs(self.trajectoryParts) do
		part:Destroy()
	end
	self.trajectoryParts = {}

	if self.trajectoryLine then
		self.trajectoryLine:Destroy()
		self.trajectoryLine = nil
	end

	-- Clean up cooking indicator
	if self.cookIndicator then
		self.cookIndicator:Destroy()
		self.cookIndicator = nil
	end

	print("Grenade System cleanup complete")
end

return GrenadeSystem