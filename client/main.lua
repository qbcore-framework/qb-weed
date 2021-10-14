local isLoggedIn = true
local currHouse = nil
local closestPlantid = 0
local housePlants = {}
local houseProps = {}
local minProximity = 0.8

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
local function populateHousePlants(plants)
    for _, plant in pairs(plants) do
        housePlants[plant.plantid] = plant
    end
end
local function updateHousePlant(plantid)
    QBCore.Functions.TriggerCallback('qb-weed:server:getHousePlant', function(plant)
        populateHousePlants(plant)
    end, currHouse, plantid)
end
local function updateHousePlants()
    if insideHouse() then
        QBCore.Functions.TriggerCallback('qb-weed:server:getHousePlants', function(plants)
            populateHousePlants(plants)
        end, currHouse)
    end
end

local function renderPlant(plantid)
    if (insideHouse() and housePlants[plantid] ~= nil) then
        Citizen.CreateThread(function()
            local plant = housePlants[plantid]
            local coords = json.decode(plant.coords)
            local hash = GetHashKey(QBWeed.Plants[plant.sort]["stages"][plant.stage])
            local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
            while not prop do Wait(0) end
            PlaceObjectOnGroundProperly(prop)
            Wait(100)
            FreezeEntityPosition(prop, true)
            SetEntityAsMissionEntity(prop, false, false)
            houseProps[plantid] = prop
        end)
    end
end
local function unrenderPlant(plantid)
    if (houseProps[plantid] ~= nil) then
        local prop = houseProps[plantid]
        houseProps[plantid] = nil
        DeleteObject(prop)
    end
end

local function renderPlants()
    for plantid, _ in pairs(housePlants) do
        renderPlant(plantid)
    end
end
local function unrenderPlants()
    for plantid, _ in pairs(housePlants) do
        unrenderPlant(plantid)
    end
end

