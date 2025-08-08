-- LoadoutSelector.client.lua
-- Simple loadout selection system for testing and configuration
-- Place in StarterPlayerScripts

local LoadoutSelector = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Loadout configuration
local availableLoadouts = {
	["Assault"] = {
		PRIMARY = "G36",
		SECONDARY = "M9",
		MELEE = "PocketKnife",
		GRENADE = "M67"
	},
	["Sniper"] = {
		PRIMARY = "AWP",
		SECONDARY = "M9", 
		MELEE = "PocketKnife",
		GRENADE = "M67"
	},
	["Anti-Material"] = {
		PRIMARY = "NTW20",
		SECONDARY = "M9",
		MELEE = "PocketKnife",
		GRENADE = "M67"
	},
	["Chaos"] = {
		PRIMARY = "NTW20_Chaos", -- Admin only
		SECONDARY = "M9",
		MELEE = "PocketKnife", 
		GRENADE = "M67"
	}
}

-- Available weapons by category
local availableWeapons = {
	PRIMARY = {"G36", "AWP", "NTW20", "NTW20_Chaos"},
	SECONDARY = {"M9"},
	MELEE = {"PocketKnife"},
	GRENADE = {"M67", "FragGrenade", "ImpactGrenade", "Flashbang", "SmokeGrenade"}
}

-- Create the loadout selection interface
function LoadoutSelector:createLoadoutGUI()
	-- Create main GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadoutSelector"
	screenGui.DisplayOrder = 100
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Loadout Selector"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 4)
	closeCorner.Parent = closeButton
	
	-- Preset loadouts section
	local presetsLabel = Instance.new("TextLabel")
	presetsLabel.Name = "PresetsLabel"
	presetsLabel.Size = UDim2.new(1, -20, 0, 30)
	presetsLabel.Position = UDim2.new(0, 10, 0, 60)
	presetsLabel.BackgroundTransparency = 1
	presetsLabel.Text = "Preset Loadouts:"
	presetsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	presetsLabel.TextXAlignment = Enum.TextXAlignment.Left
	presetsLabel.TextScaled = true
	presetsLabel.Font = Enum.Font.Gotham
	presetsLabel.Parent = mainFrame
	
	-- Preset buttons container
	local presetsContainer = Instance.new("Frame")
	presetsContainer.Name = "PresetsContainer"
	presetsContainer.Size = UDim2.new(1, -20, 0, 100)
	presetsContainer.Position = UDim2.new(0, 10, 0, 90)
	presetsContainer.BackgroundTransparency = 1
	presetsContainer.Parent = mainFrame
	
	local presetsLayout = Instance.new("UIListLayout")
	presetsLayout.FillDirection = Enum.FillDirection.Horizontal
	presetsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	presetsLayout.Padding = UDim.new(0, 5)
	presetsLayout.Parent = presetsContainer
	
	-- Create preset buttons
	for loadoutName, loadout in pairs(availableLoadouts) do
		local presetButton = Instance.new("TextButton")
		presetButton.Name = loadoutName .. "Button"
		presetButton.Size = UDim2.new(0, 80, 0, 40)
		presetButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
		presetButton.Text = loadoutName
		presetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		presetButton.TextScaled = true
		presetButton.Font = Enum.Font.Gotham
		presetButton.Parent = presetsContainer
		
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 4)
		buttonCorner.Parent = presetButton
		
		-- Button click handler
		presetButton.MouseButton1Click:Connect(function()
			self:applyLoadout(loadout)
		end)
	end
	
	-- Custom loadout section
	local customLabel = Instance.new("TextLabel")
	customLabel.Name = "CustomLabel"
	customLabel.Size = UDim2.new(1, -20, 0, 30)
	customLabel.Position = UDim2.new(0, 10, 0, 200)
	customLabel.BackgroundTransparency = 1
	customLabel.Text = "Custom Loadout:"
	customLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	customLabel.TextXAlignment = Enum.TextXAlignment.Left
	customLabel.TextScaled = true
	customLabel.Font = Enum.Font.Gotham
	customLabel.Parent = mainFrame
	
	-- Create weapon slot selectors
	local yOffset = 230
	for slotName, weapons in pairs(availableWeapons) do
		-- Slot label
		local slotLabel = Instance.new("TextLabel")
		slotLabel.Name = slotName .. "Label"
		slotLabel.Size = UDim2.new(0, 80, 0, 30)
		slotLabel.Position = UDim2.new(0, 10, 0, yOffset)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Text = slotName .. ":"
		slotLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		slotLabel.TextXAlignment = Enum.TextXAlignment.Left
		slotLabel.TextScaled = true
		slotLabel.Font = Enum.Font.Gotham
		slotLabel.Parent = mainFrame
		
		-- Dropdown/selector (simplified as buttons for now)
		local weaponsContainer = Instance.new("Frame")
		weaponsContainer.Name = slotName .. "Container"
		weaponsContainer.Size = UDim2.new(0, 290, 0, 30)
		weaponsContainer.Position = UDim2.new(0, 100, 0, yOffset)
		weaponsContainer.BackgroundTransparency = 1
		weaponsContainer.Parent = mainFrame
		
		local weaponsLayout = Instance.new("UIListLayout")
		weaponsLayout.FillDirection = Enum.FillDirection.Horizontal
		weaponsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		weaponsLayout.Padding = UDim.new(0, 5)
		weaponsLayout.Parent = weaponsContainer
		
		-- Create weapon buttons
		for _, weaponName in ipairs(weapons) do
			local weaponButton = Instance.new("TextButton")
			weaponButton.Name = weaponName .. "Button"
			weaponButton.Size = UDim2.new(0, 60, 0, 30)
			weaponButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			weaponButton.Text = weaponName
			weaponButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			weaponButton.TextScaled = true
			weaponButton.Font = Enum.Font.Gotham
			weaponButton.Parent = weaponsContainer
			
			local weaponCorner = Instance.new("UICorner")
			weaponCorner.CornerRadius = UDim.new(0, 4)
			weaponCorner.Parent = weaponButton
			
			-- Weapon button click handler
			weaponButton.MouseButton1Click:Connect(function()
				self:setWeaponSlot(slotName, weaponName)
				weaponButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
				
				-- Reset other buttons in this slot
				for _, child in pairs(weaponsContainer:GetChildren()) do
					if child ~= weaponButton and child:IsA("TextButton") then
						child.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
					end
				end
			end)
		end
		
		yOffset = yOffset + 40
	end
	
	-- Apply button
	local applyButton = Instance.new("TextButton")
	applyButton.Name = "ApplyButton"
	applyButton.Size = UDim2.new(0, 100, 0, 40)
	applyButton.Position = UDim2.new(0.5, -50, 1, -50)
	applyButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
	applyButton.Text = "Apply"
	applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	applyButton.TextScaled = true
	applyButton.Font = Enum.Font.GothamBold
	applyButton.Parent = mainFrame
	
	local applyCorner = Instance.new("UICorner")
	applyCorner.CornerRadius = UDim.new(0, 4)
	applyCorner.Parent = applyButton
	
	-- Connect events
	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		-- Re-lock mouse
		if _G.FPSCameraMouseControl then
			_G.FPSCameraMouseControl.lockMouse()
		end
	end)
	
	applyButton.MouseButton1Click:Connect(function()
		self:applyCurrentLoadout()
		screenGui:Destroy()
		-- Re-lock mouse
		if _G.FPSCameraMouseControl then
			_G.FPSCameraMouseControl.lockMouse()
		end
	end)
	
	screenGui.Parent = playerGui
	self.currentGUI = screenGui
