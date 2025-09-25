local GameConfig = {}
local Workspace = game:GetService("Workspace")

local config = nil

local DEFAULT_CONFIG = {
	-- Game Settings
	MaxPlayers = 20,
	MinPlayersToStart = 2,
	GameDuration = 1200,
	LobbyWaitTime = 30,
	FriendlyFire = false,
	RespawnTime = 5,
	MaxHealth = 100,
	
	-- XP and Progression
	BaseXPPerKill = 100,
	HeadshotMultiplier = 1.5,
	DefaultCredits = 500,
	
	-- Teams
	Teams = {"FBI", "KFC"},
	
	-- Movement
	WalkSpeed = 16,
	RunSpeed = 24,
	CrouchSpeed = 8,
	ProneSpeed = 4,
	
	-- Day/Night Cycle
	DayNightCycleSpeed = 600,
	
	-- Current Game State
	CurrentGamemode = "TDM",
	AllowSpectating = true
}

function GameConfig:Initialize()
	config = Workspace:FindFirstChild("GameConfig")
	if not config then
		warn("GameConfig not found in Workspace, using defaults")
	end
	
	_G.GameConfig = self
	print("GameConfig initialized")
	return true
end

function GameConfig:Get(valueName)
	if config then
		local valueObject = config:FindFirstChild(valueName)
		if valueObject then
			return valueObject.Value
		end
	end
	
	-- Fallback to default config
	local defaultValue = DEFAULT_CONFIG[valueName]
	if defaultValue ~= nil then
		return defaultValue
	end
	
	warn("Config value not found: " .. valueName)
	return nil
end

function GameConfig:Set(valueName, value)
	if not config then
		self:Initialize()
	end
	
	local valueObject = config:FindFirstChild(valueName)
	if valueObject then
		valueObject.Value = value
		return true
	else
		warn("Config value not found: " .. valueName)
		return false
	end
end

function GameConfig:GetGamemodeTimer()
	return self:Get("GamemodeTimer") or 1200
end

function GameConfig:GetDayNightCycleSpeed()
	return self:Get("DayNightCycleSpeed") or 600
end

function GameConfig:IsFriendlyFireEnabled()
	return self:Get("FriendlyFire") or false
end

function GameConfig:GetCurrentGamemode()
	return self:Get("CurrentGamemode") or "TDM"
end

function GameConfig:SetCurrentGamemode(gamemode)
	return self:Set("CurrentGamemode", gamemode)
end

function GameConfig:GetMaxPlayers()
	return self:Get("MaxPlayers") or 20
end

function GameConfig:GetRespawnTime()
	return self:Get("RespawnTime") or 5
end

function GameConfig:GetBaseXPPerKill()
	return self:Get("BaseXPPerKill") or 100
end

function GameConfig:GetHeadshotMultiplier()
	return self:Get("HeadshotMultiplier") or 1.5
end

function GameConfig:GetDefaultCredits()
	return self:Get("DefaultCredits") or 500
end

function GameConfig:IsSpectatingAllowed()
	return self:Get("AllowSpectating") or true
end

function GameConfig:CalculateXPRequired(rank)
	return 1000 * ((rank * rank + rank) / 2)
end

function GameConfig:CalculateCreditReward(rank)
	if rank <= 20 then
		return ((rank - 1) * 5) + 200
	else
		return (rank * 5) + 200
	end
end

function GameConfig:GetXPReward(rewardType)
	local xpRewards = {
		Kill = 100,
		Headshot = 25,
		Assist = 50,
		Wallbang = 15,
		LongDistanceShot = 20,
		QuickScope = 30,
		NoScope = 40,
		Backstab = 35,
		DoubleKill = 50,
		TripleKill = 100,
		QuadKill = 200,
		ObjectiveCapture = 150,
		ObjectiveHold = 5,
		SpottedKill = 10,
		Suppression = 5
	}
	
	return xpRewards[rewardType] or 0
end

function GameConfig:GetTeamColor(teamName)
	if teamName == "FBI" then
		return Color3.fromRGB(0, 0, 139) -- Navy Blue
	elseif teamName == "KFC" then
		return Color3.fromRGB(139, 0, 0) -- Maroon
	end
	return Color3.new(0.5, 0.5, 0.5) -- Gray default
end

return GameConfig