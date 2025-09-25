-- Enhanced Bounty System Client Script
-- Handles client-side bounty notifications and menu with proper cleanup

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for bounty events
local bountyEvents = ReplicatedStorage:WaitForChild("BountyEvents")
local placeBountyEvent = bountyEvents:WaitForChild("PlaceBounty")
local claimBountyEvent = bountyEvents:WaitForChild("ClaimBounty")

-- Bounty menu variables
local bountyMenu = nil
local selectedPlayer = nil
local bountyDisplay = nil
local bountyConnections = {}
local activeNotifications = {}

-- Bounty System Manager
local BountySystem = {}

-- Create notification function
local function createNotification(message, color)
    if not playerGui then return end

    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 400, 0, 60)
    notification.Position = UDim2.new(0.5, -200, 0, -70)
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.BackgroundTransparency = 0.2
    notification.BorderSizePixel = 0
    notification.Parent = playerGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = notification

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = notification

    -- Animate in
    notification:TweenPosition(
        UDim2.new(0.5, -200, 0, 20),
        "Out",
        "Quint",
        0.3,
        true
    )

    -- Auto-remove after 3 seconds
    game:GetService("Debris"):AddItem(notification, 3)

    -- Animate out before destruction
    spawn(function()
        wait(2.5)
        if notification and notification.Parent then
            notification:TweenPosition(
                UDim2.new(0.5, -200, 0, -70),
                "In",
                "Quint",
                0.3,
                true
            )
        end
    end)
end

-- Enhanced bounty display with proper cleanup
function BountySystem:CreateBountyDisplay(amount)
    self:RemoveBountyDisplay() -- Clean up existing display first

    bountyDisplay = Instance.new("ScreenGui")
    bountyDisplay.Name = "BountyDisplay"
    bountyDisplay.ResetOnSpawn = false -- Prevent auto-removal on respawn
    bountyDisplay.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(200, 50)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 215, 0)
    frame.Parent = bountyDisplay
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "[BOUNTY: " .. amount .. "]"
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = frame
    
    -- Position above character
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local connection
            connection = game:GetService("RunService").Heartbeat:Connect(function()
                if character and humanoidRootPart and humanoidRootPart.Parent and bountyDisplay and bountyDisplay.Parent then
                    local camera = workspace.CurrentCamera
                    local screenPosition = camera:WorldToViewportPoint(humanoidRootPart.Position + Vector3.new(0, 5, 0))
                    
                    if screenPosition.Z > 0 then
                        frame.Position = UDim2.fromOffset(screenPosition.X - 100, screenPosition.Y - 60)
                        frame.Visible = true
                    else
                        frame.Visible = false
                    end
                else
                    connection:Disconnect()
                end
            end)
        end
    end
end

-- Enhanced bounty display removal with connection cleanup
function BountySystem:RemoveBountyDisplay()
    if bountyDisplay then
        bountyDisplay:Destroy()
        bountyDisplay = nil
    end

    -- Clean up any position update connections
    for _, connection in pairs(bountyConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    bountyConnections = {}
end

-- Enhanced notification system with auto-cleanup
function BountySystem:CreateNotification(text, color, duration)
    duration = duration or 3 -- Default 3 seconds

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BountyNotification_" .. tick() -- Unique name to prevent conflicts
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Track this notification
    table.insert(activeNotifications, screenGui)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(400, 80)
    frame.Position = UDim2.new(0.5, -200, 0, 20)
    frame.BackgroundColor3 = color or Color3.fromRGB(255, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = frame
    
    -- Enhanced animation with proper cleanup
    local fadeOut = TweenService:Create(
        frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -200, 0, -60) -- Slide up while fading
        }
    )

    local fadeOutLabel = TweenService:Create(
        label,
        TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {TextTransparency = 1}
    )

    -- Auto-fade after duration
    task.delay(duration, function()
        if screenGui and screenGui.Parent then
            fadeOut:Play()
            fadeOutLabel:Play()
        end
    end)

    fadeOut.Completed:Connect(function()
        -- Remove from tracking list
        for i, notification in ipairs(activeNotifications) do
            if notification == screenGui then
                table.remove(activeNotifications, i)
                break
            end
        end

        if screenGui then
            screenGui:Destroy()
        end
    end)
end

