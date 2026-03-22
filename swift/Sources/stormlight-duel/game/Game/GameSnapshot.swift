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
        _ fn: (_ x: Element, _ isolation: isolated A) throws -> U
    ) rethrows -> [U] {
        var result = [U]()
        for x in self {
            try result.append(fn(x, isolation))
        }
        return result
    }

    public func isolatedCompactMap<A: Actor, U>(
        in isolation: isolated A = #isolation,
        _ fn: (_ x: Element, _ isolation: isolated A) throws -> U?
    ) rethrows -> [U] {
        var result = [U]()
        for x in self {
            if let new = try fn(x, isolation) {
                result.append(new)
            }
        }
        return result
    }

    public func asyncMap<U>(
        _ fn: (_ x: Element) async throws -> U
    ) async rethrows -> [U] {
        var result = [U]()
        for x in self {
            try await result.append(fn(x))
        }
        return result
    }

    public func asyncCompactMap<U>(
        _ fn: (_ x: Element) async throws -> U?
    ) async rethrows -> [U] {
        var result = [U]()
        for x in self {
            if let new = try await fn(x) {
                result.append(new)
            }
        }
        return result
    }
    public func isolatedAsyncMap<A: Actor, U>(
        in isolation: isolated A = #isolation,
        _ fn: @Sendable (_ x: Element, _ isolation: isolated A) async throws -> U
    ) async rethrows -> [U] {
        var result = [U]()
        for x in self {
            try await result.append(fn(x, isolation))
        }
        return result
    }

    public func isolatedAsyncCompactMap<A: Actor, U>(
        in isolation: isolated A = #isolation,
        _ fn: @Sendable (_ x: Element, _ isolation: isolated A) async throws -> U?
    ) async rethrows -> [U] {
        var result = [U]()
        for x in self {
            if let new = try await fn(x, isolation) {
                result.append(new)
            }
        }
        return result
    }
}
