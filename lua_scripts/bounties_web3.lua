-- Bounty System Script for Eluna
local BOUNTY_TABLE = {} -- Table to store active bounties (in-memory)
local BOUNTY_COST = 100 -- Minimum bounty cost in WOW tokens
local API_BASE_URL = "http://localhost:3000"  -- Replace with your Flask server URL
local FETCH_INTERVAL = 300 -- Fetch bounties every 5 minutes (300 seconds)
local http_utils = require("http_utils")
local json = require("json")
-- Helper function to interact with the Flask API
local function callAPI(endpoint, method, data)
    local url = API_BASE_URL .. endpoint
    local jsonData = json.encode(data)
    print("Sending request to: " .. url)
    local response, err = http_utils.httpRequest(method, jsonData, url)
    if err then
        print("HTTP Error: " .. err)
        return nil, err
    elseif response then
        if type(response) == "table" then
            print("Response is already a table, no need to decode")
            if response.success then
                return response, nil
            else
                local errorMsg = response.error or "Unknown error"
                print("API Error: " .. errorMsg)
                return nil, errorMsg
            end
        else
            print("Raw response: " .. tostring(response))
            local success, decodedResponse = pcall(json.decode, response)
            if success and decodedResponse then
                if decodedResponse.success then
                    return decodedResponse, nil
                else
                    local errorMsg = decodedResponse.error or "Unknown error"
                    print("API Error: " .. errorMsg)
                    return nil, errorMsg
                end
            else
                print("JSON Decoding Error: " .. tostring(decodedResponse))
                return nil, "JSON decoding failed"
            end
        end
    else
        print("No response received")
        return nil, "No response"
    end
end

-- Function to get the player's wallet address from the database
local function GetWalletAddressForAccount(accountId)
    local query = CharDBQuery(string.format("SELECT wallet_address FROM account_wallets WHERE account_id = %d", accountId))
    if query then
        return query:GetString(0)
    end
    return nil
end

-- Create the active_bounties table if it doesn't exist
CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `active_bounties` (
        `token_id` INT PRIMARY KEY,
        `creator` VARCHAR(42) NOT NULL,
        `target` VARCHAR(42) NOT NULL,
        `amount` BIGINT NOT NULL,
        `claimed` BOOLEAN NOT NULL
    );
]])

print("Active bounties table created (if it didn't exist).")

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

-- Function to save bounties to the database
local function SaveBountiesToDB(bounties)
    -- First, clear existing bounties
    CharDBExecute("DELETE FROM active_bounties")
    
    -- Insert new bounties
    for _, bounty in ipairs(bounties) do
        local query = string.format(
            "INSERT INTO active_bounties (token_id, creator, target, amount, claimed) VALUES (%d, '%s', '%s', %d, %d)",
            bounty.tokenId, bounty.creator, bounty.target, bounty.amount, bounty.claimed and 1 or 0
        )
        CharDBExecute(query)
    end
end

