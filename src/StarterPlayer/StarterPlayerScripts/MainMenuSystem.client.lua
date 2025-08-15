-- MainMenuSystem.client.lua
-- Phantom Forces style main menu with loadout customization
-- Place in StarterPlayer/StarterPlayerScripts/MainMenuSystem.client.lua

local MainMenuSystem = {}
MainMenuSystem.__index = MainMenuSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer

-- Prevent multiple instances
if _G.MainMenuLoaded then
    return
end
_G.MainMenuLoaded = true

-- Menu Configuration
local MENU_CONFIG = {
    COLORS = {
        BACKGROUND = Color3.fromRGB(15, 15, 20),
        PANEL = Color3.fromRGB(25, 30, 40),
        ACCENT = Color3.fromRGB(255, 165, 0), -- Orange accent
        BUTTON_PRIMARY = Color3.fromRGB(50, 120, 200),
        BUTTON_SECONDARY = Color3.fromRGB(70, 70, 80),
        TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
        TEXT_SECONDARY = Color3.fromRGB(180, 180, 180),
        SUCCESS = Color3.fromRGB(80, 200, 80),
        WARNING = Color3.fromRGB(255, 150, 50),
        ERROR = Color3.fromRGB(200, 50, 50)
    },
    ANIMATIONS = {
        FAST = 0.2,
        MEDIUM = 0.4,
        SLOW = 0.6
    }
}

-- Weapon Classes (Phantom Forces Style)
local WEAPON_CLASSES = {
    ASSAULT = {
        name = "ASSAULT",
        primaryTypes = {"Assault Rifle", "Battle Rifle", "Carbine", "Shotgun"},
        color = Color3.fromRGB(200, 80, 80)
    },
    SCOUT = {
        name = "SCOUT", 
        primaryTypes = {"PDW", "DMR", "Carbine", "Shotgun"},
        color = Color3.fromRGB(80, 200, 80)
    },
    SUPPORT = {
        name = "SUPPORT",
        primaryTypes = {"LMG", "Battle Rifle", "Carbine", "Shotgun"}, 
        color = Color3.fromRGB(80, 80, 200)
    },
    RECON = {
        name = "RECON",
        primaryTypes = {"Sniper Rifle", "DMR", "Battle Rifle", "Carbine"},
        color = Color3.fromRGB(200, 200, 80)
    }
}

-- Secondary weapon categories
local SECONDARY_CATEGORIES = {
    "PISTOLS", "MACHINE PISTOLS", "REVOLVERS", "OTHER"
}

-- Melee categories  
local MELEE_CATEGORIES = {
    "ONE HAND BLADE", "TWO HANDED BLADE", "ONE HAND BLUNT", "TWO HAND BLUNT"
}

-- Grenade categories
local GRENADE_CATEGORIES = {
    "FRAGMENTATION", "HIGH EXPLOSIVE", "IMPACT", "TACTICAL"
}

-- Weapon database (expandable)
local WEAPON_DATABASE = {
    -- Assault Rifles
    G36 = {name = "G36", class = "ASSAULT", type = "Assault Rifle", unlockRank = 1, damage = 35, rpm = 750},
    AK47 = {name = "AK-47", class = "ASSAULT", type = "Assault Rifle", unlockRank = 5, damage = 42, rpm = 600},
    M16A4 = {name = "M16A4", class = "ASSAULT", type = "Assault Rifle", unlockRank = 10, damage = 38, rpm = 800},

    -- PDWs
    MP5 = {name = "MP5", class = "SCOUT", type = "PDW", unlockRank = 2, damage = 28, rpm = 800},
    UMP45 = {name = "UMP-45", class = "SCOUT", type = "PDW", unlockRank = 8, damage = 32, rpm = 650},

    -- LMGs
    M249 = {name = "M249", class = "SUPPORT", type = "LMG", unlockRank = 15, damage = 45, rpm = 900},

    -- Snipers
    M40A1 = {name = "M40A1", class = "RECON", type = "Sniper Rifle", unlockRank = 12, damage = 85, rpm = 60},

    -- Pistols
    M9 = {name = "M9", type = "Pistol", category = "PISTOLS", unlockRank = 1, damage = 45, rpm = 400},
    Glock17 = {name = "Glock 17", type = "Pistol", category = "PISTOLS", unlockRank = 6, damage = 40, rpm = 450},

    -- Melee
    PocketKnife = {name = "Pocket Knife", type = "Melee", category = "ONE HAND BLADE", unlockRank = 1, damage = 75},
    Machete = {name = "Machete", type = "Melee", category = "ONE HAND BLADE", unlockRank = 20, damage = 85},

    -- Grenades
    M67 = {name = "M67 Frag", type = "Grenade", category = "FRAGMENTATION", unlockRank = 1, damage = 150}
}

function MainMenuSystem.new()
    local self = setmetatable({}, MainMenuSystem)

    -- Menu state
    self.isMenuOpen = true
    self.currentScreen = "MAIN" -- MAIN, LOADOUT, SKINS, SHOP, SETTINGS
    self.selectedClass = "ASSAULT"
    self.selectedWeaponSlot = "PRIMARY"

    -- Player data (will be loaded from DataStore)
    self.playerData = {
        rank = 1,
        xp = 0,
        nextRankXP = 1000,
        credits = 500,
        kills = 0,
        deaths = 0,
        totalXP = 0,
        nextWeaponUnlock = "AK47",
        nextRankReward = "New Weapon Unlock"
    }

    -- Current loadout
    self.currentLoadout = {
        PRIMARY = "G36",
        SECONDARY = "M9", 
        MELEE = "PocketKnife",
        GRENADE = "M67"
    }

    -- UI Elements
    self.gui = nil
    self.weaponPreview = nil
    self.rotationConnection = nil

    return self
