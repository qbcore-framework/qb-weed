local currHouse = nil
local housePlants = {}
local houseProps = {}

DrawText3Ds = function(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(100)
    end
end

-- Helper functions
local function insideHouse()
    return (currHouse ~= nil)
end

local function hasEnoughWeedBags(gender, amount)
    return (amount >= QBWeed.Harvest[gender]["Bags"]["Max"])
end

local function getClosestPlantId(x, y, z)
    local closestPlantId = 0
    local closestDistance = 10000

    for id, plant in pairs(housePlants) do
        local coords = json.decode(plant.coords)
        local plyDistance = #(vector3(x, y, z) - vector3(coords.x, coords.y, coords.z))
        if plyDistance < closestDistance then
            closestPlantId = id
            closestDistance = plyDistance
        end
    end

    return closestPlantId, closestDistance
end

local function renderPlant(id)
    if (insideHouse() and housePlants[id] ~= nil and houseProps[id] == nil) then
        Citizen.CreateThread(function()
            local plant = housePlants[id]
            local coords = json.decode(plant.coords)
            local hash = GetHashKey(QBWeed.Plants[plant.sort]["stages"][plant.stage])
            local propOffset = QBWeed.PropOffsets[plant.stage]
            local prop = CreateObject(hash, coords.x, coords.y, coords.z - propOffset, false, false, false)
            while not prop do Wait(0) end
            FreezeEntityPosition(prop, true)
            SetEntityAsMissionEntity(prop, false, false)
            houseProps[id] = prop
        end)
    end
end
local function unrenderPlant(id)
    if (houseProps[id] ~= nil) then
        DeleteObject(houseProps[id])
        houseProps[id] = nil
    end
end

local function renderPlants()
    for id, _ in pairs(housePlants) do
        renderPlant(id)
    end
end
local function unrenderPlants()
    for id, _ in pairs(housePlants) do
        unrenderPlant(id)
    end
end

local function populateHousePlants(plants)
    for _, plant in pairs(plants) do
        housePlants[plant.id] = plant
    end
end
local function updateHousePlant(id)
    if insideHouse() then
        QBCore.Functions.TriggerCallback('qb-weed:server:getHousePlant', function(plant)
            if next(plant) ~= nil then
                populateHousePlants(plant)
                renderPlant(id)
            end
        end, currHouse, id)
    end
end
local function updateHousePlants()
    if insideHouse() then
        QBCore.Functions.TriggerCallback('qb-weed:server:getHousePlants', function(plants)
            if next(plants) ~= nil then
                populateHousePlants(plants)
                renderPlants()
            end
        end, currHouse)
    end
end

-- Actions
local function placeAction(ped, house, coords, sort, slot)
    QBCore.Functions.Progressbar("plant_weed_plant", "Planting", QBWeed.ActionTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "amb@world_human_gardener_plant@male@base",
        anim = "base",
        flags = 16,
    }, {}, {}, function() -- Done
        ClearPedTasks(ped)
        TriggerServerEvent('qb-weed:server:placePlant', house, coords, sort, slot)
    end, function() -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Process cancelled", "error")
    end)
end
local function fertilizeAction(ped, house, plant)
    QBCore.Functions.Progressbar("plant_weed_plant", "Feeding Plant", QBWeed.ActionTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "timetable@gardener@filling_can",
        anim = "gar_ig_5_filling_can",
        flags = 16,
    }, {}, {}, function() -- Done
        ClearPedTasks(ped)
        TriggerServerEvent('qb-weed:server:fertilizePlant', house, plant)
    end, function() -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Process cancelled", "error")
    end)
end
local function harvestAction(ped, house, plant)
    QBCore.Functions.TriggerCallback('qb-weed:server:getWeedBagAmount', function(weedBagAmount)
        if hasEnoughWeedBags(plant.gender, weedBagAmount) then
            QBCore.Functions.Progressbar("remove_weed_plant", "Harvesting Plant", QBWeed.HarvestTime, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "amb@world_human_gardener_plant@male@base",
                anim = "base",
                flags = 16,
            }, {}, {}, function() -- Done
                ClearPedTasks(ped)
                TriggerServerEvent('qb-weed:server:harvestPlant', house, plant)
            end, function() -- Cancel
                ClearPedTasks(ped)
                QBCore.Functions.Notify("Process cancelled", "error")
            end)
        else
            QBCore.Functions.Notify("Not enough empty weed bags", "error", 3500)
        end
    end)
end
local function deathAction(ped, house, plant)
    QBCore.Functions.Progressbar("remove_weed_plant", "Removing The Plant", QBWeed.ActionTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "amb@world_human_gardener_plant@male@base",
        anim = "base",
        flags = 16,
    }, {}, {}, function() -- Done
        ClearPedTasks(ped)
        TriggerServerEvent('qb-weed:server:removePlant', house, plant)
    end, function() -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Process cancelled", "error")
    end)
end

-- Event triggered upon entrance to a house
-- Should really be named enterHouse
RegisterNetEvent('qb-weed:client:getHousePlants', function(house)
    if not insideHouse() then
        currHouse = house
        updateHousePlants()
    end
end)
-- Event triggered upon exiting a house
RegisterNetEvent('qb-weed:client:leaveHouse', function()
    if insideHouse() then
        unrenderPlants()
        currHouse = nil
        housePlants = {}
    end
end)

