-- GuildHouseSeller NPC script with Spawner integration and Phasing
print("Starting Guild House Seller script")
local GuildHouseSeller = {
    entry = 500030,  -- Replace with the Guild House Seller NPC entry ID
}

-- Configuration variables (default values, override in config)
local GuildHouseInnKeeper = 1000000
local GuildHouseBank = 1000000
local GuildHouseMailBox = 500000
local GuildHouseAuctioneer = 500000
local GuildHouseTrainer = 1000000
local GuildHouseVendor = 500000
local GuildHouseObject = 500000
local GuildHousePortal = 500000
local GuildHouseProf = 500000
local GuildHouseSpirit = 100000
local GuildHouseBuyRank = 4

-- Helper function to calculate guild phase based on guild ID
local function GetGuildPhase(guildId)
    return guildId + 10
end

-- Function to load configuration values
local function LoadGuildHouseConfig()
    GuildHouseInnKeeper = 1000000
    GuildHouseBank = 1000000
    GuildHouseMailBox = 500000
    GuildHouseAuctioneer = 500000
    GuildHouseTrainer = 1000000
    GuildHouseVendor = 500000
    GuildHouseObject = 500000
    GuildHousePortal = 500000
    GuildHouseProf = 500000
    GuildHouseSpirit = 100000
    GuildHouseBuyRank = 4
end

-- Function to handle spawning NPCs
local function SpawnNPC(entry, player)
    local guildId = player:GetGuildId()
    local phase = GetGuildPhase(guildId)
    
    print(string.format("Attempting to spawn NPC. Entry: %d, Player: %s, Guild ID: %d, Phase: %d", entry, player:GetName(), guildId, phase))
    
    -- Check if the NPC already exists in the guild house
    local result = WorldDBQuery(string.format("SELECT COUNT(*) FROM creature WHERE id1 = %d AND map = %d AND phaseMask = %d", entry, player:GetMapId(), phase))
    if result then
        local count = result:GetUInt32(0)
        print(string.format("Found %d existing NPCs with entry %d in the guild house.", count, entry))
        if count > 0 then
            player:SendBroadcastMessage("You already have this NPC in your guild house!")
            return
        end
    else
        print("Error querying existing NPCs.")
    end
    
    local posX, posY, posZ, ori
    local result = WorldDBQuery(string.format("SELECT `posX`, `posY`, `posZ`, `orientation` FROM `guild_house_spawns` WHERE `entry`=%d", entry))
    
    if result then
        posX = result:GetFloat(0)
        posY = result:GetFloat(1)
        posZ = result:GetFloat(2)
        ori = result:GetFloat(3)
        print(string.format("Spawn position found. X: %f, Y: %f, Z: %f, Orientation: %f", posX, posY, posZ, ori))
    else
        print(string.format("Failed to find spawn position for NPC entry %d.", entry))
        player:SendBroadcastMessage("Failed to find spawn position for NPC.")
        return
    end
    
    print(string.format("Attempting to spawn NPC with entry %d at position (%f, %f, %f, %f)", entry, posX, posY, posZ, ori))
    local creature = player:SpawnCreature(entry, posX, posY, posZ, ori, 8, 0)
    if creature then
        print(string.format("NPC successfully spawned. GUID: %d", creature:GetGUIDLow()))
        creature:SetPhaseMask(phase, true)
        print(string.format("NPC phase set to: %d", creature:GetPhaseMask()))
        player:SendBroadcastMessage(string.format("NPC (Entry: %d) successfully spawned. If you can't see it, try using the command '.gm vis' to refresh your view.", entry))
    else
        print(string.format("Failed to spawn NPC with entry %d.", entry))
        player:SendBroadcastMessage("Failed to spawn NPC.")
    end
end

-- Function to handle spawning Game Objects
local function SpawnObject(entry, player)
    local guildId = player:GetGuildId()
    local phase = GetGuildPhase(guildId)
    
    print(string.format("Attempting to spawn GameObject. Entry: %d, Player: %s, Guild ID: %d, Phase: %d", entry, player:GetName(), guildId, phase))
    
    -- Check if the object already exists in the guild house
    local result = WorldDBQuery(string.format("SELECT COUNT(*) FROM gameobject WHERE id = %d AND map = %d AND phaseMask = %d", entry, player:GetMapId(), phase))
    if result and result:GetUInt32(0) > 0 then
        print("GameObject already exists in the guild house.")
        player:SendBroadcastMessage("You already have this object in your guild house!")
        return
    end
    
    local posX, posY, posZ, ori
    local result = WorldDBQuery("SELECT `posX`, `posY`, `posZ`, `orientation` FROM `guild_house_spawns` WHERE `entry`="..entry)
    
    if result then
        posX = result:GetFloat(0)
        posY = result:GetFloat(1)
        posZ = result:GetFloat(2)
        ori = result:GetFloat(3)
        print(string.format("Spawn position found. X: %f, Y: %f, Z: %f, Orientation: %f", posX, posY, posZ, ori))
    else
        print("Failed to find spawn position for GameObject.")
        player:SendBroadcastMessage("Failed to find spawn position for GameObject.")
        return
    end
    
    local object = player:SummonGameObject(entry, posX, posY, posZ, ori, 0)
    if object then
        print(string.format("GameObject successfully spawned. GUID: %d", object:GetGUIDLow()))
        object:SetPhaseMask(phase, true)
        player:SendBroadcastMessage("GameObject successfully spawned. If you can't see it, try using the command '.gm vis' to refresh your view.")
    else
        print("Failed to spawn GameObject.")
        player:SendBroadcastMessage("Failed to spawn GameObject.")
    end
