MenuData = {}
TriggerEvent("redemrp_menu_base:getData",function(call)
    MenuData = call
end)
local soundId = 'rs_phonograph'
local volume = 0.3
local phonographEntities = {} 

local function OpenPhonographMenu(entity, networkEntityId, uniqueId)
    MenuData.CloseAll()

    local elements = {}

    if Config.AllowCustomSongs then
        table.insert(elements, {
            label = Config.Menu.Play,
            value = "play",
            desc = Config.Menu.DesPlay,
        })
    end

    if Config.AllowListSongs then
        table.insert(elements, {
            label = Config.Menu.SongList,
            value = "choose_song",
            desc = Config.Menu.DesSongList,
        })
    end

    table.insert(elements, {
        label = Config.Menu.Stop,
        value = "stop",
        desc = Config.Menu.DesStop,
    })

    table.insert(elements, {
        label = Config.Menu.VolumeUp,
        value = "volume_up",
        desc = Config.Menu.DesVolumeUp,
    })

    table.insert(elements, {
        label = Config.Menu.VolumeDown,
        value = "volume_down",
        desc = Config.Menu.DesVolumeDown,
    })

    local nuifocus = false

    MenuData.Open('default', GetCurrentResourceName(), 'phonograph_menu', {
        title = Config.Menu.Title,
        subtext = Config.Menu.SubTx,
        align = 'top-right',
        elements = elements,
    },
    function(data, menu)
        local id = uniqueId

        if data.current.value == "play" then
            if not Config.AllowCustomSongs then
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.Custom, "menu_textures", "cross", 500, "COLOR_RED")
                return
            end

            local myInput = {
                type = "enableinput",
                inputType = "input",
                button = Config.Menu.Button,
                placeholder = Config.Menu.PlaceHolder,
                style = "block",
                attributes = {
                    inputHeader = Config.Menu.InputHeader,
                    type = "text",
                    pattern = ".*",
                    title = Config.Menu.Titles,
                    style = "border-radius: 10px; background-color: ; border:none;"
                }
            }

            local result = exports.vorp_inputs:advancedInput(myInput)

            if result and result:sub(1, 4) == "http" then
                TriggerServerEvent('rs_phonograph:server:playMusic', id, GetEntityCoords(entity), result, volume)
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.PlayMessage, "generic_textures", "tick", 1500, "GREEN")
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.InvalidUrlMessage, "menu_textures", "cross", 500, "COLOR_RED")
            end

        elseif data.current.value == "choose_song" then
            local songOptions = {}

            for i, song in ipairs(Config.SongList) do
                table.insert(songOptions, {
                    label = song.label,
                    value = i,
                    desc = song.description or "",
                    image = song.image or nil,
                    descriptionimages = song.descriptionimages or nil
                })
            end

            MenuData.Open('default', GetCurrentResourceName(), 'song_list_menu', {
                title = Config.Menu.SongList,
                align = 'top-right',
                elements = songOptions,
            },
            function(data2, menu2)
                local selectedSong = Config.SongList[data2.current.value]
                if selectedSong and selectedSong.url then
                    TriggerServerEvent('rs_phonograph:server:playMusic', id, GetEntityCoords(entity), selectedSong.url, volume)
                    TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.PlayMessage, "generic_textures", "tick", 1500, "GREEN")
                else
                    TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.InvalidSound, "menu_textures", "cross", 500, "COLOR_RED")
                end
                menu2.close()
            end,
            function(data2, menu2)
                menu2.close()
            end,
            nil,
            false) -- nuifocus false aquí

        elseif data.current.value == "stop" then
            TriggerServerEvent('rs_phonograph:server:stopMusic', id)
            TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.StopMessage, "menu_textures", "stop", 500, "COLOR_RED")

        elseif data.current.value == "volume_up" then
            if volume < 1.0 then
                volume = volume + 0.1
                if volume > 1.0 then volume = 1.0 end
                TriggerServerEvent('rs_phonograph:server:setVolume', id, volume)
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.VolumeUpMessage:format(math.floor(volume * 100)), "generic_textures", "tick", 500, "GREEN")
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.MaxVolumeMessage, "menu_textures", "cross", 500, "COLOR_RED")
            end

        elseif data.current.value == "volume_down" then
            if volume > 0.0 then
                volume = volume - 0.1
                if volume < 0.0 then volume = 0.0 end
                TriggerServerEvent('rs_phonograph:server:setVolume', id, volume)
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.VolumeDownMessage:format(math.floor(volume * 100)), "generic_textures", "tick", 500, "GREEN")
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.MinVolumeMessage, "menu_textures", "cross", 500, "COLOR_RED")
            end
        end
    end,
    function(data, menu)
        menu.close()
    end,
    nil, -- onChange no usado
    nuifocus) -- nuifocus booleano correcto