-- Event triggered by the server when a single plant is fertilized
RegisterNetEvent('qb-weed:client:refreshPlantStats', function (id, food, health)
    if insideHouse() then
        if housePlants[id] == nil then
            updateHousePlant(id)
        else
            housePlants[id].food = food
            housePlants[id].health = health
        end
    end
end)
-- Event triggered by the server to refresh model after stage update, manually maintains state of houseProps
RegisterNetEvent('qb-weed:client:refreshPlantProp', function(id, newStage)
    if insideHouse() then
        if housePlants[id] == nil then
            updateHousePlant(id)
        else
            housePlants[id].stage = newStage
            housePlants[id].progress = 0
            unrenderPlant(id)
            renderPlant(id)
        end
    end
end)

-- Event triggered by the server when client attempt to place a plant
RegisterNetEvent('qb-weed:client:placePlant', function(sort, item)
    if (insideHouse()) then
        local ped = PlayerPedId()
        local pedOffset = QBWeed.MinProximity/2
        local placeCoords = GetOffsetFromEntityInWorldCoords(ped, 0, pedOffset, 0)
        
        local canPlace = true
        local closestPlantId, distance = getClosestPlantId(placeCoords.x, placeCoords.y, placeCoords.z)

        if closestPlantId ~= 0 and distance < QBWeed.MinProximity then
            QBCore.Functions.Notify("Too close to another plant", 'error', 3500)
        else
            placeAction(ped, currHouse, placeCoords, sort, item.slot)
        end
    else
        QBCore.Functions.Notify("It's not safe here, try your house", 'error', 3500)
    end
end)

-- Event triggered by the server when client attempts to fertilize a plant
RegisterNetEvent('qb-weed:client:fertilizePlant', function(item)
    if (insideHouse()) then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        local canFertilize = true
        local closestPlantId, distance = getClosestPlantId(coords.x, coords.y, coords.z)

        if closestPlantId ~= 0 and distance < QBWeed.ActionDistance then
            local plant = housePlants[closestPlantId]
            
            if plant.health <= 0 then
                QBCore.Functions.Notify('Can\'t fertilize a dead plant', 'error', 3500)
            elseif plant.food >= 100 then
                QBCore.Functions.Notify('Plant is already fertilized', 'error', 3500)
            else
                fertilizeAction(ped, currHouse, plant)
            end
        else
            QBCore.Functions.Notify("Must be near a weed plant", "error")
        end
    end
end)

-- Event triggered by the server when it has to remove a plant
RegisterNetEvent('qb-weed:client:removePlant', function(id)
    if insideHouse() then
        unrenderPlant(id)
        housePlants[id] = nil
    end
end)

-- Client harvest and inspect interactivity
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if insideHouse() then
            local ped = PlayerPedId()

            for id, plant in pairs(housePlants) do
                local coords = json.decode(plant.coords)
                local label = QBWeed.Plants[plant.sort]["label"]
                local plyDistance = #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z))

                -- Plant stats
                if plant ~= nil and plyDistance < QBWeed.MinProximity then
                    local foodColor = "b"
                    if plant.food <= QBWeed.MinimumFood then foodColor = "r" end
                    local healthColor = "b"
                    if plant.health <= QBWeed.MinimumHealth then healthColor = "r" end

                    if plant.health > 0 then
                        DrawText3Ds(coords.x, coords.y, coords.z,
                            'Sort: ~g~'..label..'~w~ ['..plant.gender..'] | Nutrition: ~' ..foodColor..'~'..plant.food..'% ~w~ | Health: ~'..healthColor..'~'..plant.health..'%')
                    else
                        DrawText3Ds(coords.x, coords.y, coords.z,
                            'Sort: ~g~'..label..'~w~ ['..plant.gender..'] | Health: ~'..healthColor..'~'..plant.health..'%')
                    end
                end

                -- Plant Actions
                local actionMsgOffset = 0.15
                if plant ~= nil and plyDistance < QBWeed.ActionDistance then
                    if plant.health > 0 then
                        if plant.stage == QBWeed.Plants[plant.sort]["highestStage"] then
                            DrawText3Ds(coords.x, coords.y, coords.z + actionMsgOffset, "Press ~g~ E ~w~ to harvest plant.")
                            if IsControlJustPressed(0, 38) then
                                harvestAction(ped, currHouse, plant)
                            end
                        else
                            DrawText3Ds(coords.x, coords.y, coords.z + actionMsgOffset, "Trapped? Press ~r~ E ~w~ to remove plant.")
                            if IsControlJustPressed(0, 38) then
                                deathAction(ped, currHouse, plant)
                            end
                        end
                    else 
                        DrawText3Ds(coords.x, coords.y, coords.z + actionMsgOffset, 'This plant is dead. Press ~r~ E ~w~ to remove plant.')
                        if IsControlJustPressed(0, 38) then
                            deathAction(ped, currHouse, plant)
                        end
                    end
                end
            end
        end

        if not insideHouse() then
            Citizen.Wait(5000)
        end
    end
end)