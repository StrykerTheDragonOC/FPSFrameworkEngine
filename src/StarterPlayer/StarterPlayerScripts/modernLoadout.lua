-- ModernWeaponLoadout.client.lua
-- Advanced weapon loadout system without emojis, proper categorization
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ModernLoadout = {}
ModernLoadout.__index = ModernLoadout

-- Modern weapon categories with proper organization
local WEAPON_CATEGORIES = {
    ASSAULT = {
        name = "ASSAULT RIFLES",
        weapons = {
            "AK74", "AK47", "AK12", "AKM", "AN94",
            "M16A3", "M16A4", "M4A1", "G36", "G36C",
            "SCAR-L", "FAMAS", "AUG A1", "TAR21", "L85A2"
        },
        color = Color3.fromRGB(85, 170, 255),
        description = "Balanced weapons for medium range combat"
    },
    SCOUT = {
        name = "CARBINES & PDWs",
        weapons = {
            "AKU12", "G36K", "M4A1C", "SCAR-PDW", "HONEY BADGER",
            "SR3M", "AS VAL", "MP7", "P90", "UMP45"
        },
        color = Color3.fromRGB(100, 255, 150),
        description = "Compact weapons for close quarters"
    },
    SUPPORT = {
        name = "LIGHT MACHINE GUNS",
        weapons = {
            "M60", "MG3KWS", "COLT LMG", "M249", "RPK",
            "L86 LSW", "HK21", "MG36", "AWS"
        },
        color = Color3.fromRGB(255, 165, 85),
        description = "Heavy firepower for sustained combat"
    },
    RECON = {
        name = "SNIPER RIFLES",
        weapons = {
            "INTERVENTION", "REMINGTON 700", "AWM", "TRG42",
            "MOSIN NAGANT", "DRAGUNOV SVDS", "BFG 50", "HECATE II",
            "M107", "NTW20"
        },
        color = Color3.fromRGB(255, 100, 100),
        description = "Precision weapons for long range elimination"
    }
}

local SECONDARY_CATEGORIES = {
    PISTOLS = {
        "M9", "GLOCK 17", "M1911", "DEAGLE 44", "FIVE SEVEN",
        "GLOCK 18", "MP412 REX", "M45A1", "SERBU SHOTGUN"
    },
    MACHINE_PISTOLS = {
        "TEC9", "GLOCK 18", "MP1911", "MICRO UZI"
    },
    REVOLVERS = {
        "MP412 REX", "JUDGE", "EXECUTIONER"
    },
    OTHER = {
        "SAWED OFF", "ZIP 22", "SERBU SHOTGUN", "OBREZ"
    }
}

local MELEE_WEAPONS = {
    "KNIFE", "TOMAHAWK", "CLEAVER", "ICE PICK", "BASEBALL BAT",
    "CROWBAR", "SLEDGEHAMMER", "KATANA", "MACHETE", "KARAMBIT"
}

local GRENADES = {
    "M67 FRAG", "RGO IMPACT", "M18 SMOKE", "FLASHBANG", "TEAR GAS"
}

-- Constructor
function ModernLoadout.new()
    local self = setmetatable({}, ModernLoadout)

    self.currentGUI = nil
    self.selectedCategory = "ASSAULT"
    self.selectedWeapons = {
        PRIMARY = "AK74",
        SECONDARY = "M9",
        MELEE = "KNIFE",
        GRENADE = "M67 FRAG"
    }

    self.attachmentMode = false
    self.selectedAttachments = {}

    return self
end

