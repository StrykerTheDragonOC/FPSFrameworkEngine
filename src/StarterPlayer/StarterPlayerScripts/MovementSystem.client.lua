local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local MovementSystem = {}

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local rootPart = nil

local isSliding = false
local isProne = false
local isCrouching = false
local isDolphinDiving = false
local isLedgeGrabbing = false

local originalWalkSpeed = 16
local originalJumpPower = 50
local originalCFrame = nil

-- Movement parameters
local SLIDE_SPEED = 24
local PRONE_SPEED = 4
local CROUCH_SPEED = 8
local SLIDE_DURATION = 1.5
local SLIDE_COOLDOWN = 2.0
local DOLPHIN_DIVE_FORCE = 50
local DOLPHIN_DIVE_UPWARD_FORCE = 20
local LEDGE_GRAB_RANGE = 8
local LEDGE_GRAB_HEIGHT = 6
local LEDGE_GRAB_FORWARD_RANGE = 4
local CLIMBING_SPEED = 12

-- State tracking
local slidingConnection = nil
local movementConnections = {}
local lastSlideTime = 0
local dolphinDiveConnection = nil
local ledgeGrabConnection = nil
local isClimbing = false

-- Physics components
local slideForce = nil
local bodyVelocity = nil

function MovementSystem:Initialize()
	RemoteEventsManager:Initialize()
	
	player.CharacterAdded:Connect(function(newCharacter)
		self:SetupCharacter(newCharacter)
	end)
	
	if player.Character then
		self:SetupCharacter(player.Character)
	end
	
	self:SetupInputHandling()
	self:SetupLedgeGrabDetection()
	self:SetupPhysicsComponents()
	
	print("MovementSystem initialized")
end

function MovementSystem:SetupCharacter(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	
	originalWalkSpeed = humanoid.WalkSpeed
	originalJumpPower = humanoid.JumpPower
	
	self:ResetMovementState()
	
	humanoid.StateChanged:Connect(function(oldState, newState)
		self:HandleStateChange(oldState, newState)
	end)
end

function MovementSystem:SetupInputHandling()
	local cKeyHoldTime = 0
	local cKeyPressed = false
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.C then
			cKeyPressed = true
			cKeyHoldTime = tick()
			
			-- Wait to determine if it's a tap or hold
			spawn(function()
				wait(0.2) -- Hold threshold
				if cKeyPressed then
					self:StartSlide()
				end
			end)
			
		elseif input.KeyCode == Enum.KeyCode.Z then
			self:ToggleProne()
		elseif input.KeyCode == Enum.KeyCode.X and humanoid.FloorMaterial == Enum.Material.Air then
			self:DolphinDive()
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.C then
			local holdDuration = tick() - cKeyHoldTime
			cKeyPressed = false
			
			if holdDuration < 0.2 then
				-- Quick tap - toggle crouch
				self:ToggleCrouch()
			else
				-- Was holding - stop slide
				self:StopSlide()
			end
		end
	end)
end

function MovementSystem:ToggleCrouch()
	if isSliding or isProne then return end
	
	if not isCrouching then
		self:StartCrouch()
	else
		self:StopCrouch()
	end
end

function MovementSystem:StartCrouch()
	if not character or not humanoid then return end
	
	isCrouching = true
	humanoid.WalkSpeed = CROUCH_SPEED
	
	-- Store original CFrame for restoration
	if not originalCFrame then
		originalCFrame = rootPart.CFrame
	end
	
	-- Animate to crouch position using CFrame
	local targetCFrame = originalCFrame - Vector3.new(0, 1.5, 0)
	local tween = TweenService:Create(rootPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		CFrame = targetCFrame
	})
	tween:Play()
	
	print("Started crouching")
end

function MovementSystem:StopCrouch()
	if not character or not humanoid then return end
	
	isCrouching = false
	humanoid.WalkSpeed = originalWalkSpeed
	
	-- Restore to original height
	if originalCFrame then
		local targetCFrame = CFrame.new(rootPart.Position + Vector3.new(0, 1.5, 0), originalCFrame.LookVector)
		local tween = TweenService:Create(rootPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			CFrame = targetCFrame
		})
		tween:Play()
	end
	
	print("Stopped crouching")
end

