import Foundation
import stormlight_duel

struct CliRpgCharacterBrain: RpgCharacterBrain {
    let characterRef: RpgCharacterRef

    init(characterRef: RpgCharacterRef) {
        self.characterRef = characterRef
    }

    @MainActor
    func decide<C: Sendable>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot) async
        -> C.Element
    where C: Collection, C.Element: Sendable {
        if let option = options.first, options.count == 1 {
            return option
        }
        let parsers: [any CliArgsParserProtocol]
        if let parser = (C.Element.self as? CliArgsConvertibleType.Type)?.anyParser {
            parsers = [parser]
        } else {
            parsers = []
        }
        let extraInterface: [String] = getExtraInterfaceForDecision(
            code, type: C.Element.self, in: gameSnapshot)
        return await decideBetweenOptions(
            Array(options),
            prompt: "\(code)",
            extraInterface: extraInterface,
            parsers: parsers,
            in: gameSnapshot,
        )
    }

    /// Grab an option from `options`.
    ///
    /// HUD: Prints the prompt and the options. Reprints it if the user's input is invalid.
    /// INPUT: Numbers get translated to 1-based indices of `options`. Any other inputs can be parsed using the parsers in `parseableClasses`.
    @MainActor
    private func decideBetweenOptions<T: Sendable>(
        _ options: [T]?,
        prompt: String,
        extraInterface: [String] = [],
        parsers: [any CliArgsParserProtocol] = [],
        displayParseableClassesInHud: Bool = false,
        in gameSnapshot: GameSnapshot,
    ) async -> T {
        await printHUD(prompt)
        for extra in extraInterface {
            await printHUD(extra)
        }
        if let options {
            for (i, x) in options.enumerated() {
                await printHUD(":\(i + 1) \(x)")
            }
        }
        if displayParseableClassesInHud {
            for parser in parsers {
                await printHUD(":\(parser.helpText)")
            }
        }
        choiceLoop: while true {
            guard let aLine = read()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                await printHUD("Couldn't read that input.")
                continue
            }
            let (args, context) = (aLine.split(separator: " "), (gameSnapshot, characterRef))
            do {
                if let statusCommand = try StatusCommand.parser.parse(args: args, context: context)
                {
                    await printHUD(statusCommand.evaluate(in: gameSnapshot, for: characterRef))
                    continue choiceLoop
                }
            } catch {
                await printHUD(error.description)
                continue choiceLoop
            }
            var result: T?
            if let options,
                let index = Int(aLine).map({ $0 - 1 }),
                index < options.count && index >= 0
            {
                result = options[options.index(options.startIndex, offsetBy: index)]
            } else {
                for parser in parsers {
                    do {
                        if let anyParsedResult = try parser.parse(
                            args: args, context: context
                        ) {
                            if let parsedResult = anyParsedResult as? T {
                                result = parsedResult
                            }
                        }
                    } catch {
                        await printHUD(
                            "\"\(aLine)\" is an invalid \(parser.helpText). \(error.description)")
                    }
                }
            }
            if let result {
                if let options {
                    if let optionsWithContains = options as? ContainsAny,
                        optionsWithContains.containsAny(result)
                    {
                        await printHUD("You chose \(result)")
                        return result
                    } else {
                        await printHUD("You chose \(result), but that is not a valid choice.")
                        continue
                    }
                } else {
                    return result
                }
            } else {
                if let options {
                    await printHUD(
                        "\(aLine) is not a valid choice. Pick a number from 1 to \(options.count)."
                    )
                } else {
                    await printHUD("\(aLine) is not a valid choice.")
                }
            }
        }
    }

    @MainActor
    func read() -> String? {
        print("  > ", terminator: "")
        return readLine()
    }

    @MainActor
    func decide<T: Sendable>(_ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot)
        async -> T
    where T: Sendable {
        switch code {
        case .combatChoice:
            return await decideCombatChoice2(in: gameSnapshot) as! T
        default:
            if let allCases = (T.self as? (any CaseIterable.Type))?.allCases {
                return await decide(code, options: allCases.map { $0 as! T }, in: gameSnapshot)
            }
            fatalError("I don't know how to decide when asked for \(type)")
        }
    }

    @MainActor
    func getExtraInterfaceForDecision<T>(
        _ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot
    ) -> [String] {
        switch code {
        case .directionToMove5Ft:
            return [(gameSnapshot.scene as! Combat).map.oneLineDescription(in: gameSnapshot)]
        default: return []
        }
    }

    @MainActor
    private func printForCharacter(_ thing: Any) async {
        try? await Task.sleep(for: .seconds(0.05))
        print("\(characterRef.name): \(thing)")
    }

    @MainActor
    private func printHUD(_ thing: Any) async {
        try? await Task.sleep(for: .seconds(0.05))
        print("\(thing)")
    }

    @MainActor
    func hear<M>(_ message: M, in gameSnapshot: GameSnapshot) async where M: Message {
        let messageDescription = message.description(for: characterRef)
        await printForCharacter(messageDescription)
        if messageDescription.contains("ROUND") {
            await printHUD(StatusCommand.general.evaluate(in: gameSnapshot, for: characterRef))
        }
    }

    @MainActor func hearHint(_ message: String, in gameSnapshot: GameSnapshot) async {
        await printForCharacter(message)
    }
}

