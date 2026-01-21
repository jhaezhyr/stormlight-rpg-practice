public protocol GameSharedProtocol {
    associatedtype CharacterType: RpgCharacterSharedProtocol
    associatedtype TestType: RpgTestSharedProtocol
    var characters: KeyedSet<CharacterType> { get }
    var tests: KeyedSet<TestType> { get }
}

public class Game {
    public var characters: KeyedSet<AnyRpgCharacter>
    public var tests: KeyedSet<AnyRpgTest> = []

    public var rng: any RandomNumberGenerator = SystemRandomNumberGenerator()
    public var broadcaster: any Broadcaster

    public init(characters: [any RpgCharacter], broadcaster: Broadcaster) {
        self.characters = KeyedSet(characters.map(AnyRpgCharacter.init))
        self.broadcaster = broadcaster
    }
}

extension GameSharedProtocol {

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
    public func character<Character: RpgCharacter>(
        at ref: RpgCharacterRef, as type: Character.Type
    )
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
    public func updateAnyTest(_ test: any RpgTest) {
        tests.upsert(AnyRpgTest(test))
    }

    public func updateTest<Test: RpgTest>(_ test: Test) {
        updateAnyTest(test)
    }

    public func anyTest(at ref: RpgTestRef) -> (any RpgTest)? {
        tests[ref]?.core
    }

    public func test<Test: RpgTest>(at ref: RpgTestRef, as type: Test.Type) -> Test? {
        tests[ref]?.core as? Test
    }
}

extension Game: NonLeafGenericListenerHolder, AllTheListenersHolder {
    public var childHolders: [Any] {
        characters.map { $0.core }
    }

    /// Why is it called naive? Because it only talks to the listeners that want something exactly like this. No narrow character mutation. If there was an event sent that included something for a character, none of the SelfListeners will be notified.
    public func naiveDispatch<T: HookTrigger>(
        _ hookTrigger: T, in gameSession: isolated GameSession
    ) async {
        var listenersRun: Set<ListenerId> = []
        while let listenerLeftToTry = allListeners.filter({
            $0.hook as? T == hookTrigger && !listenersRun.contains($0.id)
        }).first {
            // Getting this every time means we can add new listeners in response to listeners.
            await listenerLeftToTry.action(gameSession)
            listenersRun.insert(listenerLeftToTry.id)
        }
    }

    public func naiveDispatch<T: HookTrigger>(
        _ hookTrigger: T, for characterRef: RpgCharacterRef, in gameSession: isolated GameSession
    ) async {
        var listenersRun: Set<ListenerId> = []
        while let listenerLeftToTry = allSelfListeners.filter({
            $0.hook as? T == hookTrigger && !listenersRun.contains($0.id)
        }).first {
            guard let char = self.anyCharacter(at: characterRef) else {
                fatalError("Bad character reference")
            }
            await listenerLeftToTry.typeErasedAction(gameSession, char)
            listenersRun.insert(listenerLeftToTry.id)
        }
    }

    public func naiveDispatch<T: HookTriggerForSomeRpgCharacter>(
        _ hookTrigger: T, for characterRef: RpgCharacterRef, in gameSession: isolated GameSession
    ) async {
        var listenersRun: Set<ListenerId> = []
        while let listenerLeftToTry = allSelfListenersSelfHooks.filter({
            $0.hook as? T == hookTrigger && !listenersRun.contains($0.id)
        }).first {
            guard let char = self.anyCharacter(at: characterRef) else {
                fatalError("Bad character reference")
            }
            await listenerLeftToTry.typeErasedAction(gameSession, char)
            listenersRun.insert(listenerLeftToTry.id)

        }
    }

    public func naiveDispatch<T: HookTriggerForSomeRpgCharacterAndTest>(
        _ hookTrigger: T, for characterRef: RpgCharacterRef, attempting testRef: RpgTestRef,
        in gameSession: isolated GameSession
    ) async {
        var listenersRun: Set<ListenerId> = []
        while let listenerLeftToTry = allSelfListenersSelfHooksForTests.filter({
            $0.hook as? T == hookTrigger && !listenersRun.contains($0.id)
        }).first {
            guard let char = self.anyCharacter(at: characterRef) else {
                fatalError("Bad character reference")
            }
            guard let test = self.anyTest(at: testRef) else {
                fatalError("Bad test reference")
            }
            await listenerLeftToTry.typeErasedAction(gameSession, char, test)
            listenersRun.insert(listenerLeftToTry.id)
        }
    }
}
