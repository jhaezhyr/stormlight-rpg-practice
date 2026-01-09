public protocol RpgCharacterBrain: Sendable {
    func decide<C: Sendable>(options: C, in gameSnapshot: GameSnapshot) async -> C.Element
    where C: Collection, C: Sendable
    func decide<T: Sendable>(type: T.Type, in gameSnapshot: GameSnapshot) async -> T
}