end
local function SpawnAll(player, spawnType)
    local guildId = player:GetGuildId()
    local phase = GetGuildPhase(guildId)
    local query
    
    if spawnType == "npc" then
        query = "SELECT entry FROM guild_house_spawns WHERE comment NOT LIKE '%Object%'"
    else
        query = "SELECT entry FROM guild_house_spawns WHERE comment LIKE '%Object%'"
    end
    
    local result = WorldDBQuery(query)
    local spawnCount = 0
    
    if result then
        repeat
            local entry = result:GetUInt32(0)
            if spawnType == "npc" then
                SpawnNPC(entry, player)
            else
                SpawnObject(entry, player)
            end
            spawnCount = spawnCount + 1
        until not result:NextRow()
    end
    
    player:SendBroadcastMessage(string.format("Spawned %d %s(s) in your guild house.", spawnCount, spawnType == "npc" and "NPC" or "object"))
end

-- Function to handle when a player interacts with the Guild House seller NPC
function GuildHouseSeller.OnGossipHello(event, player, creature)
    print("OnGossipHello triggered for player: " .. player:GetName())
    print("Player Guild ID: " .. (player:GetGuildId() or "No Guild"))
    print("Player Phase: " .. player:GetPhaseMask())
    if not player:GetGuild() then
        player:SendBroadcastMessage("You are not a member of a guild.")
        return false
    end

    local guildId = player:GetGuildId()
    local result = CharDBQuery("SELECT id FROM guild_house WHERE guild = "..guildId)
    
    -- If the guild already owns a house
    if result then
        player:GossipMenuAddItem(0, "Teleport to Guild House", 1, 1)
        player:GossipMenuAddItem(0, "Sell Guild House", 1, 3, "Are you sure you want to sell your Guild House?")
        player:GossipMenuAddItem(0, "Spawn NPCs and Objects", 1, 100)
    else
        player:GossipMenuAddItem(0, "Buy Guild House", 1, 2)
    end

    player:GossipMenuAddItem(0, "Close", 1, 4)
    player:GossipSendMenu(1, creature)
end

-- Function to handle player's selection from gossip options
function GuildHouseSeller.OnGossipSelect(event, player, creature, sender, intid, code)
    local guildId = player:GetGuildId()
    local phase = GetGuildPhase(guildId)
    
    if intid == 1 then
        -- Teleport to guild house
        local result = CharDBQuery("SELECT map, positionX, positionY, positionZ, orientation FROM guild_house WHERE guild = "..guildId)
        if result then
            local map = result:GetUInt32(0)
            local posX = result:GetFloat(1)
            local posY = result:GetFloat(2)
            local posZ = result:GetFloat(3)
            local orientation = result:GetFloat(4)
            player:SetPhaseMask(phase, true)  -- Apply the guild-specific phase
            player:Teleport(map, posX, posY, posZ, orientation)
        else
            player:SendBroadcastMessage("Your guild does not own a Guild House.")
        end
        player:GossipComplete()

    elseif intid == 2 then
        -- Buy guild house
        CharDBExecute("INSERT INTO guild_house (guild, map, positionX, positionY, positionZ, orientation, phase) VALUES ("..guildId..", 1, 16222.972, 16267.802, 13.136777, 1.461173, "..phase..")")
        player:ModifyMoney(-10000000)  -- Deduct money
        player:SendBroadcastMessage("You have successfully purchased a Guild House.")
        player:GossipComplete()

    elseif intid == 3 then
        -- Sell guild house
        CharDBExecute("DELETE FROM guild_house WHERE guild = "..guildId)
        player:ModifyMoney(5000000)  -- Refund half the cost
        player:SendBroadcastMessage("You have successfully sold your Guild House.")
        player:GossipComplete()

    elseif intid == 100 then
        -- Open main spawner menu
        ShowSpawnerMenu(player, creature)
        return
    elseif intid == 200 then
        -- Open NPC spawner menu
        ShowSpawnerMenu(player, creature, 1, "npc")
        return
    elseif intid == 201 then
        -- Open Object spawner menu
        ShowSpawnerMenu(player, creature, 1, "object")
        return
    elseif intid == 202 or intid == 204 then
        -- Previous page (NPC or Object)
        local currentPage = player:GetData("SpawnerMenuPage") or 1
        local spawnType = player:GetData("SpawnerMenuType")
        ShowSpawnerMenu(player, creature, math.max(1, currentPage - 1), spawnType)
        return
    elseif intid == 203 or intid == 205 then
        -- Next page (NPC or Object)
        local currentPage = player:GetData("SpawnerMenuPage") or 1
        local spawnType = player:GetData("SpawnerMenuType")
        ShowSpawnerMenu(player, creature, currentPage + 1, spawnType)
        return
    elseif intid == 206 then
        -- Spawn All NPCs
        SpawnAll(player, "npc")
        player:GossipComplete()
        return
    elseif intid == 207 then
        -- Spawn All Objects
        SpawnAll(player, "object")
        player:GossipComplete()
        return
    elseif intid >= 1 then
        -- Handle spawning of NPCs or objects
        local guildId = player:GetGuildId()
        local phase = GetGuildPhase(guildId)
        local playerPhase = player:GetPhaseMask()
        
        print(string.format("Spawn attempt. Player: %s, Guild ID: %d, Calculated Phase: %d, Player's Current Phase: %d, Entry: %d", player:GetName(), guildId, phase, playerPhase, intid))
        
        if playerPhase ~= phase then
            print("Player is not in the correct phase for their guild house.")
            player:SendBroadcastMessage("You are not in your guild house phase. Please teleport to your guild house first.")
            player:GossipComplete()
            return
        end
        
        -- Check if it's an NPC or GameObject
        local result = WorldDBQuery(string.format("SELECT comment FROM guild_house_spawns WHERE entry = %d", intid))
        if result then
            local comment = result:GetString(0)
            local isObject = string.find(comment, "(Object)") ~= nil
            
            if isObject then
                SpawnObject(intid, player)
            else
                SpawnNPC(intid, player)
            end
        else
            print(string.format("Entry %d not found in guild_house_spawns", intid))
            player:SendBroadcastMessage("Failed to spawn: Entry not found.")
        end
        player:GossipComplete()
    elseif intid == 101 then
        -- Go back to main menu
        GuildHouseSeller.OnGossipHello(event, player, creature)
        return
    end

    player:GossipComplete()
