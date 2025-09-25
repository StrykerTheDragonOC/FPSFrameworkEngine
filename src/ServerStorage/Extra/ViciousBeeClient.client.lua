-- ViciousBeeClient.lua
-- Client-side script for UI and special abilities (placed inside the tool)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- FPS System integration
local FPSSystem = ReplicatedStorage:WaitForChild("FPSSystem")

-- Wait for modules to exist before requiring them
local CameraShaker, CameraShakePresets, RemoteEventsManager

spawn(function()
    local cameraShakeModule = FPSSystem.Modules:WaitForChild("CameraShakeUpdated", 10)
    local presetsModule = FPSSystem.Modules:WaitForChild("CameraShakePresets", 10)
    local remoteEventsModule = FPSSystem.RemoteEvents:WaitForChild("RemoteEventsManager", 10)

    if cameraShakeModule and presetsModule and remoteEventsModule then
        CameraShaker = require(cameraShakeModule)
        CameraShakePresets = require(presetsModule)
        RemoteEventsManager = require(remoteEventsModule)
        print("? ViciousStinger modules loaded successfully")
    else
        warn("? Failed to load ViciousStinger required modules")
    end
end)

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local player = Players.LocalPlayer
local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Asset IDs
local ASSET_IDS = {
    VICIOUS_WEAPON_FOG = 6956634060,
    WEAPON_HIT_EFFECT = 15009924404,
    EARTHQUAKE_PARTICLES = 6744534639,
    SMALL_CRACK = 29268435,
    EARTHQUAKE_CRACK = 162722971,
    HONEYFOG_SOUND = 8572573745,
    SLASH_SOUND = 137628815514180,
    HIT_SOUND = 4471648128
}

-- Configuration
local WEAPON_CONFIG = {
    MAX_METER = 100,
    METER_PER_HIT = 15,
    OVERDRIVE_COOLDOWN = 15,
    HONEY_FOG_COOLDOWN = 15,
    HONEY_FOG_RADIUS = 20,
    HONEY_FOG_DURATION = 10,
    EARTHQUAKE_COOLDOWN = 15,
    EARTHQUAKE_RADIUS = 20,
    EARTHQUAKE_DURATION = 5,
    BLOOD_FRENZY_HEAL_PERCENT = 0.07,
    BLOOD_FRENZY_LOW_HEALTH_THRESHOLD = 0.3,
    BLOOD_FRENZY_LOW_HEALTH_BONUS = 0.5,
}

-- UI Configuration
local UI_CONFIG = {
    METER_WIDTH = 300,
    METER_HEIGHT = 30,
    METER_COLOR = Color3.fromRGB(255, 200, 50),
    METER_BACKGROUND_COLOR = Color3.fromRGB(50, 50, 50),
    METER_BORDER_COLOR = Color3.fromRGB(0, 0, 0),
    METER_BORDER_SIZE = 2,
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    FONT = Enum.Font.GothamBold
}

-- Forward declaration for updateMeter function
local updateMeter


-- Function to create character afterimage
function createCharacterAfterimage(character)
    if not character then return end

    -- Clone the character for afterimage
    local afterimage = character:Clone()
    afterimage.Name = "CharacterAfterimage"
    afterimage.Parent = workspace

    -- Make afterimage non-collidable and translucent
    for _, part in pairs(afterimage:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Material = Enum.Material.ForceField
            part.Transparency = 0.7
            part.BrickColor = BrickColor.new("Bright blue")
        end
    end

    -- Remove humanoid to prevent AI behavior
    local humanoid = afterimage:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:Destroy()
    end

    -- Fade out and shrink the afterimage
    local fadeTween = TweenService:Create(
        afterimage,
        TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Transparency = 1
        }
    )

    -- Scale down the afterimage
    for _, part in pairs(afterimage:GetChildren()) do
        if part:IsA("BasePart") then
            local scaleTween = TweenService:Create(
                part,
                TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = part.Size * 0.3
                }
            )
            scaleTween:Play()
        end
    end

    fadeTween:Play()

    -- Clean up after animation
    fadeTween.Completed:Connect(function()
        if afterimage and afterimage.Parent then
            afterimage:Destroy()
        end
    end)
end

-- Variables
local isEquipped = false
local ui
local character = nil
local inputConnection = nil
-- Camera shake system now handled by FPS system modules
local playerData = {
    viciousMeter = 0,
    overdriveCooldown = 0,
    honeyFogCooldown = 0,
    earthquakeCooldown = 0,
    lastOverdriveTime = 0,
    lastHoneyFogTime = 0,
    lastEarthquakeTime = 0
}

