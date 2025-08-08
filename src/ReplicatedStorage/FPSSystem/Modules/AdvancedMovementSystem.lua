-- AdvancedMovementSystem.lua
-- Advanced movement system with diving, sliding, crouching, and prone
-- Inspired by Phantom Forces movement mechanics

local AdvancedMovementSystem = {}
AdvancedMovementSystem.__index = AdvancedMovementSystem

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Constants
local MOVEMENT_SETTINGS = {
	-- Walking and running
	WALK_SPEED = 16,
	SPRINT_SPEED = 24,
	ADS_WALK_SPEED = 10,
	
	-- Crouching
	CROUCH_SPEED = 8,
	CROUCH_HEIGHT = 6,  -- Default character height is ~10
	CROUCH_JUMP_POWER = 30, -- Reduced jump power when crouched
	
	-- Prone
	PRONE_SPEED = 3,
	PRONE_HEIGHT = 2,
	PRONE_JUMP_POWER = 0, -- Can't jump when prone
	
	-- Sliding
	SLIDE_SPEED = 35,
	SLIDE_DURATION = 2.0,
	SLIDE_DECELERATION = 0.95, -- Less aggressive deceleration
	SLIDE_MIN_SPEED = 15, -- Lower minimum speed required to slide
	SLIDE_COOLDOWN = 1.5,
	
	-- Diving
	DIVE_FORCE = 50,
	DIVE_UP_FORCE = 20,
	DIVE_DURATION = 0.8,
	DIVE_RECOVERY_TIME = 1.2,
	DIVE_COOLDOWN = 3.0,
	
	-- Fall damage
	FALL_DAMAGE_ENABLED = true,
	SAFE_FALL_HEIGHT = 20,
	MAX_FALL_HEIGHT = 100,
	MAX_FALL_DAMAGE = 50,
	
	-- Animation speeds
	STANCE_TRANSITION_TIME = 0.3,
	CAMERA_OFFSET_TIME = 0.2,
	
	-- Physics
	GRAVITY = 196.2, -- Roblox default gravity
	GROUND_RAYCAST_DISTANCE = 5,
}

-- Movement states
local MovementStates = {
	STANDING = "STANDING",
	CROUCHING = "CROUCHING", 
	PRONE = "PRONE",
	SLIDING = "SLIDING",
	DIVING = "DIVING",
	SPRINTING = "SPRINTING"
}

-- Constructor
function AdvancedMovementSystem.new()
	local self = setmetatable({}, AdvancedMovementSystem)
	
	-- Core references
	self.player = Players.LocalPlayer
	self.character = nil
	self.humanoid = nil
	self.rootPart = nil
	self.camera = workspace.CurrentCamera
	
	-- Movement state
	self.currentState = MovementStates.STANDING
	self.previousState = MovementStates.STANDING
	self.isGrounded = true
	self.lastGroundHeight = 0
	self.fallStartHeight = 0
	
	-- Input tracking
	self.keysPressed = {}
	self.lastSlideTime = 0
	self.lastDiveTime = 0
	
	-- Animation state
	self.currentTween = nil
	self.originalWalkSpeed = MOVEMENT_SETTINGS.WALK_SPEED
	self.originalJumpPower = 50
	
	-- Slide state
	self.slideStartTime = 0
	self.slideDirection = Vector3.new()
	self.slideSpeed = 0
	
	-- Dive state
	self.isDiving = false
	self.diveStartTime = 0
	self.diveBodyVelocity = nil
	
	-- Setup the system
	self:setupCharacterHandling()
	self:setupInputHandling()
	
	-- Export to global
	_G.AdvancedMovementSystem = self
	
	print("Advanced Movement System initialized")
	return self
end

-- Set up character handling
function AdvancedMovementSystem:setupCharacterHandling()
	-- Handle current character
	if self.player.Character then
		self:setupCharacter(self.player.Character)
	end
	
	-- Handle character respawning
	self.player.CharacterAdded:Connect(function(character)
		self:setupCharacter(character)
	end)
end

