local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for menu
repeat wait() until playerGui:FindFirstChild("FPSMainMenu")

local mainMenu = playerGui.FPSMainMenu

-- Wait for settings section to be created (new structure)
local settingsSection = nil
local maxWait = 10
local waited = 0
while not settingsSection and waited < maxWait do
	wait(0.1)
	waited = waited + 0.1
	local contentArea = mainMenu.MainContainer:FindFirstChild("ContentArea")
	if contentArea then
		settingsSection = contentArea:FindFirstChild("SettingsSection")
	end
end

if not settingsSection then
	warn("SettingsSection not found after " .. maxWait .. " seconds")
	return
end

-- Settings data
local settingsData = {
    sensitivity = 0.5,
    fov = 90,
    ragdollFactor = 1.0,
    masterVolume = 0.7,
    sfxVolume = 0.8,
    musicVolume = 0.5,
    mouseInvertY = false,
    autoSprint = true,
    showFPS = false,
    crosshairColor = Color3.fromRGB(255, 255, 255),
    crosshairSize = 1.0
}

-- Default settings for reset
local defaultSettings = {}
for key, value in pairs(settingsData) do
    defaultSettings[key] = value
end

local SettingsController = {}

function SettingsController:SaveSettings()
    -- In a real implementation, this would save to DataStore
    -- For now, we'll use a simple local storage approach
    _G.PlayerSettings = settingsData
    print("Settings saved locally")
end

function SettingsController:LoadSettings()
    -- Load from global storage if it exists
    if _G.PlayerSettings then
        for key, value in pairs(_G.PlayerSettings) do
            if settingsData[key] ~= nil then
                settingsData[key] = value
            end
        end
        print("Settings loaded from local storage")
    end
end

function SettingsController:ApplySettings()
    -- Apply sensitivity (would be used by weapon system)
    _G.WeaponSensitivity = settingsData.sensitivity
    
    -- Apply FOV (when weapon is equipped)
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = settingsData.fov
    end
    
    -- Apply volume settings
    -- Note: SoundService doesn't have a Volume property, this would be handled per-sound
    
    -- Apply other settings as needed
    _G.RagdollFactor = settingsData.ragdollFactor
    _G.AutoSprint = settingsData.autoSprint
    
    print("Settings applied")
end

function SettingsController:CreateSlider(name, minValue, maxValue, currentValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = name .. "Slider"
    sliderFrame.Size = UDim2.new(1, -20, 0, 60)
    sliderFrame.BackgroundTransparency = 1
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame
    
    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0, 60, 0, 25)
    valueLabel.Position = UDim2.new(1, -60, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(math.floor(currentValue * 100) / 100)
    valueLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.Parent = sliderFrame
    
    -- Slider background
    local sliderBG = Instance.new("Frame")
    sliderBG.Name = "SliderBG"
    sliderBG.Size = UDim2.new(1, -70, 0, 6)
    sliderBG.Position = UDim2.new(0, 0, 0, 35)
    sliderBG.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
    sliderBG.BorderSizePixel = 0
    sliderBG.Parent = sliderFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 3)
    bgCorner.Parent = sliderBG
    
    -- Slider fill
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((currentValue - minValue) / (maxValue - minValue), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBG
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    -- Slider knob
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Name = "Knob"
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new((currentValue - minValue) / (maxValue - minValue), -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Parent = sliderBG
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 8)
    knobCorner.Parent = sliderKnob
    
    -- Slider interaction
    local dragging = false
    
    local function updateSlider(input)
        if not dragging then return end
        
        local relativeX = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
        local newValue = minValue + (maxValue - minValue) * relativeX
        
        -- Update visuals
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        sliderKnob.Position = UDim2.new(relativeX, -8, 0.5, -8)
        valueLabel.Text = tostring(math.floor(newValue * 100) / 100)
        
        -- Call callback
        if callback then
            callback(newValue)
        end
    end
    
    sliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)
    
    sliderBG.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return sliderFrame
end

function SettingsController:CreateToggle(name, currentValue, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = name .. "Toggle"
    toggleFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleFrame.BackgroundTransparency = 1
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame
    
    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 25)
    toggleButton.Position = UDim2.new(1, -50, 0.5, -12.5)
    toggleButton.BackgroundColor3 = currentValue and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = currentValue and "ON" or "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = toggleFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        currentValue = not currentValue
        toggleButton.Text = currentValue and "ON" or "OFF"
        toggleButton.BackgroundColor3 = currentValue and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        
        if callback then
            callback(currentValue)
        end
    end)
    
    return toggleFrame
end

