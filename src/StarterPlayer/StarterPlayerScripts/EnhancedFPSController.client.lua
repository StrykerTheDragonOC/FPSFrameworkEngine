-- Main Menu System - Players spawn in menu first, deploy to game
-- Place in StarterPlayerScripts
local MainMenuSystem = {}
MainMenuSystem.__index = MainMenuSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local MENU_CONFIG = {
    -- Spawn settings
    MENU_SPAWN_POSITION = Vector3.new(0, 1000, 0), -- High in sky for menu
    GAME_SPAWN_POSITIONS = {
        Vector3.new(0, 10, 0),
        Vector3.new(10, 10, 0), 
        Vector3.new(-10, 10, 0),
        Vector3.new(0, 10, 10),
        Vector3.new(0, 10, -10)
    },

    -- Menu colors (Phantom Forces style)
    COLORS = {
        BACKGROUND = Color3.fromRGB(20, 25, 35),
        PANEL = Color3.fromRGB(35, 40, 50),
        ACCENT = Color3.fromRGB(0, 162, 255),
        TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
        TEXT_SECONDARY = Color3.fromRGB(180, 185, 195),
        DEPLOY_BUTTON = Color3.fromRGB(0, 200, 100),
        WARNING = Color3.fromRGB(255, 170, 0)
    }
}

function MainMenuSystem.new()
    local self = setmetatable({}, MainMenuSystem)

    -- State
    self.isInMenu = true
    self.hasDeployed = false
    self.menuGui = nil
    self.currentLoadout = {
        PRIMARY = "G36",
        SECONDARY = "M9", 
        MELEE = "Karambit",
        GRENADE = "M67"
    }

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the menu system
function MainMenuSystem:initialize()
    -- Wait for character
    if not player.Character then
        player.CharacterAdded:Wait()
    end

    -- Disable default spawn
    player.CharacterAdded:Connect(function(character)
        if not self.hasDeployed then
            -- Move to menu position
            self:moveToMenuPosition(character)
        end
    end)

    -- Create menu GUI
    self:createMainMenu()

    -- Setup character in menu
    if player.Character then
        self:moveToMenuPosition(player.Character)
    end

    print("Main Menu System initialized")
end

-- Move character to menu position
function MainMenuSystem:moveToMenuPosition(character)
    if not character or not character.PrimaryPart then return end

    -- Disable character movement
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end

    -- Move to menu position
    character:SetPrimaryPartCFrame(CFrame.new(MENU_CONFIG.MENU_SPAWN_POSITION))

    -- Make character invisible
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 1
            end
        end
    end
end

-- Create main menu GUI
function MainMenuSystem:createMainMenu()
    -- Create main GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenu"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 200
    screenGui.Parent = playerGui

    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = MENU_CONFIG.COLORS.BACKGROUND
    background.BorderSizePixel = 0
    background.Parent = screenGui

    -- Background pattern/texture
    local pattern = Instance.new("Frame")
    pattern.Size = UDim2.new(1, 0, 1, 0)
    pattern.BackgroundTransparency = 0.95
    pattern.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pattern.BorderSizePixel = 0
    pattern.Parent = background

    -- Main content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    contentFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = background

    -- Left panel - Game info
    self:createLeftPanel(contentFrame)

    -- Center panel - Main menu
    self:createCenterPanel(contentFrame)

    -- Right panel - Player stats/info
    self:createRightPanel(contentFrame)

    self.menuGui = screenGui
end

