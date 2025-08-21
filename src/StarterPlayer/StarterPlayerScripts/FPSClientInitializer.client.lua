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

-- Controllers storage
local controllers = {
    HUD = nil,
    Menu = nil,
    Scoreboard = nil
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
    
    -- Initialize all controllers
    initializeHUD()
    initializeMenu()
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
    
    -- Load HUD controller from FPS system
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        warn("[FPSClientInitializer] FPSSystem not found!")
        return
    end
    
    local hudController = fpsSystem.Modules:FindFirstChild("HUDController")
    if hudController then
        local success, controller = pcall(function()
            return require(hudController)
        end)
        
        if success and controller then
            -- Store and initialize the HUD controller
            controllers.HUD = controller
            if controller.init then
                controller:init()
                print("[FPSClientInitializer] HUD system initialized")
                systemsLoaded.HUD = true
            end
        else
            warn("[FPSClientInitializer] Failed to load HUD controller:", controller)
        end
    else
        warn("[FPSClientInitializer] HUD controller not found in FPSSystem.Modules")
    end
    
    -- Check for HUD GUI
    task.wait(1)
    local hudGui = playerGui:FindFirstChild("ModernHUD")
    if hudGui then
        hudGui.Enabled = true
        print("[FPSClientInitializer] HUD enabled")
    end
end

-- Initialize Menu system
function initializeMenu()
    print("[FPSClientInitializer] Initializing Menu...")
    
    -- Load menu controller from FPS system
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        warn("[FPSClientInitializer] FPSSystem not found!")
        return
    end
    
    local menuController = fpsSystem.Modules:FindFirstChild("MenuController")
    if menuController then
        local success, controller = pcall(function()
            return require(menuController)
        end)
        
        if success and controller then
            -- Store and initialize the menu controller
            controllers.Menu = controller
            if controller.init then
                controller.init()
                print("[FPSClientInitializer] Menu system initialized")
                systemsLoaded.Menu = true
            end
        else
            warn("[FPSClientInitializer] Failed to load menu controller:", controller)
        end
    else
        warn("[FPSClientInitializer] Menu controller not found in FPSSystem.Modules")
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
    
    -- Load scoreboard controller from FPS system
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        warn("[FPSClientInitializer] FPSSystem not found!")
        return
    end
    
    local scoreboardController = fpsSystem.Modules:FindFirstChild("ScoreboardController")
    if scoreboardController then
        local success, controller = pcall(function()
            return require(scoreboardController)
        end)
        
        if success and controller then
            -- Store and initialize the scoreboard controller
            controllers.Scoreboard = controller
            if controller.init then
                controller:init()
                print("[FPSClientInitializer] Scoreboard system initialized")
                systemsLoaded.Scoreboard = true
            end
        else
            warn("[FPSClientInitializer] Failed to load scoreboard controller:", controller)
        end
    else
        warn("[FPSClientInitializer] Scoreboard controller not found in FPSSystem.Modules")
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
            return true
        else
            -- Try alternative names
            local altNames = {
                PlayButton = {"Deploy", "Play", "Start", "Join"},
                LoadoutButton = {"Loadout", "Weapons", "Equipment"},
                SettingsButton = {"Settings", "Options", "Config"},
                StatsButton = {"Stats", "Statistics", "Profile"}
            }
            
            if altNames[buttonName] then
                for _, altName in ipairs(altNames[buttonName]) do
                    local altButton = menuGui:FindFirstChild(altName, true)
                    if altButton and altButton:IsA("GuiButton") then
                        altButton.MouseButton1Click:Connect(callback)
                        print("[FPSClientInitializer] Connected", altName, "button as", buttonName)
                        return true
                    end
                end
            end
            
            print("[FPSClientInitializer] Button not found:", buttonName, "- menu may not have this functionality")
            return false
        end
    end
    
    -- Setup deploy button
    findAndSetupButton("PlayButton", function()
        print("[FPSClientInitializer] Deploy button clicked")
        menuGui.Enabled = false
        
        -- Fire team selection remote (default to FBI if none selected)
        local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
        if fpsSystem then
            local RemoteEventsManager = require(fpsSystem.Modules.RemoteEventsManager)
            local teamRemote = RemoteEventsManager.getRemoteEvent("TeamSelection")
            if teamRemote then
                teamRemote:FireServer("FBI")
            else
                warn("[FPSClientInitializer] TeamSelection remote not found")
            end
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
            local loadoutScript = StarterGui:FindFirstChild("ModernLoadoutController")
            if loadoutScript then
                local success = pcall(function() require(loadoutScript) end)
                if success then
                    task.wait(0.5)
                else
                    warn("Failed to load ModernLoadoutController")
                    return
                end
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

-- Setup input handling (delegated to controllers)
function setupInputHandling()
    print("[FPSClientInitializer] Input handling delegated to individual controllers")
    -- Individual controllers handle their own input (ESC for menu, TAB for scoreboard, etc.)
end

-- Setup team management
function setupTeamManagement()
    print("[FPSClientInitializer] Setting up team management...")
    
    -- Handle player death and respawn
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            print("[FPSClientInitializer] Player died")
            
            -- Use menu controller to show menu after death
            task.wait(3) -- Brief delay for death screen
            
            if controllers.Menu and controllers.Menu.showMenu then
                controllers.Menu:showMenu()
                print("[FPSClientInitializer] Returned to menu after death")
            end
        end)
    end)
    
    -- Team selection remote is handled by server-side RemoteEventsManager
    print("[FPSClientInitializer] Team selection remote managed centrally")
end

-- Monitor system status
function monitorSystemStatus()
    print("[FPSClientInitializer] System monitoring started")
    
    -- Monitor system health every 5 seconds
    task.spawn(function()
        while true do
            task.wait(5)
            
            -- Check controller status
            if not controllers.HUD and systemsLoaded.HUD then
                warn("[FPSClientInitializer] HUD controller lost, reinitializing...")
                initializeHUD()
            end
            
            if not controllers.Menu and systemsLoaded.Menu then
                warn("[FPSClientInitializer] Menu controller lost, reinitializing...")
                initializeMenu()
            end
            
            if not controllers.Scoreboard and systemsLoaded.Scoreboard then
                warn("[FPSClientInitializer] Scoreboard controller lost, reinitializing...")
                initializeScoreboard()
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
    
    -- Show menu initially using controller
    task.wait(1)
    if controllers.Menu and controllers.Menu.showMenu then
        controllers.Menu:showMenu()
        print("[FPSClientInitializer] Initial menu shown via controller")
    else
        -- Fallback to direct GUI access
        local menuGui = playerGui:FindFirstChild("FPSGameMenu")
        if menuGui then
            menuGui.Enabled = true
            print("[FPSClientInitializer] Initial menu shown via direct access")
        end
    end
end)

print("[FPSClientInitializer] Script loaded")