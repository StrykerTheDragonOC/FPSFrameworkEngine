-- KillfeedSystem.lua
-- Advanced killfeed system with player icons, weapons, and animations
-- Place in ReplicatedStorage/FPSSystem/Modules

local KillfeedSystem = {}
KillfeedSystem.__index = KillfeedSystem

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Killfeed configuration
local KILLFEED_CONFIG = {
    maxEntries = 8,
    entryLifetime = 6.0,
    animationSpeed = 0.3,
    entryHeight = 45,
    entrySpacing = 5,
    fadeTime = 1.0
}

-- Team colors
local TEAM_COLORS = {
    FBI = Color3.fromRGB(100, 150, 255),
    KFC = Color3.fromRGB(255, 100, 100),
    Neutral = Color3.fromRGB(200, 200, 200)
}

function KillfeedSystem.new()
    local self = setmetatable({}, KillfeedSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    
    -- Killfeed state
    self.killfeedEntries = {}
    self.entryCount = 0
    self.killfeedGui = nil
    self.killfeedContainer = nil
    
    -- Remote events
    self.remoteEvents = {}
    
    -- Initialize
    self:initialize()
    
    return self
end

-- Initialize the killfeed system
function KillfeedSystem:initialize()
    print("[KillfeedSystem] Initializing killfeed system...")
    
    -- Create killfeed GUI
    self:createKillfeedGui()
    
    -- Setup remote events
    self:setupRemoteEvents()
    
    -- Setup test data (remove in production)
    self:setupTestData()
    
    print("[KillfeedSystem] Killfeed system initialized")
end

-- Create killfeed GUI
function KillfeedSystem:createKillfeedGui()
    local killfeedGui = Instance.new("ScreenGui")
    killfeedGui.Name = "KillfeedSystem"
    killfeedGui.ResetOnSpawn = false
    killfeedGui.IgnoreGuiInset = true
    killfeedGui.Enabled = true
    killfeedGui.Parent = self.playerGui
    
    self.killfeedGui = killfeedGui
    
    -- Killfeed container
    local killfeedContainer = Instance.new("Frame")
    killfeedContainer.Name = "KillfeedContainer"
    killfeedContainer.Size = UDim2.new(0, 400, 0, (KILLFEED_CONFIG.entryHeight + KILLFEED_CONFIG.entrySpacing) * KILLFEED_CONFIG.maxEntries)
    killfeedContainer.Position = UDim2.new(1, -420, 0, 100)
    killfeedContainer.BackgroundTransparency = 1
    killfeedContainer.Parent = killfeedGui
    
    self.killfeedContainer = killfeedContainer
    
    print("[KillfeedSystem] Killfeed GUI created")
end

-- Setup remote events for killfeed data
function KillfeedSystem:setupRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        warn("[KillfeedSystem] FPSSystem not found in ReplicatedStorage")
        return
    end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        warn("[KillfeedSystem] RemoteEvents not found in FPSSystem")
        return
    end
    
    -- Player damage/kill remote
    local playerDamageRemote = remoteEvents:FindFirstChild("PlayerDamage")
    if playerDamageRemote then
        playerDamageRemote.OnClientEvent:Connect(function(data)
            self:handleKillEvent(data)
        end)
        self.remoteEvents.playerDamage = playerDamageRemote
        print("[KillfeedSystem] Connected to PlayerDamage remote")
    end
end

-- Handle kill event from server
function KillfeedSystem:handleKillEvent(data)
    if data.type == "kill" then
        self:addKillEntry(data.killer, data.victim, data.weapon, data.method)
    elseif data.type == "suicide" then
        self:addSuicideEntry(data.victim, data.method)
    elseif data.type == "teamkill" then
        self:addTeamKillEntry(data.killer, data.victim, data.weapon)
    end
end

-- Add kill entry to killfeed
function KillfeedSystem:addKillEntry(killerName, victimName, weaponName, method)
    local entryData = {
        type = "kill",
        killer = killerName,
        victim = victimName,
        weapon = weaponName or "Unknown",
        method = method or "normal",
        timestamp = tick(),
        id = self.entryCount + 1
    }
    
    self:createKillfeedEntry(entryData)
end

-- Add suicide entry to killfeed
function KillfeedSystem:addSuicideEntry(victimName, method)
    local entryData = {
        type = "suicide",
        victim = victimName,
        method = method or "suicide",
        timestamp = tick(),
        id = self.entryCount + 1
    }
    
    self:createKillfeedEntry(entryData)
end

-- Add team kill entry to killfeed
function KillfeedSystem:addTeamKillEntry(killerName, victimName, weaponName)
    local entryData = {
        type = "teamkill",
        killer = killerName,
        victim = victimName,
        weapon = weaponName or "Unknown",
        timestamp = tick(),
        id = self.entryCount + 1
    }
    
    self:createKillfeedEntry(entryData)
end

-- Create killfeed entry GUI
function KillfeedSystem:createKillfeedEntry(entryData)
    -- Remove oldest entry if at max capacity
    if #self.killfeedEntries >= KILLFEED_CONFIG.maxEntries then
        self:removeOldestEntry()
    end
    
    -- Create entry frame
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = "KillfeedEntry" .. entryData.id
    entryFrame.Size = UDim2.new(1, 0, 0, KILLFEED_CONFIG.entryHeight)
    entryFrame.Position = UDim2.new(0, 0, 0, #self.killfeedEntries * (KILLFEED_CONFIG.entryHeight + KILLFEED_CONFIG.entrySpacing))
    entryFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    entryFrame.BackgroundTransparency = 0.3
    entryFrame.BorderSizePixel = 0
    entryFrame.Parent = self.killfeedContainer
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = entryFrame
    
    local entryStroke = Instance.new("UIStroke")
    entryStroke.Color = Color3.fromRGB(85, 170, 187)
    entryStroke.Thickness = 1
    entryStroke.Transparency = 0.5
    entryStroke.Parent = entryFrame
    
    -- Create entry content based on type
    if entryData.type == "kill" then
        self:createKillEntryContent(entryFrame, entryData)
    elseif entryData.type == "suicide" then
        self:createSuicideEntryContent(entryFrame, entryData)
    elseif entryData.type == "teamkill" then
        self:createTeamKillEntryContent(entryFrame, entryData)
    end
    
    -- Add to entries list
    entryData.frame = entryFrame
    table.insert(self.killfeedEntries, entryData)
    self.entryCount = self.entryCount + 1
    
    -- Animate entry appearance
    entryFrame.Position = UDim2.new(1, 0, entryFrame.Position.Y.Scale, entryFrame.Position.Y.Offset)
    local appearTween = TweenService:Create(entryFrame,
        TweenInfo.new(KILLFEED_CONFIG.animationSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, entryFrame.Position.Y.Scale, entryFrame.Position.Y.Offset)}
    )
    appearTween:Play()
    
    -- Schedule entry removal
    task.delay(KILLFEED_CONFIG.entryLifetime, function()
        self:removeEntry(entryData.id)
    end)
    
    print("[KillfeedSystem] Added", entryData.type, "entry:", entryData.killer or "N/A", "->", entryData.victim)
end

-- Create kill entry content
function KillfeedSystem:createKillEntryContent(entryFrame, entryData)
    -- Killer info
    local killerFrame = Instance.new("Frame")
    killerFrame.Size = UDim2.new(0.35, 0, 1, 0)
    killerFrame.BackgroundTransparency = 1
    killerFrame.Parent = entryFrame
    
    -- Killer avatar (placeholder)
    local killerAvatar = Instance.new("Frame")
    killerAvatar.Size = UDim2.new(0, 30, 0, 30)
    killerAvatar.Position = UDim2.new(0, 5, 0.5, -15)
    killerAvatar.BackgroundColor3 = self:getPlayerTeamColor(entryData.killer)
    killerAvatar.BorderSizePixel = 0
    killerAvatar.Parent = killerFrame
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = killerAvatar
    
    -- Killer name
    local killerName = Instance.new("TextLabel")
    killerName.Size = UDim2.new(1, -40, 1, 0)
    killerName.Position = UDim2.new(0, 40, 0, 0)
    killerName.BackgroundTransparency = 1
    killerName.Text = entryData.killer
    killerName.TextColor3 = self:getPlayerTeamColor(entryData.killer)
    killerName.TextScaled = true
    killerName.Font = Enum.Font.GothamBold
    killerName.TextXAlignment = Enum.TextXAlignment.Left
    killerName.Parent = killerFrame
    
    -- Weapon/method info
    local weaponFrame = Instance.new("Frame")
    weaponFrame.Size = UDim2.new(0.3, 0, 1, 0)
    weaponFrame.Position = UDim2.new(0.35, 0, 0, 0)
    weaponFrame.BackgroundTransparency = 1
    weaponFrame.Parent = entryFrame
    
    -- Weapon icon (placeholder)
    local weaponIcon = Instance.new("TextLabel")
    weaponIcon.Size = UDim2.new(0, 25, 0, 25)
    weaponIcon.Position = UDim2.new(0.5, -12.5, 0.5, -12.5)
    weaponIcon.BackgroundTransparency = 1
    weaponIcon.Text = self:getWeaponIcon(entryData.weapon, entryData.method)
    weaponIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    weaponIcon.TextScaled = true
    weaponIcon.Font = Enum.Font.Gotham
    weaponIcon.Parent = weaponFrame
    
    -- Victim info
    local victimFrame = Instance.new("Frame")
    victimFrame.Size = UDim2.new(0.35, 0, 1, 0)
    victimFrame.Position = UDim2.new(0.65, 0, 0, 0)
    victimFrame.BackgroundTransparency = 1
    victimFrame.Parent = entryFrame
    
    -- Victim avatar (placeholder)
    local victimAvatar = Instance.new("Frame")
    victimAvatar.Size = UDim2.new(0, 30, 0, 30)
    victimAvatar.Position = UDim2.new(1, -35, 0.5, -15)
    victimAvatar.BackgroundColor3 = self:getPlayerTeamColor(entryData.victim)
    victimAvatar.BorderSizePixel = 0
    victimAvatar.Parent = victimFrame
    
    local victimAvatarCorner = Instance.new("UICorner")
    victimAvatarCorner.CornerRadius = UDim.new(1, 0)
    victimAvatarCorner.Parent = victimAvatar
    
    -- Victim name
    local victimName = Instance.new("TextLabel")
    victimName.Size = UDim2.new(1, -40, 1, 0)
    victimName.BackgroundTransparency = 1
    victimName.Text = entryData.victim
    victimName.TextColor3 = self:getPlayerTeamColor(entryData.victim)
    victimName.TextScaled = true
    victimName.Font = Enum.Font.GothamBold
    victimName.TextXAlignment = Enum.TextXAlignment.Right
    victimName.Parent = victimFrame
end

-- Create suicide entry content
function KillfeedSystem:createSuicideEntryContent(entryFrame, entryData)
    -- Victim info (centered)
    local victimFrame = Instance.new("Frame")
    victimFrame.Size = UDim2.new(0.6, 0, 1, 0)
    victimFrame.Position = UDim2.new(0.2, 0, 0, 0)
    victimFrame.BackgroundTransparency = 1
    victimFrame.Parent = entryFrame
    
    -- Victim avatar
    local victimAvatar = Instance.new("Frame")
    victimAvatar.Size = UDim2.new(0, 30, 0, 30)
    victimAvatar.Position = UDim2.new(0, 5, 0.5, -15)
    victimAvatar.BackgroundColor3 = self:getPlayerTeamColor(entryData.victim)
    victimAvatar.BorderSizePixel = 0
    victimAvatar.Parent = victimFrame
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = victimAvatar
    
    -- Suicide text
    local suicideText = Instance.new("TextLabel")
    suicideText.Size = UDim2.new(1, -40, 1, 0)
    suicideText.Position = UDim2.new(0, 40, 0, 0)
    suicideText.BackgroundTransparency = 1
    suicideText.Text = entryData.victim .. " eliminated themselves"
    suicideText.TextColor3 = Color3.fromRGB(200, 200, 200)
    suicideText.TextScaled = true
    suicideText.Font = Enum.Font.Gotham
    suicideText.TextXAlignment = Enum.TextXAlignment.Center
    suicideText.Parent = victimFrame
end

-- Create team kill entry content
function KillfeedSystem:createTeamKillEntryContent(entryFrame, entryData)
    -- Similar to kill entry but with different styling
    self:createKillEntryContent(entryFrame, entryData)
    
    -- Add team kill indicator
    local teamKillIndicator = Instance.new("Frame")
    teamKillIndicator.Size = UDim2.new(1, 0, 0, 3)
    teamKillIndicator.Position = UDim2.new(0, 0, 1, -3)
    teamKillIndicator.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    teamKillIndicator.BorderSizePixel = 0
    teamKillIndicator.Parent = entryFrame
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 4)
    indicatorCorner.Parent = teamKillIndicator
