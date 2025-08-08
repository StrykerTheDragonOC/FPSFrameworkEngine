-- AttachmentTester.client.lua
-- Client script for testing attachments during development
-- Provides GUI for easy attachment testing

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get modules
local AttachmentSystem = require(ReplicatedStorage.FPSSystem.Modules.AttachmentSystem)
local WeaponManager = require(ReplicatedStorage.FPSSystem.Modules.WeaponManager)

local AttachmentTester = {}

-- Available attachments for testing
local testAttachments = {
    -- Barrel Attachments
    {name = "Suppressor", type = "BarrelAttachment", category = "Barrel"},
    {name = "Compensator", type = "BarrelAttachment", category = "Barrel"},
    {name = "FlashHider", type = "BarrelAttachment", category = "Barrel"},
    
    -- Optic Attachments
    {name = "RedDot", type = "OpticAttachment", category = "Optic"},
    {name = "Holographic", type = "OpticAttachment", category = "Optic"},
    {name = "ACOG", type = "OpticAttachment", category = "Optic"},
    {name = "Scope", type = "OpticAttachment", category = "Optic"},
    
    -- Underbarrel Attachments
    {name = "Foregrip", type = "UnderbarrelAttachment", category = "Underbarrel"},
    {name = "Bipod", type = "UnderbarrelAttachment", category = "Underbarrel"},
    {name = "LaserSight", type = "UnderbarrelAttachment", category = "Underbarrel"},
    
    -- Other Attachments
    {name = "ExtendedMag", type = "MagAttachment", category = "Magazine"},
    {name = "QuickDraw", type = "GripAttachment", category = "Grip"},
}

-- Create GUI
function AttachmentTester:createGUI()
    -- Main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AttachmentTester"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.Text = "Attachment Tester"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Current weapon label
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Name = "WeaponLabel"
    weaponLabel.Size = UDim2.new(1, -20, 0, 30)
    weaponLabel.Position = UDim2.new(0, 10, 0, 50)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Text = "Current Weapon: None"
    weaponLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    weaponLabel.TextScaled = true
    weaponLabel.Font = Enum.Font.SourceSans
    weaponLabel.Parent = mainFrame
    
    -- Scroll frame for attachments
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "AttachmentScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -140)
    scrollFrame.Position = UDim2.new(0, 10, 0, 90)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = mainFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 4)
    scrollCorner.Parent = scrollFrame
    
    -- Layout for attachment buttons
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.Name
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scrollFrame
    
    -- Create attachment buttons
    for _, attachment in ipairs(testAttachments) do
        self:createAttachmentButton(scrollFrame, attachment)
    end
    
    -- Update canvas size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Clear all button
    local clearButton = Instance.new("TextButton")
    clearButton.Size = UDim2.new(1, -20, 0, 35)
    clearButton.Position = UDim2.new(0, 10, 1, -45)
    clearButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    clearButton.Text = "Clear All Attachments"
    clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearButton.TextScaled = true
    clearButton.Font = Enum.Font.SourceSansBold
    clearButton.Parent = mainFrame
    
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 4)
    clearCorner.Parent = clearButton
    
    -- Clear button functionality
    clearButton.MouseButton1Click:Connect(function()
        self:clearAllAttachments()
    end)
    
    -- Store references
    self.gui = screenGui
    self.weaponLabel = weaponLabel
    
    return screenGui
end

-- Create attachment button
function AttachmentTester:createAttachmentButton(parent, attachment)
    local button = Instance.new("TextButton")
    button.Name = attachment.name .. "Button"
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.Text = attachment.name .. " (" .. attachment.category .. ")"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSans
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    -- Button hover effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end)
    
    -- Button click functionality
    button.MouseButton1Click:Connect(function()
        self:toggleAttachment(attachment)
    end)
    
    return button
end

-- Toggle attachment on current weapon
function AttachmentTester:toggleAttachment(attachment)
    local currentWeapon = self:getCurrentWeapon()
    if not currentWeapon then
        print("No weapon equipped!")
        return
    end
    
    -- Check if attachment is compatible
    if not self:isAttachmentCompatible(currentWeapon, attachment) then
        print("Attachment", attachment.name, "is not compatible with", currentWeapon)
        return
    end
    
    -- Toggle the attachment
    local isAttached = AttachmentSystem:hasAttachment(currentWeapon, attachment.type, attachment.name)
    
    if isAttached then
        AttachmentSystem:removeAttachment(currentWeapon, attachment.type)
        print("Removed", attachment.name, "from", currentWeapon)
    else
        AttachmentSystem:attachAttachment(currentWeapon, attachment.type, attachment.name)
        print("Attached", attachment.name, "to", currentWeapon)
    end
