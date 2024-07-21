-- server

local function getUUID(player)
    return string.match(player, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x")
end

local function broadcastPlayerList()
    local player_ents = Osi.DB_Players:Get(nil)
    local player_data = {}
    for _, ent in ipairs(player_ents) do
        if ent[1] then
            local entity_id = tostring(ent[1])
            local entity_obj = Ext.Entity.Get(entity_id)
            local data = {
                name = Ext.Loca.GetTranslatedString(entity_obj.DisplayName.NameKey.Handle.Handle),
                uuid = getUUID(entity_id)
            }
            table.insert(player_data, data)
        end
    end

    local players_payload = Ext.Json.Stringify(player_data)
    _P("players_payload" .. players_payload)
    Ext.Net.BroadcastMessage("player_list", players_payload)
end

function PeerToUserID(u)
    return (u & 0xffff0000) | 0x0001
end

function OnLoad()
    Ext.RegisterNetListener("request_players", function(channel, payload, userId)
        broadcastPlayerList()
    end)

    Ext.RegisterNetListener("request_follow", function(channel, payload, userId)
        _P("following player")
        local requester_uuid = tostring(Osi.GetCurrentCharacter(PeerToUserID(userId)))
        _D(requester_uuid)
        local follow_data = Ext.Json.Parse(payload)
        Osi.PROC_Follow(requester_uuid, follow_data.target)
    end)

    Ext.RegisterNetListener("request_stop_follow", function(channel, payload, userId)
        _P("stop following player")
        local requester_uuid = tostring(Osi.GetCurrentCharacter(PeerToUserID(userId)))
        Osi.PROC_StopFollow(requester_uuid)
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


Ext.Events.NetMessage:Subscribe(function(e)
    if  e.Name == "NETMSG_PLAYER_CONNECT" or
        e.Name == "NETMSG_CLIENT_JOINED" or
        e.Name == "NETMSG_PLAYER_LEFT" or
        e.Name == "NETMSG_CLIENT_LEFT" then
            _P("player count change detected")
        broadcastPlayerList()
    end
end)