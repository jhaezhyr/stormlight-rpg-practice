public protocol RpgCharacterBrain: Sendable {
    func decide<C: Sendable>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot)
        async throws
        -> C.Element
    where C: Collection, C: Sendable
    func decide<T: Sendable>(
        _ code: DecisionCode,
        nonIterableType: T.Type,
        in gameSnapshot: GameSnapshot
    )
        async throws -> T

    func hear<M>(_ message: M, in gameSnapshot: GameSnapshot) async where M: Message
    func hearHint(_ message: String, in gameSnapshot: GameSnapshot) async
}
extension RpgCharacterBrain {
    public func decide<T: Sendable & CaseIterable>(
        _ code: DecisionCode,
        iterableType: T.Type,
        in gameSnapshot: GameSnapshot
    ) async throws -> T where T.AllCases: Sendable {
        try await decide(code, options: T.allCases, in: gameSnapshot)
    }
}

public typealias GameMasterBrain = RpgCharacterBrain
