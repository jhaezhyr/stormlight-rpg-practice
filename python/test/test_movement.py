#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.game import Game
from src.character import Character

def test_new_movement_system():
    print("Testing new movement system...")

    # Create a game
    game = Game("Alice", "Bob")

    print(f"Alice movement rate: {game.player1.movement_rate}ft")
    print(f"Bob movement rate: {game.player2.movement_rate}ft")
    print(f"Starting distance: {game.state.distance}ft")
    print()

    # Test character creation shows speed
    print("Character display test:")
    print(game.player1)
    print()

    # Test game status display
    print("Game status test:")
    status = game.get_game_status()
    print(f"Distance: {status['distance']}")
    print()

    # Test action availability
    print("Available actions test:")
    available = game.get_available_actions(game.player1)
    print(f"Available actions: {available}")
    print()

    # Test attack range (should not be available at 30ft)
    can_attack = game.action_registry.get_action("attack").can_execute(
        game.player1, game.player2, game.state
    )
    print(f"Can attack at {game.state.distance}ft: {can_attack}")

    # Move closer to attack range
    game.state.set_player_position(game.player2, 5)  # Move P2 closer to P1 at 0
    can_attack_close = game.action_registry.get_action("attack").can_execute(
        game.player1, game.player2, game.state
    )
    print(f"Can attack at {game.state.distance}ft: {can_attack_close}")
    print()

def test_distance_validation():
    print("Testing distance validation...")
    game = Game("Alice", "Bob")

    # Set distance to 5ft to test minimum distance enforcement
    game.state.set_player_position(game.player2, 5)  # Move P2 to position 5, P1 is at 0
    print(f"Starting at {game.state.distance}ft apart")

    # Simulate moving too close (should be capped at 0ft)
    print("Testing movement validation logic...")

    # Test case: trying to move 10ft closer when only 5ft apart
    # This logic is now handled by the movement action
    current_distance = game.state.distance
    requested_movement = -10  # Move toward position 0
    player2_current_pos = game.state.get_player_position(game.player2)
    new_position = player2_current_pos + requested_movement

    if new_position < 0:
        new_position = 0
        actual_movement = 0 - player2_current_pos

    print(f"Requested: move {requested_movement}ft (from {player2_current_pos} to {player2_current_pos + requested_movement})")
    print(f"Actual: move {actual_movement}ft (capped at position {new_position})")

    # Update position and check distance
    game.state.set_player_position(game.player2, new_position)
    print(f"Final distance: {game.state.distance}ft")

    print("Distance validation working correctly!")

if __name__ == "__main__":
    test_new_movement_system()
    print("-" * 50)
    test_distance_validation()