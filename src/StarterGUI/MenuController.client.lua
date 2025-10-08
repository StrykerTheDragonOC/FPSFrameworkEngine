local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Check if we're in Studio edit mode (safely handle lacking capability)
local isStudioEditMode = false
pcall(function()
	isStudioEditMode = RunService:IsEdit()
end)

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

-- Update player data display (not shown in current menu design)
function MenuController:UpdatePlayerData()
    -- New menu doesn't have player data display in sidebar
    -- Could add this to a profile section later
end

-- Particle system removed (no longer used in Battlefield-style menu)

-- Initialize voting system (disabled for now - will add later)
function MenuController:InitializeVotingSystem()
    print("Voting system initialization skipped (not in current menu design)")
end

-- Update vote counts display
function MenuController:UpdateVoteCounts(votes)
    if not mainMenu then return end

    local votingFrame = mainMenu.MainContainer.MenuPanel.SectionsContainer.MainSection:FindFirstChild("MapVoting")
    if not votingFrame then return end

    -- Update each vote button's count
    for _, child in pairs(votingFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name:match("Vote") then
            local gamemode = child.Name:gsub("Vote", "")
            local voteCount = votes[gamemode] or 0

            -- Update vote count label
            local voteCountLabel = child:FindFirstChild("VoteCount")
            if voteCountLabel then
                voteCountLabel.Text = voteCount .. " vote" .. (voteCount ~= 1 and "s" or "")
            end
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

-- Update server status (not shown in simple menu)
function MenuController:UpdateServerStatus()
    -- Simple menu doesn't have server status display
end

-- Deploy player to team
function MenuController:DeployPlayer(teamName)
    print("Deploying player to team:", teamName)
    isDeployed = true

    -- Request deployment from server
    local deployEvent = RemoteEventsManager:GetEvent("PlayerDeploy")
    if deployEvent then
        RemoteEventsManager:FireServer("PlayerDeploy", {Team = teamName})
    else
        warn("PlayerDeploy event not found")
    end

    -- Hide menu
    self:HideMenu()
end

-- Show menu
function MenuController:ShowMenu()
    if mainMenu then
        mainMenu.Enabled = true

        -- Lock player input
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true

        -- Lock player in menu
        if player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
            end
        end

        print("Menu shown - MouseBehavior:", UserInputService.MouseBehavior)
    end
end

-- Hide menu
function MenuController:HideMenu()
    if mainMenu then
        mainMenu.Enabled = false

        -- Unlock player input
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false

        -- Unlock player movement
        if player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16 -- Default walkspeed
                humanoid.JumpPower = 50 -- Default jump
            end
        end

        print("Menu hidden - MouseBehavior:", UserInputService.MouseBehavior)
    end
end

-- Setup deploy button
function MenuController:SetupDeployButton()
    if not mainMenu then return end

    -- New structure: MainContainer -> ContentArea -> DeploySection -> DeployButton
    local contentArea = mainMenu.MainContainer:FindFirstChild("ContentArea")
    if not contentArea then
        warn("ContentArea not found")
        return
    end

    local deploySection = contentArea:FindFirstChild("DeploySection")
    if not deploySection then
        warn("DeploySection not found")
        return
    end

    local deployButton = deploySection:FindFirstChild("DeployButton")
    if deployButton and deployButton:IsA("TextButton") then
        deployButton.MouseButton1Click:Connect(function()
            PlayClickSound()
            -- Deploy to random team (KFC or FBI)
            local teams = {"KFC", "FBI"}
            local randomTeam = teams[math.random(1, #teams)]
            self:DeployPlayer(randomTeam)
        end)
        print("✓ Deploy button connected")
    else
        warn("DeployButton not found in DeploySection")
    end
end

-- Listen for Space key to deploy
function MenuController:SetupSpaceKeyDeploy()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Space and mainMenu and mainMenu.Enabled then
            -- Deploy to random team
            local teams = {"KFC", "FBI"}
            local randomTeam = teams[math.random(1, #teams)]
            self:DeployPlayer(randomTeam)
        end
    end)
    print("✓ Space key deploy enabled")
end

-- Track deployment state
local isDeployed = false

-- Initialize the controller
function MenuController:Initialize()
    print("MenuController: Initializing...")

    -- Hide default Roblox UI
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    end)

    -- Debug: Check if UI elements exist
    print("Debug - UI Structure Check:")
    print("  FPSMainMenu:", mainMenu and "✓" or "✗")
    print("  MainContainer:", menuFrame and "✓" or "✗")

    if mainMenu and menuFrame then
        print("  Sidebar:", menuFrame:FindFirstChild("Sidebar") and "✓" or "✗")
        print("  ContentArea:", menuFrame:FindFirstChild("ContentArea") and "✓" or "✗")

        local contentArea = menuFrame:FindFirstChild("ContentArea")
        if contentArea then
            print("  DeploySection:", contentArea:FindFirstChild("DeploySection") and "✓" or "✗")
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

    -- Initialize systems
    self:InitializeVotingSystem()
    self:InitializeLeaderboard()

    -- Setup deploy functionality
    self:SetupDeployButton()
    self:SetupSpaceKeyDeploy()

    -- Start periodic updates for server data
    self:StartPeriodicUpdates()

    -- Setup character respawn handling
    self:SetupRespawnHandling()

    -- Show menu on start
    self:ShowMenu()

    print("MenuController: Initialization Complete!")
    print("Note: Navigation is handled by the UI generator script")
end

-- Setup respawn handling
function MenuController:SetupRespawnHandling()
    -- Handle respawns
    player.CharacterAdded:Connect(function(character)
        print("Character respawned - checking deployment state")

        -- Wait for character to fully load
        wait(0.5)

        -- If player is not deployed, show menu again
        if not isDeployed then
            self:ShowMenu()
            print("Showing menu after respawn (not deployed)")
        else
            print("Player is deployed, keeping menu hidden")
        end
    end)

    -- Track when player dies
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                print("Player died")
                -- Don't change deployment state, will be handled by respawn
            end)
        end
    end
end

-- Deployment state is tracked in the first DeployPlayer function (line 204)

-- Initialize the controller
MenuController:Initialize()

return MenuController
