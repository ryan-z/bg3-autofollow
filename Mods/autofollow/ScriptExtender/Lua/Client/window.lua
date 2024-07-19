-- client

local playerList = {}
local playerButtonHandles = {} -- Store button handles here

local function clearPlayerButtons()
    for _, handle in ipairs(playerButtonHandles) do
        Follow_window:RemoveChild(handle) -- Remove each button using the handle
    end
    playerButtonList = {} -- Clear the list after removing buttons
end

local function onStopClicked()
    local data = { source = "c9b1c41d-7b5e-f29b-daf4-da21d88f30dc" }  -- Replace this with actual client UUID
    Ext.ClientNet.PostMessageToServer("request_stop_follow", Ext.Json.Stringify(data))
end

local function setupFollowWindow()
    Follow_window = Ext.IMGUI.NewWindow("Auto Follow")
    Follow_window.AlwaysAutoResize = true

    -- Add a 'Refresh Players' button
    Follow_window:AddButton("Refresh Players").OnClick = function()
        Ext.ClientNet.PostMessageToServer("request_players", "")
    end

    -- Stop button to regain control
    Follow_window:AddButton("Stop").OnClick = onStopClicked

end

local function updatePlayerList(payload)
    playerList = Ext.Json.Parse(payload)
    _P("player list is..." .. Ext.Json.Stringify(playerList))

    clearPlayerButtons() -- Clear existing buttons before adding new ones

    -- Add a button for each player in the player list
    for index, uuid in ipairs(playerList) do
        local buttonLabel = "Player " .. index
        local buttonHandle = Follow_window:AddButton(buttonLabel) -- Store the handle when adding the button
        buttonHandle.OnClick = function()
            local data = {
                source = "c9b1c41d-7b5e-f29b-daf4-da21d88f30dc",  -- Replace this with actual client UUID fetching method
                target = uuid
            }
            Ext.ClientNet.PostMessageToServer("request_follow", Ext.Json.Stringify(data))
        end
        table.insert(playerButtonHandles, buttonHandle) -- Store the handle for later removal
    end
end

Ext.RegisterNetListener("player_list", function(channel, payload, user)
    _P("Received updated player list")
    updatePlayerList(payload)
end)

Ext.Events.GameStateChanged:Subscribe(function(e)
    _P(e.ToState)
    if e.FromState == "PrepareRunning" and e.ToState == "Running" then
        OnLoad()
    end
end)


function OnLoad()
    _P("Session loaded")
    setupFollowWindow()
end