-- FixedAdvancedMovementSystem.lua
-- Place in ReplicatedStorage/FPSSystem/Modules/AdvancedMovementSystem.lua

local AdvancedMovementSystem = {}
AdvancedMovementSystem.__index = AdvancedMovementSystem

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Movement Constants
local MOVEMENT_SETTINGS = {
    -- Walking and running
    WALK_SPEED = 16,
    SPRINT_SPEED = 24,
    ADS_WALK_SPEED = 10,

    -- Crouching
    CROUCH_SPEED = 8,
    CROUCH_HEIGHT_SCALE = 0.6,
    CROUCH_JUMP_POWER = 35,

    -- Prone
    PRONE_SPEED = 3,
    PRONE_HEIGHT_SCALE = 0.2,
    PRONE_JUMP_POWER = 0,

    -- Sliding
    SLIDE_SPEED = 32,
    SLIDE_DURATION = 1.2,
    SLIDE_FRICTION = 0.96, -- Higher = less friction
    SLIDE_MIN_SPEED = 20,
    SLIDE_COOLDOWN = 0.8,

    -- Diving (Fixed values)
    DIVE_FORWARD_FORCE = 35,  -- Reduced from 45
    DIVE_UP_FORCE = 8,        -- Reduced from 15
    DIVE_DURATION = 0.6,      -- Reduced from 0.8
    DIVE_RECOVERY_TIME = 0.8,
    DIVE_COOLDOWN = 2.0,

    -- Fall damage
    FALL_DAMAGE_ENABLED = true,
    SAFE_FALL_HEIGHT = 20,
    MAX_FALL_HEIGHT = 80,
    MAX_FALL_DAMAGE = 35,

    -- Physics
    GROUND_CHECK_DISTANCE = 5.5,
    SLOPE_ANGLE_MAX = 45
}

-- Movement States
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
    self.groundNormal = Vector3.new(0, 1, 0)
    self.lastGroundHeight = 0
    self.fallStartHeight = 0

    -- Input tracking
    self.keysPressed = {}
    self.lastSlideTime = 0
    self.lastDiveTime = 0

    -- Physics objects
    self.slideBodyVelocity = nil
    self.diveBodyVelocity = nil

    -- Slide state
    self.slideStartTime = 0
    self.slideDirection = Vector3.new()
    self.slideSpeed = 0

    -- Dive state
    self.diveStartTime = 0
    self.isDiving = false

    -- Character properties backup
    self.originalWalkSpeed = MOVEMENT_SETTINGS.WALK_SPEED
    self.originalJumpPower = 50
    self.originalHipHeight = 2

    -- Setup
    self:setupCharacterHandling()
    self:setupInputHandling()

    -- Export globally
    _G.AdvancedMovementSystem = self

    print("[Movement] System initialized")
    return self
end

-- Setup character handling
function AdvancedMovementSystem:setupCharacterHandling()
    if self.player.Character then
        self:setupCharacter(self.player.Character)
    end

    self.player.CharacterAdded:Connect(function(character)
        wait(0.1) -- Wait for character to load
        self:setupCharacter(character)
    end)
end

