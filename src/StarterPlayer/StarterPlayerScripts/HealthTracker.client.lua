-- HealthTracker.client.lua
-- Tracks player health and updates HUD accordingly
-- Place in StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local HealthTracker = {}
HealthTracker.currentHealth = 100
HealthTracker.maxHealth = 100

-- Initialize health tracking
function HealthTracker:init()
    print("[HealthTracker] Initializing health tracking system...")
    
    -- Setup character health tracking
    self:setupHealthTracking()
    
    -- Start health monitoring
    self:startHealthMonitoring()
    
    print("[HealthTracker] Health tracking system initialized")
end

-- Setup health tracking for characters
function HealthTracker:setupHealthTracking()
    -- Handle character spawning
    player.CharacterAdded:Connect(function(character)
        self:onCharacterAdded(character)
    end)
    
    -- Handle existing character
    if player.Character then
        self:onCharacterAdded(player.Character)
    end
end

-- Handle new character
function HealthTracker:onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Reset health values
    self.currentHealth = humanoid.Health
    self.maxHealth = humanoid.MaxHealth
    
    -- Connect to health changes
    humanoid.HealthChanged:Connect(function(health)
        self:onHealthChanged(health)
    end)
    
    -- Connect to max health changes
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        self.maxHealth = humanoid.MaxHealth
        self:updateHUDHealth()
    end)
    
    -- Initial health update
    self:updateHUDHealth()
    
    print("[HealthTracker] Character health tracking setup for", character.Name)
end

-- Handle health changes
function HealthTracker:onHealthChanged(newHealth)
    local oldHealth = self.currentHealth
    self.currentHealth = newHealth
    
    -- Update HUD
    self:updateHUDHealth()
    
    -- Handle low health effects
    if newHealth < 30 and oldHealth >= 30 then
        self:onLowHealth()
    elseif newHealth >= 30 and oldHealth < 30 then
        self:onHealthRecovered()
    end
    
    -- Handle critical health
    if newHealth < 15 then
        self:onCriticalHealth()
    end
end

-- Update HUD health display
function HealthTracker:updateHUDHealth()
    local playerGui = player:WaitForChild("PlayerGui")
    local hudGui = playerGui:FindFirstChild("FPSGameHUD")
    
    if not hudGui then return end
    
    -- Find health elements
    local healthText = hudGui:FindFirstChild("HealthText", true)
    local healthBar = hudGui:FindFirstChild("HealthBar", true)
    local healthLabel = hudGui:FindFirstChild("HealthLabel", true)
    
    -- Update health text
    if healthText then
        healthText.Text = tostring(math.floor(self.currentHealth))
    end
    
    -- Update health label (fallback)
    if healthLabel then
        healthLabel.Text = "Health: " .. math.floor(self.currentHealth)
    end
    
    -- Update health bar
    if healthBar then
        local healthPercent = self.currentHealth / self.maxHealth
        
        -- Animate health bar
        TweenService:Create(healthBar, TweenInfo.new(0.3), {
            Size = UDim2.new(healthPercent, 0, 1, 0)
        }):Play()
        
        -- Change color based on health
        local healthColor
        if healthPercent > 0.6 then
            healthColor = Color3.fromRGB(0, 255, 136) -- Green
        elseif healthPercent > 0.3 then
            healthColor = Color3.fromRGB(255, 170, 0) -- Orange
        else
            healthColor = Color3.fromRGB(255, 51, 102) -- Red
        end
        
        TweenService:Create(healthBar, TweenInfo.new(0.3), {
            BackgroundColor3 = healthColor
        }):Play()
    end
end

-- Handle low health state
function HealthTracker:onLowHealth()
    print("[HealthTracker] Player health is low")
    
    -- Add screen effects for low health
    self:addLowHealthEffects()
end

-- Handle health recovery
function HealthTracker:onHealthRecovered()
    print("[HealthTracker] Player health recovered")
    
    -- Remove low health effects
    self:removeLowHealthEffects()
end

-- Handle critical health state
function HealthTracker:onCriticalHealth()
    -- Add critical health effects
    self:addCriticalHealthEffects()
end

-- Add low health visual effects
function HealthTracker:addLowHealthEffects()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing effect
    local existingEffect = playerGui:FindFirstChild("LowHealthEffect")
    if existingEffect then
        existingEffect:Destroy()
    end
    
    -- Create low health overlay
    local lowHealthGui = Instance.new("ScreenGui")
    lowHealthGui.Name = "LowHealthEffect"
    lowHealthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    lowHealthGui.IgnoreGuiInset = true
    lowHealthGui.Parent = playerGui
    
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    overlay.BackgroundTransparency = 0.8
    overlay.BorderSizePixel = 0
    overlay.Parent = lowHealthGui
    
    -- Pulse effect
    local function pulse()
        TweenService:Create(overlay, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            BackgroundTransparency = 0.95
        }):Play()
    end
    
    pulse()
end

-- Remove low health effects
function HealthTracker:removeLowHealthEffects()
    local playerGui = player:WaitForChild("PlayerGui")
    local lowHealthEffect = playerGui:FindFirstChild("LowHealthEffect")
    
    if lowHealthEffect then
        lowHealthEffect:Destroy()
    end
end

-- Add critical health effects
function HealthTracker:addCriticalHealthEffects()
    -- More intense effects for critical health
    local playerGui = player:WaitForChild("PlayerGui")
    
    local criticalEffect = playerGui:FindFirstChild("LowHealthEffect")
    if criticalEffect then
        local overlay = criticalEffect:FindFirstChild("Overlay")
        if overlay then
            -- Make effect more intense
            TweenService:Create(overlay, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundTransparency = 0.7
            }):Play()
        end
    end
end

-- Start health monitoring
function HealthTracker:startHealthMonitoring()
    -- Monitor for missing HUD and recreate if needed
    RunService.Heartbeat:Connect(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local currentCharacterHealth = player.Character.Humanoid.Health
            
            -- Ensure health is synced
            if math.abs(currentCharacterHealth - self.currentHealth) > 1 then
                self.currentHealth = currentCharacterHealth
                self:updateHUDHealth()
            end
        end
    end)
end

-- Get current health percentage
function HealthTracker:getHealthPercent()
    return self.currentHealth / self.maxHealth
end

-- Initialize the system
task.spawn(function()
    task.wait(3) -- Wait for HUD to load
    HealthTracker:init()
end)

-- Export for other scripts
_G.HealthTracker = HealthTracker

return HealthTracker