-- ScoreboardController.lua
-- Real scoreboard controller with functional player lists, team scores, and TAB toggle
-- Place in ReplicatedStorage/FPSSystem/Modules

local ScoreboardController = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

-- Initialize scoreboard controller
function ScoreboardController.init()
    print("[ScoreboardController] Initializing scoreboard system...")
    
    -- Core references
    ScoreboardController.player = Players.LocalPlayer
    ScoreboardController.playerGui = ScoreboardController.player:WaitForChild("PlayerGui")
    
    -- Scoreboard state
    ScoreboardController.scoreboardState = {
        isVisible = false,
        isAnimating = false,
        playerData = {},
        teamScores = {FBI = 0, KFC = 0},
        sortMode = "Score", -- "Score", "Kills", "Deaths", "KDR", "Name"
        sortAscending = false,
        updateTimer = 0
    }
    
    -- Connections
    ScoreboardController.connections = {}
    ScoreboardController.updateConnections = {}
    
    -- Wait for scoreboard GUI and initialize
    task.spawn(function()
        ScoreboardController:waitForScoreboardGui()
    end)
    
    -- Setup input handling
    ScoreboardController:setupInputHandling()
    
    -- Setup remote events
    ScoreboardController:setupRemoteEvents()
    
    -- Setup player monitoring
    ScoreboardController:setupPlayerMonitoring()
    
    print("[ScoreboardController] Scoreboard system initialized")
end

-- Wait for scoreboard GUI to be created
function ScoreboardController:waitForScoreboardGui()
    local scoreboardGui = nil
    local attempts = 0
    
    -- Wait up to 10 seconds for scoreboard to be created
    while not scoreboardGui and attempts < 100 do
        scoreboardGui = self.playerGui:FindFirstChild("FPSScoreboard")
        if not scoreboardGui then
            task.wait(0.1)
            attempts = attempts + 1
        end
    end
    
    if scoreboardGui then
        self.scoreboardGui = scoreboardGui
        self.scoreboardContainer = scoreboardGui:FindFirstChild("ScoreboardContainer")
        print("[ScoreboardController] Scoreboard GUI found, setting up functionality")
        
        -- Initially hide scoreboard
        self.scoreboardGui.Enabled = false
        
        -- Setup scoreboard functionality
        self:setupScoreboardFunctionality()
        
        -- Start update loops
        self:startScoreboardUpdates()
    else
        warn("[ScoreboardController] Scoreboard GUI not found after waiting!")
    end
end

-- Setup scoreboard functionality
function ScoreboardController:setupScoreboardFunctionality()
    if not self.scoreboardContainer then return end
    
    print("[ScoreboardController] Setting up scoreboard functionality...")
    
    -- Setup team containers
    self:setupTeamContainers()
    
    -- Setup header functionality
    self:setupHeaderFunctionality()
    
    -- Setup sorting functionality
    self:setupSortingFunctionality()
    
    -- Initial player list population
    self:populatePlayerLists()
end

-- Setup team containers
function ScoreboardController:setupTeamContainers()
    -- Find team containers
    self.fbiContainer = self.scoreboardContainer:FindFirstChild("FBITeamContainer")
    self.kfcContainer = self.scoreboardContainer:FindFirstChild("KFCTeamContainer")
    
    if self.fbiContainer then
        local fbiList = self.fbiContainer:FindFirstChild("PlayerList")
        if fbiList then
            self.fbiPlayerList = fbiList:FindFirstChild("ListContainer")
        end
    end
    
    if self.kfcContainer then
        local kfcList = self.kfcContainer:FindFirstChild("PlayerList")
        if kfcList then
            self.kfcPlayerList = kfcList:FindFirstChild("ListContainer")
        end
    end
    
    print("[ScoreboardController] Team containers setup complete")
end

-- Setup header functionality
function ScoreboardController:setupHeaderFunctionality()
    -- Setup sortable column headers
    local headers = {"Name", "Score", "Kills", "Deaths", "KDR", "Ping"}
    
    for _, headerName in ipairs(headers) do
        self:setupSortHeader(headerName)
    end
end

-- Setup sort header
function ScoreboardController:setupSortHeader(headerName)
    -- Find header in both team containers
    if self.fbiContainer then
        local header = self.fbiContainer:FindFirstChild(headerName .. "Header", true)
        if header and header:IsA("GuiButton") then
            header.MouseButton1Click:Connect(function()
                self:setSortMode(headerName)
            end)
        end
    end
    
    if self.kfcContainer then
        local header = self.kfcContainer:FindFirstChild(headerName .. "Header", true)
        if header and header:IsA("GuiButton") then
            header.MouseButton1Click:Connect(function()
                self:setSortMode(headerName)
            end)
        end
    end
