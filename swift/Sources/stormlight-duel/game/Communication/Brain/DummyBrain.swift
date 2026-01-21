public struct RpgCharacterDummyBrain: RpgCharacterBrain {
    public let characterRef: RpgCharacterRef

    public func decide<C>(options: C, in gameSnapshot: GameSnapshot) -> C.Element
    where C: Collection {
        return options.first!
    }

    public func decide<T>(type: T.Type, in gameSnapshot: GameSnapshot) -> T {
        fatalError("I'm too much of a dummy to decide.")
    }
}