-- Meter drain system
local meterDrainConnection = nil
local isDraining = false
local drainRate = 2 -- Meter points per second
local drainDelay = 3 -- Seconds before draining starts after ability use

-- Function to start meter drain after ability use
local function startMeterDrain()
    if meterDrainConnection then
        meterDrainConnection:Disconnect()
        meterDrainConnection = nil
    end

    isDraining = false

    -- Wait for the delay before starting to drain
    spawn(function()
        wait(drainDelay)

        if not isEquipped then return end

        isDraining = true
        meterDrainConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not isEquipped or playerData.viciousMeter <= 0 then
                -- Stop draining when unequipped or meter is empty
                if meterDrainConnection then
                    meterDrainConnection:Disconnect()
                    meterDrainConnection = nil
                end
                isDraining = false
                return
            end

            -- Drain meter over time
            local drainAmount = drainRate * deltaTime
            playerData.viciousMeter = math.max(0, playerData.viciousMeter - drainAmount)

            -- Update UI
            local maxValue = WEAPON_CONFIG.MAX_METER
            local currentValue = playerData.viciousMeter
            local isFull = currentValue >= maxValue
            updateMeter(currentValue, maxValue, isFull)
        end)
    end)
end

-- Initialize FPS System RemoteEvents
RemoteEventsManager:Initialize()

-- Get main FPS system events
local magicWeaponEvent = RemoteEventsManager:GetEvent("MagicWeaponActivated")
local weaponFiredEvent = RemoteEventsManager:GetEvent("WeaponFired")
local playerDamagedEvent = RemoteEventsManager:GetEvent("PlayerDamaged")

local function createFogParticle(parent)
    local particle = Instance.new("ImageLabel")
    particle.Size = UDim2.fromOffset(math.random(60, 120), math.random(30, 80))
    particle.Position = UDim2.fromScale(math.random(), math.random())
    particle.Image = "rbxassetid://122218103490965" -- fog texture
    particle.BackgroundTransparency = 1
    particle.ImageColor3 = Color3.fromRGB(255, 215, 0) -- golden tint
    particle.ImageTransparency = 0.7 -- initial transparency
    particle.AnchorPoint = Vector2.new(0.5, 0.5)
    particle.Parent = parent

    -- Animate movement slowly
    spawn(function()
        while particle.Parent do
            local targetPos = UDim2.fromScale(math.random(), math.random())
            local targetTrans = 0.3 + math.random() * 0.4
            local tween = TweenService:Create(particle, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = targetPos,
                ImageTransparency = targetTrans
            })
            tween:Play()
            tween.Completed:Wait()
        end
    end)

    return particle
end

-- Create Vicious Meter UI
local function createViciousMeterUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ViciousMeterGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromOffset(UI_CONFIG.METER_WIDTH + 20, 80)
    mainFrame.Position = UDim2.new(0.5, -(UI_CONFIG.METER_WIDTH + 20)/2, 1, -120)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.fromScale(1, 0) + UDim2.fromOffset(0, 25)
    titleLabel.Position = UDim2.fromOffset(0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "VICIOUS METER"
    titleLabel.TextColor3 = UI_CONFIG.TEXT_COLOR
    titleLabel.TextScaled = true
    titleLabel.Font = UI_CONFIG.FONT
    titleLabel.TextStrokeTransparency = 0.5
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Parent = mainFrame

    -- Meter clip frame
    local meterClipFrame = Instance.new("Frame")
    meterClipFrame.Name = "MeterClipFrame"
    meterClipFrame.Size = UDim2.fromOffset(UI_CONFIG.METER_WIDTH, UI_CONFIG.METER_HEIGHT)
    meterClipFrame.Position = UDim2.fromOffset(10, 35)
    meterClipFrame.BackgroundTransparency = 1
    meterClipFrame.ClipsDescendants = true
    meterClipFrame.Parent = mainFrame

    -- Fog container behind the meter
    local fogContainer = Instance.new("Frame")
    fogContainer.Name = "FogContainer"
    fogContainer.Size = UDim2.fromScale(1.5, 1.5)
    fogContainer.Position = UDim2.fromOffset(-UI_CONFIG.METER_WIDTH*0.25, -UI_CONFIG.METER_HEIGHT*0.25)
    fogContainer.BackgroundTransparency = 1
    fogContainer.ClipsDescendants = false
    fogContainer.Parent = meterClipFrame

    -- Spawn fog particles
    for i = 1, 15 do
        createFogParticle(fogContainer)
    end

    -- Meter background
    local meterBackground = Instance.new("Frame")
    meterBackground.Name = "MeterBackground"
    meterBackground.Size = UDim2.fromOffset(UI_CONFIG.METER_WIDTH, UI_CONFIG.METER_HEIGHT)
    meterBackground.Position = UDim2.fromOffset(0, 0)
    meterBackground.BackgroundColor3 = UI_CONFIG.METER_BACKGROUND_COLOR
    meterBackground.BorderSizePixel = 0
    meterBackground.Parent = meterClipFrame

    -- Border
    local meterBorder = Instance.new("UIStroke")
    meterBorder.Color = UI_CONFIG.METER_BORDER_COLOR
    meterBorder.Thickness = UI_CONFIG.METER_BORDER_SIZE
    meterBorder.Parent = meterBackground

    -- Meter fill
    local meterFill = Instance.new("Frame")
    meterFill.Name = "MeterFill"
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.Position = UDim2.fromOffset(0, 0)
    meterFill.BackgroundColor3 = UI_CONFIG.METER_COLOR
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meterBackground

    -- Percentage text
    local meterText = Instance.new("TextLabel")
    meterText.Name = "MeterText"
    meterText.Size = UDim2.fromScale(1, 1)
    meterText.Position = UDim2.fromOffset(0, 0)
    meterText.BackgroundTransparency = 1
    meterText.Text = "0%"
    meterText.TextColor3 = UI_CONFIG.TEXT_COLOR
    meterText.TextScaled = true
    meterText.Font = UI_CONFIG.FONT
    meterText.TextStrokeTransparency = 0.5
    meterText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    meterText.Parent = meterBackground

    ui = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        meterFill = meterFill,
        meterText = meterText,
        titleLabel = titleLabel,
        fogBackground = fogContainer,
        meterClipFrame = meterClipFrame
    }

    return ui
