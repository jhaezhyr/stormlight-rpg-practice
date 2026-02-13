/// The immutable, sendable version of Game.
public struct GameSnapshot: GameSharedProtocol, Sendable {
    public var characters: KeyedSet<AnyRpgCharacterSnapshot>
    public var tests: KeyedSet<AnyRpgTestSnapshot>
    public var scene: (any Scene)?

    public static let empty = Self(characters: [], tests: [])
}

extension Game {
    var snapshot: GameSnapshot {
        GameSnapshot(
            characters: .init(self.characters.map { .init($0.snapshot) }),
            tests: .init(
                self.tests.map { .init($0.snapshot) }),
            scene: scene

        )
    }
}

extension GameSharedProtocol {
    func enemies(of x: RpgCharacterRef) -> [RpgCharacterRef] {
        characters.keys.filter { $0 != x }
    }
}
