-- Actual current pawnshop and qbinventory authority; no FiveM or SQL writes.
local root = '../'
local function noop() end
local events, exportsByName, clientEvents, threads = {}, {}, {}, {}
local clock, checks, removeCalls = 0, 0, 0
local beforeRemove, beforeAdd
local data = { [7] = { citizenid = 'CID7', items = {} } }
local defs = {
    diamond_ring = { name = 'diamond_ring', label = 'Diamond Ring', weight = 100 },
    rolex = { name = 'rolex', label = 'Rolex', weight = 100 },
    goldchain = { name = 'goldchain', label = 'Gold Chain', weight = 100 },
    tenkgoldchain = { name = 'tenkgoldchain', label = '10K Chain', weight = 100 },
    goldbar = { name = 'goldbar', label = 'Gold Bar', weight = 1000 },
    diamond = { name = 'diamond', label = 'Diamond', weight = 1000 },
    electronickit = { name = 'electronickit', label = 'Electronics', weight = 1000 },
}
vector3 = function(x, y, z) return { x = x, y = y, z = z } end
vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end
GetCurrentResourceName = function() return 'qbinventory' end
GetInvokingResource = function() return 'qbpawnshop' end
GetGameTimer = function() return clock end
GetPlayerPed = function(src) return src end
GetEntityCoords = function() return { x = 412.34, y = 314.81, z = 103.13 } end
GetPlayerRoutingBucket = function() return 0 end
CreateThread = function(fn) threads[#threads + 1] = fn end
Wait, RegisterCommand, DropPlayer = noop, noop, function() error('probe unexpectedly banned a player') end
AddEventHandler = function(name, fn)
    events[name] = events[name] or {}
    events[name][#events[name] + 1] = fn
end
RegisterNetEvent = AddEventHandler
TriggerEvent = function(name, ...)
    for _, fn in ipairs(events[name] or {}) do fn(...) end
end
TriggerClientEvent = function(name, src, ...) clientEvents[#clientEvents + 1] = { name = name, src = src, args = { ... } } end
MySQL = { insert = function() error('probe attempted a database write') end }
QB = { resources = { serverRegistry = function() return { track = noop, untrack = noop } end },
    callback = { register = noop }, distance = { player = function() return true end }, sql = {},
    logging = { event = noop }, lang = function(key) return key end, notify = { send = noop } }
exports = setmetatable({}, {
    __call = function(_, name, fn) exportsByName[name] = fn end,
    __index = function(_, resource)
        return setmetatable({}, { __index = function(_, name)
            return function(_, ...)
                if resource == 'qbcore' then
                    local src, field, value = ...
                    if name == 'allShared' then return {} end
                    if name == 'getShared' then return defs[field] end
                    if name == 'getPlayerData' then
                        if not data[src] then return nil end
                        return field and QbInventory.copy(data[src][field[1]]) or QbInventory.copy(data[src])
                    end
                    if name == 'setPath' then
                        if field[2] then data[src].items[field[2]] = value else data[src].items = value end
                        TriggerEvent('qbcore:server:inventoryChanged', src)
                        return true
                    end
                elseif resource == 'qb-core' then
                    if name == 'GetShared' then return defs end
                    if name == 'GetPlayer' then return data[select(1, ...)] and { PlayerData = data[select(1, ...)] } end
                    if name == 'GetCoreObject' then return { Functions = { GetPlayerData = function() return data[7] end } } end
                end
                if name == 'RemoveItem' then
                    removeCalls = removeCalls + 1
                    if beforeRemove then local fn = beforeRemove; beforeRemove = nil; fn() end
                elseif name == 'AddItem' and beforeAdd then
                    local fn = beforeAdd; beforeAdd = nil; fn()
                end
                return assert(exportsByName[name], 'missing actual inventory export ' .. name)(...)
            end
        end })
    end,
})
Config = {}
dofile(root .. 'qbinventory/config.lua'); dofile(root .. 'qbinventory/shared.lua'); dofile(root .. 'qbinventory/server.lua')
local api = QbInventory.api
local inventoryConfig = Config.qbinventory
dofile(root .. 'qbpawnshop/shared/config.lua')
dofile(arg[1] or 'server/server.lua')
local function fire(name, ...) source = 7; return assert(events['qb-pawnshop:server:' .. name])[1](...) end
local function count(name) return api.getItemCount(7, name) end


local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, (message or 'unexpected result') .. ': ' .. tostring(actual) .. ' ~= ' .. tostring(expected))
end
local function reset()
    TriggerEvent('QBCore:Server:OnPlayerUnload', 7)
    data[7] = { citizenid = 'CID7', items = {} }
    clock, removeCalls = 0, 0
    beforeRemove, beforeAdd = nil, nil
    clientEvents = {}
    inventoryConfig.playerMaxWeight = 120000
end
local function lastEvent(name)
    for i = #clientEvents, 1, -1 do
        if clientEvents[i].name == name then return clientEvents[i] end
    end
end
local function melt(name, amount)
    assert(api.addItem(7, name, amount))
    fire('meltItemRemove', name, amount)
end

fire('pickupMelted', { { name = 'goldchain', amount = 1 } })
equal(count('goldbar'), 0, 'a pickup without a receipt grants nothing')
fire('pickupMelted', nil)
fire('pickupMelted', 'invalid payload')
equal(count('goldbar'), 0)

melt('goldchain', 1)
equal(count('goldchain'), 0)
equal(lastEvent('qb-pawnshop:client:startMelting').args[3], 9)
fire('pickupMelted', { { name = 'tenkgoldchain', amount = 1 } })
equal(count('diamond'), 0)
equal(count('goldbar'), 0, 'configured duration must elapse')
clock = 8999
fire('pickupMelted', {})
equal(count('goldbar'), 0)
clock = 9000
fire('pickupMelted', { { name = 'tenkgoldchain', amount = 1 } })
equal(count('goldbar'), 2, 'receipt supplies the original recipe and quantity')
equal(count('diamond'), 0)
equal(#lastEvent('qb-pawnshop:client:resetPickup').args[1], 0)
fire('pickupMelted', { { name = 'goldchain', amount = 1 } })
equal(count('goldbar'), 2, 'completed rewards cannot be replayed')

reset()
melt('goldchain', 1)
data[8] = { citizenid = 'CID8', items = {} }
source = 8
events['qb-pawnshop:server:pickupMelted'][1]({ { name = 'goldchain', amount = 100 } })
equal(api.getItemCount(8, 'goldbar'), 0, 'another player cannot collect this receipt')
clock = 9000
fire('pickupMelted', {})
equal(count('goldbar'), 2)

reset()
assert(api.addItem(7, 'goldchain', 3))
for _, amount in ipairs({ -1, 0, 0.5, 1.5, math.huge, -math.huge, 0/0, 'invalid', {}, true }) do
    fire('meltItemRemove', 'goldchain', amount)
end
equal(removeCalls, 0, 'invalid quantities never reach inventory removal')
equal(count('goldchain'), 3)
fire('meltItemRemove', 'goldchain', '2')
equal(count('goldchain'), 1)
equal(lastEvent('qb-pawnshop:client:startMelting').args[2], 2)
equal(lastEvent('qb-pawnshop:client:startMelting').args[3], 18)
fire('meltItemRemove', 'goldchain', 1)
equal(count('goldchain'), 1, 'a second active melt cannot consume inputs')
clock = 18000
fire('pickupMelted', nil)
equal(count('goldbar'), 4)

reset()
fire('meltItemRemove', 'goldchain', 1)
clock = 9000
fire('pickupMelted', { { name = 'goldchain', amount = 1 } })
equal(count('goldbar'), 0, 'failed removal creates no receipt')

reset()
assert(api.addItem(7, 'goldchain', 2))
beforeRemove = function()
    fire('meltItemRemove', 'goldchain', 1)
    fire('pickupMelted', { { name = 'goldchain', amount = 1 } })
end
fire('meltItemRemove', 'goldchain', 1)
equal(removeCalls, 1, 'reservation protects yielding or reentrant removal')
equal(count('goldchain'), 1)
clock = 9000
fire('meltItemRemove', 'goldchain', 1)
equal(count('goldchain'), 0, 'ready batches allow a new melt')
beforeAdd = function() fire('pickupMelted', { { name = 'goldchain', amount = 100 } }) end
fire('pickupMelted', {})
equal(count('goldbar'), 2, 'pickup may collect the old batch while the new one runs')
clock = 18000
fire('pickupMelted', {})
equal(count('goldbar'), 4)
fire('pickupMelted', {})
equal(count('goldbar'), 4)

reset()
melt('goldchain', 1)
local originalReward = Config.MeltingItems[1].rewards[1].amount
Config.MeltingItems[1].rewards[1].amount = 99
clock = 9000
fire('pickupMelted', {})
equal(count('goldbar'), 2, 'accepted receipts retain their server reward snapshot')
Config.MeltingItems[1].rewards[1].amount = originalReward

reset()
Config.MeltingItems[1].rewards[1].amount = 1.5
melt('goldchain', 1)
clock = 9000
fire('pickupMelted', {})
equal(count('goldbar'), 1, 'trusted fractional recipe quantities retain provider rounding')
fire('pickupMelted', {})
equal(count('goldbar'), 1)
Config.MeltingItems[1].rewards[1].amount = originalReward

reset()
local originalTime = Config.MeltingItems[1].meltTime
Config.MeltingItems[1].meltTime = 0
melt('goldchain', 1)
equal(lastEvent('qb-pawnshop:client:startMelting').args[3], 0)
fire('pickupMelted', {})
equal(count('goldbar'), 2, 'configured zero-duration melts remain immediate')
Config.MeltingItems[1].meltTime = originalTime

reset()
assert(api.addItem(7, 'goldchain', 2))
fire('meltItemRemove', 'goldchain', 1)
clock = 9000
fire('meltItemRemove', 'goldchain', 1)
beforeAdd = function() clock = 18000 end
fire('pickupMelted', {})
equal(count('goldbar'), 2)
equal(#lastEvent('qb-pawnshop:client:resetPickup').args[1], 1, 'a batch finishing during delivery remains visible')
equal(lastEvent('qb-pawnshop:client:resetPickup').args[2], false)
fire('pickupMelted', {})
equal(count('goldbar'), 4)
equal(lastEvent('qb-pawnshop:client:resetPickup').args[2], false)

reset()
melt('goldchain', 1)
clock = 9000
inventoryConfig.playerMaxWeight = 1000
fire('pickupMelted', {})
equal(count('goldbar'), 0, 'actual inventory capacity failure retains undelivered rewards')
equal(#lastEvent('qb-pawnshop:client:resetPickup').args[1], 1)
inventoryConfig.playerMaxWeight = 120000
fire('pickupMelted', {})
equal(count('goldbar'), 2)
fire('pickupMelted', {})
equal(count('goldbar'), 2)

reset()
melt('diamond_ring', 1)
clock = 9000
inventoryConfig.playerMaxWeight = 1000
fire('pickupMelted', {})
equal(count('diamond') + count('goldbar'), 1, 'partial output delivery is tracked per reward')
inventoryConfig.playerMaxWeight = 120000
fire('pickupMelted', {})
equal(count('diamond'), 1)
equal(count('goldbar'), 1)
fire('pickupMelted', {})
equal(count('diamond') + count('goldbar'), 2, 'retry cannot repeat a delivered output')

reset()
melt('goldchain', 1)
clock = 9000
data[7].citizenid = 'REPLACEMENT'
fire('pickupMelted', {})
equal(count('goldbar'), 0, 'another character cannot use the prior receipt')
reset()
melt('goldchain', 1)
source = 7
TriggerEvent('playerDropped')
clock = 9000
fire('pickupMelted', {})
equal(count('goldbar'), 0, 'disconnect clears receipts even with the same citizen identity')
reset()
melt('goldchain', 1)
TriggerEvent('QBCore:Server:OnPlayerUnload', 7)
clock = 9000
fire('pickupMelted', {})
equal(count('goldbar'), 0, 'character unload clears receipts')

reset()
assert(api.addItem(7, 'goldchain', 1))
beforeRemove = function() error('controlled inventory exception') end
equal(pcall(fire, 'meltItemRemove', 'goldchain', 1), false)
fire('meltItemRemove', 'goldchain', 1)
equal(count('goldchain'), 0, 'an exception must release the busy flag')
clock = 9000
beforeAdd = function() error('controlled inventory exception') end
equal(pcall(fire, 'pickupMelted', {}), false)
fire('pickupMelted', {})
equal(count('goldbar'), 2)
fire('pickupMelted', {})
equal(count('goldbar'), 2)

-- Run the actual client timer with controlled coroutine waits and capture only NUI.
reset()
local app, navigation, sent
local nuiFile = assert(io.open('../qblib/modules/nui/client.lua', 'r'))
local nuiSource = nuiFile:read('*a')
nuiFile:close()
local listStart = assert(nuiSource:find('local function assertListItems(', 1, true))
local listEnd = assert(nuiSource:find('local function assertAppContent(', listStart, true))
local assertListItems = assert(load(nuiSource:sub(listStart, listEnd - 1) .. '\nreturn assertListItems',
    'qblib actual list validator', 't', { assert = assert, type = type, VALID_TONES = {} }))()
QB.nui = {
    registerApp = function(value) app = value end,
    updateApp = function(_, value)
        navigation = value.navigation
        for _, row in ipairs(navigation) do
            if row.id == 'pickup' then assertListItems(row.content.blocks[1].items, 'pawnshop pickup', {}) end
        end
    end,
    isAppOpen = function() return false end,
    openApp = noop,
}
QB.blips = { create = noop }
LocalPlayer = { state = { isLoggedIn = true } }
TriggerServerEvent = function(name, ...) sent = { name = name, args = { ... } } end
dofile(arg[2] or 'client/client.lua')
threads = {}
Wait = function(ms) return coroutine.yield(ms) end
local function clientFire(name, ...) return assert(events['qb-pawnshop:client:' .. name])[1](...) end
local function timer()
    local co = coroutine.create(threads[#threads])
    local ok, ms = coroutine.resume(co)
    assert(ok, ms)
    equal(ms, 1000, 'client waits before counting the first second')
    return co
end
local function tick(co, amount)
    for _ = 1, amount do
        clock = clock + 1000
        local ok, why = coroutine.resume(co)
        assert(ok, why)
    end
end
local function pickupRow()
    for _, row in ipairs(navigation or {}) do if row.id == 'pickup' then return row end end
end
clientFire('startMelting', 'goldchain', 1, 9)
local first = timer()
tick(first, 8)
equal(pickupRow(), nil, 'client cannot finish one second before the server')
tick(first, 1)
equal(pickupRow().content.blocks[1].items[1].badge, 1)
clientFire('startMelting', 'diamond_ring', 2, 9)
local second = timer()
equal(#pickupRow().content.blocks[1].items, 1, 'starting another melt retains ready batches')
clientFire('resetPickup', { { name = 'goldchain', amount = 1 } })
equal(#pickupRow().content.blocks[1].items, 1, 'inventory-full retry remains visible')
tick(second, 9)
equal(#pickupRow().content.blocks[1].items, 2)
app.onAction('qb-pawnshop:pickup')
equal(sent.name, 'qb-pawnshop:server:pickupMelted')
equal(#sent.args[1], 2, 'legacy client event argument remains a batch list')
clientFire('resetPickup')
equal(pickupRow(), nil, 'legacy no-argument reset still clears pickup')

clientFire('startMelting', 'goldchain', 1, 9)
local stale = timer()
TriggerEvent('QBCore:Client:OnPlayerUnload')
equal(pickupRow(), nil)
clientFire('startMelting', 'rolex', 1, 9)
local replacement = timer()
tick(stale, 1)
equal(coroutine.status(stale), 'dead', 'an old timer cannot complete for a replacement character')
tick(replacement, 9)
equal(#pickupRow().content.blocks[1].items, 1)
equal(pickupRow().content.blocks[1].items[1].label, 'Rolex')

clientFire('resetPickup')
clientFire('startMelting', 'goldchain', 1, 9)
local collected = timer()
clientFire('resetPickup', {}, false)
tick(collected, 1)
equal(coroutine.status(collected), 'dead', 'server collection cancels a delayed client timer')
equal(pickupRow(), nil, 'a collected batch cannot create a phantom pickup')

clientFire('startMelting', 'goldchain', 1, 0)
local instant = coroutine.create(threads[#threads])
assert(coroutine.resume(instant))
equal(coroutine.status(instant), 'dead')
equal(pickupRow().content.blocks[1].items[1].label, 'Gold Chain')
clientFire('startMelting', 'goldchain', 2, 0)
local sameItem = coroutine.create(threads[#threads])
assert(coroutine.resume(sameItem))
local sameRows = pickupRow().content.blocks[1].items
equal(#sameRows, 2, 'two ready batches of the same item pass actual AppShell validation')
equal(sameRows[1].id ~= sameRows[2].id, true)
print(('pawnshop melting: %d checks passed (actual inventory, no live host or database)'):format(checks))
