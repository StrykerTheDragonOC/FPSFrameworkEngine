-- VotingHandler.server.lua
-- Handles voting system on the server side

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for FPS system to load
repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local VotingSystem = require(ReplicatedStorage.FPSSystem.Modules.VotingSystem)
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

-- Initialize systems
RemoteEventsManager:Initialize()
VotingSystem:Initialize()

-- Handle voting events
local voteEvent = RemoteEventsManager:GetEvent("VoteForGamemode")
if voteEvent then
    voteEvent.OnServerEvent:Connect(function(player, gamemode)
        print("Received vote from", player.Name, "for", gamemode)
        VotingSystem:ProcessVote(player, gamemode)
    end)
    print("VotingHandler: VoteForGamemode event connected")
else
    warn("VotingHandler: Could not find VoteForGamemode event")
end

print("VotingHandler initialized and ready")