end

-- Current custom loadout
LoadoutSelector.currentCustomLoadout = {
	PRIMARY = "G36",
	SECONDARY = "M9", 
	MELEE = "PocketKnife",
	GRENADE = "M67"
}

-- Set a weapon slot
function LoadoutSelector:setWeaponSlot(slot, weapon)
	self.currentCustomLoadout[slot] = weapon
	print("Set", slot, "to", weapon)
end

-- Apply a preset loadout
function LoadoutSelector:applyLoadout(loadout)
	print("Applying preset loadout:")
	for slot, weapon in pairs(loadout) do
		print(" -", slot, ":", weapon)
	end
	
	-- Apply to FPS Controller if available
	if _G.FPSController then
		for slot, weapon in pairs(loadout) do
			_G.FPSController:loadWeapon(slot, weapon)
		end
		-- Equip primary weapon
		_G.FPSController:equipWeapon("PRIMARY")
	end
end

-- Apply current custom loadout
function LoadoutSelector:applyCurrentLoadout()
	print("Applying custom loadout:")
	for slot, weapon in pairs(self.currentCustomLoadout) do
		print(" -", slot, ":", weapon)
	end
	
	-- Apply to FPS Controller if available
	if _G.FPSController then
		for slot, weapon in pairs(self.currentCustomLoadout) do
			_G.FPSController:loadWeapon(slot, weapon)
		end
		-- Equip primary weapon
		_G.FPSController:equipWeapon("PRIMARY")
	end
end

-- Initialize the loadout selector
function LoadoutSelector:init()
	print("Loadout Selector initialized")
	print("Available commands:")
	print(" - LoadoutSelector:openGUI() - Open loadout selection interface")
	print(" - LoadoutSelector:applyLoadout(loadout) - Apply a loadout directly")
end

-- Open the GUI
function LoadoutSelector:openGUI()
	-- Unlock mouse for GUI interaction
	if _G.FPSCameraMouseControl then
		_G.FPSCameraMouseControl.unlockMouse()
	end
	
	-- Close existing GUI if open
	if self.currentGUI then
		self.currentGUI:Destroy()
	end
	
	self:createLoadoutGUI()
end

-- Export globally
_G.LoadoutSelector = LoadoutSelector

-- Initialize
LoadoutSelector:init()

return LoadoutSelector