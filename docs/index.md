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
- **Anti-exploit checks** - sell, melt and pickup requests from players that are not near a pawn location, or that name an item which is not configured, result in a permanent ban. See [Events](./events.md) and [How to use](./how-to-use.md#permissions-and-anti-exploit).

## Documentation map

- [Installation](./installation.md) - install steps, manifest, dependencies, config overview, testing
- [How to use](./how-to-use.md) - selling, melting, pickup, validation and anti-exploit rules, in-app walkthrough
- [Configuration](./configuration.md) - all `Config` options, locales
- [Items](./items.md) - default pawn and melt items and rewards
- [Events](./events.md) - net events used between client and server
- [Database](./database.md) - tables used
- [Troubleshooting](./troubleshooting.md) - known caveats and common problems

This resource registers no commands and exposes no exports, so there are no commands or API pages.
