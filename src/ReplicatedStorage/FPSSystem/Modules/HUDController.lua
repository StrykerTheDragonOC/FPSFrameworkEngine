-- HUDController.lua
-- Real HUD controller with functional health, ammo, crosshair, and team score updates
-- Place in ReplicatedStorage/FPSSystem/Modules

local HUDController = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize HUD controller
function HUDController:init()
    print("[HUDController] Initializing HUD system...")
    
    -- Core references
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.character = nil
    self.humanoid = nil
    
    -- HUD state
    self.hudState = {
        health = 100,
        maxHealth = 100,
        currentAmmo = 30,
        reserveAmmo = 120,
        weaponName = "AK-47",
        fireMode = "AUTO",
        isReloading = false,
        reloadProgress = 0,
        crosshairSpread = 1.0,
        fps = 60,
        ping = 25,
        teamScores = {FBI = 0, KFC = 0}
    }
    
    -- Connections
    self.connections = {}
    self.updateConnections = {}
    
    -- Wait for HUD GUI and initialize
    task.spawn(function()
        self:waitForHUDGui()
    end)
    
    -- Setup character monitoring
    self:setupCharacterMonitoring()
    
    -- Setup performance monitoring
    self:setupPerformanceMonitoring()
    
    -- Setup input handling
    self:setupInputHandling()
    
    -- Setup remote event connections
    self:setupRemoteEvents()
    
    print("[HUDController] HUD system initialized")
end

-- Wait for HUD GUI to be created
function HUDController:waitForHUDGui()
    local hudGui = nil
    local attempts = 0
    
    -- Wait up to 10 seconds for HUD to be created
    while not hudGui and attempts < 100 do
        hudGui = self.playerGui:FindFirstChild("ModernHUD")
        if not hudGui then
            task.wait(0.1)
            attempts = attempts + 1
        end
    end
    
    if hudGui then
        self.hudGui = hudGui
        self.hudContainer = hudGui:FindFirstChild("HUDContainer")
        print("[HUDController] HUD GUI found, starting updates")
        
        -- Start HUD update loops
        self:startHUDUpdates()
    else
        warn("[HUDController] HUD GUI not found after waiting!")
    end
end

-- Setup character monitoring
function HUDController:setupCharacterMonitoring()
    local function onCharacterAdded(character)
        self.character = character
        self.humanoid = character:WaitForChild("Humanoid")
        
        -- Monitor health changes
        self.connections.healthChanged = self.humanoid.HealthChanged:Connect(function(health)
            self:updateHealthDisplay(health)
        end)
        
        -- Monitor died event
        self.connections.died = self.humanoid.Died:Connect(function()
            self:onPlayerDied()
        end)
        
        print("[HUDController] Character monitoring setup for", character.Name)
    end
    
    if self.player.Character then
        onCharacterAdded(self.player.Character)
    end
    
    self.connections.characterAdded = self.player.CharacterAdded:Connect(onCharacterAdded)
end

-- Start HUD update loops
function HUDController:startHUDUpdates()
    if not self.hudContainer then return end
    
    -- Main HUD update loop
    self.updateConnections.mainUpdate = RunService.Heartbeat:Connect(function()
        self:updateHealthSystem()
        self:updateWeaponSystem()
        self:updateCrosshair()
        self:updateTeamScores()
        self:updatePerformanceDisplay()
    end)
    
    print("[HUDController] HUD update loops started")
end

-- Update health system display
function HUDController:updateHealthSystem()
    if not self.character or not self.humanoid then return end
    
    local healthContainer = self.hudContainer:FindFirstChild("HealthSystemContainer")
    if not healthContainer then return end
    
    local currentHealth = self.humanoid.Health
    local maxHealth = self.humanoid.MaxHealth
    local healthPercent = maxHealth > 0 and currentHealth / maxHealth or 0
    
    -- Update health state
    self.hudState.health = currentHealth
    self.hudState.maxHealth = maxHealth
    
    -- Update health bar
    local healthFrame = healthContainer:FindFirstChild("HealthFrame")
    if healthFrame then
        local healthBarBg = healthFrame:FindFirstChild("HealthBarBg")
        if healthBarBg then
            local healthBar = healthBarBg:FindFirstChild("HealthBar")
            if healthBar then
                -- Animate health bar size
                local targetSize = UDim2.new(healthPercent, 0, 1, 0)
                local healthTween = TweenService:Create(healthBar,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = targetSize}
                )
                healthTween:Play()
                
                -- Update health bar color based on health level
                local healthColor
                if healthPercent > 0.6 then
                    healthColor = Color3.fromRGB(100, 255, 100) -- Green
                elseif healthPercent > 0.3 then
                    healthColor = Color3.fromRGB(255, 200, 100) -- Yellow
                else
                    healthColor = Color3.fromRGB(255, 100, 100) -- Red
                end
                healthBar.BackgroundColor3 = healthColor
            end
        end
        
        -- Update health text
        local healthText = healthFrame:FindFirstChild("HealthText")
        if healthText then
            healthText.Text = tostring(math.floor(currentHealth))
            
            -- Pulse effect when low health
            if healthPercent < 0.3 then
                local pulseIntensity = 0.7 + 0.3 * math.sin(tick() * 8)
                healthText.TextColor3 = Color3.new(pulseIntensity, 0.4, 0.4)
            else
                healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end

