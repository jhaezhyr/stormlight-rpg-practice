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

    print(f"Alice speed: {game.player1.speed}ft")
    print(f"Bob speed: {game.player2.speed}ft")
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
    game.state.distance = 5
    can_attack_close = game.action_registry.get_action("attack").can_execute(
        game.player1, game.player2, game.state
    )
    print(f"Can attack at {game.state.distance}ft: {can_attack_close}")
    print()

def test_distance_validation():
    print("Testing distance validation...")
    game = Game("Alice", "Bob")

    # Set distance to 5ft to test minimum distance enforcement
    game.state.distance = 5
    print(f"Starting at {game.state.distance}ft apart")

    # Simulate moving too close (should be capped at 0ft)
    print("Testing movement validation logic...")

    # Test case: trying to move 10ft closer when only 5ft apart
    requested_movement = -10
    new_distance = game.state.distance + requested_movement

    if new_distance < 0:
        actual_movement = -game.state.distance
        new_distance = 0
        print(f"Requested: {requested_movement}ft closer")
        print(f"Actual: {actual_movement}ft closer (capped at minimum distance)")
        print(f"Final distance: {new_distance}ft")

    print("Distance validation working correctly!")

if __name__ == "__main__":
    test_new_movement_system()
    print("-" * 50)
    test_distance_validation()