end

-- Clear all attachments from current weapon
function AttachmentTester:clearAllAttachments()
    local currentWeapon = self:getCurrentWeapon()
    if not currentWeapon then
        print("No weapon equipped!")
        return
    end
    
    AttachmentSystem:clearAllAttachments(currentWeapon)
    print("Cleared all attachments from", currentWeapon)
end

-- Get current weapon
function AttachmentTester:getCurrentWeapon()
    local character = player.Character
    if not character then return nil end
    
    -- Check for FPSClientController global or current weapon state
    if _G.FPSController and _G.FPSController.state and _G.FPSController.state.currentWeapon then
        return _G.FPSController.state.currentWeapon.name
    end
    
    -- Check for tool in character
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child.Name
        end
    end
    
    -- Default weapons for testing
    return "G36"
end

-- Check if attachment is compatible with weapon
function AttachmentTester:isAttachmentCompatible(weaponName, attachment)
    -- Get weapon viewmodel to check for attachment points
    local viewmodelPath = "ReplicatedStorage.FPSSystem.ViewModels"
    
    -- Search through weapon categories
    local categories = {"Primary", "Secondary", "Grenades", "Melee"}
    local subcategories = {
        Primary = {"AssaultRIfles", "BattleRifles", "Carbines", "DMRS", "LMGS", "Shotguns", "SMGS", "SniperRifles"},
        Secondary = {"AutomaticPistols", "Other", "Pistols", "Revolvers"},
        Grenades = {"Explosive", "Impact", "Tactical"},
        Melee = {"BladeOneHand", "BladeTwoHand", "BluntOneHand", "BluntTwoHand"}
    }
    
    -- Find the weapon model
    for _, category in ipairs(categories) do
        if subcategories[category] then
            for _, subcategory in ipairs(subcategories[category]) do
                local path = string.format("%s.%s.%s.%s", viewmodelPath, category, subcategory, weaponName)
                local success, model = pcall(function()
                    return game:GetService("ReplicatedStorage"):FindFirstChild("FPSSystem")
                        :FindFirstChild("ViewModels")
                        :FindFirstChild(category)
                        :FindFirstChild(subcategory)
                        :FindFirstChild(weaponName)
                end)
                
                if success and model then
                    -- Check if the attachment point exists
                    return model:FindFirstChild(attachment.type) ~= nil
                end
            end
        end
    end
    
    return false
end

-- Update weapon label
function AttachmentTester:updateWeaponLabel()
    if not self.weaponLabel then return end
    
    local currentWeapon = self:getCurrentWeapon()
    if currentWeapon then
        self.weaponLabel.Text = "Current Weapon: " .. currentWeapon
    else
        self.weaponLabel.Text = "Current Weapon: None"
    end
end

-- Initialize the tester
function AttachmentTester:init()
    self:createGUI()
    
    -- Update weapon label periodically
    spawn(function()
        while true do
            wait(1)
            self:updateWeaponLabel()
        end
    end)
    
    -- Hide/show GUI with F3
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F3 then
            if self.gui then
                self.gui.Enabled = not self.gui.Enabled
            end
        end
    end)
    
    print("Attachment Tester initialized! Press F3 to toggle GUI.")
end

-- Auto-initialize when script runs
spawn(function()
    wait(2) -- Wait for other systems to load
    AttachmentTester:init()
end)

-- Create test weapon function for easy testing
local function createTestWeapon(weaponName)
    local tool = Instance.new("Tool")
    tool.Name = weaponName
    tool.Parent = workspace
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 4)
    handle.Parent = tool
    handle.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -5)
    
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = handle
    
    clickDetector.MouseClick:Connect(function(player)
        tool.Parent = player.Backpack
    end)
    
    print("Created test weapon:", weaponName, "in workspace. Click to equip.")
end

-- Debug functions for testing
_G.createTestWeapon = createTestWeapon
_G.AttachmentTester = AttachmentTester

return AttachmentTester
