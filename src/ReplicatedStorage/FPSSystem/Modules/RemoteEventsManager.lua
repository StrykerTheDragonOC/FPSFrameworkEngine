-- RemoteEventsManager.lua
-- Centralized manager for all RemoteEvents to prevent duplication
-- Place in ReplicatedStorage/FPSSystem/Modules

local RemoteEventsManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local FPS_SYSTEM_PATH = ReplicatedStorage:WaitForChild("FPSSystem")

-- Storage for created events
local remoteEvents = {}
local remoteEventsFolder = nil
local isInitialized = false

-- Initialize the RemoteEvents folder and manager
function RemoteEventsManager.initialize()
    if isInitialized then
        return remoteEventsFolder
    end
    
    print("[RemoteEventsManager] Initializing RemoteEvents system...")
    
    -- Create or get the RemoteEvents folder
    remoteEventsFolder = FPS_SYSTEM_PATH:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = FPS_SYSTEM_PATH
        print("[RemoteEventsManager] Created RemoteEvents folder")
    else
        print("[RemoteEventsManager] Using existing RemoteEvents folder")
    end
    
    isInitialized = true
    print("[RemoteEventsManager] RemoteEvents system initialized")
    
    return remoteEventsFolder
end

-- Get or create a RemoteEvent
function RemoteEventsManager.getOrCreateRemoteEvent(eventName, description)
    if not isInitialized then
        RemoteEventsManager.initialize()
    end
    
    if not eventName or eventName == "" then
        warn("[RemoteEventsManager] Invalid event name provided")
        return nil
    end
    
    -- Check if event already exists
    if remoteEvents[eventName] then
        return remoteEvents[eventName]
    end
    
    -- Look for existing event in folder
    local existingEvent = remoteEventsFolder:FindFirstChild(eventName)
    if existingEvent and existingEvent:IsA("RemoteEvent") then
        remoteEvents[eventName] = existingEvent
        print("[RemoteEventsManager] Found existing RemoteEvent:", eventName)
        return existingEvent
    end
    
    -- Create new RemoteEvent
    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = eventName
    remoteEvent.Parent = remoteEventsFolder
    
    -- Store reference
    remoteEvents[eventName] = remoteEvent
    
    print("[RemoteEventsManager] Created new RemoteEvent:", eventName, description and ("(" .. description .. ")") or "")
    
    return remoteEvent
end

-- Get RemoteEvents folder
function RemoteEventsManager.getRemoteEventsFolder()
    if not isInitialized then
        RemoteEventsManager.initialize()
    end
    
    return remoteEventsFolder
end

-- Get a specific RemoteEvent (without creating)
function RemoteEventsManager.getRemoteEvent(eventName)
    if not isInitialized then
        RemoteEventsManager.initialize()
    end
    
    return remoteEvents[eventName] or remoteEventsFolder:FindFirstChild(eventName)
end

-- List all managed RemoteEvents
function RemoteEventsManager.listRemoteEvents()
    if not isInitialized then
        RemoteEventsManager.initialize()
    end
    
    local eventList = {}
    for name, event in pairs(remoteEvents) do
        if event and event.Parent then
            table.insert(eventList, name)
        end
    end
    
    return eventList
end

-- Clean up disconnected events
function RemoteEventsManager.cleanup()
    for name, event in pairs(remoteEvents) do
        if not event or not event.Parent then
            remoteEvents[name] = nil
            print("[RemoteEventsManager] Cleaned up disconnected event:", name)
        end
    end
end

-- Get manager status
function RemoteEventsManager.getStatus()
    return {
        isInitialized = isInitialized,
        folderExists = remoteEventsFolder ~= nil,
        eventCount = #RemoteEventsManager.listRemoteEvents()
    }
end

return RemoteEventsManager