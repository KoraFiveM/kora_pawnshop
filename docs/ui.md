---
title: Using the shop
sidebar_position: 3
---

# Using the shop

## Opening the Pawn Store

Go to the pawn shop counter (marked on the map as "Pawn Store") and use the "Pawn Store" target option. If opening hours are enabled and the shop is closed, a notification shows the opening window instead. Otherwise the `qb-pawnshop:app` app opens on the right side of the screen (compact layout, 500 x 700). Press Escape to close it.

The app has up to three tabs.

## Pawn Shop (sell)

Lists every item in your inventory that appears in `Config.PawnItems`, showing the label, "Selling Price $..." and the amount you own. When you own nothing sellable, an empty placeholder ("Nothing in your inventory is worth pawning here.") is shown.

1. Choose **Sell** on an item.
2. Enter an amount between 1 and the amount you own.
3. The server removes the items, pays `amount x price` to cash (or bank with `Config.BankMoney = true`) and shows "You sold ...". If you do not have enough of the item you get "You don't have enough of that item".

The list refreshes after every sale.

## Melt Items

Lists inventory items that appear in `Config.MeltingItems` ("Melt ..."). The tab is disabled while a melt is running.

1. Choose **Melt** on an item and enter an amount.
2. The server removes the items and starts a timer of `amount x meltTime` minutes. You are told how many minutes to wait.
3. When the timer ends you receive the notification "We finished melting your items. You can come pick them up at any time." You do not have to be at the shop while the items melt.

Only one batch can melt at a time; a new melt request is ignored by the server until the previous batch is ready. Finished but uncollected batches do not block a new melt.

## Pickup Melted Items

This tab appears once a batch is ready and lists the finished batches. Choose **Pickup Melted Items** and confirm.

- The server delivers the rewards it recorded when the melt started, regardless of what the client sends.
- Each delivered reward shows "You received ...".
- If a reward does not fit in your inventory you get "Your inventory is full, you couldn't carry ..." and that reward stays owed. Free some space and pick up again; only the outstanding rewards are delivered.
- Picking up before any batch is ready does nothing.

## Session rules

Pending and uncollected melts are stored in server memory for the current character. They are cleared on logout (`QBCore:Server:OnPlayerUnload`), disconnect, or a resource restart. Items that were being melted are then lost.

Invalid amounts (empty, zero or negative) are rejected in the app with "Trying to sell a negative amount?".
