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
                cpuBrainKey: .level2,
                connection: nil
            )
        case .greenie:
            return PlayerBuilderTemplate(
                prefab: .spearInfantry,
                isPlayer: false,
                name: "Greenie",
                cpuBrainKey: .level2,
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
