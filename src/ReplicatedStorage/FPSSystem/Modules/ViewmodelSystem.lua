local ViewmodelSystem = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- CLIENT-ONLY MODULE CHECK
if RunService:IsServer() then
	warn("ViewmodelSystem is a client-only module and should not be required on the server")
	return ViewmodelSystem
end

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local GlobalStateManager = require(ReplicatedStorage.FPSSystem.Modules.GlobalStateManager)

-- Load ScopeSystem if available
local ScopeSystem = nil
pcall(function()
	ScopeSystem = require(ReplicatedStorage.FPSSystem.Modules.ScopeSystem)
end)

local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Initialize player state in GlobalStateManager
GlobalStateManager:InitializePlayerState(player)

-- Viewmodel state
local activeViewmodel = nil
local viewmodelConnection = nil
local swayConnection = nil
local breathingConnection = nil
local walkingConnection = nil
local recoilConnection = nil

-- First-person system
local isFirstPersonLocked = false
local originalCameraSubject = nil
local originalMaxZoomDistance = nil
local fpsWeaponEquipped = false

-- Enhanced viewmodel offsets with FOV settings
local viewmodelOffsets = {
	Primary = {
		Position = Vector3.new(0.5, -0.5, -1),
		Rotation = Vector3.new(0, -5, 0),
		FOV = 65
	},
	Secondary = {
		Position = Vector3.new(0.3, -0.3, -0.8),
		Rotation = Vector3.new(0, -3, 0),
		FOV = 70
	},
	Melee = {
		Position = Vector3.new(0.2, -0.4, -0.6),
		Rotation = Vector3.new(0, -2, 0),
		FOV = 75
	},
	Grenade = {
		Position = Vector3.new(0.4, -0.2, -0.7),
		Rotation = Vector3.new(0, -1, 0),
		FOV = 80
	}
}

-- Sway and movement parameters
local swayIntensity = 0.02
local swaySpeed = 2
local breathingIntensity = 0.01
local breathingSpeed = 1.5
local walkingBobIntensity = 0.03
local recoilRecoverySpeed = 5

-- Current offsets
local swayOffset = Vector3.new(0, 0, 0)
local breathingOffset = Vector3.new(0, 0, 0)
local walkingOffset = Vector3.new(0, 0, 0)
local recoilOffset = Vector3.new(0, 0, 0)
local baseOffset = Vector3.new(0, 0, 0)

function ViewmodelSystem:Initialize()
	if not RunService:IsClient() then
		warn("ViewmodelSystem can only be initialized on the client")
		return
	end

	-- Store original camera settings
	originalCameraSubject = Camera.CameraSubject
	originalMaxZoomDistance = player.CameraMaxZoomDistance
	
	-- Setup all sway systems
	self:SetupMouseSway()
	self:SetupBreathingSway()
	self:SetupWalkingSway()
	self:SetupRecoilSystem()
	
	-- Setup tool connections
	self:SetupToolConnections()
	
	print("ViewmodelSystem initialized with first-person lock")
end

