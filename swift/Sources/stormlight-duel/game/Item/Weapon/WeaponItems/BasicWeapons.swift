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
        ]