end

-- Initialize the main menu
function MainMenuSystem:initialize()
    print("[MainMenu] Initializing Phantom Forces style main menu...")

    -- Load player data
    self:loadPlayerData()

    -- Create main menu UI
    self:createMainMenuUI()

    -- Setup input handling
    self:setupInputHandling()

    print("[MainMenu] Main menu initialized successfully!")
end

-- Load player data (from DataStore in real implementation)
function MainMenuSystem:loadPlayerData()
    -- This would load from DataStore in production
    -- For now using defaults or saved global data

    if _G.PlayerSaveData then
        local data = _G.PlayerSaveData
        self.playerData.rank = data.rank or 1
        self.playerData.xp = data.xp or 0
        self.playerData.kills = data.kills or 0
        self.playerData.deaths = data.deaths or 0
        self.playerData.totalXP = data.totalXP or 0
        self.playerData.credits = data.credits or 500
        self.currentLoadout = data.loadout or self.currentLoadout
    end

    -- Calculate KDR
    self.playerData.kdr = self.playerData.deaths > 0 and (self.playerData.kills / self.playerData.deaths) or self.playerData.kills

    -- Find next weapon unlock
    self:calculateNextUnlock()

    print("[MainMenu] Player data loaded")
end

-- Calculate next weapon unlock based on rank
function MainMenuSystem:calculateNextUnlock()
    local nextWeapon = nil
    local minUnlockRank = 999

    for weaponName, weapon in pairs(WEAPON_DATABASE) do
        if weapon.unlockRank > self.playerData.rank and weapon.unlockRank < minUnlockRank then
            nextWeapon = weaponName
            minUnlockRank = weapon.unlockRank
        end
    end

    self.playerData.nextWeaponUnlock = nextWeapon or "All Unlocked"
    self.playerData.weaponUnlockRank = minUnlockRank ~= 999 and minUnlockRank or self.playerData.rank
end

-- Create main menu UI
function MainMenuSystem:createMainMenuUI()
    -- Main ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "MainMenuGUI"
    self.gui.Parent = player:WaitForChild("PlayerGui")

    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = MENU_CONFIG.COLORS.BACKGROUND
    background.BorderSizePixel = 0
    background.Parent = self.gui

    -- Create main menu screen
    self:createMainScreen(background)
end

-- Create main menu screen
function MainMenuSystem:createMainScreen(parent)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainScreen"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = parent

    -- Top section with buttons
    self:createTopSection(mainFrame)

    -- Bottom section with player stats
    self:createBottomSection(mainFrame)

    -- Center deploy button
    self:createCenterDeployButton(mainFrame)
end

-- Create top section with menu buttons
function MainMenuSystem:createTopSection(parent)
    local topFrame = Instance.new("Frame")
    topFrame.Size = UDim2.new(1, 0, 0, 80)
    topFrame.BackgroundTransparency = 1
    topFrame.Parent = parent

    -- Menu buttons
    local buttons = {
        {text = "DEPLOY", color = MENU_CONFIG.COLORS.SUCCESS, action = function() self:deployPlayer() end},
        {text = "SQUAD DEPLOY", color = MENU_CONFIG.COLORS.BUTTON_SECONDARY, action = function() print("Squad Deploy - Not Implemented") end},
        {text = "WEAPON LOADOUT", color = MENU_CONFIG.COLORS.BUTTON_PRIMARY, action = function() self:openLoadoutMenu() end},
        {text = "WEAPON SKINS", color = MENU_CONFIG.COLORS.BUTTON_SECONDARY, action = function() print("Weapon Skins - Not Implemented") end},
        {text = "PLAYER SHOP", color = MENU_CONFIG.COLORS.BUTTON_SECONDARY, action = function() print("Player Shop - Not Implemented") end},
        {text = "SETTINGS", color = MENU_CONFIG.COLORS.BUTTON_SECONDARY, action = function() print("Settings - Not Implemented") end}
    }

    local buttonWidth = 1 / #buttons

    for i, buttonData in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(buttonWidth, -5, 0, 50)
        button.Position = UDim2.new(buttonWidth * (i-1), 2.5, 0, 15)
        button.BackgroundColor3 = buttonData.color
        button.BorderSizePixel = 0
        button.Text = buttonData.text
        button.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.Parent = topFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        button.MouseButton1Click:Connect(buttonData.action)

        -- Hover effects
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(MENU_CONFIG.ANIMATIONS.FAST), {
                BackgroundColor3 = Color3.fromRGB(
                    math.min(255, buttonData.color.R * 255 + 20),
                    math.min(255, buttonData.color.G * 255 + 20), 
                    math.min(255, buttonData.color.B * 255 + 20)
                )
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(MENU_CONFIG.ANIMATIONS.FAST), {
                BackgroundColor3 = buttonData.color
            }):Play()
        end)
    end
end

