---
title: Configuration
sidebar_position: 6
---

# Configuration

All options live in `shared/config.lua`, which is loaded on both client and server. Restart the resource after editing it.

## Location

`Config.PawnLocation` is a list; each entry creates a blip and a target zone, and is used by the server-side proximity check.

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `coords` | `vector3` | `vector3(412.34, 314.81, 103.13)` | Centre of the counter zone and blip position. |
| `size` | `vector4` | `vector4(1.5, 1.8, 4.45, 207.0)` | Box zone size passed to `kora_target`: x = length, y = width, z = height. The fourth value is commented as heading but is not read (see below). |
| `rotation` | number | not set | Optional zone rotation in degrees around Z, passed to `kora_target:addBoxZone`. Defaults to 0 when absent. |
| `distance` | number | `3.0` | Server-side maximum distance (from `coords`) for sell, melt and pickup requests. Falls back to `5.0` if omitted. |
| `debug` | boolean | `false` | Draws the target zone for debugging. |

The client passes `location.rotation` to `kora_target`, not the fourth component of `size`. To rotate the zone, add a `rotation` key:

```lua
Config.PawnLocation = {
    {
        coords = vector3(412.34, 314.81, 103.13),
        size = vector3(1.5, 1.8, 4.45),
        rotation = 207.0,
        distance = 3.0,
        debug = false,
    },
}
```

Keep `distance` large enough to cover the whole zone: a request from a player outside this radius is treated as an exploit and the player is banned.

## Payout and opening hours

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `Config.BankMoney` | boolean | `false` | `true` pays sales into the bank account, `false` pays cash. |
| `Config.UseTimes` | boolean | `true` | Enable opening hours based on the in-game clock. `false` keeps the shop open 24/7. |
| `Config.TimeOpen` | integer (0-23) | `7` | Opening hour; open from `TimeOpen:00`. |
| `Config.TimeClosed` | integer (0-23) | `17` | Closing hour; closed from `TimeClosed:00`. |

Opening hours are evaluated on the client when opening the app:

- `TimeOpen` lower than `TimeClosed`: open while `TimeOpen <= hour < TimeClosed`.
- `TimeOpen` greater than `TimeClosed`: overnight window, open while `hour >= TimeOpen` or `hour < TimeClosed` (for example 20 to 4).
- `TimeOpen` equal to `TimeClosed`: always open.

## Pawn items

`Config.PawnItems` lists the items that can be sold.

| Key | Type | Description |
| --- | --- | --- |
| `item` | string | Item name as defined in the `kora_core` shared items. |
| `price` | number | Price per item. |

Defaults: `goldchain`, `diamond_ring`, `rolex`, `tenkgoldchain`, `tablet`, `iphone`, `samsungphone`, `laptop`, each with `price = math.random(50, 100)`.

`math.random` is evaluated once when the config file loads, separately on the server and on each client. The server value is what the player is actually paid; the price shown in the app comes from the client's own roll and can differ. Use fixed numbers if the displayed price must match the payout:

```lua
Config.PawnItems = {
    { item = 'goldchain', price = 75 },
    { item = 'rolex', price = 90 },
}
```

## Melting items

`Config.MeltingItems` lists the items that can be melted and what they yield.

| Key | Type | Description |
| --- | --- | --- |
| `item` | string | Input item name. |
| `meltTime` | number | Minutes per item. Total duration = amount x `meltTime` minutes (rounded up to whole milliseconds). |
| `rewards` | list | Each entry `{ item = string, amount = number }`; the player receives `amount` x number of melted items of each reward. |

```lua
Config.MeltingItems = {
    { item = 'goldchain', meltTime = 0.15, rewards = { { item = 'goldbar', amount = 2 } } },
}
```

Defaults (all with `meltTime = 0.15`, about 9 seconds per item) are listed in [Items](./items.md). If a `meltTime` or reward amount is not numeric, or a reward item does not exist in shared items, the server prints an `[qb-pawnshop] Invalid ...` message and refuses the melt before removing anything.

## Helper functions

`shared/config.lua` also defines two lookup helpers used by the client and server:

| Function | Returns |
| --- | --- |
| `Config.findPawnItem(itemName)` | The `Config.PawnItems` entry for `itemName`, or `nil`. |
| `Config.findMeltItem(itemName)` | The `Config.MeltingItems` entry for `itemName`, or `nil`. |

## Locales

Player-facing notification texts are in `locales/en.json` (loaded through `Kora.lang`):

| Key | Default text |
| --- | --- |
| `info.title` | Pawn Shop |
| `info.melt_wait` | Your items are melting. Come back in `%{value}` minutes. |
| `success.sold` | You sold `%{value}`x `%{value2}` for $`%{value3}` |
| `success.items_received` | You received `%{value}`x `%{value2}` |
| `error.no_items` | You don't have enough of that item |
| `error.inventory_full` | Your inventory is full, you couldn't carry `%{value}` |
| `error.closed` | Pawnshop is closed. Come back between `%{open}` and `%{close}`. |
| `ui.sell` | Sell |
| `ui.melt` | Melt |

App titles, tab names, empty-state texts, item descriptions and the "We finished melting your items" notification are hard-coded in English in `client/client.lua`.
