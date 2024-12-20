-- Bounty System Script for Eluna
local BOUNTY_TABLE = {} -- Table to store active bounties (in-memory)
local BOUNTY_COST = 100 -- Minimum gold required to set a bounty
local COMMAND_COOLDOWN = 10 -- Cooldown in seconds for setting a bounty

-- Helper function to find player by name
local function GetPlayerByName(name)
    for _, player in pairs(GetPlayersInWorld()) do
        if player:GetName() == name then
            return player
        end
    end
    return nil
end

-- Command for setting a bounty: !bounty <player> <gold_amount>
local function SetBounty(player, targetName, goldAmount)
    -- Check if gold amount is valid
    if goldAmount == nil or goldAmount < BOUNTY_COST then
        player:SendBroadcastMessage("You must set a minimum bounty of " .. BOUNTY_COST .. " gold.")
        return false
    end
    
    -- Check if player has enough gold
    if player:GetCoinage() < (goldAmount * 10000) then
        player:SendBroadcastMessage("You do not have enough gold to set this bounty.")
        return false
    end
    
    -- Find the target player
    local targetPlayer = GetPlayerByName(targetName)
    if targetPlayer == nil then
        player:SendBroadcastMessage("Player not found.")
        return false
    end
    
    -- Create the bounty
    BOUNTY_TABLE[targetPlayer:GetGUIDLow()] = {
        bountyAmount = goldAmount,
        bountyCreator = player:GetGUIDLow()
    }
    
    -- Deduct gold from the bounty creator
    player:ModifyMoney(-(goldAmount * 10000)) -- Gold amount in copper

    -- Notify players
    player:SendBroadcastMessage("Bounty set on " .. targetPlayer:GetName() .. " for " .. goldAmount .. " gold.")
    targetPlayer:SendBroadcastMessage("A bounty has been placed on your head!")

    return true
end

-- Event when a player dies (PvP only)
local function OnPlayerKilled(event, killer, killed)
    if killed:IsPlayer() and killer:IsPlayer() then
        local killedGUID = killed:GetGUIDLow()
        
        -- Check if the killed player has a bounty
        if BOUNTY_TABLE[killedGUID] then
            local bountyInfo = BOUNTY_TABLE[killedGUID]
            local bountyAmount = bountyInfo.bountyAmount
            local bountyCreatorGUID = bountyInfo.bountyCreator
            
            -- Transfer gold from the bounty creator to the killer
            local bountyCreator = GetPlayerByGUID(bountyCreatorGUID)
            if bountyCreator then
                -- Pay the killer
                killer:ModifyMoney(bountyAmount * 10000)
                killer:SendBroadcastMessage("You have earned " .. bountyAmount .. " gold for completing the bounty on " .. killed:GetName() .. ".")
                
                -- Inform the bounty creator (if they are online)
                bountyCreator:SendBroadcastMessage("Your bounty on " .. killed:GetName() .. " has been completed.")
            end
            
            -- Remove the bounty
            BOUNTY_TABLE[killedGUID] = nil
        end
    end
end

-- Command handler for the bounty system
local function HandleBountyCommand(event, player, command)
    local args = {}
    for arg in command:gmatch("%S+") do table.insert(args, arg) end
    
    if args[1]:lower() == "bounty_classic" then
        if #args == 1 then
            -- List active bounties
            local hasBounties = false
            player:SendBroadcastMessage("Active Bounties:")
            for targetGUID, bountyInfo in pairs(BOUNTY_TABLE) do
                local targetPlayer = GetPlayerByGUID(targetGUID)
                if targetPlayer then
                    player:SendBroadcastMessage(targetPlayer:GetName() .. ": " .. bountyInfo.bountyAmount .. " gold")
                    hasBounties = true
                end
            end
            if not hasBounties then
                player:SendBroadcastMessage("No active bounties.")
            end
        elseif #args == 3 then
            -- Set a bounty
            local targetName = args[2]
            local goldAmount = tonumber(args[3])
            if goldAmount then
                SetBounty(player, targetName, goldAmount)
            else
                player:SendBroadcastMessage("Invalid gold amount. Usage: .bounty <player_name> <gold_amount>")
            end
        else
            player:SendBroadcastMessage("Usage: .bounty [<player_name> <gold_amount>]")
        end
        return false
    end
    return true
end

-- Register events
RegisterPlayerEvent(6, OnPlayerKilled) -- Register the player death event
RegisterPlayerEvent(42, HandleBountyCommand) -- Register command "bounty"

print("Bounty system loaded.")
