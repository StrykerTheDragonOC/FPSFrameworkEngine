local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)

local KillStreakManager = {}

local playerKillStreaks = {}
local activeRewards = {}

-- Kill streak rewards
local KILLSTREAK_REWARDS = {
	[3] = {
		Name = "UAV Scan",
		Description = "Reveal all enemies on radar for 30 seconds",
		Type = "Team",
		Duration = 30
	},
	[5] = {
		Name = "Ammo Resupply",
		Description = "Refill ammo for all weapons",
		Type = "Personal"
	},
	[7] = {
		Name = "Damage Boost",
		Description = "+50% weapon damage for 20 seconds",
		Type = "Personal",
		Duration = 20
	},
	[10] = {
		Name = "Team Health Boost",
		Description = "Restore full health for entire team",
		Type = "Team"
	},
	[15] = {
		Name = "Invincibility",
		Description = "Take no damage for 10 seconds",
		Type = "Personal",
		Duration = 10
	},
	[20] = {
		Name = "Nuclear Strike",
		Description = "Eliminate all enemy players",
		Type = "Global"
	}
}

function KillStreakManager:Initialize()
	RemoteEventsManager:Initialize()
	GameConfig:Initialize()
	
	-- Listen for player kills
	local playerKilledEvent = RemoteEventsManager:GetEvent("PlayerKilled")
	if playerKilledEvent then
		playerKilledEvent.OnServerEvent:Connect(function(killData)
			if killData.Killer then
				self:HandleKill(killData.Killer)
			end
			if killData.Victim then
				self:HandleDeath(killData.Victim)
			end
		end)
	end
	
	-- Player cleanup
	Players.PlayerAdded:Connect(function(player)
		playerKillStreaks[player] = 0
		activeRewards[player] = {}
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		playerKillStreaks[player] = nil
		activeRewards[player] = nil
	end)
	
	_G.KillStreakManager = self
	print("KillStreakManager initialized")
end

function KillStreakManager:HandleKill(killer)
	if not killer or not killer.Parent then return end
	
	-- Increment kill streak
	playerKillStreaks[killer] = (playerKillStreaks[killer] or 0) + 1
	local currentStreak = playerKillStreaks[killer]
	
	-- Check for kill streak rewards
	if KILLSTREAK_REWARDS[currentStreak] then
		self:AwardKillStreakReward(killer, currentStreak)
	end
	
	-- Announce kill streak milestones
	if currentStreak >= 5 and currentStreak % 5 == 0 then
		self:AnnounceKillStreak(killer, currentStreak)
	end
	
	print(killer.Name .. " is on a " .. currentStreak .. " kill streak")
end

function KillStreakManager:HandleDeath(victim)
	if not victim or not victim.Parent then return end
	
	local previousStreak = playerKillStreaks[victim] or 0
	playerKillStreaks[victim] = 0
	
	-- Clear active rewards
	if activeRewards[victim] then
		for rewardName, _ in pairs(activeRewards[victim]) do
			self:RemoveReward(victim, rewardName)
		end
		activeRewards[victim] = {}
	end
	
	-- Announce streak ended if it was significant
	if previousStreak >= 5 then
		RemoteEventsManager:FireAllClients("KillStreakEnded", {
			Player = victim.Name,
			Streak = previousStreak
		})
		print(victim.Name .. "'s " .. previousStreak .. " kill streak was ended")
	end
end

function KillStreakManager:AwardKillStreakReward(player, streak)
	local reward = KILLSTREAK_REWARDS[streak]
	if not reward then return end
	
	-- Announce reward
	RemoteEventsManager:FireClient(player, "KillStreakReward", {
		Streak = streak,
		RewardName = reward.Name,
		Description = reward.Description
	})
	
	RemoteEventsManager:FireAllClients("KillStreakAchieved", {
		Player = player.Name,
		Streak = streak,
		RewardName = reward.Name
	})
	
	-- Apply reward effect
	if reward.Type == "Personal" then
		self:ApplyPersonalReward(player, reward, streak)
	elseif reward.Type == "Team" then
		self:ApplyTeamReward(player, reward, streak)
	elseif reward.Type == "Global" then
		self:ApplyGlobalReward(player, reward, streak)
	end
	
	print(player.Name .. " earned kill streak reward: " .. reward.Name)
end

function KillStreakManager:ApplyPersonalReward(player, reward, streak)
	if not player.Character then return end
	
	if reward.Name == "Ammo Resupply" then
		-- Refill ammo for all weapons
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") and tool:FindFirstChild("Config") then
				-- Reset ammo via remote event
				RemoteEventsManager:FireClient(player, "AmmoResupply", {WeaponName = tool.Name})
			end
		end
		
	elseif reward.Name == "Damage Boost" then
		-- Apply damage multiplier
		activeRewards[player] = activeRewards[player] or {}
		activeRewards[player]["DamageBoost"] = {
			StartTime = tick(),
			Duration = reward.Duration,
			Multiplier = 1.5
		}
		
		-- Schedule removal
		spawn(function()
			wait(reward.Duration)
			self:RemoveReward(player, "DamageBoost")
		end)
		
	elseif reward.Name == "Invincibility" then
		-- Apply invincibility
		activeRewards[player] = activeRewards[player] or {}
		activeRewards[player]["Invincibility"] = {
			StartTime = tick(),
			Duration = reward.Duration
		}
		
		-- Schedule removal
		spawn(function()
			wait(reward.Duration)
			self:RemoveReward(player, "Invincibility")
		end)
	end
