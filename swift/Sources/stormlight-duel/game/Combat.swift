public struct Damage: Equatable, Hashable {
    public var amount: Int
    public var realm: Realm

    public init(_ amount: Int, realm: Realm) {
        self.amount = amount
        self.realm = realm
    }
}

public enum CombatPhase: HookTriggerForSomeRpgCharacter {
    case endOfTurn
}
