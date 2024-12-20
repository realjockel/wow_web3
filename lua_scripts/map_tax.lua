local http_utils = require("http_utils")
local json = require("json")

-- Function to get zone or area name by its ID
local function GetZoneOrAreaNameById(id)
    local result = WorldDBQuery("SELECT AreaName_Lang_enUS, ParentAreaID FROM areatable_dbc WHERE ID = " .. id)
    if result then
        local name = result:GetString(0)
        local parentAreaId = result:GetInt32(1)
        return name, parentAreaId
    else
        return "Unknown Zone/Area", 0
    end
end

-- Function to get map owner
local function getMapOwner(mapId)
    local url = string.format("http://localhost:3000/get_map_owner?mapId=%s", mapId)
    local response, err = http_utils.httpRequest("GET", nil, url)
    if err then
        print("Error getting map owner: " .. err)
        return "Unknown"
    elseif response then
        if response.success then
            return response.owner
        else
            print("Error getting map owner: " .. (response.error or "Unknown error"))
            return "Unknown"
        end
    else
        print("No response received when getting map owner")
        return "Unknown"
    end
end

-- Register command to print player's map, zone, and area information, including parent zone and map owner
RegisterPlayerEvent(42, function(event, player, command)
    -- Check if the entered command is 'location'
    if command == "location" then
        -- Get player's map, zone, and area IDs
        local mapId = player:GetMapId()
        local zoneId = player:GetZoneId()
        local areaId = player:GetAreaId()

        -- Get player's X, Y, Z coordinates
        local x, y, z = player:GetX(), player:GetY(), player:GetZ()

        -- Retrieve zone and area names from the database
        local zoneName, zoneParentId = GetZoneOrAreaNameById(zoneId)
        local areaName, areaParentId = GetZoneOrAreaNameById(areaId)

        -- If the area has a parent, fetch the parent zone name
        local parentZoneName = nil
        if areaParentId > 0 then
            parentZoneName = GetZoneOrAreaNameById(areaParentId)
        end

        -- Get the map owner
        local mapOwner = getMapOwner(areaId)

        -- Send a message to the player with their current map, zone, and area information
        player:SendBroadcastMessage("You are in Map ID: " .. mapId)
        player:SendBroadcastMessage("Zone ID: " .. zoneId .. " (" .. zoneName .. ")")
        player:SendBroadcastMessage("Area ID: " .. areaId .. " (" .. areaName .. ")")

        -- If the area has a parent area/zone, display that information
        if parentZoneName then
            player:SendBroadcastMessage("Parent Zone ID: " .. areaParentId .. " (" .. parentZoneName .. ")")
        end

        player:SendBroadcastMessage(string.format("Coordinates: X = %.2f, Y = %.2f, Z = %.2f", x, y, z))
        player:SendBroadcastMessage("Map Owner: " .. mapOwner)

        -- Optionally print the same information to the server console
        print("Player " .. player:GetName() .. " is in Map ID: " .. mapId .. ", Zone ID: " .. zoneId .. " (" .. zoneName .. ")")
        print("Area ID: " .. areaId .. " (" .. areaName .. ")")
        if parentZoneName then
            print("Parent Zone ID: " .. areaParentId .. " (" .. parentZoneName .. ")")
        end
        print(string.format("Coordinates: X = %.2f, Y = %.2f, Z = %.2f", x, y, z))
        print("Map Owner: " .. mapOwner)

        -- Return false to stop further command processing
        return false
    end
end)
