local ScopeSystem = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local scopeConfigs = {
	["Red Dot"] = {
		ZoomLevel = 1.5,
		ScopeType = "RefleX",
		FOV = 70,
		UI = true,
        Reticle = "rbxassetid://240080272",
		ReticleSize = UDim2.new(0, 4, 0, 4)
	},
	["Holographic"] = {
		ZoomLevel = 1.5,
		ScopeType = "RefleX", 
		FOV = 70,
		UI = true,
        Reticle = "rbxassetid://1012273004",
		ReticleSize = UDim2.new(0, 6, 0, 6)
	},
	["ACOG"] = {
		ZoomLevel = 4.0,
		ScopeType = "Magnified",
		FOV = 20,
		UI = false,
		ScopeModel = "ACOG_Scope",
        Reticle = "rbxassetid://126126923",
		ReticleSize = UDim2.new(0, 2, 0, 2)
	},
	["4x Scope"] = {
		ZoomLevel = 4.0,
		ScopeType = "Magnified",
		FOV = 20,
		UI = false,
		ScopeModel = "4x_Scope",
        Reticle = "rbxassetid://123566254",
		ReticleSize = UDim2.new(0, 2, 0, 2)
	},
	["8x Scope"] = {
		ZoomLevel = 8.0,
		ScopeType = "Magnified",
		FOV = 10,
		UI = false,
		ScopeModel = "8x_Scope",
		Reticle = "rbxassetid://8560915132",
		ReticleSize = UDim2.new(0, 1, 0, 1)
	},
	["Sniper Scope"] = {
		ZoomLevel = 10.0,
		ScopeType = "Magnified",
		FOV = 8,
		UI = false,
		ScopeModel = "Sniper_Scope",
        Reticle = "rbxassetid://109811932735601",
		ReticleSize = UDim2.new(0, 1, 0, 1)
	}
}

local currentWeapon = nil
local currentScope = nil
local isScoped = false
local scopeMode = "3D" -- "3D" or "UI"
local originalFOV = camera.FieldOfView
local breathHolding = false
local weaponSway = {
	x = 0,
	y = 0,
	targetX = 0,
	targetY = 0,
	breathMultiplier = 1
}

local scopeUI = nil
local scopeConnection = nil

function ScopeSystem:Initialize()
	self:SetupScopeUI()
	self:SetupInputHandling()
	self:StartWeaponSway()
	
	print("ScopeSystem initialized")
end

function ScopeSystem:SetupScopeUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	scopeUI = Instance.new("ScreenGui")
	scopeUI.Name = "ScopeOverlay"
	scopeUI.ResetOnSpawn = false
	scopeUI.Enabled = false
	scopeUI.Parent = playerGui
	
	-- Scope lens (circular view)
	local scopeLens = Instance.new("Frame")
	scopeLens.Name = "ScopeLens"
	scopeLens.Size = UDim2.new(0, 400, 0, 400)
	scopeLens.Position = UDim2.new(0.5, -200, 0.5, -200)
	scopeLens.BackgroundColor3 = Color3.new(0, 0, 0)
	scopeLens.BorderSizePixel = 4
	scopeLens.BorderColor3 = Color3.new(0.2, 0.2, 0.2)
	scopeLens.Parent = scopeUI
	
	-- Circular mask
	local scopeCorner = Instance.new("UICorner")
	scopeCorner.CornerRadius = UDim.new(1, 0)
	scopeCorner.Parent = scopeLens
	
	-- Reticle
	local reticle = Instance.new("ImageLabel")
	reticle.Name = "Reticle"
	reticle.Size = UDim2.new(0, 4, 0, 4)
	reticle.Position = UDim2.new(0.5, -2, 0.5, -2)
	reticle.BackgroundTransparency = 1
    reticle.Image = "rbxassetid://58445018"
	reticle.ImageColor3 = Color3.new(1, 0, 0)
	reticle.Parent = scopeLens
	
	-- Black overlay (outside scope)
	local blackOverlay = Instance.new("Frame")
	blackOverlay.Name = "BlackOverlay"
	blackOverlay.Size = UDim2.new(1, 0, 1, 0)
	blackOverlay.Position = UDim2.new(0, 0, 0, 0)
	blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	blackOverlay.BorderSizePixel = 0
	blackOverlay.ZIndex = -1
	blackOverlay.Parent = scopeUI
	
	-- Scope info display
	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "ScopeInfo"
	infoFrame.Size = UDim2.new(0, 200, 0, 60)
	infoFrame.Position = UDim2.new(0, 20, 1, -80)
	infoFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	infoFrame.BackgroundTransparency = 0.3
	infoFrame.BorderSizePixel = 0
	infoFrame.Parent = scopeUI
	
	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 8)
	infoCorner.Parent = infoFrame
	
	local zoomLabel = Instance.new("TextLabel")
	zoomLabel.Name = "ZoomLabel"
	zoomLabel.Size = UDim2.new(1, -10, 0.5, 0)
	zoomLabel.Position = UDim2.new(0, 5, 0, 0)
	zoomLabel.BackgroundTransparency = 1
	zoomLabel.Text = "4.0x"
	zoomLabel.TextColor3 = Color3.new(1, 1, 1)
	zoomLabel.TextScaled = true
	zoomLabel.Font = Enum.Font.SourceSansBold
	zoomLabel.TextXAlignment = Enum.TextXAlignment.Left
	zoomLabel.Parent = infoFrame
	
	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(1, -10, 0.5, 0)
	modeLabel.Position = UDim2.new(0, 5, 0.5, 0)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = "3D Mode (T to toggle)"
	modeLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	modeLabel.TextScaled = true
	modeLabel.Font = Enum.Font.SourceSans
	modeLabel.TextXAlignment = Enum.TextXAlignment.Left
	modeLabel.Parent = infoFrame