end

-- Setup sorting functionality
function ScoreboardController:setupSortingFunctionality()
    -- Default sort by score
    self:setSortMode("Score")
end

-- Set sort mode
function ScoreboardController:setSortMode(mode)
    if self.scoreboardState.sortMode == mode then
        -- Toggle between ascending/descending
        self.scoreboardState.sortAscending = not self.scoreboardState.sortAscending
    else
        self.scoreboardState.sortMode = mode
        self.scoreboardState.sortAscending = false -- Default to descending for most stats
    end
    
    -- Update sort indicators
    self:updateSortIndicators()
    
    -- Re-sort and update player lists
    self:updatePlayerLists()
    
    print("[ScoreboardController] Sort mode set to:", mode)
end

-- Update sort indicators
function ScoreboardController:updateSortIndicators()
    -- Clear existing indicators
    self:clearSortIndicators()
    
    -- Add indicator to current sort column
    local indicator = self.scoreboardState.sortAscending and "▲" or "▼"
    
    -- Add to both team headers
    if self.fbiContainer then
        local header = self.fbiContainer:FindFirstChild(self.scoreboardState.sortMode .. "Header", true)
        if header then
            header.Text = header.Text:gsub("[▲▼]", "") .. " " .. indicator
        end
    end
    
    if self.kfcContainer then
        local header = self.kfcContainer:FindFirstChild(self.scoreboardState.sortMode .. "Header", true)
        if header then
            header.Text = header.Text:gsub("[▲▼]", "") .. " " .. indicator
        end
    end
end

-- Clear sort indicators
function ScoreboardController:clearSortIndicators()
    local headers = {"Name", "Score", "Kills", "Deaths", "KDR", "Ping"}
    
    for _, headerName in ipairs(headers) do
        if self.fbiContainer then
            local header = self.fbiContainer:FindFirstChild(headerName .. "Header", true)
            if header then
                header.Text = header.Text:gsub("[▲▼]", ""):gsub("%s+$", "")
            end
        end
        
        if self.kfcContainer then
            local header = self.kfcContainer:FindFirstChild(headerName .. "Header", true)
            if header then
                header.Text = header.Text:gsub("[▲▼]", ""):gsub("%s+$", "")
            end
        end
    end
end

-- Setup input handling
function ScoreboardController:setupInputHandling()
    self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- TAB key for scoreboard toggle
        if input.KeyCode == Enum.KeyCode.Tab then
            self:showScoreboard()
        end
    end)
    
    self.connections.inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Tab then
            self:hideScoreboard()
        end
    end)
end

-- Show scoreboard
function ScoreboardController:showScoreboard()
    if not self.scoreboardGui or self.scoreboardState.isAnimating then return end
    
    self.scoreboardState.isVisible = true
    self.scoreboardState.isAnimating = true
    
    -- Update player data before showing
    self:updatePlayerData()
    self:updatePlayerLists()
    
    -- Show GUI
    self.scoreboardGui.Enabled = true
    
    -- Animate in
    if self.scoreboardContainer then
        self.scoreboardContainer.Position = UDim2.new(0.5, 0, 0.3, 0)
        self.scoreboardContainer.Size = UDim2.new(0, 0, 0, 0)
        
        local showTween = TweenService:Create(self.scoreboardContainer,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0.8, 0, 0.7, 0)
            }
        )
        showTween:Play()
        
        showTween.Completed:Connect(function()
            self.scoreboardState.isAnimating = false
        end)
    else
        self.scoreboardState.isAnimating = false
    end
    
    print("[ScoreboardController] Scoreboard shown")
end

-- Hide scoreboard
function ScoreboardController:hideScoreboard()
    if not self.scoreboardGui or self.scoreboardState.isAnimating or not self.scoreboardState.isVisible then return end
    
    self.scoreboardState.isVisible = false
    self.scoreboardState.isAnimating = true
    
    -- Animate out
    if self.scoreboardContainer then
        local hideTween = TweenService:Create(self.scoreboardContainer,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(0.5, 0, 0.3, 0),
                Size = UDim2.new(0, 0, 0, 0)
            }
        )
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            self.scoreboardGui.Enabled = false
            self.scoreboardState.isAnimating = false
        end)
    else
        self.scoreboardGui.Enabled = false
        self.scoreboardState.isAnimating = false
    end
    
    print("[ScoreboardController] Scoreboard hidden")
