-- Team Selection Handler
-- Manages team selection, deployment, and team balancing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

-- Wait for FPSSystem
local FPSSystem = ReplicatedStorage:WaitForChild("FPSSystem")
local RemoteEventsManager = require(FPSSystem.RemoteEvents.RemoteEventsManager)
local TeamManager = require(FPSSystem.Modules.TeamManager)

local TeamSelectionHandler = {}

-- Player states
local playerStates = {} -- [player] = "lobby", "deployed", "spectating"
local selectedTeams = {} -- [player] = teamName
local pendingDeployments = {} -- [player] = true

-- Team balancing
local maxTeamSizeDifference = 2
local autoBalanceEnabled = true

-- Initialize teams
local function InitializeTeams()
    -- Create teams if they don't exist
    local fbiTeam = Teams:FindFirstChild("FBI")
    local kfcTeam = Teams:FindFirstChild("KFC")
    
    if not fbiTeam then
        fbiTeam = Instance.new("Team")
        fbiTeam.Name = "FBI"
        fbiTeam.TeamColor = BrickColor.new("Bright blue")
        fbiTeam.AutoAssignable = false
        fbiTeam.Parent = Teams
    end
    
    if not kfcTeam then
        kfcTeam = Instance.new("Team")
        kfcTeam.Name = "KFC"
        kfcTeam.TeamColor = BrickColor.new("Bright red")
        kfcTeam.AutoAssignable = false
        kfcTeam.Parent = Teams
    end
end

-- Get team sizes
local function GetTeamSizes()
    local fbiCount = 0
    local kfcCount = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team and player.Team.Name == "FBI" then
            fbiCount = fbiCount + 1
        elseif player.Team and player.Team.Name == "KFC" then
            kfcCount = kfcCount + 1
        end
    end
    
    return fbiCount, kfcCount
end

-- Check if team selection is balanced
local function IsTeamBalanced()
    if not autoBalanceEnabled then return true end
    
    local fbiCount, kfcCount = GetTeamSizes()
    local difference = math.abs(fbiCount - kfcCount)
    
    return difference <= maxTeamSizeDifference
end

-- Auto-balance teams
local function AutoBalanceTeams()
    if not autoBalanceEnabled then return end
    
    local fbiCount, kfcCount = GetTeamSizes()
    local difference = math.abs(fbiCount - kfcCount)
    
    if difference > maxTeamSizeDifference then
        print("Auto-balancing teams...")
        
        -- Move players from larger team to smaller team
        local targetTeam = fbiCount > kfcCount and "KFC" or "FBI"
        local sourceTeam = fbiCount > kfcCount and "FBI" or "KFC"
        
        local playersToMove = math.floor(difference / 2)
        local movedCount = 0
        
        for _, player in pairs(Players:GetPlayers()) do
            if movedCount >= playersToMove then break end
            
            if player.Team and player.Team.Name == sourceTeam and playerStates[player] == "lobby" then
                -- Move player to other team
                selectedTeams[player] = targetTeam
                RemoteEventsManager:FireClient(player, "TeamSelected", targetTeam)
                
                movedCount = movedCount + 1
                print("Auto-moved " .. player.Name .. " to " .. targetTeam)
            end
        end
    end
end

-- Auto-assign team based on balance
local function AutoAssignTeam(player)
    if not player then return end
    
    local fbiCount, kfcCount = GetTeamSizes()
    local teamName = fbiCount <= kfcCount and "FBI" or "KFC"
    
    -- Store team selection
    selectedTeams[player] = teamName
    
    print(player.Name .. " auto-assigned to team: " .. teamName)
end

-- Handle deployment request
local function HandleDeployment(player)
    if not player then return end
    
    -- Auto-assign team if not already assigned
    local selectedTeam = selectedTeams[player]
    if not selectedTeam then
        AutoAssignTeam(player)
        selectedTeam = selectedTeams[player]
    end
    
    -- Check team balance
    if not IsTeamBalanced() then
        RemoteEventsManager:FireClient(player, "DeploymentError", "Teams are not balanced. Please wait for auto-balance.")
        return
    end
    
    -- Mark as pending deployment
    pendingDeployments[player] = true
    
    -- Change player team
    local team = Teams:FindFirstChild(selectedTeam)
    if team then
        player.Team = team
    end
    
    -- Change player state
    playerStates[player] = "deployed"
    
    -- Notify client
    RemoteEventsManager:FireClient(player, "DeploymentSuccessful", selectedTeam)
    
    print(player.Name .. " deployed to team: " .. selectedTeam)
