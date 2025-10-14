local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)
local XPSystem = require(ReplicatedStorage.FPSSystem.Modules.XPSystem)

local HealthSystem = {}

local playerHealth = {}
local playerLastDamageTime = {}
local playerKillStreaks = {}
local recentDamage = {}

local REGENERATION_DELAY = 5
local REGENERATION_RATE = 20
local MAX_HEALTH = 100

function HealthSystem:Initialize()
	RemoteEventsManager:Initialize()
	GameConfig:Initialize()
	XPSystem:Initialize()
	
	local playerDamagedEvent = RemoteEventsManager:GetEvent("PlayerDamaged")
	local playerKilledEvent = RemoteEventsManager:GetEvent("PlayerKilled")
	
	Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerHealth(player)
		
		player.CharacterAdded:Connect(function(character)
			self:SetupCharacterHealth(player, character)
		end)
		
		player.CharacterRemoving:Connect(function(character)
			self:CleanupCharacterHealth(player, character)
		end)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerData(player)
	end)
	
	spawn(function()
		while true do
			wait(0.1)
			self:ProcessHealthRegeneration()
		end
	end)
	
	print("HealthSystem initialized")
end

function HealthSystem:InitializePlayerHealth(player)
	playerHealth[player] = MAX_HEALTH
	playerLastDamageTime[player] = 0
	playerKillStreaks[player] = 0
	recentDamage[player] = {}
end

function HealthSystem:CleanupPlayerData(player)
	playerHealth[player] = nil
	playerLastDamageTime[player] = nil
	playerKillStreaks[player] = nil
	recentDamage[player] = nil
end

