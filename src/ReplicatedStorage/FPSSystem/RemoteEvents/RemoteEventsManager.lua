local RemoteEventsManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remoteEvents = {}
local remoteFunctions = {}

local REMOTE_EVENTS = {
	"WeaponFired",
	"WeaponReloaded", 
	"WeaponEquipped",
	"WeaponUnequipped",
	"PlayerDamaged",
	"PlayerKilled",
	"PlayerSpawned",
	"XPAwarded",
	"LevelUp",
	"SpotPlayer",
	"LoseSpot",
	"CreateMapPing",
	"ChangeTeam",
	"UpdateStats",
	"StatusEffect",
	"GrenadeThrown",
    "MeleeAttack",
    "GamePhaseChanged",
    "AmmoUpdate",
    "ClassUpdate",
    "TimeUpdate",
    "PickupSpawned",
    "PlayerDeployed",
    "GameStarted",
    "GameEnded",
    "AttachmentDataUpdated",
    "SaveWeaponLoadout",
    "KillStreakAchieved",
    "PurchaseResult",
    "MenuStateChanged",
    "DeployPlayer",
    "LoadoutChanged",
    "PlayerJoinedBattle",
    "ReturnToLobby",
    "VoteGamemode",
    "VotingStarted",
    "VotingEnded",
    "VoteUpdate",
    "AdminTeamChange",
    "AdminError",
    "AdminSuccess",
    "TeamChangedByAdmin",
    "VoteForGamemode",
    "PlayerDeploy",
    "SpawnVehicle",
    "DestroyVehicle",
    "ClearVehicles",
}

local REMOTE_FUNCTIONS = {
	"GetPlayerData",
	"GetWeaponConfig",
	"ValidateWeaponAction",
	"GetTeamSpawns",
	"GetGamemodeInfo",
	"GetPlayerStats",
	"PurchaseItem",
	"GetShopItems",
    "ValidateLoadout",
    "IsPlayerAdmin",
    
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