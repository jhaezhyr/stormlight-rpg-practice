import random
from enum import Enum
from typing import Dict, List, Tuple, Optional
from .character import Character
from .conditions import ConditionManager
from .actions import ActionRegistry

class TurnType(Enum):
    FAST = "fast"
    SLOW = "slow"

class GameState:
    def __init__(self):
        self.distance = 30  # Starting distance in feet
        self.turn_number = 0
        self.game_over = False
        self.winner = None

class Game:
    def __init__(self, player1_name: str, player2_name: str):
        self.player1 = Character(player1_name)
        self.player2 = Character(player2_name)
        self.state = GameState()
        self.condition_manager1 = ConditionManager()
        self.condition_manager2 = ConditionManager()
        self.action_registry = ActionRegistry()
        self.turn_choices: Dict[str, TurnType] = {}
        self.turn_order: List[Character] = []
        self.current_player_actions = 0
        self.max_actions_this_turn = 0

    def get_opponent(self, player: Character) -> Character:
        return self.player2 if player == self.player1 else self.player1

    def get_condition_manager(self, player: Character) -> ConditionManager:
        return self.condition_manager1 if player == self.player1 else self.condition_manager2

    def choose_turn_type(self, player: Character, turn_type: TurnType):
        self.turn_choices[player.name] = turn_type

    def determine_turn_order(self) -> List[Tuple[Character, int]]:
        p1_type = self.turn_choices.get(self.player1.name, TurnType.FAST)
        p2_type = self.turn_choices.get(self.player2.name, TurnType.FAST)

        p1_actions = 2 if p1_type == TurnType.FAST else 3
        p2_actions = 2 if p2_type == TurnType.FAST else 3

        if p1_type == TurnType.FAST and p2_type == TurnType.SLOW:
            return [(self.player1, p1_actions), (self.player2, p2_actions)]
        elif p1_type == TurnType.SLOW and p2_type == TurnType.FAST:
            return [(self.player2, p2_actions), (self.player1, p1_actions)]
        else:
            return [(self.player1, p1_actions), (self.player2, p2_actions)]

    def start_new_turn(self):
        self.state.turn_number += 1
        self.turn_choices.clear()
        self.process_condition_effects()

    def process_condition_effects(self):
        effects1 = self.condition_manager1.process_turn_effects(self.player1)
        effects2 = self.condition_manager2.process_turn_effects(self.player2)
        return effects1, effects2

    def execute_action(self, player: Character, action_name: str) -> Dict[str, any]:
        opponent = self.get_opponent(player)
        action = self.action_registry.get_action(action_name)

        if not action:
            return {"success": False, "message": f"Unknown action: {action_name}"}

        result = action.execute(player, opponent, self.state)
        return result

    def get_available_actions(self, player: Character) -> List[str]:
        opponent = self.get_opponent(player)
        return self.action_registry.get_available_actions(player, opponent, self.state)

    def check_game_over(self) -> bool:
        if not self.player1.is_alive():
            self.state.game_over = True
            self.state.winner = self.player2
            return True
        elif not self.player2.is_alive():
            self.state.game_over = True
            self.state.winner = self.player1
            return True
        return False

    def get_game_status(self) -> Dict[str, any]:
        return {
            "turn": self.state.turn_number,
            "distance": f"{self.state.distance}ft",
            "player1": {
                "name": self.player1.name,
                "health": f"{self.player1.current_health}/{self.player1.max_health}",
                "focus": f"{self.player1.current_focus}/{self.player1.max_focus}",
                "conditions": self.condition_manager1.get_all_conditions()
            },
            "player2": {
                "name": self.player2.name,
                "health": f"{self.player2.current_health}/{self.player2.max_health}",
                "focus": f"{self.player2.current_focus}/{self.player2.max_focus}",
                "conditions": self.condition_manager2.get_all_conditions()
            },
            "game_over": self.state.game_over,
            "winner": self.state.winner.name if self.state.winner else None
        }