-- Create bottom section with player stats
function MainMenuSystem:createBottomSection(parent)
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Size = UDim2.new(1, 0, 0, 120)
    bottomFrame.Position = UDim2.new(0, 0, 1, -120)
    bottomFrame.BackgroundTransparency = 1
    bottomFrame.Parent = parent

    -- Left stats panel
    self:createLeftStatsPanel(bottomFrame)

    -- Center rank panel  
    self:createCenterRankPanel(bottomFrame)

    -- Right stats panel
    self:createRightStatsPanel(bottomFrame)

    -- Top right equipment display
    self:createEquipmentDisplay(parent)
end

-- Create left stats panel
function MainMenuSystem:createLeftStatsPanel(parent)
    -- This space can be used for server info or additional stats
end

-- Create center rank panel
function MainMenuSystem:createCenterRankPanel(parent)
    local centerFrame = Instance.new("Frame")
    centerFrame.Size = UDim2.new(0, 400, 1, 0)
    centerFrame.Position = UDim2.new(0.5, -200, 0, 0)
    centerFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    centerFrame.BorderSizePixel = 0
    centerFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = centerFrame

    -- Rank display
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(0.5, 0, 0, 30)
    rankLabel.Position = UDim2.new(0, 20, 0, 10)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = "RANK " .. self.playerData.rank
    rankLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    rankLabel.TextScaled = true
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextXAlignment = Enum.TextXAlignment.Left
    rankLabel.Parent = centerFrame

    -- XP display
    local xpLabel = Instance.new("TextLabel")
    xpLabel.Size = UDim2.new(0.5, 0, 0, 20)
    xpLabel.Position = UDim2.new(0, 20, 0, 45)
    xpLabel.BackgroundTransparency = 1
    xpLabel.Text = string.format("XP %d / %d", self.playerData.xp, self.playerData.nextRankXP)
    xpLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    xpLabel.TextScaled = true
    xpLabel.Font = Enum.Font.Gotham
    xpLabel.TextXAlignment = Enum.TextXAlignment.Left
    xpLabel.Parent = centerFrame

    -- XP Bar
    local xpBarBG = Instance.new("Frame")
    xpBarBG.Size = UDim2.new(1, -40, 0, 8)
    xpBarBG.Position = UDim2.new(0, 20, 0, 70)
    xpBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    xpBarBG.BorderSizePixel = 0
    xpBarBG.Parent = centerFrame

    local xpBarCorner = Instance.new("UICorner")
    xpBarCorner.CornerRadius = UDim.new(0, 4)
    xpBarCorner.Parent = xpBarBG

    local xpBar = Instance.new("Frame")
    xpBar.Size = UDim2.new(self.playerData.xp / self.playerData.nextRankXP, 0, 1, 0)
    xpBar.BackgroundColor3 = MENU_CONFIG.COLORS.ACCENT
    xpBar.BorderSizePixel = 0
    xpBar.Parent = xpBarBG

    local xpBarFillCorner = Instance.new("UICorner")
    xpBarFillCorner.CornerRadius = UDim.new(0, 4)
    xpBarFillCorner.Parent = xpBar

    -- Next weapon unlock
    local nextUnlockLabel = Instance.new("TextLabel")
    nextUnlockLabel.Size = UDim2.new(1, -40, 0, 20)
    nextUnlockLabel.Position = UDim2.new(0, 20, 0, 85)
    nextUnlockLabel.BackgroundTransparency = 1
    nextUnlockLabel.Text = "NEXT WEAPON UNLOCK"
    nextUnlockLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    nextUnlockLabel.TextScaled = true
    nextUnlockLabel.Font = Enum.Font.Gotham
    nextUnlockLabel.TextXAlignment = Enum.TextXAlignment.Left
    nextUnlockLabel.Parent = centerFrame

    local weaponUnlockLabel = Instance.new("TextLabel")
    weaponUnlockLabel.Size = UDim2.new(1, -40, 0, 15)
    weaponUnlockLabel.Position = UDim2.new(0, 20, 1, -20)
    weaponUnlockLabel.BackgroundTransparency = 1
    weaponUnlockLabel.Text = self.playerData.nextWeaponUnlock
    weaponUnlockLabel.TextColor3 = MENU_CONFIG.COLORS.ACCENT
    weaponUnlockLabel.TextScaled = true
    weaponUnlockLabel.Font = Enum.Font.GothamBold
    weaponUnlockLabel.TextXAlignment = Enum.TextXAlignment.Left
    weaponUnlockLabel.Parent = centerFrame
end

-- Create right stats panel
function MainMenuSystem:createRightStatsPanel(parent)
    local rightFrame = Instance.new("Frame")
    rightFrame.Size = UDim2.new(0, 200, 1, 0)
    rightFrame.Position = UDim2.new(1, -220, 0, 0)
    rightFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    rightFrame.BorderSizePixel = 0
    rightFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = rightFrame

    local stats = {
        {label = "KILLS", value = self.playerData.kills},
        {label = "DEATHS", value = self.playerData.deaths},
        {label = "KDR", value = string.format("%.2f", self.playerData.kdr)},
        {label = "TOTAL XP", value = self.playerData.totalXP},
        {label = "WEAPON UNLOCK RANK", value = self.playerData.weaponUnlockRank},
        {label = "NEXT RANK REWARD", value = self.playerData.nextRankReward}
    }

    for i, stat in ipairs(stats) do
        local statLabel = Instance.new("TextLabel")
        statLabel.Size = UDim2.new(1, -20, 0, 15)
        statLabel.Position = UDim2.new(0, 10, 0, 5 + (i-1) * 18)
        statLabel.BackgroundTransparency = 1
        statLabel.Text = stat.label .. " " .. stat.value
        statLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
        statLabel.TextScaled = true
        statLabel.Font = Enum.Font.Gotham
        statLabel.TextXAlignment = Enum.TextXAlignment.Left
        statLabel.Parent = rightFrame
    end