function MovementSystem:StartSlide()
	if not character or not humanoid or isSliding or isProne then return end
	
	if humanoid.MoveDirection.Magnitude < 0.1 then return end
	
	isSliding = true
	humanoid.WalkSpeed = SLIDE_SPEED
	humanoid.JumpPower = 0
	
	local slideDirection = humanoid.MoveDirection
	local slideVelocity = Instance.new("BodyVelocity")
	slideVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	slideVelocity.Velocity = slideDirection * SLIDE_SPEED
	slideVelocity.Parent = rootPart
	slideVelocity.Name = "SlideVelocity"
	
	local slidePosition = Instance.new("BodyPosition")
	slidePosition.MaxForce = Vector3.new(0, math.huge, 0)
	slidePosition.Position = rootPart.Position - Vector3.new(0, 2, 0)
	slidePosition.Parent = rootPart
	slidePosition.Name = "SlidePosition"
	
	slidingConnection = RunService.Heartbeat:Connect(function()
		if slideVelocity.Parent then
			slideVelocity.Velocity = slideVelocity.Velocity * 0.95
			
			if slideVelocity.Velocity.Magnitude < 5 then
				self:StopSlide()
			end
		end
	end)
	
	spawn(function()
		wait(SLIDE_DURATION)
		if isSliding then
			self:StopSlide()
		end
	end)
	
	print("Started sliding")
end

function MovementSystem:StopSlide()
	if not isSliding then return end
	
	isSliding = false
	humanoid.WalkSpeed = originalWalkSpeed
	humanoid.JumpPower = originalJumpPower
	
	local slideVelocity = rootPart:FindFirstChild("SlideVelocity")
	if slideVelocity then
		slideVelocity:Destroy()
	end
	
	local slidePosition = rootPart:FindFirstChild("SlidePosition")
	if slidePosition then
		slidePosition:Destroy()
	end
	
	if slidingConnection then
		slidingConnection:Disconnect()
		slidingConnection = nil
	end
	
	print("Stopped sliding")
end

function MovementSystem:ToggleProne()
	if isSliding then return end
	
	if not isProne then
		self:StartProne()
	else
		self:StopProne()
	end
end

function MovementSystem:StartProne()
	if not character or not humanoid then return end
	
	isProne = true
	isCrouching = false
	humanoid.WalkSpeed = PRONE_SPEED
	humanoid.JumpPower = 0
	
	-- Store original CFrame for restoration
	if not originalCFrame then
		originalCFrame = rootPart.CFrame
	end
	
	-- Animate to prone position using CFrame (rotated 90 degrees forward)
	local targetCFrame = CFrame.new(
		rootPart.Position - Vector3.new(0, 3, 0),
		rootPart.Position - Vector3.new(0, 3, 0) + rootPart.CFrame.LookVector
	) * CFrame.Angles(math.rad(90), 0, 0)
	
	local tween = TweenService:Create(rootPart, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		CFrame = targetCFrame
	})
	tween:Play()
	
	print("Started prone")
end

function MovementSystem:StopProne()
	if not character or not humanoid then return end
	
	isProne = false
	humanoid.WalkSpeed = originalWalkSpeed
	humanoid.JumpPower = originalJumpPower
	
	-- Restore to original upright position using CFrame
	if originalCFrame then
		local targetCFrame = CFrame.new(rootPart.Position + Vector3.new(0, 3, 0), originalCFrame.LookVector)
		local tween = TweenService:Create(rootPart, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			CFrame = targetCFrame
		})
		tween:Play()
	end
	
	print("Stopped prone")
end

function MovementSystem:DolphinDive()
	if not character or not humanoid or isDolphinDiving then return end
	
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then return end
	
	isDolphinDiving = true
	
	local diveDirection = (rootPart.CFrame.LookVector + Vector3.new(0, -0.5, 0)).Unit
	local diveVelocity = Instance.new("BodyVelocity")
	diveVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	diveVelocity.Velocity = diveDirection * DOLPHIN_DIVE_FORCE
	diveVelocity.Parent = rootPart
	diveVelocity.Name = "DiveVelocity"
	
	spawn(function()
		wait(0.5)
		if diveVelocity.Parent then
			diveVelocity:Destroy()
		end
		isDolphinDiving = false
	end)
	
	print("Dolphin diving")
end

