-- ComprehensiveShopSystem.lua
-- Advanced shop system with credits, XP purchases, and comprehensive item management
-- Supports weapons, attachments, perks, and cosmetics

local ComprehensiveShopSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Shop categories and items
local SHOP_CATEGORIES = {
    WEAPONS = "Weapons",
    ATTACHMENTS = "Attachments", 
    PERKS = "Perks",
    COSMETICS = "Cosmetics",
    CONSUMABLES = "Consumables",
    PREMIUM = "Premium"
}

-- Comprehensive shop catalog
local SHOP_CATALOG = {
    [SHOP_CATEGORIES.WEAPONS] = {
        -- Primary Weapons
        ["M4A1"] = {
            Name = "M4A1 Carbine",
            Category = "Primary",
            Type = "Assault Rifle",
            Price = {Credits = 2500, XP = 0, Robux = 0},
            UnlockLevel = 5,
            Stats = {Damage = 30, Range = 200, Recoil = 2, FireRate = 650},
            Description = "Reliable assault rifle with balanced stats",
            Rarity = "Common"
        },
        ["AK47"] = {
            Name = "AK-47",
            Category = "Primary", 
            Type = "Assault Rifle",
            Price = {Credits = 3000, XP = 0, Robux = 0},
            UnlockLevel = 10,
            Stats = {Damage = 35, Range = 180, Recoil = 4, FireRate = 600},
            Description = "High damage assault rifle with strong recoil",
            Rarity = "Common"
        },
        ["SCAR_H"] = {
            Name = "FN SCAR-H",
            Category = "Primary",
            Type = "Assault Rifle", 
            Price = {Credits = 4500, XP = 0, Robux = 0},
            UnlockLevel = 20,
            Stats = {Damage = 40, Range = 220, Recoil = 3, FireRate = 575},
            Description = "Heavy hitting battle rifle for experienced players",
            Rarity = "Rare"
        },
        -- Secondary Weapons
        ["Glock17"] = {
            Name = "Glock 17",
            Category = "Secondary",
            Type = "Pistol",
            Price = {Credits = 800, XP = 0, Robux = 0},
            UnlockLevel = 1,
            Stats = {Damage = 25, Range = 50, Recoil = 1, FireRate = 400},
            Description = "Standard issue sidearm",
            Rarity = "Common"
        },
        ["DesertEagle"] = {
            Name = "Desert Eagle",
            Category = "Secondary",
            Type = "Pistol",
            Price = {Credits = 2000, XP = 0, Robux = 0},
            UnlockLevel = 15,
            Stats = {Damage = 60, Range = 70, Recoil = 6, FireRate = 200},
            Description = "High-powered handgun with devastating damage",
            Rarity = "Epic"
        }
    },
    
    [SHOP_CATEGORIES.ATTACHMENTS] = {
        ["RedDotSight"] = {
            Name = "Red Dot Sight",
            Type = "Optic",
            Price = {Credits = 1200, XP = 500, Robux = 0},
            UnlockLevel = 8,
            Effects = {AimSpeed = 0.15, Accuracy = 0.1},
            Description = "Improves target acquisition speed",
            Rarity = "Common"
        },
        ["ACOGScope"] = {
            Name = "ACOG 4x Scope",
            Type = "Optic",
            Price = {Credits = 3500, XP = 1200, Robux = 0},
            UnlockLevel = 20,
            Effects = {Accuracy = 0.25, Range = 0.2, AimSpeed = -0.1},
            Description = "Long-range magnified optic",
            Rarity = "Rare"
        },
        ["Suppressor"] = {
            Name = "Sound Suppressor",
            Type = "Barrel",
            Price = {Credits = 2000, XP = 800, Robux = 0},
            UnlockLevel = 12,
            Effects = {SoundReduction = 0.7, Damage = -0.1, Range = 0.1},
            Description = "Reduces weapon noise and muzzle flash",
            Rarity = "Uncommon"
        },
        ["ExtendedMag"] = {
            Name = "Extended Magazine",
            Type = "Magazine",
            Price = {Credits = 1500, XP = 600, Robux = 0},
            UnlockLevel = 15,
            Effects = {MagSize = 15, ReloadTime = 0.5},
            Description = "Increases ammunition capacity",
            Rarity = "Uncommon"
        }
    },
    
    [SHOP_CATEGORIES.PERKS] = {
        ["FastHands"] = {
            Name = "Fast Hands",
            Type = "Equipment",
            Price = {Credits = 2000, XP = 1000, Robux = 0},
            UnlockLevel = 18,
            Effects = {ReloadSpeed = 0.3, SwitchSpeed = 0.4},
            Description = "Faster reload and weapon switching",
            Rarity = "Rare"
        },
        ["IronLungs"] = {
            Name = "Iron Lungs",
            Type = "Physical",
            Price = {Credits = 1800, XP = 900, Robux = 0},
            UnlockLevel = 14,
            Effects = {HoldBreath = 2.0, AimSteadiness = 0.3},
            Description = "Hold breath longer when aiming",
            Rarity = "Uncommon"
        },
        ["Ghost"] = {
            Name = "Ghost",
            Type = "Stealth",
            Price = {Credits = 3000, XP = 1500, Robux = 0},
            UnlockLevel = 25,
            Effects = {RadarInvisible = true, FootstepVolume = -0.5},
            Description = "Invisible to enemy radar and quieter movement",
            Rarity = "Epic"
        }
    },
    
    [SHOP_CATEGORIES.COSMETICS] = {
        ["UrbanCamo"] = {
            Name = "Urban Camo",
            Type = "Weapon Skin",
            Price = {Credits = 1000, XP = 0, Robux = 0},
            UnlockLevel = 5,
            Description = "Urban camouflage weapon skin",
            Rarity = "Common"
        },
        ["DigitalCamo"] = {
            Name = "Digital Camo",
            Type = "Weapon Skin", 
            Price = {Credits = 2500, XP = 0, Robux = 0},
            UnlockLevel = 15,
            Description = "Digital camouflage pattern",
            Rarity = "Rare"
        },
        ["GoldSkin"] = {
            Name = "Gold Plated",
            Type = "Weapon Skin",
            Price = {Credits = 10000, XP = 5000, Robux = 0},
            UnlockLevel = 50,
            Description = "Prestigious gold-plated finish",
            Rarity = "Legendary"
        }
    },
    
    [SHOP_CATEGORIES.CONSUMABLES] = {
        ["CreditsBooster"] = {
            Name = "Credits Booster (1 Hour)",
            Type = "Booster",
            Price = {Credits = 0, XP = 0, Robux = 50},
            UnlockLevel = 1,
            Effects = {CreditsMultiplier = 2.0, Duration = 3600},
            Description = "Double credits for 1 hour",
            Rarity = "Premium"
        },
        ["XPBooster"] = {
            Name = "XP Booster (1 Hour)",
            Type = "Booster",
            Price = {Credits = 0, XP = 0, Robux = 50},
            UnlockLevel = 1,
            Effects = {XPMultiplier = 2.0, Duration = 3600},
            Description = "Double XP gain for 1 hour",
            Rarity = "Premium"
        },
        ["MedKit"] = {
            Name = "Combat Med Kit",
            Type = "Consumable",
            Price = {Credits = 500, XP = 0, Robux = 0},
            UnlockLevel = 5,
            Effects = {HealthRestore = 100, UseTime = 3.0},
            Description = "Restores health when used",
            Rarity = "Common"
        }
    },
    
    [SHOP_CATEGORIES.PREMIUM] = {
        ["PremiumPass"] = {
            Name = "Premium Battle Pass",
            Type = "Pass",
            Price = {Credits = 0, XP = 0, Robux = 800},
            UnlockLevel = 1,
            Effects = {XPBonus = 0.5, CreditsBonus = 0.5, ExclusiveItems = true},
            Description = "Unlock exclusive rewards and bonuses",
            Rarity = "Premium"
        },
        ["VIPStatus"] = {
            Name = "VIP Status (30 Days)",
            Type = "Status",
            Price = {Credits = 0, XP = 0, Robux = 400},
            UnlockLevel = 1,
            Effects = {Priority = true, ExtraLoadouts = 2, CustomTag = true},
            Description = "VIP perks for 30 days",
            Rarity = "Premium"
        }
    }
}

