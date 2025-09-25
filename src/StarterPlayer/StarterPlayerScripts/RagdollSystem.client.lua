-- Client-Side Ragdoll System
-- Handles ragdoll physics when players die
-- Connected to settings for configurable ragdoll force

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Default settings
local defaultSettings = {
    RagdollsEnabled = true,
    RagdollForce = 0.3,
    BloodEffects = true,
    MuzzleFlash = true,
    BulletTracers = true,
    AutoReload = true,
    DamageNumbers = true,
    Sensitivity = 0.5,
    FOV = 0.7,
    Volume = 0.8
}

-- Initialize settings
-- Initialize with GlobalStateManager
local globalStateManager = _G.GlobalStateManager
if globalStateManager then
	globalStateManager:Set("GameSettings", defaultSettings)
end

-- Ragdoll system
local RagdollSystem = {}

function RagdollSystem:CreateRagdoll(humanoid, bodyVelocity, forceMultiplier)
    local globalStateManager = _G.GlobalStateManager
    if not globalStateManager or not globalStateManager:GetNested("GameSettings.RagdollsEnabled") then return end
    
    local forceMultiplier = forceMultiplier or globalStateManager:GetNested("GameSettings.RagdollForce")
    
    -- Create ragdoll by setting HumanoidRootPart to nil
    local rootPart = humanoid.Parent:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Create body velocity for ragdoll physics
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVel.Velocity = bodyVelocity * forceMultiplier
    bodyVel.Parent = rootPart
    
    -- Create body angular velocity for spinning effect
    local bodyAngVel = Instance.new("BodyAngularVelocity")
    bodyAngVel.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyAngVel.AngularVelocity = Vector3.new(
        math.random(-10, 10) * forceMultiplier,
        math.random(-10, 10) * forceMultiplier,
        math.random(-10, 10) * forceMultiplier
    )
    bodyAngVel.Parent = rootPart
    
    -- Create blood particles if enabled
    local globalStateManager = _G.GlobalStateManager
    if globalStateManager and globalStateManager:GetNested("GameSettings.BloodEffects") then
        self:CreateBloodParticles(rootPart.Position, forceMultiplier)
    end
    
    -- Clean up after a few seconds
    Debris:AddItem(bodyVel, 3)
    Debris:AddItem(bodyAngVel, 3)
    
    print("Ragdoll created with force: " .. forceMultiplier)
end

function RagdollSystem:CreateBloodParticles(position, intensity)
    local bloodPart = Instance.new("Part")
    bloodPart.Name = "BloodParticle"
    bloodPart.Size = Vector3.new(0.2, 0.2, 0.2)
    bloodPart.Position = position
    bloodPart.Material = Enum.Material.Neon
    bloodPart.BrickColor = BrickColor.new("Really red")
    bloodPart.Anchored = false
    bloodPart.CanCollide = false
    bloodPart.Parent = workspace
    
    -- Create blood trail
    local attachment = Instance.new("Attachment")
    attachment.Parent = bloodPart
    
    local bloodTrail = Instance.new("Trail")
    bloodTrail.Attachment0 = attachment
    bloodTrail.Color = ColorSequence.new(Color3.fromRGB(139, 0, 0))
    bloodTrail.Lifetime = 2
    bloodTrail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    bloodTrail.Parent = bloodPart
    
    -- Add random velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(
        math.random(-20, 20) * intensity,
        math.random(5, 15) * intensity,
        math.random(-20, 20) * intensity
    )
    bodyVelocity.Parent = bloodPart
    
    -- Clean up
    Debris:AddItem(bloodPart, 5)
    Debris:AddItem(bodyVelocity, 2)
end

function RagdollSystem:HandlePlayerDeath(player, damageInfo)
    if player == Players.LocalPlayer then return end -- Don't ragdoll local player
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Calculate ragdoll force based on damage
    local damage = damageInfo and damageInfo.Damage or 50
    local globalStateManager = _G.GlobalStateManager
    local ragdollForce = globalStateManager and globalStateManager:GetNested("GameSettings.RagdollForce") or 0.3
    local forceMultiplier = math.clamp(damage / 100, 0.1, 2.0) * ragdollForce
    
    -- Get damage direction
    local damageDirection = Vector3.new(0, 0, 0)
    if damageInfo and damageInfo.Direction then
        damageDirection = damageInfo.Direction
    else
        -- Random direction if no direction provided
        damageDirection = Vector3.new(
            math.random(-1, 1),
            math.random(0.5, 1),
            math.random(-1, 1)
        ).Unit
    end
    
    -- Create ragdoll
    self:CreateRagdoll(humanoid, damageDirection * (damage * 2), forceMultiplier)
end

-- Connect to damage events
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        -- Handle ragdoll on death
        local damageInfo = {
            Damage = 100,
            Direction = Vector3.new(0, 1, 0)
        }
        RagdollSystem:HandlePlayerDeath(Players.LocalPlayer, damageInfo)
    end)
end

-- Connect to other players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            RagdollSystem:HandlePlayerDeath(player)
        end)
    end)
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Settings update function
function RagdollSystem:UpdateSettings(newSettings)
    for setting, value in pairs(newSettings) do
        local globalStateManager = _G.GlobalStateManager
        if globalStateManager then
            globalStateManager:Update("GameSettings." .. setting, value)
        end
    end
    print("Ragdoll settings updated")
end

-- Export for external use
_G.RagdollSystem = RagdollSystem

print("✅ Ragdoll System initialized")
print("   • Configurable ragdoll force via settings")
print("   • Blood particle effects")
print("   • Spinning ragdoll physics")
print("   • Connected to GameSettings")
