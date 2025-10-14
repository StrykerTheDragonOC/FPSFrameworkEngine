--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

local ClassHandler = {}

-- Player class data on server
local playerClassData = {}

-- Class unlock requirements
local CLASS_UNLOCK_LEVELS = {
	Assault = 0,
	Scout = 5,
	Support = 8,
	Recon = 12
}

-- Class configurations (server-side mirror)
local CLASS_CONFIGS = {
	Assault = {
		Name = "Assault",
		HealthMultiplier = 1.0,
		SpeedMultiplier = 1.0,
		StartingArmor = 25,
		Abilities = {
			{Name = "Tactical Sprint", Cooldown = 45, Duration = 8},
			{Name = "Combat Stim", Cooldown = 90, Duration = 15}
		}
	},
	Scout = {
		Name = "Scout",
		HealthMultiplier = 0.85,
		SpeedMultiplier = 1.15,
		StartingArmor = 15,
		Abilities = {
			{Name = "Cloak", Cooldown = 120, Duration = 12},
			{Name = "Eagle Eye", Cooldown = 60, Duration = 20}
		}
	},
	Support = {
		Name = "Support",
		HealthMultiplier = 1.2,
		SpeedMultiplier = 0.9,
		StartingArmor = 35,
		Abilities = {
			{Name = "Med Pack", Cooldown = 30, Duration = 0},
			{Name = "Ammo Crate", Cooldown = 60, Duration = 45}
		}
	},
	Recon = {
		Name = "Recon",
		HealthMultiplier = 0.9,
		SpeedMultiplier = 1.05,
		StartingArmor = 20,
		Abilities = {
			{Name = "UAV Scan", Cooldown = 90, Duration = 15},
			{Name = "EMP Pulse", Cooldown = 120, Duration = 8}
		}
	}
}

function ClassHandler:Initialize()
	DataStoreManager:Initialize()

	-- Handle class selection from clients
	local selectClassEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SelectClass")
	if selectClassEvent then
		selectClassEvent.OnServerEvent:Connect(function(player, classData)
			self:HandleClassSelection(player, classData)
		end)
	end

	-- Handle ability usage from clients
	local useAbilityEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("UseAbility")
	if useAbilityEvent then
		useAbilityEvent.OnServerEvent:Connect(function(player, abilityData)
			self:HandleAbilityUsage(player, abilityData)
		end)
	end
	
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerClass(player)
	end)
	
	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerClass(player)
		playerClassData[player] = nil
	end)
	
	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		self:InitializePlayerClass(player)
	end
	
	-- Start ability management
	self:StartAbilityManagement()
	
	-- Periodic save
	spawn(function()
		while true do
			wait(300) -- Save every 5 minutes
			for _, player in pairs(Players:GetPlayers()) do
				self:SavePlayerClass(player)
			end
		end
	end)
	
	_G.ClassHandler = self
	print("ClassHandler initialized")
end

function ClassHandler:InitializePlayerClass(player)
	-- Initialize default class data
	playerClassData[player] = {
		CurrentClass = "Assault",
		UnlockedClasses = {"Assault"},
		AbilityCooldowns = {},
		ActiveEffects = {},
		ClassStats = {}
	}
	
	-- Load saved data
	self:LoadPlayerClass(player)
	
	-- Check for newly unlocked classes
	self:CheckClassUnlocks(player)
	
	-- Apply class modifiers
	self:ApplyClassModifiers(player)
	
	-- Send initial class data to client
	wait(2) -- Give client time to initialize
	self:SyncClassWithClient(player)
end

function ClassHandler:LoadPlayerClass(player)
	if not DataStoreManager then return end
	
	local savedClassData = DataStoreManager:GetPlayerData(player, "ClassData")
	if savedClassData then
		-- Merge saved data with defaults
		for key, value in pairs(savedClassData) do
			if playerClassData[player][key] ~= nil then
				playerClassData[player][key] = value
			end
		end
	end
end

function ClassHandler:SavePlayerClass(player)
	if not DataStoreManager or not playerClassData[player] then return end
	
	-- Save class data to DataStore
	DataStoreManager:SetPlayerData(player, "ClassData", playerClassData[player])
end

