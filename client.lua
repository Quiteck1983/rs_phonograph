local volume = 0.3
local Menu = exports.vorp_menu:GetMenuData()

local function OpenSongListMenu(labelName, songs, uniqueId)
    Menu.CloseAll()

    local elements = {}

    if songs then
        for _, song in pairs(songs) do
            table.insert(elements, {
                label = song.label,
                value = song.url,
                desc = song.description or "",
            })
        end
    end

    table.insert(elements, {
        label = Config.Menu.Close,
        value = "cancel",
        desc = Config.Menu.Descsub,
    })

    Menu.Open("default", GetCurrentResourceName(), "song_list_menu", {
        title = labelName,
        subtext = Config.Menu.Select,
        align = "top-right",
        elements = elements,
    }, function(data, menu)
        local selectedUrl = data.current.value

        if selectedUrl == "cancel" then
            menu.close()
            return
        end

        TriggerServerEvent('rs_phonograph:server:playMusic', uniqueId, GetEntityCoords(PlayerPedId()), selectedUrl, volume)
        TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.PlaySelect, "generic_textures", "tick", 1500, "GREEN")
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end

local function OpenPhonographMenu(entity, uniqueId)
    Menu.CloseAll()

    local function BuildElements()
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
        })

        table.insert(elements, {
            label = Config.Menu.VolumeDown,
            value = "volume_down",
        })

        return elements
    end

    local elements = BuildElements()

    Menu.Open('default', GetCurrentResourceName(), 'phonograph_menu', {
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
                TriggerServerEvent('rs_phonograph:server:playMusic', uniqueId, GetEntityCoords(entity), result, volume)
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.PlayMessage, "generic_textures", "tick", 1500, "GREEN")
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.InvalidUrlMessage, "menu_textures", "cross", 500, "COLOR_RED")
            end

        elseif data.current.value == "choose_song" then
            menu.close()
            OpenSongListMenu(Config.Menu.SongList, Config.SongList, uniqueId)

        elseif data.current.value == "stop" then
            TriggerServerEvent('rs_phonograph:server:stopMusic', uniqueId)
            TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.StopMessage, "menu_textures", "stop", 500, "COLOR_RED")

        elseif data.current.value == "volume_up" then
            if volume < 1.0 then
                volume = volume + 0.05
                if volume > 1.0 then volume = 1.0 end
                TriggerServerEvent('rs_phonograph:server:setVolume', uniqueId, volume)
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.VolumeUpMessage:format(math.floor(volume * 100)), "generic_textures", "tick", 100, "GREEN")
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.MaxVolumeMessage, "menu_textures", "cross", 500, "COLOR_RED")
            end

        elseif data.current.value == "volume_down" then
            if volume > 0.0 then
                volume = volume - 0.05
                if volume < 0.0 then volume = 0.0 end
                TriggerServerEvent('rs_phonograph:server:setVolume', uniqueId, volume)
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.VolumeDownMessage:format(math.floor(volume * 100)), "generic_textures", "tick", 100, "GREEN")
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.MinVolumeMessage, "menu_textures", "cross", 500, "COLOR_RED")
            end
        end
    end,
    function(data, menu)
        menu.close()
    end)
end

local promptGroup = UipromptGroup:new(Config.Promp.Controls)

local playMusicPrompt = Uiprompt:new(`INPUT_DYNAMIC_SCENARIO`, Config.Promp.Play, promptGroup)
playMusicPrompt:setHoldMode(true)

local pickUpPrompt = Uiprompt:new(`INPUT_RELOAD`, Config.Promp.Collect, promptGroup)
pickUpPrompt:setHoldMode(true)

local closestEntity = nil
local closestId = nil
local pendingPhonographObject = nil
phonographEntities = {}

local function findWorldPhonographs()
    local modelHash = `p_phonograph01x`
    local handle, object = FindFirstObject()
    local success
    repeat
        if DoesEntityExist(object) and GetEntityModel(object) == modelHash then
            local id = NetworkGetNetworkIdFromEntity(object)
            if not phonographEntities[id] then
                phonographEntities[id] = object
               -- print("[Debug] Fonógrafo del mundo detectado. ID:", id)
            end
        end
        success, object = FindNextObject(handle)
    until not success
    EndFindObject(handle)
end

local function clearAllPhonographs()
    for id, entity in pairs(phonographEntities) do
        if DoesEntityExist(entity) and NetworkGetEntityIsNetworked(entity) then
           -- print("[Debug] Borrando fonógrafo colocado por jugador. ID:", id)
            DeleteObject(entity)
        end
    end
    phonographEntities = {}

    if lastPlacedPhonograph and lastPlacedPhonograph.entity and DoesEntityExist(lastPlacedPhonograph.entity) then
       -- print("[Debug] Borrando último fonógrafo colocado")
        DeleteObject(lastPlacedPhonograph.entity)
    end
    lastPlacedPhonograph = nil
