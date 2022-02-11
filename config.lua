QBCore = exports['qb-core']:GetCoreObject()

QBWeed = {}

QBWeed.GrowthTickTime = 9.6 * (1 * 1000) -- Controls when progress tick happens
QBWeed.StatsTickTime = 19.2 * (1 * 1000) -- Controls when food ticks down & health ticks up or down

QBWeed.ActionTime = 5 * 1000    -- Controls how long every action but harvesting takes
QBWeed.HarvestTime = 12 * 1000  -- Controls how long harvesting takes

QBWeed.MinimumHealth = 40       -- No progress will be made below this health
QBWeed.MinimumFood = 50         -- Plant will gain or lose health according to this amount
QBWeed.ChanceOfFemale = 50      -- Chance of planting a female plant in percent
QBWeed.MinProximity = 1.3       -- Minimum distance plants can be planted from one another
QBWeed.ActionDistance = 0.64    -- Distance from plant to enable action

QBWeed.Fertilizer = {
    ["Min"] = 40,
    ["Max"] = 60,
}

QBWeed.Progress = {
    ["Min"] = 1,
    ["Max"] = 3,
}

QBWeed.Harvest = {
    ["M"] = {
        ["Bags"] = {
            ["Min"] = 18,
            ["Max"] = 18,
        },
        ["Seeds"] = {
            ["Min"] = 1,
            ["Max"] = 1,
        },
    },
    ["F"] = {
        ["Bags"] = {
            ["Min"] = 15,
            ["Max"] = 15,
        },
        ["Seeds"] = {
            ["Min"] = 2,
            ["Max"] = 3,
        },
    },
}

QBWeed.Plants = {
    ["og-kush"] = {
        ["label"] = "OGKush 2g",
        ["item"] = "weed_og-kush",
        ["stages"] = {
            ["stage-a"] = "bkr_prop_weed_01_small_01c",
            ["stage-b"] = "bkr_prop_weed_01_small_01b",
            ["stage-c"] = "bkr_prop_weed_01_small_01a",
            ["stage-d"] = "bkr_prop_weed_med_01b",
            ["stage-e"] = "bkr_prop_weed_lrg_01a",
            ["stage-f"] = "bkr_prop_weed_lrg_01b",
            ["stage-g"] = "bkr_prop_weed_lrg_01b",
        },
        ["highestStage"] = "stage-g"
    },
    ["amnesia"] = {
        ["label"] = "Amnesia 2g",
        ["item"] = "weed_amnesia",
        ["stages"] = {
            ["stage-a"] = "bkr_prop_weed_01_small_01c",
            ["stage-b"] = "bkr_prop_weed_01_small_01b",
            ["stage-c"] = "bkr_prop_weed_01_small_01a",
            ["stage-d"] = "bkr_prop_weed_med_01b",
            ["stage-e"] = "bkr_prop_weed_lrg_01a",
            ["stage-f"] = "bkr_prop_weed_lrg_01b",
            ["stage-g"] = "bkr_prop_weed_lrg_01b",
        },
        ["highestStage"] = "stage-g"
    },
    ["skunk"] = {
        ["label"] = "Skunk 2g",
        ["item"] = "weed_skunk",
        ["stages"] = {
            ["stage-a"] = "bkr_prop_weed_01_small_01c",
            ["stage-b"] = "bkr_prop_weed_01_small_01b",
            ["stage-c"] = "bkr_prop_weed_01_small_01a",
            ["stage-d"] = "bkr_prop_weed_med_01b",
            ["stage-e"] = "bkr_prop_weed_lrg_01a",
            ["stage-f"] = "bkr_prop_weed_lrg_01b",
            ["stage-g"] = "bkr_prop_weed_lrg_01b",
        },
        ["highestStage"] = "stage-g"
    },
    ["ak47"] = {
        ["label"] = "AK47 2g",
        ["item"] = "weed_ak47",
        ["stages"] = {
            ["stage-a"] = "bkr_prop_weed_01_small_01c",
            ["stage-b"] = "bkr_prop_weed_01_small_01b",
            ["stage-c"] = "bkr_prop_weed_01_small_01a",
            ["stage-d"] = "bkr_prop_weed_med_01b",
            ["stage-e"] = "bkr_prop_weed_lrg_01a",
            ["stage-f"] = "bkr_prop_weed_lrg_01b",
            ["stage-g"] = "bkr_prop_weed_lrg_01b",
        },
        ["highestStage"] = "stage-g"
    },
    ["purple-haze"] = {
        ["label"] = "Purple Haze 2g",
        ["item"] = "weed_purple-haze",
        ["stages"] = {
            ["stage-a"] = "bkr_prop_weed_01_small_01c",
            ["stage-b"] = "bkr_prop_weed_01_small_01b",
            ["stage-c"] = "bkr_prop_weed_01_small_01a",
            ["stage-d"] = "bkr_prop_weed_med_01b",
            ["stage-e"] = "bkr_prop_weed_lrg_01a",
            ["stage-f"] = "bkr_prop_weed_lrg_01b",
            ["stage-g"] = "bkr_prop_weed_lrg_01b",
        },
        ["highestStage"] = "stage-g"
    },
    ["white-widow"] = {
        ["label"] = "White Widow 2g",
        ["item"] = "weed_white-widow",
        ["stages"] = {
            ["stage-a"] = "bkr_prop_weed_01_small_01c",
            ["stage-b"] = "bkr_prop_weed_01_small_01b",
            ["stage-c"] = "bkr_prop_weed_01_small_01a",
            ["stage-d"] = "bkr_prop_weed_med_01b",
            ["stage-e"] = "bkr_prop_weed_lrg_01a",
            ["stage-f"] = "bkr_prop_weed_lrg_01b",
            ["stage-g"] = "bkr_prop_weed_lrg_01b",
        },
        ["highestStage"] = "stage-g"
    },
}

QBWeed.Props = {
    ["stage-a"] = "bkr_prop_weed_01_small_01c",
    ["stage-b"] = "bkr_prop_weed_01_small_01b",
    ["stage-c"] = "bkr_prop_weed_01_small_01a",
    ["stage-d"] = "bkr_prop_weed_med_01b",
    ["stage-e"] = "bkr_prop_weed_lrg_01a",
    ["stage-f"] = "bkr_prop_weed_lrg_01b",
    ["stage-g"] = "bkr_prop_weed_lrg_01b",
}

QBWeed.PropOffsets = {
    ["stage-a"] = 1,
    ["stage-b"] = 1,
    ["stage-c"] = 1,
    ["stage-d"] = 3.5,
    ["stage-e"] = 3.5,
    ["stage-f"] = 3.5,
    ["stage-g"] = 3.5,
}