end

-- Create equipment display (top right)
function MainMenuSystem:createEquipmentDisplay(parent)
    local equipFrame = Instance.new("Frame")
    equipFrame.Size = UDim2.new(0, 250, 0, 150)
    equipFrame.Position = UDim2.new(1, -270, 0, 20)
    equipFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    equipFrame.BorderSizePixel = 0
    equipFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = equipFrame

    -- Credits display
    local creditsLabel = Instance.new("TextLabel")
    creditsLabel.Size = UDim2.new(1, -20, 0, 25)
    creditsLabel.Position = UDim2.new(0, 10, 0, 10)
    creditsLabel.BackgroundTransparency = 1
    creditsLabel.Text = "CREDITS: " .. self.playerData.credits
    creditsLabel.TextColor3 = MENU_CONFIG.COLORS.ACCENT
    creditsLabel.TextScaled = true
    creditsLabel.Font = Enum.Font.GothamBold
    creditsLabel.TextXAlignment = Enum.TextXAlignment.Right
    creditsLabel.Parent = equipFrame

    -- Current loadout display
    local loadoutTitle = Instance.new("TextLabel")
    loadoutTitle.Size = UDim2.new(1, -20, 0, 20)
    loadoutTitle.Position = UDim2.new(0, 10, 0, 40)
    loadoutTitle.BackgroundTransparency = 1
    loadoutTitle.Text = "CURRENT LOADOUT"
    loadoutTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    loadoutTitle.TextScaled = true
    loadoutTitle.Font = Enum.Font.GothamBold
    loadoutTitle.TextXAlignment = Enum.TextXAlignment.Left
    loadoutTitle.Parent = equipFrame

    local slots = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
    for i, slot in ipairs(slots) do
        local slotLabel = Instance.new("TextLabel")
        slotLabel.Size = UDim2.new(1, -20, 0, 15)
        slotLabel.Position = UDim2.new(0, 10, 0, 65 + (i-1) * 18)
        slotLabel.BackgroundTransparency = 1
        slotLabel.Text = slot .. ": " .. self.currentLoadout[slot]
        slotLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
        slotLabel.TextScaled = true
        slotLabel.Font = Enum.Font.Gotham
        slotLabel.TextXAlignment = Enum.TextXAlignment.Left
        slotLabel.Parent = equipFrame
    end
end

-- Create center deploy button
function MainMenuSystem:createCenterDeployButton(parent)
    local deployButton = Instance.new("TextButton")
    deployButton.Size = UDim2.new(0, 200, 0, 60)
    deployButton.Position = UDim2.new(0.5, -100, 0.5, -30)
    deployButton.BackgroundColor3 = MENU_CONFIG.COLORS.SUCCESS
    deployButton.BorderSizePixel = 0
    deployButton.Text = "DEPLOY"
    deployButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    deployButton.TextScaled = true
    deployButton.Font = Enum.Font.GothamBold
    deployButton.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = deployButton

    deployButton.MouseButton1Click:Connect(function()
        self:deployPlayer()
    end)

    -- Hover effects
    deployButton.MouseEnter:Connect(function()
        TweenService:Create(deployButton, TweenInfo.new(MENU_CONFIG.ANIMATIONS.FAST), {
            Size = UDim2.new(0, 220, 0, 70),
            Position = UDim2.new(0.5, -110, 0.5, -35)
        }):Play()
    end)

    deployButton.MouseLeave:Connect(function()
        TweenService:Create(deployButton, TweenInfo.new(MENU_CONFIG.ANIMATIONS.FAST), {
            Size = UDim2.new(0, 200, 0, 60),
            Position = UDim2.new(0.5, -100, 0.5, -30)
        }):Play()
    end)
end

-- Open loadout customization menu
function MainMenuSystem:openLoadoutMenu()
    print("[MainMenu] Opening loadout customization...")

    -- Hide main menu
    if self.gui then
        self.gui.Enabled = false
    end

    -- Create loadout menu
    self:createLoadoutMenu()
end

-- Create loadout customization menu (Phantom Forces style)
function MainMenuSystem:createLoadoutMenu()
    local loadoutGui = Instance.new("ScreenGui")
    loadoutGui.Name = "LoadoutMenuGUI" 
    loadoutGui.Parent = player.PlayerGui

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = MENU_CONFIG.COLORS.BACKGROUND
    background.BorderSizePixel = 0
    background.Parent = loadoutGui

    -- Top class selection
    self:createClassSelection(background)

    -- Left weapon selection panel
    self:createWeaponSelectionPanel(background)

    -- Center weapon preview
    self:createWeaponPreviewPanel(background)

    -- Right weapon stats panel
    self:createWeaponStatsPanel(background)

    -- Bottom navigation
    self:createLoadoutNavigation(background, loadoutGui)

    self.loadoutGui = loadoutGui
end