-- First-person camera lock system
function ViewmodelSystem:LockFirstPerson()
	if isFirstPersonLocked then return end

	-- Store original values
	if not originalMaxZoomDistance then
		originalMaxZoomDistance = player.CameraMaxZoomDistance
	end

	isFirstPersonLocked = true
	fpsWeaponEquipped = true

	-- Force first-person view
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5

	-- Apply player FOV setting from DataStore
	-- Default FOV (can be modified via client settings)
	local playerFOV = 90

	-- Try to get FOV from server if needed (but don't wait for it)
	pcall(function()
		local getSettingEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("GetPlayerSetting")
		if getSettingEvent then
			local serverFOV = getSettingEvent:InvokeServer("FOV")
			if serverFOV then
				playerFOV = serverFOV
			end
		end
	end)

	Camera.FieldOfView = playerFOV

	print("✓ First-person view locked")
end

function ViewmodelSystem:UnlockFirstPerson()
	if not isFirstPersonLocked then return end

	isFirstPersonLocked = false
	fpsWeaponEquipped = false

	-- Restore original camera settings with multiple attempts for safety
	local success = pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMaxZoomDistance = originalMaxZoomDistance or 400
		player.CameraMinZoomDistance = 0.5

		-- Also reset MouseBehavior to allow mouse movement
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default

		-- Reset to default FOV
		Camera.FieldOfView = 70
	end)

	if not success then
		warn("Failed to unlock first person view, retrying...")
		-- Fallback: Force unlock with delay
		task.wait(0.1)
		pcall(function()
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMaxZoomDistance = 400
			player.CameraMinZoomDistance = 0.5
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end

	print("✓ First-person view unlocked")
end

-- Enhanced mouse sway with multiple layers
function ViewmodelSystem:SetupMouseSway()
	local lastMousePosition = Vector2.new(mouse.X, mouse.Y)
	
	swayConnection = RunService.RenderStepped:Connect(function()
		if not activeViewmodel then return end
		
		-- Get mouse delta
		local currentMousePosition = Vector2.new(mouse.X, mouse.Y)
		local mouseDelta = currentMousePosition - lastMousePosition
		lastMousePosition = currentMousePosition
		
		-- Calculate sway based on mouse movement
		local swayX = math.clamp(mouseDelta.X * swayIntensity, -0.1, 0.1)
		local swayY = math.clamp(mouseDelta.Y * swayIntensity, -0.1, 0.1)
		
		-- Smooth sway interpolation
		swayOffset = swayOffset:Lerp(Vector3.new(-swayX, -swayY, 0), 0.1)
		
		-- Apply combined offsets to viewmodel
		self:UpdateViewmodelPosition()
	end)
end

-- Breathing sway system
function ViewmodelSystem:SetupBreathingSway()
	breathingConnection = RunService.RenderStepped:Connect(function()
		if not activeViewmodel then return end
		
		local time = tick()
		local breathX = math.sin(time * breathingSpeed) * breathingIntensity
		local breathY = math.cos(time * breathingSpeed * 0.7) * breathingIntensity * 0.8
		
		breathingOffset = Vector3.new(breathX, breathY, 0)
		self:UpdateViewmodelPosition()
	end)
end

-- Walking bob system
function ViewmodelSystem:SetupWalkingSway()
	walkingConnection = RunService.RenderStepped:Connect(function()
		if not activeViewmodel or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		local moveVector = humanoid.MoveDirection
		local walkSpeed = moveVector.Magnitude
		
		if walkSpeed > 0.1 then
			local time = tick()
			local walkBobX = math.sin(time * 8) * walkingBobIntensity * walkSpeed
			local walkBobY = math.abs(math.sin(time * 16)) * walkingBobIntensity * walkSpeed * 0.5
			
			walkingOffset = Vector3.new(walkBobX, walkBobY, 0)
		else
			-- Smooth out walking bob when stopped
			walkingOffset = walkingOffset:Lerp(Vector3.new(0, 0, 0), 0.1)
		end
		
		self:UpdateViewmodelPosition()
	end)
end

-- Recoil system
function ViewmodelSystem:SetupRecoilSystem()
	recoilConnection = RunService.RenderStepped:Connect(function()
		if not activeViewmodel then return end
		
		-- Gradually recover from recoil
		recoilOffset = recoilOffset:Lerp(Vector3.new(0, 0, 0), recoilRecoverySpeed * RunService.RenderStepped:Wait())
		self:UpdateViewmodelPosition()
	end)
end


-- Tool connection system
function ViewmodelSystem:SetupToolConnections()
	-- Connect to player's backpack and character
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				self:OnToolEquipped(child)
			end
		end)
		
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				self:OnToolUnequipped(child)
			end
		end)
	end)
	
	if player.Character then
		for _, child in pairs(player.Character:GetChildren()) do
			if child:IsA("Tool") then
				self:OnToolEquipped(child)
			end
		end
	end
end

