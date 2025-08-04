-- ViewmodelOffsetDebugger with Fixed Functionality
local ViewmodelOffsetDebugger = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Configurable offsets
ViewmodelOffsetDebugger.Offsets = {
	DEFAULT = {
		Position = Vector3.new(0.2, -0.2, -0.7),
		Rotation = Vector3.new(0, 0, 0)
	},
	ADS = {
		Position = Vector3.new(0, -0.1, -0.4),
		Rotation = Vector3.new(0, 0, 0)
	},
	SPRINT = {
		Position = Vector3.new(0.4, -0.15, -0.6),
		Rotation = Vector3.new(0, 0, 0)
	},
	WEAPON = {
		DEFAULT = CFrame.new(0.2, -0.25, -0.4),
		ADS = CFrame.new(0, -0.1, -0.2),
		SPRINT = CFrame.new(0.4, -0.3, -0.5)
	}
}

-- Mouse behavior during debugging
local originalMouseBehavior = Enum.MouseBehavior.LockCenter

-- Store the viewmodel system reference
local injectedViewmodelSystem = nil

-- Global state for GUI elements
local GUI = {
	currentOffsetType = "DEFAULT",
	currentAxis = "Position",
	offsetTypeLabel = nil,
	offsetDisplay = nil,
	frame = nil
}

