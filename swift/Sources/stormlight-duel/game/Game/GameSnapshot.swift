import KeyedSet

/// The immutable, sendable version of Game.
public struct GameSnapshot: GameSharedProtocol, Sendable {
    public var characters: KeyedSet<AnyRpgCharacterSnapshot>
    public var tests: KeyedSet<AnyRpgTestSnapshot>
    public var scene: (any Scene)?

    public static let empty = Self(characters: [], tests: [])
}

extension Game {
    func snapshot(in gameSession: isolated GameSession = #isolation) -> GameSnapshot {
        GameSnapshot(
            characters: .init(
                self.characters.isolatedMap(in: gameSession) {
                    .init($0.snapshot(in: $1))
                }),
            tests: .init(
                self.tests.isolatedMap { .init($0.snapshot(in: $1)) }),
            scene: scene

        )
    }
}

extension Sequence {
    public func isolatedMap<A: Actor, U>(
        in isolation: isolated A = #isolation,
        _ fn: (_ x: Element, _ isolation: isolated A) -> U
    ) -> [U] {
        var result = [U]()
        for x in self {
            result.append(fn(x, isolation))
        }
        return result
    }
}
