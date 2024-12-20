local json = require("json")
local http_utils = require("http_utils")

local PLAYER_EVENT_ON_MONEY_CHANGE = 14  -- Assuming event ID 14 is for money change
local playerGold = {}  -- Table to keep track of each player's gold amount
local TAX_RATE = 5  -- 5% tax rate, should match the contract's TAX_RATE
local TOKEN_DECIMALS = 1000000000000000000  -- 10^18, for 18 decimal places
local COPPER_TO_TOKEN_FACTOR = TOKEN_DECIMALS / 10000  -- Adjusted to handle copper units

-- Add these utility functions at the top
local function stringToNumber(str)
    -- Remove scientific notation
    local num = string.format("%.0f", tonumber(str))
    return tonumber(num)
end

-- Convert tokens (with 18 decimals) to WoW copper
local function tokensToCopper(tokens)
    if type(tokens) == "string" then
        tokens = stringToNumber(tokens)
    end
    -- 1 copper = 10^14 token units (since tokens have 18 decimals and we want 4 decimals for copper)
    return math.floor(tokens / COPPER_TO_TOKEN_FACTOR)
end

-- Convert WoW copper to tokens (with 18 decimals)
local function copperToTokens(copper)
    -- Ensure copper is an integer
    copper = math.floor(copper)
    -- Convert to token units (multiply by 10^14)
    return copper * COPPER_TO_TOKEN_FACTOR
end

-- Function to make RPC request to Flask server
local function rpcRequest(url, data)
    local jsonData = json.encode(data)
    
    local response, err = http_utils.httpRequest("POST", jsonData, url)
    if err then
        print("Error: " .. err)
        return nil, err
    elseif response then
        if response.success then
            print("Transaction successful. Hash: " .. (response.transaction_hash or ""))
            return response, nil
        else
            print("Error: " .. (response.error or "Unknown error"))
            return nil, response.error
        end
    else
        print("No response received")
        return nil, "No response"
    end
end

-- Function to get player's token balance
local function getTokenBalance(address)
    local url = string.format("http://localhost:3000/balance?address=%s", address)
    local response, err = http_utils.httpRequest("GET", nil, url)
    if err then
        print("Error getting balance: " .. err)
        return 0
    elseif response then
        if response.success then
            return tonumber(response.balance) or 0
        else
            print("Error getting balance: " .. (response.error or "Unknown error"))
            return 0
        end
    else
        print("No response received when getting balance")
        return 0
    end
end

-- Function to get map owner
local function getMapOwner(mapId)
    local url = string.format("http://localhost:3000/get_map_owner?mapId=%s", mapId)
    local response, err = http_utils.httpRequest("GET", nil, url)
    if err then
        print("Error getting map owner: " .. err)
        return nil
    elseif response then
        if response.success then
            return response.owner
        else
            print("Error getting map owner: " .. (response.error or "Unknown error"))
            return nil
        end
    else
        print("No response received when getting map owner")
        return nil
    end
end

