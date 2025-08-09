-- Enhanced Loadout Selector - Phantom Forces Style with Locked Weapons
-- Place in StarterPlayerScripts
local EnhancedLoadoutSelector = {}
EnhancedLoadoutSelector.__index = EnhancedLoadoutSelector

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Weapon Database with Unlock Requirements and Stats
local WEAPON_DATABASE = {
    -- PRIMARY WEAPONS (Assault Rifles First)
    PRIMARY = {
        -- ASSAULT RIFLES (First category)
        {category = "ASSAULT RIFLE", weapons = {
            {name = "AK-12", unlockRank = 0, damage = 42, range = 75, mobility = 68, rpm = 650, unlocked = true},
            {name = "AN-94", unlockRank = 12, damage = 45, range = 78, mobility = 65, rpm = 600, unlocked = false},
            {name = "AS VAL", unlockRank = 45, damage = 35, range = 45, mobility = 85, rpm = 900, unlocked = false},
            {name = "AUG A1", unlockRank = 20, damage = 38, range = 72, mobility = 70, rpm = 680, unlocked = false},
            {name = "M16A4", unlockRank = 25, damage = 40, range = 85, mobility = 66, rpm = 750, unlocked = false},
            {name = "G36", unlockRank = 15, damage = 34, range = 70, mobility = 72, rpm = 650, unlocked = true},
            {name = "SCAR-L", unlockRank = 35, damage = 41, range = 80, mobility = 67, rpm = 625, unlocked = false},
            {name = "M4A1", unlockRank = 30, damage = 36, range = 75, mobility = 74, rpm = 700, unlocked = false}
        }},

        -- BATTLE RIFLES
        {category = "BATTLE RIFLE", weapons = {
            {name = "AG-3", unlockRank = 50, damage = 55, range = 95, mobility = 55, rpm = 500, unlocked = false},
            {name = "SCAR-H", unlockRank = 40, damage = 52, range = 90, mobility = 58, rpm = 525, unlocked = false},
            {name = "FAL 50.00", unlockRank = 60, damage = 58, range = 100, mobility = 52, rpm = 475, unlocked = false}
        }},

        -- CARBINES  
        {category = "CARBINE", weapons = {
            {name = "M4A4", unlockRank = 18, damage = 35, range = 65, mobility = 78, rpm = 725, unlocked = false},
            {name = "AK-12C", unlockRank = 28, damage = 40, range = 68, mobility = 75, rpm = 675, unlocked = false},
            {name = "G36C", unlockRank = 22, damage = 33, range = 62, mobility = 80, rpm = 700, unlocked = false}
        }},

        -- DMRs
        {category = "DMR", weapons = {
            {name = "MK11", unlockRank = 70, damage = 65, range = 120, mobility = 45, rpm = 275, unlocked = false},
            {name = "SKS", unlockRank = 55, damage = 62, range = 115, mobility = 48, rpm = 300, unlocked = false},
            {name = "VSS VINTOREZ", unlockRank = 85, damage = 58, range = 95, mobility = 52, rpm = 325, unlocked = false}
        }},

        -- SNIPER RIFLES
        {category = "SNIPER RIFLE", weapons = {
            {name = "INTERVENTION", unlockRank = 0, damage = 95, range = 150, mobility = 35, rpm = 45, unlocked = true},
            {name = "REMINGTON 700", unlockRank = 10, damage = 92, range = 145, mobility = 38, rpm = 50, unlocked = false},
            {name = "AWP", unlockRank = 80, damage = 115, range = 160, mobility = 30, rpm = 40, unlocked = false},
            {name = "TRG-42", unlockRank = 95, damage = 105, range = 155, mobility = 32, rpm = 42, unlocked = false},
            {name = "NTW-20", unlockRank = 125, damage = 125, range = 180, mobility = 25, rpm = 35, unlocked = false}
        }}
    },

    -- SECONDARY WEAPONS
    SECONDARY = {
        {category = "PISTOLS", weapons = {
            {name = "M9", unlockRank = 0, damage = 28, range = 35, mobility = 95, rpm = 400, unlocked = true},
            {name = "GLOCK 17", unlockRank = 5, damage = 26, range = 32, mobility = 98, rpm = 425, unlocked = false},
            {name = "DESERT EAGLE XIX", unlockRank = 75, damage = 55, range = 45, mobility = 78, rpm = 275, unlocked = false},
            {name = "M1911", unlockRank = 25, damage = 42, range = 38, mobility = 85, rpm = 320, unlocked = false}
        }},

        {category = "MACHINE PISTOLS", weapons = {
            {name = "TMP", unlockRank = 45, damage = 22, range = 28, mobility = 92, rpm = 950, unlocked = false},
            {name = "G18", unlockRank = 55, damage = 24, range = 30, mobility = 90, rpm = 900, unlocked = false}
        }},

        {category = "REVOLVERS", weapons = {
            {name = "MP412 REX", unlockRank = 40, damage = 68, range = 50, mobility = 70, rpm = 180, unlocked = false},
            {name = "JUDGE", unlockRank = 65, damage = 45, range = 25, mobility = 75, rpm = 200, unlocked = false}
        }}
    },

    -- MELEE WEAPONS
    MELEE = {
        {category = "BLADE", weapons = {
            {name = "KNIFE", unlockRank = 0, damage = 85, range = 5, mobility = 100, rpm = 200, unlocked = true},
            {name = "KARAMBIT", unlockRank = 50, damage = 90, range = 4, mobility = 105, rpm = 185, unlocked = false},
            {name = "TOMAHAWK", unlockRank = 75, damage = 95, range = 6, mobility = 95, rpm = 175, unlocked = false}
        }}
    },

    -- GRENADES
    GRENADE = {
        {category = "EXPLOSIVE", weapons = {
            {name = "M67 FRAG", unlockRank = 0, damage = 100, range = 15, mobility = 90, rpm = 60, unlocked = true},
            {name = "RGD-5", unlockRank = 20, damage = 95, range = 18, mobility = 88, rpm = 65, unlocked = false}
        }},

        {category = "TACTICAL", weapons = {
            {name = "FLASHBANG", unlockRank = 15, damage = 0, range = 12, mobility = 95, rpm = 45, unlocked = false},
            {name = "SMOKE GRENADE", unlockRank = 25, damage = 0, range = 20, mobility = 92, rpm = 40, unlocked = false}
        }}
    }
}

