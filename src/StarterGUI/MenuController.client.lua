local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for FPS System to load
repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local VotingSystem = require(ReplicatedStorage.FPSSystem.Modules.VotingSystem)
local ArmorySystem = require(ReplicatedStorage.FPSSystem.Modules.ArmorySystem)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI to be created (will be created by UIGenerator)
repeat wait() until playerGui:FindFirstChild("FPSMainMenu")

local mainMenu = playerGui.FPSMainMenu
local menuFrame = mainMenu.MainContainer
local particleContainer = mainMenu.MainContainer.BackgroundParticles

-- Menu sections and navigation buttons will be set up in Initialize function
local sections = {}
local navButtons = {}
local backButtons = {}

-- Current section tracking
local currentSection = "MainSection"

-- Player data cache
local playerData = {
    level = 1,
    credits = 1000,
    xp = 0,
    nextLevelXP = 1500,
    kills = 0,
    deaths = 0,
    kdr = 0,
    currentWeaponPool = {},
    unlockedWeapons = {},
    currentLoadout = {}
}

-- Animation settings
local transitionInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Menu controller
local MenuController = {}

function MenuController:PlayClickSound()
    -- Placeholder for click sound - will be replaced with actual sound ID
    local clickSound = Instance.new("Sound")
    clickSound.SoundId = "rbxassetid://535716488" -- Temporary click sound
    clickSound.Volume = 0.5
    clickSound.Parent = SoundService
    clickSound:Play()
    
    clickSound.Ended:Connect(function()
        clickSound:Destroy()
    end)
end

function MenuController:AnimateButtonHover(button, isHovering)
    -- Remove size animation to prevent layout breaking
    -- Only animate transparency for hover effect
    local targetTransparency = isHovering and 0.05 or 0.1

    local transparencyTween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = targetTransparency})
    transparencyTween:Play()

    -- Optional: Add subtle glow effect instead of scaling
    local uiStroke = button:FindFirstChild("UIStroke")
    if uiStroke then
        local glowTween = TweenService:Create(uiStroke, TweenInfo.new(0.2), {
            Transparency = isHovering and 0.3 or 0.5
        })
        glowTween:Play()
    end
end

function MenuController:UpdatePlayerInfo()
    -- Update player info in top bar
    local topBar = menuFrame.MenuPanel.TopBar
    local playerInfo = topBar.PlayerInfo

    playerInfo.PlayerName.Text = player.Name:upper()
    playerInfo.PlayerLevel.Text = "LVL " .. playerData.level
    playerInfo.PlayerCredits.Text = playerData.credits .. " CR"
end

function MenuController:LoadPlayerData()
    -- Request player data from server
    RemoteEventsManager:InvokeServer("GetPlayerData", player)
    -- This would populate playerData table with server response

    -- For now, use default values and update UI
    self:UpdatePlayerInfo()
end

function MenuController:InitializeVotingSystem()
    -- Initialize voting system and connect UI buttons
    VotingSystem:Initialize()

    -- Connect voting buttons from the GamemodeVoting panel
    local votingFrame = sections.MainSection:FindFirstChild("GamemodeVoting")
    if votingFrame then
        local voteButtons = {}
        for _, child in pairs(votingFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("Vote") then
                table.insert(voteButtons, child)
            end
        end

        -- Connect vote button events
        for i, button in pairs(voteButtons) do
            button.MouseButton1Click:Connect(function()
                local gamemodes = {"TDM", "KOTH", "KC"} -- Matches VotingSystem gamemode codes
                local gamemodeNames = {"Team Deathmatch", "King of the Hill", "Kill Confirmed"}
                local selectedGamemode = gamemodes[i]
                local selectedName = gamemodeNames[i]

                if selectedGamemode then
                    -- Connect to VotingSystem for actual voting
                    local voteEvent = RemoteEventsManager:GetEvent("VoteForGamemode")
                    if voteEvent then
                        voteEvent:FireServer(selectedGamemode)
                    end

                    -- Don't update button text locally - let server handle vote tracking
                    self:PlayClickSound()
                    print("Voted for gamemode:", selectedName)
                end
            end)
        end
    end
end

function MenuController:SwitchToSection(targetSectionName)
    if currentSection == targetSectionName then return end
    
    self:PlayClickSound()
    
    local currentSectionFrame = sections[currentSection]
    local targetSectionFrame = sections[targetSectionName]
    
    -- Hide current section
    local hideCurrentTween = TweenService:Create(currentSectionFrame, transitionInfo, {
        Position = UDim2.fromScale(-1, 0),
        BackgroundTransparency = 1
    })
    
    -- Show target section
    targetSectionFrame.Position = UDim2.fromScale(1, 0)
    targetSectionFrame.Visible = true
    
    local showTargetTween = TweenService:Create(targetSectionFrame, transitionInfo, {
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 0.1
    })
    
    hideCurrentTween:Play()
    showTargetTween:Play()
    
    hideCurrentTween.Completed:Connect(function()
        currentSectionFrame.Visible = false
        currentSectionFrame.Position = UDim2.fromScale(0, 0)
    end)
    
    currentSection = targetSectionName
end

function MenuController:InitializeNavigation()
    print("MenuController: Initializing Navigation...")

    -- Debug: Check if navigation buttons exist
    print("Navigation Buttons Check:")
    for buttonName, button in pairs(navButtons) do
        print("  " .. buttonName .. ":", button and "✓" or "✗")
        if not button then
            print("    Expected at:", "menuFrame.MenuPanel.NavigationFrame." .. buttonName:gsub("Button", ""):upper() .. "Button")
        end
    end

    -- Main section navigation - Updated button names
    if navButtons.deployButton then
        navButtons.deployButton.MouseButton1Click:Connect(function()
            self:PlayClickSound()
            -- Simple deploy logic without unwanted deploy menu
            RemoteEventsManager:InvokeServer("DeployPlayer", player)
            print("Deploying to battlefield...")
        end)
        print("✓ Deploy button connected")
    else
        warn("✗ Deploy button not found!")
    end

    if navButtons.armoryButton then
        navButtons.armoryButton.MouseButton1Click:Connect(function()
            self:SwitchToSection("ArmorySection")
            self:InitializeArmoryTabs()
        end)
        print("✓ Armory button connected")
    else
        warn("✗ Armory button not found!")
    end

    if navButtons.shopButton then
        navButtons.shopButton.MouseButton1Click:Connect(function()
            self:SwitchToSection("ShopSection")
        end)
        print("✓ Shop button connected")
    else
        warn("✗ Shop button not found!")
    end

    if navButtons.leaderboardButton then
        navButtons.leaderboardButton.MouseButton1Click:Connect(function()
            self:SwitchToSection("LeaderboardSection")
        end)
        print("✓ Leaderboard button connected")
    else
        warn("✗ Leaderboard button not found!")
    end

    if navButtons.settingsButton then
        navButtons.settingsButton.MouseButton1Click:Connect(function()
            self:SwitchToSection("SettingsSection")
        end)
        print("✓ Settings button connected")
    else
        warn("✗ Settings button not found!")
    end

    -- Back button navigation
    print("Back Buttons Check:")
    for sectionName, backButton in pairs(backButtons) do
        if backButton then
            backButton.MouseButton1Click:Connect(function()
                self:SwitchToSection("MainSection")
            end)
            print("  " .. sectionName .. " back button: ✓")
        else
            print("  " .. sectionName .. " back button: ✗")
        end
    end
end

function MenuController:InitializeButtonHovers()
    -- Main navigation buttons
    for buttonName, button in pairs(navButtons) do
        button.MouseEnter:Connect(function()
            self:AnimateButtonHover(button, true)
        end)
        
        button.MouseLeave:Connect(function()
            self:AnimateButtonHover(button, false)
        end)
    end
    
    -- Back buttons
    for sectionName, backButton in pairs(backButtons) do
        backButton.MouseEnter:Connect(function()
            self:AnimateButtonHover(backButton, true)
        end)
        
        backButton.MouseLeave:Connect(function()
            self:AnimateButtonHover(backButton, false)
        end)
    end
end

function MenuController:InitializeParticleSystem()
    -- Particle animation system
    local particles = {}
    local particleCount = 50
    
    for i = 1, particleCount do
        local particle = Instance.new("Frame")
        particle.Name = "Particle" .. i
        particle.Size = UDim2.fromOffset(2, 2)
        particle.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        particle.BorderSizePixel = 0
        particle.Position = UDim2.fromScale(math.random(), math.random())
        particle.Parent = particleContainer
        
        particles[i] = {
            frame = particle,
            velocity = Vector2.new((math.random() - 0.5) * 0.01, (math.random() - 0.5) * 0.01),
            alpha = math.random()
        }
    end
    
    -- Animate particles
    spawn(function()
        while mainMenu.Parent do
            for i, particle in pairs(particles) do
                local currentPos = particle.frame.Position
                local newX = currentPos.X.Scale + particle.velocity.X
                local newY = currentPos.Y.Scale + particle.velocity.Y
                
                -- Wrap around screen
                if newX > 1 then newX = 0 end
                if newX < 0 then newX = 1 end
                if newY > 1 then newY = 0 end
                if newY < 0 then newY = 1 end
                
                particle.frame.Position = UDim2.fromScale(newX, newY)
                
                -- Animate alpha
                particle.alpha = particle.alpha + 0.02
                local alpha = (math.sin(particle.alpha) + 1) / 2
                particle.frame.BackgroundTransparency = 1 - (alpha * 0.3)
            end
            
            wait(0.03)
        end
    end)
end

function MenuController:HandleMenuToggle()
    -- ESC key to toggle menu
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            mainMenu.Enabled = not mainMenu.Enabled

            if mainMenu.Enabled then
                -- Return to main section when opening menu
                if currentSection ~= "MainSection" then
                    self:SwitchToSection("MainSection")
                end
            end
        end
    end)
end

