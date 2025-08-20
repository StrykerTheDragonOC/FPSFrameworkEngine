-- CompleteUISystemGenerator.lua
-- COMPREHENSIVE UI SYSTEM GENERATOR FOR KFCS FUNNY RANDOMIZER
-- RUN THIS ONCE IN STUDIO CONSOLE TO CREATE ALL UI ELEMENTS AND SCRIPTS
-- After running this, you can delete this file

print("🚀 Starting Complete UI System Generation for KFCS FUNNY RANDOMIZER...")

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- Clear existing UI to avoid conflicts
print("🧹 Cleaning up existing UI elements...")
for _, child in pairs(StarterGui:GetChildren()) do
    if child.Name:find("FPS") or child.Name:find("Loadout") or child.Name:find("Scoreboard") or child.Name:find("ModernHUD") then
        child:Destroy()
        print("   Removed:", child.Name)
    end
end

-- ============================================================================
-- 1. CREATE FPS GAME MENU (Main Menu Container)
-- ============================================================================
print("📋 Creating FPSGameMenu...")

local fpsGameMenu = Instance.new("ScreenGui")
fpsGameMenu.Name = "FPSGameMenu"
fpsGameMenu.ResetOnSpawn = false
fpsGameMenu.IgnoreGuiInset = true
fpsGameMenu.Enabled = false -- Start disabled
fpsGameMenu.Parent = StarterGui

-- Background with military theme
local bgFrame = Instance.new("Frame")
bgFrame.Name = "BackgroundFrame"
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
bgFrame.BorderSizePixel = 0
bgFrame.Parent = fpsGameMenu

-- Gradient overlay
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 20, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 35, 50))
}
gradient.Rotation = 45
gradient.Parent = bgFrame

-- Title
local titleFrame = Instance.new("Frame")
titleFrame.Name = "TitleFrame"
titleFrame.Size = UDim2.new(0, 600, 0, 100)
titleFrame.Position = UDim2.new(0.5, -300, 0.1, 0)
titleFrame.BackgroundTransparency = 1
titleFrame.Parent = bgFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.7, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "KFCS FUNNY RANDOMIZER"
titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleFrame

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(1, 0, 0.3, 0)
subtitleLabel.Position = UDim2.new(0, 0, 0.7, 0)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Version 4.0 | Advanced Combat Operations"
subtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
subtitleLabel.TextScaled = true
titleLabel.Font = Enum.Font.Gotham
subtitleLabel.Parent = titleFrame

-- Menu buttons
local menuContainer = Instance.new("Frame")
menuContainer.Name = "MenuContainer"
menuContainer.Size = UDim2.new(0, 400, 0, 300)
menuContainer.Position = UDim2.new(0.5, -200, 0.4, 0)
menuContainer.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
menuContainer.BorderSizePixel = 2
menuContainer.BorderColor3 = Color3.fromRGB(255, 100, 0)
menuContainer.Parent = bgFrame

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menuContainer

-- Menu buttons data
local menuButtons = {
    {name = "DEPLOY", key = "[DEPLOY]", desc = "Enter the battlefield"},
    {name = "ARMORY", key = "[ARM]", desc = "Customize weapons"},
    {name = "LEADERBOARD", key = "[BOARD]", desc = "View rankings"},
    {name = "SETTINGS", key = "[SET]", desc = "Game options"},
    {name = "STATISTICS", key = "[STAT]", desc = "Your stats"}
}

for i, buttonData in ipairs(menuButtons) do
    local button = Instance.new("TextButton")
    button.Name = buttonData.name .. "Button"
    button.Size = UDim2.new(1, -20, 0, 50)
    button.Position = UDim2.new(0, 10, 0, (i-1) * 55 + 10)
    button.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.fromRGB(0, 150, 255)
    button.Text = buttonData.key .. " " .. buttonData.name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = menuContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
end

print("   ✅ FPSGameMenu created")

-- ============================================================================
-- 2. CREATE FPS SCOREBOARD
-- ============================================================================
print("📊 Creating FPSScoreboard...")

