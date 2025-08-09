-- Advanced UI System for High-Tech FPS Experience
-- Place in ReplicatedStorage.FPSSystem.Modules.AdvancedUISystem
local AdvancedUISystem = {}
AdvancedUISystem.__index = AdvancedUISystem

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- UI Configuration
local UI_CONFIG = {
    -- Theme colors
    COLORS = {
        PRIMARY = Color3.fromRGB(0, 162, 255),
        SECONDARY = Color3.fromRGB(255, 255, 255),
        ACCENT = Color3.fromRGB(255, 100, 0),
        SUCCESS = Color3.fromRGB(0, 255, 100),
        WARNING = Color3.fromRGB(255, 200, 0),
        DANGER = Color3.fromRGB(255, 50, 50),
        BACKGROUND = Color3.fromRGB(20, 20, 30),
        FOREGROUND = Color3.fromRGB(40, 40, 50)
    },

    -- Animation settings
    ANIMATIONS = {
        FAST = 0.15,
        NORMAL = 0.3,
        SLOW = 0.6,
        EASE_STYLE = Enum.EasingStyle.Quart,
        EASE_DIRECTION = Enum.EasingDirection.Out
    },

    -- Kill feed settings
    KILL_FEED = {
        MAX_ENTRIES = 8,
        ENTRY_LIFETIME = 6.0,
        FADE_TIME = 1.0,
        UPDATE_RATE = 0.1
    },

    -- Hit marker settings
    HIT_MARKERS = {
        DURATION = 0.3,
        SIZE = 20,
        THICKNESS = 3,
        HEADSHOT_COLOR = Color3.fromRGB(255, 0, 0),
        BODY_COLOR = Color3.fromRGB(255, 255, 255),
        ARMOR_COLOR = Color3.fromRGB(100, 150, 255)
    },

    -- Damage indicator settings
    DAMAGE_INDICATORS = {
        FADE_DISTANCE = 100,
        MAX_DISTANCE = 500,
        MIN_ALPHA = 0.3,
        PULSE_RATE = 2.0
    }
}

function AdvancedUISystem.new()
    local self = setmetatable({}, AdvancedUISystem)

    -- References
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.camera = workspace.CurrentCamera

    -- UI State
    self.isInitialized = false
    self.currentWeapon = nil
    self.currentAmmo = {current = 0, reserve = 0}
    self.currentHealth = 100
    self.currentArmor = 0

    -- UI Elements
    self.mainGui = nil
    self.crosshair = nil
    self.hud = nil
    self.killFeed = nil
    self.hitMarkers = {}
    self.damageIndicators = {}

    -- Kill feed data
    self.killFeedEntries = {}

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the UI system
function AdvancedUISystem:initialize()
    -- Hide default Roblox UI
    self:hideDefaultUI()

    -- Create main GUI container
    self:createMainGUI()

    -- Create UI components
    self:createCrosshair()
    self:createHUD()
    self:createKillFeed()
    self:createHitMarkerSystem()
    self:createDamageIndicatorSystem()

    -- Start update loops
    self:startUpdateLoops()

    self.isInitialized = true
    print("Advanced UI System initialized")
end

-- Hide default Roblox UI
function AdvancedUISystem:hideDefaultUI()
    local coreGuiTypes = {
        Enum.CoreGuiType.PlayerList,
        Enum.CoreGuiType.Health,
        Enum.CoreGuiType.Backpack,
        Enum.CoreGuiType.Chat
    }

    for _, guiType in ipairs(coreGuiTypes) do
        StarterGui:SetCoreGuiEnabled(guiType, false)
    end
end

-- Create main GUI container
function AdvancedUISystem:createMainGUI()
    self.mainGui = Instance.new("ScreenGui")
    self.mainGui.Name = "AdvancedFPSUI"
    self.mainGui.ResetOnSpawn = false
    self.mainGui.IgnoreGuiInset = true
    self.mainGui.DisplayOrder = 100
    self.mainGui.Parent = self.playerGui
end