end

local function updatePrompts()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    closestEntity, closestId = nil, nil
    local found = false

    for uniqueId, entity in pairs(phonographEntities or {}) do
        if DoesEntityExist(entity) then
            local entityCoords = GetEntityCoords(entity)
            local distance = #(playerCoords - entityCoords)
            if distance <= 2.5 then
                closestEntity = entity
                closestId = uniqueId
                found = true
                break
            end
        end
    end

    if not found and pendingPhonographObject and DoesEntityExist(pendingPhonographObject) then
        local distance = #(playerCoords - GetEntityCoords(pendingPhonographObject))
        if distance <= 2.5 then
            closestEntity = pendingPhonographObject
            closestId = nil
            found = true
        end
    end

    promptGroup:setActive(found)
    playMusicPrompt:setVisible(found)
    playMusicPrompt:setEnabled(found)
    pickUpPrompt:setVisible(found)
    pickUpPrompt:setEnabled(found)

   -- print("[PromptDebug] Found:", found, "Closest entity:", closestEntity, "Closest ID:", closestId)
end

RegisterNetEvent('rs_phonograph:client:spawnPhonograph')
AddEventHandler('rs_phonograph:client:spawnPhonograph', function(data)
    local propModel = `p_phonograph01x`
    local x, y, z = data.x, data.y, data.z
    local rotZ = tonumber(data.rotation.z or 0.0) % 360.0
    local uniqueId = data.id

    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(10) end

    if phonographEntities[uniqueId] and DoesEntityExist(phonographEntities[uniqueId]) then
        DeleteObject(phonographEntities[uniqueId])
    end

    local object = CreateObject(propModel, 0.0, 0.0, 0.0, true, false, true)
    SetEntityCoordsNoOffset(object, x, y, z, false, false, false)
    SetEntityHeading(object, rotZ)
    FreezeEntityPosition(object, true)
    SetEntityAsMissionEntity(object, true, true)

    phonographEntities[uniqueId] = object

    CreateThread(function()
        Wait(1000)
        updatePrompts()
    end)
end)

RegisterNetEvent('rs_phonograph:client:updatePhonographId')
AddEventHandler('rs_phonograph:client:updatePhonographId', function(id)
    if lastPlacedPhonograph and lastPlacedPhonograph.entity then
        phonographEntities[id] = lastPlacedPhonograph.entity
        lastPlacedPhonograph.id = id

        if pendingPhonographObject == lastPlacedPhonograph.entity then
            pendingPhonographObject = nil
        end

        CreateThread(function()
            Wait(100)
            updatePrompts()
        end)
    end
end)

promptGroup:setOnHoldModeJustCompleted(function(group, prompt)
    if closestEntity and DoesEntityExist(closestEntity) then
        if prompt == playMusicPrompt then
            if closestId then
                OpenPhonographMenu(closestEntity, closestId)
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.UnregisteredMessage, "generic_textures", "tick", 3000, "GREEN")
            end
        elseif prompt == pickUpPrompt then
            if closestId then
                TriggerServerEvent('rs_phonograph:server:pickUpByOwner', closestId)
            else
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.UnregisteredMessage, "generic_textures", "tick", 3000, "GREEN")
            end
        end
    else
        TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.NoPhonographMessage, "menu_textures", "cross", 3000, "COLOR_RED")
    end
end)

CreateThread(function()
    Wait(1500)
    findWorldPhonographs()
    updatePrompts()
end)

CreateThread(function()
    while true do
        Wait(500)
        updatePrompts()
    end
end)

RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function()
    clearAllPhonographs()
    TriggerServerEvent("rs_phonograph:server:loadPhonographs")
    Wait(1000)
    findWorldPhonographs()
    updatePrompts()
end)

UipromptManager:startEventThread()