end

local promptGroup = UipromptGroup:new(Config.Promp.Controls)

local playMusicPrompt = Uiprompt:new(`INPUT_DYNAMIC_SCENARIO`, Config.Promp.Play, promptGroup)
playMusicPrompt:setHoldMode(true)

local pickUpPrompt = Uiprompt:new(`INPUT_RELOAD`, Config.Promp.Collect, promptGroup)
pickUpPrompt:setHoldMode(true)

local closestEntity = nil

local function updatePrompts()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    closestEntity = nil

    local found = false

    for netId, uniqueId in pairs(phonographEntities or {}) do
        if NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId) then
            local entity = NetworkGetEntityFromNetworkId(netId)
            local entityCoords = GetEntityCoords(entity)
            local distance = #(playerCoords - entityCoords)

            if distance <= 1.5 then
                closestEntity = entity
                found = true
                break
            end
        end
    end

    promptGroup:setActive(found)
    playMusicPrompt:setVisible(found)
    playMusicPrompt:setEnabled(found)
    pickUpPrompt:setVisible(found)
    pickUpPrompt:setEnabled(found)
end

RegisterNetEvent('rs_phonograph:client:spawnPhonograph')
AddEventHandler('rs_phonograph:client:spawnPhonograph', function(data)
    local propModel = GetHashKey('p_phonograph01x')
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(10) end

    local object = CreateObject(propModel, data.x, data.y, data.z, true, false, false)

    SetEntityRotation(object, data.rotation.x, data.rotation.y, data.rotation.z, 0, true)

    phonographEntities = phonographEntities or {}
    local netId = NetworkGetNetworkIdFromEntity(object)
    phonographEntities[netId] = data.id
    updatePrompts()
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent("rs_phonograph:server:loadPhonographs")
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent("rs_phonograph:server:loadPhonographs")
    end
end)

promptGroup:setOnHoldModeJustCompleted(function(group, prompt)
    if closestEntity and DoesEntityExist(closestEntity) then
        local netId = NetworkGetNetworkIdFromEntity(closestEntity)
        local uniqueId = phonographEntities[netId]

        if prompt == playMusicPrompt then
            if uniqueId then
                OpenPhonographMenu(closestEntity, netId, uniqueId)
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.UnregisteredMessage, "generic_textures", "tick", 3000, "GREEN")
            end
        elseif prompt == pickUpPrompt then
            if uniqueId then
                TriggerServerEvent('rs_phonograph:server:pickUpByOwner', uniqueId)
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.UnregisteredMessage, "generic_textures", "tick", 3000, "GREEN")
            end
        end
    else
        TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.NoPhonographMessage, "menu_textures", "cross", 3000, "COLOR_RED")
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        updatePrompts()
    end
end)

UipromptManager:startEventThread()

