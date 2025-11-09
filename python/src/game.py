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
        # Position-based battlefield: P1 at 0, P2 at 30
        self.player1_position = 0
        self.player2_position = 30
        # 3 random cover points within 100ft
        self.cover_points = sorted(random.sample(range(5, 96), 3))  # Random positions, avoiding edges
        self.turn_number = 0
        self.game_over = False
        self.winner = None

    @property
    def distance(self) -> int:
        """Calculate distance between players for backward compatibility"""
        return abs(self.player2_position - self.player1_position)

    def get_player_position(self, player: 'Character') -> int:
        """Get position of a specific player"""
        # This will be set properly by the Game class
        return getattr(player, '_battlefield_position', 0)

    def set_player_position(self, player: 'Character', position: int):
        """Set position of a specific player"""
        setattr(player, '_battlefield_position', position)
        # Also update the state positions for backward compatibility
        if hasattr(player, '_is_player1') and player._is_player1:
            self.player1_position = position
        else:
            self.player2_position = position

class Game:
    def __init__(self, player1_name: str, player2_name: str):
        self.player1 = Character(player1_name)
        self.player2 = Character(player2_name)
        self.state = GameState()

        # Initialize player positions and identities
        self.player1._is_player1 = True
        self.player2._is_player1 = False
        self.state.set_player_position(self.player1, 0)
        self.state.set_player_position(self.player2, 30)

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
            "battlefield": {
                "player1_position": self.state.player1_position,
                "player2_position": self.state.player2_position,
                "cover_points": self.state.cover_points
            },
            "player1": {
                "name": self.player1.name,
                "position": self.state.get_player_position(self.player1),
                "health": f"{self.player1.current_health}/{self.player1.max_health}",
                "focus": f"{self.player1.current_focus}/{self.player1.max_focus}",
                "conditions": self.condition_manager1.get_all_conditions()
            },
            "player2": {
                "name": self.player2.name,
                "position": self.state.get_player_position(self.player2),
                "health": f"{self.player2.current_health}/{self.player2.max_health}",
                "focus": f"{self.player2.current_focus}/{self.player2.max_focus}",
                "conditions": self.condition_manager2.get_all_conditions()
            },
            "game_over": self.state.game_over,
            "winner": self.state.winner.name if self.state.winner else None
        }

    def display_battlefield(self) -> str:
        """Generate a visual representation of the battlefield"""
        battlefield = ["_"] * 21  # Represent 0-100ft as 21 positions (every 5ft)

        # Add player positions
        p1_pos = self.state.player1_position // 5
        p2_pos = self.state.player2_position // 5
        battlefield[p1_pos] = "1"
        battlefield[p2_pos] = "2"

        # Add cover points
        for cover_pos in self.state.cover_points:
            cover_index = cover_pos // 5
            if battlefield[cover_index] == "_":
                battlefield[cover_index] = "C"

        # Create the display
        display = "".join(battlefield)
        position_labels = [f"{i*5:2d}" for i in range(0, 21, 5)]

        return f"""Battlefield (0-100ft):
{display}
{' '.join(position_labels)}

P1: {self.player1.name} at {self.state.player1_position}ft
P2: {self.player2.name} at {self.state.player2_position}ft
Cover at: {', '.join([f'{pos}ft' for pos in self.state.cover_points])}
Distance: {self.state.distance}ft"""

    def get_cover_options(self, player: Character) -> Dict[str, List[int]]:
        """Get movement options to reach cover for a player"""
        player_pos = self.state.get_player_position(player)
        advance_options = []
        retreat_options = []

        for cover_pos in self.state.cover_points:
            distance_to_cover = cover_pos - player_pos
            if distance_to_cover > 0:
                advance_options.append(distance_to_cover)
            elif distance_to_cover < 0:
                retreat_options.append(abs(distance_to_cover))

        return {
            "advance": sorted(advance_options),
            "retreat": sorted(retreat_options)
        }