end

-- Start scoreboard update loops
function ScoreboardController:startScoreboardUpdates()
    -- Main update loop
    self.updateConnections.mainUpdate = RunService.Heartbeat:Connect(function()
        self.scoreboardState.updateTimer = self.scoreboardState.updateTimer + RunService.Heartbeat:Wait()
        
        -- Update every 2 seconds when visible
        if self.scoreboardState.isVisible and self.scoreboardState.updateTimer >= 2 then
            self:updatePlayerData()
            self:updatePlayerLists()
            self:updateTeamScoreDisplay()
            self.scoreboardState.updateTimer = 0
        end
    end)
    
    print("[ScoreboardController] Update loops started")
end

-- Setup player monitoring
function ScoreboardController:setupPlayerMonitoring()
    -- Monitor player additions
    self.connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        self:addPlayerData(player)
    end)
    
    -- Monitor player removals
    self.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:removePlayerData(player)
    end)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:addPlayerData(player)
    end
end

-- Add player data
function ScoreboardController:addPlayerData(player)
    self.scoreboardState.playerData[player.UserId] = {
        player = player,
        name = player.Name,
        team = self:getPlayerTeam(player),
        score = 0,
        kills = 0,
        deaths = 0,
        kdr = 0,
        ping = 0
    }
    
    print("[ScoreboardController] Added player data for", player.Name)
end

-- Remove player data
function ScoreboardController:removePlayerData(player)
    self.scoreboardState.playerData[player.UserId] = nil
    
    if self.scoreboardState.isVisible then
        self:updatePlayerLists()
    end
    
    print("[ScoreboardController] Removed player data for", player.Name)
end

-- Get player team
function ScoreboardController:getPlayerTeam(player)
    if player.Team then
        return player.Team.Name
    end
    
    -- Fallback to checking team in FPS system
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if fpsSystem then
        local playerData = fpsSystem:FindFirstChild("PlayerData")
        if playerData then
            local data = playerData:FindFirstChild(player.Name)
            if data and data:FindFirstChild("Team") then
                return data.Team.Value
            end
        end
    end
    
    return "Spectator"
end

-- Update player data
function ScoreboardController:updatePlayerData()
    for userId, data in pairs(self.scoreboardState.playerData) do
        local player = data.player
        
        if player and player.Parent then
            -- Update team
            data.team = self:getPlayerTeam(player)
            
            -- Update ping
            data.ping = math.floor(player:GetNetworkPing() * 1000)
            
            -- Calculate KDR
            if data.deaths > 0 then
                data.kdr = math.floor((data.kills / data.deaths) * 100) / 100
            else
                data.kdr = data.kills
            end
            
            -- Update score (kills * 100 - deaths * 50 for now)
            data.score = data.kills * 100 - data.deaths * 50
        end
    end
end

-- Populate player lists
function ScoreboardController:populatePlayerLists()
    self:updatePlayerData()
    self:updatePlayerLists()
end

