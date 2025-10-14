--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local AttachmentManager = require(ReplicatedStorage.FPSSystem.Modules.AttachmentManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local AttachmentController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local attachmentGui = nil
local currentWeapon = nil
local currentLoadout = {}
local playerData = nil

function AttachmentController:Initialize()
	self:CreateAttachmentGUI()
	self:SetupEventConnections()

	-- Request player data if not loaded
	local playerDataEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("RequestPlayerData")
	if playerDataEvent then
		playerDataEvent:FireServer()
	end

	print("AttachmentController initialized")
end

function AttachmentController:SetupEventConnections()
	-- Listen for attachment data updates
	local attachmentDataUpdated = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AttachmentDataUpdated")
	if attachmentDataUpdated then
		attachmentDataUpdated.OnClientEvent:Connect(function(data)
			self:UpdatePlayerData(data)
		end)
	end

	-- Listen for player data updates
	local playerDataUpdated = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PlayerDataUpdated")
	if playerDataUpdated then
		playerDataUpdated.OnClientEvent:Connect(function(data)
			self:UpdatePlayerData(data)
		end)
	end

	-- No standalone attachment menu - integrated into loadout menu

	-- Listen for equipped weapon changes
	local weaponEquippedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("WeaponEquipped")
	if weaponEquippedEvent then
		weaponEquippedEvent.OnClientEvent:Connect(function(weaponName)
			currentWeapon = weaponName
			if attachmentGui.Enabled then
				self:RefreshAttachmentMenu()
			end
		end)
	end
end

function AttachmentController:CreateAttachmentGUI()
	-- Attachment GUI is now integrated into the loadout menu
	-- This function is kept for backward compatibility but creates a minimal GUI
	attachmentGui = Instance.new("ScreenGui")
	attachmentGui.Name = "AttachmentGUI"
	attachmentGui.Enabled = false
	attachmentGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "AttachmentFrame"
	mainFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
	mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
	mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = attachmentGui
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.08, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "WEAPON ATTACHMENTS"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = mainFrame
	
	-- Weapon selector
	local weaponSelector = Instance.new("Frame")
	weaponSelector.Name = "WeaponSelector"
	weaponSelector.Size = UDim2.new(1, -20, 0.1, 0)
	weaponSelector.Position = UDim2.new(0, 10, 0.08, 10)
	weaponSelector.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	weaponSelector.BorderSizePixel = 0
	weaponSelector.Parent = mainFrame
	
	local weaponLabel = Instance.new("TextLabel")
	weaponLabel.Name = "WeaponLabel"
	weaponLabel.Size = UDim2.new(0.3, 0, 1, 0)
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.Text = "Current Weapon:"
	weaponLabel.TextColor3 = Color3.new(1, 1, 1)
	weaponLabel.TextScaled = true
	weaponLabel.Font = Enum.Font.SourceSans
	weaponLabel.Parent = weaponSelector
	
	local weaponName = Instance.new("TextLabel")
	weaponName.Name = "WeaponName"
	weaponName.Size = UDim2.new(0.7, 0, 1, 0)
	weaponName.Position = UDim2.new(0.3, 0, 0, 0)
	weaponName.BackgroundTransparency = 1
	weaponName.Text = "None Selected"
	weaponName.TextColor3 = Color3.new(0.8, 0.8, 1)
	weaponName.TextScaled = true
	weaponName.Font = Enum.Font.SourceSansBold
	weaponName.Parent = weaponSelector
	
	-- Attachment slots area
	local slotsFrame = Instance.new("Frame")
	slotsFrame.Name = "SlotsFrame"
	slotsFrame.Size = UDim2.new(0.4, -10, 0.75, 0)
	slotsFrame.Position = UDim2.new(0, 10, 0.2, 0)
	slotsFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
	slotsFrame.BorderSizePixel = 0
	slotsFrame.Parent = mainFrame
	
	local slotsTitle = Instance.new("TextLabel")
	slotsTitle.Size = UDim2.new(1, 0, 0.1, 0)
	slotsTitle.BackgroundTransparency = 1
	slotsTitle.Text = "ATTACHMENT SLOTS"
	slotsTitle.TextColor3 = Color3.new(1, 1, 1)
	slotsTitle.TextScaled = true
	slotsTitle.Font = Enum.Font.SourceSansBold
	slotsTitle.Parent = slotsFrame
	
	local slotsScroll = Instance.new("ScrollingFrame")
	slotsScroll.Name = "SlotsScroll"
	slotsScroll.Size = UDim2.new(1, -10, 0.9, -5)
	slotsScroll.Position = UDim2.new(0, 5, 0.1, 5)
	slotsScroll.BackgroundTransparency = 1
	slotsScroll.ScrollBarThickness = 8
	slotsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	slotsScroll.Parent = slotsFrame
	
	-- Available attachments area
	local availableFrame = Instance.new("Frame")
	availableFrame.Name = "AvailableFrame"
	availableFrame.Size = UDim2.new(0.6, -10, 0.75, 0)
	availableFrame.Position = UDim2.new(0.4, 10, 0.2, 0)
	availableFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
	availableFrame.BorderSizePixel = 0
	availableFrame.Parent = mainFrame
	
	local availableTitle = Instance.new("TextLabel")
	availableTitle.Size = UDim2.new(1, 0, 0.1, 0)
	availableTitle.BackgroundTransparency = 1
	availableTitle.Text = "AVAILABLE ATTACHMENTS"
	availableTitle.TextColor3 = Color3.new(1, 1, 1)
	availableTitle.TextScaled = true
	availableTitle.Font = Enum.Font.SourceSansBold
	availableTitle.Parent = availableFrame
	
	local availableScroll = Instance.new("ScrollingFrame")
	availableScroll.Name = "AvailableScroll"
	availableScroll.Size = UDim2.new(1, -10, 0.9, -5)
	availableScroll.Position = UDim2.new(0, 5, 0.1, 5)
	availableScroll.BackgroundTransparency = 1
	availableScroll.ScrollBarThickness = 8
	availableScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	availableScroll.Parent = availableFrame
	
	-- Control buttons
	local controlFrame = Instance.new("Frame")
	controlFrame.Size = UDim2.new(1, 0, 0.06, 0)
	controlFrame.Position = UDim2.new(0, 0, 0.94, 0)
	controlFrame.BackgroundTransparency = 1
	controlFrame.Parent = mainFrame
	
	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.Size = UDim2.new(0.2, -5, 1, 0)
	saveButton.Position = UDim2.new(0.6, 5, 0, 0)
	saveButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
	saveButton.Text = "SAVE LOADOUT"
	saveButton.TextColor3 = Color3.new(1, 1, 1)
	saveButton.TextScaled = true
	saveButton.Font = Enum.Font.SourceSansBold
	saveButton.Parent = controlFrame
	
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.2, -5, 1, 0)
	closeButton.Position = UDim2.new(0.8, 5, 0, 0)
	closeButton.BackgroundColor3 = Color3.new(0.6, 0.2, 0.2)
	closeButton.Text = "CLOSE"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = controlFrame
	
	-- Button connections
	saveButton.MouseButton1Click:Connect(function()
		self:SaveCurrentLoadout()
	end)
	
	closeButton.MouseButton1Click:Connect(function()
		self:CloseAttachmentMenu()
	end)
