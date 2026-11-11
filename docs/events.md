---
title: Events
sidebar_position: 5
---

# Events

The resource keeps the legacy `qb-pawnshop:*` names. All of these events are internal to the client/server flow of the Pawn Store app; there is no public API for other resources. The resource registers no commands and no exports.

## Server events (internal, guarded)

These are triggered by the app's client code. Do not trigger them from other resources: each handler checks that the player is near a `Config.PawnLocation` (within `distance`) and that the item is configured, and **permanently bans** the player otherwise.

| Event | Payload | Behaviour |
| --- | --- | --- |
| `qb-pawnshop:server:sellPawnItems` | `itemName`, `amount` | Sells `amount` of a `Config.PawnItems` item at the server price. Bans if not near the shop, if the item is not sellable, or if `amount` is not a positive integer. |
| `qb-pawnshop:server:meltItemRemove` | `itemName`, `amount` | Removes the items and records a melt batch with its ready time and rewards. Bans if not near the shop or the item is not meltable. Invalid amounts, a still-running batch, or a concurrent request are ignored silently. |
| `qb-pawnshop:server:pickupMelted` | `batches` (ignored) | Delivers rewards of all ready batches from the server's records. The argument is kept for compatibility only. Bans if not near the shop. |

## Client events (internal)

Sent by the server to the player.

| Event | Payload | Behaviour |
| --- | --- | --- |
| `qb-pawnshop:client:refreshApp` | none | Rebuilds the app navigation (inventory lists, tabs). |
| `qb-pawnshop:client:startMelting` | `itemName`, `amount`, `seconds` | Starts the client countdown, disables the Melt tab and, when done, adds the batch to the pickup list and notifies the player. |
| `qb-pawnshop:client:resetPickup` | `readyBatches`, `stillMelting` | Replaces the pickup list with the batches still owed (each `{ name, amount }`); `stillMelting = false` cancels the client countdown. |

## Events used from other resources

| Event | Side | Use |
| --- | --- | --- |
| `qb-inventory:client:ItemBox` | client (triggered by server) | Shows the item add/remove box after sales, melts and pickups. |
| `QBCore:Server:OnPlayerUnload` | server (listened) | Clears the player's pending melts. |
| `QBCore:Client:OnPlayerUnload` | client (listened) | Resets the melting/pickup state and refreshes the app. |
| `playerDropped` | server (listened) | Clears the player's pending melts. |

Bans are also recorded with `Kora.logging.event('pawnshop', src, { action = 'ban', reason = ... })`.
