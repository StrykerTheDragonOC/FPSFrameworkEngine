-- VehicleController.client.lua
-- Client-side vehicle control system for KFCS FUNNY RANDOMIZER
-- Handles input, UI, and vehicle interaction from player perspective

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Wait for remote events
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Vehicle Controller Class
local VehicleController = {}
VehicleController.__index = VehicleController

function VehicleController.new()
    local self = setmetatable({}, VehicleController)
    
    self.player = Players.LocalPlayer
    self.currentVehicle = nil
    self.currentSeat = nil
    self.vehicleGui = nil
    self.inputConnection = nil
    self.updateConnection = nil
    
    self.inputState = {
        throttle = 0,
        steering = 0,
        brake = false,
        handbrake = false
    }
    
    self:setupVehicleUI()
    self:connectRemoteEvents()
    self:setupInputHandling()
    
    print("[VehicleController] ✅ Client vehicle controller initialized")
    return self
end

-- Setup vehicle UI
function VehicleController:setupVehicleUI()
    -- Remove existing
    local existing = StarterGui:FindFirstChild("VehicleControlUI")
    if existing then existing:Destroy() end
    
    local vehicleGui = Instance.new("ScreenGui")
    vehicleGui.Name = "VehicleControlUI"
    vehicleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    vehicleGui.IgnoreGuiInset = true
    vehicleGui.Enabled = false
    vehicleGui.Parent = StarterGui
    
    -- Vehicle HUD container
    local hudContainer = Instance.new("Frame")
    hudContainer.Name = "VehicleHUD"
    hudContainer.Size = UDim2.new(1, 0, 0, 150)
    hudContainer.Position = UDim2.new(0, 0, 1, -150)
    hudContainer.BackgroundTransparency = 1
    hudContainer.Parent = vehicleGui
    
    -- Speed gauge
    local speedFrame = Instance.new("Frame")
    speedFrame.Name = "SpeedGauge"
    speedFrame.Size = UDim2.new(0, 200, 0, 120)
    speedFrame.Position = UDim2.new(0, 50, 0, 15)
    speedFrame.BackgroundColor3 = Color3.fromHex("#1a1a2e")
    speedFrame.BackgroundTransparency = 0.1
    speedFrame.BorderSizePixel = 0
    speedFrame.Parent = hudContainer
    
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 15)
    speedCorner.Parent = speedFrame
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, 0, 0.6, 0)
    speedLabel.Position = UDim2.new(0, 0, 0, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "0"
    speedLabel.TextColor3 = Color3.fromHex("#ffffff")
    speedLabel.TextScaled = true
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.Parent = speedFrame
    
    local speedUnit = Instance.new("TextLabel")
    speedUnit.Name = "SpeedUnit"
    speedUnit.Size = UDim2.new(1, 0, 0.3, 0)
    speedUnit.Position = UDim2.new(0, 0, 0.65, 0)
    speedUnit.BackgroundTransparency = 1
    speedUnit.Text = "KM/H"
    speedUnit.TextColor3 = Color3.fromHex("#b8c6db")
    speedUnit.TextScaled = true
    speedUnit.Font = Enum.Font.Gotham
    speedUnit.Parent = speedFrame
    
    -- Health gauge
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthGauge"
    healthFrame.Size = UDim2.new(0, 250, 0, 60)
    healthFrame.Position = UDim2.new(0, 270, 0, 45)
    healthFrame.BackgroundColor3 = Color3.fromHex("#1a1a2e")
    healthFrame.BackgroundTransparency = 0.1
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = hudContainer
    
    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(0, 10)
    healthCorner.Parent = healthFrame
    
    local healthBarBG = Instance.new("Frame")
    healthBarBG.Name = "HealthBarBG"
    healthBarBG.Size = UDim2.new(1, -20, 0, 15)
    healthBarBG.Position = UDim2.new(0, 10, 0, 30)
    healthBarBG.BackgroundColor3 = Color3.fromHex("#0a0a0f")
    healthBarBG.BorderSizePixel = 0
    healthBarBG.Parent = healthFrame
    
    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(0, 7)
    healthBarCorner.Parent = healthBarBG
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromHex("#00ff88")
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBG
    
    local healthBarCorner2 = Instance.new("UICorner")
    healthBarCorner2.CornerRadius = UDim.new(0, 7)
    healthBarCorner2.Parent = healthBar
    
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 0, 25)
    healthText.Position = UDim2.new(0, 0, 0, 5)
    healthText.BackgroundTransparency = 1
    healthText.Text = "🛡️ VEHICLE INTEGRITY"
    healthText.TextColor3 = Color3.fromHex("#ffffff")
    healthText.TextScaled = true
    healthText.Font = Enum.Font.GothamBold
    healthText.Parent = healthFrame
    
    -- Fuel gauge
    local fuelFrame = Instance.new("Frame")
    fuelFrame.Name = "FuelGauge"
    fuelFrame.Size = UDim2.new(0, 180, 0, 60)
    fuelFrame.Position = UDim2.new(0, 540, 0, 45)
    fuelFrame.BackgroundColor3 = Color3.fromHex("#1a1a2e")
    fuelFrame.BackgroundTransparency = 0.1
    fuelFrame.BorderSizePixel = 0
    fuelFrame.Parent = hudContainer
    
    local fuelCorner = Instance.new("UICorner")
    fuelCorner.CornerRadius = UDim.new(0, 10)
    fuelCorner.Parent = fuelFrame
    
    local fuelBarBG = Instance.new("Frame")
    fuelBarBG.Name = "FuelBarBG"
    fuelBarBG.Size = UDim2.new(1, -20, 0, 15)
    fuelBarBG.Position = UDim2.new(0, 10, 0, 30)
    fuelBarBG.BackgroundColor3 = Color3.fromHex("#0a0a0f")
    fuelBarBG.BorderSizePixel = 0
    fuelBarBG.Parent = fuelFrame
    
    local fuelBarCorner = Instance.new("UICorner")
    fuelBarCorner.CornerRadius = UDim.new(0, 7)
    fuelBarCorner.Parent = fuelBarBG
    
    local fuelBar = Instance.new("Frame")
    fuelBar.Name = "FuelBar"
    fuelBar.Size = UDim2.new(1, 0, 1, 0)
    fuelBar.BackgroundColor3 = Color3.fromHex("#ffaa00")
    fuelBar.BorderSizePixel = 0
    fuelBar.Parent = fuelBarBG
    
    local fuelBarCorner2 = Instance.new("UICorner")
    fuelBarCorner2.CornerRadius = UDim.new(0, 7)
    fuelBarCorner2.Parent = fuelBar
    
    local fuelText = Instance.new("TextLabel")
    fuelText.Name = "FuelText"
    fuelText.Size = UDim2.new(1, 0, 0, 25)
    fuelText.Position = UDim2.new(0, 0, 0, 5)
    fuelText.BackgroundTransparency = 1
    fuelText.Text = "⛽ FUEL"
    fuelText.TextColor3 = Color3.fromHex("#ffffff")
    fuelText.TextScaled = true
    fuelText.Font = Enum.Font.GothamBold
    fuelText.Parent = fuelFrame
    
    -- Weapon info (for gunner seat)
    local weaponFrame = Instance.new("Frame")
    weaponFrame.Name = "WeaponInfo"
    weaponFrame.Size = UDim2.new(0, 200, 0, 80)
    weaponFrame.Position = UDim2.new(1, -250, 0, 35)
    weaponFrame.BackgroundColor3 = Color3.fromHex("#1a1a2e")
    weaponFrame.BackgroundTransparency = 0.1
    weaponFrame.BorderSizePixel = 0
    weaponFrame.Visible = false
    weaponFrame.Parent = hudContainer
    
    local weaponCorner = Instance.new("UICorner")
    weaponCorner.CornerRadius = UDim.new(0, 10)
    weaponCorner.Parent = weaponFrame
    
    local weaponName = Instance.new("TextLabel")
    weaponName.Name = "WeaponName"
    weaponName.Size = UDim2.new(1, 0, 0.5, 0)
    weaponName.BackgroundTransparency = 1
    weaponName.Text = "🔫 MOUNTED MG"
    weaponName.TextColor3 = Color3.fromHex("#ff6b35")
    weaponName.TextScaled = true
    weaponName.Font = Enum.Font.GothamBold
    weaponName.Parent = weaponFrame
    
    local weaponAmmo = Instance.new("TextLabel")
    weaponAmmo.Name = "WeaponAmmo"
    weaponAmmo.Size = UDim2.new(1, 0, 0.5, 0)
    weaponAmmo.Position = UDim2.new(0, 0, 0.5, 0)
    weaponAmmo.BackgroundTransparency = 1
    weaponAmmo.Text = "200 / 200"
    weaponAmmo.TextColor3 = Color3.fromHex("#ffffff")
    weaponAmmo.TextScaled = true
    weaponAmmo.Font = Enum.Font.Gotham
    weaponAmmo.Parent = weaponFrame
    
    -- Controls help
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "ControlsHelp"
    controlsFrame.Size = UDim2.new(0, 300, 0, 100)
    controlsFrame.Position = UDim2.new(0.5, -150, 0, 20)
    controlsFrame.BackgroundColor3 = Color3.fromHex("#1a1a2e")
    controlsFrame.BackgroundTransparency = 0.2
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = hudContainer
    
    local controlsCorner = Instance.new("UICorner")
    controlsCorner.CornerRadius = UDim.new(0, 10)
    controlsCorner.Parent = controlsFrame
    
    local controlsText = Instance.new("TextLabel")
    controlsText.Name = "ControlsText"
    controlsText.Size = UDim2.new(1, 0, 1, 0)
    controlsText.BackgroundTransparency = 1
    controlsText.Text = "WASD - Movement | SPACE - Brake\\nLMB - Fire | E - Exit Vehicle"
    controlsText.TextColor3 = Color3.fromHex("#b8c6db")
    controlsText.TextScaled = true
    controlsText.Font = Enum.Font.Gotham
    controlsText.Parent = controlsFrame
    
    self.vehicleGui = vehicleGui
    
    print("[VehicleController] 🖥️ Vehicle UI created")
