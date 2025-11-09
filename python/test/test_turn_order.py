#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.game import Game, TurnType

def test_turn_order():
    game = Game("Player 1", "Player 2")

    print("Testing turn order logic...")
    print()

    # Test case 1: Both choose fast
    print("Case 1: Both choose FAST")
    game.choose_turn_type(game.player1, TurnType.FAST)
    game.choose_turn_type(game.player2, TurnType.FAST)
    turn_order = game.determine_turn_order()
    print(f"Turn order: {[(player.name, actions) for player, actions in turn_order]}")
    print(f"Player 1 goes first: {turn_order[0][0].name == 'Player 1'}")
    print()

    # Test case 2: Both choose slow
    print("Case 2: Both choose SLOW")
    game.turn_choices.clear()
    game.choose_turn_type(game.player1, TurnType.SLOW)
    game.choose_turn_type(game.player2, TurnType.SLOW)
    turn_order = game.determine_turn_order()
    print(f"Turn order: {[(player.name, actions) for player, actions in turn_order]}")
    print(f"Player 1 goes first: {turn_order[0][0].name == 'Player 1'}")
    print()

    # Test case 3: P1 fast, P2 slow
    print("Case 3: Player 1 FAST, Player 2 SLOW")
    game.turn_choices.clear()
    game.choose_turn_type(game.player1, TurnType.FAST)
    game.choose_turn_type(game.player2, TurnType.SLOW)
    turn_order = game.determine_turn_order()
    print(f"Turn order: {[(player.name, actions) for player, actions in turn_order]}")
    print(f"Player 1 goes first: {turn_order[0][0].name == 'Player 1'}")
    print()

    # Test case 4: P1 slow, P2 fast
    print("Case 4: Player 1 SLOW, Player 2 FAST")
    game.turn_choices.clear()
    game.choose_turn_type(game.player1, TurnType.SLOW)
    game.choose_turn_type(game.player2, TurnType.FAST)
    turn_order = game.determine_turn_order()
    print(f"Turn order: {[(player.name, actions) for player, actions in turn_order]}")
    print(f"Player 2 goes first: {turn_order[0][0].name == 'Player 2'}")

if __name__ == "__main__":
    test_turn_order()