function HealthSystem:SetupCharacterHealth(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	
	humanoid.MaxHealth = MAX_HEALTH
	humanoid.Health = MAX_HEALTH
	playerHealth[player] = MAX_HEALTH
	
	humanoid.Died:Connect(function()
		self:HandlePlayerDeath(player, character)
	end)
	
	humanoid.HealthChanged:Connect(function(health)
		if health <= 0 and humanoid.Health > 0 then
			self:HandlePlayerDeath(player, character)
		end
	end)
end

function HealthSystem:CleanupCharacterHealth(player, character)
	
end

function HealthSystem:DamagePlayer(player, damage, damageInfo)
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then
		return false
	end
	
	local humanoid = player.Character.Humanoid
	if humanoid.Health <= 0 then
		return false
	end
	
	local actualDamage = math.min(damage, humanoid.Health)
	humanoid.Health = humanoid.Health - actualDamage
	playerHealth[player] = humanoid.Health
	playerLastDamageTime[player] = tick()
	
	if damageInfo.Attacker and damageInfo.Attacker ~= player then
		self:TrackDamage(player, damageInfo.Attacker, actualDamage, damageInfo)
	end
	
	RemoteEventsManager:FireClient(player, "PlayerDamaged", {
		Damage = actualDamage,
		Health = humanoid.Health,
		MaxHealth = humanoid.MaxHealth,
		DamageType = damageInfo.DamageType or "Unknown",
		Attacker = damageInfo.Attacker and damageInfo.Attacker.Name or "Unknown"
	})
	
	if humanoid.Health <= 0 then
		self:HandlePlayerDeath(player, player.Character, damageInfo)
	end
	
	return true
end

function HealthSystem:TrackDamage(victim, attacker, damage, damageInfo)
	if not recentDamage[victim] then
		recentDamage[victim] = {}
	end
	
	local damageRecord = {
		Attacker = attacker,
		Damage = damage,
		Time = tick(),
		DamageInfo = damageInfo
	}
	
	table.insert(recentDamage[victim], damageRecord)
	
	spawn(function()
		wait(10)
		for i, record in pairs(recentDamage[victim]) do
			if record == damageRecord then
				table.remove(recentDamage[victim], i)
				break
			end
		end
	end)
end

function HealthSystem:HandlePlayerDeath(player, character, damageInfo)
	local killer = nil
	local assisters = {}
	
	if recentDamage[player] then
		local totalDamageByPlayer = {}
		
		for _, record in pairs(recentDamage[player]) do
			if tick() - record.Time <= 5 then
				totalDamageByPlayer[record.Attacker] = (totalDamageByPlayer[record.Attacker] or 0) + record.Damage
			end
		end
		
		local maxDamage = 0
		for attacker, damage in pairs(totalDamageByPlayer) do
			if damage > maxDamage and attacker ~= player then
				maxDamage = damage
				killer = attacker
			end
		end
		
		for attacker, damage in pairs(totalDamageByPlayer) do
			if attacker ~= killer and attacker ~= player and damage >= 25 then
				table.insert(assisters, attacker)
			end
		end
	end
	
	if damageInfo and damageInfo.Attacker and damageInfo.Attacker ~= player then
		killer = damageInfo.Attacker
	end
	
	self:ProcessKill(player, killer, assisters, damageInfo)
	
	recentDamage[player] = {}
	playerKillStreaks[player] = 0
	
	local dataStoreManager = _G.DataStoreManager
	if dataStoreManager then
		dataStoreManager:UpdateMatchStat(player, "Deaths", 1, true)
		dataStoreManager:UpdatePlayerStat(player, "TotalDeaths", 1, true)
	end
end

function HealthSystem:ProcessKill(victim, killer, assisters, damageInfo)
	if not killer then return end
	
	playerKillStreaks[killer] = (playerKillStreaks[killer] or 0) + 1
	
	local killData = {
		Victim = victim,
		Killer = killer,
		Assisters = assisters,
		KillStreak = playerKillStreaks[killer],
		IsHeadshot = damageInfo and damageInfo.IsHeadshot or false,
		Distance = damageInfo and damageInfo.Distance or 0,
		WeaponName = damageInfo and damageInfo.WeaponName or "Unknown",
		IsWallbang = damageInfo and damageInfo.IsWallbang or false,
		IsBackstab = damageInfo and damageInfo.IsBackstab or false,
		Timestamp = tick()
	}
	
	local dataStoreManager = _G.DataStoreManager
	if dataStoreManager then
		dataStoreManager:UpdateMatchStat(killer, "Kills", 1, true)
		dataStoreManager:UpdatePlayerStat(killer, "TotalKills", 1, true)
		
		local currentStreak = dataStoreManager:GetPlayerData(killer).MatchStats.KillStreak or 0
		dataStoreManager:UpdateMatchStat(killer, "KillStreak", playerKillStreaks[killer])
		
		if playerKillStreaks[killer] > (dataStoreManager:GetPlayerData(killer).MatchStats.BestStreak or 0) then
			dataStoreManager:UpdateMatchStat(killer, "BestStreak", playerKillStreaks[killer])
		end
		
		local xpGained, xpDetails = XPSystem:CalculateKillXP(killData)
		dataStoreManager:AddXP(killer, xpGained, "Kill (" .. table.concat(xpDetails.Reasons, ", ") .. ")")
		
		for _, assister in pairs(assisters) do
			local assistXP = XPSystem:GetAssistXP()
			dataStoreManager:AddXP(assister, assistXP, "Assist")
			dataStoreManager:UpdateMatchStat(assister, "Assists", 1, true)
		end
	end
	
	RemoteEventsManager:FireAllClients("PlayerKilled", {
		Victim = victim.Name,
		Killer = killer.Name,
		Assisters = self:GetPlayerNames(assisters),
		KillStreak = playerKillStreaks[killer],
		IsHeadshot = killData.IsHeadshot,
		WeaponName = killData.WeaponName,
		Distance = killData.Distance
	})
	
	print(killer.Name .. " killed " .. victim.Name .. " (Streak: " .. playerKillStreaks[killer] .. ")")
end

function HealthSystem:GetPlayerNames(players)
	local names = {}
	for _, player in pairs(players) do
		table.insert(names, player.Name)
	end
	return names
end

function HealthSystem:ProcessHealthRegeneration()
	local currentTime = tick()
	
	for player, lastDamageTime in pairs(playerLastDamageTime) do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			
			if humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
				if currentTime - lastDamageTime >= REGENERATION_DELAY then
					local newHealth = math.min(humanoid.Health + (REGENERATION_RATE * 0.1), humanoid.MaxHealth)
					humanoid.Health = newHealth
					playerHealth[player] = newHealth
				end
			end
		end
	end
end

function HealthSystem:GetPlayerHealth(player)
	return playerHealth[player] or 0
end

function HealthSystem:SetPlayerHealth(player, health)
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then
		return false
	end
	
	local humanoid = player.Character.Humanoid
	humanoid.Health = math.clamp(health, 0, humanoid.MaxHealth)
	playerHealth[player] = humanoid.Health
	
	return true
end

function HealthSystem:HealPlayer(player, healAmount)
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then
		return false
	end
	
	local humanoid = player.Character.Humanoid
	local newHealth = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
	humanoid.Health = newHealth
	playerHealth[player] = newHealth
	
	return true
end

function HealthSystem:GetPlayerKillStreak(player)
	return playerKillStreaks[player] or 0
end

function HealthSystem:ResetPlayerKillStreak(player)
	playerKillStreaks[player] = 0
end

HealthSystem:Initialize()

_G.HealthSystem = HealthSystem

return HealthSystem