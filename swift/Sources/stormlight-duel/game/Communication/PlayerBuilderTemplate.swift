/// Template for building a player character through the builder flow.
public struct PlayerBuilderTemplate: @unchecked Sendable {
    public var prefab: PlayerPrefabKey
    public var isPlayer: Bool
    public var name: String
    public var cpuBrainKey: CpuBrainKey?
    /// The connection for this player's brain. nil for CPU-controlled characters.
    /// This is typed as `Any` to avoid depending on the service module.
    /// The actual type should be a Sendable connection type from the using module.
    public var connection: Any?

    public init(
        prefab: PlayerPrefabKey,
        isPlayer: Bool,
        name: String,
        cpuBrainKey: CpuBrainKey? = nil,
        connection: Any? = nil
    ) {
        self.prefab = prefab
        self.isPlayer = isPlayer
        self.name = name
        self.cpuBrainKey = cpuBrainKey
        self.connection = connection
    }
}

/// Enum for selecting character class/prefab.
public enum PlayerPrefabKey: String, CaseIterable, Sendable, CustomStringConvertible {
    case archer = "Archer"
    case spearInfantry = "Spear Infantry"

    public var description: String { self.rawValue }
}

/// Enum for selecting CPU brain difficulty.
public enum CpuBrainKey: String, CaseIterable, Sendable, CustomStringConvertible {
    case level1

    public var description: String { "Level 1 CPU" }
}
