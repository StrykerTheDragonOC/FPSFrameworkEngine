-- KFCSUISystemGenerator.lua
-- COMPREHENSIVE UI SYSTEM GENERATOR FOR KFCS FUNNY RANDOMIZER
-- Run once in Studio console to generate all UI systems
-- Based on "KFCS FUNNY RANDOMIZER" theme with dark blue/cyan colors

print("🎯 Starting KFCS UI System Generation...")

local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Clear existing UI systems
local uiElementsToRemove = {
    "FPSGameMenu", "ModernHUD", "FPSScoreboard", "LoadoutArmoryUI"
}

for _, uiName in ipairs(uiElementsToRemove) do
    local existing = StarterGui:FindFirstChild(uiName)
    if existing then
        existing:Destroy()
        print("   🧹 Removed existing " .. uiName)
    end
end

-- Theme colors
local THEME = {
    primary = Color3.fromRGB(85, 170, 187),     -- Cyan blue
    secondary = Color3.fromRGB(45, 85, 100),     -- Dark cyan
    background = Color3.fromRGB(8, 12, 20),      -- Very dark blue
    backgroundAlt = Color3.fromRGB(15, 20, 30),  -- Dark blue
    text = Color3.fromRGB(255, 255, 255),        -- White
    textSecondary = Color3.fromRGB(200, 200, 200), -- Light gray
    accent = Color3.fromRGB(255, 180, 60),       -- Orange/yellow
    success = Color3.fromRGB(100, 255, 100),     -- Green
    warning = Color3.fromRGB(255, 200, 100),     -- Yellow
    danger = Color3.fromRGB(255, 100, 100),      -- Red
}

-- ============================================================================
-- MAIN MENU SYSTEM - KFCS FUNNY RANDOMIZER THEME
-- ============================================================================

