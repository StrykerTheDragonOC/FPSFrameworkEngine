-- ModernUISystem.lua
-- Professional UI system with proper weapon organization (no emojis)
-- Place in ReplicatedStorage.FPSSystem.Modules

local UISystem = {}
UISystem.__index = UISystem

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- UI Constants
local UI_CONFIG = {
    -- Color scheme (modern dark theme)
    COLORS = {
        BACKGROUND = Color3.fromRGB(15, 15, 15),
        SURFACE = Color3.fromRGB(25, 25, 25),
        SURFACE_VARIANT = Color3.fromRGB(35, 35, 35),
        PRIMARY = Color3.fromRGB(85, 170, 255),
        SECONDARY = Color3.fromRGB(100, 255, 150),
        ACCENT = Color3.fromRGB(255, 165, 85),
        WARNING = Color3.fromRGB(255, 195, 85),
        ERROR = Color3.fromRGB(255, 100, 100),
        TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
        TEXT_SECONDARY = Color3.fromRGB(200, 200, 200),
        TEXT_MUTED = Color3.fromRGB(150, 150, 150)
    },

    -- Animation settings
    ANIMATIONS = {
        FAST = 0.15,
        NORMAL = 0.25,
        SLOW = 0.4,
        EASING = Enum.EasingStyle.Quad,
        DIRECTION = Enum.EasingDirection.Out
    },

    -- Layout settings
    LAYOUT = {
        PADDING = 10,
        LARGE_PADDING = 20,
        SMALL_PADDING = 5,
        BORDER_RADIUS = 8,
        LARGE_BORDER_RADIUS = 12
    }
}

-- Weapon categories with proper organization
local WEAPON_CATEGORIES = {
    {
        id = "ASSAULT",
        name = "ASSAULT RIFLES",
        color = UI_CONFIG.COLORS.PRIMARY,
        weapons = {
            "AK74", "AK47", "AK12", "AKM", "AN94",
            "M16A3", "M16A4", "M4A1", "G36", "G36C",
            "SCAR-L", "FAMAS", "AUG A1", "TAR21", "L85A2",
            "HK416", "ACE 52", "TYPE 88"
        }
    },
    {
        id = "SCOUT", 
        name = "CARBINES & PDWs",
        color = UI_CONFIG.COLORS.SECONDARY,
        weapons = {
            "AKU12", "G36K", "M4A1C", "SCAR-PDW", "HONEY BADGER",
            "SR3M", "AS VAL", "MP7", "P90", "UMP45",
            "MP5", "MP5K", "KRISS VECTOR", "MAC10"
        }
    },
    {
        id = "SUPPORT",
        name = "LIGHT MACHINE GUNS", 
        color = UI_CONFIG.COLORS.ACCENT,
        weapons = {
            "M60", "MG3KWS", "COLT LMG", "M249", "RPK",
            "L86 LSW", "HK21", "MG36", "AWS", "HAMR",
            "RPK12", "MG42"
        }
    },
    {
        id = "RECON",
        name = "SNIPER RIFLES",
        color = UI_CONFIG.COLORS.ERROR,
        weapons = {
            "INTERVENTION", "REMINGTON 700", "AWM", "TRG42",
            "MOSIN NAGANT", "DRAGUNOV SVDS", "BFG 50", "HECATE II",
            "M107", "NTW20", "BARRETT M82", "L115A3"
        }
    }
}

local SECONDARY_WEAPONS = {
    {
        category = "PISTOLS",
        weapons = {"M9", "GLOCK 17", "M1911", "DEAGLE 44", "FIVE SEVEN", "M45A1"}
    },
    {
        category = "MACHINE PISTOLS", 
        weapons = {"GLOCK 18", "TEC9", "MP1911", "MICRO UZI"}
    },
    {
        category = "REVOLVERS",
        weapons = {"MP412 REX", "JUDGE", "EXECUTIONER"}
    },
    {
        category = "OTHER",
        weapons = {"SAWED OFF", "ZIP 22", "SERBU SHOTGUN", "OBREZ"}
    }
}