RegisterNetEvent('rs_phonograph:client:placePropPhonograph')
AddEventHandler('rs_phonograph:client:placePropPhonograph', function()
    local phonographModel = GetHashKey('p_phonograph01x')
    RequestModel(phonographModel)
    while not HasModelLoaded(phonographModel) do Wait(10) end

    local playerPed = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(playerPed, true))
    local ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.5, 0.0))

    local groundSuccess, groundZ = GetGroundZFor_3dCoord(ox, oy, pz, false)
    if groundSuccess then pz = groundZ end

    local object = CreateObject(phonographModel, ox, oy, pz, true, false, false)
    PlaceObjectOnGroundProperly(object)

    local posX, posY, posZ = table.unpack(GetEntityCoords(object))
    local heading = GetEntityHeading(object)

    local moveStep = 0.05
    local isPlacing = true

    FreezeEntityPosition(object, true)
    SetEntityCollision(object, false, false)
    SetEntityAlpha(object, 150, false)
    SendNUIMessage({ action = "show" })

    CreateThread(function()
        while isPlacing do
            Wait(0)
            local moved = false

            if IsControlPressed(0, 0x6319DB71) then posY = posY + moveStep; moved = true end
            if IsControlPressed(0, 0x05CA7C52) then posY = posY - moveStep; moved = true end
            if IsControlPressed(0, 0xA65EBAB4) then posX = posX - moveStep; moved = true end
            if IsControlPressed(0, 0xDEB34313) then posX = posX + moveStep; moved = true end
            if IsControlPressed(0, 0xB03A913B) then posZ = posZ + moveStep; moved = true end
            if IsControlPressed(0, 0x42385422) then posZ = posZ - moveStep; moved = true end
            if IsControlPressed(0, 0xE6F612E4) then heading = heading + 5; moved = true end
            if IsControlPressed(0, 0x1CE6D9EB) then heading = heading - 5; moved = true end

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

            if moved then
                SetEntityCoords(object, posX, posY, posZ, true, true, true, false)
                SetEntityHeading(object, heading)
            end

            if IsControlJustPressed(0, 0xC7B5340A) then
                isPlacing = false

                FreezeEntityPosition(object, true)
                SetEntityAlpha(object, 255, false)
                SetEntityCollision(object, true, true)

                local pos = GetEntityCoords(object)
                local rot = GetEntityRotation(object, 2)

                lastPlacedPhonograph = {
                    entity = object,
                    coords = pos,
                    rotation = rot
                }

                TriggerServerEvent('rs_phonograph:server:saveOwner', pos, rot)
                TriggerServerEvent("rs_phonograph:givePhonograph")
                TriggerEvent("vorp:NotifyLeft", Config.Notify.Phono, Config.Notify.Place, "generic_textures", "tick", 500, "GREEN")
                SendNUIMessage({ action = "hide" })

                updatePrompts()
            end
        end
    end)
end)

RegisterNetEvent('rs_phonograph:client:removePhonograph')
AddEventHandler('rs_phonograph:client:removePhonograph', function(uniqueId)
    local entity = phonographEntities[uniqueId]
    if entity and DoesEntityExist(entity) then
        DeleteObject(entity)
    end
    phonographEntities[uniqueId] = nil
end)

local function getSoundName(uniqueId)
    return tostring(uniqueId)
end

RegisterNetEvent('rs_phonograph:client:playMusic')
AddEventHandler('rs_phonograph:client:playMusic', function(uniqueId, coords, url, volume)
    local soundName = getSoundName(uniqueId)

    exports.xsound:PlayUrlPos(soundName, url, volume, coords)
    exports.xsound:Distance(soundName, 10)

    if Config.WithEffect then
        local effectSoundName = soundName .. "_effect"
        local effectVolume = volume * Config.VolumeEffect
        exports.xsound:PlayUrlPos(effectSoundName, "https://www.youtube.com/watch?v=m5Mz9Tqs9CE", effectVolume, coords)
        exports.xsound:Distance(effectSoundName, 10)
    end

    if exports.xsound.onPlayEnd then
        exports.xsound:onPlayEnd(soundName, function()
            local effectSoundName = soundName .. "_effect"
            if exports.xsound:soundExists(effectSoundName) then
                exports.xsound:Destroy(effectSoundName)
            end

            TriggerServerEvent('rs_phonograph:server:soundEnded', uniqueId)
        end)
    end
end)

RegisterNetEvent('rs_phonograph:client:stopMusic')
AddEventHandler('rs_phonograph:client:stopMusic', function(uniqueId)
    local soundName = getSoundName(uniqueId)
    local effectSoundName = soundName .. "_effect"

    if exports.xsound:soundExists(soundName) then
        exports.xsound:Destroy(soundName)
    end

    if exports.xsound:soundExists(effectSoundName) then
        exports.xsound:Destroy(effectSoundName)
    end

    TriggerServerEvent('rs_phonograph:server:soundEnded', uniqueId)
end)

RegisterNetEvent('rs_phonograph:client:setVolume')
AddEventHandler('rs_phonograph:client:setVolume', function(uniqueId, newVolume)
    local soundName = getSoundName(uniqueId)

    if exports.xsound:soundExists(soundName) then
        exports.xsound:setVolume(soundName, newVolume)
    end

    if Config.WithEffect then
        local effectSoundName = soundName .. "_effect"
        if exports.xsound:soundExists(effectSoundName) then
            exports.xsound:setVolume(effectSoundName, newVolume * Config.VolumeEffect)
        end
    end
end)
