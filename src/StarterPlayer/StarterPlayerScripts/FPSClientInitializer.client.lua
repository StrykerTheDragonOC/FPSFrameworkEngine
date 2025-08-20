-- FPSClientInitializer.client.lua
-- Main client-side initialization for FPS system
-- Handles HUD, menu systems, and UI functionality
-- Place in StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- System state
local systemsLoaded = {
    HUD = false,
    Menu = false,
    Scoreboard = false
}

-- Initialize client systems
local function initializeClientSystems()
    print("[FPSClientInitializer] Starting client initialization...")
    
    -- Wait for FPS system to be available
    local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem", 30)
    if not fpsSystem then
        warn("[FPSClientInitializer] FPSSystem not found in ReplicatedStorage!")
        return
    end
    
    -- Initialize HUD system
    initializeHUD()
    
    -- Initialize Menu system  
    initializeMenu()
    
    -- Initialize Scoreboard system
    initializeScoreboard()
    
    -- Setup input handling
    setupInputHandling()
    
    -- Setup team management
    setupTeamManagement()
    
    print("[FPSClientInitializer] Client initialization complete!")
end

-- Initialize HUD system
function initializeHUD()
    print("[FPSClientInitializer] Initializing HUD...")
    
    -- Check if ModernHUDSystem exists in StarterGUI and create it
    local hudScript = StarterGui:FindFirstChild("ModernHUDSystem")
    if hudScript then
        -- Execute the HUD creation script
        local success, err = pcall(function()
            require(hudScript)
        end)
        
        if success then
            print("[FPSClientInitializer] HUD system loaded from StarterGUI")
            systemsLoaded.HUD = true
        else
            warn("[FPSClientInitializer] Failed to load HUD from StarterGUI:", err)
        end
    end
    
    -- Ensure HUD is enabled
    task.wait(1) -- Wait for HUD to be created
    local hudGui = playerGui:FindFirstChild("FPSGameHUD")
    if hudGui then
        hudGui.Enabled = true
        print("[FPSClientInitializer] HUD enabled")
        systemsLoaded.HUD = true
    else
        warn("[FPSClientInitializer] HUD not found in PlayerGui")
    end
end

-- Initialize Menu system
function initializeMenu()
    print("[FPSClientInitializer] Initializing Menu...")
    
    -- Check if menu system exists and create it
    local menuScript = StarterGui:FindFirstChild("UltraEnhancedMenuUI")
    if menuScript then
        local success, err = pcall(function()
            require(menuScript)
        end)
        
        if success then
            print("[FPSClientInitializer] Menu system loaded")
            systemsLoaded.Menu = true
        else
            warn("[FPSClientInitializer] Failed to load menu:", err)
        end
    end
    
    -- Setup menu functionality
    task.wait(1)
    local menuGui = playerGui:FindFirstChild("FPSGameMenu")
    if menuGui then
        setupMenuFunctionality(menuGui)
        systemsLoaded.Menu = true
    end
end

-- Initialize Scoreboard system
function initializeScoreboard()
    print("[FPSClientInitializer] Initializing Scoreboard...")
    
    -- Check if scoreboard exists and create it
    local scoreboardScript = StarterGui:FindFirstChild("AdvancedScoreboardSystem")
    if scoreboardScript then
        local success, err = pcall(function()
            require(scoreboardScript)
        end)
        
        if success then
            print("[FPSClientInitializer] Scoreboard system loaded")
            systemsLoaded.Scoreboard = true
        else
            warn("[FPSClientInitializer] Failed to load scoreboard:", err)
        end
    end
    
    -- Setup scoreboard functionality
    task.wait(1)
    local scoreboardGui = playerGui:FindFirstChild("FPSScoreboard")
    if scoreboardGui then
        setupScoreboardFunctionality(scoreboardGui)
    end
end

