local XPSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)

-- XP Reward Values (based on requirements)
local XP_REWARDS = {
	-- Basic Combat
	Kill = 100,
	Assist = 50,
	
	-- Skill-based bonuses
	Headshot = 25,
	LongRangeKill = 20,
	LongDistanceShot = 20,
	Quickscope = 30,
	NoScope = 40,
	Wallbang = 15,
	Suppression = 5,
	Backstab = 35,
	
	-- Multi-kills
	DoubleKill = 50,
	TripleKill = 100,
	QuadKill = 200,
	
	-- Spotted system
	SpottedKill = 10,
	SpottedAssist = 10,
	
	-- Objectives
	ObjectiveCapture = 150,
	ObjectiveDefend = 100,
	ObjectiveHold = 5, -- Per tick while holding
	
	-- Progression
	WeaponMastery = 100, -- Per mastery level gained
	AttachmentUnlock = 50
}

-- Credit rewards per rank (formula: Credit = ((rank-1) * 5) + 200 for ranks 1-20, (rank * 5) + 200 for 21+)
local function calculateCreditReward(rank)
	if rank <= 20 then
		return ((rank - 1) * 5) + 200
	else
		return (rank * 5) + 200
	end
end

function XPSystem:Initialize()
	if RunService:IsServer() then
		RemoteEventsManager:Initialize()
		
		local xpAwardedEvent = RemoteEventsManager:GetEvent("XPAwarded")
		local levelUpEvent = RemoteEventsManager:GetEvent("LevelUp")
		
		print("XPSystem initialized on server")
	else
		print("XPSystem initialized on client")
	end
end

function XPSystem:CalculateKillXP(killData)
	local baseXP = XP_REWARDS.Kill
	local bonusXP = 0
	
	if killData.IsHeadshot then
		bonusXP = bonusXP + XP_REWARDS.Headshot
	end
	
	if killData.Distance and killData.Distance > 200 then
		bonusXP = bonusXP + XP_REWARDS.LongRangeKill
	end
	
	if killData.IsWallbang then
		bonusXP = bonusXP + XP_REWARDS.Wallbang
	end
	
	if killData.IsQuickscope then
		bonusXP = bonusXP + XP_REWARDS.Quickscope
	end
	
	if killData.IsNoScope then
		bonusXP = bonusXP + XP_REWARDS.NoScope
	end
	
	if killData.IsBackstab then
		bonusXP = bonusXP + XP_REWARDS.Backstab
	end
	
	if killData.IsSpottedKill then
		bonusXP = bonusXP + XP_REWARDS.SpottedKill
	end
	
	local killStreak = killData.KillStreak or 1
	if killStreak >= 2 then
		if killStreak == 2 then
			bonusXP = bonusXP + XP_REWARDS.DoubleKill
		elseif killStreak == 3 then
			bonusXP = bonusXP + XP_REWARDS.TripleKill
		elseif killStreak >= 4 then
			bonusXP = bonusXP + XP_REWARDS.QuadKill
		end
	end
	
	local totalXP = baseXP + bonusXP
	
	local headshotMultiplier = GameConfig:GetHeadshotMultiplier() or 1.5
	if killData.IsHeadshot then
		totalXP = math.floor(totalXP * headshotMultiplier)
	end
	
	return totalXP, {
		BaseXP = baseXP,
		BonusXP = bonusXP,
		Multipliers = killData.IsHeadshot and headshotMultiplier or 1.0,
		Reasons = self:GetXPReasons(killData)
	}
end

function XPSystem:GetXPReasons(killData)
	local reasons = {"Kill"}
	
	if killData.IsHeadshot then
		table.insert(reasons, "Headshot")
	end
	
	if killData.Distance and killData.Distance > 200 then
		table.insert(reasons, "Long Range")
	end
	
	if killData.IsWallbang then
		table.insert(reasons, "Wallbang")
	end
	
	if killData.IsQuickscope then
		table.insert(reasons, "Quickscope")
	end
	
	if killData.IsNoScope then
		table.insert(reasons, "No Scope")
	end
	
	if killData.IsBackstab then
		table.insert(reasons, "Backstab")
	end
	
	if killData.IsSpottedKill then
		table.insert(reasons, "Spotted Enemy")
	end
	
	local killStreak = killData.KillStreak or 1
	if killStreak >= 2 then
		if killStreak == 2 then
			table.insert(reasons, "Double Kill")
		elseif killStreak == 3 then
			table.insert(reasons, "Triple Kill")
		elseif killStreak >= 4 then
			table.insert(reasons, "Quad Kill+")
		end
	end
	
	return reasons