-- Player progression data (would normally come from DataStore)
local PLAYER_DATA = {
    rank = 18, -- Example rank
    kills = 1247,
    credits = 2500
}

function EnhancedLoadoutSelector.new()
    local self = setmetatable({}, EnhancedLoadoutSelector)

    -- State
    self.isOpen = false
    self.currentSlot = "PRIMARY"
    self.selectedWeapon = nil
    self.currentLoadout = {
        PRIMARY = "AK-12",
        SECONDARY = "M9",
        MELEE = "KNIFE", 
        GRENADE = "M67 FRAG"
    }

    -- UI References
    self.gui = nil
    self.weaponPreview = nil
    self.statsDisplay = nil

    return self
end

-- Open the loadout menu
function EnhancedLoadoutSelector:openMenu()
    if self.isOpen then return end

    self.isOpen = true

    -- Unlock mouse
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true

    -- Create GUI
    self:createMainGUI()
end

-- Close the menu
function EnhancedLoadoutSelector:closeMenu()
    if not self.isOpen then return end

    self.isOpen = false

    -- Lock mouse back
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Destroy GUI
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end

    -- Update main menu if it exists
    if _G.MainMenuSystem then
        _G.MainMenuSystem:updateLoadout(self.currentLoadout)
    end
end

-- Create main GUI
function EnhancedLoadoutSelector:createMainGUI()
    -- Create main GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EnhancedLoadoutSelector"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 150
    screenGui.Parent = playerGui

    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    background.BorderSizePixel = 0
    background.Parent = screenGui

    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0.95, 0, 0.9, 0)
    container.Position = UDim2.new(0.025, 0, 0.05, 0)
    container.BackgroundTransparency = 1
    container.Parent = background

    -- Create layout sections
    self:createHeader(container)
    self:createCategoryTabs(container)
    self:createWeaponList(container)
    self:createWeaponPreview(container)
    self:createStatsDisplay(container)

    self.gui = screenGui

    -- Load initial category
    self:selectCategory("PRIMARY")
end

