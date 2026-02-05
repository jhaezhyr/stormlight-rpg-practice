import Foundation
import stormlight_duel

struct CliRpgCharacterBrain: RpgCharacterBrain {
    let broadcaster: CliBroadcaster
    let characterRef: RpgCharacterRef

    init(broadcaster: CliBroadcaster, characterRef: RpgCharacterRef) {
        self.characterRef = characterRef
        self.broadcaster = broadcaster
    }

    @MainActor
    func decide<C: Sendable>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot) async
        -> C.Element
    where C: Collection, C.Element: Sendable {
        if let option = options.first, options.count == 1 {
            return option
        }
        try? await Task.sleep(for: .seconds(0.2))
        await printForCharacter(code)
        for (i, x) in options.enumerated() {
            print(">", i, x)
        }
        if let aLine = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
            let index = Int(aLine),
            index < options.count
        {
            let result = options[options.index(options.startIndex, offsetBy: index)]
            await printForCharacter("You chose \(result)")
            return result
        }
        await printForCharacter("No, try again.")
        return await decide(code, options: options, in: gameSnapshot)
    }

    @MainActor
    func decide<T: Sendable>(_ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot)
        async -> T
    where T: Sendable {
        try? await Task.sleep(for: .seconds(0.2))
        switch code {
        case .combatChoice:
            return await decideCombatChoice(in: gameSnapshot) as! T
        default:
            if let allCases = (T.self as? (any CaseIterable.Type))?.allCases {
                return await decide(code, options: allCases.map { $0 as! T }, in: gameSnapshot)
            }
            fatalError("I don't know how to decide when asked for \(type)")

        }
    }

    @MainActor
    private func decideCombatChoice(in gameSnapshot: GameSnapshot) async -> CombatChoice {
        guard let character = gameSnapshot.characters[characterRef] else {
            fatalError("Bad character ref \(characterRef)")
        }
        await printForCharacter(
            "You have \(character.combatState!.actionsRemaining) actions. What is your combat choice?"
        )
        let actionsICanTake = allCombatActions.filter {
            $0.canMaybeTakeAction(by: character.primaryKey, in: gameSnapshot)
        }
        for action in actionsICanTake {
            if let action = action as? (CliArgsConvertibleType & CombatAction).Type {
                print(">", action.helpText)
            } else {
                print(">", action.actionName, "(coming soon)")
            }
        }
        print("> (e)nd")
        let line = readLine()!.trimmingCharacters(in: .whitespacesAndNewlines)
        let args: [Any] = line.split(separator: " ")
        do {
            for action in actionsICanTake {
                if let parseAction = (action as? (CliArgsConvertibleType & CombatAction).Type)?
                    .init,
                    let action = try parseAction(
                        args, (game: gameSnapshot, characterRef: characterRef))
                {
                    if action.canTakeAction(by: characterRef, in: gameSnapshot) {
                        await printForCharacter("Your action is \(action)")
                        return .action(action)
                    }
                }
            }
            if ["e", "end", "end turn"].contains(line) {
                await printForCharacter("I guess your turn is over")
                return .endTurn
            }
            await printForCharacter("No, try again.")
        } catch {
            await printForCharacter(error.description)
        }
        return await decideCombatChoice(in: gameSnapshot)
    }

    @MainActor
    private func printForCharacter(_ thing: Any) async {
        await broadcaster.tell("\(thing)", to: characterRef)
    }
}

struct CliParseError: Error {
    var description: Substring

    init(_ description: Substring) {
        self.description = description
    }
}

typealias CliArgsConversionContext = (game: GameSnapshot, characterRef: RpgCharacterRef)

/// The CLI input might look like this:
/// - move 15 back
/// - strike
protocol CliArgsConvertibleType {
    /// If it returns nil, it means it's not even trying to be this type.
    /// If it throws, it means it is trying to be this type, but it's wrong.
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError)
    static var helpText: Substring { get }
}

protocol CliArgsContextFreeConvertibleType: CliArgsConvertibleType {
    init?(args: [Any]) throws(CliParseError)
}
extension CliArgsContextFreeConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        try self.init(args: args)
    }
}

extension InteractiveMove: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedMove = args.first as? InteractiveMove, args.count == 1 {
            self = alreadyParsedMove
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "m" || firstArgAsString == "move"
        else {
            return nil
        }
        self.init()
    }

    static var helpText: Substring { "(m)ove [\(Distance.helpText)]" }
}