-- Function to fetch bounties from the blockchain
local function FetchBounties()
    local response, err = callAPI("/fetch_bounties", "GET", {})
    if response then
        -- Filter out claimed bounties
        BOUNTY_TABLE = {}
        for _, bounty in ipairs(response.bounties or {}) do
            if not bounty.claimed then
                table.insert(BOUNTY_TABLE, bounty)
            end
        end
        SaveBountiesToDB(BOUNTY_TABLE)
        print("Bounties fetched and saved to DB. Total active bounties: " .. #BOUNTY_TABLE)
    else
        print("Failed to fetch bounties: " .. (err or "Unknown error"))
    end
end



-- Command for setting a bounty: !bounty <player> <amount>
local function SetBounty(player, targetName, amount)
    if amount < BOUNTY_COST then
        player:SendBroadcastMessage("Minimum bounty is " .. BOUNTY_COST .. " WOW tokens.")
        return false
    end

    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        player:SendBroadcastMessage("Target player not found.")
        return false
    end

    local creatorWallet = GetWalletAddressForAccount(player:GetAccountId())
    local targetWallet = GetWalletAddressForAccount(targetPlayer:GetAccountId())

    if not creatorWallet or not targetWallet then
        player:SendBroadcastMessage("Wallet address not found for one of the players.")
        return false
    end

    local currentGold = player:GetCoinage()
    if currentGold < amount then
        player:SendBroadcastMessage("You don't have enough gold to set this bounty.")
        return false
    end

    local response, err = callAPI("/create_bounty", "POST", {
        creator = creatorWallet,
        target = targetWallet,
        amount = amount
    })

    if response then
        -- Convert token amount to game gold (divide by 10^18 and round down)
        local goldAmount = math.floor(amount / 1000000000000000000)
        -- Ensure the amount doesn't exceed the maximum gold limit
        goldAmount = math.min(goldAmount, 4294967295)
        
        -- Deduct the bounty amount from the player's gold
        player:SetCoinage(player:GetCoinage() - goldAmount)
        player:SendBroadcastMessage("Bounty set on " .. targetName .. " for " .. goldAmount .. " gold.")
        player:SendBroadcastMessage("Your new gold balance: " .. player:GetCoinage())
        targetPlayer:SendBroadcastMessage("A bounty has been placed on your head!")
        FetchBounties() -- Refresh bounties after creating a new one
        return true
    else
        player:SendBroadcastMessage("Failed to set bounty: " .. (err or "Unknown error"))
        return false
    end
end

-- Event when a player dies (PvP only)
local function OnPlayerKilled(event, killer, killed)
    if killed:IsPlayer() and killer:IsPlayer() then
        local killerWallet = GetWalletAddressForAccount(killer:GetAccountId())
        local killedWallet = GetWalletAddressForAccount(killed:GetAccountId())

        if not killerWallet or not killedWallet then
            print("Wallet address not found for one of the players.")
            return
        end

        local response, err = callAPI("/claim_bounty", "POST", {
            killer = killerWallet,
            killed = killedWallet
        })

        if response then
            -- Convert token amount to game gold (divide by 10^18 and round down)
            local goldAmount = math.floor(response.amount / 1000000000000000000)
            -- Ensure the amount doesn't exceed the maximum gold limit
            goldAmount = math.min(goldAmount, 4294967295)
            
            -- Update killer's gold balance
            killer:SetCoinage(killer:GetCoinage() + goldAmount)
            
            killer:SendBroadcastMessage("You have claimed a bounty of " .. goldAmount .. " gold!")
            killer:SendBroadcastMessage("Your new gold balance: " .. killer:GetCoinage())
            killed:SendBroadcastMessage("The bounty on your head has been claimed.")
            FetchBounties() -- Refresh bounties after claiming
        else
            print("Failed to claim bounty: " .. (err or "Unknown error"))
        end
    end
end

-- Command handler for the bounty system
local function HandleBountyCommand(event, player, command)
    local args = {}
    for arg in command:gmatch("%S+") do table.insert(args, arg) end
    
    if args[1]:lower() == "bounty" then
        if #args == 1 then
            -- List active bounties
            player:SendBroadcastMessage("Active Bounties:")
            if #BOUNTY_TABLE == 0 then
                player:SendBroadcastMessage("No active bounties at the moment.")
            else
                for _, bounty in ipairs(BOUNTY_TABLE) do
                    player:SendBroadcastMessage(bounty.target .. ": " .. bounty.amount .. " WOW tokens")
                end
            end
        elseif #args == 3 then
            -- Set a bounty
            local targetName = args[2]
            local amount = tonumber(args[3])
            if amount then
                SetBounty(player, targetName, amount)
            else
                player:SendBroadcastMessage("Invalid amount. Usage: .bounty <player_name> <amount>")
            end
        else
            player:SendBroadcastMessage("Usage: .bounty [<player_name> <amount>]")
        end
        return false
    end
    return true
end

-- Function to periodically fetch bounties
local function PeriodicBountyFetch(eventId, delay, repeats)
    FetchBounties()
end

-- Register events
RegisterPlayerEvent(6, OnPlayerKilled) -- Register the player death event
RegisterPlayerEvent(42, HandleBountyCommand) -- Register command "bounty"
CreateLuaEvent(PeriodicBountyFetch, FETCH_INTERVAL * 1000, 0) -- Fetch bounties periodically

-- Initial fetch of bounties
FetchBounties()

print("Bounty system loaded.")



