-- ToolViewmodelConnector.client.lua
-- Connects tool equipping/unequipping to the ImprovedViewmodelSystem
-- Place in StarterPlayer/StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for the improved viewmodel system to be available
local function waitForViewmodelSystem()
    local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem", 10)
    if not fpsSystem then
        warn("[ToolConnector] FPSSystem not found")
        return nil
    end
    
    local modules = fpsSystem:WaitForChild("Modules", 10)
    if not modules then
        warn("[ToolConnector] Modules folder not found")
        return nil
    end
    
    local viewmodelModule = modules:WaitForChild("ImprovedViewmodelSystem", 10)
    if not viewmodelModule then
        warn("[ToolConnector] ImprovedViewmodelSystem not found")
        return nil
    end
    
    local success, ViewmodelSystem = pcall(require, viewmodelModule)
    if not success then
        warn("[ToolConnector] Failed to require ImprovedViewmodelSystem:", ViewmodelSystem)
        return nil
    end
    
    return ViewmodelSystem
end

-- Setup equip/unequip listeners for a tool
local function setupTool(tool, viewmodelInstance)
    if tool:IsA("Tool") then
        tool.Equipped:Connect(function()
            print("[ToolConnector] Tool equipped:", tool.Name)
            viewmodelInstance:onToolEquipped(tool)
        end)

        tool.Unequipped:Connect(function()
            print("[ToolConnector] Tool unequipped:", tool.Name)
            viewmodelInstance:onToolUnequipped(tool)
        end)
    end
end

-- Initialize tool connections
local function initializeToolConnections()
    print("[ToolConnector] Initializing tool-viewmodel connections...")
    
    local ViewmodelSystem = waitForViewmodelSystem()
    if not ViewmodelSystem then
        warn("[ToolConnector] Could not load viewmodel system")
        return
    end
    
    -- Create viewmodel instance
    local viewmodelInstance = ViewmodelSystem.new()
    
    -- Store globally for access
    _G.ImprovedViewmodelSystem = viewmodelInstance
    
    local function onCharacterAdded(character)
        if not character then return end
        
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end
        
        print("[ToolConnector] Character added, setting up tool connections")

        -- Setup for tools already in backpack
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            setupTool(tool, viewmodelInstance)
        end

        -- Setup for tools added later to backpack
        player.Backpack.ChildAdded:Connect(function(tool)
            setupTool(tool, viewmodelInstance)
        end)

        -- Setup for tools already in character
        for _, tool in ipairs(character:GetChildren()) do
            setupTool(tool, viewmodelInstance)
        end

        -- Setup for tools added later to character
        character.ChildAdded:Connect(function(tool)
            setupTool(tool, viewmodelInstance)
        end)

        -- Start the viewmodel update loop
        viewmodelInstance:startUpdateLoop()
        
        print("[ToolConnector] Tool connections established for character")
    end
    
    -- Setup for current character
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    -- Setup for future characters
    player.CharacterAdded:Connect(onCharacterAdded)
    
    print("[ToolConnector] Tool-viewmodel connector initialized successfully")
end

-- Initialize with error handling
task.spawn(function()
    local success, err = pcall(initializeToolConnections)
    if not success then
        warn("[ToolConnector] Failed to initialize:", err)
    end
end)

print("[ToolConnector] Tool-Viewmodel Connector loaded")