function ClassHandler:HandleClassSelection(player, classData)
	local playerData = playerClassData[player]
	if not playerData then return end
	
	local className = classData.ClassName
	
	-- Validate class is unlocked
	if not table.find(playerData.UnlockedClasses, className) then
		print("Player " .. player.Name .. " tried to select locked class: " .. className)
		return
	end
	
	-- Update current class
	playerData.CurrentClass = className
	playerData.ActiveEffects = {} -- Clear active effects
	
	-- Reset ability cooldowns
	self:ResetAbilityCooldowns(player)
	
	-- Apply class modifiers
	self:ApplyClassModifiers(player)
	
	-- Sync with client
	self:SyncClassWithClient(player)
	
	print("Player " .. player.Name .. " selected class: " .. className)
end

function ClassHandler:HandleAbilityUsage(player, abilityData)
	local playerData = playerClassData[player]
	if not playerData then return end
	
	local abilityName = abilityData.AbilityName
	local className = abilityData.ClassName
	
	-- Validate player is using correct class
	if playerData.CurrentClass ~= className then
		return
	end
	
	-- Validate ability exists for this class
	local classConfig = CLASS_CONFIGS[className]
	if not classConfig or not classConfig.Abilities then return end
	
	local ability = nil
	for _, abilityConfig in pairs(classConfig.Abilities) do
		if abilityConfig.Name == abilityName then
			ability = abilityConfig
			break
		end
	end
	
	if not ability then return end
	
	-- Check cooldown (server-side validation)
	local cooldownRemaining = playerData.AbilityCooldowns[abilityName] or 0
	if cooldownRemaining > 0 then
		print("Player " .. player.Name .. " tried to use ability on cooldown: " .. abilityName)
		return
	end
	
	-- Execute ability
	self:ExecuteAbility(player, ability)
	
	-- Set cooldown
	playerData.AbilityCooldowns[abilityName] = ability.Cooldown
	
	print("Player " .. player.Name .. " used ability: " .. abilityName)
end

function ClassHandler:ExecuteAbility(player, ability)
	local playerData = playerClassData[player]
	if not playerData then return end
	
	-- Apply ability effects
	if ability.Duration > 0 then
		-- Temporary effect
		playerData.ActiveEffects[ability.Name] = {
			TimeRemaining = ability.Duration,
			StartTime = tick()
		}
		
		-- Apply temporary modifiers
		self:ApplyAbilityEffects(player, ability)
		
	else
		-- Instant effect
		self:ApplyInstantAbility(player, ability)
	end
end

function ClassHandler:ApplyInstantAbility(player, ability)
	local character = player.Character
	if not character then return end
	
	if ability.Name == "Med Pack" then
		-- Heal player and nearby teammates
		local humanoid = character:FindFirstChild("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart then
			-- Heal self
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 75)
			
			-- Heal nearby teammates
			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Team == player.Team then
					local otherCharacter = otherPlayer.Character
					if otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart") then
						local distance = (rootPart.Position - otherCharacter.HumanoidRootPart.Position).Magnitude
						if distance <= 8 then -- Heal radius
							local otherHumanoid = otherCharacter:FindFirstChild("Humanoid")
							if otherHumanoid then
								otherHumanoid.Health = math.min(otherHumanoid.MaxHealth, otherHumanoid.Health + 50)

								-- Notify client of heal effect
								local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
								if abilityEffectEvent then
									abilityEffectEvent:FireClient(otherPlayer, {
										EffectType = "Heal",
										Amount = 50
									})
								end
							end
					end
				end
			end
		end
	end

	elseif ability.Name == "Ammo Crate" then
		-- Create ammo resupply crate
		self:CreateAmmoCrate(player)

	elseif ability.Name == "UAV Scan" then
		-- Reveal enemies to team
		self:PerformUAVScan(player)

	elseif ability.Name == "EMP Pulse" then
		-- Disable enemy equipment
		self:PerformEMPPulse(player)
	end
end