-- Set up character references
function AdvancedMovementSystem:setupCharacter(character)
	self.character = character
	self.humanoid = character:WaitForChild("Humanoid")
	self.rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Store original values
	self.originalWalkSpeed = self.humanoid.WalkSpeed
	self.originalJumpPower = self.humanoid.JumpPower or 50
	
	-- Connect to humanoid state changes
	self.humanoid.StateChanged:Connect(function(oldState, newState)
		self:handleStateChange(oldState, newState)
	end)
	
	-- Start update loop
	if self.updateConnection then
		self.updateConnection:Disconnect()
	end
	
	self.updateConnection = RunService.Heartbeat:Connect(function(dt)
		self:update(dt)
	end)
	
	print("Character setup complete for advanced movement")
end

-- Set up input handling
function AdvancedMovementSystem:setupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:handleInputBegan(input)
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:handleInputEnded(input)
	end)
end

-- Handle input began
function AdvancedMovementSystem:handleInputBegan(input)
	if not self.character then return end
	
	local keyCode = input.KeyCode
	self.keysPressed[keyCode] = true
	
	-- C key - Crouch/Slide
	if keyCode == Enum.KeyCode.C then
		if self:canSlide() then
			self:startSlide()
		else
			self:toggleCrouch()
		end
	
	-- X key - Prone (hold) / Dive (Space + X)
	elseif keyCode == Enum.KeyCode.X then
		if self.keysPressed[Enum.KeyCode.Space] then
			-- Diving (Space + X) - prevent prone when diving
			if self:canDive() then
				self:startDive()
				return -- Don't process prone
			end
		end
		-- Only toggle prone if not diving
		if self.currentState ~= MovementStates.DIVING then
			self:toggleProne()
		end
	
	-- Left Shift - Sprint
	elseif keyCode == Enum.KeyCode.LeftShift then
		self:setSprinting(true)
	
	-- Space - Jump / Dive combo
	elseif keyCode == Enum.KeyCode.Space then
		if self.keysPressed[Enum.KeyCode.X] then
			-- Diving combo
			if self:canDive() then
				self:startDive()
			end
		end
	end
end

-- Handle input ended
function AdvancedMovementSystem:handleInputEnded(input)
	if not self.character then return end
	
	local keyCode = input.KeyCode
	self.keysPressed[keyCode] = false
	
	-- Left Shift - Stop sprinting
	if keyCode == Enum.KeyCode.LeftShift then
		self:setSprinting(false)
	end
end

-- Main update function
function AdvancedMovementSystem:update(dt)
	if not self.character or not self.humanoid or not self.rootPart then return end
	
	-- Update ground detection
	self:updateGroundDetection()
	
	-- Update current movement state
	self:updateMovementState(dt)
	
	-- Update fall damage detection
	self:updateFallDamage()
	
	-- Update camera effects
	self:updateCameraEffects()
end

-- Update ground detection
function AdvancedMovementSystem:updateGroundDetection()
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {self.character}
	
	local rayResult = workspace:Raycast(
		self.rootPart.Position,
		Vector3.new(0, -MOVEMENT_SETTINGS.GROUND_RAYCAST_DISTANCE, 0),
		raycastParams
	)
	
	local wasGrounded = self.isGrounded
	self.isGrounded = rayResult ~= nil
	
	-- Track fall start height
	if wasGrounded and not self.isGrounded then
		self.fallStartHeight = self.rootPart.Position.Y
	end
	
	if rayResult then
		self.lastGroundHeight = rayResult.Position.Y
	end
end

-- Update movement state logic
function AdvancedMovementSystem:updateMovementState(dt)
	-- Handle sliding
	if self.currentState == MovementStates.SLIDING then
		self:updateSliding(dt)
	end
	
	-- Handle diving
	if self.currentState == MovementStates.DIVING then
		self:updateDiving(dt)
	end
	
	-- Update humanoid properties based on state
	self:updateHumanoidProperties()
end

