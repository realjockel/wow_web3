-- Requires HTTP libraries like luasocket to make HTTP requests
local http_utils = require("http_utils")
local json = require("json")

-- Create the guild_daos table if it doesn't exist
CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `guild_daos` (
        `guild_name` VARCHAR(255) NOT NULL,
        `dao_address` VARCHAR(255) NOT NULL,
        `token_address` VARCHAR(255) NOT NULL,
        PRIMARY KEY (`guild_name`)
    );
]])

print("Guild DAOs table created (if it didn't exist).")

-- Function to get wallet address for a player
local function GetWalletAddressForPlayer(player)
    if not player then
        print("Error: Player object is nil")
        return nil
    end

    local guid = player:GetGUIDLow()
    if not guid then
        print("Error: Unable to get player GUID")
        return nil
    end

    local query = CharDBQuery(string.format("SELECT aw.wallet_address FROM account_wallets aw JOIN characters c ON c.account = aw.account_id WHERE c.guid = %d", guid))
    if query then
        return query:GetString(0)
    else
        print(string.format("No wallet address found for player with GUID %d", guid))
        return nil
    end
end

-- Event when a new guild is created
local function OnGuildCreate(event, guild, leader, name)
    local wallet_address = GetWalletAddressForPlayer(leader)
    if not wallet_address then
        leader:SendBroadcastMessage("Error: Could not find your wallet address.")
        return
    end

    -- Prepare the request body for the Flask backend to create the DAO
    local requestBody = {
        guildName = name,
        leaderWallet = wallet_address,
        tokenAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3", -- Replace with actual token address
        votingDelay = 1, -- Replace with desired value (e.g., 1 day)
        votingPeriod = 7, -- Replace with desired value (e.g., 7 days)
        proposalThreshold = "100000000000000000000", -- Replace with desired value (e.g., 100 tokens)
        quorumPercentage = 4 -- Replace with desired value (e.g., 4%)
    }

    -- Send the request to the Flask backend to create the DAO
    local response, err = http_utils.httpRequest("POST", json.encode(requestBody), "http://localhost:3000/api/create_dao")

    if err then
        print("Error creating DAO: " .. err)
        leader:SendBroadcastMessage("Error creating DAO for guild: " .. name)
    elseif response and response.status == "success" then
        print("DAO created successfully for guild: " .. name)
        leader:SendBroadcastMessage("DAO successfully created for guild: " .. name)
        
        -- Store DAO information in the database
        CharDBExecute(string.format("INSERT INTO guild_daos (guild_name, dao_address, token_address) VALUES ('%s', '%s', '%s')",
            name, response.contractAddress, requestBody.tokenAddress))
    else
        print("Failed to create DAO: " .. (response.message or "Unknown error"))
        leader:SendBroadcastMessage("Error creating DAO for guild: " .. name)
    end
end

-- Register the function to the event where a guild is created
RegisterGuildEvent(5, OnGuildCreate) -- GUILD_EVENT_ON_CREATE is 5
