Config = {}

Config.PawnLocation = {
    {
        coords = vector3(412.34, 314.81, 103.13),
        size = vector4(1.5, 1.8, 4.45, 207.0), -- length, width, height, heading
        distance = 3.0,
        debug = false,
    },
}

Config.BankMoney = false -- Set to true if you want the money to go into the players bank
Config.UseTimes = false  -- Set to false if you want the pawnshop open 24/7
Config.TimeOpen = 7      -- Opening Time
Config.TimeClosed = 17   -- Closing Time

Config.PawnItems = {
    { item = 'goldchain', price = math.random(50, 100) },
    { item = 'diamond_ring', price = math.random(50, 100) },
    { item = 'rolex', price = math.random(50, 100) },
    { item = 'tenkgoldchain', price = math.random(50, 100) },
    { item = 'tablet', price = math.random(50, 100) },
    { item = 'iphone', price = math.random(50, 100) },
    { item = 'samsungphone', price = math.random(50, 100) },
    { item = 'laptop', price = math.random(50, 100) },
}

Config.MeltingItems = { -- meltTime is minutes per item
    { item = 'goldchain', meltTime = 0.15, rewards = { { item = 'goldbar', amount = 2 } } },
    { item = 'diamond_ring', meltTime = 0.15, rewards = { { item = 'diamond', amount = 1 }, { item = 'goldbar', amount = 1 } } },
    { item = 'rolex', meltTime = 0.15, rewards = { { item = 'diamond', amount = 1 }, { item = 'goldbar', amount = 1 }, { item = 'electronickit', amount = 1 } } },
    { item = 'tenkgoldchain', meltTime = 0.15, rewards = { { item = 'diamond', amount = 5 }, { item = 'goldbar', amount = 1 } } },
}

function Config.findPawnItem(itemName)
    for i = 1, #Config.PawnItems do
        if Config.PawnItems[i].item == itemName then return Config.PawnItems[i] end
    end
end

function Config.findMeltItem(itemName)
    for i = 1, #Config.MeltingItems do
        if Config.MeltingItems[i].item == itemName then return Config.MeltingItems[i] end
    end
end