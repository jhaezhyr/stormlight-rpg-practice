import KeyedSet

public protocol GameSharedProtocol {
    associatedtype CharacterType: RpgCharacterSharedProtocol
    associatedtype TestType: RpgTestSharedProtocol
    var characters: KeyedSet<CharacterType> { get }
    var tests: KeyedSet<TestType> { get }
    var scene: Scene? { get }
}

public class Game {
    public var characters: KeyedSet<AnyRpgCharacter>
    public var tests: KeyedSet<AnyRpgTest> = []
    public var scene: Scene?

    public var rng: any RandomNumberGenerator = SystemRandomNumberGenerator()
    public var broadcaster: Broadcaster
    public var gameMasterBrain: any GameMasterBrain

    public init(
        characters: [any RpgCharacter],
        broadcaster: Broadcaster,
        gameMasterBrain: any GameMasterBrain
    ) {
        self.characters = KeyedSet(characters.map(AnyRpgCharacter.init))
        self.broadcaster = broadcaster
        self.gameMasterBrain = gameMasterBrain
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

    public func removeTest(_ test: any RpgTest) {
        tests.remove(test.primaryKey)
    }
}

extension Game: Responder {
    public var childResponders: [any Responder] {
        characters.map { $0.core }
    }

    public func dispatch(_ event: Event?, in gameSession: isolated GameSession = #isolation)
        async throws
    {
        if let event {
            try await respondAndPassOn(to: event, in: gameSession)
        }
    }
}
