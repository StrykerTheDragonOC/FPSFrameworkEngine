-- MainFPSController.lua
-- Complete FPS controller that integrates all systems
-- Place in StarterPlayer/StarterPlayerScripts/MainFPSController.lua

local FPSController = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Player references
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- System modules
local systems = {}
local modules = {}

-- Current state
local state = {
    currentWeapon = nil,
    currentSlot = "PRIMARY",
    isAiming = false,
    isSprinting = false,
    isReloading = false,

    slots = {
        PRIMARY = nil,
        SECONDARY = nil,
        MELEE = nil,
        GRENADE = nil
    }
}

-- Input mappings
local inputActions = {
    primaryFire = Enum.UserInputType.MouseButton1,
    aim = Enum.UserInputType.MouseButton2,
    reload = Enum.KeyCode.R,
    sprint = Enum.KeyCode.LeftShift,

    weaponPrimary = Enum.KeyCode.One,
    weaponSecondary = Enum.KeyCode.Two,
    weaponMelee = Enum.KeyCode.Three,
    weaponGrenade = Enum.KeyCode.Four,

    throwGrenade = Enum.KeyCode.G,
    spotEnemy = Enum.KeyCode.Q,
    toggleAttachments = Enum.KeyCode.T,

    -- Movement
    crouch = Enum.KeyCode.C,
    prone = Enum.KeyCode.X,
    dive = Enum.KeyCode.Space -- Combined with X
}

-- Initialize controller
function FPSController:init()
    print("[FPS] Initializing main controller...")

    -- Load all modules
    self:loadModules()

    -- Initialize systems
    self:initSystems()

    -- Setup input handlers
    self:setupInputHandlers()

    -- Export globally
    _G.FPSController = self

    print("[FPS] Controller initialized!")
end

-- Load modules
function FPSController:loadModules()
    local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem")
    local modulesFolder = fpsSystem:WaitForChild("Modules")

    -- Required modules
    local requiredModules = {
        "ViewmodelSystem",
        "WeaponFiringSystem",
        "AdvancedMovementSystem",
        "CrosshairSystem",
        "AttachmentSystem",
        "ScopeSystem"
    }

    for _, moduleName in ipairs(requiredModules) do
        local module = modulesFolder:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(module)
            end)

            if success then
                modules[moduleName] = result
                print("[FPS] Loaded module:", moduleName)
            else
                warn("[FPS] Failed to load module:", moduleName, result)
            end
        else
            warn("[FPS] Module not found:", moduleName)
        end
    end

    -- Load weapon config
    local configFolder = fpsSystem:FindFirstChild("Config")
    if configFolder then
        local weaponConfig = configFolder:FindFirstChild("WeaponConfigManager")
        if weaponConfig then
            modules.WeaponConfig = require(weaponConfig)
            print("[FPS] Loaded weapon configuration")
        end
    end
end

-- Initialize systems
function FPSController:initSystems()
    -- Initialize viewmodel system
    if modules.ViewmodelSystem then
        systems.viewmodel = modules.ViewmodelSystem.new()
        systems.viewmodel:startUpdateLoop()
        print("[FPS] Viewmodel system ready")
    end

    -- Initialize firing system
    if modules.WeaponFiringSystem then
        systems.firing = modules.WeaponFiringSystem.new(systems.viewmodel)
        print("[FPS] Firing system ready")
    end

    -- Initialize movement system
    if modules.AdvancedMovementSystem then
        systems.movement = modules.AdvancedMovementSystem.new()
        print("[FPS] Movement system ready")
    end

    -- Initialize crosshair
    if modules.CrosshairSystem then
        systems.crosshair = modules.CrosshairSystem.new()
        print("[FPS] Crosshair system ready")
    end

    -- Initialize attachment system
    if modules.AttachmentSystem then
        systems.attachments = modules.AttachmentSystem
        print("[FPS] Attachment system ready")
    end

    -- Initialize scope system
    if modules.ScopeSystem then
        systems.scope = modules.ScopeSystem.new()
        print("[FPS] Scope system ready")
    end
end

