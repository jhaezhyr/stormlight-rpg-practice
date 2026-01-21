public protocol SelfListenerSelfHookHolder {
    var selfListenersSelfHooks: [any SelfListenerSelfHookProtocol] { get }
    var allSelfListenersSelfHooks: [any SelfListenerSelfHookProtocol] { get }
}
extension SelfListenerSelfHookHolder {
    public var selfListenersSelfHooks: [any SelfListenerSelfHookProtocol] { [] }
}
public protocol SelfListenerSelfHookHolderLeaf: SelfListenerSelfHookHolder {
}
extension SelfListenerSelfHookHolderLeaf {
    public var allSelfListenersSelfHooks: [any SelfListenerSelfHookProtocol] {
        selfListenersSelfHooks
    }
}
extension NonLeafGenericListenerHolder where Self: SelfListenerSelfHookHolder {
    public var allSelfListenersSelfHooks: [any SelfListenerSelfHookProtocol] {
        selfListenersSelfHooks
            + childHolders.compactMap {
                ($0 as? any SelfListenerSelfHookHolder)?.allSelfListenersSelfHooks
            }.flatMap { $0 }
    }
}

public protocol SelfListenerSelfHookProtocol: Sendable {
    associatedtype Trigger: HookTriggerForSomeRpgCharacter
    associatedtype C: RpgCharacter
    var id: ListenerId { get }
    var hook: Trigger { get }
    var action: ActionForRpgCharacter<C> { get }
}
extension SelfListenerSelfHookProtocol {
    func typeErasedAction(_ gameSession: isolated GameSession, _ character: any RpgCharacter) async
    {
        if let wrappedCharacter = character as? AnyRpgCharacter {
            await self.typeErasedAction(gameSession, wrappedCharacter.core)
            return
        }
        // If we get here, we don't have a wrapped character.
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

        await self.action(gameSession, characterToUse)
    }
}

public struct SelfListenerSelfHook<
    Trigger: HookTriggerForSomeRpgCharacter, Character: RpgCharacter
>:
    SelfListenerSelfHookProtocol
{
    public var id: ListenerId
    public var hook: Trigger
    public var action: ActionForRpgCharacter<Character>
    func asListener(for characterRef: RpgCharacterRef) -> Listener<
        HookTriggerForSpecificRpgCharacter<Trigger>
    > {
        let specificHook = HookTriggerForSpecificRpgCharacter(hook, for: characterRef)
        return Listener(id: id, hook: specificHook) { gameSession in
            guard let character = gameSession.game.character(at: characterRef, as: Character.self)
            else {
                return
            }
            await action(gameSession, character)
        }
    }
}

extension GameSession {
    func selfListen<Trigger: HookTriggerForSomeRpgCharacter, Character: RpgCharacter>(
        toMy hook: Trigger, as _: Character.Type, action: @escaping ActionForRpgCharacter<Character>
    ) -> SelfListenerSelfHook<Trigger, Character> {
        SelfListenerSelfHook(id: self.nextId(), hook: hook, action: action)
    }
}
