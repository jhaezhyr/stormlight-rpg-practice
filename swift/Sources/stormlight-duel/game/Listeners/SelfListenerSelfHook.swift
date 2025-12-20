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

public protocol SelfListenerSelfHookProtocol {
    associatedtype Trigger: HookTriggerForSomeRpgCharacter
    associatedtype C: RpgCharacter
    var hook: Trigger { get }
    var action: ActionForRpgCharacter<C> { get }
}
extension SelfListenerSelfHookProtocol {
    func typeErasedAction(_ game: Game, _ character: any RpgCharacter) {
        if let wrappedCharacter = character as? AnyRpgCharacter {
            self.typeErasedAction(game, wrappedCharacter.core)
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

        self.action(game, characterToUse)
    }
}

public struct SelfListenerSelfHook<
    Trigger: HookTriggerForSomeRpgCharacter, Character: RpgCharacter
>:
    SelfListenerSelfHookProtocol
{
    public var hook: Trigger
    public var action: ActionForRpgCharacter<Character>
    func asListener(for characterRef: RpgCharacterRef) -> Listener<
        HookTriggerForSpecificRpgCharacter<Trigger>
    > {
        let specificHook = HookTriggerForSpecificRpgCharacter(hook, for: characterRef)
        return listen(to: specificHook) { game in
            guard let character = game.character(at: characterRef, as: Character.self) else {
                return
            }
            action(game, character)
        }
    }
}

func selfListen<Trigger: HookTriggerForSomeRpgCharacter, Character: RpgCharacter>(
    toMy hook: Trigger, as _: Character.Type, action: @escaping ActionForRpgCharacter<Character>
) -> SelfListenerSelfHook<Trigger, Character> {
    SelfListenerSelfHook(hook: hook, action: action)
}
