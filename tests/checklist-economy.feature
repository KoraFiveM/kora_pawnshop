# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_pawnshop — Economy

  @kora_pawnshop @checklist @checklist:kora_pawnshop:pawn-blip-target @cat:economy
  Scenario: Pawn shop blip and target
    """
    Checklist test: Go to the pawn shop (412.34,314.81,103.13); blip on map and target 'Pawn Store' on the counter opens the panel.
    """
    When I manually: go to the pawn shop counter and look at the map
    Then I confirm: a pawn shop blip is shown on my map
    When I manually: use the target on the counter
    Then I confirm: a target option 'Pawn Store' is shown on the counter
    And the "qb-pawnshop:app" app opens

  @kora_pawnshop @checklist @checklist:kora_pawnshop:sell-items @cat:economy
  Scenario: Sell items tab
    """
    Checklist test: With goldchain, diamond_ring, rolex, tablet, phone or laptop in inventory open Pawn Store > Pawn Shop, Sell with amount; paid $50-100 each.
    """
    Given I have 1 "goldchain"
    When I manually: open Pawn Store > Pawn Shop at the pawn shop counter
    Then the "qb-pawnshop:app" app opens
    When I manually: sell goldchain with an amount of 1 in the Sell tab
    Then I should have no "goldchain"
    And my cash balance should have changed by 50
    And I confirm: I was paid between $50 and $100 per item sold

  @kora_pawnshop @checklist @checklist:kora_pawnshop:sell-amount-validation @cat:economy
  Scenario: Sell amount validation
    """
    Checklist test: Enter 0, negative or more than owned; rejected ('Trying to sell a negative amount?' or max limit).
    """
    Given I have 1 "goldchain"
    When I manually: open Pawn Store > Pawn Shop at the pawn shop counter
    And I manually: enter an amount of 0 in the Sell tab and confirm
    Then I confirm: the sale is rejected
    When I manually: enter a negative amount and confirm
    Then I should see a notification containing "Trying to sell a negative amount?"
    When I manually: enter an amount greater than the amount I own and confirm
    Then I confirm: the sale is rejected with a max limit message
    And I should have 1 "goldchain"

  @kora_pawnshop @checklist @checklist:kora_pawnshop:sell-empty-list @cat:economy
  Scenario: Empty state when nothing sellable
    """
    Checklist test: Open Sell tab with no pawnable items; panel shows empty 'PackageOpen' placeholder.
    """
    Given I have no "goldchain"
    And I have no "diamond_ring"
    And I have no "rolex"
    And I have no "tablet"
    And I have no "phone"
    And I have no "laptop"
    When I manually: open Pawn Store > Pawn Shop at the pawn shop counter and open the Sell tab
    Then I confirm: the panel shows an empty 'PackageOpen' placeholder

  @kora_pawnshop @checklist @checklist:kora_pawnshop:pay-to-cash-or-bank @cat:economy
  Scenario: Payout account
    """
    Checklist test: After selling check cash increases (Config.BankMoney=false) rather than bank.
    """
    Given I have 1 "goldchain"
    When I manually: open Pawn Store > Pawn Shop at the pawn shop counter
    And I manually: sell goldchain with an amount of 1
    Then I confirm: my cash increased and my bank did not (only applies when Config.BankMoney is false; otherwise the bank increases)

  @kora_pawnshop @checklist @checklist:kora_pawnshop:melt-items @cat:economy
  Scenario: Melt items tab
    """
    Checklist test: Open Melt Items; goldchain, diamond_ring, rolex, tenkgoldchain listed; Melt with amount starts a melt batch and removes the items.
    """
    Given I have 1 "goldchain"
    And I have 1 "diamond_ring"
    And I have 1 "rolex"
    And I have 1 "tenkgoldchain"
    When I manually: open Pawn Store and open the Melt Items tab
    Then I confirm: goldchain, diamond_ring, rolex and tenkgoldchain are listed
    When I manually: melt 1 goldchain with an amount of 1
    Then I should have no "goldchain"
    And I confirm: a melt batch was started

  @kora_pawnshop @checklist @checklist:kora_pawnshop:melt-timer-notify @cat:economy
  Scenario: Melting completion notice
    """
    Checklist test: After ~9 seconds per item (0.15 min) a notification 'We finished melting your items' appears.
    """
    Given I have 1 "goldchain"
    When I manually: open Pawn Store > Melt Items and melt 1 goldchain
    And I wait 10 seconds
    Then I should see a notification containing "We finished melting your items"

  @kora_pawnshop @checklist @checklist:kora_pawnshop:pickup-melted @cat:economy
  Scenario: Pickup melted items
    """
    Checklist test: Open Pickup Melted Items, confirm; rewards (goldbar, diamond, electronickit) added. Before completion nothing is owed.
    """
    Given I have 1 "goldchain"
    When I manually: open Pawn Store > Melt Items and melt 1 goldchain
    And I manually: immediately open Pickup Melted Items and confirm before melting completes
    Then I confirm: nothing is owed and no items are received
    When I wait 10 seconds
    And I manually: open Pickup Melted Items and confirm
    Then I confirm: the melt rewards (goldbar, diamond, electronickit as applicable) were added to my inventory

  @kora_pawnshop @checklist @checklist:kora_pawnshop:melt-inventory-full @cat:economy
  Scenario: Pickup with full inventory
    """
    Checklist test: Fill inventory then pick up; items remain owed and a retry delivers only what is still owed, no duplicates.
    """
    Given I have 1 "goldchain"
    When I manually: open Pawn Store > Melt Items and melt 1 goldchain
    And I wait 10 seconds
    And I manually: fill my inventory completely
    And I manually: open Pickup Melted Items and confirm
    Then I confirm: the items remain owed and are not delivered
    When I manually: free inventory space and pick up again
    Then I confirm: only the still owed items are delivered with no duplicates

  @kora_pawnshop @checklist @checklist:kora_pawnshop:melt-session-clear @cat:economy
  Scenario: Pending melts clear on logout
    """
    Checklist test: Start a melt, relog the character; pending melts are cleared (per character session).
    """
    Given I have 1 "goldchain"
    When I manually: open Pawn Store > Melt Items and melt 1 goldchain
    And I manually: log out and relog the same character
    And I manually: open Pickup Melted Items
    Then I confirm: no pending melts are owed (cleared for the new character session)

  @kora_pawnshop @checklist @checklist:kora_pawnshop:opening-hours @cat:economy @manual
  Scenario: Opening hours (if enabled)
    """
    Checklist test: Config.UseTimes is false so shop is open 24/7; if enabled, outside 7-17 'Pawnshop is closed' notification shows.
    """
    When I manually: open Pawn Store at the pawn shop at any time of day
    Then I confirm: the shop is open 24/7 (when Config.UseTimes is false)
    And I confirm: outside 7-17 a 'Pawnshop is closed' notification shows (only applies when Config.UseTimes is enabled; otherwise mark Pass if nothing happens)
