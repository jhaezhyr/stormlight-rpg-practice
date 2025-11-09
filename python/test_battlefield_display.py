#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

from src.game import Game

# Test the new battlefield display
game = Game("Alice", "Bob")

print("=== Initial Battlefield State ===")
print(game.display_battlefield())
print()

print("=== Cover Options for Alice ===")
cover_options = game.get_cover_options(game.player1)
print(f"Advance options: {cover_options['advance']}ft")
print(f"Retreat options: {cover_options['retreat']}ft")
print()

print("=== Cover Options for Bob ===")
cover_options = game.get_cover_options(game.player2)
print(f"Advance options: {cover_options['advance']}ft")
print(f"Retreat options: {cover_options['retreat']}ft")
print()

# Move players around and show the updated battlefield
game.state.set_player_position(game.player1, 25)
game.state.set_player_position(game.player2, 75)

print("=== After Moving Players ===")
print(game.display_battlefield())
print()

print("=== Game Status with Positions ===")
status = game.get_game_status()
print(f"Turn: {status['turn']}")
print(f"Distance: {status['distance']}")
print(f"Battlefield: {status['battlefield']}")
print(f"Player 1: {status['player1']['name']} at {status['player1']['position']}ft")
print(f"Player 2: {status['player2']['name']} at {status['player2']['position']}ft")