local QBCore = exports['qb-core']:GetCoreObject()
local housePlants, currentHouse, plantSpawned, closestPlant = {}, nil, false, 0

local function drawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function spawnHousePlants()
    if not currentHouse or plantSpawned or not housePlants[currentHouse] then return end
    CreateThread(function()
        for k in pairs(housePlants[currentHouse]) do
            local plantData = {
                ["plantCoords"] = json.decode(housePlants[currentHouse][k].coords),
                ["plantProp"] = joaat(QBWeed.Plants[housePlants[currentHouse][k].sort].stages[housePlants[currentHouse][k].stage]),
            }

            local plantProp = CreateObject(plantData["plantProp"], plantData["plantCoords"].x, plantData["plantCoords"].y, plantData["plantCoords"].z, false, false, false)
            while not plantProp do Wait(0) end
            PlaceObjectOnGroundProperly(plantProp)
            Wait(10)
            FreezeEntityPosition(plantProp, true)
            SetEntityAsMissionEntity(plantProp, false, false)
        end
        plantSpawned = true
    end)
end

local function updateHousePlants(leftHouse)
    if not plantSpawned or not currentHouse then return end
    CreateThread(function()
        for k in pairs(housePlants[currentHouse]) do
            local plantData = {
                ["plantCoords"] = json.decode(housePlants[currentHouse][k].coords),
            }

            for _, stage in pairs(QBWeed.Plants[housePlants[currentHouse][k].sort]["stages"]) do
                local oldPlant = GetClosestObjectOfType(plantData["plantCoords"].x, plantData["plantCoords"].y, plantData["plantCoords"].z, 3.5, GetHashKey(stage), false, false, false)
                if oldPlant ~= 0 then
                    DeleteObject(oldPlant)
                end
            end
        end
        plantSpawned = false
        if leftHouse then
            housePlants[currentHouse] = nil
            currentHouse = nil
        else
            QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
                housePlants[currentHouse] = plants
                spawnHousePlants()
            end, currentHouse)
        end
    end)
end

local function getPlantData()
    return {
        ["plantCoords"] = json.decode(housePlants[currentHouse][closestPlant].coords),
        ["plantStage"] = housePlants[currentHouse][closestPlant].stage,
        ["plantProp"] = GetHashKey(QBWeed.Plants[housePlants[currentHouse][closestPlant].sort]["stages"][housePlants[currentHouse][closestPlant].stage]),
        ["plantSort"] = {
            ["name"] = housePlants[currentHouse][closestPlant].sort,
            ["label"] = QBWeed.Plants[housePlants[currentHouse][closestPlant].sort]["label"],
        },
        ["plantStats"] = {
            ["food"] = housePlants[currentHouse][closestPlant].food,
            ["health"] = housePlants[currentHouse][closestPlant].health,
            ["progress"] = housePlants[currentHouse][closestPlant].progress,
            ["stage"] = housePlants[currentHouse][closestPlant].stage,
            ["highestStage"] = QBWeed.Plants[housePlants[currentHouse][closestPlant].sort]["highestStage"],
            ["gender"] = (housePlants[currentHouse][closestPlant].gender == "woman") and "F" or "M",
            ["plantId"] = housePlants[currentHouse][closestPlant].plantid,
        }
    }
end

