local VORPcore = exports.vorp_core:GetCore()
local VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local spawnedPhonograph = false
local objectPosition = {}
local currentlyPlaying = {}

RegisterNetEvent('rs_phonograph:server:playMusic')
AddEventHandler('rs_phonograph:server:playMusic', function(id, coords, url, volume)
    if currentlyPlaying[id] then
        return -- Ya está sonando, no hacer nada
    end

    currentlyPlaying[id] = {
        url = url,
        volume = volume or Config.volumeDefault,
        coords = coords,
    }

    TriggerClientEvent('rs_phonograph:client:playMusic', -1, id, coords, url, volume)

    SetTimeout(60000, function()
        currentlyPlaying[id] = nil
    end)
end)

RegisterNetEvent('rs_phonograph:server:saveOwner')
AddEventHandler('rs_phonograph:server:saveOwner', function(id, coords, rotation)
    local src = source
    local User = VORPcore.getUser(src)
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character then return end

    local u_identifier = Character.identifier
    local u_charid = Character.charIdentifier

    -- Normalizar rotación si es necesario (puedes quitar si no lo usas)
    local rotX = rotation.x
    local rotY = rotation.y 
    local rotZ = rotation.z

    local query = [[
        INSERT INTO phonographs (id, owner_identifier, owner_charid, x, y, z, rot_x, rot_y, rot_z)
        VALUES (@id, @identifier, @charid, @x, @y, @z, @rot_x, @rot_y, @rot_z)
    ]]

    local params = {
        ['@id'] = id,
        ['@identifier'] = u_identifier,
        ['@charid'] = u_charid,
        ['@x'] = coords.x,
        ['@y'] = coords.y,
        ['@z'] = coords.z,
        ['@rot_x'] = rotX,
        ['@rot_y'] = rotY,
        ['@rot_z'] = rotZ
    }

    exports.oxmysql:execute(query, params, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
        end
    end)
end)

RegisterNetEvent('rs_phonograph:server:pickUpByOwner')
AddEventHandler('rs_phonograph:server:pickUpByOwner', function()
    local src = source
    local User = VORPcore.getUser(src)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    local u_identifier = Character.identifier
    local u_charid = Character.charIdentifier

    exports.oxmysql:execute(
        'SELECT id FROM phonographs WHERE owner_identifier = ? AND owner_charid = ?',
        {u_identifier, u_charid},
        function(results)
            if results and #results > 0 then
                for _, row in ipairs(results) do
                    local phonographId = row.id
                    TriggerClientEvent('rs_phonograph:client:removePhonograph', -1, phonographId)
                    if currentlyPlaying and currentlyPlaying[phonographId] then
                        TriggerClientEvent('rs_phonograph:client:stopMusic', -1, phonographId)
                        currentlyPlaying[phonographId] = nil
                    end
                end

                exports.oxmysql:execute(
                    'DELETE FROM phonographs WHERE owner_identifier = ? AND owner_charid = ?',
                    {u_identifier, u_charid},
                    function(result)
                        if result and result.affectedRows and result.affectedRows > 0 then
                            exports.vorp_inventory:addItem(src, "phonograph", 1)
                            VORPcore.NotifyLeft(src, Config.Text.Phono, Config.Text.Picked, "generic_textures", "tick", 4000, "GREEN")
                        end
                    end
                )
            else
                VORPcore.NotifyLeft(src, Config.Text.Phono, Config.Text.Dont, "menu_textures", "cross", 4000, "COLOR_RED")
            end
        end
    )
end)

local function loadPhonographs()
    exports.oxmysql:execute('SELECT * FROM phonographs', {}, function(results)
        if results then
            for _, row in pairs(results) do
                local phonographData = {
                    id = row.id,
                    x = row.x,
                    y = row.y,
                    z = row.z,
                    rotation = {
                        x = row.rot_x,
                        y = row.rot_y,
                        z = row.rot_z,
                    }
                }
                TriggerClientEvent('rs_phonograph:client:spawnPhonograph', -1, phonographData)
            end
        end
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadPhonographs()
    end
end)

VorpInv.RegisterUsableItem("phonograph", function(data)
    local src = data.source
    TriggerClientEvent("rs_phonograph:client:placePropPhonograph", src)
    VorpInv.subItem(src, "phonograph", 1)
    VorpInv.CloseInv(src)
end)

RegisterNetEvent('rs_phonograph:server:stopMusic')
AddEventHandler('rs_phonograph:server:stopMusic', function(id)
    if currentlyPlaying[id] then
        TriggerClientEvent('rs_phonograph:client:stopMusic', -1, id)
        currentlyPlaying[id] = nil
    end
end)

RegisterNetEvent('rs_phonograph:server:setVolume')
AddEventHandler('rs_phonograph:server:setVolume', function(id, volume)
    TriggerClientEvent('rs_phonograph:client:setVolume', -1, id, volume)
end)

RegisterNetEvent("rs_phonograph:server:loadPhonographs")
AddEventHandler("rs_phonograph:server:loadPhonographs", function()
    local src = source
    loadPhonographs(src)
end)