-- Player shop data
local playerShopData = {}

function ComprehensiveShopSystem:init()
    print("[ComprehensiveShopSystem] Initializing comprehensive shop system...")
    
    -- Initialize player data
    Players.PlayerAdded:Connect(function(player)
        self:initializePlayerData(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:initializePlayerData(player)
    end
    
    -- Setup remote events
    self:setupRemoteEvents()
    
    -- Setup purchase processing
    if RunService:IsServer() then
        self:setupPurchaseProcessing()
    end
    
    print("[ComprehensiveShopSystem] System initialized")
    return true
end

function ComprehensiveShopSystem:initializePlayerData(player)
    playerShopData[player.UserId] = {
        credits = 5000, -- Starting credits
        xp = 0,
        level = 1,
        owned = {
            weapons = {"Glock17"}, -- Default weapon
            attachments = {},
            perks = {},
            cosmetics = {},
            consumables = {}
        },
        cart = {},
        purchaseHistory = {},
        boosters = {
            credits = {active = false, endTime = 0, multiplier = 1.0},
            xp = {active = false, endTime = 0, multiplier = 1.0}
        }
    }
end

function ComprehensiveShopSystem:getShopCatalog(category)
    if category then
        return SHOP_CATALOG[category]
    else
        return SHOP_CATALOG
    end
end

function ComprehensiveShopSystem:getPlayerData(player)
    return playerShopData[player.UserId]
end

function ComprehensiveShopSystem:addCredits(player, amount, reason)
    local playerData = playerShopData[player.UserId]
    if not playerData then return false end
    
    local finalAmount = amount
    
    -- Apply credits booster if active
    if playerData.boosters.credits.active and tick() < playerData.boosters.credits.endTime then
        finalAmount = amount * playerData.boosters.credits.multiplier
    end
    
    playerData.credits = playerData.credits + finalAmount
    
    print("[ComprehensiveShopSystem]", player.Name, "earned", finalAmount, "credits for", reason or "unknown")
    
    -- Sync with client
    self:syncPlayerData(player)
    return true
end

function ComprehensiveShopSystem:canPurchaseItem(player, itemId, category)
    local playerData = playerShopData[player.UserId]
    if not playerData then return false, "Player data not found" end
    
    local item = SHOP_CATALOG[category] and SHOP_CATALOG[category][itemId]
    if not item then return false, "Item not found" end
    
    -- Check level requirement
    if playerData.level < item.UnlockLevel then
        return false, "Level " .. item.UnlockLevel .. " required"
    end
    
    -- Check if already owned (for non-consumables)
    if category ~= SHOP_CATEGORIES.CONSUMABLES then
        local ownedCategory = category:lower():gsub("s$", "s") -- weapons -> weapons
        if playerData.owned[ownedCategory] then
            for _, ownedItem in pairs(playerData.owned[ownedCategory]) do
                if ownedItem == itemId then
                    return false, "Already owned"
                end
            end
        end
    end
    
    -- Check currency requirements
    local price = item.Price
    if price.Credits > 0 and playerData.credits < price.Credits then
        return false, "Insufficient credits"
    end
    
    if price.XP > 0 and playerData.xp < price.XP then
        return false, "Insufficient XP"
    end
    
    -- Robux purchases handled separately
    
    return true, "Can purchase"
end

function ComprehensiveShopSystem:purchaseItem(player, itemId, category, paymentMethod)
    local canPurchase, reason = self:canPurchaseItem(player, itemId, category)
    if not canPurchase then
        return false, reason
    end
    
    local playerData = playerShopData[player.UserId]
    local item = SHOP_CATALOG[category][itemId]
    local price = item.Price
    
    -- Handle different payment methods
    if paymentMethod == "credits" and price.Credits > 0 then
        playerData.credits = playerData.credits - price.Credits
    elseif paymentMethod == "xp" and price.XP > 0 then
        playerData.xp = playerData.xp - price.XP
    elseif paymentMethod == "robux" and price.Robux > 0 then
        -- Handle Robux purchase through MarketplaceService
        return self:processRobuxPurchase(player, itemId, category)
    else
        return false, "Invalid payment method"
    end
    
    -- Add item to player's inventory
    self:grantItem(player, itemId, category)
    
    -- Record purchase
    table.insert(playerData.purchaseHistory, {
        itemId = itemId,
        category = category,
        price = price,
        paymentMethod = paymentMethod,
        timestamp = tick()
    })
    
    -- Sync with client
    self:syncPlayerData(player)
    
    print("[ComprehensiveShopSystem]", player.Name, "purchased", item.Name, "for", paymentMethod)
    return true, "Purchase successful"
end

function ComprehensiveShopSystem:grantItem(player, itemId, category)
    local playerData = playerShopData[player.UserId]
    if not playerData then return false end
    
    local item = SHOP_CATALOG[category][itemId]
    if not item then return false end
    
    -- Add to appropriate inventory category
    local inventoryCategory = category:lower():gsub("s$", "s")
    
    if not playerData.owned[inventoryCategory] then
        playerData.owned[inventoryCategory] = {}
    end
    
    -- Handle consumables differently (can have multiples)
    if category == SHOP_CATEGORIES.CONSUMABLES then
        if not playerData.owned.consumables[itemId] then
            playerData.owned.consumables[itemId] = 0
        end
        playerData.owned.consumables[itemId] = playerData.owned.consumables[itemId] + 1
    else
        -- Regular items (weapons, attachments, etc.)
        table.insert(playerData.owned[inventoryCategory], itemId)
    end
    
    -- Apply special effects for certain items
    if item.Type == "Booster" then
        self:activateBooster(player, item)
    end
    
    print("[ComprehensiveShopSystem] Granted", item.Name, "to", player.Name)
    return true
end

function ComprehensiveShopSystem:activateBooster(player, boosterItem)
    local playerData = playerShopData[player.UserId]
    if not playerData then return end
    
    local effects = boosterItem.Effects
    local duration = effects.Duration or 3600 -- 1 hour default
    local endTime = tick() + duration
    
    if effects.CreditsMultiplier then
        playerData.boosters.credits = {
            active = true,
            endTime = endTime,
            multiplier = effects.CreditsMultiplier
        }
    end
    
    if effects.XPMultiplier then
        playerData.boosters.xp = {
            active = true,
            endTime = endTime,
            multiplier = effects.XPMultiplier
        }
    end
    
    print("[ComprehensiveShopSystem] Activated", boosterItem.Name, "for", player.Name)
end

function ComprehensiveShopSystem:processRobuxPurchase(player, itemId, category)
    local item = SHOP_CATALOG[category][itemId]
    if not item or item.Price.Robux <= 0 then return false end
    
    -- Create developer product for the purchase
    local productId = self:getProductId(itemId, category)
    if not productId then return false, "Product not configured" end
    
    -- Prompt purchase
    local success, errorMessage = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productId)
    end)
    
    if success then
        return true, "Purchase prompted"
    else
        return false, "Failed to prompt purchase: " .. tostring(errorMessage)
    end