-- Event triggered upon entrance to a house
RegisterNetEvent('qb-weed:client:enterHouse', function(house)
    if not insideHouse() then
        currHouse = house
        updateHousePlants()
        renderPlants()
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
RegisterNetEvent('qb-weed:client:refreshPlantStats', function (plantid)
    updateHousePlant(plantid)
end)
-- Event triggered by the server when a growth cycle or a food and nutrition cycle occurs
RegisterNetEvent('qb-weed:client:refreshAllPlantStats', function ()
    updateHousePlants()
end)
-- Event triggered by the server to refresh model after stage update, manually maintains state of houseProps
RegisterNetEvent('qb-weed:client:refreshPlantProp', function(plantid, newStage)
    if insideHouse() then
        housePlants[plantid].stage = newStage
        housePlants[plantid].progress = 0
        unrenderPlant(plantid)
        renderPlant(plantid)
    end
end)
-- Event triggered by the server when it has to render a new model for a plant
RegisterNetEvent('qb-weed:client:renderNewPlant', function(plantid)
    if insideHouse() then
        renderPlant(plantid)
    end
end)

-- Event triggered by the server when client attempt to place a plant
RegisterNetEvent('qb-weed:client:placePlant', function(sort, item)
    if insideHouse() then
        local ped = PlayerPedId()
        local pedOffset = 0.75
        local plantCoords = GetOffsetFromEntityInWorldCoords(ped, 0, pedOffset, 0)

        -- Check if any plants are too close in proximity to new position
        local closestPlant = nil
        for _, prop in pairs(QBWeed.Props) do
            if not closestPlant then
                closestPlant = GetClosestObjectOfType(plantCoords.x, plantCoords.y, plantCoords.z, minProximity, GetHashKey(prop), false, false, false)
            end
        end

        if closestPlant ~= nil then
            QBCore.Functions.Progressbar("plant_weed_plant", "Planting", 8000, false, true, {
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
                TriggerServerEvent('qb-weed:server:placePlant', currHouse, plantCoords, sort, item.slot)
            end, function() -- Cancel
                ClearPedTasks(ped)
                QBCore.Functions.Notify("Process Cancelled", "error")
            end)
        else
            QBCore.Functions.Notify("Can't Place Here", 'error', 3500)
        end
    else
        QBCore.Functions.Notify("It's Not Safe Here, try your house", 'error', 3500)
    end
end)

-- Event triggered by the server when client attempts to fertilize a plant
RegisterNetEvent('qb-weed:client:fertilizePlant', function(item)
    if (insideHouse() and closestPlantid ~= 0) then
        local plant = housePlants[closestPlantid]
        local coords = json.decode(plant.coords)
        local plyDistance = #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z))

        if plyDistance < minPoximity + 0.2 then
            local ped = PlayerPedId()

            if plant.food == 100 then
                QBCore.Functions.Notify('The Plant Does Not Need Nutrition', 'error', 3500)
            else
                QBCore.Functions.Progressbar("plant_weed_plant", "Feeding Plant", math.random(4000, 8000), false, true, {
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
                    TriggerServerEvent('qb-weed:server:fertilizePlant', currHouse, plant)
                end, function() -- Cancel
                    ClearPedTasks(ped)
                    QBCore.Functions.Notify("Process Cancelled", "error")
                end)
            end
        else
            QBCore.Functions.Notify("Must Be Near A Weed Plant", "error")
        end
    end
end)

-- Event triggered by the server when it has to remove a plant
RegisterNetEvent('qb-weed:client:removePlant', function(plantid)
    if insideHouse() then
        housePlants[plantid] = nil
        unrenderPlant(plantid)
    end
end)

-- Client harvest and inspect interactivity
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if insideHouse() then
            local ped = PlayerPedId()
            for plantid, plant in pairs(housePlants) do
                local gender = "M"
                if plant.gender == "woman" then gender = "F" end
                local coords = json.decode(plant.coords)
                local label = QBWeed.Plants[plant.sort]["label"]
                local plyDistance = #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z))

                if plyDistance < minProximity then
                    closestPlantid = plantid
                    -- Plant is alive
                    if plant.health > 0 then
                        -- Plant is fully grown
                        if plant.stage == QBWeed.Plants[plant.sort]["highestStage"] then
                            DrawText3Ds(coords.x, coords.y, coords.z + 0.2, "Press ~g~ E ~w~ to harvest plant.")
                            DrawText3Ds(coords.x, coords.y, coords.z,
                                'Sort: ~g~'..label..'~w~ ['..gender..'] | Nutrition: ~b~'..plant.food..'% ~w~ | Health: ~b~'..plant.health..'%')
                            if IsControlJustPressed(0, 38) then
                                QBCore.Functions.Progressbar("remove_weed_plant", "Harvesting Plant", 8000, false, true, {
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
                                    TriggerServerEvent('qb-weed:server:harvestPlant', currHouse, plant)
                                end, function() -- Cancel
                                    ClearPedTasks(ped)
                                    QBCore.Functions.Notify("Process Cancelled", "error")
                                end)
                            end
                        -- Plant is still growing
                        else
                            DrawText3Ds(coords.x, coords.y, coords.z,
                                'Sort: '..label..'~w~ ['..gender..'] | Nutrition: ~b~'..plant.food..'% ~w~ | Health: ~b~'..plant.health..'%')
                        end
                    -- Plant is dead
                    else
                        DrawText3Ds(coords.x, coords.y, coords.z, 'The plant has died. Press ~r~ E ~w~ to remove plant.')
                        if IsControlJustPressed(0, 38) then
                            QBCore.Functions.Progressbar("remove_weed_plant", "Removing The Plant", 8000, false, true, {
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
                                TriggerServerEvent('qb-weed:server:removeDeadPlant', currHouse, plant)
                            end, function() -- Cancel
                                ClearPedTasks(ped)
                                QBCore.Functions.Notify("Process Cancelled", "error")
                            end)
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