local function inHouse()
    CreateThread(function()
        while currentHouse do
            local plyCoords = GetEntityCoords(PlayerPedId())
            closestPlant = 0
            for k in pairs(housePlants[currentHouse]) do
                local plantCoords = json.decode(housePlants[currentHouse][k].coords)
                if #(plyCoords - vector3(plantCoords.x, plantCoords.y, plantCoords.z)) < 0.8 then
                    closestPlant = k
                    break
                end
            end
            Wait(100)
        end
    end)
    CreateThread(function()
        while currentHouse do
            Wait(0)
            if plantSpawned and closestPlant ~= 0 then
                local plantData, status = getPlantData(), 0
                local plantInfoLabel = Lang:t('text.sort')..' ~g~' ..plantData["plantSort"]["label"]..'~w~ ['..plantData["plantStats"]["gender"]..'] | '..Lang:t('text.nutrition')..' ~b~'..plantData["plantStats"]["food"]..'% ~w~ | '..Lang:t('text.health')..' ~b~'..plantData["plantStats"]["health"]..'%'
                local plantStageLabel = Lang:t('text.stage').. ' ~b~' .. QBWeed.StageLabels[plantData["plantStats"]["stage"]] ..' ~w~' ..Lang:t('text.progress')..' ~b~'..plantData["plantStats"]["progress"]..'% ~w~ / ' ..Lang:t('text.highestStage') .. ' ~b~' .. QBWeed.StageLabels[plantData["plantStats"]["highestStage"]]
                local plantActionLabel

                if plantData["plantStats"]["health"] > 0 and plantData["plantStage"] == plantData["plantStats"]["highestStage"] then
                    status = 1
                    plantStageLabel = nil
                    plantActionLabel = Lang:t('text.harvest_plant')
                elseif plantData["plantStats"]["health"] == 0 then
                    status = 2
                    plantStageLabel = nil
                    plantActionLabel = Lang:t('error.plant_has_died')
                end

                if plantInfoLabel then drawText3Ds(plantData["plantCoords"].x, plantData["plantCoords"].y, plantData["plantCoords"].z, plantInfoLabel) end
                if plantStageLabel and QBWeed.ShowStages then drawText3Ds(plantData["plantCoords"].x, plantData["plantCoords"].y, plantData["plantCoords"].z - 0.1, plantStageLabel) end
                if plantActionLabel then drawText3Ds(plantData["plantCoords"].x, plantData["plantCoords"].y, plantData["plantCoords"].z + 0.2, plantActionLabel) end

                if status > 0 and IsControlJustPressed(0, 38) then
                    local ped = PlayerPedId()

                    QBCore.Functions.Progressbar("remove_weed_plant", Lang:t((status == 1) and 'text.harvesting_plant' or 'text.removing_the_plant'), 8000, false, true, {
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
                        if status == 1 then
                            local amount = math.random(1, (plantData["plantStats"]["gender"] == "M") and 2 or 6)
                            TriggerServerEvent('qb-weed:server:harvestPlant', currentHouse, amount, plantData["plantSort"]["name"], plantData["plantStats"]["plantId"])
                        else
                            TriggerServerEvent('qb-weed:server:removeDeathPlant', currentHouse, plantData["plantStats"]["plantId"])
                        end
                    end, function() -- Cancel
                        ClearPedTasks(ped)
                        QBCore.Functions.Notify(Lang:t('error.process_canceled'), "error")
                    end)
                end
            else
                Wait(100)
            end
        end
    end)
end

RegisterNetEvent('qb-weed:client:getHousePlants', function(house)
    QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
        currentHouse = house
        housePlants[currentHouse] = plants
        spawnHousePlants()
        inHouse()
    end, house)
end)

RegisterNetEvent('qb-weed:client:leaveHouse', function()
    updateHousePlants(true)
end)

RegisterNetEvent('qb-weed:client:refreshHousePlants', function(house)
    if currentHouse == house or not house then
        updateHousePlants(false)
    end
end)

RegisterNetEvent('qb-weed:client:placePlant', function(type, item)
    if not currentHouse then QBCore.Functions.Notify(Lang:t('error.not_safe_here'), 'error', 3500) return end
    if closestPlant ~= 0 then QBCore.Functions.Notify(Lang:t('error.cant_place_here'), 'error', 3500) return end
    local ped = PlayerPedId()
    local plantCoords = GetOffsetFromEntityInWorldCoords(ped, 0, 0.75, 0)
    local plantData = {
        ["plantCoords"] = {["x"] = plantCoords.x, ["y"] = plantCoords.y, ["z"] = plantCoords.z},
        ["plantModel"] = QBWeed.Plants[type]["stages"]["stage-a"],
        ["plantLabel"] = QBWeed.Plants[type]["label"]
    }

    LocalPlayer.state:set("inv_busy", true, true)
    QBCore.Functions.Progressbar("plant_weed_plant", Lang:t('text.planting'), 8000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "amb@world_human_gardener_plant@male@base",
        anim = "base",
        flags = 16,
        LocalPlayer.state:set("inv_busy", false, true)
    }, {}, {}, function() -- Done
        ClearPedTasks(ped)
        TriggerServerEvent('qb-weed:server:placePlant', json.encode(plantData["plantCoords"]), type, currentHouse)
        TriggerServerEvent('qb-weed:server:removeSeed', item.slot, type)
    end, function() -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify(Lang:t('error.process_canceled'), "error")
        LocalPlayer.state:set("inv_busy", false, true)
    end)
end)

RegisterNetEvent('qb-weed:client:foodPlant', function()
    if not currentHouse then return end
    if closestPlant ~= 0 then
        local ped = PlayerPedId()
        local plantData = getPlantData()

        if plantData["plantStats"]["food"] == 100 then
            QBCore.Functions.Notify(Lang:t('error.not_need_nutrition'), 'error', 3500)
        else
            LocalPlayer.state:set("inv_busy", true, true)
            QBCore.Functions.Progressbar("plant_weed_plant", Lang:t('text.feeding_plant'), math.random(4000, 8000), false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "timetable@gardener@filling_can",
                anim = "gar_ig_5_filling_can",
                flags = 16,

                LocalPlayer.state:set("inv_busy", false, true)
            }, {}, {}, function() -- Done
                ClearPedTasks(ped)
                local newFood = math.random(40, 60)
                TriggerServerEvent('qb-weed:server:foodPlant', currentHouse, newFood, plantData["plantSort"]["name"], plantData["plantStats"]["plantId"])
            end, function() -- Cancel
                ClearPedTasks(ped)
                LocalPlayer.state:set("inv_busy", false, true)
                QBCore.Functions.Notify(Lang:t('error.process_canceled'), "error")
            end)
        end
    else
        QBCore.Functions.Notify(Lang:t('error.cant_place_here'), "error")
    end
end)
