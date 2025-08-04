-- Fixed FPSFrameworkController.lua
-- Place this in StarterPlayerScripts

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Player reference
local player = Players.LocalPlayer

-- System instances
local viewmodelSystem
local weaponSystem
local grenadeSystem
local meleeSystem
local debugger

-- Current weapon data
local weapons = {}
local currentSlot = "primary"
local isChargingGrenade = false

-- Ensure required folders exist
local function ensureFolders()
    -- Create FPSSystem folder if needed
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        local folder = Instance.new("Folder")
        folder.Name = "FPSSystem"
        folder.Parent = ReplicatedStorage
        print("Created FPSSystem folder")
    end

    -- Create Modules folder if needed
    local modulesFolder = fpsSystem:FindFirstChild("Modules")
    if not modulesFolder then
        local folder = Instance.new("Folder")
        folder.Name = "Modules"
        folder.Parent = fpsSystem
        print("Created Modules folder")
    end

    -- Create ViewModels folder if needed
    local viewModelsFolder = fpsSystem:FindFirstChild("ViewModels")
    if not viewModelsFolder then
        local folder = Instance.new("Folder")
        folder.Name = "ViewModels"
        folder.Parent = fpsSystem
        print("Created ViewModels folder")
    end

    return modulesFolder
end

-- Safely require a module
local function safeRequire(modulePath)
    local success, result = pcall(function()
        return require(modulePath)
    end)

    if success then
        return result
    else
        warn("Failed to require module: " .. tostring(modulePath) .. " - " .. tostring(result))
        return nil
    end
end

-- Create placeholder weapon models
local function createPlaceholderModels()
    -- Primary weapon (assault rifle)
    local primaryModel = Instance.new("Model")
    primaryModel.Name = "M4A1"

    local primaryHandle = Instance.new("Part")
    primaryHandle.Name = "Handle"
    primaryHandle.Size = Vector3.new(0.5, 0.3, 2)
    primaryHandle.Color = Color3.fromRGB(50, 50, 50)
    primaryHandle.Anchored = true -- Important: Must be anchored
    primaryHandle.CanCollide = false
    primaryHandle.Parent = primaryModel
    primaryModel.PrimaryPart = primaryHandle

    local primaryBarrel = Instance.new("Part")
    primaryBarrel.Name = "Barrel"
    primaryBarrel.Size = Vector3.new(0.2, 0.2, 1)
    primaryBarrel.Color = Color3.fromRGB(30, 30, 30)
    primaryBarrel.CFrame = primaryHandle.CFrame * CFrame.new(0, 0, -1.5)
    primaryBarrel.Anchored = true -- Important: Must be anchored
    primaryBarrel.CanCollide = false
    primaryBarrel.Parent = primaryModel

    -- Add muzzle point for effects
    local muzzlePoint = Instance.new("Attachment")
    muzzlePoint.Name = "MuzzlePoint"
    muzzlePoint.Position = Vector3.new(0, 0, -primaryBarrel.Size.Z/2)
    muzzlePoint.Parent = primaryBarrel

    -- Secondary weapon (pistol)
    local secondaryModel = Instance.new("Model")
    secondaryModel.Name = "Pistol"

    local secondaryHandle = Instance.new("Part")
    secondaryHandle.Name = "Handle"
    secondaryHandle.Size = Vector3.new(0.3, 0.8, 0.2)
    secondaryHandle.Color = Color3.fromRGB(40, 40, 40)
    secondaryHandle.Anchored = true
    secondaryHandle.CanCollide = false
    secondaryHandle.Parent = secondaryModel
    secondaryModel.PrimaryPart = secondaryHandle

    local secondaryBarrel = Instance.new("Part")
    secondaryBarrel.Name = "Barrel"
    secondaryBarrel.Size = Vector3.new(0.2, 0.2, 0.8)
    secondaryBarrel.Color = Color3.fromRGB(30, 30, 30)
    secondaryBarrel.CFrame = secondaryHandle.CFrame * CFrame.new(0, -0.3, -0.4)
    secondaryBarrel.Anchored = true
    secondaryBarrel.CanCollide = false
    secondaryBarrel.Parent = secondaryModel

    -- Add muzzle point
    local pistolMuzzle = Instance.new("Attachment")
    pistolMuzzle.Name = "MuzzlePoint"
    pistolMuzzle.Position = Vector3.new(0, 0, -secondaryBarrel.Size.Z/2)
    pistolMuzzle.Parent = secondaryBarrel

    -- Melee weapon (knife)
    local meleeModel = Instance.new("Model")
    meleeModel.Name = "Knife"

    local meleeHandle = Instance.new("Part")
    meleeHandle.Name = "Handle"
    meleeHandle.Size = Vector3.new(0.2, 0.8, 0.2)
    meleeHandle.Color = Color3.fromRGB(50, 50, 50)
    meleeHandle.Anchored = true
    meleeHandle.CanCollide = false
    meleeHandle.Parent = meleeModel
    meleeModel.PrimaryPart = meleeHandle

    local meleeBlade = Instance.new("Part")
    meleeBlade.Name = "Blade"
    meleeBlade.Size = Vector3.new(0.05, 1, 0.4)
    meleeBlade.Color = Color3.fromRGB(200, 200, 200)
    meleeBlade.CFrame = meleeHandle.CFrame * CFrame.new(0, 0.9, 0)
    meleeBlade.Anchored = true
    meleeBlade.CanCollide = false
    meleeBlade.Parent = meleeModel

    -- Grenade model
    local grenadeModel = Instance.new("Model")
    grenadeModel.Name = "Grenade"

    local grenadeBody = Instance.new("Part")
    grenadeBody.Name = "Handle"
    grenadeBody.Shape = Enum.PartType.Ball
    grenadeBody.Size = Vector3.new(0.8, 0.8, 0.8)
    grenadeBody.Color = Color3.fromRGB(30, 100, 30)
    grenadeBody.Anchored = true
    grenadeBody.CanCollide = false
    grenadeBody.Parent = grenadeModel
    grenadeModel.PrimaryPart = grenadeBody

    -- Store models
    return {
        primary = primaryModel,
        secondary = secondaryModel,
        melee = meleeModel,
        grenade = grenadeModel
    }