function MenuController:Initialize()
    print("MenuController: Initializing...")

    -- Debug: Check if UI elements exist
    print("Debug - UI Structure Check:")
    print("  FPSMainMenu:", playerGui:FindFirstChild("FPSMainMenu") and "✓" or "✗")
    print("  MainContainer:", mainMenu and mainMenu:FindFirstChild("MainContainer") and "✓" or "✗")
    print("  MenuPanel:", menuFrame and menuFrame:FindFirstChild("MenuPanel") and "✓" or "✗")

    if menuFrame and menuFrame:FindFirstChild("MenuPanel") then
        local menuPanel = menuFrame.MenuPanel
        print("  NavigationFrame:", menuPanel:FindFirstChild("NavigationFrame") and "✓" or "✗")
        print("  SectionsContainer:", menuPanel:FindFirstChild("SectionsContainer") and "✓" or "✗")

        -- Set up navigation buttons now that UI is confirmed to exist
        if menuPanel:FindFirstChild("NavigationFrame") then
            local navigationFrame = menuPanel.NavigationFrame
            navButtons.deployButton = navigationFrame:FindFirstChild("DEPLOYButton")
            navButtons.armoryButton = navigationFrame:FindFirstChild("ARMORYButton")
            navButtons.shopButton = navigationFrame:FindFirstChild("SHOPButton")
            navButtons.leaderboardButton = navigationFrame:FindFirstChild("LEADERBOARDButton")
            navButtons.settingsButton = navigationFrame:FindFirstChild("SETTINGSButton")

            print("  DEPLOYButton:", navButtons.deployButton and "✓" or "✗")
            print("  ARMORYButton:", navButtons.armoryButton and "✓" or "✗")
            print("  SHOPButton:", navButtons.shopButton and "✓" or "✗")
            print("  LEADERBOARDButton:", navButtons.leaderboardButton and "✓" or "✗")
            print("  SETTINGSButton:", navButtons.settingsButton and "✓" or "✗")
        end

        if menuPanel:FindFirstChild("SectionsContainer") then
            local sectionsContainer = menuPanel.SectionsContainer

            -- Set up sections references
            sections.MainSection = sectionsContainer:FindFirstChild("MainSection")
            sections.ArmorySection = sectionsContainer:FindFirstChild("ArmorySection")
            sections.ShopSection = sectionsContainer:FindFirstChild("ShopSection")
            sections.LeaderboardSection = sectionsContainer:FindFirstChild("LeaderboardSection")
            sections.StatisticsSection = sectionsContainer:FindFirstChild("StatisticsSection")
            sections.SettingsSection = sectionsContainer:FindFirstChild("SettingsSection")

            print("  MainSection:", sections.MainSection and "✓" or "✗")
            print("  ArmorySection:", sections.ArmorySection and "✓" or "✗")
            print("  ShopSection:", sections.ShopSection and "✓" or "✗")
            print("  LeaderboardSection:", sections.LeaderboardSection and "✓" or "✗")
            print("  StatisticsSection:", sections.StatisticsSection and "✓" or "✗")
            print("  SettingsSection:", sections.SettingsSection and "✓" or "✗")

            -- Set up back buttons in each section
            for sectionName, section in pairs(sections) do
                if section then
                    local backBtn = section:FindFirstChild("BackButton")
                    if backBtn then
                        backButtons[sectionName] = backBtn
                    end
                end
            end
        end
    else
        warn("MenuController: MenuPanel not found! UI may not have been generated properly.")
        return
    end

    -- Initialize FPS System modules with error handling
    local success, error = pcall(function()
        RemoteEventsManager:Initialize()
        WeaponConfig:Initialize()
    end)

    if not success then
        warn("Failed to initialize FPS System modules:", error)
    end

    -- Load player data
    self:LoadPlayerData()

    -- Initialize all systems with error handling
    local initSuccess, initError = pcall(function()
        self:InitializeNavigation()
        self:InitializeButtonHovers()
        self:InitializeParticleSystem()
        self:HandleMenuToggle()
        self:InitializeVotingSystem()
    end)

    if not initSuccess then
        warn("Failed to initialize menu systems:", initError)
    end

    -- Start with main menu visible
    mainMenu.Enabled = true

    print("MenuController: Ready!")
end

-- Armory tab management
function MenuController:InitializeArmoryTabs()
    print("MenuController: Initializing Armory Tabs...")

    local armorySection = sections.ArmorySection
    if not armorySection then
        warn("ArmorySection not found!")
        return
    end
    print("✓ ArmorySection found")

    -- Find attachment tabs frame from the UI generator
    local attachmentTabsFrame = armorySection:FindFirstChild("AttachmentTabs")
    if not attachmentTabsFrame then
        warn("AttachmentTabs not found in ArmorySection!")
        print("Available children in ArmorySection:")
        for _, child in pairs(armorySection:GetChildren()) do
            print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
        return
    end
    print("✓ AttachmentTabs found")

    -- Get tab buttons
    local tabButtons = {
        ATTACHMENTS = attachmentTabsFrame:FindFirstChild("ATTACHMENTSTab"),
        PERKS = attachmentTabsFrame:FindFirstChild("PERKSTab"),
        SKINS = attachmentTabsFrame:FindFirstChild("SKINSTab"),
        WEAPONS = attachmentTabsFrame:FindFirstChild("WEAPONSTab")
    }

    -- Debug tab buttons
    for tabName, tabButton in pairs(tabButtons) do
        print("  " .. tabName .. "Tab:", tabButton and "✓" or "✗")
    end

    -- Initialize tab content areas if they don't exist
    self:CreateArmoryTabContent(armorySection)

    -- Connect tab button events
    for tabName, tabButton in pairs(tabButtons) do
        if tabButton then
            tabButton.MouseButton1Click:Connect(function()
                self:SwitchArmoryTab(tabName)
                self:PlayClickSound()
            end)
        end
    end

    -- Start with WEAPONS tab active
    self:SwitchArmoryTab("WEAPONS")
end

function MenuController:CreateArmoryTabContent(armorySection)
    -- Load ArmorySystem, PerkSystem, and AttachmentManager
    local ArmorySystem = require(ReplicatedStorage.FPSSystem.Modules.ArmorySystem)
    local PerkSystem = require(ReplicatedStorage.FPSSystem.Modules.PerkSystem)
    local AttachmentManager = require(ReplicatedStorage.FPSSystem.Modules.AttachmentManager)
    ArmorySystem:Initialize()
    PerkSystem:Initialize()
    AttachmentManager:Initialize()

    -- Create content container for armory tabs
    local tabContentContainer = armorySection:FindFirstChild("TabContentContainer")
    if not tabContentContainer then
        tabContentContainer = Instance.new("Frame")
        tabContentContainer.Name = "TabContentContainer"
        tabContentContainer.Size = UDim2.new(1, 0, 1, -40)
        tabContentContainer.Position = UDim2.new(0, 0, 0, 40)
        tabContentContainer.BackgroundTransparency = 1
        tabContentContainer.Parent = armorySection
    end

    -- Create individual tab content frames
    local tabContents = {"ATTACHMENTS", "PERKS", "SKINS", "WEAPONS"}
    for _, tabName in ipairs(tabContents) do
        local contentFrame = tabContentContainer:FindFirstChild(tabName .. "Content")
        if not contentFrame then
            contentFrame = Instance.new("Frame")
            contentFrame.Name = tabName .. "Content"
            contentFrame.Size = UDim2.new(1, 0, 1, 0)
            contentFrame.BackgroundTransparency = 1
            contentFrame.Visible = false
            contentFrame.Parent = tabContentContainer

            -- Create specific content based on tab type
            if tabName == "WEAPONS" then
                self:CreateWeaponsContent(contentFrame, ArmorySystem)
            elseif tabName == "PERKS" then
                self:CreatePerksContent(contentFrame, PerkSystem)
            elseif tabName == "ATTACHMENTS" then
                self:CreateAttachmentsContent(contentFrame, AttachmentManager, ArmorySystem)
            else
                -- Add placeholder content for other tabs
                local placeholder = Instance.new("TextLabel")
                placeholder.Name = "Placeholder"
                placeholder.Size = UDim2.new(1, 0, 1, 0)
                placeholder.BackgroundTransparency = 1
                placeholder.Text = tabName .. " Content\n(Under Development)"
                placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
                placeholder.TextSize = 18
                placeholder.Font = Enum.Font.Gotham
                placeholder.Parent = contentFrame
            end
        end
    end
end

function MenuController:SwitchArmoryTab(targetTab)
    local armorySection = sections.ArmorySection
    if not armorySection then return end

    local attachmentTabsFrame = armorySection:FindFirstChild("AttachmentTabs")
    local tabContentContainer = armorySection:FindFirstChild("TabContentContainer")
    if not attachmentTabsFrame or not tabContentContainer then return end

    -- Update tab button appearances
    for _, child in pairs(attachmentTabsFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name:find("Tab") then
            if child.Name == targetTab .. "Tab" then
                child.BackgroundColor3 = Color3.fromRGB(0, 206, 209) -- Active tab color
                child.BackgroundTransparency = 0.1
            else
                child.BackgroundColor3 = Color3.fromRGB(60, 100, 140) -- Inactive tab color
                child.BackgroundTransparency = 0.3
            end
        end
    end

    -- Show/hide content frames
    for _, child in pairs(tabContentContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Content") then
            child.Visible = (child.Name == targetTab .. "Content")
        end
    end

    print("Switched to armory tab:", targetTab)
end

function MenuController:CreateWeaponsContent(contentFrame, ArmorySystem)
    -- Create class selector
    local classSelector = Instance.new("Frame")
    classSelector.Name = "ClassSelector"
    classSelector.Size = UDim2.new(1, 0, 0, 35)
    classSelector.BackgroundTransparency = 1
    classSelector.Parent = contentFrame

    local classLabel = Instance.new("TextLabel")
    classLabel.Name = "ClassLabel"
    classLabel.Size = UDim2.new(0, 80, 1, 0)
    classLabel.Position = UDim2.new(0, 5, 0, 0)
    classLabel.BackgroundTransparency = 1
    classLabel.Text = "CLASS:"
    classLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    classLabel.TextSize = 12
    classLabel.Font = Enum.Font.Gotham
    classLabel.TextXAlignment = Enum.TextXAlignment.Left
    classLabel.Parent = classSelector

    local availableClasses = ArmorySystem:GetAvailableClasses()
    local currentClass = ArmorySystem:GetPlayerClass()
    local classIndex = 1

    for className, classInfo in pairs(availableClasses) do
        local classButton = Instance.new("TextButton")
        classButton.Name = className .. "Class"
        classButton.Size = UDim2.new(0, 80, 0, 25)
        classButton.Position = UDim2.new(0, 85 + (classIndex - 1) * 85, 0, 5)
        classButton.BackgroundColor3 = className == currentClass and Color3.fromRGB(0, 206, 209) or Color3.fromRGB(80, 80, 80)
        classButton.BackgroundTransparency = 0.2
        classButton.Text = classInfo.displayName
        classButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        classButton.TextSize = 11
        classButton.Font = Enum.Font.Gotham
        classButton.BorderSizePixel = 0
        classButton.Parent = classSelector

        local classCorner = Instance.new("UICorner")
        classCorner.CornerRadius = UDim.new(0, 3)
        classCorner.Parent = classButton

        classButton.MouseButton1Click:Connect(function()
            ArmorySystem:SetPlayerClass(className)
            self:RefreshWeaponsDisplay()
            self:PlayClickSound()
        end)

        classIndex = classIndex + 1
    end

    -- Create weapon category filter buttons
    local categoryFilter = Instance.new("Frame")
    categoryFilter.Name = "CategoryFilter"
    categoryFilter.Size = UDim2.new(1, 0, 0, 40)
    categoryFilter.Position = UDim2.new(0, 0, 0, 40)
    categoryFilter.BackgroundTransparency = 1
    categoryFilter.Parent = contentFrame

    local categories = {"Primary", "Secondary", "Melee", "Grenade"}
    local currentCategory = "Primary"

    for i, category in ipairs(categories) do
        local categoryButton = Instance.new("TextButton")
        categoryButton.Name = category .. "Filter"
        categoryButton.Size = UDim2.new(0.25, -5, 1, 0)
        categoryButton.Position = UDim2.new((i-1) * 0.25, 2, 0, 0)
        categoryButton.BackgroundColor3 = category == currentCategory and Color3.fromRGB(0, 206, 209) or Color3.fromRGB(60, 100, 140)
        categoryButton.BackgroundTransparency = 0.2
        categoryButton.Text = category
        categoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        categoryButton.TextSize = 14
        categoryButton.Font = Enum.Font.Gotham
        categoryButton.BorderSizePixel = 0
        categoryButton.Parent = categoryFilter

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 4)
        uiCorner.Parent = categoryButton
    end

    -- Create main content area
    local mainContent = Instance.new("Frame")
    mainContent.Name = "MainContent"
    mainContent.Size = UDim2.new(1, 0, 1, -90)
    mainContent.Position = UDim2.new(0, 0, 0, 90)
    mainContent.BackgroundTransparency = 1
    mainContent.Parent = contentFrame

    -- Create weapon list (left side)
    local weaponList = Instance.new("ScrollingFrame")
    weaponList.Name = "WeaponList"
    weaponList.Size = UDim2.new(0.35, -10, 1, 0)
    weaponList.Position = UDim2.new(0, 5, 0, 0)
    weaponList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    weaponList.BackgroundTransparency = 0.3
    weaponList.BorderSizePixel = 0
    weaponList.ScrollBarThickness = 8
    weaponList.Parent = mainContent

    local weaponListCorner = Instance.new("UICorner")
    weaponListCorner.CornerRadius = UDim.new(0, 6)
    weaponListCorner.Parent = weaponList

    local weaponListLayout = Instance.new("UIListLayout")
    weaponListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    weaponListLayout.Padding = UDim.new(0, 2)
    weaponListLayout.Parent = weaponList

    -- Create weapon preview area (right side)
    local previewArea = Instance.new("Frame")
    previewArea.Name = "PreviewArea"
    previewArea.Size = UDim2.new(0.65, -10, 1, 0)
    previewArea.Position = UDim2.new(0.35, 5, 0, 0)
    previewArea.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    previewArea.BackgroundTransparency = 0.2
    previewArea.BorderSizePixel = 0
    previewArea.Parent = mainContent

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 6)
    previewCorner.Parent = previewArea

    -- Create 3D viewport
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "WeaponViewport"
    viewport.Size = UDim2.new(1, -20, 0.6, -10)
    viewport.Position = UDim2.new(0, 10, 0, 10)
    viewport.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    viewport.BackgroundTransparency = 0.1
    viewport.BorderSizePixel = 0
    viewport.Parent = previewArea

    local viewportCorner = Instance.new("UICorner")
    viewportCorner.CornerRadius = UDim.new(0, 4)
    viewportCorner.Parent = viewport

    -- Create camera for viewport
    local camera = Instance.new("Camera")
    viewport.CurrentCamera = camera

    -- Create stats display
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -20, 0.4, -10)
    statsFrame.Position = UDim2.new(0, 10, 0.6, 5)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = previewArea

    -- Store references for updating
    local weaponData = {
        categoryFilter = categoryFilter,
        weaponList = weaponList,
        viewport = viewport,
        camera = camera,
        statsFrame = statsFrame,
        currentCategory = currentCategory,
        selectedWeapon = nil
    }

    -- Connect category filter events
    for _, child in pairs(categoryFilter:GetChildren()) do
        if child:IsA("TextButton") then
            child.MouseButton1Click:Connect(function()
                local category = child.Name:gsub("Filter", "")
                self:UpdateWeaponCategory(weaponData, ArmorySystem, category)
                self:PlayClickSound()
            end)
        end
    end

    -- Initialize with primary weapons
    self:UpdateWeaponCategory(weaponData, ArmorySystem, currentCategory)
