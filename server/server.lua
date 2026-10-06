local function itemData(name)
    return exports.qbcore:getShared('items', name)
end
local pendingMelts = {}

local function positiveInteger(value)
    local amount = tonumber(value)
    if not amount or amount <= 0 or amount ~= math.floor(amount) then return nil end
    return math.tointeger(amount)
end

local function citizenId(src)
    return exports.qbcore:getPlayerData(src, { 'citizenid' })
end

local function currentMelt(src, state)
    return pendingMelts[src] == state and citizenId(src) == state.citizenid
end

local function exploitBan(src, reason)
    local identifiers = exports.qbcore:getIdentifiers(src)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(src),
        identifiers.license,
        identifiers.discord,
        identifiers.ip,
        reason,
        2147483647,
        'qb-pawnshop',
    })
    QB.logging.event('pawnshop', src, { action = 'ban', reason = reason })
    DropPlayer(src, 'You were permanently banned by the server for: Exploiting')
end

local function nearAnyPawnLocation(src)
    for _, location in pairs(Config.PawnLocation) do
        if QB.distance.player(src, location.coords, location.distance or 5.0) then
            return true
        end
    end
    return false
end

RegisterNetEvent('qb-pawnshop:server:sellPawnItems', function(itemName, itemAmount)
    local src = source
    if not nearAnyPawnLocation(src) then
        exploitBan(src, 'sellPawnItems Exploiting')
        return
    end

    local entry = Config.findPawnItem(itemName)
    if not entry then
        exploitBan(src, 'sellPawnItems invalid item')
        return
    end

    local totalPrice = tonumber(itemAmount) * entry.price

    if exports['qb-inventory']:RemoveItem(src, itemName, tonumber(itemAmount), false, 'qb-pawnshop:server:sellPawnItems') then
        exports.qbcore:addMoney(src, Config.BankMoney and 'bank' or 'cash', totalPrice, 'qb-pawnshop:server:sellPawnItems')
        QB.notify.send(src, {
            title = QB.lang('info.title'),
            message = QB.lang('success.sold', { value = tonumber(itemAmount), value2 = itemData(itemName).label, value3 = totalPrice }),
            type = 'success',
        })
        TriggerClientEvent('qb-inventory:client:ItemBox', src, itemData(itemName), 'remove')
    else
        QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('error.no_items'), type = 'error' })
    end

    TriggerClientEvent('qb-pawnshop:client:refreshApp', src)
end)

RegisterNetEvent('qb-pawnshop:server:meltItemRemove', function(itemName, itemAmount)
    local src = source
    if not nearAnyPawnLocation(src) then
        exploitBan(src, 'meltItemRemove Exploiting')
        return
    end

    local entry = Config.findMeltItem(itemName)
    if not entry then
        exploitBan(src, 'meltItemRemove invalid item')
        return
    end

    itemAmount = positiveInteger(itemAmount)
    if not itemAmount then return end
    local cid = citizenId(src)
    if not cid then return end
    local state = pendingMelts[src]
    if not state or state.citizenid ~= cid then
        state = { citizenid = cid, batches = {} }
        pendingMelts[src] = state
    end
    if state.busy then return end
    local lastBatch = state.batches[#state.batches]
    if lastBatch and GetGameTimer() < lastBatch.readyAt then return end

    local meltTime = tonumber(entry.meltTime)
    local duration = meltTime and itemAmount * 1.0 * meltTime * 60000
    if not duration or duration < 0 or duration ~= duration or duration == math.huge then
        print('[qb-pawnshop] Invalid melt time for ' .. tostring(itemName))
        return
    end
    local rewards = {}
    for _, reward in pairs(entry.rewards) do
        local perItem = tonumber(reward.amount)
        local amount = perItem and itemAmount * 1.0 * perItem
        if not amount or amount ~= amount or math.abs(amount) == math.huge or not itemData(reward.item) then
            print('[qb-pawnshop] Invalid melting reward for ' .. tostring(itemName))
            return
        end
        rewards[#rewards + 1] = { item = reward.item, amount = amount }
    end

    -- Reserve before the inventory export can yield; only consumed inputs get a receipt.
    state.busy = true
    local ok, removed = pcall(function()
        return exports['qb-inventory']:RemoveItem(src, itemName, itemAmount, false, 'qb-pawnshop:server:meltItemRemove')
    end)
    if not ok then state.busy = false; error(removed, 0) end
    if not currentMelt(src, state) then state.busy = false; return end
    if removed then
        duration = math.ceil(duration)
        state.batches[#state.batches + 1] = {
            name = itemName, amount = itemAmount, readyAt = GetGameTimer() + duration, rewards = rewards,
        }
        TriggerClientEvent('qb-inventory:client:ItemBox', src, itemData(itemName), 'remove')
        local meltMinutes = duration / 60000
        TriggerClientEvent('qb-pawnshop:client:startMelting', src, itemName, itemAmount, duration / 1000)
        QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('info.melt_wait', { value = meltMinutes }), type = 'info' })
    else
        QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('error.no_items'), type = 'error' })
    end
    state.busy = false
end)

RegisterNetEvent('qb-pawnshop:server:pickupMelted', function(batches)
    local src = source
    if not nearAnyPawnLocation(src) then
        exploitBan(src, 'pickupMelted Exploiting')
        return
    end

    -- Keep the legacy argument, but quantities and rewards come only from server receipts.
    local state = pendingMelts[src]
    if not state or state.busy or not currentMelt(src, state) then return end
    state.busy = true
    local now = GetGameTimer()
    local remaining, hasReady = {}, false
    for _, batch in ipairs(state.batches) do
        local outstanding = now < batch.readyAt
        if not outstanding then
            hasReady = true
            for _, reward in ipairs(batch.rewards) do
                if not reward.delivered then
                    local ok, added = pcall(function()
                        return exports['qb-inventory']:AddItem(src, reward.item, reward.amount, false, false, 'qb-pawnshop:server:pickupMelted')
                    end)
                    if not ok then
                        state.busy = false
                        error(added, 0)
                    end
                    if added then reward.delivered = true else outstanding = true end
                    if not currentMelt(src, state) then state.busy = false; return end
                    if added then
                        TriggerClientEvent('qb-inventory:client:ItemBox', src, itemData(reward.item), 'add')
                        QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('success.items_received', { value = reward.amount, value2 = itemData(reward.item).label }), type = 'success' })
                    else
                        QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('error.inventory_full', { value = itemData(reward.item).label }), type = 'warning', duration = 7500 })
                    end
                end
            end
        end
        if outstanding then remaining[#remaining + 1] = batch end
    end
    state.busy = false
    if not hasReady then return end
    state.batches = remaining
    if #remaining == 0 then pendingMelts[src] = nil end

    -- A second melt may finish while delivery yields. Sync what is still owed
    -- and cancel a client timer if its batch was already collected.
    local readyBatches, stillMelting = {}, false
    now = GetGameTimer()
    for _, batch in ipairs(remaining) do
        if now >= batch.readyAt then
            readyBatches[#readyBatches + 1] = { name = batch.name, amount = batch.amount }
        else
            stillMelting = true
        end
    end
    TriggerClientEvent('qb-pawnshop:client:resetPickup', src, readyBatches, stillMelting)
    TriggerClientEvent('qb-pawnshop:client:refreshApp', src)
end)

AddEventHandler('playerDropped', function() pendingMelts[source] = nil end)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src) pendingMelts[src] = nil end)