end

-- Attachment menu functions removed - now integrated into loadout menu
function AttachmentController:ToggleAttachmentMenu()
	warn("AttachmentController: Standalone attachment menu deprecated - use loadout menu instead")
end

function AttachmentController:OpenAttachmentMenu()
	warn("AttachmentController: Standalone attachment menu deprecated - use loadout menu instead")
end

function AttachmentController:CloseAttachmentMenu()
	warn("AttachmentController: Standalone attachment menu deprecated - use loadout menu instead")
end

function AttachmentController:RefreshAttachmentMenu()
	if not currentWeapon then
		attachmentGui.AttachmentFrame.WeaponSelector.WeaponName.Text = "No Weapon Selected"
		return
	end
	
	attachmentGui.AttachmentFrame.WeaponSelector.WeaponName.Text = currentWeapon
	
	self:UpdateSlotDisplay()
	self:UpdateAvailableAttachments()
end

function AttachmentController:UpdateSlotDisplay()
	local slotsScroll = attachmentGui.AttachmentFrame.SlotsFrame.SlotsScroll
	
	-- Clear existing slots
	for _, child in pairs(slotsScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	if not currentWeapon then return end
	
	local availableSlots = AttachmentManager:GetAvailableSlots(currentWeapon)
	local yOffset = 0
	
	for slotName, category in pairs(availableSlots) do
		local slotFrame = Instance.new("Frame")
		slotFrame.Size = UDim2.new(1, -10, 0, 60)
		slotFrame.Position = UDim2.new(0, 5, 0, yOffset)
		slotFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		slotFrame.BorderSizePixel = 1
		slotFrame.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
		slotFrame.Parent = slotsScroll
		
		local slotLabel = Instance.new("TextLabel")
		slotLabel.Size = UDim2.new(1, 0, 0.4, 0)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Text = slotName:upper()
		slotLabel.TextColor3 = Color3.new(1, 1, 1)
		slotLabel.TextScaled = true
		slotLabel.Font = Enum.Font.SourceSansBold
		slotLabel.Parent = slotFrame
		
		local attachmentLabel = Instance.new("TextLabel")
		attachmentLabel.Name = "AttachmentLabel"
		attachmentLabel.Size = UDim2.new(1, -10, 0.6, 0)
		attachmentLabel.Position = UDim2.new(0, 5, 0.4, 0)
		attachmentLabel.BackgroundTransparency = 1
		attachmentLabel.Text = self:GetEquippedAttachmentForSlot(slotName, category) or "None"
		attachmentLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		attachmentLabel.TextScaled = true
		attachmentLabel.Font = Enum.Font.SourceSans
		attachmentLabel.Parent = slotFrame
		
		-- Store slot info
		slotFrame:SetAttribute("SlotName", slotName)
		slotFrame:SetAttribute("Category", category)
		
		yOffset = yOffset + 70
	end
	
	slotsScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function AttachmentController:UpdateAvailableAttachments()
	local availableScroll = attachmentGui.AttachmentFrame.AvailableFrame.AvailableScroll
	
	-- Clear existing attachments
	for _, child in pairs(availableScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	if not currentWeapon then return end
	
	local yOffset = 0
	
	-- Group by category
	local categories = {"Sights", "Barrels", "Underbarrel", "Other"}
	
	for _, category in pairs(categories) do
		local attachments = AttachmentManager:GetAttachmentsByCategory(category)
		local hasValidAttachments = false
		
		for attachmentName, config in pairs(attachments) do
			if AttachmentManager:CanAttachToWeapon(currentWeapon, attachmentName) and self:PlayerOwnsAttachment(attachmentName) then
				hasValidAttachments = true
				break
			end
		end
		
		if hasValidAttachments then
			-- Category header
			local categoryFrame = Instance.new("Frame")
			categoryFrame.Size = UDim2.new(1, -10, 0, 30)
			categoryFrame.Position = UDim2.new(0, 5, 0, yOffset)
			categoryFrame.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
			categoryFrame.Parent = availableScroll
			
			local categoryLabel = Instance.new("TextLabel")
			categoryLabel.Size = UDim2.new(1, 0, 1, 0)
			categoryLabel.BackgroundTransparency = 1
			categoryLabel.Text = category:upper()
			categoryLabel.TextColor3 = Color3.new(1, 1, 1)
			categoryLabel.TextScaled = true
			categoryLabel.Font = Enum.Font.SourceSansBold
			categoryLabel.Parent = categoryFrame
			
			yOffset = yOffset + 35
			
			-- Attachments in category
			for attachmentName, config in pairs(attachments) do
				if AttachmentManager:CanAttachToWeapon(currentWeapon, attachmentName) and self:PlayerOwnsAttachment(attachmentName) then
					local attachmentFrame = Instance.new("TextButton")
					attachmentFrame.Size = UDim2.new(1, -10, 0, 50)
					attachmentFrame.Position = UDim2.new(0, 5, 0, yOffset)
					attachmentFrame.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
					attachmentFrame.Text = ""
					attachmentFrame.Parent = availableScroll
					
					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(1, -10, 0.6, 0)
					nameLabel.Position = UDim2.new(0, 5, 0, 0)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Text = config.Name
					nameLabel.TextColor3 = Color3.new(1, 1, 1)
					nameLabel.TextScaled = true
					nameLabel.Font = Enum.Font.SourceSans
					nameLabel.Parent = attachmentFrame
					
					local descLabel = Instance.new("TextLabel")
					descLabel.Size = UDim2.new(1, -10, 0.4, 0)
					descLabel.Position = UDim2.new(0, 5, 0.6, 0)
					descLabel.BackgroundTransparency = 1
					descLabel.Text = config.Description
					descLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
					descLabel.TextScaled = true
					descLabel.Font = Enum.Font.SourceSans
					descLabel.Parent = attachmentFrame
					
					attachmentFrame.MouseButton1Click:Connect(function()
						self:EquipAttachment(attachmentName)
					end)
					
					yOffset = yOffset + 55
				end
			end
		end
	end
	
	availableScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function AttachmentController:GetEquippedAttachmentForSlot(slotName, category)
	-- Return currently equipped attachment for this slot
	for _, attachmentName in pairs(currentLoadout) do
		local config = AttachmentManager:GetAttachmentConfig(attachmentName)
		if config and config.Category == category then
			return config.Name
		end
	end
	return nil
end

function AttachmentController:EquipAttachment(attachmentName)
	local config = AttachmentManager:GetAttachmentConfig(attachmentName)
	if not config then return end
	
	-- Remove any existing attachment from the same category
	for i = #currentLoadout, 1, -1 do
		local existingConfig = AttachmentManager:GetAttachmentConfig(currentLoadout[i])
		if existingConfig and existingConfig.Category == config.Category then
			table.remove(currentLoadout, i)
		end
	end
	
	-- Add new attachment
	table.insert(currentLoadout, attachmentName)
	
	-- Refresh displays
	self:UpdateSlotDisplay()
end

function AttachmentController:SaveCurrentLoadout()
	if not currentWeapon then
		return
	end

	local valid, errorMessage = AttachmentManager:ValidateLoadout(currentWeapon, currentLoadout)
	if not valid then
		print("Invalid loadout: " .. errorMessage)
		return
	end

	-- Send to server
	local saveWeaponLoadoutEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SaveWeaponLoadout")
	if saveWeaponLoadoutEvent then
		saveWeaponLoadoutEvent:FireServer({
			WeaponName = currentWeapon,
			Attachments = currentLoadout
		})
	end

	print("Saved loadout for " .. currentWeapon)
end

function AttachmentController:PlayerOwnsAttachment(attachmentName)
	-- Check if player owns this attachment
	if not playerData or not currentWeapon then return false end
	
	-- Try multiple data structure paths for compatibility
	local unlockedAttachments = playerData.UnlockedAttachments
	
	-- Fallback to nested structure if primary doesn't exist
	if not unlockedAttachments and playerData.Unlocks then
		unlockedAttachments = playerData.Unlocks.Attachments
	end
	
	-- If still no attachments data, return false
	if not unlockedAttachments or type(unlockedAttachments) ~= "table" then 
		return false 
	end
	
	-- Safe access to weapon attachment table
	local weaponAttachments = unlockedAttachments[currentWeapon]
	if not weaponAttachments or type(weaponAttachments) ~= "table" then 
		-- Initialize empty attachment list for this weapon if it doesn't exist
		if type(unlockedAttachments) == "table" then
			unlockedAttachments[currentWeapon] = {}
		end
		return false 
	end
	
	return table.find(weaponAttachments, attachmentName) ~= nil
end

function AttachmentController:UpdatePlayerData(data)
	playerData = data
	
	-- Ensure player data has the required structure
	if playerData and not playerData.UnlockedAttachments then
		if playerData.Unlocks and playerData.Unlocks.Attachments then
			-- Use the nested structure as the primary one
			playerData.UnlockedAttachments = playerData.Unlocks.Attachments
		else
			-- Initialize empty attachment structure
			playerData.UnlockedAttachments = {}
		end
	end
	
	if attachmentGui and attachmentGui.Enabled then
		self:RefreshAttachmentMenu()
	end
	
	print("Player data updated in AttachmentController")
end

-- Console commands for testing
_G.AttachmentCommands = {
	openMenu = function()
		AttachmentController:OpenAttachmentMenu()
	end,
	
	setWeapon = function(weaponName)
		currentWeapon = weaponName
		AttachmentController:RefreshAttachmentMenu()
		print("Set current weapon to: " .. weaponName)
	end,
	
	testLoadout = function(weaponName)
		currentWeapon = weaponName
		currentLoadout = {"RedDotSight", "Suppressor", "VerticalGrip"}
		AttachmentController:RefreshAttachmentMenu()
		print("Set test loadout for " .. weaponName)
	end
}

AttachmentController:Initialize()

return AttachmentController