#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.character import Character
from src.equipment import (
    Weapon, Armor, EquipmentState, DamageType, WeaponType,
    create_weapon, create_armor, create_unarmed_attack,
    WEAPONS_DATA, ARMOR_DATA
)

def test_weapon_creation():
    """Test weapon creation and basic properties."""
    print("Testing weapon creation...")

    # Test basic weapon creation
    sword = Weapon("Test Sword", "1d8", DamageType.KEEN, WeaponType.MELEE, "Light Weaponry")
    assert sword.name == "Test Sword"
    assert sword.damage_die == "1d8"
    assert sword.damage_type == DamageType.KEEN
    assert sword.skill == "Light Weaponry"
    assert sword.reach == 5  # Default reach
    assert sword.state == EquipmentState.CARRIED

    # Test weapon with traits
    spear = Weapon("Spear", "1d8", DamageType.KEEN, WeaponType.MELEE, "Heavy Weaponry",
                   traits=["Two-Handed"], reach=10)
    assert spear.has_trait("Two-Handed")
    assert spear.is_two_handed()
    assert spear.reach == 10

    print("✓ Basic weapon creation working")

def test_predefined_weapons():
    """Test creation of predefined weapons."""
    print("Testing predefined weapons...")

    # Test a few key weapons
    longsword = create_weapon("Longsword")
    assert longsword is not None
    assert longsword.damage_die == "1d8"
    assert longsword.skill == "Heavy Weaponry"
    assert longsword.has_trait("Two-Handed")

    shortbow = create_weapon("Shortbow")
    assert shortbow is not None
    assert shortbow.is_ranged()
    assert shortbow.short_range == 80
    assert shortbow.long_range == 320

    # Test invalid weapon
    invalid = create_weapon("Invalid Weapon")
    assert invalid is None

    print(f"✓ Created predefined weapons: {len(WEAPONS_DATA)} types available")

def test_armor_creation():
    """Test armor creation and properties."""
    print("Testing armor creation...")

    # Test basic armor
    leather = create_armor("Leather")
    assert leather is not None
    assert leather.deflect == 1
    assert leather.state == EquipmentState.EQUIPPED  # Armor starts equipped

    # Test cumbersome armor
    full_plate = create_armor("Full Plate")
    assert full_plate.is_cumbersome()
    assert full_plate.get_cumbersome_requirement() == 5

    print(f"✓ Created armor types: {len(ARMOR_DATA)} types available")

def test_equipment_states():
    """Test equipment state management."""
    print("Testing equipment states...")

    sword = create_weapon("Longsword")

    # Test initial state
    assert sword.state == EquipmentState.CARRIED

    # Test state changes
    sword.state = EquipmentState.EQUIPPED
    assert sword.state == EquipmentState.EQUIPPED

    sword.state = EquipmentState.DROPPED
    assert sword.state == EquipmentState.DROPPED

    print("✓ Equipment state management working")

def test_damage_rolling():
    """Test weapon damage rolling."""
    print("Testing damage rolling...")

    # Test fixed damage (unarmed for low strength)
    unarmed_weak = create_unarmed_attack(0)  # Strength 0-2 = fixed 1 damage
    for _ in range(10):
        damage = unarmed_weak.roll_damage()
        assert damage == 1, f"Expected fixed damage 1, got {damage}"

    # Test die damage
    sword = create_weapon("Longsword")  # 1d8 damage
    damages = [sword.roll_damage() for _ in range(20)]
    assert all(1 <= d <= 8 for d in damages), f"Damage out of range: {damages}"

    # Test advantage/disadvantage
    advantage_damage = sword.roll_damage(advantage=True)
    disadvantage_damage = sword.roll_damage(disadvantage=True)
    assert 1 <= advantage_damage <= 8
    assert 1 <= disadvantage_damage <= 8

    print("✓ Damage rolling working correctly")

