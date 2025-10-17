--[[
	WeaponPreviewSystem.lua
	Handles 3D weapon previews in ViewportFrames with rotation, attachment visualization, and animation
]]

local WeaponPreviewSystem = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local WeaponConfig = require(script.Parent.WeaponConfig)

-- Active viewport data
local activeViewports = {}
local rotationConnections = {}

function WeaponPreviewSystem:Initialize()
	print("WeaponPreviewSystem: Initialized")
end

-- Create a 3D weapon preview in a ViewportFrame
function WeaponPreviewSystem:CreateWeaponPreview(viewportFrame, weaponName, showAttachments)
	if not viewportFrame or not weaponName then
		warn("WeaponPreviewSystem: Invalid viewport or weapon name")
		return nil
	end

	-- Clear existing content
	viewportFrame:ClearAllChildren()

	-- Get weapon model path
	local modelPath = WeaponConfig:GetWeaponModelPath(weaponName)
	if not modelPath then
		warn("WeaponPreviewSystem: No model path found for weapon:", weaponName)
		return nil
	end

	-- Navigate to weapon model
	local pathParts = string.split(modelPath, ".")
	local currentObj = game

	for _, part in ipairs(pathParts) do
		currentObj = currentObj:FindFirstChild(part)
		if not currentObj then
			warn("WeaponPreviewSystem: Model not found at path:", modelPath)
			return nil
		end
	end

    -- Clone the weapon model
    local weaponModel = currentObj:Clone()
    if not weaponModel then
        warn("WeaponPreviewSystem: Failed to clone weapon model:", weaponName)
        return nil
    end

    -- Strip runtime scripts and sounds from preview clone to avoid running code in preview
    for _, desc in pairs(weaponModel:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") or desc:IsA("Sound") then
            desc:Destroy()
        end
    end

    -- Ensure the model has a PrimaryPart; if not, pick the first BasePart found
    if not weaponModel.PrimaryPart then
        for _, part in pairs(weaponModel:GetDescendants()) do
            if part:IsA("BasePart") then
                weaponModel.PrimaryPart = part
                break
            end
        end
    end

    -- Anchor preview parts and disable collisions so the viewport is stable
    for _, part in pairs(weaponModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        end
    end

    -- Parent the preview model inside the viewport
    weaponModel.Parent = viewportFrame

    -- Create camera for viewport (after parenting model so PrimaryPart positions are valid)
    local camera = Instance.new("Camera")
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera

	-- Calculate model bounds and position camera
	local modelSize = self:GetModelSize(weaponModel)
	local distance = math.max(modelSize.X, modelSize.Y, modelSize.Z) * 2

	-- Position camera to view weapon
	camera.CFrame = CFrame.lookAt(
		Vector3.new(distance, distance * 0.5, distance),
		weaponModel.PrimaryPart and weaponModel.PrimaryPart.Position or Vector3.new(0, 0, 0)
	)

	-- Setup lighting
	self:SetupViewportLighting(viewportFrame)

	-- Add attachments if requested
	if showAttachments then
		self:AddWeaponAttachments(weaponModel, weaponName)
	end

	-- Store viewport data for rotation
	local viewportData = {
		viewport = viewportFrame,
		model = weaponModel,
		camera = camera,
		baseDistance = distance,
		rotationX = 0,
		rotationY = 0,
		isDragging = false,
		canRotate = true
	}

	activeViewports[viewportFrame] = viewportData

	-- Setup mouse rotation if enabled
	self:SetupViewportRotation(viewportData)

	return viewportData
end

-- Calculate the size of a model
function WeaponPreviewSystem:GetModelSize(model)
	local minPoint = Vector3.new(math.huge, math.huge, math.huge)
	local maxPoint = Vector3.new(-math.huge, -math.huge, -math.huge)

	local function processDescendant(obj)
		if obj:IsA("BasePart") then
			local cf = obj.CFrame
			local size = obj.Size
			local corners = {
				cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
				cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
				cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
				cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
				cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
				cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
				cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
				cf * Vector3.new(size.X/2, size.Y/2, size.Z/2)
			}

			for _, corner in ipairs(corners) do
				minPoint = Vector3.new(
					math.min(minPoint.X, corner.X),
					math.min(minPoint.Y, corner.Y),
					math.min(minPoint.Z, corner.Z)
				)
				maxPoint = Vector3.new(
					math.max(maxPoint.X, corner.X),
					math.max(maxPoint.Y, corner.Y),
					math.max(maxPoint.Z, corner.Z)
				)
			end
		end
	end

	processDescendant(model)
	for _, descendant in pairs(model:GetDescendants()) do
		processDescendant(descendant)
	end

	return maxPoint - minPoint
end

-- Setup lighting for viewport
function WeaponPreviewSystem:SetupViewportLighting(viewportFrame)
	-- Main light
	local mainLight = Instance.new("PointLight")
	mainLight.Brightness = 2
	mainLight.Color = Color3.fromRGB(255, 245, 235)
	mainLight.Range = 100

	-- Create light holder
	local lightHolder = Instance.new("Part")
	lightHolder.Name = "LightHolder"
	lightHolder.Anchored = true
	lightHolder.CanCollide = false
	lightHolder.Transparency = 1
	lightHolder.Size = Vector3.new(0.1, 0.1, 0.1)
	lightHolder.Position = Vector3.new(5, 5, 5)
	lightHolder.Parent = viewportFrame

	mainLight.Parent = lightHolder

	-- Ambient light
	local ambientLight = Instance.new("PointLight")
	ambientLight.Brightness = 1
	ambientLight.Color = Color3.fromRGB(200, 220, 255)
	ambientLight.Range = 50

	local ambientHolder = Instance.new("Part")
	ambientHolder.Name = "AmbientLightHolder"
	ambientHolder.Anchored = true
	ambientHolder.CanCollide = false
	ambientHolder.Transparency = 1
	ambientHolder.Size = Vector3.new(0.1, 0.1, 0.1)
	ambientHolder.Position = Vector3.new(-3, 2, -3)
	ambientHolder.Parent = viewportFrame

	ambientLight.Parent = ambientHolder
end

-- Add attachments to weapon model for preview
function WeaponPreviewSystem:AddWeaponAttachments(weaponModel, weaponName)
	-- This would be called with current player's attachment loadout
	-- For now, just add some example attachments if attachment points exist

	local config = WeaponConfig:GetWeaponConfig(weaponName)
	if not config or not config.AttachmentSlots then return end

	-- Look for attachment points in the model
	local attachmentPoints = {}
	for _, descendant in pairs(weaponModel:GetDescendants()) do
		if descendant:IsA("Attachment") then
			attachmentPoints[descendant.Name] = descendant
		end
	end

	-- Add example attachments (this would be replaced with actual player loadout)
	if attachmentPoints["SightMount"] then
		self:AttachAccessory(weaponModel, attachmentPoints["SightMount"], "RedDot")
	end

	if attachmentPoints["MuzzleMount"] then
		self:AttachAccessory(weaponModel, attachmentPoints["MuzzleMount"], "Suppressor")
	end
end

-- Attach an accessory to weapon model
function WeaponPreviewSystem:AttachAccessory(weaponModel, attachmentPoint, accessoryType)
	-- Create a simple accessory representation
	-- In a full implementation, this would load actual attachment models

	local accessory = Instance.new("Part")
	accessory.Name = accessoryType
	accessory.Size = Vector3.new(0.5, 0.2, 0.2)
	accessory.Material = Enum.Material.Metal
	accessory.BrickColor = BrickColor.new("Dark stone grey")
	accessory.CanCollide = false
	accessory.Anchored = false

	-- Weld to attachment point
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = attachmentPoint.Parent
	weld.Part1 = accessory
	weld.Parent = accessory

	accessory.CFrame = attachmentPoint.WorldCFrame
	accessory.Parent = weaponModel
end

-- Setup mouse rotation for viewport
function WeaponPreviewSystem:SetupViewportRotation(viewportData)
	local viewport = viewportData.viewport

	-- Mouse input handling
	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = input.Position
			local viewportPos = viewport.AbsolutePosition
			local viewportSize = viewport.AbsoluteSize

			-- Check if mouse is over viewport
			if mousePos.X >= viewportPos.X and mousePos.X <= viewportPos.X + viewportSize.X and
			   mousePos.Y >= viewportPos.Y and mousePos.Y <= viewportPos.Y + viewportSize.Y then
				viewportData.isDragging = true
				viewportData.lastMousePos = mousePos
			end
		end
	end

	local function onInputChanged(input)
		if viewportData.isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = input.Position
			local deltaX = mousePos.X - viewportData.lastMousePos.X
			local deltaY = mousePos.Y - viewportData.lastMousePos.Y

			viewportData.rotationY = viewportData.rotationY + deltaX * 0.01
			viewportData.rotationX = math.clamp(viewportData.rotationX + deltaY * 0.01, -1.5, 1.5)

			self:UpdateCameraRotation(viewportData)
			viewportData.lastMousePos = mousePos
		end
	end

	local function onInputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			viewportData.isDragging = false
		end
	end

	-- Connect input events
	local connections = {
		UserInputService.InputBegan:Connect(onInputBegan),
		UserInputService.InputChanged:Connect(onInputChanged),
		UserInputService.InputEnded:Connect(onInputEnded)
	}

	rotationConnections[viewport] = connections
end

-- Update camera rotation based on mouse input
function WeaponPreviewSystem:UpdateCameraRotation(viewportData)
	local model = viewportData.model
	local camera = viewportData.camera
	local distance = viewportData.baseDistance

	local centerPos = model.PrimaryPart and model.PrimaryPart.Position or Vector3.new(0, 0, 0)

	local rotX = CFrame.Angles(viewportData.rotationX, 0, 0)
	local rotY = CFrame.Angles(0, viewportData.rotationY, 0)

	local offset = rotY * rotX * Vector3.new(0, 0, distance)
	camera.CFrame = CFrame.lookAt(centerPos + offset, centerPos)
end

-- Enable/disable rotation for a viewport
function WeaponPreviewSystem:SetViewportRotationEnabled(viewportFrame, enabled)
	local viewportData = activeViewports[viewportFrame]
	if viewportData then
		viewportData.canRotate = enabled
		viewportData.isDragging = false
	end
end

-- Update weapon in existing viewport
function WeaponPreviewSystem:UpdateWeaponPreview(viewportFrame, weaponName, showAttachments)
	if activeViewports[viewportFrame] then
		self:CleanupViewport(viewportFrame)
	end
	return self:CreateWeaponPreview(viewportFrame, weaponName, showAttachments)
end

-- Animate weapon preview (idle animation)
function WeaponPreviewSystem:AnimateWeaponPreview(viewportFrame, animationType)
	local viewportData = activeViewports[viewportFrame]
	if not viewportData or not viewportData.model then return end

	local model = viewportData.model

	if animationType == "idle" then
		-- Gentle bobbing animation
		local tween = TweenService:Create(model.PrimaryPart,
			TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Position = model.PrimaryPart.Position + Vector3.new(0, 0.1, 0)}
		)
		tween:Play()
		viewportData.animation = tween
	elseif animationType == "spin" then
		-- Spinning animation
		local startCFrame = model.PrimaryPart.CFrame
		local tween = TweenService:Create(model.PrimaryPart,
			TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
			{CFrame = startCFrame * CFrame.Angles(0, math.pi * 2, 0)}
		)
		tween:Play()
		viewportData.animation = tween
	end
end

-- Stop weapon preview animation
function WeaponPreviewSystem:StopWeaponAnimation(viewportFrame)
	local viewportData = activeViewports[viewportFrame]
	if viewportData and viewportData.animation then
		viewportData.animation:Cancel()
		viewportData.animation = nil
	end
end

-- Reset viewport camera to default position
function WeaponPreviewSystem:ResetViewportCamera(viewportFrame)
	local viewportData = activeViewports[viewportFrame]
	if not viewportData then return end

	viewportData.rotationX = 0
	viewportData.rotationY = 0
	self:UpdateCameraRotation(viewportData)
end

-- Cleanup viewport
function WeaponPreviewSystem:CleanupViewport(viewportFrame)
	local viewportData = activeViewports[viewportFrame]
	if viewportData then
		-- Stop animations
		self:StopWeaponAnimation(viewportFrame)

		-- Disconnect rotation events
		local connections = rotationConnections[viewportFrame]
		if connections then
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			rotationConnections[viewportFrame] = nil
		end

		-- Clear viewport
		viewportFrame:ClearAllChildren()
		activeViewports[viewportFrame] = nil
	end
end

-- Get all active viewports (for debugging)
function WeaponPreviewSystem:GetActiveViewports()
	return activeViewports
end

-- Cleanup all viewports
function WeaponPreviewSystem:CleanupAll()
	for viewportFrame, _ in pairs(activeViewports) do
		self:CleanupViewport(viewportFrame)
	end
end

return WeaponPreviewSystem