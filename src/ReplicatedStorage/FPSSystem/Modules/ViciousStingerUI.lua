--[[
	ViciousStingerUI Module
	Handles custom UI for the Vicious Stinger weapon
	Displays:
	- Vicious Meter (0-100)
	- Ability cooldowns (Vicious Overdrive, Honey Fog, Earthquake)
	- Blood Frenzy heal indicators
	- Background particle effects (honey fog)
]]

local ViciousStingerUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI state
local uiScreenGui = nil
local meterFrame = nil
local meterFill = nil
local meterText = nil
local cooldownFrames = {}
local particleBackground = nil

-- Ability configurations
local ABILITIES = {
	ViciousOverdrive = {
		Name = "Vicious Overdrive",
		Key = "G",
		Cooldown = 45,
		Color = Color3.fromRGB(255, 50, 50),
		Description = "Ultimate Attack"
	},
	HoneyFog = {
		Key = "T",
		Cooldown = 25,
		Color = Color3.fromRGB(255, 200, 50),
		Description = "Honey Fog"
	},
	Earthquake = {
		Key = "R",
		Cooldown = 30,
		Color = Color3.fromRGB(150, 100, 50),
		Description = "Earthquake"
	}
}

-- Current state
local currentMeter = 0
local cooldowns = {
	ViciousOverdrive = 0,
	HoneyFog = 0,
	Earthquake = 0
}

function ViciousStingerUI:Initialize()
	print("ViciousStingerUI: Initializing...")
	self:CreateUI()
	self:StartCooldownUpdates()
	print("ViciousStingerUI: Initialized")
end

function ViciousStingerUI:CreateUI()
	-- Create ScreenGui
	uiScreenGui = Instance.new("ScreenGui")
	uiScreenGui.Name = "ViciousStingerUI"
	uiScreenGui.ResetOnSpawn = false
	uiScreenGui.DisplayOrder = 15
	uiScreenGui.IgnoreGuiInset = true
	uiScreenGui.Enabled = false -- Hidden by default
	uiScreenGui.Parent = playerGui

	-- Main container (bottom center)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 400, 0, 150)
	container.Position = UDim2.new(0.5, -200, 1, -170)
	container.BackgroundTransparency = 1
	container.Parent = uiScreenGui

	-- Create Vicious Meter
	self:CreateViciousMeter(container)

	-- Create Ability Cooldown Indicators
	self:CreateAbilityCooldowns(container)

	print("ViciousStingerUI: UI created successfully")
end

function ViciousStingerUI:CreateViciousMeter(parent)
	-- Meter frame
	meterFrame = Instance.new("Frame")
	meterFrame.Name = "MeterFrame"
	meterFrame.Size = UDim2.new(1, 0, 0, 50)
	meterFrame.Position = UDim2.new(0, 0, 0, 0)
	meterFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	meterFrame.BackgroundTransparency = 0.3
	meterFrame.BorderSizePixel = 0
	meterFrame.Parent = parent

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = meterFrame

	-- Particle background effect (to be populated with UIParticles)
	particleBackground = Instance.new("Frame")
	particleBackground.Name = "ParticleBackground"
	particleBackground.Size = UDim2.new(1, 0, 1, 0)
	particleBackground.Position = UDim2.new(0, 0, 0, 0)
	particleBackground.BackgroundTransparency = 1
	particleBackground.ZIndex = 1
	particleBackground.Parent = meterFrame

	-- Meter fill (animated)
	meterFill = Instance.new("Frame")
	meterFill.Name = "MeterFill"
	meterFill.Size = UDim2.new(0, 0, 1, -8)
	meterFill.Position = UDim2.new(0, 4, 0, 4)
	meterFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50) -- Honey gold color
	meterFill.BorderSizePixel = 0
	meterFill.ZIndex = 2
	meterFill.Parent = meterFrame

	-- Rounded corners for fill
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = meterFill

	-- Gradient effect on fill
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 50))
	}
	gradient.Rotation = 90
	gradient.Parent = meterFill

	-- Meter text
	meterText = Instance.new("TextLabel")
	meterText.Name = "MeterText"
	meterText.Size = UDim2.new(1, 0, 1, 0)
	meterText.Position = UDim2.new(0, 0, 0, 0)
	meterText.BackgroundTransparency = 1
	meterText.Text = "VICIOUS METER: 0%"
	meterText.TextColor3 = Color3.fromRGB(255, 255, 255)
	meterText.Font = Enum.Font.GothamBold
	meterText.TextSize = 18
	meterText.ZIndex = 3
	meterText.Parent = meterFrame

	-- Add glow effect to text
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(0, 0, 0)
	textStroke.Thickness = 2
	textStroke.Parent = meterText
