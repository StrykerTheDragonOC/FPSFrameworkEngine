-- AdvancedMovementSystem.lua
-- Enhanced movement system with diving, sliding, and advanced mechanics
-- Place in ReplicatedStorage/FPSSystem/Modules

local AdvancedMovementSystem = {}
AdvancedMovementSystem.__index = AdvancedMovementSystem

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Movement configuration
local MOVEMENT_CONFIG = {
    -- Sprint settings
    SPRINT_SPEED = 22,
    WALK_SPEED = 16,
    CROUCH_SPEED = 8,
    PRONE_SPEED = 4,

    -- Diving settings
    DIVE_FORCE = 50,
    DIVE_UPWARD_FORCE = 10,
    DIVE_DURATION = 0.8,
    DIVE_COOLDOWN = 2.0,
    MIN_DIVE_SPEED = 10, -- Minimum speed required to dive

    -- Sliding settings
    SLIDE_FORCE = 30,
    SLIDE_DURATION = 1.2,
    SLIDE_DECELERATION = 0.85,
    MIN_SLIDE_SPEED = 15,

    -- Stance settings
    CROUCH_HEIGHT = 0.5,
    PRONE_HEIGHT = 0.25,
    STANCE_TRANSITION_TIME = 0.3,

    -- Leaning settings
    LEAN_ANGLE = 15, -- degrees
    LEAN_SPEED = 0.2,

    -- Stamina settings
    MAX_STAMINA = 100,
    SPRINT_STAMINA_DRAIN = 20, -- per second
    DIVE_STAMINA_COST = 30,
    STAMINA_REGEN_RATE = 25 -- per second when not sprinting
}

-- Movement states
local MovementState = {
    WALKING = "WALKING",
    SPRINTING = "SPRINTING", 
    CROUCHING = "CROUCHING",
    PRONE = "PRONE",
    SLIDING = "SLIDING",
    DIVING = "DIVING"
}