-- Update health display when health changes
function HUDController:updateHealthDisplay(newHealth)
    -- Trigger damage flash effect if health decreased
    if newHealth < self.hudState.health then
        local damageAmount = self.hudState.health - newHealth
        self:triggerDamageFlash(damageAmount)
    end
end

-- Trigger damage flash effect
function HUDController:triggerDamageFlash(damageAmount)
    local healthContainer = self.hudContainer:FindFirstChild("HealthSystemContainer")
    if not healthContainer then return end
    
    local healthFrame = healthContainer:FindFirstChild("HealthFrame")
    if not healthFrame then return end
    
    -- Create temporary damage overlay
    local damageOverlay = Instance.new("Frame")
    damageOverlay.Name = "DamageFlash"
    damageOverlay.Size = UDim2.new(1, 0, 1, 0)
    damageOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    damageOverlay.BackgroundTransparency = 1
    damageOverlay.BorderSizePixel = 0
    damageOverlay.ZIndex = 10
    damageOverlay.Parent = healthFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = damageOverlay
    
    -- Flash effect based on damage amount
    local flashIntensity = math.min(damageAmount / 50, 0.8)
    
    local flashTween = TweenService:Create(damageOverlay,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1 - flashIntensity}
    )
    flashTween:Play()
    
    flashTween.Completed:Connect(function()
        local fadeTween = TweenService:Create(damageOverlay,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            damageOverlay:Destroy()
        end)
    end)
end

-- Update weapon system display
function HUDController:updateWeaponSystem()
    local weaponContainer = self.hudContainer:FindFirstChild("WeaponInfoContainer")
    if not weaponContainer then return end
    
    local weaponFrame = weaponContainer:FindFirstChild("WeaponFrame")
    if not weaponFrame then return end
    
    -- Update weapon name
    local weaponName = weaponFrame:FindFirstChild("WeaponName")
    if weaponName then
        weaponName.Text = self.hudState.weaponName
    end
    
    -- Update ammo display
    local currentAmmo = weaponFrame:FindFirstChild("CurrentAmmo")
    if currentAmmo then
        currentAmmo.Text = tostring(self.hudState.currentAmmo)
        
        -- Color code based on ammo level
        local ammoPercent = self.hudState.currentAmmo / 30 -- Assuming 30 is full mag
        if ammoPercent <= 0.2 then
            currentAmmo.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red for low ammo
        else
            currentAmmo.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for normal
        end
    end
    
    local reserveAmmo = weaponFrame:FindFirstChild("ReserveAmmo")
    if reserveAmmo then
        reserveAmmo.Text = "/ " .. tostring(self.hudState.reserveAmmo)
    end
    
    -- Handle reload progress
    if self.hudState.isReloading then
        self:updateReloadProgress(weaponContainer)
    end
end

-- Update reload progress display
function HUDController:updateReloadProgress(weaponContainer)
    local reloadFrame = weaponContainer:FindFirstChild("ReloadFrame")
    if reloadFrame then
        reloadFrame.Visible = true
        
        -- This would be updated by weapon system when reloading
        -- For now, we'll simulate reload progress
        local reloadBar = reloadFrame:FindFirstChild("ReloadBg")
        if reloadBar then
            local progressBar = reloadBar:FindFirstChild("ReloadBar")
            if progressBar then
                local targetSize = UDim2.new(self.hudState.reloadProgress, 0, 1, 0)
                progressBar.Size = targetSize
            end
        end
    end
end

