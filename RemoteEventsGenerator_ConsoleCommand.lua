-- RemoteEventsGenerator_ConsoleCommand.lua
-- Run this ONCE in Studio Console to generate all missing RemoteEvents
-- This creates all required RemoteEvents and RemoteFunctions for the FPS system

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔗 RemoteEvents Generator Starting...")

-- Ensure FPSSystem folder exists
local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
if not fpsSystem then
    fpsSystem = Instance.new("Folder")
    fpsSystem.Name = "FPSSystem"
    fpsSystem.Parent = ReplicatedStorage
    print("📁 Created FPSSystem folder")
end

-- Ensure RemoteEvents folder exists
local remoteEventsFolder = fpsSystem:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = fpsSystem
    print("📁 Created RemoteEvents folder")
end

-- Complete list of required RemoteEvents
local REMOTE_EVENTS = {
    -- Weapon System
    "WeaponFired",
    "WeaponReloaded",
    "WeaponEquipped",
    "WeaponUnequipped",
    "WeaponSwitched",
    "MagicWeaponActivated",
    "AdminWeaponUsed",
    "WeaponJammed",
    "WeaponOverheat",

    -- Combat System
    "PlayerDamaged",
    "PlayerKilled",
    "PlayerAssist",
    "HeadshotKill",
    "BackstabKill",
    "LongRangeKill",
    "WallbangKill",
    "DoubleKill",
    "TripleKill",
    "QuadKill",
    "KillStreak",
    "MeleeAttack",
    "GrenadeThrown",
    "GrenadeExploded",
    "GrenadeCooked",
    "C4Planted",
    "C4Detonated",

    -- Movement & Status
    "PlayerSpawned",
    "PlayerMoved",
    "PlayerSliding",
    "PlayerLedgeGrab",
    "PlayerDolphinDive",
    "PlayerCrouched",
    "PlayerProne",
    "StatusEffect",
    "StatusEffectRemoved",
    "PlayerBleeding",
    "PlayerFractured",
    "PlayerDeafened",
    "PlayerBurning",
    "PlayerFrozen",

    -- XP & Progression
    "XPAwarded",
    "LevelUp",
    "CreditsAwarded",
    "WeaponUnlocked",
    "AttachmentUnlocked",
    "MasteryUnlocked",
    "PerkUnlocked",

    -- Team & Spotting
    "SpotPlayer",
    "LoseSpot",
    "CreateMapPing",
    "ChangeTeam",
    "TeamSwitched",
    "PlayerDeployed",
    "PlayerJoinedBattle",
    "ReturnToLobby",

    -- Game Management
    "GamePhaseChanged",
    "GameStarted",
    "GameEnded",
    "GamemodeChanged",
    "MapChanged",
    "RoundStarted",
    "RoundEnded",
    "TimeUpdate",
    "DayNightChanged",
    "ObjectiveCaptured",
    "ObjectiveLost",

    -- UI & Menu
    "MenuStateChanged",
    "LoadoutChanged",
    "AttachmentEquipped",
    "AttachmentRemoved",
    "WeaponCustomized",
    "SkinEquipped",
    "SettingsChanged",
    "TabPressed",
    "ScoreboardToggled",

    -- Shop & Economy
    "PurchaseItem",
    "PurchaseResult",
    "ShopItemBought",
    "SkinPurchased",
    "WeaponPurchased",
    "AttachmentPurchased",
    "DailySkinRotation",

    -- Voting System
    "VoteGamemode",
    "VotingStarted",
    "VotingEnded",
    "VoteUpdate",
    "VoteCast",

    -- Pickups & Environment
    "PickupSpawned",
    "PickupCollected",
    "PickupDespawned",
    "AmmoRefilled",
    "HealthRestored",
    "ArmorPickedUp",
    "NightVisionPickedUp",
    "DestructionTriggered",
    "ExplosionDamage",

    -- Admin System
    "AdminCommand",
    "AdminTeamChange",
    "AdminKick",
    "AdminBan",
    "AdminError",
    "AdminSuccess",
    "TeamChangedByAdmin",
    "AdminModeToggled",

    -- Vehicle System
    "SpawnVehicle",
    "DestroyVehicle",
    "ClearVehicles",
    "VehicleAction",
    "VehicleEntered",
    "VehicleExited",
    "VehicleDamaged",
    "VehicleDestroyed",
    "VehicleRepaired",

    -- Missing Events (from error log)
    "UpdateStats",
    "ClassUpdate",
    "AmmoUpdate",
    "DeployPlayer",
    "DeploymentSuccessful",
    "DeploymentError",
    "ReturnedToLobby",
    "TeamSelected",
    "AdminError",
    "AdminSuccess",
    "TeamChangedByAdmin",
    "AdminTeamChangeSuccess",
    "GetPlayerSetting",
    "ResetBountyUI",

    -- Additional System Events
    "ChatMessage",
    "PlayerJoined",
    "PlayerLeft",
    "ErrorOccurred",
    "DebugMessage",
    "SystemInitialized",
    "PlayerDataLoaded",
    "WeaponStatsUpdated",
    "InventoryUpdated",
    "AchievementUnlocked"
}