end

-- Update meter function with fog effects
updateMeter = function(currentValue, maxValue, isFull)
    if not ui then return end
    local percentage = currentValue / maxValue

    -- Animate fill
    TweenService:Create(ui.meterFill, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(percentage, 1)
    }):Play()
    ui.meterText.Text = math.floor(percentage * 100) .. "%"

    -- Update fog particles
    local baseTransparency = 0.7 - (percentage * 0.5)
    for _, particle in ipairs(ui.fogBackground:GetChildren()) do
        if particle:IsA("ImageLabel") then
            local extraScale = 1 + (percentage * 0.5)
            local tween = TweenService:Create(
                particle,
                TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {
                    ImageTransparency = math.clamp(baseTransparency + math.random()*0.1, 0, 1),
                    Size = UDim2.fromOffset(particle.Size.X.Offset * extraScale, particle.Size.Y.Offset * extraScale)
                }
            )
            tween:Play()
        end
    end

    -- Flash title when full
    if isFull then
        TweenService:Create(
            ui.titleLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 3, true),
            {TextColor3 = Color3.fromRGB(255, 255, 100)}
        ):Play()
    else
        ui.titleLabel.TextColor3 = UI_CONFIG.TEXT_COLOR
    end
end

-- Example usage:
createViciousMeterUI()
-- Call updateMeter(currentValue, maxValue, isFull) whenever meter changes

