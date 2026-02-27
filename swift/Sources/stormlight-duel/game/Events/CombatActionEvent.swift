public struct CombatActionEvent: Event {
    public let characterRef: RpgCharacterRef
    public let action: any CombatAction

    public init(characterRef: RpgCharacterRef, action: any CombatAction) {
        self.characterRef = characterRef
        self.action = action
    }
}
