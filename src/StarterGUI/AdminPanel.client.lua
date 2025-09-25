--[[
	AdminPanel.client.lua
	Sliding admin panel with horror lighting, sound system, bounty controls, and admin tools
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for FPS System to load
repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AdminPanel = {}

-- Panel state
local isPanelOpen = false
local isHorrorLighting = false
local currentSoundId = ""
local panelGui = nil
local isPlayerAdmin = false

-- Bounty system state
local bountyToggleEnabled = true

function AdminPanel:CreateAdminPanelUI()
	-- Create ScreenGui
	panelGui = Instance.new("ScreenGui")
	panelGui.Name = "AdminPanel"
	panelGui.ResetOnSpawn = false
	panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Arrow Button (Top-right corner trigger)
	local arrowButton = Instance.new("ImageButton")
	arrowButton.Name = "ArrowButton"
	arrowButton.Size = UDim2.fromOffset(40, 40)
	arrowButton.Position = UDim2.new(1, -50, 0, 10)
	arrowButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	arrowButton.BackgroundTransparency = 0.3
	arrowButton.BorderSizePixel = 0
	arrowButton.Image = "rbxassetid://14255292906" -- Right arrow placeholder
	arrowButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	arrowButton.Parent = panelGui

	local arrowCorner = Instance.new("UICorner")
	arrowCorner.CornerRadius = UDim.new(0, 8)
	arrowCorner.Parent = arrowButton

	-- Main Panel (initially hidden off-screen)
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.fromOffset(350, 500)
	mainPanel.Position = UDim2.new(1, 0, 0, 60) -- Off-screen to the right
	mainPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	mainPanel.BorderSizePixel = 0
	mainPanel.Parent = panelGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 15)
	panelCorner.Parent = mainPanel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(80, 120, 200)
	panelStroke.Thickness = 2
	panelStroke.Transparency = 0.3
	panelStroke.Parent = mainPanel

	-- Panel Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.Position = UDim2.fromScale(0, 0)
	header.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
	header.BorderSizePixel = 0
	header.Parent = mainPanel

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 15)
	headerCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(0.8, 1)
	title.Position = UDim2.fromScale(0.1, 0)
	title.BackgroundTransparency = 1
	title.Text = "ADMIN PANEL"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = header

	-- Scroll Frame for content
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollContent"
	scrollFrame.Size = UDim2.new(1, -20, 1, -80)
	scrollFrame.Position = UDim2.fromOffset(10, 70)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 200)
	scrollFrame.Parent = mainPanel

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 10)
	contentLayout.Parent = scrollFrame

	-- Admin Tools Sections
	self:CreateLightingSection(scrollFrame)
	self:CreateSoundSection(scrollFrame)
	self:CreateBountySection(scrollFrame)
	self:CreateVehicleSection(scrollFrame)
	self:CreatePlayerManagementSection(scrollFrame)

	-- Panel functionality
	arrowButton.MouseButton1Click:Connect(function()
		self:TogglePanel()
	end)

	panelGui.Parent = playerGui
	return panelGui
end

function AdminPanel:CreateLightingSection(parent)
	local section = self:CreateSection(parent, "LIGHTING CONTROLS", 1)

	-- Horror Lighting Toggle
	local horrorToggle = self:CreateToggleButton(section, "Horror Lighting", function(enabled)
		self:ToggleHorrorLighting(enabled)
	end)

	-- Brightness Slider
	local brightnessSlider = self:CreateSlider(section, "Brightness", 0, 3, 1, function(value)
		Lighting.Brightness = value
	end)

	-- Ambient Color Picker (simplified)
	local ambientButton = self:CreateActionButton(section, "Dark Red Ambient", function()
		Lighting.Ambient = Color3.fromRGB(80, 20, 20)
		Lighting.OutdoorAmbient = Color3.fromRGB(60, 15, 15)
	end)

	-- Reset Lighting
	local resetButton = self:CreateActionButton(section, "Reset Lighting", function()
		self:ResetLighting()
	end)
