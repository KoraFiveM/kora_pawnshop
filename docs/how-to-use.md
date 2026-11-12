---
title: "How to use"
sidebar_position: 3
---


# How to use

A player interacts with a `kora_target` box zone at a configured pawn location to open the `qb-pawnshop:app` AppShell app (three tabs: Pawn Shop, Melt Items, and — only once something is ready — Pickup Melted Items). Every state-changing action round-trips to the server; the server is the sole authority on what is owned, what melting has produced, and what is still owed.

## Selling items

The Pawn Shop tab lists only items the player currently holds that also appear in `Config.PawnItems`, each with a "Sell" action asking for an amount (clamped client-side between 1 and the held quantity). Submitting fires `qb-pawnshop:server:sellPawnItems`, which the server validates from scratch — the client-side clamp is a convenience, not a trust boundary.

- Server checks, in order: the caller is near a configured pawn location (`nearAnyPawnLocation`); `itemName` matches a `Config.PawnItems` entry; `itemAmount` is a positive integer (`positiveInteger` — see Validation below). Any of the first three failing permanently bans the player (see Permissions).
- On success: `exports['qb-inventory']:RemoveItem` removes `itemAmount` of the item; if that succeeds, `exports.kora_core:addMoney` credits `itemAmount * entry.price` to `bank` (if `Config.BankMoney`) or `cash`, the player is sent a localized `success.sold` notification, and an `ItemBox` removal toast fires on the client. If the removal fails (player no longer actually holds enough), the player gets `error.no_items` instead and no money changes hands.
- The app is refreshed (`qb-pawnshop:client:refreshApp`) either way, so the listing reflects the player's actual inventory after the attempt.

## Melting items

The Melt Items tab lists held items that also appear in `Config.MeltingItems`. Submitting an amount fires `qb-pawnshop:server:meltItemRemove(itemName, itemAmount)`. Melting state (what was fed in, when it finishes, what it owes) lives only on the server, keyed by `source` and cross-checked against the player's `citizenid` — nothing about an in-progress or completed melt is trusted from the client.

- Validation mirrors selling: proximity, a known `Config.MeltingItems` entry, and `positiveInteger(itemAmount)` — but an invalid amount here is simply ignored (`return`), it does NOT trigger `exploitBan` the way an invalid amount does in `sellPawnItems`. See Validation below for the precise difference.
- Only one melt batch may be "in flight" being removed at a time per player (`state.busy` reservation) — this guards the window where `exports['qb-inventory']:RemoveItem` can yield, including against a reentrant call from the same player. A second melt cannot start while the inventory removal for the first is still resolving, and a melt already queued (its `readyAt` not yet reached) also blocks starting another.
- Duration is `itemAmount * meltTime * 60000` ms, rounded up with `math.ceil`. Reward quantities are `itemAmount * reward.amount` per configured reward. Both are sanity-checked (`NaN`/`inf` guarded) before anything is removed from the inventory; a bad config value is logged to console and the request is dropped, nothing is taken from the player.
- On a successful removal the server starts the client-side countdown (`qb-pawnshop:client:startMelting`) and the batch (`{ name, amount, readyAt, rewards }`) is appended to that player's pending list. The player is notified how many minutes to wait (`info.melt_wait`).

## Picking up melted items

Once a batch's client-side timer reaches zero, a "Pickup Melted Items" tab appears and its one action fires `qb-pawnshop:server:pickupMelted`. The client-supplied batch list argument is accepted for backward compatibility but ignored for anything that matters — quantities, items and readiness all come from the server's own `pendingMelts` state.

- The server walks every pending batch for that player: a batch is only "ready" once `GetGameTimer() >= batch.readyAt`. For each ready batch it delivers any reward not already marked `delivered`, via `exports['qb-inventory']:AddItem`, one reward at a time.
- A reward that fails to be added (inventory full) is NOT lost: it stays undelivered and the batch remains in the pending list for a later pickup attempt, and the player gets an `error.inventory_full` warning naming the item. A reward that succeeds is marked `delivered` so a retry can never grant it twice.
- After processing, the server re-syncs the client with exactly what is still outstanding (`qb-pawnshop:client:resetPickup`, batches + whether anything is still melting) and refreshes the app.
- Pending melts are character-scoped, not account-scoped: `playerDropped`, `QBCore:Server:OnPlayerUnload`, or simply the citizenid on file no longer matching the pending state (a character swap) all discard the pending batches for that `source`. A resource restart also clears them — this is in-memory state only, nothing is persisted to a database.

