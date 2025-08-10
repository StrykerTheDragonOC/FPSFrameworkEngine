-- FPSCamera.lua
-- FPS camera system with FOV transitions and mouse control
-- Place in ReplicatedStorage.FPSSystem.Modules

local FPSCamera = {}
FPSCamera.__index = FPSCamera

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Constants
local CAMERA_SETTINGS = {
    DEFAULT_FOV = 70,
    ADS_FOV = 50,
    TRANSITION_TIME = 0.3,
    MOUSE_SENSITIVITY = 0.2
}

function FPSCamera.new()
    local self = setmetatable({}, FPSCamera)

    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera
    self.mouse = self.player:GetMouse()

    -- Camera state
    self.isAiming = false
    self.currentFOV = CAMERA_SETTINGS.DEFAULT_FOV
    self.targetFOV = CAMERA_SETTINGS.DEFAULT_FOV

    -- Mouse control
    self.mouseLocked = true
    self.lastMousePosition = Vector2.new()

    -- Initialize camera
    self:setupCamera()

    print("FPSCamera initialized")
    return self
end

function FPSCamera:setupCamera()
    -- Set camera type
    self.camera.CameraType = Enum.CameraType.Custom
    self.camera.FieldOfView = CAMERA_SETTINGS.DEFAULT_FOV

    -- Lock mouse to center
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    -- Connect mouse movement
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self:handleMouseMovement(input.Delta)
        end
    end)
end

function FPSCamera:handleMouseMovement(delta)
    if not self.mouseLocked then return end

    local character = self.player.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then return end

    -- Calculate rotation
    local sensitivity = CAMERA_SETTINGS.MOUSE_SENSITIVITY
    local deltaX = delta.X * sensitivity
    local deltaY = delta.Y * sensitivity

    -- Apply rotation
    local currentCFrame = self.camera.CFrame
    local newCFrame = currentCFrame * CFrame.Angles(math.rad(-deltaY), math.rad(-deltaX), 0)

    self.camera.CFrame = newCFrame
end

function FPSCamera:setAiming(isAiming)
    self.isAiming = isAiming

    if isAiming then
        self:setFOV(CAMERA_SETTINGS.ADS_FOV)
    else
        self:setFOV(CAMERA_SETTINGS.DEFAULT_FOV)
    end
end

function FPSCamera:setFOV(targetFOV)
    self.targetFOV = targetFOV

    -- Smooth FOV transition
    local tween = TweenService:Create(
        self.camera,
        TweenInfo.new(CAMERA_SETTINGS.TRANSITION_TIME),
        {FieldOfView = targetFOV}
    )
    tween:Play()
end

function FPSCamera:setScopeSettings(scopeSettings)
    if not scopeSettings then return end

    -- Apply scope-specific FOV
    if scopeSettings.fov then
        self:setFOV(scopeSettings.fov)
    end

    -- Apply scope sensitivity
    if scopeSettings.sensitivity then
        CAMERA_SETTINGS.MOUSE_SENSITIVITY = scopeSettings.sensitivity
    end
end

function FPSCamera:lockMouse()
    self.mouseLocked = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function FPSCamera:unlockMouse()
    self.mouseLocked = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function FPSCamera:cleanup()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

return FPSCamera