-- Create class selection (top of loadout menu)
function MainMenuSystem:createClassSelection(parent)
    local classFrame = Instance.new("Frame")
    classFrame.Size = UDim2.new(1, 0, 0, 80)
    classFrame.BackgroundTransparency = 1
    classFrame.Parent = parent

    local classes = {"ASSAULT", "SCOUT", "SUPPORT", "RECON"}
    local buttonWidth = 1 / #classes

    for i, className in ipairs(classes) do
        local classData = WEAPON_CLASSES[className]
        local isSelected = className == self.selectedClass

        local classButton = Instance.new("TextButton")
        classButton.Size = UDim2.new(buttonWidth, -5, 0, 50)
        classButton.Position = UDim2.new(buttonWidth * (i-1), 2.5, 0, 15)
        classButton.BackgroundColor3 = isSelected and classData.color or MENU_CONFIG.COLORS.BUTTON_SECONDARY
        classButton.BorderSizePixel = 0
        classButton.Text = classData.name
        classButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        classButton.TextScaled = true
        classButton.Font = Enum.Font.GothamBold
        classButton.Parent = classFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = classButton

        classButton.MouseButton1Click:Connect(function()
            self:selectClass(className)
            self:refreshLoadoutMenu()
        end)
    end
end

-- Create weapon selection panel (left side)
function MainMenuSystem:createWeaponSelectionPanel(parent)
    local leftPanel = Instance.new("Frame")
    leftPanel.Size = UDim2.new(0, 300, 1, -160)
    leftPanel.Position = UDim2.new(0, 20, 0, 100)
    leftPanel.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    leftPanel.BorderSizePixel = 0
    leftPanel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = leftPanel

    -- Weapon slot selection
    local slotFrame = Instance.new("Frame")
    slotFrame.Size = UDim2.new(1, 0, 0, 60)
    slotFrame.BackgroundTransparency = 1
    slotFrame.Parent = leftPanel

    local slots = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
    local slotWidth = 1 / #slots

    for i, slot in ipairs(slots) do
        local isSelected = slot == self.selectedWeaponSlot

        local slotButton = Instance.new("TextButton")
        slotButton.Size = UDim2.new(slotWidth, -2, 0, 40)
        slotButton.Position = UDim2.new(slotWidth * (i-1), 1, 0, 10)
        slotButton.BackgroundColor3 = isSelected and MENU_CONFIG.COLORS.ACCENT or MENU_CONFIG.COLORS.BUTTON_SECONDARY
        slotButton.BorderSizePixel = 0
        slotButton.Text = slot
        slotButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        slotButton.TextScaled = true
        slotButton.Font = Enum.Font.Gotham
        slotButton.Parent = slotFrame

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 4)
        slotCorner.Parent = slotButton

        slotButton.MouseButton1Click:Connect(function()
            self.selectedWeaponSlot = slot
            self:refreshWeaponList()
        end)
    end

    -- Weapon categories (for selected slot)
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(1, 0, 0, 40)
    categoryFrame.Position = UDim2.new(0, 0, 0, 70)
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Parent = leftPanel

    self:createWeaponCategories(categoryFrame)

    -- Weapon list
    local weaponListFrame = Instance.new("ScrollingFrame")
    weaponListFrame.Size = UDim2.new(1, -20, 1, -130)
    weaponListFrame.Position = UDim2.new(0, 10, 0, 120)
    weaponListFrame.BackgroundTransparency = 1
    weaponListFrame.BorderSizePixel = 0
    weaponListFrame.ScrollBarThickness = 8
    weaponListFrame.ScrollBarImageColor3 = MENU_CONFIG.COLORS.ACCENT
    weaponListFrame.Parent = leftPanel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = weaponListFrame

    self.weaponListFrame = weaponListFrame
    self:populateWeaponList()
end

