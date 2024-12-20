local json = require("json")
local http_utils = require("http_utils")

-- Function to make an RPC request to the Flask server
local function rpcRequest(url, data)
    local jsonData = json.encode(data)
    local response, err = http_utils.httpRequest("POST", jsonData, url)
    if err then
        print("Error: " .. err)
        return nil, err
    elseif response then
        if response.success then
            print("Trade successful. Transaction hash: " .. (response.transaction_hash or ""))
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

-- Function to execute the trade using a smart contract via the Flask server
local function ExecuteTrade(player, itemId)
    -- Prepare the data to be sent to the Flask server
    local tradeData = {
        playerAddress = "0xYourEthereumAddress",  -- Replace with player's Ethereum address
        itemId = itemId
    }

    -- Flask server URL for the trade
    local flask_url = "http://localhost:3000/trade_item"

    -- Make the RPC request to execute the trade
    local result, err = rpcRequest(flask_url, tradeData)
    if result then
        player:SendBroadcastMessage("Trade successful! Transaction hash: " .. (result.transaction_hash or ""))
    else
        player:SendBroadcastMessage("Trade failed. Error: " .. (err or "Unknown error"))
    end
end




-- Function to create a custom window for trading specific items
local function OpenTradeWindow(player)
    -- Clear any previous gossip menu
    player:GossipClearMenu()

    -- Example item IDs for trading (you can replace these with real item IDs)
    local itemOptions = {
        {itemId = 12345, itemName = "Sword of Power"},
        {itemId = 67890, itemName = "Shield of Valor"},
        {itemId = 54321, itemName = "Ring of Wisdom"}
    }

    -- Add the items to the gossip window
    for _, item in pairs(itemOptions) do
        player:GossipMenuAddItem(0, "Trade " .. item.itemName, 0, item.itemId)
    end

    -- Add an exit option
    player:GossipMenuAddItem(0, "Exit", 0, 0)

    -- Send the gossip window to the player
    player:GossipSendMenu(1, player, 0)  -- Changed this line
end

-- Function to handle the player's item selection from the gossip window
local function OnGossipSelect(event, player, menuId, id, code)
    if id == 0 then
        -- Exit the menu
        player:GossipComplete()
    else
        -- Execute the trade for the selected item
        player:GossipComplete()
        player:SendBroadcastMessage("Executing trade for item ID: " .. id)
        ExecuteTrade(player, id)
    end
end

-- Register a command to open the trade window
RegisterPlayerEvent(42, function(event, player, command)
    if command == "tradeitems" then
        OpenTradeWindow(player)
        return false  -- Prevent the command from being processed further
    end
end)

-- Register the gossip event handler for item selection
--RegisterPlayerGossipEvent(2, OnGossipSelect)