end

function XPSystem:GetAssistXP()
	return XP_REWARDS.Assist
end

function XPSystem:GetObjectiveXP(objectiveType)
	if objectiveType == "capture" then
		return XP_REWARDS.ObjectiveCapture
	elseif objectiveType == "defend" then
		return XP_REWARDS.ObjectiveDefend
	elseif objectiveType == "hold" then
		return XP_REWARDS.ObjectiveHold
	end
	return 0
end

function XPSystem:GetSuppressionXP()
	return XP_REWARDS.Suppression
end

function XPSystem:GetWeaponMasteryXP()
	return XP_REWARDS.WeaponMastery
end

function XPSystem:GetAttachmentUnlockXP()
	return XP_REWARDS.AttachmentUnlock
end

-- Core Progression Functions (using exact formula from requirements)
function XPSystem:CalculateXPForLevel(rank)
	-- Formula: XP = 1000 × ((rank² + rank) ÷ 2)
	return 1000 * ((rank * rank + rank) / 2)
end

function XPSystem:CalculateLevelFromXP(totalXP)
	if totalXP <= 0 then
		return 0
	end
	
	local level = 0
	local accumulatedXP = 0
	
	-- Find the highest level where accumulated XP <= totalXP
	repeat
		level = level + 1
		local xpForThisLevel = self:CalculateXPForLevel(level)
		if accumulatedXP + xpForThisLevel <= totalXP then
			accumulatedXP = accumulatedXP + xpForThisLevel
		else
			level = level - 1
			break
		end
	until level >= 1000 -- Safety cap
	
	return level
end

function XPSystem:GetXPToNextLevel(currentXP, currentLevel)
	if not currentLevel then
		currentLevel = self:CalculateLevelFromXP(currentXP)
	end
	
	local nextLevelXP = self:CalculateXPForLevel(currentLevel + 1)
	local currentLevelTotalXP = 0
	
	-- Calculate total XP needed to reach current level
	for i = 1, currentLevel do
		currentLevelTotalXP = currentLevelTotalXP + self:CalculateXPForLevel(i)
	end
	
	return (currentLevelTotalXP + nextLevelXP) - currentXP
end

function XPSystem:GetLevelProgress(currentXP, currentLevel)
	if not currentLevel then
		currentLevel = self:CalculateLevelFromXP(currentXP)
	end
	
	if currentLevel == 0 then
		local nextLevelXP = self:CalculateXPForLevel(1)
		return currentXP / nextLevelXP
	end
	
	local currentLevelTotalXP = 0
	for i = 1, currentLevel do
		currentLevelTotalXP = currentLevelTotalXP + self:CalculateXPForLevel(i)
	end
	
	local nextLevelXP = self:CalculateXPForLevel(currentLevel + 1)
	local progressInCurrentLevel = currentXP - currentLevelTotalXP
	
	return math.clamp(progressInCurrentLevel / nextLevelXP, 0, 1)
end

-- Credit System Functions
function XPSystem:CalculateCreditReward(rank)
	return calculateCreditReward(rank)
end

function XPSystem:GetDefaultCredits()
	return 200 -- Starting credits for new players (Rank 0)
end

-- Rank-Up Detection and Rewards
function XPSystem:CheckForLevelUp(oldXP, newXP)
	local oldLevel = self:CalculateLevelFromXP(oldXP)
	local newLevel = self:CalculateLevelFromXP(newXP)
	
	if newLevel > oldLevel then
		local creditReward = self:CalculateCreditReward(newLevel)
		return true, newLevel, creditReward
	end
	
	return false, newLevel, 0
end

