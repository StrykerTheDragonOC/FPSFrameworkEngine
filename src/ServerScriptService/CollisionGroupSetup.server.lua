--[[
	CollisionGroupSetup.server.lua
	Creates collision groups on the server for the FPS system
]]

local PhysicsService = game:GetService("PhysicsService")

-- Create Viewmodels collision group
local success, err = pcall(function()
	PhysicsService:RegisterCollisionGroup("Viewmodels")
end)

if not success then
	if not err:match("already exists") then
		warn("Failed to create Viewmodels collision group:", err)
	end
end

-- Disable collisions between Viewmodels and Default group
pcall(function()
	PhysicsService:CollisionGroupSetCollidable("Viewmodels", "Default", false)
end)

print("✓ Collision groups configured (Viewmodels)")
