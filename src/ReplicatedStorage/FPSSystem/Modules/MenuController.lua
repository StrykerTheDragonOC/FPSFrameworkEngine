-- MenuController.lua
-- Real menu controller with functional navigation, team selection, and animations
-- Place in ReplicatedStorage/FPSSystem/Modules

local MenuController = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

-- Initialize menu controller
function MenuController.init()
    print("[MenuController] Initializing menu system...")
    
    -- Core references
    MenuController.player = Players.LocalPlayer
    MenuController.playerGui = MenuController.player:WaitForChild("PlayerGui")
    
    -- Menu state
    MenuController.menuState = {
        currentScreen = "MainMenu",
        selectedTeam = nil,
        isAnimating = false,
        settingsOpen = false,
        loadoutOpen = false
    }
    
    -- Connections
    MenuController.connections = {}
    
    -- Wait for menu GUI and initialize
    task.spawn(function()
        MenuController:waitForMenuGui()
    end)
    
    -- Setup input handling
    MenuController:setupInputHandling()
    
    -- Setup remote events
    MenuController:setupRemoteEvents()
    
    print("[MenuController] Menu system initialized")
end

-- Wait for menu GUI to be created
function MenuController:waitForMenuGui()
    local menuGui = nil
    local attempts = 0
    
    -- Wait up to 10 seconds for menu to be created
    while not menuGui and attempts < 100 do
        menuGui = MenuController.playerGui:FindFirstChild("FPSGameMenu")
        if not menuGui then
            task.wait(0.1)
            attempts = attempts + 1
        end
    end
    
    if menuGui then
        MenuController.menuGui = menuGui
        print("[MenuController] Menu GUI found, setting up functionality")
        
        -- Setup menu functionality
        MenuController:setupMenuFunctionality()
        
        -- Setup team selection
        MenuController:setupTeamSelection()
        
        -- Setup button animations
        MenuController:setupButtonAnimations()
        
        -- Setup background effects
        MenuController:setupBackgroundEffects()
    else
        warn("[MenuController] Menu GUI 'FPSGameMenu' not found after waiting!")
        print("[MenuController] Available GUIs in PlayerGui:")
        for _, gui in pairs(MenuController.playerGui:GetChildren()) do
            print("  -", gui.Name, gui.ClassName)
        end
        print("[MenuController] Please run the UI Generator script to create the required GUIs")
    end
end

-- Setup menu functionality
function MenuController:setupMenuFunctionality()
    if not self.menuGui then return end
    
    print("[MenuController] Setting up menu functionality...")
    
    -- Find main container
    local menuContainer = self.menuGui:FindFirstChild("MenuContainer")
    if not menuContainer then return end
    
    -- Setup deploy/play button
    self:setupDeployButton(menuContainer)
    
    -- Setup loadout button
    self:setupLoadoutButton(menuContainer)
    
    -- Setup settings button
    self:setupSettingsButton(menuContainer)
    
    -- Setup stats button
    self:setupStatsButton(menuContainer)
    
    -- Setup exit button
    self:setupExitButton(menuContainer)
end

-- Setup deploy button functionality
function MenuController:setupDeployButton(container)
    local deployButton = self:findButton(container, "PlayButton")
    if not deployButton then return end
    
    deployButton.MouseButton1Click:Connect(function()
        if self.menuState.isAnimating then return end
        
        print("[MenuController] Deploy button clicked")
        self:handleDeploy()
    end)
    
    print("[MenuController] Deploy button connected")
end

-- Setup loadout button functionality
function MenuController:setupLoadoutButton(container)
    local loadoutButton = self:findButton(container, "LoadoutButton")
    if not loadoutButton then return end
    
    loadoutButton.MouseButton1Click:Connect(function()
        if self.menuState.isAnimating then return end
        
        print("[MenuController] Loadout button clicked")
        self:openLoadoutMenu()
    end)
    
    print("[MenuController] Loadout button connected")
end

-- Setup settings button functionality
function MenuController:setupSettingsButton(container)
    local settingsButton = self:findButton(container, "SettingsButton")
    if not settingsButton then return end
    
    settingsButton.MouseButton1Click:Connect(function()
        if self.menuState.isAnimating then return end
        
        print("[MenuController] Settings button clicked")
        self:openSettingsMenu()
    end)
    
    print("[MenuController] Settings button connected")
