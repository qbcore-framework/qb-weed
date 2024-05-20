local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('qb-weed:server:getBuildingPlants', function(_, cb, building)
    local buildingPlants = {}

    MySQL.query('SELECT * FROM house_plants WHERE building = ?', { building }, function(plants)
        for i = 1, #plants, 1 do
            buildingPlants[#buildingPlants + 1] = plants[i]
        end

        cb(buildingPlants)
    end)
end)

RegisterNetEvent('qb-weed:server:placePlant', function(coords, sort, currentHouse)
    local random = math.random(1, 2)
    local gender = (random == 1) and 'man' or 'woman'

    MySQL.insert('INSERT INTO house_plants (building, coords, gender, sort, plantid) VALUES (?, ?, ?, ?, ?)',
        { currentHouse, coords, gender, sort, math.random(111111, 999999) })
    TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, currentHouse)
end)

RegisterNetEvent('qb-weed:server:removeDeathPlant', function(building, plantId)
    MySQL.query('DELETE FROM house_plants WHERE plantid = ? AND building = ?', { plantId, building })
    TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, building)
end)

RegisterServerEvent('qb-weed:server:removeSeed', function(itemslot, seed)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    exports['qb-inventory']:RemoveItem(src, seed, 1, itemslot, 'qb-weed:server:removeSeed')
end)

RegisterNetEvent('qb-weed:server:harvestPlant', function(house, amount, plantName, plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local weedBag = Player.Functions.GetItemByName('empty_weed_bag')
    local sndAmount = math.random(12, 16)
    if weedBag ~= nil and weedBag.amount >= sndAmount then
        if house ~= nil then
            local result = MySQL.query.await('SELECT * FROM house_plants WHERE plantid = ? AND building = ?', { plantId, house })
            if result[1] ~= nil then
                exports['qb-inventory']:AddItem(src, 'weed_' .. plantName .. '_seed', amount, false, false, 'qb-weed:server:harvestPlant')
                exports['qb-inventory']:AddItem(src, 'weed_' .. plantName, sndAmount, false, false, 'qb-weed:server:harvestPlant')
                exports['qb-inventory']:RemoveItem(src, 'empty_weed_bag', sndAmount, false, 'qb-weed:server:harvestPlant')
                MySQL.query('DELETE FROM house_plants WHERE plantid = ? AND building = ?', { plantId, house })
                TriggerClientEvent('QBCore:Notify', src, Lang:t('text.the_plant_has_been_harvested'), 'success', 3500)
                TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, house)
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.this_plant_no_longer_exists'), 'error', 3500)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.house_not_found'), 'error', 3500)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.you_dont_have_enough_resealable_bags'), 'error', 3500)
    end
end)

RegisterNetEvent('qb-weed:server:foodPlant', function(house, amount, plantName, plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plantStats = MySQL.query.await('SELECT * FROM house_plants WHERE building = ? AND sort = ? AND plantid = ?',{ house, plantName, tostring(plantId) })
    local updatedFood = math.min(100, plantStats[1].food + amount)
    TriggerClientEvent('QBCore:Notify', src, QBWeed.Plants[plantName]['label'] ..' | Nutrition: ' .. plantStats[1].food .. '% + ' .. updatedFood - plantStats[1].food .. '% (' ..updatedFood .. '%)', 'success', 3500)
    MySQL.update('UPDATE house_plants SET food = ? WHERE building = ? AND plantid = ?',{ updatedFood, house, plantId })
    exports['qb-inventory']:RemoveItem(src, 'weed_nutrition', 1, false, 'qb-weed:server:foodPlant')
    TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, house)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for plantName, _ in pairs(QBWeed.Plants) do
        QBCore.Functions.CreateUseableItem('weed_' .. plantName .. '_seed', function(source, item)
            TriggerClientEvent('qb-weed:client:placePlant', source, plantName, item)
        end)
    end
    QBCore.Functions.CreateUseableItem('weed_nutrition', function(source, item)
        TriggerClientEvent('qb-weed:client:foodPlant', source, item)
    end)
end)

CreateThread(function()
    local healthTick = false
    while true do
        local housePlants = MySQL.query.await('SELECT * FROM house_plants', {})
        for k, plant in pairs(housePlants) do
            if housePlants[k].health > 50 then
                local Grow = math.random(QBWeed.Progress.min, QBWeed.Progress.max)
                if housePlants[k].progress + Grow < 100 then
                    MySQL.update('UPDATE house_plants SET progress = ? WHERE plantid = ?',
                        { (housePlants[k].progress + Grow), housePlants[k].plantid })
                elseif housePlants[k].progress + Grow >= 100 then
                    if housePlants[k].stage ~= QBWeed.Plants[housePlants[k].sort]['highestStage'] then
                        MySQL.update('UPDATE house_plants SET stage = ?, progress = 0 WHERE plantid = ?',
                            { housePlants[k].stage + 1, housePlants[k].plantid })
                    end
                end
            end
            if healthTick then
                local plantFood = math.max(0, plant.food - QBWeed.FoodUsage)
                local plantHealth = (plantFood >= 50) and math.min(100, plant.health + 1) or math.max(0, plant.health - 1)

                MySQL.update('UPDATE house_plants SET food = ?, health = ? WHERE plantid = ?',
                    { plantFood, plantHealth, plant.plantid })
            end
        end

        TriggerClientEvent('qb-weed:client:refreshHousePlants', -1)
        healthTick = not healthTick
        Wait((60 * 1000) * QBWeed.GrowthTick)
    end
end)
