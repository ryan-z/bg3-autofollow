-- server

local function getUUID(player)
    return string.match(player, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x")
end

local function broadcastPlayerList()
    local players = Osi.DB_Players:Get(nil)
    
    local uuids = {}
    -- loop over all the players here for debugging
    for i, player in ipairs(players) do
        if player[1] then  -- Check if the first element exists
            local uuid = getUUID(player[1])
            if uuid then
                table.insert(uuids, uuid)
            end
            print(uuid)  -- Print the UUID for debugging
        end
    end

    _P("Broadcasting player list")
    local players_payload = Ext.Json.Stringify(uuids)
    _P(players_payload)
    Ext.Net.BroadcastMessage("player_list", players_payload)
end

function OnLoad()
    -- on load, send player list to the clients
    broadcastPlayerList()
    -- someone requested the players
    Ext.RegisterNetListener("request_players", function(channel, payload, user)
        broadcastPlayerList()
    end)


    Ext.RegisterNetListener("request_follow", function(channel, payload, user)
        _P("following player")
        _P(payload)
        local follow_data = Ext.Json.Parse(payload)
        Osi.PROC_Follow(follow_data.source, follow_data.target)
    end)

    Ext.RegisterNetListener("request_stop_follow", function(channel, payload, user)
        _P("stop following player")
        local data = Ext.Json.Parse(payload)
        _P(data.source .. " requested to stop follow")
        Osi.PROC_StopFollow(data.source)
    end)

end



-- Ext.Events.StatsLoaded:Subscribe(OnStatsLoaded)

Ext.Events.GameStateChanged:Subscribe(function(e)
    _P(e.ToState)
    if e.FromState == "LoadLevel" and e.ToState == "Sync" then
        OnLoad()
    end
    -- local player = "c9b1c41d-7b5e-f29b-daf4-da21d88f30dc"
    -- local wyll = "c774d764-4a17-48dc-b470-32ace9ce447d"
    -- local astarion = "c7c13742-bacd-460a-8f65-f864fe41f255"
    -- _P(player)
end)