-- Create dynamic crosshair system
function AdvancedUISystem:createCrosshair()
    local crosshairFrame = Instance.new("Frame")
    crosshairFrame.Name = "CrosshairFrame"
    crosshairFrame.Size = UDim2.new(0, 100, 0, 100)
    crosshairFrame.Position = UDim2.new(0.5, -50, 0.5, -50)
    crosshairFrame.BackgroundTransparency = 1
    crosshairFrame.Parent = self.mainGui

    -- Dynamic crosshair components
    local crosshairData = {
        top = self:createCrosshairLine(crosshairFrame, UDim2.new(0.5, -1, 0, -20), UDim2.new(0, 2, 0, 15)),
        bottom = self:createCrosshairLine(crosshairFrame, UDim2.new(0.5, -1, 1, 5), UDim2.new(0, 2, 0, 15)),
        left = self:createCrosshairLine(crosshairFrame, UDim2.new(0, -20, 0.5, -1), UDim2.new(0, 15, 0, 2)),
        right = self:createCrosshairLine(crosshairFrame, UDim2.new(1, 5, 0.5, -1), UDim2.new(0, 15, 0, 2)),
        center = self:createCrosshairDot(crosshairFrame)
    }

    self.crosshair = {
        frame = crosshairFrame,
        elements = crosshairData,
        currentSpread = 0,
        targetSpread = 0
    }
end

-- Create crosshair line
function AdvancedUISystem:createCrosshairLine(parent, position, size)
    local line = Instance.new("Frame")
    line.Position = position
    line.Size = size
    line.BackgroundColor3 = UI_CONFIG.COLORS.SECONDARY
    line.BorderSizePixel = 0
    line.Parent = parent

    -- Add outline
    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(0, 0, 0)
    outline.Thickness = 1
    outline.Parent = line

    return line
end

-- Create crosshair center dot
function AdvancedUISystem:createCrosshairDot(parent)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 2, 0, 2)
    dot.Position = UDim2.new(0.5, -1, 0.5, -1)
    dot.BackgroundColor3 = UI_CONFIG.COLORS.ACCENT
    dot.BorderSizePixel = 0
    dot.Parent = parent

    return dot
end

-- Create main HUD
function AdvancedUISystem:createHUD()
    -- Health and armor display
    local healthFrame = self:createHealthDisplay()

    -- Ammo display
    local ammoFrame = self:createAmmoDisplay()

    -- Weapon info display
    local weaponFrame = self:createWeaponDisplay()

    -- Minimap
    local minimapFrame = self:createMinimap()

    -- Score display
    local scoreFrame = self:createScoreDisplay()

    self.hud = {
        health = healthFrame,
        ammo = ammoFrame,
        weapon = weaponFrame,
        minimap = minimapFrame,
        score = scoreFrame
    }
end

-- Create health display
function AdvancedUISystem:createHealthDisplay()
    local frame = Instance.new("Frame")
    frame.Name = "HealthFrame"
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(0, 20, 1, -100)
    frame.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = self.mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Health bar
    local healthBG = Instance.new("Frame")
    healthBG.Size = UDim2.new(1, -20, 0, 15)
    healthBG.Position = UDim2.new(0, 10, 0, 10)
    healthBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBG.BorderSizePixel = 0
    healthBG.Parent = frame

    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(0, 3)
    healthBarCorner.Parent = healthBG

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = UI_CONFIG.COLORS.SUCCESS
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBG

    local healthFillCorner = Instance.new("UICorner")
    healthFillCorner.CornerRadius = UDim.new(0, 3)
    healthFillCorner.Parent = healthBar

    -- Health text
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 0, 25)
    healthText.Position = UDim2.new(0, 0, 0, 30)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100 HP"
    healthText.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    healthText.TextScaled = true
    healthText.Font = Enum.Font.GothamBold
    healthText.Parent = frame

    -- Armor bar (if applicable)
    local armorBG = Instance.new("Frame")
    armorBG.Size = UDim2.new(1, -20, 0, 10)
    armorBG.Position = UDim2.new(0, 10, 0, 55)
    armorBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    armorBG.BorderSizePixel = 0
    armorBG.Parent = frame

    local armorBarCorner = Instance.new("UICorner")
    armorBarCorner.CornerRadius = UDim.new(0, 2)
    armorBarCorner.Parent = armorBG

    local armorBar = Instance.new("Frame")
    armorBar.Name = "ArmorBar"
    armorBar.Size = UDim2.new(0, 0, 1, 0)
    armorBar.Position = UDim2.new(0, 0, 0, 0)
    armorBar.BackgroundColor3 = UI_CONFIG.COLORS.PRIMARY
    armorBar.BorderSizePixel = 0
    armorBar.Parent = armorBG

    local armorFillCorner = Instance.new("UICorner")
    armorFillCorner.CornerRadius = UDim.new(0, 2)
    armorFillCorner.Parent = armorBar

    return {
        frame = frame,
        healthBar = healthBar,
        healthText = healthText,
        armorBar = armorBar
    }
