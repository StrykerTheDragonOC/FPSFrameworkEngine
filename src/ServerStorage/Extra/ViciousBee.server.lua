-- ViciousBee.server.lua
-- Main tool script for the Vicious Bee weapon
-- Place this script inside the Tool

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

-- Configuration
local DAMAGE = 25
local COOLDOWN_TIME = 1
local MAX_RANGE = 8

-- Sound effects
local slashSound = Instance.new("Sound")
slashSound.SoundId = "rbxassetid://137628815514180"
slashSound.Volume = 0.5
slashSound.Parent = handle

local hitSound = Instance.new("Sound")
hitSound.SoundId = "rbxassetid://4471648128"
hitSound.Volume = 0.3
slashSound.Pitch = 0.8
hitSound.Parent = handle

-- Variables
local lastAttackTime = 0
local humanoid = nil
local character = nil

-- FPS System integration
local FPSSystem = ReplicatedStorage:WaitForChild("FPSSystem")
local RemoteEventsManager = require(FPSSystem.RemoteEvents.RemoteEventsManager)

-- Initialize RemoteEvents
RemoteEventsManager:Initialize()

-- Get magic weapon events
local magicWeaponEvent = RemoteEventsManager:GetEvent("MagicWeaponActivated")
local weaponFiredEvent = RemoteEventsManager:GetEvent("WeaponFired")
local playerDamagedEvent = RemoteEventsManager:GetEvent("PlayerDamaged")

-- Configuration for meter system
local METER_CONFIG = {
    MAX_METER = 100,
    METER_PER_HIT = 10
}

-- Player data - persist meter value
local playerData = {
    viciousMeter = 0
}

-- Load saved meter value from tool attributes
local function loadMeterValue()
    local savedMeter = tool:GetAttribute("ViciousMeter")
    if savedMeter then
        playerData.viciousMeter = savedMeter
        print("Loaded saved meter value:", savedMeter)
    end
end

-- Save meter value to tool attributes
local function saveMeterValue()
    tool:SetAttribute("ViciousMeter", playerData.viciousMeter)
    print("Saved meter value:", playerData.viciousMeter)
end

-- Enhanced swing animation
local function performSwingAnimation()
    if not humanoid or not handle then return end

    -- Create swing animation using TweenService
    local originalCFrame = handle.CFrame
    local character = humanoid.Parent

    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local lookDirection = rootPart.CFrame.LookVector
        local rightDirection = rootPart.CFrame.RightVector

        -- Calculate swing position
        local swingOffset = rightDirection * 2 + lookDirection * 1.5
        local targetCFrame = rootPart.CFrame * CFrame.new(swingOffset) * CFrame.Angles(0, math.rad(45), 0)

        -- Swing motion
        local swingTween = TweenService:Create(handle, 
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {CFrame = targetCFrame}
        )

        local returnTween = TweenService:Create(handle, 
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {CFrame = originalCFrame}
        )

        swingTween:Play()
        swingTween.Completed:Connect(function()
            returnTween:Play()
        end)
    end
end

-- Enhanced visual effects
local function createSlashEffect()
    local attachment = handle:FindFirstChild("SlashAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "SlashAttachment"
        attachment.Parent = handle
    end

    -- Create slash trail
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment
    trail.Attachment1 = attachment
    trail.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
    }
    trail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    trail.Lifetime = 0.8
    trail.MinLength = 0.5
    trail.FaceCamera = true
    trail.Parent = handle

    -- Animate trail
    trail.Enabled = true

    spawn(function()
        wait(0.3)
        trail.Enabled = false
        wait(0.5)
        if trail and trail.Parent then
            trail:Destroy()
        end
    end)
end

