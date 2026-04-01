import stormlight_duel
import text_brain

/// Options for character rules type.
enum RulesType: CustomStringConvertible, CaseIterable {
    case player
    case minion

    var description: String {
        switch self {
        case .player: return "Player (full capabilities)"
        case .minion: return "Minion (simplified rules)"
        }
    }

    var isPlayer: Bool {
        switch self {
        case .player: return true
        case .minion: return false
        }
    }
}

/// Actor responsible for guiding players through character building.
actor GameBuilderSession {

    // MARK: - Build Player Character

    /// Guides a player through building their character (class, name, rules).
    /// Used by both PvE and PvP flows.
    func buildPlayerCharacter(connection: WebTextInterfaceConnection) async throws
        -> PlayerBuilderTemplate
    {
        // Step 1: Choose class
        let prefab = try await decideBetweenOptions(
            PlayerPrefabKey.allCases,
            prompt: "Choose your character class:",
            extraInterface: nil,
            connection: connection
        )

        // Step 2: Enter name
        await connection.display("prompt", message: "Enter your character's name:", interface: nil)
        var name = try await connection.getAnswer()
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            name = prefab.rawValue
        }

        // Step 3: Choose rules type (Player or Minion)
        let rulesType = try await decideBetweenOptions(
            RulesType.allCases,
            prompt: "Choose your character's rules type:",
            extraInterface: nil,
            connection: connection
        )

        return PlayerBuilderTemplate(
            prefab: prefab,
            isPlayer: rulesType.isPlayer,
            name: name,
            cpuBrainKey: nil,
            connection: connection
        )
    }

    // MARK: - Build Enemy Character (PvE)

    /// Guides a player through selecting/building an enemy character for PvE.
    func buildEnemyCharacter(connection: WebTextInterfaceConnection) async throws
        -> PlayerBuilderTemplate
    {
        // Present predefined options or custom
        enum EnemyChoice: CustomStringConvertible, CaseIterable {
            case thaylenno
            case greenie
            case custom

            var description: String {
                switch self {
                case .thaylenno: return "Thaylenno the Archer"
                case .greenie: return "Greenie the Spear Infantry"
                case .custom: return "Custom — build your own enemy"
                }
            }
        }

        let choice = try await decideBetweenOptions(
            EnemyChoice.allCases,
            prompt: "Choose your opponent:",
            extraInterface: nil,
            connection: connection
        )

        switch choice {
        case .thaylenno:
            return PlayerBuilderTemplate(
                prefab: .archer,
                isPlayer: false,
                name: "Thaylenno",
                cpuBrainKey: .level1,
                connection: nil
            )
        case .greenie:
            return PlayerBuilderTemplate(
                prefab: .spearInfantry,
                isPlayer: false,
                name: "Greenie",
                cpuBrainKey: .level1,
                connection: nil
            )
        case .custom:
            return try await buildCustomEnemyCharacter(connection: connection)
        }
    }

    /// Builds a custom enemy character with full options.
    private func buildCustomEnemyCharacter(connection: WebTextInterfaceConnection) async throws
        -> PlayerBuilderTemplate
    {
        // Step 1: Choose class
        let prefab = try await decideBetweenOptions(
            PlayerPrefabKey.allCases,
            prompt: "Choose enemy class:",
            extraInterface: nil,
            connection: connection
        )

        // Step 2: Enter name
        await connection.display("prompt", message: "Enter enemy's name:", interface: nil)
        var name = try await connection.getAnswer()
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            name = "Custom Enemy"
        }

        // Step 3: Choose rules type
        let rulesType = try await decideBetweenOptions(
            RulesType.allCases,
            prompt: "Choose enemy's rules type:",
            extraInterface: nil,
            connection: connection
        )

        // Step 4: Choose CPU brain (only level 1 for now)
        let cpuBrain = try await decideBetweenOptions(
            CpuBrainKey.allCases,
            prompt: "Choose CPU difficulty:",
            extraInterface: nil,
            connection: connection
        )

        return PlayerBuilderTemplate(
            prefab: prefab,
            isPlayer: rulesType.isPlayer,
            name: name,
            cpuBrainKey: cpuBrain,
            connection: nil
        )
    }

    // MARK: - Show Instructions

    /// Displays an instructions screen with actual character names and classes.
    func showInstructions(
        player: PlayerBuilderTemplate,
        enemy: PlayerBuilderTemplate,
        connection: WebTextInterfaceConnection
    ) async throws {
        let playerClass = player.prefab.description
        let enemyClass = enemy.prefab.description

        await connection.display(
            "prompt",
            message: """
                Welcome to STORMLIGHT DUEL!

                This videogame experience is based on the "Cosmere Roleplaying Game" by
                Brotherwise Games, based on works by Brandon Sanderson. The videogame is
                written and hosted by Braeden Hintze.

                            * ** INSTRUCTIONS ** * 

                You play as \(player.name), a \(playerClass). You are in a one-on-one
                combat with \(enemy.name), a \(enemyClass). Bring them down.

                Anytime you are prompted to make a choice, you type in your answer and
                press ENTER. In some cases, you are given multiple numbered options. In
                other cases, your choices are a list of one-word commands. Some commands
                have single-letter aliases to make them easier to type.

                When the game waits for your input, you also can type "status" in order
                to see the map and the conditions of both characters. The map shows a
                character initial for each location, and a . for every 5ft distance.
                The map is 1-dimensional to keep things simple and brutal.

                Do you understand?
                """,
            interface: nil
        )

        // Wait for confirmation
        _ = try await decideBetweenOptions(
            UnderstandingChoice.allCases,
            prompt: "Do you understand the instructions?",
            extraInterface: nil,
            connection: connection
        )
    }

    // MARK: - Decision Helper

    /// Helper to decide between options using numbered choices.
    private func decideBetweenOptions<T: CustomStringConvertible>(
        _ options: [T],
        prompt: String,
        extraInterface: [String]? = nil,
        connection: WebTextInterfaceConnection
    ) async throws -> T {
        var message = prompt
        for (i, option) in options.enumerated() {
            message += "\n:\(i + 1) \(option)"
        }

        while true {
            await connection.display(
                "prompt", message: message, interface: extraInterface?.joined(separator: "\n"))
            let answer = try await connection.getAnswer()

            if let index = Int(answer), index >= 1, index <= options.count {
                return options[index - 1]
            }

            await connection.display(
                "hint",
                message: "Invalid choice. Please enter a number from 1 to \(options.count).",
                interface: nil)
        }
    }
}

// MARK: - Understanding Choice

enum UnderstandingChoice: String, Sendable, Hashable, CustomStringConvertible, CaseIterable {
    case yes = "yes, life before death"
    var description: String { self.rawValue }
}
