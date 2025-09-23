#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.game import Game
from src.actions import Advance, Retreat, Disengage

def test_advance_action():
    """Test the Advance action"""
    print("Testing Advance action...")

    game = Game("Alice", "Bob")
    advance_action = Advance()

    # Initial positions: P1 at 0, P2 at 30
    assert game.state.distance == 30

    # Test that advance can be executed when not within 5ft
    assert advance_action.can_execute(game.player1, game.player2, game.state)

    # Test advance without distance (should use full movement rate)
    result = advance_action.execute(game.player1, game.player2, game.state)
    print(f"Advance result: {result['message']}")

    # Alice should move toward Bob (from 0 toward 30)
    expected_new_pos = min(30, game.player1.movement_rate)  # But stops at 5ft from Bob
    actual_new_pos = game.state.get_player_position(game.player1)
    print(f"Alice moved from 0 to {actual_new_pos} (distance now {game.state.distance}ft)")

    # Test advance with specific distance
    game = Game("TestA", "TestB")  # Reset
    result = advance_action.execute(game.player1, game.player2, game.state, 15)
    print(f"Advance 15ft result: {result['message']}")

    # Test that you can't advance when within 5ft
    game.state.set_player_position(game.player1, 25)  # Close to P2 at 30
    assert not advance_action.can_execute(game.player1, game.player2, game.state)

    result = advance_action.execute(game.player1, game.player2, game.state)
    assert not result["success"]
    print(f"Cannot advance when close: {result['message']}")

    print("✓ Advance action working correctly")

def test_retreat_action():
    """Test the Retreat action"""
    print("Testing Retreat action...")

    game = Game("Alice", "Bob")
    retreat_action = Retreat()

    # Test that retreat can always be executed
    assert retreat_action.can_execute(game.player1, game.player2, game.state)

    # Test retreat without distance (should use full movement rate)
    result = retreat_action.execute(game.player1, game.player2, game.state)
    print(f"Retreat result: {result['message']}")

    # Alice should move away from Bob (from 0 away from 30, so toward 0 but can't go below 0)
    actual_new_pos = game.state.get_player_position(game.player1)
    print(f"Alice position after retreat: {actual_new_pos} (distance now {game.state.distance}ft)")

    # Test retreat with specific distance from middle position
    game = Game("TestA", "TestB")  # Reset
    game.state.set_player_position(game.player1, 40)  # P1 at 40, P2 at 30
    result = retreat_action.execute(game.player1, game.player2, game.state, 10)
    print(f"Retreat 10ft result: {result['message']}")

    # Test retreat validation (5ft increments)
    result = retreat_action.execute(game.player1, game.player2, game.state, 7)
    assert not result["success"]
    print(f"Invalid increment rejected: {result['message']}")

    print("✓ Retreat action working correctly")

def test_disengage_action():
    """Test the Disengage action"""
    print("Testing Disengage action...")

    game = Game("Alice", "Bob")
    disengage_action = Disengage()

    # Test that disengage can always be executed
    assert disengage_action.can_execute(game.player1, game.player2, game.state)

    # Test disengage (should move exactly 5ft away)
    initial_pos = game.state.get_player_position(game.player1)
    result = disengage_action.execute(game.player1, game.player2, game.state)
    print(f"Disengage result: {result['message']}")

    # Should move exactly 5ft
    final_pos = game.state.get_player_position(game.player1)
    movement = abs(final_pos - initial_pos)
    assert movement == 5 or final_pos == 0  # Movement might be limited by bounds

    # Check that it indicates no reactive strike
    assert result.get("no_reactive_strike") is True

    # Test from different position
    game.state.set_player_position(game.player1, 35)  # P1 at 35, P2 at 30
    result = disengage_action.execute(game.player1, game.player2, game.state)
    print(f"Disengage from 35ft: {result['message']}")

    print("✓ Disengage action working correctly")

def test_movement_validation():
    """Test movement validation rules"""
    print("Testing movement validation...")

    game = Game("Alice", "Bob")
    advance_action = Advance()

    # Test 5ft increment validation
    result = advance_action.execute(game.player1, game.player2, game.state, 7)
    assert not result["success"]
    assert "5ft increments" in result["message"]

    # Test movement rate limit validation
    result = advance_action.execute(game.player1, game.player2, game.state, 50)
    assert not result["success"]
    assert "movement rate" in result["message"] or "Cannot move more than" in result["message"]

    print("✓ Movement validation working correctly")

def test_action_aliases():
    """Test that action aliases work"""
    print("Testing action aliases...")

    game = Game("Alice", "Bob")

    # Test short forms
    advance_action = game.action_registry.get_action("a")
    retreat_action = game.action_registry.get_action("t")
    disengage_action = game.action_registry.get_action("d")

    assert advance_action is not None
    assert retreat_action is not None
    assert disengage_action is not None

    # Test that they're the same as full names
    assert type(advance_action) == type(game.action_registry.get_action("advance"))
    assert type(retreat_action) == type(game.action_registry.get_action("retreat"))
    assert type(disengage_action) == type(game.action_registry.get_action("disengage"))

    print("✓ Action aliases working correctly")

def test_boundary_conditions():
    """Test movement at battlefield boundaries"""
    print("Testing boundary conditions...")

    game = Game("Alice", "Bob")
    retreat_action = Retreat()
    advance_action = Advance()

    # Test retreat at left boundary (position 0)
    # P1 is already at 0, P2 at 30
    result = retreat_action.execute(game.player1, game.player2, game.state, 10)
    assert game.state.get_player_position(game.player1) == 0  # Should stay at 0
    print(f"Retreat at boundary: {result['message']}")

    # Test advance at right boundary
    game.state.set_player_position(game.player1, 100)
    game.state.set_player_position(game.player2, 50)
    result = advance_action.execute(game.player1, game.player2, game.state, 10)
    # Should move toward P2 but within bounds
    final_pos = game.state.get_player_position(game.player1)
    print(f"Advance from boundary: moved to {final_pos}ft")

    print("✓ Boundary conditions working correctly")

def test_available_actions():
    """Test that new actions appear in available actions"""
    print("Testing available actions...")

    game = Game("Alice", "Bob")
    available = game.get_available_actions(game.player1)

    print(f"Available actions: {available}")

    # Should have advance (not within 5ft), retreat, disengage
    assert "advance" in available or "a" in available
    assert "retreat" in available or "t" in available
    assert "disengage" in available or "d" in available

    # Move closer and check that advance is no longer available
    game.state.set_player_position(game.player1, 27)  # Within 5ft of P2 at 30
    available_close = game.get_available_actions(game.player1)
    print(f"Available when close: {available_close}")

    # Advance should not be available when close
    assert "advance" not in available_close and "a" not in available_close

    print("✓ Available actions working correctly")

if __name__ == "__main__":
    print("Running advanced movement tests...")
    print("=" * 60)

    test_advance_action()
    print()

    test_retreat_action()
    print()

    test_disengage_action()
    print()

    test_movement_validation()
    print()

    test_action_aliases()
    print()

    test_boundary_conditions()
    print()

    test_available_actions()
    print()

    print("=" * 60)
    print("✓ All advanced movement tests passed!")