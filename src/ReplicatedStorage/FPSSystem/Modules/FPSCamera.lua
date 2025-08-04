-- FPSCamera.lua
-- Enhanced first-person camera system with proper character handling
-- Place in ReplicatedStorage.FPSSystem.Modules

local FPSCamera = {}
FPSCamera.__index = FPSCamera

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Constants
local CAMERA_SETTINGS = {
	-- View limits
	PITCH_LIMIT_UP = 80,     -- Look up limit (degrees)
	PITCH_LIMIT_DOWN = 80,   -- Look down limit (degrees)

	-- Sensitivity
	SENSITIVITY = 0.5,       -- Base mouse sensitivity
	SENSITIVITY_ADS = 0.3,   -- ADS sensitivity multiplier

	-- Camera positioning
	HEAD_OFFSET = Vector3.new(0, 1.6, 0), -- Camera offset from character root
	CULL_DISTANCE = 1,       -- Distance at which character parts are hidden

	-- Head bob settings
	BOB = {
		ENABLED = true,
		INTENSITY = 0.05,    -- Intensity of camera bob
		SPEED = 10,          -- Speed of camera bob
		SPRINT_MULT = 1.5    -- Bob multiplier when sprinting
	},

	-- Sway settings
	SWAY = {
		ENABLED = true,
		AMOUNT = 0.1,        -- Sway amount when moving mouse
		SMOOTHING = 10,      -- Sway smoothing factor (higher = smoother)
		RETURN_SPEED = 5     -- Speed at which sway returns to center
	},

	-- Recoil settings
	RECOIL = {
		RECOVERY_SPEED = 5,  -- Speed at which recoil recovers
		MAX_CAMERA_KICK = 15 -- Maximum camera kick in degrees
	},

	-- Animations
	ANIMATION = {
		ADS_TIME = 0.2,      -- Time to aim down sights
		LAND_INTENSITY = 0.5, -- Landing shake intensity
		LAND_DURATION = 0.3  -- Landing shake duration
	},

	-- Scope settings
	SCOPE = {
		DEFAULT_FOV = 70,    -- Default field of view
		MIN_FOV = 20,        -- Minimum FOV when scoped
		BLUR_AMOUNT = 15     -- Amount of blur outside scope
	},

	-- Debug settings
	DEBUG = false           -- Enable debug visuals
}

-- Constructor
function FPSCamera.new()
	local self = setmetatable({}, FPSCamera)

	-- Core components
	self.player = Players.LocalPlayer
	self.camera = workspace.CurrentCamera
	self.character = nil
	self.humanoid = nil
	self.rootPart = nil

	-- Camera state
	self.rotationX = 0       -- Horizontal rotation (yaw)
	self.rotationY = 0       -- Vertical rotation (pitch)
	self.targetRotX = 0      -- Target horizontal rotation
	self.targetRotY = 0      -- Target vertical rotation
	self.originalFOV = 70    -- Original field of view
	self.targetFOV = 70      -- Target field of view
	self.currentFOV = 70     -- Current field of view

	-- Recoil and sway
	self.recoil = Vector3.new()        -- Current recoil offset
	self.sway = Vector3.new()          -- Current sway offset
	self.bob = Vector3.new()           -- Current bob offset
	self.lastMouseDelta = Vector2.new() -- Last mouse movement
	self.bobCycle = 0                  -- Bob animation cycle

	-- Character state
	self.isAiming = false
	self.isSprinting = false
	self.isMoving = false
	self.isGrounded = true
	self.jumpState = false   -- Used to detect landing
	self.walkSpeed = 16      -- Default walk speed
	self.adsScale = 1        -- Scale applied during ADS

	-- Character transparency management
	self.transparencyConnections = {}

	-- Set up the camera
	self:setupCamera()

	-- Connect to player's character 
	self:setupCharacterHandling()

	-- Create debugging elements
	if CAMERA_SETTINGS.DEBUG then
		self:createDebugVisuals()
	end

	-- Export to _G for other systems to access
	_G.FPSCameraSystem = self

	print("FPS Camera system initialized")
	return self
end

