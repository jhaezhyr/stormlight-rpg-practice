public protocol RpgCharacterBrain {
    func decide<C>(options: C) -> C.Element where C: Collection
    func decide<T>(type: T.Type) -> T
}

struct RpgCharacterDummyBrain: RpgCharacterBrain {
    func decide<C>(options: C) -> C.Element where C: Collection {
        return options.first!
    }

    func decide<T>(type: T.Type) -> T {
        fatalError("I'm too much of a dummy to decide.")
    }
}