-- Setup menu functionality
function setupMenuFunctionality(menuGui)
    if not menuGui then return end
    
    print("[FPSClientInitializer] Setting up menu functionality...")
    
    -- Find and setup buttons
    local function findAndSetupButton(buttonName, callback)
        local button = menuGui:FindFirstChild(buttonName, true)
        if button and button:IsA("GuiButton") then
            button.MouseButton1Click:Connect(callback)
            print("[FPSClientInitializer] Connected", buttonName, "button")
        else
            warn("[FPSClientInitializer] Button not found:", buttonName)
        end
    end
    
    -- Setup deploy button
    findAndSetupButton("PlayButton", function()
        print("[FPSClientInitializer] Deploy button clicked")
        menuGui.Enabled = false
        
        -- Fire team selection remote (default to FBI if none selected)
        local teamRemote = ReplicatedStorage:FindFirstChild("TeamSelection")
        if teamRemote then
            teamRemote:FireServer("FBI")
        end
    end)
    
    -- Setup loadout button
    findAndSetupButton("LoadoutButton", function()
        print("[FPSClientInitializer] Loadout button clicked")
        
        -- Show loadout UI
        local loadoutGui = playerGui:FindFirstChild("LoadoutArmoryUI")
        if loadoutGui then
            loadoutGui.Enabled = true
        else
            -- Create loadout UI if it doesn't exist
            local loadoutScript = StarterGui:FindFirstChild("LoadoutArmoryUI")
            if loadoutScript then
                require(loadoutScript)
                task.wait(0.5)
                local newLoadoutGui = playerGui:FindFirstChild("LoadoutArmoryUI")
                if newLoadoutGui then
                    newLoadoutGui.Enabled = true
                end
            end
        end
    end)
    
    -- Setup settings button
    findAndSetupButton("SettingsButton", function()
        print("[FPSClientInitializer] Settings button clicked")
        -- TODO: Implement settings menu
    end)
    
    -- Setup stats button
    findAndSetupButton("StatsButton", function()
        print("[FPSClientInitializer] Stats button clicked")
        -- TODO: Implement stats menu
    end)
end

-- Setup scoreboard functionality
function setupScoreboardFunctionality(scoreboardGui)
    if not scoreboardGui then return end
    
    print("[FPSClientInitializer] Setting up scoreboard functionality...")
    
    -- Setup TAB key toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Tab then
            scoreboardGui.Enabled = not scoreboardGui.Enabled
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Tab then
            scoreboardGui.Enabled = false
        end
    end)
end

-- Setup input handling
function setupInputHandling()
    print("[FPSClientInitializer] Setting up input handling...")
    
    -- ESC key for menu toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            toggleMainMenu()
        end
    end)
end

-- Toggle main menu
function toggleMainMenu()
    local menuGui = playerGui:FindFirstChild("FPSGameMenu")
    local hudGui = playerGui:FindFirstChild("FPSGameHUD")
    
    if menuGui then
        local isMenuVisible = menuGui.Enabled
        menuGui.Enabled = not isMenuVisible
        
        -- Hide HUD when menu is shown
        if hudGui then
            hudGui.Enabled = isMenuVisible
        end
        
        -- Handle mouse lock
        if menuGui.Enabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
        
        print("[FPSClientInitializer] Menu toggled:", not isMenuVisible)
    end
end

-- Setup team management
function setupTeamManagement()
    print("[FPSClientInitializer] Setting up team management...")
    
    -- Handle player death and respawn
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            print("[FPSClientInitializer] Player died")
            
            -- Show menu after death instead of auto-respawn
            task.wait(3) -- Brief delay for death screen
            
            local menuGui = playerGui:FindFirstChild("FPSGameMenu")
            if menuGui then
                menuGui.Enabled = true
                print("[FPSClientInitializer] Returned to menu after death")
            end
            
            -- Hide HUD
            local hudGui = playerGui:FindFirstChild("FPSGameHUD")
            if hudGui then
                hudGui.Enabled = false
            end
        end)
    end)
    
    -- Setup team selection remote
    local teamRemote = ReplicatedStorage:FindFirstChild("TeamSelection")
    if not teamRemote then
        teamRemote = Instance.new("RemoteEvent")
        teamRemote.Name = "TeamSelection"
        teamRemote.Parent = ReplicatedStorage
    end
end

-- Monitor system status
function monitorSystemStatus()
    RunService.Heartbeat:Connect(function()
        -- Check if systems are working correctly
        local hudGui = playerGui:FindFirstChild("FPSGameHUD")
        local menuGui = playerGui:FindFirstChild("FPSGameMenu")
        
        -- Auto-fix missing HUD
        if not hudGui or not hudGui.Enabled then
            if not systemsLoaded.HUD then
                initializeHUD()
            end
        end
    end)
end

-- Main initialization
task.spawn(function()
    task.wait(2) -- Wait for game to fully load
    
    initializeClientSystems()
    
    -- Start monitoring
    monitorSystemStatus()
    
    -- Show menu initially
    task.wait(1)
    local menuGui = playerGui:FindFirstChild("FPSGameMenu")
    if menuGui then
        menuGui.Enabled = true
        print("[FPSClientInitializer] Initial menu shown")
    end
end)

print("[FPSClientInitializer] Script loaded")