end

-- Connect to remote events
function VehicleController:connectRemoteEvents()
    -- Vehicle stats updates
    remoteEvents.UpdateVehicleStats.OnClientEvent:Connect(function(vehicle, stats)
        if vehicle == self.currentVehicle then
            self:updateVehicleUI(stats)
        end
    end)
    
    -- Vehicle destruction
    remoteEvents.VehicleDestroyed.OnClientEvent:Connect(function(vehicle)
        if vehicle == self.currentVehicle then
            self:exitVehicle()
        end
    end)
end

-- Setup input handling
function VehicleController:setupInputHandling()
    -- Handle vehicle interaction
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.E then
            self:handleInteraction()
        elseif input.KeyCode == Enum.KeyCode.F then
            self:handleVehicleSpawn()
        end
    end)
end

-- Handle interaction (enter/exit vehicle)
function VehicleController:handleInteraction()
    if self.currentVehicle then
        self:exitVehicle()
    else
        self:tryEnterNearbyVehicle()
    end
end

-- Try to enter nearby vehicle
function VehicleController:tryEnterNearbyVehicle()
    local character = self.player.Character
    if not character or not character.PrimaryPart then return end
    
    local playerPosition = character.PrimaryPart.Position
    local nearestVehicle = nil
    local nearestDistance = math.huge
    
    -- Find nearest vehicle
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Chassis") then
            local distance = (model.PrimaryPart.Position - playerPosition).Magnitude
            if distance < 20 and distance < nearestDistance then
                nearestVehicle = model
                nearestDistance = distance
            end
        end
    end
    
    if nearestVehicle then
        -- Find available seat
        for i = 1, 4 do
            local seat = nearestVehicle:FindFirstChild("Seat" .. i)
            if seat and not seat.Occupant then
                remoteEvents.RequestVehicleEntry:FireServer(nearestVehicle, i)
                self:enterVehicle(nearestVehicle, i)
                break
            end
        end
    end