-- Special ability functions
local function findNearestEnemy(maxDistance)
    if not character then return nil end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end

    local nearestEnemy = nil
    local nearestDistance = maxDistance or 50

    -- Check other players
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRootPart = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRootPart then
                local distance = (humanoidRootPart.Position - otherRootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestEnemy = otherRootPart
                    nearestDistance = distance
                end
            end
        end
    end

    -- Check NPCs (characters without players)
    for _, child in pairs(workspace:GetChildren()) do
        if child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
            local npcPlayer = Players:GetPlayerFromCharacter(child)
            if not npcPlayer then -- This is an NPC
                local distance = (humanoidRootPart.Position - child.HumanoidRootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestEnemy = child.HumanoidRootPart
                    nearestDistance = distance
                end
            end
        end
    end

    return nearestEnemy
end

-- Cinematic cutscene for Vicious Overdrive (Pentagram Dash)
-- Cinematic cutscene for Vicious Overdrive (Pentagram Dash)
local function performOverdriveCutscene(enemyRootPart)
    if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local humanoid = character.Humanoid
    local hrp = character.HumanoidRootPart
    local enemyChar = enemyRootPart.Parent
    local enemyPos = enemyRootPart.Position

    print("Starting Pentagram Overdrive cutscene!")

    -- Lock enemy (remove tools + anchor humanoidRootPart)
    if enemyChar then
        for _, tool in ipairs(enemyChar:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = workspace
            end
        end
        if enemyChar:FindFirstChild("HumanoidRootPart") then
            enemyChar.HumanoidRootPart.Anchored = true
        end
    end

    -- Save player stats
    local origWalk, origJump = humanoid.WalkSpeed, humanoid.JumpPower
    humanoid.WalkSpeed, humanoid.JumpPower = 0, 0
    local originalPlayerPos = hrp.CFrame -- save original position

    ------------------------------------------------------------------
    -- Phase 1: Initial charge into enemy
    ------------------------------------------------------------------
    local chargePos = enemyPos + hrp.CFrame.LookVector * 5
    local chargeTween = TweenService:Create(hrp, TweenInfo.new(0.2), {CFrame = CFrame.new(chargePos, enemyPos)})
    chargeTween:Play()

    local hitSound = Instance.new("Sound", hrp)
    hitSound.SoundId = "rbxassetid://" .. ASSET_IDS.HIT_SOUND
    hitSound:Play()
    Debris:AddItem(hitSound, 2)

    chargeTween.Completed:Wait()

    ------------------------------------------------------------------
    -- Phase 2: 5 dashes in star pattern
    ------------------------------------------------------------------
    local angles = {0, 144, 288, 72, 216} -- true pentagram order
    local radius = 15
    local starLines = {}
    local dashPositions = {}
    local startPos = hrp.Position

    for _, angle in ipairs(angles) do
        local rad = math.rad(angle)
        local dir = Vector3.new(math.cos(rad), 0, math.sin(rad))
        local targetPos = enemyPos + dir * radius

        table.insert(dashPositions, targetPos)

        local tween = TweenService:Create(hrp, TweenInfo.new(0.25), {CFrame = CFrame.new(targetPos, enemyPos)})
        tween:Play()

        local conn
        conn = RunService.Heartbeat:Connect(function()
            createCharacterAfterimage(character)
        end)

        tween.Completed:Wait()
        if conn then conn:Disconnect() end

        -- Trail line
        local line = Instance.new("Part")
        line.Anchored, line.CanCollide = true, false
        line.Material = Enum.Material.Neon
        line.Color = Color3.fromRGB(255, 223, 0) -- golden yellow
        line.Size = Vector3.new(0.3, 0.3, (hrp.Position - startPos).Magnitude)
        line.CFrame = CFrame.new((hrp.Position + startPos) / 2, hrp.Position)
        line.Parent = workspace
        table.insert(starLines, line)

        -- Dash hit sound
        local s = Instance.new("Sound", hrp)
        s.SoundId = "rbxassetid://" .. ASSET_IDS.HIT_SOUND
        s:Play()
        Debris:AddItem(s, 2)

        startPos = hrp.Position
        task.wait(0.05)
    end

    -- Connect final line back to the first dash
    local finalLine = Instance.new("Part")
    finalLine.Anchored, finalLine.CanCollide = true, false
    finalLine.Material = Enum.Material.Neon
    finalLine.Color = Color3.fromRGB(255, 223, 0)
    finalLine.Size = Vector3.new(0.3, 0.3, (dashPositions[1] - dashPositions[#dashPositions]).Magnitude)
    finalLine.CFrame = CFrame.new((dashPositions[1] + dashPositions[#dashPositions]) / 2, dashPositions[1])
    finalLine.Parent = workspace
    table.insert(starLines, finalLine)

    -- Pulse star lines
    for _, line in ipairs(starLines) do
        TweenService:Create(line, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.2}):Play()
    end

    ------------------------------------------------------------------
    -- Phase 3: Final golden beam (kills enemy)
    ------------------------------------------------------------------
    local beam = Instance.new("Part")
    beam.Anchored, beam.CanCollide = true, false
    beam.Material = Enum.Material.Neon
    beam.Color = Color3.fromRGB(255, 223, 0)
    beam.Size = Vector3.new(3, 20, 3)
    beam.CFrame = CFrame.new(enemyPos - Vector3.new(0, 10, 0))
    beam.Parent = workspace

    local beamSound = Instance.new("Sound", beam)
    beamSound.SoundId = "rbxassetid://138615896263805"
    beamSound:Play()

    TweenService:Create(beam, TweenInfo.new(0.5), {CFrame = CFrame.new(enemyPos)}):Play()

    -- Apply explosion camera shake
    if CameraShaker and CameraShakePresets then
        local shakeData = CameraShakePresets["SmallExplosion"]
        if shakeData then
            CameraShaker.Shake(shakeData.magnitude, shakeData.roughness, shakeData.duration,
                shakeData.positionInfluence, shakeData.rotationInfluence, shakeData.fadeOutTime)
        end
    end

    local particles = Instance.new("ParticleEmitter", beam)
    particles.Texture = "rbxassetid://241650934"
    particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 120), Color3.fromRGB(255, 200, 50))
    particles.Rate = 200
    particles.Lifetime = NumberRange.new(1)
    particles.Speed = NumberRange.new(10)
    particles:Emit(100)

    -- Kill enemy NOW (beam is the finisher)
    local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
    if enemyHum then enemyHum.Health = 0 end

    task.wait(1.5)
    beam:Destroy()

    -- Fade out star lines
    for _, line in ipairs(starLines) do
        if line and line.Parent then
            TweenService:Create(line, TweenInfo.new(1), {Transparency = 1}):Play()
            Debris:AddItem(line, 2)
        end
    end

    -- Restore enemy
    if enemyChar and enemyChar:FindFirstChild("HumanoidRootPart") then
        enemyChar.HumanoidRootPart.Anchored = false
    end

    -- Return player to original position
    hrp.CFrame = originalPlayerPos
    humanoid.WalkSpeed, humanoid.JumpPower = origWalk, origJump

    print("Pentagram Overdrive complete!")
end


local function performViciousOverdrive()
    local currentTime = tick()

    print("Attempting Vicious Overdrive...")
    print("Meter:", playerData.viciousMeter, "/", WEAPON_CONFIG.MAX_METER)
    print("Cooldown remaining:", WEAPON_CONFIG.OVERDRIVE_COOLDOWN - (currentTime - playerData.lastOverdriveTime))

    -- Check cooldown
    if currentTime - playerData.lastOverdriveTime < WEAPON_CONFIG.OVERDRIVE_COOLDOWN then
        print("Vicious Overdrive on cooldown!")
        return false
    end

    -- Check if meter is full
    if playerData.viciousMeter < WEAPON_CONFIG.MAX_METER then
        print("Meter not full! Need", WEAPON_CONFIG.MAX_METER, "but have", playerData.viciousMeter)
        return false
    end

    if not character then 
        print("No character found!")
        return false 
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        print("No HumanoidRootPart found!")
        return false 
    end

    -- Find nearest enemy
    local enemyRootPart = findNearestEnemy(30)
    if not enemyRootPart then 
        print("No enemy found within range!")
        return false 
    end

    print("Executing Vicious Overdrive!")

    -- Reset meter and update cooldown
    playerData.viciousMeter = 0
    playerData.lastOverdriveTime = currentTime
    updateMeter(0, WEAPON_CONFIG.MAX_METER, false)

    -- Start meter drain after ability use
    startMeterDrain()

    -- Start the cinematic cutscene
    performOverdriveCutscene(enemyRootPart)

    -- Notify server
    weaponHitEvent:FireServer("VICIOUS_OVERDRIVE", enemyRootPart.Position)

    return true
end

local function performHoneyFog()
    local currentTime = tick()

    print("Attempting Honey Fog...")
    print("Cooldown remaining:", WEAPON_CONFIG.HONEY_FOG_COOLDOWN - (currentTime - playerData.lastHoneyFogTime))

    -- Check cooldown
    if currentTime - playerData.lastHoneyFogTime < WEAPON_CONFIG.HONEY_FOG_COOLDOWN then
        print("Honey Fog on cooldown!")
        return false
    end

    if not character then 
        print("No character for Honey Fog!")
        return false 
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        print("No HumanoidRootPart for Honey Fog!")
        return false 
    end

    print("Executing Honey Fog!")

    -- Update cooldown
    playerData.lastHoneyFogTime = currentTime

    -- Start meter drain after ability use
    startMeterDrain()

    -- Notify server
    weaponHitEvent:FireServer("HONEY_FOG", humanoidRootPart.Position)

    return true
end

local function performEarthquake()
    local currentTime = tick()

    print("Attempting Earthquake...")
    print("Cooldown remaining:", WEAPON_CONFIG.EARTHQUAKE_COOLDOWN - (currentTime - playerData.lastEarthquakeTime))

    -- Check cooldown
    if currentTime - playerData.lastEarthquakeTime < WEAPON_CONFIG.EARTHQUAKE_COOLDOWN then
        print("Earthquake on cooldown!")
        return false
    end

    if not character then 
        print("No character for Earthquake!")
        return false 
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        print("No HumanoidRootPart for Earthquake!")
        return false 
    end

    print("Executing Earthquake!")

    -- Update cooldown
    playerData.lastEarthquakeTime = currentTime

    -- Start meter drain after ability use
    startMeterDrain()

    -- Notify server
    weaponHitEvent:FireServer("EARTHQUAKE", humanoidRootPart.Position)

    return true
end

-- Input handling for special attacks (only when equipped)
local function onInputBegan(input, gameProcessed)
    if gameProcessed or not isEquipped then return end

    print("Key pressed:", input.KeyCode.Name, "Equipped:", isEquipped)

    if input.KeyCode == Enum.KeyCode.G then
        print("G key pressed - attempting Vicious Overdrive")
        performViciousOverdrive()
    elseif input.KeyCode == Enum.KeyCode.T then
        print("T key pressed - attempting Honey Fog")
        performHoneyFog()
    elseif input.KeyCode == Enum.KeyCode.R then
        print("R key pressed - attempting Earthquake")
        performEarthquake()
    end
end

-- Visual effects functions for Vicious Overdrive
local function createOverdriveEffects(enemyPosition)
    print("Creating Vicious Overdrive effects at position:", enemyPosition)

    local starTrails = {}
    local starRadius = 12

    -- Create 8-pointed star formation
    for i = 1, 8 do
        local angle = (i - 1) * math.pi / 4 -- 45 degree intervals
        local startOffset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * starRadius
        local endOffset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (starRadius * 0.3)

        local trail = Instance.new("Part")
        trail.Name = "StarTrail"
        trail.Material = Enum.Material.Neon
        trail.BrickColor = BrickColor.new("Bright yellow")
        trail.Size = Vector3.new(0.3, 0.3, starRadius * 0.7)
        trail.Anchored = true
        trail.CanCollide = false
        trail.Transparency = 0.2
        trail.Parent = workspace

        -- Position trail from center to edge
        trail.Position = enemyPosition + (startOffset + endOffset) / 2
        trail.CFrame = CFrame.lookAt(enemyPosition + endOffset, enemyPosition + startOffset)

        table.insert(starTrails, trail)

        -- Animate trail appearance
        local appearTween = TweenService:Create(
            trail,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 0.2, Size = Vector3.new(0.5, 0.5, starRadius * 0.7)}
        )
        appearTween:Play()
    end

    -- Wait for star to form, then create beam attack
    spawn(function()
        wait(2.5) -- Star formation time

        -- Create beam from under enemy
        local beam = Instance.new("Part")
        beam.Name = "OverdriveBeam"
        beam.Material = Enum.Material.Neon
        beam.BrickColor = BrickColor.new("Bright red")
        beam.Size = Vector3.new(3, 20, 3)
        beam.Anchored = true
        beam.CanCollide = false
        beam.Transparency = 0.1
        beam.Position = enemyPosition + Vector3.new(0, -10, 0)
        beam.Parent = workspace

        -- Beam sound effect
        local beamSound = Instance.new("Sound")
        beamSound.SoundId = "rbxassetid://138615896263805" -- Laser sound
        beamSound.Volume = 1
        beamSound.Pitch = 0.8
        beamSound.Parent = beam
        beamSound:Play()

        -- Animate beam rising up
        local beamRise = TweenService:Create(
            beam,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = enemyPosition + Vector3.new(0, 5, 0)}
        )
        beamRise:Play()

        -- Flash effect on beam
        local flashTween = TweenService:Create(
            beam,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 5, true),
            {Transparency = 0.5}
        )
        flashTween:Play()

        -- Clean up after beam attack
        wait(1.5)

        -- Fade out star trails
        for _, trail in ipairs(starTrails) do
            local fadeTween = TweenService:Create(
                trail,
                TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 1}
            )
            fadeTween:Play()

            fadeTween.Completed:Connect(function()
                if trail and trail.Parent then
                    trail:Destroy()
                end
            end)
        end

        -- Fade out beam
        local beamFade = TweenService:Create(
            beam,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1}
        )
        beamFade:Play()

        beamFade.Completed:Connect(function()
            if beam and beam.Parent then
                beam:Destroy()
            end
        end)
    end)
end

local function createHoneyFogEffects(position)
    print("Creating honey fog effects at position:", position)

    local fogPart = Instance.new("Part")
    fogPart.Name = "HoneyFog"
    fogPart.Size = Vector3.new(1, 1, 1)
    fogPart.Position = position
    fogPart.Anchored = true
    fogPart.CanCollide = false
    fogPart.Transparency = 1
    fogPart.Parent = workspace

    -- Create fog sound with pitch shifting
    local honeyFogSound = Instance.new("Sound")
    honeyFogSound.SoundId = "rbxassetid://" .. ASSET_IDS.HONEYFOG_SOUND
    honeyFogSound.Volume = 0.6
    honeyFogSound.Pitch = math.random(80, 120) / 100
    honeyFogSound.Looped = true
    honeyFogSound.Parent = fogPart
    honeyFogSound:Play()

    -- Add random pitch shifting effect
    spawn(function()
        while honeyFogSound.Parent do
            wait(math.random(1, 3)) -- Random interval between pitch changes
            local newPitch = math.random(60, 140) / 100 -- Pitch range from 0.6 to 1.4

            local pitchTween = TweenService:Create(
                honeyFogSound,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {Pitch = newPitch}
            )
            pitchTween:Play()
        end
    end)

    -- Create attachment for particles
    local attachment = Instance.new("Attachment")
    attachment.Parent = fogPart

    -- Create honey fog smoke particles
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Parent = attachment
    particleEmitter.Texture = "rbxassetid://241650934" -- Use sparkles texture for smoke effect
    particleEmitter.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- Light yellow
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 235, 100)), -- Golden yellow
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 200, 50)), -- Amber
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 30)) -- Dark golden
    }
    particleEmitter.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5), -- Start small
        NumberSequenceKeypoint.new(0.3, 3), -- Grow large
        NumberSequenceKeypoint.new(0.7, 4), -- Peak size
        NumberSequenceKeypoint.new(1, 6) -- Fade out large
    }
    particleEmitter.Lifetime = NumberRange.new(3, 6) -- Longer lifetime for smoke
    particleEmitter.Rate = 80 -- Slower rate for more realistic smoke
    particleEmitter.SpreadAngle = Vector2.new(60, 60) -- Wider spread
    particleEmitter.Speed = NumberRange.new(1, 4) -- Slower movement
    particleEmitter.Drag = 8 -- Higher drag for smoke-like behavior
    particleEmitter.VelocityInheritance = 0.2 -- Less inheritance for natural drift
    particleEmitter.Acceleration = Vector3.new(0, 2, 0) -- Slight upward drift
    particleEmitter.LightEmission = 0.3 -- Subtle glow

    -- Create expanding honey fog effect like the second image
    local mainFog = Instance.new("Part")
    mainFog.Name = "HoneyFogMain"
    mainFog.Shape = Enum.PartType.Ball
    mainFog.Size = Vector3.new(2, 2, 2) -- Start small
    mainFog.Position = position
    mainFog.Anchored = true
    mainFog.CanCollide = false
    mainFog.Material = Enum.Material.ForceField
    mainFog.BrickColor = BrickColor.new("Bright yellow")
    mainFog.Transparency = 0.3
    mainFog.Parent = workspace

    -- Create expanding animation
    local expandTween = TweenService:Create(
        mainFog,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(WEAPON_CONFIG.HONEY_FOG_RADIUS * 3, 4, WEAPON_CONFIG.HONEY_FOG_RADIUS * 3),
            Transparency = 0.7
        }
    )
    expandTween:Play()

    -- Add subtle pulsing effect
    local pulseTween = TweenService:Create(
        mainFog,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.6}
    )
    pulseTween:Play()

    spawn(function()
        wait(WEAPON_CONFIG.HONEY_FOG_DURATION)

        -- Stop particle emission
        particleEmitter.Enabled = false

        local soundFadeTween = TweenService:Create(
            honeyFogSound,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Volume = 0}
        )
        soundFadeTween:Play()

        -- Fade out main fog
        local fadeTween = TweenService:Create(
            mainFog,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1}
        )
        fadeTween:Play()

        wait(1)
        fogPart:Destroy()
        mainFog:Destroy()
    end)
