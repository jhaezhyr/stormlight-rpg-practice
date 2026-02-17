/*
ARMOR_DATA = {
    "Uniform": {"deflect": 0, "traits": ["Presentable"]},
    "Leather": {"deflect": 1, "traits": []},
    "Chain": {"deflect": 2, "traits": ["Cumbersome [3]"]},
    "Breastplate": {"deflect": 2, "traits": ["Cumbersome [3]"]},
    "Half Plate": {"deflect": 3, "traits": ["Cumbersome [4]"]},
    "Full Plate": {"deflect": 4, "traits": ["Cumbersome [5]"]}
}
*/

enum BasicArmorTypes {
    static func uniform(in gameSession: isolated GameSession) -> BasicArmor {
        BasicArmor(
            price: 40, weight: 5, armorType: .uniform, deflect: 0,
            traits: [(trait: Presentable(), condition: .always)], in: gameSession)
    }
    static func leather(in gameSession: isolated GameSession) -> BasicArmor {
        BasicArmor(
            price: 60, weight: 10, armorType: .leather, deflect: 1,
            traits: [(trait: Presentable(), condition: .expert)], in: gameSession)
    }
    // TODO the rest
}
