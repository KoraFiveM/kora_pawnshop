---
title: "Installation"
sidebar_position: 2
---


# Installation

Kora Pawnshop lets a player sell a fixed list of valuables for cash or bank money, or melt them down over time for crafting materials, through one kora_lib AppShell app. It answers to the legacy export/resource name `kora_pawnshop`.

## Install Kora Pawnshop

1. **Add the folder** — Place `kora_pawnshop` in your resources directory (on the Kora recipe it is `resources/[kora]/kora_pawnshop`).

2. **Start its dependencies first** — It declares `dependency` on `kora_lib`, `kora_core` and `kora_sql`. Start all three before `ensure kora_pawnshop`.

   ```bash title="server.cfg"
   ensure kora_lib
   ensure kora_sql
   ensure kora_core
   ensure kora_pawnshop
   ```

3. **It also needs kora_inventory and kora_target running** — The manifest does not declare these as `dependency`, but the code calls `exports['qb-inventory']` directly (`RemoveItem`/`AddItem`) and `exports.kora_target:addBoxZone` to place the interaction point. Both must be running or the pawnshop fails to start cleanly / cannot be interacted with.

4. **Review the manifest** — Script load order: `shared/config.lua` on both realms, then every `server/**.lua` file on the server and every `client/**.lua` file on the client.

   ```lua title="fxmanifest.lua"
   fx_version 'cerulean'
   game 'gta5'
   lua54 'yes'
   author 'Kakarot'
   description 'Allows players to sell items for money, built on the kora_lib AppShell'
   version '0.2.0'

   dependency 'kora_lib'
   dependency 'kora_core'
   dependency 'kora_sql'

   shared_script {
       '@kora_lib/init.lua',
       'shared/config.lua'
   }

   server_scripts {
       '@kora_sql/init.lua',
       'server/**.lua',
   }

   client_script 'client/**.lua'

   files {
       'locales/*.json',
   }

   -- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
   qa_feature 'tests/*.feature'
   ```

5. **Set up pawn locations, hours and item lists** — Everything is configured in `shared/config.lua` — no database table is created by this resource. See the Configuration section below for each option's real default.

   ```lua title="shared/config.lua"
   Config.PawnLocation = {
       {
           coords = vector3(412.34, 314.81, 103.13),
           size = vector4(1.5, 1.8, 4.45, 207.0), -- length, width, height, heading
           distance = 3.0,
           debug = false,
       },
   }

   Config.BankMoney = false -- Set to true if you want the money to go into the players bank
   Config.UseTimes = true   -- Opening hours on (in-game clock). Set to false if you want the pawnshop open 24/7
   Config.TimeOpen = 7      -- Opening hour (0-23, in-game clock): open from 07:00
   Config.TimeClosed = 17   -- Closing hour (0-23, in-game clock): closed from 17:00. May be lower than TimeOpen for overnight hours

   Config.PawnItems = {
       { item = 'goldchain', price = math.random(50, 100) },
       { item = 'diamond_ring', price = math.random(50, 100) },
       -- ...
   }

   Config.MeltingItems = { -- meltTime is minutes per item
       { item = 'goldchain', meltTime = 0.15, rewards = { { item = 'goldbar', amount = 2 } } },
       -- ...
   }
   ```

## Configuration (shared/config.lua)

- `Config.PawnLocation` — array of `{ coords, size, distance, debug }`. Each entry gets a map blip (sprite 431, color 5) and a `kora_target` box zone (`size` = `vector4(length, width, height, heading)`); `distance` (default `3.0` where set, falls back to `5.0` server-side if omitted — see Permissions) is how close the server requires a player to be before honoring a sell/melt/pickup request from them.
- `Config.BankMoney` (boolean, default `false`) — when `true`, a sale pays into the player's bank account instead of cash.
- `Config.UseTimes` (boolean, default `true`) — gates the shop by in-game clock hour on the CLIENT only (opening the app). When `false` the shop is open 24/7.
- `Config.TimeOpen` / `Config.TimeClosed` (integer 0–23, defaults `7` / `17`) — open from `TimeOpen:00` until `TimeClosed:00`; the closing hour itself is closed. `TimeOpen > TimeClosed` is treated as overnight hours (e.g. 20 → 4).
- `Config.PawnItems` — array of `{ item, price }` sold at the counter. Shipped defaults: `goldchain`, `diamond_ring`, `rolex`, `tenkgoldchain`, `tablet`, `iphone`, `samsungphone`, `laptop`, each with `price = math.random(50, 100)` — note this randomises ONCE, when the config file is parsed at resource start, not per sale.
- `Config.MeltingItems` — array of `{ item, meltTime, rewards }`. `meltTime` is MINUTES per single item melted (the server multiplies it by the quantity). `rewards` is `{ item, amount }[]` granted per item melted. Shipped defaults all use `meltTime = 0.15` (9 seconds per item): `goldchain` → 2 `goldbar`; `diamond_ring` → 1 `diamond` + 1 `goldbar`; `rolex` → 1 `diamond` + 1 `goldbar` + 1 `electronickit`; `tenkgoldchain` → 5 `diamond` + 1 `goldbar`.
- `Config.findPawnItem(itemName)` / `Config.findMeltItem(itemName)` — linear-scan lookup helpers used by both realms; return the matching config entry or `nil`.

## Requirements

| Resource | Declared in manifest | Used for |
| --- | --- | --- |
| [kora_lib](https://github.com/KoraFiveM/kora_lib) | yes | `Kora.nui` app shell, notifications, blips, locales, distance checks, logging |
| [kora_core](https://github.com/KoraFiveM/kora_core) | yes | Player data (`getPlayerData`), shared items (`getShared`), money (`addMoney`), identifiers |
| [kora_sql](https://github.com/KoraFiveM/kora_sql) | yes | Writing ban records |
| [kora_target](https://github.com/KoraFiveM/kora_target) | no | `exports.kora_target:addBoxZone` for the counter interaction (client) |
| [kora_inventory](https://github.com/KoraFiveM/kora_inventory) | no | Called as `exports['qb-inventory']` (`RemoveItem`, `AddItem`) and the `qb-inventory:client:ItemBox` event; `kora_inventory` provides `qb-inventory` |

A complete `server.cfg` order including the undeclared dependencies:

```cfg title="server.cfg"
ensure kora_lib
ensure kora_sql
ensure kora_core
ensure kora_inventory
ensure kora_target
ensure kora_pawnshop
```

## After installing

- No SQL import is needed. The resource only inserts into the existing `bans` table (see [Database](./database.md)).
- Every item named in `Config.PawnItems` and `Config.MeltingItems` (inputs and rewards) must exist in the `kora_core` shared items list. The defaults are listed in [Items](./items.md).
- Full option reference with types and defaults: [Configuration](./configuration.md).

## Testing

- `lua test/smoke/melting.lua` (run from the repository root, with `kora_inventory` and `kora_lib` checked out alongside) exercises the melt and pickup flow against the real inventory code with a controlled clock and host stubs. It does not start FiveM or write SQL.
- `tests/checklist-economy.feature` contains manual QA scenarios for `kora_qa` (registered via `qa_feature` in `fxmanifest.lua`).