-- Create header
function EnhancedLoadoutSelector:createHeader(parent)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0.08, 0)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    header.BorderSizePixel = 0
    header.Parent = parent

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.3, 0, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "WEAPON LOADOUTS"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Player info
    local playerInfo = Instance.new("TextLabel")
    playerInfo.Size = UDim2.new(0.3, 0, 1, 0)
    playerInfo.Position = UDim2.new(0.4, 0, 0, 0)
    playerInfo.BackgroundTransparency = 1
    playerInfo.Text = "RANK " .. PLAYER_DATA.rank .. " | " .. PLAYER_DATA.credits .. " CREDITS"
    playerInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
    playerInfo.TextScaled = true
    playerInfo.Font = Enum.Font.Gotham
    playerInfo.Parent = header

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.08, 0, 0.6, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0.2, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "?"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:closeMenu()
    end)
end

-- Create category tabs
function EnhancedLoadoutSelector:createCategoryTabs(parent)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "CategoryTabs"
    tabFrame.Size = UDim2.new(1, 0, 0.08, 0)
    tabFrame.Position = UDim2.new(0, 0, 0.08, 0)
    tabFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    tabFrame.BorderSizePixel = 0
    tabFrame.Parent = parent

    local categories = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
    local colors = {
        Color3.fromRGB(70, 130, 180),
        Color3.fromRGB(255, 140, 0),
        Color3.fromRGB(220, 20, 60),
        Color3.fromRGB(34, 139, 34)
    }

    for i, category in ipairs(categories) do
        local tab = Instance.new("TextButton")
        tab.Name = category .. "Tab"
        tab.Size = UDim2.new(0.25, -5, 0.8, 0)
        tab.Position = UDim2.new((i-1) * 0.25, 5, 0.1, 0)
        tab.BackgroundColor3 = colors[i]
        tab.Text = category
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.TextScaled = true
        tab.Font = Enum.Font.GothamBold
        tab.Parent = tabFrame

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tab

        tab.MouseButton1Click:Connect(function()
            self:selectCategory(category)
        end)
    end
end

-- Create weapon list
function EnhancedLoadoutSelector:createWeaponList(parent)
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "WeaponList"
    listFrame.Size = UDim2.new(0.4, -10, 0.84, 0)
    listFrame.Position = UDim2.new(0, 5, 0.16, 0)
    listFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 8
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    listFrame.Parent = parent

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = listFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = listFrame

    self.weaponListFrame = listFrame
end

-- Create weapon preview
function EnhancedLoadoutSelector:createWeaponPreview(parent)
    local previewFrame = Instance.new("Frame")
    previewFrame.Name = "WeaponPreview"
    previewFrame.Size = UDim2.new(0.35, -10, 0.5, 0)
    previewFrame.Position = UDim2.new(0.4, 5, 0.16, 0)
    previewFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = parent

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = previewFrame

    -- Viewport for 3D weapon
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, -20, 0.8, -20)
    viewport.Position = UDim2.new(0, 10, 0, 10)
    viewport.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    viewport.BorderSizePixel = 0
    viewport.Parent = previewFrame

    local viewportCorner = Instance.new("UICorner")
    viewportCorner.CornerRadius = UDim.new(0, 6)
    viewportCorner.Parent = viewport

    -- Weapon name label
    local weaponNameLabel = Instance.new("TextLabel")
    weaponNameLabel.Size = UDim2.new(1, -20, 0.2, -10)
    weaponNameLabel.Position = UDim2.new(0, 10, 0.8, 5)
    weaponNameLabel.BackgroundTransparency = 1
    weaponNameLabel.Text = "SELECT A WEAPON"
    weaponNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    weaponNameLabel.TextScaled = true
    weaponNameLabel.Font = Enum.Font.GothamBold
    weaponNameLabel.Parent = previewFrame

    self.weaponPreview = {
        frame = previewFrame,
        viewport = viewport,
        nameLabel = weaponNameLabel
    }
end

-- Create stats display
function EnhancedLoadoutSelector:createStatsDisplay(parent)
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsDisplay"
    statsFrame.Size = UDim2.new(0.25, -10, 0.84, 0)
    statsFrame.Position = UDim2.new(0.75, 5, 0.16, 0)
    statsFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = parent

    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame

    -- Stats title
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, -20, 0, 40)
    statsTitle.Position = UDim2.new(0, 10, 0, 10)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "WEAPON STATS"
    statsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsTitle.TextScaled = true
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.Parent = statsFrame

    self.statsDisplay = {
        frame = statsFrame,
        title = statsTitle
    }
end

-- Select category and load weapons
function EnhancedLoadoutSelector:selectCategory(category)
    self.currentSlot = category
    self:loadWeaponsForCategory(category)