end

-- Create ammo display
function AdvancedUISystem:createAmmoDisplay()
    local frame = Instance.new("Frame")
    frame.Name = "AmmoFrame"
    frame.Size = UDim2.new(0, 250, 0, 100)
    frame.Position = UDim2.new(1, -270, 1, -120)
    frame.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = self.mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Current ammo (large number)
    local currentAmmoText = Instance.new("TextLabel")
    currentAmmoText.Name = "CurrentAmmo"
    currentAmmoText.Size = UDim2.new(0.6, 0, 0.7, 0)
    currentAmmoText.Position = UDim2.new(0, 10, 0, 5)
    currentAmmoText.BackgroundTransparency = 1
    currentAmmoText.Text = "30"
    currentAmmoText.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    currentAmmoText.TextScaled = true
    currentAmmoText.Font = Enum.Font.GothamBold
    currentAmmoText.TextXAlignment = Enum.TextXAlignment.Right
    currentAmmoText.Parent = frame

    -- Separator
    local separator = Instance.new("TextLabel")
    separator.Size = UDim2.new(0, 20, 0.7, 0)
    separator.Position = UDim2.new(0.6, 5, 0, 5)
    separator.BackgroundTransparency = 1
    separator.Text = "/"
    separator.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    separator.TextScaled = true
    separator.Font = Enum.Font.GothamBold
    separator.Parent = frame

    -- Reserve ammo
    local reserveAmmoText = Instance.new("TextLabel")
    reserveAmmoText.Name = "ReserveAmmo"
    reserveAmmoText.Size = UDim2.new(0.35, -25, 0.7, 0)
    reserveAmmoText.Position = UDim2.new(0.65, 5, 0, 5)
    reserveAmmoText.BackgroundTransparency = 1
    reserveAmmoText.Text = "120"
    reserveAmmoText.TextColor3 = Color3.fromRGB(180, 180, 180)
    reserveAmmoText.TextScaled = true
    reserveAmmoText.Font = Enum.Font.Gotham
    reserveAmmoText.TextXAlignment = Enum.TextXAlignment.Left
    reserveAmmoText.Parent = frame

    -- Fire mode indicator
    local fireModeText = Instance.new("TextLabel")
    fireModeText.Name = "FireMode"
    fireModeText.Size = UDim2.new(1, -20, 0, 20)
    fireModeText.Position = UDim2.new(0, 10, 1, -25)
    fireModeText.BackgroundTransparency = 1
    fireModeText.Text = "AUTO"
    fireModeText.TextColor3 = UI_CONFIG.COLORS.ACCENT
    fireModeText.TextScaled = true
    fireModeText.Font = Enum.Font.GothamBold
    fireModeText.TextXAlignment = Enum.TextXAlignment.Right
    fireModeText.Parent = frame

    return {
        frame = frame,
        currentAmmo = currentAmmoText,
        reserveAmmo = reserveAmmoText,
        fireMode = fireModeText
    }
end