function SettingsController:CreateColorPicker(name, currentColor, callback)
    local colorFrame = Instance.new("Frame")
    colorFrame.Name = name .. "ColorPicker"
    colorFrame.Size = UDim2.new(1, -20, 0, 40)
    colorFrame.BackgroundTransparency = 1
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = colorFrame
    
    -- Color display/button
    local colorButton = Instance.new("TextButton")
    colorButton.Name = "ColorButton"
    colorButton.Size = UDim2.new(0, 50, 0, 25)
    colorButton.Position = UDim2.new(1, -50, 0.5, -12.5)
    colorButton.BackgroundColor3 = currentColor
    colorButton.BorderSizePixel = 0
    colorButton.Text = ""
    colorButton.Parent = colorFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = colorButton
    
    -- Simple color cycling for now (could be expanded to full color picker)
    local colors = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(255, 100, 100),
        Color3.fromRGB(100, 255, 100),
        Color3.fromRGB(100, 100, 255),
        Color3.fromRGB(255, 255, 100),
        Color3.fromRGB(255, 100, 255),
        Color3.fromRGB(100, 255, 255)
    }
    
    local currentColorIndex = 1
    for i, color in pairs(colors) do
        if color == currentColor then
            currentColorIndex = i
            break
        end
    end
    
    colorButton.MouseButton1Click:Connect(function()
        currentColorIndex = currentColorIndex + 1
        if currentColorIndex > #colors then
            currentColorIndex = 1
        end
        
        local newColor = colors[currentColorIndex]
        colorButton.BackgroundColor3 = newColor
        
        if callback then
            callback(newColor)
        end
    end)
    
    return colorFrame
end

function SettingsController:PopulateSettings()
    local scrollingFrame = settingsSection:FindFirstChild("SettingsScroll")
    if not scrollingFrame then return end
    
    -- Clear existing settings
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Sensitivity slider
    local sensitivitySlider = self:CreateSlider("Mouse Sensitivity", 0.1, 2.0, settingsData.sensitivity, function(value)
        settingsData.sensitivity = value
        self:ApplySettings()
    end)
    sensitivitySlider.Parent = scrollingFrame
    
    -- FOV slider
    local fovSlider = self:CreateSlider("Field of View", 60, 120, settingsData.fov, function(value)
        settingsData.fov = value
        self:ApplySettings()
    end)
    fovSlider.Parent = scrollingFrame
    
    -- Ragdoll factor slider
    local ragdollSlider = self:CreateSlider("Ragdoll Factor", 0.0, 3.0, settingsData.ragdollFactor, function(value)
        settingsData.ragdollFactor = value
        self:ApplySettings()
    end)
    ragdollSlider.Parent = scrollingFrame
    
    -- Volume sliders
    local masterVolumeSlider = self:CreateSlider("Master Volume", 0.0, 1.0, settingsData.masterVolume, function(value)
        settingsData.masterVolume = value
        self:ApplySettings()
    end)
    masterVolumeSlider.Parent = scrollingFrame
    
    local sfxVolumeSlider = self:CreateSlider("SFX Volume", 0.0, 1.0, settingsData.sfxVolume, function(value)
        settingsData.sfxVolume = value
    end)
    sfxVolumeSlider.Parent = scrollingFrame
    
    local musicVolumeSlider = self:CreateSlider("Music Volume", 0.0, 1.0, settingsData.musicVolume, function(value)
        settingsData.musicVolume = value
    end)
    musicVolumeSlider.Parent = scrollingFrame
    
    -- Crosshair size slider
    local crosshairSizeSlider = self:CreateSlider("Crosshair Size", 0.5, 2.0, settingsData.crosshairSize, function(value)
        settingsData.crosshairSize = value
    end)
    crosshairSizeSlider.Parent = scrollingFrame
    
    -- Toggle settings
    local invertYToggle = self:CreateToggle("Invert Mouse Y", settingsData.mouseInvertY, function(value)
        settingsData.mouseInvertY = value
    end)
    invertYToggle.Parent = scrollingFrame
    
    local autoSprintToggle = self:CreateToggle("Auto Sprint", settingsData.autoSprint, function(value)
        settingsData.autoSprint = value
        self:ApplySettings()
    end)
    autoSprintToggle.Parent = scrollingFrame
    
    local showFPSToggle = self:CreateToggle("Show FPS", settingsData.showFPS, function(value)
        settingsData.showFPS = value
        self:ToggleFPSDisplay(value)
    end)
    showFPSToggle.Parent = scrollingFrame
    
    -- Crosshair color picker
    local crosshairColorPicker = self:CreateColorPicker("Crosshair Color", settingsData.crosshairColor, function(color)
        settingsData.crosshairColor = color
        self:ApplyCrosshairColor(color)
    end)
    crosshairColorPicker.Parent = scrollingFrame
    
    -- Action buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ActionButtons"
    buttonFrame.Size = UDim2.new(1, -20, 0, 50)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = scrollingFrame
    
    -- Save button
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.Size = UDim2.new(0.3, -5, 0, 40)
    saveButton.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
    saveButton.BorderSizePixel = 0
    saveButton.Text = "SAVE SETTINGS"
    saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveButton.TextScaled = true
    saveButton.Font = Enum.Font.GothamBold
    saveButton.Parent = buttonFrame
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 4)
    saveCorner.Parent = saveButton
    
    saveButton.MouseButton1Click:Connect(function()
        self:SaveSettings()
        self:ShowConfirmation("Settings Saved!")
    end)
    
    -- Reset button
    local resetButton = Instance.new("TextButton")
    resetButton.Name = "ResetButton"
    resetButton.Size = UDim2.new(0.3, -5, 0, 40)
    resetButton.Position = UDim2.new(0.35, 5, 0, 0)
    resetButton.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
    resetButton.BorderSizePixel = 0
    resetButton.Text = "RESET TO DEFAULT"
    resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetButton.TextScaled = true
    resetButton.Font = Enum.Font.GothamBold
    resetButton.Parent = buttonFrame
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 4)
    resetCorner.Parent = resetButton
    
    resetButton.MouseButton1Click:Connect(function()
        self:ResetSettings()
    end)
    
    -- Apply button
    local applyButton = Instance.new("TextButton")
    applyButton.Name = "ApplyButton"
    applyButton.Size = UDim2.new(0.3, -5, 0, 40)
    applyButton.Position = UDim2.new(0.7, 10, 0, 0)
    applyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
    applyButton.BorderSizePixel = 0
    applyButton.Text = "APPLY"
    applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyButton.TextScaled = true
    applyButton.Font = Enum.Font.GothamBold
    applyButton.Parent = buttonFrame
    
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 4)
    applyCorner.Parent = applyButton
    
    applyButton.MouseButton1Click:Connect(function()
        self:ApplySettings()
        self:ShowConfirmation("Settings Applied!")
    end)