end

function AdminPanel:CreateSoundSection(parent)
	local section = self:CreateSection(parent, "GLOBAL SOUND SYSTEM", 2)

	-- Sound ID Input
	local soundInput = Instance.new("TextBox")
	soundInput.Name = "SoundInput"
	soundInput.Size = UDim2.new(1, -20, 0, 35)
	soundInput.Position = UDim2.fromOffset(10, 10)
	soundInput.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
	soundInput.BorderSizePixel = 0
	soundInput.Text = "Enter Sound ID..."
	soundInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	soundInput.TextScaled = true
	soundInput.Font = Enum.Font.Gotham
	soundInput.Parent = section

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = soundInput

	-- Play Sound Button
	local playButton = self:CreateActionButton(section, "Play Global Sound", function()
		local soundId = soundInput.Text
		if soundId and soundId ~= "Enter Sound ID..." and tonumber(soundId) then
			self:PlayGlobalSound(soundId)
		end
	end)

	-- Stop Sound Button
	local stopButton = self:CreateActionButton(section, "Stop All Sounds", function()
		self:StopGlobalSounds()
	end)

	-- Volume Slider
	local volumeSlider = self:CreateSlider(section, "Volume", 0, 1, 0.5, function(value)
		SoundService.AmbientReverb = Enum.ReverbType.NoReverb
		-- Apply volume to current playing sounds
		for _, sound in pairs(workspace:GetDescendants()) do
			if sound:IsA("Sound") and sound.Name == "GlobalAdminSound" then
				sound.Volume = value
			end
		end
	end)
end

function AdminPanel:CreateBountySection(parent)
	local section = self:CreateSection(parent, "BOUNTY SYSTEM", 3)

	-- Bounty Toggle (B key alternative)
	local bountyToggle = self:CreateToggleButton(section, "Enable B Key Toggle", function(enabled)
		bountyToggleEnabled = enabled
	end)

	-- Open Bounty System
	local openBountyButton = self:CreateActionButton(section, "Open Bounty System", function()
		RemoteEventsManager:FireServer("OpenBountySystem")
	end)

	-- Clear All Bounties
	local clearBountiesButton = self:CreateActionButton(section, "Clear All Bounties", function()
		RemoteEventsManager:FireServer("ClearAllBounties")
	end)

	-- Reset Bounty UI (fix stuck UI bug)
	local resetUIButton = self:CreateActionButton(section, "Reset Bounty UI", function()
		RemoteEventsManager:FireServer("ResetBountyUI")
	end)
end

function AdminPanel:CreateVehicleSection(parent)
	local section = self:CreateSection(parent, "VEHICLE CONTROLS", 4)

	-- Spawn Tank
	local spawnTankButton = self:CreateActionButton(section, "Spawn Test Tank", function()
		if player.Character and player.Character.PrimaryPart then
			local position = player.Character.PrimaryPart.Position + Vector3.new(10, 5, 0)
			RemoteEventsManager:FireServer("SpawnVehicle", "Tank", position)
		end
	end)

	-- Spawn Helicopter
	local spawnHeliButton = self:CreateActionButton(section, "Spawn Test Helicopter", function()
		if player.Character and player.Character.PrimaryPart then
			local position = player.Character.PrimaryPart.Position + Vector3.new(0, 15, 10)
			RemoteEventsManager:FireServer("SpawnVehicle", "Helicopter", position)
		end
	end)

	-- Clear Vehicles
	local clearVehiclesButton = self:CreateActionButton(section, "Clear All Vehicles", function()
		RemoteEventsManager:FireServer("ClearVehicles")
	end)
end