-- Create weapon display
function AdvancedUISystem:createWeaponDisplay()
    local frame = Instance.new("Frame")
    frame.Name = "WeaponFrame"
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(1, -320, 1, -200)
    frame.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = self.mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Weapon name
    local weaponName = Instance.new("TextLabel")
    weaponName.Name = "WeaponName"
    weaponName.Size = UDim2.new(1, -20, 0, 30)
    weaponName.Position = UDim2.new(0, 10, 0, 5)
    weaponName.BackgroundTransparency = 1
    weaponName.Text = "G36 ASSAULT RIFLE"
    weaponName.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    weaponName.TextScaled = true
    weaponName.Font = Enum.Font.GothamBold
    weaponName.TextXAlignment = Enum.TextXAlignment.Right
    weaponName.Parent = frame

    -- Attachment indicators
    local attachmentsFrame = Instance.new("Frame")
    attachmentsFrame.Name = "Attachments"
    attachmentsFrame.Size = UDim2.new(1, -20, 0, 20)
    attachmentsFrame.Position = UDim2.new(0, 10, 0, 35)
    attachmentsFrame.BackgroundTransparency = 1
    attachmentsFrame.Parent = frame

    local attachmentsLayout = Instance.new("UIListLayout")
    attachmentsLayout.FillDirection = Enum.FillDirection.Horizontal
    attachmentsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    attachmentsLayout.Padding = UDim.new(0, 5)
    attachmentsLayout.Parent = attachmentsFrame

    return {
        frame = frame,
        weaponName = weaponName,
        attachmentsFrame = attachmentsFrame
    }
end

-- Create minimap
function AdvancedUISystem:createMinimap()
    local frame = Instance.new("Frame")
    frame.Name = "MinimapFrame"
    frame.Size = UDim2.new(0, 200, 0, 200)
    frame.Position = UDim2.new(1, -220, 0, 20)
    frame.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = self.mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Minimap content (simplified)
    local minimapLabel = Instance.new("TextLabel")
    minimapLabel.Size = UDim2.new(1, 0, 1, 0)
    minimapLabel.BackgroundTransparency = 1
    minimapLabel.Text = "MINIMAP"
    minimapLabel.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    minimapLabel.TextScaled = true
    minimapLabel.Font = Enum.Font.Gotham
    minimapLabel.Parent = frame

    return {
        frame = frame,
        content = minimapLabel
    }
end

-- Create score display
function AdvancedUISystem:createScoreDisplay()
    local frame = Instance.new("Frame")
    frame.Name = "ScoreFrame"
    frame.Size = UDim2.new(0, 150, 0, 60)
    frame.Position = UDim2.new(0.5, -75, 0, 20)
    frame.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = self.mainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Score text
    local scoreText = Instance.new("TextLabel")
    scoreText.Name = "ScoreText"
    scoreText.Size = UDim2.new(1, -20, 1, -20)
    scoreText.Position = UDim2.new(0, 10, 0, 10)
    scoreText.BackgroundTransparency = 1
    scoreText.Text = "15 / 3"
    scoreText.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    scoreText.TextScaled = true
    scoreText.Font = Enum.Font.GothamBold
    scoreText.Parent = frame

    return {
        frame = frame,
        scoreText = scoreText
    }
end

-- Create kill feed system
function AdvancedUISystem:createKillFeed()
    local frame = Instance.new("ScrollingFrame")
    frame.Name = "KillFeedFrame"
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(1, -420, 0, 250)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 0
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.Parent = self.mainGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 5)
    layout.Parent = frame

    self.killFeed = {
        frame = frame,
        layout = layout
    }
end

-- Create hit marker system
function AdvancedUISystem:createHitMarkerSystem()
    -- Hit markers are created dynamically
    self.hitMarkers = {}
end

