local function itemData(name)
    return exports.qbcore:getShared('items', name) or { label = name }
end

local appId = 'qb-pawnshop:app'
local sellAction = 'qb-pawnshop:sell'
local meltAction = 'qb-pawnshop:melt'
local pickupAction = 'qb-pawnshop:pickup'

local isMelting = false
local canTake = false
local meltedItem = {}
local meltVersion = 0
local inited = nil

local function splitItemId(id)
    local sep = id and id:find(':', 1, true)
    if not sep then return nil, nil end
    return id:sub(1, sep - 1), id:sub(sep + 1)
end

local function eligibleItems(configList)
    if not inited then return {} end
    local playerItems = exports.qbcore:getPlayerData({ 'items' }) or {}
    local items = {}
    for _, invItem in pairs(playerItems) do
        for _, entry in ipairs(configList) do
            if invItem.name == entry.item then
                items[#items + 1] = { name = invItem.name, amount = invItem.amount, entry = entry }
                break
            end
        end
    end
    return items
end

local function itemsBlock(listItems, emptyDescription)
    if #listItems == 0 then
        return { type = 'empty', title = emptyDescription, icon = 'PackageOpen' }
    end
    return { type = 'list', id = 'items', items = listItems }
end


local function buildSellItems()
    local listItems = {}
    for _, item in ipairs(eligibleItems(Config.PawnItems)) do
        listItems[#listItems + 1] = {
            id = 'sell:' .. item.name,
            label = itemData(item.name).label,
            description = 'Selling Price $' .. item.entry.price,
            badge = item.amount,
            action = {
                id = sellAction,
                label = 'Sell',
                fields = {
                    { id = 'amount', label = 'Max Amount ' .. item.amount, type = 'number', min = 1, max = item.amount, default = 1, required = true },
                },
            },
        }
    end
    return listItems
end

local function buildMeltItems()
    local listItems = {}
    for _, item in ipairs(eligibleItems(Config.MeltingItems)) do
        listItems[#listItems + 1] = {
            id = 'melt:' .. item.name,
            label = itemData(item.name).label,
            description = 'Melt ' .. itemData(item.name).label,
            badge = item.amount,
            action = {
                id = meltAction,
                label = 'Melt',
                fields = {
                    { id = 'amount', label = 'Max Amount ' .. item.amount, type = 'number', min = 1, max = item.amount, default = 1, required = true },
                },
            },
        }
    end
    return listItems
end

local function buildNavigation()
    local nav = {
        {
            id = 'sell',
            label = 'Pawn Shop',
            icon = 'Coins',
            content = {
                title = 'Pawn Shop',
                blocks = { itemsBlock(buildSellItems(), 'Nothing in your inventory is worth pawning here.') },
            },
        },
        {
            id = 'melt',
            label = 'Melt Items',
            icon = 'Flame',
            disabled = isMelting,
            content = {
                title = 'Melt Items',
                description = 'Open the Melting Shop',
                blocks = { itemsBlock(buildMeltItems(), 'Nothing in your inventory can be melted here.') },
            },
        },
    }

    if canTake then
        local pickupItems = {}
        for index, batch in ipairs(meltedItem) do
            pickupItems[#pickupItems + 1] = { id = 'melted:' .. batch.name .. ':' .. index, label = itemData(batch.name).label, badge = batch.amount }
        end

        nav[#nav + 1] = {
            id = 'pickup',
            label = 'Pickup Melted Items',
            icon = 'PackageCheck',
            content = {
                title = 'Pickup Melted Items',
                actions = { { id = pickupAction, label = 'Pickup Melted Items', confirm = 'Collect your melted items?' } },
                blocks = { { type = 'list', id = 'melted', items = pickupItems } },
            },
        }
    end

    return nav
end

local function refreshApp()
    QB.nui.updateApp(appId, { navigation = buildNavigation() })
end


local function onAction(actionId, context)
    if actionId == pickupAction then
        TriggerServerEvent('qb-pawnshop:server:pickupMelted', meltedItem)
        return
    end

    local _, itemName = splitItemId(context and context.itemId)
    local amount = context and context.value and tonumber(context.value.amount)

    if not itemName or not amount or amount <= 0 then
        return { notice = { tone = 'destructive', message = 'Trying to sell a negative amount?' } }
    end

    if actionId == sellAction then
        TriggerServerEvent('qb-pawnshop:server:sellPawnItems', itemName, amount)
    elseif actionId == meltAction then
        TriggerServerEvent('qb-pawnshop:server:meltItemRemove', itemName, amount)
    end
end

QB.nui.registerApp({
    id = appId,
    title = 'Pawn Store',
    description = 'Open the Pawn Shop',
    icon = 'Store',
    layout = 'compact',
    defaultView = 'sell',
    width = 500,
    height = 700,
    placement = 'right',
    footer = 'Press Escape to close',
    navigation = buildNavigation(),
    onAction = onAction,
})


local function openPawnShop()
    if QB.nui.isAppOpen(appId) then return end
     if Config.UseTimes and not (GetClockHours() >= Config.TimeOpen and GetClockHours() <= Config.TimeClosed) then
         QB.notify.send({
             title = 'Pawn Store',
             message = 'Pawnshop is closed. Come back between ' .. Config.TimeOpen .. ':00 AM - ' .. Config.TimeClosed .. ':00 PM',
             type = 'error',
         })
         return
     end
    refreshApp()
    QB.nui.openApp(appId)
end


CreateThread(function()
    for key, location in pairs(Config.PawnLocation) do
        QB.blips.create(location.coords, {
            sprite = 431,
            color = 5,
            scale = 0.7,
            shortRange = true,
            name = 'Pawn Store',
        })

        exports.qbtarget:addBoxZone({
            coords = location.coords,
            size = location.size,
            rotation = location.rotation,
            debug = location.debug,
            options = {
                {
                    label = 'Pawn Store',
                    icon = 'Store',
                    onSelect = function() openPawnShop() end
                }
            }
        })
    end
end)

RegisterNetEvent('qb-pawnshop:client:refreshApp', function()
    refreshApp()
end)

RegisterNetEvent('qb-pawnshop:client:startMelting', function(itemName, meltingAmount, meltSeconds)
    if isMelting then return end
    isMelting = true
    meltVersion = meltVersion + 1
    local version = meltVersion
    refreshApp()

    CreateThread(function()
        while isMelting and meltVersion == version do
            if meltSeconds > 0 then Wait(1000) end
            if not isMelting or meltVersion ~= version or not LocalPlayer.state.isLoggedIn then return end
            meltSeconds = meltSeconds - 1
            if meltSeconds <= 0 then
                canTake = true
                isMelting = false
                meltedItem[#meltedItem + 1] = { name = itemName, amount = meltingAmount }
                refreshApp()
                QB.notify.send({ title = 'Pawn Store', message = 'We finished melting your items. You can come pick them up at any time.', type = 'success' })
            end
        end
    end)
end)

RegisterNetEvent('qb-pawnshop:client:resetPickup', function(batches, stillMelting)
    if stillMelting == false then
        isMelting = false
        meltVersion = meltVersion + 1
    end
    meltedItem = batches or {}
    canTake = #meltedItem > 0
    refreshApp()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isMelting = false
    canTake = false
    meltedItem = {}
    meltVersion = meltVersion + 1
    refreshApp()
end)
inited = true