end

function ViciousStingerUI:CreateAbilityCooldowns(parent)
	-- Abilities container (below meter)
	local abilitiesContainer = Instance.new("Frame")
	abilitiesContainer.Name = "AbilitiesContainer"
	abilitiesContainer.Size = UDim2.new(1, 0, 0, 80)
	abilitiesContainer.Position = UDim2.new(0, 0, 0, 60)
	abilitiesContainer.BackgroundTransparency = 1
	abilitiesContainer.Parent = parent

	-- UI Layout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 15)
	layout.Parent = abilitiesContainer

	-- Create cooldown indicators for each ability
	for abilityName, abilityData in pairs(ABILITIES) do
		local abilityFrame = self:CreateAbilityFrame(abilityName, abilityData)
		abilityFrame.Parent = abilitiesContainer
		cooldownFrames[abilityName] = abilityFrame
	end
end

function ViciousStingerUI:CreateAbilityFrame(abilityName, abilityData)
	-- Ability frame
	local frame = Instance.new("Frame")
	frame.Name = abilityName .. "Frame"
	frame.Size = UDim2.new(0, 110, 0, 80)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	-- Ability name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "AbilityName"
	nameLabel.Size = UDim2.new(1, -8, 0, 20)
	nameLabel.Position = UDim2.new(0, 4, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = abilityData.Description or abilityName
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextSize = 12
	nameLabel.TextScaled = true
	nameLabel.Parent = frame

	-- Key indicator
	local keyFrame = Instance.new("Frame")
	keyFrame.Name = "KeyFrame"
	keyFrame.Size = UDim2.new(0, 30, 0, 30)
	keyFrame.Position = UDim2.new(0.5, -15, 0, 28)
	keyFrame.BackgroundColor3 = abilityData.Color
	keyFrame.BorderSizePixel = 0
	keyFrame.Parent = frame

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 6)
	keyCorner.Parent = keyFrame

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.Size = UDim2.new(1, 0, 1, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = abilityData.Key
	keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.TextSize = 16
	keyLabel.Parent = keyFrame

	-- Cooldown text
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, -8, 0, 16)
	cooldownText.Position = UDim2.new(0, 4, 1, -20)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Text = "READY"
	cooldownText.TextColor3 = Color3.fromRGB(100, 255, 100)
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.TextSize = 12
	cooldownText.TextScaled = true
	cooldownText.Parent = frame

	-- Cooldown overlay (covers frame when on cooldown)
	local cooldownOverlay = Instance.new("Frame")
	cooldownOverlay.Name = "CooldownOverlay"
	cooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
	cooldownOverlay.Position = UDim2.new(0, 0, 1, 0)
	cooldownOverlay.AnchorPoint = Vector2.new(0, 1)
	cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cooldownOverlay.BackgroundTransparency = 0.6
	cooldownOverlay.BorderSizePixel = 0
	cooldownOverlay.ZIndex = 10
	cooldownOverlay.Parent = frame

	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 8)
	overlayCorner.Parent = cooldownOverlay

	return frame
end

-- Update meter display
function ViciousStingerUI:UpdateMeter(meterValue)
	currentMeter = math.clamp(meterValue, 0, 100)

	-- Update fill size with animation
	local fillSize = UDim2.new(currentMeter / 100, -8, 1, -8)
	local tween = TweenService:Create(meterFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = fillSize
	})
	tween:Play()

	-- Update text
	meterText.Text = string.format("VICIOUS METER: %d%%", currentMeter)

	-- Change color based on meter level
	if currentMeter >= 100 then
		meterFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red when full
		meterText.TextColor3 = Color3.fromRGB(255, 255, 100)

		-- Pulse effect when full
		self:PulseMeter()
	else
		meterFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50) -- Gold when filling
		meterText.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