end

-- Load weapons for category
function EnhancedLoadoutSelector:loadWeaponsForCategory(category)
    local weaponData = WEAPON_DATABASE[category]
    if not weaponData then return end

    -- Clear existing weapons
    for _, child in pairs(self.weaponListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local layoutOrder = 1

    -- Create weapons by subcategory
    for _, subcategory in ipairs(weaponData) do
        -- Category header
        local categoryHeader = Instance.new("Frame")
        categoryHeader.Size = UDim2.new(1, -10, 0, 35)
        categoryHeader.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
        categoryHeader.BorderSizePixel = 0
        categoryHeader.LayoutOrder = layoutOrder
        categoryHeader.Parent = self.weaponListFrame

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 4)
        headerCorner.Parent = categoryHeader

        local categoryLabel = Instance.new("TextLabel")
        categoryLabel.Size = UDim2.new(1, -20, 1, 0)
        categoryLabel.Position = UDim2.new(0, 10, 0, 0)
        categoryLabel.BackgroundTransparency = 1
        categoryLabel.Text = subcategory.category
        categoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        categoryLabel.TextScaled = true
        categoryLabel.Font = Enum.Font.GothamBold
        categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
        categoryLabel.Parent = categoryHeader

        layoutOrder = layoutOrder + 1

        -- Create weapon entries
        for _, weapon in ipairs(subcategory.weapons) do
            local weaponFrame = self:createWeaponEntry(weapon, layoutOrder)
            weaponFrame.Parent = self.weaponListFrame
            layoutOrder = layoutOrder + 1
        end
    end

    -- Update canvas size
    self.weaponListFrame.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 50)
end

