public let basicWeapons:
    [WeaponName: @Sendable (_ gameSession: isolated GameSession) -> BasicWeapon] =
        [
            .axe: { gameSession in
                BasicWeapon(
                    weaponName: .axe,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .keen,
                    traits: [(Thrown(short: 20, long: 60), .always), (Offhand(), .expert)],
                    price: 20,
                    weight: 2,
                    in: gameSession
                )
            },
            .crossbow: { gameSession in
                BasicWeapon(
                    weaponName: .crossbow,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .ranged(short: 100, long: 400),
                    damage: .init(dice: [(.d8, 1)]),
                    damageType: .keen,
                    traits: [
                        (Loaded(ammunition: .init(value: 1, maxValue: 1)), .always),
                        (TwoHanded(), .always),
                        (Deadly(), .expert),
                    ],
                    price: 200,
                    weight: 7,
                    in: gameSession
                )
            },
            .grandbow: { gameSession in
                BasicWeapon(
                    weaponName: .grandbow,
                    type: .specialWeapons,
                    weaponsSkill: .heavy,
                    range: .ranged(short: 200, long: 800),
                    damage: .init(dice: [(.d6, 2)]),
                    damageType: .keen,
                    traits: [
                        (CumbersomeWeapon(minStrength: 5), .always),
                        (TwoHanded(), .always),
                        (Pierce(), .expert),
                    ],
                    price: 1000,
                    weight: 20,
                    in: gameSession
                )
            },
            .greatsword: { gameSession in
                BasicWeapon(
                    weaponName: .greatsword,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d10, 1)]),
                    damageType: .keen,
                    traits: [(TwoHanded(), .always), (Deadly(), .expert)],
                    price: 200,
                    weight: 7,
                    in: gameSession
                )
            },
            // TODO Half-shard
            .hammer: { gameSession in
                BasicWeapon(
                    weaponName: .hammer,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d10, 1)]),
                    damageType: .impact,
                    traits: [
                        (TwoHanded(), .always),
                        (Momentum(), .expert),
                    ],
                    price: 40,
                    weight: 8,
                    in: gameSession
                )
            },
            // TODO Hand Ballista
            // TODO Improvised weapon
            .javelin: { gameSession in
                BasicWeapon(
                    weaponName: .javelin,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .melee(),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .keen,
                    traits: [(Thrown(short: 30, long: 120), .always), (Indirect(), .expert)],
                    price: 20,
                    weight: 2,
                    in: gameSession
                )
            },
            .knife: { gameSession in
                BasicWeapon(
                    weaponName: .knife,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .melee(),
                    damage: .init(dice: [(.d4, 1)]),
                    damageType: .keen,
                    traits: [
                        (Discreet(), .always),
                        (Offhand(), .expert),
                        (Thrown(short: 20, long: 60), .expert),
                    ],
                    price: 8,
                    weight: 1,
                    in: gameSession
                )
            },
            .longbow: { gameSession in
                BasicWeapon(
                    weaponName: .longbow,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .ranged(short: 150, long: 600),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .keen,
                    traits: [
                        (TwoHanded(), .always),
                        (Indirect(), .expert),
                    ],
                    price: 100,
                    weight: 3,
                    in: gameSession
                )
            },
            .longspear: { gameSession in
                BasicWeapon(
                    weaponName: .longspear,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .melee(extraReach: 5),
                    damage: .init(dice: [(.d8, 1)]),
                    damageType: .keen,
                    traits: [
                        (TwoHanded(), .always),
                        (Defensive(), .expert),
                    ],
                    price: 15,
                    weight: 9,
                    in: gameSession
                )
            },
            .longsword: { gameSession in
                BasicWeapon(
                    weaponName: .longsword,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d8, 1)]),
                    damageType: .keen,
                    traits: [
                        (TwoHanded(), .notExpert),
                        (Quickdraw(), .always),
                        // TODO: Unique
                    ],
                    price: 60,
                    weight: 3,
                    in: gameSession
                )
            },
            .mace: { gameSession in
                BasicWeapon(
                    weaponName: .mace,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .melee(),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .impact,
                    traits: [
                        (Momentum(), .expert)
                    ],
                    price: 20,
                    weight: 3,
                    in: gameSession
                )
            },
            .poleaxe: { gameSession in
                BasicWeapon(
                    weaponName: .poleaxe,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d10, 1)]),
                    damageType: .keen,
                    traits: [
                        (TwoHanded(), .always)
                        // (RangeTrait(.melee(extraReach: 5)), .expert)
                        // TODO: Unique
                    ],
                    price: 40,
                    weight: 5,
                    in: gameSession
                )
            },
            .rapier: { gameSession in
                BasicWeapon(
                    weaponName: .rapier,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .melee(),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .keen,
                    traits: [
                        (Quickdraw(), .always),
                        (Defensive(), .expert),
                        // (RangeTrait(.melee(extraReach: 5)), .expert)
                        // TODO: Unique
                    ],
                    price: 100,
                    weight: 2,
                    in: gameSession
                )
            },
            // TODO Shardblade
            // TODO Shardblade (radiant)
            .shield: { gameSession in
                BasicWeapon(
                    weaponName: .shield,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d4, 1)]),
                    damageType: .impact,
                    traits: [
                        (Defensive(), .always),
                        (Offhand(), .expert),
                    ],
                    price: 10,
                    weight: 2,
                    in: gameSession
                )
            },
            .shortbow: { gameSession in
                BasicWeapon(
                    weaponName: .shortbow,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .ranged(short: 80, long: 320),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .impact,
                    traits: [
                        (TwoHanded(), .always),
                        (Quickdraw(), .expert),
                    ],
                    price: 80,
                    weight: 2,
                    in: gameSession
                )
            },
            .shortspear: { gameSession in
                BasicWeapon(
                    weaponName: .shortspear,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .melee(),
                    damage: .init(dice: [(.d8, 1)]),
                    damageType: .keen,
                    traits: [
                        (TwoHanded(), .notExpert)
                        // TODO Unique
                    ],
                    price: 10,
                    weight: 3,
                    in: gameSession
                )
            },
            .sidesword: { gameSession in
                BasicWeapon(
                    weaponName: .sidesword,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .melee(),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .keen,
                    traits: [
                        (Quickdraw(), .always),
                        (Offhand(), .always),
                    ],
                    price: 40,
                    weight: 2,
                    in: gameSession
                )
            },
            .sling: { gameSession in
                BasicWeapon(
                    weaponName: .sling,
                    type: .lightWeaponry,
                    weaponsSkill: .light,
                    range: .ranged(short: 30, long: 120),
                    damage: .init(dice: [(.d4, 1)]),
                    damageType: .impact,
                    traits: [
                        (Discreet(), .always),
                        (Indirect(), .expert),
                    ],
                    price: 2,
                    weight: 1,
                    in: gameSession
                )
            },
            .spikedShield: { gameSession in
                BasicWeapon(
                    weaponName: .spikedShield,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .keen,
                    traits: [
                        (CumbersomeWeapon(minStrength: 3), .always),
                        (Defensive(), .always),
                        (TwoHanded(), .notExpert),
                        (Momentum(), .expert),
                    ],
                    price: 50,
                    weight: 8,
                    in: gameSession
                )
            },
            .staff: { gameSession in
                BasicWeapon(
                    weaponName: .staff,
                    type: .heavyWeaponry,
                    weaponsSkill: .heavy,
                    range: .melee(),
                    damage: .init(dice: [(.d6, 1)]),
                    damageType: .impact,
                    traits: [
                        (Discreet(), .always),
                        (TwoHanded(), .always),
                        (Defensive(), .expert),
                    ],
                    price: 1,
                    weight: 4,
                    in: gameSession
                )
            },
            // TODO Unarmed attack
            // TODO Warhammer
        ]
