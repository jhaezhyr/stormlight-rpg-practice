from typing import Dict, List
from .utils import roll_stat, roll_traits, roll_speed

class Character:
    def __init__(self, name: str):
        self.name = name
        self.max_health = roll_stat(10, 15)
        self.current_health = self.max_health
        self.max_focus = roll_stat(3, 5)
        self.current_focus = self.max_focus
        self.speed = roll_speed()
        self.traits = roll_traits()
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

    def __str__(self) -> str:
        traits_str = ", ".join([f"{trait}: {value}" for trait, value in self.traits.items()])
        conditions_str = ", ".join(self.conditions) if self.conditions else "None"
        return (f"{self.name}\n"
                f"Health: {self.current_health}/{self.max_health}\n"
                f"Focus: {self.current_focus}/{self.max_focus}\n"
                f"Speed: {self.speed}ft\n"
                f"Traits: {traits_str}\n"
                f"Conditions: {conditions_str}")