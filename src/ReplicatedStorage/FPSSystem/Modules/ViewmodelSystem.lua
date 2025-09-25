local ViewmodelSystem = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local mouse = player:GetMouse()

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
	
	-- Initialize components
	RemoteEventsManager:Initialize()
	
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
	
	isFirstPersonLocked = true
	fpsWeaponEquipped = true
	
	-- Force first-person view
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5
	
	-- Apply player FOV setting from DataStore
	-- Default FOV (can be modified via client settings)
	local playerFOV = 90

	-- Try to get FOV from server if needed
	local getSettingEvent = RemoteEventsManager:GetEvent("GetPlayerSetting")
	if getSettingEvent then
		local serverFOV = getSettingEvent:InvokeServer("FOV")
		if serverFOV then
			playerFOV = serverFOV
		end
	end
	Camera.FieldOfView = playerFOV
	
	print("First-person view locked")
end

function ViewmodelSystem:UnlockFirstPerson()
	if not isFirstPersonLocked then return end
	
	isFirstPersonLocked = false
	fpsWeaponEquipped = false
	
	-- Restore original camera settings
	player.CameraMaxZoomDistance = originalMaxZoomDistance or 400
	player.CameraMinZoomDistance = 0.5
	
	-- Reset to default FOV
	Camera.FieldOfView = 70
	
	print("First-person view unlocked")
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
		self:CreateViewmodel(tool.Name, weaponConfig)
	end
end

-- Tool unequipped handler
function ViewmodelSystem:OnToolUnequipped(tool)
	local weaponConfig = WeaponConfig:GetWeaponConfig(tool.Name)
	if weaponConfig then
		self:UnlockFirstPerson()
		self:RemoveViewmodel()
	end
end

-- Create viewmodel for weapon
function ViewmodelSystem:CreateViewmodel(weaponName, weaponCategory)
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
	local viewmodelPath = ReplicatedStorage.FPSSystem.ViewModels
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
	
	local weaponFolder = typeFolder:FindFirstChild(weaponName)
	if not weaponFolder then 
		warn("Weapon folder not found: " .. weaponName)
		return 
	end
	
	local viewmodelModel = weaponFolder:FindFirstChildOfClass("Model")
	if not viewmodelModel then 
		warn("Viewmodel model not found for: " .. weaponName)
		return 
	end
	
	-- Clone and setup viewmodel
	activeViewmodel = viewmodelModel:Clone()
	activeViewmodel.Name = "ActiveViewmodel"
	activeViewmodel.Parent = Camera
	
	-- Get base offset for weapon category
	baseOffset = viewmodelOffsets[weaponConfig.Category].Position
	
	-- Set initial position
	self:UpdateViewmodelPosition()
	
	print("Viewmodel created for " .. weaponName .. " (" .. weaponConfig.Category .. ")")
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

-- Update viewmodel position with all offsets combined
function ViewmodelSystem:UpdateViewmodelPosition()
	if not activeViewmodel then return end
	
	-- Combine all offset vectors
	local totalOffset = baseOffset + swayOffset + breathingOffset + walkingOffset + recoilOffset
	
	-- Calculate new CFrame relative to camera
	local cameraCFrame = Camera.CFrame
	local viewmodelCFrame = cameraCFrame * CFrame.new(totalOffset)
	
	-- Apply the transform to viewmodel
	activeViewmodel:SetPrimaryPartCFrame(viewmodelCFrame)
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
	
	print("ViewmodelSystem cleaned up")
end

-- Alias for RemoveViewmodel for backward compatibility
function ViewmodelSystem:DestroyViewmodel()
	return self:RemoveViewmodel()
end

return ViewmodelSystem