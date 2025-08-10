-- CrosshairSystem.lua
-- Dynamic crosshair system for FPS framework
-- Place in ReplicatedStorage.FPSSystem.Modules

local CrosshairSystem = {}
CrosshairSystem.__index = CrosshairSystem

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function CrosshairSystem.new()
    local self = setmetatable({}, CrosshairSystem)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")

    -- Crosshair state
    self.isVisible = true
    self.spread = 0
    self.currentWeapon = nil

    -- Create crosshair GUI
    self:createCrosshairGui()

    print("CrosshairSystem initialized")
    return self
end

function CrosshairSystem:createCrosshairGui()
    -- Create ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "CrosshairGui"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.Parent = self.playerGui

    -- Create main crosshair frame
    self.crosshairFrame = Instance.new("Frame")
    self.crosshairFrame.Name = "CrosshairFrame"
    self.crosshairFrame.Size = UDim2.new(0, 100, 0, 100)
    self.crosshairFrame.Position = UDim2.new(0.5, -50, 0.5, -50)
    self.crosshairFrame.BackgroundTransparency = 1
    self.crosshairFrame.Parent = self.screenGui

    -- Create crosshair lines
    local lineThickness = 2
    local lineLength = 20
    local gap = 5

    -- Top line
    self.topLine = Instance.new("Frame")
    self.topLine.Name = "TopLine"
    self.topLine.Size = UDim2.new(0, lineThickness, 0, lineLength)
    self.topLine.Position = UDim2.new(0.5, -lineThickness/2, 0.5, -gap - lineLength)
    self.topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.topLine.BorderSizePixel = 0
    self.topLine.Parent = self.crosshairFrame

    -- Bottom line
    self.bottomLine = Instance.new("Frame")
    self.bottomLine.Name = "BottomLine"
    self.bottomLine.Size = UDim2.new(0, lineThickness, 0, lineLength)
    self.bottomLine.Position = UDim2.new(0.5, -lineThickness/2, 0.5, gap)
    self.bottomLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.bottomLine.BorderSizePixel = 0
    self.bottomLine.Parent = self.crosshairFrame

    -- Left line
    self.leftLine = Instance.new("Frame")
    self.leftLine.Name = "LeftLine"
    self.leftLine.Size = UDim2.new(0, lineLength, 0, lineThickness)
    self.leftLine.Position = UDim2.new(0.5, -gap - lineLength, 0.5, -lineThickness/2)
    self.leftLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.leftLine.BorderSizePixel = 0
    self.leftLine.Parent = self.crosshairFrame

    -- Right line
    self.rightLine = Instance.new("Frame")
    self.rightLine.Name = "RightLine"
    self.rightLine.Size = UDim2.new(0, lineLength, 0, lineThickness)
    self.rightLine.Position = UDim2.new(0.5, gap, 0.5, -lineThickness/2)
    self.rightLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.rightLine.BorderSizePixel = 0
    self.rightLine.Parent = self.crosshairFrame

    -- Center dot
    self.centerDot = Instance.new("Frame")
    self.centerDot.Name = "CenterDot"
    self.centerDot.Size = UDim2.new(0, 2, 0, 2)
    self.centerDot.Position = UDim2.new(0.5, -1, 0.5, -1)
    self.centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.centerDot.BorderSizePixel = 0
    self.centerDot.Parent = self.crosshairFrame
end

function CrosshairSystem:setVisible(visible)
    self.isVisible = visible
    self.screenGui.Enabled = visible
end

function CrosshairSystem:updateSpread(spread)
    self.spread = spread or 0

    local gap = 5 + self.spread
    local lineLength = 20
    local lineThickness = 2

    -- Update positions based on spread
    self.topLine.Position = UDim2.new(0.5, -lineThickness/2, 0.5, -gap - lineLength)
    self.bottomLine.Position = UDim2.new(0.5, -lineThickness/2, 0.5, gap)
    self.leftLine.Position = UDim2.new(0.5, -gap - lineLength, 0.5, -lineThickness/2)
    self.rightLine.Position = UDim2.new(0.5, gap, 0.5, -lineThickness/2)
end

function CrosshairSystem:setColor(color)
    color = color or Color3.fromRGB(255, 255, 255)

    self.topLine.BackgroundColor3 = color
    self.bottomLine.BackgroundColor3 = color
    self.leftLine.BackgroundColor3 = color
    self.rightLine.BackgroundColor3 = color
    self.centerDot.BackgroundColor3 = color
end

function CrosshairSystem:updateFromWeaponState(weaponConfig, isAiming)
    if not weaponConfig then return end

    -- Adjust crosshair based on weapon and aiming state
    local baseSpread = weaponConfig.spread or 10
    local aimingMultiplier = isAiming and 0.3 or 1.0

    self:updateSpread(baseSpread * aimingMultiplier)

    -- Change color based on aiming
    if isAiming then
        self:setColor(Color3.fromRGB(255, 200, 200)) -- Light red when aiming
    else
        self:setColor(Color3.fromRGB(255, 255, 255)) -- White normally
    end
end

function CrosshairSystem:setMovementState(stateType, active)
    -- Adjust crosshair based on movement states
    if stateType == "moving" and active then
        self:updateSpread(self.spread + 5)
    elseif stateType == "jumping" and active then
        self:updateSpread(self.spread + 15)
    elseif stateType == "crouching" and active then
        self:updateSpread(self.spread - 3)
    end
end

function CrosshairSystem:cleanup()
    if self.screenGui then
        self.screenGui:Destroy()
    end
end

return CrosshairSystem