private protocol ContainsAny {
    /// If this container can compare elements, this is equivalent to `contains`. Otherwise, it returns nil.
    func containsAny(_ x: Any) -> Bool
}
extension Array: ContainsAny where Element: Equatable {
    func containsAny(_ x: Any) -> Bool {
        if let x = x as? Element {
            return self.contains(x)
        }
        return false
    }
}

extension CliRpgCharacterBrain {

    @MainActor
    private func decideCombatChoice2(in gameSnapshot: GameSnapshot) async -> CombatChoice {
        guard let character = gameSnapshot.characters[characterRef] else {
            fatalError("Bad character ref \(characterRef)")
        }
        let parsers =
            allCombatActions.compactMap {
                $0.canMaybeTakeAction(by: character.primaryKey, in: gameSnapshot)
                    ? $0.combatChoiceParserOpt?.asAny
                    : nil
            } + [endTurnParser.asAny]

        while true {
            let answer: CombatChoice = await decideBetweenOptions(
                nil,
                prompt:
                    "You have \(character.combatState!.actionsRemaining) actions. What is your combat choice?",
                parsers: parsers,
                displayParseableClassesInHud: true,
                in: gameSnapshot
            )
            if case CombatChoice.action(let action) = answer {
                guard action.canTakeAction(by: characterRef, in: gameSnapshot) else {
                    await self.printHUD("\(answer) is not a valid combat action.")
                    continue
                }
            }
            await printHUD("You chose \(answer)")
            return answer
        }
    }

    @MainActor
    func makeInteractiveMoveStep(
        _ options: [DecideOrOther<Direction1D>],
        in gameSnapshot: GameSnapshot
    ) async
        -> DecideOrOther<Direction1D>
    {
        await printHUD((gameSnapshot.scene as! Combat).map.oneLineDescription(in: gameSnapshot))
        //await printHUD("You have \(movementRemaining) movement remaining.")
        let answer: DecideOrOther<Direction1D> = await decideBetweenOptions(
            options,
            prompt: "Which direction will you step 5ft?",
            parsers: [
                CliArgsParser<DecideOrOther<Direction1D>>(parsers: [Direction1D.parser]) {
                    .decide($0 as! Direction1D)
                }
            ],
            in: gameSnapshot
        )
        return answer
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
extension CliArgsConvertibleType {
    static var parser: CliArgsParser<Self> {
        CliArgsParser(Self.self)
    }
    static var anyParser: CliArgsParser<Any> { parser.asAny }
}

protocol CliArgsParserProtocol {
    associatedtype Value
    var helpText: Substring { get }
    func parse(args: [Any], context: CliArgsConversionContext) throws(CliParseError) -> Value?
}
struct CliArgsParser<T>: CliArgsParserProtocol {
    let helpText: Substring
    let parseFunc: (_ args: [Any], _ context: CliArgsConversionContext) throws(CliParseError) -> T?
    func parse(args: [Any], context: CliArgsConversionContext) throws(CliParseError) -> T? {
        let result = try parseFunc(args, context)
        return result
    }
}
extension CliArgsParser where T: CliArgsConvertibleType {
    init(_ type: T.Type) {
        self.helpText = type.helpText
        self.parseFunc = type.init(args:context:)
    }
}
extension CliArgsParser {
    init(parsers: [any CliArgsParserProtocol], converter: @escaping (Any) -> T?) {
        self.parseFunc = { (args, context) throws(CliParseError) in
            for parser in parsers {
                if let result = try parser.parse(args: args, context: context),
                    let convertedResult = converter(result)
                {
                    return convertedResult
                }
            }
            return nil
        }
        self.helpText = parsers.map { $0.helpText }.joined(separator: "\n")[...]
    }
}
extension CliArgsParser {
    var asAny: CliArgsParser<Any> {
        CliArgsParser<Any>(helpText: self.helpText) { (args, context) throws(CliParseError) in
            try parseFunc(args, context)
        }
    }
}

protocol CliArgsContextFreeConvertibleType: CliArgsConvertibleType {
    init?(args: [Any]) throws(CliParseError)
}
extension CliArgsContextFreeConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        try self.init(args: args)
    }
}

