local json = require("json")

local M = {}

function M.httpRequest(method, params, url)
    local curl_command

    if method:upper() == "GET" then
        curl_command = string.format("curl -s '%s'", url)
    else
        curl_command = string.format(
            "curl -s -X %s -H 'Content-Type: application/json' --data '%s' '%s'",
            method:upper(),
            params,  -- params is already JSON-encoded
            url
        )
    end

    local handle = io.popen(curl_command)
    local result = handle:read("*a")
    local success, exit_type, exit_code = handle:close()

    if not success then
        print("Error: Curl command failed to execute")
        return nil, "Curl execution failed"
    end

    if result == "" then
        print("Error: Empty response received")
        return nil, "Empty response"    
    end

    local success, response = pcall(json.decode, result)
    if not success then
        print("JSON Decode Error: " .. response)
        return nil, "JSON decode error: " .. response
    end

    print(string.format("HTTP Request: %s, Response: %s", curl_command, result))

    return response, nil
end

return M