-- Comprehensive XP Award System
function XPSystem:AwardXP(player, xpType, amount, additionalData)
	if RunService:IsClient() then
		warn("XPSystem:AwardXP should only be called on server")
		return
	end
	
	local xpAmount = amount or XP_REWARDS[xpType] or 0
	if xpAmount <= 0 then
		return
	end
	
	-- Fire remote event to update player XP
	local awardXPEvent = RemoteEventsManager:GetEvent("AwardXP")
	if awardXPEvent then
		awardXPEvent:FireClient(player, xpType, xpAmount, additionalData)
	end
end

-- Enhanced Kill XP Calculation
function XPSystem:CalculateAdvancedKillXP(killData)
	local baseXP = XP_REWARDS.Kill
	local bonusXP = 0
	local reasons = {"Kill"}
	
	-- Headshot bonus
	if killData.IsHeadshot then
		bonusXP = bonusXP + XP_REWARDS.Headshot
		table.insert(reasons, "Headshot")
	end
	
	-- Distance bonus
	if killData.Distance and killData.Distance > 200 then
		bonusXP = bonusXP + XP_REWARDS.LongDistanceShot
		table.insert(reasons, "Long Distance")
	end
	
	-- Wallbang bonus
	if killData.IsWallbang then
		bonusXP = bonusXP + XP_REWARDS.Wallbang
		table.insert(reasons, "Wallbang")
	end
	
	-- Quickscope/NoScope bonuses
	if killData.IsQuickscope then
		bonusXP = bonusXP + XP_REWARDS.Quickscope
		table.insert(reasons, "Quickscope")
	elseif killData.IsNoScope then
		bonusXP = bonusXP + XP_REWARDS.NoScope
		table.insert(reasons, "No Scope")
	end
	
	-- Backstab bonus (for melee)
	if killData.IsBackstab then
		bonusXP = bonusXP + XP_REWARDS.Backstab
		table.insert(reasons, "Backstab")
	end
	
	-- Spotted enemy bonus
	if killData.IsSpottedKill then
		bonusXP = bonusXP + XP_REWARDS.SpottedKill
		table.insert(reasons, "Spotted Enemy")
	end
	
	-- Multi-kill bonuses
	local killStreak = killData.KillStreak or 1
	if killStreak >= 2 then
		if killStreak == 2 then
			bonusXP = bonusXP + XP_REWARDS.DoubleKill
			table.insert(reasons, "Double Kill")
		elseif killStreak == 3 then
			bonusXP = bonusXP + XP_REWARDS.TripleKill
			table.insert(reasons, "Triple Kill")
		elseif killStreak >= 4 then
			bonusXP = bonusXP + XP_REWARDS.QuadKill
			table.insert(reasons, "Quad Kill+")
		end
	end
	
	local totalXP = baseXP + bonusXP
	
	return totalXP, {
		BaseXP = baseXP,
		BonusXP = bonusXP,
		TotalXP = totalXP,
		Reasons = reasons,
		KillData = killData
	}
end

-- Get XP reward for specific action
function XPSystem:GetXPReward(actionType)
	return XP_REWARDS[actionType] or 0
end

-- Player Statistics Functions
function XPSystem:CreatePlayerStats()
	return {
		TotalXP = 0,
		CurrentLevel = 0,
		Credits = self:GetDefaultCredits(),
		
		-- Match Stats
		Kills = 0,
		Deaths = 0,
		Assists = 0,
		Score = 0,
		KillStreak = 0,
		
		-- All-time Stats
		TotalKills = 0,
		TotalDeaths = 0,
		TotalAssists = 0,
		TotalScore = 0,
		HighestKillStreak = 0,
		
		-- Weapon Mastery
		WeaponKills = {}, -- [WeaponName] = KillCount
		WeaponMastery = {}, -- [WeaponName] = MasteryLevel
		
		-- Unlocks
		UnlockedWeapons = {},
		UnlockedAttachments = {},
		
		-- Other Stats
		HeadshotCount = 0,
		LongDistanceKills = 0,
		WallbangKills = 0,
		BackstabKills = 0,
		ObjectiveCaptures = 0
	}
end

-- Level-up notification system
function XPSystem:CreateLevelUpNotification(newLevel, creditReward)
	return {
		Type = "LevelUp",
		Level = newLevel,
		Credits = creditReward,
		Message = "Level Up! Rank " .. newLevel .. " +" .. creditReward .. " Credits"
	}
end

return XPSystem