function MovementSystem:HandleStateChange(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed and isDolphinDiving then
		self:StartSlide()
		isDolphinDiving = false
	end
	
	if newState == Enum.HumanoidStateType.Freefall and isSliding then
		self:StopSlide()
	end
end

function MovementSystem:ResetMovementState()
	isSliding = false
	isProne = false
	isCrouching = false
	isDolphinDiving = false
	isLedgeGrabbing = false
	
	if humanoid then
		humanoid.WalkSpeed = originalWalkSpeed
		humanoid.JumpPower = originalJumpPower
	end
	
	if slidingConnection then
		slidingConnection:Disconnect()
		slidingConnection = nil
	end
	
	for _, connection in pairs(movementConnections) do
		connection:Disconnect()
	end
	movementConnections = {}
end

function MovementSystem:GetMovementState()
	return {
		IsSliding = isSliding,
		IsProne = isProne,
		IsCrouching = isCrouching,
		IsDolphinDiving = isDolphinDiving,
		IsLedgeGrabbing = isLedgeGrabbing
	}
end

function MovementSystem:SetMovementSpeedMultiplier(multiplier)
	if humanoid then
		humanoid.WalkSpeed = originalWalkSpeed * multiplier
	end
end

function MovementSystem:CheckForLedgeGrab()
	if not character or not humanoid or not rootPart then return false end
	
	-- Only check when falling
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then return false end
	
	-- Don't grab if already grabbing or in other movement state
	if isLedgeGrabbing or isSliding or isProne or isDolphinDiving then return false end
	
	-- Raycast forward to check for ledge
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}
	
	local forwardDirection = rootPart.CFrame.LookVector
	local rayStart = rootPart.Position
	local rayEnd = rayStart + (forwardDirection * LEDGE_GRAB_RANGE)
	
	-- Check for wall at player level
	local wallRay = workspace:Raycast(rayStart, forwardDirection * LEDGE_GRAB_RANGE, raycastParams)
	if not wallRay then return false end
	
	-- Check for ledge above wall
	local ledgeCheckStart = wallRay.Position + Vector3.new(0, LEDGE_GRAB_HEIGHT, 0) + (forwardDirection * 1)
	local ledgeCheckEnd = ledgeCheckStart + Vector3.new(0, -2, 0) -- Check downward for ledge surface
	
	local ledgeRay = workspace:Raycast(ledgeCheckStart, Vector3.new(0, -2, 0), raycastParams)
	if not ledgeRay then return false end
	
	-- Check if there's space above the ledge (so player can climb up)
	local spaceCheckStart = ledgeRay.Position + Vector3.new(0, 6, 0) -- Check 6 studs above ledge
	local spaceCheckEnd = spaceCheckStart + (forwardDirection * 2)
	
	local spaceRay = workspace:Raycast(spaceCheckStart, forwardDirection * 2, raycastParams)
	if spaceRay then return false end -- There's an obstacle above
	
	-- Valid ledge found, initiate grab
	self:StartLedgeGrab(ledgeRay.Position, wallRay.Normal)
	return true
end

function MovementSystem:StartLedgeGrab(ledgePosition, wallNormal)
	if isLedgeGrabbing then return end
	
	isLedgeGrabbing = true
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Position player at ledge
	local hangPosition = ledgePosition - (wallNormal * 1.5) + Vector3.new(0, -3, 0)
	
	-- Create body position to hold player at ledge
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPosition.Position = hangPosition
	bodyPosition.D = 2000
	bodyPosition.P = 10000
	bodyPosition.Parent = rootPart
	
	-- Create body angular velocity to face wall
	local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
	bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
	bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
	bodyAngularVelocity.Parent = rootPart
	
	-- Face the wall
	local targetCFrame = CFrame.lookAt(hangPosition, hangPosition - wallNormal)
	local tween = TweenService:Create(rootPart, TweenInfo.new(0.3), {CFrame = targetCFrame})
	tween:Play()
	
	-- Setup climb/drop controls
	local climbConnection, dropConnection
	
	-- Climb up with Space
	climbConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Space and isLedgeGrabbing then
			self:ClimbUp(ledgePosition, wallNormal)
			climbConnection:Disconnect()
			dropConnection:Disconnect()
		end
	end)
	
	-- Drop with S key
	dropConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.S and isLedgeGrabbing then
			self:DropFromLedge()
			climbConnection:Disconnect()
			dropConnection:Disconnect()
		end
	end)
	
	-- Auto-drop after 10 seconds
	spawn(function()
		wait(10)
		if isLedgeGrabbing then
			self:DropFromLedge()
			if climbConnection then climbConnection:Disconnect() end
			if dropConnection then dropConnection:Disconnect() end
		end
	end)
	
	-- Store connections for cleanup
	table.insert(movementConnections, climbConnection)
	table.insert(movementConnections, dropConnection)
	
	print("Started ledge grab")
end

