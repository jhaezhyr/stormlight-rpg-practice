from enum import Enum
from typing import List, Optional, Dict, Any
import random

class EquipmentState(Enum):
    CARRIED = "carried"
    EQUIPPED = "equipped"
    DROPPED = "dropped"

class DamageType(Enum):
    KEEN = "keen"
    IMPACT = "impact"
    SPIRIT = "spirit"

class WeaponType(Enum):
    MELEE = "melee"
    RANGED = "ranged"

class Weapon:
    def __init__(self, name: str, damage_die: str, damage_type: DamageType,
                 weapon_type: WeaponType, skill: str, traits: List[str] = None,
                 reach: int = 5, short_range: int = 0, long_range: int = 0):
        self.name = name
        self.damage_die = damage_die  # e.g., "1d6", "1d8", "2d4"
        self.damage_type = damage_type
        self.weapon_type = weapon_type
        self.skill = skill  # Which skill is used to attack with this weapon
        self.traits = traits or []
        self.reach = reach  # For melee weapons
        self.short_range = short_range  # For ranged weapons
        self.long_range = long_range  # For ranged weapons
        self.state = EquipmentState.CARRIED

    def has_trait(self, trait: str) -> bool:
        return trait.lower() in [t.lower() for t in self.traits]

    def is_two_handed(self) -> bool:
        return self.has_trait("Two-Handed")

    def is_ranged(self) -> bool:
        return self.weapon_type == WeaponType.RANGED

    def can_throw(self) -> bool:
        return any("Thrown" in trait for trait in self.traits)

    def get_thrown_range(self) -> tuple[int, int]:
        """Get thrown range if weapon has Thrown trait."""
        for trait in self.traits:
            if "Thrown" in trait and "[" in trait:
                # Extract range from "Thrown [30/120]" format
                range_part = trait.split("[")[1].split("]")[0]
                short, long = map(int, range_part.split("/"))
                return short, long
        return 0, 0

    def roll_damage(self, advantage: bool = False, disadvantage: bool = False) -> int:
        """Roll damage for this weapon."""
        if "d" not in self.damage_die:
            # Fixed damage like "1" for low strength unarmed
            return int(self.damage_die)

        # Parse damage die (e.g., "1d6", "2d8")
        if self.damage_die.startswith("d"):
            num_dice = 1
            die_size = int(self.damage_die[1:])
        else:
            parts = self.damage_die.split("d")
            num_dice = int(parts[0])
            die_size = int(parts[1])

        rolls = []
        for _ in range(num_dice):
            if advantage or disadvantage:
                roll1 = random.randint(1, die_size)
                roll2 = random.randint(1, die_size)
                if advantage:
                    rolls.append(max(roll1, roll2))
                else:  # disadvantage
                    rolls.append(min(roll1, roll2))
            else:
                rolls.append(random.randint(1, die_size))

        return sum(rolls)

    def __str__(self) -> str:
        traits_str = ", ".join(self.traits) if self.traits else "None"
        if self.is_ranged():
            range_str = f"Range [{self.short_range}/{self.long_range}]"
        else:
            range_str = f"Reach {self.reach}ft"

        return (f"{self.name} ({self.damage_die} {self.damage_type.value})\n"
                f"  {range_str}, Skill: {self.skill}\n"
                f"  Traits: {traits_str}\n"
                f"  State: {self.state.value}")

class Armor:
    def __init__(self, name: str, deflect: int, traits: List[str] = None):
        self.name = name
        self.deflect = deflect
        self.traits = traits or []
        self.state = EquipmentState.EQUIPPED  # Armor starts equipped

    def has_trait(self, trait: str) -> bool:
        return trait.lower() in [t.lower() for t in self.traits]

    def is_cumbersome(self) -> bool:
        return any("Cumbersome" in trait for trait in self.traits)

    def get_cumbersome_requirement(self) -> int:
        """Get strength requirement for cumbersome armor."""
        for trait in self.traits:
            if "Cumbersome" in trait and "[" in trait:
                # Extract number from "Cumbersome [3]" format
                return int(trait.split("[")[1].split("]")[0])
        return 0

    def __str__(self) -> str:
        traits_str = ", ".join(self.traits) if self.traits else "None"
        return (f"{self.name} (Deflect {self.deflect})\n"
                f"  Traits: {traits_str}\n"
                f"  State: {self.state.value}")

