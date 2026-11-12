---
title: Database
sidebar_position: 9
---

# Database

`kora_pawnshop` creates no tables and ships no SQL files. Sales, melts and pickups are not persisted; pending melts live only in server memory.

## `bans` (write only)

When an exploit check fails (see [Events](./events.md)), the server inserts a permanent ban into the existing `bans` table used by the core ban system:

```sql
INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby)
VALUES (?, ?, ?, ?, ?, ?, ?)
```

| Column | Value |
| --- | --- |
| `name` | Player name (`GetPlayerName`) |
| `license` | License identifier from `kora_core:getIdentifiers` |
| `discord` | Discord identifier |
| `ip` | IP identifier |
| `reason` | For example `sellPawnItems Exploiting`, `sellPawnItems invalid item`, `sellPawnItems invalid amount`, `meltItemRemove Exploiting`, `meltItemRemove invalid item`, `pickupMelted Exploiting` |
| `expire` | `2147483647` (permanent) |
| `bannedby` | `qb-pawnshop` |

The player is then dropped with "You were permanently banned by the server for: Exploiting".
