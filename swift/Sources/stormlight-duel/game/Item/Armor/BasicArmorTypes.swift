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
    static func chain(in gameSession: isolated GameSession) -> BasicArmor {
        BasicArmor(
            price: 80, weight: 25, armorType: .chain, deflect: 2,
            traits: [
                (trait: CumbersomeArmor(minStrength: 3), condition: .notExpert)
                // TODO: Expert traits: Unique?
            ], in: gameSession)
    }
    static func breastplate(in gameSession: isolated GameSession) -> BasicArmor {
        BasicArmor(
            price: 120, weight: 30, armorType: .breastplate, deflect: 1,
            traits: [
                (trait: CumbersomeArmor(minStrength: 3), condition: .always),
                (trait: Presentable(), condition: .expert),
            ], in: gameSession)
    }
    static func halfPlate(in gameSession: isolated GameSession) -> BasicArmor {
        BasicArmor(
            price: 400, weight: 40, armorType: .halfPlate, deflect: 3,
            traits: [
                (trait: CumbersomeArmor(minStrength: 4), condition: .notExpert),
                (trait: CumbersomeArmor(minStrength: 3), condition: .expert),
                // TODO: Expert traits: Unique?
            ], in: gameSession)
    }
    static func fullPlate(in gameSession: isolated GameSession) -> BasicArmor {
        BasicArmor(
            price: 1600, weight: 55, armorType: .fullPlate, deflect: 4,
            traits: [(trait: CumbersomeArmor(minStrength: 5), condition: .always)], in: gameSession)
    }
    // TODO Shardplate
    // TODO Shardplate (Radiant)
}
