local QBCore = exports['qb-core']:GetCoreObject()

-- Serves one plant for given building to client
QBCore.Functions.CreateCallback('qb-weed:server:getHousePlant', function(source, callback, house, id)
    exports.oxmysql:query('SELECT * FROM house_plants WHERE building = ? AND id = ?', {house, id}, function(plant)
        callback(plant)
    end)
end)

-- Serves all plants for given building to client
QBCore.Functions.CreateCallback('qb-weed:server:getHousePlants', function(source, callback, house)
    exports.oxmysql:query('SELECT * FROM house_plants WHERE building = ?', {house}, function(plants)
        callback(plants)
    end)
end)

-- Places a new plant, tells client to render it, removes seed
RegisterServerEvent('qb-weed:server:placePlant')
AddEventHandler('qb-weed:server:placePlant', function(house, coords, sort, seedSlot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local gender = math.random(0, 1) == 1 and "F" or "M"

    exports.oxmysql:insert('INSERT INTO house_plants (building, coords, gender, sort) VALUES (?, ?, ?, ?)',
        {house, json.encode(coords), gender, sort}, function(insertId)
            if insertId ~= 0 then
                TriggerClientEvent('qb-weed:client:refreshPlantStats', -1, insertId, 100, 100)
            end
        end)

    Player.Functions.RemoveItem(sort, 1, seedSlot)
end)

-- Fertilizes plant, removes weed_nutrition
RegisterServerEvent('qb-weed:server:fertilizePlant')
AddEventHandler('qb-weed:server:fertilizePlant', function(house, plant)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = math.random(40, 60)
    local newFood = math.min(plant.food + amount, 100)
    
    exports.oxmysql:query('UPDATE house_plants SET food = ? WHERE building = ? AND id = ?',
        {newFood, house, plant.id}, function(res)
            if res["affectedRows"] == 1 then
                TriggerClientEvent('qb-weed:client:refreshPlantStats', -1, plant.id, newFood, plant.health)
                TriggerClientEvent('QBCore:Notify', src,
                    QBWeed.Plants[plant.sort]["label"] .. ' | Nutrition: ' .. plant.food .. '% + ' .. amount .. '% (' ..
                    newFood .. '%)', 'success', 3500)
                Player.Functions.RemoveItem('weed_nutrition', 1)
            end
        end)
end)

-- Removes plant, gives player seeds & weed, removes weed bags
RegisterServerEvent('qb-weed:server:harvestPlant')
AddEventHandler('qb-weed:server:harvestPlant', function(house, plant)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local weedBag = Player.Functions.GetItemByName('empty_weed_bag')
    local weedAmount = plant.gender == "F" and 15 or 18
    local seedAmount = plant.gender == "F" and math.random(2, 3) or 1
    local seedText = plant.gender == "M" and "seed" or "seeds"
    
    if (weedBag ~= nil and weedBag.amount >= weedAmount) then
        exports.oxmysql:query('DELETE FROM house_plants WHERE id = ? AND building = ?',
            {plant.id, house}, function(res)
                if res["affectedRows"] == 1 then
                    Player.Functions.AddItem('weed_' .. plant.sort .. '_seed', seedAmount)
                    Player.Functions.AddItem('weed_' .. plant.sort, weedAmount)
                    Player.Functions.RemoveItem('empty_weed_bag', weedAmount)
                    TriggerClientEvent('qb-weed:client:removePlant', -1, plant.id)
                    TriggerClientEvent('QBCore:Notify', src,
                        QBWeed.Plants[plant.sort]["label"] .. ' | Harvested ' .. weedAmount .. ' bags, ' .. seedAmount .. ' ' .. seedText, 'success', 3500)
                end
            end)
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have enough bags", 'error', 3500)
    end
end)

-- Removes a dead plant
RegisterServerEvent('qb-weed:server:removeDeadPlant')
AddEventHandler('qb-weed:server:removeDeadPlant', function(house, plant)
    exports.oxmysql:query('DELETE FROM house_plants WHERE id = ? AND building = ?', {plant.id, house}, function(res)
        if res["affectedRows"] == 1 then
            TriggerClientEvent('qb-weed:client:removePlant', -1, plant.id)
        end
    end)
end)

-- Nutrition and food tick function
Citizen.CreateThread(function()
    while true do
        exports.oxmysql:query('SELECT * FROM house_plants', {}, function(housePlants)
            for _, plant in pairs(housePlants) do
                if plant.health > 0 then
                    local newFood = math.max(plant.food - 1, 0)
                    local newHealth = math.min(plant.health + 1, 100)
                    if plant.food < QBWeed.MinimumFood then newHealth = math.max(plant.health - 1, 0) end
        
                    exports.oxmysql:update('UPDATE house_plants SET food = ?, health = ? WHERE id = ?',
                        {newFood, newHealth, plant.id}, function(res)
                            if res == 1 then
                                TriggerClientEvent('qb-weed:client:refreshPlantStats', -1, plant.id, newFood, newHealth)
                            end
                        end)
                end
            end
        end)

        Citizen.Wait(QBWeed.StatsTime)
    end
end)

-- Growth tick function
Citizen.CreateThread(function()
    while true do
        exports.oxmysql:query('SELECT * FROM house_plants', {}, function(housePlants)
            for _, plant in pairs(housePlants) do
                if plant.health > QBWeed.MinimumHealth and plant.stage ~= QBWeed.Plants[plant.sort]["highestStage"] then
                    local newProgress = plant.progress + math.random(1, 3)
                    local oldStage = plant.stage
                    local newStage = plant.stage

                    if newProgress >= 100 then
                        newProgress = 0
                        if plant.stage == "stage-a" then
                            newStage = "stage-b"
                        elseif plant.stage == "stage-b" then
                            newStage = "stage-c"
                        elseif plant.stage == "stage-c" then
                            newStage = "stage-d"
                        elseif plant.stage == "stage-d" then
                            newStage = "stage-e"
                        elseif plant.stage == "stage-e" then
                            newStage = "stage-f"
                        elseif plant.stage == "stage-f" then
                            newStage = "stage-g"
                        end
                    end

                    exports.oxmysql:update('UPDATE house_plants SET stage = ?, progress = ? WHERE id = ?',
                        {newStage, 0, plant.id}, function(res)
                            if res == 1 then
                                TriggerClientEvent('qb-weed:client:refreshPlantProp', -1, plant.id, newStage, 0)
                            end
                        end)
                end
            end
        end)
        Citizen.Wait(QBWeed.GrowthTime)
    end
end)

-- Usable items
QBCore.Functions.CreateUseableItem("weed_white-widow_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'white-widow', item)
end)
QBCore.Functions.CreateUseableItem("weed_skunk_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'skunk', item)
end)
QBCore.Functions.CreateUseableItem("weed_purple-haze_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'purple-haze', item)
end)
QBCore.Functions.CreateUseableItem("weed_og-kush_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'og-kush', item)
end)
QBCore.Functions.CreateUseableItem("weed_amnesia_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'amnesia', item)
end)
QBCore.Functions.CreateUseableItem("weed_ak47_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'ak47', item)
end)
QBCore.Functions.CreateUseableItem("weed_nutrition", function(source, item)
    TriggerClientEvent('qb-weed:client:fertilizePlant', source, item)
end)