-- Create debug GUI with fixed buttons
function ViewmodelOffsetDebugger:createDebugGUI()
	print("Creating Viewmodel Offset Debugger GUI...")

	-- Get local player
	local player = Players.LocalPlayer
	if not player then
		warn("No LocalPlayer found")
		return nil
	end

	-- Check if GUI already exists and clean up
	local existingGui = player.PlayerGui:FindFirstChild("ViewmodelOffsetDebugger")
	if existingGui then
		existingGui:Destroy()
	end

	-- Create ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "ViewmodelOffsetDebugger"

	-- Set ResetOnSpawn to false and start disabled
	gui.ResetOnSpawn = false
	gui.Enabled = false -- Start hidden

	-- Create main frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 430) -- Added space for another button
	frame.Position = UDim2.new(0, 10, 0.5, -215)
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	frame.Parent = gui
	GUI.frame = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "Viewmodel Offset Debugger"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Parent = frame

	-- Offset type selection
	local offsetTypeLabel = Instance.new("TextLabel")
	offsetTypeLabel.Text = "Offset Type: DEFAULT"
	offsetTypeLabel.Size = UDim2.new(1, 0, 0, 30)
	offsetTypeLabel.Position = UDim2.new(0, 0, 0, 40)
	offsetTypeLabel.Parent = frame
	GUI.offsetTypeLabel = offsetTypeLabel

	-- Current offset display
	local offsetDisplay = Instance.new("TextLabel")
	offsetDisplay.Size = UDim2.new(1, 0, 0, 60)
	offsetDisplay.Position = UDim2.new(0, 0, 0, 80)
	offsetDisplay.TextScaled = false
	offsetDisplay.TextSize = 14
	offsetDisplay.Parent = frame
	GUI.offsetDisplay = offsetDisplay

	-- Create adjustment buttons
	local function createAdjustButton(text, position, callback)
		local button = Instance.new("TextButton")
		button.Text = text
		button.Size = UDim2.new(0, 50, 0, 50)
		button.Position = position
		button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		button.Parent = frame

		-- Connect function with error handling
		button.MouseButton1Click:Connect(function()
			local success, result = pcall(callback)
			if not success then
				warn("Button error:", result)
			end
		end)

		return button
	end

	-- Update display function with error handling
	local function updateDisplay()
		local success, result = pcall(function()
			-- Safely access current offset
			local currentOffset = self.Offsets[GUI.currentOffsetType]
			if not currentOffset then
				offsetDisplay.Text = "Error: Invalid offset type"
				return
			end

			-- Safely access offset value
			local offsetValue = GUI.currentAxis == "Position" and currentOffset.Position or currentOffset.Rotation
			if not offsetValue then
				offsetDisplay.Text = "Error: Invalid axis"
				return
			end

			-- Update the display text
			offsetDisplay.Text = string.format(
				"Offset Type: %s\nAxis: %s\nX: %.2f\nY: %.2f\nZ: %.2f", 
				GUI.currentOffsetType, 
				GUI.currentAxis, 
				offsetValue.X, 
				offsetValue.Y, 
				offsetValue.Z
			)
		end)

		if not success then
			warn("Update display error:", result)
			offsetDisplay.Text = "Error updating display"
		end
	end

	-- Adjustment function with error handling
	local function adjustOffset(axis, delta)
		local success, result = pcall(function()
			-- Get current offset safely
			local currentOffset = self.Offsets[GUI.currentOffsetType]
			if not currentOffset then
				warn("Invalid offset type: " .. tostring(GUI.currentOffsetType))
				return
			end

			-- Get current value safely
			local offsetValue
			if GUI.currentAxis == "Position" then
				offsetValue = currentOffset.Position or Vector3.new(0, 0, 0)
			else
				offsetValue = currentOffset.Rotation or Vector3.new(0, 0, 0)
			end

			-- Adjust the value based on axis
			if axis == "X" then
				offsetValue = Vector3.new(offsetValue.X + delta, offsetValue.Y, offsetValue.Z)
			elseif axis == "Y" then
				offsetValue = Vector3.new(offsetValue.X, offsetValue.Y + delta, offsetValue.Z)
			elseif axis == "Z" then
				offsetValue = Vector3.new(offsetValue.X, offsetValue.Y, offsetValue.Z + delta)
			end

			-- Update the offset
			if GUI.currentAxis == "Position" then
				self.Offsets[GUI.currentOffsetType].Position = offsetValue
			else
				self.Offsets[GUI.currentOffsetType].Rotation = offsetValue
			end

			-- Apply to viewmodel system immediately if injected
			if injectedViewmodelSystem then
				injectedViewmodelSystem.Offsets = self.Offsets

				-- Disable debug logging in the viewmodel system to prevent console spam
				if typeof(injectedViewmodelSystem) == "table" then
					injectedViewmodelSystem.debugLogging = false
				end

				-- Update immediately
				if typeof(injectedViewmodelSystem.update) == "function" then
					injectedViewmodelSystem:update(0.01)
				end
			end

			-- Update the display
			updateDisplay()
		end)

		if not success then
			warn("Adjust offset error:", result)
		end
	end

	-- Create adjustment buttons
	createAdjustButton("+X", UDim2.new(0, 10, 0, 150), function() adjustOffset("X", 0.1) end)
	createAdjustButton("-X", UDim2.new(0, 10, 0, 210), function() adjustOffset("X", -0.1) end)
	createAdjustButton("+Y", UDim2.new(0, 70, 0, 150), function() adjustOffset("Y", 0.1) end)
	createAdjustButton("-Y", UDim2.new(0, 70, 0, 210), function() adjustOffset("Y", -0.1) end)
	createAdjustButton("+Z", UDim2.new(0, 130, 0, 150), function() adjustOffset("Z", 0.1) end)
	createAdjustButton("-Z", UDim2.new(0, 130, 0, 210), function() adjustOffset("Z", -0.1) end)

	-- Fine adjustment buttons
	createAdjustButton("+X Fine", UDim2.new(0, 190, 0, 150), function() adjustOffset("X", 0.01) end)
	createAdjustButton("-X Fine", UDim2.new(0, 190, 0, 210), function() adjustOffset("X", -0.01) end)
	createAdjustButton("+Y Fine", UDim2.new(0, 250, 0, 150), function() adjustOffset("Y", 0.01) end)
	createAdjustButton("-Y Fine", UDim2.new(0, 250, 0, 210), function() adjustOffset("Y", -0.01) end)

	-- Cycle offset type button
	local cycleOffsetButton = Instance.new("TextButton")
	cycleOffsetButton.Text = "Cycle Offset Type"
	cycleOffsetButton.Size = UDim2.new(0, 150, 0, 30)
	cycleOffsetButton.Position = UDim2.new(0, 10, 0, 270)
	cycleOffsetButton.Parent = frame

	local offsetTypes = {"DEFAULT", "ADS", "SPRINT"}
	local currentOffsetTypeIndex = 1

	cycleOffsetButton.MouseButton1Click:Connect(function()
		local success, result = pcall(function()
			currentOffsetTypeIndex = currentOffsetTypeIndex % #offsetTypes + 1
			GUI.currentOffsetType = offsetTypes[currentOffsetTypeIndex]
			offsetTypeLabel.Text = "Offset Type: " .. GUI.currentOffsetType
			updateDisplay()
		end)

		if not success then
			warn("Cycle offset type error:", result)
		end
	end)

	-- Cycle axis button
	local cycleAxisButton = Instance.new("TextButton")
	cycleAxisButton.Text = "Cycle Axis"
	cycleAxisButton.Size = UDim2.new(0, 150, 0, 30)
	cycleAxisButton.Position = UDim2.new(0, 10, 0, 310)
	cycleAxisButton.Parent = frame

	local axisTypes = {"Position", "Rotation"}
	local currentAxisIndex = 1

	cycleAxisButton.MouseButton1Click:Connect(function()
		local success, result = pcall(function()
			currentAxisIndex = currentAxisIndex % #axisTypes + 1
			GUI.currentAxis = axisTypes[currentAxisIndex]
			updateDisplay()
		end)

		if not success then
			warn("Cycle axis error:", result)
		end
	end)

	-- Export button
	local exportButton = Instance.new("TextButton")
	exportButton.Text = "Export Offsets"
	exportButton.Size = UDim2.new(0, 150, 0, 30)
	exportButton.Position = UDim2.new(0, 10, 0, 350)
	exportButton.Parent = frame

	exportButton.MouseButton1Click:Connect(function()
		local success, result = pcall(function()
			print("Current Viewmodel Offsets:")

			-- Print each offset type safely
			for offsetType, offsetData in pairs(self.Offsets) do
				if offsetType ~= "WEAPON" then
					local posStr = offsetData.Position and 
						string.format("Vector3.new(%.2f, %.2f, %.2f)", 
							offsetData.Position.X, 
							offsetData.Position.Y, 
							offsetData.Position.Z) or 
						"nil"

					local rotStr = offsetData.Rotation and
						string.format("Vector3.new(%.2f, %.2f, %.2f)", 
							offsetData.Rotation.X, 
							offsetData.Rotation.Y, 
							offsetData.Rotation.Z) or
						"nil"

					print(string.format("%s Position: %s", offsetType, posStr))
					print(string.format("%s Rotation: %s", offsetType, rotStr))
				end
			end

			-- Print weapon offsets if they exist
			if self.Offsets.WEAPON then
				for posType, posCFrame in pairs(self.Offsets.WEAPON) do
					if typeof(posCFrame) == "CFrame" then
						local pos = posCFrame.Position
						print(string.format("WEAPON_%s: CFrame.new(%.2f, %.2f, %.2f)", 
							posType, pos.X, pos.Y, pos.Z))
					end
				end
			end
		end)

		if not success then
			warn("Export offsets error:", result)
		end
	end)

	-- Add a button to toggle the mouse lock
	local toggleMouseButton = Instance.new("TextButton")
	toggleMouseButton.Text = "Toggle Mouse Lock"
	toggleMouseButton.Size = UDim2.new(0, 150, 0, 30)
	toggleMouseButton.Position = UDim2.new(0, 10, 0, 390)
	toggleMouseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
	toggleMouseButton.Parent = frame

	toggleMouseButton.MouseButton1Click:Connect(function()
		local success, result = pcall(function()
			if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
				-- Lock the mouse
				UserInputService.MouseBehavior = originalMouseBehavior
				toggleMouseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
				toggleMouseButton.Text = "Toggle Mouse Lock"
			else
				-- Unlock the mouse
				originalMouseBehavior = UserInputService.MouseBehavior
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				toggleMouseButton.BackgroundColor3 = Color3.fromRGB(150, 80, 80)
				toggleMouseButton.Text = "Enable Mouse Lock"
			end
		end)

		if not success then
			warn("Toggle mouse error:", result)
		end
	end)

	-- Initialize display
	updateDisplay()

	-- Parent the GUI
	gui.Parent = player.PlayerGui

	print("Viewmodel Offset Debugger GUI created successfully!")

	-- Return interface for getting current offsets
	return {
		getOffsets = function() return self.Offsets end,
		gui = gui,
		toggleVisibility = function()
			local success, result = pcall(function()
				gui.Enabled = not gui.Enabled

				-- Toggle mouse lock when GUI is shown
				if gui.Enabled then
					-- Store original mouse behavior and unlock mouse
					originalMouseBehavior = UserInputService.MouseBehavior
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
					toggleMouseButton.BackgroundColor3 = Color3.fromRGB(150, 80, 80)
					toggleMouseButton.Text = "Enable Mouse Lock"
				else
					-- Restore mouse lock
					UserInputService.MouseBehavior = originalMouseBehavior
				end

				return gui.Enabled
			end)

			if not success then
				warn("Toggle visibility error:", result)
				return false
			end

			return result
		end
	}