local MELEE_WEAPONS = {
    "KNIFE", "TOMAHAWK", "CLEAVER", "MACHETE", "KATANA",
    "CROWBAR", "BASEBALL BAT", "SLEDGEHAMMER", "ICE PICK", "KARAMBIT"
}

local GRENADES = {
    "M67 FRAG", "RGO IMPACT", "M18 SMOKE", "FLASHBANG", "TEAR GAS"
}

-- Constructor
function UISystem.new()
    local self = setmetatable({}, UISystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")

    -- UI state
    self.currentGUI = nil
    self.isOpen = false
    self.selectedCategory = "ASSAULT"
    self.selectedWeapon = nil
    self.loadout = {
        PRIMARY = "AK74",
        SECONDARY = "M9", 
        MELEE = "KNIFE",
        GRENADE = "M67 FRAG"
    }

    -- UI elements cache
    self.elements = {}
    self.connections = {}

    print("Modern UI System initialized")
    return self
end

-- Create main loadout interface
function UISystem:createLoadoutGUI()
    -- Main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernLoadoutGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true

    -- Main container with backdrop
    local mainFrame = self:createFrame(screenGui, {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0
    })

    -- Content frame
    local contentFrame = self:createFrame(mainFrame, {
        Size = UDim2.new(0, 1200, 0, 800),
        Position = UDim2.new(0.5, -600, 0.5, -400),
        BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND,
        BorderSizePixel = 0
    })

    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, UI_CONFIG.LAYOUT.LARGE_BORDER_RADIUS)
    corner.Parent = contentFrame

    -- Header
    self:createHeader(contentFrame)

    -- Category navigation
    self:createCategoryNavigation(contentFrame)

    -- Weapon list
    self:createWeaponList(contentFrame)

    -- Stats panel
    self:createStatsPanel(contentFrame)

    -- Loadout display
    self:createLoadoutDisplay(contentFrame)

    -- Action buttons
    self:createActionButtons(contentFrame)

    -- Store references
    self.currentGUI = screenGui
    self.elements.mainFrame = mainFrame
    self.elements.contentFrame = contentFrame

    -- Add to player GUI
    screenGui.Parent = self.playerGui

    -- Animate in
    self:animateIn()

    return screenGui
end

-- Create styled frame
function UISystem:createFrame(parent, properties)
    local frame = Instance.new("Frame")

    for property, value in pairs(properties) do
        frame[property] = value
    end

    frame.Parent = parent
    return frame
end

-- Create styled text label
function UISystem:createTextLabel(parent, properties)
    local label = Instance.new("TextLabel")

    -- Default properties
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextColor3 = UI_CONFIG.COLORS.TEXT_PRIMARY
    label.TextScaled = true
    label.TextWrapped = true

    -- Apply custom properties
    for property, value in pairs(properties or {}) do
        label[property] = value
    end

    label.Parent = parent
    return label
end

-- Create styled button
function UISystem:createButton(parent, properties, callback)
    local button = Instance.new("TextButton")

    -- Default properties
    button.BackgroundColor3 = UI_CONFIG.COLORS.SURFACE
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansBold
    button.TextColor3 = UI_CONFIG.COLORS.TEXT_PRIMARY
    button.TextScaled = true

    -- Apply custom properties
    for property, value in pairs(properties or {}) do
        button[property] = value
    end

    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, UI_CONFIG.LAYOUT.BORDER_RADIUS)
    corner.Parent = button

    -- Add hover effects
    local originalColor = button.BackgroundColor3
    local hoverColor = Color3.new(
        math.min(originalColor.R + 0.1, 1),
        math.min(originalColor.G + 0.1, 1),
        math.min(originalColor.B + 0.1, 1)
    )

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(UI_CONFIG.ANIMATIONS.FAST), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(UI_CONFIG.ANIMATIONS.FAST), {
            BackgroundColor3 = originalColor
        }):Play()
    end)

    -- Connect callback
    if callback then
        button.MouseButton1Click:Connect(callback)
    end

    button.Parent = parent
    return button