end

-- Setup stats button functionality
function MenuController:setupStatsButton(container)
    local statsButton = self:findButton(container, "StatsButton")
    if not statsButton then return end
    
    statsButton.MouseButton1Click:Connect(function()
        if self.menuState.isAnimating then return end
        
        print("[MenuController] Stats button clicked")
        self:openStatsMenu()
    end)
    
    print("[MenuController] Stats button connected")
end

-- Setup exit button functionality
function MenuController:setupExitButton(container)
    local exitButton = self:findButton(container, "ExitButton")
    if not exitButton then return end
    
    exitButton.MouseButton1Click:Connect(function()
        if self.menuState.isAnimating then return end
        
        print("[MenuController] Exit button clicked")
        self:handleExit()
    end)
    
    print("[MenuController] Exit button connected")
end

-- Find button in container (recursive search)
function MenuController:findButton(container, buttonName)
    local function searchRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == buttonName and child:IsA("GuiButton") then
                return child
            elseif child:IsA("GuiObject") then
                local found = searchRecursive(child)
                if found then return found end
            end
        end
        return nil
    end
    
    return searchRecursive(container)
end

-- Setup team selection functionality
function MenuController:setupTeamSelection()
    local teamContainer = self.menuGui:FindFirstChild("TeamSelection")
    if not teamContainer then return end
    
    -- Setup FBI team button
    local fbiButton = self:findButton(teamContainer, "FBIButton")
    if fbiButton then
        fbiButton.MouseButton1Click:Connect(function()
            self:selectTeam("FBI")
        end)
    end
    
    -- Setup KFC team button
    local kfcButton = self:findButton(teamContainer, "KFCButton")
    if kfcButton then
        kfcButton.MouseButton1Click:Connect(function()
            self:selectTeam("KFC")
        end)
    end
    
    print("[MenuController] Team selection setup complete")
end

-- Handle team selection
function MenuController:selectTeam(team)
    if self.menuState.isAnimating then return end
    
    print("[MenuController] Team selected:", team)
    self.menuState.selectedTeam = team
    
    -- Update UI to show selection
    self:updateTeamSelectionUI(team)
    
    -- Play selection sound
    self:playSelectionSound()
end

-- Update team selection UI
function MenuController:updateTeamSelectionUI(selectedTeam)
    local teamContainer = self.menuGui:FindFirstChild("TeamSelection")
    if not teamContainer then return end
    
    -- Reset all team buttons
    local fbiButton = self:findButton(teamContainer, "FBIButton")
    local kfcButton = self:findButton(teamContainer, "KFCButton")
    
    if fbiButton then
        local originalColor = Color3.fromRGB(85, 170, 187)
        fbiButton.BackgroundColor3 = selectedTeam == "FBI" and originalColor or Color3.fromRGB(50, 50, 50)
        
        -- Add selection effect
        if selectedTeam == "FBI" then
            self:addSelectionEffect(fbiButton)
        end
    end
    
    if kfcButton then
        local originalColor = Color3.fromRGB(255, 100, 100)
        kfcButton.BackgroundColor3 = selectedTeam == "KFC" and originalColor or Color3.fromRGB(50, 50, 50)
        
        -- Add selection effect
        if selectedTeam == "KFC" then
            self:addSelectionEffect(kfcButton)
        end
    end
end

-- Add selection effect to button
function MenuController:addSelectionEffect(button)
    -- Create glow effect
    local glow = Instance.new("Frame")
    glow.Name = "SelectionGlow"
    glow.Size = UDim2.new(1, 4, 1, 4)
    glow.Position = UDim2.new(0, -2, 0, -2)
    glow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glow.BackgroundTransparency = 0.5
    glow.BorderSizePixel = 0
    glow.ZIndex = button.ZIndex - 1
    glow.Parent = button
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 15)
    glowCorner.Parent = glow
    
    -- Pulse animation
    local pulseTween = TweenService:Create(glow,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.8}
    )
    pulseTween:Play()
    
    -- Remove old glow effects
    for _, child in ipairs(button:GetChildren()) do
        if child.Name == "SelectionGlow" and child ~= glow then
            child:Destroy()
        end
    end
