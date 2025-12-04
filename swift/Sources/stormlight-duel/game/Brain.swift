public protocol RpgCharacterBrain {
    var character: (any RpgCharacter)! { get set }
    func decide<C>(options: C) -> C.Element where C: Collection
    func decide<T>(type: T.Type) -> T
}

public struct RpgCharacterDummyBrain: RpgCharacterBrain {
    public unowned var character: (any RpgCharacter)!
    public func decide<C>(options: C) -> C.Element where C: Collection {
        return options.first!
    }

    public func decide<T>(type: T.Type) -> T {
        fatalError("I'm too much of a dummy to decide.")
    }
}
