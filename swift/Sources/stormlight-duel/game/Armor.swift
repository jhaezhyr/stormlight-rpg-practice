public protocol Armor: Item {
    var deflect: Int { get }
    var traits: [(trait: any ArmorTrait, condition: TraitCondition)] { get }
}

public protocol ArmorTrait {}

public struct CumbersomeArmor: ArmorTrait {
    var minStrength: Int
}
public struct Presentable: ArmorTrait {}
public struct UniqueArmor: ArmorTrait {}
