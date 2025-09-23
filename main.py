#!/usr/bin/env python3

import sys
from typing import List, Optional
from src.game import Game, TurnType
from src.character import Character

class StormLightDuelREPL:
    def __init__(self):
        self.game: Optional[Game] = None
        self.current_player: Optional[Character] = None
        self.actions_remaining = 0

    def start(self):
        self.print_welcome()
        while True:
            if not self.game:
                self.setup_game()
            else:
                self.run_game_loop()

    def print_welcome(self):
        print("=" * 60)
        print("            STORMLIGHT DUEL")
        print("         A Command Line MUD")
        print("=" * 60)
        print()
        print("Two characters enter the arena...")
        print("Only one will emerge victorious!")
        print()

    def setup_game(self):
        print("Setting up new duel...")
        print()

        player1_name = input("Enter name for Player 1: ").strip()
        if not player1_name:
            player1_name = "Player 1"

        player2_name = input("Enter name for Player 2: ").strip()
        if not player2_name:
            player2_name = "Player 2"

        self.game = Game(player1_name, player2_name)
        print()
        print("Characters created!")
        print()
        self.display_characters()
        print()
        print("The duel begins! Type 'help' for available commands.")
        print()

    def display_characters(self):
        print("=" * 40)
        print(self.game.player1)
        print()
        print(self.game.player2)
        print("=" * 40)

    def run_game_loop(self):
        if self.game.check_game_over():
            self.handle_game_over()
            return

        if self.actions_remaining <= 0:
            self.start_turn_phase()
        else:
            self.handle_action_phase()

    def start_turn_phase(self):
        self.game.start_new_turn()
        self.display_game_status()

        print(f"\n--- Turn {self.game.state.turn_number} ---")
        print("Choose turn types:")

        for player in [self.game.player1, self.game.player2]:
            while True:
                choice = input(f"{player.name}, choose turn type (fast/slow): ").lower().strip()
                if choice in ['fast', 'slow']:
                    turn_type = TurnType.FAST if choice == 'fast' else TurnType.SLOW
                    self.game.choose_turn_type(player, turn_type)
                    break
                else:
                    print("Please enter 'fast' or 'slow'")

        turn_order = self.game.determine_turn_order()
        print(f"\nTurn order: {turn_order[0][0].name} goes first, then {turn_order[1][0].name}")

        self.current_player = turn_order[0][0]
        self.actions_remaining = turn_order[0][1]
        print(f"\n{self.current_player.name}'s turn ({self.actions_remaining} actions)")

    def handle_action_phase(self):
        print(f"\n{self.current_player.name}, you have {self.actions_remaining} actions remaining.")
        self.show_available_actions()

        while True:
            command = input(f"{self.current_player.name}> ").strip().lower()

            if command in ['quit', 'exit']:
                print("Thanks for playing!")
                sys.exit(0)
            elif command == 'help':
                self.show_help()
                continue
            elif command == 'status':
                self.display_game_status()
                continue
            elif command == 'actions':
                self.show_available_actions()
                continue
            elif command in self.game.action_registry.actions:
                result = self.game.execute_action(self.current_player, command)
                self.handle_action_result(result)
                break
            else:
                print("Unknown command. Type 'help' for available commands.")

    def handle_action_result(self, result):
        if result["success"]:
            print(result["message"])
            self.actions_remaining -= 1

            if self.actions_remaining <= 0:
                self.switch_player()
        else:
            print(f"Action failed: {result['message']}")

    def switch_player(self):
        if self.current_player == self.game.player1:
            turn_order = self.game.determine_turn_order()
            if len(turn_order) > 1 and turn_order[1][0] != self.current_player:
                self.current_player = turn_order[1][0]
                self.actions_remaining = turn_order[1][1]
                print(f"\n{self.current_player.name}'s turn ({self.actions_remaining} actions)")
            else:
                self.actions_remaining = 0
        else:
            self.actions_remaining = 0

    def show_available_actions(self):
        available = self.game.get_available_actions(self.current_player)
        all_actions = self.game.action_registry.list_all_actions()

        print("\nAvailable actions:")
        for action_name in available:
            description = all_actions.get(action_name, "")
            print(f"  {action_name}: {description}")

        print("\nOther commands: help, status, actions, quit")

    def show_help(self):
        print("\n" + "=" * 50)
        print("STORMLIGHT DUEL HELP")
        print("=" * 50)
        print("Game Flow:")
        print("  1. Each turn, choose 'fast' (2 actions) or 'slow' (3 actions)")
        print("  2. Turn order: Fast beats Slow, otherwise random")
        print("  3. Execute actions until you run out")
        print("  4. Repeat until someone dies")
        print()
        print("Actions:")
        all_actions = self.game.action_registry.list_all_actions()
        for name, desc in all_actions.items():
            print(f"  {name}: {desc}")
        print("  - move: Use negative distance to move closer, positive to move away")
        print("  - Maximum movement per turn equals your speed (25ft or 30ft)")
        print("  - Cannot move closer than 0ft apart")
        print()
        print("Commands:")
        print("  help: Show this help")
        print("  status: Display game status")
        print("  actions: Show available actions")
        print("  quit: Exit game")
        print("=" * 50)

    def display_game_status(self):
        status = self.game.get_game_status()
        print("\n" + "=" * 50)
        print(f"Turn {status['turn']} | Distance: {status['distance']}")
        print("-" * 50)

        p1 = status['player1']
        p2 = status['player2']

        print(f"{p1['name']}: HP {p1['health']}, Focus {p1['focus']}")
        if p1['conditions']:
            print(f"  Conditions: {', '.join(p1['conditions'])}")

        print(f"{p2['name']}: HP {p2['health']}, Focus {p2['focus']}")
        if p2['conditions']:
            print(f"  Conditions: {', '.join(p2['conditions'])}")

        print("=" * 50)

    def handle_game_over(self):
        status = self.game.get_game_status()
        print("\n" + "=" * 60)
        print("                GAME OVER")
        print("=" * 60)
        print(f"{status['winner']} is victorious!")
        print("=" * 60)

        while True:
            choice = input("\nPlay again? (y/n): ").lower().strip()
            if choice in ['y', 'yes']:
                self.game = None
                self.current_player = None
                self.actions_remaining = 0
                break
            elif choice in ['n', 'no']:
                print("Thanks for playing!")
                sys.exit(0)
            else:
                print("Please enter 'y' or 'n'")

def main():
    try:
        repl = StormLightDuelREPL()
        repl.start()
    except KeyboardInterrupt:
        print("\n\nGoodbye!")
        sys.exit(0)

if __name__ == "__main__":
    main()