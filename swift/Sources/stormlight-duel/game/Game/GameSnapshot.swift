/// The immutable, sendable version of Game.
public struct GameSnapshot: GameSharedProtocol, Sendable {
    public var characters: KeyedSet<AnyRpgCharacterSnapshot>
    public var tests: KeyedSet<AnyRpgTestSnapshot>
}

extension Game {
    var snapshot: GameSnapshot {
        GameSnapshot(
            characters: .init(self.characters.map { .init($0.snapshot) }),
            tests: .init(self.tests.map { .init($0.snapshot) })
        )
    }
}