-- Create damage indicator system
function AdvancedUISystem:createDamageIndicatorSystem()
    -- Create damage direction indicators around screen edges
    local directions = {"Top", "Bottom", "Left", "Right"}
    self.damageIndicators = {}

    for _, direction in ipairs(directions) do
        local indicator = Instance.new("Frame")
        indicator.Name = direction .. "DamageIndicator"
        indicator.BackgroundColor3 = UI_CONFIG.COLORS.DANGER
        indicator.BackgroundTransparency = 1
        indicator.BorderSizePixel = 0
        indicator.Parent = self.mainGui

        if direction == "Top" then
            indicator.Size = UDim2.new(1, 0, 0, 50)
            indicator.Position = UDim2.new(0, 0, 0, 0)
        elseif direction == "Bottom" then
            indicator.Size = UDim2.new(1, 0, 0, 50)
            indicator.Position = UDim2.new(0, 0, 1, -50)
        elseif direction == "Left" then
            indicator.Size = UDim2.new(0, 50, 1, 0)
            indicator.Position = UDim2.new(0, 0, 0, 0)
        elseif direction == "Right" then
            indicator.Size = UDim2.new(0, 50, 1, 0)
            indicator.Position = UDim2.new(1, -50, 0, 0)
        end

        self.damageIndicators[direction:lower()] = indicator
    end
end

-- Update crosshair spread
function AdvancedUISystem:updateCrosshairSpread(spread)
    if not self.crosshair then return end

    self.crosshair.targetSpread = spread

    -- Animate crosshair spread
    local elements = self.crosshair.elements
    TweenService:Create(elements.top, TweenInfo.new(0.1), {
        Position = UDim2.new(0.5, -1, 0, -20 - spread)
    }):Play()

    TweenService:Create(elements.bottom, TweenInfo.new(0.1), {
        Position = UDim2.new(0.5, -1, 1, 5 + spread)
    }):Play()

    TweenService:Create(elements.left, TweenInfo.new(0.1), {
        Position = UDim2.new(0, -20 - spread, 0.5, -1)
    }):Play()

    TweenService:Create(elements.right, TweenInfo.new(0.1), {
        Position = UDim2.new(1, 5 + spread, 0.5, -1)
    }):Play()
end

-- Show hit marker
function AdvancedUISystem:showHitMarker(hitType)
    local hitMarker = Instance.new("Frame")
    hitMarker.Name = "HitMarker"
    hitMarker.Size = UDim2.new(0, UI_CONFIG.HIT_MARKERS.SIZE, 0, UI_CONFIG.HIT_MARKERS.SIZE)
    hitMarker.Position = UDim2.new(0.5, -UI_CONFIG.HIT_MARKERS.SIZE/2, 0.5, -UI_CONFIG.HIT_MARKERS.SIZE/2)
    hitMarker.BackgroundTransparency = 1
    hitMarker.Parent = self.mainGui

    -- Create hit marker lines
    local color = UI_CONFIG.HIT_MARKERS.BODY_COLOR
    if hitType == "headshot" then
        color = UI_CONFIG.HIT_MARKERS.HEADSHOT_COLOR
    elseif hitType == "armor" then
        color = UI_CONFIG.HIT_MARKERS.ARMOR_COLOR
    end

    -- Top-left line
    local line1 = Instance.new("Frame")
    line1.Size = UDim2.new(0, 8, 0, UI_CONFIG.HIT_MARKERS.THICKNESS)
    line1.Position = UDim2.new(0, 2, 0, 2)
    line1.BackgroundColor3 = color
    line1.BorderSizePixel = 0
    line1.Rotation = 45
    line1.Parent = hitMarker

    -- Top-right line
    local line2 = Instance.new("Frame")
    line2.Size = UDim2.new(0, 8, 0, UI_CONFIG.HIT_MARKERS.THICKNESS)
    line2.Position = UDim2.new(1, -10, 0, 2)
    line2.BackgroundColor3 = color
    line2.BorderSizePixel = 0
    line2.Rotation = -45
    line2.Parent = hitMarker

    -- Bottom-left line
    local line3 = Instance.new("Frame")
    line3.Size = UDim2.new(0, 8, 0, UI_CONFIG.HIT_MARKERS.THICKNESS)
    line3.Position = UDim2.new(0, 2, 1, -5)
    line3.BackgroundColor3 = color
    line3.BorderSizePixel = 0
    line3.Rotation = -45
    line3.Parent = hitMarker

    -- Bottom-right line
    local line4 = Instance.new("Frame")
    line4.Size = UDim2.new(0, 8, 0, UI_CONFIG.HIT_MARKERS.THICKNESS)
    line4.Position = UDim2.new(1, -10, 1, -5)
    line4.BackgroundColor3 = color
    line4.BorderSizePixel = 0
    line4.Rotation = 45
    line4.Parent = hitMarker

    -- Animate hit marker
    TweenService:Create(hitMarker, TweenInfo.new(UI_CONFIG.HIT_MARKERS.DURATION), {
        Size = UDim2.new(0, UI_CONFIG.HIT_MARKERS.SIZE * 1.5, 0, UI_CONFIG.HIT_MARKERS.SIZE * 1.5),
        Position = UDim2.new(0.5, -UI_CONFIG.HIT_MARKERS.SIZE * 0.75, 0.5, -UI_CONFIG.HIT_MARKERS.SIZE * 0.75)
    }):Play()

    TweenService:Create(hitMarker, TweenInfo.new(UI_CONFIG.HIT_MARKERS.DURATION), {
        BackgroundTransparency = 1
    }):Play()

    -- Clean up
    game:GetService("Debris"):AddItem(hitMarker, UI_CONFIG.HIT_MARKERS.DURATION + 0.1)