-- Pulse animation when meter is full
function ViciousStingerUI:PulseMeter()
	if currentMeter < 100 then return end

	local pulseTween = TweenService:Create(meterFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Size = UDim2.new(1, 10, 0, 55)
	})
	pulseTween:Play()

	spawn(function()
		wait(2)
		pulseTween:Cancel()
		meterFrame.Size = UDim2.new(1, 0, 0, 50)
	end)
end

-- Start a cooldown for an ability
function ViciousStingerUI:StartCooldown(abilityName, cooldownTime)
	if not cooldownFrames[abilityName] then return end

	cooldowns[abilityName] = cooldownTime

	local frame = cooldownFrames[abilityName]
	local cooldownText = frame:FindFirstChild("CooldownText")
	local cooldownOverlay = frame:FindFirstChild("CooldownOverlay")

	if cooldownText then
		cooldownText.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	-- Animate overlay from bottom to top
	if cooldownOverlay then
		cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)

		local tween = TweenService:Create(cooldownOverlay, TweenInfo.new(cooldownTime, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 0, 0)
		})
		tween:Play()
	end
end

-- Update cooldown displays
function ViciousStingerUI:StartCooldownUpdates()
	RunService.Heartbeat:Connect(function(deltaTime)
		for abilityName, timeRemaining in pairs(cooldowns) do
			if timeRemaining > 0 then
				cooldowns[abilityName] = math.max(0, timeRemaining - deltaTime)

				local frame = cooldownFrames[abilityName]
				if frame then
					local cooldownText = frame:FindFirstChild("CooldownText")
					if cooldownText then
						if cooldowns[abilityName] > 0 then
							cooldownText.Text = string.format("%.1fs", cooldowns[abilityName])
							cooldownText.TextColor3 = Color3.fromRGB(255, 100, 100)
						else
							cooldownText.Text = "READY"
							cooldownText.TextColor3 = Color3.fromRGB(100, 255, 100)
						end
					end
				end
			end
		end
	end)
end

-- Show heal indicator (Blood Frenzy)
function ViciousStingerUI:ShowHealIndicator(healAmount)
	if not uiScreenGui then return end

	-- Create floating heal text
	local healText = Instance.new("TextLabel")
	healText.Size = UDim2.new(0, 100, 0, 30)
	healText.Position = UDim2.new(0.5, -50, 0.7, 0)
	healText.BackgroundTransparency = 1
	healText.Text = "+" .. math.floor(healAmount) .. " HP"
	healText.TextColor3 = Color3.fromRGB(100, 255, 100)
	healText.Font = Enum.Font.GothamBold
	healText.TextSize = 24
	healText.TextStrokeTransparency = 0.5
	healText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	healText.Parent = uiScreenGui

	-- Animate up and fade out
	local tween1 = TweenService:Create(healText, TweenInfo.new(1, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0.5, -50, 0.6, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})
	tween1:Play()

	tween1.Completed:Connect(function()
		healText:Destroy()
	end)
end

-- Show/Hide UI
function ViciousStingerUI:Show()
	if uiScreenGui then
		uiScreenGui.Enabled = true
		print("ViciousStingerUI: Shown")
	end
end

function ViciousStingerUI:Hide()
	if uiScreenGui then
		uiScreenGui.Enabled = false
		print("ViciousStingerUI: Hidden")
	end
end

-- Get particle background frame for UIParticles integration
function ViciousStingerUI:GetParticleBackground()
	return particleBackground
end

-- Cleanup
function ViciousStingerUI:Destroy()
	if uiScreenGui then
		uiScreenGui:Destroy()
		uiScreenGui = nil
	end

	cooldownFrames = {}
	print("ViciousStingerUI: Destroyed")
end

return ViciousStingerUI