function ClassHandler:CreateAmmoCrate(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local rootPart = character.HumanoidRootPart
	local cratePosition = rootPart.Position + rootPart.CFrame.LookVector * 3
	
	-- Create ammo crate
	local ammoCrate = Instance.new("Part")
	ammoCrate.Name = "AmmoCrate"
	ammoCrate.Size = Vector3.new(2, 1, 2)
	ammoCrate.Material = Enum.Material.Metal
	ammoCrate.Color = Color3.new(0.3, 0.3, 0.3)
	ammoCrate.Anchored = true
	ammoCrate.CanCollide = true
	ammoCrate.Position = cratePosition
	ammoCrate.Parent = workspace
	
	-- Add identifying attributes
	ammoCrate:SetAttribute("AmmoCrate", true)
	ammoCrate:SetAttribute("Owner", player.Name)
	ammoCrate:SetAttribute("Team", player.Team and player.Team.Name or "None")
	ammoCrate:SetAttribute("Duration", 45)
	ammoCrate:SetAttribute("SpawnTime", tick())
	
	-- Visual effects
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.new(0, 0.5, 1)
	pointLight.Brightness = 1
	pointLight.Range = 10
	pointLight.Parent = ammoCrate
	
	-- Resupply functionality
	spawn(function()
		local startTime = tick()
		while ammoCrate.Parent and tick() - startTime < 45 do
			wait(1)
			
			-- Check for nearby teammates
			for _, teammate in pairs(Players:GetPlayers()) do
				if teammate.Team == player.Team then
					local teammateCharacter = teammate.Character
					if teammateCharacter and teammateCharacter:FindFirstChild("HumanoidRootPart") then
						local distance = (ammoCrate.Position - teammateCharacter.HumanoidRootPart.Position).Magnitude
						if distance <= 6 then
							-- Resupply ammo
							local ammoHandler = _G.AmmoHandler
							if ammoHandler then
								-- Give some ammo for each caliber
								ammoHandler:GiveAmmo(teammate, "556", "Standard", 30)
								ammoHandler:GiveAmmo(teammate, "9mm", "Standard", 15)
								ammoHandler:GiveAmmo(teammate, "762", "Standard", 20)

								-- Visual feedback
								local ammoResupplyEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
								if ammoResupplyEvent then
									ammoResupplyEvent:FireClient(teammate, {
										EffectType = "AmmoResupply"
									})
								end
							end
						end
					end
				end
			end
		end
		
		-- Remove crate after duration
		if ammoCrate.Parent then
			ammoCrate:Destroy()
		end
	end)
	
	print("Ammo crate deployed by " .. player.Name)
end

function ClassHandler:PerformUAVScan(player)
	if not player.Team then return end
	
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local scanCenter = character.HumanoidRootPart.Position
	local scanRadius = 100
	
	-- Find all enemies within scan radius
	local scannedEnemies = {}
	for _, enemy in pairs(Players:GetPlayers()) do
		if enemy.Team ~= player.Team then
			local enemyCharacter = enemy.Character
			if enemyCharacter and enemyCharacter:FindFirstChild("HumanoidRootPart") then
				local distance = (scanCenter - enemyCharacter.HumanoidRootPart.Position).Magnitude
				if distance <= scanRadius then
					table.insert(scannedEnemies, enemy)
				end
			end
		end
	end
	
	-- Share scan results with team
	local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
	if abilityEffectEvent then
		for _, teammate in pairs(Players:GetPlayers()) do
			if teammate.Team == player.Team then
				abilityEffectEvent:FireClient(teammate, {
					EffectType = "UAVScan",
					ScannedEnemies = scannedEnemies,
					Duration = 15
				})
			end
		end
	end
	
	print("UAV scan performed by " .. player.Name .. " - " .. #scannedEnemies .. " enemies revealed")
end

function ClassHandler:PerformEMPPulse(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local empCenter = character.HumanoidRootPart.Position
	local empRadius = 15
	
	-- Affect all enemies within EMP radius
	local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
	if abilityEffectEvent then
		for _, enemy in pairs(Players:GetPlayers()) do
			if enemy.Team ~= player.Team then
				local enemyCharacter = enemy.Character
				if enemyCharacter and enemyCharacter:FindFirstChild("HumanoidRootPart") then
					local distance = (empCenter - enemyCharacter.HumanoidRootPart.Position).Magnitude
					if distance <= empRadius then
						-- Apply EMP effects
						abilityEffectEvent:FireClient(enemy, {
							EffectType = "EMP",
							Duration = 8
						})
					end
				end
			end
		end
	end
	
	print("EMP pulse performed by " .. player.Name)
end

function ClassHandler:ApplyAbilityEffects(player, ability)
	-- Apply temporary ability effects
	local playerData = playerClassData[player]
	if not playerData then return end
	
	-- Store original stats if not already stored
	if not playerData.ClassStats.OriginalStats then
		playerData.ClassStats.OriginalStats = self:GetPlayerBaseStats(player)
	end
	
	-- Apply ability-specific effects
	if ability.Name == "Tactical Sprint" then
		self:ApplySpeedMultiplier(player, 1.4)
		
	elseif ability.Name == "Combat Stim" then
		self:ApplyDamageResistance(player, 0.15)
		
	elseif ability.Name == "Cloak" then
		self:ApplyCloakEffect(player)
		
	elseif ability.Name == "Eagle Eye" then
		self:ApplyEagleEyeEffect(player)
	end
end

function ClassHandler:ApplySpeedMultiplier(player, multiplier)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return end
	
	local humanoid = character.Humanoid
	local baseWalkSpeed = humanoid.WalkSpeed / (playerClassData[player].ClassStats.CurrentSpeedMultiplier or 1)
	
	humanoid.WalkSpeed = baseWalkSpeed * multiplier
	playerClassData[player].ClassStats.CurrentSpeedMultiplier = multiplier

	-- Notify client
	local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
	if abilityEffectEvent then
		abilityEffectEvent:FireClient(player, {
			EffectType = "SpeedBoost",
			Multiplier = multiplier
		})
	end
end

function ClassHandler:ApplyDamageResistance(player, resistance)
	playerClassData[player].ClassStats.DamageResistance = resistance

	-- Notify client
	local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
	if abilityEffectEvent then
		abilityEffectEvent:FireClient(player, {
			EffectType = "DamageResistance",
			Resistance = resistance
		})
	end
end

function ClassHandler:ApplyCloakEffect(player)
	local character = player.Character
	if not character then return end
	
	-- Make player semi-transparent
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 0.8
		end
	end

	-- Notify client
	local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
	if abilityEffectEvent then
		abilityEffectEvent:FireClient(player, {
			EffectType = "Cloak",
			Duration = 12
		})
	end
end

function ClassHandler:ApplyEagleEyeEffect(player)
	-- Notify client to apply eagle eye effects
	local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
	if abilityEffectEvent then
		abilityEffectEvent:FireClient(player, {
			EffectType = "EagleEye",
			Duration = 20
		})
	end
end

function ClassHandler:GetPlayerBaseStats(player)
	local character = player.Character
	if not character then return {} end
	
	local humanoid = character:FindFirstChild("Humanoid")
	return {
		WalkSpeed = humanoid and humanoid.WalkSpeed or 16,
		MaxHealth = humanoid and humanoid.MaxHealth or 100
	}
end

function ClassHandler:StartAbilityManagement()
	spawn(function()
		while true do
			wait(1)
			self:UpdateAbilities()
		end
	end)
end

function ClassHandler:UpdateAbilities()
	for player, data in pairs(playerClassData) do
		if player.Parent then -- Player still in game
			-- Update cooldowns
			for abilityName, cooldown in pairs(data.AbilityCooldowns) do
				if cooldown > 0 then
					data.AbilityCooldowns[abilityName] = math.max(0, cooldown - 1)
				end
			end
			
			-- Update active effects
			for effectName, effectData in pairs(data.ActiveEffects) do
				effectData.TimeRemaining = effectData.TimeRemaining - 1
				
				if effectData.TimeRemaining <= 0 then
					-- Effect expired
					self:RemoveAbilityEffect(player, effectName)
					data.ActiveEffects[effectName] = nil
				end
			end
		end
	end
end

function ClassHandler:RemoveAbilityEffect(player, effectName)
	local playerData = playerClassData[player]
	if not playerData then return end
	
	-- Restore original stats
	if effectName == "Tactical Sprint" then
		self:RestoreSpeed(player)
		
	elseif effectName == "Combat Stim" then
		playerData.ClassStats.DamageResistance = 0
		
	elseif effectName == "Cloak" then
		self:RemoveCloakEffect(player)
		
	elseif effectName == "Eagle Eye" then
		-- Eagle eye effects handled client-side
		print("Removed Eagle Eye effect from " .. player.Name)
	end
	
	-- Notify client
	local abilityEffectEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AbilityEffect")
	if abilityEffectEvent then
		abilityEffectEvent:FireClient(player, {
			EffectType = "Remove",
			EffectName = effectName
		})
	end
end

function ClassHandler:RestoreSpeed(player)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return end
	
	local classConfig = CLASS_CONFIGS[playerClassData[player].CurrentClass]
	local baseSpeed = 16 * (classConfig and classConfig.SpeedMultiplier or 1)
	
	character.Humanoid.WalkSpeed = baseSpeed
	playerClassData[player].ClassStats.CurrentSpeedMultiplier = classConfig.SpeedMultiplier or 1
end

function ClassHandler:RemoveCloakEffect(player)
	local character = player.Character
	if not character then return end
	
	-- Restore transparency
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 0
		end
	end
end

function ClassHandler:CheckClassUnlocks(player)
	if not DataStoreManager then return end
	
	local playerLevel = DataStoreManager:GetPlayerData(player, "Level") or 1
	local playerData = playerClassData[player]
	if not playerData then return end
	
	-- Check each class unlock level
	for className, unlockLevel in pairs(CLASS_UNLOCK_LEVELS) do
		if playerLevel >= unlockLevel and not table.find(playerData.UnlockedClasses, className) then
			-- Unlock this class
			table.insert(playerData.UnlockedClasses, className)

			-- Notify client
			local classUnlockEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ClassUpdate")
			if classUnlockEvent then
				classUnlockEvent:FireClient(player, {
					ClassName = className,
					UnlockLevel = unlockLevel
				})
			end

			print("Player " .. player.Name .. " unlocked class: " .. className)
		end
	end
end

function ClassHandler:ApplyClassModifiers(player)
	local playerData = playerClassData[player]
	if not playerData then return end
	
	local classConfig = CLASS_CONFIGS[playerData.CurrentClass]
	if not classConfig then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		-- Apply health modifier
		local newMaxHealth = 100 * classConfig.HealthMultiplier
		humanoid.MaxHealth = newMaxHealth
		humanoid.Health = newMaxHealth
		
		-- Apply speed modifier
		humanoid.WalkSpeed = 16 * classConfig.SpeedMultiplier
		
		playerData.ClassStats.CurrentSpeedMultiplier = classConfig.SpeedMultiplier
	end
	
	-- Apply armor (would integrate with armor system)
	local dataStore = DataStoreManager
	if dataStore then
		dataStore:SetPlayerData(player, "Armor", classConfig.StartingArmor)
	end
end

function ClassHandler:ResetAbilityCooldowns(player)
	local playerData = playerClassData[player]
	if not playerData then return end
	
	local classConfig = CLASS_CONFIGS[playerData.CurrentClass]
	if not classConfig or not classConfig.Abilities then return end
	
	playerData.AbilityCooldowns = {}
	for _, ability in pairs(classConfig.Abilities) do
		playerData.AbilityCooldowns[ability.Name] = 0
	end
end

function ClassHandler:SyncClassWithClient(player)
	local playerData = playerClassData[player]
	if not playerData then return end

	local classUpdateEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ClassUpdate")
	if classUpdateEvent then
		classUpdateEvent:FireClient(player, {
			CurrentClass = playerData.CurrentClass,
			UnlockedClasses = playerData.UnlockedClasses,
			AbilityCooldowns = playerData.AbilityCooldowns,
			ActiveEffects = playerData.ActiveEffects
		})
	end
end

function ClassHandler:GetPlayerClass(player)
	local playerData = playerClassData[player]
	return playerData and playerData.CurrentClass or "Assault"
end

function ClassHandler:IsClassUnlocked(player, className)
	local playerData = playerClassData[player]
	if not playerData then return false end
	
	return table.find(playerData.UnlockedClasses, className) ~= nil
end

-- Admin commands for testing
_G.AdminClassCommands = {
	setPlayerClass = function(playerName, className)
		local targetPlayer = Players:FindFirstChild(playerName)
		if targetPlayer and CLASS_CONFIGS[className] then
			ClassHandler:HandleClassSelection(targetPlayer, {ClassName = className})
		else
			print("Player not found or invalid class: " .. playerName .. ", " .. className)
		end
	end,
	
	unlockPlayerClass = function(playerName, className)
		local targetPlayer = Players:FindFirstChild(playerName)
		if targetPlayer and CLASS_CONFIGS[className] then
			local playerData = playerClassData[targetPlayer]
			if playerData then
				table.insert(playerData.UnlockedClasses, className)
				ClassHandler:SyncClassWithClient(targetPlayer)
				print("Unlocked " .. className .. " for " .. playerName)
			end
		end
	end,
	
	checkPlayerClass = function(playerName)
		local targetPlayer = Players:FindFirstChild(playerName)
		if targetPlayer then
			local playerData = playerClassData[targetPlayer]
			if playerData then
				print("Class data for " .. playerName .. ":")
				print("Current: " .. playerData.CurrentClass)
				print("Unlocked: " .. table.concat(playerData.UnlockedClasses, ", "))
			end
		end
	end,
	
	unlockAllClasses = function()
		for player, data in pairs(playerClassData) do
			data.UnlockedClasses = {"Assault", "Scout", "Support", "Recon"}
			ClassHandler:SyncClassWithClient(player)
		end
		print("Unlocked all classes for all players")
	end
}

ClassHandler:Initialize()

return ClassHandler