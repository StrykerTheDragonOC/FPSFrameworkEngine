local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local MeleeSystem = require(ReplicatedStorage.FPSSystem.Modules.MeleeSystem)
local DamageSystem = require(ReplicatedStorage.FPSSystem.Modules.DamageSystem)

local MeleeHandler = {}

function MeleeHandler:Initialize()
	RemoteEventsManager:Initialize()
	DamageSystem:Initialize()
	
	-- Handle melee attacks
	local meleeAttackEvent = RemoteEventsManager:GetEvent("MeleeAttack")
	if meleeAttackEvent then
		meleeAttackEvent.OnServerEvent:Connect(function(player, attackData)
			self:HandleMeleeAttack(player, attackData)
		end)
	end
	
	_G.MeleeHandler = self
	print("MeleeHandler initialized")
end

function MeleeHandler:HandleMeleeAttack(attacker, attackData)
	local target = attackData.Target
	local weaponName = attackData.WeaponName
	local isSpecialAttack = attackData.IsSpecialAttack
	local isBackstab = attackData.IsBackstab
	
	-- Validate attack
	if not target or not target.Character or not target.Character:FindFirstChild("Humanoid") then
		return
	end
	
	if not attacker.Character or not attacker.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	-- Get weapon config
	local config = MeleeSystem:GetMeleeConfig(weaponName)
	if not config then
		warn("Invalid melee weapon: " .. weaponName)
		return
	end
	
	-- Validate distance
	local attackerPos = attacker.Character.HumanoidRootPart.Position
	local targetPos = target.Character.HumanoidRootPart.Position
	local distance = (attackerPos - targetPos).Magnitude
	
	if distance > config.Range + 2 then -- Add slight tolerance
		warn("Melee attack out of range: " .. distance .. " > " .. config.Range)
		return
	end
	
	-- Calculate damage
	local baseDamage = config.Damage
	
	if isBackstab and config.CanBackstab then
		baseDamage = config.BackstabDamage
	end
	
	if isSpecialAttack and config.SpecialAttackMultiplier then
		baseDamage = baseDamage * config.SpecialAttackMultiplier
	end
	
	-- Apply damage
	local damageInfo = {
		Attacker = attacker,
		DamageType = "Melee",
		WeaponName = weaponName,
		IsBackstab = isBackstab,
		IsSpecialAttack = isSpecialAttack,
		Position = attackData.HitPosition
	}
	
	local success = false
	if DamageSystem and DamageSystem.DamagePlayer then
		success = DamageSystem:DamagePlayer(target, baseDamage, damageInfo)
	end
	
	if success then
		-- Notify clients of hit effect
		RemoteEventsManager:FireAllClients("MeleeHit", {
			Attacker = attacker.Name,
			Target = target.Name,
			Damage = baseDamage,
			WeaponName = weaponName,
			IsBackstab = isBackstab,
			IsSpecialAttack = isSpecialAttack,
			HitPosition = attackData.HitPosition,
			HitNormal = attackData.HitNormal
		})
		
		-- Award XP for melee kills
		if target.Character.Humanoid.Health <= 0 then
			local xpAmount = isBackstab and 150 or 100
			if isSpecialAttack then xpAmount = xpAmount + 25 end
			
			local dataStoreManager = _G.DataStoreManager
			if dataStoreManager then
				local reason = "Melee Kill"
				if isBackstab then reason = "Backstab Kill" end
				if isSpecialAttack then reason = reason .. " (Special)" end
				
				dataStoreManager:AddXP(attacker, xpAmount, reason)
			end
		end
		
		print(attacker.Name .. " hit " .. target.Name .. " with " .. weaponName .. " for " .. baseDamage .. " damage")
	end
end

-- Console commands
_G.MeleeCommands = {
	giveMeleeWeapons = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player and player.Character then
			local meleeWeapons = {
				"PocketKnife", "CombatKnife", "Hammer", "Baton",
				"FireAxe", "Katana", "Sledgehammer", "BaseballBat"
			}
			
			for _, weaponName in pairs(meleeWeapons) do
				local tool = Instance.new("Tool")
				tool.Name = weaponName
				tool.RequiresHandle = false
				tool.Parent = player.Backpack
				
				-- Add basic handle for visualization
				local handle = Instance.new("Part")
				handle.Name = "Handle"
				handle.Size = Vector3.new(0.2, 3, 0.2)
				handle.Material = Enum.Material.Metal
				handle.BrickColor = BrickColor.new("Dark stone grey")
				handle.Parent = tool
				
				-- Connect to melee system
				tool.Equipped:Connect(function()
					local meleeSystem = require(ReplicatedStorage.FPSSystem.Modules.MeleeSystem)
					meleeSystem:OnMeleeEquipped(tool)
				end)
				
				tool.Unequipped:Connect(function()
					local meleeSystem = require(ReplicatedStorage.FPSSystem.Modules.MeleeSystem)
					meleeSystem:OnMeleeUnequipped(tool)
				end)
			end
			
			print("Gave all melee weapons to " .. playerName)
		end
	end,
	
	testBackstab = function(attackerName, targetName)
		local attacker = Players:FindFirstChild(attackerName)
		local target = Players:FindFirstChild(targetName)
		
		if attacker and target and attacker.Character and target.Character then
			-- Simulate backstab
			MeleeHandler:HandleMeleeAttack(attacker, {
				Target = target,
				WeaponName = "PocketKnife",
				IsSpecialAttack = false,
				IsBackstab = true,
				HitPosition = target.Character.HumanoidRootPart.Position,
				HitNormal = Vector3.new(0, 1, 0),
				Distance = 3
			})
			
			print("Simulated backstab: " .. attackerName .. " -> " .. targetName)
		end
	end
}

MeleeHandler:Initialize()

return MeleeHandler