-- Set up the camera with correct settings
function FPSCamera:setupCamera()
	-- Set camera type
	self.camera.CameraType = Enum.CameraType.Scriptable

	-- Save original field of view
	self.originalFOV = self.camera.FieldOfView
	self.targetFOV = self.originalFOV
	self.currentFOV = self.originalFOV

	-- Lock the mouse
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	-- Connect mouse movement
	self.mouseConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			self:handleMouseMovement(input)
		end
	end)

	-- Connect update function to RenderStepped
	self.updateConnection = RunService.RenderStepped:Connect(function(dt)
		self:update(dt)
	end)

	print("Camera setup complete")
end

-- Set up character handling
function FPSCamera:setupCharacterHandling()
	-- Handle current character if it exists
	if self.player.Character then
		self:setupCharacter(self.player.Character)
	end

	-- Connect to character added event
	self.characterAddedConnection = self.player.CharacterAdded:Connect(function(char)
		self:setupCharacter(char)
	end)

	print("Character handling setup complete")
end

-- Set up the character
function FPSCamera:setupCharacter(character)
	print("Setting up character for FPS Camera")

	-- Clean up any existing connections
	self:cleanupTransparencyConnections()

	-- Store character references
	self.character = character

	-- Wait for humanoid
	self.humanoid = character:WaitForChild("Humanoid")
	self.rootPart = character:WaitForChild("HumanoidRootPart")

	-- Reset rotation to match character
	local rootCF = self.rootPart.CFrame
	self.rotationX = math.atan2(rootCF.LookVector.X, rootCF.LookVector.Z)
	self.rotationY = 0
	self.targetRotX = self.rotationX
	self.targetRotY = self.rotationY

	-- Store default walk speed
	self.walkSpeed = self.humanoid.WalkSpeed

	-- Connect to humanoid state changes
	self.humanoidStateConnection = self.humanoid.StateChanged:Connect(function(oldState, newState)
		self:handleStateChange(oldState, newState)
	end)

	-- Make character parts invisible from first person
	self:setupCharacterTransparency()

	print("Character setup complete")
end

-- Handle character transparency
function FPSCamera:setupCharacterTransparency()
	print("Setting up character transparency")

	-- Function to handle transparency for a part
	local function handleTransparency(part)
		if part:IsA("BasePart") or part:IsA("Decal") then
			-- Set local transparency to fully transparent
			part.LocalTransparencyModifier = 1

			-- Track connection for cleanup
			table.insert(self.transparencyConnections, 
				part:GetPropertyChangedSignal("Transparency"):Connect(function()
					-- Maintain local invisibility while allowing server changes
					part.LocalTransparencyModifier = 1
				end))
		end
	end

	-- Apply to all existing parts
	for _, part in ipairs(self.character:GetDescendants()) do
		handleTransparency(part)
	end

	-- Handle future parts
	local descendantAddedConnection = self.character.DescendantAdded:Connect(function(descendant)
		handleTransparency(descendant)
	end)

	-- Store connection for cleanup
	table.insert(self.transparencyConnections, descendantAddedConnection)

	print("Character transparency setup complete")
end

-- Handle humanoid state changes
function FPSCamera:handleStateChange(oldState, newState)
	-- Detect jumping and landing
	if oldState == Enum.HumanoidStateType.Jumping then
		self.jumpState = true
		self.isGrounded = false
	elseif (newState == Enum.HumanoidStateType.Running or
		newState == Enum.HumanoidStateType.RunningNoPhysics) and
		self.jumpState then
		-- Player has landed
		self.jumpState = false
		self.isGrounded = true
		self:applyLandingEffect()
	end

	-- Update grounded state
	if newState == Enum.HumanoidStateType.Freefall then
		self.isGrounded = false
	elseif newState == Enum.HumanoidStateType.Running or
		newState == Enum.HumanoidStateType.RunningNoPhysics then
		self.isGrounded = true
	end
end

-- Apply landing camera effect
function FPSCamera:applyLandingEffect()
	-- Add a quick camera dip when landing
	local intensity = CAMERA_SETTINGS.ANIMATION.LAND_INTENSITY
	local duration = CAMERA_SETTINGS.ANIMATION.LAND_DURATION

	-- Add a downward recoil that will recover naturally
	self.recoil = Vector3.new(intensity, 0, 0)

	-- Apply a FOV pulse effect
	local originalFOV = self.targetFOV
	self.targetFOV = originalFOV - 5

	-- Return to normal FOV
	task.delay(duration / 2, function()
		self.targetFOV = originalFOV
	end)