function AdminPanel:CreatePlayerManagementSection(parent)
	local section = self:CreateSection(parent, "PLAYER MANAGEMENT", 5)

	-- Player List for targeting
	local playerList = Instance.new("ScrollingFrame")
	playerList.Name = "PlayerList"
	playerList.Size = UDim2.new(1, -20, 0, 100)
	playerList.Position = UDim2.fromOffset(10, 10)
	playerList.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
	playerList.BorderSizePixel = 0
	playerList.ScrollBarThickness = 4
	playerList.Parent = section

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = playerList

	-- Populate player list
	self:UpdatePlayerList(playerList)

	-- Admin Actions
	local kickButton = self:CreateActionButton(section, "Kick Selected Player", function()
		-- Implementation for kicking selected player
	end)

	local changeTeamButton = self:CreateActionButton(section, "Force Team Change", function()
		-- Implementation for team change
	end)
end

-- Helper functions for creating UI elements
function AdminPanel:CreateSection(parent, title, layoutOrder)
	local section = Instance.new("Frame")
	section.Name = title:gsub(" ", "") .. "Section"
	section.Size = UDim2.new(1, 0, 0, 200) -- Will auto-resize with content
	section.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
	section.BorderSizePixel = 0
	section.LayoutOrder = layoutOrder
	section.Parent = parent

	local sectionCorner = Instance.new("UICorner")
	sectionCorner.CornerRadius = UDim.new(0, 10)
	sectionCorner.Parent = section

	-- Section header
	local header = Instance.new("TextLabel")
	header.Name = "SectionHeader"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.Position = UDim2.fromScale(0, 0)
	header.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
	header.BorderSizePixel = 0
	header.Text = title
	header.TextColor3 = Color3.fromRGB(200, 220, 255)
	header.TextScaled = true
	header.Font = Enum.Font.GothamBold
	header.Parent = section

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = header

	-- Content layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = section

	-- Auto-resize section based on content
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		section.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)

	return section
end

function AdminPanel:CreateActionButton(parent, text, callback)
	local button = Instance.new("TextButton")
	button.Name = text:gsub(" ", "") .. "Button"
	button.Size = UDim2.new(1, -20, 0, 35)
	button.Position = UDim2.fromOffset(10, 0)
	button.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = parent

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	button.MouseButton1Click:Connect(callback)
	return button
end

function AdminPanel:CreateToggleButton(parent, text, callback)
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Name = text:gsub(" ", "") .. "Toggle"
	toggleFrame.Size = UDim2.new(1, -20, 0, 35)
	toggleFrame.Position = UDim2.fromOffset(10, 0)
	toggleFrame.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
	toggleFrame.BorderSizePixel = 0
	toggleFrame.Parent = parent

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = toggleFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.7, 1)
	label.Position = UDim2.fromScale(0.05, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggleFrame

	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.fromScale(0.2, 0.8)
	toggleButton.Position = UDim2.fromScale(0.75, 0.1)
	toggleButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "OFF"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Parent = toggleFrame

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 5)
	toggleCorner.Parent = toggleButton

	local isEnabled = false
	toggleButton.MouseButton1Click:Connect(function()
		isEnabled = not isEnabled
		toggleButton.BackgroundColor3 = isEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(180, 60, 60)
		toggleButton.Text = isEnabled and "ON" or "OFF"
		callback(isEnabled)
	end)

	return toggleFrame
end

function AdminPanel:CreateSlider(parent, text, min, max, default, callback)
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Name = text:gsub(" ", "") .. "Slider"
	sliderFrame.Size = UDim2.new(1, -20, 0, 50)
	sliderFrame.Position = UDim2.fromOffset(10, 0)
	sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
	sliderFrame.BorderSizePixel = 0
	sliderFrame.Parent = parent

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = sliderFrame

	-- Slider implementation would go here
	-- For brevity, creating a simplified version

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 25)
	label.Position = UDim2.fromScale(0, 0)
	label.BackgroundTransparency = 1
	label.Text = text .. ": " .. tostring(default)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Parent = sliderFrame

	return sliderFrame
end

