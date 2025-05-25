local RSGCore = exports['rsg-core']:GetCoreObject()

local State = {
    flute = {
        prop = nil,
        isAttached = false,
        isPlaying = false,
        animationActive = false
    },
    soundPermission = false,
    soundRadius = Config.MaxDistance,
    snakes = {}
}

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(5)
        end
    end
end

local function loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end

local function attachFlute()
    local playerPed = PlayerPedId()
    local settings = Config.PropSettings.flute
    local propHash = loadModel(settings.model)
    
    State.flute.prop = CreateObject(propHash, 0, 0, 0, true, true, false)
    local boneIndex = GetEntityBoneIndexByName(playerPed, settings.boneName)
    
    AttachEntityToEntity(
        State.flute.prop, playerPed, boneIndex,
        settings.position.x, settings.position.y, settings.position.z,
        settings.rotation.pitch, settings.rotation.roll, settings.rotation.yaw,
        false, true, false, true, 2, true
    )
    
    SetModelAsNoLongerNeeded(propHash)
    State.flute.isAttached = true
    TriggerEvent('rNotify:NotifyLeft', "FLUTE EQUIPPED", "Press G to play enchanting tunes!", "generic_textures", "tick", 4000)
	ExecuteCommand('closeInv')
end

local function detachFlute()
    if State.flute.prop then
        DetachEntity(State.flute.prop, true, true)
        DeleteObject(State.flute.prop)
        State.flute.prop = nil
        State.flute.isAttached = false
        TriggerEvent('rNotify:NotifyLeft', "FLUTE STORED", "Your flute has been put away", "generic_textures", "tick", 4000)
    end
end

local function stopFluteAnimation()
    if State.flute.animationActive then
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        State.flute.animationActive = false
        State.flute.isPlaying = false
        TriggerEvent('rNotify:NotifyLeft', "MUSIC STOPPED", "The snakes retreat", "generic_textures", "tick", 4000)
    end
end

local function startFluteAnimation()
    if not State.flute.animationActive then
        local ped = PlayerPedId()
        loadAnimDict(Config.Animation.dict)
      
        TaskPlayAnim(ped, Config.Animation.dict, Config.Animation.name, 8.0, -8.0, -1, 25, 0, false, false, false)
        State.flute.animationActive = true
        TriggerEvent('rNotify:NotifyLeft', "PLAYING FLUTE", "The snakes are enchanted!", "generic_textures", "tick", 4000)
        
        CreateThread(function()
            while State.flute.isPlaying do
                Wait(1000)
                if not IsEntityPlayingAnim(ped, Config.Animation.dict, Config.Animation.name, 3) and State.flute.isPlaying then
                    TaskPlayAnim(ped, Config.Animation.dict, Config.Animation.name, 8.0, -8.0, -1, 25, 0, false, false, false)
                   
                end
            end
            State.flute.animationActive = false
        end)
    end
end