end

local function createEarthquakeEffects(position)
    print("Creating earthquake effects at position:", position)

    -- Apply earthquake camera shake
    if CameraShaker and CameraShakePresets then
        local shakeData = CameraShakePresets["ViciousEarthquake"]
        if shakeData then
            CameraShaker.Shake(shakeData.magnitude, shakeData.roughness, shakeData.duration,
                shakeData.positionInfluence, shakeData.rotationInfluence, shakeData.fadeOutTime)
        end
    end

    -- Create earthquake indicator
    local earthquakeIndicator = Instance.new("Part")
    earthquakeIndicator.Name = "EarthquakeIndicator"
    earthquakeIndicator.Shape = Enum.PartType.Cylinder
    earthquakeIndicator.Size = Vector3.new(1, WEAPON_CONFIG.EARTHQUAKE_RADIUS * 2, WEAPON_CONFIG.EARTHQUAKE_RADIUS * 2)
    earthquakeIndicator.Position = position
    earthquakeIndicator.Anchored = true
    earthquakeIndicator.CanCollide = false
    earthquakeIndicator.Material = Enum.Material.ForceField
    earthquakeIndicator.BrickColor = BrickColor.new("Brown")
    earthquakeIndicator.Transparency = 0.8
    earthquakeIndicator.Parent = workspace

    spawn(function()
        wait(WEAPON_CONFIG.EARTHQUAKE_DURATION)

        local fadeTween = TweenService:Create(
            earthquakeIndicator,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1}
        )
        fadeTween:Play()

        wait(1)
        earthquakeIndicator:Destroy()
    end)
