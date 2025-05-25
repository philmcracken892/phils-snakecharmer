local RSGCore = exports['rsg-core']:GetCoreObject()
local xSound = exports.xsound

local State = {
    activePlayers = {},
    snakes = {},
    soundRadius = Config.MaxDistance,
    cooldowns = {}
}

local function getVolumeFactor(distance)
    if distance <= Config.VolumeSettings.MinDistance then
        return 1.0
    elseif distance >= Config.VolumeSettings.MaxDistance then
        return 0.0
    else
        return 1.0 - (distance / Config.VolumeSettings.MaxDistance)
    end
end

local function updateListenerPositions(source, coords)
    for playerId, _ in pairs(State.activePlayers) do
        if tonumber(playerId) ~= tonumber(source) then
            local playerPed = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - coords)
            local volume = Config.VolumeSettings.BaseVolume * getVolumeFactor(distance)
            xSound:setVolume(playerId, tostring(source), volume)
        end
    end
end

RSGCore.Functions.CreateUseableItem("snakeflute", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("snake_charmer:client:placeInstrument", source, {
            type = "flute",
            item = item.name
        })
        State.activePlayers[source] = true
    end
end)

RegisterNetEvent('snake_charmer:server:playMusic', function(data)
    local source = source
    if data.type == 'flute' and State.activePlayers[source] then
        xSound:PlayUrlPos(-1, tostring(source), data.url, Config.VolumeSettings.BaseVolume, data.coords, true)
        xSound:Distance(-1, tostring(source), State.soundRadius)
        updateListenerPositions(source, data.coords)

        TriggerClientEvent('snake_charmer:client:spawnSnakes', source, {
            coords = data.coords,
            behavior = data.behavior,
            radius = data.radius or 3.0,
            spacing = data.spacing or 1.5
        })
    end
end)

RegisterNetEvent('snake_charmer:server:pauseMusic', function(data)
    local source = source
    if data.type == 'flute' then
        xSound:Pause(-1, tostring(source))
    end
end)

RegisterNetEvent('snake_charmer:server:resumeMusic', function(data)
    local source = source
    if data.type == 'flute' then
        xSound:Resume(-1, tostring(source))
    end
end)

RegisterNetEvent('snake_charmer:server:stopMusic', function(data)
    local source = source
    xSound:Destroy(-1, tostring(source))
    if State.snakes[source] then
        for i, snake in ipairs(State.snakes[source]) do
            if DoesEntityExist(snake) then
                DeleteEntity(snake)
                print("Server: Deleted snake entity: " .. tostring(snake))
            else
                print("Server: Snake entity does not exist: " .. tostring(snake))
            end
        end
        State.snakes[source] = nil
        print("Server: State.snakes[" .. source .. "] cleared")
    end
    TriggerClientEvent('snake_charmer:client:clearSnakes', source)
end)

RegisterNetEvent('snake_charmer:server:pickupInstrument', function(data)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    if data.type == "flute" then
        Player.Functions.AddItem("snakeflute", 1)
        TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items["snakeflute"], "add")
        State.activePlayers[source] = nil
    end
end)

RegisterNetEvent('snake_charmer:server:toggleSound', function(data)
    local source = source
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    if data.type == 'flute' and State.activePlayers[source] then
        TriggerClientEvent('snake_charmer:client:playSound', source, {
            type = 'flute',
            action = data.enabled and 'play' or 'stop',
            coords = coords
        })
    end
end)

RegisterNetEvent('snake_charmer:server:changeVolume', function(volume, type)
    local source = source
    if type == 'flute' then
        xSound:setVolume(-1, tostring(source), volume)
    end
end)

RegisterNetEvent('snake_charmer:server:changeRadius', function(radius, type)
    local source = source
    if type == 'flute' then
        State.soundRadius = radius
        xSound:Distance(-1, tostring(source), radius)
    end
end)

RegisterNetEvent('snake_charmer:server:manageSnakes', function(data)
    local source = source
    State.snakes[source] = data.snakes
    print("Server: Updated State.snakes[" .. source .. "] with " .. #data.snakes .. " snakes")
    TriggerClientEvent('snake_charmer:client:manageSnakes', source, data)
end)

AddEventHandler('playerDropped', function()
    local source = source
    if State.activePlayers[source] then
        State.activePlayers[source] = nil
        if State.snakes[source] then
            for i, snake in ipairs(State.snakes[source]) do
                if DoesEntityExist(snake) then
                    DeleteEntity(snake)
                    
                end
            end
            State.snakes[source] = nil
           
        end
        xSound:Destroy(-1, tostring(source))
        TriggerClientEvent('snake_charmer:client:clearSnakes', source)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for source, snakes in pairs(State.snakes) do
        for i, snake in ipairs(snakes) do
            if DoesEntityExist(snake) then
                DeleteEntity(snake)
               
            end
        end
    end
    State.snakes = {}
    State.activePlayers = {}
    xSound:Destroy(-1, "*")
   
end)