-- Load weapon into slot
function FPSController:loadWeapon(slot, weaponName)
    if not modules.WeaponConfig then
        warn("[FPS] No weapon config loaded")
        return
    end

    local config = modules.WeaponConfig:getWeaponConfig(weaponName)
    if not config then
        warn("[FPS] No config for weapon:", weaponName)
        return
    end

    -- Store weapon data
    state.slots[slot] = {
        name = weaponName,
        config = config,
        attachments = {}
    }

    print("[FPS] Loaded", weaponName, "into", slot, "slot")
end

-- Equip weapon from slot
function FPSController:equipWeapon(slot)
    local weaponData = state.slots[slot]
    if not weaponData then
        warn("[FPS] No weapon in slot:", slot)
        return
    end

    -- Update state
    state.currentSlot = slot
    state.currentWeapon = weaponData
    state.isAiming = false

    -- Equip in viewmodel
    if systems.viewmodel then
        systems.viewmodel:equipWeapon(weaponData.name, slot)
    end

    -- Set weapon in firing system
    if systems.firing then
        systems.firing:setWeapon(nil, weaponData.config)
    end

    -- Update crosshair
    if systems.crosshair then
        systems.crosshair:updateFromWeaponState(weaponData.config, false)
    end

    print("[FPS] Equipped", weaponData.name, "from", slot)
end

-- Setup input handlers
function FPSController:setupInputHandlers()
    -- Input began
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        self:handleInputBegan(input)
    end)

    -- Input ended
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        self:handleInputEnded(input)
    end)

    -- Mouse movement
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if systems.viewmodel then
                systems.viewmodel:handleMouseDelta(input.Delta)
            end
        end
    end)
end

-- Handle input began
function FPSController:handleInputBegan(input)
    -- Primary fire
    if input.UserInputType == inputActions.primaryFire then
        self:handlePrimaryFire(true)

        -- Aim
    elseif input.UserInputType == inputActions.aim then
        self:handleAiming(true)

        -- Reload
    elseif input.KeyCode == inputActions.reload then
        self:handleReload()

        -- Sprint
    elseif input.KeyCode == inputActions.sprint then
        state.isSprinting = true
        if systems.viewmodel then
            systems.viewmodel:setSprinting(true)
        end

        -- Weapon switching
    elseif input.KeyCode == inputActions.weaponPrimary then
        self:equipWeapon("PRIMARY")
    elseif input.KeyCode == inputActions.weaponSecondary then
        self:equipWeapon("SECONDARY")
    elseif input.KeyCode == inputActions.weaponMelee then
        self:equipWeapon("MELEE")
    elseif input.KeyCode == inputActions.weaponGrenade then
        self:equipWeapon("GRENADE")

        -- Grenade throw
    elseif input.KeyCode == inputActions.throwGrenade then
        self:throwGrenade()

        -- Spot enemy
    elseif input.KeyCode == inputActions.spotEnemy then
        self:spotEnemy()

        -- Toggle attachments
    elseif input.KeyCode == inputActions.toggleAttachments then
        self:toggleAttachmentMode()
    end
end

-- Handle input ended
function FPSController:handleInputEnded(input)
    -- Primary fire
    if input.UserInputType == inputActions.primaryFire then
        self:handlePrimaryFire(false)

        -- Aim
    elseif input.UserInputType == inputActions.aim then
        self:handleAiming(false)

        -- Sprint
    elseif input.KeyCode == inputActions.sprint then
        state.isSprinting = false
        if systems.viewmodel then
            systems.viewmodel:setSprinting(false)
        end
    end
end

-- Handle primary fire
function FPSController:handlePrimaryFire(isPressed)
    if state.currentSlot == "PRIMARY" or state.currentSlot == "SECONDARY" then
        -- Gun firing
        if systems.firing then
            systems.firing:handleFiring(isPressed)
        end

    elseif state.currentSlot == "MELEE" and isPressed then
        -- Melee attack
        self:meleeAttack()

    elseif state.currentSlot == "GRENADE" and isPressed then
        -- Start cooking grenade
        self:startCookingGrenade()
    end
end

-- Handle aiming
function FPSController:handleAiming(isAiming)
    state.isAiming = isAiming

    -- Update viewmodel
    if systems.viewmodel then
        systems.viewmodel:setAiming(isAiming)
    end

    -- Update scope
    if systems.scope and state.currentWeapon then
        local config = state.currentWeapon.config
        if config.scope then
            systems.scope:scope(state.currentWeapon, isAiming)
        end
    end

    -- Update crosshair
    if systems.crosshair and state.currentWeapon then
        systems.crosshair:updateFromWeaponState(state.currentWeapon.config, isAiming)
    end

    -- Update camera FOV for aiming
    if isAiming then
        camera.FieldOfView = 60
    else
        camera.FieldOfView = 70
    end