-- Create left panel
function MainMenuSystem:createLeftPanel(parent)
    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "LeftPanel"
    leftPanel.Size = UDim2.new(0.25, -10, 1, 0)
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    leftPanel.BackgroundTransparency = 0.1
    leftPanel.BorderSizePixel = 0
    leftPanel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = leftPanel

    -- Game title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 60)
    title.Position = UDim2.new(0, 10, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "TACTICAL FPS"
    title.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = leftPanel

    -- Game mode info
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(1, -20, 0, 30)
    modeLabel.Position = UDim2.new(0, 10, 0, 90)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "TEAM DEATHMATCH"
    modeLabel.TextColor3 = MENU_CONFIG.COLORS.ACCENT
    modeLabel.TextScaled = true
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.Parent = leftPanel

    -- Map info
    local mapLabel = Instance.new("TextLabel")
    mapLabel.Size = UDim2.new(1, -20, 0, 25)
    mapLabel.Position = UDim2.new(0, 10, 0, 130)
    mapLabel.BackgroundTransparency = 1
    mapLabel.Text = "Map: Training Grounds"
    mapLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    mapLabel.TextScaled = true
    mapLabel.Font = Enum.Font.Gotham
    mapLabel.Parent = leftPanel

    -- Server info
    local serverInfo = Instance.new("TextLabel")
    serverInfo.Size = UDim2.new(1, -20, 0, 60)
    serverInfo.Position = UDim2.new(0, 10, 1, -100)
    serverInfo.BackgroundTransparency = 1
    serverInfo.Text = "Players: " .. #Players:GetPlayers() .. "/20\nPing: <50ms\nRegion: Auto"
    serverInfo.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    serverInfo.TextScaled = true
    serverInfo.Font = Enum.Font.Gotham
    serverInfo.TextYAlignment = Enum.TextYAlignment.Top
    serverInfo.Parent = leftPanel
end

-- Create center panel (main menu)
function MainMenuSystem:createCenterPanel(parent)
    local centerPanel = Instance.new("Frame")
    centerPanel.Name = "CenterPanel"
    centerPanel.Size = UDim2.new(0.5, -20, 1, 0)
    centerPanel.Position = UDim2.new(0.25, 10, 0, 0)
    centerPanel.BackgroundTransparency = 1
    centerPanel.Parent = parent

    -- Welcome section
    local welcomeFrame = Instance.new("Frame")
    welcomeFrame.Size = UDim2.new(1, 0, 0.3, 0)
    welcomeFrame.Position = UDim2.new(0, 0, 0, 0)
    welcomeFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    welcomeFrame.BackgroundTransparency = 0.1
    welcomeFrame.BorderSizePixel = 0
    welcomeFrame.Parent = centerPanel

    local welcomeCorner = Instance.new("UICorner")
    welcomeCorner.CornerRadius = UDim.new(0, 8)
    welcomeCorner.Parent = welcomeFrame

    local welcomeText = Instance.new("TextLabel")
    welcomeText.Size = UDim2.new(1, -40, 0, 40)
    welcomeText.Position = UDim2.new(0, 20, 0, 20)
    welcomeText.BackgroundTransparency = 1
    welcomeText.Text = "WELCOME, " .. player.Name:upper()
    welcomeText.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    welcomeText.TextScaled = true
    welcomeText.Font = Enum.Font.GothamBold
    welcomeText.Parent = welcomeFrame

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -40, 0, 30)
    statusText.Position = UDim2.new(0, 20, 0, 70)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Select your loadout and deploy to battlefield"
    statusText.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    statusText.TextScaled = true
    statusText.Font = Enum.Font.Gotham
    statusText.Parent = welcomeFrame

    -- Loadout section
    local loadoutFrame = Instance.new("Frame")
    loadoutFrame.Size = UDim2.new(1, 0, 0.4, -10)
    loadoutFrame.Position = UDim2.new(0, 0, 0.3, 10)
    loadoutFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    loadoutFrame.BackgroundTransparency = 0.1
    loadoutFrame.BorderSizePixel = 0
    loadoutFrame.Parent = centerPanel

    local loadoutCorner = Instance.new("UICorner")
    loadoutCorner.CornerRadius = UDim.new(0, 8)
    loadoutCorner.Parent = loadoutFrame

    -- Loadout title
    local loadoutTitle = Instance.new("TextLabel")
    loadoutTitle.Size = UDim2.new(0.7, 0, 0, 30)
    loadoutTitle.Position = UDim2.new(0, 20, 0, 15)
    loadoutTitle.BackgroundTransparency = 1
    loadoutTitle.Text = "CURRENT LOADOUT"
    loadoutTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    loadoutTitle.TextScaled = true
    loadoutTitle.Font = Enum.Font.GothamBold
    loadoutTitle.TextXAlignment = Enum.TextXAlignment.Left
    loadoutTitle.Parent = loadoutFrame

    -- Customize button
    local customizeButton = Instance.new("TextButton")
    customizeButton.Size = UDim2.new(0.25, -10, 0, 30)
    customizeButton.Position = UDim2.new(0.75, 0, 0, 15)
    customizeButton.BackgroundColor3 = MENU_CONFIG.COLORS.ACCENT
    customizeButton.Text = "CUSTOMIZE"
    customizeButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    customizeButton.TextScaled = true
    customizeButton.Font = Enum.Font.GothamBold
    customizeButton.Parent = loadoutFrame

    local customizeCorner = Instance.new("UICorner")
    customizeCorner.CornerRadius = UDim.new(0, 4)
    customizeCorner.Parent = customizeButton

    -- Loadout display
    self:createLoadoutDisplay(loadoutFrame)

    -- Deploy section
    local deployFrame = Instance.new("Frame")
    deployFrame.Size = UDim2.new(1, 0, 0.3, -10)
    deployFrame.Position = UDim2.new(0, 0, 0.7, 10)
    deployFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    deployFrame.BackgroundTransparency = 0.1
    deployFrame.BorderSizePixel = 0
    deployFrame.Parent = centerPanel

    local deployCorner = Instance.new("UICorner")
    deployCorner.CornerRadius = UDim.new(0, 8)
    deployCorner.Parent = deployFrame

    -- Deploy button
    local deployButton = Instance.new("TextButton")
    deployButton.Size = UDim2.new(0.8, 0, 0.5, 0)
    deployButton.Position = UDim2.new(0.1, 0, 0.25, 0)
    deployButton.BackgroundColor3 = MENU_CONFIG.COLORS.DEPLOY_BUTTON
    deployButton.Text = "DEPLOY TO BATTLEFIELD"
    deployButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    deployButton.TextScaled = true
    deployButton.Font = Enum.Font.GothamBold
    deployButton.Parent = deployFrame

    local deployButtonCorner = Instance.new("UICorner")
    deployButtonCorner.CornerRadius = UDim.new(0, 6)
    deployButtonCorner.Parent = deployButton

    -- Connect button events
    customizeButton.MouseButton1Click:Connect(function()
        self:openLoadoutCustomization()
    end)

    deployButton.MouseButton1Click:Connect(function()
        self:deployToGame()
    end)

    -- Button hover effects
    customizeButton.MouseEnter:Connect(function()
        TweenService:Create(customizeButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(30, 182, 255)
        }):Play()
    end)

    customizeButton.MouseLeave:Connect(function()
        TweenService:Create(customizeButton, TweenInfo.new(0.2), {
            BackgroundColor3 = MENU_CONFIG.COLORS.ACCENT
        }):Play()
    end)

    deployButton.MouseEnter:Connect(function()
        TweenService:Create(deployButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(20, 220, 120),
            Size = UDim2.new(0.82, 0, 0.52, 0)
        }):Play()
    end)

    deployButton.MouseLeave:Connect(function()
        TweenService:Create(deployButton, TweenInfo.new(0.2), {
            BackgroundColor3 = MENU_CONFIG.COLORS.DEPLOY_BUTTON,
            Size = UDim2.new(0.8, 0, 0.5, 0)
        }):Play()
    end)
