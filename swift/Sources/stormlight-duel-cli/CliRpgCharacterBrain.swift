import Foundation
import stormlight_duel

struct CliRpgCharacterBrain: RpgCharacterBrain {
    let characterRef: RpgCharacterRef

    @MainActor
    init(characterRef: RpgCharacterRef) async {
        self.characterRef = characterRef
        _ = await self.decideBetweenOptions(
            UnderstandingChoice.allCases,
            prompt: """
                Welcome to STORMLIGHT DUEL!

                This videogame experience is based on the "Cosmere Roleplaying Game" by
                Brotherwise Games, based on works by Brandon Sanderson. The videogame is
                written and hosted by Braeden Hintze.

                            * ** INSTRUCTIONS ** * 

                You play as a player character named Kal. You are in a one-on-one combat
                with Shallan, an NPC. Bring her down.

                You have no armor, no talents, and level 0 skills. You also have an axe.

                Anytime you are prompted to make a choice, you type in your answer and
                press ENTER. In some cases, you are given multiple numbered options. In
                other cases, your choices are a list of one-word commands. Some commands
                have single-letter aliases to make them easier to type.

                When the game waits for your input, you also can type "status" in order
                to see the map and the conditions of both characters. The map shows a K
                for your location, an S for Shallan's location, and a . for every 5ft
                distance. The map is 1-dimensional to keep things simple and brutal.

                Do you understand?
                """, in: GameSnapshot.empty)
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
            return await decideCombatChoice(in: gameSnapshot) as! T
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
    private func decideCombatChoice(in gameSnapshot: GameSnapshot) async -> CombatChoice {
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

enum UnderstandingChoice: String, Sendable, Hashable, CustomStringConvertible, CaseIterable {
    case yes = "yes, life before death"
    var description: String { self.rawValue }
}