-- Create weapon categories for current slot
function MainMenuSystem:createWeaponCategories(parent)
    local categories = {}

    if self.selectedWeaponSlot == "PRIMARY" then
        categories = WEAPON_CLASSES[self.selectedClass].primaryTypes
    elseif self.selectedWeaponSlot == "SECONDARY" then
        categories = SECONDARY_CATEGORIES
    elseif self.selectedWeaponSlot == "MELEE" then
        categories = MELEE_CATEGORIES
    elseif self.selectedWeaponSlot == "GRENADE" then
        categories = GRENADE_CATEGORIES
    end

    -- Clear existing categories
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local categoryWidth = 1 / math.max(#categories, 1)

    for i, category in ipairs(categories) do
        local categoryButton = Instance.new("TextButton")
        categoryButton.Size = UDim2.new(categoryWidth, -2, 1, 0)
        categoryButton.Position = UDim2.new(categoryWidth * (i-1), 1, 0, 0)
        categoryButton.BackgroundColor3 = MENU_CONFIG.COLORS.BUTTON_SECONDARY
        categoryButton.BorderSizePixel = 0
        categoryButton.Text = category
        categoryButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        categoryButton.TextScaled = true
        categoryButton.Font = Enum.Font.Gotham
        categoryButton.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = categoryButton

        categoryButton.MouseButton1Click:Connect(function()
            self.selectedCategory = category
            self:populateWeaponList()
        end)
    end
end

-- Populate weapon list based on selection
function MainMenuSystem:populateWeaponList()
    if not self.weaponListFrame then return end

    -- Clear existing weapons
    for _, child in ipairs(self.weaponListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local availableWeapons = {}

    -- Filter weapons based on current selection
    for weaponName, weapon in pairs(WEAPON_DATABASE) do
        local shouldShow = false

        if self.selectedWeaponSlot == "PRIMARY" then
            shouldShow = weapon.class == self.selectedClass and 
                table.find(WEAPON_CLASSES[self.selectedClass].primaryTypes, weapon.type)
        elseif self.selectedWeaponSlot == "SECONDARY" then
            shouldShow = weapon.type == "Pistol"
        elseif self.selectedWeaponSlot == "MELEE" then
            shouldShow = weapon.type == "Melee"
        elseif self.selectedWeaponSlot == "GRENADE" then
            shouldShow = weapon.type == "Grenade"
        end

        if shouldShow then
            table.insert(availableWeapons, weapon)
        end
    end

    -- Sort by unlock rank
    table.sort(availableWeapons, function(a, b)
        return a.unlockRank < b.unlockRank
    end)

    -- Create weapon buttons
    for i, weapon in ipairs(availableWeapons) do
        local isUnlocked = weapon.unlockRank <= self.playerData.rank
        local isEquipped = self.currentLoadout[self.selectedWeaponSlot] == weapon.name

        local weaponFrame = Instance.new("Frame")
        weaponFrame.Size = UDim2.new(1, 0, 0, 60)
        weaponFrame.BackgroundColor3 = isEquipped and MENU_CONFIG.COLORS.ACCENT or 
            (isUnlocked and MENU_CONFIG.COLORS.PANEL or Color3.fromRGB(60, 40, 40))
        weaponFrame.BorderSizePixel = 0
        weaponFrame.Parent = self.weaponListFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = weaponFrame

        local weaponButton = Instance.new("TextButton")
        weaponButton.Size = UDim2.new(1, 0, 1, 0)
        weaponButton.BackgroundTransparency = 1
        weaponButton.Text = ""
        weaponButton.Parent = weaponFrame

        -- Weapon name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = weapon.name
        nameLabel.TextColor3 = isUnlocked and MENU_CONFIG.COLORS.TEXT_PRIMARY or MENU_CONFIG.COLORS.TEXT_SECONDARY
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = weaponFrame

        -- Unlock rank
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0.3, 0, 0, 20)
        rankLabel.Position = UDim2.new(0.7, 0, 0, 5)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "RANK " .. weapon.unlockRank
        rankLabel.TextColor3 = isUnlocked and MENU_CONFIG.COLORS.SUCCESS or MENU_CONFIG.COLORS.ERROR
        rankLabel.TextScaled = true
        rankLabel.Font = Enum.Font.Gotham
        rankLabel.TextXAlignment = Enum.TextXAlignment.Right
        rankLabel.Parent = weaponFrame

        -- Weapon type
        local typeLabel = Instance.new("TextLabel")
        typeLabel.Size = UDim2.new(1, -20, 0, 15)
        typeLabel.Position = UDim2.new(0, 10, 0, 30)
        typeLabel.BackgroundTransparency = 1
        typeLabel.Text = weapon.type
        typeLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
        typeLabel.TextScaled = true
        typeLabel.Font = Enum.Font.Gotham
        typeLabel.TextXAlignment = Enum.TextXAlignment.Left
        typeLabel.Parent = weaponFrame

        -- Lock overlay for locked weapons
        if not isUnlocked then
            local lockOverlay = Instance.new("Frame")
            lockOverlay.Size = UDim2.new(1, 0, 1, 0)
            lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            lockOverlay.BackgroundTransparency = 0.7
            lockOverlay.BorderSizePixel = 0
            lockOverlay.Parent = weaponFrame

            local lockCorner = Instance.new("UICorner")
            lockCorner.CornerRadius = UDim.new(0, 6)
            lockCorner.Parent = lockOverlay

            local lockIcon = Instance.new("TextLabel")
            lockIcon.Size = UDim2.new(0, 40, 0, 40)
            lockIcon.Position = UDim2.new(0.5, -20, 0.5, -20)
            lockIcon.BackgroundTransparency = 1
            lockIcon.Text = "??"
            lockIcon.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
            lockIcon.TextScaled = true
            lockIcon.Font = Enum.Font.Gotham
            lockIcon.Parent = lockOverlay
        end

        -- Click handler
        weaponButton.MouseButton1Click:Connect(function()
            if isUnlocked then
                self.currentLoadout[self.selectedWeaponSlot] = weapon.name
                self:refreshWeaponList()
                self:updateWeaponPreview(weapon)
                self:updateWeaponStats(weapon)
            else
                print("Weapon locked - Rank " .. weapon.unlockRank .. " required")
            end
        end)
    end

    -- Update canvas size
    self.weaponListFrame.CanvasSize = UDim2.new(0, 0, 0, #availableWeapons * 65)
end

-- Create weapon preview panel (center)
function MainMenuSystem:createWeaponPreviewPanel(parent)
    local previewPanel = Instance.new("Frame")
    previewPanel.Size = UDim2.new(0, 400, 1, -160)
    previewPanel.Position = UDim2.new(0, 340, 0, 100)
    previewPanel.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    previewPanel.BorderSizePixel = 0
    previewPanel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = previewPanel

    -- Preview title
    local previewTitle = Instance.new("TextLabel")
    previewTitle.Size = UDim2.new(1, 0, 0, 30)
    previewTitle.Position = UDim2.new(0, 0, 0, 10)
    previewTitle.BackgroundTransparency = 1
    previewTitle.Text = "WEAPON PREVIEW"
    previewTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    previewTitle.TextScaled = true
    previewTitle.Font = Enum.Font.GothamBold
    previewTitle.Parent = previewPanel

    -- 3D Preview area (placeholder)
    local previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(1, -20, 1, -80)
    previewFrame.Position = UDim2.new(0, 10, 0, 50)
    previewFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = previewPanel

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 6)
    previewCorner.Parent = previewFrame

    -- Placeholder for 3D model
    local previewLabel = Instance.new("TextLabel")
    previewLabel.Size = UDim2.new(1, 0, 1, 0)
    previewLabel.BackgroundTransparency = 1
    previewLabel.Text = "3D WEAPON MODEL\n(Rotatable Preview)"
    previewLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
    previewLabel.TextScaled = true
    previewLabel.Font = Enum.Font.Gotham
    previewLabel.Parent = previewFrame

    self.weaponPreview = previewFrame
end

-- Create weapon stats panel (right)
function MainMenuSystem:createWeaponStatsPanel(parent)
    local statsPanel = Instance.new("Frame")
    statsPanel.Size = UDim2.new(0, 300, 1, -160)
    statsPanel.Position = UDim2.new(1, -320, 0, 100)
    statsPanel.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    statsPanel.BorderSizePixel = 0
    statsPanel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = statsPanel

    -- Stats title
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, 0, 0, 30)
    statsTitle.Position = UDim2.new(0, 0, 0, 10)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "WEAPON STATISTICS"
    statsTitle.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    statsTitle.TextScaled = true
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.Parent = statsPanel

    -- Stats container
    local statsContainer = Instance.new("ScrollingFrame")
    statsContainer.Size = UDim2.new(1, -20, 1, -50)
    statsContainer.Position = UDim2.new(0, 10, 0, 40)
    statsContainer.BackgroundTransparency = 1
    statsContainer.BorderSizePixel = 0
    statsContainer.ScrollBarThickness = 6
    statsContainer.ScrollBarImageColor3 = MENU_CONFIG.COLORS.ACCENT
    statsContainer.Parent = statsPanel

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.Padding = UDim.new(0, 10)
    statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    statsLayout.Parent = statsContainer

    self.weaponStatsContainer = statsContainer

    -- Initialize with current weapon
    local currentWeapon = WEAPON_DATABASE[self.currentLoadout[self.selectedWeaponSlot]]
    if currentWeapon then
        self:updateWeaponStats(currentWeapon)
    end