end

-- Handle mouse movement
function FPSCamera:handleMouseMovement(input)
	-- Calculate sensitivity based on aiming state
	local sensitivity = CAMERA_SETTINGS.SENSITIVITY
	if self.isAiming then
		sensitivity = sensitivity * CAMERA_SETTINGS.SENSITIVITY_ADS

		-- Apply additional zoom sensitivity scaling if provided
		if self.adsScale ~= 1 then
			sensitivity = sensitivity * self.adsScale
		end
	end

	-- Update rotation based on mouse movement
	self.targetRotY = math.clamp(
		self.targetRotY - input.Delta.Y * sensitivity,
		-CAMERA_SETTINGS.PITCH_LIMIT_DOWN,
		CAMERA_SETTINGS.PITCH_LIMIT_UP
	)
	self.targetRotX = self.targetRotX - input.Delta.X * sensitivity

	-- Store mouse delta for sway calculations
	self.lastMouseDelta = Vector2.new(
		input.Delta.X * sensitivity * 0.1,
		input.Delta.Y * sensitivity * 0.1
	)
end

-- Main update function
function FPSCamera:update(dt)
	if not self.rootPart then return end

	-- Smooth camera movement
	self.rotationX = self:lerpAngle(self.rotationX, self.targetRotX, 0.5)
	self.rotationY = self:lerp(self.rotationY, self.targetRotY, 0.5)

	-- Update recoil recovery
	self:updateRecoil(dt)

	-- Update camera sway
	if CAMERA_SETTINGS.SWAY.ENABLED then
		self:updateSway(dt)
	end

	-- Update head bob
	if CAMERA_SETTINGS.BOB.ENABLED then
		self:updateHeadBob(dt)
	end

	-- Update FOV
	self:updateFOV(dt)

	-- Calculate camera position (offset from character)
	local cameraPos = self.rootPart.Position + CAMERA_SETTINGS.HEAD_OFFSET

	-- Calculate camera angles with recoil
	local recoilX = self.recoil.X
	local recoilY = self.recoil.Y
	local recoilZ = self.recoil.Z

	local cameraAngleX = math.rad(self.rotationX + recoilY)
	local cameraAngleY = math.rad(self.rotationY + recoilX)
	local cameraAngleZ = math.rad(recoilZ)

	-- Create base camera CFrame
	local cameraCFrame = CFrame.new(cameraPos) *
		CFrame.Angles(0, cameraAngleX, 0) *
		CFrame.Angles(cameraAngleY, 0, cameraAngleZ)

	-- Apply sway and bob
	local swayCFrame = CFrame.new(self.sway.X, self.sway.Y, self.sway.Z)
	local bobCFrame = CFrame.new(self.bob.X, self.bob.Y, self.bob.Z)

	-- Set final camera CFrame
	self.camera.CFrame = cameraCFrame * swayCFrame * bobCFrame

	-- Update player's character orientation to match camera
	self:updateCharacterOrientation()
end

-- Update character orientation to match camera
function FPSCamera:updateCharacterOrientation()
	if not self.rootPart or not self.humanoid then return end

	-- Only rotate character horizontally, not vertically
	local characterCFrame = CFrame.new(self.rootPart.Position) *
		CFrame.Angles(0, math.rad(self.rotationX), 0)

	-- Set the orientation without affecting the position
	self.rootPart.CFrame = CFrame.new(self.rootPart.Position) * 
		(characterCFrame - characterCFrame.Position)
end

-- Update field of view
function FPSCamera:updateFOV(dt)
	-- Smoothly interpolate FOV
	self.currentFOV = self:lerp(self.currentFOV, self.targetFOV, 10 * dt)
	self.camera.FieldOfView = self.currentFOV
end

-- Update recoil recovery
function FPSCamera:updateRecoil(dt)
	-- Gradually reduce recoil over time
	local recovery = CAMERA_SETTINGS.RECOIL.RECOVERY_SPEED * dt
	self.recoil = Vector3.new(
		self.recoil.X * (1 - recovery),
		self.recoil.Y * (1 - recovery),
		self.recoil.Z * (1 - recovery)
	)
end