-- Update player lists
function ScoreboardController:updatePlayerLists()
    if not self.fbiPlayerList or not self.kfcPlayerList then return end
    
    -- Clear existing entries
    self:clearPlayerLists()
    
    -- Sort players
    local sortedPlayers = self:getSortedPlayers()
    
    -- Separate by team
    local fbiPlayers = {}
    local kfcPlayers = {}
    
    for _, data in ipairs(sortedPlayers) do
        if data.team == "FBI" then
            table.insert(fbiPlayers, data)
        elseif data.team == "KFC" then
            table.insert(kfcPlayers, data)
        end
    end
    
    -- Create FBI entries
    for i, data in ipairs(fbiPlayers) do
        self:createPlayerEntry(data, self.fbiPlayerList, i)
    end
    
    -- Create KFC entries
    for i, data in ipairs(kfcPlayers) do
        self:createPlayerEntry(data, self.kfcPlayerList, i)
    end
    
    -- Update team counts
    self:updateTeamCounts(#fbiPlayers, #kfcPlayers)
end

-- Clear player lists
function ScoreboardController:clearPlayerLists()
    if self.fbiPlayerList then
        for _, child in ipairs(self.fbiPlayerList:GetChildren()) do
            if child:IsA("Frame") and child.Name:match("^PlayerEntry") then
                child:Destroy()
            end
        end
    end
    
    if self.kfcPlayerList then
        for _, child in ipairs(self.kfcPlayerList:GetChildren()) do
            if child:IsA("Frame") and child.Name:match("^PlayerEntry") then
                child:Destroy()
            end
        end
    end
end

-- Get sorted players
function ScoreboardController:getSortedPlayers()
    local players = {}
    
    for userId, data in pairs(self.scoreboardState.playerData) do
        if data.player and data.player.Parent then
            table.insert(players, data)
        end
    end
    
    -- Sort based on current sort mode
    table.sort(players, function(a, b)
        local aValue, bValue
        
        if self.scoreboardState.sortMode == "Name" then
            aValue = (a.name and a.name:lower()) or ""
            bValue = (b.name and b.name:lower()) or ""
        elseif self.scoreboardState.sortMode == "Score" then
            aValue = a.score or 0
            bValue = b.score or 0
        elseif self.scoreboardState.sortMode == "Kills" then
            aValue = a.kills or 0
            bValue = b.kills or 0
        elseif self.scoreboardState.sortMode == "Deaths" then
            aValue = a.deaths or 0
            bValue = b.deaths or 0
        elseif self.scoreboardState.sortMode == "KDR" then
            aValue = a.kdr or 0
            bValue = b.kdr or 0
        elseif self.scoreboardState.sortMode == "Ping" then
            aValue = a.ping or 0
            bValue = b.ping or 0
        else
            aValue = a.score or 0
            bValue = b.score or 0
        end
        
        if self.scoreboardState.sortAscending then
            return aValue < bValue
        else
            return aValue > bValue
        end
    end)
    
    return players
end

-- Create player entry
function ScoreboardController:createPlayerEntry(data, parentList, index)
    local entry = Instance.new("Frame")
    entry.Name = "PlayerEntry" .. index
    entry.Size = UDim2.new(1, 0, 0, 30)
    entry.Position = UDim2.new(0, 0, 0, (index - 1) * 30)
    entry.BackgroundColor3 = index % 2 == 0 and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(40, 40, 40)
    entry.BorderSizePixel = 0
    entry.Parent = parentList
    
    -- Highlight local player
    if data.player == self.player then
        entry.BackgroundColor3 = Color3.fromRGB(85, 170, 187)
    end
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(0.25, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- Score
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "PlayerScore"
    scoreLabel.Size = UDim2.new(0.15, 0, 1, 0)
    scoreLabel.Position = UDim2.new(0.25, 0, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = tostring(data.score)
    scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.Gotham
    scoreLabel.Parent = entry
    
    -- Kills
    local killsLabel = Instance.new("TextLabel")
    killsLabel.Name = "PlayerKills"
    killsLabel.Size = UDim2.new(0.15, 0, 1, 0)
    killsLabel.Position = UDim2.new(0.4, 0, 0, 0)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = tostring(data.kills)
    killsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    killsLabel.TextScaled = true
    killsLabel.Font = Enum.Font.Gotham
    killsLabel.Parent = entry
    
    -- Deaths
    local deathsLabel = Instance.new("TextLabel")
    deathsLabel.Name = "PlayerDeaths"
    deathsLabel.Size = UDim2.new(0.15, 0, 1, 0)
    deathsLabel.Position = UDim2.new(0.55, 0, 0, 0)
    deathsLabel.BackgroundTransparency = 1
    deathsLabel.Text = tostring(data.deaths)
    deathsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    deathsLabel.TextScaled = true
    deathsLabel.Font = Enum.Font.Gotham
    deathsLabel.Parent = entry
    
    -- KDR
    local kdrLabel = Instance.new("TextLabel")
    kdrLabel.Name = "PlayerKDR"
    kdrLabel.Size = UDim2.new(0.15, 0, 1, 0)
    kdrLabel.Position = UDim2.new(0.7, 0, 0, 0)
    kdrLabel.BackgroundTransparency = 1
    kdrLabel.Text = tostring(data.kdr)
    kdrLabel.TextColor3 = Color3.fromRGB(255, 180, 60)
    kdrLabel.TextScaled = true
    kdrLabel.Font = Enum.Font.Gotham
    kdrLabel.Parent = entry
    
    -- Ping
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PlayerPing"
    pingLabel.Size = UDim2.new(0.15, 0, 1, 0)
    pingLabel.Position = UDim2.new(0.85, 0, 0, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = tostring(data.ping) .. "ms"
    
    -- Color code ping
    if data.ping < 50 then
        pingLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
    elseif data.ping < 100 then
        pingLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow
    else
        pingLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
    end
    
    pingLabel.TextScaled = true
    pingLabel.Font = Enum.Font.Gotham
    pingLabel.Parent = entry
end

-- Update team counts
function ScoreboardController:updateTeamCounts(fbiCount, kfcCount)
    if self.fbiContainer then
        local fbiHeader = self.fbiContainer:FindFirstChild("TeamHeader")
        if fbiHeader then
            local fbiTitle = fbiHeader:FindFirstChild("TeamTitle")
            if fbiTitle then
                fbiTitle.Text = "FBI (" .. fbiCount .. ")"
            end
        end
    end
    
    if self.kfcContainer then
        local kfcHeader = self.kfcContainer:FindFirstChild("TeamHeader")
        if kfcHeader then
            local kfcTitle = kfcHeader:FindFirstChild("TeamTitle")
            if kfcTitle then
                kfcTitle.Text = "KFC (" .. kfcCount .. ")"
            end
        end
    end
end

-- Update team score display
function ScoreboardController:updateTeamScoreDisplay()
    if self.fbiContainer then
        local fbiScore = self.fbiContainer:FindFirstChild("TeamScore", true)
        if fbiScore then
            fbiScore.Text = tostring(self.scoreboardState.teamScores.FBI)
        end
    end
    
    if self.kfcContainer then
        local kfcScore = self.kfcContainer:FindFirstChild("TeamScore", true)
        if kfcScore then
            kfcScore.Text = tostring(self.scoreboardState.teamScores.KFC)
        end
    end
end

-- Setup remote events
function ScoreboardController:setupRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    -- Connect to score updates
    local scoreUpdate = remoteEvents:FindFirstChild("ScoreUpdate")
    if scoreUpdate then
        self.connections.scoreUpdate = scoreUpdate.OnClientEvent:Connect(function(scores)
            self:updateTeamScores(scores)
        end)
    end
    
    -- Connect to player damage for kill/death tracking
    local playerDamage = remoteEvents:FindFirstChild("PlayerDamage")
    if playerDamage then
        self.connections.playerDamage = playerDamage.OnClientEvent:Connect(function(damageData)
            self:updatePlayerStats(damageData)
        end)
    end
end

-- Update team scores from server
function ScoreboardController:updateTeamScores(scores)
    if scores then
        self.scoreboardState.teamScores = scores
        
        if self.scoreboardState.isVisible then
            self:updateTeamScoreDisplay()
        end
    end
end

-- Update player stats from damage events
function ScoreboardController:updatePlayerStats(damageData)
    if not damageData then return end
    
    -- Update killer stats
    if damageData.killer and damageData.killer.UserId then
        local killerData = self.scoreboardState.playerData[damageData.killer.UserId]
        if killerData then
            killerData.kills = killerData.kills + 1
        end
    end
    
    -- Update victim stats
    if damageData.victim and damageData.victim.UserId then
        local victimData = self.scoreboardState.playerData[damageData.victim.UserId]
        if victimData then
            victimData.deaths = victimData.deaths + 1
        end
    end
    
    -- Update display if visible
    if self.scoreboardState.isVisible then
        self:updatePlayerLists()
    end
end

-- Cleanup function
function ScoreboardController:cleanup()
    print("[ScoreboardController] Cleaning up scoreboard controller...")
    
    -- Disconnect all connections
    for name, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    for name, connection in pairs(self.updateConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Clear data
    self.connections = {}
    self.updateConnections = {}
    self.scoreboardState.playerData = {}
    
    print("[ScoreboardController] Scoreboard controller cleanup complete")
end

-- API functions for external systems
function ScoreboardController:updatePlayerKill(player)
    if player and player.UserId then
        local playerData = self.scoreboardState.playerData[player.UserId]
        if playerData then
            playerData.kills = playerData.kills + 1
        end
    end
end

function ScoreboardController:updatePlayerDeath(player)
    if player and player.UserId then
        local playerData = self.scoreboardState.playerData[player.UserId]
        if playerData then
            playerData.deaths = playerData.deaths + 1
        end
    end
end

function ScoreboardController:setPlayerScore(player, score)
    if player and player.UserId then
        local playerData = self.scoreboardState.playerData[player.UserId]
        if playerData then
            playerData.score = score
        end
    end
end

function ScoreboardController:isVisible()
    return self.scoreboardState.isVisible
end

return ScoreboardController