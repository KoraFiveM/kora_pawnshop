local sharedItems = exports['qb-core']:GetShared('Items')

local function exploitBan(src, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(src),
        QBCore.Functions.GetIdentifier(src, 'license'),
        QBCore.Functions.GetIdentifier(src, 'discord'),
        QBCore.Functions.GetIdentifier(src, 'ip'),
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

    local player = exports['qb-core']:GetPlayer(src)
    local totalPrice = tonumber(itemAmount) * entry.price

    if exports['qb-inventory']:RemoveItem(src, itemName, tonumber(itemAmount), false, 'qb-pawnshop:server:sellPawnItems') then
        player.AddMoney(Config.BankMoney and 'bank' or 'cash', totalPrice, 'qb-pawnshop:server:sellPawnItems')
        QB.notify.send(src, {
            title = QB.lang('info.title'),
            message = QB.lang('success.sold', { value = tonumber(itemAmount), value2 = sharedItems[itemName].label, value3 = totalPrice }),
            type = 'success',
        })
        TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[itemName], 'remove')
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

    if exports['qb-inventory']:RemoveItem(src, itemName, itemAmount, false, 'qb-pawnshop:server:meltItemRemove') then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[itemName], 'remove')
        local meltMinutes = tonumber(itemAmount) * entry.meltTime
        TriggerClientEvent('qb-pawnshop:client:startMelting', src, itemName, tonumber(itemAmount), meltMinutes * 60)
        QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('info.melt_wait', { value = meltMinutes }), type = 'info' })
    else
        QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('error.no_items'), type = 'error' })
    end
end)

RegisterNetEvent('qb-pawnshop:server:pickupMelted', function(batches)
    local src = source
    if not nearAnyPawnLocation(src) then
        exploitBan(src, 'pickupMelted Exploiting')
        return
    end

    for _, batch in pairs(batches) do
        local entry = Config.findMeltItem(batch.name)
        if entry then
            for _, reward in pairs(entry.rewards) do
                local rewardAmount = batch.amount * reward.amount
                if exports['qb-inventory']:AddItem(src, reward.item, rewardAmount, false, false, 'qb-pawnshop:server:pickupMelted') then
                    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[reward.item], 'add')
                    QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('success.items_received', { value = rewardAmount, value2 = sharedItems[reward.item].label }), type = 'success' })
                else
                    QB.notify.send(src, { title = QB.lang('info.title'), message = QB.lang('error.inventory_full', { value = sharedItems[reward.item].label }), type = 'warning', duration = 7500 })
                end
            end
        end
    end

    TriggerClientEvent('qb-pawnshop:client:resetPickup', src)
    TriggerClientEvent('qb-pawnshop:client:refreshApp', src)
end)