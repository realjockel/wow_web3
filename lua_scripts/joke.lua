local json = require("json")
local http_utils = require("http_utils")


RegisterPlayerEvent(42, function(event, player, command)
    if command == "joke" then
        local guid = player:GetGUID()

        -- GET request for joke
        local url = "https://api.chucknorris.io/jokes/random"
        local joke_response, error = http_utils.httpRequest("GET", {}, url)
        if joke_response then
            local player = GetPlayerByGUID(guid)
            player:SendBroadcastMessage(joke_response.value)
        else
            print("Failed to get joke: " .. (error or "Unknown error"))
        end

        return false
    end
end)