local function createHitEffect(hitPosition)
    -- Create hit explosion effect
    local hitPart = Instance.new("Part")
    hitPart.Name = "HitEffect"
    hitPart.Size = Vector3.new(0.1, 0.1, 0.1)
    hitPart.Position = hitPosition
    hitPart.Anchored = true
    hitPart.CanCollide = false
    hitPart.Transparency = 1
    hitPart.Parent = workspace

    local attachment = Instance.new("Attachment")
    attachment.Parent = hitPart

    -- Create hit particles
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Parent = attachment
    particleEmitter.Texture = "rbxassetid://241650934" -- Sparkles texture
    particleEmitter.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
    }
    particleEmitter.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0)
    }
    particleEmitter.Lifetime = NumberRange.new(0.5, 1.2)
    particleEmitter.Rate = 200
    particleEmitter.SpreadAngle = Vector2.new(45, 45)
    particleEmitter.Speed = NumberRange.new(8, 15)
    particleEmitter.Drag = 5

    -- Burst effect
    particleEmitter:Emit(50)

    -- Create impact shockwave
    local shockwave = Instance.new("Part")
    shockwave.Name = "Shockwave"
    shockwave.Shape = Enum.PartType.Ball
    shockwave.Size = Vector3.new(0.5, 0.5, 0.5)
    shockwave.Position = hitPosition
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Material = Enum.Material.Neon
    shockwave.BrickColor = BrickColor.new("Bright yellow")
    shockwave.Transparency = 0.5
    shockwave.Parent = workspace

    -- Animate shockwave
    local shockwaveTween = TweenService:Create(
        shockwave,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(4, 4, 4),
            Transparency = 1
        }
    )
    shockwaveTween:Play()

    -- Clean up
    Debris:AddItem(hitPart, 2)
    Debris:AddItem(shockwave, 1)

    print("Hit effect created at position:", hitPosition)
end

-- Improved hit detection with multiple raycasts
local function performHitDetection()
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        print("No character or HumanoidRootPart for hit detection")
        return false 
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character}

    local rootPart = character.HumanoidRootPart
    local rayOrigin = handle.Position
    local lookDirection = rootPart.CFrame.LookVector

    -- Create fan of raycasts for better hit detection
    local rayDirections = {}
    for i = -2, 2 do
        local angle = math.rad(i * 10) -- 10 degree increments
        local rotatedDirection = CFrame.Angles(0, angle, 0) * lookDirection
        table.insert(rayDirections, rotatedDirection.Unit)
    end

    -- Add vertical rays
    local upDirection = rootPart.CFrame.UpVector
    table.insert(rayDirections, (lookDirection + upDirection * 0.2).Unit)
    table.insert(rayDirections, (lookDirection - upDirection * 0.2).Unit)

    local hitResults = {}

    for _, rayDirection in ipairs(rayDirections) do
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection * MAX_RANGE, raycastParams)

        if raycastResult then
            local hit = raycastResult.Instance
            local hitCharacter = hit.Parent
            local distance = (raycastResult.Position - rayOrigin).Magnitude

            -- Check if it's a valid target
            if hitCharacter:FindFirstChild("Humanoid") and hitCharacter ~= character and distance <= MAX_RANGE then
                local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
                table.insert(hitResults, {
                    character = hitCharacter,
                    humanoid = hitCharacter.Humanoid,
                    position = raycastResult.Position,
                    distance = distance,
                    player = hitPlayer
                })
                print("Valid hit detected on:", hitCharacter.Name, "Distance:", distance)
            end
        end
    end

    -- Process hits (take closest one)
    if #hitResults > 0 then
        -- Sort by distance
        table.sort(hitResults, function(a, b) return a.distance < b.distance end)
        local closestHit = hitResults[1]

        -- Deal damage through FPS system
        local attacker = Players:GetPlayerFromCharacter(character)
        if attacker and closestHit.player then
            -- Fire damage event to FPS system
            RemoteEventsManager:FireAllClients("PlayerDamaged", {
                attacker = attacker,
                victim = closestHit.player,
                weaponName = "ViciousStinger",
                damage = DAMAGE,
                hitPosition = closestHit.position,
                damageType = "Melee"
            })
        end

        -- Deal damage directly (still needed for functionality)
        closestHit.humanoid:TakeDamage(DAMAGE)

        -- Play hit sound
        hitSound:Play()

        -- Create hit effect
        createHitEffect(closestHit.position)

        -- Update meter (only for player hits)
        local meterGain = 0
        if closestHit.player then
            meterGain = METER_CONFIG.METER_PER_HIT
            print("Hit player:", closestHit.player.Name, "- gaining", meterGain, "meter")
        else
            meterGain = 50 -- Small gain for NPCs
            print("Hit NPC - gaining", meterGain, "meter")
        end

        playerData.viciousMeter = math.min(playerData.viciousMeter + meterGain, METER_CONFIG.MAX_METER)
        local meterFull = playerData.viciousMeter >= METER_CONFIG.MAX_METER

        -- Save meter value
        saveMeterValue()

        -- Notify client script about meter update
        local meterUpdate = Instance.new("IntValue")
        meterUpdate.Name = "MeterUpdate"
        meterUpdate.Value = playerData.viciousMeter
        meterUpdate:SetAttribute("MaxValue", METER_CONFIG.MAX_METER)
        meterUpdate:SetAttribute("IsFull", meterFull)
        meterUpdate.Parent = tool

        -- Notify server about weapon hit
        if remoteEvents and remoteEvents:FindFirstChild("WeaponHit") then
            -- Server should use FireAllClients to notify all clients about the weapon hit
            remoteEvents.WeaponHit:FireAllClients("WEAPON_HIT", DAMAGE, closestHit.character)
        end

        print("Meter updated to:", playerData.viciousMeter, "/", METER_CONFIG.MAX_METER)
        return true
    else
        print("No valid hits detected")
        -- Small meter gain for attempting attack
        playerData.viciousMeter = math.min(playerData.viciousMeter + 1, METER_CONFIG.MAX_METER)
        saveMeterValue()

        local meterUpdate = Instance.new("IntValue")
        meterUpdate.Name = "MeterUpdate"
        meterUpdate.Value = playerData.viciousMeter
        meterUpdate:SetAttribute("MaxValue", METER_CONFIG.MAX_METER)
        meterUpdate:SetAttribute("IsFull", playerData.viciousMeter >= METER_CONFIG.MAX_METER)
        meterUpdate.Parent = tool

        return false
    end
