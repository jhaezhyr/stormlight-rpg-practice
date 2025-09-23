from typing import Dict, List, Optional
from .utils import create_traits_with_points, get_recovery_die, get_movement_rate, calculate_defense
from .equipment import Weapon, Armor, EquipmentState, create_unarmed_attack

class Character:
    def __init__(self, name: str):
        self.name = name
        self.traits = create_traits_with_points(12)

        # Calculate derived stats
        self.max_health = 10 + self.traits["Strength"]
        self.current_health = self.max_health
        self.max_focus = 2 + self.traits["Willpower"]
        self.current_focus = self.max_focus
        self.recovery_die = get_recovery_die(self.traits["Willpower"])
        self.movement_rate = get_movement_rate(self.traits["Speed"])

        # Calculate defenses
        self.physical_defense = calculate_defense(self.traits["Strength"], self.traits["Speed"])
        self.mental_defense = calculate_defense(self.traits["Intellect"], self.traits["Willpower"])
        self.spiritual_defense = calculate_defense(self.traits["Presence"], self.traits["Awareness"])

        # Initialize skills (equal to corresponding trait)
        self.skills = {
            "Agility": self.traits["Speed"],
            "Athletics": self.traits["Strength"],
            "Heavy Weaponry": self.traits["Strength"],
            "Light Weaponry": self.traits["Speed"],
            "Stealth": self.traits["Speed"],
            "Thievery": self.traits["Speed"],
            "Crafting": self.traits["Intellect"],
            "Deduction": self.traits["Intellect"],
            "Lore": self.traits["Intellect"],
            "Medicine": self.traits["Intellect"],
            "Discipline": self.traits["Willpower"],
            "Intimidation": self.traits["Willpower"],
            "Deception": self.traits["Presence"],
            "Leadership": self.traits["Presence"],
            "Persuasion": self.traits["Presence"],
            "Insight": self.traits["Awareness"],
            "Perception": self.traits["Awareness"],
            "Survival": self.traits["Awareness"]
        }

        # Equipment and inventory
        self.mainhand_weapon: Optional[Weapon] = None
        self.offhand_weapon: Optional[Weapon] = None
        self.armor: Optional[Armor] = None
        self.carried_weapons: List[Weapon] = []
        self.carried_armor: List[Armor] = []
        self.dropped_items: List[Weapon | Armor] = []  # Items dropped in battle

        # Start with basic equipment - unarmed attack always available
        self.unarmed_attack = create_unarmed_attack(self.traits["Strength"])

        self.conditions: List[str] = []

    def is_alive(self) -> bool:
        return self.current_health > 0

    def take_damage(self, damage: int):
        self.current_health = max(0, self.current_health - damage)

    def spend_focus(self, cost: int) -> bool:
        if self.current_focus >= cost:
            self.current_focus -= cost
            return True
        return False

    def restore_focus(self, amount: int):
        self.current_focus = min(self.max_focus, self.current_focus + amount)

    def get_trait_bonus(self, trait_name: str) -> int:
        return self.traits.get(trait_name, 0)

    def add_condition(self, condition: str):
        if condition not in self.conditions:
            self.conditions.append(condition)

    def remove_condition(self, condition: str):
        if condition in self.conditions:
            self.conditions.remove(condition)

    def has_condition(self, condition: str) -> bool:
        return condition in self.conditions

    # Equipment management methods
    def equip_weapon(self, weapon: Weapon, hand: str = "main") -> bool:
        """Equip a weapon in main hand or offhand."""
        if hand == "main":
            if self.mainhand_weapon:
                self.unequip_weapon("main")
            self.mainhand_weapon = weapon
            weapon.state = EquipmentState.EQUIPPED
            if weapon in self.carried_weapons:
                self.carried_weapons.remove(weapon)
            return True
        elif hand == "offhand":
            if self.offhand_weapon:
                self.unequip_weapon("offhand")
            self.offhand_weapon = weapon
            weapon.state = EquipmentState.EQUIPPED
            if weapon in self.carried_weapons:
                self.carried_weapons.remove(weapon)
            return True
        return False

    def unequip_weapon(self, hand: str) -> Optional[Weapon]:
        """Unequip a weapon and move it to carried."""
        weapon = None
        if hand == "main" and self.mainhand_weapon:
            weapon = self.mainhand_weapon
            self.mainhand_weapon = None
        elif hand == "offhand" and self.offhand_weapon:
            weapon = self.offhand_weapon
            self.offhand_weapon = None

        if weapon:
            weapon.state = EquipmentState.CARRIED
            self.carried_weapons.append(weapon)
        return weapon

    def drop_weapon(self, hand: str) -> Optional[Weapon]:
        """Drop a weapon to the ground."""
        weapon = None
        if hand == "main" and self.mainhand_weapon:
            weapon = self.mainhand_weapon
            self.mainhand_weapon = None
        elif hand == "offhand" and self.offhand_weapon:
            weapon = self.offhand_weapon
            self.offhand_weapon = None

        if weapon:
            weapon.state = EquipmentState.DROPPED
            self.dropped_items.append(weapon)
        return weapon

    def equip_armor(self, armor: Armor) -> bool:
        """Equip armor."""
        if self.armor:
            self.unequip_armor()
        self.armor = armor
        armor.state = EquipmentState.EQUIPPED
        if armor in self.carried_armor:
            self.carried_armor.remove(armor)
        return True

    def unequip_armor(self) -> Optional[Armor]:
        """Unequip armor and move it to carried."""
        if self.armor:
            old_armor = self.armor
            self.armor = None
            old_armor.state = EquipmentState.CARRIED
            self.carried_armor.append(old_armor)
            return old_armor
        return None

    def get_total_deflect(self) -> int:
        """Get total deflect from equipped armor."""
        if self.armor:
            return self.armor.deflect
        return 0

    def get_equipped_weapons(self) -> List[Weapon]:
        """Get list of currently equipped weapons."""
        weapons = []
        if self.mainhand_weapon:
            weapons.append(self.mainhand_weapon)
        if self.offhand_weapon:
            weapons.append(self.offhand_weapon)
        return weapons

    def get_primary_weapon(self) -> Weapon:
        """Get primary weapon for attacks (mainhand, offhand, or unarmed)."""
        if self.mainhand_weapon:
            return self.mainhand_weapon
        elif self.offhand_weapon:
            return self.offhand_weapon
        else:
            return self.unarmed_attack

    def can_use_weapon(self, weapon: Weapon) -> tuple[bool, str]:
        """Check if character can use a weapon based on requirements."""
        # Check strength requirement for cumbersome weapons
        for trait in weapon.traits:
            if "Cumbersome" in trait and "[" in trait:
                required_strength = int(trait.split("[")[1].split("]")[0])
                if self.traits["Strength"] < required_strength:
                    return False, f"Requires {required_strength} Strength"

        return True, ""

    def get_skill_bonus(self, skill_name: str) -> int:
        """Get bonus for a specific skill."""
        return self.skills.get(skill_name, 0)

    def get_defense(self, defense_type: str) -> int:
        """Get defense value by type."""
        if defense_type.lower() == "physical":
            return self.physical_defense
        elif defense_type.lower() == "mental":
            return self.mental_defense
        elif defense_type.lower() == "spiritual":
            return self.spiritual_defense
        else:
            return 10  # Default defense

    def get_reach(self, hand: str = "main") -> int:
        """Get reach for attacks. Defaults to 5ft for unarmed, or weapon reach."""
        if hand == "main" and self.mainhand_weapon:
            return self.mainhand_weapon.reach
        elif hand == "offhand" and self.offhand_weapon:
            return self.offhand_weapon.reach
        else:
            return 5  # Unarmed reach is always 5ft

    def get_max_reach(self) -> int:
        """Get the maximum reach from all equipped weapons."""
        max_reach = 5  # Base unarmed reach
        if self.mainhand_weapon:
            max_reach = max(max_reach, self.mainhand_weapon.reach)
        if self.offhand_weapon:
            max_reach = max(max_reach, self.offhand_weapon.reach)
        return max_reach

    def can_reach_target(self, target_distance: int, hand: str = "main") -> bool:
        """Check if target is within reach for attacks."""
        return target_distance <= self.get_reach(hand)

    def __str__(self) -> str:
        traits_str = ", ".join([f"{trait}: {value}" for trait, value in self.traits.items()])
        conditions_str = ", ".join(self.conditions) if self.conditions else "None"

        # Equipment display
        mainhand_str = self.mainhand_weapon.name if self.mainhand_weapon else "None"
        offhand_str = self.offhand_weapon.name if self.offhand_weapon else "None"
        armor_str = f"{self.armor.name} (Deflect {self.armor.deflect})" if self.armor else "None"

        return (f"{self.name}\n"
                f"Health: {self.current_health}/{self.max_health}\n"
                f"Focus: {self.current_focus}/{self.max_focus}\n"
                f"Recovery Die: {self.recovery_die}\n"
                f"Movement: {self.movement_rate}ft\n"
                f"Defenses: Phys {self.physical_defense}, Mental {self.mental_defense}, Spirit {self.spiritual_defense}\n"
                f"Equipment: Main {mainhand_str}, Off {offhand_str}, Armor {armor_str}\n"
                f"Traits: {traits_str}\n"
                f"Conditions: {conditions_str}")