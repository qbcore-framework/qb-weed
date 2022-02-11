-- Prune onload
if QBWeed.PruneOnLoad then
    MySQL.query('DELETE FROM house_plants WHERE health = ?', {0})
end

-- Serves one plant for given building to client
QBCore.Functions.CreateCallback('qb-weed:server:getHousePlant', function(source, callback, house, id)
    MySQL.query('SELECT * FROM house_plants WHERE building = ? AND id = ?', {house, id}, function(plant)
        callback(plant)
    end)
end)

-- Serves all plants for given building to client
QBCore.Functions.CreateCallback('qb-weed:server:getHousePlants', function(source, callback, house)
    MySQL.query('SELECT * FROM house_plants WHERE building = ?', {house}, function(plants)
        callback(plants)
    end)
end)

-- Returns to the client the number of weed bags the client has
QBCore.Functions.CreateCallback('qb-weed:server:getWeedBagAmount', function(source, callback)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local weedBag = Player.Functions.GetItemByName('empty_weed_bag')
    local amount = weedBag ~= nil and weedBag.amount or 0
    callback(amount)
end)

-- Places a new plant, tells client to render it, removes seed
RegisterServerEvent('qb-weed:server:placePlant')
AddEventHandler('qb-weed:server:placePlant', function(house, coords, sort, seedSlot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local gender = ((math.random()*100) <= QBWeed.ChanceOfFemale) and "F" or "M"

    MySQL.insert('INSERT INTO house_plants (building, coords, gender, sort) VALUES (?, ?, ?, ?)',
        {house, json.encode(coords), gender, sort}, function(insertId)
            if insertId ~= 0 then
                Player.Functions.RemoveItem(sort, 1, seedSlot)
                TriggerClientEvent('qb-weed:client:refreshPlantStats', -1, insertId, 100, 100, house)
            end
        end)
end)

-- Fertilizes plant, removes weed_nutrition
RegisterServerEvent('qb-weed:server:fertilizePlant')
AddEventHandler('qb-weed:server:fertilizePlant', function(house, plant)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = math.random(QBWeed.Fertilizer["Min"], QBWeed.Fertilizer["Max"])
    local newFood = math.min(plant.food + amount, 100)
    
    MySQL.query('UPDATE house_plants SET food = ? WHERE building = ? AND id = ?',
        {newFood, house, plant.id}, function(res)
            if res["affectedRows"] == 1 then
                TriggerClientEvent('qb-weed:client:refreshPlantStats', -1, plant.id, newFood, plant.health, house)
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
    local weedAmount = math.random(QBWeed.Harvest[plant.gender]["Bags"]["Min"], QBWeed.Harvest[plant.gender]["Bags"]["Max"])
    local seedAmount = math.random(QBWeed.Harvest[plant.gender]["Seeds"]["Min"], QBWeed.Harvest[plant.gender]["Seeds"]["Max"])
    local seedText = seedAmount == 1 and "seed" or "seeds"
    
    MySQL.query('DELETE FROM house_plants WHERE id = ? AND building = ?',
        {plant.id, house}, function(res)
            if res["affectedRows"] == 1 then
                Player.Functions.AddItem('weed_' .. plant.sort .. '_seed', seedAmount)
                Player.Functions.AddItem('weed_' .. plant.sort, weedAmount)
                Player.Functions.RemoveItem('empty_weed_bag', weedAmount)
                TriggerClientEvent('qb-weed:client:removePlant', -1, plant.id, house)
                TriggerClientEvent('QBCore:Notify', src,
                    QBWeed.Plants[plant.sort]["label"] .. ' | Harvested ' .. weedAmount .. ' bags, ' .. seedAmount .. ' ' .. seedText, 'success', 3500)
            end
        end)
end)

-- Removes a dead plant
RegisterServerEvent('qb-weed:server:removePlant')
AddEventHandler('qb-weed:server:removePlant', function(house, plant)
    MySQL.query('DELETE FROM house_plants WHERE id = ? AND building = ?', {plant.id, house}, function(res)
        if res["affectedRows"] == 1 then
            TriggerClientEvent('qb-weed:client:removePlant', -1, plant.id, house)
        end
    end)
end)

-- Nutrition and food tick function
Citizen.CreateThread(function()
    local foodUpdate = 'food = (0.5 * ((food - 1) + ABS(food - 1)))'
    local healthInc = 'food > ? AND health < 100 THEN health + 1'
    local healthDec = 'food <= ? AND health > 0 THEN health - 1'
    while true do
        MySQL.Sync.execute('UPDATE house_plants SET ' .. foodUpdate .. ' , health = CASE WHEN ' .. healthInc .. ' WHEN ' .. healthDec .. ' ELSE health END',
            {QBWeed.MinimumFood, QBWeed.MinimumFood})
        TriggerClientEvent('qb-weed:client:refreshAllPlantStats', -1)
        Citizen.Wait(QBWeed.StatsTickTime)
    end
end)

-- Growth tick function
Citizen.CreateThread(function()
    local caseAB = 'WHEN stage = "stage-a" THEN "stage-b" '
    local caseBC = 'WHEN stage = "stage-b" THEN "stage-c" '
    local caseCD = 'WHEN stage = "stage-c" THEN "stage-d" '
    local caseDE = 'WHEN stage = "stage-d" THEN "stage-e" '
    local caseEF = 'WHEN stage = "stage-e" THEN "stage-f" '
    local caseFG = 'WHEN stage = "stage-f" THEN "stage-g" '
    while true do
        local progressGain = math.random(QBWeed.Progress["Min"], QBWeed.Progress["Max"])
        MySQL.Sync.execute('UPDATE house_plants SET progress = (progress + ?) WHERE progress < 100 AND health > ?', {progressGain, QBWeed.MinimumHealth})
        MySQL.Sync.execute('UPDATE house_plants SET stage = CASE ' .. caseAB .. caseBC .. caseCD .. caseDE .. caseEF .. caseFG .. ' ELSE stage END, progress = 0 WHERE progress >= 100 AND stage != "stage-g"', {})
        TriggerClientEvent('qb-weed:client:refreshPlantProps', -1)
        Citizen.Wait(QBWeed.GrowthTickTime)
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