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
    @MainActor
    public func decide<C>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot)
        -> C.Element
    where C: Collection, C.Element: Sendable {
        if let answer = getPremadeAnswer(ofType: C.Element.self) {
            return answer
        }
        if !onlyGivePremadeAnswers {
            return options.first!
        }
        fatalError(
            "\(self.characterRef.name) is too much of a dummy to decide between these \(options.count) options: \(options)."
        )
    }

    @MainActor
    public func decide<T: Sendable>(
        _ code: DecisionCode,
        nonIterableType: T.Type,
        in gameSnapshot: GameSnapshot
    ) -> T {
        if let answer = getPremadeAnswer(ofType: nonIterableType) {
            return answer
        }
        fatalError("\(self.characterRef.name) is too much of a dummy to decide on a \(T.self)")
    }

    @MainActor
    private func getPremadeAnswer<T: Sendable>(ofType type: T.Type) -> T? {
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

    public func hear<M>(_ message: M, in gameSnapshot: GameSnapshot) async where M: Message {
    }

    public func hearHint(_ message: String, in gameSnapshot: GameSnapshot) async {
    }
}
