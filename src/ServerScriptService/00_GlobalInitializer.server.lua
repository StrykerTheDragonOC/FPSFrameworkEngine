-- This script runs first to initialize global state management
-- Replaces _G usage with centralized state management

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize global state manager
local GlobalStateManager = require(ReplicatedStorage.FPSSystem.Modules.GlobalStateManager)
GlobalStateManager:Initialize()

-- Initialize core systems
local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)
local TeamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)

-- Initialize the systems
DataStoreManager:Initialize()
TeamManager:Initialize()
GameConfig:Initialize()

-- Store in global state manager
GlobalStateManager:Set("DataStoreManager", DataStoreManager)
GlobalStateManager:Set("TeamManager", TeamManager)
GlobalStateManager:Set("GameConfig", GameConfig)

-- Set up global functions that other scripts expect
GlobalStateManager:Set("onInputBegan", nil)
GlobalStateManager:Set("onInputEnded", nil)
GlobalStateManager:Set("onFire", nil)

-- Legacy _G support for backward compatibility (temporary)
_G.GlobalStateManager = GlobalStateManager
_G.DataStoreManager = DataStoreManager
_G.TeamManager = TeamManager
_G.GameConfig = GameConfig
_G.onInputBegan = nil
_G.onInputEnded = nil
_G.onFire = nil

print("Global systems initialized with GlobalStateManager")
print("Global initializer completed")