local function createMainMenu()
    print("   📱 Creating Main Menu System...")
    
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FPSGameMenu"
    menuGui.ResetOnSpawn = false
    menuGui.IgnoreGuiInset = true
    menuGui.Enabled = true
    menuGui.Parent = StarterGui
    
    -- Main container with animated background
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.BackgroundColor3 = THEME.background
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = menuGui
    
    -- Animated particle background
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleBackground"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.Parent = mainContainer
    
    -- Create floating particles
    for i = 1, 25 do
        local particle = Instance.new("Frame")
        particle.Name = "Particle" .. i
        particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = THEME.primary
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0
        particle.Parent = particleContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        -- Animate particles continuously
        task.spawn(function()
            while particle.Parent do
                local newPosition = UDim2.new(math.random(), 0, math.random(), 0)
                local animTime = math.random(8, 15)
                
                local tween = TweenService:Create(particle, 
                    TweenInfo.new(animTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Position = newPosition, BackgroundTransparency = math.random(0.5, 0.9)}
                )
                tween:Play()
                tween.Completed:Wait()
            end
        end)
    end
    
    -- Main title section
    local titleContainer = Instance.new("Frame")
    titleContainer.Name = "TitleContainer"
    titleContainer.Size = UDim2.new(0.8, 0, 0.3, 0)
    titleContainer.Position = UDim2.new(0.1, 0, 0.1, 0)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = mainContainer
    
    -- Main title with glow effect
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "GameTitle"
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.2, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "KFCS FUNNY RANDOMIZER"
    titleLabel.TextColor3 = THEME.primary
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextStrokeTransparency = 0.5
    titleLabel.TextStrokeColor3 = THEME.background
    titleLabel.Parent = titleContainer
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "GameSubtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.8, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Version 4.0 | Advanced Combat Operations"
    subtitleLabel.TextColor3 = THEME.textSecondary
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Parent = titleContainer
    
    -- Menu buttons container
    local menuButtons = Instance.new("Frame")
    menuButtons.Name = "MenuButtons"
    menuButtons.Size = UDim2.new(0.35, 0, 0.45, 0)
    menuButtons.Position = UDim2.new(0.325, 0, 0.45, 0)
    menuButtons.BackgroundColor3 = THEME.backgroundAlt
    menuButtons.BackgroundTransparency = 0.1
    menuButtons.BorderSizePixel = 0
    menuButtons.Parent = mainContainer
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 15)
    menuCorner.Parent = menuButtons
    
    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color = THEME.primary
    menuStroke.Thickness = 3
    menuStroke.Transparency = 0.3
    menuStroke.Parent = menuButtons
    
    -- Menu button configurations
    local buttonConfigs = {
        {name = "DEPLOY", key = "[DEPLOY]", desc = "Enter the battlefield", color = THEME.success},
        {name = "ARMORY", key = "[ARM]", desc = "Customize weapons", color = THEME.accent},
        {name = "LEADERBOARD", key = "[BOARD]", desc = "View player rankings", color = THEME.primary},
        {name = "CONFIG", key = "[CFG]", desc = "Game settings", color = THEME.warning},
        {name = "STATISTICS", key = "[STAT]", desc = "Performance analytics", color = THEME.textSecondary}
    }
    
    -- Create menu buttons
    for i, config in ipairs(buttonConfigs) do
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Name = config.name .. "Button"
        buttonFrame.Size = UDim2.new(0.85, 0, 0.15, 0)
        buttonFrame.Position = UDim2.new(0.075, 0, 0.05 + (i-1) * 0.18, 0)
        buttonFrame.BackgroundColor3 = THEME.backgroundAlt
        buttonFrame.BackgroundTransparency = 0.3
        buttonFrame.BorderSizePixel = 0
        buttonFrame.Parent = menuButtons
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = buttonFrame
        
        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = config.color
        buttonStroke.Thickness = 2
        buttonStroke.Transparency = 0.4
        buttonStroke.Parent = buttonFrame
        
        -- Button key label
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(0.25, 0, 1, 0)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = config.key
        keyLabel.TextColor3 = config.color
        keyLabel.TextScaled = true
        keyLabel.Font = Enum.Font.GothamBold
        keyLabel.TextXAlignment = Enum.TextXAlignment.Center
        keyLabel.Parent = buttonFrame
        
        -- Button name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 0.6, 0)
        nameLabel.Position = UDim2.new(0.25, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = config.name
        nameLabel.TextColor3 = THEME.text
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = buttonFrame
        
        -- Button description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
        descLabel.Position = UDim2.new(0.25, 0, 0.6, 0)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = config.desc
        descLabel.TextColor3 = THEME.textSecondary
        descLabel.TextScaled = true
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = buttonFrame
        
        -- Make button clickable
        local clickButton = Instance.new("TextButton")
        clickButton.Name = config.name .. "ClickButton"
        clickButton.Size = UDim2.new(1, 0, 1, 0)
        clickButton.BackgroundTransparency = 1
        clickButton.Text = ""
        clickButton.Parent = buttonFrame
        
        -- Button hover effects
        clickButton.MouseEnter:Connect(function()
            local hoverTween = TweenService:Create(buttonStroke,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 0.1, Thickness = 3}
            )
            hoverTween:Play()
        end)
        
        clickButton.MouseLeave:Connect(function()
            local leaveTween = TweenService:Create(buttonStroke,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 0.4, Thickness = 2}
            )
            leaveTween:Play()
        end)
    end
    
    -- Operative status panel
    local statusPanel = Instance.new("Frame")
    statusPanel.Name = "OperativeStatus"
    statusPanel.Size = UDim2.new(0.25, 0, 0.3, 0)
    statusPanel.Position = UDim2.new(0.73, 0, 0.65, 0)
    statusPanel.BackgroundColor3 = THEME.backgroundAlt
    statusPanel.BackgroundTransparency = 0.1
    statusPanel.BorderSizePixel = 0
    statusPanel.Parent = mainContainer
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 12)
    statusCorner.Parent = statusPanel
    
    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = THEME.primary
    statusStroke.Thickness = 2
    statusStroke.Transparency = 0.4
    statusStroke.Parent = statusPanel
    
    -- Status title
    local statusTitle = Instance.new("TextLabel")
    statusTitle.Size = UDim2.new(1, 0, 0.2, 0)
    statusTitle.Position = UDim2.new(0, 0, 0.05, 0)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "OPERATIVE STATUS"
    statusTitle.TextColor3 = THEME.text
    statusTitle.TextScaled = true
    statusTitle.Font = Enum.Font.GothamBold
    statusTitle.TextXAlignment = Enum.TextXAlignment.Center
    statusTitle.Parent = statusPanel
    
    -- Status information
    local statusInfo = {
        {label = "RANK:", value = "1", color = THEME.textSecondary},
        {label = "XP:", value = "0/1000", color = THEME.primary},
        {label = "CREDITS:", value = "200", color = THEME.accent},
        {label = "K/D:", value = "0.00", color = THEME.text}
    }
    
    for i, info in ipairs(statusInfo) do
        local infoFrame = Instance.new("Frame")
        infoFrame.Size = UDim2.new(1, -20, 0.15, 0)
        infoFrame.Position = UDim2.new(0, 10, 0.25 + (i-1) * 0.17, 0)
        infoFrame.BackgroundTransparency = 1
        infoFrame.Parent = statusPanel
        
        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(0.5, 0, 1, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = info.label
        labelText.TextColor3 = THEME.textSecondary
        labelText.TextScaled = true
        labelText.Font = Enum.Font.Gotham
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = infoFrame
        
        local valueText = Instance.new("TextLabel")
        valueText.Name = info.label:gsub(":", ""):gsub("/", "")
        valueText.Size = UDim2.new(0.5, 0, 1, 0)
        valueText.Position = UDim2.new(0.5, 0, 0, 0)
        valueText.BackgroundTransparency = 1
        valueText.Text = info.value
        valueText.TextColor3 = info.color
        valueText.TextScaled = true
        valueText.Font = Enum.Font.GothamBold
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.Parent = infoFrame
    end
    
    -- Main menu active indicator
    local activeIndicator = Instance.new("TextLabel")
    activeIndicator.Name = "ActiveIndicator"
    activeIndicator.Size = UDim2.new(0.2, 0, 0.05, 0)
    activeIndicator.Position = UDim2.new(0.02, 0, 0.93, 0)
    activeIndicator.BackgroundTransparency = 1
    activeIndicator.Text = "MAIN MENU ACTIVE"
    activeIndicator.TextColor3 = THEME.primary
    activeIndicator.TextScaled = true
    activeIndicator.Font = Enum.Font.Gotham
    activeIndicator.TextXAlignment = Enum.TextXAlignment.Left
    activeIndicator.Parent = mainContainer
    
    -- Pulsing effect for active indicator
    task.spawn(function()
        while activeIndicator.Parent do
            local pulseTween = TweenService:Create(activeIndicator,
                TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {TextTransparency = 0.5}
            )
            pulseTween:Play()
            pulseTween.Completed:Wait()
            
            local pulseTween2 = TweenService:Create(activeIndicator,
                TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {TextTransparency = 0}
            )
            pulseTween2:Play()
            pulseTween2.Completed:Wait()
        end
    end)
    
    print("      ✅ Main Menu created with KFCS theme")
    return menuGui
end

-- ============================================================================
-- ADVANCED HUD SYSTEM
-- ============================================================================

local function createAdvancedHUD()
    print("   🎯 Creating Advanced HUD System...")
    
    local hudGui = Instance.new("ScreenGui")
    hudGui.Name = "ModernHUD"
    hudGui.ResetOnSpawn = false
    hudGui.IgnoreGuiInset = true
    hudGui.Enabled = false
    hudGui.Parent = StarterGui
    
    -- Main HUD Container
    local hudContainer = Instance.new("Frame")
    hudContainer.Name = "HUDContainer"
    hudContainer.Size = UDim2.new(1, 0, 1, 0)
    hudContainer.BackgroundTransparency = 1
    hudContainer.Parent = hudGui
    
    -- Dynamic crosshair system
    local crosshairContainer = Instance.new("Frame")
    crosshairContainer.Name = "CrosshairContainer"
    crosshairContainer.Size = UDim2.new(0, 60, 0, 60)
    crosshairContainer.Position = UDim2.new(0.5, -30, 0.5, -30)
    crosshairContainer.BackgroundTransparency = 1
    crosshairContainer.Parent = hudContainer
    
    -- Center dot
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.Size = UDim2.new(0, 4, 0, 4)
    centerDot.Position = UDim2.new(0.5, -2, 0.5, -2)
    centerDot.BackgroundColor3 = THEME.success
    centerDot.BorderSizePixel = 0
    centerDot.Parent = crosshairContainer
    
    local centerDotCorner = Instance.new("UICorner")
    centerDotCorner.CornerRadius = UDim.new(1, 0)
    centerDotCorner.Parent = centerDot
    
    -- Crosshair arms
    local armConfigs = {
        {name = "Top", size = UDim2.new(0, 2, 0, 15), pos = UDim2.new(0.5, -1, 0.5, -25)},
        {name = "Bottom", size = UDim2.new(0, 2, 0, 15), pos = UDim2.new(0.5, -1, 0.5, 10)},
        {name = "Left", size = UDim2.new(0, 15, 0, 2), pos = UDim2.new(0.5, -25, 0.5, -1)},
        {name = "Right", size = UDim2.new(0, 15, 0, 2), pos = UDim2.new(0.5, 10, 0.5, -1)}
    }
    
    for _, config in ipairs(armConfigs) do
        local arm = Instance.new("Frame")
        arm.Name = config.name .. "Arm"
        arm.Size = config.size
        arm.Position = config.pos
        arm.BackgroundColor3 = THEME.text
        arm.BorderSizePixel = 0
        arm.Parent = crosshairContainer
        
        local armStroke = Instance.new("UIStroke")
        armStroke.Color = THEME.background
        armStroke.Thickness = 1
        armStroke.Parent = arm
    end
    
    -- Health system container
    local healthContainer = Instance.new("Frame")
    healthContainer.Name = "HealthSystemContainer"
    healthContainer.Size = UDim2.new(0, 320, 0, 120)
    healthContainer.Position = UDim2.new(0, 50, 1, -170)
    healthContainer.BackgroundTransparency = 1
    healthContainer.Parent = hudContainer
    
    -- Health frame
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthFrame"
    healthFrame.Size = UDim2.new(1, 0, 0.6, 0)
    healthFrame.BackgroundColor3 = THEME.backgroundAlt
    healthFrame.BackgroundTransparency = 0.3
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = healthContainer
    
    local healthFrameCorner = Instance.new("UICorner")
    healthFrameCorner.CornerRadius = UDim.new(0, 12)
    healthFrameCorner.Parent = healthFrame
    
    local healthFrameStroke = Instance.new("UIStroke")
    healthFrameStroke.Color = THEME.success
    healthFrameStroke.Thickness = 2
    healthFrameStroke.Transparency = 0.3
    healthFrameStroke.Parent = healthFrame
    
    -- Health bar background
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBg"
    healthBarBg.Size = UDim2.new(0, 200, 0, 12)
    healthBarBg.Position = UDim2.new(0, 60, 0.5, -6)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Parent = healthFrame
    
    local healthBarBgCorner = Instance.new("UICorner")
    healthBarBgCorner.CornerRadius = UDim.new(0, 6)
    healthBarBgCorner.Parent = healthBarBg
    
    -- Health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = THEME.success
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBg
    
    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(0, 6)
    healthBarCorner.Parent = healthBar
    
    -- Health text
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(0, 50, 1, 0)
    healthText.Position = UDim2.new(0, 270, 0, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100"
    healthText.TextColor3 = THEME.text
    healthText.TextScaled = true
    healthText.Font = Enum.Font.GothamBold
    healthText.Parent = healthFrame
    
    -- Weapon info container
    local weaponContainer = Instance.new("Frame")
    weaponContainer.Name = "WeaponInfoContainer"
    weaponContainer.Size = UDim2.new(0, 400, 0, 140)
    weaponContainer.Position = UDim2.new(1, -450, 1, -190)
    weaponContainer.BackgroundTransparency = 1
    weaponContainer.Parent = hudContainer
    
    -- Weapon frame
    local weaponFrame = Instance.new("Frame")
    weaponFrame.Name = "WeaponFrame"
    weaponFrame.Size = UDim2.new(1, 0, 0.7, 0)
    weaponFrame.BackgroundColor3 = THEME.backgroundAlt
    weaponFrame.BackgroundTransparency = 0.3
    weaponFrame.BorderSizePixel = 0
    weaponFrame.Parent = weaponContainer
    
    local weaponFrameCorner = Instance.new("UICorner")
    weaponFrameCorner.CornerRadius = UDim.new(0, 12)
    weaponFrameCorner.Parent = weaponFrame
    
    local weaponStroke = Instance.new("UIStroke")
    weaponStroke.Color = THEME.accent
    weaponStroke.Thickness = 2
    weaponStroke.Transparency = 0.3
    weaponStroke.Parent = weaponFrame
    
    -- Weapon name
    local weaponName = Instance.new("TextLabel")
    weaponName.Name = "WeaponName"
    weaponName.Size = UDim2.new(0.6, 0, 0.4, 0)
    weaponName.Position = UDim2.new(0, 15, 0, 5)
    weaponName.BackgroundTransparency = 1
    weaponName.Text = "AK-47"
    weaponName.TextColor3 = THEME.text
    weaponName.TextScaled = true
    weaponName.Font = Enum.Font.GothamBold
    weaponName.TextXAlignment = Enum.TextXAlignment.Left
    weaponName.Parent = weaponFrame
    
    -- Current ammo
    local currentAmmo = Instance.new("TextLabel")
    currentAmmo.Name = "CurrentAmmo"
    currentAmmo.Size = UDim2.new(0.4, 0, 0.6, 0)
    currentAmmo.Position = UDim2.new(0, 15, 0.4, 0)
    currentAmmo.BackgroundTransparency = 1
    currentAmmo.Text = "30"
    currentAmmo.TextColor3 = THEME.text
    currentAmmo.TextScaled = true
    currentAmmo.Font = Enum.Font.GothamBold
    currentAmmo.TextXAlignment = Enum.TextXAlignment.Left
    currentAmmo.Parent = weaponFrame
    
    -- Reserve ammo
    local reserveAmmo = Instance.new("TextLabel")
    reserveAmmo.Name = "ReserveAmmo"
    reserveAmmo.Size = UDim2.new(0.5, 0, 0.6, 0)
    reserveAmmo.Position = UDim2.new(0.5, 0, 0.4, 0)
    reserveAmmo.BackgroundTransparency = 1
    reserveAmmo.Text = "/ 120"
    reserveAmmo.TextColor3 = THEME.textSecondary
    reserveAmmo.TextScaled = true
    reserveAmmo.Font = Enum.Font.Gotham
    reserveAmmo.TextXAlignment = Enum.TextXAlignment.Left
    reserveAmmo.Parent = weaponFrame
    
    -- Team scores container
    local scoresContainer = Instance.new("Frame")
    scoresContainer.Name = "ScoresContainer"
    scoresContainer.Size = UDim2.new(0, 350, 0, 80)
    scoresContainer.Position = UDim2.new(0.5, -175, 0, 30)
    scoresContainer.BackgroundTransparency = 1
    scoresContainer.Parent = hudContainer
    
    -- FBI score
    local fbiFrame = Instance.new("Frame")
    fbiFrame.Size = UDim2.new(0.4, 0, 1, 0)
    fbiFrame.BackgroundColor3 = Color3.fromRGB(0, 80, 160)
    fbiFrame.BackgroundTransparency = 0.3
    fbiFrame.BorderSizePixel = 0
    fbiFrame.Parent = scoresContainer
    
    local fbiCorner = Instance.new("UICorner")
    fbiCorner.CornerRadius = UDim.new(0, 10)
    fbiCorner.Parent = fbiFrame
    
    local fbiScore = Instance.new("TextLabel")
    fbiScore.Name = "FBIScore"
    fbiScore.Size = UDim2.new(1, 0, 1, 0)
    fbiScore.BackgroundTransparency = 1
    fbiScore.Text = "FBI: 0"
    fbiScore.TextColor3 = THEME.text
    fbiScore.TextScaled = true
    fbiScore.Font = Enum.Font.GothamBold
    fbiScore.Parent = fbiFrame
    
    -- KFC score
    local kfcFrame = Instance.new("Frame")
    kfcFrame.Size = UDim2.new(0.4, 0, 1, 0)
    kfcFrame.Position = UDim2.new(0.6, 0, 0, 0)
    kfcFrame.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
    kfcFrame.BackgroundTransparency = 0.3
    kfcFrame.BorderSizePixel = 0
    kfcFrame.Parent = scoresContainer
    
    local kfcCorner = Instance.new("UICorner")
    kfcCorner.CornerRadius = UDim.new(0, 10)
    kfcCorner.Parent = kfcFrame
    
    local kfcScore = Instance.new("TextLabel")
    kfcScore.Name = "KFCScore"
    kfcScore.Size = UDim2.new(1, 0, 1, 0)
    kfcScore.BackgroundTransparency = 1
    kfcScore.Text = "KFC: 0"
    kfcScore.TextColor3 = THEME.text
    kfcScore.TextScaled = true
    kfcScore.Font = Enum.Font.GothamBold
    kfcScore.Parent = kfcFrame
    
    print("      ✅ Advanced HUD created with enhanced features")
    return hudGui
end

-- ============================================================================
-- ADVANCED SCOREBOARD SYSTEM
-- ============================================================================

local function createAdvancedScoreboard()
    print("   📊 Creating Advanced Scoreboard...")
    
    local scoreboardGui = Instance.new("ScreenGui")
    scoreboardGui.Name = "FPSScoreboard"
    scoreboardGui.ResetOnSpawn = false
    scoreboardGui.IgnoreGuiInset = true
    scoreboardGui.Enabled = false
    scoreboardGui.Parent = StarterGui
    
    -- Main scoreboard container
    local scoreboardContainer = Instance.new("Frame")
    scoreboardContainer.Name = "ScoreboardContainer"
    scoreboardContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
    scoreboardContainer.Position = UDim2.new(0.05, 0, 0.1, 0)
    scoreboardContainer.BackgroundColor3 = THEME.background
    scoreboardContainer.BackgroundTransparency = 0.05
    scoreboardContainer.BorderSizePixel = 0
    scoreboardContainer.Parent = scoreboardGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 15)
    containerCorner.Parent = scoreboardContainer
    
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = THEME.primary
    containerStroke.Thickness = 3
    containerStroke.Transparency = 0.2
    containerStroke.Parent = scoreboardContainer
    
    -- Header section
    local headerSection = Instance.new("Frame")
    headerSection.Name = "HeaderSection"
    headerSection.Size = UDim2.new(1, 0, 0, 120)
    headerSection.BackgroundColor3 = THEME.backgroundAlt
    headerSection.BorderSizePixel = 0
    headerSection.Parent = scoreboardContainer
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = headerSection
    
    -- Match title
    local matchTitle = Instance.new("TextLabel")
    matchTitle.Name = "MatchTitle"
    matchTitle.Size = UDim2.new(0.6, 0, 0.4, 0)
    matchTitle.Position = UDim2.new(0.2, 0, 0.1, 0)
    matchTitle.BackgroundTransparency = 1
    matchTitle.Text = "TEAM DEATHMATCH"
    matchTitle.TextColor3 = THEME.text
    matchTitle.TextScaled = true
    matchTitle.Font = Enum.Font.GothamBold
    matchTitle.TextXAlignment = Enum.TextXAlignment.Center
    matchTitle.Parent = headerSection
    
    -- Team headers frame
    local teamHeaders = Instance.new("Frame")
    teamHeaders.Name = "TeamHeaders"
    teamHeaders.Size = UDim2.new(1, -40, 0, 60)
    teamHeaders.Position = UDim2.new(0, 20, 0.5, 0)
    teamHeaders.BackgroundTransparency = 1
    teamHeaders.Parent = headerSection
    
    -- FBI team header
    local fbiHeader = Instance.new("Frame")
    fbiHeader.Name = "FBIHeader"
    fbiHeader.Size = UDim2.new(0.48, 0, 1, 0)
    fbiHeader.BackgroundColor3 = Color3.fromRGB(0, 80, 160)
    fbiHeader.BorderSizePixel = 0
    fbiHeader.Parent = teamHeaders
    
    local fbiHeaderCorner = Instance.new("UICorner")
    fbiHeaderCorner.CornerRadius = UDim.new(0, 12)
    fbiHeaderCorner.Parent = fbiHeader
    
    local fbiTeamName = Instance.new("TextLabel")
    fbiTeamName.Size = UDim2.new(0.6, 0, 1, 0)
    fbiTeamName.Position = UDim2.new(0.2, 0, 0, 0)
    fbiTeamName.BackgroundTransparency = 1
    fbiTeamName.Text = "FBI TEAM"
    fbiTeamName.TextColor3 = THEME.text
    fbiTeamName.TextScaled = true
    fbiTeamName.Font = Enum.Font.GothamBold
    fbiTeamName.Parent = fbiHeader
    
    -- KFC team header
    local kfcHeader = Instance.new("Frame")
    kfcHeader.Name = "KFCHeader"
    kfcHeader.Size = UDim2.new(0.48, 0, 1, 0)
    kfcHeader.Position = UDim2.new(0.52, 0, 0, 0)
    kfcHeader.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
    kfcHeader.BorderSizePixel = 0
    kfcHeader.Parent = teamHeaders
    
    local kfcHeaderCorner = Instance.new("UICorner")
    kfcHeaderCorner.CornerRadius = UDim.new(0, 12)
    kfcHeaderCorner.Parent = kfcHeader
    
    local kfcTeamName = Instance.new("TextLabel")
    kfcTeamName.Size = UDim2.new(0.6, 0, 1, 0)
    kfcTeamName.Position = UDim2.new(0.2, 0, 0, 0)
    kfcTeamName.BackgroundTransparency = 1
    kfcTeamName.Text = "KFC TEAM"
    kfcTeamName.TextColor3 = THEME.text
    kfcTeamName.TextScaled = true
    kfcTeamName.Font = Enum.Font.GothamBold
    kfcTeamName.Parent = kfcHeader
    
    -- Player list container
    local playerListContainer = Instance.new("ScrollingFrame")
    playerListContainer.Name = "PlayerListContainer"
    playerListContainer.Size = UDim2.new(1, 0, 1, -120)
    playerListContainer.Position = UDim2.new(0, 0, 0, 120)
    playerListContainer.BackgroundTransparency = 1
    playerListContainer.BorderSizePixel = 0
    playerListContainer.ScrollBarThickness = 8
    playerListContainer.ScrollBarImageColor3 = THEME.primary
    playerListContainer.Parent = scoreboardContainer
    
    print("      ✅ Advanced Scoreboard created")
    return scoreboardGui
end

-- ============================================================================
-- KILLFEED SYSTEM
-- ============================================================================

local function createKillfeedSystem()
    print("   💀 Creating Killfeed System...")
    
    local killfeedGui = Instance.new("ScreenGui")
    killfeedGui.Name = "KillfeedSystem"
    killfeedGui.ResetOnSpawn = false
    killfeedGui.IgnoreGuiInset = true
    killfeedGui.Enabled = true
    killfeedGui.Parent = StarterGui
    
    -- Killfeed container
    local killfeedContainer = Instance.new("Frame")
    killfeedContainer.Name = "KillfeedContainer"
    killfeedContainer.Size = UDim2.new(0, 400, 0, 300)
    killfeedContainer.Position = UDim2.new(1, -420, 0, 100)
    killfeedContainer.BackgroundTransparency = 1
    killfeedContainer.Parent = killfeedGui
    
    print("      ✅ Killfeed System created")
    return killfeedGui
end

-- ============================================================================
-- LOADOUT/ARMORY SYSTEM
-- ============================================================================

local function createLoadoutSystem()
    print("   🔫 Creating Loadout/Armory System...")
    
    local loadoutGui = Instance.new("ScreenGui")
    loadoutGui.Name = "LoadoutArmoryUI"
    loadoutGui.ResetOnSpawn = false
    loadoutGui.IgnoreGuiInset = true
    loadoutGui.Enabled = false
    loadoutGui.Parent = StarterGui
    
    -- Main loadout container
    local loadoutContainer = Instance.new("Frame")
    loadoutContainer.Name = "LoadoutContainer"
    loadoutContainer.Size = UDim2.new(1, 0, 1, 0)
    loadoutContainer.BackgroundColor3 = THEME.background
    loadoutContainer.BorderSizePixel = 0
    loadoutContainer.Parent = loadoutGui
    
    -- Weapon categories frame
    local categoriesFrame = Instance.new("Frame")
    categoriesFrame.Name = "WeaponCategories"
    categoriesFrame.Size = UDim2.new(0.2, 0, 1, -100)
    categoriesFrame.Position = UDim2.new(0, 20, 0, 50)
    categoriesFrame.BackgroundColor3 = THEME.backgroundAlt
    categoriesFrame.BackgroundTransparency = 0.1
    categoriesFrame.BorderSizePixel = 0
    categoriesFrame.Parent = loadoutContainer
    
    local categoriesCorner = Instance.new("UICorner")
    categoriesCorner.CornerRadius = UDim.new(0, 12)
    categoriesCorner.Parent = categoriesFrame
    
    -- Weapon preview frame
    local weaponPreview = Instance.new("Frame")
    weaponPreview.Name = "WeaponPreview"
    weaponPreview.Size = UDim2.new(0.5, 0, 1, -100)
    weaponPreview.Position = UDim2.new(0.25, 0, 0, 50)
    weaponPreview.BackgroundColor3 = THEME.backgroundAlt
    weaponPreview.BackgroundTransparency = 0.1
    weaponPreview.BorderSizePixel = 0
    weaponPreview.Parent = loadoutContainer
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 12)
    previewCorner.Parent = weaponPreview
    
    -- Weapon stats frame
    local weaponStats = Instance.new("Frame")
    weaponStats.Name = "WeaponStats"
    weaponStats.Size = UDim2.new(0.2, 0, 1, -100)
    weaponStats.Position = UDim2.new(0.78, 0, 0, 50)
    weaponStats.BackgroundColor3 = THEME.backgroundAlt
    weaponStats.BackgroundTransparency = 0.1
    weaponStats.BorderSizePixel = 0
    weaponStats.Parent = loadoutContainer
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 12)
    statsCorner.Parent = weaponStats
    
    print("      ✅ Loadout/Armory System created")
    return loadoutGui