-- Update sliding mechanics
function AdvancedMovementSystem:updateSliding(dt)
	local slideTime = tick() - self.slideStartTime
	
	-- Check if slide should end
	if slideTime >= MOVEMENT_SETTINGS.SLIDE_DURATION or not self.isGrounded then
		self:endSlide()
		return
	end
	
	-- Decelerate slide more gradually
	self.slideSpeed = self.slideSpeed * (MOVEMENT_SETTINGS.SLIDE_DECELERATION ^ dt)
	
	-- End slide if speed is too low
	if self.slideSpeed < 8 then
		self:endSlide()
		return
	end
	
	-- Apply slide movement with downward force to keep on ground
	local bodyVelocity = self.rootPart:FindFirstChild("SlideVelocity")
	if bodyVelocity then
		local slideVelocity = self.slideDirection * self.slideSpeed
		slideVelocity = slideVelocity + Vector3.new(0, -20, 0) -- Keep on ground
		bodyVelocity.Velocity = slideVelocity
		bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000) -- Allow vertical force
	end
end

-- Update diving mechanics
function AdvancedMovementSystem:updateDiving(dt)
	local diveTime = tick() - self.diveStartTime
	
	-- Check if dive should end
	if diveTime >= MOVEMENT_SETTINGS.DIVE_DURATION or (self.isGrounded and diveTime > 0.3) then
		self:endDive()
		return
	end
end

-- Update humanoid properties based on current state
function AdvancedMovementSystem:updateHumanoidProperties()
	if not self.humanoid then return end
	
	local targetSpeed = MOVEMENT_SETTINGS.WALK_SPEED
	local targetJumpPower = self.originalJumpPower
	
	-- Determine speed and jump power based on state
	if self.currentState == MovementStates.CROUCHING then
		targetSpeed = MOVEMENT_SETTINGS.CROUCH_SPEED
		targetJumpPower = MOVEMENT_SETTINGS.CROUCH_JUMP_POWER
		
	elseif self.currentState == MovementStates.PRONE then
		targetSpeed = MOVEMENT_SETTINGS.PRONE_SPEED
		targetJumpPower = MOVEMENT_SETTINGS.PRONE_JUMP_POWER
		
	elseif self.currentState == MovementStates.SLIDING then
		targetSpeed = 0 -- Movement handled by BodyVelocity
		targetJumpPower = 0
		
	elseif self.currentState == MovementStates.DIVING then
		targetSpeed = 0 -- Movement handled by BodyVelocity
		targetJumpPower = 0
		
	elseif self.currentState == MovementStates.SPRINTING then
		targetSpeed = MOVEMENT_SETTINGS.SPRINT_SPEED
		targetJumpPower = self.originalJumpPower
		
	end
	
	-- Apply speed and jump power
	self.humanoid.WalkSpeed = targetSpeed
	self.humanoid.JumpPower = targetJumpPower
end

-- Update fall damage
function AdvancedMovementSystem:updateFallDamage()
	if not MOVEMENT_SETTINGS.FALL_DAMAGE_ENABLED then return end
	if not self.isGrounded or self.fallStartHeight == 0 then return end
	
	local fallDistance = self.fallStartHeight - self.rootPart.Position.Y
	
	if fallDistance > MOVEMENT_SETTINGS.SAFE_FALL_HEIGHT then
		local damagePercent = math.min(
			(fallDistance - MOVEMENT_SETTINGS.SAFE_FALL_HEIGHT) / 
			(MOVEMENT_SETTINGS.MAX_FALL_HEIGHT - MOVEMENT_SETTINGS.SAFE_FALL_HEIGHT),
			1
		)
		
		local damage = damagePercent * MOVEMENT_SETTINGS.MAX_FALL_DAMAGE
		
		if damage > 5 then
			self.humanoid:TakeDamage(damage)
			print("Fall damage:", math.floor(damage), "from", math.floor(fallDistance), "studs")
		end
	end
	
	self.fallStartHeight = 0
end

-- Update camera effects based on movement state
function AdvancedMovementSystem:updateCameraEffects()
	-- This would integrate with the FPS camera system
	if _G.FPSCameraSystem then
		local cameraOffset = Vector3.new(0, 0, 0)
		
		if self.currentState == MovementStates.CROUCHING then
			cameraOffset = Vector3.new(0, -2, 0)
		elseif self.currentState == MovementStates.PRONE then
			cameraOffset = Vector3.new(0, -4, 0)
		end
		
		-- Apply offset to camera system (this would need to be implemented in FPSCamera)
		-- _G.FPSCameraSystem:setHeadOffset(cameraOffset)
	end
