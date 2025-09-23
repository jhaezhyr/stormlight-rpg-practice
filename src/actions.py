from abc import ABC, abstractmethod
from typing import Dict, Any, List
import random

class Action(ABC):
    def __init__(self, name: str, focus_cost: int = 0, description: str = ""):
        self.name = name
        self.focus_cost = focus_cost
        self.description = description

    @abstractmethod
    def can_execute(self, actor, target, game_state) -> bool:
        pass

    @abstractmethod
    def execute(self, actor, target, game_state) -> Dict[str, Any]:
        pass

class Attack(Action):
    def __init__(self):
        super().__init__("Attack", 1, "Basic attack using Strength")

    def can_execute(self, actor, target, game_state) -> bool:
        return actor.current_focus >= self.focus_cost and game_state.distance <= 5

    def execute(self, actor, target, game_state) -> Dict[str, Any]:
        if not self.can_execute(actor, target, game_state):
            return {"success": False, "message": "Cannot execute attack"}

        actor.spend_focus(self.focus_cost)
        damage = actor.get_trait_bonus("Strength") + random.randint(1, 3)
        target.take_damage(damage)

        return {
            "success": True,
            "message": f"{actor.name} attacks {target.name} for {damage} damage!",
            "damage": damage
        }

class Move(Action):
    def __init__(self):
        super().__init__("Move", 0, "Move up to your speed toward or away from opponent")

    def can_execute(self, actor, target, game_state) -> bool:
        return True  # Can always attempt to move

    def execute(self, actor, target, game_state) -> Dict[str, Any]:
        print(f"Current distance: {game_state.distance}ft")
        print(f"Your movement rate: {actor.movement_rate}ft")
        print("Enter movement distance (negative to move closer, positive to move away):")

        try:
            move_input = input("Distance: ").strip()
            movement = int(move_input)
        except (ValueError, EOFError):
            return {"success": False, "message": "Invalid movement input"}

        # Validate movement doesn't exceed movement rate
        if abs(movement) > actor.movement_rate:
            return {"success": False, "message": f"Cannot move more than {actor.movement_rate}ft"}

        new_distance = game_state.distance + movement

        # Validate minimum distance of 0ft
        if new_distance < 0:
            new_distance = 0
            movement = -game_state.distance

        game_state.distance = new_distance

        if movement < 0:
            direction = "closer"
        elif movement > 0:
            direction = "away"
        else:
            direction = "in place"

        return {
            "success": True,
            "message": f"{actor.name} moves {abs(movement)}ft {direction} (distance now {game_state.distance}ft)",
            "distance_change": movement
        }

class Rest(Action):
    def __init__(self):
        super().__init__("Rest", 0, "Restore 1 focus point")

    def can_execute(self, actor, target, game_state) -> bool:
        return actor.current_focus < actor.max_focus

    def execute(self, actor, target, game_state) -> Dict[str, Any]:
        if not self.can_execute(actor, target, game_state):
            return {"success": False, "message": "Focus is already at maximum"}

        actor.restore_focus(1)
        return {
            "success": True,
            "message": f"{actor.name} rests and restores 1 focus",
            "focus_restored": 1
        }

class ActionRegistry:
    def __init__(self):
        self.actions = {
            "attack": Attack(),
            "move": Move(),
            "rest": Rest()
        }

    def get_action(self, action_name: str) -> Action:
        return self.actions.get(action_name.lower())

    def get_available_actions(self, actor, target, game_state) -> List[str]:
        available = []
        for name, action in self.actions.items():
            if action.can_execute(actor, target, game_state):
                available.append(name)
        return available

    def list_all_actions(self) -> Dict[str, str]:
        return {name: action.description for name, action in self.actions.items()}