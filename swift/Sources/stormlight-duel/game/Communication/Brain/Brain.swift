public protocol RpgCharacterBrain: Sendable {
    func decide<C: Sendable>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot) async
        -> C.Element
    where C: Collection, C: Sendable
    func decide<T: Sendable>(_ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot)
        async -> T

    func hear<M>(_ message: M, in gameSnapshot: GameSnapshot) async where M: Message
    func hearHint(_ message: String, in gameSnapshot: GameSnapshot) async
}

public typealias GameMasterBrain = RpgCharacterBrain