function MovementSystem:ClimbUp(ledgePosition, wallNormal)
	if not isLedgeGrabbing then return end
	
	isLedgeGrabbing = false
	
	-- Clean up body movers
	for _, obj in pairs(rootPart:GetChildren()) do
		if obj:IsA("BodyPosition") or obj:IsA("BodyAngularVelocity") then
			obj:Destroy()
		end
	end
	
	-- Move player up and forward onto ledge
	local climbPosition = ledgePosition - (wallNormal * 2) + Vector3.new(0, 3, 0)
	
	-- Animate climb
	local climbTween = TweenService:Create(rootPart, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
		CFrame = CFrame.new(climbPosition, climbPosition + Vector3.new(0, 0, -1))
	})
	climbTween:Play()
	
	-- Restore normal physics after climb
	climbTween.Completed:Connect(function()
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end)
	
	-- Award XP for successful climb
	RemoteEventsManager:FireServer("MovementAction", {
		Action = "LedgeClimb",
		Position = climbPosition
	})
	
	print("Climbed up ledge")
end

function MovementSystem:DropFromLedge()
	if not isLedgeGrabbing then return end
	
	isLedgeGrabbing = false
	
	-- Clean up body movers
	for _, obj in pairs(rootPart:GetChildren()) do
		if obj:IsA("BodyPosition") or obj:IsA("BodyAngularVelocity") then
			obj:Destroy()
		end
	end
	
	-- Restore normal physics
	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	
	print("Dropped from ledge")
end

function MovementSystem:SetupLedgeGrabDetection()
	-- Continuously check for ledge grab opportunities when falling
	local ledgeConnection
	ledgeConnection = RunService.Heartbeat:Connect(function()
		if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			if not isLedgeGrabbing then
				-- Small delay to prevent immediate grab after jump
				local velocity = rootPart.AssemblyLinearVelocity
				if velocity.Y < -10 then -- Only when falling fast enough
					self:CheckForLedgeGrab()
				end
			end
		end
	end)
	
	table.insert(movementConnections, ledgeConnection)
end

function MovementSystem:SetupPhysicsComponents()
	-- Initialize reusable physics components
	slideForce = Instance.new("BodyVelocity")
	slideForce.MaxForce = Vector3.new(4000, 0, 4000)
	slideForce.Velocity = Vector3.new(0, 0, 0)
	
	bodyVelocity = Instance.new("BodyVelocity") 
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
end

-- Enhanced slide system with momentum physics
function MovementSystem:EnhancedStartSlide()
	if not character or not humanoid or isSliding or isProne then return end
	
	local currentTime = tick()
	if currentTime - lastSlideTime < SLIDE_COOLDOWN then return end
	
	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude < 0.1 then return end
	
	isSliding = true
	lastSlideTime = currentTime
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	
	-- Calculate slide velocity based on current speed and direction
	local currentVelocity = rootPart.AssemblyLinearVelocity
	local slideVelocity = moveDirection * math.max(SLIDE_SPEED, currentVelocity.Magnitude * 1.2)
	slideVelocity = slideVelocity + Vector3.new(0, -5, 0) -- Add downward component
	
	-- Apply physics-based sliding
	if slideForce then
		slideForce.Velocity = slideVelocity
		slideForce.Parent = rootPart
	end
	
	-- Lower player to slide position
	local targetPosition = rootPart.Position - Vector3.new(0, 2.5, 0)
	local slidePosition = Instance.new("BodyPosition")
	slidePosition.MaxForce = Vector3.new(0, 4000, 0)
	slidePosition.Position = targetPosition
	slidePosition.D = 1000
	slidePosition.Parent = rootPart
	slidePosition.Name = "SlidePosition"
	
	-- Momentum-based deceleration with friction
	slidingConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if slideForce and slideForce.Parent then
			local friction = 0.85 -- Friction coefficient
			local airResistance = 0.98
			
			-- Apply friction based on surface type
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			
			local groundRay = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), raycastParams)
			local surfaceFriction = friction
			
			if groundRay then
				-- Adjust friction based on material
				if groundRay.Instance.Material == Enum.Material.Ice then
					surfaceFriction = 0.98 -- Very slippery
				elseif groundRay.Instance.Material == Enum.Material.Sand then
					surfaceFriction = 0.75 -- High friction
				elseif groundRay.Instance.Material == Enum.Material.Grass then
					surfaceFriction = 0.8 -- Medium friction
				end
			end
			
			-- Apply deceleration
			local currentVel = slideForce.Velocity
			slideForce.Velocity = currentVel * surfaceFriction * airResistance
			
			-- Stop sliding when velocity is too low
			if slideForce.Velocity.Magnitude < 3 then
				self:EnhancedStopSlide()
			end
		end
	end)
	
	-- Auto-stop after maximum duration
	spawn(function()
		wait(SLIDE_DURATION)
		if isSliding then
			self:EnhancedStopSlide()
		end
	end)
	
	-- Fire slide event for effects/sounds
	RemoteEventsManager:FireServer("MovementAction", {
		Action = "StartSlide",
		Position = rootPart.Position,
		Direction = moveDirection
	})
	
	print("Enhanced sliding started")
