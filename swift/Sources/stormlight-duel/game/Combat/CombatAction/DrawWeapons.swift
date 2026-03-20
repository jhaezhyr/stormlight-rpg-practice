public struct InteractiveDrawWeapons: CombatAction {
    public static var canBeTakenMoreThanOncePerTurn: Bool { true }
    public init() {}
    public static func actionCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Int
    {
        guard let character = gameSnapshot.characters[characterRef] else {
            return 1
        }
        if character.features.contains(where: { $0.name == MinionFeature.name }) {
            return 0
        } else {
            return 1
        }
    }
    public func action(
        by characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation,
    ) async throws {
        guard var character = gameSession.game.anyCharacter(at: characterRef) else {
            return
        }
        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                w1: "$1 puts away their current weapons and draws new ones.",
                wU: "You put away your current weapons and draw new ones.",
                as1: characterRef
            )
        )
        if let mainHandWeaponRef = character.mainHand,
            let mainHandReadyable = character.equipment[mainHandWeaponRef]
        {
            character.mainHand = nil
            character.equipment[mainHandWeaponRef] = Readyable(
                mainHandReadyable.core, isReady: false)
        }
        if let offHandWeaponRef = character.offHand,
            let offHandReadyable = character.equipment[offHandWeaponRef]
        {
            character.offHand = nil
            character.equipment[offHandWeaponRef] = Readyable(
                offHandReadyable.core, isReady: false)
        }
        for hand in Hand.allCases {
            let weapons = character.equipment.filter({ !$0.isReady }).compactMap({
                $0.core.core as? any Weapon
            })
            let weaponsICanWield = weapons.isolatedCompactMap(in: gameSession) { w, gameSession in
                w.canReady(by: characterRef, preferredHand: hand).map { hands in (w, hands) }
            }
            let snapshot = gameSession.game.snapshot()
            let decisions: [DrawWeaponDecision] =
                weaponsICanWield.isolatedMap { (tuple, gameSession: isolated GameSession) in
                    .weapon(
                        DrawWeaponPositiveDecision(
                            weaponId: tuple.0.primaryKey,
                            isTwoHanded: tuple.1.count == 2,
                            isQuickdraw: tuple.0.activeTraits(
                                whenEquippedBy: characterRef, in: snapshot
                            )
                            .contains(
                                where: { $0 is Quickdraw }),
                            hasOffhandTrait: tuple.0.activeTraits(
                                whenEquippedBy: characterRef, in: snapshot
                            )
                            .contains(
                                where: { $0 is Offhand })))
                } + [.none]
            let drawWeaponDecision = try await character.brain.decide(
                DecisionCode.drawWeaponsChoice(hand),
                options: decisions,
                in: gameSession.game.snapshot()
            )
            switch drawWeaponDecision {
            case .none:
                break
            case .weapon(let weapon):
                guard
                    let weapon = character.equipment.first(where: {
                        $0.primaryKey == weapon.weaponId
                    })?.core.core as? any Weapon
                else {
                    continue
                }
                weapon.ready(by: character, preferredHand: hand)
            }
        }
        if character.offHand == character.mainHand {
            await gameSession.game.broadcaster.tellAll(
                SingleTargetMessage(
                    w1:
                        "$1 is now holding \(character.mainHand?.name ?? "nothing") in their hands.",
                    wU:
                        "You are now holding \(character.mainHand?.name ?? "nothing") in your hands.",
                    as1: characterRef
                )
            )
        } else {
            await gameSession.game.broadcaster.tellAll(
                SingleTargetMessage(
                    w1:
                        "$1 is now holding \(character.mainHand?.name ?? "nothing") in their main hand and \(character.offHand?.name ?? "nothing") in their off hand.",
                    wU:
                        "You are now holding \(character.mainHand?.name ?? "nothing") in your main hand and \(character.offHand?.name ?? "nothing") in your off hand.",
                    as1: characterRef
                )
            )
        }
    }
}

public struct DrawWeaponPositiveDecision: Sendable {
    var weaponId: ItemRef
    var isTwoHanded: Bool
    var isQuickdraw: Bool
    var hasOffhandTrait: Bool
}
extension DrawWeaponPositiveDecision: CustomStringConvertible {
    public var description: String {
        "\(weaponId)"
            + (isTwoHanded ? " (two handed)" : "")
            + (isQuickdraw ? " (quickdraw)" : "")
            + (hasOffhandTrait ? " (offhand)" : "")
    }
}
public enum DrawWeaponDecision: Sendable {
    case weapon(DrawWeaponPositiveDecision)
    case none
}
extension DrawWeaponDecision: CustomStringConvertible {
    public var description: String {
        switch self {
        case .weapon(let x): "\(x)"
        case .none: "nothing"
        }
    }
}

/*
# Experience
You have the following weapons available to you. Which will go in your main hand?
:1 longsword (two-handed)
:2 javelin 1
:3 javelin 2
:4 javelin 3
:0 nothing

<If you pick a single-handed weapon>
You have the following weapons available to you. Which will go in your off hand?
:1 javelin 2
:2 javelin 3
:0 nothing

<If you instead picked the double-handed weapon, it ends there>
*/