end

-- Create right panel
function MainMenuSystem:createRightPanel(parent)
    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "RightPanel"
    rightPanel.Size = UDim2.new(0.25, -10, 1, 0)
    rightPanel.Position = UDim2.new(0.75, 10, 0, 0)
    rightPanel.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    rightPanel.BackgroundTransparency = 0.1
    rightPanel.BorderSizePixel = 0
    rightPanel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = rightPanel

    -- Player stats title
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, -20, 0, 40)
    statsTitle.Position = UDim2.new(0, 10, 0, 20)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "PLAYER STATS"
    statsTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    statsTitle.TextScaled = true
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.Parent = rightPanel

    -- Stats display
    local statsText = Instance.new("TextLabel")
    statsText.Size = UDim2.new(1, -20, 0, 200)
    statsText.Position = UDim2.new(0, 10, 0, 70)
    statsText.BackgroundTransparency = 1
    statsText.Text = "Level: 25\nKills: 1,247\nDeaths: 856\nK/D: 1.46\nAccuracy: 67%\nFavorite Weapon: G36\nPlaytime: 23h 42m"
    statsText.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    statsText.TextScaled = true
    statsText.Font = Enum.Font.Gotham
    statsText.TextYAlignment = Enum.TextYAlignment.Top
    statsText.Parent = rightPanel

    -- Recent matches
    local recentTitle = Instance.new("TextLabel")
    recentTitle.Size = UDim2.new(1, -20, 0, 30)
    recentTitle.Position = UDim2.new(0, 10, 0, 290)
    recentTitle.BackgroundTransparency = 1
    recentTitle.Text = "RECENT MATCHES"
    recentTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    recentTitle.TextScaled = true
    recentTitle.Font = Enum.Font.GothamBold
    recentTitle.Parent = rightPanel

    local recentText = Instance.new("TextLabel")
    recentText.Size = UDim2.new(1, -20, 0, 120)
    recentText.Position = UDim2.new(0, 10, 0, 330)
    recentText.BackgroundTransparency = 1
    recentText.Text = "Victory - Metro\n24/12 K/D\n\nDefeat - Warehouse\n18/15 K/D\n\nVictory - Bazaar\n31/8 K/D"
    recentText.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    recentText.TextScaled = true
    recentText.Font = Enum.Font.Gotham
    recentText.TextYAlignment = Enum.TextYAlignment.Top
    recentText.Parent = rightPanel