## Validation: sellPawnItems vs. meltItemRemove (read directly from current server/server.lua)

Both handlers validate the quantity argument with the exact same shared helper, `positiveInteger(value)` (server/server.lua lines 6–10): `tonumber(value)` must succeed, the result must be `> 0`, and `Kora.util.isInteger(amount)` must be true (rejects fractions, `NaN`, `inf`/`-inf`, and non-numbers); on success it returns `math.tointeger(amount)`, a true Lua integer. Neither handler does any additional range/upper-bound check on the amount itself — the only other constraint on quantity is implicit, from however much the player actually holds, enforced by the inventory `RemoveItem` call.

- `sellPawnItems`: `itemAmount = positiveInteger(itemAmount); if not itemAmount then exploitBan(src, 'sellPawnItems invalid amount') return end` — an invalid amount is treated as evidence of tampering (the client already clamps the field to a valid range, so a bad value here did not come from the shipped UI) and the player is permanently banned via a direct `bans` table insert plus `DropPlayer`.
- `meltItemRemove`: `itemAmount = positiveInteger(itemAmount); if not itemAmount then return end` — an invalid amount is simply discarded, no ban, no notification, no further processing.
- So the integer/positivity check itself is identical in both handlers (same helper function, same logic); what differs is strictly the CONSEQUENCE of failing it — `sellPawnItems` escalates to a permanent ban, `meltItemRemove` silently no-ops. Nothing in the current source conditions that difference on anything other than which handler it is; it is not a severity tier based on how invalid the value is.

## Permissions and anti-exploit

- `nearAnyPawnLocation(src)` — every mutating event (`sellPawnItems`, `meltItemRemove`, `pickupMelted`) first requires the caller to be within `location.distance` (falls back to `5.0` if a location entry omits `distance`) of at least one `Config.PawnLocation` entry, checked with `Kora.distance.player`.
- `exploitBan(src, reason)` — inserts a permanent ban row (`expire = 2147483647`) into the `bans` table keyed by the player's license/discord/ip identifiers, logs a `pawnshop` event via `Kora.logging.event`, and immediately `DropPlayer`s them with a fixed "Exploiting" message. It is called for: failing the proximity check on any of the three events, an unrecognized item name in `sellPawnItems` or `meltItemRemove`, and an invalid amount specifically in `sellPawnItems` (not in `meltItemRemove` — see Validation above).
- There is no permission/job/ace check anywhere in this resource — any connected player who is near a configured location and owns eligible items can sell or melt. Access is purely geographic plus inventory ownership.

## Walkthrough in the app

### Opening the Pawn Store

Go to the pawn shop counter (marked on the map as "Pawn Store") and use the "Pawn Store" target option. If opening hours are enabled and the shop is closed, a notification shows the opening window instead. Otherwise the `qb-pawnshop:app` app opens on the right side of the screen (compact layout, 500 x 700). Press Escape to close it.

### Selling

The tab shows the label, "Selling Price $..." and the amount you own. When you own nothing sellable, an empty placeholder ("Nothing in your inventory is worth pawning here.") is shown.

1. Choose **Sell** on an item.
2. Enter an amount between 1 and the amount you own.
3. The server removes the items, pays `amount x price` to cash (or bank with `Config.BankMoney = true`) and shows "You sold ...". If you do not have enough of the item you get "You don't have enough of that item".

The list refreshes after every sale.

### Melting

The tab is disabled while a melt is running.

1. Choose **Melt** on an item and enter an amount.
2. The server removes the items and starts a timer of `amount x meltTime` minutes. You are told how many minutes to wait.
3. When the timer ends you receive the notification "We finished melting your items. You can come pick them up at any time." You do not have to be at the shop while the items melt.

Finished but uncollected batches do not block a new melt.

### Picking up

The Pickup tab lists the finished batches. Choose **Pickup Melted Items** and confirm.

- Each delivered reward shows "You received ...".
- If a reward does not fit in your inventory you get "Your inventory is full, you couldn't carry ..." and that reward stays owed. Free some space and pick up again; only the outstanding rewards are delivered.
- Picking up before any batch is ready does nothing.

Invalid amounts (empty, zero or negative) are rejected in the app with "Trying to sell a negative amount?".

See also [Events](./events.md), [Configuration](./configuration.md), [Items](./items.md) and [Troubleshooting](./troubleshooting.md).