end

-- Create header section
function UISystem:createHeader(parent)
    local headerFrame = self:createFrame(parent, {
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = UI_CONFIG.COLORS.SURFACE,
        BorderSizePixel = 0
    })

    -- Title
    local title = self:createTextLabel(headerFrame, {
        Size = UDim2.new(0, 400, 1, 0),
        Position = UDim2.new(0, UI_CONFIG.LAYOUT.LARGE_PADDING, 0, 0),
        Text = "WEAPON LOADOUTS",
        Font = Enum.Font.SourceSansBold,
        TextScaled = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Credits display
    local credits = self:createTextLabel(headerFrame, {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(1, -220, 0, 0),
        Text = "CREDITS: 1,573",
        Font = Enum.Font.SourceSans,
        TextScaled = true,
        TextXAlignment = Enum.TextXAlignment.Right
    })

    -- Close button
    local closeButton = self:createButton(headerFrame, {
        Size = UDim2.new(0, 100, 0, 40),
        Position = UDim2.new(1, -120, 0, 20),
        Text = "CLOSE",
        BackgroundColor3 = UI_CONFIG.COLORS.ERROR
    }, function()
        self:closeGUI()
    end)

    self.elements.header = headerFrame
end

-- Create category navigation
function UISystem:createCategoryNavigation(parent)
    local navFrame = self:createFrame(parent, {
        Size = UDim2.new(1, -40, 0, 60),
        Position = UDim2.new(0, 20, 0, 100),
        BackgroundTransparency = 1
    })

    -- Create layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, UI_CONFIG.LAYOUT.PADDING)
    layout.Parent = navFrame

    -- Create category buttons
    self.elements.categoryButtons = {}

    for i, category in ipairs(WEAPON_CATEGORIES) do
        local button = self:createButton(navFrame, {
            Size = UDim2.new(0, 280, 1, 0),
            Text = category.name,
            BackgroundColor3 = category.id == self.selectedCategory and category.color or UI_CONFIG.COLORS.SURFACE_VARIANT,
            Font = Enum.Font.SourceSansBold
        }, function()
            self:selectCategory(category.id)
        end)

        self.elements.categoryButtons[category.id] = button
    end

    self.elements.navigation = navFrame
end

-- Create weapon list
function UISystem:createWeaponList(parent)
    local listFrame = self:createFrame(parent, {
        Size = UDim2.new(0, 350, 1, -250),
        Position = UDim2.new(0, 20, 0, 180),
        BackgroundColor3 = UI_CONFIG.COLORS.SURFACE,
        BorderSizePixel = 0
    })

    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, UI_CONFIG.LAYOUT.BORDER_RADIUS)
    corner.Parent = listFrame

    -- Category title
    local categoryTitle = self:createTextLabel(listFrame, {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 10),
        Text = "PRIMARY WEAPONS",
        Font = Enum.Font.SourceSansBold,
        TextColor3 = UI_CONFIG.COLORS.TEXT_SECONDARY,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Scrolling frame for weapons
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -60)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = UI_CONFIG.COLORS.TEXT_MUTED
    scrollFrame.Parent = listFrame

    -- Layout for weapon items
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scrollFrame

    self.elements.weaponList = listFrame
    self.elements.weaponScroll = scrollFrame
    self.elements.categoryTitle = categoryTitle
end

