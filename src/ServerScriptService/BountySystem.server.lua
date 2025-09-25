-- Bounty System Server Script
-- Handles bounty placement, tracking, and rewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for RemoteEvents (manually created)
local bountyEvents = ReplicatedStorage:WaitForChild("BountyEvents")
local placeBountyEvent = bountyEvents:WaitForChild("PlaceBounty")
local claimBountyEvent = bountyEvents:WaitForChild("ClaimBounty")
local bountyNotification = ReplicatedStorage:WaitForChild("BountyNotification")

-- Bounty data storage
local bounties = {}
local bountyHighlights = {}
local lastDamageSource = {} -- Track who dealt the last damage to each player

-- Function to track damage for bounty claiming
local function trackDamage(victim, attacker)
    if victim and attacker and victim ~= attacker then
        lastDamageSource[victim.UserId] = attacker
    end
end

-- Function to remove bounty highlight (defined early for use in other functions)
local function removeBountyHighlight(player)
    local character = player.Character
    if not character then return end
    
    -- Remove highlight
    local highlight = character:FindFirstChild("BountyHighlight")
    if highlight then
        highlight:Destroy()
    end
    
    -- Notify client to remove bounty display
    bountyNotification:FireClient(player, "bountyDisplay", "hide", 0)
    
    bountyHighlights[player.UserId] = nil
end

-- Function to check and claim bounty on kill
local function checkBountyClaim(victim, killer)
    if not bounties[victim.UserId] or not killer then return end
    
    local bountyAmount = bounties[victim.UserId]
    
    -- Remove bounty
    bounties[victim.UserId] = nil
    removeBountyHighlight(victim)
    
    -- Clear damage tracking
    lastDamageSource[victim.UserId] = nil
    
    -- Notify all players
    bountyNotification:FireAllClients("claimed", killer.Name, victim.Name, bountyAmount)
    
    -- Give reward to killer (you can implement your own reward system here)
    print(killer.Name .. " claimed bounty of " .. bountyAmount .. " for killing " .. victim.Name)
end

-- Function to create bounty highlight
local function createBountyHighlight(player)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "BountyHighlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    
    -- Notify client to create bounty display
    bountyNotification:FireClient(player, "bountyDisplay", "show", bounties[player.UserId])
    
    bountyHighlights[player.UserId] = {
        highlight = highlight
    }
end


-- Handle bounty placement
placeBountyEvent.OnServerEvent:Connect(function(player, targetPlayer, bountyAmount)
    if not targetPlayer or not targetPlayer.Character then return end
    
    -- Allow self-bounties (placing bounty on yourself)
    local isSelfBounty = (player == targetPlayer)
    
    -- List of allowed usernames (add your usernames here)
    local allowedUsers = {
        "StrykerOC",         -- Your username
        "D4TAC0DED",   -- Add more usernames as needed
        "AdminUser1",        -- Example usernames
        "AdminUser2"         -- Example usernames
    }
    
    -- Check if player has permission
    local hasPermission = false
    for _, username in pairs(allowedUsers) do
        if player.Name == username then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        print("Player " .. player.Name .. " tried to place bounty but doesn't have permission")
        return
    end
    
    -- Validate bounty amount
    if bountyAmount < 100 or bountyAmount > 1000000 then
        bountyAmount = math.max(100, math.min(1000000, bountyAmount))
    end
    
    -- Place bounty
    bounties[targetPlayer.UserId] = bountyAmount
    
    -- Create highlight for target player
    createBountyHighlight(targetPlayer)
    
    -- Notify all players
    if isSelfBounty then
        bountyNotification:FireAllClients("placed", player.Name .. " (SELF)", targetPlayer.Name, bountyAmount)
    else
        bountyNotification:FireAllClients("placed", player.Name, targetPlayer.Name, bountyAmount)
    end
end)

-- Handle bounty claiming
claimBountyEvent.OnServerEvent:Connect(function(killer, victim)
    if not bounties[victim.UserId] then return end
    
    local bountyAmount = bounties[victim.UserId]
    
    -- Remove bounty
    bounties[victim.UserId] = nil
    removeBountyHighlight(victim)
    
    -- Notify all players
    bountyNotification:FireAllClients("claimed", killer.Name, victim.Name, bountyAmount)
    
    -- Give reward to killer (you can implement your own reward system here)
    print(killer.Name .. " claimed bounty of " .. bountyAmount .. " for killing " .. victim.Name)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    if bounties[player.UserId] then
        bounties[player.UserId] = nil
    end
    if bountyHighlights[player.UserId] then
        bountyHighlights[player.UserId] = nil
    end
end)

-- Handle character respawning and death detection
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Wait for character to fully load
        if bounties[player.UserId] then
            createBountyHighlight(player)
        end
        
        -- Set up death detection for this character
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            -- Check if there's a bounty and if someone killed this player
            local killer = lastDamageSource[player.UserId]
            
            if bounties[player.UserId] then
                if killer then
                    -- Someone killed this player - claim the bounty
                    checkBountyClaim(player, killer)
                else
                    -- Player died without being killed by someone (fall damage, etc.)
                    local bountyAmount = bounties[player.UserId]
                    bounties[player.UserId] = nil
                    removeBountyHighlight(player)
                    
                    -- Notify all players that bounty was cleared due to death
                    bountyNotification:FireAllClients("cleared", player.Name, "DEATH", bountyAmount)
                    print("Bounty cleared for " .. player.Name .. " due to death")
                end
            end
            
            -- Clear damage tracking
            lastDamageSource[player.UserId] = nil
        end)
    end)
end)

-- Handle existing players (in case server restarts)
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                -- Check if there's a bounty and if someone killed this player
                local killer = lastDamageSource[player.UserId]
                
                if bounties[player.UserId] then
                    if killer then
                        -- Someone killed this player - claim the bounty
                        checkBountyClaim(player, killer)
                    else
                        -- Player died without being killed by someone (fall damage, etc.)
                        local bountyAmount = bounties[player.UserId]
                        bounties[player.UserId] = nil
                        removeBountyHighlight(player)
                        
                        -- Notify all players that bounty was cleared due to death
                        bountyNotification:FireAllClients("cleared", player.Name, "DEATH", bountyAmount)
                        print("Bounty cleared for " .. player.Name .. " due to death")
                    end
                end
                
                -- Clear damage tracking
                lastDamageSource[player.UserId] = nil
            end)
        end
    end
end

-- Create BountySystem table for external access
local BountySystem = {}

-- Function to be called by other systems when damage is dealt
function BountySystem:TrackDamage(victim, attacker)
    trackDamage(victim, attacker)
end

-- Make the system globally accessible
_G.BountySystem = BountySystem

-- Console command for testing
game:GetService("Players").PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:lower() == "/testbounty" then
            -- Place a test bounty on the player who typed the command
            if bounties[player.UserId] then
                print("Player " .. player.Name .. " already has a bounty")
            else
                bounties[player.UserId] = 1000
                createBountyHighlight(player)
                bountyNotification:FireAllClients("placed", "SYSTEM", player.Name, 1000)
                print("Test bounty placed on " .. player.Name)
            end
        end
    end)
end)

print("Bounty System loaded - Use /testbounty to place a test bounty on yourself")