end

-- Check if sliding is possible
function AdvancedMovementSystem:canSlide()
	if not self.isGrounded then return false end
	if self.currentState ~= MovementStates.STANDING and self.currentState ~= MovementStates.SPRINTING then return false end
	if tick() - self.lastSlideTime < MOVEMENT_SETTINGS.SLIDE_COOLDOWN then return false end
	
	-- Check if player is moving fast enough
	local velocity = self.rootPart.Velocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	
	return horizontalSpeed >= MOVEMENT_SETTINGS.SLIDE_MIN_SPEED
end

-- Start sliding
function AdvancedMovementSystem:startSlide()
	print("Starting slide")
	
	self.previousState = self.currentState
	self.currentState = MovementStates.SLIDING
	self.slideStartTime = tick()
	self.lastSlideTime = tick()
	
	-- Calculate slide direction and speed
	local velocity = self.rootPart.Velocity
	self.slideDirection = Vector3.new(velocity.X, 0, velocity.Z).Unit
	self.slideSpeed = MOVEMENT_SETTINGS.SLIDE_SPEED
	
	-- Create body velocity for sliding
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "SlideVelocity"
	bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	bodyVelocity.Velocity = self.slideDirection * self.slideSpeed
	bodyVelocity.Parent = self.rootPart
	
	-- Animate character to sliding pose
	self:animateToHeight(MOVEMENT_SETTINGS.CROUCH_HEIGHT)
end

-- End sliding
function AdvancedMovementSystem:endSlide()
	print("Ending slide")
	
	self.currentState = MovementStates.STANDING
	
	-- Remove slide body velocity
	local bodyVelocity = self.rootPart:FindFirstChild("SlideVelocity")
	if bodyVelocity then
		bodyVelocity:Destroy()
	end
	
	-- Animate back to standing
	self:animateToHeight(10) -- Default character height
end

-- Check if diving is possible
function AdvancedMovementSystem:canDive()
	if not self.isGrounded then return false end
	if self.currentState ~= MovementStates.STANDING and self.currentState ~= MovementStates.SPRINTING then return false end
	if tick() - self.lastDiveTime < MOVEMENT_SETTINGS.DIVE_COOLDOWN then return false end
	
	return true
end

-- Start diving
function AdvancedMovementSystem:startDive()
	print("Starting dive")
	
	self.previousState = self.currentState
	self.currentState = MovementStates.DIVING
	self.isDiving = true
	self.diveStartTime = tick()
	self.lastDiveTime = tick()
	
	-- Calculate dive direction (forward from camera)
	local camera = workspace.CurrentCamera
	local diveDirection = camera.CFrame.LookVector
	diveDirection = Vector3.new(diveDirection.X, 0, diveDirection.Z).Unit
	
	-- Create body velocity for diving
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "DiveVelocity"
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Velocity = diveDirection * MOVEMENT_SETTINGS.DIVE_FORCE + Vector3.new(0, MOVEMENT_SETTINGS.DIVE_UP_FORCE, 0)
	bodyVelocity.Parent = self.rootPart
	
	self.diveBodyVelocity = bodyVelocity
	
	-- Make player go prone after dive
	task.delay(MOVEMENT_SETTINGS.DIVE_RECOVERY_TIME, function()
		if self.currentState == MovementStates.DIVING then
			self:setProne(true)
		end
	end)
end

-- End diving
function AdvancedMovementSystem:endDive()
	print("Ending dive")
	
	self.isDiving = false
	
	-- Remove dive body velocity
	if self.diveBodyVelocity then
		self.diveBodyVelocity:Destroy()
		self.diveBodyVelocity = nil
	end
	
	-- Transition to prone if on ground, otherwise standing
	if self.isGrounded then
		self:setProne(true)
	else
		self.currentState = MovementStates.STANDING
	end
end

-- Toggle crouching
function AdvancedMovementSystem:toggleCrouch()
	if self.currentState == MovementStates.CROUCHING then
		self:setCrouching(false)
	else
		self:setCrouching(true)
	end