-- Add these helper functions at the top with other utility functions
local function copperToGoldStr(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copper = copper % 100
    return string.format("%dg %ds %dc", gold, silver, copper)
end

-- Function to handle the gold change event
local function OnGoldChange(event, player, amount)
    if not player or not amount then
        player:SendBroadcastMessage("Error: Player or amount is nil")
        return
    end

    local playerGUID = player:GetGUIDLow()
    local oldGold = player:GetCoinage()
    local goldDifference = amount
    local newGold = oldGold + amount
    local playerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"  -- Player's Ethereum address
    local playerAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    local currentTokenBalance = stringToNumber(getTokenBalance(playerAddress))
    local mapOwner = getMapOwner(player:GetAreaId())
    local taxAmount = math.floor(goldDifference * TAX_RATE / 100)

    player:SendBroadcastMessage("Old Money: " .. copperToGoldStr(oldGold))
    player:SendBroadcastMessage("New Money: " .. copperToGoldStr(newGold))
    player:SendBroadcastMessage("Money Difference: " .. copperToGoldStr(goldDifference))
    player:SendBroadcastMessage("Current Token Balance: " .. currentTokenBalance)
    player:SendBroadcastMessage("Map Owner: " .. tostring(mapOwner))

    if goldDifference == 0 then
        player:SendBroadcastMessage("No change in money amount.")
        return
    end

    local flask_url = "http://localhost:3000"
    local mapId = player:GetAreaId()

    local currentGold = tokensToCopper(currentTokenBalance)
    if oldGold ~= currentGold then
        player:SendBroadcastMessage("Money and token balance do not match. Adjusting...")
        player:SendBroadcastMessage("Current Token Balance: " .. copperToGoldStr(currentGold))
        player:SendBroadcastMessage("Old Money: " .. copperToGoldStr(oldGold))
        player:SetCoinage(currentGold)
        player:SendBroadcastMessage("Money adjusted to match token balance: " .. copperToGoldStr(currentGold))
    end

    if goldDifference > 0 then
        player:SendBroadcastMessage("Minting tokens...")
        local tokenAmount = copperToTokens(goldDifference)
        local data = {
            to = playerAddress,
            amount = string.format("%.0f", tokenAmount),
            mapId = tostring(mapId)
        }
        local result, err = rpcRequest(flask_url .. "/mint", data)
        if result then
            local netAmount = goldDifference - taxAmount
            player:SendBroadcastMessage("Gross Amount: " .. copperToGoldStr(goldDifference))
            player:SendBroadcastMessage("Tax Amount: " .. copperToGoldStr(taxAmount))
            player:SendBroadcastMessage("Net Amount: " .. copperToGoldStr(netAmount))
            
            local expectedTokenBalance = currentTokenBalance + copperToTokens(netAmount)
            player:SendBroadcastMessage("Expected token balance: " .. string.format("%.0f", expectedTokenBalance))
            
            local newTokenBalance = stringToNumber(getTokenBalance(playerAddress))
            player:SendBroadcastMessage("Actual token balance: " .. string.format("%.0f", newTokenBalance))
            
            local expectedCopper = tokensToCopper(expectedTokenBalance)
            local actualCopper = tokensToCopper(newTokenBalance)
            
            if expectedCopper ~= actualCopper then
                player:SendBroadcastMessage("Warning: Money balance mismatch. Expected: " .. copperToGoldStr(expectedCopper) .. 
                      ", Actual: " .. copperToGoldStr(actualCopper))
            end
            
            player:SetCoinage(actualCopper)
            player:SendBroadcastMessage("Adjusted money after tax: " .. copperToGoldStr(actualCopper))
            player:SendBroadcastMessage(string.format("You gained %s. Tax paid: %s.", 
                copperToGoldStr(netAmount), 
                copperToGoldStr(taxAmount)))
            player:SendBroadcastMessage(string.format("Map Owner: %s", mapOwner or "None"))
        else
            player:SetCoinage(currentGold)
            player:SendBroadcastMessage("Minting failed, money change reverted")
            player:SendBroadcastMessage("Failed to process money gain. Please contact an administrator.")
        end
    elseif goldDifference < 0 then
        player:SendBroadcastMessage("Burning tokens...")
        local burnAmount = math.abs(goldDifference)
        local tokenBurnAmount = copperToTokens(burnAmount)
        
        if currentTokenBalance < tokenBurnAmount then
            player:SendBroadcastMessage("Insufficient token balance. Cannot burn tokens.")
            player:SetCoinage(currentGold)
            player:SendBroadcastMessage("Money adjusted to match token balance: " .. copperToGoldStr(currentGold))
            return
        end
        
        local data = {
            from = playerAddress,
            amount = string.format("%.0f", tokenBurnAmount),
            mapId = tostring(mapId)
        }
        local result, err = rpcRequest(flask_url .. "/burn", data)
        if result then
            local newTokenBalance = stringToNumber(getTokenBalance(playerAddress))
            local newCopper = tokensToCopper(newTokenBalance)
            player:SetCoinage(newCopper)
            player:SendBroadcastMessage("Adjusted money after burning: " .. copperToGoldStr(newCopper))
            player:SendBroadcastMessage(string.format("You lost %s.", 
                copperToGoldStr(burnAmount)))
        else
            player:SetCoinage(currentGold)
            player:SendBroadcastMessage("Burning failed, money change reverted")
            player:SendBroadcastMessage("Failed to process money loss. Please contact an administrator.")
        end
    end

    playerGold[playerGUID] = player:GetCoinage()
    player:SendBroadcastMessage("Current Money: " .. copperToGoldStr(player:GetCoinage()))
    player:SetCoinage(player:GetCoinage() - (goldDifference + taxAmount))
    player:SendBroadcastMessage("Current Money after change: " .. copperToGoldStr(player:GetCoinage()))
end

-- Register the event handler for when a player's gold amount changes
RegisterPlayerEvent(PLAYER_EVENT_ON_MONEY_CHANGE, OnGoldChange)
