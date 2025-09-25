local RemoteEventsManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remoteEvents = {}
local remoteFunctions = {}

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
	"ResetBountyUI",

	-- Additional System Events
	"SystemInitialized",
	"PlayerDataLoaded",
	"WeaponStatsUpdated",
	"InventoryUpdated",
	"AchievementUnlocked",

	-- Miscellaneous
	"ChatMessage",
	"PlayerJoined",
	"PlayerLeft",
	"ErrorOccurred",
	"DebugMessage"
}

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

	-- Missing Functions (from error log)
	"GetPlayerClasses",
	"GetClassConfig",
	"ValidateClassChange",
	"GetAmmoCount",
	"CanDeploy",
	"DeployPlayer"
}

function RemoteEventsManager:Initialize()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")
	
	if not remoteEventsFolder then
		warn("RemoteEvents folder not found in FPSSystem")
		return
	end
	
	for _, eventName in pairs(REMOTE_EVENTS) do
		local remoteEvent = remoteEventsFolder:FindFirstChild(eventName)
		if not remoteEvent then
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = eventName
			remoteEvent.Parent = remoteEventsFolder
		end
		remoteEvents[eventName] = remoteEvent
	end
	
	for _, functionName in pairs(REMOTE_FUNCTIONS) do
		local remoteFunction = remoteEventsFolder:FindFirstChild(functionName)
		if not remoteFunction then
			remoteFunction = Instance.new("RemoteFunction")
			remoteFunction.Name = functionName
			remoteFunction.Parent = remoteEventsFolder
		end
		remoteFunctions[functionName] = remoteFunction
	end
	
	print("RemoteEventsManager initialized with " .. #REMOTE_EVENTS .. " events and " .. #REMOTE_FUNCTIONS .. " functions")
end

function RemoteEventsManager:GetEvent(eventName)
	return remoteEvents[eventName]
end

function RemoteEventsManager:GetFunction(functionName)
	return remoteFunctions[functionName]
end

function RemoteEventsManager:FireServer(eventName, ...)
	if RunService:IsClient() then
		local event = remoteEvents[eventName]
		if event then
			event:FireServer(...)
		else
			warn("RemoteEvent not found: " .. eventName)
		end
	end
end

function RemoteEventsManager:FireClient(player, eventName, ...)
	if RunService:IsServer() then
		local event = remoteEvents[eventName]
		if event then
			event:FireClient(player, ...)
		else
			warn("RemoteEvent not found: " .. eventName)
		end
	end
end

function RemoteEventsManager:FireAllClients(eventName, ...)
	if RunService:IsServer() then
		local event = remoteEvents[eventName]
		if event then
			event:FireAllClients(...)
		else
			warn("RemoteEvent not found: " .. eventName)
		end
	end
end

function RemoteEventsManager:InvokeServer(functionName, ...)
	if RunService:IsClient() then
		local func = remoteFunctions[functionName]
		if func then
			return func:InvokeServer(...)
		else
			warn("RemoteFunction not found: " .. functionName)
			return nil
		end
	end
end

function RemoteEventsManager:InvokeClient(player, functionName, ...)
	if RunService:IsServer() then
		local func = remoteFunctions[functionName]
		if func then
			return func:InvokeClient(player, ...)
		else
			warn("RemoteFunction not found: " .. functionName)
			return nil
		end
	end
end

return RemoteEventsManager