-- Update camera sway based on mouse movement
function FPSCamera:updateSway(dt)
	local swayAmount = CAMERA_SETTINGS.SWAY.AMOUNT

	-- Reduce sway when aiming
	if self.isAiming then
		swayAmount = swayAmount * 0.5
	end

	-- Calculate target sway from mouse movement
	local targetSwayX = -self.lastMouseDelta.X * swayAmount
	local targetSwayY = -self.lastMouseDelta.Y * swayAmount

	-- Smoothly interpolate current sway
	self.sway = Vector3.new(
		self:lerp(self.sway.X, targetSwayX, CAMERA_SETTINGS.SWAY.SMOOTHING * dt),
		self:lerp(self.sway.Y, targetSwayY, CAMERA_SETTINGS.SWAY.SMOOTHING * dt),
		self.sway.Z
	)

	-- Return sway to center when not moving mouse
	local returnSpeed = CAMERA_SETTINGS.SWAY.RETURN_SPEED * dt
	self.lastMouseDelta = Vector2.new(
		self.lastMouseDelta.X * (1 - returnSpeed),
		self.lastMouseDelta.Y * (1 - returnSpeed)
	)
end

-- Update head bob animation
function FPSCamera:updateHeadBob(dt)
	local bobEnabled = CAMERA_SETTINGS.BOB.ENABLED
	local bobIntensity = CAMERA_SETTINGS.BOB.INTENSITY
	local bobSpeed = CAMERA_SETTINGS.BOB.SPEED

	-- Only bob when moving and on ground
	if not self.isMoving or not self.isGrounded then
		-- Gradually reset bob
		self.bob = Vector3.new(
			self:lerp(self.bob.X, 0, 5 * dt),
			self:lerp(self.bob.Y, 0, 5 * dt),
			self.bob.Z
		)
		return
	end

	-- Adjust bob for sprinting
	if self.isSprinting then
		bobIntensity = bobIntensity * CAMERA_SETTINGS.BOB.SPRINT_MULT
		bobSpeed = bobSpeed * CAMERA_SETTINGS.BOB.SPRINT_MULT
	end

	-- Reduce bob when aiming
	if self.isAiming then
		bobIntensity = bobIntensity * 0.3
	end

	-- Update bob cycle
	self.bobCycle = (self.bobCycle + dt * bobSpeed) % (math.pi * 2)

	-- Calculate bob offsets
	self.bob = Vector3.new(
		math.sin(self.bobCycle) * bobIntensity,
		math.abs(math.sin(self.bobCycle * 0.5)) * bobIntensity,
		0
	)
end

-- Set aiming state
function FPSCamera:setAiming(isAiming, zoomLevel)
	self.isAiming = isAiming

	-- Set FOV based on aiming state
	if isAiming then
		-- Use custom zoom level if provided
		local targetZoom = CAMERA_SETTINGS.SCOPE.DEFAULT_FOV

		if zoomLevel then
			targetZoom = zoomLevel
			-- Store sensitivity scale based on zoom level
			self.adsScale = zoomLevel / self.originalFOV
		else
			-- Default ADS zoom
			targetZoom = self.originalFOV * 0.7
			self.adsScale = 0.7
		end

		-- Clamp to minimum FOV
		self.targetFOV = math.max(targetZoom, CAMERA_SETTINGS.SCOPE.MIN_FOV)
	else
		-- Reset to default FOV
		self.targetFOV = self.originalFOV
		self.adsScale = 1
	end
end

-- Set sprinting state
function FPSCamera:setSprinting(isSprinting)
	self.isSprinting = isSprinting

	-- Disable sprinting while aiming
	if isSprinting and self.isAiming then
		return
	end

	-- Update humanoid speed
	if self.humanoid then
		if isSprinting then
			self.humanoid.WalkSpeed = self.walkSpeed * 1.5
		else
			self.humanoid.WalkSpeed = self.walkSpeed
		end
	end
end

-- Set moving state
function FPSCamera:setMoving(isMoving)
	self.isMoving = isMoving
end

-- Add recoil to camera
function FPSCamera:addRecoil(vertical, horizontal)
	-- Clamp to maximum recoil
	vertical = math.clamp(vertical or 0, 0, CAMERA_SETTINGS.RECOIL.MAX_CAMERA_KICK)
	horizontal = math.clamp(horizontal or 0, -CAMERA_SETTINGS.RECOIL.MAX_CAMERA_KICK, CAMERA_SETTINGS.RECOIL.MAX_CAMERA_KICK)

	-- Reduce recoil when aiming
	if self.isAiming then
		vertical = vertical * 0.7
		horizontal = horizontal * 0.7
	end

	-- Add some randomness to recoil direction
	local randomZ = (math.random() - 0.5) * 0.2

	-- Apply recoil to current recoil vector
	self.recoil = Vector3.new(
		self.recoil.X + vertical,
		self.recoil.Y + horizontal,
		self.recoil.Z + randomZ
	)