-- Tool equipped handler
function ViewmodelSystem:OnToolEquipped(tool)
	-- Check if this is an FPS weapon tool
	local weaponConfig = WeaponConfig:GetWeaponConfig(tool.Name)
	if weaponConfig then
		self:LockFirstPerson()
		self:CreateViewmodel(tool.Name)

		-- Hide the tool's handle so only viewmodel is visible
		local handle = tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			-- Store original transparency
			if not handle:GetAttribute("OriginalTransparency") then
				handle:SetAttribute("OriginalTransparency", handle.Transparency)
			end
			handle.Transparency = 1
			print("✓ Hidden tool handle for", tool.Name)
		end

		-- Notify ScopeSystem about weapon equipped
		if ScopeSystem and ScopeSystem.OnWeaponEquipped then
			ScopeSystem:OnWeaponEquipped(tool)
		end
	end
end

-- Tool unequipped handler
function ViewmodelSystem:OnToolUnequipped(tool)
	local weaponConfig = WeaponConfig:GetWeaponConfig(tool.Name)
	if weaponConfig then
		-- Restore tool handle visibility
		local handle = tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local originalTransparency = handle:GetAttribute("OriginalTransparency") or 0
			handle.Transparency = originalTransparency
			print("✓ Restored tool handle visibility for", tool.Name)
		end

		-- Remove viewmodel first
		self:RemoveViewmodel()

		-- Then unlock first person (with safety delay)
		task.spawn(function()
			task.wait(0.05) -- Small delay to ensure tool fully unequipped
			self:UnlockFirstPerson()
		end)

		-- Notify ScopeSystem about weapon unequipped
		if ScopeSystem and ScopeSystem.OnWeaponUnequipped then
			ScopeSystem:OnWeaponUnequipped()
		end

		print("✓ Tool unequipped, camera should unlock")
	end
end

