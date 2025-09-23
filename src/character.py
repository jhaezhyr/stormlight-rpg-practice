from typing import Dict, List
from .utils import create_traits_with_points, get_recovery_die, get_movement_rate, calculate_defense

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

    def __str__(self) -> str:
        traits_str = ", ".join([f"{trait}: {value}" for trait, value in self.traits.items()])
        conditions_str = ", ".join(self.conditions) if self.conditions else "None"
        return (f"{self.name}\n"
                f"Health: {self.current_health}/{self.max_health}\n"
                f"Focus: {self.current_focus}/{self.max_focus}\n"
                f"Recovery Die: {self.recovery_die}\n"
                f"Movement: {self.movement_rate}ft\n"
                f"Defenses: Phys {self.physical_defense}, Mental {self.mental_defense}, Spirit {self.spiritual_defense}\n"
                f"Traits: {traits_str}\n"
                f"Conditions: {conditions_str}")