-- Complete list of required RemoteFunctions
local REMOTE_FUNCTIONS = {
    -- Player Data
    "GetPlayerData",
    "GetPlayerStats",
    "GetPlayerLoadout",
    "GetPlayerUnlockedWeapons",
    "GetPlayerAttachments",
    "GetPlayerProgress",
    "GetPlayerCredits",
    "GetPlayerLevel",

    -- Weapon System
    "GetWeaponConfig",
    "GetWeaponStats",
    "GetWeaponPool",
    "GetRandomWeaponPool",
    "GetWeaponAttachments",
    "ValidateWeaponAction",
    "ValidateLoadout",
    "GetWeaponMastery",
    "CanUseWeapon",

    -- Shop & Economy
    "GetShopItems",
    "GetDailyShop",
    "PurchaseItem",
    "PurchaseWeapon",
    "PurchaseAttachment",
    "PurchaseSkin",
    "ValidatePurchase",
    "GetItemPrice",

    -- Game Management
    "GetTeamSpawns",
    "GetGamemodeInfo",
    "GetCurrentGamemode",
    "GetMapInfo",
    "GetServerSettings",
    "GetGameState",
    "GetObjectiveStatus",
    "GetRoundTimeLeft",

    -- Leaderboard & Statistics
    "GetLeaderboard",
    "GetTopPlayers",
    "GetPlayerRank",
    "GetMatchStats",
    "GetWeaponStats",
    "GetKillFeed",

    -- Admin Functions
    "IsPlayerAdmin",
    "GetAdminCommands",
    "ExecuteAdminCommand",
    "GetPlayerPermissions",
    "ValidateAdminAction",

    -- Vehicle Functions
    "GetActiveVehicles",
    "GetVehicleConfig",
    "CanSpawnVehicle",
    "GetVehicleHealth",

    -- Attachment System
    "GetAvailableAttachments",
    "GetAttachmentConfig",
    "CanEquipAttachment",
    "GetAttachmentUnlockRequirements",

    -- Validation Functions
    "ValidateMovement",
    "ValidateCombatAction",
    "ValidateTeamAction",
    "ValidateShopAction",
    "AntiCheatValidation",

    -- Missing Functions
    "GetPlayerClasses",
    "GetClassConfig",
    "ValidateClassChange",
    "GetAmmoCount",
    "CanDeploy"
}

-- Function to create RemoteEvent if it doesn't exist
local function createRemoteEvent(eventName)
    local existing = remoteEventsFolder:FindFirstChild(eventName)
    if not existing then
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = remoteEventsFolder
        return true
    end
    return false
end

-- Function to create RemoteFunction if it doesn't exist
local function createRemoteFunction(functionName)
    local existing = remoteEventsFolder:FindFirstChild(functionName)
    if not existing then
        local remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = functionName
        remoteFunction.Parent = remoteEventsFolder
        return true
    end
    return false
end

-- Generate all RemoteEvents
print("\n🔗 Creating RemoteEvents...")
local eventsCreated = 0
for _, eventName in ipairs(REMOTE_EVENTS) do
    if createRemoteEvent(eventName) then
        eventsCreated = eventsCreated + 1
        print("  ✅ Created: " .. eventName)
    end
end

-- Generate all RemoteFunctions
print("\n📞 Creating RemoteFunctions...")
local functionsCreated = 0
for _, functionName in ipairs(REMOTE_FUNCTIONS) do
    if createRemoteFunction(functionName) then
        functionsCreated = functionsCreated + 1
        print("  ✅ Created: " .. functionName)
    end
end

-- Summary
print("\n🎉 RemoteEvents Generation Complete!")
print("📊 Summary:")
print("  - RemoteEvents created: " .. eventsCreated)
print("  - RemoteFunctions created: " .. functionsCreated)
print("  - Total RemoteEvents: " .. #REMOTE_EVENTS)
print("  - Total RemoteFunctions: " .. #REMOTE_FUNCTIONS)

-- Validation
print("\n🔍 Validating RemoteEvents folder...")
local totalChildren = #remoteEventsFolder:GetChildren()
local expectedTotal = #REMOTE_EVENTS + #REMOTE_FUNCTIONS

if totalChildren >= expectedTotal then
    print("✅ All RemoteEvents and RemoteFunctions are present!")
    print("📁 Location: ReplicatedStorage.FPSSystem.RemoteEvents")
    print("📋 Ready for RemoteEventsManager initialization")
else
    warn("❌ Missing some RemoteEvents or RemoteFunctions")
    warn("Expected: " .. expectedTotal .. ", Found: " .. totalChildren)
end

print("\n✨ You can now run your scripts without RemoteEvent errors!")
return true