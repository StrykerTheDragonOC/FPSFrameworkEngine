local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

local LeaderboardHandler = {}

-- Cache leaderboard data
local leaderboardCache = {}
local lastUpdateTime = 0
local CACHE_DURATION = 5 -- Update cache every 5 seconds

function LeaderboardHandler:Initialize()
    DataStoreManager:Initialize()
    
    -- Handle leaderboard requests
    local getLeaderboardFunction = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("GetLeaderboard")
    if getLeaderboardFunction then
        getLeaderboardFunction.OnServerInvoke = function(player)
            return self:GetLeaderboardData()
        end
    end
    
    -- Update leaderboard cache periodically
    spawn(function()
        while true do
            self:UpdateLeaderboardCache()
            wait(CACHE_DURATION)
        end
    end)
    
    print("LeaderboardHandler initialized")
end

function LeaderboardHandler:GetLeaderboardData()
    -- Return cached data if recent
    if tick() - lastUpdateTime < CACHE_DURATION and #leaderboardCache > 0 then
        return leaderboardCache
    end
    
    -- Update cache and return
    self:UpdateLeaderboardCache()
    return leaderboardCache
end

function LeaderboardHandler:UpdateLeaderboardCache()
    local leaderboardData = {}
    
    -- Get data for all players
    for _, player in pairs(Players:GetPlayers()) do
        local playerData = DataStoreManager:GetPlayerData(player)
        if playerData then
            local kdr = 0
            if playerData.deaths and playerData.deaths > 0 then
                kdr = playerData.kills / playerData.deaths
            elseif playerData.kills and playerData.kills > 0 then
                kdr = playerData.kills
            end
            
            table.insert(leaderboardData, {
                name = player.Name,
                level = playerData.level or 1,
                kills = playerData.kills or 0,
                deaths = playerData.deaths or 0,
                kdr = kdr,
                score = playerData.score or 0,
                team = playerData.team or "Lobby"
            })
        else
            -- Fallback data for players without data
            table.insert(leaderboardData, {
                name = player.Name,
                level = 1,
                kills = 0,
                deaths = 0,
                kdr = 0,
                score = 0,
                team = "Lobby"
            })
        end
    end
    
    -- Sort by score (highest first)
    table.sort(leaderboardData, function(a, b)
        return a.score > b.score
    end)
    
    leaderboardCache = leaderboardData
    lastUpdateTime = tick()
end

-- Initialize the handler
LeaderboardHandler:Initialize()

return LeaderboardHandler