end

-- Update weapon stats display
function MainMenuSystem:updateWeaponStats(weapon)
    if not self.weaponStatsContainer then return end

    -- Clear existing stats
    for _, child in ipairs(self.weaponStatsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local stats = {
        {label = "DAMAGE", value = weapon.damage or "N/A"},
        {label = "FIRE RATE", value = weapon.rpm and (weapon.rpm .. " RPM") or "N/A"},
        {label = "UNLOCK RANK", value = weapon.unlockRank},
        {label = "WEAPON TYPE", value = weapon.type},
        {label = "KILLS WITH WEAPON", value = "0"}, -- Would track from save data
        {label = "HEADSHOT MULTIPLIER", value = "1.5x"},
        {label = "BODY MULTIPLIER", value = "1.0x"},
        {label = "LIMB MULTIPLIER", value = "0.9x"}
    }

    for i, stat in ipairs(stats) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(1, 0, 0, 25)
        statFrame.BackgroundTransparency = 1
        statFrame.Parent = self.weaponStatsContainer

        local statLabel = Instance.new("TextLabel")
        statLabel.Size = UDim2.new(0.6, 0, 1, 0)
        statLabel.BackgroundTransparency = 1
        statLabel.Text = stat.label
        statLabel.TextColor3 = MENU_CONFIG.COLORS.TEXT_SECONDARY
        statLabel.TextScaled = true
        statLabel.Font = Enum.Font.Gotham
        statLabel.TextXAlignment = Enum.TextXAlignment.Left
        statLabel.Parent = statFrame

        local statValue = Instance.new("TextLabel")
        statValue.Size = UDim2.new(0.4, 0, 1, 0)
        statValue.Position = UDim2.new(0.6, 0, 0, 0)
        statValue.BackgroundTransparency = 1
        statValue.Text = tostring(stat.value)
        statValue.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
        statValue.TextScaled = true
        statValue.Font = Enum.Font.GothamBold
        statValue.TextXAlignment = Enum.TextXAlignment.Right
        statValue.Parent = statFrame
    end

    -- Update canvas size
    self.weaponStatsContainer.CanvasSize = UDim2.new(0, 0, 0, #stats * 35)
end

-- Update weapon preview
function MainMenuSystem:updateWeaponPreview(weapon)
    if not self.weaponPreview then return end

    -- Update preview text (would show 3D model in full implementation)
    local previewLabel = self.weaponPreview:FindFirstChild("TextLabel")
    if previewLabel then
        previewLabel.Text = weapon.name .. "\n3D PREVIEW\n(Rotatable Model)"
    end
end

-- Create loadout navigation (bottom)
function MainMenuSystem:createLoadoutNavigation(parent, loadoutGui)
    local navFrame = Instance.new("Frame")
    navFrame.Size = UDim2.new(1, 0, 0, 60)
    navFrame.Position = UDim2.new(0, 0, 1, -60)
    navFrame.BackgroundColor3 = MENU_CONFIG.COLORS.PANEL
    navFrame.BorderSizePixel = 0
    navFrame.Parent = parent

    -- Back button
    local backButton = Instance.new("TextButton")
    backButton.Size = UDim2.new(0, 120, 0, 40)
    backButton.Position = UDim2.new(0, 20, 0.5, -20)
    backButton.BackgroundColor3 = MENU_CONFIG.COLORS.BUTTON_SECONDARY
    backButton.BorderSizePixel = 0
    backButton.Text = "BACK"
    backButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    backButton.TextScaled = true
    backButton.Font = Enum.Font.GothamBold
    backButton.Parent = navFrame

    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 6)
    backCorner.Parent = backButton

    -- Apply button
    local applyButton = Instance.new("TextButton")
    applyButton.Size = UDim2.new(0, 120, 0, 40)
    applyButton.Position = UDim2.new(1, -140, 0.5, -20)
    applyButton.BackgroundColor3 = MENU_CONFIG.COLORS.SUCCESS
    applyButton.BorderSizePixel = 0
    applyButton.Text = "APPLY"
    applyButton.TextColor3 = MENU_CONFIG.COLORS.TEXT_PRIMARY
    applyButton.TextScaled = true
    applyButton.Font = Enum.Font.GothamBold
    applyButton.Parent = navFrame

    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 6)
    applyCorner.Parent = applyButton

    -- Button actions
    backButton.MouseButton1Click:Connect(function()
        self:closeLoadoutMenu(loadoutGui)
    end)

    applyButton.MouseButton1Click:Connect(function()
        self:saveLoadout()
        self:closeLoadoutMenu(loadoutGui)
    end)