end

-- Setup button animations
function MenuController:setupButtonAnimations()
    local container = self.menuGui:FindFirstChild("MenuContainer")
    if not container then return end
    
    local buttons = {"PlayButton", "LoadoutButton", "SettingsButton", "StatsButton", "ExitButton"}
    
    for _, buttonName in ipairs(buttons) do
        local button = self:findButton(container, buttonName)
        if button then
            self:addButtonHoverEffects(button)
        end
    end
    
    print("[MenuController] Button animations setup complete")
end

-- Add hover effects to button
function MenuController:addButtonHoverEffects(button)
    local originalSize = button.Size
    local originalPosition = button.Position
    
    button.MouseEnter:Connect(function()
        if self.menuState.isAnimating then return end
        
        -- Scale up effect
        local hoverTween = TweenService:Create(button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset * 1.05,
                                originalSize.Y.Scale * 1.05, originalSize.Y.Offset * 1.05),
                Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset - originalSize.X.Offset * 0.025,
                                    originalPosition.Y.Scale, originalPosition.Y.Offset - originalSize.Y.Offset * 0.025)
            }
        )
        hoverTween:Play()
        
        -- Play hover sound
        self:playHoverSound()
    end)
    
    button.MouseLeave:Connect(function()
        -- Scale back down
        local leaveTween = TweenService:Create(button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = originalSize,
                Position = originalPosition
            }
        )
        leaveTween:Play()
    end)
end

-- Setup background effects
function MenuController:setupBackgroundEffects()
    -- This integrates with ParticleAnimationManager
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local particleManager = fpsSystem.Modules:FindFirstChild("ParticleAnimationManager")
    if particleManager then
        local success, manager = pcall(function()
            return require(particleManager)
        end)
        
        if success and manager and self.menuGui then
            -- Initialize particle background for menu
            manager.initializeParticleBackground(self.menuGui)
            print("[MenuController] Particle background initialized")
        elseif not self.menuGui then
            print("[MenuController] MenuGui not available for particle background")
        end
    end
end