end

function MovementSystem:EnhancedStopSlide()
	if not isSliding then return end
	
	isSliding = false
	humanoid.WalkSpeed = originalWalkSpeed
	humanoid.JumpPower = originalJumpPower
	
	-- Clean up slide physics
	if slideForce and slideForce.Parent then
		slideForce.Parent = nil
	end
	
	local slidePosition = rootPart:FindFirstChild("SlidePosition")
	if slidePosition then
		slidePosition:Destroy()
	end
	
	if slidingConnection then
		slidingConnection:Disconnect()
		slidingConnection = nil
	end
	
	-- Gradually restore player height
	local restoreHeight = TweenService:Create(rootPart, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		CFrame = rootPart.CFrame + Vector3.new(0, 2.5, 0)
	})
	restoreHeight:Play()
	
	print("Enhanced sliding stopped")
end

-- Wall-run system (bonus advanced movement)
function MovementSystem:CheckWallRun()
	if not character or not humanoid or not rootPart then return false end
	
	-- Only when airborne and moving horizontally
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then return false end
	if isSliding or isProne or isLedgeGrabbing then return false end
	
	local velocity = rootPart.AssemblyLinearVelocity
	if velocity.Y > -5 or math.abs(velocity.Y) > math.max(math.abs(velocity.X), math.abs(velocity.Z)) then
		return false
	end
	
	-- Check for wall to the side
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	
	local rightVector = rootPart.CFrame.RightVector
	local leftVector = -rightVector
	
	-- Check both sides for walls
	local rightWall = workspace:Raycast(rootPart.Position, rightVector * 4, raycastParams)
	local leftWall = workspace:Raycast(rootPart.Position, leftVector * 4, raycastParams)
	
	if rightWall and math.abs(rightWall.Normal.Y) < 0.3 then
		self:StartWallRun(rightWall, "right")
		return true
	elseif leftWall and math.abs(leftWall.Normal.Y) < 0.3 then
		self:StartWallRun(leftWall, "left")
		return true
	end
	
	return false
end

function MovementSystem:StartWallRun(wallHit, side)
	if isLedgeGrabbing then return end
	
	-- Apply wall-run velocity
	local wallNormal = wallHit.Normal
	local forwardDirection = rootPart.CFrame.LookVector
	local wallRunDirection = forwardDirection:Cross(wallNormal).Unit
	
	if side == "left" then
		wallRunDirection = -wallRunDirection
	end
	
	-- Create wall-run physics
	local wallRunVelocity = Instance.new("BodyVelocity")
	wallRunVelocity.MaxForce = Vector3.new(4000, 2000, 4000)
	wallRunVelocity.Velocity = wallRunDirection * 20 + Vector3.new(0, 5, 0) -- Slight upward lift
	wallRunVelocity.Parent = rootPart
	wallRunVelocity.Name = "WallRunVelocity"
	
	-- Auto-stop wall run after short duration
	spawn(function()
		wait(1.5)
		if wallRunVelocity.Parent then
			wallRunVelocity:Destroy()
		end
	end)
	
	print("Wall running on " .. side .. " side")
end

-- Enhanced movement state system
function MovementSystem:GetAdvancedMovementState()
	local state = self:GetMovementState()
	
	-- Add velocity and momentum information
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity
		state.Velocity = velocity
		state.Speed = velocity.Magnitude
		state.IsMoving = humanoid and humanoid.MoveDirection.Magnitude > 0.1
		state.IsAirborne = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall
	end
	
	return state
end

-- Cleanup function
function MovementSystem:Cleanup()
	-- Disconnect all connections
	for _, connection in pairs(movementConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	movementConnections = {}
	
	if slidingConnection then
		slidingConnection:Disconnect()
		slidingConnection = nil
	end
	
	-- Clean up physics components
	if slideForce then
		slideForce:Destroy()
		slideForce = nil
	end
	
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	
	-- Reset movement state
	self:ResetMovementState()
	
	print("MovementSystem cleaned up")
end

MovementSystem:Initialize()

-- Set as global for other systems to access
_G.MovementSystem = MovementSystem
return MovementSystem