-- Create weapon entry
function EnhancedLoadoutSelector:createWeaponEntry(weaponData, layoutOrder)
    local isLocked = PLAYER_DATA.rank < weaponData.unlockRank
    local isSelected = weaponData.name == self.currentLoadout[self.currentSlot]

    local weaponFrame = Instance.new("TextButton")
    weaponFrame.Size = UDim2.new(1, -10, 0, 45)
    weaponFrame.BackgroundColor3 = isSelected and Color3.fromRGB(60, 120, 200) or Color3.fromRGB(35, 40, 50)
    weaponFrame.BorderSizePixel = 0
    weaponFrame.LayoutOrder = layoutOrder
    weaponFrame.Text = ""

    local weaponCorner = Instance.new("UICorner")
    weaponCorner.CornerRadius = UDim.new(0, 4)
    weaponCorner.Parent = weaponFrame

    -- Lock overlay if locked
    if isLocked then
        local lockOverlay = Instance.new("Frame")
        lockOverlay.Size = UDim2.new(1, 0, 1, 0)
        lockOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        lockOverlay.BackgroundTransparency = 0.3
        lockOverlay.BorderSizePixel = 0
        lockOverlay.Parent = weaponFrame

        local lockCorner = Instance.new("UICorner")
        lockCorner.CornerRadius = UDim.new(0, 4)
        lockCorner.Parent = lockOverlay

        local lockIcon = Instance.new("TextLabel")
        lockIcon.Size = UDim2.new(0, 30, 0, 30)
        lockIcon.Position = UDim2.new(0, 10, 0.5, -15)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Text = "??"
        lockIcon.TextColor3 = Color3.fromRGB(255, 200, 0)
        lockIcon.TextScaled = true
        lockIcon.Font = Enum.Font.Gotham
        lockIcon.Parent = lockOverlay
    end

    -- Weapon name
    local weaponName = Instance.new("TextLabel")
    weaponName.Size = UDim2.new(0.6, -50, 0.6, 0)
    weaponName.Position = UDim2.new(0, isLocked and 50 or 15, 0, 5)
    weaponName.BackgroundTransparency = 1
    weaponName.Text = weaponData.name
    weaponName.TextColor3 = isLocked and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255)
    weaponName.TextScaled = true
    weaponName.Font = Enum.Font.GothamBold
    weaponName.TextXAlignment = Enum.TextXAlignment.Left
    weaponName.Parent = weaponFrame

    -- Unlock requirement if locked
    if isLocked then
        local unlockText = Instance.new("TextLabel")
        unlockText.Size = UDim2.new(0.6, -50, 0.4, 0)
        unlockText.Position = UDim2.new(0, 50, 0.6, 0)
        unlockText.BackgroundTransparency = 1
        unlockText.Text = "RANK " .. weaponData.unlockRank .. " REQUIRED"
        unlockText.TextColor3 = Color3.fromRGB(255, 200, 0)
        unlockText.TextScaled = true
        unlockText.Font = Enum.Font.Gotham
        unlockText.TextXAlignment = Enum.TextXAlignment.Left
        unlockText.Parent = weaponFrame
    end

    -- Damage indicator
    local damageBar = Instance.new("Frame")
    damageBar.Size = UDim2.new(0.25, 0, 0.2, 0)
    damageBar.Position = UDim2.new(0.7, 0, 0.2, 0)
    damageBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    damageBar.BorderSizePixel = 0
    damageBar.Parent = weaponFrame

    local damageBarCorner = Instance.new("UICorner")
    damageBarCorner.CornerRadius = UDim.new(0, 2)
    damageBarCorner.Parent = damageBar

    local damageFill = Instance.new("Frame")
    damageFill.Size = UDim2.new(weaponData.damage / 100, 0, 1, 0)
    damageFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    damageFill.BorderSizePixel = 0
    damageFill.Parent = damageBar

    local damageFillCorner = Instance.new("UICorner")
    damageFillCorner.CornerRadius = UDim.new(0, 2)
    damageFillCorner.Parent = damageFill

    -- Range indicator  
    local rangeBar = Instance.new("Frame")
    rangeBar.Size = UDim2.new(0.25, 0, 0.2, 0)
    rangeBar.Position = UDim2.new(0.7, 0, 0.6, 0)
    rangeBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    rangeBar.BorderSizePixel = 0
    rangeBar.Parent = weaponFrame

    local rangeBarCorner = Instance.new("UICorner")
    rangeBarCorner.CornerRadius = UDim.new(0, 2)
    rangeBarCorner.Parent = rangeBar

    local rangeFill = Instance.new("Frame")
    rangeFill.Size = UDim2.new(weaponData.range / 150, 0, 1, 0)
    rangeFill.BackgroundColor3 = Color3.fromRGB(50, 150, 220)
    rangeFill.BorderSizePixel = 0
    rangeFill.Parent = rangeBar

    local rangeFillCorner = Instance.new("UICorner")
    rangeFillCorner.CornerRadius = UDim.new(0, 2)
    rangeFillCorner.Parent = rangeFill

    -- Click handler
    weaponFrame.MouseButton1Click:Connect(function()
        self:selectWeapon(weaponData)
    end)

    -- Hover effects
    weaponFrame.MouseEnter:Connect(function()
        if not isSelected and not isLocked then
            TweenService:Create(weaponFrame, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(45, 50, 60)
            }):Play()
        end
        self:previewWeapon(weaponData)
    end)

    weaponFrame.MouseLeave:Connect(function()
        if not isSelected then
            TweenService:Create(weaponFrame, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(35, 40, 50)
            }):Play()
        end
    end)

    return weaponFrame
end

-- Select weapon
function EnhancedLoadoutSelector:selectWeapon(weaponData)
    local isLocked = PLAYER_DATA.rank < weaponData.unlockRank

    if isLocked then
        print("Weapon locked! Rank " .. weaponData.unlockRank .. " required")
        return
    end

    self.currentLoadout[self.currentSlot] = weaponData.name
    self.selectedWeapon = weaponData

    print("Selected " .. weaponData.name .. " for " .. self.currentSlot)

    -- Refresh weapon list to update selection
    self:loadWeaponsForCategory(self.currentSlot)

    -- Update preview
    self:previewWeapon(weaponData)
end

-- Preview weapon (show even if locked)
function EnhancedLoadoutSelector:previewWeapon(weaponData)
    if not self.weaponPreview then return end

    -- Update weapon name
    local isLocked = PLAYER_DATA.rank < weaponData.unlockRank
    local nameText = weaponData.name
    if isLocked then
        nameText = nameText .. " (LOCKED)"
    end

    self.weaponPreview.nameLabel.Text = nameText
    self.weaponPreview.nameLabel.TextColor3 = isLocked and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 255, 255)

    -- Show weapon stats
    self:showWeaponStats(weaponData)

    -- TODO: Load 3D weapon model in viewport
    self:load3DWeaponModel(weaponData)
end