end

function ComprehensiveShopSystem:getProductId(itemId, category)
    -- This would map items to actual Roblox developer product IDs
    -- For demo purposes, returning placeholder IDs
    local productMap = {
        ["CreditsBooster"] = 123456789,
        ["XPBooster"] = 123456790,
        ["PremiumPass"] = 123456791,
        ["VIPStatus"] = 123456792
    }
    
    return productMap[itemId]
end

function ComprehensiveShopSystem:addToCart(player, itemId, category, quantity)
    local playerData = playerShopData[player.UserId]
    if not playerData then return false end
    
    quantity = quantity or 1
    
    local cartItem = {
        itemId = itemId,
        category = category,
        quantity = quantity,
        addedTime = tick()
    }
    
    table.insert(playerData.cart, cartItem)
    
    -- Sync with client
    self:syncPlayerData(player)
    return true
end

function ComprehensiveShopSystem:removeFromCart(player, cartIndex)
    local playerData = playerShopData[player.UserId]
    if not playerData or not playerData.cart[cartIndex] then return false end
    
    table.remove(playerData.cart, cartIndex)
    
    -- Sync with client
    self:syncPlayerData(player)
    return true
end

function ComprehensiveShopSystem:purchaseCart(player, paymentMethod)
    local playerData = playerShopData[player.UserId]
    if not playerData or #playerData.cart == 0 then return false, "Empty cart" end
    
    local totalCost = {Credits = 0, XP = 0, Robux = 0}
    local purchaseableItems = {}
    
    -- Calculate total cost and validate items
    for _, cartItem in pairs(playerData.cart) do
        local item = SHOP_CATALOG[cartItem.category] and SHOP_CATALOG[cartItem.category][cartItem.itemId]
        if item then
            local canPurchase, reason = self:canPurchaseItem(player, cartItem.itemId, cartItem.category)
            if canPurchase then
                totalCost.Credits = totalCost.Credits + (item.Price.Credits * cartItem.quantity)
                totalCost.XP = totalCost.XP + (item.Price.XP * cartItem.quantity)
                totalCost.Robux = totalCost.Robux + (item.Price.Robux * cartItem.quantity)
                table.insert(purchaseableItems, cartItem)
            end
        end
    end
    
    -- Check if player can afford total
    if paymentMethod == "credits" and playerData.credits < totalCost.Credits then
        return false, "Insufficient credits for cart"
    end
    
    if paymentMethod == "xp" and playerData.xp < totalCost.XP then
        return false, "Insufficient XP for cart"
    end
    
    -- Process purchases
    local purchasedItems = {}
    for _, cartItem in pairs(purchaseableItems) do
        local success, message = self:purchaseItem(player, cartItem.itemId, cartItem.category, paymentMethod)
        if success then
            table.insert(purchasedItems, cartItem)
        end
    end
    
    -- Clear cart
    playerData.cart = {}
    
    -- Sync with client
    self:syncPlayerData(player)
    
    return true, "Purchased " .. #purchasedItems .. " items"
