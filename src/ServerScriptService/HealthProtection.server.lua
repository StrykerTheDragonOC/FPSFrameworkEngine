-- TEMPORARY: Health Protection System to prevent random deaths
-- This script prevents unexpected health drops

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PROTECTED_HEALTH = 100
local protectedPlayers = {}

-- Add protection when player spawns
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Set initial health
		humanoid.MaxHealth = PROTECTED_HEALTH
		humanoid.Health = PROTECTED_HEALTH
		
		-- Mark as protected
		protectedPlayers[player] = true
		
		print("Health protection enabled for " .. player.Name)
		
		-- Monitor health changes
		humanoid.HealthChanged:Connect(function(health)
			if protectedPlayers[player] and health < PROTECTED_HEALTH * 0.9 then
				-- Only allow health to drop to 90% minimum (for testing)
				print("Prevented excessive health drop for " .. player.Name .. " (Health was: " .. health .. ")")
				humanoid.Health = math.max(health, PROTECTED_HEALTH * 0.9)
			end
		end)
		
		-- Remove protection when player dies naturally
		humanoid.Died:Connect(function()
			print(player.Name .. " died naturally, removing protection")
			protectedPlayers[player] = nil
		end)
	end)
end)

-- Remove protection when player leaves
Players.PlayerRemoving:Connect(function(player)
	protectedPlayers[player] = nil
end)

-- Console command to toggle protection
_G.HealthProtection = {
	enable = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player then
			protectedPlayers[player] = true
			print("Enabled health protection for " .. playerName)
		end
	end,
	
	disable = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player then
			protectedPlayers[player] = nil
			print("Disabled health protection for " .. playerName)
		end
	end,
	
	status = function()
		print("Protected players:")
		for player, _ in pairs(protectedPlayers) do
			print("- " .. player.Name)
		end
	end
}

print("Health Protection System initialized")