end

function ScopeSystem:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.T then
			self:ToggleScopeMode()
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			breathHolding = true
			weaponSway.breathMultiplier = 0.2
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			breathHolding = false
			weaponSway.breathMultiplier = 1.0
		end
	end)
end

function ScopeSystem:StartWeaponSway()
	local swayUpdate = 0
	
	RunService.Heartbeat:Connect(function(dt)
		swayUpdate = swayUpdate + dt
		
		if swayUpdate >= 0.016 then -- ~60 FPS
			self:UpdateWeaponSway(dt)
			swayUpdate = 0
		end
	end)
end

function ScopeSystem:UpdateWeaponSway(deltaTime)
	if not currentWeapon then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Base sway from movement
	local velocity = humanoid.RootPart.Velocity
	local speed = velocity.Magnitude
	local movementSway = math.min(speed / 50, 1) * (isScoped and 2 or 1)
	
	-- Mouse movement sway
	local mouseDelta = UserInputService:GetMouseDelta()
	weaponSway.targetX = weaponSway.targetX + (mouseDelta.X * 0.001 * (isScoped and 3 or 1))
	weaponSway.targetY = weaponSway.targetY + (mouseDelta.Y * 0.001 * (isScoped and 3 or 1))
	
	-- Add random sway
	local randomSway = (isScoped and currentScope and currentScope.ZoomLevel or 1) * 0.1
	weaponSway.targetX = weaponSway.targetX + (math.random() - 0.5) * randomSway * weaponSway.breathMultiplier
	weaponSway.targetY = weaponSway.targetY + (math.random() - 0.5) * randomSway * weaponSway.breathMultiplier
	
	-- Lerp to target
	local lerpSpeed = 5 * deltaTime
	weaponSway.x = weaponSway.x + (weaponSway.targetX - weaponSway.x) * lerpSpeed
	weaponSway.y = weaponSway.y + (weaponSway.targetY - weaponSway.y) * lerpSpeed
	
	-- Decay sway
	weaponSway.targetX = weaponSway.targetX * 0.95
	weaponSway.targetY = weaponSway.targetY * 0.95
	
	-- Clamp sway
	local maxSway = isScoped and 0.02 or 0.005
	weaponSway.x = math.clamp(weaponSway.x, -maxSway, maxSway)
	weaponSway.y = math.clamp(weaponSway.y, -maxSway, maxSway)
	
	-- Apply sway to camera
	if isScoped then
		local currentCFrame = camera.CFrame
		local swayOffset = CFrame.Angles(weaponSway.y, weaponSway.x, 0)
		camera.CFrame = currentCFrame * swayOffset
	end
end

function ScopeSystem:SetWeapon(weapon)
	currentWeapon = weapon
	if weapon then
		local weaponData = WeaponConfig.GetWeaponData(weapon.Name)
		if weaponData and weaponData.Attachments and weaponData.Attachments.Optic then
			currentScope = scopeConfigs[weaponData.Attachments.Optic]
		end
	else
		currentScope = nil
	end
end

function ScopeSystem:ToggleScopeMode()
	if not isScoped then return end
	
	scopeMode = (scopeMode == "3D") and "UI" or "3D"
	
	-- Update UI display
	if scopeUI then
		local modeLabel = scopeUI:FindFirstChild("ScopeInfo"):FindFirstChild("ModeLabel")
		if modeLabel then
			modeLabel.Text = scopeMode .. " Mode (T to toggle)"
		end
		
		-- Toggle UI visibility
		scopeUI.Enabled = (scopeMode == "UI")
	end
	
	print("Scope mode: " .. scopeMode)