end

-- Function to inject this into a ViewmodelSystem
function ViewmodelOffsetDebugger:injectIntoViewmodelSystem(viewmodelSystem)
	if not viewmodelSystem then
		warn("Cannot inject into nil viewmodelSystem")
		return
	end

	print("Injecting offsets into viewmodel system...")

	-- Store reference to the viewmodel system
	injectedViewmodelSystem = viewmodelSystem

	-- Disable debug logging to prevent console spam
	if typeof(viewmodelSystem) == "table" then
		viewmodelSystem.debugLogging = false
	end

	-- Check if getTargetPosition exists
	if typeof(viewmodelSystem.getTargetPosition) ~= "function" then
		warn("viewmodelSystem lacks getTargetPosition method, creating it")
		-- Create the method if it doesn't exist
		viewmodelSystem.getTargetPosition = function(self)
			return Vector3.new(0.25, -0.4, -0.8) -- Default position
		end
	end

	-- Override the getTargetPosition method
	local originalGetTargetPosition = viewmodelSystem.getTargetPosition

	viewmodelSystem.getTargetPosition = function(self)
		local offsetType = "DEFAULT"
		if self.isAiming then
			offsetType = "ADS"
		elseif self.isSprinting then
			offsetType = "SPRINT"
		end

		local offsets = ViewmodelOffsetDebugger.Offsets
		if not offsets or not offsets[offsetType] or not offsets[offsetType].Position then
			warn("Invalid offset for type: " .. offsetType)
			return typeof(originalGetTargetPosition) == "function" and 
				originalGetTargetPosition(self) or 
				Vector3.new(0.25, -0.4, -0.8)
		end

		-- Get position from offsets (ensure it's Vector3, not CFrame)
		local position = offsets[offsetType].Position

		-- Return position (must be Vector3)
		return position
	end

	-- Store offsets in the viewmodel system
	viewmodelSystem.Offsets = self.Offsets

	-- Set up weapon offset handling too
	if viewmodelSystem.container and viewmodelSystem.container.PrimaryPart then
		local weaponAttachment = viewmodelSystem.container.PrimaryPart:FindFirstChild("WeaponAttachment")
		if weaponAttachment then
			-- Update the attachment based on current weapon offsets
			local offsetType = "DEFAULT"
			if viewmodelSystem.isAiming then
				offsetType = "ADS"
			elseif viewmodelSystem.isSprinting then
				offsetType = "SPRINT"
			end

			if self.Offsets.WEAPON and self.Offsets.WEAPON[offsetType] then
				weaponAttachment.CFrame = self.Offsets.WEAPON[offsetType]
			end
		end
	end

	print("Offsets injected successfully!")
end

-- Initialize the debugger
function ViewmodelOffsetDebugger:init()
	-- Show the GUI
	local result = self:createDebugGUI()

	-- Set up keyboard shortcut to toggle visibility
	local gui = result and result.gui

	if result and result.toggleVisibility then
		-- Set up keyboard shortcut (P key)
		local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end

			-- Press P to toggle debugger visibility
			if input.KeyCode == Enum.KeyCode.P then
				local success, result = pcall(function()
					local isVisible = result.toggleVisibility()
					print("Debugger visibility: " .. (isVisible and "ON" or "OFF"))
				end)

				if not success then
					warn("Toggle debugger error:", result)
				end
			end
		end)

		-- Add cleanup method
		result.cleanup = function()
			if connection then
				connection:Disconnect()
			end
			if gui then
				gui:Destroy()
			end
		end
	end

	-- Try to find viewmodel system
	task.spawn(function()
		task.wait(1)

		-- Try to find in _G
		local vmSystem = _G.CurrentViewmodelSystem
		if vmSystem then
			print("Found viewmodel system in _G, injecting")
			self:injectIntoViewmodelSystem(vmSystem)
		else
			-- Try to find in camera
			local camera = workspace.CurrentCamera
			if camera then
				local container = camera:FindFirstChild("ViewmodelContainer")
				if container then
					print("Found viewmodel container, creating proxy for injection")

					-- Create a basic proxy
					local proxy = {
						container = container,
						isAiming = false,
						isSprinting = false,

						update = function(self)
							-- Force update
							if self.container and self.container.PrimaryPart then
								self.container.PrimaryPart.CFrame = self.container.PrimaryPart.CFrame * CFrame.new(0,0,0)
							end
						end
					}

					self:injectIntoViewmodelSystem(proxy)
				end
			end
		end
	end)

	return result
end

return ViewmodelOffsetDebugger