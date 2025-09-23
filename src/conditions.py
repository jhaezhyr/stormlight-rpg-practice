from abc import ABC, abstractmethod
from typing import Dict, Any, List

class Condition(ABC):
    def __init__(self, name: str, duration: int = -1):
        self.name = name
        self.duration = duration

    @abstractmethod
    def apply_effect(self, character) -> Dict[str, Any]:
        pass

    def tick_duration(self) -> bool:
        if self.duration > 0:
            self.duration -= 1
        return self.duration == 0

    def is_permanent(self) -> bool:
        return self.duration == -1

class Stunned(Condition):
    def __init__(self, duration: int = 1):
        super().__init__("Stunned", duration)

    def apply_effect(self, character) -> Dict[str, Any]:
        return {"actions_reduced": 1}

class Bleeding(Condition):
    def __init__(self, duration: int = 3, damage_per_turn: int = 1):
        super().__init__("Bleeding", duration)
        self.damage_per_turn = damage_per_turn

    def apply_effect(self, character) -> Dict[str, Any]:
        character.take_damage(self.damage_per_turn)
        return {"damage_dealt": self.damage_per_turn}

class Focused(Condition):
    def __init__(self, duration: int = 2, trait_bonus: int = 1):
        super().__init__("Focused", duration)
        self.trait_bonus = trait_bonus

    def apply_effect(self, character) -> Dict[str, Any]:
        return {"trait_bonuses": {"all": self.trait_bonus}}

class ConditionManager:
    def __init__(self):
        self.conditions: Dict[str, Condition] = {}

    def add_condition(self, condition: Condition):
        self.conditions[condition.name] = condition

    def remove_condition(self, condition_name: str):
        if condition_name in self.conditions:
            del self.conditions[condition_name]

    def has_condition(self, condition_name: str) -> bool:
        return condition_name in self.conditions

    def get_condition(self, condition_name: str) -> Condition:
        return self.conditions.get(condition_name)

    def process_turn_effects(self, character) -> Dict[str, Any]:
        effects = {}
        conditions_to_remove = []

        for condition in self.conditions.values():
            effect = condition.apply_effect(character)
            effects[condition.name] = effect

            if condition.tick_duration():
                conditions_to_remove.append(condition.name)

        for condition_name in conditions_to_remove:
            self.remove_condition(condition_name)

        return effects

    def get_all_conditions(self) -> List[str]:
        return list(self.conditions.keys())