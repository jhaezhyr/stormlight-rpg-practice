public struct Broadcaster: Sendable {
    public init() {}
    func tellAll<M: Message>(_ message: M, in gameSession: isolated GameSession = #isolation) async
    {
        for character in gameSession.game.characters {
            await character.brain.hear(message, in: gameSession.game.snapshot)
        }
    }

    // TODO This is a subpar pattern. We should pass context objects to prompts instead, in addition to the snapshot. Maybe that way, tests could be part of the context, instead of this weird array next to the characters.
    func tellHint(
        _ hint: String,
        to: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    )
        async
    {
        await gameSession.game.anyCharacter(at: to)?.brain.hearHint(
            hint, in: gameSession.game.snapshot)
    }
}

public protocol Message: Sendable {
    func description(for characterRef: RpgCharacterRef) -> String
}

public struct NoTargetMessage: Message {
    // Phase 1 begins
    public let description: String
    public func description(for characterRef: RpgCharacterRef) -> String { description }
    public init(_ description: String) {
        self.description = description
    }
}

public struct SingleTargetMessage: Message {
    // Shallan recovers 5 health. You recover 5 health.
    // The Heralds smile upon Taravangian. The Heralds smile upon you.
    public let target: RpgCharacterRef
    public let thirdPersonDescription: String
    public let secondPersonDescription: String
    public func description(for characterRef: RpgCharacterRef) -> String {
        if characterRef == target {
            secondPersonDescription
        } else {
            thirdPersonDescription.replacing("$1", with: target.name)
        }
    }
    public init(
        w1 thirdPersonDescription: String,
        wU secondPersonDescription: String,
        as1 target: RpgCharacterRef
    ) {
        self.thirdPersonDescription = thirdPersonDescription
        self.secondPersonDescription = secondPersonDescription
        self.target = target
    }
}

public struct DoubleTargetMessage: Message {
    // Kal attacks Shallan. You attack Shallan. Kal attacks you.
    // Moash brandishes their blade and strikes Teft. You brandish your blade and strike Teft. Moash brandishes their blade and strikes you.
    public let subject: RpgCharacterRef
    public let object: RpgCharacterRef
    public let thirdPersonDescription: String
    public let secondPersonSubjectDescription: String
    public let secondPersonObjectDescription: String
    public func description(for characterRef: RpgCharacterRef) -> String {
        if subject == characterRef {
            return secondPersonSubjectDescription.replacing("$2", with: object.name)
        } else if object == characterRef {
            return secondPersonObjectDescription.replacing("$1", with: subject.name)
        } else {
            return thirdPersonDescription.replacing("$1", with: subject.name).replacing(
                "$2", with: object.name)
        }
    }
    public init(
        w12 thirdPersonDescription: String,
        wU2 secondPersonSubjectDescription: String,
        w1U secondPersonObjectDescription: String,
        as1 subject: RpgCharacterRef,
        as2 object: RpgCharacterRef
    ) {
        self.thirdPersonDescription = thirdPersonDescription
        self.secondPersonSubjectDescription = secondPersonSubjectDescription
        self.secondPersonObjectDescription = secondPersonObjectDescription
        self.subject = subject
        self.object = object
    }
}

public struct ContextFreeMultiTargetMessage: Message {
    public let thirdPersonDescription: String
    public let targets: [RpgCharacterRef]
    public func description(for characterRef: RpgCharacterRef) -> String {
        var result = thirdPersonDescription
        for (i, target) in targets.enumerated() {
            let replacer = "$\(i)"
            let toReplaceWith = characterRef == target ? "you" : target.name
            result = result.replacing(replacer, with: toReplaceWith)
        }
        if !result.isEmpty && result.first! == "y" {
            return result.replacing("y", with: "Y", maxReplacements: 1)
        }
        return result
    }
    public init(_ thirdPersonDescription: String, for targets: [RpgCharacterRef]) {
        self.thirdPersonDescription = thirdPersonDescription
        self.targets = targets
    }
}