end

-- Enter vehicle
function VehicleController:enterVehicle(vehicle, seatNumber)
    self.currentVehicle = vehicle
    self.currentSeat = seatNumber
    
    -- Show vehicle UI
    self.vehicleGui.Enabled = true
    
    -- Setup seat-specific controls
    if seatNumber == 1 then
        -- Driver controls
        self:setupDriverControls()
    elseif seatNumber == 2 then
        -- Gunner controls
        self:setupGunnerControls()
        self.vehicleGui.VehicleHUD.WeaponInfo.Visible = true
    else
        -- Passenger
        self:setupPassengerControls()
    end
    
    print("[VehicleController] 🚗 Entered vehicle seat", seatNumber)
end

-- Exit vehicle
function VehicleController:exitVehicle()
    if not self.currentVehicle then return end
    
    remoteEvents.RequestVehicleExit:FireServer()
    
    -- Cleanup
    if self.inputConnection then
        self.inputConnection:Disconnect()
        self.inputConnection = nil
    end
    
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    
    self.vehicleGui.Enabled = false
    self.vehicleGui.VehicleHUD.WeaponInfo.Visible = false
    
    self.currentVehicle = nil
    self.currentSeat = nil
    
    print("[VehicleController] 🚪 Exited vehicle")
end

-- Setup driver controls
function VehicleController:setupDriverControls()
    self.inputConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.W then
            self.inputState.throttle = 1
        elseif input.KeyCode == Enum.KeyCode.S then
            self.inputState.throttle = -1
        elseif input.KeyCode == Enum.KeyCode.A then
            self.inputState.steering = -1
        elseif input.KeyCode == Enum.KeyCode.D then
            self.inputState.steering = 1
        elseif input.KeyCode == Enum.KeyCode.Space then
            self.inputState.brake = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
            self.inputState.throttle = 0
        elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
            self.inputState.steering = 0
        elseif input.KeyCode == Enum.KeyCode.Space then
            self.inputState.brake = false
        end
    end)
    
    -- Send input to server
    self.updateConnection = RunService.Heartbeat:Connect(function()
        remoteEvents.VehicleInput:FireServer(self.inputState)
    end)
