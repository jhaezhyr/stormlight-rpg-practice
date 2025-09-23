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
        return actor.current_focus >= self.focus_cost and actor.can_reach_target(game_state.distance)

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

class Advance(Action):
    def __init__(self):
        super().__init__("Advance", 0, "Move toward the opponent")

    def can_execute(self, actor, target, game_state) -> bool:
        current_distance = game_state.distance
        return current_distance > 5  # Cannot advance if already within 5ft (per spec)

    def execute(self, actor, target, game_state, distance: int = None) -> Dict[str, Any]:
        if not self.can_execute(actor, target, game_state):
            return {"success": False, "message": "Cannot advance - already within 5ft of opponent"}

        actor_position = game_state.get_player_position(actor)
        target_position = game_state.get_player_position(target)

        # If no distance specified, move full speed toward opponent
        if distance is None:
            distance = actor.movement_rate

        # Validate distance is in 5ft increments
        if distance % 5 != 0:
            return {"success": False, "message": "Movement must be in 5ft increments"}

        # Validate distance doesn't exceed movement rate
        if distance > actor.movement_rate:
            return {"success": False, "message": f"Cannot move more than {actor.movement_rate}ft"}

        # Determine direction toward opponent
        if target_position > actor_position:
            new_position = actor_position + distance
        else:
            new_position = actor_position - distance

        # Validate position bounds
        new_position = max(0, min(100, new_position))

        # Ensure we don't get closer than 5ft (per spec, advance stops at 5ft regardless of reach)
        new_distance = abs(target_position - new_position)
        if new_distance < 5:
            if new_position < target_position:
                new_position = target_position - 5
            else:
                new_position = target_position + 5
            new_position = max(0, min(100, new_position))

        actual_movement = abs(new_position - actor_position)
        game_state.set_player_position(actor, new_position)
        final_distance = abs(target_position - new_position)

        return {
            "success": True,
            "message": f"{actor.name} advances {actual_movement}ft toward opponent (distance now {final_distance}ft)",
            "distance_moved": actual_movement,
            "new_position": new_position
        }

class Retreat(Action):
    def __init__(self):
        super().__init__("Retreat", 0, "Move away from the opponent")

    def can_execute(self, actor, target, game_state) -> bool:
        return True  # Can always attempt to retreat

    def execute(self, actor, target, game_state, distance: int = None) -> Dict[str, Any]:
        actor_position = game_state.get_player_position(actor)
        target_position = game_state.get_player_position(target)

        # If no distance specified, move full speed away from opponent
        if distance is None:
            distance = actor.movement_rate

        # Validate distance is in 5ft increments
        if distance % 5 != 0:
            return {"success": False, "message": "Movement must be in 5ft increments"}

        # Validate distance doesn't exceed movement rate
        if distance > actor.movement_rate:
            return {"success": False, "message": f"Cannot move more than {actor.movement_rate}ft"}

        # Determine direction away from opponent
        if target_position > actor_position:
            new_position = actor_position - distance
        else:
            new_position = actor_position + distance

        # Validate position bounds
        new_position = max(0, min(100, new_position))
        actual_movement = abs(new_position - actor_position)

        game_state.set_player_position(actor, new_position)
        final_distance = abs(target_position - new_position)

        return {
            "success": True,
            "message": f"{actor.name} retreats {actual_movement}ft from opponent (distance now {final_distance}ft)",
            "distance_moved": actual_movement,
            "new_position": new_position
        }

class Disengage(Action):
    def __init__(self):
        super().__init__("Disengage", 0, "Move 5ft away from opponent without provoking reactive strike")

    def can_execute(self, actor, target, game_state) -> bool:
        return True  # Can always attempt to disengage

    def execute(self, actor, target, game_state) -> Dict[str, Any]:
        actor_position = game_state.get_player_position(actor)
        target_position = game_state.get_player_position(target)

        # Move exactly 5ft away from opponent
        if target_position > actor_position:
            new_position = actor_position - 5
        else:
            new_position = actor_position + 5

        # Validate position bounds
        new_position = max(0, min(100, new_position))
        actual_movement = abs(new_position - actor_position)

        game_state.set_player_position(actor, new_position)
        final_distance = abs(target_position - new_position)

        return {
            "success": True,
            "message": f"{actor.name} disengages {actual_movement}ft from opponent (distance now {final_distance}ft) - no reactive strike",
            "distance_moved": actual_movement,
            "new_position": new_position,
            "no_reactive_strike": True
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
            "advance": Advance(),
            "a": Advance(),  # Short form
            "retreat": Retreat(),
            "t": Retreat(),  # re(t)reat short form
            "disengage": Disengage(),
            "d": Disengage(),  # Short form
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