end

function SettingsController:ResetSettings()
    -- Reset to default values
    for key, value in pairs(defaultSettings) do
        settingsData[key] = value
    end
    
    -- Repopulate UI
    self:PopulateSettings()
    self:ApplySettings()
    self:ShowConfirmation("Settings Reset to Default!")
end

function SettingsController:ShowConfirmation(message)
    local confirmation = Instance.new("Frame")
    confirmation.Name = "SettingsConfirmation"
    confirmation.Size = UDim2.new(0, 300, 0, 100)
    confirmation.Position = UDim2.new(0.5, -150, 0.5, -50)
    confirmation.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
    confirmation.BorderSizePixel = 0
    confirmation.Parent = settingsSection
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = confirmation
    
    local confirmText = Instance.new("TextLabel")
    confirmText.Size = UDim2.new(1, -20, 1, 0)
    confirmText.Position = UDim2.new(0, 10, 0, 0)
    confirmText.BackgroundTransparency = 1
    confirmText.Text = message
    confirmText.TextColor3 = Color3.fromRGB(100, 255, 100)
    confirmText.TextScaled = true
    confirmText.Font = Enum.Font.GothamBold
    confirmText.Parent = confirmation
    
    -- Auto-remove after 2 seconds
    spawn(function()
        wait(2)
        if confirmation.Parent then
            confirmation:Destroy()
        end
    end)
end

function SettingsController:ToggleFPSDisplay(enabled)
    local fpsDisplay = playerGui:FindFirstChild("FPSDisplay")
    
    if enabled and not fpsDisplay then
        fpsDisplay = Instance.new("ScreenGui")
        fpsDisplay.Name = "FPSDisplay"
        fpsDisplay.Parent = playerGui
        
        local fpsLabel = Instance.new("TextLabel")
        fpsLabel.Name = "FPSLabel"
        fpsLabel.Size = UDim2.new(0, 100, 0, 30)
        fpsLabel.Position = UDim2.new(1, -110, 0, 10)
        fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        fpsLabel.BackgroundTransparency = 0.5
        fpsLabel.BorderSizePixel = 0
        fpsLabel.Text = "FPS: 60"
        fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        fpsLabel.TextScaled = true
        fpsLabel.Font = Enum.Font.GothamBold
        fpsLabel.Parent = fpsDisplay
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = fpsLabel
        
        -- FPS counter
        spawn(function()
            local lastTime = tick()
            local frameCount = 0
            
            while fpsDisplay.Parent do
                frameCount = frameCount + 1
                local currentTime = tick()
                
                if currentTime - lastTime >= 1 then
                    local fps = math.floor(frameCount / (currentTime - lastTime))
                    fpsLabel.Text = "FPS: " .. fps
                    frameCount = 0
                    lastTime = currentTime
                end
                
                game:GetService("RunService").Heartbeat:Wait()
            end
        end)
        
    elseif not enabled and fpsDisplay then
        fpsDisplay:Destroy()
    end
end

function SettingsController:ApplyCrosshairColor(color)
    local gameHUD = playerGui:FindFirstChild("FPSGameHUD")
    if gameHUD and gameHUD:FindFirstChild("Crosshair") then
        local crosshair = gameHUD.Crosshair
        for _, child in pairs(crosshair:GetChildren()) do
            if child:IsA("Frame") then
                child.BackgroundColor3 = color
            end
        end
    end
end

function SettingsController:Initialize()
    print("SettingsController: Initializing...")
    
    -- Load settings
    self:LoadSettings()
    
    -- Populate settings UI
    self:PopulateSettings()
    
    -- Apply loaded settings
    self:ApplySettings()
    
    print("SettingsController: Ready!")
end

-- Initialize when settings section becomes visible
spawn(function()
    while true do
        if settingsSection.Visible then
            SettingsController:Initialize()
            break
        end
        wait(0.5)
    end
end)

return SettingsController