---
title: kora_pawnshop
sidebar_position: 1
---

# kora_pawnshop

`kora_pawnshop` is a pawn shop for Kora servers. Players walk up to the pawn shop counter, open a `kora_lib` NUI app ("Pawn Store") through `kora_target`, sell configured valuables for cash or bank money, and melt jewellery into raw materials (gold bars, diamonds, electronic kits) that they collect once a timer has elapsed. All prices, melt inputs, durations and rewards are decided on the server; client-supplied quantities are never trusted for payouts. It is a rewrite of `qb-pawnshop` and still uses the legacy `qb-pawnshop:*` event and app names.

Current version: see `version` in `fxmanifest.lua`.

## Features

- **Pawn Store location** - every entry in `Config.PawnLocation` gets a map blip ("Pawn Store", sprite 431) and a `kora_target` box zone with a "Pawn Store" option that opens the app.
- **Opening hours** - optionally restrict the shop to an in-game time window (`Config.UseTimes`, `Config.TimeOpen`, `Config.TimeClosed`), including overnight windows. Outside the window the player gets a "Pawnshop is closed" notification.
- **Selling** - the "Pawn Shop" tab lists every item in the player's inventory that appears in `Config.PawnItems`, with its price and the owned amount. Choosing an amount sells that many items; the money goes to cash, or to the bank when `Config.BankMoney` is `true`.
- **Melting** - the "Melt Items" tab lists inventory items from `Config.MeltingItems`. Melting removes the items immediately and starts a server-side timer (`meltTime` minutes per item). Only one batch can be melting at a time.
- **Pickup** - when a melt finishes, the player is notified and a "Pickup Melted Items" tab appears. Pickup delivers the rewards recorded by the server. If the inventory is full, undelivered rewards stay owed and a later pickup delivers only what is still owed.
- **Session-scoped melts** - pending melts are kept in server memory per character session. Logging out, disconnecting or restarting the resource clears them (items in the melter are lost).
- **Anti-exploit checks** - sell, melt and pickup requests from players that are not near a pawn location, or that name an item which is not configured, result in a permanent ban. See [Events](./events.md).

## Requirements

Declared in `fxmanifest.lua`:

| Resource | Used for |
| --- | --- |
| [kora_lib](https://github.com/KoraFiveM/kora_lib) | `Kora.nui` app shell, notifications, blips, locales, distance checks, logging |
| [kora_core](https://github.com/KoraFiveM/kora_core) | Player data (`getPlayerData`), shared items (`getShared`), money (`addMoney`), identifiers |
| [kora_sql](https://github.com/KoraFiveM/kora_sql) | Writing ban records |

Used but not declared as a dependency:

| Resource | Used for |
| --- | --- |
| [kora_target](https://github.com/KoraFiveM/kora_target) | `exports.kora_target:addBoxZone` for the counter interaction (client) |
| [kora_inventory](https://github.com/KoraFiveM/kora_inventory) | Called as `exports['qb-inventory']` (`RemoveItem`, `AddItem`) and the `qb-inventory:client:ItemBox` event; `kora_inventory` provides `qb-inventory` |

## Installation

1. Place the resource in your resources folder (in the Kora setup it is listed in `resources.manifest`).
2. Ensure it after its dependencies in `server.cfg`:

   ```cfg
   ensure kora_lib
   ensure kora_sql
   ensure kora_core
   ensure kora_inventory
   ensure kora_target
   ensure kora_pawnshop
   ```

3. No SQL import is needed. The resource only inserts into the existing `bans` table (see [Database](./database.md)).
4. Make sure every item named in `Config.PawnItems` and `Config.MeltingItems` (inputs and rewards) exists in the `kora_core` shared items list. The defaults are listed in [Items](./items.md).
5. Adjust [Configuration](./configuration.md) (location, hours, prices, melt recipes).

## Testing

- `lua test/smoke/melting.lua` (run from the repository root, with `kora_inventory` and `kora_lib` checked out alongside) exercises the melt and pickup flow against the real inventory code with a controlled clock and host stubs. It does not start FiveM or write SQL.
- `tests/checklist-economy.feature` contains manual QA scenarios for `kora_qa` (registered via `qa_feature` in `fxmanifest.lua`).

## Pages

- [Configuration](./configuration.md) - all `Config` options
- [Using the shop](./ui.md) - the Pawn Store app, selling, melting and pickup flow
- [Items](./items.md) - default pawn and melt items and rewards
- [Events](./events.md) - net events used between client and server
- [Database](./database.md) - tables used
- [Troubleshooting](./troubleshooting.md) - known caveats and common problems

This resource registers no commands and exposes no exports.
