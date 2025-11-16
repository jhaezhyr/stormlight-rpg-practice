public struct AnyRpgCharacter: RpgCharacter {
    public var name: String { core.name }
    public var attributes: CompleteDictionary<AttributeName, Int> { core.attributes }
    public var ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int> { core.ranksInCoreSkills }
    public var ranksInOtherSkills: [SkillName: Int] { core.ranksInOtherSkills }
    public var health: Resource {
        get { core.health }
        set { core.health = newValue }
    }
    public var focus: Resource {
        get { core.focus }
        set { core.focus = newValue }
    }
    public var investiture: Resource {
        get { core.investiture }
        set { core.investiture = newValue }
    }
    public var conditions: [any ConditionProtocol] {
        get { core.conditions }
        set { core.conditions = newValue }
    }
    public var size: CharacterSize { core.size }
    public var core: any RpgCharacter
    init(_ character: any RpgCharacter) {
        self.core = character
    }
}

public struct Game {
    public var characters: [any RpgCharacter]
    public var tests: [RpgTestRef: any RpgTestProtocol] = [:]

    public init(characters: [any RpgCharacter]) {
        self.characters = characters
    }
}

extension Game {
    // Raw, dealing with existential `any RpgCharacter` types.

    /// Unwrap and update the given character in the game state.
    ///
    //// If the character is wrapped in an AnyRpgCharacter, will unwrap and update the underlying character as many times as necessary to get to a concrete one.
    public mutating func updateAnyCharacter(_ character: any RpgCharacter) {
        if let characterAsWrapper = character as? AnyRpgCharacter {
            updateAnyCharacter(characterAsWrapper.core)
            return
        }
        if let index = characters.firstIndex(where: { $0.name == character.name }) {
            characters[index] = character
        } else {
            characters.append(character)
        }
    }

    public func anyCharacter(at ref: RpgCharacterRef) -> (any RpgCharacter)? {
        characters.first(where: { $0.name == ref.name })
    }

    /// Get a character at the given reference, if it exists and is of the requested type.
    ///
    /// If you ask for a wrapped `AnyRpgCharacter`, it will unwrap any existing character found at the reference.
    public func character<Character: RpgCharacter>(at ref: RpgCharacterRef, as type: Character.Type)
        -> Character?
    {
        if Character.self == AnyRpgCharacter.self {
            if let anyChar = anyCharacter(at: ref) {
                // First check if we've actually stored a character in a type-erased wrapper. If so, return that wrapper directly. (This shouldn't happen, but just in case.)
                if let anyCharAsAnyRpg = anyChar as? AnyRpgCharacter {
                    return anyCharAsAnyRpg as? Character  // Will always succeed
                }
                // Otherwise, wrap what we found.
                return AnyRpgCharacter(anyChar) as? Character
            }
        }
        return anyCharacter(at: ref) as? Character
    }

    /// Update the given character in the game state.
    public mutating func updateCharacter<Character: RpgCharacter>(_ character: Character) {
        updateAnyCharacter(character)
    }
}

extension Game {
    public mutating func updateAnyTest(_ test: any RpgTestProtocol, at ref: RpgTestRef) {
        if let testAsWrapper = test as? AnyRpgTest {
            updateAnyTest(testAsWrapper.core, at: ref)
            return
        }
        tests[ref] = test
    }

    public mutating func updateTest<Test: RpgTestProtocol>(_ test: Test, at ref: RpgTestRef) {
        updateAnyTest(test, at: ref)
    }

    public func anyTest(at ref: RpgTestRef) -> (any RpgTestProtocol)? {
        tests[ref]
    }

    public func test<Test: RpgTestProtocol>(at ref: RpgTestRef, as type: Test.Type) -> Test? {
        if Test.self == AnyRpgTest.self {
            if let anyTest = anyTest(at: ref) {
                // First check if we've actually stored a test in a type-erased wrapper. If so, return that wrapper directly. (This shouldn't happen, but just in case.)
                if let anyTestAsAnyRpgTest = anyTest as? AnyRpgTest {
                    return anyTestAsAnyRpgTest as? Test  // Will always succeed
                }
                // Otherwise, wrap what we found.
                return AnyRpgTest(anyTest) as? Test
            }
        }
        return anyTest(at: ref) as? Test
    }
}

extension Game: NonLeafGenericListenerHolder, AllTheListenersHolder {
    public var childHolders: [Any] {
        characters
    }

    /// Why is it called naive? Because it only talks to the listeners that want something exactly like this. No narrow character mutation. If there was an event sent that included something for a character, none of the SelfListeners will be notified.
    public mutating func naiveDispatch<T: HookTrigger>(_ hookTrigger: T) {
        for listener in allListeners {
            if listener.hook as? T == hookTrigger {
                listener.action(&self)
            }
        }
    }

    public mutating func naiveDispatch<T: HookTrigger>(
        _ hookTrigger: T, for characterRef: RpgCharacterRef
    ) {
        for listener in self.allSelfListeners {
            if listener.hook as? T == hookTrigger {
                guard var char = self.anyCharacter(at: characterRef) else {
                    fatalError("Bad character reference")
                }
                listener.typeErasedAction(self, &char)
                self.updateAnyCharacter(char)
            }
        }
    }

    public mutating func naiveDispatch<T: HookTriggerForSomeRpgCharacter>(
        _ hookTrigger: T, for characterRef: RpgCharacterRef
    ) {
        for listener in self.allSelfListenersSelfHooks {
            if listener.hook as? T == hookTrigger {
                guard var char = self.anyCharacter(at: characterRef) else {
                    fatalError("Bad character reference")
                }
                listener.typeErasedAction(self, &char)
                self.updateAnyCharacter(char)
            }
        }
    }

    public mutating func naiveDispatch<T: HookTrigger>(
        _ hookTrigger: T, for characterRef: RpgCharacterRef, attempting testRef: RpgTestRef
    ) {
        for listener in self.allSelfListenersSelfHooksForTests {
            if listener.hook as? T == hookTrigger {
                guard var char = self.anyCharacter(at: characterRef) else {
                    fatalError("Bad character reference")
                }
                guard var test = self.anyTest(at: testRef) else {
                    fatalError("Bad test reference")
                }
                listener.typeErasedAction(self, &char, &test)
                self.updateAnyCharacter(char)
            }
        }
    }
}