def test_character_equipment_integration():
    """Test character equipment management."""
    print("Testing character equipment integration...")

    char = Character("Test Fighter")

    # Test initial state - should have unarmed attack
    assert char.unarmed_attack is not None
    assert char.get_primary_weapon() == char.unarmed_attack

    # Test equipping weapons
    sword = create_weapon("Longsword")
    shield = create_weapon("Shield")

    # Equip mainhand weapon
    assert char.equip_weapon(sword, "main")
    assert char.mainhand_weapon == sword
    assert sword.state == EquipmentState.EQUIPPED
    assert char.get_primary_weapon() == sword

    # Equip offhand weapon
    assert char.equip_weapon(shield, "offhand")
    assert char.offhand_weapon == shield

    # Test equipped weapons list
    equipped = char.get_equipped_weapons()
    assert len(equipped) == 2
    assert sword in equipped
    assert shield in equipped

    print("✓ Character can equip weapons")

def test_armor_integration():
    """Test character armor management."""
    print("Testing armor integration...")

    char = Character("Test Fighter")

    # Test initial state - no armor
    assert char.armor is None
    assert char.get_total_deflect() == 0

    # Equip armor
    leather = create_armor("Leather")
    assert char.equip_armor(leather)
    assert char.armor == leather
    assert char.get_total_deflect() == 1

    # Change armor
    chain = create_armor("Chain")
    assert char.equip_armor(chain)
    assert char.armor == chain
    assert char.get_total_deflect() == 2
    assert leather in char.carried_armor  # Old armor moved to carried

    print("✓ Character armor management working")

def test_weapon_requirements():
    """Test weapon strength requirements."""
    print("Testing weapon requirements...")

    # Create character with low strength
    weak_char = Character("Weak Fighter")
    # Force low strength for testing
    weak_char.traits["Strength"] = 1

    # Test weapon they can use
    knife = create_weapon("Knife")
    can_use, reason = weak_char.can_use_weapon(knife)
    assert can_use, f"Should be able to use knife: {reason}"

    # Create a cumbersome weapon for testing
    heavy_weapon = Weapon("Heavy Sword", "2d6", DamageType.KEEN, WeaponType.MELEE,
                         "Heavy Weaponry", traits=["Cumbersome [4]"])

    can_use, reason = weak_char.can_use_weapon(heavy_weapon)
    assert not can_use, "Should not be able to use cumbersome weapon"
    assert "Strength" in reason

    print("✓ Weapon strength requirements working")

def test_drop_and_pickup():
    """Test dropping and picking up items."""
    print("Testing drop and pickup mechanics...")

    char = Character("Test Fighter")
    sword = create_weapon("Longsword")

    # Equip then drop weapon
    char.equip_weapon(sword, "main")
    dropped = char.drop_weapon("main")

    assert dropped == sword
    assert char.mainhand_weapon is None
    assert sword.state == EquipmentState.DROPPED
    assert sword in char.dropped_items

    print("✓ Drop and pickup mechanics working")

def test_character_display_with_equipment():
    """Test character string representation includes equipment."""
    print("Testing character display with equipment...")

    char = Character("Test Knight")
    sword = create_weapon("Longsword")
    shield = create_weapon("Shield")
    armor = create_armor("Chain")

    char.equip_weapon(sword, "main")
    char.equip_weapon(shield, "offhand")
    char.equip_armor(armor)

    char_str = str(char)

    # Check that equipment is shown
    assert "Equipment:" in char_str
    assert "Longsword" in char_str
    assert "Shield" in char_str
    assert "Chain" in char_str
    assert "Deflect 2" in char_str

    print("Character display with equipment:")
    print(char_str)
    print("✓ Character display includes equipment")

def test_thrown_weapons():
    """Test thrown weapon mechanics."""
    print("Testing thrown weapons...")

    javelin = create_weapon("Javelin")
    assert javelin.can_throw()

    short_range, long_range = javelin.get_thrown_range()
    assert short_range == 30
    assert long_range == 120

    # Test weapon without thrown trait
    sword = create_weapon("Longsword")
    assert not sword.can_throw()
    short, long = sword.get_thrown_range()
    assert short == 0 and long == 0

    print("✓ Thrown weapon mechanics working")

if __name__ == "__main__":
    print("=" * 60)
    print("         EQUIPMENT SYSTEM TESTS")
    print("=" * 60)

    test_weapon_creation()
    test_predefined_weapons()
    test_armor_creation()
    test_equipment_states()
    test_damage_rolling()
    test_character_equipment_integration()
    test_armor_integration()
    test_weapon_requirements()
    test_drop_and_pickup()
    test_character_display_with_equipment()
    test_thrown_weapons()

    print()
    print("=" * 60)
    print("    ALL EQUIPMENT TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)