extension Strike: CliArgsConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsedStrike = args.first as? Strike, args.count == 1 {
            self = alreadyParsedStrike
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "k" || firstArgAsString == "strike"
        else {
            return nil
        }
        var target: RpgCharacterRef?
        var weaponToStrikeWith: ItemRef?
        guard let contextCharacter = context.game.characters[context.characterRef] else {
            throw CliParseError("Bad character ref \(context.characterRef)")
        }
        for arg in remaining {
            if let targetArg = try RpgCharacterRef(args: [arg], context: context), target == nil {
                target = targetArg
            } else if let weaponArg = try WeaponName(args: [arg], context: context),
                weaponToStrikeWith == nil
            {
                let weaponToStrikeWithCandidates = contextCharacter.equipment.filter {
                    ($0.core as? any Weapon)?.weaponName == weaponArg
                }
                if weaponToStrikeWithCandidates.count == 0 {
                    throw CliParseError("\(arg) is not a weapon that \(contextCharacter.name) has")
                } else if weaponToStrikeWithCandidates.count > 1 {
                    let readyWeaponCandidates = weaponToStrikeWithCandidates.filter { $0.isReady }
                    if readyWeaponCandidates.count != 1 {
                        throw CliParseError(
                            "\(arg) is a weapon that \(contextCharacter.name) has two or more of, and \(readyWeaponCandidates.count) are ready"
                        )
                    } else {
                        weaponToStrikeWith = readyWeaponCandidates[0].primaryKey
                    }
                } else {
                    weaponToStrikeWith = weaponToStrikeWithCandidates[0].primaryKey
                }
            } else {
                throw CliParseError("\(arg) not a target or weapon name")
            }
        }
        // What if the target wasn't provided?
        let realTarget: RpgCharacterRef = try
            ({ (x: ()) throws(CliParseError) in
                if let target {
                    return target
                } else {
                    let characters = context.game.characters
                    let viableTargets = characters.filter {
                        $0.primaryKey != contextCharacter.primaryKey && $0.health.value > 0
                    }
                    if viableTargets.count != 1 {
                        throw CliParseError(
                            "It seems \(contextCharacter.name) has \(viableTargets.count) available targets: \(viableTargets)"
                        )
                    }
                    return viableTargets[0].primaryKey
                }
            })(())
        let realWeapon: ItemRef = try
            ({ (x: ()) throws(CliParseError) in
                if let weaponToStrikeWith {
                    return weaponToStrikeWith
                } else {
                    let equipment = contextCharacter.equipment
                    let viableWeapons = equipment.filter {
                        $0.isReady && $0.core.core is any WeaponSnapshot
                    }
                    if viableWeapons.count != 1 {
                        throw CliParseError(
                            "It seems \(contextCharacter.name) has \(viableWeapons.count) ready weapons: \(viableWeapons)"
                        )
                    }
                    return viableWeapons[0].primaryKey
                }
            })(())
        self.init(realTarget, with: realWeapon)
    }

    public static var helpText: Substring { "stri(k)e [target] [weapon]" }
}

extension GainAdvantage: CliArgsConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsedGainAdvantage = args.first as? Self, args.count == 1 {
            self = alreadyParsedGainAdvantage
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "g" || firstArgAsString == "gainadv"
        else {
            return nil
        }
        var target: RpgCharacterRef?
        var skill: CoreSkillName?
        guard let contextCharacter = context.game.characters[context.characterRef] else {
            throw CliParseError("Bad character ref \(context.characterRef)")
        }
        for arg in remaining {
            if let skillArg = try CoreSkillName(args: [arg], context: context), skill == nil {
                skill = skillArg
            } else if let targetArg = try RpgCharacterRef(args: [arg], context: context),
                target == nil
            {
                target = targetArg
            } else {
                throw CliParseError("\(arg) not a target or core skill")
            }
        }
        // What if the target wasn't provided?
        let realTarget: RpgCharacterRef = try
            ({ (x: ()) throws(CliParseError) in
                if let target {
                    return target
                } else {
                    let characters = context.game.characters
                    let viableTargets = characters.filter {
                        $0.primaryKey != contextCharacter.primaryKey && $0.health.value > 0
                    }
                    if viableTargets.count != 1 {
                        throw CliParseError(
                            "It seems \(contextCharacter.name) has \(viableTargets.count) available targets: \(viableTargets)"
                        )
                    }
                    return viableTargets[0].primaryKey
                }
            })(())
        let realSkill: CoreSkillName = try { (x: ()) throws(CliParseError) in
            if let skill {
                return skill
            }
            throw CliParseError("No skill was chosen for the Gain Advantage action.")
        }(())
        self.init(opponent: realTarget, skill: realSkill)
    }

    static var helpText: Substring {
        "(g)ainadv [skill] [target]"
    }
}

extension CoreSkillName: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedSkill = args.first as? Self, args.count == 1 {
            self = alreadyParsedSkill
            return
        }
        if let string = args.first as? Substring,
            let skill = CoreSkillName(rawValue: String(string))
        {
            self = skill
            return
        }
        throw CliParseError("\(args) is not a core skill")
    }

    static var helpText: Substring {
        "<core skill>"
    }
}

// TODO Make distance a wrapper around a number
extension Int: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedNumber = args.first as? Distance, args.count == 1 {
            self = alreadyParsedNumber
            return
        }
        if let string = args.first as? Substring, let int = Int(string) {
            self = int
            return
        }
        throw CliParseError("\(args) is not a number")
    }

    static var helpText: Substring { "###" }
}

extension RpgCharacterRef: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedName = args.first as? RpgCharacterRef, args.count == 1 {
            self = alreadyParsedName
            return
        }
        if let string = args.first as? Substring {
            self = RpgCharacterRef(name: String(string))
            return
        }
        throw CliParseError("\(args) is not a name")
    }
    static var helpText: Substring { "<character>" }
}

extension WeaponName: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedName = args.first as? WeaponName, args.count == 1 {
            self = alreadyParsedName
            return
        }
        if let string = args.first as? Substring,
            let weaponName = WeaponName(rawValue: String(string))
        {
            self = weaponName
            return
        }
        throw CliParseError("\(args) is not a weapon name")
    }
    static var helpText: Substring { "<weapon>" }
}

extension Recover: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "r" || firstArgAsString == "recover"
        else {
            return nil
        }
        self.init()
    }

    static var helpText: Substring {
        "(r)ecover"
    }
}
