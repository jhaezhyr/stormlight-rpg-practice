public protocol SelfListenerSelfHookForTestHolder {
    var selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] { get }
    var allSelfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] { get }
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
}
extension NonLeafGenericListenerHolder where Self: SelfListenerSelfHookForTestHolder {
    public var allSelfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] {
        selfListenersSelfHooksForTests
            + childHolders.compactMap {
                ($0 as? any SelfListenerSelfHookForTestHolder)?.allSelfListenersSelfHooksForTests
            }.flatMap { $0 }
    }
}

public protocol SelfListenerSelfHookForTestProtocol {
    associatedtype Trigger: HookTriggerForSomeRpgCharacterAndTest
    associatedtype C: RpgCharacter
    associatedtype Test: RpgTestProtocol
    var id: ListenerId { get }
    var hook: Trigger { get }
    var action: ActionForRpgCharacterAndTest<C, Test> { get }
}
extension SelfListenerSelfHookForTestProtocol {
    func typeErasedAction(
        _ game: Game, _ character: any RpgCharacter, _ test: any RpgTestProtocol
    ) {
        if let wrappedCharacter = character as? AnyRpgCharacter {
            self.typeErasedAction(game, wrappedCharacter.core, test)
            return
        }
        // If we get here, we don't have a wrapped character.
        if let wrappedTest = test as? AnyRpgTest {
            self.typeErasedAction(game, character, wrappedTest.core)
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
                    "You passed the wrong character type into the SelfListenerSelfHookProtocol")
            }
            characterToUse = typeSafeCharacter
        }
        let testToUse: Test
        if C.self == AnyRpgTest.self {
            // We WANT a wrapped test.
            testToUse = AnyRpgTest(test) as! Test
        } else {
            guard let typeSafeTest = test as? Test else {
                fatalError(
                    "You passed the wrong test type into the SelfListenerSelfHookProtocol")
            }
            testToUse = typeSafeTest
        }

        self.action(game, characterToUse, testToUse)
    }
}

public struct SelfListenerSelfHookForTest<
    Trigger: HookTriggerForSomeRpgCharacterAndTest, Character: RpgCharacter, Test: RpgTestProtocol
>: SelfListenerSelfHookForTestProtocol {
    public var id: ListenerId = nextListenerId()
    public var hook: Trigger
    public var action: ActionForRpgCharacterAndTest<Character, Test>
    func asListener(
        for characterRef: RpgCharacterRef, in testRef: RpgTestRef, ofTestType _: Test.Type
    ) -> Listener<
        HookTriggerForSpecificRpgCharacterAndTest<Trigger>
    > {
        let specificHook = HookTriggerForSpecificRpgCharacterAndTest(
            hook, for: characterRef)
        return Listener(id: id, hook: specificHook) { game in
            guard let character = game.character(at: characterRef, as: Character.self) else {
                return
            }
            guard let test = game.test(at: testRef, as: Test.self) else {
                return
            }
            action(game, character, test)
        }
    }
}

func selfListen<
    Trigger: HookTriggerForSomeRpgCharacterAndTest,
    Character: RpgCharacter,
    Test: RpgTestProtocol
>(
    toMyTests hook: Trigger,
    as _: Character.Type,
    testType _: Test.Type,
    action: @escaping ActionForRpgCharacterAndTest<Character, Test>
) -> SelfListenerSelfHookForTest<Trigger, Character, Test> {
    SelfListenerSelfHookForTest(hook: hook, action: action)
}

public typealias ActionForRpgCharacterAndTest<Character: RpgCharacter, Test: RpgTestProtocol> = (
    _ game: Game, _ character: Character, _ test: Test
) -> Void

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
