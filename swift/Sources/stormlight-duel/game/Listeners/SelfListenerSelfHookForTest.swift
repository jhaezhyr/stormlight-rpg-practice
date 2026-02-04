public protocol SelfListenerSelfHookForTestHolder {
    var selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] { get }
    var allSelfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] { get }
    var debugAllSelfListenersSelfHooksForTests: [(String, any SelfListenerSelfHookForTestProtocol)]
    { get }
}
extension SelfListenerSelfHookForTestHolder {
    public var selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] { [] }
}
public protocol SelfListenerSelfHookForTestHolderLeaf: SelfListenerSelfHookForTestHolder {
}
extension SelfListenerSelfHookForTestHolderLeaf {
    public var allSelfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] {
        selfListenersSelfHooksForTests
    }
    public var debugAllSelfListenersSelfHooksForTests:
        [(String, any SelfListenerSelfHookForTestProtocol)]
    {
        allSelfListenersSelfHooksForTests.map { ("\(self)", $0) }
    }
}
extension NonLeafGenericListenerHolder where Self: SelfListenerSelfHookForTestHolder {
    public var allSelfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] {
        selfListenersSelfHooksForTests
            + childHolders.compactMap {
                ($0 as? any SelfListenerSelfHookForTestHolder)?.allSelfListenersSelfHooksForTests
            }.flatMap { $0 }
    }

    public var debugAllSelfListenersSelfHooksForTests:
        [(String, any SelfListenerSelfHookForTestProtocol)]
    {
        selfListenersSelfHooksForTests.map { ("\(self)", $0) }
            + childHolders.compactMap {
                ($0 as? any SelfListenerSelfHookForTestHolder)?
                    .debugAllSelfListenersSelfHooksForTests.map { str, lis in
                        ("\(str), \(self)", lis)
                    }
            }.flatMap { $0 }
    }
}

public protocol SelfListenerSelfHookForTestProtocol: Sendable {
    associatedtype Trigger: HookTriggerForSomeRpgCharacterAndTest
    associatedtype C: RpgCharacter
    associatedtype Test: RpgTest
    var id: ListenerId { get }
    var hook: Trigger { get }
    var action: ActionForRpgCharacterAndTest<C, Test> { get }
}
extension SelfListenerSelfHookForTestProtocol {
    func typeErasedAction(
        _ gameSession: isolated GameSession, _ character: any RpgCharacter, _ test: any RpgTest
    ) async {
        if let wrappedCharacter = character as? AnyRpgCharacter {
            await self.typeErasedAction(gameSession, wrappedCharacter.core, test)
            return
        }
        // If we get here, we don't have a wrapped character.
        if let wrappedTest = test as? AnyRpgTest {
            await self.typeErasedAction(gameSession, character, wrappedTest.core)
            return
        }
        // If we get here, we don't have a wrapped test.
        let characterToUse: C
        if C.self == AnyRpgCharacter.self {
            // We WANT a wrapped character. Nice.
            characterToUse = AnyRpgCharacter(character) as! C
        } else {
            guard let typeSafeCharacter = character as? C else {
                fatalError(
                    "You passed the wrong character type into the SelfListenerSelfHookProtocol. Needed \(C.self), got \(type(of: character))"
                )
            }
            characterToUse = typeSafeCharacter
        }
        let testToUse: Test
        if Test.self == AnyRpgTest.self {
            // We WANT a wrapped test.
            testToUse = AnyRpgTest(test) as! Test
        } else {
            guard let typeSafeTest = test as? Test else {
                fatalError(
                    "You passed the wrong test type into the SelfListenerSelfHookProtocol. Needed \(Test.self), got \(type(of: test))"
                )
            }
            testToUse = typeSafeTest
        }

        await self.action(gameSession, characterToUse, testToUse)
    }
}

public struct SelfListenerSelfHookForTest<
    Trigger: HookTriggerForSomeRpgCharacterAndTest,
    Character: RpgCharacter,
    Test: RpgTest
>: SelfListenerSelfHookForTestProtocol {
    public var id: ListenerId
    public var hook: Trigger
    public var action: ActionForRpgCharacterAndTest<Character, Test>
    func asListener(
        for characterRef: RpgCharacterRef, in testRef: RpgTestRef, ofTestType _: Test.Type
    ) -> Listener<
        HookTriggerForSpecificRpgCharacterAndTest<Trigger>
    > {
        let specificHook = HookTriggerForSpecificRpgCharacterAndTest(
            hook, for: characterRef)
        return Listener(id: id, hook: specificHook) { gameSession in
            guard let character = gameSession.game.character(at: characterRef, as: Character.self)
            else {
                return
            }
            guard let test = gameSession.game.test(at: testRef, as: Test.self) else {
                return
            }
            await action(gameSession, character, test)
        }
    }
}

extension GameSession {
    func selfListen<
        Trigger: HookTriggerForSomeRpgCharacterAndTest,
        Character: RpgCharacter,
        Test: RpgTest
    >(
        toMyTests hook: Trigger,
        as _: Character.Type,
        testType _: Test.Type,
        action: @escaping ActionForRpgCharacterAndTest<Character, Test>
    ) -> SelfListenerSelfHookForTest<Trigger, Character, Test> {
        SelfListenerSelfHookForTest(id: self.nextId(), hook: hook, action: action)
    }
}

public typealias ActionForRpgCharacterAndTest<Character: RpgCharacter, Test: RpgTest> =
    @Sendable (
        _ game: isolated GameSession, _ character: Character, _ test: Test
    ) async -> Void

public protocol HookTriggerForSomeRpgCharacterAndTest: Hashable, Sendable {}

public struct HookTriggerForSpecificRpgCharacterAndTest<
    T: HookTriggerForSomeRpgCharacterAndTest
>: HookTrigger {
    var characterRef: RpgCharacterRef
    var hookType: T
    init(_ hookType: T, for character: RpgCharacterRef) {
        self.hookType = hookType
        self.characterRef = character
    }
}
