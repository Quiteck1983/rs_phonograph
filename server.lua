local VORPcore = exports.vorp_core:GetCore()
local VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local currentlyPlaying = {}

RegisterNetEvent('rs_phonograph:server:playMusic')
AddEventHandler('rs_phonograph:server:playMusic', function(uniqueId, coords, url, volume)
    if currentlyPlaying[uniqueId] then return end

    currentlyPlaying[uniqueId] = {
        url = url,
        volume = volume,
        coords = coords
    }

    TriggerClientEvent('rs_phonograph:client:playMusic', -1, uniqueId, coords, url, volume)
end)

RegisterNetEvent('rs_phonograph:server:stopMusic')
AddEventHandler('rs_phonograph:server:stopMusic', function(uniqueId)
    currentlyPlaying[uniqueId] = nil
    TriggerClientEvent('rs_phonograph:client:stopMusic', -1, uniqueId)
end)

RegisterNetEvent('rs_phonograph:server:setVolume')
AddEventHandler('rs_phonograph:server:setVolume', function(uniqueId, newVolume)
    if currentlyPlaying[uniqueId] then
        currentlyPlaying[uniqueId].volume = newVolume
        TriggerClientEvent('rs_phonograph:client:setVolume', -1, uniqueId, newVolume)
    end
end)

RegisterNetEvent('rs_phonograph:server:soundEnded')
AddEventHandler('rs_phonograph:server:soundEnded', function(uniqueId)
    currentlyPlaying[uniqueId] = nil
end)

RegisterNetEvent('rs_phonograph:server:saveOwner')
AddEventHandler('rs_phonograph:server:saveOwner', function(coords, rotation)
    local src = source
    local User = VORPcore.getUser(src)
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character then return end

    local u_identifier = Character.identifier
    local u_charid = Character.charIdentifier

    local rotX = rotation.x
    local rotY = rotation.y
    local rotZ = rotation.z

    local query = [[
        INSERT INTO phonographs (owner_identifier, owner_charid, x, y, z, rot_x, rot_y, rot_z)
        VALUES (@identifier, @charid, @x, @y, @z, @rot_x, @rot_y, @rot_z)
    ]]

    local params = {
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
        if result and result.insertId then

            local phonographData = {
                id = result.insertId,
                x = coords.x,
                y = coords.y,
                z = coords.z,
                rotation = {
                    x = rotX,
                    y = rotY,
                    z = rotZ,
                }
            }

            TriggerClientEvent('rs_phonograph:client:updatePhonographId', -1, result.insertId)
        end
    end)
end)

RegisterNetEvent('rs_phonograph:server:pickUpByOwner')
AddEventHandler('rs_phonograph:server:pickUpByOwner', function(uniqueId)
    local src = source
    local User = VORPcore.getUser(src)
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character then return end

    local u_identifier = Character.identifier
    local u_charid = Character.charIdentifier

    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)

    exports.oxmysql:execute(
        'SELECT * FROM phonographs WHERE id = ? AND owner_identifier = ? AND owner_charid = ?',
        {uniqueId, u_identifier, u_charid},
        function(results)
            if results and #results > 0 then
                local row = results[1]
                local phonoCoords = vector3(row.x, row.y, row.z)
                local distance = #(playerCoords - phonoCoords)

                if distance <= 2.5 then
                    TriggerClientEvent('rs_phonograph:client:removePhonograph', -1, uniqueId)

                    if currentlyPlaying[uniqueId] then
                        TriggerClientEvent('rs_phonograph:client:stopMusic', -1, uniqueId)
                        currentlyPlaying[uniqueId] = nil
                    end

                    exports.oxmysql:execute(
                        'DELETE FROM phonographs WHERE id = ?',
                        {uniqueId},
                        function(result)
                            local affected = result and (result.affectedRows or result.affected_rows or result.changes)
                            if affected and affected > 0 then
                                VorpInv.addItem(src, Config.PhonoItems, 1)
                                VORPcore.NotifyLeft(src, Config.Text.Phono, Config.Text.Picked, "generic_textures", "tick", 4000, "GREEN")
                            end
                        end
                    )
                end
            else
                VORPcore.NotifyLeft(src, Config.Text.Phono, Config.Text.Dont, "menu_textures", "cross", 3000, "COLOR_RED")
            end
        end
    )
end)

local function loadPhonographs(targetPlayer)
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
                TriggerClientEvent('rs_phonograph:client:spawnPhonograph', targetPlayer, phonographData)
            end
        end
    end)
end

RegisterNetEvent('rs_phonograph:server:loadPhonographs')
AddEventHandler('rs_phonograph:server:loadPhonographs', function()
    local src = source
    loadPhonographs(src)
end)

VorpInv.RegisterUsableItem(Config.PhonoItems, function(data)
    local src = data.source
    local User = VORPcore.getUser(src)
    if not User then return end
    local Character = User.getUsedCharacter
    if not Character then return end

    local identifier = Character.identifier
    local charid = Character.charIdentifier
    VorpInv.CloseInv(src)

    exports.oxmysql:execute('SELECT id FROM phonographs WHERE owner_identifier = ? AND owner_charid = ?', {
        identifier, charid
    }, function(result)
        if result and #result > 0 then
            VORPcore.NotifyLeft(src, Config.Notify.Phono, Config.Notify.Already, "menu_textures", "cross", 3000, "COLOR_RED")
        else
            TriggerClientEvent("rs_phonograph:client:placePropPhonograph", src)
        end
    end)
end)

RegisterNetEvent("rs_phonograph:givePhonograph", function()
    local src = source
    VorpInv.subItem(src, Config.PhonoItems, 1)
end)