-- Show weapon stats
function EnhancedLoadoutSelector:showWeaponStats(weaponData)
    if not self.statsDisplay then return end

    -- Clear existing stats
    for _, child in pairs(self.statsDisplay.frame:GetChildren()) do
        if child.Name:find("Stat") then
            child:Destroy()
        end
    end

    local stats = {"damage", "range", "mobility", "rpm"}
    local statNames = {"DAMAGE", "RANGE", "MOBILITY", "FIRE RATE"}
    local statColors = {
        Color3.fromRGB(220, 50, 50),
        Color3.fromRGB(50, 150, 220),
        Color3.fromRGB(50, 220, 100),
        Color3.fromRGB(220, 150, 50)
    }

    for i, stat in ipairs(stats) do
        local yPos = 60 + (i - 1) * 60

        -- Stat name
        local statLabel = Instance.new("TextLabel")
        statLabel.Name = "Stat" .. i .. "Label"
        statLabel.Size = UDim2.new(1, -20, 0, 20)
        statLabel.Position = UDim2.new(0, 10, 0, yPos)
        statLabel.BackgroundTransparency = 1
        statLabel.Text = statNames[i]
        statLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statLabel.TextScaled = true
        statLabel.Font = Enum.Font.Gotham
        statLabel.TextXAlignment = Enum.TextXAlignment.Left
        statLabel.Parent = self.statsDisplay.frame

        -- Stat bar background
        local statBarBG = Instance.new("Frame")
        statBarBG.Name = "Stat" .. i .. "BarBG"
        statBarBG.Size = UDim2.new(1, -20, 0, 10)
        statBarBG.Position = UDim2.new(0, 10, 0, yPos + 25)
        statBarBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        statBarBG.BorderSizePixel = 0
        statBarBG.Parent = self.statsDisplay.frame

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 2)
        barCorner.Parent = statBarBG

        -- Stat bar fill
        local maxValue = stat == "rpm" and 1000 or 150
        local statBar = Instance.new("Frame")
        statBar.Name = "Stat" .. i .. "Bar"
        statBar.Size = UDim2.new(weaponData[stat] / maxValue, 0, 1, 0)
        statBar.BackgroundColor3 = statColors[i]
        statBar.BorderSizePixel = 0
        statBar.Parent = statBarBG

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 2)
        fillCorner.Parent = statBar

        -- Stat value
        local statValue = Instance.new("TextLabel")
        statValue.Name = "Stat" .. i .. "Value"
        statValue.Size = UDim2.new(0, 40, 0, 20)
        statValue.Position = UDim2.new(1, -45, 0, yPos)
        statValue.BackgroundTransparency = 1
        statValue.Text = tostring(weaponData[stat])
        statValue.TextColor3 = Color3.fromRGB(255, 255, 255)
        statValue.TextScaled = true
        statValue.Font = Enum.Font.GothamBold
        statValue.Parent = self.statsDisplay.frame
    end
end

-- Load 3D weapon model (placeholder)
function EnhancedLoadoutSelector:load3DWeaponModel(weaponData)
    -- Clear existing model
    self.weaponPreview.viewport:ClearAllChildren()

    -- Create camera
    local camera = Instance.new("Camera")
    camera.Parent = self.weaponPreview.viewport
    self.weaponPreview.viewport.CurrentCamera = camera

    -- Create placeholder weapon (replace with actual model loading)
    local weapon = Instance.new("Part")
    weapon.Size = Vector3.new(0.5, 0.3, 2) * 1.5  -- Bigger preview
    weapon.Color = Color3.fromRGB(100, 100, 100)
    weapon.Material = Enum.Material.Metal
    weapon.Anchored = true
    weapon.Parent = self.weaponPreview.viewport

    -- Position camera
    camera.CFrame = CFrame.new(Vector3.new(3, 1, 0), Vector3.new(0, 0, 0))

    -- Add rotation animation
    spawn(function()
        while weapon.Parent do
            weapon.CFrame = weapon.CFrame * CFrame.Angles(0, math.rad(1), 0)
            wait(0.05)
        end
    end)
end

-- Initialize the system
local enhancedLoadout = EnhancedLoadoutSelector.new()

-- Export globally
_G.EnhancedLoadoutSelector = enhancedLoadout

-- Key binding to open
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.L then
        if enhancedLoadout.isOpen then
            enhancedLoadout:closeMenu()
        else
            enhancedLoadout:openMenu()
        end
    end
end)

return EnhancedLoadoutSelector