end

-- Handle reload
function FPSController:handleReload()
    if state.currentSlot == "PRIMARY" or state.currentSlot == "SECONDARY" then
        if systems.firing then
            systems.firing:reload()
        end
    end
end

-- Melee attack
function FPSController:meleeAttack()
    if not state.currentWeapon then return end

    print("[FPS] Melee attack with", state.currentWeapon.name)

    -- Play attack animation
    if systems.viewmodel then
        systems.viewmodel:playAnimation("attack1")
    end

    -- Perform melee raycast
    local ray = workspace:Raycast(
        camera.CFrame.Position,
        camera.CFrame.LookVector * (state.currentWeapon.config.damage.range or 5),
        RaycastParams.new()
    )

    if ray and ray.Instance then
        local humanoid = ray.Instance.Parent:FindFirstChild("Humanoid")
        if humanoid then
            -- Check for backstab
            local isBackstab = false
            local targetLook = ray.Instance.Parent.HumanoidRootPart.CFrame.LookVector
            local attackDirection = (ray.Position - camera.CFrame.Position).Unit

            if targetLook:Dot(attackDirection) > 0.5 then
                isBackstab = true
            end

            -- Deal damage
            local damage = isBackstab and state.currentWeapon.config.damage.backstab 
                or state.currentWeapon.config.damage.front

            -- Send to server
            local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if remoteEvents then
                local meleeEvent = remoteEvents:FindFirstChild("MeleeHit") or Instance.new("RemoteEvent")
                meleeEvent.Name = "MeleeHit"
                meleeEvent.Parent = remoteEvents

                meleeEvent:FireServer(humanoid, damage, isBackstab)
            end

            print("[FPS] Melee hit for", damage, "damage", isBackstab and "(BACKSTAB)" or "")
        end
    end
end

-- Throw grenade
function FPSController:throwGrenade()
    print("[FPS] Throwing grenade")

    -- Quick grenade throw without switching
    if state.currentSlot ~= "GRENADE" then
        -- Remember current weapon
        local previousSlot = state.currentSlot

        -- Quick switch and throw
        self:equipWeapon("GRENADE")

        wait(0.5)

        -- Throw animation
        if systems.viewmodel then
            systems.viewmodel:playAnimation("throw")
        end

        -- Return to previous weapon
        wait(1)
        self:equipWeapon(previousSlot)
    else
        -- Already holding grenade
        if systems.viewmodel then
            systems.viewmodel:playAnimation("throw")
        end
    end
end

-- Start cooking grenade
function FPSController:startCookingGrenade()
    if state.currentSlot == "GRENADE" then
        print("[FPS] Cooking grenade")
        -- Grenade cooking logic here
    end
end

-- Spot enemy
function FPSController:spotEnemy()
    -- Cast ray from camera
    local ray = workspace:Raycast(
        camera.CFrame.Position,
        camera.CFrame.LookVector * 1000,
        RaycastParams.new()
    )

    if ray and ray.Instance then
        local humanoid = ray.Instance.Parent:FindFirstChild("Humanoid")
        if humanoid and humanoid.Parent ~= player.Character then
            print("[FPS] Spotted:", humanoid.Parent.Name)

            -- Create spot marker (UI element)
            -- This would be implemented based on your UI system
        end
    end
end

-- Toggle attachment mode
function FPSController:toggleAttachmentMode()
    print("[FPS] Toggling attachment mode")

    -- Unlock/lock mouse
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true

        -- Open attachment UI
        -- This would open your attachment selection UI
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end

-- Get ammo info
function FPSController:getAmmoInfo()
    if systems.firing then
        return systems.firing:getAmmoInfo()
    end

    return {current = 0, magazine = 0, reserve = 0}
end

-- Get current weapon
function FPSController:getCurrentWeapon()
    return state.currentWeapon
end

-- Get current slot
function FPSController:getCurrentSlot()
    return state.currentSlot
end

-- Initialize on script run
FPSController:init()

return FPSController