end

function MenuController:UpdateWeaponCategory(weaponData, ArmorySystem, category)
    -- Update category filter appearance
    for _, child in pairs(weaponData.categoryFilter:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Name == category .. "Filter" then
                child.BackgroundColor3 = Color3.fromRGB(0, 206, 209)
                child.BackgroundTransparency = 0.1
            else
                child.BackgroundColor3 = Color3.fromRGB(60, 100, 140)
                child.BackgroundTransparency = 0.3
            end
        end
    end

    weaponData.currentCategory = category

    -- Clear weapon list
    for _, child in pairs(weaponData.weaponList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Get weapons for category
    local weapons = ArmorySystem:GetWeaponsByCategory(category)
    local layoutOrder = 1

    for _, weaponInfo in pairs(weapons) do
        local weapon = weaponInfo.data
        local unlocked = weaponInfo.unlocked
        local selected = weaponInfo.selected
        local subcategory = weaponInfo.subcategory

        -- Create weapon button
        local weaponButton = Instance.new("Frame")
        weaponButton.Name = weapon.name .. "Button"
        weaponButton.Size = UDim2.new(1, -10, 0, 70)
        weaponButton.BackgroundColor3 = selected and Color3.fromRGB(0, 206, 209) or (unlocked and Color3.fromRGB(50, 80, 120) or Color3.fromRGB(80, 50, 50))
        weaponButton.BackgroundTransparency = selected and 0.1 or 0.3
        weaponButton.BorderSizePixel = 0
        weaponButton.LayoutOrder = layoutOrder
        weaponButton.Parent = weaponData.weaponList

        local weaponCorner = Instance.new("UICorner")
        weaponCorner.CornerRadius = UDim.new(0, 4)
        weaponCorner.Parent = weaponButton

        -- Weapon name
        local weaponName = Instance.new("TextLabel")
        weaponName.Name = "WeaponName"
        weaponName.Size = UDim2.new(1, -10, 0.5, 0)
        weaponName.Position = UDim2.new(0, 5, 0, 0)
        weaponName.BackgroundTransparency = 1
        weaponName.Text = weapon.displayName or weapon.name
        weaponName.TextColor3 = unlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        weaponName.TextSize = 13
        weaponName.Font = Enum.Font.Gotham
        weaponName.TextXAlignment = Enum.TextXAlignment.Left
        weaponName.Parent = weaponButton

        -- Subcategory label
        local subcategoryLabel = Instance.new("TextLabel")
        subcategoryLabel.Name = "SubcategoryLabel"
        subcategoryLabel.Size = UDim2.new(1, -10, 0.25, 0)
        subcategoryLabel.Position = UDim2.new(0, 5, 0.5, 0)
        subcategoryLabel.BackgroundTransparency = 1
        subcategoryLabel.Text = subcategory or weapon.category or ""
        subcategoryLabel.TextColor3 = unlocked and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(120, 120, 120)
        subcategoryLabel.TextSize = 10
        subcategoryLabel.Font = Enum.Font.Gotham
        subcategoryLabel.TextXAlignment = Enum.TextXAlignment.Left
        subcategoryLabel.Parent = weaponButton

        -- Lock status or requirement
        local statusText = Instance.new("TextLabel")
        statusText.Name = "StatusText"
        statusText.Size = UDim2.new(1, -10, 0.25, 0)
        statusText.Position = UDim2.new(0, 5, 0.75, 0)
        statusText.BackgroundTransparency = 1
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusText.TextSize = 11
        statusText.Font = Enum.Font.Gotham
        statusText.TextXAlignment = Enum.TextXAlignment.Left
        statusText.Parent = weaponButton

        if unlocked then
            statusText.Text = selected and "EQUIPPED" or "AVAILABLE"
            statusText.TextColor3 = selected and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
        else
            local reqText = "Lvl " .. (weapon.level or 0)
            if weapon.credits and weapon.credits > 0 then
                reqText = reqText .. " | " .. weapon.credits .. " CR"
            end
            statusText.Text = reqText
            statusText.TextColor3 = Color3.fromRGB(255, 150, 150)
        end

        -- Make clickable if unlocked
        if unlocked then
            local clickButton = Instance.new("TextButton")
            clickButton.Name = "ClickButton"
            clickButton.Size = UDim2.new(1, 0, 1, 0)
            clickButton.BackgroundTransparency = 1
            clickButton.Text = ""
            clickButton.Parent = weaponButton

            clickButton.MouseButton1Click:Connect(function()
                self:SelectWeapon(weaponData, ArmorySystem, category, weapon.name)
                self:PlayClickSound()
            end)
        end

        layoutOrder = layoutOrder + 1
    end

    -- Update canvas size (increased for taller buttons)
    weaponData.weaponList.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 72)

    -- Select first available weapon if none selected
    if not weaponData.selectedWeapon and #weapons > 0 then
        for _, weaponInfo in pairs(weapons) do
            if weaponInfo.unlocked then
                self:SelectWeapon(weaponData, ArmorySystem, category, weaponInfo.data.name)
                break
            end
        end
    end
end

function MenuController:SelectWeapon(weaponData, ArmorySystem, category, weaponName)
    weaponData.selectedWeapon = weaponName

    -- Update weapon list selection appearance
    for _, child in pairs(weaponData.weaponList:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Button") then
            local isSelected = child.Name == weaponName .. "Button"
            child.BackgroundColor3 = isSelected and Color3.fromRGB(0, 206, 209) or Color3.fromRGB(50, 80, 120)
            child.BackgroundTransparency = isSelected and 0.1 or 0.3

            local statusText = child:FindFirstChild("StatusText")
            if statusText and isSelected then
                statusText.Text = "SELECTED"
                statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
            elseif statusText then
                statusText.Text = "AVAILABLE"
                statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end

    -- Update 3D viewport
    self:Update3DWeaponPreview(weaponData, category, weaponName)

    -- Update stats display
    self:UpdateWeaponStats(weaponData, ArmorySystem, category, weaponName)

    -- Select weapon in armory system
    ArmorySystem:SelectWeapon(category, weaponName)
end

function MenuController:Update3DWeaponPreview(weaponData, category, weaponName, equippedAttachments)
    -- Clear viewport
    weaponData.viewport:ClearAllChildren()

    -- Create new camera
    local camera = Instance.new("Camera")
    weaponData.viewport.CurrentCamera = camera
    weaponData.camera = camera

    -- Get weapon data and subcategory from ArmorySystem
    local weapon, subCategory = ArmorySystem:GetWeaponData(category, weaponName)
    if not weapon or not subCategory then
        warn("Could not find weapon data for:", category, weaponName)
        return
    end

    -- Load weapon model using ArmorySystem path
    local modelPath = ArmorySystem:GetWeaponModelPath(category, weaponName)

    local success, weaponModel = pcall(function()
        return game:GetService("ReplicatedStorage").FPSSystem.WeaponModels[category][subCategory][weaponName]:Clone()
    end)

    if success and weaponModel then
        weaponModel.Parent = weaponData.viewport

        -- Apply equipped attachments to the weapon model
        if equippedAttachments then
            self:ApplyAttachmentsToWeaponModel(weaponModel, equippedAttachments)
        end

        -- Position camera based on weapon type
        local cameraPositions = {
            Primary = CFrame.new(2, 0, 2) * CFrame.Angles(0, math.rad(45), 0),
            Secondary = CFrame.new(1.5, 0, 1.5) * CFrame.Angles(0, math.rad(45), 0),
            Melee = CFrame.new(1, 0, 1) * CFrame.Angles(0, math.rad(45), 0),
            Grenade = CFrame.new(0.5, 0, 0.5) * CFrame.Angles(0, math.rad(45), 0)
        }

        camera.CFrame = cameraPositions[category] or cameraPositions.Primary

        -- Add rotation animation
        spawn(function()
            local startTime = tick()
            while weaponModel.Parent do
                local elapsed = tick() - startTime
                weaponModel.CFrame = CFrame.Angles(0, elapsed * 0.5, 0)
                wait(0.03)
            end
        end)

        -- Store reference for attachment previewing
        weaponData.currentWeaponModel = weaponModel
    else
        -- Create placeholder if model not found
        local placeholder = Instance.new("TextLabel")
        placeholder.Size = UDim2.new(1, 0, 1, 0)
        placeholder.BackgroundTransparency = 1
        placeholder.Text = weaponName .. "\\nModel Not Found"
        placeholder.TextColor3 = Color3.fromRGB(150, 150, 150)
        placeholder.TextSize = 16
        placeholder.Font = Enum.Font.Gotham
        placeholder.Parent = weaponData.viewport
    end
end

function MenuController:ApplyAttachmentsToWeaponModel(weaponModel, attachments)
    -- Clear existing attachment models
    self:ClearAttachmentModels(weaponModel)

    -- Attachment point mapping based on the structure you showed
    local attachmentPoints = {
        Optics = {"AimPoint", "Scope1", "Scope2"}, -- Try multiple possible points
        Barrel = {"MuzzlePoint", "Muzzle"},
        Underbarrel = {"LeftGripPoint", "RightGripPoint", "Mount"},
        Other = {"LeftGripPoint", "RightGripPoint", "Mount", "Switch"} -- Lasers, flashlights, etc.
    }

    for category, attachmentId in pairs(attachments) do
        if attachmentId and attachmentId ~= "" then
            local attachmentModel = self:LoadAttachmentModel(attachmentId)
            if attachmentModel then
                self:AttachToWeapon(weaponModel, attachmentModel, category, attachmentPoints[category])
            end
        end
    end
end

function MenuController:ClearAttachmentModels(weaponModel)
    -- Remove existing attachment models
    local attachmentsFolder = weaponModel:FindFirstChild("AttachedModels")
    if attachmentsFolder then
        attachmentsFolder:Destroy()
    end
end

function MenuController:LoadAttachmentModel(attachmentId)
    -- Try to load attachment model from various possible locations
    local possiblePaths = {
        "ReplicatedStorage.FPSSystem.AttachmentModels." .. attachmentId,
        "ReplicatedStorage.FPSSystem.Attachments." .. attachmentId,
        "ReplicatedStorage.FPSSystem.Models.Attachments." .. attachmentId
    }

    for _, path in ipairs(possiblePaths) do
        local success, model = pcall(function()
            local pathParts = path:split(".")
            local current = game:GetService("ReplicatedStorage")
            for i = 2, #pathParts do
                current = current:FindFirstChild(pathParts[i])
                if not current then return nil end
            end
            return current:Clone()
        end)

        if success and model then
            return model
        end
    end

    -- Create placeholder attachment model if none found
    return self:CreatePlaceholderAttachment(attachmentId)
end

function MenuController:CreatePlaceholderAttachment(attachmentId)
    local placeholder = Instance.new("Part")
    placeholder.Name = attachmentId .. "_Placeholder"
    placeholder.Size = Vector3.new(0.5, 0.2, 0.2)
    placeholder.Color = Color3.fromRGB(100, 100, 100)
    placeholder.Material = Enum.Material.Metal
    placeholder.CanCollide = false

    -- Add a simple label to identify the attachment
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Top
    gui.Parent = placeholder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = attachmentId
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 8
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.Parent = gui

    return placeholder
end

function MenuController:AttachToWeapon(weaponModel, attachmentModel, category, possiblePoints)
    -- Create attachments folder if it doesn't exist
    local attachmentsFolder = weaponModel:FindFirstChild("AttachedModels")
    if not attachmentsFolder then
        attachmentsFolder = Instance.new("Folder")
        attachmentsFolder.Name = "AttachedModels"
        attachmentsFolder.Parent = weaponModel
    end

    -- Find the best attachment point
    local attachmentPoint = nil
    for _, pointName in ipairs(possiblePoints) do
        attachmentPoint = self:FindAttachmentPoint(weaponModel, pointName)
        if attachmentPoint then
            break
        end
    end

    if not attachmentPoint then
        -- Create a default attachment point if none found
        attachmentPoint = Instance.new("Attachment")
        attachmentPoint.Name = "DefaultAttachPoint"

        -- Position based on category
        if category == "Optics" then
            attachmentPoint.CFrame = CFrame.new(0, 0.2, -0.5)
        elseif category == "Barrel" then
            attachmentPoint.CFrame = CFrame.new(0, 0, -1)
        elseif category == "Underbarrel" then
            attachmentPoint.CFrame = CFrame.new(0, -0.2, -0.3)
        else -- Other
            attachmentPoint.CFrame = CFrame.new(0.2, 0, -0.3)
        end

        -- Find the main weapon part to attach to
        local mainPart = weaponModel:FindFirstChild("Handle") or
                        weaponModel:FindFirstChildWhichIsA("Part") or
                        weaponModel:FindFirstChildWhichIsA("MeshPart")

        if mainPart then
            attachmentPoint.Parent = mainPart
        else
            warn("Could not find main part in weapon model:", weaponModel.Name)
            return
        end
    end

    -- Position the attachment model
    attachmentModel.Parent = attachmentsFolder

    -- Create weld or motor to attach the model
    local weld = Instance.new("WeldConstraint")

    -- Find the main parts to weld
    local weaponPart = attachmentPoint.Parent
    local attachmentPart = attachmentModel:FindFirstChildWhichIsA("BasePart")

    if weaponPart and attachmentPart then
        -- Position the attachment at the attachment point
        attachmentPart.CFrame = weaponPart.CFrame * attachmentPoint.CFrame

        -- Create the weld
        weld.Part0 = weaponPart
        weld.Part1 = attachmentPart
        weld.Parent = attachmentPart

        print("Attached", attachmentModel.Name, "to", weaponModel.Name, "at", attachmentPoint.Name)
    else
        warn("Could not weld attachment", attachmentModel.Name, "to weapon", weaponModel.Name)
    end
end

function MenuController:FindAttachmentPoint(weaponModel, pointName)
    -- Recursively search for attachment point
    local function searchForAttachment(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Attachment") and child.Name == pointName then
                return child
            elseif child:IsA("BasePart") or child:IsA("Model") then
                local found = searchForAttachment(child)
                if found then return found end
            end
        end
        return nil
    end

    return searchForAttachment(weaponModel)
end

function MenuController:PreviewAttachmentOnWeapon(weaponData, attachmentId, category)
    -- Create a temporary attachment preview
    if not weaponData.currentWeaponModel then return end

    -- Remove previous preview
    local previewFolder = weaponData.currentWeaponModel:FindFirstChild("PreviewAttachment")
    if previewFolder then
        previewFolder:Destroy()
    end

    -- Create preview folder
    previewFolder = Instance.new("Folder")
    previewFolder.Name = "PreviewAttachment"
    previewFolder.Parent = weaponData.currentWeaponModel

    -- Load and attach preview
    local attachmentModel = self:LoadAttachmentModel(attachmentId)
    if attachmentModel then
        attachmentModel.Parent = previewFolder

        -- Make it slightly transparent to show it's a preview
        local function makeTransparent(obj)
            if obj:IsA("BasePart") then
                obj.Transparency = 0.3
            end
            for _, child in pairs(obj:GetChildren()) do
                makeTransparent(child)
            end
        end
        makeTransparent(attachmentModel)

        -- Attach it temporarily
        local attachmentPoints = {
            Optics = {"AimPoint", "Scope1", "Scope2"},
            Barrel = {"MuzzlePoint", "Muzzle"},
            Underbarrel = {"LeftGripPoint", "RightGripPoint", "Mount"},
            Other = {"LeftGripPoint", "RightGripPoint", "Mount", "Switch"}
        }

        self:AttachToWeapon(weaponData.currentWeaponModel, attachmentModel, category, attachmentPoints[category])
    end
end

function MenuController:ClearAttachmentPreview(weaponModel)
    -- Remove preview attachment
    local previewFolder = weaponModel:FindFirstChild("PreviewAttachment")
    if previewFolder then
        previewFolder:Destroy()
    end
end

function MenuController:EquipAttachmentToWeapon(attachmentData, AttachmentManager, weaponName, slotName, attachmentId)
    -- This would normally interface with the AttachmentManager to save the equipped attachment
    -- For now, we'll simulate this by storing it in the UI data
    if not attachmentData.equippedAttachments then
        attachmentData.equippedAttachments = {}
    end
    if not attachmentData.equippedAttachments[weaponName] then
        attachmentData.equippedAttachments[weaponName] = {}
    end

    attachmentData.equippedAttachments[weaponName][slotName] = attachmentId
    return true, "Attachment equipped successfully"
end

function MenuController:UpdateWeaponPreviewWithAttachments(attachmentData, AttachmentManager, weaponName)
    -- Get equipped attachments for this weapon
    local equippedAttachments = {}
    if attachmentData.equippedAttachments and attachmentData.equippedAttachments[weaponName] then
        equippedAttachments = attachmentData.equippedAttachments[weaponName]
    end

    -- Update the weapon preview to show equipped attachments
    if attachmentData.currentWeaponModel then
        self:ApplyAttachmentsToWeaponModel(attachmentData.currentWeaponModel, equippedAttachments)
    end
end

function MenuController:UpdateWeaponStats(weaponData, ArmorySystem, category, weaponName)
    -- Clear stats frame
    for _, child in pairs(weaponData.statsFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    -- Create layout if it doesn't exist
    if not weaponData.statsFrame:FindFirstChild("UIListLayout") then
        local statsLayout = Instance.new("UIListLayout")
        statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        statsLayout.Padding = UDim.new(0, 4)
        statsLayout.Parent = weaponData.statsFrame
    end

    -- Get weapon data
    local weaponData = ArmorySystem:GetWeaponData(category, weaponName)
    if not weaponData or not weaponData.stats then return end

    -- Create title
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Name = "StatsTitle"
    statsTitle.Size = UDim2.new(1, 0, 0, 25)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "WEAPON STATISTICS"
    statsTitle.TextColor3 = Color3.fromRGB(0, 206, 209)
    statsTitle.TextSize = 14
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.LayoutOrder = 0
    statsTitle.Parent = weaponData.statsFrame

    -- Category-specific stats display
    local statOrder = 1
    local stats = weaponData.stats

    if category == "Primary" or category == "Secondary" then
        self:CreateStatBar(weaponData.statsFrame, "DAMAGE", stats.damage or 0, 100, statOrder)
        self:CreateStatBar(weaponData.statsFrame, "RANGE", stats.range or 0, 100, statOrder + 1)
        self:CreateStatBar(weaponData.statsFrame, "ACCURACY", stats.accuracy or 0, 100, statOrder + 2)
        self:CreateStatBar(weaponData.statsFrame, "FIRE RATE", (stats.fireRate or 0) / 10, 100, statOrder + 3)
        self:CreateStatBar(weaponData.statsFrame, "MOBILITY", stats.mobility or 0, 100, statOrder + 4)
        self:CreateStatBar(weaponData.statsFrame, "CONTROL", stats.control or 0, 100, statOrder + 5)
    elseif category == "Melee" then
        self:CreateStatBar(weaponData.statsFrame, "DAMAGE", stats.damage or 0, 100, statOrder)
        self:CreateStatBar(weaponData.statsFrame, "SPEED", stats.speed or 0, 100, statOrder + 1)
        self:CreateStatBar(weaponData.statsFrame, "RANGE", stats.range or 0, 10, statOrder + 2)
        self:CreateStatBar(weaponData.statsFrame, "BACKSTAB", stats.backstabDamage or 0, 100, statOrder + 3)
        self:CreateStatBar(weaponData.statsFrame, "MOBILITY", stats.mobility or 0, 100, statOrder + 4)
    elseif category == "Grenade" then
        self:CreateStatBar(weaponData.statsFrame, "DAMAGE", stats.damage or 0, 150, statOrder)
        self:CreateStatBar(weaponData.statsFrame, "BLAST RADIUS", (stats.blastRadius or 0) * 5, 100, statOrder + 1)
        self:CreateStatBar(weaponData.statsFrame, "THROW DISTANCE", (stats.throwDistance or 0) * 2, 100, statOrder + 2)
        if stats.fuseTime then
            self:CreateStatBar(weaponData.statsFrame, "FUSE TIME", (5 - stats.fuseTime) * 20, 100, statOrder + 3)
        end
    end
end

function MenuController:CreateStatBar(parent, statName, value, maxValue, layoutOrder)
    local statFrame = Instance.new("Frame")
    statFrame.Name = statName .. "Stat"
    statFrame.Size = UDim2.new(1, 0, 0, 20)
    statFrame.BackgroundTransparency = 1
    statFrame.LayoutOrder = layoutOrder
    statFrame.Parent = parent

    local statLabel = Instance.new("TextLabel")
    statLabel.Name = "StatLabel"
    statLabel.Size = UDim2.new(0.4, 0, 1, 0)
    statLabel.BackgroundTransparency = 1
    statLabel.Text = statName
    statLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statLabel.TextSize = 12
    statLabel.Font = Enum.Font.Gotham
    statLabel.TextXAlignment = Enum.TextXAlignment.Left
    statLabel.Parent = statFrame

    local statBarBG = Instance.new("Frame")
    statBarBG.Name = "StatBarBG"
    statBarBG.Size = UDim2.new(0.55, -5, 0.7, 0)
    statBarBG.Position = UDim2.new(0.4, 5, 0.15, 0)
    statBarBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    statBarBG.BorderSizePixel = 0
    statBarBG.Parent = statFrame

    local statBarBGCorner = Instance.new("UICorner")
    statBarBGCorner.CornerRadius = UDim.new(0, 2)
    statBarBGCorner.Parent = statBarBG

    local statBar = Instance.new("Frame")
    statBar.Name = "StatBar"
    statBar.Size = UDim2.new(math.min(value / maxValue, 1), 0, 1, 0)
    statBar.BackgroundColor3 = Color3.fromRGB(0, 206, 209)
    statBar.BorderSizePixel = 0
    statBar.Parent = statBarBG

    local statBarCorner = Instance.new("UICorner")
    statBarCorner.CornerRadius = UDim.new(0, 2)
    statBarCorner.Parent = statBar

    local statValue = Instance.new("TextLabel")
    statValue.Name = "StatValue"
    statValue.Size = UDim2.new(0.05, 0, 1, 0)
    statValue.Position = UDim2.new(0.95, 0, 0, 0)
    statValue.BackgroundTransparency = 1
    statValue.Text = tostring(math.floor(value))
    statValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    statValue.TextSize = 12
    statValue.Font = Enum.Font.Gotham
    statValue.TextXAlignment = Enum.TextXAlignment.Center
    statValue.Parent = statFrame
end

function MenuController:CreatePerksContent(contentFrame, PerkSystem)
    -- Create perk category filter buttons
    local categoryFilter = Instance.new("Frame")
    categoryFilter.Name = "CategoryFilter"
    categoryFilter.Size = UDim2.new(1, 0, 0, 40)
    categoryFilter.BackgroundTransparency = 1
    categoryFilter.Parent = contentFrame

    local categories = {"Movement", "Combat", "Utility"}
    local currentCategory = "Movement"

    for i, category in ipairs(categories) do
        local categoryButton = Instance.new("TextButton")
        categoryButton.Name = category .. "Filter"
        categoryButton.Size = UDim2.new(0.33, -5, 1, 0)
        categoryButton.Position = UDim2.new((i-1) * 0.33, 2, 0, 0)
        categoryButton.BackgroundColor3 = category == currentCategory and Color3.fromRGB(0, 206, 209) or Color3.fromRGB(60, 100, 140)
        categoryButton.BackgroundTransparency = 0.2
        categoryButton.Text = category
        categoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        categoryButton.TextSize = 14
        categoryButton.Font = Enum.Font.Gotham
        categoryButton.BorderSizePixel = 0
        categoryButton.Parent = categoryFilter

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 4)
        uiCorner.Parent = categoryButton
    end

    -- Create main content area
    local mainContent = Instance.new("Frame")
    mainContent.Name = "MainContent"
    mainContent.Size = UDim2.new(1, 0, 1, -50)
    mainContent.Position = UDim2.new(0, 0, 0, 50)
    mainContent.BackgroundTransparency = 1
    mainContent.Parent = contentFrame

    -- Create perk list (left side)
    local perkList = Instance.new("ScrollingFrame")
    perkList.Name = "PerkList"
    perkList.Size = UDim2.new(0.35, -10, 1, 0)
    perkList.Position = UDim2.new(0, 5, 0, 0)
    perkList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    perkList.BackgroundTransparency = 0.3
    perkList.BorderSizePixel = 0
    perkList.ScrollBarThickness = 8
    perkList.Parent = mainContent

    local perkListCorner = Instance.new("UICorner")
    perkListCorner.CornerRadius = UDim.new(0, 6)
    perkListCorner.Parent = perkList

    local perkListLayout = Instance.new("UIListLayout")
    perkListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    perkListLayout.Padding = UDim.new(0, 2)
    perkListLayout.Parent = perkList

    -- Create perk details area (right side)
    local detailsArea = Instance.new("Frame")
    detailsArea.Name = "DetailsArea"
    detailsArea.Size = UDim2.new(0.65, -10, 1, 0)
    detailsArea.Position = UDim2.new(0.35, 5, 0, 0)
    detailsArea.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    detailsArea.BackgroundTransparency = 0.2
    detailsArea.BorderSizePixel = 0
    detailsArea.Parent = mainContent

    local detailsCorner = Instance.new("UICorner")
    detailsCorner.CornerRadius = UDim.new(0, 6)
    detailsCorner.Parent = detailsArea

    -- Create perk info display
    local perkInfoFrame = Instance.new("Frame")
    perkInfoFrame.Name = "PerkInfoFrame"
    perkInfoFrame.Size = UDim2.new(1, -20, 0.6, -10)
    perkInfoFrame.Position = UDim2.new(0, 10, 0, 10)
    perkInfoFrame.BackgroundTransparency = 1
    perkInfoFrame.Parent = detailsArea

    -- Create equipped perks display (bottom)
    local equippedFrame = Instance.new("Frame")
    equippedFrame.Name = "EquippedFrame"
    equippedFrame.Size = UDim2.new(1, -20, 0.4, -10)
    equippedFrame.Position = UDim2.new(0, 10, 0.6, 5)
    equippedFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    equippedFrame.BackgroundTransparency = 0.1
    equippedFrame.BorderSizePixel = 0
    equippedFrame.Parent = detailsArea

    local equippedCorner = Instance.new("UICorner")
    equippedCorner.CornerRadius = UDim.new(0, 4)
    equippedCorner.Parent = equippedFrame

    local equippedTitle = Instance.new("TextLabel")
    equippedTitle.Name = "EquippedTitle"
    equippedTitle.Size = UDim2.new(1, 0, 0, 25)
    equippedTitle.Position = UDim2.new(0, 5, 0, 5)
    equippedTitle.BackgroundTransparency = 1
    equippedTitle.Text = "EQUIPPED PERKS"
    equippedTitle.TextColor3 = Color3.fromRGB(0, 206, 209)
    equippedTitle.TextSize = 14
    equippedTitle.Font = Enum.Font.GothamBold
    equippedTitle.TextXAlignment = Enum.TextXAlignment.Left
    equippedTitle.Parent = equippedFrame

    -- Store references for updating
    local perkData = {
        categoryFilter = categoryFilter,
        perkList = perkList,
        perkInfoFrame = perkInfoFrame,
        equippedFrame = equippedFrame,
        currentCategory = currentCategory,
        selectedPerk = nil
    }

    -- Connect category filter events
    for _, child in pairs(categoryFilter:GetChildren()) do
        if child:IsA("TextButton") then
            child.MouseButton1Click:Connect(function()
                local category = child.Name:gsub("Filter", "")
                self:UpdatePerkCategory(perkData, PerkSystem, category)
                self:PlayClickSound()
            end)
        end
    end

    -- Initialize with movement perks
    self:UpdatePerkCategory(perkData, PerkSystem, currentCategory)
    self:UpdateEquippedPerks(perkData, PerkSystem)
end

function MenuController:UpdatePerkCategory(perkData, PerkSystem, category)
    -- Update category filter appearance
    for _, child in pairs(perkData.categoryFilter:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Name == category .. "Filter" then
                child.BackgroundColor3 = Color3.fromRGB(0, 206, 209)
                child.BackgroundTransparency = 0.1
            else
                child.BackgroundColor3 = Color3.fromRGB(60, 100, 140)
                child.BackgroundTransparency = 0.3
            end
        end
    end

    perkData.currentCategory = category

    -- Clear perk list
    for _, child in pairs(perkData.perkList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Get perks for category
    local perks = PerkSystem:GetPerksByCategory(category)
    local layoutOrder = 1

    for _, perkInfo in pairs(perks) do
        local perk = perkInfo.data
        local unlocked = perkInfo.unlocked
        local equipped = perkInfo.equipped
        local onCooldown = perkInfo.onCooldown

        -- Create perk button
        local perkButton = Instance.new("Frame")
        perkButton.Name = perk.id .. "Button"
        perkButton.Size = UDim2.new(1, -10, 0, 80)
        perkButton.BackgroundColor3 = equipped and Color3.fromRGB(0, 206, 209) or (unlocked and Color3.fromRGB(50, 80, 120) or Color3.fromRGB(80, 50, 50))
        perkButton.BackgroundTransparency = equipped and 0.1 or 0.3
        perkButton.BorderSizePixel = 0
        perkButton.LayoutOrder = layoutOrder
        perkButton.Parent = perkData.perkList

        local perkCorner = Instance.new("UICorner")
        perkCorner.CornerRadius = UDim.new(0, 4)
        perkCorner.Parent = perkButton

        -- Perk icon placeholder
        local perkIcon = Instance.new("Frame")
        perkIcon.Name = "PerkIcon"
        perkIcon.Size = UDim2.new(0, 50, 0, 50)
        perkIcon.Position = UDim2.new(0, 5, 0, 5)
        perkIcon.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        perkIcon.BorderSizePixel = 0
        perkIcon.Parent = perkButton

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 4)
        iconCorner.Parent = perkIcon

        local iconPlaceholder = Instance.new("TextLabel")
        iconPlaceholder.Size = UDim2.new(1, 0, 1, 0)
        iconPlaceholder.BackgroundTransparency = 1
        iconPlaceholder.Text = "?"
        iconPlaceholder.TextColor3 = Color3.fromRGB(200, 200, 200)
        iconPlaceholder.TextSize = 20
        iconPlaceholder.Font = Enum.Font.GothamBold
        iconPlaceholder.Parent = perkIcon

        -- Perk name
        local perkName = Instance.new("TextLabel")
        perkName.Name = "PerkName"
        perkName.Size = UDim2.new(1, -65, 0, 25)
        perkName.Position = UDim2.new(0, 60, 0, 5)
        perkName.BackgroundTransparency = 1
        perkName.Text = perk.displayName
        perkName.TextColor3 = unlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        perkName.TextSize = 14
        perkName.Font = Enum.Font.Gotham
        perkName.TextXAlignment = Enum.TextXAlignment.Left
        perkName.TextYAlignment = Enum.TextYAlignment.Top
        perkName.Parent = perkButton

        -- Perk type and cooldown
        local perkType = Instance.new("TextLabel")
        perkType.Name = "PerkType"
        perkType.Size = UDim2.new(1, -65, 0, 15)
        perkType.Position = UDim2.new(0, 60, 0, 25)
        perkType.BackgroundTransparency = 1
        perkType.Text = perk.type:upper() .. (perk.cooldown > 0 and " | " .. perk.cooldown .. "s CD" or "")
        perkType.TextColor3 = Color3.fromRGB(180, 180, 180)
        perkType.TextSize = 11
        perkType.Font = Enum.Font.Gotham
        perkType.TextXAlignment = Enum.TextXAlignment.Left
        perkType.TextYAlignment = Enum.TextYAlignment.Top
        perkType.Parent = perkButton

        -- Status text (unlock requirements or equipped status)
        local statusText = Instance.new("TextLabel")
        statusText.Name = "StatusText"
        statusText.Size = UDim2.new(1, -65, 0, 15)
        statusText.Position = UDim2.new(0, 60, 0, 45)
        statusText.BackgroundTransparency = 1
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusText.TextSize = 11
        statusText.Font = Enum.Font.Gotham
        statusText.TextXAlignment = Enum.TextXAlignment.Left
        statusText.TextYAlignment = Enum.TextYAlignment.Top
        statusText.Parent = perkButton

        if unlocked then
            if equipped then
                statusText.Text = "EQUIPPED"
                statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
            elseif onCooldown then
                local cooldownTime = PerkSystem:GetPerkCooldownTime(perk.id)
                statusText.Text = "COOLDOWN: " .. math.ceil(cooldownTime) .. "s"
                statusText.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                statusText.Text = "AVAILABLE"
                statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        else
            statusText.Text = "Lvl " .. perk.level .. " | " .. perk.credits .. " CR"
            statusText.TextColor3 = Color3.fromRGB(255, 150, 150)
        end

        -- Make clickable
        local clickButton = Instance.new("TextButton")
        clickButton.Name = "ClickButton"
        clickButton.Size = UDim2.new(1, 0, 1, 0)
        clickButton.BackgroundTransparency = 1
        clickButton.Text = ""
        clickButton.Parent = perkButton

        clickButton.MouseButton1Click:Connect(function()
            self:SelectPerk(perkData, PerkSystem, perk.id)
            self:PlayClickSound()
        end)

        layoutOrder = layoutOrder + 1
    end

    -- Update canvas size
    perkData.perkList.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 82)

    -- Select first perk if none selected
    if not perkData.selectedPerk and #perks > 0 then
        self:SelectPerk(perkData, PerkSystem, perks[1].data.id)
    end
end

function MenuController:SelectPerk(perkData, PerkSystem, perkId)
    perkData.selectedPerk = perkId

    -- Update perk list selection appearance
    for _, child in pairs(perkData.perkList:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Button") then
            local isSelected = child.Name == perkId .. "Button"
            if isSelected then
                local uiStroke = child:FindFirstChild("UIStroke")
                if not uiStroke then
                    uiStroke = Instance.new("UIStroke")
                    uiStroke.Color = Color3.fromRGB(0, 206, 209)
                    uiStroke.Thickness = 2
                    uiStroke.Parent = child
                end
            else
                local uiStroke = child:FindFirstChild("UIStroke")
                if uiStroke then
                    uiStroke:Destroy()
                end
            end
        end
    end

    -- Update perk info display
    self:UpdatePerkInfo(perkData, PerkSystem, perkId)
end

function MenuController:UpdatePerkInfo(perkData, PerkSystem, perkId)
    -- Clear perk info frame
    for _, child in pairs(perkData.perkInfoFrame:GetChildren()) do
        child:Destroy()
    end

    local perk = PerkSystem:GetPerkData(perkId)
    if not perk then return end

    local unlocked = PerkSystem:IsPerkUnlocked(perkId)
    local equipped = PerkSystem:IsPerkEquipped(perkId)
    local onCooldown = PerkSystem:IsPerkOnCooldown(perkId)

    -- Create perk title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = perk.displayName:upper()
    title.TextColor3 = Color3.fromRGB(0, 206, 209)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = perkData.perkInfoFrame

    -- Create perk description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 35)
    description.BackgroundTransparency = 1
    description.Text = perk.description
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.TextSize = 14
    description.Font = Enum.Font.Gotham
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.TextWrapped = true
    description.Parent = perkData.perkInfoFrame

    -- Create perk details
    local detailsY = 85
    local details = {
        {"TYPE", perk.type:upper()},
        {"CATEGORY", perk.category:upper()},
        {"LEVEL REQ", "Level " .. perk.level},
        {"COST", perk.credits .. " Credits"}
    }

    if perk.cooldown and perk.cooldown > 0 then
        table.insert(details, {"COOLDOWN", perk.cooldown .. " seconds"})
    end

    if perk.duration then
        table.insert(details, {"DURATION", perk.duration .. " seconds"})
    end

    for i, detail in ipairs(details) do
        local detailLabel = Instance.new("TextLabel")
        detailLabel.Name = "Detail" .. i
        detailLabel.Size = UDim2.new(0.5, 0, 0, 20)
        detailLabel.Position = UDim2.new(((i-1) % 2) * 0.5, 0, 0, detailsY + math.floor((i-1) / 2) * 25)
        detailLabel.BackgroundTransparency = 1
        detailLabel.Text = detail[1] .. ": " .. detail[2]
        detailLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        detailLabel.TextSize = 12
        detailLabel.Font = Enum.Font.Gotham
        detailLabel.TextXAlignment = Enum.TextXAlignment.Left
        detailLabel.Parent = perkData.perkInfoFrame
    end

    -- Create action buttons
    local buttonY = detailsY + math.ceil(#details / 2) * 25 + 10

    if not unlocked then
        -- Unlock button
        local unlockButton = Instance.new("TextButton")
        unlockButton.Name = "UnlockButton"
        unlockButton.Size = UDim2.new(0.4, -5, 0, 30)
        unlockButton.Position = UDim2.new(0, 0, 0, buttonY)
        unlockButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
        unlockButton.Text = "UNLOCK"
        unlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        unlockButton.TextSize = 14
        unlockButton.Font = Enum.Font.GothamBold
        unlockButton.BorderSizePixel = 0
        unlockButton.Parent = perkData.perkInfoFrame

        local unlockCorner = Instance.new("UICorner")
        unlockCorner.CornerRadius = UDim.new(0, 4)
        unlockCorner.Parent = unlockButton

        unlockButton.MouseButton1Click:Connect(function()
            local success, message = PerkSystem:UnlockPerk(perkId)
            print(message)
            if success then
                self:UpdatePerkCategory(perkData, PerkSystem, perkData.currentCategory)
                self:UpdatePerkInfo(perkData, PerkSystem, perkId)
            end
            self:PlayClickSound()
        end)
    else
        -- Equip/Unequip button
        local equipButton = Instance.new("TextButton")
        equipButton.Name = "EquipButton"
        equipButton.Size = UDim2.new(0.4, -5, 0, 30)
        equipButton.Position = UDim2.new(0, 0, 0, buttonY)
        equipButton.BackgroundColor3 = equipped and Color3.fromRGB(150, 100, 100) or Color3.fromRGB(100, 150, 100)
        equipButton.Text = equipped and "UNEQUIP" or "EQUIP"
        equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        equipButton.TextSize = 14
        equipButton.Font = Enum.Font.GothamBold
        equipButton.BorderSizePixel = 0
        equipButton.Parent = perkData.perkInfoFrame

        local equipCorner = Instance.new("UICorner")
        equipCorner.CornerRadius = UDim.new(0, 4)
        equipCorner.Parent = equipButton

        equipButton.MouseButton1Click:Connect(function()
            local success, message
            if equipped then
                success, message = PerkSystem:UnequipPerk(perkId)
            else
                success, message = PerkSystem:EquipPerk(perkId)
            end
            print(message)
            if success then
                self:UpdatePerkCategory(perkData, PerkSystem, perkData.currentCategory)
                self:UpdateEquippedPerks(perkData, PerkSystem)
                self:UpdatePerkInfo(perkData, PerkSystem, perkId)
            end
            self:PlayClickSound()
        end)

        -- Activate button (for active perks)
        if perk.type == "active" and equipped then
            local activateButton = Instance.new("TextButton")
            activateButton.Name = "ActivateButton"
            activateButton.Size = UDim2.new(0.4, -5, 0, 30)
            activateButton.Position = UDim2.new(0.5, 5, 0, buttonY)
            activateButton.BackgroundColor3 = onCooldown and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(150, 100, 150)
            activateButton.Text = onCooldown and ("CD: " .. math.ceil(PerkSystem:GetPerkCooldownTime(perkId)) .. "s") or "ACTIVATE"
            activateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            activateButton.TextSize = 14
            activateButton.Font = Enum.Font.GothamBold
            activateButton.BorderSizePixel = 0
            activateButton.Active = not onCooldown
            activateButton.Parent = perkData.perkInfoFrame

            local activateCorner = Instance.new("UICorner")
            activateCorner.CornerRadius = UDim.new(0, 4)
            activateCorner.Parent = activateButton

            if not onCooldown then
                activateButton.MouseButton1Click:Connect(function()
                    local success, message = PerkSystem:ActivatePerk(perkId)
                    print(message)
                    if success then
                        self:UpdatePerkInfo(perkData, PerkSystem, perkId)
                    end
                    self:PlayClickSound()
                end)
            end
        end
    end
end

function MenuController:UpdateEquippedPerks(perkData, PerkSystem)
    -- Clear equipped perks display
    for _, child in pairs(perkData.equippedFrame:GetChildren()) do
        if not child.Name:find("Title") then
            child:Destroy()
        end
    end

    local equippedPerks = PerkSystem:GetEquippedPerks()
    local yPos = 30

    for category, perk in pairs(equippedPerks) do
        if perk then
            local equippedPerk = Instance.new("Frame")
            equippedPerk.Name = category .. "Equipped"
            equippedPerk.Size = UDim2.new(1, -10, 0, 25)
            equippedPerk.Position = UDim2.new(0, 5, 0, yPos)
            equippedPerk.BackgroundTransparency = 1
            equippedPerk.Parent = perkData.equippedFrame

            local categoryLabel = Instance.new("TextLabel")
            categoryLabel.Size = UDim2.new(0.3, 0, 1, 0)
            categoryLabel.BackgroundTransparency = 1
            categoryLabel.Text = category:upper() .. ":"
            categoryLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            categoryLabel.TextSize = 12
            categoryLabel.Font = Enum.Font.Gotham
            categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
            categoryLabel.Parent = equippedPerk

            local perkLabel = Instance.new("TextLabel")
            perkLabel.Size = UDim2.new(0.7, 0, 1, 0)
            perkLabel.Position = UDim2.new(0.3, 0, 0, 0)
            perkLabel.BackgroundTransparency = 1
            perkLabel.Text = perk.displayName
            perkLabel.TextColor3 = Color3.fromRGB(0, 206, 209)
            perkLabel.TextSize = 12
            perkLabel.Font = Enum.Font.Gotham
            perkLabel.TextXAlignment = Enum.TextXAlignment.Left
            perkLabel.Parent = equippedPerk

            yPos = yPos + 30
        end
    end

    if yPos == 30 then
        local noPerks = Instance.new("TextLabel")
        noPerks.Size = UDim2.new(1, -10, 0, 25)
        noPerks.Position = UDim2.new(0, 5, 0, 30)
        noPerks.BackgroundTransparency = 1
        noPerks.Text = "No perks equipped"
        noPerks.TextColor3 = Color3.fromRGB(120, 120, 120)
        noPerks.TextSize = 12
        noPerks.Font = Enum.Font.Gotham
        noPerks.TextXAlignment = Enum.TextXAlignment.Left
        noPerks.Parent = perkData.equippedFrame
    end
end

function MenuController:CreateAttachmentsContent(contentFrame, AttachmentManager, ArmorySystem)
    -- Create weapon selector at top
    local weaponSelector = Instance.new("Frame")
    weaponSelector.Name = "WeaponSelector"
    weaponSelector.Size = UDim2.new(1, 0, 0, 50)
    weaponSelector.BackgroundTransparency = 1
    weaponSelector.Parent = contentFrame

    local selectorTitle = Instance.new("TextLabel")
    selectorTitle.Name = "SelectorTitle"
    selectorTitle.Size = UDim2.new(0.2, 0, 1, 0)
    selectorTitle.BackgroundTransparency = 1
    selectorTitle.Text = "SELECT WEAPON:"
    selectorTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    selectorTitle.TextSize = 14
    selectorTitle.Font = Enum.Font.GothamBold
    selectorTitle.TextXAlignment = Enum.TextXAlignment.Left
    selectorTitle.Parent = weaponSelector

    -- Create weapon dropdown buttons
    local weaponButtons = {}
    local availableWeapons = {"G36", "M9"} -- Only weapons that can have attachments
    local selectedWeapon = "G36"

    for i, weaponName in ipairs(availableWeapons) do
        local weaponButton = Instance.new("TextButton")
        weaponButton.Name = weaponName .. "Button"
        weaponButton.Size = UDim2.new(0.15, -5, 0.8, 0)
        weaponButton.Position = UDim2.new(0.2 + (i-1) * 0.2, 2, 0.1, 0)
        weaponButton.BackgroundColor3 = weaponName == selectedWeapon and Color3.fromRGB(0, 206, 209) or Color3.fromRGB(60, 100, 140)
        weaponButton.BackgroundTransparency = 0.2
        weaponButton.Text = weaponName
        weaponButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        weaponButton.TextSize = 14
        weaponButton.Font = Enum.Font.Gotham
        weaponButton.BorderSizePixel = 0
        weaponButton.Parent = weaponSelector

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = weaponButton

        weaponButtons[weaponName] = weaponButton
    end

    -- Create main content area
    local mainContent = Instance.new("Frame")
    mainContent.Name = "MainContent"
    mainContent.Size = UDim2.new(1, 0, 1, -60)
    mainContent.Position = UDim2.new(0, 0, 0, 60)
    mainContent.BackgroundTransparency = 1
    mainContent.Parent = contentFrame

    -- Create weapon preview section (top center)
    local previewSection = Instance.new("Frame")
    previewSection.Name = "PreviewSection"
    previewSection.Size = UDim2.new(0.6, -10, 0.4, -5)
    previewSection.Position = UDim2.new(0.4, 5, 0, 0)
    previewSection.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    previewSection.BackgroundTransparency = 0.2
    previewSection.BorderSizePixel = 0
    previewSection.Parent = mainContent

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 6)
    previewCorner.Parent = previewSection

    -- Create 3D viewport for weapon
    local weaponViewport = Instance.new("ViewportFrame")
    weaponViewport.Name = "WeaponViewport"
    weaponViewport.Size = UDim2.new(1, -10, 1, -10)
    weaponViewport.Position = UDim2.new(0, 5, 0, 5)
    weaponViewport.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    weaponViewport.BackgroundTransparency = 0.1
    weaponViewport.BorderSizePixel = 0
    weaponViewport.Parent = previewSection

    local viewportCorner = Instance.new("UICorner")
    viewportCorner.CornerRadius = UDim.new(0, 4)
    viewportCorner.Parent = weaponViewport

    -- Create camera for viewport
    local weaponCamera = Instance.new("Camera")
    weaponViewport.CurrentCamera = weaponCamera

    -- Create attachment slots section (left side)
    local slotsSection = Instance.new("Frame")
    slotsSection.Name = "SlotsSection"
    slotsSection.Size = UDim2.new(0.4, -10, 1, 0)
    slotsSection.Position = UDim2.new(0, 5, 0, 0)
    slotsSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    slotsSection.BackgroundTransparency = 0.3
    slotsSection.BorderSizePixel = 0
    slotsSection.Parent = mainContent

    local slotsCorner = Instance.new("UICorner")
    slotsCorner.CornerRadius = UDim.new(0, 6)
    slotsCorner.Parent = slotsSection

    local slotsTitle = Instance.new("TextLabel")
    slotsTitle.Name = "SlotsTitle"
    slotsTitle.Size = UDim2.new(1, 0, 0, 30)
    slotsTitle.Position = UDim2.new(0, 10, 0, 5)
    slotsTitle.BackgroundTransparency = 1
    slotsTitle.Text = "ATTACHMENT SLOTS"
    slotsTitle.TextColor3 = Color3.fromRGB(0, 206, 209)
    slotsTitle.TextSize = 16
    slotsTitle.Font = Enum.Font.GothamBold
    slotsTitle.TextXAlignment = Enum.TextXAlignment.Left
    slotsTitle.Parent = slotsSection

    -- Create available attachments section (bottom right)
    local availableSection = Instance.new("Frame")
    availableSection.Name = "AvailableSection"
    availableSection.Size = UDim2.new(0.6, -10, 0.6, -5)
    availableSection.Position = UDim2.new(0.4, 5, 0.4, 5)
    availableSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    availableSection.BackgroundTransparency = 0.2
    availableSection.BorderSizePixel = 0
    availableSection.Parent = mainContent

    local availableCorner = Instance.new("UICorner")
    availableCorner.CornerRadius = UDim.new(0, 6)
    availableCorner.Parent = availableSection

    local availableTitle = Instance.new("TextLabel")
    availableTitle.Name = "AvailableTitle"
    availableTitle.Size = UDim2.new(1, 0, 0, 30)
    availableTitle.Position = UDim2.new(0, 10, 0, 5)
    availableTitle.BackgroundTransparency = 1
    availableTitle.Text = "AVAILABLE ATTACHMENTS"
    availableTitle.TextColor3 = Color3.fromRGB(0, 206, 209)
    availableTitle.TextSize = 16
    availableTitle.Font = Enum.Font.GothamBold
    availableTitle.TextXAlignment = Enum.TextXAlignment.Left
    availableTitle.Parent = availableSection

    -- Store references
    local attachmentData = {
        weaponSelector = weaponSelector,
        weaponButtons = weaponButtons,
        slotsSection = slotsSection,
        availableSection = availableSection,
        weaponViewport = weaponViewport,
        weaponCamera = weaponCamera,
        selectedWeapon = selectedWeapon,
        selectedSlot = nil,
        currentWeaponModel = nil,
        equippedAttachments = {}
    }

    -- Connect weapon button events
    for weaponName, button in pairs(weaponButtons) do
        button.MouseButton1Click:Connect(function()
            self:SelectAttachmentWeapon(attachmentData, AttachmentManager, weaponName)
            self:PlayClickSound()
        end)
    end

    -- Initialize with G36
    self:SelectAttachmentWeapon(attachmentData, AttachmentManager, selectedWeapon)
end

function MenuController:SelectAttachmentWeapon(attachmentData, AttachmentManager, weaponName)
    attachmentData.selectedWeapon = weaponName

    -- Update weapon button appearances
    for name, button in pairs(attachmentData.weaponButtons) do
        if name == weaponName then
            button.BackgroundColor3 = Color3.fromRGB(0, 206, 209)
            button.BackgroundTransparency = 0.1
        else
            button.BackgroundColor3 = Color3.fromRGB(60, 100, 140)
            button.BackgroundTransparency = 0.3
        end
    end

    -- Update weapon preview
    self:UpdateAttachmentWeaponPreview(attachmentData, weaponName)

    -- Update attachment slots display
    self:UpdateAttachmentSlots(attachmentData, AttachmentManager, weaponName)

    -- Update available attachments display
    self:UpdateAvailableAttachments(attachmentData, AttachmentManager, weaponName, nil)
end

function MenuController:UpdateAttachmentWeaponPreview(attachmentData, weaponName)
    -- Clear viewport
    attachmentData.weaponViewport:ClearAllChildren()

    -- Load weapon model
    local weaponPath = "ReplicatedStorage.FPSSystem.WeaponModels"
    local categoryFolders = {
        G36 = "Primary.AssaultRifles",
        M9 = "Secondary.Pistols"
    }

    local modelPath = categoryFolders[weaponName]
    if not modelPath then return end

    local success, weaponModel = pcall(function()
        local pathParts = {"ReplicatedStorage", "FPSSystem", "WeaponModels"}
        for part in modelPath:gmatch("[^.]+") do
            table.insert(pathParts, part)
        end
        table.insert(pathParts, weaponName)

        local current = game:GetService("ReplicatedStorage")
        for i = 2, #pathParts do
            current = current:FindFirstChild(pathParts[i])
            if not current then return nil end
        end
        return current:Clone()
    end)

    if success and weaponModel then
        weaponModel.Parent = attachmentData.weaponViewport
        attachmentData.currentWeaponModel = weaponModel

        -- Apply equipped attachments
        local equippedAttachments = attachmentData.equippedAttachments[weaponName] or {}
        self:ApplyAttachmentsToWeaponModel(weaponModel, equippedAttachments)

        -- Position camera
        local cameraPosition = CFrame.new(2, 0, 2) * CFrame.Angles(0, math.rad(45), 0)
        if weaponName == "M9" then
            cameraPosition = CFrame.new(1.2, 0, 1.2) * CFrame.Angles(0, math.rad(45), 0)
        end
        attachmentData.weaponCamera.CFrame = cameraPosition

        -- Add rotation animation
        spawn(function()
            local startTime = tick()
            while weaponModel.Parent do
                local elapsed = tick() - startTime
                weaponModel.CFrame = CFrame.Angles(0, elapsed * 0.3, 0)
                wait(0.05)
            end
        end)
    else
        -- Create placeholder
        local placeholder = Instance.new("TextLabel")
        placeholder.Size = UDim2.new(1, 0, 1, 0)
        placeholder.BackgroundTransparency = 1
        placeholder.Text = weaponName .. "\nModel Not Found"
        placeholder.TextColor3 = Color3.fromRGB(150, 150, 150)
        placeholder.TextSize = 16
        placeholder.Font = Enum.Font.Gotham
        placeholder.Parent = attachmentData.weaponViewport
    end
end

function MenuController:UpdateAttachmentSlots(attachmentData, AttachmentManager, weaponName)
    local slotsSection = attachmentData.slotsSection

    -- Clear existing slots (except title)
    for _, child in pairs(slotsSection:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Slot") then
            child:Destroy()
        end
    end

    -- Get available attachment slots for this weapon
    local availableSlots = AttachmentManager:GetAvailableSlots(weaponName)
    local yPos = 40

    -- Define slot order and icons
    local slotOrder = {"Sight", "Barrel", "Underbarrel", "Other"}
    local slotIcons = {
        Sight = "👁",
        Barrel = "🔫",
        Underbarrel = "🔧",
        Other = "⚙"
    }

    for _, slotName in ipairs(slotOrder) do
        if availableSlots[slotName] then
            local slotFrame = Instance.new("Frame")
            slotFrame.Name = slotName .. "Slot"
            slotFrame.Size = UDim2.new(1, -20, 0, 80)
            slotFrame.Position = UDim2.new(0, 10, 0, yPos)
            slotFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            slotFrame.BackgroundTransparency = 0.3
            slotFrame.BorderSizePixel = 0
            slotFrame.Parent = slotsSection

            local slotCorner = Instance.new("UICorner")
            slotCorner.CornerRadius = UDim.new(0, 4)
            slotCorner.Parent = slotFrame

            -- Slot icon
            local slotIcon = Instance.new("TextLabel")
            slotIcon.Name = "SlotIcon"
            slotIcon.Size = UDim2.new(0, 40, 0, 40)
            slotIcon.Position = UDim2.new(0, 10, 0, 5)
            slotIcon.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            slotIcon.BorderSizePixel = 0
            slotIcon.Text = slotIcons[slotName] or "?"
            slotIcon.TextSize = 20
            slotIcon.Parent = slotFrame

            local iconCorner = Instance.new("UICorner")
            iconCorner.CornerRadius = UDim.new(0, 4)
            iconCorner.Parent = slotIcon

            -- Slot name
            local slotLabel = Instance.new("TextLabel")
            slotLabel.Name = "SlotLabel"
            slotLabel.Size = UDim2.new(1, -60, 0, 20)
            slotLabel.Position = UDim2.new(0, 55, 0, 5)
            slotLabel.BackgroundTransparency = 1
            slotLabel.Text = slotName:upper()
            slotLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            slotLabel.TextSize = 12
            slotLabel.Font = Enum.Font.GothamBold
            slotLabel.TextXAlignment = Enum.TextXAlignment.Left
            slotLabel.Parent = slotFrame

            -- Current attachment
            local currentAttachment = Instance.new("TextLabel")
            currentAttachment.Name = "CurrentAttachment"
            currentAttachment.Size = UDim2.new(1, -60, 0, 20)
            currentAttachment.Position = UDim2.new(0, 55, 0, 25)
            currentAttachment.BackgroundTransparency = 1
            currentAttachment.TextSize = 11
            currentAttachment.Font = Enum.Font.Gotham
            currentAttachment.TextXAlignment = Enum.TextXAlignment.Left
            currentAttachment.Parent = slotFrame

            -- Check if weapon has an equipped attachment in this slot
            local equippedAttachmentId = nil
            if attachmentData.equippedAttachments and
               attachmentData.equippedAttachments[weaponName] and
               attachmentData.equippedAttachments[weaponName][slotName] then
                equippedAttachmentId = attachmentData.equippedAttachments[weaponName][slotName]
            end

            if equippedAttachmentId then
                -- Get attachment config to show proper name
                local attachmentConfig = AttachmentManager:GetAttachmentConfig(equippedAttachmentId)
                if attachmentConfig then
                    currentAttachment.Text = attachmentConfig.Name
                    currentAttachment.TextColor3 = Color3.fromRGB(0, 206, 209)
                else
                    currentAttachment.Text = equippedAttachmentId
                    currentAttachment.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            else
                currentAttachment.Text = "None Equipped"
                currentAttachment.TextColor3 = Color3.fromRGB(150, 150, 150)
            end

            -- Make slot clickable
            local clickButton = Instance.new("TextButton")
            clickButton.Name = "ClickButton"
            clickButton.Size = UDim2.new(1, 0, 1, 0)
            clickButton.BackgroundTransparency = 1
            clickButton.Text = ""
            clickButton.Parent = slotFrame

            clickButton.MouseButton1Click:Connect(function()
                self:SelectAttachmentSlot(attachmentData, AttachmentManager, slotName)
                self:PlayClickSound()
            end)

            yPos = yPos + 90
        end
    end
end

function MenuController:SelectAttachmentSlot(attachmentData, AttachmentManager, slotName)
    local slotsSection = attachmentData.slotsSection
    attachmentData.selectedSlot = slotName

    -- Update slot selection appearance
    for _, child in pairs(slotsSection:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Slot") then
            local isSelected = child.Name == slotName .. "Slot"
            if isSelected then
                local uiStroke = child:FindFirstChild("UIStroke")
                if not uiStroke then
                    uiStroke = Instance.new("UIStroke")
                    uiStroke.Color = Color3.fromRGB(0, 206, 209)
                    uiStroke.Thickness = 2
                    uiStroke.Parent = child
                end
            else
                local uiStroke = child:FindFirstChild("UIStroke")
                if uiStroke then
                    uiStroke:Destroy()
                end
            end
        end
    end

    -- Update available attachments for this slot
    self:UpdateAvailableAttachments(attachmentData, AttachmentManager, attachmentData.selectedWeapon, slotName)
end

function MenuController:UpdateAvailableAttachments(attachmentData, AttachmentManager, weaponName, selectedSlot)
    local availableSection = attachmentData.availableSection

    -- Clear existing attachments (except title)
    for _, child in pairs(availableSection:GetChildren()) do
        if child:IsA("ScrollingFrame") or (child:IsA("Frame") and child.Name:find("Attachment")) then
            child:Destroy()
        end
    end

    if not selectedSlot then
        -- Show instruction text
        local instruction = Instance.new("TextLabel")
        instruction.Size = UDim2.new(1, -20, 1, -40)
        instruction.Position = UDim2.new(0, 10, 0, 40)
        instruction.BackgroundTransparency = 1
        instruction.Text = "Select an attachment slot to view available attachments"
        instruction.TextColor3 = Color3.fromRGB(120, 120, 120)
        instruction.TextSize = 14
        instruction.Font = Enum.Font.Gotham
        instruction.TextWrapped = true
        instruction.Parent = availableSection
        return
    end

    -- Create scrolling frame for attachments
    local attachmentList = Instance.new("ScrollingFrame")
    attachmentList.Name = "AttachmentList"
    attachmentList.Size = UDim2.new(1, -20, 1, -40)
    attachmentList.Position = UDim2.new(0, 10, 0, 40)
    attachmentList.BackgroundTransparency = 1
    attachmentList.BorderSizePixel = 0
    attachmentList.ScrollBarThickness = 8
    attachmentList.Parent = availableSection

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = attachmentList

    -- Get compatible attachments for this slot
    local slotCategory = AttachmentManager:GetAvailableSlots(weaponName)[selectedSlot]
    local compatibleAttachments = AttachmentManager:GetAttachmentsByCategory(slotCategory)

    local layoutOrder = 1

    for attachmentName, attachmentInfo in pairs(compatibleAttachments) do
        local config = attachmentInfo.Config
        local unlockReq = attachmentInfo.UnlockRequirement

        -- Create attachment button
        local attachmentButton = Instance.new("Frame")
        attachmentButton.Name = attachmentName .. "Attachment"
        attachmentButton.Size = UDim2.new(1, 0, 0, 100)
        attachmentButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        attachmentButton.BackgroundTransparency = 0.2
        attachmentButton.BorderSizePixel = 0
        attachmentButton.LayoutOrder = layoutOrder
        attachmentButton.Parent = attachmentList

        local attachmentCorner = Instance.new("UICorner")
        attachmentCorner.CornerRadius = UDim.new(0, 4)
        attachmentCorner.Parent = attachmentButton

        -- Attachment icon placeholder
        local attachmentIcon = Instance.new("Frame")
        attachmentIcon.Name = "AttachmentIcon"
        attachmentIcon.Size = UDim2.new(0, 60, 0, 60)
        attachmentIcon.Position = UDim2.new(0, 10, 0, 10)
        attachmentIcon.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        attachmentIcon.BorderSizePixel = 0
        attachmentIcon.Parent = attachmentButton

        local attachmentIconCorner = Instance.new("UICorner")
        attachmentIconCorner.CornerRadius = UDim.new(0, 4)
        attachmentIconCorner.Parent = attachmentIcon

        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(1, 0, 1, 0)
        iconText.BackgroundTransparency = 1
        iconText.Text = "📎" -- Attachment icon placeholder
        iconText.TextSize = 24
        iconText.Parent = attachmentIcon

        -- Attachment name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -85, 0, 25)
        nameLabel.Position = UDim2.new(0, 80, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = config.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = attachmentButton

        -- Attachment description
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "DescLabel"
        descLabel.Size = UDim2.new(1, -85, 0, 20)
        descLabel.Position = UDim2.new(0, 80, 0, 35)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = config.Description
        descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextWrapped = true
        descLabel.Parent = attachmentButton

        -- Unlock requirements
        local reqLabel = Instance.new("TextLabel")
        reqLabel.Name = "ReqLabel"
        reqLabel.Size = UDim2.new(1, -85, 0, 20)
        reqLabel.Position = UDim2.new(0, 80, 0, 55)
        reqLabel.BackgroundTransparency = 1
        reqLabel.Text = unlockReq.Kills .. " kills | " .. unlockReq.Cost .. " credits"
        reqLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        reqLabel.TextSize = 10
        reqLabel.Font = Enum.Font.Gotham
        reqLabel.TextXAlignment = Enum.TextXAlignment.Left
        reqLabel.Parent = attachmentButton

        -- Equip button
        local equipButton = Instance.new("TextButton")
        equipButton.Name = "EquipButton"
        equipButton.Size = UDim2.new(0, 60, 0, 25)
        equipButton.Position = UDim2.new(1, -70, 0, 75)
        equipButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        equipButton.Text = "EQUIP"
        equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        equipButton.TextSize = 11
        equipButton.Font = Enum.Font.GothamBold
        equipButton.BorderSizePixel = 0
        equipButton.Parent = attachmentButton

        local equipCorner = Instance.new("UICorner")
        equipCorner.CornerRadius = UDim.new(0, 3)
        equipCorner.Parent = equipButton

        equipButton.MouseButton1Click:Connect(function()
            -- Equip the attachment and update weapon preview
            local success, message = self:EquipAttachmentToWeapon(attachmentData, AttachmentManager, weaponName, selectedSlot, attachmentName)
            if success then
                print("Equipped", config.Name, "to", weaponName)
                self:UpdateAttachmentSlots(attachmentData, AttachmentManager, weaponName)
                self:UpdateWeaponPreviewWithAttachments(attachmentData, AttachmentManager, weaponName)
            else
                warn("Failed to equip attachment:", message)
            end
            self:PlayClickSound()
        end)

        -- Add hover preview functionality
        attachmentButton.MouseEnter:Connect(function()
            if attachmentData.currentWeaponModel then
                self:PreviewAttachmentOnWeapon(attachmentData.currentWeaponModel, attachmentName, selectedSlot)
            end
        end)

        attachmentButton.MouseLeave:Connect(function()
            if attachmentData.currentWeaponModel then
                self:ClearAttachmentPreview(attachmentData.currentWeaponModel)
            end
        end)

        layoutOrder = layoutOrder + 1
    end

    -- Update canvas size
    attachmentList.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 105)
end

-- Refresh the weapons display when class changes
function MenuController:RefreshWeaponsDisplay()
    local armorySection = sections.ArmorySection
    if not armorySection then return end

    local tabContentContainer = armorySection:FindFirstChild("TabContentContainer")
    if not tabContentContainer then return end

    local weaponsContent = tabContentContainer:FindFirstChild("WEAPONSContent")
    if not weaponsContent then return end

    -- Update class selector buttons
    local classSelector = weaponsContent:FindFirstChild("ClassSelector")
    if classSelector then
        local currentClass = ArmorySystem:GetPlayerClass()
        for _, child in pairs(classSelector:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("Class") then
                local className = child.Name:gsub("Class", "")
                child.BackgroundColor3 = className == currentClass and Color3.fromRGB(0, 206, 209) or Color3.fromRGB(80, 80, 80)
            end
        end
    end

    -- Refresh weapon list for current category
    local categoryFilter = weaponsContent:FindFirstChild("CategoryFilter")
    if categoryFilter then
        for _, child in pairs(categoryFilter:GetChildren()) do
            if child:IsA("TextButton") and child.BackgroundColor3 == Color3.fromRGB(0, 206, 209) then
                -- This is the selected category button, refresh its weapons
                local category = child.Name:gsub("Filter", "")
                local mainContent = weaponsContent:FindFirstChild("MainContent")
                if mainContent then
                    local weaponData = {
                        weaponList = mainContent:FindFirstChild("WeaponList"),
                        viewport = mainContent:FindFirstChild("PreviewArea"):FindFirstChild("WeaponViewport"),
                        statsFrame = mainContent:FindFirstChild("PreviewArea"):FindFirstChild("WeaponStats"),
                        selectedWeapon = nil
                    }
                    self:DisplayWeapons(weaponData, ArmorySystem, category)
                end
                break
            end
        end
    end
end

-- Initialize the controller
MenuController:Initialize()

return MenuController