end

-- Handle deployment cancellation (return to lobby)
local function HandleReturnToLobby(player)
    if not player then return end
    
    -- Remove from team
    player.Team = nil
    
    -- Reset state
    playerStates[player] = "lobby"
    pendingDeployments[player] = nil
    
    -- Notify client
    RemoteEventsManager:FireClient(player, "ReturnedToLobby")
    
    print(player.Name .. " returned to lobby")
end

-- Admin team change
local function AdminTeamChange(adminPlayer, targetPlayer, teamName)
    if not adminPlayer or not targetPlayer or not teamName then return end
    
    -- Check admin permissions (simplified - you can expand this)
    local adminLevel = adminPlayer:GetAttribute("AdminLevel") or 0
    if adminLevel < 1 then
        RemoteEventsManager:FireClient(adminPlayer, "AdminError", "Insufficient permissions")
        return
    end
    
    -- Validate team
    local team = Teams:FindFirstChild(teamName)
    if not team then
        RemoteEventsManager:FireClient(adminPlayer, "AdminError", "Invalid team: " .. teamName)
        return
    end
    
    -- Change target player's team
    selectedTeams[targetPlayer] = teamName
    targetPlayer.Team = team
    playerStates[targetPlayer] = "deployed"
    
    -- Notify both players
    RemoteEventsManager:FireClient(adminPlayer, "AdminTeamChangeSuccess", targetPlayer.Name .. " moved to " .. teamName)
    RemoteEventsManager:FireClient(targetPlayer, "TeamChangedByAdmin", teamName)
    
    print(adminPlayer.Name .. " moved " .. targetPlayer.Name .. " to team: " .. teamName)
end

-- Admin command system
local function HandleAdminCommand(player, command, args)
    if not player then return end
    
    -- Check admin permissions
    local adminLevel = player:GetAttribute("AdminLevel") or 0
    if adminLevel < 1 then
        RemoteEventsManager:FireClient(player, "AdminError", "Insufficient permissions")
        return
    end
    
    command = command:lower()
    
    if command == "teamchange" or command == "tc" then
        -- Usage: /tc <player> <team>
        if #args < 2 then
            RemoteEventsManager:FireClient(player, "AdminError", "Usage: /tc <player> <team>")
            return
        end
        
        local targetName = args[1]
        local teamName = args[2]:upper()
        
        local targetPlayer = Players:FindFirstChild(targetName)
        if not targetPlayer then
            RemoteEventsManager:FireClient(player, "AdminError", "Player not found: " .. targetName)
            return
        end
        
        AdminTeamChange(player, targetPlayer, teamName)
        
    elseif command == "balance" or command == "bal" then
        -- Force team balance
        AutoBalanceTeams()
        RemoteEventsManager:FireClient(player, "AdminSuccess", "Teams balanced")
        
    elseif command == "setbalance" or command == "setbal" then
        -- Set auto-balance on/off
        if #args < 1 then
            RemoteEventsManager:FireClient(player, "AdminError", "Usage: /setbal <on/off>")
            return
        end
        
        local state = args[1]:lower()
        if state == "on" or state == "true" then
            autoBalanceEnabled = true
            RemoteEventsManager:FireClient(player, "AdminSuccess", "Auto-balance enabled")
        elseif state == "off" or state == "false" then
            autoBalanceEnabled = false
            RemoteEventsManager:FireClient(player, "AdminSuccess", "Auto-balance disabled")
        else
            RemoteEventsManager:FireClient(player, "AdminError", "Usage: /setbal <on/off>")
        end
        
    elseif command == "teamdiff" or command == "tdiff" then
        -- Set max team size difference
        if #args < 1 then
            RemoteEventsManager:FireClient(player, "AdminError", "Usage: /tdiff <number>")
            return
        end
        
        local diff = tonumber(args[1])
        if diff and diff >= 0 then
            maxTeamSizeDifference = diff
            RemoteEventsManager:FireClient(player, "AdminSuccess", "Max team difference set to: " .. diff)
        else
            RemoteEventsManager:FireClient(player, "AdminError", "Invalid number")
        end
        
    elseif command == "teaminfo" or command == "tinfo" then
        -- Show team information
        local fbiCount, kfcCount = GetTeamSizes()
        local message = string.format("FBI: %d | KFC: %d | Difference: %d | Auto-balance: %s", 
            fbiCount, kfcCount, math.abs(fbiCount - kfcCount), autoBalanceEnabled and "ON" or "OFF")
        RemoteEventsManager:FireClient(player, "AdminSuccess", message)
        
    elseif command == "help" then
        -- Show admin commands
        local helpMessage = "Admin Commands:\n" ..
            "/tc <player> <team> - Move player to team\n" ..
            "/bal - Force team balance\n" ..
            "/setbal <on/off> - Toggle auto-balance\n" ..
            "/tdiff <number> - Set max team difference\n" ..
            "/tinfo - Show team information"
        RemoteEventsManager:FireClient(player, "AdminSuccess", helpMessage)
        
    else
        RemoteEventsManager:FireClient(player, "AdminError", "Unknown command: " .. command)
    end