# Pre-defined weapons from the spec
WEAPONS_DATA = {
    # Light Weaponry
    "Javelin": {"damage_die": "1d6", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
                "skill": "Light Weaponry", "traits": ["Thrown [30/120]"]},
    "Knife": {"damage_die": "1d4", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
              "skill": "Light Weaponry", "traits": ["Discreet"]},
    "Mace": {"damage_die": "1d6", "damage_type": DamageType.IMPACT, "weapon_type": WeaponType.MELEE,
             "skill": "Light Weaponry", "traits": []},
    "Rapier": {"damage_die": "1d6", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
               "skill": "Light Weaponry", "traits": ["Quickdraw"]},
    "Shortspear": {"damage_die": "1d8", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
                   "skill": "Light Weaponry", "traits": ["Two-Handed"]},
    "Sidesword": {"damage_die": "1d6", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
                  "skill": "Light Weaponry", "traits": ["Quickdraw"]},
    "Staff": {"damage_die": "1d6", "damage_type": DamageType.IMPACT, "weapon_type": WeaponType.MELEE,
              "skill": "Light Weaponry", "traits": ["Discreet", "Two-Handed"]},
    "Shortbow": {"damage_die": "1d6", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.RANGED,
                 "skill": "Light Weaponry", "traits": ["Two-Handed"], "short_range": 80, "long_range": 320},
    "Sling": {"damage_die": "1d4", "damage_type": DamageType.IMPACT, "weapon_type": WeaponType.RANGED,
              "skill": "Light Weaponry", "traits": ["Discreet"], "short_range": 30, "long_range": 120},

    # Heavy Weaponry
    "Axe": {"damage_die": "1d6", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
            "skill": "Heavy Weaponry", "traits": ["Thrown [20/60]"]},
    "Greatsword": {"damage_die": "1d10", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
                   "skill": "Heavy Weaponry", "traits": ["Two-Handed"]},
    "Hammer": {"damage_die": "1d10", "damage_type": DamageType.IMPACT, "weapon_type": WeaponType.MELEE,
               "skill": "Heavy Weaponry", "traits": ["Two-Handed"]},
    "Longspear": {"damage_die": "1d8", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
                  "skill": "Heavy Weaponry", "traits": ["Two-Handed"], "reach": 10},
    "Longsword": {"damage_die": "1d8", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
                  "skill": "Heavy Weaponry", "traits": ["Quickdraw", "Two-Handed"]},
    "Poleaxe": {"damage_die": "1d10", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.MELEE,
                "skill": "Heavy Weaponry", "traits": ["Two-Handed"]},
    "Shield": {"damage_die": "1d4", "damage_type": DamageType.IMPACT, "weapon_type": WeaponType.MELEE,
               "skill": "Heavy Weaponry", "traits": ["Defensive"]},
    "Crossbow": {"damage_die": "1d8", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.RANGED,
                 "skill": "Heavy Weaponry", "traits": ["Loaded [1]", "Two-Handed"],
                 "short_range": 100, "long_range": 400},
    "Longbow": {"damage_die": "1d6", "damage_type": DamageType.KEEN, "weapon_type": WeaponType.RANGED,
                "skill": "Heavy Weaponry", "traits": ["Two-Handed"], "short_range": 150, "long_range": 600}
}

ARMOR_DATA = {
    "Uniform": {"deflect": 0, "traits": ["Presentable"]},
    "Leather": {"deflect": 1, "traits": []},
    "Chain": {"deflect": 2, "traits": ["Cumbersome [3]"]},
    "Breastplate": {"deflect": 2, "traits": ["Cumbersome [3]"]},
    "Half Plate": {"deflect": 3, "traits": ["Cumbersome [4]"]},
    "Full Plate": {"deflect": 4, "traits": ["Cumbersome [5]"]}
}

def create_weapon(weapon_name: str) -> Optional[Weapon]:
    """Create a weapon from the predefined weapons data."""
    if weapon_name not in WEAPONS_DATA:
        return None

    data = WEAPONS_DATA[weapon_name]
    return Weapon(
        name=weapon_name,
        damage_die=data["damage_die"],
        damage_type=data["damage_type"],
        weapon_type=data["weapon_type"],
        skill=data["skill"],
        traits=data["traits"],
        reach=data.get("reach", 5),
        short_range=data.get("short_range", 0),
        long_range=data.get("long_range", 0)
    )

def create_armor(armor_name: str) -> Optional[Armor]:
    """Create armor from the predefined armor data."""
    if armor_name not in ARMOR_DATA:
        return None

    data = ARMOR_DATA[armor_name]
    return Armor(
        name=armor_name,
        deflect=data["deflect"],
        traits=data["traits"]
    )

def create_unarmed_attack(strength: int) -> Weapon:
    """Create an unarmed attack weapon based on strength."""
    if strength <= 2:
        damage_die = "1"  # Fixed 1 damage
    else:
        damage_die = "1d4"

    return Weapon(
        name="Unarmed Attack",
        damage_die=damage_die,
        damage_type=DamageType.IMPACT,
        weapon_type=WeaponType.MELEE,
        skill="Athletics",
        traits=["Unique"],
        reach=5
    )