-- Handle deploy button click
function MenuController:handleDeploy()
    if not self.menuState.selectedTeam then
        self:showTeamSelectionPrompt()
        return
    end
    
    self.menuState.isAnimating = true
    
    -- Play deploy sound
    self:playDeploySound()
    
    -- Animate menu close
    local fadeOutTween = TweenService:Create(self.menuGui,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    fadeOutTween:Play()
    
    fadeOutTween.Completed:Connect(function()
        self.menuGui.Enabled = false
        self.menuState.isAnimating = false
        
        -- Fire team selection remote
        self:fireTeamSelection(self.menuState.selectedTeam)
        
        -- Enable HUD
        self:enableHUD()
        
        -- Set mouse lock
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        
        print("[MenuController] Deployed to game as", self.menuState.selectedTeam)
    end)
end

-- Show team selection prompt
function MenuController:showTeamSelectionPrompt()
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Name = "TeamSelectionPrompt"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(0.5, -150, 0.2, 0)
    notification.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    notification.BorderSizePixel = 0
    notification.ZIndex = 10
    notification.Parent = self.menuGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 12)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, 0, 1, 0)
    notifText.Position = UDim2.new(0, 0, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = "Please select a team first!"
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.TextScaled = true
    notifText.Font = Enum.Font.GothamBold
    notifText.Parent = notification
    
    -- Auto-remove notification
    task.delay(2, function()
        if notification and notification.Parent then
            local fadeTween = TweenService:Create(notification,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            fadeTween:Play()
            
            fadeTween.Completed:Connect(function()
                notification:Destroy()
            end)
        end
    end)
end

-- Open loadout menu
function MenuController:openLoadoutMenu()
    print("[MenuController] Opening loadout menu...")
    
    -- Find or create loadout UI
    local loadoutGui = self.playerGui:FindFirstChild("LoadoutArmoryUI")
    if loadoutGui then
        loadoutGui.Enabled = true
        self.menuState.loadoutOpen = true
    else
        -- Try to find loadout controller in StarterGui
        local loadoutScript = StarterGui:FindFirstChild("LoadoutController")
        if loadoutScript then
            local success = pcall(function() require(loadoutScript) end)
            if success then
                task.wait(0.5)
            else
                self:showNotification("Failed to load loadout controller")
                return
            end
            
            local newLoadoutGui = self.playerGui:FindFirstChild("LoadoutArmoryUI")
            if newLoadoutGui then
                newLoadoutGui.Enabled = true
                self.menuState.loadoutOpen = true
            end
        else
            self:showNotification("Loadout system not available")
        end
    end
end

-- Open settings menu
function MenuController:openSettingsMenu()
    print("[MenuController] Opening settings menu...")
    self:showNotification("Settings menu coming soon!")
    -- TODO: Implement settings menu
end

-- Open stats menu
function MenuController:openStatsMenu()
    print("[MenuController] Opening stats menu...")
    self:showNotification("Stats menu coming soon!")
    -- TODO: Implement stats menu
end

-- Handle exit button
function MenuController:handleExit()
    print("[MenuController] Exit button clicked")
    
    -- Create confirmation dialog
    self:showExitConfirmation()
end

-- Show exit confirmation
function MenuController:showExitConfirmation()
    local confirmation = Instance.new("Frame")
    confirmation.Name = "ExitConfirmation"
    confirmation.Size = UDim2.new(0, 400, 0, 200)
    confirmation.Position = UDim2.new(0.5, -200, 0.5, -100)
    confirmation.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    confirmation.BorderSizePixel = 0
    confirmation.ZIndex = 15
    confirmation.Parent = self.menuGui
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 15)
    confirmCorner.Parent = confirmation
    
    local confirmText = Instance.new("TextLabel")
    confirmText.Size = UDim2.new(1, 0, 0.5, 0)
    confirmText.Position = UDim2.new(0, 0, 0, 0)
    confirmText.BackgroundTransparency = 1
    confirmText.Text = "Are you sure you want to exit?"
    confirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmText.TextScaled = true
    confirmText.Font = Enum.Font.Gotham
    confirmText.Parent = confirmation
    
    -- Yes button
    local yesButton = Instance.new("TextButton")
    yesButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    yesButton.Position = UDim2.new(0.1, 0, 0.6, 0)
    yesButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    yesButton.Text = "Yes"
    yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesButton.TextScaled = true
    yesButton.Font = Enum.Font.GothamBold
    yesButton.BorderSizePixel = 0
    yesButton.Parent = confirmation
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 8)
    yesCorner.Parent = yesButton
    
    -- No button
    local noButton = Instance.new("TextButton")
    noButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    noButton.Position = UDim2.new(0.5, 0, 0.6, 0)
    noButton.BackgroundColor3 = Color3.fromRGB(85, 170, 187)
    noButton.Text = "No"
    noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    noButton.TextScaled = true
    noButton.Font = Enum.Font.GothamBold
    noButton.BorderSizePixel = 0
    noButton.Parent = confirmation
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 8)
    noCorner.Parent = noButton
    
    -- Button connections
    yesButton.MouseButton1Click:Connect(function()
        confirmation:Destroy()
        -- Close game or return to main lobby
        self.player:Kick("Thanks for playing KFCS Funny Randomizer!")
    end)
    
    noButton.MouseButton1Click:Connect(function()
        confirmation:Destroy()
    end)
end

-- Setup input handling
function MenuController:setupInputHandling()
    self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- ESC key for menu toggle
        if input.KeyCode == Enum.KeyCode.Escape then
            self:toggleMenu()
        end
    end)
end

-- Toggle menu visibility
function MenuController:toggleMenu()
    if not self.menuGui then return end
    
    local isMenuVisible = self.menuGui.Enabled
    self.menuGui.Enabled = not isMenuVisible
    
    -- Handle mouse behavior
    if self.menuGui.Enabled then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
    
    -- Handle HUD visibility
    local hudGui = self.playerGui:FindFirstChild("ModernHUD")
    if hudGui then
        hudGui.Enabled = not self.menuGui.Enabled
    end
    
    print("[MenuController] Menu toggled:", not isMenuVisible)
end

-- Setup remote events
function MenuController:setupRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    -- Connect to game mode updates
    local gameModeUpdate = remoteEvents:FindFirstChild("GameModeUpdate")
    if gameModeUpdate then
        self.connections.gameModeUpdate = gameModeUpdate.OnClientEvent:Connect(function(gameMode, timeLeft)
            self:updateGameModeDisplay(gameMode, timeLeft)
        end)
    end