-- Create bounty menu GUI
local function createBountyMenu()
    if bountyMenu then
        bountyMenu:Destroy()
    end
    
    bountyMenu = Instance.new("ScreenGui")
    bountyMenu.Name = "BountyMenu"
    bountyMenu.ResetOnSpawn = false
    bountyMenu.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.fromOffset(500, 600)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = bountyMenu
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(500, 50)
    title.Position = UDim2.fromOffset(0, 0)
    title.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    title.BorderSizePixel = 0
    title.Text = "BOUNTY SYSTEM"
    title.TextColor3 = Color3.fromRGB(0, 0, 0)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.fromOffset(30, 30)
    closeButton.Position = UDim2.fromOffset(460, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = title
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        bountyMenu:Destroy()
        bountyMenu = nil
    end)
    
    -- Player list frame
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.fromOffset(480, 400)
    playerListFrame.Position = UDim2.fromOffset(10, 70)
    playerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    playerListFrame.BorderSizePixel = 0
    playerListFrame.Parent = mainFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 5)
    listCorner.Parent = playerListFrame
    
    -- Scroll frame for players
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.fromScale(1, 1)
    scrollFrame.Position = UDim2.fromOffset(0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = playerListFrame
    
    -- Player list
    local playerList = Instance.new("UIListLayout")
    playerList.SortOrder = Enum.SortOrder.LayoutOrder
    playerList.Padding = UDim.new(0, 2)
    playerList.Parent = scrollFrame
    
    -- Amount input frame
    local amountFrame = Instance.new("Frame")
    amountFrame.Size = UDim2.fromOffset(480, 60)
    amountFrame.Position = UDim2.fromOffset(10, 480)
    amountFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    amountFrame.BorderSizePixel = 0
    amountFrame.Parent = mainFrame
    
    local amountCorner = Instance.new("UICorner")
    amountCorner.CornerRadius = UDim.new(0, 5)
    amountCorner.Parent = amountFrame
    
    local amountLabel = Instance.new("TextLabel")
    amountLabel.Size = UDim2.fromOffset(100, 60)
    amountLabel.Position = UDim2.fromOffset(0, 0)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Text = "Amount:"
    amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountLabel.TextScaled = true
    amountLabel.Font = Enum.Font.SourceSansBold
    amountLabel.Parent = amountFrame
    
    local amountBox = Instance.new("TextBox")
    amountBox.Size = UDim2.fromOffset(200, 40)
    amountBox.Position = UDim2.fromOffset(110, 10)
    amountBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    amountBox.BorderSizePixel = 0
    amountBox.Text = "1000"
    amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountBox.TextScaled = true
    amountBox.Font = Enum.Font.SourceSans
    amountBox.PlaceholderText = "Enter amount..."
    amountBox.Parent = amountFrame
    
    local amountBoxCorner = Instance.new("UICorner")
    amountBoxCorner.CornerRadius = UDim.new(0, 5)
    amountBoxCorner.Parent = amountBox
    
    -- Place bounty button
    local placeButton = Instance.new("TextButton")
    placeButton.Size = UDim2.fromOffset(150, 40)
    placeButton.Position = UDim2.fromOffset(320, 10)
    placeButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    placeButton.BorderSizePixel = 0
    placeButton.Text = "PLACE BOUNTY"
    placeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    placeButton.TextScaled = true
    placeButton.Font = Enum.Font.SourceSansBold
    placeButton.Parent = amountFrame
    
    local placeCorner = Instance.new("UICorner")
    placeCorner.CornerRadius = UDim.new(0, 5)
    placeCorner.Parent = placeButton
    
    -- Populate player list
    local function updatePlayerList()
        -- Clear existing buttons
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local yOffset = 0
        
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.fromOffset(460, 40)
            playerButton.Position = UDim2.fromOffset(0, yOffset)
            playerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            playerButton.BorderSizePixel = 0
            playerButton.Text = otherPlayer.Name .. (otherPlayer == player and " (YOU)" or "")
            playerButton.TextColor3 = otherPlayer == player and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
            playerButton.TextScaled = true
            playerButton.Font = Enum.Font.SourceSans
            playerButton.Parent = scrollFrame
            
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 5)
            buttonCorner.Parent = playerButton
            
            -- Highlight selected player
            if selectedPlayer == otherPlayer then
                playerButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                playerButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            end
            
            playerButton.MouseButton1Click:Connect(function()
                selectedPlayer = otherPlayer
                updatePlayerList()
            end)
            
            yOffset = yOffset + 42
        end
        
        scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset)
    end
    
    -- Place bounty button functionality
    placeButton.MouseButton1Click:Connect(function()
        if not selectedPlayer then
            createNotification("Please select a player!", Color3.fromRGB(255, 0, 0))
            return
        end
        
        local amount = tonumber(amountBox.Text)
        if not amount or amount < 100 or amount > 1000000 then
            createNotification("Invalid amount! Must be between 100 and 1,000,000", Color3.fromRGB(255, 0, 0))
            return
        end
        
        placeBountyEvent:FireServer(selectedPlayer, amount)
        bountyMenu:Destroy()
        bountyMenu = nil
        
        local message = selectedPlayer == player and 
            "Placed bounty of " .. amount .. " on yourself!" or
            "Placed bounty of " .. amount .. " on " .. selectedPlayer.Name .. "!"
        createNotification(message, Color3.fromRGB(0, 255, 0))
    end)
    
    -- Initial player list update
    updatePlayerList()
    
    -- Update player list when players join/leave
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)
end