end

-- Get player team color
function KillfeedSystem:getPlayerTeamColor(playerName)
    local player = Players:FindFirstChild(playerName)
    if player and player.Team then
        if player.Team.Name == "FBI" then
            return TEAM_COLORS.FBI
        elseif player.Team.Name == "KFC" then
            return TEAM_COLORS.KFC
        end
    end
    return TEAM_COLORS.Neutral
end

-- Get weapon icon based on weapon name
function KillfeedSystem:getWeaponIcon(weaponName, method)
    local weaponIcons = {
        -- Primary weapons
        ["AK-47"] = "🔫",
        ["G36"] = "🔫",
        ["M4A1"] = "🔫",
        ["AWM"] = "🎯",
        
        -- Secondary weapons
        ["M9"] = "🔫",
        ["Glock"] = "🔫",
        
        -- Melee weapons
        ["PocketKnife"] = "🔪",
        ["Knife"] = "🔪",
        
        -- Grenades
        ["M67"] = "💣",
        ["Flashbang"] = "💥",
        
        -- Special methods
        ["headshot"] = "🎯",
        ["explosion"] = "💥",
        ["fall"] = "⬇️",
        ["suicide"] = "💀"
    }
    
    -- Check method first for special icons
    if method and weaponIcons[method] then
        return weaponIcons[method]
    end
    
    -- Check weapon name
    if weaponName and weaponIcons[weaponName] then
        return weaponIcons[weaponName]
    end
    
    -- Default icon
    return "⚔️"
