public protocol RpgCharacterBrain: Sendable {
    func decide<C: Sendable>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot) async
        -> C.Element
    where C: Collection, C: Sendable
    func decide<T: Sendable>(_ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot)
        async -> T
}

public typealias GameMasterBrain = RpgCharacterBrain