end

-- Create loadout display
function MainMenuSystem:createLoadoutDisplay(parent)
    local weapons = {
        {slot = "PRIMARY", weapon = self.currentLoadout.PRIMARY, icon = "??"},
        {slot = "SECONDARY", weapon = self.currentLoadout.SECONDARY, icon = "??"},
        {slot = "MELEE", weapon = self.currentLoadout.MELEE, icon = "???"},
        {slot = "GRENADE", weapon = self.currentLoadout.GRENADE, icon = "??"}
    }

    for i, data in ipairs(weapons) do
        local weaponFrame = Instance.new("Frame")
        weaponFrame.Size = UDim2.new(0.45, 0, 0.3, 0)
        weaponFrame.Position = UDim2.new(
            ((i-1) % 2) * 0.5 + 0.05, 0,
            math.floor((i-1) / 2) * 0.35 + 0.4, 0
        )
        weaponFrame.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
        weaponFrame.BorderSizePixel = 0
        weaponFrame.Parent = parent

        local weaponCorner = Instance.new("UICorner")
        weaponCorner.CornerRadius = UDim.new(0, 4)
        weaponCorner.Parent = weaponFrame

        local slotLabel = Instance.new("TextLabel")
        slotLabel.Size = UDim2.new(1, -10, 0, 15)
        slotLabel.Position = UDim2.new(0, 5, 0, 5)
        slotLabel.BackgroundTransparency = 1
        slotLabel.Text = data.slot
        slotLabel.TextColor3 = MENU_CONFIG.COLORS.ACCENT
        slotLabel.TextScaled = true
        slotLabel.Font = Enum.Font.Gotham
        slotLabel.Parent = weaponFrame

        local weaponName = Instance.new("TextLabel")
        weaponName.Size = UDim2.new(1, -10, 0, 20)
        weaponName.Position = UDim2.new(0, 5, 1, -25)
        weaponName.BackgroundTransparency = 1
        weaponName.Text = data.weapon
        weaponName.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        weaponName.TextScaled = true
        weaponName.Font = Enum.Font.GothamBold
        weaponName.Parent = weaponFrame
    end
