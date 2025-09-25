-- MenuUIGenerator_ConsoleCommand.lua
-- Run this ONCE in Studio Console to generate all UI components for the FPS system
-- Optimized for 1920x1080 display with proper positioning

local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

print("🎨 FPS System UI Generator Starting...")
print("📺 Optimized for 1920x1080 display")

-- Clean up existing UI first
local function CleanupExistingUI()
    print("🧹 Cleaning up existing UI...")
    local existingUIs = {
        "FPSMainMenu",
        "FPSHUD",
        "DeployGUI",
        "InGameUI"
        -- Clean up any conflicting/old UI elements
    }

    for _, uiName in ipairs(existingUIs) do
        local existing = StarterGui:FindFirstChild(uiName)
        if existing then
            existing:Destroy()
            print("  - Removed existing " .. uiName)
        end
    end
end

-- Color scheme - Modern Turquoise/Blue
local Colors = {
    Primary = Color3.fromRGB(0, 206, 209), -- Turquoise
    Secondary = Color3.fromRGB(30, 144, 255), -- Deep Sky Blue
    Accent = Color3.fromRGB(0, 191, 255), -- Deep Sky Blue
    Background = Color3.fromRGB(10, 10, 15),
    Panel = Color3.fromRGB(25, 25, 30),
    Button = Color3.fromRGB(35, 35, 40),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(241, 196, 15),
    Error = Color3.fromRGB(231, 76, 60)
}

-- Function to create animated background particles
local function createBackgroundStars(parent)
    local starCount = 60
    local stars = {}

    for i = 1, starCount do
        local star = Instance.new("Frame")
        star.Name = "Star" .. i
        star.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
        star.Position = UDim2.new(
            math.random(0, 1000) / 1000,
            0,
            math.random(0, 1000) / 1000,
            0
        )
        star.BackgroundColor3 = Colors.Primary
        star.BorderSizePixel = 0
        star.BackgroundTransparency = math.random(20, 70) / 100
        star.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = star

        -- Animate star twinkling
        spawn(function()
            while star.Parent do
                local tweenInfo = TweenInfo.new(
                    math.random(30, 60) / 10,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut,
                    -1,
                    true
                )
                local tween = TweenService:Create(star, tweenInfo, {
                    BackgroundTransparency = math.random(80, 95) / 100
                })
                tween:Play()
                wait(math.random(3, 8))
                tween:Cancel()
                star.BackgroundTransparency = math.random(20, 70) / 100
            end
        end)

        table.insert(stars, star)
    end

    return stars
end