function AdvancedMovementSystem.new()
    local self = setmetatable({}, AdvancedMovementSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
    self.camera = workspace.CurrentCamera

    -- Movement state
    self.currentState = MovementState.WALKING
    self.isSprinting = false
    self.isCrouching = false
    self.isProne = false
    self.isSliding = false
    self.isDiving = false

    -- Diving state
    self.lastDiveTime = 0
    self.diveBodyVelocity = nil
    self.diveConnection = nil

    -- Sliding state
    self.slideBodyVelocity = nil
    self.slideConnection = nil

    -- Leaning state
    self.leanDirection = 0 -- -1 for left, 1 for right, 0 for center
    self.currentLeanAngle = 0

    -- Stamina system
    self.stamina = MOVEMENT_CONFIG.MAX_STAMINA
    self.staminaConnection = nil

    -- Stance system
    self.originalHipHeight = nil
    self.stanceConnections = {}

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the movement system
function AdvancedMovementSystem:initialize()
    print("[AdvancedMovement] Initializing Advanced Movement System...")

    -- Wait for character
    self:waitForCharacter()

    -- Setup stamina system
    self:setupStaminaSystem()

    print("[AdvancedMovement] Advanced Movement System initialized")
end

-- Wait for character spawn
function AdvancedMovementSystem:waitForCharacter()
    if self.player.Character then
        self:onCharacterSpawned(self.player.Character)
    end

    self.player.CharacterAdded:Connect(function(character)
        self:onCharacterSpawned(character)
    end)
end

-- Handle character spawning
function AdvancedMovementSystem:onCharacterSpawned(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid")
    self.rootPart = character:WaitForChild("HumanoidRootPart")

    -- Store original hip height for stance changes
    self.originalHipHeight = self.humanoid.HipHeight

    -- Reset movement state
    self:resetMovementState()

    print("[AdvancedMovement] Character spawned, movement system ready")
end

-- Reset movement state on spawn
function AdvancedMovementSystem:resetMovementState()
    self.currentState = MovementState.WALKING
    self.isSprinting = false
    self.isCrouching = false
    self.isProne = false
    self.isSliding = false
    self.isDiving = false
    self.leanDirection = 0
    self.currentLeanAngle = 0
    self.stamina = MOVEMENT_CONFIG.MAX_STAMINA

    -- Reset humanoid properties
    if self.humanoid then
        self.humanoid.WalkSpeed = MOVEMENT_CONFIG.WALK_SPEED
        self.humanoid.HipHeight = self.originalHipHeight
    end

    -- Clean up any active movement effects
    self:stopDiving()
    self:stopSliding()
end

-- Setup stamina system
function AdvancedMovementSystem:setupStaminaSystem()
    self.staminaConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:updateStamina(deltaTime)
    end)
end

-- Update stamina based on current actions
function AdvancedMovementSystem:updateStamina(deltaTime)
    if self.isSprinting and self.stamina > 0 then
        -- Drain stamina while sprinting
        self.stamina = math.max(0, self.stamina - (MOVEMENT_CONFIG.SPRINT_STAMINA_DRAIN * deltaTime))

        -- Stop sprinting if stamina is depleted
        if self.stamina <= 0 then
            self:setSprinting(false)
        end
    elseif not self.isSprinting and self.stamina < MOVEMENT_CONFIG.MAX_STAMINA then
        -- Regenerate stamina when not sprinting
        self.stamina = math.min(MOVEMENT_CONFIG.MAX_STAMINA, 
            self.stamina + (MOVEMENT_CONFIG.STAMINA_REGEN_RATE * deltaTime))
    end
end

-- Set sprinting state
function AdvancedMovementSystem:setSprinting(sprinting)
    if not self.humanoid then return end

    -- Can't sprint while crouching, prone, sliding, or diving
    if sprinting and (self.isCrouching or self.isProne or self.isSliding or self.isDiving) then
        return
    end

    -- Can't sprint without stamina
    if sprinting and self.stamina <= 0 then
        return
    end

    self.isSprinting = sprinting

    if sprinting then
        self.currentState = MovementState.SPRINTING
        self.humanoid.WalkSpeed = MOVEMENT_CONFIG.SPRINT_SPEED
        print("[AdvancedMovement] Started sprinting")
    else
        self.currentState = MovementState.WALKING
        self.humanoid.WalkSpeed = MOVEMENT_CONFIG.WALK_SPEED
        print("[AdvancedMovement] Stopped sprinting")
    end
end

-- Toggle crouch state
function AdvancedMovementSystem:toggleCrouch()
    if not self.humanoid then return end

    if self.isProne then
        -- Exit prone first
        self:toggleProne()
        return
    end

    if self.isSliding or self.isDiving then
        return -- Can't crouch while sliding or diving
    end

    self.isCrouching = not self.isCrouching

    if self.isCrouching then
        -- Enter crouch
        self.currentState = MovementState.CROUCHING
        self:setSprinting(false) -- Stop sprinting
        self:transitionToStance(MOVEMENT_CONFIG.CROUCH_HEIGHT, MOVEMENT_CONFIG.CROUCH_SPEED)
        print("[AdvancedMovement] Entered crouch")
    else
        -- Exit crouch
        self.currentState = MovementState.WALKING
        self:transitionToStance(self.originalHipHeight, MOVEMENT_CONFIG.WALK_SPEED)
        print("[AdvancedMovement] Exited crouch")
    end
end

-- Toggle prone state
function AdvancedMovementSystem:toggleProne()
    if not self.humanoid then return end

    if self.isSliding or self.isDiving then
        return -- Can't go prone while sliding or diving
    end

    self.isProne = not self.isProne

    if self.isProne then
        -- Enter prone
        self.currentState = MovementState.PRONE
        self.isCrouching = false -- Exit crouch if crouching
        self:setSprinting(false) -- Stop sprinting
        self:transitionToStance(MOVEMENT_CONFIG.PRONE_HEIGHT, MOVEMENT_CONFIG.PRONE_SPEED)
        print("[AdvancedMovement] Entered prone")
    else
        -- Exit prone
        self.currentState = MovementState.WALKING
        self:transitionToStance(self.originalHipHeight, MOVEMENT_CONFIG.WALK_SPEED)
        print("[AdvancedMovement] Exited prone")
    end
end

-- Transition to different stance with smooth animation
function AdvancedMovementSystem:transitionToStance(targetHipHeight, targetWalkSpeed)
    if not self.humanoid then return end

    -- Immediately set walk speed
    self.humanoid.WalkSpeed = targetWalkSpeed

    -- Smoothly transition hip height
    local currentHipHeight = self.humanoid.HipHeight
    local tween = TweenService:Create(
        self.humanoid,
        TweenInfo.new(MOVEMENT_CONFIG.STANCE_TRANSITION_TIME, Enum.EasingStyle.Quad),
        {HipHeight = targetHipHeight}
    )
    tween:Play()
end

-- REQUESTED: Dive ability while airborne after jumping while running
function AdvancedMovementSystem:dive()
    if not self.rootPart or not self.humanoid then return end

    -- Check cooldown
    if tick() - self.lastDiveTime < MOVEMENT_CONFIG.DIVE_COOLDOWN then
        print("[AdvancedMovement] Dive on cooldown")
        return
    end

    -- Check stamina
    if self.stamina < MOVEMENT_CONFIG.DIVE_STAMINA_COST then
        print("[AdvancedMovement] Not enough stamina to dive")
        return
    end

    -- Check if already diving or sliding
    if self.isDiving or self.isSliding then
        return
    end

    -- Check if airborne (jumping, falling, or freefall)
    local humanoidState = self.humanoid:GetState()
    local isAirborne = humanoidState == Enum.HumanoidStateType.Freefall or 
        humanoidState == Enum.HumanoidStateType.Flying or
        humanoidState == Enum.HumanoidStateType.Jumping

    if not isAirborne then
        print("[AdvancedMovement] Must be airborne to dive")
        return
    end

    -- Check horizontal speed
    local velocity = self.rootPart.Velocity
    local horizontalSpeed = math.sqrt(velocity.X^2 + velocity.Z^2)

    if horizontalSpeed < MOVEMENT_CONFIG.MIN_DIVE_SPEED then
        print("[AdvancedMovement] Not moving fast enough to dive")
        return
    end

    -- Consume stamina
    self.stamina = math.max(0, self.stamina - MOVEMENT_CONFIG.DIVE_STAMINA_COST)

    -- Start dive
    self.isDiving = true
    self.currentState = MovementState.DIVING
    self.lastDiveTime = tick()

    -- Calculate dive direction (forward and slightly down)
    local camera = self.camera
    local diveDirection = camera.CFrame.LookVector
    diveDirection = Vector3.new(diveDirection.X, -0.3, diveDirection.Z).Unit -- Add downward component

    -- Apply dive force
    self:applyDiveForce(diveDirection)

    -- Transition to prone-like stance during dive
    self:transitionToStance(MOVEMENT_CONFIG.PRONE_HEIGHT, 0) -- No walking during dive

    -- Set dive duration
    task.delay(MOVEMENT_CONFIG.DIVE_DURATION, function()
        self:stopDiving()
    end)

    print("[AdvancedMovement] Dive initiated while airborne!")
end

-- Apply dive force to character
function AdvancedMovementSystem:applyDiveForce(direction)
    if not self.rootPart then return end

    -- Create BodyVelocity for dive
    self.diveBodyVelocity = Instance.new("BodyVelocity")
    self.diveBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)

    -- Calculate dive velocity
    local diveVelocity = direction * MOVEMENT_CONFIG.DIVE_FORCE
    diveVelocity = diveVelocity + Vector3.new(0, MOVEMENT_CONFIG.DIVE_UPWARD_FORCE, 0) -- Add slight upward force

    self.diveBodyVelocity.Velocity = diveVelocity
    self.diveBodyVelocity.Parent = self.rootPart

    -- Gradually reduce dive force
    self.diveConnection = RunService.Heartbeat:Connect(function()
        if self.diveBodyVelocity then
            local currentVelocity = self.diveBodyVelocity.Velocity
            local reducedVelocity = currentVelocity * 0.95 -- Gradually slow down
            self.diveBodyVelocity.Velocity = reducedVelocity
        end
    end)