-- Create viewmodel for weapon
function ViewmodelSystem:CreateViewmodel(weaponName)
	-- Remove existing viewmodel
	self:RemoveViewmodel()

	-- Get weapon config
	local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not weaponConfig then
		warn("No weapon config found for: " .. weaponName)
		return
	end

	-- Lock first-person view
	self:LockFirstPerson()

	-- Load viewmodel from ReplicatedStorage
	local viewmodelPath = ReplicatedStorage.FPSSystem:FindFirstChild("ViewModels") or ReplicatedStorage.FPSSystem:FindFirstChild("Viewmodels")
	if not viewmodelPath then
		warn("ViewModels folder not found in ReplicatedStorage")
		return
	end

	local categoryFolder = viewmodelPath:FindFirstChild(weaponConfig.Category)
	if not categoryFolder then
		warn("Category folder not found: " .. weaponConfig.Category)
		return
	end

	local typeFolder = categoryFolder:FindFirstChild(weaponConfig.Type)
	if not typeFolder then
		warn("Type folder not found: " .. weaponConfig.Type)
		return
	end

	-- Try to find weapon - could be a folder or direct RBXM file
	local weaponFolder = typeFolder:FindFirstChild(weaponName)
	local viewmodelModel = nil

	if weaponFolder then
		-- Found a folder/model with the weapon name
		if weaponFolder:IsA("Model") or weaponFolder:IsA("Tool") then
			-- The item itself is the viewmodel
			viewmodelModel = weaponFolder
		else
			-- Look for a Model or Tool inside the folder
			viewmodelModel = weaponFolder:FindFirstChildOfClass("Model") or weaponFolder:FindFirstChildOfClass("Tool")
		end
	else
		-- No folder found - try looking for direct Model/Tool in typeFolder
		viewmodelModel = typeFolder:FindFirstChild(weaponName)
		if viewmodelModel and not (viewmodelModel:IsA("Model") or viewmodelModel:IsA("Tool")) then
			viewmodelModel = nil
		end
	end

	if not viewmodelModel then
		warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		warn("⚠ VIEWMODEL NOT FOUND")
		warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		warn("Weapon: " .. weaponName)
		warn("Category: " .. weaponConfig.Category)
		warn("Type: " .. weaponConfig.Type)
		warn("Expected path: " .. typeFolder:GetFullName() .. "/" .. weaponName)
		warn("Searched for: Model or Tool named '" .. weaponName .. "'")
		warn("")
		warn("Available items in folder:")
		for _, child in pairs(typeFolder:GetChildren()) do
			warn("  - " .. child.Name .. " (" .. child.ClassName .. ")")
		end
		warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		return
	end

	-- Clone and setup viewmodel
	activeViewmodel = viewmodelModel:Clone()
	activeViewmodel.Name = "ActiveViewmodel"

	-- Set all parts to Massless and CanCollide false
	for _, descendant in pairs(activeViewmodel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.Massless = true
			descendant.CastShadow = false
			descendant.Anchored = false

			-- Set collision group to Viewmodels
			pcall(function()
				descendant.CollisionGroup = "Viewmodels"
			end)
		end
	end

	-- Find CameraPart and connect to head
	local cameraPart = activeViewmodel:FindFirstChild("CameraPart", true)
	if cameraPart and cameraPart:IsA("BasePart") then
		print("✓ Found CameraPart in viewmodel")

		-- Set CameraPart as primary part
		if activeViewmodel:IsA("Model") then
			activeViewmodel.PrimaryPart = cameraPart
		end

		-- Wait for character head
		if player.Character then
			local head = player.Character:WaitForChild("Head", 3)
			if head then
				-- Create weld between CameraPart and Camera
				cameraPart.CFrame = Camera.CFrame
				cameraPart.Anchored = false

				print("✓ CameraPart connected to camera")
			else
				warn("Head not found in character")
			end
		end
	else
		warn("CameraPart not found in viewmodel - viewmodel may not display correctly")
		-- Try to find any part to use as primary
		local primaryPart = activeViewmodel:FindFirstChildOfClass("BasePart")
		if primaryPart and activeViewmodel:IsA("Model") then
			activeViewmodel.PrimaryPart = primaryPart
			print("Using " .. primaryPart.Name .. " as primary part")
		end
	end

	activeViewmodel.Parent = Camera

	-- Load animations
	self:LoadViewmodelAnimations(weaponName, weaponConfig)

	-- Get base offset for weapon category
	baseOffset = viewmodelOffsets[weaponConfig.Category].Position

	-- Set initial position
	self:UpdateViewmodelPosition()

	print("✓ Viewmodel created for " .. weaponName .. " (" .. weaponConfig.Category .. ")")
end
-- Apply recoil to viewmodel
function ViewmodelSystem:ApplyRecoil(recoilVector)
	if not activeViewmodel then return end
	
	recoilOffset = recoilOffset + recoilVector
	
	-- Apply recoil recovery
	spawn(function()
		wait(0.1)
		local tween = TweenService:Create(recoilOffset, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			X = 0,
			Y = 0,
			Z = 0
		})
		tween:Play()
	end)
end

-- Remove active viewmodel
function ViewmodelSystem:RemoveViewmodel()
	if activeViewmodel then
		activeViewmodel:Destroy()
		activeViewmodel = nil
		baseOffset = Vector3.new(0, 0, 0)
		print("Viewmodel removed")
	end
end

