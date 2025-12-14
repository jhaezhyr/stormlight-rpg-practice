/// Cannot hold one itself recursively. `AnyRpgCharacter(AnyRpgCharacter(someChar)).core === someChar`
public class AnyRpgCharacter: RpgCharacter {
    public var name: String { core.name }
    public var game: Game! {
        get { core.game }
        set { core.game = newValue }
    }
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
    public var combatState: RpgCharacterCombatState? {
        get { core.combatState }
        set { core.combatState = newValue }
    }
    public var brain: any RpgCharacterBrain { core.brain }
    public var equipment: KeyedSet<ReadyableItem> {
        get { core.equipment }
        set { core.equipment = newValue }
    }
    public var core: any RpgCharacter
    private init(notUnwrapping character: any RpgCharacter) {
        self.core = character
    }
    public convenience init(_ character: any RpgCharacter) {
        if let character = character as? AnyRpgCharacter {
            self.init(character)
        } else {
            self.init(notUnwrapping: character)
        }
    }
}

public class Game {
    public var characters: KeyedSet<AnyRpgCharacter>
    public var tests: KeyedSet<AnyRpgTest> = []

    public var rng: any RandomNumberGenerator = SystemRandomNumberGenerator()
    public var broadcaster: any Broadcaster

    public init(characters: [any RpgCharacter], broadcaster: Broadcaster) {
        self.characters = KeyedSet(characters.map(AnyRpgCharacter.init))
        self.broadcaster = broadcaster
        for character in characters {
            character.game = self
        }
    }
}

extension Game {
    // Raw, dealing with existential `any RpgCharacter` types.

    /// Unwrap and update the given character in the game state.
    ///
    //// If the character is wrapped in an AnyRpgCharacter, will unwrap and update the underlying character as many times as necessary to get to a concrete one.
    public func updateAnyCharacter(_ character: any RpgCharacter) {
        characters.upsert(AnyRpgCharacter(character))
    }

    public func anyCharacter(at ref: RpgCharacterRef) -> (any RpgCharacter)? {
        characters[ref]?.core
    }

    /// Get a character at the given reference, if it exists and is of the requested type.
    ///
    /// If you ask for a wrapped `AnyRpgCharacter`, it will unwrap any existing character found at the reference.
    public func character<Character: RpgCharacter>(at ref: RpgCharacterRef, as type: Character.Type)
        -> Character?
    {
        characters[ref]?.core as? Character
    }

    /// Update the given character in the game state.
    public func updateCharacter<Character: RpgCharacter>(_ character: Character) {
        updateAnyCharacter(character)
    }
}

extension Game {
    public func updateAnyTest(_ test: any RpgTestProtocol) {
        tests.upsert(AnyRpgTest(test))
    }

    public func updateTest<Test: RpgTestProtocol>(_ test: Test) {
        updateAnyTest(test)
    }

    public func anyTest(at ref: RpgTestRef) -> (any RpgTestProtocol)? {
        tests[ref]?.core
    }

    public func test<Test: RpgTestProtocol>(at ref: RpgTestRef, as type: Test.Type) -> Test? {
        tests[ref]?.core as? Test
    }
}

extension Game: NonLeafGenericListenerHolder, AllTheListenersHolder {
    public var childHolders: [Any] {
        characters.map { $0.core }
    }

    /// Why is it called naive? Because it only talks to the listeners that want something exactly like this. No narrow character mutation. If there was an event sent that included something for a character, none of the SelfListeners will be notified.
    public func naiveDispatch<T: HookTrigger>(_ hookTrigger: T) {
        for listener in allListeners {
            if listener.hook as? T == hookTrigger {
                listener.action(self)
            }
        }
    }

    public func naiveDispatch<T: HookTrigger>(
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

    public func naiveDispatch<T: HookTriggerForSomeRpgCharacter>(
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

    public func naiveDispatch<T: HookTriggerForSomeRpgCharacterAndTest>(
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