-- Update crosshair display
function HUDController:updateCrosshair()
    local crosshairContainer = self.hudContainer:FindFirstChild("CrosshairContainer")
    if not crosshairContainer then return end
    
    -- Get movement state for dynamic crosshair
    if self.character and self.humanoid then
        local isMoving = self.humanoid.MoveDirection.Magnitude > 0
        local targetSpread = isMoving and 1.5 or 1.0
        
        -- Smoothly interpolate crosshair spread
        self.hudState.crosshairSpread = self.hudState.crosshairSpread + (targetSpread - self.hudState.crosshairSpread) * 0.1
        
        -- Update crosshair arm positions
        local arms = {"Top", "Bottom", "Left", "Right"}
        for _, armName in ipairs(arms) do
            local arm = crosshairContainer:FindFirstChild(armName .. "Arm")
            if arm then
                local baseDistance = 10
                local spreadDistance = baseDistance * self.hudState.crosshairSpread
                
                if armName == "Top" then
                    arm.Position = UDim2.new(0.5, -1, 0.5, -spreadDistance - 5)
                elseif armName == "Bottom" then
                    arm.Position = UDim2.new(0.5, -1, 0.5, spreadDistance + 5)
                elseif armName == "Left" then
                    arm.Position = UDim2.new(0.5, -spreadDistance - 5, 0.5, -1)
                elseif armName == "Right" then
                    arm.Position = UDim2.new(0.5, spreadDistance + 5, 0.5, -1)
                end
            end
        end
    end
end

-- Update team scores display
function HUDController:updateTeamScores()
    local scoresContainer = self.hudContainer:FindFirstChild("ScoresContainer")
    if not scoresContainer then return end
    
    -- Update FBI score
    local fbiFrame = scoresContainer:FindFirstChild("Frame") -- First frame
    if fbiFrame then
        local fbiScore = fbiFrame:FindFirstChild("FBIScore")
        if fbiScore then
            fbiScore.Text = "FBI: " .. tostring(self.hudState.teamScores.FBI)
        end
    end
    
    -- Update KFC score (second frame)
    local frames = scoresContainer:GetChildren()
    for _, frame in ipairs(frames) do
        if frame:IsA("Frame") then
            local kfcScore = frame:FindFirstChild("KFCScore")
            if kfcScore then
                kfcScore.Text = "KFC: " .. tostring(self.hudState.teamScores.KFC)
                break
            end
        end
    end
end

-- Update performance display (FPS/Ping)
function HUDController:updatePerformanceDisplay()
    -- This would typically be in a performance container
    -- For now, we'll update the stored values which can be displayed elsewhere
    self.hudState.ping = math.min(self.player:GetNetworkPing() * 1000, 999)
end

-- Setup performance monitoring
function HUDController:setupPerformanceMonitoring()
    -- FPS monitoring
    local lastTime = tick()
    local frameCount = 0
    
    self.connections.fpsMonitor = RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastTime >= 1 then
            self.hudState.fps = math.floor(frameCount / (currentTime - lastTime))
            frameCount = 0
            lastTime = currentTime
        end
    end)
end

-- Setup input handling for HUD
function HUDController:setupInputHandling()
    self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- R key for reload
        if input.KeyCode == Enum.KeyCode.R then
            self:handleReload()
        end
        
        -- F3 to toggle performance display
        if input.KeyCode == Enum.KeyCode.F3 then
            -- Toggle performance indicators
            print("[HUDController] FPS:", self.hudState.fps, "Ping:", self.hudState.ping .. "ms")
        end
    end)
end

-- Handle reload input
function HUDController:handleReload()
    if self.hudState.currentAmmo < 30 and self.hudState.reserveAmmo > 0 and not self.hudState.isReloading then
        print("[HUDController] Starting reload...")
        self:startReload()
    end
end

-- Start reload sequence
function HUDController:startReload()
    self.hudState.isReloading = true
    self.hudState.reloadProgress = 0
    
    -- Simulate reload progress
    local reloadTime = 2.5 -- 2.5 seconds
    local startTime = tick()
    
    local reloadConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        self.hudState.reloadProgress = math.min(elapsed / reloadTime, 1.0)
        
        if self.hudState.reloadProgress >= 1.0 then
            self:completeReload()
            return
        end
    end)
    
    -- Store connection for cleanup
    self.updateConnections.reloadProgress = reloadConnection
    
    -- Auto-complete after reload time
    task.delay(reloadTime, function()
        if self.updateConnections.reloadProgress then
            self.updateConnections.reloadProgress:Disconnect()
            self.updateConnections.reloadProgress = nil
        end
        self:completeReload()
    end)
