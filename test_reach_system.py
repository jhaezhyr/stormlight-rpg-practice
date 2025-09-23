#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

from src.game import Game
from src.equipment import Weapon, WeaponType, DamageType

# Test reach-based combat
game = Game("Alice", "Bob")

print("=== Testing Reach System ===")
print(f"Initial distance: {game.state.distance}ft")

# Test basic unarmed reach
print(f"Alice reach (unarmed): {game.player1.get_reach()}ft")
print(f"Bob reach (unarmed): {game.player2.get_reach()}ft")

# Create weapons with different reach
longspear = Weapon("Longspear", "1d8", DamageType.KEEN, WeaponType.MELEE, "Heavy Weaponry",
                   traits=["Two-Handed"], reach=10)  # +5 reach weapon
shortspear = Weapon("Shortspear", "1d8", DamageType.KEEN, WeaponType.MELEE, "Light Weaponry",
                    traits=["Two-Handed"], reach=5)  # Normal reach weapon

print("\n=== Testing with Different Weapons ===")

# Equip Alice with longspear (10ft reach)
game.player1.equip_weapon(longspear, "main")
print(f"Alice equipped with Longspear (reach: {game.player1.get_reach()}ft)")

# Equip Bob with shortspear (5ft reach)
game.player2.equip_weapon(shortspear, "main")
print(f"Bob equipped with Shortspear (reach: {game.player2.get_reach()}ft)")

# Test attack availability at different distances
print(f"\nAt {game.state.distance}ft apart:")
print(f"Alice can attack Bob: {game.player1.can_reach_target(game.state.distance)}")
print(f"Bob can attack Alice: {game.player2.can_reach_target(game.state.distance)}")

# Move closer to test reach differences
game.state.set_player_position(game.player2, 15)  # Distance now 15ft
print(f"\nAt {game.state.distance}ft apart:")
print(f"Alice can attack Bob: {game.player1.can_reach_target(game.state.distance)}")
print(f"Bob can attack Alice: {game.player2.can_reach_target(game.state.distance)}")

# Move to exactly 10ft apart
game.state.set_player_position(game.player2, 10)  # Distance now 10ft
print(f"\nAt {game.state.distance}ft apart:")
print(f"Alice can attack Bob: {game.player1.can_reach_target(game.state.distance)}")
print(f"Bob can attack Alice: {game.player2.can_reach_target(game.state.distance)}")

# Move to exactly 5ft apart
game.state.set_player_position(game.player2, 5)   # Distance now 5ft
print(f"\nAt {game.state.distance}ft apart:")
print(f"Alice can attack Bob: {game.player1.can_reach_target(game.state.distance)}")
print(f"Bob can attack Alice: {game.player2.can_reach_target(game.state.distance)}")

# Test available actions with reach
print(f"\n=== Available Actions at {game.state.distance}ft ===")
alice_actions = game.get_available_actions(game.player1)
bob_actions = game.get_available_actions(game.player2)

print(f"Alice actions: {alice_actions}")
print(f"Bob actions: {bob_actions}")

# Test advance behavior with different reach
print(f"\n=== Testing Advance with Different Reach ===")
advance_action = game.action_registry.get_action("advance")

print(f"Alice can advance: {advance_action.can_execute(game.player1, game.player2, game.state)}")
print(f"Bob can advance: {advance_action.can_execute(game.player2, game.player1, game.state)}")

# Bob tries to advance (should work since he has shorter reach)
if advance_action.can_execute(game.player2, game.player1, game.state):
    result = advance_action.execute(game.player2, game.player1, game.state, 5)
    print(f"Bob advance result: {result['message']}")
else:
    print("Bob cannot advance (already within his reach)")

# Test what happens if Alice tries to advance (should fail if within her reach)
print(f"Alice can advance: {advance_action.can_execute(game.player1, game.player2, game.state)}")
if not advance_action.can_execute(game.player1, game.player2, game.state):
    result = advance_action.execute(game.player1, game.player2, game.state)
    print(f"Alice advance blocked: {result['message']}")

print("\n=== Reach System Testing Complete ===")