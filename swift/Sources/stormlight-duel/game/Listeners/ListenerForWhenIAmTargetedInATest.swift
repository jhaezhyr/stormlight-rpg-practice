public protocol ListenerForWhenIAmTargetedInATestHolder {
    var listenersForWhenIAmTargetedInATest: [any ListenerForWhenIAmTargetedInATestProtocol] { get }
    var allListenersForWhenIAmTargetedInATest: [any ListenerForWhenIAmTargetedInATestProtocol] {
        get
    }
    var debugAllListenersForWhenIAmTargetedInATest:
        [(String, any ListenerForWhenIAmTargetedInATestProtocol)]
    { get }
}
extension ListenerForWhenIAmTargetedInATestHolder {
    public var listenersForWhenIAmTargetedInATest: [any ListenerForWhenIAmTargetedInATestProtocol] {
        []
    }
}
public protocol ListenerForWhenIAmTargetedInATestHolderLeaf:
    ListenerForWhenIAmTargetedInATestHolder
{
}
extension ListenerForWhenIAmTargetedInATestHolderLeaf {
    public var allListenersForWhenIAmTargetedInATest:
        [any ListenerForWhenIAmTargetedInATestProtocol]
    {
        listenersForWhenIAmTargetedInATest
    }
    public var debugAllListenersForWhenIAmTargetedInATest:
        [(String, any ListenerForWhenIAmTargetedInATestProtocol)]
    {
        listenersForWhenIAmTargetedInATest.map { ("\(self)", $0) }
    }
}
extension NonLeafGenericListenerHolder where Self: ListenerForWhenIAmTargetedInATestHolder {
    public var allListenersForWhenIAmTargetedInATest:
        [any ListenerForWhenIAmTargetedInATestProtocol]
    {
        listenersForWhenIAmTargetedInATest
            + childHolders.compactMap {
                ($0 as? any ListenerForWhenIAmTargetedInATestHolder)?
                    .allListenersForWhenIAmTargetedInATest
            }.flatMap { $0 }
    }

    public var debugAllListenersForWhenIAmTargetedInATest:
        [(String, any ListenerForWhenIAmTargetedInATestProtocol)]
    {
        listenersForWhenIAmTargetedInATest.map { ("\(self)", $0) }
            + childHolders.compactMap {
                ($0 as? any ListenerForWhenIAmTargetedInATestHolder)?
                    .debugAllListenersForWhenIAmTargetedInATest.map { str, lis in
                        ("\(str), \(self)", lis)
                    }
            }.flatMap { $0 }
    }
}

public protocol ListenerForWhenIAmTargetedInATestProtocol: Sendable {
    associatedtype Trigger: HookTriggerForSomeRpgCharacterAndTest
    associatedtype C: RpgCharacter
    associatedtype Test: RpgTest
    var id: ListenerId { get }
    var hook: Trigger { get }
    var action: ActionForRpgCharacterAndTest<C, Test> { get }
}
extension ListenerForWhenIAmTargetedInATestProtocol {
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

        await self.action(gameSession, characterToUse, testToUse)
    }
}

public struct ListenerForWhenIAmTargetedInATest<
    Trigger: HookTriggerForSomeRpgCharacterAndTest,
    Character: RpgCharacter,
    Test: RpgTest
>: ListenerForWhenIAmTargetedInATestProtocol {
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
        toTestsWhereIAmTargeted hook: Trigger,
        as _: Character.Type,
        testType _: Test.Type,
        action: @escaping ActionForRpgCharacterAndTest<Character, Test>
    ) -> ListenerForWhenIAmTargetedInATest<Trigger, Character, Test> {
        ListenerForWhenIAmTargetedInATest(id: self.nextId(), hook: hook, action: action)
    }
}