end

-- Complete reload
function HUDController:completeReload()
    if not self.hudState.isReloading then return end
    
    local ammoNeeded = 30 - self.hudState.currentAmmo
    local ammoToAdd = math.min(ammoNeeded, self.hudState.reserveAmmo)
    
    self.hudState.currentAmmo = self.hudState.currentAmmo + ammoToAdd
    self.hudState.reserveAmmo = self.hudState.reserveAmmo - ammoToAdd
    self.hudState.isReloading = false
    self.hudState.reloadProgress = 0
    
    -- Hide reload frame
    if self.hudContainer then
        local weaponContainer = self.hudContainer:FindFirstChild("WeaponInfoContainer")
        if weaponContainer then
            local reloadFrame = weaponContainer:FindFirstChild("ReloadFrame")
            if reloadFrame then
                reloadFrame.Visible = false
            end
        end
    end
    
    print("[HUDController] Reload completed")
end

-- Setup remote event connections
function HUDController:setupRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    -- Connect to score updates
    local scoreUpdate = remoteEvents:FindFirstChild("ScoreUpdate")
    if scoreUpdate then
        self.connections.scoreUpdate = scoreUpdate.OnClientEvent:Connect(function(scores)
            self:updateTeamScoresFromServer(scores)
        end)
    end
    
    -- Connect to weapon updates
    local weaponEquip = remoteEvents:FindFirstChild("WeaponEquip")
    if weaponEquip then
        self.connections.weaponEquip = weaponEquip.OnClientEvent:Connect(function(weaponData)
            self:updateWeaponFromServer(weaponData)
        end)
    end
end

-- Update team scores from server
function HUDController:updateTeamScoresFromServer(scores)
    if scores then
        self.hudState.teamScores = scores
        print("[HUDController] Team scores updated:", scores.FBI, "vs", scores.KFC)
    end
end

-- Update weapon from server
function HUDController:updateWeaponFromServer(weaponData)
    if weaponData then
        self.hudState.weaponName = weaponData.name or self.hudState.weaponName
        self.hudState.currentAmmo = weaponData.currentAmmo or self.hudState.currentAmmo
        self.hudState.reserveAmmo = weaponData.reserveAmmo or self.hudState.reserveAmmo
        print("[HUDController] Weapon updated:", weaponData.name)
    end
end

-- Handle player death
function HUDController:onPlayerDied()
    print("[HUDController] Player died - resetting HUD state")
    
    -- Reset HUD state
    self.hudState.health = 0
    self.hudState.isReloading = false
    self.hudState.reloadProgress = 0
    
    -- Stop any active reload
    if self.updateConnections.reloadProgress then
        self.updateConnections.reloadProgress:Disconnect()
        self.updateConnections.reloadProgress = nil
    end
end

-- Cleanup function
function HUDController:cleanup()
    print("[HUDController] Cleaning up HUD controller...")
    
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
    
    print("[HUDController] HUD controller cleanup complete")
end

-- API functions for external systems to call
function HUDController:updateAmmo(current, reserve)
    self.hudState.currentAmmo = current
    self.hudState.reserveAmmo = reserve
end

function HUDController:updateWeapon(name, ammo, reserve)
    self.hudState.weaponName = name
    self.hudState.currentAmmo = ammo
    self.hudState.reserveAmmo = reserve
end

function HUDController:showHitConfirmation()
    local crosshairContainer = self.hudContainer and self.hudContainer:FindFirstChild("CrosshairContainer")
    if not crosshairContainer then return end
    
    -- Create hit confirmation effect
    local hitIndicator = Instance.new("Frame")
    hitIndicator.Name = "HitConfirmation"
    hitIndicator.Size = UDim2.new(0, 8, 0, 8)
    hitIndicator.Position = UDim2.new(0.5, -4, 0.5, -4)
    hitIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hitIndicator.BorderSizePixel = 0
    hitIndicator.ZIndex = 10
    hitIndicator.Parent = crosshairContainer
    
    local hitCorner = Instance.new("UICorner")
    hitCorner.CornerRadius = UDim.new(1, 0)
    hitCorner.Parent = hitIndicator
    
    -- Animate hit confirmation
    local hitTween = TweenService:Create(hitIndicator,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0.5, -8, 0.5, -8),
            BackgroundTransparency = 1
        }
    )
    hitTween:Play()
    
    hitTween.Completed:Connect(function()
        hitIndicator:Destroy()
    end)
end

return HUDController