-- Main functionality
function AdminPanel:TogglePanel()
	local arrow = panelGui.ArrowButton
	local panel = panelGui.MainPanel

	if isPanelOpen then
		-- Close panel
		local slideTween = TweenService:Create(panel,
			TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Position = UDim2.new(1, 0, 0, 60)}
		)

		local arrowTween = TweenService:Create(arrow,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Rotation = 0}
		)

		slideTween:Play()
		arrowTween:Play()
		isPanelOpen = false
	else
		-- Open panel
		local slideTween = TweenService:Create(panel,
			TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Position = UDim2.new(1, -360, 0, 60)}
		)

		local arrowTween = TweenService:Create(arrow,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Rotation = 180}
		)

		slideTween:Play()
		arrowTween:Play()
		isPanelOpen = true
	end
end

function AdminPanel:ToggleHorrorLighting(enabled)
	if enabled then
		-- Apply horror lighting
		Lighting.Brightness = 0.5
		Lighting.Ambient = Color3.fromRGB(80, 20, 20)
		Lighting.OutdoorAmbient = Color3.fromRGB(60, 15, 15)
		Lighting.ColorShift_Bottom = Color3.fromRGB(100, 30, 30)
		Lighting.ColorShift_Top = Color3.fromRGB(80, 20, 20)

		-- Add fog for atmosphere
		Lighting.FogEnd = 500
		Lighting.FogStart = 100
		Lighting.FogColor = Color3.fromRGB(40, 10, 10)

		isHorrorLighting = true
	else
		self:ResetLighting()
		isHorrorLighting = false
	end
end

function AdminPanel:ResetLighting()
	-- Reset to default lighting
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(127, 127, 127)
	Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0
	Lighting.FogColor = Color3.fromRGB(192, 192, 192)
end

function AdminPanel:PlayGlobalSound(soundId)
	-- Stop existing sounds first
	self:StopGlobalSounds()

	-- Create and play new sound
	local sound = Instance.new("Sound")
	sound.Name = "GlobalAdminSound"
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = 0.5
	sound.Looped = false
	sound.Parent = workspace

	sound:Play()
	currentSoundId = soundId

	-- Notify all clients
	RemoteEventsManager:FireServer("PlayGlobalSound", soundId)
end

function AdminPanel:StopGlobalSounds()
	-- Stop all global admin sounds
	for _, sound in pairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") and sound.Name == "GlobalAdminSound" then
			sound:Stop()
			sound:Destroy()
		end
	end

	RemoteEventsManager:FireServer("StopGlobalSounds")
end

function AdminPanel:UpdatePlayerList(playerList)
	-- Clear existing items
	for _, child in pairs(playerList:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	-- Add current players
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local playerButton = Instance.new("TextButton")
			playerButton.Name = otherPlayer.Name
			playerButton.Size = UDim2.new(1, 0, 0, 25)
			playerButton.BackgroundColor3 = Color3.fromRGB(50, 60, 75)
			playerButton.BorderSizePixel = 0
			playerButton.Text = otherPlayer.Name
			playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			playerButton.TextScaled = true
			playerButton.Font = Enum.Font.Gotham
			playerButton.Parent = playerList

			-- Selection highlighting would go here
		end
	end

	-- Update canvas size
	local layout = playerList:FindFirstChild("UIListLayout")
	if layout then
		playerList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end
end

function AdminPanel:Initialize()
	-- Check if player is admin
	isPlayerAdmin = RemoteEventsManager:InvokeServer("IsPlayerAdmin")

	if not isPlayerAdmin then
		warn("AdminPanel: Player is not admin, panel will not be created")
		return
	end

	-- Initialize remote events
	RemoteEventsManager:Initialize()

	-- Create the panel UI
	self:CreateAdminPanelUI()

	-- Handle bounty system B key toggle
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.B and bountyToggleEnabled then
			RemoteEventsManager:FireServer("ToggleBountySystem")
		end
	end)

	print("AdminPanel: Initialized for admin user")
end

-- Auto-initialize
AdminPanel:Initialize()

return AdminPanel