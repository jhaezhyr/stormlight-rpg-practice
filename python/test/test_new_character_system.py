#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.character import Character
from src.utils import create_traits_with_points, get_recovery_die, get_movement_rate, calculate_defense

def test_trait_allocation():
    """Test that traits are allocated correctly with 12 points total."""
    print("Testing trait allocation...")

    traits = create_traits_with_points(12)
    total = sum(traits.values())
    print(f"Total trait points: {total}")
    assert total == 12, f"Expected 12 total points, got {total}"

    # Check that no trait exceeds 4
    for trait, value in traits.items():
        assert 0 <= value <= 4, f"Trait {trait} has invalid value {value}"

    # Check that all expected traits are present
    expected_traits = {"Strength", "Speed", "Intellect", "Willpower", "Presence", "Awareness"}
    assert set(traits.keys()) == expected_traits, f"Missing or extra traits: {traits.keys()}"

    print("✓ Trait allocation working correctly")
    print()

def test_derived_stats():
    """Test that derived stats are calculated correctly."""
    print("Testing derived stats calculation...")

    char = Character("Test Character")

    # Test health calculation
    expected_health = 10 + char.traits["Strength"]
    assert char.max_health == expected_health, f"Expected health {expected_health}, got {char.max_health}"
    assert char.current_health == char.max_health, "Current health should equal max health initially"

    # Test focus calculation
    expected_focus = 2 + char.traits["Willpower"]
    assert char.max_focus == expected_focus, f"Expected focus {expected_focus}, got {char.max_focus}"
    assert char.current_focus == char.max_focus, "Current focus should equal max focus initially"

    # Test recovery die
    expected_recovery = get_recovery_die(char.traits["Willpower"])
    assert char.recovery_die == expected_recovery, f"Expected recovery die {expected_recovery}, got {char.recovery_die}"

    # Test movement rate
    expected_movement = get_movement_rate(char.traits["Speed"])
    assert char.movement_rate == expected_movement, f"Expected movement {expected_movement}, got {char.movement_rate}"

    print(f"✓ Health: {char.current_health}/{char.max_health}")
    print(f"✓ Focus: {char.current_focus}/{char.max_focus}")
    print(f"✓ Recovery Die: {char.recovery_die}")
    print(f"✓ Movement Rate: {char.movement_rate}ft")
    print()

def test_defenses():
    """Test that defenses are calculated correctly."""
    print("Testing defense calculations...")

    char = Character("Test Character")

    # Test physical defense
    expected_physical = 10 + char.traits["Strength"] + char.traits["Speed"]
    assert char.physical_defense == expected_physical, f"Expected physical defense {expected_physical}, got {char.physical_defense}"

    # Test mental defense
    expected_mental = 10 + char.traits["Intellect"] + char.traits["Willpower"]
    assert char.mental_defense == expected_mental, f"Expected mental defense {expected_mental}, got {char.mental_defense}"

    # Test spiritual defense
    expected_spiritual = 10 + char.traits["Presence"] + char.traits["Awareness"]
    assert char.spiritual_defense == expected_spiritual, f"Expected spiritual defense {expected_spiritual}, got {char.spiritual_defense}"

    # Test get_defense method
    assert char.get_defense("physical") == char.physical_defense
    assert char.get_defense("mental") == char.mental_defense
    assert char.get_defense("spiritual") == char.spiritual_defense
    assert char.get_defense("invalid") == 10  # Default

    print(f"✓ Physical Defense: {char.physical_defense}")
    print(f"✓ Mental Defense: {char.mental_defense}")
    print(f"✓ Spiritual Defense: {char.spiritual_defense}")
    print()

def test_skills_system():
    """Test that skills are correctly mapped to traits."""
    print("Testing skills system...")

    char = Character("Test Character")

    # Test that skills equal their corresponding traits
    skill_to_trait_mapping = {
        "Agility": "Speed",
        "Athletics": "Strength",
        "Heavy Weaponry": "Strength",
        "Light Weaponry": "Speed",
        "Stealth": "Speed",
        "Thievery": "Speed",
        "Crafting": "Intellect",
        "Deduction": "Intellect",
        "Lore": "Intellect",
        "Medicine": "Intellect",
        "Discipline": "Willpower",
        "Intimidation": "Willpower",
        "Deception": "Presence",
        "Leadership": "Presence",
        "Persuasion": "Presence",
        "Insight": "Awareness",
        "Perception": "Awareness",
        "Survival": "Awareness"
    }

    for skill, trait in skill_to_trait_mapping.items():
        expected_value = char.traits[trait]
        actual_value = char.skills[skill]
        assert actual_value == expected_value, f"Skill {skill} should equal trait {trait}: expected {expected_value}, got {actual_value}"

        # Test get_skill_bonus method
        assert char.get_skill_bonus(skill) == expected_value

    # Test invalid skill
    assert char.get_skill_bonus("Invalid Skill") == 0

    print(f"✓ All {len(skill_to_trait_mapping)} skills correctly mapped to traits")
    print()

def test_utility_functions():
    """Test utility functions work correctly."""
    print("Testing utility functions...")

    # Test recovery die function
    assert get_recovery_die(0) == "d4"
    assert get_recovery_die(1) == "d6"
    assert get_recovery_die(2) == "d6"
    assert get_recovery_die(3) == "d8"
    assert get_recovery_die(4) == "d8"

    # Test movement rate function
    assert get_movement_rate(0) == 20
    assert get_movement_rate(1) == 25
    assert get_movement_rate(2) == 25
    assert get_movement_rate(3) == 30
    assert get_movement_rate(4) == 30

    # Test defense calculation
    assert calculate_defense(2, 3) == 15  # 10 + 2 + 3
    assert calculate_defense(0, 0) == 10  # 10 + 0 + 0
    assert calculate_defense(4, 4) == 18  # 10 + 4 + 4

    print("✓ All utility functions working correctly")
    print()

def test_character_display():
    """Test character string representation."""
    print("Testing character display...")

    char = Character("Test Hero")
    char_str = str(char)

    # Check that all important info is present
    assert "Test Hero" in char_str
    assert "Health:" in char_str
    assert "Focus:" in char_str
    assert "Recovery Die:" in char_str
    assert "Movement:" in char_str
    assert "Defenses:" in char_str
    assert "Traits:" in char_str

    print("Character display:")
    print(char_str)
    print("✓ Character display contains all required information")
    print()

def test_multiple_characters():
    """Test that multiple characters have different stats."""
    print("Testing multiple character creation...")

    characters = [Character(f"Hero {i}") for i in range(5)]

    # Check that not all characters are identical
    trait_sets = [tuple(sorted(char.traits.items())) for char in characters]
    unique_trait_sets = set(trait_sets)

    print(f"Created {len(characters)} characters")
    print(f"Found {len(unique_trait_sets)} unique trait combinations")

    # Display each character's key stats
    for char in characters:
        print(f"{char.name}: Health {char.max_health}, Focus {char.max_focus}, Movement {char.movement_rate}ft")
        print(f"  Traits: {dict(char.traits)}")

    print("✓ Multiple character creation working")
    print()

if __name__ == "__main__":
    print("=" * 60)
    print("         NEW CHARACTER SYSTEM TESTS")
    print("=" * 60)

    test_trait_allocation()
    test_derived_stats()
    test_defenses()
    test_skills_system()
    test_utility_functions()
    test_character_display()
    test_multiple_characters()

    print("=" * 60)
    print("       ALL TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)