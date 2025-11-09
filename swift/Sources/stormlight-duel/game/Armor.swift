protocol Armor: Item {
    var deflect: Int { get }
    var traits: [(trait: any ArmorTrait, condition: TraitCondition)] { get }
}

protocol ArmorTrait {}

struct CumbersomeArmor: ArmorTrait {
    var minStrength: Int
}
struct Presentable: ArmorTrait {}
struct UniqueArmor: ArmorTrait {}
