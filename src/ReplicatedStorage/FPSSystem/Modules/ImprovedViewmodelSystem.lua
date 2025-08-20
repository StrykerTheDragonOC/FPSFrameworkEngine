-- ImprovedViewmodelSystem.lua
-- Fixed viewmodel system that only shows arms when tool is equipped
-- Place in ReplicatedStorage/FPSSystem/Modules/ViewmodelSystem

local ViewmodelSystem = {}
ViewmodelSystem.__index = ViewmodelSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Constructor
function ViewmodelSystem.new()
    local self = setmetatable({}, ViewmodelSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.camera = workspace.CurrentCamera

    -- Viewmodel components
    self.viewmodelContainer = nil
    self.currentViewmodel = nil
    self.currentWeaponName = nil
    self.equippedTool = nil

    -- State tracking
    self.isAiming = false
    self.isSprinting = false
    self.toolEquipped = false

    -- Animation tracking
    self.animationTracks = {}

    -- Update connection
    self.updateConnection = nil

    -- Setup character connection
    self:setupCharacterConnection()

    return self
end

function ViewmodelSystem:setupCharacterConnection()
    local function onCharacterAdded(character)
        self.character = character
        print("[ImprovedViewmodel] Character added")
        
        -- Don't create viewmodel immediately - wait for tool
        self:hideViewmodel()
    end

    if self.player.Character then
        onCharacterAdded(self.player.Character)
    end

    self.player.CharacterAdded:Connect(onCharacterAdded)
end

function ViewmodelSystem:onToolEquipped(tool)
    print("[ImprovedViewmodel] Tool equipped:", tool.Name)
    
    self.equippedTool = tool
    self.toolEquipped = true
    self.currentWeaponName = tool.Name
    
    -- Lock camera to first person
    self:lockFirstPerson()
    
    -- Create/show viewmodel for this weapon
    self:createViewmodelForWeapon(tool.Name)
    
    -- Setup tool unequip detection
    tool.Unequipped:Connect(function()
        self:onToolUnequipped(tool)
    end)
end

function ViewmodelSystem:onToolUnequipped(tool)
    print("[ImprovedViewmodel] Tool unequipped:", tool.Name)
    
    self.equippedTool = nil
    self.toolEquipped = false
    self.currentWeaponName = nil
    
    -- Unlock camera
    self:unlockFirstPerson()
    
    -- Hide viewmodel
    self:hideViewmodel()
end

function ViewmodelSystem:createViewmodelForWeapon(weaponName)
    -- Clear existing viewmodel
    self:clearViewmodel()
    
    -- Create container if it doesn't exist
    if not self.viewmodelContainer then
        self.viewmodelContainer = Instance.new("Model")
        self.viewmodelContainer.Name = "ViewmodelContainer"
        self.viewmodelContainer.Parent = self.camera
    end
    
    -- Try to find weapon-specific viewmodel first
    local weaponViewmodel = self:findWeaponViewmodel(weaponName)
    
    if weaponViewmodel then
        print("[ImprovedViewmodel] Found weapon viewmodel for:", weaponName)
        self.currentViewmodel = weaponViewmodel:Clone()
    else
        print("[ImprovedViewmodel] Using default viewmodel for:", weaponName)
        self.currentViewmodel = self:createDefaultViewmodel()
    end
    
    if self.currentViewmodel then
        self.currentViewmodel.Name = "ViewmodelRig"
        self.currentViewmodel.Parent = self.viewmodelContainer
        
        -- Position viewmodel
        self:positionViewmodel()
        
        -- Make arms visible
        self:setupArmVisibility()
        
        print("[ImprovedViewmodel] Viewmodel created and positioned")
    else
        warn("[ImprovedViewmodel] Failed to create viewmodel")
    end
end

function ViewmodelSystem:findWeaponViewmodel(weaponName)
    -- Look for weapon-specific viewmodel
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return nil end
    
    local viewModels = fpsSystem:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    
    -- Try different paths based on weapon categories
    local searchPaths = {
        viewModels:FindFirstChild("Primary"),
        viewModels:FindFirstChild("Secondary"), 
        viewModels:FindFirstChild("Melee"),
        viewModels:FindFirstChild("Arms")
    }
    
    for _, categoryFolder in pairs(searchPaths) do
        if categoryFolder then
            -- Look in subcategories
            for _, subcategory in pairs(categoryFolder:GetChildren()) do
                if subcategory:IsA("Folder") then
                    local weaponModel = subcategory:FindFirstChild(weaponName)
                    if weaponModel then
                        return weaponModel
                    end
                end
            end
            
            -- Look directly in category
            local weaponModel = categoryFolder:FindFirstChild(weaponName)
            if weaponModel then
                return weaponModel
            end
        end
    end
    
    return nil
end

function ViewmodelSystem:createDefaultViewmodel()
    -- Create basic arm viewmodel
    local viewmodel = Instance.new("Model")
    viewmodel.Name = "DefaultViewmodel"
    
    -- Create HumanoidRootPart
    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(2, 2, 1)
    rootPart.Transparency = 1
    rootPart.CanCollide = false
    rootPart.Anchored = true
    rootPart.Parent = viewmodel
    
    viewmodel.PrimaryPart = rootPart
    
    -- Create arms
    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Material = Enum.Material.SmoothPlastic
    rightArm.BrickColor = BrickColor.new("Light orange")
    rightArm.CanCollide = false
    rightArm.Parent = viewmodel
    
    local leftArm = Instance.new("Part")
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Material = Enum.Material.SmoothPlastic
    leftArm.BrickColor = BrickColor.new("Light orange")
    leftArm.CanCollide = false
    leftArm.Parent = viewmodel
    
    -- Position arms
    rightArm.CFrame = rootPart.CFrame * CFrame.new(1.5, 0, -1)
    leftArm.CFrame = rootPart.CFrame * CFrame.new(-1.5, 0, -1)
    
    -- Create welds
    local rightWeld = Instance.new("WeldConstraint")
    rightWeld.Part0 = rootPart
    rightWeld.Part1 = rightArm
    rightWeld.Parent = rightArm
    
    local leftWeld = Instance.new("WeldConstraint")
    leftWeld.Part0 = rootPart
    leftWeld.Part1 = leftArm
    leftWeld.Parent = leftArm
    
    return viewmodel
end

function ViewmodelSystem:positionViewmodel()
    if not self.currentViewmodel or not self.currentViewmodel.PrimaryPart then
        return
    end
    
    -- Position viewmodel in front of camera
    local cameraCFrame = self.camera.CFrame
    local viewmodelCFrame = cameraCFrame * CFrame.new(0.5, -0.4, -0.6)
    
    self.currentViewmodel:SetPrimaryPartCFrame(viewmodelCFrame)
end

function ViewmodelSystem:setupArmVisibility()
    if not self.currentViewmodel then return end
    
    -- Make sure all arm parts are visible
    for _, part in pairs(self.currentViewmodel:GetDescendants()) do
        if part:IsA("BasePart") and (
            part.Name:find("Arm") or 
            part.Name:find("Hand") or
            part.Name == "RightArm" or 
            part.Name == "LeftArm"
        ) then
            part.Transparency = 0
            part.LocalTransparencyModifier = 0
            part.CanCollide = false
            print("[ImprovedViewmodel] Made arm part visible:", part.Name)
        end
    end
end

function ViewmodelSystem:hideViewmodel()
    if self.viewmodelContainer then
        self.viewmodelContainer:Destroy()
        self.viewmodelContainer = nil
        self.currentViewmodel = nil
        print("[ImprovedViewmodel] Viewmodel hidden")
    end
end

function ViewmodelSystem:clearViewmodel()
    if self.currentViewmodel then
        self.currentViewmodel:Destroy()
        self.currentViewmodel = nil
    end
end

function ViewmodelSystem:lockFirstPerson()
    if self.player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
        self.player.CameraMode = Enum.CameraMode.LockFirstPerson
        print("[ImprovedViewmodel] Camera locked to first person")
    end
end

function ViewmodelSystem:unlockFirstPerson()
    if self.player.CameraMode ~= Enum.CameraMode.Classic then
        self.player.CameraMode = Enum.CameraMode.Classic
        print("[ImprovedViewmodel] Camera unlocked from first person")
    end
end

function ViewmodelSystem:startUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end
    
    self.updateConnection = RunService.Heartbeat:Connect(function()
        if self.toolEquipped and self.currentViewmodel then
            self:updateViewmodel()
        end
    end)
end

function ViewmodelSystem:updateViewmodel()
    if not self.currentViewmodel or not self.currentViewmodel.PrimaryPart then
        return
    end
    
    -- Update viewmodel position
    self:positionViewmodel()
end

function ViewmodelSystem:setAiming(aiming)
    self.isAiming = aiming
    print("[ImprovedViewmodel] Aiming:", aiming)
end

function ViewmodelSystem:setSprinting(sprinting)
    self.isSprinting = sprinting
    print("[ImprovedViewmodel] Sprinting:", sprinting)
end

function ViewmodelSystem:cleanup()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    
    self:hideViewmodel()
    print("[ImprovedViewmodel] Cleanup complete")
end

-- Stop all animations
function ViewmodelSystem:stopAllAnimations()
    if not self.animationTracks then
        self.animationTracks = {}
        return
    end
    
    for _, track in pairs(self.animationTracks) do
        if track then
            track:Stop()
        end
    end
    self.animationTracks = {}
end

return ViewmodelSystem