end

-- Handle tool equipped
tool.Equipped:Connect(function()
    character = tool.Parent
    isEquipped = true

    -- Camera shaker now handled automatically by FPS system

    -- Create UI when tool is equipped
    if not ui then
        ui = createViciousMeterUI()
    end

    -- Connect input handling
    if not inputConnection then
        inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
        print("Input handling connected for ViciousBee")
    end
end)

-- Handle tool unequipped
tool.Unequipped:Connect(function()
    character = nil
    isEquipped = false

    -- Stop meter drain
    if meterDrainConnection then
        meterDrainConnection:Disconnect()
        meterDrainConnection = nil
        isDraining = false
        print("Meter drain stopped for ViciousBee")
    end

    -- Camera shaker handled automatically by FPS system

    -- Disconnect input handling
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
        print("Input handling disconnected for ViciousBee")
    end
end)

-- Listen for meter updates from the main tool script
tool.ChildAdded:Connect(function(child)
    if child.Name == "MeterUpdate" then
        local currentValue = child.Value
        local maxValue = child:GetAttribute("MaxValue") or WEAPON_CONFIG.MAX_METER
        local isFull = child:GetAttribute("IsFull") or false

        print("Meter update received:", currentValue, "/", maxValue, "Full:", isFull)

        -- If meter increased, stop draining temporarily
        if currentValue > playerData.viciousMeter and isDraining then
            print("Meter increased during drain - stopping drain temporarily")
            if meterDrainConnection then
                meterDrainConnection:Disconnect()
                meterDrainConnection = nil
            end
            isDraining = false

            -- Restart drain after a short delay
            spawn(function()
                wait(1) -- Brief pause before restarting drain
                if isEquipped then
                    startMeterDrain()
                end
            end)
        end

        playerData.viciousMeter = currentValue
        updateMeter(currentValue, maxValue, isFull)

        child:Destroy()
    end
end)