end

-- Chat command handler
local function OnChatted(player, message)
    if message:sub(1, 1) == "/" then
        local parts = {}
        for part in message:gmatch("%S+") do
            table.insert(parts, part)
        end
        
        if #parts > 0 then
            local command = parts[1]:sub(2) -- Remove the "/"
            table.remove(parts, 1) -- Remove command from args
            HandleAdminCommand(player, command, parts)
        end
    end
end

-- Player joining
local function OnPlayerAdded(player)
    -- Initialize player state
    playerStates[player] = "lobby"
    selectedTeams[player] = nil
    pendingDeployments[player] = nil
    
    -- Remove from any team
    player.Team = nil
    
    -- Auto-assign team for balance
    AutoAssignTeam(player)
    
    -- Connect chat commands for admins
    player.Chatted:Connect(function(message)
        OnChatted(player, message)
    end)
    
    print(player.Name .. " joined - added to lobby and auto-assigned team")
end

-- Player leaving
local function OnPlayerRemoving(player)
    -- Clean up player data
    playerStates[player] = nil
    selectedTeams[player] = nil
    pendingDeployments[player] = nil
    
    print(player.Name .. " left - cleaned up data")
end

-- Initialize
function TeamSelectionHandler:Initialize()
    print("TeamSelectionHandler: Initializing...")
    
    -- Initialize teams
    InitializeTeams()
    
    -- Connect player events
    Players.PlayerAdded:Connect(OnPlayerAdded)
    Players.PlayerRemoving:Connect(OnPlayerRemoving)
    
    -- Connect remote events
    local deployEvent = RemoteEventsManager:GetEvent("DeployPlayer")
    if deployEvent then
        deployEvent.OnServerEvent:Connect(HandleDeployment)
    end

    local lobbyEvent = RemoteEventsManager:GetEvent("ReturnToLobby")
    if lobbyEvent then
        lobbyEvent.OnServerEvent:Connect(HandleReturnToLobby)
    end

    local adminTeamEvent = RemoteEventsManager:GetEvent("AdminTeamChange")
    if adminTeamEvent then
        adminTeamEvent.OnServerEvent:Connect(AdminTeamChange)
    end
    
    -- Auto-balance timer
    spawn(function()
        while true do
            wait(10) -- Check every 10 seconds
            AutoBalanceTeams()
        end
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        OnPlayerAdded(player)
    end
    
    print("TeamSelectionHandler: Ready!")
end

-- Public methods
function TeamSelectionHandler:GetPlayerState(player)
    return playerStates[player]
end

function TeamSelectionHandler:GetSelectedTeam(player)
    return selectedTeams[player]
end

function TeamSelectionHandler:IsPlayerDeployed(player)
    return playerStates[player] == "deployed"
end

function TeamSelectionHandler:SetAutoBalance(enabled)
    autoBalanceEnabled = enabled
    print("Auto-balance " .. (enabled and "enabled" or "disabled"))
end

function TeamSelectionHandler:SetMaxTeamDifference(difference)
    maxTeamSizeDifference = difference
    print("Max team size difference set to: " .. difference)
end

-- Initialize
TeamSelectionHandler:Initialize()

return TeamSelectionHandler