end

-- Handle tool activation
tool.Activated:Connect(function()
    local currentTime = tick()

    -- Check cooldown
    if currentTime - lastAttackTime < COOLDOWN_TIME then
        print("Attack on cooldown")
        return
    end

    lastAttackTime = currentTime

    print("Tool activated - performing attack")

    -- Play slash sound
    slashSound:Play()

    -- Create visual effect
    createSlashEffect()

    -- Get character and humanoid
    character = tool.Parent
    humanoid = character:FindFirstChild("Humanoid")

    if not humanoid then 
        print("No humanoid found")
        return 
    end

    -- Perform swing animation
    spawn(function()
        performSwingAnimation()
    end)

    -- Wait a bit for the swing to start before checking for hits
    wait(0.1)

    -- Perform hit detection
    performHitDetection()
end)

-- Handle tool equipped
tool.Equipped:Connect(function()
    character = tool.Parent
    humanoid = character:FindFirstChild("Humanoid")

    print("ViciousBee equipped by:", character.Name)

    -- Load saved meter value
    loadMeterValue()

    -- Send current meter value to client
    wait(0.1) -- Small delay to ensure client script is ready
    local meterUpdate = Instance.new("IntValue")
    meterUpdate.Name = "MeterUpdate"
    meterUpdate.Value = playerData.viciousMeter
    meterUpdate:SetAttribute("MaxValue", METER_CONFIG.MAX_METER)
    meterUpdate:SetAttribute("IsFull", playerData.viciousMeter >= METER_CONFIG.MAX_METER)
    meterUpdate.Parent = tool
end)

-- Handle tool unequipped
tool.Unequipped:Connect(function()
    print("ViciousBee unequipped")

    -- Save meter value when unequipped
    saveMeterValue()

    character = nil
    humanoid = nil
end)

print("ViciousBee tool script loaded!")