-- Create Main Menu UI
local function CreateMainMenuUI()
    print("📋 Creating Main Menu UI...")

    local mainMenuGui = Instance.new("ScreenGui")
    mainMenuGui.Name = "FPSMainMenu"
    mainMenuGui.ResetOnSpawn = false
    mainMenuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainMenuGui.IgnoreGuiInset = true
    mainMenuGui.Parent = StarterGui

    -- Main Container (fullscreen)
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.Position = UDim2.new(0, 0, 0, 0)
    mainContainer.BackgroundColor3 = Colors.Background
    mainContainer.BackgroundTransparency = 0
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = mainMenuGui

    -- Animated background gradient
    local backgroundGradient = Instance.new("UIGradient")
    backgroundGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 15, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 25, 45))
    })
    backgroundGradient.Rotation = 45
    backgroundGradient.Parent = mainContainer

    -- Animated background particles/stars
    local backgroundParticles = Instance.new("Frame")
    backgroundParticles.Name = "BackgroundParticles"
    backgroundParticles.Size = UDim2.new(1, 0, 1, 0)
    backgroundParticles.Position = UDim2.new(0, 0, 0, 0)
    backgroundParticles.BackgroundTransparency = 1
    backgroundParticles.ZIndex = 1
    backgroundParticles.Parent = mainContainer

    -- Create animated background stars
    createBackgroundStars(backgroundParticles)

    -- Background blur effect
    local blurFrame = Instance.new("Frame")
    blurFrame.Name = "BlurBackground"
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blurFrame.BackgroundTransparency = 0.5
    blurFrame.BorderSizePixel = 0
    blurFrame.Parent = mainContainer

    -- Game Title - Centered and properly positioned for 1920x1080
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0, 1100, 0, 100)
    titleLabel.Position = UDim2.new(0.5, -550, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "KFC'S: FUNNY RANDOMIZER 4.0"
    titleLabel.TextColor3 = Colors.Primary
    titleLabel.TextSize = 58
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextStrokeTransparency = 0.2
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextScaled = true
    titleLabel.Parent = mainContainer

    -- Remove subtitle as requested

    -- Menu Panel - Fixed sizing for 1920x1080
    local menuPanel = Instance.new("Frame")
    menuPanel.Name = "MenuPanel"
    menuPanel.Size = UDim2.new(0, 1400, 0, 750)
    menuPanel.Position = UDim2.new(0.5, -700, 0, 160)
    menuPanel.BackgroundColor3 = Colors.Panel
    menuPanel.BackgroundTransparency = 0.1
    menuPanel.BorderSizePixel = 0
    menuPanel.ClipsDescendants = true -- Prevent expansion beyond bounds
    menuPanel.Parent = mainContainer

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 15)
    menuCorner.Parent = menuPanel

    -- Top Bar with Player Info - Fixed positioning
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 70)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    topBar.BackgroundTransparency = 0.2
    topBar.BorderSizePixel = 0
    topBar.Parent = menuPanel

    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 15)
    topBarCorner.Parent = topBar

    -- Player Info Container - Right side
    local playerInfo = Instance.new("Frame")
    playerInfo.Name = "PlayerInfo"
    playerInfo.Size = UDim2.new(0, 400, 1, -10)
    playerInfo.Position = UDim2.new(1, -410, 0, 5)
    playerInfo.BackgroundTransparency = 1
    playerInfo.Parent = topBar

    -- Player Stats Display
    local playerName = Instance.new("TextLabel")
    playerName.Name = "PlayerName"
    playerName.Size = UDim2.new(1, 0, 0.25, 0)
    playerName.Position = UDim2.new(0, 0, 0, 5)
    playerName.BackgroundTransparency = 1
    playerName.Text = "OPERATIVE"
    playerName.TextColor3 = Colors.Text
    playerName.TextSize = 22
    playerName.Font = Enum.Font.GothamBold
    playerName.TextXAlignment = Enum.TextXAlignment.Right
    playerName.TextScaled = true
    playerName.Parent = playerInfo

    local playerLevel = Instance.new("TextLabel")
    playerLevel.Name = "PlayerLevel"
    playerLevel.Size = UDim2.new(0.33, 0, 0.25, 0)
    playerLevel.Position = UDim2.new(0, 0, 0.25, 0)
    playerLevel.BackgroundTransparency = 1
    playerLevel.Text = "RANK: 1"
    playerLevel.TextColor3 = Colors.Primary
    playerLevel.TextSize = 16
    playerLevel.Font = Enum.Font.Gotham
    playerLevel.TextXAlignment = Enum.TextXAlignment.Right
    playerLevel.TextScaled = true
    playerLevel.Parent = playerInfo

    local playerCredits = Instance.new("TextLabel")
    playerCredits.Name = "PlayerCredits"
    playerCredits.Size = UDim2.new(0.33, 0, 0.25, 0)
    playerCredits.Position = UDim2.new(0.33, 5, 0.25, 0)
    playerCredits.BackgroundTransparency = 1
    playerCredits.Text = "CREDITS: 200"
    playerCredits.TextColor3 = Colors.Warning
    playerCredits.TextSize = 16
    playerCredits.Font = Enum.Font.Gotham
    playerCredits.TextXAlignment = Enum.TextXAlignment.Right
    playerCredits.TextScaled = true
    playerCredits.Parent = playerInfo

    local playerXP = Instance.new("TextLabel")
    playerXP.Name = "PlayerXP"
    playerXP.Size = UDim2.new(0.33, 0, 0.25, 0)
    playerXP.Position = UDim2.new(0.67, 5, 0.25, 0)
    playerXP.BackgroundTransparency = 1
    playerXP.Text = "XP: 0/1000"
    playerXP.TextColor3 = Colors.Primary
    playerXP.TextSize = 16
    playerXP.Font = Enum.Font.Gotham
    playerXP.TextXAlignment = Enum.TextXAlignment.Right
    playerXP.TextScaled = true
    playerXP.Parent = playerInfo

    local playerKD = Instance.new("TextLabel")
    playerKD.Name = "PlayerKD"
    playerKD.Size = UDim2.new(1, 0, 0.25, 0)
    playerKD.Position = UDim2.new(0, 0, 0.5, 0)
    playerKD.BackgroundTransparency = 1
    playerKD.Text = "K/D: 0.00"
    playerKD.TextColor3 = Colors.TextSecondary
    playerKD.TextSize = 16
    playerKD.Font = Enum.Font.Gotham
    playerKD.TextXAlignment = Enum.TextXAlignment.Right
    playerKD.TextScaled = true
    playerKD.Parent = playerInfo

    -- Navigation Buttons Frame - Fixed spacing
    local navFrame = Instance.new("Frame")
    navFrame.Name = "NavigationFrame"
    navFrame.Size = UDim2.new(1, -40, 0, 90)
    navFrame.Position = UDim2.new(0, 20, 0, 85)
    navFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    navFrame.BackgroundTransparency = 0.3
    navFrame.BorderSizePixel = 0
    navFrame.Parent = menuPanel

    local navCorner = Instance.new("UICorner")
    navCorner.CornerRadius = UDim.new(0, 12)
    navCorner.Parent = navFrame

    -- Navigation buttons - Fixed width for 1920x1080
    local navButtons = {
        {name = "DEPLOY", text = "[DEPLOY]\nEnter the battlefield", color = Colors.Success},
        {name = "ARMORY", text = "[ARMORY]\nCustomize weapons", color = Colors.Primary},
        {name = "LEADERBOARD", text = "[BOARD]\nView player rankings", color = Colors.Primary},
        {name = "SETTINGS", text = "[CFG]\nGame settings", color = Colors.Primary},
        {name = "SHOP", text = "[SHOP]\nPurchase items", color = Colors.Primary}
    }

    local buttonWidth = 260
    local buttonSpacing = 15
    local totalWidth = (#navButtons * buttonWidth) + ((#navButtons - 1) * buttonSpacing)
    local startX = (1360 - totalWidth) / 2 -- Center in 1360px wide frame

    for i, buttonData in ipairs(navButtons) do
        local navButton = Instance.new("TextButton")
        navButton.Name = buttonData.name .. "Button"
        navButton.Size = UDim2.new(0, buttonWidth, 1, -20)
        navButton.Position = UDim2.new(0, startX + (i-1) * (buttonWidth + buttonSpacing), 0, 10)
        navButton.BackgroundColor3 = buttonData.color
        navButton.BackgroundTransparency = 0.1
        navButton.BorderSizePixel = 0
        navButton.Text = buttonData.text
        navButton.TextColor3 = Colors.Text
        navButton.TextSize = 18
        navButton.Font = Enum.Font.GothamBold
        navButton.TextScaled = true
        navButton.Parent = navFrame

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = navButton

        -- Glow effect
        local buttonGlow = Instance.new("UIStroke")
        buttonGlow.Color = buttonData.color
        buttonGlow.Thickness = 2
        buttonGlow.Transparency = 0.5
        buttonGlow.Parent = navButton
    end

    -- Sections Container - Fixed positioning with clipping
    local sectionsContainer = Instance.new("Frame")
    sectionsContainer.Name = "SectionsContainer"
    sectionsContainer.Size = UDim2.new(1, -40, 1, -185)
    sectionsContainer.Position = UDim2.new(0, 20, 0, 175)
    sectionsContainer.BackgroundTransparency = 1
    sectionsContainer.ClipsDescendants = true -- Prevent content overflow
    sectionsContainer.Parent = menuPanel

    -- MAIN SECTION
    local mainSection = Instance.new("Frame")
    mainSection.Name = "MainSection"
    mainSection.Size = UDim2.new(1, 0, 1, 0)
    mainSection.BackgroundTransparency = 1
    mainSection.Visible = true
    mainSection.Parent = sectionsContainer

    -- Main Section Content
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.Padding = UDim.new(0, 20)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.Parent = mainSection

    -- Server Status Panel
    local serverStatusFrame = Instance.new("Frame")
    serverStatusFrame.Name = "ServerStatus"
    serverStatusFrame.Size = UDim2.new(1, 0, 0, 120)
    serverStatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    serverStatusFrame.BackgroundTransparency = 0.3
    serverStatusFrame.BorderSizePixel = 0
    serverStatusFrame.Parent = mainSection

    local serverCorner = Instance.new("UICorner")
    serverCorner.CornerRadius = UDim.new(0, 10)
    serverCorner.Parent = serverStatusFrame

    local serverTitle = Instance.new("TextLabel")
    serverTitle.Name = "ServerTitle"
    serverTitle.Size = UDim2.new(1, -20, 0, 30)
    serverTitle.Position = UDim2.new(0, 10, 0, 10)
    serverTitle.BackgroundTransparency = 1
    serverTitle.Text = "SERVER STATUS"
    serverTitle.TextColor3 = Colors.Primary
    serverTitle.TextSize = 18
    serverTitle.Font = Enum.Font.GothamBold
    serverTitle.TextXAlignment = Enum.TextXAlignment.Left
    serverTitle.Parent = serverStatusFrame

    local playerCount = Instance.new("TextLabel")
    playerCount.Name = "PlayerCount"
    playerCount.Size = UDim2.new(0.5, -10, 0, 25)
    playerCount.Position = UDim2.new(0, 10, 0, 45)
    playerCount.BackgroundTransparency = 1
    playerCount.Text = "PLAYERS ONLINE: 24/64"
    playerCount.TextColor3 = Colors.Text
    playerCount.TextSize = 14
    playerCount.Font = Enum.Font.Gotham
    playerCount.TextXAlignment = Enum.TextXAlignment.Left
    playerCount.Parent = serverStatusFrame

    local matchStatus = Instance.new("TextLabel")
    matchStatus.Name = "MatchStatus"
    matchStatus.Size = UDim2.new(0.5, -10, 0, 25)
    matchStatus.Position = UDim2.new(0.5, 10, 0, 45)
    matchStatus.BackgroundTransparency = 1
    matchStatus.Text = "MATCH STATUS: WAITING"
    matchStatus.TextColor3 = Colors.Warning
    matchStatus.TextSize = 14
    matchStatus.Font = Enum.Font.Gotham
    matchStatus.TextXAlignment = Enum.TextXAlignment.Left
    matchStatus.Parent = serverStatusFrame

    local nextMatch = Instance.new("TextLabel")
    nextMatch.Name = "NextMatch"
    nextMatch.Size = UDim2.new(1, -20, 0, 25)
    nextMatch.Position = UDim2.new(0, 10, 0, 75)
    nextMatch.BackgroundTransparency = 1
    nextMatch.Text = "NEXT MATCH STARTS IN: 02:45"
    nextMatch.TextColor3 = Colors.TextSecondary
    nextMatch.TextSize = 14
    nextMatch.Font = Enum.Font.Gotham
    nextMatch.TextXAlignment = Enum.TextXAlignment.Left
    nextMatch.Parent = serverStatusFrame

    -- Map Voting Panel
    local votingFrame = Instance.new("Frame")
    votingFrame.Name = "MapVoting"
    votingFrame.Size = UDim2.new(1, 0, 0, 200)
    votingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    votingFrame.BackgroundTransparency = 0.3
    votingFrame.BorderSizePixel = 0
    votingFrame.Parent = mainSection

    local votingCorner = Instance.new("UICorner")
    votingCorner.CornerRadius = UDim.new(0, 10)
    votingCorner.Parent = votingFrame

    local votingTitle = Instance.new("TextLabel")
    votingTitle.Name = "VotingTitle"
    votingTitle.Size = UDim2.new(1, -20, 0, 30)
    votingTitle.Position = UDim2.new(0, 10, 0, 10)
    votingTitle.BackgroundTransparency = 1
    votingTitle.Text = "GAMEMODE VOTING"
    votingTitle.TextColor3 = Colors.Primary
    votingTitle.TextSize = 18
    votingTitle.Font = Enum.Font.GothamBold
    votingTitle.TextXAlignment = Enum.TextXAlignment.Left
    votingTitle.Parent = votingFrame

    -- Gamemode Vote Options
    local gamemodeOptions = {"Team Deathmatch", "King of the Hill", "Kill Confirmed"}
    for i, gamemodeName in ipairs(gamemodeOptions) do
        local gamemodeVoteBtn = Instance.new("TextButton")
        gamemodeVoteBtn.Name = gamemodeName .. "Vote"
        gamemodeVoteBtn.Size = UDim2.new(1, -20, 0, 35)
        gamemodeVoteBtn.Position = UDim2.new(0, 10, 0, 35 + (i * 45))
        gamemodeVoteBtn.BackgroundColor3 = Colors.Primary
        gamemodeVoteBtn.BackgroundTransparency = 0.7
        gamemodeVoteBtn.BorderSizePixel = 0
        gamemodeVoteBtn.Text = gamemodeName .. " (0 votes)"
        gamemodeVoteBtn.TextColor3 = Colors.Text
        gamemodeVoteBtn.TextSize = 14
        gamemodeVoteBtn.Font = Enum.Font.GothamBold
        gamemodeVoteBtn.Parent = votingFrame

        local gamemodeCorner = Instance.new("UICorner")
        gamemodeCorner.CornerRadius = UDim.new(0, 6)
        gamemodeCorner.Parent = gamemodeVoteBtn
    end

    -- Recent Updates Panel
    local updatesFrame = Instance.new("Frame")
    updatesFrame.Name = "RecentUpdates"
    updatesFrame.Size = UDim2.new(1, 0, 0, 150)
    updatesFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    updatesFrame.BackgroundTransparency = 0.3
    updatesFrame.BorderSizePixel = 0
    updatesFrame.Parent = mainSection

    local updatesCorner = Instance.new("UICorner")
    updatesCorner.CornerRadius = UDim.new(0, 10)
    updatesCorner.Parent = updatesFrame

    local updatesTitle = Instance.new("TextLabel")
    updatesTitle.Name = "UpdatesTitle"
    updatesTitle.Size = UDim2.new(1, -20, 0, 30)
    updatesTitle.Position = UDim2.new(0, 10, 0, 10)
    updatesTitle.BackgroundTransparency = 1
    updatesTitle.Text = "RECENT UPDATES"
    updatesTitle.TextColor3 = Colors.Primary
    updatesTitle.TextSize = 18
    updatesTitle.Font = Enum.Font.GothamBold
    updatesTitle.TextXAlignment = Enum.TextXAlignment.Left
    updatesTitle.Parent = updatesFrame

    local updatesList = Instance.new("TextLabel")
    updatesList.Name = "UpdatesList"
    updatesList.Size = UDim2.new(1, -20, 1, -50)
    updatesList.Position = UDim2.new(0, 10, 0, 40)
    updatesList.BackgroundTransparency = 1
    updatesList.Text = "• Added new weapon attachments\n• Fixed weapon balancing issues\n• Improved map lighting\n• Enhanced UI responsiveness"
    updatesList.TextColor3 = Colors.TextSecondary
    updatesList.TextSize = 14
    updatesList.Font = Enum.Font.Gotham
    updatesList.TextXAlignment = Enum.TextXAlignment.Left
    updatesList.TextYAlignment = Enum.TextYAlignment.Top
    updatesList.TextWrapped = true
    updatesList.Parent = updatesFrame

    -- Create other sections
    local sectionNames = {"ArmorySection", "ShopSection", "LeaderboardSection", "StatisticsSection", "SettingsSection"}
    for _, sectionName in ipairs(sectionNames) do
        local section = Instance.new("Frame")
        section.Name = sectionName
        section.Size = UDim2.new(1, 0, 1, 0)
        section.BackgroundTransparency = 1
        section.Visible = false
        section.Parent = sectionsContainer

        -- Add Phantom Forces style loadout system
        if sectionName == "ArmorySection" then
            -- Create exact PF layout: Left sidebar (classes/weapons), Center (3D view), Right sidebar (stats/loadout)

            -- LEFT SIDEBAR - Class Selection & Weapon List
            local leftSidebar = Instance.new("Frame")
            leftSidebar.Name = "LeftSidebar"
            leftSidebar.Size = UDim2.new(0, 280, 1, 0)
            leftSidebar.Position = UDim2.new(0, 0, 0, 0)
            leftSidebar.BackgroundColor3 = Color3.fromRGB(45, 85, 125) -- PF Blue
            leftSidebar.BackgroundTransparency = 0.1
            leftSidebar.BorderSizePixel = 0
            leftSidebar.Parent = section

            -- Class tabs (top of left sidebar)
            local classTabsFrame = Instance.new("Frame")
            classTabsFrame.Name = "ClassTabs"
            classTabsFrame.Size = UDim2.new(1, 0, 0, 40)
            classTabsFrame.BackgroundTransparency = 1
            classTabsFrame.Parent = leftSidebar

            local classes = {"ASSAULT", "SCOUT", "SUPPORT", "RECON"}
            for i, className in ipairs(classes) do
                local classTab = Instance.new("TextButton")
                classTab.Name = className .. "Tab"
                classTab.Size = UDim2.new(0.25, -2, 1, 0)
                classTab.Position = UDim2.new((i-1) * 0.25, (i-1)*2, 0, 0)
                classTab.BackgroundColor3 = (i == 1) and Color3.fromRGB(30, 60, 90) or Color3.fromRGB(60, 100, 140)
                classTab.BorderSizePixel = 0
                classTab.Text = className
                classTab.TextColor3 = Colors.Text
                classTab.TextSize = 10
                classTab.Font = Enum.Font.GothamBold
                classTab.Parent = classTabsFrame
            end

            -- Weapon categories (below class tabs)
            local categoryFrame = Instance.new("Frame")
            categoryFrame.Name = "CategoryFrame"
            categoryFrame.Size = UDim2.new(1, 0, 0, 30)
            categoryFrame.Position = UDim2.new(0, 0, 0, 45)
            categoryFrame.BackgroundTransparency = 1
            categoryFrame.Parent = leftSidebar

            local categories = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
            for i, catName in ipairs(categories) do
                local catBtn = Instance.new("TextButton")
                catBtn.Name = catName .. "Button"
                catBtn.Size = UDim2.new(0.25, -2, 1, 0)
                catBtn.Position = UDim2.new((i-1) * 0.25, (i-1)*2, 0, 0)
                catBtn.BackgroundColor3 = (i == 1) and Colors.Primary or Color3.fromRGB(70, 110, 150)
                catBtn.BorderSizePixel = 0
                catBtn.Text = catName
                catBtn.TextColor3 = Colors.Text
                catBtn.TextSize = 10
                catBtn.Font = Enum.Font.Gotham
                catBtn.TextScaled = true
                catBtn.Parent = categoryFrame
            end

            -- Weapon list (scrollable)
            local weaponListFrame = Instance.new("ScrollingFrame")
            weaponListFrame.Name = "WeaponList"
            weaponListFrame.Size = UDim2.new(1, 0, 1, -80)
            weaponListFrame.Position = UDim2.new(0, 0, 0, 80)
            weaponListFrame.BackgroundColor3 = Color3.fromRGB(50, 90, 130)
            weaponListFrame.BackgroundTransparency = 0.2
            weaponListFrame.BorderSizePixel = 0
            weaponListFrame.ScrollBarThickness = 8
            weaponListFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
            weaponListFrame.Parent = leftSidebar

            local weaponListLayout = Instance.new("UIListLayout")
            weaponListLayout.Padding = UDim.new(0, 2)
            weaponListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            weaponListLayout.Parent = weaponListFrame

            -- Sample weapon entries
            local weapons = {"AK12", "AN-94", "AS VAL", "AUG A1", "AUG A3", "C7A2", "G36", "HK416", "L85A2", "M16A4", "M4A1", "SCAR-L"}
            for i, weaponName in ipairs(weapons) do
                local weaponEntry = Instance.new("TextButton")
                weaponEntry.Name = weaponName .. "Entry"
                weaponEntry.Size = UDim2.new(1, -8, 0, 25)
                weaponEntry.BackgroundColor3 = (i == 1) and Colors.Primary or Color3.fromRGB(40, 75, 110)
                weaponEntry.BackgroundTransparency = (i == 1) and 0.1 or 0.3
                weaponEntry.BorderSizePixel = 0
                weaponEntry.Text = "  " .. weaponName
                weaponEntry.TextColor3 = Colors.Text
                weaponEntry.TextSize = 11
                weaponEntry.Font = Enum.Font.Gotham
                weaponEntry.TextXAlignment = Enum.TextXAlignment.Left
                weaponEntry.LayoutOrder = i
                weaponEntry.Parent = weaponListFrame
            end

            -- CENTER AREA - 3D Weapon Display with Pegboard Background
            local centerArea = Instance.new("Frame")
            centerArea.Name = "CenterDisplay"
            centerArea.Size = UDim2.new(1, -580, 1, -40) -- Space between left sidebar (280px) and right sidebar (300px), reserve space for attachment tabs
            centerArea.Position = UDim2.new(0, 280, 0, 40)
            centerArea.BackgroundColor3 = Color3.fromRGB(200, 190, 180) -- Pegboard beige
            centerArea.BorderSizePixel = 0
            centerArea.Parent = section

            -- Attachment management tabs (above center area)
            local attachmentTabsFrame = Instance.new("Frame")
            attachmentTabsFrame.Name = "AttachmentTabs"
            attachmentTabsFrame.Size = UDim2.new(1, -580, 0, 40)
            attachmentTabsFrame.Position = UDim2.new(0, 280, 0, 0)
            attachmentTabsFrame.BackgroundColor3 = Color3.fromRGB(30, 60, 90)
            attachmentTabsFrame.BorderSizePixel = 0
            attachmentTabsFrame.Parent = section

            local attachmentTabs = {"ATTACHMENTS", "PERKS", "SKINS", "WEAPONS"}
            for i, tabName in ipairs(attachmentTabs) do
                local attachTab = Instance.new("TextButton")
                attachTab.Name = tabName .. "Tab"
                attachTab.Size = UDim2.new(0.25, -2, 1, 0)
                attachTab.Position = UDim2.new((i-1) * 0.25, (i-1)*2, 0, 0)
                attachTab.BackgroundColor3 = (i == 1) and Colors.Primary or Color3.fromRGB(60, 100, 140)
                attachTab.BorderSizePixel = 0
                attachTab.Text = tabName
                attachTab.TextColor3 = Colors.Text
                attachTab.TextSize = 12
                attachTab.Font = Enum.Font.GothamBold
                attachTab.TextScaled = true
                attachTab.Parent = attachmentTabsFrame
            end

            -- Pegboard pattern background
            local pegboardPattern = Instance.new("Frame")
            pegboardPattern.Name = "PegboardPattern"
            pegboardPattern.Size = UDim2.new(1, 0, 1, 0)
            pegboardPattern.BackgroundTransparency = 1
            pegboardPattern.Parent = centerArea

            -- Create dot pattern for pegboard effect
            for x = 1, 30 do
                for y = 1, 15 do
                    local dot = Instance.new("Frame")
                    dot.Size = UDim2.new(0, 2, 0, 2)
                    dot.Position = UDim2.new(0, x * 20, 0, y * 25)
                    dot.BackgroundColor3 = Color3.fromRGB(150, 140, 130)
                    dot.BorderSizePixel = 0
                    dot.Parent = pegboardPattern

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(1, 0)
                    corner.Parent = dot
                end
            end

            -- 3D Weapon Display Area (ViewportFrame placeholder)
            local weaponDisplayArea = Instance.new("Frame")
            weaponDisplayArea.Name = "WeaponDisplay"
            weaponDisplayArea.Size = UDim2.new(0.8, 0, 0.6, 0)
            weaponDisplayArea.Position = UDim2.new(0.1, 0, 0.2, 0)
            weaponDisplayArea.BackgroundTransparency = 1
            weaponDisplayArea.Parent = centerArea

            local weaponPlaceholder = Instance.new("TextLabel")
            weaponPlaceholder.Size = UDim2.new(1, 0, 1, 0)
            weaponPlaceholder.BackgroundTransparency = 1
            weaponPlaceholder.Text = "3D WEAPON MODEL\n(ViewportFrame)"
            weaponPlaceholder.TextColor3 = Color3.fromRGB(100, 90, 80)
            weaponPlaceholder.TextSize = 16
            weaponPlaceholder.Font = Enum.Font.GothamBold
            weaponPlaceholder.Parent = weaponDisplayArea

            -- RIGHT SIDEBAR - Advanced Stats & Current Loadout
            local rightSidebar = Instance.new("Frame")
            rightSidebar.Name = "RightSidebar"
            rightSidebar.Size = UDim2.new(0, 300, 1, 0)
            rightSidebar.Position = UDim2.new(1, -300, 0, 0)
            rightSidebar.BackgroundColor3 = Color3.fromRGB(60, 120, 120) -- Teal green like PF
            rightSidebar.BackgroundTransparency = 0.1
            rightSidebar.BorderSizePixel = 0
            rightSidebar.Parent = section

            -- Stats/Loadout toggle tabs
            local statsTabFrame = Instance.new("Frame")
            statsTabFrame.Name = "StatsTabFrame"
            statsTabFrame.Size = UDim2.new(1, 0, 0, 35)
            statsTabFrame.BackgroundTransparency = 1
            statsTabFrame.Parent = rightSidebar

            local statsTab = Instance.new("TextButton")
            statsTab.Name = "AdvancedStatsTab"
            statsTab.Size = UDim2.new(0.5, -1, 1, 0)
            statsTab.BackgroundColor3 = Colors.Primary
            statsTab.BorderSizePixel = 0
            statsTab.Text = "ADVANCED STATS"
            statsTab.TextColor3 = Colors.Text
            statsTab.TextSize = 10
            statsTab.Font = Enum.Font.GothamBold
            statsTab.Parent = statsTabFrame

            local loadoutTab = Instance.new("TextButton")
            loadoutTab.Name = "RecoilStatsTab"
            loadoutTab.Size = UDim2.new(0.5, -1, 1, 0)
            loadoutTab.Position = UDim2.new(0.5, 1, 0, 0)
            loadoutTab.BackgroundColor3 = Color3.fromRGB(80, 140, 140)
            loadoutTab.BorderSizePixel = 0
            loadoutTab.Text = "RECOIL STATS"
            loadoutTab.TextColor3 = Colors.Text
            loadoutTab.TextSize = 10
            loadoutTab.Font = Enum.Font.GothamBold
            loadoutTab.Parent = statsTabFrame

            -- Advanced Stats Panel (scrollable)
            local advancedStatsPanel = Instance.new("ScrollingFrame")
            advancedStatsPanel.Name = "AdvancedStatsPanel"
            advancedStatsPanel.Size = UDim2.new(1, -10, 1, -40)
            advancedStatsPanel.Position = UDim2.new(0, 5, 0, 35)
            advancedStatsPanel.BackgroundColor3 = Color3.fromRGB(50, 110, 110)
            advancedStatsPanel.BackgroundTransparency = 0.2
            advancedStatsPanel.BorderSizePixel = 0
            advancedStatsPanel.ScrollBarThickness = 6
            advancedStatsPanel.CanvasSize = UDim2.new(0, 0, 0, 800)
            advancedStatsPanel.Parent = rightSidebar

            -- Stats sections like reference
            local statsSections = {
                {name = "WEAPON BALLISTICS", stats = {
                    {"MINIMUM TIME TO KILL", "0.12s"},
                    {"MUZZLE VELOCITY", "1225.00 studs/s"},
                    {"PENETRATION DEPTH", "0.50 studs"},
                    {"SUPPRESSION", "0.25"},
                    {"RADAR SUPPRESSION RANGE", "Beyond 35 studs"}
                }},
                {name = "HIP ACCURACY", stats = {
                    {"HIPFIRE SPREAD FACTOR", "0.08"},
                    {"HIPFIRE RECOVERY SPEED", "15.30"},
                    {"HIPFIRE SPREAD DAMPING", "0.95"}
                }},
                {name = "SIGHT ACCURACY", stats = {
                    {"SIGHT MAGNIFICATION", "1.20"},
                    {"CROSSHAIR SIZE", "25.00"},
                    {"CROSSHAIR SPREAD RATE", "250.00"},
                    {"CROSSHAIR RECOVER RATE", "15.00"}
                }},
                {name = "ACCURACY", stats = {
                    {"HIP CHOKE", "0.00"},
                    {"AIM CHOKE", "0.00"}
                }},
                {name = "WEAPON HANDLING", stats = {
                    {"RELOAD TIME", "2.75 seconds"},
                    {"EMPTY RELOAD TIME", "3.50 seconds"}
                }}
            }

            local yOffset = 10
            for _, section in ipairs(statsSections) do
                -- Section header
                local sectionHeader = Instance.new("TextLabel")
                sectionHeader.Name = section.name .. "Header"
                sectionHeader.Size = UDim2.new(1, -10, 0, 25)
                sectionHeader.Position = UDim2.new(0, 5, 0, yOffset)
                sectionHeader.BackgroundColor3 = Color3.fromRGB(40, 100, 100)
                sectionHeader.BorderSizePixel = 0
                sectionHeader.Text = section.name
                sectionHeader.TextColor3 = Colors.Text
                sectionHeader.TextSize = 11
                sectionHeader.Font = Enum.Font.GothamBold
                sectionHeader.Parent = advancedStatsPanel

                yOffset = yOffset + 30

                -- Stats entries
                for _, stat in ipairs(section.stats) do
                    local statEntry = Instance.new("Frame")
                    statEntry.Size = UDim2.new(1, -10, 0, 20)
                    statEntry.Position = UDim2.new(0, 5, 0, yOffset)
                    statEntry.BackgroundTransparency = 1
                    statEntry.Parent = advancedStatsPanel

                    local statName = Instance.new("TextLabel")
                    statName.Size = UDim2.new(0.6, 0, 1, 0)
                    statName.BackgroundTransparency = 1
                    statName.Text = stat[1]
                    statName.TextColor3 = Colors.Text
                    statName.TextSize = 9
                    statName.Font = Enum.Font.Gotham
                    statName.TextXAlignment = Enum.TextXAlignment.Left
                    statName.Parent = statEntry

                    local statValue = Instance.new("TextLabel")
                    statValue.Size = UDim2.new(0.4, 0, 1, 0)
                    statValue.Position = UDim2.new(0.6, 0, 0, 0)
                    statValue.BackgroundTransparency = 1
                    statValue.Text = stat[2]
                    statValue.TextColor3 = Colors.Warning -- Yellow for values
                    statValue.TextSize = 9
                    statValue.Font = Enum.Font.Gotham
                    statValue.TextXAlignment = Enum.TextXAlignment.Right
                    statValue.Parent = statEntry

                    yOffset = yOffset + 22
                end
                yOffset = yOffset + 10 -- Extra space between sections
            end

        elseif sectionName == "LeaderboardSection" then
            local leaderTitle = Instance.new("TextLabel")
            leaderTitle.Name = "LeaderTitle"
            leaderTitle.Size = UDim2.new(1, 0, 0, 50)
            leaderTitle.BackgroundTransparency = 1
            leaderTitle.Text = "PLAYER RANKINGS"
            leaderTitle.TextColor3 = Colors.Primary
            leaderTitle.TextSize = 24
            leaderTitle.Font = Enum.Font.GothamBold
            leaderTitle.Parent = section

            local leaderContent = Instance.new("ScrollingFrame")
            leaderContent.Name = "LeaderboardList"
            leaderContent.Size = UDim2.new(1, 0, 1, -100)
            leaderContent.Position = UDim2.new(0, 0, 0, 60)
            leaderContent.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            leaderContent.BackgroundTransparency = 0.3
            leaderContent.BorderSizePixel = 0
            leaderContent.ScrollBarThickness = 8
            leaderContent.CanvasSize = UDim2.new(0, 0, 0, 600)
            leaderContent.Parent = section

            local leaderContentCorner = Instance.new("UICorner")
            leaderContentCorner.CornerRadius = UDim.new(0, 10)
            leaderContentCorner.Parent = leaderContent

            local leaderLayout = Instance.new("UIListLayout")
            leaderLayout.Padding = UDim.new(0, 5)
            leaderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            leaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
            leaderLayout.Parent = leaderContent

            local leaderPadding = Instance.new("UIPadding")
            leaderPadding.PaddingTop = UDim.new(0, 15)
            leaderPadding.PaddingBottom = UDim.new(0, 15)
            leaderPadding.PaddingLeft = UDim.new(0, 15)
            leaderPadding.PaddingRight = UDim.new(0, 15)
            leaderPadding.Parent = leaderContent

            -- Header row
            local headerRow = Instance.new("Frame")
            headerRow.Name = "HeaderRow"
            headerRow.Size = UDim2.new(1, -20, 0, 40)
            headerRow.BackgroundColor3 = Colors.Primary
            headerRow.BackgroundTransparency = 0.1
            headerRow.BorderSizePixel = 0
            headerRow.LayoutOrder = 1
            headerRow.Parent = leaderContent

            local headerCorner = Instance.new("UICorner")
            headerCorner.CornerRadius = UDim.new(0, 6)
            headerCorner.Parent = headerRow

            local headers = {"RANK", "PLAYER", "LEVEL", "K/D", "SCORE"}
            local headerWidths = {0.1, 0.3, 0.15, 0.2, 0.25}

            for i, headerText in ipairs(headers) do
                local header = Instance.new("TextLabel")
                header.Name = headerText .. "Header"
                header.Size = UDim2.new(headerWidths[i], -5, 1, 0)
                header.Position = UDim2.new(
                    (i == 1 and 0) or (headerWidths[1] + (i > 2 and headerWidths[2] or 0) + (i > 3 and headerWidths[3] or 0) + (i > 4 and headerWidths[4] or 0)),
                    (i-1) * 5,
                    0,
                    0
                )
                header.BackgroundTransparency = 1
                header.Text = headerText
                header.TextColor3 = Colors.Text
                header.TextSize = 14
                header.Font = Enum.Font.GothamBold
                header.Parent = headerRow
            end

            -- Sample leaderboard entries
            local samplePlayers = {
                {"1", "Player1", "25", "2.14", "4250"},
                {"2", "Player2", "22", "1.89", "3890"},
                {"3", "Player3", "19", "1.76", "3420"},
                {"4", "Player4", "17", "1.52", "2980"},
                {"5", "Player5", "15", "1.31", "2650"}
            }

            for i, playerData in ipairs(samplePlayers) do
                local playerRow = Instance.new("Frame")
                playerRow.Name = "PlayerRow" .. i
                playerRow.Size = UDim2.new(1, -20, 0, 35)
                playerRow.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                playerRow.BackgroundTransparency = (i % 2 == 0) and 0.3 or 0.5
                playerRow.BorderSizePixel = 0
                playerRow.LayoutOrder = i + 1
                playerRow.Parent = leaderContent

                local rowCorner = Instance.new("UICorner")
                rowCorner.CornerRadius = UDim.new(0, 4)
                rowCorner.Parent = playerRow

                for j, data in ipairs(playerData) do
                    local dataLabel = Instance.new("TextLabel")
                    dataLabel.Name = headers[j] .. "Data"
                    dataLabel.Size = UDim2.new(headerWidths[j], -5, 1, 0)
                    dataLabel.Position = UDim2.new(
                        (j == 1 and 0) or (headerWidths[1] + (j > 2 and headerWidths[2] or 0) + (j > 3 and headerWidths[3] or 0) + (j > 4 and headerWidths[4] or 0)),
                        (j-1) * 5,
                        0,
                        0
                    )
                    dataLabel.BackgroundTransparency = 1
                    dataLabel.Text = data
                    dataLabel.TextColor3 = (j == 1) and Colors.Primary or Colors.Text
                    dataLabel.TextSize = 13
                    dataLabel.Font = Enum.Font.Gotham
                    dataLabel.Parent = playerRow
                end
            end
        end

        -- Add CategoryButtons to ShopSection
        if sectionName == "ShopSection" then
            local categoryButtons = Instance.new("Frame")
            categoryButtons.Name = "CategoryButtons"
            categoryButtons.Size = UDim2.new(1, 0, 0, 60)
            categoryButtons.Position = UDim2.new(0, 0, 0, 0)
            categoryButtons.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            categoryButtons.BackgroundTransparency = 0.3
            categoryButtons.BorderSizePixel = 0
            categoryButtons.Parent = section

            local categoryCorner = Instance.new("UICorner")
            categoryCorner.CornerRadius = UDim.new(0, 8)
            categoryCorner.Parent = categoryButtons

            local categoryLayout = Instance.new("UIListLayout")
            categoryLayout.FillDirection = Enum.FillDirection.Horizontal
            categoryLayout.Padding = UDim.new(0, 15)
            categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            categoryLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            categoryLayout.Parent = categoryButtons

            -- Create category buttons
            local categories = {"WEAPONS", "ATTACHMENTS", "SKINS", "PERKS"}
            for _, categoryName in ipairs(categories) do
                local catButton = Instance.new("TextButton")
                catButton.Name = categoryName .. "Button"
                catButton.Size = UDim2.new(0, 160, 0, 40)
                catButton.BackgroundColor3 = Colors.Primary
                catButton.BackgroundTransparency = 0.2
                catButton.BorderSizePixel = 0
                catButton.Text = categoryName
                catButton.TextColor3 = Colors.Text
                catButton.TextSize = 16
                catButton.Font = Enum.Font.GothamBold
                catButton.Parent = categoryButtons

                local catCorner = Instance.new("UICorner")
                catCorner.CornerRadius = UDim.new(0, 6)
                catCorner.Parent = catButton
            end

            -- Shop Grid
            local shopGrid = Instance.new("ScrollingFrame")
            shopGrid.Name = "ShopGrid"
            shopGrid.Size = UDim2.new(1, 0, 1, -80)
            shopGrid.Position = UDim2.new(0, 0, 0, 70)
            shopGrid.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
            shopGrid.BackgroundTransparency = 0.3
            shopGrid.BorderSizePixel = 0
            shopGrid.ScrollBarThickness = 8
            shopGrid.CanvasSize = UDim2.new(0, 0, 0, 800)
            shopGrid.Parent = section

            local shopGridCorner = Instance.new("UICorner")
            shopGridCorner.CornerRadius = UDim.new(0, 10)
            shopGridCorner.Parent = shopGrid
        end

        -- Add back button to all sections except main
        local backButton = Instance.new("TextButton")
        backButton.Name = "BackButton"
        backButton.Size = UDim2.new(0, 120, 0, 50)
        backButton.Position = UDim2.new(0, 0, 1, -60)
        backButton.BackgroundColor3 = Colors.Error
        backButton.BackgroundTransparency = 0.2
        backButton.BorderSizePixel = 0
        backButton.Text = "← BACK"
        backButton.TextColor3 = Colors.Text
        backButton.TextSize = 16
        backButton.Font = Enum.Font.GothamBold
        backButton.Parent = section

        local backCorner = Instance.new("UICorner")
        backCorner.CornerRadius = UDim.new(0, 8)
        backCorner.Parent = backButton
    end

    print("📋 Main Menu UI Created Successfully!")
    return mainMenuGui
end

-- Create In-Game HUD with proper 1920x1080 positioning
local function CreateInGameHUD()
    print("🎯 Creating In-Game HUD...")

    local hudGui = Instance.new("ScreenGui")
    hudGui.Name = "FPSHUD"
    hudGui.ResetOnSpawn = false
    hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    hudGui.IgnoreGuiInset = true
    hudGui.Parent = StarterGui

    -- RADAR/MINIMAP - TOP LEFT CORNER (BIGGER)
    local radarFrame = Instance.new("Frame")
    radarFrame.Name = "RadarFrame"
    radarFrame.Size = UDim2.new(0, 220, 0, 220)
    radarFrame.Position = UDim2.new(0, 30, 0, 30)
    radarFrame.BackgroundColor3 = Colors.Panel
    radarFrame.BackgroundTransparency = 0.2
    radarFrame.BorderSizePixel = 0
    radarFrame.Parent = hudGui

    local radarCorner = Instance.new("UICorner")
    radarCorner.CornerRadius = UDim.new(1, 0) -- Circular
    radarCorner.Parent = radarFrame

    local radarStroke = Instance.new("UIStroke")
    radarStroke.Color = Colors.Primary
    radarStroke.Thickness = 3
    radarStroke.Transparency = 0.3
    radarStroke.Parent = radarFrame

    local radarCenter = Instance.new("Frame")
    radarCenter.Name = "Center"
    radarCenter.Size = UDim2.new(0, 8, 0, 8)
    radarCenter.Position = UDim2.new(0.5, -4, 0.5, -4)
    radarCenter.BackgroundColor3 = Colors.Primary
    radarCenter.BorderSizePixel = 0
    radarCenter.Parent = radarFrame

    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = radarCenter

    -- Health Bar - Bottom Left
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthFrame"
    healthFrame.Size = UDim2.new(0, 300, 0, 70)
    healthFrame.Position = UDim2.new(0, 30, 1, -100)
    healthFrame.BackgroundColor3 = Colors.Panel
    healthFrame.BackgroundTransparency = 0.2
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = hudGui

    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(0, 10)
    healthCorner.Parent = healthFrame

    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, -20, 0.4, 0)
    healthText.Position = UDim2.new(0, 10, 0, 5)
    healthText.BackgroundTransparency = 1
    healthText.Text = "HEALTH"
    healthText.TextColor3 = Colors.Text
    healthText.TextSize = 16
    healthText.Font = Enum.Font.GothamBold
    healthText.TextXAlignment = Enum.TextXAlignment.Left
    healthText.Parent = healthFrame

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, -20, 0, 25)
    healthBar.Position = UDim2.new(0, 10, 0, 30)
    healthBar.BackgroundColor3 = Colors.Success
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthFrame

    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(0, 5)
    healthBarCorner.Parent = healthBar

    local healthValue = Instance.new("TextLabel")
    healthValue.Name = "HealthValue"
    healthValue.Size = UDim2.new(1, 0, 1, 0)
    healthValue.BackgroundTransparency = 1
    healthValue.Text = "100"
    healthValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthValue.TextSize = 16
    healthValue.Font = Enum.Font.GothamBold
    healthValue.Parent = healthBar

    -- Ammo Display - Bottom Right (Fixed positioning)
    local ammoFrame = Instance.new("Frame")
    ammoFrame.Name = "AmmoFrame"
    ammoFrame.Size = UDim2.new(0, 200, 0, 80)
    ammoFrame.Position = UDim2.new(1, -220, 1, -100) -- Better positioning for 1920x1080
    ammoFrame.BackgroundColor3 = Colors.Panel
    ammoFrame.BackgroundTransparency = 0.2
    ammoFrame.BorderSizePixel = 0
    ammoFrame.Parent = hudGui

    local ammoCorner = Instance.new("UICorner")
    ammoCorner.CornerRadius = UDim.new(0, 10)
    ammoCorner.Parent = ammoFrame

    local currentAmmo = Instance.new("TextLabel")
    currentAmmo.Name = "CurrentAmmo"
    currentAmmo.Size = UDim2.new(0.535, 0, 0.6, 0)
    currentAmmo.Position = UDim2.new(0, 3, 0, 12)
    currentAmmo.BackgroundTransparency = 1
    currentAmmo.Text = "031"
    currentAmmo.TextColor3 = Colors.Primary
    currentAmmo.TextSize = 28
    currentAmmo.Font = Enum.Font.GothamBold
    currentAmmo.TextXAlignment = Enum.TextXAlignment.Right
    currentAmmo.TextYAlignment = Enum.TextYAlignment.Center
    currentAmmo.Parent = ammoFrame

    local reserveAmmo = Instance.new("TextLabel")
    reserveAmmo.Name = "ReserveAmmo"
    reserveAmmo.Size = UDim2.new(0.4, 0, 0.6, 0)
    reserveAmmo.Position = UDim2.new(0.6, 0, 0, 0)
    reserveAmmo.BackgroundTransparency = 1
    reserveAmmo.Text = "/ 124"
    reserveAmmo.TextColor3 = Colors.TextSecondary
    reserveAmmo.TextSize = 16
    reserveAmmo.Font = Enum.Font.Gotham
    reserveAmmo.TextXAlignment = Enum.TextXAlignment.Left
    reserveAmmo.TextYAlignment = Enum.TextYAlignment.Bottom
    reserveAmmo.Parent = ammoFrame

    local weaponName = Instance.new("TextLabel")
    weaponName.Name = "WeaponName"
    weaponName.Size = UDim2.new(1, -10, 0.4, 0)
    weaponName.Position = UDim2.new(0, 5, 0.6, 0)
    weaponName.BackgroundTransparency = 1
    weaponName.Text = "M4A1"
    weaponName.TextColor3 = Colors.Primary
    weaponName.TextSize = 14
    weaponName.Font = Enum.Font.GothamBold
    weaponName.TextXAlignment = Enum.TextXAlignment.Center
    weaponName.Parent = ammoFrame

    -- Compass - Top Center
    local compassFrame = Instance.new("Frame")
    compassFrame.Name = "CompassFrame"
    compassFrame.Size = UDim2.new(0, 400, 0, 50)
    compassFrame.Position = UDim2.new(0.5, -200, 0, 30)
    compassFrame.BackgroundColor3 = Colors.Panel
    compassFrame.BackgroundTransparency = 0.3
    compassFrame.BorderSizePixel = 0
    compassFrame.Parent = hudGui

    local compassCorner = Instance.new("UICorner")
    compassCorner.CornerRadius = UDim.new(0, 25)
    compassCorner.Parent = compassFrame

    local compassText = Instance.new("TextLabel")
    compassText.Name = "CompassText"
    compassText.Size = UDim2.new(1, 0, 1, 0)
    compassText.BackgroundTransparency = 1
    compassText.Text = "N    314°    NW"
    compassText.TextColor3 = Colors.Primary
    compassText.TextSize = 18
    compassText.Font = Enum.Font.GothamBold
    compassText.Parent = compassFrame

    -- Crosshair - Screen Center (Grenade-style)
    local crosshairFrame = Instance.new("Frame")
    crosshairFrame.Name = "CrosshairFrame"
    crosshairFrame.Size = UDim2.new(0, 50, 0, 50)
    crosshairFrame.Position = UDim2.new(0.5, -25, 0.5, -25)
    crosshairFrame.BackgroundTransparency = 1
    crosshairFrame.Parent = hudGui

    local crosshair = Instance.new("ImageLabel")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 20, 0, 20)
    crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
    crosshair.BackgroundTransparency = 1
    crosshair.Image = "rbxassetid://316279305" -- Crosshair image
    crosshair.ImageColor3 = Colors.Primary
    crosshair.Parent = crosshairFrame

    -- Score Display - Top Right
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.new(0, 280, 0, 90)
    scoreFrame.Position = UDim2.new(1, -310, 0, 30)
    scoreFrame.BackgroundColor3 = Colors.Panel
    scoreFrame.BackgroundTransparency = 0.2
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = hudGui

    local scoreCorner = Instance.new("UICorner")
    scoreCorner.CornerRadius = UDim.new(0, 10)
    scoreCorner.Parent = scoreFrame

    local objectiveText = Instance.new("TextLabel")
    objectiveText.Name = "ObjectiveText"
    objectiveText.Size = UDim2.new(1, -20, 0.35, 0)
    objectiveText.Position = UDim2.new(0, 10, 0, 5)
    objectiveText.BackgroundTransparency = 1
    objectiveText.Text = "TEAM DEATHMATCH"
    objectiveText.TextColor3 = Colors.Primary
    objectiveText.TextSize = 16
    objectiveText.Font = Enum.Font.GothamBold
    objectiveText.TextXAlignment = Enum.TextXAlignment.Center
    objectiveText.Parent = scoreFrame

    local scoreText = Instance.new("TextLabel")
    scoreText.Name = "ScoreText"
    scoreText.Size = UDim2.new(1, -20, 0.65, 0)
    scoreText.Position = UDim2.new(0, 10, 0.35, 0)
    scoreText.BackgroundTransparency = 1
    scoreText.Text = "KFC: 75  |  FBI: 128"
    scoreText.TextColor3 = Colors.Text
    scoreText.TextSize = 20
    scoreText.Font = Enum.Font.Gotham
    scoreText.TextXAlignment = Enum.TextXAlignment.Center
    scoreText.Parent = scoreFrame

    print("🎯 In-Game HUD Created Successfully!")
    return hudGui
end

-- Main execution
CleanupExistingUI()

wait(0.5) -- Brief pause for cleanup

print("🚀 Generating optimized UI for 1920x1080...")

local mainMenu = CreateMainMenuUI()
local gameHUD = CreateInGameHUD()

print("✅ FPS System UI Generation Complete!")
print("🎮 Created optimized UIs:")
print("  - FPSMainMenu (Properly positioned for 1920x1080)")
print("  - FPSHUD (Radar in top-left, proper scaling)")
print("📺 All elements positioned for 1920x1080 display")
print("🗑️ You can now delete this generator script.")