end

-- Setup gunner controls
function VehicleController:setupGunnerControls()
    self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Fire weapon
            local mouse = self.player:GetMouse()
            remoteEvents.VehicleWeaponFire:FireServer("mounted_mg", mouse.Hit.Position)
        end
    end)
end

-- Setup passenger controls
function VehicleController:setupPassengerControls()
    -- Passengers can only exit
    print("[VehicleController] 👥 Passenger mode - limited controls")
end

-- Handle vehicle spawn terminal
function VehicleController:handleVehicleSpawn()
    local character = self.player.Character
    if not character or not character.PrimaryPart then return end
    
    local playerPosition = character.PrimaryPart.Position
    
    -- Find nearby spawn terminal
    for _, part in pairs(workspace:GetChildren()) do
        if part.Name:match("VehicleSpawn_") then
            local distance = (part.Position - playerPosition).Magnitude
            if distance < 15 then
                self:openVehicleSpawnMenu(part.Name)
                break
            end
        end
    end
end

-- Open vehicle spawn menu
function VehicleController:openVehicleSpawnMenu(terminalName)
    -- Create spawn selection UI
    local spawnGui = Instance.new("ScreenGui")
    spawnGui.Name = "VehicleSpawnMenu"
    spawnGui.Parent = StarterGui
    
    local menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.new(0, 600, 0, 400)
    menuFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    menuFrame.BackgroundColor3 = Color3.fromHex("#1a1a2e")
    menuFrame.BorderSizePixel = 0
    menuFrame.Parent = spawnGui
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 15)
    menuCorner.Parent = menuFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🚗 VEHICLE SPAWN TERMINAL"
    titleLabel.TextColor3 = Color3.fromHex("#ff6b35")
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = menuFrame
    
    -- Sample vehicle options
    local vehicles = {
        {name = "Tactical ATV", cost = 150, desc = "Fast reconnaissance"},
        {name = "Armored Humvee", cost = 300, desc = "Multi-role transport"},
        {name = "Battle Tank", cost = 800, desc = "Heavy assault"}
    }
    
    for i, vehicleData in pairs(vehicles) do
        local vehicleButton = Instance.new("TextButton")
        vehicleButton.Size = UDim2.new(1, -40, 0, 80)
        vehicleButton.Position = UDim2.new(0, 20, 0, 70 + (i-1) * 90)
        vehicleButton.BackgroundColor3 = Color3.fromHex("#16213e")
        vehicleButton.BorderSizePixel = 0
        vehicleButton.Text = ""
        vehicleButton.Parent = menuFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 10)
        buttonCorner.Parent = vehicleButton
        
        local vehicleName = Instance.new("TextLabel")
        vehicleName.Size = UDim2.new(0.7, 0, 0.5, 0)
        vehicleName.Position = UDim2.new(0, 15, 0, 5)
        vehicleName.BackgroundTransparency = 1
        vehicleName.Text = vehicleData.name
        vehicleName.TextColor3 = Color3.fromHex("#ffffff")
        vehicleName.TextScaled = true
        vehicleName.Font = Enum.Font.GothamBold
        vehicleName.TextXAlignment = Enum.TextXAlignment.Left
        vehicleName.Parent = vehicleButton
        
        local vehicleDesc = Instance.new("TextLabel")
        vehicleDesc.Size = UDim2.new(0.7, 0, 0.3, 0)
        vehicleDesc.Position = UDim2.new(0, 15, 0.5, 0)
        vehicleDesc.BackgroundTransparency = 1
        vehicleDesc.Text = vehicleData.desc
        vehicleDesc.TextColor3 = Color3.fromHex("#b8c6db")
        vehicleDesc.TextScaled = true
        vehicleDesc.Font = Enum.Font.Gotham
        vehicleDesc.TextXAlignment = Enum.TextXAlignment.Left
        vehicleDesc.Parent = vehicleButton
        
        local vehicleCost = Instance.new("TextLabel")
        vehicleCost.Size = UDim2.new(0.25, 0, 0.5, 0)
        vehicleCost.Position = UDim2.new(0.7, 0, 0.25, 0)
        vehicleCost.BackgroundTransparency = 1
        vehicleCost.Text = "₵ " .. vehicleData.cost
        vehicleCost.TextColor3 = Color3.fromHex("#ffaa00")
        vehicleCost.TextScaled = true
        vehicleCost.Font = Enum.Font.GothamBold
        vehicleCost.Parent = vehicleButton
        
        vehicleButton.MouseButton1Click:Connect(function()
            -- Request vehicle spawn
            local spawnId = terminalName:gsub("VehicleSpawn_", "")
            remoteEvents.RequestVehicleSpawn:FireServer(vehicleData.name:gsub(" ", "_"), spawnId)
            spawnGui:Destroy()
        end)
    end
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 40)
    closeButton.Position = UDim2.new(1, -120, 1, -60)
    closeButton.BackgroundColor3 = Color3.fromHex("#ff3366")
    closeButton.BorderSizePixel = 0
    closeButton.Text = "CLOSE"
    closeButton.TextColor3 = Color3.fromHex("#ffffff")
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = menuFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        spawnGui:Destroy()
    end)
