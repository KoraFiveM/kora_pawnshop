---
title: Items
sidebar_position: 7
---

# Items

The resource does not define items. All items below must exist in the `kora_core` shared items list (they are part of the default list). Labels shown in the app come from `exports.kora_core:getShared('items', name)`; if an item is missing, its name is used as the label.

## Sellable items (default)

| Item | Price |
| --- | --- |
| `goldchain` | random 50-100 |
| `diamond_ring` | random 50-100 |
| `rolex` | random 50-100 |
| `tenkgoldchain` | random 50-100 |
| `tablet` | random 50-100 |
| `iphone` | random 50-100 |
| `samsungphone` | random 50-100 |
| `laptop` | random 50-100 |

Prices are rolled once per resource start (see [Configuration](./configuration.md#pawn-items)).

## Melting recipes (default)

All defaults use `meltTime = 0.15` minutes (about 9 seconds) per item. Rewards are per melted item.

| Input | Rewards per item |
| --- | --- |
| `goldchain` | 2x `goldbar` |
| `diamond_ring` | 1x `diamond`, 1x `goldbar` |
| `rolex` | 1x `diamond`, 1x `goldbar`, 1x `electronickit` |
| `tenkgoldchain` | 5x `diamond`, 1x `goldbar` |

Example: melting 3 `goldchain` takes about 27 seconds and yields 6 `goldbar`.
