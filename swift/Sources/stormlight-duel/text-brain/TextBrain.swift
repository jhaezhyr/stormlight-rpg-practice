import Foundation
import stormlight_duel

public actor TextBrain<Connection: TextInterfaceConnection>: RpgCharacterBrain {
    let characterRef: RpgCharacterRef
    private var ui: TextInterfaceProxy<Connection>

    /// Callback fired just before prompting the player.
    /// Other players can use this to show a "waiting" alert.
    private let onBeforePrompt:
        (@Sendable (_ characterName: String, _ prompt: String) async -> Void)?

    /// Callback fired just after the player responds to a prompt.
    /// Other players can use this to clear the "waiting" alert.
    private let onAfterPrompt: (@Sendable (_ characterName: String) async -> Void)?

    public init(
        characterRef: RpgCharacterRef,
        ui: TextInterfaceProxy<Connection>,
        onBeforePrompt: (@Sendable (_ characterName: String, _ prompt: String) async -> Void)? =
            nil,
        onAfterPrompt: (@Sendable (_ characterName: String) async -> Void)? = nil
    ) async {
        self.onBeforePrompt = onBeforePrompt
        self.onAfterPrompt = onAfterPrompt
        self.characterRef = characterRef
        self.ui = ui
    }

    @MainActor
    public func decide<C: Sendable>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot)
        async throws
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
        let extraInterface: [String]? = getExtraInterfaceForDecision(
            code, type: C.Element.self, in: gameSnapshot)
        return try await decideBetweenOptions(
            Array(options),
            forCode: code,
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
        forCode code: DecisionCode,
        prompt: String,
        extraInterface: [String]? = nil,
        parsers: [any CliArgsParserProtocol] = [],
        displayParseableClassesInHud: Bool = false,
        in gameSnapshot: GameSnapshot,
    ) async throws -> T {
        let describeOptionFn: OptionDescriber<T> = optionDescriber(
            forCode: code,
            andType: T.self
        )
        let describeParserFn: ParserDescriber = parserDescriber(forCode: code)

        var message = prompt
        message +=
            (options?.enumerated().map {
                (i, x) in "\n:\(i + 1) \(describeOptionFn(x, gameSnapshot, self.characterRef))"
            }.joined() ?? "")
        if displayParseableClassesInHud {
            message += parsers.map { "\n:\(describeParserFn($0, gameSnapshot, self.characterRef))" }
                .joined()
        }
        choiceLoop: while true {
            guard
                let aLine = try await read(
                    message,
                    interface: extraInterface?.joined(separator: "\n") ?? nil
                )?.trimmingCharacters(in: .whitespacesAndNewlines)
            else {
                await printHint("Couldn't read that input.")
                continue
            }
            let (args, context) = (aLine.split(separator: " "), (gameSnapshot, characterRef))
            do {
                if let statusCommand = try StatusCommand.parser.parse(args: args, context: context)
                {
                    await printHint(statusCommand.evaluate(in: gameSnapshot, for: characterRef))
                    continue choiceLoop
                }
            } catch {
                await printHint(error.description)
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
                        await printHint(
                            "\"\(aLine)\" is an invalid \(parser.helpText). \(error.description)")
                    }
                }
            }
            if let result {
                if let options {
                    if let optionsWithContains = options as? ContainsAny,
                        optionsWithContains.containsAny(result)
                    {
                        await printHint("You chose \(result)")
                        return result
                    } else {
                        print(
                            "DEVELOPER: I trust that this is okay, even though it might not be.")
                        return result
                    }
                } else {
                    return result
                }
            } else {
                if let options {
                    await printHint(
                        "\(aLine) is not a valid choice. Pick a number from 1 to \(options.count)."
                    )
                } else {
                    await printHint("\(aLine) is not a valid choice.")
                }
            }
        }
    }

    func read(_ message: String, interface: String? = nil) async throws -> String? {
        await onBeforePrompt?(characterRef.name, message)
        let answer = try await ui.prompt(message, interface: interface)
        await onAfterPrompt?(characterRef.name)
        return answer
    }

    @MainActor
    public func decide<T: Sendable>(
        _ code: DecisionCode, nonIterableType: T.Type, in gameSnapshot: GameSnapshot
    )
        async throws -> T
    where T: Sendable {
        switch code {
        case .combatChoice:
            return try await decideCombatChoice(in: gameSnapshot) as! T
        default:
            if let allCases = (T.self as? (any CaseIterable.Type))?.allCases {
                return try await decide(code, options: allCases.map { $0 as! T }, in: gameSnapshot)
            }
            fatalError("I don't know how to decide when asked for \(nonIterableType)")
        }
    }

    @MainActor
    func getExtraInterfaceForDecision<T>(
        _ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot
    ) -> [String]? {
        switch code {
        case .directionToMove5Ft:
            return [(gameSnapshot.scene as! Combat).map.oneLineDescription(in: gameSnapshot)]
        default: return nil
        }
    }

    @MainActor
    private func printEvent(_ thing: Any, interface: String? = nil) async {
        await ui.event("\(thing)", interface: interface)
    }

    @MainActor
    private func printHint(_ thing: Any, interface: String? = nil) async {
        await ui.hint("\(thing)", interface: interface)
    }

    @MainActor
    public func hear<M>(_ message: M, in gameSnapshot: GameSnapshot) async where M: Message {
        let messageDescription = message.description(for: characterRef)
        let interface: String?
        interface = StatusCommand.general.evaluate(in: gameSnapshot, for: characterRef)
        await printEvent(messageDescription, interface: interface)
    }

    @MainActor public func hearHint(_ message: String, in gameSnapshot: GameSnapshot) async {
        await printHint(message)
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

extension TextBrain {
    @MainActor
    private func decideCombatChoice(in gameSnapshot: GameSnapshot) async throws -> CombatChoice {
        guard let character = gameSnapshot.characters[characterRef]?.core else {
            fatalError("Bad character ref \(characterRef)")
        }
        let parsers =
            character.actions.flatMap {
                (actionType: CombatAction.Type) -> [CliArgsParser<CombatChoice>] in
                if !actionType.canReallyMaybeTakeAction(by: character.primaryKey, in: gameSnapshot)
                {
                    return []
                }
                if let parsers = actionType.combatChoiceParsers(
                    context: (gameSnapshot, characterRef)
                ) {
                    return parsers
                }
                if let parser = actionType.combatChoiceParserOpt {
                    return [parser]
                }
                return []
            } + [endTurnParser]

        while true {
            let answer: CombatChoice = try await decideBetweenOptions(
                nil,
                forCode: .combatChoice,
                prompt:
                    "You have \(character.combatState!.actionsRemaining) actions. What is your combat choice?",
                parsers: parsers,
                displayParseableClassesInHud: true,
                in: gameSnapshot
            )
            if case CombatChoice.action(let action) = answer {
                guard action.canReallyTakeAction(by: characterRef, in: gameSnapshot) else {
                    await self.printHint("\(answer) is not a valid combat action.")
                    continue
                }
            }
            await printHint("You chose \(answer)")
            return answer
        }
    }

    @MainActor
    func makeInteractiveMoveStep(
        _ options: [DecideOrOther<Direction1D>],
        in gameSnapshot: GameSnapshot
    ) async throws
        -> DecideOrOther<Direction1D>
    {
        await printHint((gameSnapshot.scene as! Combat).map.oneLineDescription(in: gameSnapshot))
        //await printHUD("You have \(movementRemaining) movement remaining.")
        let answer: DecideOrOther<Direction1D> = try await decideBetweenOptions(
            options,
            forCode: .directionToMove5Ft,
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