end

-- Update vehicle UI
function VehicleController:updateVehicleUI(stats)
    if not self.vehicleGui or not self.vehicleGui.Enabled then return end
    
    local hudFrame = self.vehicleGui.VehicleHUD
    
    -- Update speed (placeholder calculation)
    local speed = 0 -- Calculate from vehicle velocity
    hudFrame.SpeedGauge.SpeedLabel.Text = tostring(math.floor(speed))
    
    -- Update health
    local healthPercentage = stats.health / stats.maxHealth
    hudFrame.HealthGauge.HealthBarBG.HealthBar.Size = UDim2.new(healthPercentage, 0, 1, 0)
    
    -- Change health bar color based on percentage
    if healthPercentage < 0.3 then
        hudFrame.HealthGauge.HealthBarBG.HealthBar.BackgroundColor3 = Color3.fromHex("#ff3366")
    elseif healthPercentage < 0.6 then
        hudFrame.HealthGauge.HealthBarBG.HealthBar.BackgroundColor3 = Color3.fromHex("#ffaa00")
    else
        hudFrame.HealthGauge.HealthBarBG.HealthBar.BackgroundColor3 = Color3.fromHex("#00ff88")
    end
    
    -- Update fuel
    local fuelPercentage = stats.fuel / stats.maxFuel
    hudFrame.FuelGauge.FuelBarBG.FuelBar.Size = UDim2.new(fuelPercentage, 0, 1, 0)
    
    -- Warning if fuel is low
    if fuelPercentage < 0.2 then
        hudFrame.FuelGauge.FuelBarBG.FuelBar.BackgroundColor3 = Color3.fromHex("#ff3366")
        -- Add blinking effect
        TweenService:Create(hudFrame.FuelGauge, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
            BackgroundTransparency = 0.5
        }):Play()
    else
        hudFrame.FuelGauge.FuelBarBG.FuelBar.BackgroundColor3 = Color3.fromHex("#ffaa00")
    end
end

-- Initialize the controller
local vehicleController = VehicleController.new()

print("[VehicleController] 🎮 CLIENT VEHICLE FEATURES:")
print("  • Advanced vehicle HUD with gauges")
print("  • Seat-specific control systems")
print("  • Interactive spawn terminals")
print("  • Real-time vehicle status updates")
print("  • Weapon control for gunner seats")
print("  • Visual feedback and warnings")

return vehicleController