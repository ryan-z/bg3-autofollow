-- client

local playerButtonHandles = {} -- Store button handles here

local function clearPlayerButtons()
    for _, handle in ipairs(playerButtonHandles) do
        UserTable:RemoveChild(handle) -- Remove each button using the handle
    end
end

local function onStopClicked()
    Ext.ClientNet.PostMessageToServer("request_stop_follow", "")
end

local function updatePlayerList(payload)
    local player_list = Ext.Json.Parse(payload)

    clearPlayerButtons() -- Clear existing buttons before adding new ones
    
    local currentRow = nil
    local buttonCount = 0
    for _, obj in ipairs(player_list) do
        if buttonCount % 2 == 0 then
            currentRow = UserTable:AddRow()
        end

        local buttonLabel = obj.name
        local buttonHandle = currentRow ~= nil and currentRow:AddCell():AddButton(buttonLabel)
        buttonHandle.OnClick = function()
            local data = {
                target = obj.uuid
            }
            Ext.ClientNet.PostMessageToServer("request_follow", Ext.Json.Stringify(data))
        end
        table.insert(playerButtonHandles, buttonHandle)
        buttonCount = buttonCount + 1
    end
end

local function addRefreshButton()
    local refreshButton = TopRow:AddCell():AddButton("Refresh")
    local tooltip = refreshButton:Tooltip()
    tooltip:AddText("Refresh player list")
    refreshButton.OnClick = function()
        _P("Refresh button clicked!")
        Ext.ClientNet.PostMessageToServer("request_players", "")
    end
end

local function setupFollowWindow()
    Follow_window = Ext.IMGUI.NewWindow("Auto Follow")
    Follow_window.AlwaysAutoResize = false

    TopTable = Follow_window:AddTable("Something", 2)
    TopRow = TopTable:AddRow()
    local stop_button = TopRow:AddCell():AddButton("Stop")
    local tooltip = stop_button:Tooltip()
    tooltip:AddText("Regain control of your character")
    stop_button.OnClick = onStopClicked
    addRefreshButton()
    Follow_window:AddSeparator()
    UserTable = Follow_window:AddTable("Something", 2)
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
    Ext.ClientNet.PostMessageToServer("request_players", "")
end