-- Create stats panel
function UISystem:createStatsPanel(parent)
    local statsFrame = self:createFrame(parent, {
        Size = UDim2.new(0, 400, 1, -250),
        Position = UDim2.new(1, -420, 0, 180),
        BackgroundColor3 = UI_CONFIG.COLORS.SURFACE,
        BorderSizePixel = 0
    })

    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, UI_CONFIG.LAYOUT.BORDER_RADIUS)
    corner.Parent = statsFrame

    -- Weapon title
    local weaponTitle = self:createTextLabel(statsFrame, {
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 10),
        Text = "WEAPON STATS",
        Font = Enum.Font.SourceSansBold,
        TextScaled = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Stats container
    local statsContainer = self:createFrame(statsFrame, {
        Size = UDim2.new(1, -20, 1, -70),
        Position = UDim2.new(0, 10, 0, 60),
        BackgroundTransparency = 1
    })

    self.elements.statsPanel = statsFrame
    self.elements.statsContainer = statsContainer
    self.elements.weaponTitle = weaponTitle
end

-- Create loadout display
function UISystem:createLoadoutDisplay(parent)
    local loadoutFrame = self:createFrame(parent, {
        Size = UDim2.new(1, -40, 0, 80),
        Position = UDim2.new(0, 20, 1, -100),
        BackgroundColor3 = UI_CONFIG.COLORS.SURFACE_VARIANT,
        BorderSizePixel = 0
    })

    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, UI_CONFIG.LAYOUT.BORDER_RADIUS)
    corner.Parent = loadoutFrame

    -- Current loadout label
    local loadoutLabel = self:createTextLabel(loadoutFrame, {
        Size = UDim2.new(0, 200, 0, 30),
        Position = UDim2.new(0, 15, 0, 10),
        Text = "CURRENT LOADOUT",
        Font = Enum.Font.SourceSansBold,
        TextColor3 = UI_CONFIG.COLORS.TEXT_SECONDARY,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Loadout slots
    local slots = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
    local slotWidth = (loadoutFrame.AbsoluteSize.X - 100) / 4

    self.elements.loadoutSlots = {}

    for i, slot in ipairs(slots) do
        local slotFrame = self:createFrame(loadoutFrame, {
            Size = UDim2.new(0, 200, 0, 40),
            Position = UDim2.new(0, 15 + (i-1) * 210, 0, 35),
            BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND,
            BorderSizePixel = 0
        })

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, UI_CONFIG.LAYOUT.BORDER_RADIUS)
        slotCorner.Parent = slotFrame

        local slotLabel = self:createTextLabel(slotFrame, {
            Size = UDim2.new(0, 60, 1, 0),
            Position = UDim2.new(0, 5, 0, 0),
            Text = slot,
            Font = Enum.Font.SourceSans,
            TextColor3 = UI_CONFIG.COLORS.TEXT_MUTED,
            TextScaled = false,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local weaponLabel = self:createTextLabel(slotFrame, {
            Size = UDim2.new(1, -70, 1, 0),
            Position = UDim2.new(0, 65, 0, 0),
            Text = self.loadout[slot],
            Font = Enum.Font.SourceSansBold,
            TextScaled = false,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        self.elements.loadoutSlots[slot] = {
            frame = slotFrame,
            label = weaponLabel
        }
    end

    self.elements.loadoutDisplay = loadoutFrame
end

-- Create action buttons
function UISystem:createActionButtons(parent)
    local buttonFrame = self:createFrame(parent, {
        Size = UDim2.new(0, 300, 0, 50),
        Position = UDim2.new(0.5, -150, 1, -70),
        BackgroundTransparency = 1
    })

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, UI_CONFIG.LAYOUT.PADDING)
    layout.Parent = buttonFrame

    -- Apply button
    local applyButton = self:createButton(buttonFrame, {
        Size = UDim2.new(0, 120, 1, 0),
        Text = "APPLY",
        BackgroundColor3 = UI_CONFIG.COLORS.PRIMARY
    }, function()
        self:applyLoadout()
    end)

    -- Reset button  
    local resetButton = self:createButton(buttonFrame, {
        Size = UDim2.new(0, 120, 1, 0),
        Text = "RESET",
        BackgroundColor3 = UI_CONFIG.COLORS.WARNING
    }, function()
        self:resetLoadout()
    end)

    self.elements.actionButtons = buttonFrame
end

-- Select weapon category
function UISystem:selectCategory(categoryId)
    self.selectedCategory = categoryId

    -- Update button colors
    for id, button in pairs(self.elements.categoryButtons) do
        local category = nil
        for _, cat in ipairs(WEAPON_CATEGORIES) do
            if cat.id == id then
                category = cat
                break
            end
        end

        if category then
            local targetColor = id == categoryId and category.color or UI_CONFIG.COLORS.SURFACE_VARIANT
            TweenService:Create(button, TweenInfo.new(UI_CONFIG.ANIMATIONS.FAST), {
                BackgroundColor3 = targetColor
            }):Play()
        end
    end

    -- Update weapon list
    self:populateWeaponList()
end

-- Populate weapon list for selected category
function UISystem:populateWeaponList()
    -- Clear existing weapons
    for _, child in ipairs(self.elements.weaponScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Find selected category
    local selectedCat = nil
    for _, category in ipairs(WEAPON_CATEGORIES) do
        if category.id == self.selectedCategory then
            selectedCat = category
            break
        end
    end

    if not selectedCat then return end

    -- Update category title
    self.elements.categoryTitle.Text = selectedCat.name

    -- Create weapon buttons
    for i, weaponName in ipairs(selectedCat.weapons) do
        local weaponButton = self:createButton(self.elements.weaponScroll, {
            Size = UDim2.new(1, 0, 0, 35),
            Text = weaponName,
            BackgroundColor3 = UI_CONFIG.COLORS.SURFACE_VARIANT,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left
        }, function()
            self:selectWeapon(weaponName)
        end)

        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = weaponButton
    end

    -- Update canvas size
    local layout = self.elements.weaponScroll:FindFirstChild("UIListLayout")
    if layout then
        self.elements.weaponScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end
end

-- Select weapon and update stats
function UISystem:selectWeapon(weaponName)
    self.selectedWeapon = weaponName
    self.loadout.PRIMARY = weaponName

    -- Update loadout display
    if self.elements.loadoutSlots.PRIMARY then
        self.elements.loadoutSlots.PRIMARY.label.Text = weaponName
    end

    -- Update weapon title
    self.elements.weaponTitle.Text = weaponName

    -- Update stats display
    self:updateStatsDisplay(weaponName)

    print("Selected weapon:", weaponName)
end

-- Update weapon stats display
function UISystem:updateStatsDisplay(weaponName)
    -- Clear existing stats
    for _, child in ipairs(self.elements.statsContainer:GetChildren()) do
        child:Destroy()
    end

    -- Mock weapon stats (replace with actual weapon data)
    local stats = {
        {name = "DAMAGE", value = math.random(30, 50), max = 50, color = UI_CONFIG.COLORS.ERROR},
        {name = "RANGE", value = math.random(60, 90), max = 100, color = UI_CONFIG.COLORS.PRIMARY},
        {name = "ACCURACY", value = math.random(70, 95), max = 100, color = UI_CONFIG.COLORS.SECONDARY},
        {name = "MOBILITY", value = math.random(50, 80), max = 100, color = UI_CONFIG.COLORS.ACCENT},
        {name = "FIRE RATE", value = math.random(600, 900), max = 1000, color = UI_CONFIG.COLORS.WARNING}
    }

    for i, stat in ipairs(stats) do
        self:createStatBar(stat, i - 1)
    end
end

-- Create individual stat bar
function UISystem:createStatBar(stat, index)
    local yPos = index * 50

    local statFrame = self:createFrame(self.elements.statsContainer, {
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, yPos),
        BackgroundTransparency = 1
    })

    -- Stat name
    local nameLabel = self:createTextLabel(statFrame, {
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = stat.name,
        Font = Enum.Font.SourceSans,
        TextColor3 = UI_CONFIG.COLORS.TEXT_SECONDARY,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextScaled = false,
        TextSize = 14
    })

    -- Stat value
    local valueLabel = self:createTextLabel(statFrame, {
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.4, 0, 0, 0),
        Text = tostring(stat.value),
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextScaled = false,
        TextSize = 14
    })

    -- Stat bar background
    local barBG = self:createFrame(statFrame, {
        Size = UDim2.new(0.25, 0, 0, 4),
        Position = UDim2.new(0.75, 0, 0.5, -2),
        BackgroundColor3 = UI_CONFIG.COLORS.SURFACE_VARIANT,
        BorderSizePixel = 0
    })

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = barBG

    -- Stat bar fill
    local barFill = self:createFrame(barBG, {
        Size = UDim2.new(stat.value / stat.max, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = stat.color,
        BorderSizePixel = 0
    })

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = barFill
end

-- Apply current loadout
function UISystem:applyLoadout()
    print("Applying loadout:")
    for slot, weapon in pairs(self.loadout) do
        print(" -", slot, ":", weapon)
    end

    -- Integrate with weapon system
    if _G.EnhancedFPSController then
        for slot, weapon in pairs(self.loadout) do
            _G.EnhancedFPSController:loadWeapon(slot, weapon)
        end
        _G.EnhancedFPSController:switchToWeapon("PRIMARY")
    end

    self:closeGUI()
end

-- Reset loadout to defaults
function UISystem:resetLoadout()
    self.loadout = {
        PRIMARY = "AK74",
        SECONDARY = "M9",
        MELEE = "KNIFE", 
        GRENADE = "M67 FRAG"
    }

    -- Update display
    for slot, weapon in pairs(self.loadout) do
        if self.elements.loadoutSlots[slot] then
            self.elements.loadoutSlots[slot].label.Text = weapon
        end
    end

    print("Loadout reset to defaults")
end

-- Animate GUI in
function UISystem:animateIn()
    local contentFrame = self.elements.contentFrame

    -- Start offscreen
    contentFrame.Position = UDim2.new(0.5, -600, 1.5, 0)
    contentFrame.Size = UDim2.new(0, 1200, 0, 0)

    -- Animate to center
    local tween = TweenService:Create(contentFrame, 
        TweenInfo.new(UI_CONFIG.ANIMATIONS.SLOW, UI_CONFIG.ANIMATIONS.EASING, UI_CONFIG.ANIMATIONS.DIRECTION),
        {
            Position = UDim2.new(0.5, -600, 0.5, -400),
            Size = UDim2.new(0, 1200, 0, 800)
        }
    )
    tween:Play()
end

-- Animate GUI out  
function UISystem:animateOut(callback)
    local contentFrame = self.elements.contentFrame

    local tween = TweenService:Create(contentFrame,
        TweenInfo.new(UI_CONFIG.ANIMATIONS.NORMAL, UI_CONFIG.ANIMATIONS.EASING, Enum.EasingDirection.In),
        {
            Position = UDim2.new(0.5, -600, -1, 0),
            Size = UDim2.new(0, 1200, 0, 0)
        }
    )

    tween:Play()
    tween.Completed:Connect(function()
        if callback then callback() end
    end)
end

-- Open loadout GUI
function UISystem:openGUI()
    if self.isOpen then return end

    self.isOpen = true

    -- Unlock mouse
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    if _G.FPSCameraMouseControl then
        _G.FPSCameraMouseControl.unlockMouse()
    end

    -- Create GUI
    self:createLoadoutGUI()

    -- Populate initial data
    self:populateWeaponList()
    self:selectWeapon(self.loadout.PRIMARY)
end

-- Close loadout GUI
function UISystem:closeGUI()
    if not self.isOpen then return end

    self:animateOut(function()
        if self.currentGUI then
            self.currentGUI:Destroy()
            self.currentGUI = nil
        end

        self.isOpen = false

        -- Re-lock mouse
        if _G.FPSCameraMouseControl then
            _G.FPSCameraMouseControl.lockMouse()
        end

        print("Loadout GUI closed")
    end)
end

-- Cleanup
function UISystem:cleanup()
    print("Cleaning up Modern UI System")

    -- Disconnect connections
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    -- Destroy GUI
    if self.currentGUI then
        self.currentGUI:Destroy()
    end

    -- Clear references
    self.elements = {}
    self.connections = {}

    print("Modern UI System cleanup complete")
end

-- Initialize and export
local uiSystem = UISystem.new()
_G.ModernUISystem = uiSystem

-- Debug command
_G.OpenLoadout = function()
    uiSystem:openGUI()
end

return uiSystem