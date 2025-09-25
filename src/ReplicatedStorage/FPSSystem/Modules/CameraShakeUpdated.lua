-- CameraShakeUpdated Module
-- Source: https://devforum.roblox.com/t/camerashakeupdated-simple-camerascreen-shaking-module/3621709
-- Modified for FPS System integration

local CameraShake = {}
CameraShake.__index = CameraShake

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Active shake instances
local activeShakes = {}
local camera = workspace.CurrentCamera

-- Camera shake class
function CameraShake.new(magnitude, roughness, duration, positionInfluence, rotationInfluence, fadeOutTime)
    local self = setmetatable({}, CameraShake)

    self.magnitude = magnitude or 1
    self.roughness = roughness or 1
    self.duration = duration or 1
    self.positionInfluence = positionInfluence or Vector3.new(1, 1, 1)
    self.rotationInfluence = rotationInfluence or Vector3.new(1, 1, 1)
    self.fadeOutTime = fadeOutTime or 0.1

    self.startTime = tick()
    self.endTime = self.startTime + duration
    self.fadeStartTime = self.endTime - self.fadeOutTime

    self.positionOffset = Vector3.new()
    self.rotationOffset = Vector3.new()

    -- Generate random seeds for smooth noise
    self.positionSeeds = {
        x = math.random() * 1000,
        y = math.random() * 1000,
        z = math.random() * 1000
    }

    self.rotationSeeds = {
        x = math.random() * 1000,
        y = math.random() * 1000,
        z = math.random() * 1000
    }

    self.isActive = true

    -- Add to active shakes
    table.insert(activeShakes, self)

    return self
end

function CameraShake:Update()
    if not self.isActive then return end

    local currentTime = tick()

    -- Check if shake is finished
    if currentTime >= self.endTime then
        self:Stop()
        return
    end

    -- Calculate fade factor
    local fadeFactor = 1
    if currentTime >= self.fadeStartTime then
        local fadeProgress = (currentTime - self.fadeStartTime) / self.fadeOutTime
        fadeFactor = 1 - fadeProgress
    end

    -- Generate noise-based shake using time
    local timeOffset = currentTime * self.roughness

    -- Position shake
    local posX = (math.noise(self.positionSeeds.x, timeOffset) * 2 - 1) * self.magnitude * self.positionInfluence.X * fadeFactor
    local posY = (math.noise(self.positionSeeds.y, timeOffset) * 2 - 1) * self.magnitude * self.positionInfluence.Y * fadeFactor
    local posZ = (math.noise(self.positionSeeds.z, timeOffset) * 2 - 1) * self.magnitude * self.positionInfluence.Z * fadeFactor

    self.positionOffset = Vector3.new(posX, posY, posZ)

    -- Rotation shake (in degrees)
    local rotX = (math.noise(self.rotationSeeds.x, timeOffset) * 2 - 1) * self.magnitude * self.rotationInfluence.X * fadeFactor * 0.5
    local rotY = (math.noise(self.rotationSeeds.y, timeOffset) * 2 - 1) * self.magnitude * self.rotationInfluence.Y * fadeFactor * 0.5
    local rotZ = (math.noise(self.rotationSeeds.z, timeOffset) * 2 - 1) * self.magnitude * self.rotationInfluence.Z * fadeFactor * 0.5

    self.rotationOffset = Vector3.new(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
end

function CameraShake:Stop()
    self.isActive = false

    -- Remove from active shakes
    for i = #activeShakes, 1, -1 do
        if activeShakes[i] == self then
            table.remove(activeShakes, i)
            break
        end
    end
end

-- Global shake management
local CameraShakeManager = {}

function CameraShakeManager:Initialize()
    -- Main update loop
    RunService.RenderStepped:Connect(function()
        -- Update all active shakes
        for _, shake in pairs(activeShakes) do
            shake:Update()
        end

        -- Apply combined shake to camera
        self:ApplyCombinedShake()
    end)
end

function CameraShakeManager:ApplyCombinedShake()
    if #activeShakes == 0 then return end

    local totalPosition = Vector3.new()
    local totalRotation = Vector3.new()

    -- Combine all active shakes
    for _, shake in pairs(activeShakes) do
        if shake.isActive then
            totalPosition = totalPosition + shake.positionOffset
            totalRotation = totalRotation + shake.rotationOffset
        end
    end

    -- Apply to camera
    if camera then
        camera.CFrame = camera.CFrame + totalPosition
        camera.CFrame = camera.CFrame * CFrame.Angles(totalRotation.X, totalRotation.Y, totalRotation.Z)
    end
end

function CameraShakeManager:StopAll()
    for _, shake in pairs(activeShakes) do
        shake:Stop()
    end
    activeShakes = {}
end

-- Public API
local CameraShakeAPI = {}

function CameraShakeAPI.Shake(magnitude, roughness, duration, positionInfluence, rotationInfluence, fadeOutTime)
    return CameraShake.new(magnitude, roughness, duration, positionInfluence, rotationInfluence, fadeOutTime)
end

function CameraShakeAPI.StopAll()
    CameraShakeManager:StopAll()
end

-- Initialize the system
CameraShakeManager:Initialize()

return CameraShakeAPI