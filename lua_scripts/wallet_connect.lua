-- Create a table to associate accounts with Ethereum wallet addresses and private keys
CharDBQuery('CREATE TABLE IF NOT EXISTS `account_wallets` (' ..
            '`account_id` INT NOT NULL, ' ..
            '`wallet_address` VARCHAR(255) NOT NULL, ' ..
            '`private_key` VARCHAR(255) NOT NULL, ' ..
            'PRIMARY KEY (`account_id`));')

print("Account wallets table created (if it didn't exist).")

local PLAYER_EVENT_ON_COMMAND = 42  -- Event ID for listening to player commands

-- Register command to associate wallet with account
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, function(event, player, command)
    -- Check if the entered command starts with "!setwallet"
    if command:sub(1, 10) == "!setwallet" then
        -- Split the command into parts: !setwallet <wallet_address> <private_key>
        local params = {}
        for param in command:gmatch("%S+") do table.insert(params, param) end
        
        -- Check if the player provided both wallet address and private key
        if #params < 3 then
            player:SendBroadcastMessage("Usage: !setwallet <wallet_address> <private_key>")
            return false
        end

        local wallet_address = params[2]
        local private_key = params[3]

        -- Get the player's account ID
        local account_id = player:GetAccountId()

        -- Store the wallet address and private key in the database
        CharDBExecute(string.format([[
            REPLACE INTO `account_wallets` (account_id, wallet_address, private_key)
            VALUES (%d, '%s', '%s')
        ]], account_id, wallet_address, private_key))

        -- Send confirmation to the player
        player:SendBroadcastMessage("Your wallet has been successfully associated with your account.")

        -- Print debug information to the server console (optional)
        print(string.format("Account ID: %d associated with Wallet: %s", account_id, wallet_address))

        return false  -- Prevent further command processing
    end
end)