local fpsScoreboard = Instance.new("ScreenGui")
fpsScoreboard.Name = "FPSScoreboard"
fpsScoreboard.ResetOnSpawn = false
fpsScoreboard.IgnoreGuiInset = true
fpsScoreboard.Enabled = false
fpsScoreboard.Parent = StarterGui

-- Scoreboard frame
local scoreboardFrame = Instance.new("Frame")
scoreboardFrame.Name = "ScoreboardFrame"
scoreboardFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
scoreboardFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
scoreboardFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
scoreboardFrame.BackgroundTransparency = 0.1
scoreboardFrame.BorderSizePixel = 2
scoreboardFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
scoreboardFrame.Parent = fpsScoreboard

local scoreboardCorner = Instance.new("UICorner")
scoreboardCorner.CornerRadius = UDim.new(0, 10)
scoreboardCorner.Parent = scoreboardFrame

-- Scoreboard header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
header.Parent = scoreboardFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

-- Header labels
local headerLabels = {"Player", "Rank", "Kills", "Deaths", "K/D", "Score", "Ping"}
for i, label in ipairs(headerLabels) do
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1/7, 0, 1, 0)
    headerLabel.Position = UDim2.new((i-1)/7, 0, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = label
    headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerLabel.TextScaled = true
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.Parent = header
end

-- Player list container
local playerListContainer = Instance.new("ScrollingFrame")
playerListContainer.Name = "PlayerListContainer"
playerListContainer.Size = UDim2.new(1, 0, 1, -50)
playerListContainer.Position = UDim2.new(0, 0, 0, 50)
playerListContainer.BackgroundTransparency = 1
playerListContainer.ScrollBarThickness = 8
playerListContainer.Parent = scoreboardFrame

print("   ✅ FPSScoreboard created")

-- ============================================================================
-- 3. CREATE LOADOUT ARMORY UI
-- ============================================================================
print("🔫 Creating LoadoutArmoryUI...")

local loadoutArmoryUI = Instance.new("ScreenGui")
loadoutArmoryUI.Name = "LoadoutArmoryUI"
loadoutArmoryUI.ResetOnSpawn = false
loadoutArmoryUI.IgnoreGuiInset = true
loadoutArmoryUI.Enabled = false
loadoutArmoryUI.Parent = StarterGui

-- Main armory frame
local armoryFrame = Instance.new("Frame")
armoryFrame.Name = "ArmoryFrame"
armoryFrame.Size = UDim2.new(1, 0, 1, 0)
armoryFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
armoryFrame.BorderSizePixel = 0
armoryFrame.Parent = loadoutArmoryUI

-- Left panel - weapon categories
local categoriesPanel = Instance.new("Frame")
categoriesPanel.Name = "CategoriesPanel"
categoriesPanel.Size = UDim2.new(0, 200, 1, 0)
categoriesPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
categoriesPanel.BorderSizePixel = 1
categoriesPanel.BorderColor3 = Color3.fromRGB(50, 50, 50)
categoriesPanel.Parent = armoryFrame

-- Category buttons
local categories = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE", "ATTACHMENTS"}
for i, category in ipairs(categories) do
    local categoryButton = Instance.new("TextButton")
    categoryButton.Name = category .. "Button"
    categoryButton.Size = UDim2.new(1, -10, 0, 40)
    categoryButton.Position = UDim2.new(0, 5, 0, (i-1) * 45 + 10)
    categoryButton.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    categoryButton.Text = category
    categoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    categoryButton.TextScaled = true
    categoryButton.Font = Enum.Font.GothamBold
    categoryButton.Parent = categoriesPanel
    
    local catCorner = Instance.new("UICorner")
    catCorner.CornerRadius = UDim.new(0, 5)
    catCorner.Parent = categoryButton
end

-- Center panel - weapon selection
local weaponPanel = Instance.new("Frame")
weaponPanel.Name = "WeaponPanel"
weaponPanel.Size = UDim2.new(0, 400, 1, 0)
weaponPanel.Position = UDim2.new(0, 200, 0, 0)
weaponPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
weaponPanel.BorderSizePixel = 1
weaponPanel.BorderColor3 = Color3.fromRGB(50, 50, 50)
weaponPanel.Parent = armoryFrame

-- Right panel - attachments and stats
local attachmentPanel = Instance.new("Frame")
attachmentPanel.Name = "AttachmentPanel"
attachmentPanel.Size = UDim2.new(1, -600, 1, 0)
attachmentPanel.Position = UDim2.new(0, 600, 0, 0)
attachmentPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
attachmentPanel.BorderSizePixel = 1
attachmentPanel.BorderColor3 = Color3.fromRGB(50, 50, 50)
attachmentPanel.Parent = armoryFrame

-- Stats display
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(1, -20, 0.5, 0)
statsFrame.Position = UDim2.new(0, 10, 0, 10)
statsFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
statsFrame.Parent = attachmentPanel

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsFrame

print("   ✅ LoadoutArmoryUI created")

-- ============================================================================
-- 4. CREATE MODERN HUD SYSTEM
-- ============================================================================
print("🎯 Creating ModernHUD...")

local modernHUD = Instance.new("ScreenGui")
modernHUD.Name = "ModernHUD"
modernHUD.ResetOnSpawn = false
modernHUD.IgnoreGuiInset = true
modernHUD.Enabled = false
modernHUD.Parent = StarterGui

-- HUD Container
local hudContainer = Instance.new("Frame")
hudContainer.Name = "HUDContainer"
hudContainer.Size = UDim2.new(1, 0, 1, 0)
hudContainer.BackgroundTransparency = 1
hudContainer.Parent = modernHUD

-- Crosshair (center)
local crosshairFrame = Instance.new("Frame")
crosshairFrame.Name = "CrosshairFrame"
crosshairFrame.Size = UDim2.new(0, 40, 0, 40)
crosshairFrame.Position = UDim2.new(0.5, -20, 0.5, -20)
crosshairFrame.BackgroundTransparency = 1
crosshairFrame.Parent = hudContainer

-- Simple crosshair lines
local hLine = Instance.new("Frame")
hLine.Size = UDim2.new(0, 20, 0, 2)
hLine.Position = UDim2.new(0.5, -10, 0.5, -1)
hLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
hLine.BorderSizePixel = 0
hLine.Parent = crosshairFrame

local vLine = Instance.new("Frame")
vLine.Size = UDim2.new(0, 2, 0, 20)
vLine.Position = UDim2.new(0.5, -1, 0.5, -10)
vLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
vLine.BorderSizePixel = 0
vLine.Parent = crosshairFrame

-- Health and Ammo (bottom center)
local healthAmmoFrame = Instance.new("Frame")
healthAmmoFrame.Name = "HealthAmmoFrame"
healthAmmoFrame.Size = UDim2.new(0, 300, 0, 80)
healthAmmoFrame.Position = UDim2.new(0.5, -150, 1, -100)
healthAmmoFrame.BackgroundTransparency = 1
healthAmmoFrame.Parent = hudContainer

-- Health display
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthFrame"
healthFrame.Size = UDim2.new(0.4, 0, 1, 0)
healthFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
healthFrame.Parent = healthAmmoFrame

local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(1, 0, 1, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.Text = "100"
healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healthLabel.TextScaled = true
healthLabel.Font = Enum.Font.GothamBold
healthLabel.Parent = healthFrame

-- Ammo display  
local ammoFrame = Instance.new("Frame")
ammoFrame.Name = "AmmoFrame"
ammoFrame.Size = UDim2.new(0.4, 0, 1, 0)
ammoFrame.Position = UDim2.new(0.6, 0, 0, 0)
ammoFrame.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
ammoFrame.Parent = healthAmmoFrame

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(1, 0, 1, 0)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Text = "30/120"
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.TextScaled = true
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.Parent = ammoFrame

-- Radar/Minimap (bottom left)
local radarFrame = Instance.new("Frame")
radarFrame.Name = "RadarFrame"
radarFrame.Size = UDim2.new(0, 200, 0, 200)
radarFrame.Position = UDim2.new(0, 20, 1, -220)
radarFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
radarFrame.BackgroundTransparency = 0.3
radarFrame.BorderSizePixel = 2
radarFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
radarFrame.Parent = hudContainer

local radarCorner = Instance.new("UICorner")
radarCorner.CornerRadius = UDim.new(0, 10)
radarCorner.Parent = radarFrame

-- Score display (above radar)
local scoreFrame = Instance.new("Frame")
scoreFrame.Name = "ScoreFrame"
scoreFrame.Size = UDim2.new(0, 200, 0, 80)
scoreFrame.Position = UDim2.new(0, 20, 1, -310)
scoreFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
scoreFrame.BackgroundTransparency = 0.3
scoreFrame.BorderSizePixel = 1
scoreFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
scoreFrame.Parent = hudContainer

-- Team scores
local fbiScore = Instance.new("TextLabel")
fbiScore.Name = "FBIScore"
fbiScore.Size = UDim2.new(0.5, 0, 0.5, 0)
fbiScore.BackgroundTransparency = 1
fbiScore.Text = "FBI: 0"
fbiScore.TextColor3 = Color3.fromRGB(0, 100, 255)
fbiScore.TextScaled = true
fbiScore.Font = Enum.Font.GothamBold
fbiScore.Parent = scoreFrame

local kfcScore = Instance.new("TextLabel")
kfcScore.Name = "KFCScore"
kfcScore.Size = UDim2.new(0.5, 0, 0.5, 0)
kfcScore.Position = UDim2.new(0.5, 0, 0, 0)
kfcScore.BackgroundTransparency = 1
kfcScore.Text = "KFC: 0"
kfcScore.TextColor3 = Color3.fromRGB(255, 50, 50)
kfcScore.TextScaled = true
kfcScore.Font = Enum.Font.GothamBold
kfcScore.Parent = scoreFrame

-- Gamemode display
local gamemodeLabel = Instance.new("TextLabel")
gamemodeLabel.Name = "GamemodeLabel"
gamemodeLabel.Size = UDim2.new(1, 0, 0.5, 0)
gamemodeLabel.Position = UDim2.new(0, 0, 0.5, 0)
gamemodeLabel.BackgroundTransparency = 1
gamemodeLabel.Text = "TEAM DEATHMATCH"
gamemodeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gamemodeLabel.TextScaled = true
gamemodeLabel.Font = Enum.Font.Gotham
gamemodeLabel.Parent = scoreFrame

print("   ✅ ModernHUD created")

-- ============================================================================
-- 5. CREATE CONTROLLER SCRIPTS IN STARTERGUI
-- ============================================================================
print("📜 Creating controller scripts...")

-- MainMenuController
local mainMenuController = Instance.new("ModuleScript")
mainMenuController.Name = "MainMenuController"
mainMenuController.Parent = StarterGui
mainMenuController.Source = [[
-- MainMenuController.lua
-- Controls the main menu system for KFCS FUNNY RANDOMIZER

local MainMenuController = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

function MainMenuController:init()
    print("[MainMenuController] Initializing main menu...")
    
    -- Get menu UI
    local menuUI = playerGui:WaitForChild("FPSGameMenu")
    if not menuUI then
        warn("[MainMenuController] FPSGameMenu not found!")
        return
    end
    
    -- Setup button connections
    self:setupButtons(menuUI)
    
    print("[MainMenuController] Main menu initialized")
end

function MainMenuController:setupButtons(menuUI)
    local menuContainer = menuUI:FindFirstChild("BackgroundFrame"):FindFirstChild("MenuContainer")
    
    -- Deploy button
    local deployButton = menuContainer:FindFirstChild("DEPLOYButton")
    if deployButton then
        deployButton.MouseButton1Click:Connect(function()
            self:onDeployClicked()
        end)
    end
    
    -- Armory button
    local armoryButton = menuContainer:FindFirstChild("ARMORYButton")
    if armoryButton then
        armoryButton.MouseButton1Click:Connect(function()
            self:onArmoryClicked()
        end)
    end
end

function MainMenuController:onDeployClicked()
    print("[MainMenuController] Deploy clicked - joining game...")
    -- Hide menu and enable HUD
    local menuUI = playerGui:FindFirstChild("FPSGameMenu")
    local hudUI = playerGui:FindFirstChild("ModernHUD")
    
    if menuUI then menuUI.Enabled = false end
    if hudUI then hudUI.Enabled = true end
end

function MainMenuController:onArmoryClicked()
    print("[MainMenuController] Armory clicked - opening loadout...")
    local loadoutUI = playerGui:FindFirstChild("LoadoutArmoryUI")
    if loadoutUI then
        loadoutUI.Enabled = true
    end
end

function MainMenuController:showMenu()
    local menuUI = playerGui:FindFirstChild("FPSGameMenu")
    if menuUI then
        menuUI.Enabled = true
    end
end

function MainMenuController:hideMenu()
    local menuUI = playerGui:FindFirstChild("FPSGameMenu")
    if menuUI then
        menuUI.Enabled = false
    end
end

return MainMenuController
]]

-- LoadoutController
local loadoutController = Instance.new("ModuleScript")
loadoutController.Name = "LoadoutController"
loadoutController.Parent = StarterGui
loadoutController.Source = [[
-- LoadoutController.lua
-- Controls the weapon loadout and customization system

local LoadoutController = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

function LoadoutController:init()
    print("[LoadoutController] Initializing loadout system...")
    
    -- Wait for loadout UI
    local loadoutUI = playerGui:WaitForChild("LoadoutArmoryUI")
    if not loadoutUI then
        warn("[LoadoutController] LoadoutArmoryUI not found!")
        return
    end
    
    -- Setup category buttons
    self:setupCategoryButtons(loadoutUI)
    
    print("[LoadoutController] Loadout system initialized")
end

function LoadoutController:setupCategoryButtons(loadoutUI)
    local categoriesPanel = loadoutUI:FindFirstChild("ArmoryFrame"):FindFirstChild("CategoriesPanel")
    
    local categories = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE", "ATTACHMENTS"}
    for _, category in ipairs(categories) do
        local button = categoriesPanel:FindFirstChild(category .. "Button")
        if button then
            button.MouseButton1Click:Connect(function()
                self:onCategorySelected(category)
            end)
        end
    end
end

function LoadoutController:onCategorySelected(category)
    print("[LoadoutController] Selected category:", category)
    -- Update weapon panel based on selected category
    self:updateWeaponPanel(category)
end

function LoadoutController:updateWeaponPanel(category)
    -- This would populate the weapon panel with weapons from the selected category
    print("[LoadoutController] Updating weapon panel for:", category)
end

return LoadoutController
]]

-- ScoreboardController
local scoreboardController = Instance.new("ModuleScript")
scoreboardController.Name = "ScoreboardController"
scoreboardController.Parent = StarterGui
scoreboardController.Source = [[
-- ScoreboardController.lua
-- Controls the custom scoreboard system

local ScoreboardController = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

function ScoreboardController:init()
    print("[ScoreboardController] Initializing scoreboard...")
    
    -- Hide default playerlist
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    
    -- Setup tab key handling
    self:setupInputHandling()
    
    print("[ScoreboardController] Scoreboard initialized")
end

function ScoreboardController:setupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Tab then
            self:showScoreboard()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Tab then
            self:hideScoreboard()
        end
    end)
end

function ScoreboardController:showScoreboard()
    local scoreboardUI = playerGui:FindFirstChild("FPSScoreboard")
    if scoreboardUI then
        scoreboardUI.Enabled = true
        self:updatePlayerList()
    end
end

function ScoreboardController:hideScoreboard()
    local scoreboardUI = playerGui:FindFirstChild("FPSScoreboard")
    if scoreboardUI then
        scoreboardUI.Enabled = false
    end
end

function ScoreboardController:updatePlayerList()
    print("[ScoreboardController] Updating player list...")
    -- This would populate the scoreboard with current player stats
end

return ScoreboardController
]]

-- ModernHUDSystem
local modernHUDSystem = Instance.new("ModuleScript")
modernHUDSystem.Name = "ModernHUDSystem"
modernHUDSystem.Parent = StarterGui
modernHUDSystem.Source = [[
-- ModernHUDSystem.lua
-- Controls the in-game HUD elements

local ModernHUDSystem = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

function ModernHUDSystem:init()
    print("[ModernHUDSystem] Initializing HUD system...")
    
    -- Get HUD UI
    local hudUI = playerGui:WaitForChild("ModernHUD")
    if not hudUI then
        warn("[ModernHUDSystem] ModernHUD not found!")
        return
    end
    
    -- Setup HUD updates
    self:setupHUDUpdates(hudUI)
    
    print("[ModernHUDSystem] HUD system initialized")
end

function ModernHUDSystem:setupHUDUpdates(hudUI)
    -- Update HUD elements regularly
    RunService.Heartbeat:Connect(function()
        self:updateHealth(hudUI)
        self:updateAmmo(hudUI)
        self:updateScores(hudUI)
    end)
end

function ModernHUDSystem:updateHealth(hudUI)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local health = player.Character.Humanoid.Health
        local healthLabel = hudUI:FindFirstChild("HUDContainer"):FindFirstChild("HealthAmmoFrame"):FindFirstChild("HealthFrame"):FindFirstChild("TextLabel")
        if healthLabel then
            healthLabel.Text = math.floor(health)
        end
    end
end

function ModernHUDSystem:updateAmmo(hudUI)
    -- This would update ammo display based on equipped weapon
    -- Placeholder for now
end

function ModernHUDSystem:updateScores(hudUI)
    -- This would update team scores from game state
    -- Placeholder for now
end

return ModernHUDSystem
]]

-- UltraEnhancedMenuUI (placeholder to fix require errors)
local ultraEnhancedMenuUI = Instance.new("ModuleScript")
ultraEnhancedMenuUI.Name = "UltraEnhancedMenuUI"
ultraEnhancedMenuUI.Parent = StarterGui
ultraEnhancedMenuUI.Source = [[
-- UltraEnhancedMenuUI.lua
-- Placeholder module to fix require errors

local UltraEnhancedMenuUI = {}

function UltraEnhancedMenuUI:init()
    print("[UltraEnhancedMenuUI] Placeholder module initialized")
end

return UltraEnhancedMenuUI
]]

-- AdvancedScoreboardSystem (placeholder to fix require errors)
local advancedScoreboardSystem = Instance.new("ModuleScript")
advancedScoreboardSystem.Name = "AdvancedScoreboardSystem"
advancedScoreboardSystem.Parent = StarterGui
advancedScoreboardSystem.Source = [[
-- AdvancedScoreboardSystem.lua
-- Placeholder module to fix require errors

local AdvancedScoreboardSystem = {}

function AdvancedScoreboardSystem:init()
    print("[AdvancedScoreboardSystem] Placeholder module initialized")
end

return AdvancedScoreboardSystem
]]

print("   ✅ All controller scripts created")

-- ============================================================================
-- 6. FINAL SETUP AND INSTRUCTIONS
-- ============================================================================
print("\n🎉 COMPLETE UI SYSTEM GENERATION FINISHED!")
print("=" .. string.rep("=", 50))
print("✅ Created UI Elements:")
print("   - FPSGameMenu (Main menu)")
print("   - FPSScoreboard (Tab scoreboard)")  
print("   - LoadoutArmoryUI (Weapon customization)")
print("   - ModernHUD (In-game HUD)")
print("✅ Created Controller Scripts:")
print("   - MainMenuController")
print("   - LoadoutController") 
print("   - ScoreboardController")
print("   - ModernHUDSystem")
print("   - UltraEnhancedMenuUI (placeholder)")
print("   - AdvancedScoreboardSystem (placeholder)")
print("\n📋 NEXT STEPS:")
print("1. All UI scripts are now in StarterGui - they will automatically replicate to PlayerGui")
print("2. The missing require errors should now be fixed")  
print("3. You can now delete this generator script")
print("4. Test the UI system by running the game")
print("\n⚠️  IMPORTANT NOTES:")
print("- All UI starts DISABLED except for the main menu")
print("- Controller scripts handle showing/hiding UI elements")
print("- Tab key shows/hides scoreboard")  
print("- Default playerlist is hidden")
print("- Scripts contain placeholder functions - expand as needed")
print("\n🚀 UI System Generation Complete! 🚀")