public protocol Armor: Item {
    var deflect: Int { get }
    var traits: [(trait: any ArmorTrait, condition: TraitCondition)] { get }
}

public protocol ArmorTrait {}
