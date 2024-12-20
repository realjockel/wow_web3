local http_utils = require("http_utils")
local json = require("json")
local os = require("os")
-- Function to get the player's wallet address from the database
local function GetWalletAddressForAccount(accountId)
    local query = CharDBQuery(string.format("SELECT wallet_address FROM account_wallets WHERE account_id = %d", accountId))
    if query then
        return query:GetString(0)
    end
    return nil
end
-- Function to make an RPC request to the Flask server
local function rpcRequest(url, data)
    local jsonData = json.encode(data)
    local response, err = http_utils.httpRequest("POST", jsonData, url)
    if err then
        print("Error: " .. err)
        return nil, err
    elseif response then
        if response.success then
            print("NFT minting successful. Transaction hash: " .. (response.transaction_hash or ""))
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

-- Function to get the player's inventory from the database, including equipped items
local function GetPlayerInventory(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT item, slot FROM character_inventory WHERE guid = " .. guid)
    
    local inventory = {}
    if query then
        repeat
            local itemGUID = query:GetUInt32(0)  -- item column (GUID of the item)
            local slot = query:GetUInt32(1)      -- slot column
            -- You might need to do an additional query to get the actual item ID from the item GUID
            local itemQuery = CharDBQuery("SELECT itemEntry FROM item_instance WHERE guid = " .. itemGUID)
            local itemID = itemQuery and itemQuery:GetUInt32(0) or 0
            table.insert(inventory, {itemID = itemID, slot = slot, equipped = (slot >= 0 and slot <= 18)})
        until not query:NextRow()
    end
    return inventory
end

-- Function to get the player's reputation from the database
local function GetPlayerReputation(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT faction, standing FROM character_reputation WHERE guid = " .. guid)
    
    local reputation = {}
    if query then
        repeat
            local factionID = query:GetUInt32(0)  -- faction column
            local standing = query:GetInt32(1)    -- standing column
            table.insert(reputation, {factionID = factionID, standing = standing})
        until not query:NextRow()
    end
    return reputation
end

-- Function to get player's achievements
local function GetPlayerAchievements(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT achievement FROM character_achievement WHERE guid = " .. guid)

    local achievements = {}
    if query then
        repeat
            local achievementID = query:GetUInt32(0)
            table.insert(achievements, achievementID)
        until not query:NextRow()
    end
    return achievements
end

-- Function to get player's auras
local function GetPlayerAuras(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT spell, duration FROM character_aura WHERE guid = " .. guid)

    local auras = {}
    if query then
        repeat
            local spellID = query:GetUInt32(0)
            local duration = query:GetInt32(1)
            table.insert(auras, {spellID = spellID, duration = duration})
        until not query:NextRow()
    end
    return auras
end


-- Function to get player's arena stats
local function GetPlayerArenaStats(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT arenaTeamId, personalRating FROM arena_team_member WHERE guid = " .. guid)

    local arenaStats = {}
    if query then
        repeat
            local teamID = query:GetUInt32(0)
            local rating = query:GetInt32(1)
            table.insert(arenaStats, {teamID = teamID, rating = rating})
        until not query:NextRow()
    end
    return arenaStats
end

-- Function to get player's glyphs
local function GetPlayerGlyphs(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT slot, glyph FROM character_glyphs WHERE guid = " .. guid)

    local glyphs = {}
    if query then
        repeat
            local slot = query:GetUInt32(0)
            local glyphID = query:GetUInt32(1)
            table.insert(glyphs, {slot = slot, glyphID = glyphID})
        until not query:NextRow()
    end
    return glyphs
end

-- Function to get player's homebind information
local function GetPlayerHomebind(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT mapId, zoneId, posX, posY, posZ FROM character_homebind WHERE guid = " .. guid)

    local homebind = {}
    if query then
        homebind = {
            mapId = query:GetUInt32(0),
            zoneId = query:GetUInt32(1),
            x = query:GetFloat(2),
            y = query:GetFloat(3),
            z = query:GetFloat(4)
        }
    end
    return homebind
end

-- Function to get player's quest statuses
local function GetPlayerQuestStatuses(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT quest, status FROM character_queststatus WHERE guid = " .. guid)

    local questStatuses = {}
    if query then
        repeat
            local questID = query:GetUInt32(0)
            local status = query:GetUInt32(1)
            table.insert(questStatuses, {questID = questID, status = status})
        until not query:NextRow()
    end
    return questStatuses
end

-- Function to get player's skills
local function GetPlayerSkills(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT skill, value, max FROM character_skills WHERE guid = " .. guid)

    local skills = {}
    if query then
        repeat
            local skillID = query:GetUInt32(0)
            local value = query:GetUInt32(1)
            local max = query:GetUInt32(2)
            table.insert(skills, {skillID = skillID, value = value, max = max})
        until not query:NextRow()
    end
    return skills
end

-- Function to get player's spell information
local function GetPlayerSpells(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT spell FROM character_spell WHERE guid = " .. guid)

    local spells = {}
    if query then
        repeat
            local spellID = query:GetUInt32(0)
            table.insert(spells, spellID)
        until not query:NextRow()
    end
    return spells
end

-- Function to save the character data as a JSON file
local function SaveCharacterAsJSON(player)
    if not player then
        print("Player is nil")
        return
    end

    local accountId = player:GetAccountId()  -- Add this line

    -- Get character details
    local playerName = player:GetName()
    local playerLevel = player:GetLevel()
    local playerClass = player:GetClass()
    local playerRace = player:GetRace()
    local mapId = player:GetMapId()
    local zoneId = player:GetZoneId()
    local areaId = player:GetAreaId()

    -- Get player's X, Y, Z coordinates
    local x, y, z = player:GetX(), player:GetY(), player:GetZ()

    -- Get all additional data
    local inventory = GetPlayerInventory(player)
    local reputation = GetPlayerReputation(player)
    local achievements = GetPlayerAchievements(player)
    local arenaStats = GetPlayerArenaStats(player)
    --local glyphs = GetPlayerGlyphs(player)
    local homebind = GetPlayerHomebind(player)
    local questStatuses = GetPlayerQuestStatuses(player)
    local skills = GetPlayerSkills(player)
    local spells = GetPlayerSpells(player)

    -- Assemble the character data into a JSON-compatible table
    local characterData = {
        name = playerName,
        level = playerLevel,
        class = playerClass,
        race = playerRace,
        mapId = mapId,
        zoneId = zoneId,
        areaId = areaId,
        coordinates = {x = x, y = y, z = z},
        inventory = inventory,
        reputation = reputation,
        achievements = achievements,
        arenaStats = arenaStats,
        glyphs = glyphs,
        homebind = homebind,
        questStatuses = questStatuses,
        skills = skills,
        spells = spells
    }

    -- Convert the data to JSON
    local jsonData = json.encode(characterData)

    -- Create a filename with timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("character_%s_%s.json", playerName, timestamp)

    -- Save the JSON data to a local file
    local file = io.open(filename, "w")
    if file then
        file:write(jsonData)
        file:close()
        player:SendBroadcastMessage("Character data has been saved locally to " .. filename)
    else
        player:SendBroadcastMessage("Failed to save character data locally")
    end

    -- Check if the player already has an NFT
    local tokenId = GetPlayerNFTTokenId(player)

    local apiEndpoint
    local apiData

    local walletAddress = GetWalletAddressForAccount(accountId)
    if not walletAddress then
        player:SendBroadcastMessage("No wallet address found. Please set your wallet using the !setwallet command.")
        return
    end

    if tokenId and tokenId ~= 0 then
        -- Update existing character NFT
        apiEndpoint = "http://localhost:3000/update_character"
        apiData = {
            tokenId = tokenId,
            level = playerLevel,
            mapId = mapId,
            zoneId = zoneId,
            areaId = areaId,
            x = x,
            y = y,
            z = z,
            inventory = json.encode(inventory),
            reputation = json.encode(reputation),
            achievements = json.encode(achievements),
            arenaStats = json.encode(arenaStats),
            glyphs = json.encode(glyphs),
            homebind = json.encode(homebind),
            questStatuses = json.encode(questStatuses),
            skills = json.encode(skills),
            spells = json.encode(spells)
        }
    else
        -- Mint new character NFT
        apiEndpoint = "http://localhost:3000/mint_character"
        apiData = {
            playerAddress = walletAddress,
            name = playerName,
            level = playerLevel,
            class = playerClass,
            race = playerRace,
            mapId = mapId,
            zoneId = zoneId,
            areaId = areaId,
            x = x,
            y = y,
            z = z
        }
    end

    -- Make the API call to save data on-chain
    local apiJsonData = json.encode(apiData)
    local response, err = http_utils.httpRequest("POST", apiJsonData, apiEndpoint)

    if err then
        player:SendBroadcastMessage("Error saving character data on-chain: " .. err)
    elseif response and response.success then
        if tokenId and tokenId ~= 0 then
            player:SendBroadcastMessage("Character NFT updated successfully on-chain")
        else
            tokenId = response.token_id
            player:SendBroadcastMessage("New character NFT minted successfully on-chain. Token ID: " .. tokenId)
        end
    else
        player:SendBroadcastMessage("Failed to save character data on-chain: " .. (response.error or "Unknown error"))
    end
end

-- Register the command to save character data
RegisterPlayerEvent(42, function(event, player, command)
    if command == "savechar" then
        SaveCharacterAsJSON(player)
        return false  -- Prevent the command from being processed further
    end
end)

function MintCharacterNFT(player, characterData)
    local accountId = player:GetAccountId()
    local walletAddress = GetWalletAddressForAccount(accountId)
    if not walletAddress then
        print("No wallet address found for account ID: " .. accountId)
        return nil
    end

    local data = {
        playerAddress = walletAddress,
        name = characterData.name,
        level = characterData.level,
        class = characterData.class,
        race = characterData.race,
        mapId = characterData.mapId,
        zoneId = characterData.zoneId,
        areaId = characterData.areaId,
        x = math.floor(characterData.coordinates.x),  -- Convert to integer
        y = math.floor(characterData.coordinates.y),  -- Convert to integer
        z = math.floor(characterData.coordinates.z)   -- Convert to integer
    }
    
    local jsonData = json.encode(data)
    local response, err = http_utils.httpRequest("POST", jsonData, "http://localhost:3000/mint_character")
    
    if err then
        print("Error minting character NFT: " .. err)
        return nil
    elseif response and response.success then
        print("Character NFT minted successfully. Token ID: " .. response.token_id)
        return response.token_id
    else
        print("Failed to mint character NFT: " .. (response.error or "Unknown error"))
        return nil
    end
end

function UpdateCharacterNFT(tokenId, characterData)
    local data = {
        tokenId = tokenId,
        level = characterData.level,
        mapId = characterData.mapId,
        zoneId = characterData.zoneId,
        areaId = characterData.areaId,
        x = characterData.coordinates.x,
        y = characterData.coordinates.y,
        z = characterData.coordinates.z,
        inventory = characterData.inventory,
        reputation = characterData.reputation,
        achievements = characterData.achievements,
        arenaStats = characterData.arenaStats,
        glyphs = characterData.glyphs,
        homebind = characterData.homebind,
        questStatuses = characterData.questStatuses,
        skills = characterData.skills,
        spells = characterData.spells
    }
    
    local jsonData = json.encode(data)
    local response, err = http_utils.httpRequest("POST", jsonData, "http://localhost:3000/update_character")
    
    if err then
        print("Error updating character NFT: " .. err)
    elseif response and response.success then
        print("Character NFT updated successfully")
    else
        print("Failed to update character NFT")
    end
end



-- Function to get the player's NFT token ID
function GetPlayerNFTTokenId(player)
    local accountId = player:GetAccountId()
    local walletAddress = GetWalletAddressForAccount(accountId)
    if not walletAddress then
        print("No wallet address found for account ID: " .. accountId)
        return nil
    end
    
    local response, err = http_utils.httpRequest("GET", nil, "http://localhost:3000/get_player_token_id?playerAddress=" .. walletAddress)
    
    if err then
        print("Error getting player NFT token ID: " .. err)
        return nil
    elseif response and response.success then
        return response.tokenId or 0  -- Return 0 if tokenId is nil
    else
        print("Failed to get player NFT token ID")
        return nil
    end
end

-- We don't need SetPlayerNFTTokenId anymore, as the token ID is now stored in the smart contract







