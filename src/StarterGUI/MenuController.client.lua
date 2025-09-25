local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Check if we're in Studio edit mode
local isStudioEditMode = RunService:IsEdit()

-- Wait for FPS System to load (with timeout for Studio edit mode)
local maxWaitTime = isStudioEditMode and 5 or 10
local waitTime = 0
while not ReplicatedStorage:FindFirstChild("FPSSystem") and waitTime < maxWaitTime do
    wait(0.1)
    waitTime = waitTime + 0.1
end

if not ReplicatedStorage:FindFirstChild("FPSSystem") then
    if isStudioEditMode then
        warn("FPSSystem not found in Studio edit mode - some features may not work")
    else
        error("FPSSystem not found - required for MenuController to function")
    end
end

-- Safely require modules with error handling for Studio edit mode
local function safeRequire(modulePath, moduleName)
    local success, module = pcall(require, modulePath)
    if not success then
        if isStudioEditMode then
            warn("Could not load " .. moduleName .. " in Studio edit mode - using placeholder")
            return {
                Initialize = function() print("Placeholder " .. moduleName .. " initialized") end,
                GetAvailableWeapons = function() return {} end,
                GetWeaponConfig = function() return {} end,
                InvokeServer = function() return false end,
                GetEvent = function() return nil end
            }
        else
            error("Failed to load " .. moduleName .. ": " .. tostring(module))
        end
    end
    return module
end

local RemoteEventsManager = safeRequire(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager, "RemoteEventsManager")
local WeaponConfig = safeRequire(ReplicatedStorage.FPSSystem.Modules.WeaponConfig, "WeaponConfig")
local VotingSystem = safeRequire(ReplicatedStorage.FPSSystem.Modules.VotingSystem, "VotingSystem")
local ArmorySystem = safeRequire(ReplicatedStorage.FPSSystem.Modules.ArmorySystem, "ArmorySystem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI to be created (will be created by UIGenerator)
local mainMenu = nil
local maxWaitTime = 10
local waitTime = 0

-- Wait for the UI to be available in PlayerGui
while not playerGui:FindFirstChild("FPSMainMenu") and waitTime < maxWaitTime do
    wait(0.1)
    waitTime = waitTime + 0.1
end

if playerGui:FindFirstChild("FPSMainMenu") then
    mainMenu = playerGui.FPSMainMenu
    print("✓ Found FPSMainMenu in PlayerGui")
else
    warn("✗ FPSMainMenu not found in PlayerGui after " .. maxWaitTime .. " seconds")
    return
end

local menuFrame = mainMenu.MainContainer
local particleContainer = mainMenu.MainContainer.BackgroundParticles

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

-- MenuController object
local MenuController = {}

-- Animation settings
local transitionInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Sound effects
local function PlayClickSound()
    local clickSound = Instance.new("Sound")
    clickSound.SoundId = "rbxasset://sounds/button.wav"
    clickSound.Volume = 0.5
    clickSound.Parent = SoundService
    clickSound:Play()
    clickSound.Ended:Connect(function()
        clickSound:Destroy()
    end)
end

-- Update player data display
function MenuController:UpdatePlayerData()
    if not mainMenu then return end
    
    local playerInfo = mainMenu.MainContainer.MenuPanel.TopBar.PlayerInfo
    
    if playerInfo then
        local playerName = playerInfo:FindFirstChild("PlayerName")
        local playerLevel = playerInfo:FindFirstChild("PlayerLevel")
        local playerCredits = playerInfo:FindFirstChild("PlayerCredits")
        local playerXP = playerInfo:FindFirstChild("PlayerXP")
        local playerKD = playerInfo:FindFirstChild("PlayerKD")
        
        if playerName then
            playerName.Text = player.Name:upper()
        end
        
        if playerLevel then
            playerLevel.Text = "RANK: " .. playerData.level
        end
        
        if playerCredits then
            playerCredits.Text = "CREDITS: " .. playerData.credits
        end
        
        if playerXP then
            playerXP.Text = "XP: " .. playerData.xp .. "/" .. playerData.nextLevelXP
        end
        
        if playerKD then
            playerKD.Text = "K/D: " .. string.format("%.2f", playerData.kdr)
        end
    end
end

-- Initialize particle system
function MenuController:InitializeParticleSystem()
    if not particleContainer then return end
    
    print("Initializing particle system...")
    
    -- Add subtle animation to existing stars
    for _, star in pairs(particleContainer:GetChildren()) do
        if star:IsA("Frame") and star.Name:match("Star") then
            -- Add subtle pulsing effect
            local pulseTween = TweenService:Create(star, 
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Size = UDim2.new(0, star.Size.X.Offset + 2, 0, star.Size.Y.Offset + 2)}
            )
            pulseTween:Play()
        end
    end