end

-- Register Events for the NPC and Player login
print("Registering gossip events for NPC ID: " .. GuildHouseSeller.entry)
RegisterCreatureGossipEvent(GuildHouseSeller.entry, 1, GuildHouseSeller.OnGossipHello)
RegisterCreatureGossipEvent(GuildHouseSeller.entry, 2, GuildHouseSeller.OnGossipSelect)
print("Gossip events registered successfully")

-- Load configuration values when the server starts
LoadGuildHouseConfig()

print("Guild House Seller script loaded successfully")

local ITEMS_PER_PAGE = 10  -- Reduced to accommodate sub-menus

ShowSpawnerMenu = nil  -- Declare it globally

-- Define the ShowSpawnerMenu function globally
function ShowSpawnerMenu(player, creature, page, spawnType)
    player:GossipClearMenu()
    
    if not spawnType then
        -- Main spawner menu
        player:GossipMenuAddItem(0, "Spawn NPCs", 1, 200)
        player:GossipMenuAddItem(0, "Spawn Objects", 1, 201)
        player:GossipMenuAddItem(0, "Spawn All NPCs", 1, 206)
        player:GossipMenuAddItem(0, "Spawn All Objects", 1, 207)
        player:GossipMenuAddItem(0, "Go Back", 1, 101)
        player:GossipSendMenu(1, creature)
        return
    end
    
    local offset = (page - 1) * ITEMS_PER_PAGE
    local query
    if spawnType == "npc" then
        query = string.format("SELECT entry, comment FROM guild_house_spawns WHERE comment NOT LIKE '%%Object%%' ORDER BY id LIMIT %d OFFSET %d", ITEMS_PER_PAGE, offset)
    else
        query = string.format("SELECT entry, comment FROM guild_house_spawns WHERE comment LIKE '%%Object%%' ORDER BY id LIMIT %d OFFSET %d", ITEMS_PER_PAGE, offset)
    end
    
    local result = WorldDBQuery(query)
    
    local itemCount = 0
    if result then
        repeat
            local entry = result:GetUInt32(0)
            local comment = result:GetString(1)
            player:GossipMenuAddItem(0, "Spawn " .. comment, 1, entry)
            itemCount = itemCount + 1
        until not result:NextRow()
    end
    
    -- Navigation buttons
    if page > 1 then
        player:GossipMenuAddItem(0, "Previous Page", 1, spawnType == "npc" and 202 or 204)
    end
    if itemCount == ITEMS_PER_PAGE then
        player:GossipMenuAddItem(0, "Next Page", 1, spawnType == "npc" and 203 or 205)
    end
    
    player:GossipMenuAddItem(0, "Go Back", 1, 100)
    player:GossipSendMenu(1, creature)
    
    -- Store the current page and spawn type in the player's data
    player:SetData("SpawnerMenuPage", page)
    player:SetData("SpawnerMenuType", spawnType)
end