RegisterNetEvent('rs_phonograph:client:placePropPhonograph')
AddEventHandler('rs_phonograph:client:placePropPhonograph', function()

    local propModel = GetHashKey('p_phonograph01x')
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(10) end

    local playerPed = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(playerPed, true))

    local offsetDistance = 2.5
    local ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, offsetDistance, 0.0))
    local groundSuccess, groundZ = GetGroundZFor_3dCoord(ox, oy, pz, false)
    if groundSuccess then
        pz = groundZ
    end

    local object = CreateObject(propModel, ox, oy, pz, true, false, false)
    PlaceObjectOnGroundProperly(object)

    local posX, posY, posZ = table.unpack(GetEntityCoords(object))
    local heading = GetEntityHeading(object)

    local moveStep = 0.05
    local isPlacing = true

    FreezeEntityPosition(object, true)
    SetEntityCollision(object, false, false)
    SetEntityAlpha(object, 150, false)

    SendNUIMessage({ action = "show" })

    Citizen.CreateThread(function()
        while isPlacing do
            Citizen.Wait(0)

            if IsControlJustPressed(0, 0x4F49CC4C) then
                local myInput = {
                    type = "enableinput",
                    inputType = "input",
                    button = Config.Menu.Confirm,
                    placeholder = Config.Menu.MinMax,
                    style = "block",
                    attributes = {
                        inputHeader = Config.Menu.Speed,
                        type = "text",
                        pattern = "[0-9.]+",
                        title = Config.Menu.Change,
                        style = "border-radius: 10px; background-color: ; border:none;"
                    }
                }

                local result = exports.vorp_inputs:advancedInput(myInput)
                if result and result ~= "" then
                    local testint = tonumber(result)
                    if testint and testint ~= 0 then
                        moveStep = math.max(0.01, math.min(testint, 5))
                    end
                end
            end

            local moved = false
            if IsControlPressed(0, 0x6319DB71) then posY = posY + moveStep; moved = true end -- UP
            if IsControlPressed(0, 0x05CA7C52) then posY = posY - moveStep; moved = true end -- DOWN
            if IsControlPressed(0, 0xA65EBAB4) then posX = posX - moveStep; moved = true end -- LEFT
            if IsControlPressed(0, 0xDEB34313) then posX = posX + moveStep; moved = true end -- RIGHT
            if IsControlPressed(0, 0xB03A913B) then posZ = posZ + moveStep; moved = true end -- 7
            if IsControlPressed(0, 0x42385422) then posZ = posZ - moveStep; moved = true end -- 8
            if IsControlPressed(0, 0xE6F612E4) then heading = heading + 5; moved = true end -- 1
            if IsControlPressed(0, 0x1CE6D9EB) then heading = heading - 5; moved = true end -- 2

            if moved then
                SetEntityCoords(object, posX, posY, posZ, true, true, true, false)
                SetEntityHeading(object, heading)
            end

            if IsControlJustPressed(0, 0xC7B5340A) then -- ENTER
                isPlacing = false
                
                FreezeEntityPosition(object, true)
                SetEntityAlpha(object, 255, false)
                SetEntityCollision(object, true, true)

                local netId = NetworkGetNetworkIdFromEntity(object)
                local uniqueId = 'rs_phonograph' .. '-' .. netId
                phonographEntities = phonographEntities or {}
                phonographEntities[netId] = uniqueId

                local rotation = GetEntityRotation(object, 2)
                local coords = GetEntityCoords(object)

                TriggerServerEvent('rs_phonograph:server:saveOwner',
                    uniqueId,
                    { x = coords.x, y = coords.y, z = coords.z },
                    { x = rotation.x, y = rotation.y, z = rotation.z }
                )
                TriggerServerEvent("rs_phonograph:givePhonograph")
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.Place, "generic_textures", "tick", 500, "GREEN")
                SendNUIMessage({ action = "hide" })
                updatePrompts()
            end

            if IsControlJustPressed(0, 0x760A9C6F) then -- G
                isPlacing = false
                DeleteObject(object)
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.Placed, "menu_textures", "cross", 500, "COLOR_RED")
                SendNUIMessage({ action = "hide" })
            end
        end
    end)
end)

RegisterNetEvent('rs_phonograph:client:removePhonograph')
AddEventHandler('rs_phonograph:client:removePhonograph', function(uniqueId)
    for netId, id in pairs(phonographEntities) do
        if id == uniqueId then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and DoesEntityExist(entity) then
                DeleteObject(entity)
            end
            phonographEntities[netId] = nil
            break
        end
    end
end)

local function getSoundName(id)
    return "phonograph_" .. tostring(id)
end

RegisterNetEvent('rs_phonograph:client:playMusic')
AddEventHandler('rs_phonograph:client:playMusic', function(id, coords, url, volume)
    local soundName = getSoundName(id)

    exports.xsound:PlayUrlPos(soundName, url, volume, coords)
    exports.xsound:Distance(soundName, 10)
end)

RegisterNetEvent('rs_phonograph:client:stopMusic')
AddEventHandler('rs_phonograph:client:stopMusic', function(id)
    local soundName = getSoundName(id)

    if exports.xsound:soundExists(soundName) then
        exports.xsound:Destroy(soundName)
    end
end)

RegisterNetEvent('rs_phonograph:client:setVolume')
AddEventHandler('rs_phonograph:client:setVolume', function(id, newVolume)
    local soundName = getSoundName(id)

    if exports.xsound:soundExists(soundName) then
        exports.xsound:setVolume(soundName, newVolume)
    end
end)