-- Handle bounty notifications
local bountyNotification = ReplicatedStorage:WaitForChild("BountyNotification")
bountyNotification.OnClientEvent:Connect(function(action, player1, player2, amount)
    if action == "placed" then
        local message = player1:find("(SELF)") and 
            player1 .. " placed a bounty of " .. amount .. " on themselves!" or
            player1 .. " placed a bounty of " .. amount .. " on " .. player2 .. "!"
        createNotification(message, Color3.fromRGB(255, 215, 0))
    elseif action == "claimed" then
        local message = player1 .. " claimed a bounty of " .. amount .. " for killing " .. player2 .. "!"
        createNotification(message, Color3.fromRGB(0, 255, 0))
    elseif action == "cleared" then
        local message = "Bounty of " .. amount .. " on " .. player1 .. " was cleared due to " .. player2 .. "!"
        createNotification(message, Color3.fromRGB(255, 100, 0))
    elseif action == "bountyDisplay" then
        if player2 == "show" then
            createBountyDisplay(amount)
        elseif player2 == "hide" then
            removeBountyDisplay()
        end
    end
end)

-- Input handling - Press B to open bounty menu
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.B then
        if bountyMenu then
            bountyMenu:Destroy()
            bountyMenu = nil
        else
            createBountyMenu()
        end
    end
end)

-- Enhanced cleanup and management functions
function BountySystem:CleanupAll()
    -- Remove bounty display
    self:RemoveBountyDisplay()

    -- Close bounty menu
    if bountyMenu then
        bountyMenu:Destroy()
        bountyMenu = nil
    end

    -- Clear all notifications
    for _, notification in pairs(activeNotifications) do
        if notification and notification.Parent then
            notification:Destroy()
        end
    end
    activeNotifications = {}

    -- Remove any leftover highlight effects
    self:RemoveAllHighlights()
end

function BountySystem:RemoveAllHighlights()
    -- Remove highlight from all players
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer.Character then
            local highlight = otherPlayer.Character:FindFirstChild("BountyHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
end

function BountySystem:HandlePlayerDeath(targetPlayer)
    -- Remove bounty display and highlights when player dies
    if targetPlayer == player then
        self:RemoveBountyDisplay()
    end

    -- Remove highlight from dead player
    if targetPlayer.Character then
        local highlight = targetPlayer.Character:FindFirstChild("BountyHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

function BountySystem:AddBountyHighlight(targetPlayer)
    if not targetPlayer.Character then return end

    -- Remove existing highlight
    local existingHighlight = targetPlayer.Character:FindFirstChild("BountyHighlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end

    -- Add new highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "BountyHighlight"
    highlight.FillColor = Color3.fromRGB(255, 100, 100)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
    highlight.OutlineTransparency = 0.2
    highlight.Parent = targetPlayer.Character
end

-- Player death cleanup
Players.PlayerRemoving:Connect(function(leavingPlayer)
    BountySystem:HandlePlayerDeath(leavingPlayer)
end)

-- Character respawn cleanup
player.CharacterAdded:Connect(function(character)
    -- Clean up any UI when respawning
    BountySystem:RemoveBountyDisplay()

    character.Humanoid.Died:Connect(function()
        BountySystem:HandlePlayerDeath(player)
    end)
end)

-- Handle current character if already spawned
if player.Character and player.Character:FindFirstChild("Humanoid") then
    player.Character.Humanoid.Died:Connect(function()
        BountySystem:HandlePlayerDeath(player)
    end)
end

-- Initialize cleanup on script start
BountySystem:CleanupAll()

print("Enhanced Bounty System Client loaded - Press B to open bounty menu")