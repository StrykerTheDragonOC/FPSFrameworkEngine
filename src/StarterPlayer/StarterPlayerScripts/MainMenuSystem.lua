-- Enhanced Main Menu System - Players spawn in menu first, deploy to game
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

-- Complete weapon database from the project knowledge
local WEAPON_DATABASE = {
    PRIMARY = {
        -- ASSAULT RIFLES
        ["G36"] = {category = "ASSAULT RIFLE", unlockRank = 0, damage = 25, range = 85, mobility = 68, rpm = 600, unlocked = true},
        ["M16A4"] = {category = "ASSAULT RIFLE", unlockRank = 5, damage = 30, range = 90, mobility = 65, rpm = 700, unlocked = false},
        ["AK74"] = {category = "ASSAULT RIFLE", unlockRank = 10, damage = 35, range = 88, mobility = 62, rpm = 650, unlocked = false},
        ["M4A1"] = {category = "ASSAULT RIFLE", unlockRank = 15, damage = 28, range = 85, mobility = 70, rpm = 750, unlocked = false},
        ["SCAR-L"] = {category = "ASSAULT RIFLE", unlockRank = 25, damage = 32, range = 92, mobility = 63, rpm = 625, unlocked = false},
        ["AUG A1"] = {category = "ASSAULT RIFLE", unlockRank = 35, damage = 29, range = 88, mobility = 66, rpm = 680, unlocked = false},
        ["FAMAS"] = {category = "ASSAULT RIFLE", unlockRank = 45, damage = 26, range = 80, mobility = 72, rpm = 900, unlocked = false},
        ["AS VAL"] = {category = "ASSAULT RIFLE", unlockRank = 55, damage = 40, range = 65, mobility = 58, rpm = 525, unlocked = false},
        ["FAL 50.00"] = {category = "ASSAULT RIFLE", unlockRank = 60, damage = 58, range = 100, mobility = 52, rpm = 475, unlocked = false},

        -- CARBINES
        ["M4A4"] = {category = "CARBINE", unlockRank = 18, damage = 35, range = 65, mobility = 78, rpm = 725, unlocked = false},
        ["AK-12C"] = {category = "CARBINE", unlockRank = 28, damage = 40, range = 68, mobility = 75, rpm = 675, unlocked = false},
        ["G36C"] = {category = "CARBINE", unlockRank = 22, damage = 33, range = 62, mobility = 80, rpm = 700, unlocked = false},

        -- DMRs
        ["MK11"] = {category = "DMR", unlockRank = 70, damage = 65, range = 120, mobility = 45, rpm = 275, unlocked = false},
        ["SKS"] = {category = "DMR", unlockRank = 55, damage = 62, range = 115, mobility = 48, rpm = 300, unlocked = false},
        ["VSS VINTOREZ"] = {category = "DMR", unlockRank = 85, damage = 58, range = 95, mobility = 52, rpm = 325, unlocked = false},

        -- SNIPER RIFLES
        ["INTERVENTION"] = {category = "SNIPER RIFLE", unlockRank = 0, damage = 95, range = 150, mobility = 35, rpm = 45, unlocked = true},
        ["REMINGTON 700"] = {category = "SNIPER RIFLE", unlockRank = 10, damage = 92, range = 145, mobility = 38, rpm = 50, unlocked = false},
        ["AWP"] = {category = "SNIPER RIFLE", unlockRank = 80, damage = 115, range = 160, mobility = 30, rpm = 40, unlocked = false},
        ["TRG-42"] = {category = "SNIPER RIFLE", unlockRank = 95, damage = 105, range = 155, mobility = 32, rpm = 42, unlocked = false},
        ["NTW-20"] = {category = "SNIPER RIFLE", unlockRank = 125, damage = 125, range = 180, mobility = 25, rpm = 35, unlocked = false},

        -- PDWs
        ["M41"] = {category = "PDW", unlockRank = 20, damage = 24, range = 45, mobility = 85, rpm = 800, unlocked = false},
        ["G36K"] = {category = "PDW", unlockRank = 30, damage = 26, range = 48, mobility = 82, rpm = 750, unlocked = false},
        ["M4"] = {category = "PDW", unlockRank = 40, damage = 28, range = 50, mobility = 80, rpm = 725, unlocked = false},

        -- SHOTGUNS
        ["L22"] = {category = "SHOTGUN", unlockRank = 12, damage = 85, range = 25, mobility = 65, rpm = 120, unlocked = false},
        ["SCAR PDW"] = {category = "SHOTGUN", unlockRank = 25, damage = 90, range = 22, mobility = 70, rpm = 100, unlocked = false},
        ["AK-12U"] = {category = "SHOTGUN", unlockRank = 35, damage = 88, range = 28, mobility = 68, rpm = 110, unlocked = false}
    },

    SECONDARY = {
        -- PISTOLS
        ["M9"] = {category = "PISTOLS", unlockRank = 0, damage = 28, range = 35, mobility = 95, rpm = 400, unlocked = true},
        ["GLOCK 17"] = {category = "PISTOLS", unlockRank = 5, damage = 26, range = 32, mobility = 98, rpm = 425, unlocked = false},
        ["USP .45"] = {category = "PISTOLS", unlockRank = 15, damage = 38, range = 38, mobility = 88, rpm = 350, unlocked = false},
        ["P226"] = {category = "PISTOLS", unlockRank = 20, damage = 32, range = 36, mobility = 92, rpm = 375, unlocked = false},
        ["DESERT EAGLE XIX"] = {category = "PISTOLS", unlockRank = 75, damage = 55, range = 45, mobility = 78, rpm = 275, unlocked = false},
        ["M1911"] = {category = "PISTOLS", unlockRank = 25, damage = 42, range = 38, mobility = 85, rpm = 320, unlocked = false},

        -- MACHINE PISTOLS
        ["TMP"] = {category = "MACHINE PISTOLS", unlockRank = 45, damage = 22, range = 28, mobility = 92, rpm = 950, unlocked = false},
        ["G18"] = {category = "MACHINE PISTOLS", unlockRank = 55, damage = 24, range = 30, mobility = 90, rpm = 900, unlocked = false},

        -- REVOLVERS
        ["MP412 REX"] = {category = "REVOLVERS", unlockRank = 40, damage = 68, range = 50, mobility = 70, rpm = 180, unlocked = false},
        ["JUDGE"] = {category = "REVOLVERS", unlockRank = 65, damage = 45, range = 25, mobility = 75, rpm = 200, unlocked = false}
    },

    MELEE = {
        -- BLADES
        ["KNIFE"] = {category = "BLADE", unlockRank = 0, damage = 85, range = 5, mobility = 100, rpm = 200, unlocked = true},
        ["KARAMBIT"] = {category = "BLADE", unlockRank = 50, damage = 90, range = 4, mobility = 105, rpm = 185, unlocked = false},
        ["TOMAHAWK"] = {category = "BLADE", unlockRank = 75, damage = 95, range = 6, mobility = 95, rpm = 175, unlocked = false}
    },

    GRENADE = {
        -- EXPLOSIVE
        ["M67 FRAG"] = {category = "EXPLOSIVE", unlockRank = 0, damage = 100, range = 15, mobility = 90, rpm = 60, unlocked = true},
        ["RGD-5"] = {category = "EXPLOSIVE", unlockRank = 20, damage = 95, range = 18, mobility = 88, rpm = 65, unlocked = false},

        -- TACTICAL
        ["FLASHBANG"] = {category = "TACTICAL", unlockRank = 15, damage = 0, range = 12, mobility = 95, rpm = 45, unlocked = false},
        ["SMOKE GRENADE"] = {category = "TACTICAL", unlockRank = 25, damage = 0, range = 20, mobility = 92, rpm = 40, unlocked = false}
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
        MELEE = "KNIFE",
        GRENADE = "M67 FRAG"
    }

    -- Player data (start at zero unless loaded from datastore)
    self.playerStats = {
        level = 1,
        kills = 0,
        deaths = 0,
        kd = 0,
        accuracy = 0,
        favoriteWeapon = "G36",
        playtime = "0h 0m",
        credits = 0
    }

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the menu system
function MainMenuSystem:initialize()
    -- FIXED: Ensure mouse is unlocked in menu
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    -- Disable camera controls while in menu
    if _G.FPSCameraMouseControl then
        _G.FPSCameraMouseControl.unlockMouse()
    end

    -- Wait for character
    if not player.Character then
        player.CharacterAdded:Wait()
    end

    -- Setup character spawning
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

    -- Load player data from server
    self:requestPlayerData()

    print("Main Menu System initialized - Mouse unlocked for menu navigation")
end

-- Request player data from server
function MainMenuSystem:requestPlayerData()
    local dataRequest = ReplicatedStorage:FindFirstChild("PlayerDataRequest")
    if dataRequest then
        dataRequest:FireServer()
    end

    -- Listen for data updates
    local dataUpdate = ReplicatedStorage:FindFirstChild("PlayerDataUpdate")
    if dataUpdate then
        dataUpdate.OnClientEvent:Connect(function(data)
            self:updatePlayerStats(data)
        end)
    end
end

-- Update player stats from server data
function MainMenuSystem:updatePlayerStats(data)
    if not data then return end

    self.playerStats = {
        level = data.level or 1,
        kills = data.kills or 0,
        deaths = data.deaths or 0,
        kd = data.deaths > 0 and math.floor((data.kills / data.deaths) * 100) / 100 or data.kills,
        accuracy = data.accuracy or 0,
        favoriteWeapon = data.favoriteWeapon or "G36",
        playtime = self:formatPlaytime(data.playtime or 0),
        credits = data.credits or 0
    }

    -- Update unlocked weapons based on level
    self:updateUnlockedWeapons(data.level or 1)

    -- Refresh UI if menu is open
    if self.menuGui then
        self:refreshPlayerStatsDisplay()
    end
end

-- Update unlocked weapons based on level
function MainMenuSystem:updateUnlockedWeapons(level)
    for slot, weapons in pairs(WEAPON_DATABASE) do
        for weaponName, weaponData in pairs(weapons) do
            weaponData.unlocked = level >= weaponData.unlockRank
        end
    end
end

-- Format playtime from seconds to readable format
function MainMenuSystem:formatPlaytime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%dh %dm", hours, minutes)
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
    serverInfo.Name = "ServerInfo"
    serverInfo.Size = UDim2.new(1, -20, 0, 60)
    serverInfo.Position = UDim2.new(0, 10, 1, -100)
    serverInfo.BackgroundTransparency = 1
    serverInfo.Text = "Players: " .. #Players:GetPlayers() .. "/20\nPing: <50ms\nRegion: Auto"
    serverInfo.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    serverInfo.TextScaled = true
    serverInfo.Font = Enum.Font.Gotham
    serverInfo.TextYAlignment = Enum.TextYAlignment.Top
    serverInfo.Parent = leftPanel

    -- Update server info periodically
    spawn(function()
        while self.isInMenu do
            serverInfo.Text = "Players: " .. #Players:GetPlayers() .. "/20\nPing: <50ms\nRegion: Auto"
            wait(5)
        end
    end)
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
    loadoutFrame.Name = "LoadoutFrame"
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
        self:openWeaponCustomization()
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
    statsText.Name = "StatsText"
    statsText.Size = UDim2.new(1, -20, 0, 200)
    statsText.Position = UDim2.new(0, 10, 0, 70)
    statsText.BackgroundTransparency = 1
    statsText.Text = self:getStatsDisplayText()
    statsText.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    statsText.TextScaled = true
    statsText.Font = Enum.Font.Gotham
    statsText.TextYAlignment = Enum.TextYAlignment.Top
    statsText.Parent = rightPanel

    -- Credits display
    local creditsFrame = Instance.new("Frame")
    creditsFrame.Size = UDim2.new(1, -20, 0, 50)
    creditsFrame.Position = UDim2.new(0, 10, 0, 280)
    creditsFrame.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
    creditsFrame.BorderSizePixel = 0
    creditsFrame.Parent = rightPanel

    local creditsCorner = Instance.new("UICorner")
    creditsCorner.CornerRadius = UDim.new(0, 4)
    creditsCorner.Parent = creditsFrame

    local creditsLabel = Instance.new("TextLabel")
    creditsLabel.Size = UDim2.new(1, -10, 0, 20)
    creditsLabel.Position = UDim2.new(0, 5, 0, 5)
    creditsLabel.BackgroundTransparency = 1
    creditsLabel.Text = "CREDITS"
    creditsLabel.TextColor3 = MENU_CONFIG.COLORS.ACCENT
    creditsLabel.TextScaled = true
    creditsLabel.Font = Enum.Font.Gotham
    creditsLabel.Parent = creditsFrame

    local creditsValue = Instance.new("TextLabel")
    creditsValue.Name = "CreditsValue"
    creditsValue.Size = UDim2.new(1, -10, 0, 20)
    creditsValue.Position = UDim2.new(0, 5, 1, -25)
    creditsValue.BackgroundTransparency = 1
    creditsValue.Text = "$" .. self.playerStats.credits
    creditsValue.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    creditsValue.TextScaled = true
    creditsValue.Font = Enum.Font.GothamBold
    creditsValue.Parent = creditsFrame

    -- Recent matches
    local recentTitle = Instance.new("TextLabel")
    recentTitle.Size = UDim2.new(1, -20, 0, 30)
    recentTitle.Position = UDim2.new(0, 10, 0, 350)
    recentTitle.BackgroundTransparency = 1
    recentTitle.Text = "RECENT MATCHES"
    recentTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    recentTitle.TextScaled = true
    recentTitle.Font = Enum.Font.GothamBold
    recentTitle.Parent = rightPanel

    local recentText = Instance.new("TextLabel")
    recentText.Size = UDim2.new(1, -20, 0, 120)
    recentText.Position = UDim2.new(0, 10, 0, 390)
    recentText.BackgroundTransparency = 1
    recentText.Text = "No recent matches\nDeploy to start playing!"
    recentText.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    recentText.TextScaled = true
    recentText.Font = Enum.Font.Gotham
    recentText.TextYAlignment = Enum.TextYAlignment.Top
    recentText.Parent = rightPanel
end

-- Get stats display text
function MainMenuSystem:getStatsDisplayText()
    return string.format("Level: %d\nKills: %d\nDeaths: %d\nK/D: %.2f\nAccuracy: %d%%\nFavorite Weapon: %s\nPlaytime: %s",
        self.playerStats.level,
        self.playerStats.kills,
        self.playerStats.deaths,
        self.playerStats.kd,
        self.playerStats.accuracy,
        self.playerStats.favoriteWeapon,
        self.playerStats.playtime
    )
end

-- Refresh player stats display
function MainMenuSystem:refreshPlayerStatsDisplay()
    if not self.menuGui then return end

    local statsText = self.menuGui:FindFirstChild("Background"):FindFirstChild("ContentFrame"):FindFirstChild("RightPanel"):FindFirstChild("StatsText")
    if statsText then
        statsText.Text = self:getStatsDisplayText()
    end

    local creditsValue = self.menuGui:FindFirstChild("Background"):FindFirstChild("ContentFrame"):FindFirstChild("RightPanel"):FindFirstChild("Frame"):FindFirstChild("CreditsValue")
    if creditsValue then
        creditsValue.Text = "$" .. self.playerStats.credits
    end
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
        weaponFrame.Name = "WeaponSlot" .. i
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

-- FIXED: Open separate weapon customization instead of loadout selector
function MainMenuSystem:openWeaponCustomization()
    if _G.WeaponCustomizationSystem then
        _G.WeaponCustomizationSystem:openMenu(self.currentLoadout, WEAPON_DATABASE)
    else
        print("Loading weapon customization system...")
        -- Create the weapon customization system
        self:createWeaponCustomizationSystem()
    end
end

-- Create weapon customization system
function MainMenuSystem:createWeaponCustomizationSystem()
    local WeaponCustomizationSystem = self:createWeaponCustomizationClass()
    _G.WeaponCustomizationSystem = WeaponCustomizationSystem.new()
    _G.WeaponCustomizationSystem:openMenu(self.currentLoadout, WEAPON_DATABASE)
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

    -- FIXED: Initialize FPS systems after deploy (not in menu)
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

-- FIXED: Initialize FPS systems after deploy (prevents viewmodel errors in menu)
function MainMenuSystem:initializeFPSSystems()
    -- Enable mouse lock for FPS controls
    if _G.FPSCameraMouseControl then
        _G.FPSCameraMouseControl.lockMouse()
    end
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    -- Apply current loadout
    if _G.EnhancedFPSController then
        for slot, weapon in pairs(self.currentLoadout) do
            _G.EnhancedFPSController:loadWeapon(slot, weapon)
        end
        _G.EnhancedFPSController:equipWeapon("PRIMARY")
    elseif _G.FPSController then
        for slot, weapon in pairs(self.currentLoadout) do
            _G.FPSController:loadWeapon(slot, weapon)
        end
        _G.FPSController:equipWeapon("PRIMARY")
    end

    -- Initialize HUD
    if _G.AdvancedUISystem then
        _G.AdvancedUISystem:initialize()
    end

    print("FPS systems initialized after deployment")
end

-- Update current loadout
function MainMenuSystem:updateLoadout(newLoadout)
    self.currentLoadout = newLoadout
    -- Update loadout display if menu is open
    if self.menuGui then
        -- Clear and recreate loadout display
        local loadoutFrame = self.menuGui:FindFirstChild("Background"):FindFirstChild("ContentFrame"):FindFirstChild("CenterPanel"):FindFirstChild("LoadoutFrame")
        if loadoutFrame then
            for _, child in pairs(loadoutFrame:GetChildren()) do
                if child.Name:find("WeaponSlot") then
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

-- Create weapon customization class (separate from main menu)
function MainMenuSystem:createWeaponCustomizationClass()
    local WeaponCustomizationSystem = {}
    WeaponCustomizationSystem.__index = WeaponCustomizationSystem

    function WeaponCustomizationSystem.new()
        local self = setmetatable({}, WeaponCustomizationSystem)
        self.customizationGui = nil
        self.currentSlot = "PRIMARY"
        self.currentWeapon = nil
        self.weaponDatabase = nil
        self.loadout = nil
        self.previewModel = nil
        self.dragStart = nil
        self.dragging = false
        return self
    end

    function WeaponCustomizationSystem:openMenu(currentLoadout, weaponDatabase)
        if self.customizationGui then
            self.customizationGui:Destroy()
        end

        self.loadout = currentLoadout
        self.weaponDatabase = weaponDatabase
        self.currentWeapon = weaponDatabase.PRIMARY[currentLoadout.PRIMARY]

        self:createCustomizationGUI()
    end

    function WeaponCustomizationSystem:createCustomizationGUI()
        -- Create main GUI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "WeaponCustomization"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 300
        screenGui.Parent = playerGui

        -- Background overlay
        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 0.5
        overlay.BorderSizePixel = 0
        overlay.Parent = screenGui

        -- Main frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
        mainFrame.Position = UDim2.new(0.05, 0, 0.075, 0)
        mainFrame.BackgroundColor3 = MENU_CONFIG.COLORS.BACKGROUND
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = overlay

        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 12)
        mainCorner.Parent = mainFrame

        -- Title bar
        self:createTitleBar(mainFrame)

        -- Weapon categories (left side)
        self:createWeaponCategories(mainFrame)

        -- Weapon preview (center)
        self:createWeaponPreview(mainFrame)

        -- Weapon stats (right side)
        self:createWeaponStats(mainFrame)

        -- Bottom controls
        self:createBottomControls(mainFrame)

        self.customizationGui = screenGui

        -- Load initial weapon
        self:loadWeaponPreview(self.currentWeapon)
    end

    function WeaponCustomizationSystem:createTitleBar(parent)
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 60)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
        titleBar.BorderSizePixel = 0
        titleBar.Parent = parent

        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 12)
        titleCorner.Parent = titleBar

        -- Title text
        local titleText = Instance.new("TextLabel")
        titleText.Size = UDim2.new(0.8, 0, 1, 0)
        titleText.Position = UDim2.new(0, 20, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Text = "WEAPON CUSTOMIZATION"
        titleText.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        titleText.TextScaled = true
        titleText.Font = Enum.Font.GothamBold
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.Parent = titleBar

        -- Close button
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 40, 0, 40)
        closeButton.Position = UDim2.new(1, -50, 0, 10)
        closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeButton.Text = "?"
        closeButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        closeButton.TextScaled = true
        closeButton.Font = Enum.Font.GothamBold
        closeButton.Parent = titleBar

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeButton

        closeButton.MouseButton1Click:Connect(function()
            self:closeMenu()
        end)
    end

    function WeaponCustomizationSystem:createWeaponCategories(parent)
        local categoriesFrame = Instance.new("ScrollingFrame")
        categoriesFrame.Name = "CategoriesFrame"
        categoriesFrame.Size = UDim2.new(0.25, -10, 1, -140)
        categoriesFrame.Position = UDim2.new(0, 10, 0, 70)
        categoriesFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
        categoriesFrame.BorderSizePixel = 0
        categoriesFrame.ScrollBarThickness = 6
        categoriesFrame.Parent = parent

        local categoriesCorner = Instance.new("UICorner")
        categoriesCorner.CornerRadius = UDim.new(0, 8)
        categoriesCorner.Parent = categoriesFrame

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = categoriesFrame

        -- Slot tabs
        local slots = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
        for i, slot in ipairs(slots) do
            local slotButton = Instance.new("TextButton")
            slotButton.Name = slot .. "Tab"
            slotButton.Size = UDim2.new(1, -10, 0, 40)
            slotButton.BackgroundColor3 = slot == self.currentSlot and MENU_CONFIG.COLORS.ACCENT or Color3.fromRGB(55, 60, 70)
            slotButton.Text = slot
            slotButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
            slotButton.TextScaled = true
            slotButton.Font = Enum.Font.GothamBold
            slotButton.LayoutOrder = i
            slotButton.Parent = categoriesFrame

            local slotCorner = Instance.new("UICorner")
            slotCorner.CornerRadius = UDim.new(0, 6)
            slotCorner.Parent = slotButton

            slotButton.MouseButton1Click:Connect(function()
                self:switchSlot(slot)
            end)
        end

        -- Weapon list for current slot
        self:populateWeaponList(categoriesFrame, self.currentSlot)
    end

    function WeaponCustomizationSystem:populateWeaponList(parent, slot)
        -- Clear existing weapon buttons
        for _, child in pairs(parent:GetChildren()) do
            if child.Name:find("WeaponButton") then
                child:Destroy()
            end
        end

        local weapons = self.weaponDatabase[slot]
        if not weapons then return end

        local layoutOrder = 10 -- Start after slot tabs

        for weaponName, weaponData in pairs(weapons) do
            if weaponData.unlocked then
                local weaponButton = Instance.new("TextButton")
                weaponButton.Name = "WeaponButton_" .. weaponName
                weaponButton.Size = UDim2.new(1, -10, 0, 50)
                weaponButton.BackgroundColor3 = Color3.fromRGB(65, 70, 80)
                weaponButton.Text = weaponName .. "\n" .. weaponData.category
                weaponButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
                weaponButton.TextScaled = true
                weaponButton.Font = Enum.Font.Gotham
                weaponButton.LayoutOrder = layoutOrder
                weaponButton.Parent = parent

                local weaponCorner = Instance.new("UICorner")
                weaponCorner.CornerRadius = UDim.new(0, 6)
                weaponCorner.Parent = weaponButton

                weaponButton.MouseButton1Click:Connect(function()
                    self:selectWeapon(weaponName, weaponData)
                end)

                layoutOrder = layoutOrder + 1
            end
        end
    end

    function WeaponCustomizationSystem:createWeaponPreview(parent)
        local previewFrame = Instance.new("Frame")
        previewFrame.Name = "PreviewFrame"
        previewFrame.Size = UDim2.new(0.4, -10, 0.6, 0)
        previewFrame.Position = UDim2.new(0.25, 5, 0, 70)
        previewFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
        previewFrame.BorderSizePixel = 0
        previewFrame.Parent = parent

        local previewCorner = Instance.new("UICorner")
        previewCorner.CornerRadius = UDim.new(0, 8)
        previewCorner.Parent = previewFrame

        -- Preview title
        local previewTitle = Instance.new("TextLabel")
        previewTitle.Size = UDim2.new(1, -20, 0, 30)
        previewTitle.Position = UDim2.new(0, 10, 0, 10)
        previewTitle.BackgroundTransparency = 1
        previewTitle.Text = "WEAPON PREVIEW"
        previewTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        previewTitle.TextScaled = true
        previewTitle.Font = Enum.Font.GothamBold
        previewTitle.Parent = previewFrame

        -- Preview viewport
        local viewportFrame = Instance.new("ViewportFrame")
        viewportFrame.Name = "WeaponViewport"
        viewportFrame.Size = UDim2.new(1, -20, 1, -100)
        viewportFrame.Position = UDim2.new(0, 10, 0, 50)
        viewportFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
        viewportFrame.BorderSizePixel = 0
        viewportFrame.Parent = previewFrame

        local viewportCorner = Instance.new("UICorner")
        viewportCorner.CornerRadius = UDim.new(0, 6)
        viewportCorner.Parent = viewportFrame

        -- Add drag functionality for weapon rotation
        local dragDetector = Instance.new("Frame")
        dragDetector.Size = UDim2.new(1, 0, 1, 0)
        dragDetector.BackgroundTransparency = 1
        dragDetector.Parent = viewportFrame

        dragDetector.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.dragging = true
                self.dragStart = input.Position
            end
        end)

        dragDetector.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and self.dragging then
                self:rotateWeaponPreview(input.Delta)
            end
        end)

        dragDetector.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.dragging = false
            end
        end)

        -- Instructions
        local instructionText = Instance.new("TextLabel")
        instructionText.Size = UDim2.new(1, -20, 0, 30)
        instructionText.Position = UDim2.new(0, 10, 1, -40)
        instructionText.BackgroundTransparency = 1
        instructionText.Text = "Drag to rotate weapon"
        instructionText.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
        instructionText.TextScaled = true
        instructionText.Font = Enum.Font.Gotham
        instructionText.Parent = previewFrame
    end

    function WeaponCustomizationSystem:createWeaponStats(parent)
        local statsFrame = Instance.new("ScrollingFrame")
        statsFrame.Name = "StatsFrame"
        statsFrame.Size = UDim2.new(0.35, -10, 1, -140)
        statsFrame.Position = UDim2.new(0.65, 5, 0, 70)
        statsFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
        statsFrame.BorderSizePixel = 0
        statsFrame.ScrollBarThickness = 6
        statsFrame.Parent = parent

        local statsCorner = Instance.new("UICorner")
        statsCorner.CornerRadius = UDim.new(0, 8)
        statsCorner.Parent = statsFrame

        -- Stats title
        local statsTitle = Instance.new("TextLabel")
        statsTitle.Size = UDim2.new(1, -20, 0, 40)
        statsTitle.Position = UDim2.new(0, 10, 0, 10)
        statsTitle.BackgroundTransparency = 1
        statsTitle.Text = "WEAPON STATISTICS"
        statsTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        statsTitle.TextScaled = true
        statsTitle.Font = Enum.Font.GothamBold
        statsTitle.Parent = statsFrame

        -- Stats content will be populated by updateWeaponStats
        self:createStatsContent(statsFrame)
    end

    function WeaponCustomizationSystem:createStatsContent(parent)
        local statNames = {"DAMAGE", "RANGE", "MOBILITY", "RPM", "UNLOCK RANK"}
        local yOffset = 60

        for i, statName in ipairs(statNames) do
            local statFrame = Instance.new("Frame")
            statFrame.Name = statName .. "Frame"
            statFrame.Size = UDim2.new(1, -20, 0, 40)
            statFrame.Position = UDim2.new(0, 10, 0, yOffset)
            statFrame.BackgroundTransparency = 1
            statFrame.Parent = parent

            local statLabel = Instance.new("TextLabel")
            statLabel.Size = UDim2.new(0.5, 0, 1, 0)
            statLabel.Position = UDim2.new(0, 0, 0, 0)
            statLabel.BackgroundTransparency = 1
            statLabel.Text = statName
            statLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
            statLabel.TextScaled = true
            statLabel.Font = Enum.Font.Gotham
            statLabel.TextXAlignment = Enum.TextXAlignment.Left
            statLabel.Parent = statFrame

            local statValue = Instance.new("TextLabel")
            statValue.Name = "Value"
            statValue.Size = UDim2.new(0.5, 0, 1, 0)
            statValue.Position = UDim2.new(0.5, 0, 0, 0)
            statValue.BackgroundTransparency = 1
            statValue.Text = "0"
            statValue.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
            statValue.TextScaled = true
            statValue.Font = Enum.Font.GothamBold
            statValue.TextXAlignment = Enum.TextXAlignment.Right
            statValue.Parent = statFrame

            yOffset = yOffset + 50
        end

        -- Update canvas size
        parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end

    function WeaponCustomizationSystem:createBottomControls(parent)
        local controlsFrame = Instance.new("Frame")
        controlsFrame.Name = "ControlsFrame"
        controlsFrame.Size = UDim2.new(1, -20, 0, 60)
        controlsFrame.Position = UDim2.new(0, 10, 1, -70)
        controlsFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
        controlsFrame.BorderSizePixel = 0
        controlsFrame.Parent = parent

        local controlsCorner = Instance.new("UICorner")
        controlsCorner.CornerRadius = UDim.new(0, 8)
        controlsCorner.Parent = controlsFrame

        -- Apply button
        local applyButton = Instance.new("TextButton")
        applyButton.Size = UDim2.new(0.2, -10, 0, 40)
        applyButton.Position = UDim2.new(0.6, 5, 0, 10)
        applyButton.BackgroundColor3 = MENU_CONFIG.COLORS.DEPLOY_BUTTON
        applyButton.Text = "APPLY LOADOUT"
        applyButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        applyButton.TextScaled = true
        applyButton.Font = Enum.Font.GothamBold
        applyButton.Parent = controlsFrame

        local applyCorner = Instance.new("UICorner")
        applyCorner.CornerRadius = UDim.new(0, 6)
        applyCorner.Parent = applyButton

        -- Cancel button
        local cancelButton = Instance.new("TextButton")
        cancelButton.Size = UDim2.new(0.2, -10, 0, 40)
        cancelButton.Position = UDim2.new(0.8, 5, 0, 10)
        cancelButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        cancelButton.Text = "CANCEL"
        cancelButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        cancelButton.TextScaled = true
        cancelButton.Font = Enum.Font.GothamBold
        cancelButton.Parent = controlsFrame

        local cancelCorner = Instance.new("UICorner")
        cancelCorner.CornerRadius = UDim.new(0, 6)
        cancelCorner.Parent = cancelButton

        applyButton.MouseButton1Click:Connect(function()
            self:applyLoadout()
        end)

        cancelButton.MouseButton1Click:Connect(function()
            self:closeMenu()
        end)
    end

    function WeaponCustomizationSystem:switchSlot(slot)
        self.currentSlot = slot

        -- Update tab colors
        local categoriesFrame = self.customizationGui.Overlay.MainFrame.CategoriesFrame
        for _, child in pairs(categoriesFrame:GetChildren()) do
            if child.Name:find("Tab") then
                child.BackgroundColor3 = Color3.fromRGB(55, 60, 70)
            end
        end

        local activeTab = categoriesFrame:FindFirstChild(slot .. "Tab")
        if activeTab then
            activeTab.BackgroundColor3 = MENU_CONFIG.COLORS.ACCENT
        end

        -- Populate weapon list for new slot
        self:populateWeaponList(categoriesFrame, slot)

        -- Load first available weapon
        local weapons = self.weaponDatabase[slot]
        if weapons then
            for weaponName, weaponData in pairs(weapons) do
                if weaponData.unlocked then
                    self:selectWeapon(weaponName, weaponData)
                    break
                end
            end
        end
    end

    function WeaponCustomizationSystem:selectWeapon(weaponName, weaponData)
        self.currentWeapon = weaponData
        self.currentWeapon.name = weaponName

        -- Update loadout
        self.loadout[self.currentSlot] = weaponName

        -- Update preview and stats
        self:loadWeaponPreview(weaponData)
        self:updateWeaponStats(weaponData)
    end

    function WeaponCustomizationSystem:loadWeaponPreview(weaponData)
        local viewportFrame = self.customizationGui.Overlay.MainFrame.PreviewFrame.WeaponViewport

        -- Clear existing models
        viewportFrame:ClearAllChildren()

        -- Create camera
        local camera = Instance.new("Camera")
        camera.Parent = viewportFrame
        viewportFrame.CurrentCamera = camera

        -- Create simple weapon representation (since we don't have actual models)
        local weaponModel = Instance.new("Part")
        weaponModel.Name = "WeaponPreview"
        weaponModel.Size = Vector3.new(2, 0.5, 4)
        weaponModel.Material = Enum.Material.Metal
        weaponModel.BrickColor = BrickColor.new("Dark stone grey")
        weaponModel.TopSurface = Enum.SurfaceType.Smooth
        weaponModel.BottomSurface = Enum.SurfaceType.Smooth
        weaponModel.Parent = viewportFrame

        -- Add some detail parts
        local barrel = Instance.new("Part")
        barrel.Name = "Barrel"
        barrel.Size = Vector3.new(0.3, 0.3, 3)
        barrel.Material = Enum.Material.Metal
        barrel.BrickColor = BrickColor.new("Really black")
        barrel.TopSurface = Enum.SurfaceType.Smooth
        barrel.BottomSurface = Enum.SurfaceType.Smooth
        barrel.Parent = viewportFrame

        local barrelWeld = Instance.new("WeldConstraint")
        barrelWeld.Part0 = weaponModel
        barrelWeld.Part1 = barrel
        barrelWeld.Parent = weaponModel

        -- Position barrel
        barrel.CFrame = weaponModel.CFrame * CFrame.new(0, 0.2, 1)

        -- Position camera to view weapon
        camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, 8), Vector3.new(0, 0, 0))

        self.previewModel = weaponModel
    end

    function WeaponCustomizationSystem:rotateWeaponPreview(delta)
        if self.previewModel then
            local rotationSpeed = 0.005
            local rotationX = delta.Y * rotationSpeed
            local rotationY = delta.X * rotationSpeed

            self.previewModel.CFrame = self.previewModel.CFrame * CFrame.Angles(rotationX, rotationY, 0)
        end
    end

    function WeaponCustomizationSystem:updateWeaponStats(weaponData)
        local statsFrame = self.customizationGui.Overlay.MainFrame.StatsFrame

        -- Update stat values
        local stats = {
            DAMAGE = weaponData.damage or 0,
            RANGE = weaponData.range or 0,
            MOBILITY = weaponData.mobility or 0,
            RPM = weaponData.rpm or 0,
            ["UNLOCK RANK"] = weaponData.unlockRank or 0
        }

        for statName, value in pairs(stats) do
            local statFrame = statsFrame:FindFirstChild(statName .. "Frame")
            if statFrame then
                local valueLabel = statFrame:FindFirstChild("Value")
                if valueLabel then
                    valueLabel.Text = tostring(value)
                end
            end
        end
    end

    function WeaponCustomizationSystem:applyLoadout()
        -- Update main menu system's loadout
        if _G.MainMenuSystem then
            _G.MainMenuSystem:updateLoadout(self.loadout)
        end

        print("Applied new loadout:", self.loadout)
        self:closeMenu()
    end

    function WeaponCustomizationSystem:closeMenu()
        if self.customizationGui then
            self.customizationGui:Destroy()
            self.customizationGui = nil
        end
    end

    return WeaponCustomizationSystem
end

-- Initialize the system
local mainMenu = MainMenuSystem.new()

-- Export globally
_G.MainMenuSystem = mainMenu

return MainMenuSystem