end

function ComprehensiveShopSystem:setupRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    -- Use centralized RemoteEvents manager
    local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.Modules.RemoteEventsManager)
    
    -- Create shop remote events
    local purchaseItemEvent = RemoteEventsManager.getOrCreateRemoteEvent("PurchaseItem", "Shop item purchasing")
    local addToCartEvent = RemoteEventsManager.getOrCreateRemoteEvent("AddToCart", "Shop cart management")
    
    local getShopDataFunction = Instance.new("RemoteFunction")
    getShopDataFunction.Name = "GetShopData"
    getShopDataFunction.Parent = remoteEvents
    
    -- Handle remote events on server
    if RunService:IsServer() then
        purchaseItemEvent.OnServerEvent:Connect(function(player, itemId, category, paymentMethod)
            local success, message = self:purchaseItem(player, itemId, category, paymentMethod)
            -- Send result back to client
            local resultEvent = RemoteEventsManager.getOrCreateRemoteEvent("PurchaseResult", "Purchase result notifications")
            resultEvent:FireClient(player, success, message, itemId)
        end)
        
        addToCartEvent.OnServerEvent:Connect(function(player, itemId, category, quantity)
            self:addToCart(player, itemId, category, quantity)
        end)
        
        getShopDataFunction.OnServerInvoke = function(player)
            return self:getPlayerData(player), SHOP_CATALOG
        end
    end
