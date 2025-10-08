--[[
	Bounty Events Initializer
	Creates the BountyEvents folder and RemoteEvents before other scripts run
	Numbered 00_ to ensure it runs first
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Initializing Bounty Events...")

-- Create BountyEvents folder
local bountyEvents = ReplicatedStorage:FindFirstChild("BountyEvents")
if not bountyEvents then
	bountyEvents = Instance.new("Folder")
	bountyEvents.Name = "BountyEvents"
	bountyEvents.Parent = ReplicatedStorage
	print("✓ Created BountyEvents folder")
end

-- Create PlaceBounty RemoteEvent
local placeBountyEvent = bountyEvents:FindFirstChild("PlaceBounty")
if not placeBountyEvent then
	placeBountyEvent = Instance.new("RemoteEvent")
	placeBountyEvent.Name = "PlaceBounty"
	placeBountyEvent.Parent = bountyEvents
	print("✓ Created PlaceBounty event")
end

-- Create ClaimBounty RemoteEvent
local claimBountyEvent = bountyEvents:FindFirstChild("ClaimBounty")
if not claimBountyEvent then
	claimBountyEvent = Instance.new("RemoteEvent")
	claimBountyEvent.Name = "ClaimBounty"
	claimBountyEvent.Parent = bountyEvents
	print("✓ Created ClaimBounty event")
end

-- Create BountyNotification RemoteEvent
local bountyNotification = ReplicatedStorage:FindFirstChild("BountyNotification")
if not bountyNotification then
	bountyNotification = Instance.new("RemoteEvent")
	bountyNotification.Name = "BountyNotification"
	bountyNotification.Parent = ReplicatedStorage
	print("✓ Created BountyNotification event")
end

print("✓ Bounty Events initialized successfully")