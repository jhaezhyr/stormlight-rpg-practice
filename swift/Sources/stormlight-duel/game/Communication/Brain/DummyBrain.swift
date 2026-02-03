public final class RpgCharacterDummyBrain: RpgCharacterBrain {
    public let characterRef: RpgCharacterRef

    /// Why is this isolated to the main actor? Because it needed to be isolated to SOMETHING, apparently.
    @MainActor
    public private(set) var premadeAnswers: [any Sendable] = []
    @MainActor
    public var onlyGivePremadeAnswers: Bool = false

    public init(characterRef: RpgCharacterRef) {
        self.characterRef = characterRef
    }

    /// If we have a valid premade answer, return it!
    ///
    /// Only checks for type info; doesn't check whether it's in the option list.
    public func decide<C>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot)
        async -> C.Element
    where C: Collection, C.Element: Sendable {
        if let answer = await getPremadeAnswer(ofType: C.Element.self) {
            return answer
        }
        if await !onlyGivePremadeAnswers {
            return options.first!
        }
        fatalError(
            "\(self.characterRef.name) is too much of a dummy to decide between these \(options.count) options: \(options)."
        )
    }

    public func decide<T: Sendable>(
        _ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot
    ) async -> T {
        if let answer = await getPremadeAnswer(ofType: type) {
            return answer
        }
        fatalError("\(self.characterRef.name) is too much of a dummy to decide on a \(T.self)")
    }

    @MainActor
    private func getPremadeAnswer<T: Sendable>(ofType type: T.Type) -> T? {
        print("Looking for a premade answer of type \(type). We have \(premadeAnswers) available.")
        for (i, premadeAnswer) in premadeAnswers.enumerated() {
            if let answerAsRightType = premadeAnswer as? T {
                premadeAnswers.remove(at: i)
                return answerAsRightType
            }
        }
        return nil
    }

    @MainActor
    public func insertPremadeAnswer<T: Sendable>(_ value: T) {
        self.premadeAnswers.append(value)
    }
}
