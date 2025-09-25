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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI to be created (will be created by UIGenerator)
repeat wait() until playerGui:FindFirstChild("FPSMainMenu")

local mainMenu = playerGui.FPSMainMenu
local menuFrame = mainMenu.MainContainer
local particleContainer = mainMenu.MainContainer.BackgroundParticles

-- Menu sections - Updated to match new UI structure
local sectionsContainer = menuFrame.MenuPanel.SectionsContainer
local sections = {
    MainSection = sectionsContainer.MainSection,
    ArmorySection = sectionsContainer.ArmorySection,
    ShopSection = sectionsContainer.ShopSection,
    LeaderboardSection = sectionsContainer.LeaderboardSection,
    StatisticsSection = sectionsContainer.StatisticsSection,
    SettingsSection = sectionsContainer.SettingsSection
}

-- Navigation buttons from the navigation frame - Updated to match new UI structure
local navigationFrame = menuFrame.MenuPanel.NavigationFrame
local navButtons = {
    deployButton = navigationFrame.DEPLOYButton,
    armoryButton = navigationFrame.ARMORYButton,
    shopButton = navigationFrame.SHOPButton,
    leaderboardButton = navigationFrame.LEADERBOARDButton,
    settingsButton = navigationFrame.SETTINGSButton
}

-- Back buttons in each section
local backButtons = {}
for sectionName, section in pairs(sections) do
    local backBtn = section:FindFirstChild("BackButton")
    if backBtn then
        backButtons[sectionName] = backBtn
    end
end

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
    local targetSize = isHovering and UDim2.fromScale(1.05, 1.05) or UDim2.fromScale(1, 1)
    local targetTransparency = isHovering and 0.8 or 1

    local sizeTween = TweenService:Create(button, TweenInfo.new(0.2), {Size = targetSize})
    local transparencyTween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = targetTransparency})

    sizeTween:Play()
    transparencyTween:Play()
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
    local votingFrame = sections.MainSection:FindFirstChild("MapVoting")
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

                    -- Update button text to show vote
                    local voteCount = tonumber(button.Text:match("%((%d+) votes%)")) or 0
                    button.Text = selectedName .. " (" .. (voteCount + 1) .. " votes)"
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
    -- Main section navigation - Updated button names
    navButtons.deployButton.MouseButton1Click:Connect(function()
        self:PlayClickSound()
        -- Simple deploy logic without unwanted deploy menu
        RemoteEventsManager:InvokeServer("DeployPlayer", player)
        print("Deploying to battlefield...")
    end)
    
    navButtons.armoryButton.MouseButton1Click:Connect(function()
        self:SwitchToSection("ArmorySection")
    end)

    navButtons.shopButton.MouseButton1Click:Connect(function()
        self:SwitchToSection("ShopSection")
    end)

    navButtons.leaderboardButton.MouseButton1Click:Connect(function()
        self:SwitchToSection("LeaderboardSection")
    end)

    navButtons.settingsButton.MouseButton1Click:Connect(function()
        self:SwitchToSection("SettingsSection")
    end)
    
    -- Back button navigation
    for sectionName, backButton in pairs(backButtons) do
        backButton.MouseButton1Click:Connect(function()
            self:SwitchToSection("MainSection")
        end)
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

    -- Initialize FPS System modules
    RemoteEventsManager:Initialize()
    WeaponConfig:Initialize()

    -- Load player data
    self:LoadPlayerData()

    -- Initialize all systems
    self:InitializeNavigation()
    self:InitializeButtonHovers()
    self:InitializeParticleSystem()
    self:HandleMenuToggle()
    self:InitializeVotingSystem()

    -- Start with main menu visible
    mainMenu.Enabled = true

    print("MenuController: Ready!")
end

-- Initialize the controller
MenuController:Initialize()

return MenuController