end

function ScopeSystem:EnterScope()
	if not currentScope or isScoped then return end
	
	isScoped = true
	
	-- Store original FOV
	originalFOV = camera.FieldOfView
	
	-- Apply scope settings
	local targetFOV = currentScope.FOV
	
	-- Smooth FOV transition
	local fovTween = TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = targetFOV
	})
	fovTween:Play()
	
	-- Setup scope display based on mode
	if scopeMode == "UI" or currentScope.UI then
		scopeUI.Enabled = true
		
		-- Update scope info
		local zoomLabel = scopeUI:FindFirstChild("ScopeInfo"):FindFirstChild("ZoomLabel")
		local modeLabel = scopeUI:FindFirstChild("ScopeInfo"):FindFirstChild("ModeLabel")
		local reticle = scopeUI:FindFirstChild("ScopeLens"):FindFirstChild("Reticle")
		
		if zoomLabel then
			zoomLabel.Text = currentScope.ZoomLevel .. "x"
		end
		if modeLabel then
			modeLabel.Text = scopeMode .. " Mode (T to toggle)"
		end
		if reticle then
			reticle.Size = currentScope.ReticleSize
			reticle.Position = UDim2.new(0.5, -currentScope.ReticleSize.X.Offset/2, 0.5, -currentScope.ReticleSize.Y.Offset/2)
		end
	end
	
	-- Hide weapon viewmodel when scoped
	self:SetViewmodelVisibility(false)
	
	print("Entered scope: " .. (currentScope.ZoomLevel or "Unknown") .. "x")
end

function ScopeSystem:ExitScope()
	if not isScoped then return end
	
	isScoped = false
	
	-- Restore original FOV
	local fovTween = TweenService:Create(camera, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = originalFOV
	})
	fovTween:Play()
	
	-- Hide scope UI
	if scopeUI then
		scopeUI.Enabled = false
	end
	
	-- Show weapon viewmodel
	self:SetViewmodelVisibility(true)
	
	-- Reset weapon sway
	weaponSway.x = 0
	weaponSway.y = 0
	weaponSway.targetX = 0
	weaponSway.targetY = 0
	
	print("Exited scope")
end

function ScopeSystem:SetViewmodelVisibility(visible)
	local character = player.Character
	if not character then return end
	
	-- Hide/show viewmodel arms and weapon
	for _, part in pairs(character:GetChildren()) do
		if part.Name:find("Arm") or part.Name == "ViewmodelRig" then
			part.Transparency = visible and 0 or 1
		end
	end
	
	-- Hide/show current tool
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		for _, part in pairs(tool:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = visible and 0 or 1
			end
		end
	end
end

function ScopeSystem:GetCurrentZoom()
	return currentScope and currentScope.ZoomLevel or 1
end

function ScopeSystem:IsScoped()
	return isScoped
end

function ScopeSystem:GetScopeMode()
	return scopeMode
end

function ScopeSystem:SetScopeMode(mode)
	if mode == "3D" or mode == "UI" then
		scopeMode = mode
		if isScoped then
			-- Refresh scope display
			self:ExitScope()
			wait(0.1)
			self:EnterScope()
		end
	end
end

function ScopeSystem:IsBreathHolding()
	return breathHolding
end

function ScopeSystem:GetWeaponSway()
	return weaponSway
end

-- Integration with weapon system
function ScopeSystem:OnWeaponEquipped(weapon)
	self:SetWeapon(weapon)
end

function ScopeSystem:OnWeaponUnequipped()
	self:ExitScope()
	self:SetWeapon(nil)
end

function ScopeSystem:OnAiming(aiming)
	if aiming and currentScope then
		self:EnterScope()
	elseif not aiming then
		self:ExitScope()
	end
end

-- Console commands for testing
_G.ScopeCommands = {
	setMode = function(mode)
		ScopeSystem:SetScopeMode(mode)
		print("Scope mode set to: " .. mode)
	end,
	
	testScope = function(scopeName)
		if scopeConfigs[scopeName] then
			currentScope = scopeConfigs[scopeName]
			print("Test scope set: " .. scopeName)
		else
			print("Available scopes:")
			for name, _ in pairs(scopeConfigs) do
				print("- " .. name)
			end
		end
	end,
	
	toggleScope = function()
		if isScoped then
			ScopeSystem:ExitScope()
		else
			if currentScope then
				ScopeSystem:EnterScope()
			else
				print("No scope attached")
			end
		end
	end
}

return ScopeSystem