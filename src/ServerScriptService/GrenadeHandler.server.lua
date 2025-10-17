local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local GrenadeSystem = require(ReplicatedStorage.FPSSystem.Modules.GrenadeSystem)
local DamageSystem = require(ReplicatedStorage.FPSSystem.Modules.DamageSystem)

local GrenadeHandler = {}

local activeGrenades = {}
local placedC4s = {}

function GrenadeHandler:Initialize()
	DamageSystem:Initialize()
	
	-- Handle grenade throws
	local throwGrenadeEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ThrowGrenade")
	if throwGrenadeEvent then
		throwGrenadeEvent.OnServerEvent:Connect(function(player, grenadeData)
			-- Server-side validation: rate limit grenade throws per player
			if not player then return end
			player._lastGrenadeThrow = player._lastGrenadeThrow or 0
			if tick() - player._lastGrenadeThrow < 0.5 then
				-- Too fast; ignore
				return
			end
			player._lastGrenadeThrow = tick()
			self:HandleGrenadeThrow(player, grenadeData)
		end)
	end
	
	-- Handle C4 detonation
	local detonateC4Event = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("DetonateC4")
	if detonateC4Event then
		detonateC4Event.OnServerEvent:Connect(function(player)
			self:DetonatePlayerC4(player)
		end)
	end
	
	-- Cleanup on player leave
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerGrenades(player)
	end)
	
	if _G then
		_G.GrenadeHandler = self
	end
	print("GrenadeHandler initialized")
end

function GrenadeHandler:HandleGrenadeThrow(player, grenadeData)
	local config = GrenadeSystem:GetGrenadeConfig(grenadeData.GrenadeType)
	if not config then
		warn("Invalid grenade type: " .. tostring(grenadeData.GrenadeType))
		return
	end
	
	-- Create physical grenade
	local grenade = self:CreateGrenadeProjectile(player, grenadeData, config)
	if not grenade then return end
	
	-- Track grenade
	local grenadeId = tostring(grenade)
	activeGrenades[grenadeId] = {
		Player = player,
		Grenade = grenade,
		Config = config,
		ThrowTime = tick(),
		FuseTime = grenadeData.FuseTime
	}
	
	-- Handle special grenade types
	if config.Type == "Impact" then
		self:SetupImpactGrenade(grenade, grenadeId)
	elseif config.Type == "Sticky" then
		self:SetupStickyGrenade(grenade, grenadeId)
	elseif config.Type == "Remote" then
		self:SetupC4(player, grenade, grenadeId)
	else
		-- Standard timed grenade
		self:SetupTimedGrenade(grenade, grenadeId, grenadeData.FuseTime)
	end
end

