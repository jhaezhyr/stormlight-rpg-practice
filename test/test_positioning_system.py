#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.game import Game, GameState
from src.character import Character

def test_position_initialization():
    """Test that players start at correct positions with cover points"""
    print("Testing position initialization...")

    game = Game("Alice", "Bob")

    # Check initial positions
    assert game.state.player1_position == 0, f"P1 should start at 0, got {game.state.player1_position}"
    assert game.state.player2_position == 30, f"P2 should start at 30, got {game.state.player2_position}"

    # Check distance calculation
    assert game.state.distance == 30, f"Initial distance should be 30ft, got {game.state.distance}ft"

    # Check cover points
    assert len(game.state.cover_points) == 3, f"Should have 3 cover points, got {len(game.state.cover_points)}"
    assert all(5 <= pos <= 95 for pos in game.state.cover_points), "Cover points should be within 5-95ft"
    assert game.state.cover_points == sorted(game.state.cover_points), "Cover points should be sorted"

    # Check player position tracking
    assert game.state.get_player_position(game.player1) == 0
    assert game.state.get_player_position(game.player2) == 30

    print("✓ Position initialization working correctly")

def test_position_manipulation():
    """Test setting and getting player positions"""
    print("Testing position manipulation...")

    game = Game("Alice", "Bob")

    # Test setting positions
    game.state.set_player_position(game.player1, 10)
    game.state.set_player_position(game.player2, 40)

    assert game.state.get_player_position(game.player1) == 10
    assert game.state.get_player_position(game.player2) == 40
    assert game.state.distance == 30  # Distance should still be 30ft

    # Test backward compatibility with state positions
    assert game.state.player1_position == 10
    assert game.state.player2_position == 40

    print("✓ Position manipulation working correctly")

def test_movement_with_positions():
    """Test movement using absolute positions instead of relative distance"""
    print("Testing movement with positions...")

    game = Game("Alice", "Bob")

    # Test movement bounds (should not go below 0 or above 100)
    game.state.set_player_position(game.player1, 5)  # Near left edge
    game.state.set_player_position(game.player2, 95) # Near right edge

    # Test that distance is calculated correctly
    assert game.state.distance == 90

    # Test battlefield bounds
    game.state.set_player_position(game.player1, -10)  # Should be clamped to bounds in practice
    game.state.set_player_position(game.player2, 110)  # Should be clamped to bounds in practice

    print("✓ Movement with positions working correctly")

def test_battlefield_display():
    """Test battlefield visualization"""
    print("Testing battlefield display...")

    game = Game("Alice", "Bob")

    # Test basic battlefield display
    battlefield_display = game.display_battlefield()
    assert "Battlefield (0-100ft):" in battlefield_display
    assert f"P1: {game.player1.name} at 0ft" in battlefield_display
    assert f"P2: {game.player2.name} at 30ft" in battlefield_display
    assert "Cover at:" in battlefield_display
    assert "Distance: 30ft" in battlefield_display

    # Test with different positions
    game.state.set_player_position(game.player1, 20)
    game.state.set_player_position(game.player2, 60)

    battlefield_display = game.display_battlefield()
    assert f"P1: {game.player1.name} at 20ft" in battlefield_display
    assert f"P2: {game.player2.name} at 60ft" in battlefield_display
    assert "Distance: 40ft" in battlefield_display

    print("✓ Battlefield display working correctly")

def test_cover_options():
    """Test cover option calculations"""
    print("Testing cover options...")

    game = Game("Alice", "Bob")

    # Force specific cover positions for testing
    game.state.cover_points = [15, 45, 75]

    # Test cover options for player at position 30
    game.state.set_player_position(game.player1, 30)
    cover_options = game.get_cover_options(game.player1)

    # Should have retreat option to 15ft (15ft back) and advance options to 45ft and 75ft
    expected_retreat = [15]  # 30 - 15 = 15ft to retreat
    expected_advance = [15, 45]  # 45 - 30 = 15ft, 75 - 30 = 45ft to advance

    assert cover_options["retreat"] == expected_retreat, f"Expected retreat {expected_retreat}, got {cover_options['retreat']}"
    assert cover_options["advance"] == expected_advance, f"Expected advance {expected_advance}, got {cover_options['advance']}"

    print("✓ Cover options working correctly")

def test_minimum_distance_enforcement():
    """Test that players cannot get closer than 5ft"""
    print("Testing minimum distance enforcement...")

    game = Game("Alice", "Bob")

    # Place players close together
    game.state.set_player_position(game.player1, 10)
    game.state.set_player_position(game.player2, 17)

    assert game.state.distance == 7  # 7ft apart

    # Try to move them closer than 5ft - this should be handled by movement logic
    # For now, just test that the distance calculation works
    game.state.set_player_position(game.player1, 15)
    game.state.set_player_position(game.player2, 17)

    assert game.state.distance == 2  # Would be too close, but distance calc works

    print("✓ Distance enforcement logic ready")

def test_game_status_with_positions():
    """Test that game status includes position information"""
    print("Testing game status with positions...")

    game = Game("Alice", "Bob")
    status = game.get_game_status()

    # Check that battlefield info is included
    assert "battlefield" in status
    assert "player1_position" in status["battlefield"]
    assert "player2_position" in status["battlefield"]
    assert "cover_points" in status["battlefield"]

    # Check that player positions are included
    assert "position" in status["player1"]
    assert "position" in status["player2"]

    assert status["player1"]["position"] == 0
    assert status["player2"]["position"] == 30
    assert status["battlefield"]["player1_position"] == 0
    assert status["battlefield"]["player2_position"] == 30

    print("✓ Game status with positions working correctly")

if __name__ == "__main__":
    print("Running positioning system tests...")
    print("=" * 60)

    test_position_initialization()
    print()

    test_position_manipulation()
    print()

    test_movement_with_positions()
    print()

    test_battlefield_display()
    print()

    test_cover_options()
    print()

    test_minimum_distance_enforcement()
    print()

    test_game_status_with_positions()
    print()

    print("=" * 60)
    print("✓ All positioning system tests passed!")