end

-- Set crouching state
function AdvancedMovementSystem:setCrouching(crouching)
	if crouching and self.currentState ~= MovementStates.CROUCHING then
		print("Crouching")
		self.previousState = self.currentState
		self.currentState = MovementStates.CROUCHING
		self:animateToHeight(MOVEMENT_SETTINGS.CROUCH_HEIGHT)
		
	elseif not crouching and self.currentState == MovementStates.CROUCHING then
		print("Standing up from crouch")
		self.currentState = MovementStates.STANDING
		self:animateToHeight(10)
	end
end

-- Toggle prone
function AdvancedMovementSystem:toggleProne()
	if self.currentState == MovementStates.PRONE then
		self:setProne(false)
	else
		self:setProne(true)
	end
end

-- Set prone state
function AdvancedMovementSystem:setProne(prone)
	if prone and self.currentState ~= MovementStates.PRONE then
		print("Going prone")
		self.previousState = self.currentState
		self.currentState = MovementStates.PRONE
		self:animateToHeight(MOVEMENT_SETTINGS.PRONE_HEIGHT)
		
	elseif not prone and self.currentState == MovementStates.PRONE then
		print("Standing up from prone")
		self.currentState = MovementStates.STANDING
		self:animateToHeight(10)
	end
end

-- Set sprinting state
function AdvancedMovementSystem:setSprinting(sprinting)
	if sprinting and (self.currentState == MovementStates.STANDING or self.currentState == MovementStates.SPRINTING) then
		if self.currentState ~= MovementStates.SPRINTING then
			print("Sprinting")
			self.previousState = self.currentState
			self.currentState = MovementStates.SPRINTING
		end
		
	elseif not sprinting and self.currentState == MovementStates.SPRINTING then
		print("Stop sprinting")
		self.currentState = MovementStates.STANDING
	end
end

-- Animate character height change
function AdvancedMovementSystem:animateToHeight(targetHeight)
	if not self.character then return end
	
	-- Find the character's parts that need resizing
	local humanoidRootPart = self.character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Calculate the height difference
	local currentHeight = 10 -- Default Roblox character height
	local heightDifference = targetHeight - currentHeight
	
	-- Move the character down/up
	local currentCFrame = humanoidRootPart.CFrame
	local targetCFrame = currentCFrame + Vector3.new(0, heightDifference/2, 0)
	
	-- Tween to the new position
	if self.currentTween then
		self.currentTween:Cancel()
	end
	
	local tweenInfo = TweenInfo.new(
		MOVEMENT_SETTINGS.STANCE_TRANSITION_TIME,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)
	
	self.currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {
		CFrame = targetCFrame
	})
	
	self.currentTween:Play()
end

-- Handle humanoid state changes
function AdvancedMovementSystem:handleStateChange(oldState, newState)
	-- Reset certain movement states when jumping or falling
	if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
		if self.currentState == MovementStates.SLIDING then
			self:endSlide()
		end
	end
end

-- Get current movement state (for other systems to query)
function AdvancedMovementSystem:getCurrentState()
	return self.currentState
end

-- Check if player is in a specific state
function AdvancedMovementSystem:isInState(state)
	return self.currentState == state
end

-- Get movement speed modifier for other systems
function AdvancedMovementSystem:getSpeedModifier()
	if self.currentState == MovementStates.CROUCHING then
		return 0.5
	elseif self.currentState == MovementStates.PRONE then
		return 0.2
	elseif self.currentState == MovementStates.SPRINTING then
		return 1.5
	else
		return 1.0
	end
end

-- Clean up
function AdvancedMovementSystem:destroy()
	if self.updateConnection then
		self.updateConnection:Disconnect()
	end
	
	if self.currentTween then
		self.currentTween:Cancel()
	end
	
	if self.diveBodyVelocity then
		self.diveBodyVelocity:Destroy()
	end
	
	local slideVelocity = self.rootPart and self.rootPart:FindFirstChild("SlideVelocity")
	if slideVelocity then
		slideVelocity:Destroy()
	end
	
	print("Advanced Movement System destroyed")
end

return AdvancedMovementSystem