end

-- Remove oldest entry
function KillfeedSystem:removeOldestEntry()
    if #self.killfeedEntries > 0 then
        local oldestEntry = self.killfeedEntries[1]
        self:removeEntry(oldestEntry.id)
    end
end

-- Remove entry by ID
function KillfeedSystem:removeEntry(entryId)
    for i, entry in ipairs(self.killfeedEntries) do
        if entry.id == entryId then
            -- Animate entry removal
            if entry.frame and entry.frame.Parent then
                local removeTween = TweenService:Create(entry.frame,
                    TweenInfo.new(KILLFEED_CONFIG.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Position = UDim2.new(1, 0, entry.frame.Position.Y.Scale, entry.frame.Position.Y.Offset),
                        BackgroundTransparency = 1
                    }
                )
                removeTween:Play()
                
                removeTween.Completed:Connect(function()
                    entry.frame:Destroy()
                end)
            end
            
            -- Remove from entries list
            table.remove(self.killfeedEntries, i)
            
            -- Reposition remaining entries
            self:repositionEntries()
            break
        end
    end
end

-- Reposition entries after removal
function KillfeedSystem:repositionEntries()
    for i, entry in ipairs(self.killfeedEntries) do
        if entry.frame and entry.frame.Parent then
            local newPosition = UDim2.new(0, 0, 0, (i - 1) * (KILLFEED_CONFIG.entryHeight + KILLFEED_CONFIG.entrySpacing))
            
            local repositionTween = TweenService:Create(entry.frame,
                TweenInfo.new(KILLFEED_CONFIG.animationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = newPosition}
            )
            repositionTween:Play()
        end
    end
end

-- Setup test data for demonstration
function KillfeedSystem:setupTestData()
    -- Add some test killfeed entries after a delay
    task.delay(2, function()
        self:addKillEntry("Player1", "Player2", "AK-47", "headshot")
        
        task.delay(1, function()
            self:addSuicideEntry("Player3", "fall")
            
            task.delay(1, function()
                self:addTeamKillEntry("Player4", "Player5", "M9")
                
                task.delay(1, function()
                    self:addKillEntry("Player6", "Player7", "AWM", "normal")
                end)
            end)
        end)
    end)
end

-- Cleanup
function KillfeedSystem:cleanup()
    print("[KillfeedSystem] Cleaning up killfeed system...")
    
    -- Clear all entries
    for _, entry in pairs(self.killfeedEntries) do
        if entry.frame then
            entry.frame:Destroy()
        end
    end
    self.killfeedEntries = {}
    
    -- Destroy GUI
    if self.killfeedGui then
        self.killfeedGui:Destroy()
    end
    
    print("[KillfeedSystem] Killfeed cleanup complete")
end

return KillfeedSystem