-- Create modern weapon selection interface
function ModernLoadout:createWeaponGUI()
    -- Create main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernLoadoutGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Background frame with dark theme
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 80)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 400, 1, 0)
    title.Position = UDim2.new(0, 30, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "WEAPON LOADOUTS"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    -- Credits display
    local credits = Instance.new("TextLabel")
    credits.Size = UDim2.new(0, 200, 1, 0)
    credits.Position = UDim2.new(1, -230, 0, 0)
    credits.BackgroundTransparency = 1
    credits.Text = "CREDITS: 1,573"
    credits.TextColor3 = Color3.fromRGB(255, 255, 255)
    credits.TextScaled = true
    credits.Font = Enum.Font.SourceSans
    credits.TextXAlignment = Enum.TextXAlignment.Right
    credits.Parent = topBar

    -- Category selection
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(1, -40, 0, 60)
    categoryFrame.Position = UDim2.new(0, 20, 0, 100)
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Parent = mainFrame

    -- Create category buttons
    local buttonWidth = 1 / 4
    local categoryButtons = {}

    for i, category in ipairs({"ASSAULT", "SCOUT", "SUPPORT", "RECON"}) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(buttonWidth, -10, 1, 0)
        button.Position = UDim2.new(buttonWidth * (i-1), 5, 0, 0)
        button.BackgroundColor3 = category == self.selectedCategory and WEAPON_CATEGORIES[category].color or Color3.fromRGB(40, 40, 40)
        button.BorderSizePixel = 0
        button.Text = WEAPON_CATEGORIES[category].name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSansBold
        button.Parent = categoryFrame

        categoryButtons[category] = button

        -- Button click handler
        button.MouseButton1Click:Connect(function()
            self:selectCategory(category, categoryButtons)
        end)
    end

    -- Main content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -40, 1, -200)
    contentFrame.Position = UDim2.new(0, 20, 0, 180)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    -- Weapon list panel
    local weaponListFrame = Instance.new("Frame")
    weaponListFrame.Size = UDim2.new(0, 300, 1, 0)
    weaponListFrame.Position = UDim2.new(0, 0, 0, 0)
    weaponListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    weaponListFrame.BorderSizePixel = 0
    weaponListFrame.Parent = contentFrame

    -- Weapon list
    local weaponScrollFrame = Instance.new("ScrollingFrame")
    weaponScrollFrame.Size = UDim2.new(1, -20, 1, -40)
    weaponScrollFrame.Position = UDim2.new(0, 10, 0, 30)
    weaponScrollFrame.BackgroundTransparency = 1
    weaponScrollFrame.BorderSizePixel = 0
    weaponScrollFrame.ScrollBarThickness = 8
    weaponScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    weaponScrollFrame.Parent = weaponListFrame

    -- Category label in weapon list
    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Size = UDim2.new(1, 0, 0, 30)
    categoryLabel.Position = UDim2.new(0, 10, 0, 0)
    categoryLabel.BackgroundTransparency = 1
    categoryLabel.Text = "PRIMARY"
    categoryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    categoryLabel.TextScaled = true
    categoryLabel.Font = Enum.Font.SourceSansBold
    categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    categoryLabel.Parent = weaponListFrame

    -- Stats panel
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0, 350, 1, 0)
    statsFrame.Position = UDim2.new(1, -350, 0, 0)
    statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = contentFrame

    -- Store references
    self.currentGUI = screenGui
    self.weaponScrollFrame = weaponScrollFrame
    self.statsFrame = statsFrame
    self.categoryButtons = categoryButtons

    -- Populate weapon list
    self:populateWeaponList()

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 40)
    closeButton.Position = UDim2.new(1, -120, 0, 20)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "CLOSE"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = topBar

    closeButton.MouseButton1Click:Connect(function()
        self:closeGUI()
    end)

    screenGui.Parent = playerGui
end

-- Select weapon category
function ModernLoadout:selectCategory(category, buttons)
    self.selectedCategory = category

    -- Update button colors
    for cat, button in pairs(buttons) do
        if cat == category then
            button.BackgroundColor3 = WEAPON_CATEGORIES[cat].color
        else
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end

    -- Refresh weapon list
    self:populateWeaponList()
end

-- Populate weapon list based on selected category
function ModernLoadout:populateWeaponList()
    -- Clear existing weapons
    for _, child in ipairs(self.weaponScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local weapons = WEAPON_CATEGORIES[self.selectedCategory].weapons
    local yOffset = 0

    for i, weaponName in ipairs(weapons) do
        local weaponFrame = Instance.new("Frame")
        weaponFrame.Size = UDim2.new(1, -10, 0, 40)
        weaponFrame.Position = UDim2.new(0, 0, 0, yOffset)
        weaponFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        weaponFrame.BorderSizePixel = 0
        weaponFrame.Parent = self.weaponScrollFrame

        local weaponButton = Instance.new("TextButton")
        weaponButton.Size = UDim2.new(1, 0, 1, 0)
        weaponButton.Position = UDim2.new(0, 0, 0, 0)
        weaponButton.BackgroundTransparency = 1
        weaponButton.Text = weaponName
        weaponButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        weaponButton.TextScaled = true
        weaponButton.Font = Enum.Font.SourceSans
        weaponButton.TextXAlignment = Enum.TextXAlignment.Left
        weaponButton.Parent = weaponFrame

        -- Selection indicator
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 4, 1, 0)
        indicator.Position = UDim2.new(0, 0, 0, 0)
        indicator.BackgroundColor3 = WEAPON_CATEGORIES[self.selectedCategory].color
        indicator.BorderSizePixel = 0
        indicator.Visible = weaponName == self.selectedWeapons.PRIMARY
        indicator.Parent = weaponFrame

        weaponButton.MouseButton1Click:Connect(function()
            self:selectWeapon(weaponName)
        end)

        yOffset = yOffset + 45
    end

    -- Update scroll canvas size
    self.weaponScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Select a weapon