extension CombatAction {
    static var parserOpt: CliArgsParser<Self>? {
        guard let parser = Self.self as? (any CliArgsConvertibleType.Type) else {
            return nil
        }
        return CliArgsParser<Self>(helpText: parser.helpText) {
            (args, context) throws(CliParseError) in
            let result = try parser.init(args: args, context: context)
            return result.map { $0 as! Self }
        }
    }
    static var combatChoiceParserOpt: CliArgsParser<CombatChoice>? {
        Self.parserOpt.map { x in
            CliArgsParser(parsers: [x]) { action in
                CombatChoice.action(action as! any CombatAction)
            }
        }
    }
}

struct EndTurn {}
@MainActor let endTurnParser = CliArgsParser<CombatChoice>(helpText: "(e)nd") { args, context in
    if let alreadyParsedMove = args.first as? CombatChoice,
        args.count == 1,
        case .endTurn = alreadyParsedMove
    {
        return alreadyParsedMove
    }
    var remaining = args[...]
    guard
        let firstArg = remaining.popFirst(),
        let firstArgAsString = firstArg as? Substring,
        firstArgAsString == "e" || firstArgAsString == "end"
    else {
        return nil
    }
    return CombatChoice.endTurn
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

    static var helpText: Substring { "(m)ove" }
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

extension Direction1D: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "r" || firstArgAsString == "l"
        else {
            return nil
        }
        self = firstArgAsString == "r" ? .right : .left
    }

    static var helpText: Substring {
        "R|L"
    }
}

extension DisengageAction: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedGainAdvantage = args.first as? Self, args.count == 1 {
            self = alreadyParsedGainAdvantage
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "d" || firstArgAsString == "disengage"
        else {
            return nil
        }
        var direction: Direction1D?
        for arg in remaining {
            if let directionArg = try Direction1D(args: [arg]), direction == nil {
                direction = directionArg
            } else {
                throw CliParseError("\(arg) not a direction")
            }
        }
        guard let direction = direction else {
            throw CliParseError("No direction established for disengage.")
        }
        self.init(direction: direction)
    }

    static var helpText: Substring {
        "(d)isengage \(Direction1D.helpText)"
    }
}

extension DecideOrOther: CliArgsConvertibleType where T: CliArgsConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let result = try T.init(args: args, context: context) {
            self = .decide(result)
        } else {
            self = .other(args.map { "\($0)" }.joined(separator: " "))
        }
    }

    static var helpText: Substring {
        T.helpText
    }
}

enum StatusCommand {
    case general
}
extension StatusCommand: CliArgsConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "s" || firstArgAsString == "status"
        else {
            return nil
        }
        self = .general
    }

    static var helpText: Substring {
        "(s)tatus"
    }
}
extension StatusCommand {
    func evaluate(in gameSnapshot: GameSnapshot, for characterRef: RpgCharacterRef) -> String {
        guard let character = gameSnapshot.characters[characterRef]?.core else {
            return "WHO ARE YOU?"
        }
        var result = ""
        result += (gameSnapshot.scene as! Combat).map.oneLineDescription(in: gameSnapshot) + "\n"
        var isFirst = true
        for someCharacter in gameSnapshot.characters {
            if isFirst {
                isFirst = false
            } else {
                result += "\n"
            }
            let opponents = gameSnapshot.characters.filter {
                $0.primaryKey != someCharacter.primaryKey
            }
            let (distanceToNearestOppontent, nearestOpponent) =
                opponents.map {
                    ($0.combatState!.space.distance(to: someCharacter.combatState!.space), $0)
                }
                .sorted { (lh, rh) in lh.0 < rh.0 }[0]
            result +=
                "\(someCharacter.primaryKey == characterRef ? "Your" : "\(someCharacter.name)'s") stats:\n"
                + "  Health: \(someCharacter.health.value)/\(character.health.maxValue)\n"
                + "  Focus: \(someCharacter.focus.value)/\(character.focus.maxValue)\n"
                + "  Conditions: \(someCharacter.conditions.map { "\($0.core)" }.joined(separator: ","))\n"
                + "  Space controlled: \(someCharacter.combatState!.space.lo)...\(someCharacter.combatState!.space.hi)\n"
                + "  Distance to \(nearestOpponent.name): \(distanceToNearestOppontent)"
        }
        return result
    }
}
