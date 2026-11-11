---
title: Troubleshooting
sidebar_position: 7
---

# Troubleshooting

## The price shown differs from the money received

Default prices use `math.random(50, 100)`, which is rolled separately on the server and on each client when `shared/config.lua` loads. The server price is paid. Set fixed prices in `Config.PawnItems` to make them match (see [Configuration](./configuration.md#pawn-items)).

## The target zone is not rotated

The fourth component of `size` (commented as heading) is not used. The client passes `location.rotation` to `kora_target`; add a `rotation` key to the location entry.

## Players get banned when using the shop

Sell, melt and pickup requests are rejected with a permanent ban if the player is farther than `distance` (default `3.0`, fallback `5.0`) from the location `coords`. If you enlarge or move the target zone, increase `distance` accordingly. Banned players are recorded in the `bans` table with `bannedby = 'qb-pawnshop'` (see [Database](./database.md)).

## "Pawnshop is closed"

`Config.UseTimes` is `true` by default with hours 07:00 to 17:00 on the in-game clock. Set `Config.UseTimes = false` for 24/7 access or adjust `TimeOpen`/`TimeClosed`.

## A melt does not start

- Another batch is still melting; wait until it is ready (the Melt tab is disabled meanwhile).
- The server console shows `[qb-pawnshop] Invalid melt time ...` or `[qb-pawnshop] Invalid melting reward ...`: fix `meltTime`/`rewards` in `Config.MeltingItems` or add the missing reward item to the shared items.

## Melted items disappeared

Pending melts are cleared on logout, disconnect and resource restart. This is by design.

## Pickup says the inventory is full

The rewards stay owed. Free inventory space and pick up again; only the outstanding rewards are delivered.