end

-- Open loadout customization
function MainMenuSystem:openLoadoutCustomization()
    if _G.EnhancedLoadoutSelector then
        _G.EnhancedLoadoutSelector:openMenu()
    else
        print("Loading loadout customization...")
        -- Fallback to basic loadout selector
        if _G.LoadoutSelector then
            _G.LoadoutSelector:openGUI()
        end
    end
end

-- Deploy to game
function MainMenuSystem:deployToGame()
    if self.hasDeployed then return end

    print("Deploying to battlefield...")
    self.hasDeployed = true
    self.isInMenu = false

    -- Play deploy sound
    local deploySound = Instance.new("Sound")
    deploySound.SoundId = "rbxassetid://131961136" -- Replace with actual sound
    deploySound.Volume = 0.5
    deploySound.Parent = SoundService
    deploySound:Play()

    -- Fade out menu
    TweenService:Create(self.menuGui, TweenInfo.new(1), {
        BackgroundTransparency = 1
    }):Play()

    -- Move character to game
    if player.Character then
        self:spawnInGame()
    end

    -- Destroy menu after fade
    game:GetService("Debris"):AddItem(self.menuGui, 1.5)

    -- Initialize FPS systems
    task.delay(1, function()
        self:initializeFPSSystems()
    end)
end

-- Spawn character in game
function MainMenuSystem:spawnInGame()
    local character = player.Character
    if not character or not character.PrimaryPart then return end

    -- Choose random spawn position
    local spawnPos = MENU_CONFIG.GAME_SPAWN_POSITIONS[math.random(1, #MENU_CONFIG.GAME_SPAWN_POSITIONS)]

    -- Enable character movement
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end

    -- Move to spawn position
    character:SetPrimaryPartCFrame(CFrame.new(spawnPos))

    -- Make character visible
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 0
            end
        end
    end

    print("Player deployed to position:", spawnPos)
end

-- Initialize FPS systems after deploy
function MainMenuSystem:initializeFPSSystems()
    -- Apply current loadout
    if _G.FPSController then
        for slot, weapon in pairs(self.currentLoadout) do
            _G.FPSController:loadWeapon(slot, weapon)
        end
        _G.FPSController:equipWeapon("PRIMARY")
    end

    -- Enable camera controls
    if _G.FPSCameraMouseControl then
        _G.FPSCameraMouseControl.lockMouse()
    end

    -- Initialize HUD
    if _G.AdvancedUISystem then
        _G.AdvancedUISystem:initialize()
    end

    print("FPS systems initialized")
end

-- Update current loadout
function MainMenuSystem:updateLoadout(newLoadout)
    self.currentLoadout = newLoadout
    -- Update loadout display if menu is open
    if self.menuGui then
        -- Refresh loadout display
        local loadoutFrame = self.menuGui:FindFirstChild("Background"):FindFirstChild("ContentFrame"):FindFirstChild("CenterPanel"):FindFirstChild("Frame")
        if loadoutFrame then
            -- Clear and recreate loadout display
            for _, child in pairs(loadoutFrame:GetChildren()) do
                if child.Name:find("Frame") then
                    child:Destroy()
                end
            end
            self:createLoadoutDisplay(loadoutFrame)
        end
    end
end

-- Check if player is in menu
function MainMenuSystem:isPlayerInMenu()
    return self.isInMenu and not self.hasDeployed
end

-- Initialize the system
local mainMenu = MainMenuSystem.new()

-- Export globally
_G.MainMenuSystem = mainMenu

return MainMenuSystem