end

-- Helper functions
function MainMenuSystem:selectClass(className)
    self.selectedClass = className
    self.selectedWeaponSlot = "PRIMARY" -- Reset to primary when changing class
end

function MainMenuSystem:refreshLoadoutMenu()
    if self.loadoutGui then
        self.loadoutGui:Destroy()
        self:createLoadoutMenu()
    end
end

function MainMenuSystem:refreshWeaponList()
    self:populateWeaponList()
end

function MainMenuSystem:closeLoadoutMenu(loadoutGui)
    if loadoutGui then
        loadoutGui:Destroy()
    end

    if self.gui then
        self.gui.Enabled = true
    end

    self.loadoutGui = nil
end

function MainMenuSystem:saveLoadout()
    -- Save loadout to player data
    self:savePlayerData()
    print("[MainMenu] Loadout saved:", self.currentLoadout)
end

-- Save player data (would use DataStore in production)
function MainMenuSystem:savePlayerData()
    _G.PlayerSaveData = {
        rank = self.playerData.rank,
        xp = self.playerData.xp,
        kills = self.playerData.kills,
        deaths = self.playerData.deaths,
        totalXP = self.playerData.totalXP,
        credits = self.playerData.credits,
        loadout = self.currentLoadout
    }
end

-- Deploy player to game
function MainMenuSystem:deployPlayer()
    print("[MainMenu] Deploying player with loadout:", self.currentLoadout)

    -- Hide menu
    if self.gui then
        self.gui:Destroy()
    end

    -- Initialize FPS systems
    self:initializeFPSSystems()

    -- Spawn player
    self:spawnPlayer()

    self.isMenuOpen = false
end

-- Initialize FPS systems after deployment
function MainMenuSystem:initializeFPSSystems()
    -- Wait for FPS framework
    local maxWait = 10
    local waited = 0

    while not _G.FPSFramework and waited < maxWait do
        task.wait(0.1)
        waited = waited + 0.1
    end

    if _G.FPSFramework then
        -- Load weapons into framework
        for slot, weaponName in pairs(self.currentLoadout) do
            _G.FPSFramework:loadWeapon(slot, weaponName)
        end

        -- Equip primary weapon
        _G.FPSFramework:equipWeapon("PRIMARY")

        print("[MainMenu] FPS systems initialized with loadout")
    else
        warn("[MainMenu] FPS Framework not found")
    end
end

-- Spawn player to appropriate team spawn
function MainMenuSystem:spawnPlayer()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- Determine spawn position based on team
    local spawnPosition = Vector3.new(0, 10, 0) -- Default spawn

    if player.Team then
        if player.Team.Name == "KFC" then
            spawnPosition = Vector3.new(100, 10, 100) -- KFC spawn near city
        elseif player.Team.Name == "FBI" then
            spawnPosition = Vector3.new(-100, 10, -100) -- FBI spawn at bunker
        end
    end

    -- Teleport player
    if character.PrimaryPart then
        character:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
    end

    print("[MainMenu] Player spawned at:", spawnPosition)
end

-- Setup input handling
function MainMenuSystem:setupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Escape and self.isMenuOpen then
            if self.currentScreen == "LOADOUT" then
                self:closeLoadoutMenu(self.loadoutGui)
            end
        elseif input.KeyCode == Enum.KeyCode.M and not self.isMenuOpen then
            -- Reopen menu (for testing)
            self:initialize()
        end
    end)
end

-- Initialize the main menu system
local mainMenu = MainMenuSystem.new()
mainMenu:initialize()

-- Export globally
_G.MainMenuSystem = mainMenu

return mainMenu