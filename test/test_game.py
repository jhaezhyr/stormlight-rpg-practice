#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.game import Game, TurnType
from src.character import Character

def test_character_creation():
    print("Testing character creation...")
    char = Character("Test Hero")
    print(f"Created character: {char.name}")
    print(f"Health: {char.current_health}/{char.max_health}")
    print(f"Focus: {char.current_focus}/{char.max_focus}")
    print(f"Traits: {char.traits}")
    print()

def test_game_setup():
    print("Testing game setup...")
    game = Game("Alice", "Bob")
    print(f"Player 1: {game.player1.name}")
    print(f"Player 2: {game.player2.name}")
    print(f"Initial distance: {game.state.distance}")
    print()

def test_turn_system():
    print("Testing turn system...")
    game = Game("Alice", "Bob")

    game.choose_turn_type(game.player1, TurnType.FAST)
    game.choose_turn_type(game.player2, TurnType.SLOW)

    turn_order = game.determine_turn_order()
    print(f"Turn order: {[(player.name, actions) for player, actions in turn_order]}")
    print()

def test_actions():
    print("Testing actions...")
    game = Game("Alice", "Bob")

    available = game.get_available_actions(game.player1)
    print(f"Available actions for {game.player1.name}: {available}")

    # Test moving closer by directly changing distance
    print("Testing movement system by setting distance to 5ft")
    game.state.distance = 5
    print(f"Distance set to: {game.state.distance}ft")

    # Test attack (should work now that distance is 5ft)
    result = game.execute_action(game.player1, "attack")
    print(f"Attack result: {result}")
    print(f"Bob's health: {game.player2.current_health}/{game.player2.max_health}")
    print()

if __name__ == "__main__":
    test_character_creation()
    test_game_setup()
    test_turn_system()
    test_actions()