end

-- Stop diving
function AdvancedMovementSystem:stopDiving()
    if not self.isDiving then return end

    self.isDiving = false

    -- Clean up dive BodyVelocity
    if self.diveBodyVelocity then
        self.diveBodyVelocity:Destroy()
        self.diveBodyVelocity = nil
    end

    -- Disconnect dive connection
    if self.diveConnection then
        self.diveConnection:Disconnect()
        self.diveConnection = nil
    end

    -- Return to walking stance after dive
    if not self.isCrouching and not self.isProne then
        self.currentState = MovementState.WALKING
        self:transitionToStance(self.originalHipHeight, MOVEMENT_CONFIG.WALK_SPEED)
    end

    print("[AdvancedMovement] Dive ended")
end

-- Start sliding (when crouching while sprinting)
function AdvancedMovementSystem:startSlide()
    if not self.rootPart or not self.humanoid then return end

    if self.isDiving or self.isSliding then return end

    -- Check if moving fast enough to slide
    local velocity = self.rootPart.Velocity
    local horizontalSpeed = math.sqrt(velocity.X^2 + velocity.Z^2)

    if horizontalSpeed < MOVEMENT_CONFIG.MIN_SLIDE_SPEED then
        return -- Not moving fast enough to slide
    end

    self.isSliding = true
    self.currentState = MovementState.SLIDING
    self.isCrouching = true -- Slide in crouch position

    -- Apply slide force
    local slideDirection = self.rootPart.CFrame.LookVector
    self:applySlideForce(slideDirection, horizontalSpeed)

    -- Transition to crouch stance
    self:transitionToStance(MOVEMENT_CONFIG.CROUCH_HEIGHT, 0) -- No walking during slide

    -- End slide after duration
    task.delay(MOVEMENT_CONFIG.SLIDE_DURATION, function()
        self:stopSliding()
    end)

    print("[AdvancedMovement] Started sliding")