-- Setup character
function AdvancedMovementSystem:setupCharacter(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid")
    self.rootPart = character:WaitForChild("HumanoidRootPart")

    -- Store original values
    self.originalWalkSpeed = self.humanoid.WalkSpeed
    self.originalJumpPower = self.humanoid.JumpPower or self.humanoid.JumpHeight * 7.2
    self.originalHipHeight = self.humanoid.HipHeight

    -- Disable default climbing to prevent jiggling
    self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    self.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

    -- Start update loop
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end

    self.updateConnection = RunService.Heartbeat:Connect(function(dt)
        self:update(dt)
    end)

    print("[Movement] Character setup complete")
end

-- Setup input handling
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

        -- X key - Prone (check for dive combo)
    elseif keyCode == Enum.KeyCode.X then
        -- Space must be held FIRST, then X for dive
        if self.keysPressed[Enum.KeyCode.Space] and self:canDive() then
            self:startDive()
        else
            -- Regular prone
            self:toggleProne()
        end

        -- Space key - Jump (or start dive combo)
    elseif keyCode == Enum.KeyCode.Space then
        -- Check if X is pressed after space for dive
        task.wait(0.1) -- Small window for combo
        if self.keysPressed[Enum.KeyCode.X] and self:canDive() then
            self:startDive()
        end

        -- Left Shift - Sprint
    elseif keyCode == Enum.KeyCode.LeftShift then
        self:setSprinting(true)
    end
end

-- Handle input ended
function AdvancedMovementSystem:handleInputEnded(input)
    local keyCode = input.KeyCode
    self.keysPressed[keyCode] = false

    if keyCode == Enum.KeyCode.LeftShift then
        self:setSprinting(false)
    end
end

-- Toggle crouch
function AdvancedMovementSystem:toggleCrouch()
    if self.currentState == MovementStates.CROUCHING then
        self:setState(MovementStates.STANDING)
    else
        self:setState(MovementStates.CROUCHING)
    end
end

-- Toggle prone
function AdvancedMovementSystem:toggleProne()
    if self.currentState == MovementStates.PRONE then
        self:setState(MovementStates.STANDING)
    else
        self:setState(MovementStates.PRONE)
    end
end

-- Set sprinting
function AdvancedMovementSystem:setSprinting(sprinting)
    if sprinting and self.currentState == MovementStates.STANDING then
        self:setState(MovementStates.SPRINTING)
    elseif not sprinting and self.currentState == MovementStates.SPRINTING then
        self:setState(MovementStates.STANDING)
    end
end

-- Check if can slide
function AdvancedMovementSystem:canSlide()
    if not self.isGrounded then return false end
    if self.currentState ~= MovementStates.STANDING and self.currentState ~= MovementStates.SPRINTING then
        return false
    end
    if tick() - self.lastSlideTime < MOVEMENT_SETTINGS.SLIDE_COOLDOWN then
        return false
    end

    -- Check movement speed
    local velocity = self.rootPart.AssemblyLinearVelocity
    local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

    return horizontalSpeed >= MOVEMENT_SETTINGS.SLIDE_MIN_SPEED
end

-- Start sliding
function AdvancedMovementSystem:startSlide()
    print("[Movement] Starting slide")

    self.previousState = self.currentState
    self.currentState = MovementStates.SLIDING
    self.slideStartTime = tick()
    self.lastSlideTime = tick()

    -- Get slide direction from current velocity
    local velocity = self.rootPart.AssemblyLinearVelocity
    self.slideDirection = Vector3.new(velocity.X, 0, velocity.Z).Unit
    self.slideSpeed = MOVEMENT_SETTINGS.SLIDE_SPEED

    -- Create slide BodyVelocity
    if self.slideBodyVelocity then
        self.slideBodyVelocity:Destroy()
    end

    self.slideBodyVelocity = Instance.new("BodyVelocity")
    self.slideBodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
    self.slideBodyVelocity.Velocity = self.slideDirection * self.slideSpeed
    self.slideBodyVelocity.Parent = self.rootPart

    -- Reduce character height
    self.humanoid.HipHeight = self.originalHipHeight * 0.4
    self.humanoid.WalkSpeed = 0
    self.humanoid.JumpPower = 0
end

-- End sliding
function AdvancedMovementSystem:endSlide()
    print("[Movement] Ending slide")

    -- Clean up BodyVelocity
    if self.slideBodyVelocity then
        self.slideBodyVelocity:Destroy()
        self.slideBodyVelocity = nil
    end

    -- Restore character
    self:setState(MovementStates.STANDING)
end

-- Check if can dive
function AdvancedMovementSystem:canDive()
    if not self.isGrounded then return false end
    if self.currentState == MovementStates.PRONE or 
        self.currentState == MovementStates.SLIDING or 
        self.currentState == MovementStates.DIVING then
        return false
    end
    if tick() - self.lastDiveTime < MOVEMENT_SETTINGS.DIVE_COOLDOWN then
        return false
    end

    return true
end

-- Start dive (FIXED)
function AdvancedMovementSystem:startDive()
    print("[Movement] Starting dive")

    self.previousState = self.currentState
    self.currentState = MovementStates.DIVING
    self.isDiving = true
    self.diveStartTime = tick()
    self.lastDiveTime = tick()

    -- Calculate dive direction (forward from camera)
    local lookDirection = self.camera.CFrame.LookVector
    local diveDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit

    -- Clean up any existing dive velocity
    if self.diveBodyVelocity then
        self.diveBodyVelocity:Destroy()
    end

    -- Create controlled dive force
    self.diveBodyVelocity = Instance.new("BodyVelocity")
    self.diveBodyVelocity.MaxForce = Vector3.new(3000, 2000, 3000) -- Reduced force
    self.diveBodyVelocity.Velocity = 
        diveDirection * MOVEMENT_SETTINGS.DIVE_FORWARD_FORCE + 
        Vector3.new(0, MOVEMENT_SETTINGS.DIVE_UP_FORCE, 0)
    self.diveBodyVelocity.Parent = self.rootPart

    -- Disable normal movement
    self.humanoid.WalkSpeed = 0
    self.humanoid.JumpPower = 0

    -- Gradually reduce dive force over time
    spawn(function()
        local startTime = tick()
        while self.isDiving and self.diveBodyVelocity do
            local elapsed = tick() - startTime
            local progress = elapsed / MOVEMENT_SETTINGS.DIVE_DURATION

            if progress >= 1 then
                break
            end

            -- Reduce velocity over time
            local falloff = 1 - (progress * 0.7) -- Retain 30% velocity at end
            self.diveBodyVelocity.Velocity = 
                diveDirection * (MOVEMENT_SETTINGS.DIVE_FORWARD_FORCE * falloff) + 
                Vector3.new(0, -10 * progress, 0) -- Add downward force

            wait(0.05)
        end

        -- End dive
        if self.currentState == MovementStates.DIVING then
            self:endDive()
        end
    end)
end

-- End dive
function AdvancedMovementSystem:endDive()
    print("[Movement] Ending dive")

    self.isDiving = false

    -- Clean up BodyVelocity
    if self.diveBodyVelocity then
        self.diveBodyVelocity:Destroy()
        self.diveBodyVelocity = nil
    end

    -- Go prone after dive if grounded
    if self.isGrounded then
        self:setState(MovementStates.PRONE)
    else
        self:setState(MovementStates.STANDING)
    end
end

-- Set movement state
function AdvancedMovementSystem:setState(newState)
    if self.currentState == newState then return end

    print("[Movement] State:", self.currentState, "->", newState)

    self.previousState = self.currentState
    self.currentState = newState

    -- Clean up any active physics objects
    if self.slideBodyVelocity and newState ~= MovementStates.SLIDING then
        self.slideBodyVelocity:Destroy()
        self.slideBodyVelocity = nil
    end

    if self.diveBodyVelocity and newState ~= MovementStates.DIVING then
        self.diveBodyVelocity:Destroy()
        self.diveBodyVelocity = nil
    end

    -- Apply state properties with smooth transitions
    local targetSpeed, targetJump, targetHeight

    if newState == MovementStates.STANDING then
        targetSpeed = MOVEMENT_SETTINGS.WALK_SPEED
        targetJump = self.originalJumpPower
        targetHeight = self.originalHipHeight

    elseif newState == MovementStates.CROUCHING then
        targetSpeed = MOVEMENT_SETTINGS.CROUCH_SPEED
        targetJump = MOVEMENT_SETTINGS.CROUCH_JUMP_POWER
        targetHeight = self.originalHipHeight * MOVEMENT_SETTINGS.CROUCH_HEIGHT_SCALE

    elseif newState == MovementStates.PRONE then
        targetSpeed = MOVEMENT_SETTINGS.PRONE_SPEED
        targetJump = MOVEMENT_SETTINGS.PRONE_JUMP_POWER
        targetHeight = self.originalHipHeight * MOVEMENT_SETTINGS.PRONE_HEIGHT_SCALE

    elseif newState == MovementStates.SPRINTING then
        targetSpeed = MOVEMENT_SETTINGS.SPRINT_SPEED
        targetJump = self.originalJumpPower
        targetHeight = self.originalHipHeight

    elseif newState == MovementStates.SLIDING then
        -- Handled in startSlide
        return

    elseif newState == MovementStates.DIVING then
        -- Handled in startDive
        return
    end

    -- Apply changes smoothly
    self.humanoid.WalkSpeed = targetSpeed
    self.humanoid.JumpPower = targetJump

    -- Smooth height transition to prevent jiggling
    TweenService:Create(
        self.humanoid,
        TweenInfo.new(0.15, Enum.EasingStyle.Linear),
        {HipHeight = targetHeight}
    ):Play()
end

-- Main update
function AdvancedMovementSystem:update(dt)
    if not self.character or not self.humanoid or not self.rootPart then return end

    -- Update ground detection
    self:updateGroundDetection()

    -- Update sliding
    if self.currentState == MovementStates.SLIDING then
        self:updateSliding(dt)
    end

    -- Update fall damage
    self:updateFallDamage()
end

-- Update ground detection
function AdvancedMovementSystem:updateGroundDetection()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {self.character}

    local rayResult = workspace:Raycast(
        self.rootPart.Position,
        Vector3.new(0, -MOVEMENT_SETTINGS.GROUND_CHECK_DISTANCE, 0),
        raycastParams
    )

    local wasGrounded = self.isGrounded
    self.isGrounded = rayResult ~= nil

    if rayResult then
        self.groundNormal = rayResult.Normal
        self.lastGroundHeight = rayResult.Position.Y
    end

    -- Track fall start
    if wasGrounded and not self.isGrounded then
        self.fallStartHeight = self.rootPart.Position.Y
    end

    -- Landing from dive
    if not wasGrounded and self.isGrounded and self.isDiving then
        self:endDive()
    end
end

-- Update sliding
function AdvancedMovementSystem:updateSliding(dt)
    local slideTime = tick() - self.slideStartTime

    -- End slide conditions
    if slideTime >= MOVEMENT_SETTINGS.SLIDE_DURATION or not self.isGrounded then
        self:endSlide()
        return
    end

    -- Apply friction
    self.slideSpeed = self.slideSpeed * MOVEMENT_SETTINGS.SLIDE_FRICTION

    -- End if too slow
    if self.slideSpeed < 8 then
        self:endSlide()
        return
    end

    -- Update velocity
    if self.slideBodyVelocity then
        self.slideBodyVelocity.Velocity = self.slideDirection * self.slideSpeed
    end
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
            print("[Movement] Fall damage:", math.floor(damage))
        end
    end

    self.fallStartHeight = 0
end

-- Get current state
function AdvancedMovementSystem:getCurrentState()
    return self.currentState
end

-- Get speed modifier for other systems
function AdvancedMovementSystem:getSpeedModifier()
    local modifiers = {
        [MovementStates.STANDING] = 1.0,
        [MovementStates.CROUCHING] = 0.5,
        [MovementStates.PRONE] = 0.2,
        [MovementStates.SLIDING] = 0,
        [MovementStates.DIVING] = 0,
        [MovementStates.SPRINTING] = 1.5
    }

    return modifiers[self.currentState] or 1.0
end

-- Cleanup
function AdvancedMovementSystem:destroy()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end

    if self.slideBodyVelocity then
        self.slideBodyVelocity:Destroy()
    end

    if self.diveBodyVelocity then
        self.diveBodyVelocity:Destroy()
    end

    print("[Movement] System destroyed")
end

return AdvancedMovementSystem