function GrenadeHandler:CreateGrenadeProjectile(player, grenadeData, config)
	local grenade = Instance.new("Part")
	grenade.Name = "Grenade_" .. config.Type
	grenade.Size = Vector3.new(0.5, 0.5, 0.5)
	grenade.Shape = Enum.PartType.Ball
	grenade.Material = Enum.Material.Metal
	grenade.BrickColor = BrickColor.new("Dark stone grey")
	grenade.Position = grenadeData.Position
	grenade.Parent = workspace
	
	-- Add physics
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Velocity = grenadeData.Direction * grenadeData.Force
	bodyVelocity.Parent = grenade
	
	-- Remove velocity after short time to allow natural physics
	spawn(function()
		wait(0.5)
		if bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
	
	-- Add bounce sound
	local bounceSound = Instance.new("Sound")
	bounceSound.SoundId = "rbxassetid://5564314786" -- Placeholder
	bounceSound.Volume = 0.5
	bounceSound.Parent = grenade
	
	grenade.Touched:Connect(function(hit)
		if hit.Parent ~= player.Character and not hit:IsDescendantOf(player.Character) then
			if bounceSound and bounceSound.Parent then
				bounceSound:Play()
			end
		end
	end)
	
	return grenade
end

function GrenadeHandler:SetupTimedGrenade(grenade, grenadeId, fuseTime)
	spawn(function()
		wait(fuseTime)
		if activeGrenades[grenadeId] then
			self:ExplodeGrenade(grenadeId)
		end
	end)
end

function GrenadeHandler:SetupImpactGrenade(grenade, grenadeId)
	local hasExploded = false
	
	grenade.Touched:Connect(function(hit)
		if hasExploded then return end
		
		local hitCharacter = hit.Parent
		local shouldExplode = false
		
		if (hitCharacter:FindFirstChild("Humanoid") and hitCharacter ~= activeGrenades[grenadeId].Player.Character) or 
		   not hit:IsDescendantOf(activeGrenades[grenadeId].Player.Character) then
			shouldExplode = true
		end
		
		if shouldExplode then
			hasExploded = true
			spawn(function()
				wait(0.1) -- Small delay for impact grenades
				self:ExplodeGrenade(grenadeId)
			end)
		end
	end)
end

function GrenadeHandler:SetupStickyGrenade(grenade, grenadeId)
	local hasStuck = false
	
	grenade.Touched:Connect(function(hit)
		if hasStuck then return end
		
		local hitCharacter = hit.Parent
		if hitCharacter:FindFirstChild("Humanoid") or not hit:IsDescendantOf(activeGrenades[grenadeId].Player.Character) then
			hasStuck = true
			
			-- Stick to surface
			grenade.Anchored = true
			grenade.CanCollide = false
			
			-- Create weld if stuck to player
			if hitCharacter:FindFirstChild("Humanoid") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = grenade
				weld.Part1 = hit
				weld.Parent = grenade
			end
			
			-- Explode after fuse time
			local config = activeGrenades[grenadeId].Config
			spawn(function()
				wait(config.FuseTime)
				if activeGrenades[grenadeId] then
					self:ExplodeGrenade(grenadeId)
				end
			end)
		end
	end)
end

function GrenadeHandler:SetupC4(player, grenade, grenadeId)
	grenade.Touched:Connect(function(hit)
		if hit.Parent ~= player.Character and not hit:IsDescendantOf(player.Character) then
			-- Stick to surface
			grenade.Anchored = true
			grenade.CanCollide = false
			
			-- Add to player's C4 list
			if not placedC4s[player] then
				placedC4s[player] = {}
			end
			
			table.insert(placedC4s[player], grenadeId)
			
			-- Limit C4 count
			local config = activeGrenades[grenadeId].Config
			if #placedC4s[player] > (config.MaxPlaced or 3) then
				local oldestC4 = table.remove(placedC4s[player], 1)
				if activeGrenades[oldestC4] then
					activeGrenades[oldestC4].Grenade:Destroy()
					activeGrenades[oldestC4] = nil
				end
			end
			
			-- Visual indicator
			grenade.BrickColor = BrickColor.new("Really red")
			local light = Instance.new("PointLight")
			light.Color = Color3.new(1, 0, 0)
			light.Brightness = 2
			light.Range = 5
			light.Parent = grenade
			
			-- Despawn after 5 minutes
			Debris:AddItem(grenade, 300)
		end
	end)
end

function GrenadeHandler:DetonatePlayerC4(player)
	if not placedC4s[player] then return end
	
	for _, grenadeId in pairs(placedC4s[player]) do
		if activeGrenades[grenadeId] then
			self:ExplodeGrenade(grenadeId)
		end
	end
	
	placedC4s[player] = {}
end

function GrenadeHandler:ExplodeGrenade(grenadeId)
	local grenadeData = activeGrenades[grenadeId]
	if not grenadeData then return end
	
	local grenade = grenadeData.Grenade
	local config = grenadeData.Config
	local thrower = grenadeData.Player
	
	local explosionPos = grenade.Position
	
	-- Calculate damage to nearby players
	if config.Damage > 0 then
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local distance = (player.Character.HumanoidRootPart.Position - explosionPos).Magnitude
				
				if distance <= config.ExplosionRadius then
					local damageMultiplier = 1 - (distance / config.ExplosionRadius)
					if distance <= config.MinDamageRadius then
						damageMultiplier = 1
					end
					
					local finalDamage = config.Damage * damageMultiplier
					
					-- Apply damage
					if DamageSystem and DamageSystem.DamagePlayer then
						DamageSystem:DamagePlayer(player, finalDamage, {
							Attacker = thrower,
							DamageType = "Grenade",
							WeaponName = config.Name,
							Position = explosionPos
						})
					end
				end
			end
		end
	end
	
	-- Notify all clients of explosion
	local grenadeExplodedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("GrenadeThrown")
	if grenadeExplodedEvent then
		grenadeExplodedEvent:FireAllClients({
			Position = explosionPos,
			GrenadeType = grenadeData.Config.Name,
			Radius = config.ExplosionRadius or config.EffectRadius or config.SmokeRadius,
			Effect = config.Effect
		})
	end
	
	-- Clean up
	grenade:Destroy()
	activeGrenades[grenadeId] = nil
	
	-- Remove from C4 list if applicable
	if placedC4s[thrower] then
		for i, id in pairs(placedC4s[thrower]) do
			if id == grenadeId then
				table.remove(placedC4s[thrower], i)
				break
			end
		end
	end
end

function GrenadeHandler:CleanupPlayerGrenades(player)
	-- Clean up player's C4
	if placedC4s[player] then
		for _, grenadeId in pairs(placedC4s[player]) do
			if activeGrenades[grenadeId] then
				activeGrenades[grenadeId].Grenade:Destroy()
				activeGrenades[grenadeId] = nil
			end
		end
		placedC4s[player] = nil
	end
	
	-- Clean up thrown grenades
	for grenadeId, grenadeData in pairs(activeGrenades) do
		if grenadeData.Player == player then
			grenadeData.Grenade:Destroy()
			activeGrenades[grenadeId] = nil
		end
	end
end

-- Console commands
if _G then
	_G.GrenadeCommands = {
	explodeAll = function()
		for grenadeId, _ in pairs(activeGrenades) do
			GrenadeHandler:ExplodeGrenade(grenadeId)
		end
		print("Exploded all active grenades")
	end,
	
	listActive = function()
		print("Active grenades:")
		for grenadeId, data in pairs(activeGrenades) do
			print("- " .. data.Config.Name .. " by " .. data.Player.Name)
		end
	end,
	
	giveGrenades = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player and player.Character then
			-- Give all grenade types for testing
			local grenadeTypes = {"M67", "Impact", "Sticky", "Smoke", "Flashbang", "Flare", "C4"}
			for _, grenadeType in pairs(grenadeTypes) do
				-- Create grenade tool (placeholder)
				local tool = Instance.new("Tool")
				tool.Name = grenadeType
				tool.RequiresHandle = false
				tool.Parent = player.Backpack
				
				-- Add activation
				tool.Activated:Connect(function()
					if grenadeType == "C4" then
						GrenadeHandler:DetonatePlayerC4(player)
					else
						-- Start cooking or immediate throw
						local config = GrenadeSystem:GetGrenadeConfig(grenadeType)
						if config and config.CanCook then
							print("Started cooking " .. grenadeType)
						else
							print("Threw " .. grenadeType)
						end
					end
				end)
			end
			print("Gave all grenades to " .. playerName)
		end
	end
}
end

GrenadeHandler:Initialize()

return GrenadeHandler