-- Load viewmodel animations
function ViewmodelSystem:LoadViewmodelAnimations(weaponName, weaponConfig)
	if not activeViewmodel then return end

	-- Look for animations in ReplicatedStorage.FPSSystem
	local animationsPath = ReplicatedStorage.FPSSystem:FindFirstChild("Animations")
	if not animationsPath then
		warn("Animations folder not found in FPSSystem")
		return
	end

	-- Check category folder
	local categoryFolder = animationsPath:FindFirstChild(weaponConfig.Category)
	if not categoryFolder then
		print("No animations folder for category: " .. weaponConfig.Category)
		return
	end

	-- Check type folder
	local typeFolder = categoryFolder:FindFirstChild(weaponConfig.Type)
	if not typeFolder then
		print("No animations folder for type: " .. weaponConfig.Type)
		return
	end

	-- Check weapon-specific folder
	local weaponAnimFolder = typeFolder:FindFirstChild(weaponName)
	if not weaponAnimFolder then
		print("No animations folder for weapon: " .. weaponName)
		return
	end

	-- Find AnimationController or Humanoid in viewmodel
	local animController = activeViewmodel:FindFirstChildOfClass("AnimationController")
	if not animController then
		-- Create one if it doesn't exist
		animController = Instance.new("AnimationController")
		animController.Parent = activeViewmodel

		-- Find a humanoid root part or create one
		local rootPart = activeViewmodel:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			rootPart = activeViewmodel:FindFirstChild("CameraPart")
		end

		if rootPart then
			local animator = Instance.new("Animator")
			animator.Parent = animController
		end
	end

	local animator = animController:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animController
	end

	-- Load all animations
	for _, anim in pairs(weaponAnimFolder:GetChildren()) do
		if anim:IsA("Animation") then
			local track = animator:LoadAnimation(anim)
			print("✓ Loaded animation: " .. anim.Name)
			-- Store animation track if needed
		end
	end

	print("✓ Loaded animations for " .. weaponName)
end

-- Update viewmodel position with all offsets combined
function ViewmodelSystem:UpdateViewmodelPosition()
	if not activeViewmodel then return end

	-- Combine all offset vectors
	local totalOffset = baseOffset + swayOffset + breathingOffset + walkingOffset + recoilOffset

	-- Calculate new CFrame relative to camera
	local cameraCFrame = Camera.CFrame
	local viewmodelCFrame = cameraCFrame * CFrame.new(totalOffset)

	-- Apply the transform to viewmodel
	if activeViewmodel:IsA("Model") and activeViewmodel.PrimaryPart then
		activeViewmodel:SetPrimaryPartCFrame(viewmodelCFrame)
	elseif activeViewmodel:IsA("Tool") then
		-- For tools, set the Handle CFrame
		local handle = activeViewmodel:FindFirstChild("Handle")
		if handle then
			handle.CFrame = viewmodelCFrame
		end
	end
end

-- Public interface functions
function ViewmodelSystem:GetActiveViewmodel()
	return activeViewmodel
end

function ViewmodelSystem:IsFirstPersonLocked()
	return isFirstPersonLocked
end

function ViewmodelSystem:HasFPSWeaponEquipped()
	return fpsWeaponEquipped
end

-- Cleanup function
function ViewmodelSystem:Cleanup()
	-- Disconnect all connections
	if swayConnection then
		swayConnection:Disconnect()
		swayConnection = nil
	end

	if breathingConnection then
		breathingConnection:Disconnect()
		breathingConnection = nil
	end

	if walkingConnection then
		walkingConnection:Disconnect()
		walkingConnection = nil
	end

	if recoilConnection then
		recoilConnection:Disconnect()
		recoilConnection = nil
	end

	-- Remove viewmodel and unlock first person
	self:RemoveViewmodel()
	self:UnlockFirstPerson()

	-- Force camera unlock as final safety measure
	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMaxZoomDistance = 400
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end)

	print("ViewmodelSystem cleaned up")
end

-- Add safety cleanup on character removing
if player then
	player.CharacterRemoving:Connect(function()
		-- Force unlock camera when character is removed
		pcall(function()
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMaxZoomDistance = 400
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end)
end

-- Alias for RemoveViewmodel for backward compatibility
function ViewmodelSystem:DestroyViewmodel()
	return self:RemoveViewmodel()
end

-- Notify ScopeSystem when aiming (called by weapon scripts)
function ViewmodelSystem:SetAiming(isAiming)
	-- Update GlobalStateManager with aiming state
	GlobalStateManager:UpdatePlayerState(player, "IsAiming", isAiming)

	-- Notify ScopeSystem
	if ScopeSystem and ScopeSystem.OnAiming then
		ScopeSystem:OnAiming(isAiming)
	end

	print("Aiming state updated:", isAiming)
end

-- Check if scope system is active
function ViewmodelSystem:IsScopeSystemActive()
	return ScopeSystem and ScopeSystem:IsScoped() or false
end

return ViewmodelSystem