end

function KillStreakManager:ApplyTeamReward(player, reward, streak)
	if not player.Team then return end
	
	local teamPlayers = {}
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer.Team == player.Team then
			table.insert(teamPlayers, otherPlayer)
		end
	end
	
	if reward.Name == "UAV Scan" then
		-- Reveal enemies on radar for team
		for _, teammate in pairs(teamPlayers) do
			RemoteEventsManager:FireClient(teammate, "UAVActive", {Duration = reward.Duration})
		end
		
	elseif reward.Name == "Team Health Boost" then
		-- Restore full health for team
		local healthSystem = _G.HealthSystem
		if healthSystem then
			for _, teammate in pairs(teamPlayers) do
				if teammate.Character and teammate.Character:FindFirstChild("Humanoid") then
					teammate.Character.Humanoid.Health = teammate.Character.Humanoid.MaxHealth
				end
			end
		end
	end
end

function KillStreakManager:ApplyGlobalReward(player, reward, streak)
	if reward.Name == "Nuclear Strike" then
		-- Eliminate all enemy players
		local enemyTeamName = player.Team and player.Team.Name == "FBI" and "KFC" or "FBI"
		
		-- DISABLED: Kill streak team wipe (causing random deaths)
		-- for _, otherPlayer in pairs(Players:GetPlayers()) do
		--     if otherPlayer.Team and otherPlayer.Team.Name == enemyTeamName then
		--         if otherPlayer.Character and otherPlayer.Character:FindFirstChild("Humanoid") then
		--             otherPlayer.Character.Humanoid.Health = 0
		--         end
		--     end
		-- end
		print("Kill streak activated - team wipe temporarily disabled")
		
		-- Dramatic announcement
		RemoteEventsManager:FireAllClients("NuclearStrike", {
			Player = player.Name,
			Team = player.Team.Name
		})
		
		print("NUCLEAR STRIKE by " .. player.Name .. "!")
	end
end

function KillStreakManager:RemoveReward(player, rewardName)
	if activeRewards[player] and activeRewards[player][rewardName] then
		activeRewards[player][rewardName] = nil
		
		RemoteEventsManager:FireClient(player, "RewardExpired", {
			RewardName = rewardName
		})
		
		print("Removed " .. rewardName .. " from " .. player.Name)
	end
end

function KillStreakManager:AnnounceKillStreak(player, streak)
	local announcements = {
		[5] = "is on a killing spree!",
		[10] = "is on a rampage!",
		[15] = "is dominating!",
		[20] = "is unstoppable!",
		[25] = "is godlike!"
	}
	
	local message = announcements[streak] or "is on fire!"
	
	RemoteEventsManager:FireAllClients("KillStreakAnnouncement", {
		Player = player.Name,
		Streak = streak,
		Message = player.Name .. " " .. message .. " (" .. streak .. " kills)"
	})
end

function KillStreakManager:GetPlayerKillStreak(player)
	return playerKillStreaks[player] or 0
end

function KillStreakManager:HasActiveReward(player, rewardName)
	return activeRewards[player] and activeRewards[player][rewardName] ~= nil
end

function KillStreakManager:GetDamageMultiplier(player)
	if self:HasActiveReward(player, "DamageBoost") then
		local reward = activeRewards[player]["DamageBoost"]
		if reward and tick() - reward.StartTime < reward.Duration then
			return reward.Multiplier
		else
			self:RemoveReward(player, "DamageBoost")
		end
	end
	return 1.0
end

function KillStreakManager:IsInvincible(player)
	if self:HasActiveReward(player, "Invincibility") then
		local reward = activeRewards[player]["Invincibility"]
		if reward and tick() - reward.StartTime < reward.Duration then
			return true
		else
			self:RemoveReward(player, "Invincibility")
		end
	end
	return false
end

-- Hook into damage system
local originalDamagePlayer = nil
if _G.HealthSystem then
	originalDamagePlayer = _G.HealthSystem.DamagePlayer
	_G.HealthSystem.DamagePlayer = function(self, player, damage, damageInfo)
		-- Check invincibility
		if KillStreakManager:IsInvincible(player) then
			return false -- No damage taken
		end
		
		-- Apply damage multiplier if attacker has boost
		if damageInfo and damageInfo.Attacker then
			local multiplier = KillStreakManager:GetDamageMultiplier(damageInfo.Attacker)
			damage = damage * multiplier
		end
		
		return originalDamagePlayer(self, player, damage, damageInfo)
	end
end

-- Console commands
_G.KillStreakCommands = {
	setStreak = function(playerName, streak)
		local player = Players:FindFirstChild(playerName)
		if player then
			playerKillStreaks[player] = streak
			print("Set " .. playerName .. " kill streak to " .. streak)
		end
	end,
	
	triggerReward = function(playerName, streak)
		local player = Players:FindFirstChild(playerName)
		if player and KILLSTREAK_REWARDS[streak] then
			KillStreakManager:AwardKillStreakReward(player, streak)
			print("Triggered kill streak reward for " .. playerName)
		end
	end,
	
	listRewards = function()
		print("Available Kill Streak Rewards:")
		for streak, reward in pairs(KILLSTREAK_REWARDS) do
			print(streak .. " kills: " .. reward.Name .. " - " .. reward.Description)
		end
	end
}

KillStreakManager:Initialize()

return KillStreakManager