-- Listen for special ability triggers from main FPS system
magicWeaponEvent.OnClientEvent:Connect(function(weaponName, abilityName, data)
    if weaponName == "ViciousStinger" then
        if abilityName == "ViciousOverdrive" and data.enemyPosition then
            createOverdriveEffects(data.enemyPosition)
        elseif abilityName == "HoneyFog" and data.position then
            createHoneyFogEffects(data.position)
        elseif abilityName == "Earthquake" and data.position then
            createEarthquakeEffects(data.position)
        end
    end
end)


-- Function to create shockwave hit effect
local function createShockwaveEffect(position)
    -- Create shockwave part
    local shockwave = Instance.new("Part")
    shockwave.Name = "HitShockwave"
    shockwave.Shape = Enum.PartType.Ball
    shockwave.Size = Vector3.new(1, 1, 1) -- Start small
    shockwave.Position = position
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Material = Enum.Material.ForceField
    shockwave.BrickColor = BrickColor.new("Bright blue")
    shockwave.Transparency = 0.2
    shockwave.Parent = workspace

    -- Create the hit effect mesh using the provided asset ID
    local hitMesh = Instance.new("SpecialMesh")
    hitMesh.MeshType = Enum.MeshType.FileMesh
    hitMesh.MeshId = "rbxassetid://4124211540"
    hitMesh.Scale = Vector3.new(0.5, 0.5, 0.5) -- Start small
    hitMesh.Parent = shockwave

    -- Expand the shockwave
    local expandTween = TweenService:Create(
        shockwave,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(8, 8, 8),
            Transparency = 1
        }
    )

    local meshExpandTween = TweenService:Create(
        hitMesh,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Scale = Vector3.new(4, 4, 4)
        }
    )

    expandTween:Play()
    meshExpandTween:Play()

    -- Clean up after animation
    expandTween.Completed:Connect(function()
        if shockwave and shockwave.Parent then
            shockwave:Destroy()
        end
    end)
end

-- Listen for weapon hit effects from main FPS system
playerDamagedEvent.OnClientEvent:Connect(function(damageData)
    -- Check if this was from ViciousStinger
    if damageData.weaponName == "ViciousStinger" then
        -- Create shockwave effect at hit position
        if damageData.hitPosition then
            createShockwaveEffect(damageData.hitPosition)
        end

        -- Small camera shake for regular weapon hits
        if CameraShaker and CameraShakePresets then
            local shakeData = CameraShakePresets["ViciousStrike"]
            if shakeData then
                CameraShaker.Shake(shakeData.magnitude, shakeData.roughness, shakeData.duration,
                    shakeData.positionInfluence, shakeData.rotationInfluence, shakeData.fadeOutTime)
            end
        end
    end
end)

print("ViciousBee client loaded!")