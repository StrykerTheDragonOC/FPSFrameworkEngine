local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local MatchStatusHandler = {}

-- Match status data
local matchStatus = {
    status = "WAITING",
    timeRemaining = 0,
    currentGamemode = "TDM",
    teamScores = {
        FBI = 0,
        KFC = 0
    }
}

function MatchStatusHandler:Initialize()
    
    -- Handle match status requests
    local getMatchStatusFunction = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("GetMatchStatus")
    if getMatchStatusFunction then
        getMatchStatusFunction.OnServerInvoke = function(player)
            return self:GetCurrentMatchStatus()
        end
    end
    
    -- Update match status periodically
    spawn(function()
        while true do
            self:UpdateMatchStatus()
            wait(1) -- Update every second
        end
    end)
    
    print("MatchStatusHandler initialized")
end

function MatchStatusHandler:GetCurrentMatchStatus()
    return {
        status = matchStatus.status,
        timeRemaining = matchStatus.timeRemaining,
        currentGamemode = matchStatus.currentGamemode,
        teamScores = matchStatus.teamScores
    }
end

function MatchStatusHandler:UpdateMatchStatus()
    -- Get current player count
    local playerCount = #Players:GetPlayers()
    
    -- Update match status based on player count and game state
    if playerCount < 2 then
        matchStatus.status = "WAITING"
        matchStatus.timeRemaining = 0
    elseif matchStatus.status == "WAITING" then
        -- Start countdown when we have enough players
        if playerCount >= 2 then
            matchStatus.status = "STARTING"
            matchStatus.timeRemaining = 10 -- 10 second countdown
        end
    elseif matchStatus.status == "STARTING" then
        matchStatus.timeRemaining = matchStatus.timeRemaining - 1
        if matchStatus.timeRemaining <= 0 then
            matchStatus.status = "IN PROGRESS"
            matchStatus.timeRemaining = 1200 -- 20 minutes
        end
    elseif matchStatus.status == "IN PROGRESS" then
        matchStatus.timeRemaining = matchStatus.timeRemaining - 1
        if matchStatus.timeRemaining <= 0 then
            matchStatus.status = "ENDING"
            matchStatus.timeRemaining = 10
        end
    elseif matchStatus.status == "ENDING" then
        matchStatus.timeRemaining = matchStatus.timeRemaining - 1
        if matchStatus.timeRemaining <= 0 then
            matchStatus.status = "WAITING"
            matchStatus.timeRemaining = 0
            -- Reset scores
            matchStatus.teamScores.FBI = 0
            matchStatus.teamScores.KFC = 0
        end
    end
end

function MatchStatusHandler:SetMatchStatus(status, timeRemaining)
    matchStatus.status = status
    matchStatus.timeRemaining = timeRemaining or 0
end

function MatchStatusHandler:UpdateTeamScore(team, score)
    if matchStatus.teamScores[team] then
        matchStatus.teamScores[team] = score
    end
end

-- Initialize the handler
MatchStatusHandler:Initialize()

return MatchStatusHandler
