public protocol SelfListenerHolder {
    var selfListeners: [any SelfListenerProtocol] { get }
    var allSelfListeners: [any SelfListenerProtocol] { get }
}
extension SelfListenerHolder {
    public var selfListeners: [any SelfListenerProtocol] { [] }
}
public protocol SelfListenerHolderLeaf: SelfListenerHolder {
}
extension SelfListenerHolderLeaf {
    public var allSelfListeners: [any SelfListenerProtocol] {
        selfListeners
    }
}
extension NonLeafGenericListenerHolder where Self: SelfListenerHolder {
    public var allSelfListeners: [any SelfListenerProtocol] {
        selfListeners
            + childHolders.compactMap { ($0 as? any SelfListenerHolder)?.allSelfListeners }.flatMap
        { $0 }
    }
}

public protocol SelfListenerProtocol {
    associatedtype Trigger: HookTrigger
    associatedtype C: RpgCharacter
    var hook: Trigger { get }
    var action: ActionForRpgCharacter<C> { get }
}
extension SelfListenerProtocol {
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

/// Creates a listener for a specific RPG character that performs the given action when the trigger occurs.
///
/// Useful so that conditions don't need to be tailored specifically to the character they apply to.
///
/// Gotcha! All modifications to the character must be done on the inout parameter passed to the action closure. After the action is performed, the updated character is saved back to the game state.
public struct SelfListener<Trigger: HookTrigger, Character: RpgCharacter>: SelfListenerProtocol {
    public var hook: Trigger
    public var action: ActionForRpgCharacter<Character>
    func asListener(for characterRef: RpgCharacterRef) -> Listener<Trigger> {
        listen(to: hook) { game in
            guard let character = game.character(at: characterRef, as: Character.self) else {
                return
            }
            action(game, character)
        }
    }
}

func selfListen<Trigger: HookTrigger, Character: RpgCharacter>(
    _ trigger: Trigger,
    action: @escaping ActionForRpgCharacter<Character>
) -> SelfListener<Trigger, Character> {
    SelfListener(hook: trigger, action: action)
}

public typealias ActionForRpgCharacter<Character: RpgCharacter> = (
    _ game: Game, _ character: Character
) -> Void

public protocol HookTriggerForSomeRpgCharacter: Hashable, Sendable {}

public struct HookTriggerForSpecificRpgCharacter<T: HookTriggerForSomeRpgCharacter>: HookTrigger {
    var characterRef: RpgCharacterRef
    var hookType: T
    init(_ hookType: T, for character: RpgCharacterRef) {
        self.hookType = hookType
        self.characterRef = character
    }
}