end

-- Apply a camera shake
function FPSCamera:shake(intensity, duration, frequency)
	intensity = intensity or 1
	duration = duration or 0.5
	frequency = frequency or 10

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

		-- Apply shake as recoil
		self.recoil = Vector3.new(
			self.recoil.X + shakeX,
			self.recoil.Y + shakeY,
			self.recoil.Z
		)
	end)
end

-- Create debug visuals
function FPSCamera:createDebugVisuals()
	-- Create debug text
	local debugGui = Instance.new("ScreenGui")
	debugGui.Name = "FPSCameraDebug"

	local debugText = Instance.new("TextLabel")
	debugText.Size = UDim2.new(0, 300, 0, 200)
	debugText.Position = UDim2.new(0, 10, 0, 10)
	debugText.BackgroundTransparency = 0.7
	debugText.BackgroundColor3 = Color3.new(0, 0, 0)
	debugText.TextColor3 = Color3.new(1, 1, 1)
	debugText.TextXAlignment = Enum.TextXAlignment.Left
	debugText.TextYAlignment = Enum.TextYAlignment.Top
	debugText.Parent = debugGui

	debugGui.Parent = self.player.PlayerGui
	self.debugText = debugText

	-- Update debug text
	RunService.RenderStepped:Connect(function()
		if not self.debugText then return end

		self.debugText.Text = string.format(
			"FPS Camera Debug\nRotX: %.2f\nRotY: %.2f\nRecoil: (%.2f, %.2f, %.2f)\nSway: (%.2f, %.2f, %.2f)\nBob: (%.2f, %.2f, %.2f)\nFOV: %.1f\nAiming: %s\nSprinting: %s\nMoving: %s\nGrounded: %s",
			self.rotationX, self.rotationY,
			self.recoil.X, self.recoil.Y, self.recoil.Z,
			self.sway.X, self.sway.Y, self.sway.Z,
			self.bob.X, self.bob.Y, self.bob.Z,
			self.currentFOV,
			tostring(self.isAiming),
			tostring(self.isSprinting),
			tostring(self.isMoving),
			tostring(self.isGrounded)
		)
	end)
end

-- Utility function: Lerp between two values
function FPSCamera:lerp(a, b, t)
	return a + (b - a) * t
end

-- Utility function: Lerp between two angles
function FPSCamera:lerpAngle(a, b, t)
	-- Find the shortest path around the circle
	local diff = (b - a) % 360
	if diff > 180 then
		diff = diff - 360
	end

	return a + diff * t
end

-- Clean up transparency connections
function FPSCamera:cleanupTransparencyConnections()
	for _, connection in ipairs(self.transparencyConnections) do
		connection:Disconnect()
	end
	self.transparencyConnections = {}

	if self.humanoidStateConnection then
		self.humanoidStateConnection:Disconnect()
		self.humanoidStateConnection = nil
	end
end

-- Clean up everything
function FPSCamera:destroy()
	print("Cleaning up FPS Camera")

	-- Disconnect all events
	if self.mouseConnection then
		self.mouseConnection:Disconnect()
	end

	if self.updateConnection then
		self.updateConnection:Disconnect()
	end

	if self.characterAddedConnection then
		self.characterAddedConnection:Disconnect()
	end

	-- Clean up any character connections
	self:cleanupTransparencyConnections()

	-- Reset camera
	self.camera.CameraType = Enum.CameraType.Custom

	-- Unlock mouse
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	-- Reset humanoid speed if it exists
	if self.humanoid then
		self.humanoid.WalkSpeed = self.walkSpeed
	end

	-- Remove debug GUI if it exists
	if self.debugText and self.debugText.Parent then
		self.debugText.Parent:Destroy()
	end

	-- Remove global reference
	if _G.FPSCameraSystem == self then
		_G.FPSCameraSystem = nil
	end

	print("FPS Camera cleanup complete")
end

return FPSCamera