end

-- Add kill feed entry
function AdvancedUISystem:addKillFeedEntry(killerName, victimName, weapon, isHeadshot)
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = "KillFeedEntry"
    entryFrame.Size = UDim2.new(0, 380, 0, 30)
    entryFrame.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    entryFrame.BackgroundTransparency = 0.2
    entryFrame.BorderSizePixel = 0
    entryFrame.Parent = self.killFeed.frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = entryFrame

    -- Killer name
    local killerLabel = Instance.new("TextLabel")
    killerLabel.Size = UDim2.new(0, 120, 1, 0)
    killerLabel.Position = UDim2.new(0, 5, 0, 0)
    killerLabel.BackgroundTransparency = 1
    killerLabel.Text = killerName
    killerLabel.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    killerLabel.TextScaled = true
    killerLabel.Font = Enum.Font.Gotham
    killerLabel.TextXAlignment = Enum.TextXAlignment.Right
    killerLabel.Parent = entryFrame

    -- Weapon icon/text
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Size = UDim2.new(0, 80, 1, 0)
    weaponLabel.Position = UDim2.new(0, 130, 0, 0)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Text = weapon
    weaponLabel.TextColor3 = isHeadshot and UI_CONFIG.COLORS.DANGER or UI_CONFIG.COLORS.ACCENT
    weaponLabel.TextScaled = true
    weaponLabel.Font = Enum.Font.GothamBold
    weaponLabel.Parent = entryFrame

    -- Victim name
    local victimLabel = Instance.new("TextLabel")
    victimLabel.Size = UDim2.new(0, 120, 1, 0)
    victimLabel.Position = UDim2.new(0, 215, 0, 0)
    victimLabel.BackgroundTransparency = 1
    victimLabel.Text = victimName
    victimLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    victimLabel.TextScaled = true
    victimLabel.Font = Enum.Font.Gotham
    victimLabel.TextXAlignment = Enum.TextXAlignment.Left
    victimLabel.Parent = entryFrame

    -- Add to entries list
    table.insert(self.killFeedEntries, {
        frame = entryFrame,
        timestamp = tick()
    })

    -- Remove old entries
    while #self.killFeedEntries > UI_CONFIG.KILL_FEED.MAX_ENTRIES do
        local oldEntry = table.remove(self.killFeedEntries, 1)
        oldEntry.frame:Destroy()
    end

    -- Update canvas size
    self.killFeed.frame.CanvasSize = UDim2.new(0, 0, 0, #self.killFeedEntries * 35)
end

-- Show damage indicator from direction
function AdvancedUISystem:showDamageIndicator(damageDirection)
    -- Determine which edge indicator to use
    local cameraDirection = self.camera.CFrame.LookVector
    local indicatorDirection = "top" -- Default

    -- Simple direction calculation (can be improved)
    if damageDirection.X > 0.5 then
        indicatorDirection = "right"
    elseif damageDirection.X < -0.5 then
        indicatorDirection = "left"
    elseif damageDirection.Z > 0 then
        indicatorDirection = "bottom"
    else
        indicatorDirection = "top"
    end

    local indicator = self.damageIndicators[indicatorDirection]
    if indicator then
        -- Flash the indicator
        indicator.BackgroundTransparency = 0.3
        TweenService:Create(indicator, TweenInfo.new(0.5), {
            BackgroundTransparency = 1
        }):Play()
    end
end

-- Update ammo display
function AdvancedUISystem:updateAmmo(current, reserve)
    if not self.hud or not self.hud.ammo then return end

    self.currentAmmo.current = current
    self.currentAmmo.reserve = reserve

    self.hud.ammo.currentAmmo.Text = tostring(current)
    self.hud.ammo.reserveAmmo.Text = tostring(reserve)

    -- Color coding for low ammo
    if current <= 5 then
        self.hud.ammo.currentAmmo.TextColor3 = UI_CONFIG.COLORS.DANGER
    elseif current <= 10 then
        self.hud.ammo.currentAmmo.TextColor3 = UI_CONFIG.COLORS.WARNING
    else
        self.hud.ammo.currentAmmo.TextColor3 = UI_CONFIG.COLORS.SECONDARY
    end
end

-- Update health display
function AdvancedUISystem:updateHealth(health, armor)
    if not self.hud or not self.hud.health then return end

    self.currentHealth = health
    self.currentArmor = armor or 0

    -- Update health bar
    local healthPercent = health / 100
    self.hud.health.healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    self.hud.health.healthText.Text = math.floor(health) .. " HP"

    -- Update armor bar
    local armorPercent = self.currentArmor / 100
    self.hud.health.armorBar.Size = UDim2.new(armorPercent, 0, 1, 0)

    -- Health color coding
    if health > 70 then
        self.hud.health.healthBar.BackgroundColor3 = UI_CONFIG.COLORS.SUCCESS
    elseif health > 30 then
        self.hud.health.healthBar.BackgroundColor3 = UI_CONFIG.COLORS.WARNING
    else
        self.hud.health.healthBar.BackgroundColor3 = UI_CONFIG.COLORS.DANGER
    end
end

-- Update weapon display
function AdvancedUISystem:updateWeapon(weaponName, attachments)
    if not self.hud or not self.hud.weapon then return end

    self.currentWeapon = weaponName
    self.hud.weapon.weaponName.Text = weaponName:upper()

    -- Clear existing attachment indicators
    for _, child in pairs(self.hud.weapon.attachmentsFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    -- Add attachment indicators
    if attachments then
        for _, attachment in pairs(attachments) do
            local attachmentLabel = Instance.new("TextLabel")
            attachmentLabel.Size = UDim2.new(0, 60, 1, 0)
            attachmentLabel.BackgroundTransparency = 1
            attachmentLabel.Text = attachment
            attachmentLabel.TextColor3 = UI_CONFIG.COLORS.ACCENT
            attachmentLabel.TextScaled = true
            attachmentLabel.Font = Enum.Font.Gotham
            attachmentLabel.Parent = self.hud.weapon.attachmentsFrame
        end
    end
end

-- Start update loops
function AdvancedUISystem:startUpdateLoops()
    -- Kill feed cleanup loop
    spawn(function()
        while self.isInitialized do
            local currentTime = tick()

            -- Remove expired kill feed entries
            for i = #self.killFeedEntries, 1, -1 do
                local entry = self.killFeedEntries[i]
                if currentTime - entry.timestamp > UI_CONFIG.KILL_FEED.ENTRY_LIFETIME then
                    entry.frame:Destroy()
                    table.remove(self.killFeedEntries, i)
                end
            end

            wait(UI_CONFIG.KILL_FEED.UPDATE_RATE)
        end
    end)
end

-- Cleanup
function AdvancedUISystem:cleanup()
    self.isInitialized = false

    if self.mainGui then
        self.mainGui:Destroy()
    end

    -- Restore default UI
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
end

return AdvancedUISystem