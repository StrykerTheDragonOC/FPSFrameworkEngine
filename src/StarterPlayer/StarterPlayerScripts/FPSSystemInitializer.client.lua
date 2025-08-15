local FPSSystemInitializer = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module loading with proper error handling
local function safeRequire(moduleName)
    local success, result = pcall(function()
        local moduleScript = ReplicatedStorage.FPSSystem.Modules:FindFirstChild(moduleName)
        if moduleScript then
            return require(moduleScript)
        else
            return nil
        end
    end)

    if success and result then
        print("Loaded:", moduleName)
        return result
    else
        warn("Failed to load:", moduleName)
        return nil
    end
end

-- Initialize all FPS systems with missing module handling
function FPSSystemInitializer.initialize()
    print("Initializing FPS systems...")

    local systems = {}

    -- Load required systems (these MUST exist)
    systems.AdvancedSoundSystem = safeRequire("AdvancedSoundSystem")
    systems.WeaponFiringSystem = safeRequire("WeaponFiringSystem") 
    systems.AdvancedSoundSystem = safeRequire("AdvancedSoundSystem")

    -- Load optional systems (missing ones won't break the game)
    systems.ViewmodelSystem = safeRequire("ViewmodelSystem")
    systems.CrosshairSystem = safeRequire("CrosshairSystem")
    systems.FPSCamera = safeRequire("FPSCamera")
    systems.WeaponConverter = safeRequire("WeaponConverter")
    systems.ScopeSystem = safeRequire("ScopeSystem")
    systems.AttachmentSystem = safeRequire("AttachmentSystem")

    -- Initialize systems that loaded successfully
    for systemName, system in pairs(systems) do
        if system and system.init then
            local success, err = pcall(function()
                system.init()
            end)

            if success then
                print("Initialized:", systemName)
            else
                warn("Failed to initialize:", systemName, err)
            end
        end
    end

    print("FPS system initialization complete")
    return systems
end

return FPSSystemInitializer