end

-- Initialize the viewmodel system
local function initViewmodel()
    print("Initializing viewmodel system...")

    -- Ensure folders exist
    local modulesFolder = ensureFolders()

    -- Get ViewmodelSystem module
    local viewmodelModule = modulesFolder:FindFirstChild("ViewmodelSystem")
    if not viewmodelModule then
        warn("ViewmodelSystem module not found, creating placeholder")
        -- Create placeholder module
        viewmodelModule = Instance.new("ModuleScript")
        viewmodelModule.Name = "ViewmodelSystem"
        viewmodelModule.Source = "return require(script.Parent.FixedViewmodelSystem)" -- Redirect to fixed module
        viewmodelModule.Parent = modulesFolder

        -- Create fixed module
        local fixedModule = Instance.new("ModuleScript")
        fixedModule.Name = "FixedViewmodelSystem"
        -- You should paste the fixed code here, omitted for brevity
        fixedModule.Parent = modulesFolder
    end

    -- Load the module
    local ViewmodelSystemModule = safeRequire(viewmodelModule)
    if not ViewmodelSystemModule then
        error("Failed to load ViewmodelSystem module")
        return nil
    end

    -- Create viewmodel instance
    local vm = ViewmodelSystemModule.new()
    if not vm then
        error("Failed to create ViewmodelSystem instance")
        return nil
    end

    -- Set up arms
    vm:setupArms()

    -- Start the update loop
    vm:startUpdateLoop()

    print("Viewmodel system initialized!")
    return vm
end

-- Register default weapons
local function setupWeapons()
    print("Setting up weapons...")

    -- Create placeholder data
    weapons = {
        primary = {
            name = "G36",
            damage = 25,
            recoil = 1.0
        },
        secondary = {
            name = "Pistol",
            damage = 15,
            recoil = 0.5
        },
        melee = {
            name = "Knife",
            damage = 50
        }
    }

    -- Create placeholder models
    local models = createPlaceholderModels()

    -- Equip primary by default
    if viewmodelSystem then
        viewmodelSystem:equipWeapon(models.primary)
        currentSlot = "primary"
        print("Equipped primary weapon")
    end
end

-- Equip a weapon by slot
local function equipWeapon(slot)
    if not weapons[slot] then
        warn("No weapon in slot: " .. slot)
        return
    end

    -- Update current slot
    currentSlot = slot

    -- Get weapon models
    local models = createPlaceholderModels()
    local model = models[slot]

    -- Equip in viewmodel
    if viewmodelSystem and model then
        viewmodelSystem:equipWeapon(model)
        print("Equipped " .. slot)
    else
        warn("Failed to equip weapon: viewmodelSystem or model is nil")
    end
end

-- Handle firing based on weapon type
local function handleFiring(isDown)
    if not isDown or not viewmodelSystem then return false end

    -- Simple recoil simulation based on weapon type
    if currentSlot == "primary" then
        viewmodelSystem:addRecoil(0.05, math.random(-3, 3) / 100)
        print("Fired primary weapon")
        return true
    elseif currentSlot == "secondary" then
        viewmodelSystem:addRecoil(0.03, math.random(-2, 2) / 100)
        print("Fired secondary weapon")
        return true
    elseif currentSlot == "melee" then
        -- Melee attack
        print("Used melee weapon")
        return true
    end

    return false
end

-- Handle aiming based on weapon type
local function handleAiming(isAiming)
    if viewmodelSystem then
        viewmodelSystem:setAiming(isAiming)
        return true
    end
    return false
end

-- Handle sprinting
local function handleSprinting(isSprinting)
    if viewmodelSystem then
        viewmodelSystem:setSprinting(isSprinting)
        return true
    end
    return false
end

-- Set up input handling
local function setupInputs()
    print("Setting up input handlers...")

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- Mouse primary button (fire/attack)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            handleFiring(true)
            -- Mouse secondary button (aim)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            handleAiming(true)
            -- Weapon switching
        elseif input.KeyCode == Enum.KeyCode.One then
            equipWeapon("primary")
        elseif input.KeyCode == Enum.KeyCode.Two then
            equipWeapon("secondary")
        elseif input.KeyCode == Enum.KeyCode.Three then
            equipWeapon("melee")
            -- Sprint
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            handleSprinting(true)
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- Mouse secondary button release (aim)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            handleAiming(false)
            -- Stop sprinting
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            handleSprinting(false)
        end
    end)

    -- Mouse movement for weapon sway
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and viewmodelSystem then
            viewmodelSystem.lastMouseDelta = input.Delta
        end
    end)

    print("Input handlers set up!")
end