end

-- Initialize voting system
function MenuController:InitializeVotingSystem()
    if not mainMenu then return end
    
    print("Initializing voting system...")
    
    local votingFrame = mainMenu.MainContainer.MenuPanel.SectionsContainer.MainSection:FindFirstChild("MapVoting")
    if not votingFrame then return end
    
    -- Connect gamemode vote buttons
    for _, child in pairs(votingFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name:match("Vote") then
            child.MouseButton1Click:Connect(function()
                PlayClickSound()
                print("Voted for: " .. child.Name:gsub("Vote", ""))
                -- Add voting logic here
            end)
        end
    end
end

-- Initialize leaderboard
function MenuController:InitializeLeaderboard()
    if not mainMenu then return end
    
    print("Initializing leaderboard...")
    
    -- This would populate the leaderboard with actual player data
    -- For now, it's just a placeholder
end

-- Load player data (placeholder)
function MenuController:LoadPlayerData()
    print("Loading player data...")
    
    -- In a real implementation, this would load from DataStore
    playerData = {
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
    
    self:UpdatePlayerData()
end

-- Start periodic updates
function MenuController:StartPeriodicUpdates()
    print("Starting periodic updates...")
    
    -- Update server status every 10 seconds
    spawn(function()
        while mainMenu and mainMenu.Parent do
            wait(10)
            self:UpdateServerStatus()
        end
    end)
    
    -- Update player data every 30 seconds
    spawn(function()
        while mainMenu and mainMenu.Parent do
            wait(30)
            self:LoadPlayerData()
        end
    end)
end

-- Update server status
function MenuController:UpdateServerStatus()
    if not mainMenu then return end
    
    local serverStatus = mainMenu.MainContainer.MenuPanel.SectionsContainer.MainSection:FindFirstChild("ServerStatus")
    if not serverStatus then return end
    
    local playerCount = serverStatus:FindFirstChild("PlayerCount")
    local matchStatus = serverStatus:FindFirstChild("MatchStatus")
    local nextMatch = serverStatus:FindFirstChild("NextMatch")
    
    if playerCount then
        local totalPlayers = #Players:GetPlayers()
        playerCount.Text = "PLAYERS ONLINE: " .. totalPlayers .. "/64"
    end
    
    if matchStatus then
        matchStatus.Text = "MATCH STATUS: WAITING"
    end
    
    if nextMatch then
        -- Calculate time until next match (placeholder)
        local timeLeft = 165 -- 2:45 in seconds
        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60
        nextMatch.Text = "NEXT MATCH STARTS IN: " .. string.format("%02d:%02d", minutes, seconds)
    end
end

-- Initialize the controller
function MenuController:Initialize()
    print("MenuController: Initializing...")

    -- Debug: Check if UI elements exist
    print("Debug - UI Structure Check:")
    print("  FPSMainMenu:", mainMenu and "✓" or "✗")
    print("  MainContainer:", menuFrame and "✓" or "✗")
    
    if mainMenu and menuFrame then
        local menuPanel = menuFrame:FindFirstChild("MenuPanel")
        print("  MenuPanel:", menuPanel and "✓" or "✗")
        
        if menuPanel then
            print("  NavigationFrame:", menuPanel:FindFirstChild("NavigationFrame") and "✓" or "✗")
            print("  SectionsContainer:", menuPanel:FindFirstChild("SectionsContainer") and "✓" or "✗")
        end
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

    -- Initialize systems that don't require navigation (since it's handled by the UI generator)
    self:InitializeParticleSystem()
    self:InitializeVotingSystem()
    self:InitializeLeaderboard()
    
    -- Start periodic updates for server data
    self:StartPeriodicUpdates()

    print("MenuController: Initialization Complete!")
    print("Note: Navigation is handled by the UI generator script")
end

-- Initialize the controller
MenuController:Initialize()

return MenuController