end

-- Apply slide force
function AdvancedMovementSystem:applySlideForce(direction, initialSpeed)
    if not self.rootPart then return end

    -- Create BodyVelocity for slide
    self.slideBodyVelocity = Instance.new("BodyVelocity")
    self.slideBodyVelocity.MaxForce = Vector3.new(4000, 0, 4000) -- No Y force

    local slideVelocity = direction * math.min(initialSpeed, MOVEMENT_CONFIG.SLIDE_FORCE)
    self.slideBodyVelocity.Velocity = slideVelocity
    self.slideBodyVelocity.Parent = self.rootPart

    -- Gradually decelerate slide
    self.slideConnection = RunService.Heartbeat:Connect(function()
        if self.slideBodyVelocity then
            local currentVelocity = self.slideBodyVelocity.Velocity
            local deceleratedVelocity = currentVelocity * MOVEMENT_CONFIG.SLIDE_DECELERATION
            self.slideBodyVelocity.Velocity = deceleratedVelocity

            -- Stop sliding if too slow
            local speed = deceleratedVelocity.Magnitude
            if speed < 5 then
                self:stopSliding()
            end
        end
    end)
end

-- Stop sliding
function AdvancedMovementSystem:stopSliding()
    if not self.isSliding then return end

    self.isSliding = false

    -- Clean up slide BodyVelocity
    if self.slideBodyVelocity then
        self.slideBodyVelocity:Destroy()
        self.slideBodyVelocity = nil
    end

    -- Disconnect slide connection
    if self.slideConnection then
        self.slideConnection:Disconnect()
        self.slideConnection = nil
    end

    -- Return to crouching state
    self.currentState = MovementState.CROUCHING
    self.humanoid.WalkSpeed = MOVEMENT_CONFIG.CROUCH_SPEED

    print("[AdvancedMovement] Slide ended")
end

-- Lean left
function AdvancedMovementSystem:leanLeft(leaning)
    if leaning then
        self.leanDirection = -1
        self:applyLean()
    else
        self:stopLeaning()
    end
end

-- Lean right
function AdvancedMovementSystem:leanRight(leaning)
    if leaning then
        self.leanDirection = 1
        self:applyLean()
    else
        self:stopLeaning()
    end
end

-- Apply leaning effect
function AdvancedMovementSystem:applyLean()
    if not self.rootPart then return end

    local targetAngle = self.leanDirection * MOVEMENT_CONFIG.LEAN_ANGLE

    -- Smooth lean transition
    local tween = TweenService:Create(
        self.rootPart,
        TweenInfo.new(MOVEMENT_CONFIG.LEAN_SPEED),
        {CFrame = self.rootPart.CFrame * CFrame.Angles(0, 0, math.rad(targetAngle - self.currentLeanAngle))}
    )
    tween:Play()

    self.currentLeanAngle = targetAngle
end

-- Stop leaning
function AdvancedMovementSystem:stopLeaning()
    if not self.rootPart or self.currentLeanAngle == 0 then return end

    -- Return to upright position
    local tween = TweenService:Create(
        self.rootPart,
        TweenInfo.new(MOVEMENT_CONFIG.LEAN_SPEED),
        {CFrame = self.rootPart.CFrame * CFrame.Angles(0, 0, math.rad(-self.currentLeanAngle))}
    )
    tween:Play()

    self.currentLeanAngle = 0
    self.leanDirection = 0
end

-- Get current movement state
function AdvancedMovementSystem:getMovementState()
    return self.currentState
end

-- Get stamina percentage
function AdvancedMovementSystem:getStaminaPercent()
    return self.stamina / MOVEMENT_CONFIG.MAX_STAMINA
end

-- Check if can perform action based on stamina
function AdvancedMovementSystem:canPerformAction(staminaCost)
    return self.stamina >= staminaCost
end

-- Cleanup
function AdvancedMovementSystem:cleanup()
    print("[AdvancedMovement] Cleaning up Advanced Movement System...")

    -- Stop all movement actions
    self:stopDiving()
    self:stopSliding()
    self:stopLeaning()

    -- Disconnect stamina connection
    if self.staminaConnection then
        self.staminaConnection:Disconnect()
        self.staminaConnection = nil
    end

    -- Disconnect stance connections
    for _, connection in pairs(self.stanceConnections) do
        connection:Disconnect()
    end

    -- Clear references
    self.stanceConnections = {}
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil

    print("[AdvancedMovement] Advanced Movement System cleanup complete")
end

return AdvancedMovementSystem