function ModernLoadout:selectWeapon(weaponName)
    self.selectedWeapons.PRIMARY = weaponName

    -- Update selection indicators
    for _, child in ipairs(self.weaponScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            local indicator = child:FindFirstChild("Frame")
            if indicator then
                local button = child:FindFirstChild("TextButton")
                indicator.Visible = button and button.Text == weaponName
            end
        end
    end

    -- Update stats display
    self:updateStatsDisplay(weaponName)

    print("Selected weapon:", weaponName)
end

-- Update weapon stats display
function ModernLoadout:updateStatsDisplay(weaponName)
    -- Clear existing stats
    for _, child in ipairs(self.statsFrame:GetChildren()) do
        child:Destroy()
    end

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 50)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = weaponName
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = self.statsFrame

    -- Mock stats (replace with actual weapon config)
    local stats = {
        {name = "DAMAGE", value = math.random(30, 50), max = 50},
        {name = "RANGE", value = math.random(60, 90), max = 100},
        {name = "ACCURACY", value = math.random(70, 95), max = 100},
        {name = "MOBILITY", value = math.random(50, 80), max = 100},
        {name = "FIRE RATE", value = math.random(600, 900), max = 1000, unit = " RPM"}
    }

    local yOffset = 70
    for _, stat in ipairs(stats) do
        self:createStatBar(stat.name, stat.value, stat.max, yOffset, stat.unit or "")
        yOffset = yOffset + 50
    end
end

-- Create a stat bar
function ModernLoadout:createStatBar(name, value, maxValue, yPos, unit)
    local statFrame = Instance.new("Frame")
    statFrame.Size = UDim2.new(1, -20, 0, 40)
    statFrame.Position = UDim2.new(0, 10, 0, yPos)
    statFrame.BackgroundTransparency = 1
    statFrame.Parent = self.statsFrame

    local statLabel = Instance.new("TextLabel")
    statLabel.Size = UDim2.new(0.5, 0, 1, 0)
    statLabel.Position = UDim2.new(0, 0, 0, 0)
    statLabel.BackgroundTransparency = 1
    statLabel.Text = name
    statLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statLabel.TextScaled = true
    statLabel.Font = Enum.Font.SourceSans
    statLabel.TextXAlignment = Enum.TextXAlignment.Left
    statLabel.Parent = statFrame

    local statValue = Instance.new("TextLabel")
    statValue.Size = UDim2.new(0.5, 0, 1, 0)
    statValue.Position = UDim2.new(0.5, 0, 0, 0)
    statValue.BackgroundTransparency = 1
    statValue.Text = tostring(value) .. unit
    statValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    statValue.TextScaled = true
    statValue.Font = Enum.Font.SourceSansBold
    statValue.TextXAlignment = Enum.TextXAlignment.Right
    statValue.Parent = statFrame

    -- Stat bar
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, 0, 0, 4)
    barBG.Position = UDim2.new(0, 0, 1, -8)
    barBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    barBG.BorderSizePixel = 0
    barBG.Parent = statFrame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(value / maxValue, 0, 1, 0)
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = WEAPON_CATEGORIES[self.selectedCategory].color
    bar.BorderSizePixel = 0
    bar.Parent = barBG
end

-- Close the GUI
function ModernLoadout:closeGUI()
    if self.currentGUI then
        self.currentGUI:Destroy()
        self.currentGUI = nil
    end

    -- Re-lock mouse for gameplay
    if _G.FPSCameraMouseControl then
        _G.FPSCameraMouseControl.lockMouse()
    end
end

-- Open the loadout GUI
function ModernLoadout:openGUI()
    -- Unlock mouse for GUI interaction
    if _G.FPSCameraMouseControl then
        _G.FPSCameraMouseControl.unlockMouse()
    end

    -- Close existing GUI
    if self.currentGUI then
        self.currentGUI:Destroy()
    end

    self:createWeaponGUI()
end

-- Apply current loadout
function ModernLoadout:applyLoadout()
    print("Applying loadout:")
    for slot, weapon in pairs(self.selectedWeapons) do
        print(" -", slot, ":", weapon)
    end

    -- Apply to FPS Controller if available
    if _G.FPSController then
        for slot, weapon in pairs(self.selectedWeapons) do
            _G.FPSController:loadWeapon(slot, weapon)
        end
        _G.FPSController:equipWeapon("PRIMARY")
    end

    self:closeGUI()
end

-- Initialize
local modernLoadout = ModernLoadout.new()

-- Global access
_G.ModernLoadout = modernLoadout

-- Auto-open for testing
task.delay(2, function()
    print("Modern Loadout System initialized")
    print("Commands:")
    print(" - _G.ModernLoadout:openGUI() - Open modern loadout interface")
    print(" - _G.ModernLoadout:applyLoadout() - Apply current selections")
end)

return modernLoadout