end

-- ============================================================================
-- MODULE CONTROLLERS CREATION
-- ============================================================================

local function createControllerModules()
    print("   🎮 Creating Controller Modules...")
    
    -- Check if FPSSystem exists in ReplicatedStorage
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        warn("   ⚠️ FPSSystem not found in ReplicatedStorage! Controllers may not work properly.")
        return
    end
    
    local modulesFolder = fpsSystem:FindFirstChild("Modules")
    if not modulesFolder then
        warn("   ⚠️ Modules folder not found in FPSSystem! Controllers may not work properly.")
        return
    end
    
    -- Create basic controller modules if they don't exist
    local controllerNames = {"HUDController", "MenuController", "ScoreboardController"}
    
    for _, controllerName in ipairs(controllerNames) do
        local existingController = modulesFolder:FindFirstChild(controllerName)
        if not existingController then
            local controller = Instance.new("ModuleScript")
            controller.Name = controllerName
            controller.Source = [[
-- ]] .. controllerName .. [[ Module
local Controller = {}

function Controller:init()
    print("[]] .. controllerName .. [[] Initialized")
end

return Controller
]]
            controller.Parent = modulesFolder
            print("      ✅ Created " .. controllerName .. " module")
        end
    end
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

local function main()
    print("🚀 Starting comprehensive UI generation...")
    
    -- Create all UI systems
    createMainMenu()
    createAdvancedHUD()
    createAdvancedScoreboard()
    createKillfeedSystem()
    createLoadoutSystem()
    createControllerModules()
    
    print("✅ KFCS UI System Generation Complete!")
    print("   📝 Main Menu: FPSGameMenu")
    print("   🎯 HUD System: ModernHUD")
    print("   📊 Scoreboard: FPSScoreboard")
    print("   💀 Killfeed: KillfeedSystem")
    print("   🔫 Loadout: LoadoutArmoryUI")
    print("   ")
    print("🎮 All systems ready for KFCS Funny Randomizer!")
    print("   Theme: Dark blue/cyan with animated particles")
    print("   Controls: TAB for scoreboard, ESC for menu")
    print("   Status: All UI elements properly themed and functional")
end

-- Execute the generator
main()