local function manageSnakes(data)
    State.snakes = data.snakes
    local playerPed = PlayerPedId()
    
    CreateThread(function()
        while State.flute.isPlaying and #State.snakes > 0 do
            local playerCoords = GetEntityCoords(playerPed)
            for i, snake in ipairs(State.snakes) do
                if DoesEntityExist(snake) and not IsPedDeadOrDying(snake, true) then
                    if data.behavior == "circle" then
                        local angle = (i / #State.snakes) * 2 * math.pi
                        local target = playerCoords + vector3(math.cos(angle) * data.radius, math.sin(angle) * data.radius, 0.0)
                        TaskGoToCoordAnyMeans(snake, target.x, target.y, target.z, 1.0, 0, false, 786603, 0)
                    elseif data.behavior == "follow" then
                        local offset = vector3(0.0, -i * data.spacing, 0.0)
                        ClearPedTasks(snake)
                        TaskFollowToOffsetOfEntity(snake, playerPed, offset.x, offset.y, offset.z, 1.5, -1, 0.0, true)
                    elseif data.behavior == "random" then
                        local offset = vector3(math.random(-data.radius, data.radius), math.random(-data.radius, data.radius), 0.0)
                        local target = playerCoords + offset
                        TaskGoToCoordAnyMeans(snake, target.x, target.y, target.z, 1.0, 0, false, 786603, 0)
                    end
                end
            end
            Wait(500)
        end
       
        TriggerEvent('snake_charmer:client:clearSnakes')
    end)
end

local function createFluteMenu()
    lib.registerContext({
        id = 'flute_menu',
        title = 'Snake Flute',
        options = {
            {
                title = 'Play a Tune',
                description = 'Choose a flute melody to charm snakes',
                onSelect = function()
                    lib.registerContext({
                        id = 'flute_tunes',
                        title = 'Flute Tunes',
                        menu = 'flute_menu',
                        options = {
                            {
                                title = 'Mystic Call',
                                description = 'Snakes circle around you',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:playMusic', {
                                        type = 'flute',
                                        url = Config.Tunes[1].url,
                                        coords = GetEntityCoords(PlayerPedId()),
                                        behavior = Config.Tunes[1].behavior,
                                        radius = Config.Tunes[1].radius
                                    })
                                end
                            },
                            {
                                title = 'Serpent March',
                                description = 'Snakes follow in a line',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:playMusic', {
                                        type = 'flute',
                                        url = Config.Tunes[2].url,
                                        coords = GetEntityCoords(PlayerPedId()),
                                        behavior = Config.Tunes[2].behavior,
                                        spacing = Config.Tunes[2].spacing
                                    })
                                end
                            },
                            {
                                title = 'Wild Dance',
                                description = 'Snakes sway randomly',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:playMusic', {
                                        type = 'flute',
                                        url = Config.Tunes[3].url,
                                        coords = GetEntityCoords(PlayerPedId()),
                                        behavior = Config.Tunes[3].behavior,
                                        radius = Config.Tunes[3].radius
                                    })
                                end
                            }
                        }
                    })
                    lib.showContext('flute_tunes')
                end
            },
            {
                title = 'Pause Music',
                description = 'Pause currently playing tune',
                onSelect = function()
                    TriggerServerEvent('snake_charmer:server:pauseMusic', { type = 'flute' })
                end
            },
            {
                title = 'Resume Music',
                description = 'Resume paused tune',
                onSelect = function()
                    TriggerServerEvent('snake_charmer:server:resumeMusic', { type = 'flute' })
                end
            },
            {
                title = 'Change Volume',
                description = 'Adjust the music volume',
                onSelect = function()
                    lib.registerContext({
                        id = 'flute_volume',
                        title = 'Volume Control',
                        menu = 'flute_menu',
                        options = {
                            {
                                title = 'Low Volume (25%)',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:changeVolume', 0.25, 'flute')
                                end
                            },
                            {
                                title = ' Medium Volume (50%)',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:changeVolume', 0.50, 'flute')
                                end
                            },
                            {
                                title = ' Full Volume (100%)',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:changeVolume', 1.00, 'flute')
                                end
                            }
                        }
                    })
                    lib.showContext('flute_volume')
                end
            },
            {
                title = ' Change Range',
                description = 'Adjust how far the music can be heard',
                onSelect = function()
                    lib.registerContext({
                        id = 'flute_radius',
                        title = ' Sound Range Control',
                        menu = 'flute_menu',
                        options = {
                            {
                                title = ' Small Range (5m)',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:changeRadius', 5.0, 'flute')
                                end
                            },
                            {
                                title = ' Medium Range (25m)',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:changeRadius', 25.0, 'flute')
                                end
                            },
                            {
                                title = ' Large Range (50m)',
                                onSelect = function()
                                    TriggerServerEvent('snake_charmer:server:changeRadius', 50.0, 'flute')
                                end
                            },
                            {
                                title = ' Custom Range',
                                onSelect = function()
                                    local input = lib.inputDialog('Custom Range', {
                                        {
                                            type = 'number',
                                            label = 'Range in meters',
                                            description = 'Enter a value between 1 and 100 meters',
                                            required = true,
                                            min = 1,
                                            max = 100,
                                            step = 1,
                                            default = 25
                                        }
                                    })
                                    if input then
                                        local radius = input[1]
                                        if radius then
                                            TriggerServerEvent('snake_charmer:server:changeRadius', radius, 'flute')
                                        end
                                    end
                                end
                            }
                        }
                    })
                    lib.showContext('flute_radius')
                end
            },
            {
                title = ' Stop Music',
                description = 'Stop playing and put away flute',
                onSelect = function()
                    TriggerServerEvent('snake_charmer:server:stopMusic', { type = 'flute' })
                    stopFluteAnimation()
                    State.flute.isPlaying = false
                    State.soundPermission = false
                    TriggerEvent('snake_charmer:client:clearSnakes')
                    TriggerEvent('snake_charmer:client:pickupInstrument', { type = 'flute' })
                end
            }
        }
    })
    lib.showContext('flute_menu')