end

-- Fire team selection remote
function MenuController:fireTeamSelection(team)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local RemoteEventsManager = require(fpsSystem.Modules.RemoteEventsManager)
    local teamRemote = RemoteEventsManager.getRemoteEvent("TeamSelection")
    
    if teamRemote then
        teamRemote:FireServer(team)
        print("[MenuController] Fired team selection:", team)
    else
        warn("[MenuController] TeamSelection remote not found")
    end
end

-- Enable HUD
function MenuController:enableHUD()
    local hudGui = self.playerGui:FindFirstChild("ModernHUD")
    if hudGui then
        hudGui.Enabled = true
    end
end

-- Show notification
function MenuController:showNotification(message)
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(0.5, -150, 0.9, 0)
    notification.BackgroundColor3 = Color3.fromRGB(85, 170, 187)
    notification.BorderSizePixel = 0
    notification.ZIndex = 10
    notification.Parent = self.menuGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 12)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, 0, 1, 0)
    notifText.Position = UDim2.new(0, 0, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.TextScaled = true
    notifText.Font = Enum.Font.Gotham
    notifText.Parent = notification
    
    -- Slide in animation
    notification.Position = UDim2.new(0.5, -150, 1.1, 0)
    local slideInTween = TweenService:Create(notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0.9, 0)}
    )
    slideInTween:Play()
    
    -- Auto-remove notification
    task.delay(3, function()
        if notification and notification.Parent then
            local slideOutTween = TweenService:Create(notification,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, -150, 1.1, 0)}
            )
            slideOutTween:Play()
            
            slideOutTween.Completed:Connect(function()
                notification:Destroy()
            end)
        end
    end)
end

-- Play sound effects
function MenuController:playHoverSound()
    -- Create hover sound effect
    local hoverSound = Instance.new("Sound")
    hoverSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    hoverSound.Volume = 0.3
    hoverSound.Parent = SoundService
    hoverSound:Play()
    
    hoverSound.Ended:Connect(function()
        hoverSound:Destroy()
    end)
end

function MenuController:playSelectionSound()
    local selectionSound = Instance.new("Sound")
    selectionSound.SoundId = "rbxasset://sounds/button-2.mp3"
    selectionSound.Volume = 0.5
    selectionSound.Parent = SoundService
    selectionSound:Play()
    
    selectionSound.Ended:Connect(function()
        selectionSound:Destroy()
    end)
end

function MenuController:playDeploySound()
    local deploySound = Instance.new("Sound")
    deploySound.SoundId = "rbxasset://sounds/impact_generic.mp3"
    deploySound.Volume = 0.7
    deploySound.Parent = SoundService
    deploySound:Play()
    
    deploySound.Ended:Connect(function()
        deploySound:Destroy()
    end)
end

-- Update game mode display
function MenuController:updateGameModeDisplay(gameMode, timeLeft)
    -- This could update a game mode indicator in the menu
    print("[MenuController] Game mode update:", gameMode, "Time left:", timeLeft)
end

-- Cleanup function
function MenuController:cleanup()
    print("[MenuController] Cleaning up menu controller...")
    
    -- Disconnect all connections
    for name, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Clear data
    self.connections = {}
    
    print("[MenuController] Menu controller cleanup complete")
end

-- API functions for external systems
function MenuController:showMenu()
    if self.menuGui then
        self.menuGui.Enabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        
        -- Hide HUD
        local hudGui = self.playerGui:FindFirstChild("ModernHUD")
        if hudGui then
            hudGui.Enabled = false
        end
    end
end

function MenuController:hideMenu()
    if self.menuGui then
        self.menuGui.Enabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        
        -- Show HUD
        local hudGui = self.playerGui:FindFirstChild("ModernHUD")
        if hudGui then
            hudGui.Enabled = true
        end
    end
end

function MenuController:getSelectedTeam()
    return self.menuState.selectedTeam
end

function MenuController:forceTeamSelection(team)
    self.menuState.selectedTeam = team
    self:updateTeamSelectionUI(team)
end

return MenuController