end

function ComprehensiveShopSystem:setupPurchaseProcessing()
    -- Handle MarketplaceService developer product purchases
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
        
        -- Map product ID to item
        local itemMapping = {
            [123456789] = {itemId = "CreditsBooster", category = SHOP_CATEGORIES.CONSUMABLES},
            [123456790] = {itemId = "XPBooster", category = SHOP_CATEGORIES.CONSUMABLES},
            [123456791] = {itemId = "PremiumPass", category = SHOP_CATEGORIES.PREMIUM},
            [123456792] = {itemId = "VIPStatus", category = SHOP_CATEGORIES.PREMIUM}
        }
        
        local mapping = itemMapping[receiptInfo.ProductId]
        if mapping then
            self:grantItem(player, mapping.itemId, mapping.category)
            print("[ComprehensiveShopSystem] Processed Robux purchase:", mapping.itemId, "for", player.Name)
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
        
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

function ComprehensiveShopSystem:syncPlayerData(player)
    local remoteEvents = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents")
    local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.Modules.RemoteEventsManager)
    local syncEvent = RemoteEventsManager.getOrCreateRemoteEvent("SyncShopData", "Shop data synchronization")
    
    syncEvent:FireClient(player, playerShopData[player.UserId])
end

function ComprehensiveShopSystem:getDailyDeals()
    -- Generate rotating daily deals
    local dailyDeals = {}
    local dealItems = {
        {category = SHOP_CATEGORIES.WEAPONS, itemId = "M4A1", discount = 0.3},
        {category = SHOP_CATEGORIES.ATTACHMENTS, itemId = "RedDotSight", discount = 0.25},
        {category = SHOP_CATEGORIES.COSMETICS, itemId = "UrbanCamo", discount = 0.4}
    }
    
    -- Use current day to determine deals
    local dayOfYear = math.floor(tick() / 86400) % 365
    math.randomseed(dayOfYear)
    
    for i = 1, 3 do
        local dealIndex = math.random(1, #dealItems)
        table.insert(dailyDeals, dealItems[dealIndex])
        table.remove(dealItems, dealIndex)
    end
    
    return dailyDeals
end

return ComprehensiveShopSystem