end

RegisterNetEvent('snake_charmer:client:clearSnakes', function()
    if State.snakes then
        for i, snake in ipairs(State.snakes) do
            if DoesEntityExist(snake) then
                ClearPedTasks(snake) 
                DeleteEntity(snake)
               
            else
               
            end
        end
        State.snakes = {}
       
    end
end)

RegisterNetEvent('snake_charmer:client:placeInstrument', function(data)
    if data.type == "flute" then
        attachFlute()
        State.soundPermission = true
        TriggerServerEvent('snake_charmer:server:toggleSound', { type = 'flute', enabled = true })
    end
end)

RegisterNetEvent('snake_charmer:client:pickupInstrument', function(data)
    if data.type == "flute" then
        if State.flute.isAttached then
            stopFluteAnimation()
            detachFlute()
            State.soundPermission = false
            State.flute.isPlaying = false
            TriggerServerEvent('snake_charmer:server:toggleSound', { type = 'flute', enabled = false })
            TriggerServerEvent('snake_charmer:server:pickupInstrument', { type = "flute" })
        end
    end
end)

RegisterNetEvent('snake_charmer:client:spawnSnakes', function(data)
    local coords = data.coords
    local modelHash = GetHashKey("a_c_snake_01")

    RequestModel(modelHash)
    local startTime = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(10)
        if GetGameTimer() - startTime > 5000 then
           
            return
        end
    end

    State.snakes = {}
    for i = 1, Config.MaxSnakes do
        local offset = vector3(math.random(-2, 2), math.random(-2, 2), 0.0)
        local spawnCoords = coords + offset
        local snake = CreatePed(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true, true)

        if DoesEntityExist(snake) then
            Citizen.InvokeNative(0x283978A15512B2FE, snake, true)
            SetEntityAsMissionEntity(snake, true, true)
            SetBlockingOfNonTemporaryEvents(snake, true)
            table.insert(State.snakes, snake)
           
        end
    end

    SetModelAsNoLongerNeeded(modelHash)
    
    TriggerServerEvent('snake_charmer:server:manageSnakes', { snakes = State.snakes, behavior = data.behavior, radius = data.radius, spacing = data.spacing })
end)

RegisterNetEvent('snake_charmer:client:playSound', function(data)
    if data.type == 'flute' then
        if data.action == 'play' then
            State.flute.isPlaying = true
            startFluteAnimation()
        elseif data.action == 'stop' then
            State.flute.isPlaying = false
            stopFluteAnimation()
        end
    end
end)

RegisterNetEvent('snake_charmer:client:manageSnakes', function(data)
    manageSnakes(data)
end)

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, 0x760A9C6F) then -- G key
            if State.flute.isAttached then
                createFluteMenu()
            end
        end
    end
end)

exports('getState', function()
    return State
end)

exports('isPlaying', function()
    return State.flute.isPlaying
end)