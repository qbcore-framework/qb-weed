-- Serves one plant for given building to client
QBCore.Functions.CreateCallback('qb-weed:server:getHousePlant', function(source, callback, house, plantid)
    exports.oxmysql:fetch('SELECT * FROM house_plants WHERE plantid = ? AND building = ?', {plantid, house}, function(plant)
        callback(plant)
    end)
end)

-- Serves all plants for given building to client
QBCore.Functions.CreateCallback('qb-weed:server:getHousePlants', function(source, callback, house)
    exports.oxmysql:fetch('SELECT * FROM house_plants WHERE building = ?', {house}, function(plants)
        callback(plants)
    end)
end)

-- Places a new plant, tells client to render it, removes seed
RegisterServerEvent('qb-weed:server:placePlant')
AddEventHandler('qb-weed:server:placePlant', function(house, coords, sort, seedSlot)
    local gender = "man"
    if math.random(0, 1) == 1 then gender = "woman" end
    local plantid = math.random(111111, 999999) -- NOTE: Could possibly overwrite a key in SQL by randomly choosing

    exports.oxmysql:insert('INSERT INTO house_plants (building, coords, gender, sort, plantid) VALUES (?, ?, ?, ?, ?)',
        {house, json.encode(coords), gender, sort, plantid})
    TriggerClientEvent('qb-weed:client:refreshPlantStats', -1, plantid)
    TriggerClientEvent('qb-weed:client:renderNewPlant', -1, plantid)

    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.RemoveItem(sort, 1, seedSlot)
end)

-- Fertilizes plant, removes weed_nutrition
RegisterServerEvent('qb-weed:server:fertilizePlant')
AddEventHandler('qb-weed:server:fertilizePlant', function(house, plant)
    local Player = QBCore.Functions.GetPlayer(source)
    local amount = math.random(40, 60)
    local newFood = math.min(plant.food + amount, 100)
    TriggerClientEvent('QBCore:Notify', source,
        QBWeed.Plants[plant.sort]["label"] .. ' | Nutrition: ' .. plant.food .. '% + ' .. amount .. '% (' ..
            newFood .. '%)', 'success', 3500)
    exports.oxmysql:execute('UPDATE house_plants SET food = ? WHERE building = ? AND plantid = ?',
        {newFood, house, plant.plantid})
    Player.Functions.RemoveItem('weed_nutrition', 1)
    TriggerClientEvent('qb-weed:client:refreshPlantStats', -1, plant.plantid)
end)

-- Removes plant, gives player seeds & weed, removes weed bags
RegisterServerEvent('qb-weed:server:harvestPlant')
AddEventHandler('qb-weed:server:harvestPlant', function(house, plant)
    local Player = QBCore.Functions.GetPlayer(source)
    local weedBag = Player.Functions.GetItemByName('empty_weed_bag')
    local weedAmount = math.random(12, 16)
    local maxSeedAmount = plant.gender == "F" and 6 or 2
    local seedAmount = math.random(1, maxSeedAmount)
    

    if house ~= nil then
        if (weedBag ~= nil and weedBag.amount >= weedAmount) then
            local result = exports.oxmysql:fetchSync(
                'SELECT * FROM house_plants WHERE plantid = ? AND building = ?', {plant.plantid, house})
            if result[1] ~= nil then
                Player.Functions.AddItem('weed_' .. plant.sort .. '_seed', seedAmount)
                Player.Functions.AddItem('weed_' .. plant.sort, weedAmount)
                Player.Functions.RemoveItem('empty_weed_bag', weedAmount)
                exports.oxmysql:execute('DELETE FROM house_plants WHERE plantid = ? AND building = ?', {plant.plantid, house})
                TriggerClientEvent('QBCore:Notify', source, 'The plant has been harvested', 'success', 3500)
                TriggerClientEvent('qb-weed:client:removePlant', -1, plant.plantid)
            else
                TriggerClientEvent('QBCore:Notify', source, 'This plant no longer exists?', 'error', 3500)
            end
        else
            TriggerClientEvent('QBCore:Notify', source, "You Don't Have Enough Resealable Bags", 'error', 3500)
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'House Not Found', 'error', 3500)
    end
end)

-- Removes a dead plant
RegisterServerEvent('qb-weed:server:removeDeadPlant')
AddEventHandler('qb-weed:server:removeDeadPlant', function(house, plant)
    exports.oxmysql:execute('DELETE FROM house_plants WHERE plantid = ? AND building = ?', {plant.plantid, house})
    TriggerClientEvent('qb-weed:client:removePlant', -1, plant.plantid)
end)

-- Nutrition and food tick function
Citizen.CreateThread(function()
    while true do
        local housePlants = exports.oxmysql:fetchSync('SELECT * FROM house_plants', {})
        for _, plant in pairs(housePlants) do
            local newFood = math.max(plant.food - 1, 0)
            local newHealth = math.min(plant.health + 1, 100)
            if plant.food < 50 then newHealth = math.max(plant.health - 1, 0) end

            exports.oxmysql:execute('UPDATE house_plants SET food = ? WHERE plantid = ?',
                {newFood, plant.plantid})
            exports.oxmysql:execute('UPDATE house_plants SET health = ? WHERE plantid = ?',
                {newHealth, plant.plantid})
        end
        TriggerClientEvent('qb-weed:client:refreshAllPlantStats', -1)
        Citizen.Wait((60 * 1000) * 19.2)
    end
end)

-- Growth tick function
Citizen.CreateThread(function()
    while true do
        local housePlants = exports.oxmysql:fetchSync('SELECT * FROM house_plants', {})
        for _, plant in pairs(housePlants) do
            if plant.health > 50 then
                local newProgress = plant.progress + math.random(1, 3)
                if newProgress < 100 then
                    exports.oxmysql:execute('UPDATE house_plants SET progress = ? WHERE plantid = ?',
                        {newProgress, plant.plantid})
                else
                    if plant.stage ~= QBWeed.Plants[plant.sort]["highestStage"] then
                        local newStage = ""
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
                        exports.oxmysql:execute('UPDATE house_plants SET stage = ? WHERE plantid = ?',
                            {newStage, plant.plantid})
                        exports.oxmysql:execute('UPDATE house_plants SET progress = ? WHERE plantid = ?',
                            {0, plant.plantid})
                        TriggerClientEvent('qb-weed:client:refreshPlantProp', -1, plant.plantid, newStage)
                    end
                end
            end
        end
        TriggerClientEvent('qb-weed:client:refreshAllPlantStats', -1)
        Citizen.Wait((60 * 1000) * 9.6)
    end
end)

-- Usable items
QBCore.Functions.CreateUseableItem("weed_white-widow_seed", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'white-widow', item)
end)
QBCore.Functions.CreateUseableItem("weed_skunk_seed", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'skunk', item)
end)
QBCore.Functions.CreateUseableItem("weed_purple-haze_seed", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'purple-haze', item)
end)
QBCore.Functions.CreateUseableItem("weed_og-kush_seed", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'og-kush', item)
end)
QBCore.Functions.CreateUseableItem("weed_amnesia_seed", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'amnesia', item)
end)
QBCore.Functions.CreateUseableItem("weed_ak47_seed", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'ak47', item)
end)
QBCore.Functions.CreateUseableItem("weed_nutrition", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-weed:client:fertilizePlant', source, item)
end)