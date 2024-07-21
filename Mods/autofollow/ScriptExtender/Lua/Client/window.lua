local ui = {
    playerButtonHandles = {},
    userTable = nil,
    topRow = nil,
}

local function clearPlayerButtons()
    local uniqueRows = {}
    for _, item in ipairs(ui.playerButtonHandles) do
        uniqueRows[item.row] = true
    end
    for row in pairs(uniqueRows) do
        ui.userTable:RemoveChild(row)
    end
    ui.playerButtonHandles = {}
end

local function onStopClicked()
    Ext.ClientNet.PostMessageToServer("request_stop_follow", "")
end

local function createPlayerButton(obj, currentRow)
    local buttonLabel = obj.name
    local buttonHandle = currentRow:AddCell():AddButton(buttonLabel)
    buttonHandle.OnClick = function()
        Ext.ClientNet.PostMessageToServer("request_follow", Ext.Json.Stringify({target = obj.uuid}))
    end
    table.insert(ui.playerButtonHandles, {handle = buttonHandle, row = currentRow})
end

local function updatePlayerList(payload)
    local player_list = Ext.Json.Parse(payload)

    clearPlayerButtons()
    
    local currentRow = nil
    local buttonCount = 0
    for _, obj in ipairs(player_list) do
        if buttonCount % 2 == 0 then
            currentRow = ui.userTable:AddRow()
        end

        createPlayerButton(obj, currentRow)
        buttonCount = buttonCount + 1
    end
end

local function addRefreshButton()
    local refreshButton = ui.topRow:AddCell():AddButton("Refresh")
    local tooltip = refreshButton:Tooltip()
    tooltip:AddText("Refresh player list")
    refreshButton.OnClick = function()
        Ext.ClientNet.PostMessageToServer("request_players", "")
    end
end

local function setupFollowWindow()
    local followWindow = Ext.IMGUI.NewWindow("Auto Follow")
    followWindow.AlwaysAutoResize = false

    local topTable = followWindow:AddTable("Something", 2)
    ui.topRow = topTable:AddRow()

    local stopButton = ui.topRow:AddCell():AddButton("Stop")
    local tooltip = stopButton:Tooltip()
    tooltip:AddText("Regain control of your character")
    stopButton.OnClick = onStopClicked

    addRefreshButton()
    followWindow:AddSeparator()
    ui.userTable = followWindow:AddTable("Something", 2)

end

Ext.RegisterNetListener("player_list", function(channel, payload, user)
    _P("Received updated player list")
    updatePlayerList(payload)
end)

Ext.Events.GameStateChanged:Subscribe(function(e)
---@diagnostic disable-next-line: undefined-field
    _P(e.ToState)
---@diagnostic disable-next-line: undefined-field
    if e.FromState == "PrepareRunning" and e.ToState == "Running" then
        OnLoad()
    end
end)

function OnLoad()
    _P("Session loaded")
    setupFollowWindow()
    Ext.ClientNet.PostMessageToServer("request_players", "")
end
