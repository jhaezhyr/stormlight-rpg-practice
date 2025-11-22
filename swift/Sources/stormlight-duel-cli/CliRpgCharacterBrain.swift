import stormlight_duel
import Foundation

struct CliRpgCharacterBrain: RpgCharacterBrain {
    func decide<C>(options: C) -> C.Element where C: Collection {
        print("Make a choice between the following \(options.count) options:")
        for (i, x) in options.enumerated() {
            print(">", i, x)
        }
        if let aLine = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), let index = Int(aLine) {
            return options[options.index(options.startIndex, offsetBy: index)]
        }
        print("No, try again.")
        return decide(options: options)
    }

    func decide<T>(type: T.Type) -> T {
        if T.self == CombatChoice.self {
            return decideCombatChoice() as! T
        }
        fatalError("I don't know how to decide when asked for \(type)")
    }

    private func decideCombatChoice() -> CombatChoice {
        print("What is your combat choice?")
        for action in allParseableCombatActions {
            print(">", action.helpText)
        }
        let line = readLine()!.trimmingCharacters(in: .whitespacesAndNewlines)
        let args: [Any] = line.split(separator: " ")
        for action in allParseableCombatActions {
            if let action = action.init(args: args) {
                print("Your action is \(action)")
                return .action(action)
            }
        }
        if ["e", "end", "end turn"].contains(line) {
            print("I guess your turn is over")
            return .endTurn
        }
        print("No, try again.")
        return decideCombatChoice()
    }
}

/// The CLI input might look like this:
/// - move 15 back
/// - strike
protocol CliArgsConvertibleType {
    init?(args: [Any])
    static var helpText: Substring { get }
}

extension Move: CliArgsConvertibleType {
    init?(args: [Any]) {
        if let alreadyParsedMove = args.first as? Move, args.count == 1 {
            self = alreadyParsedMove
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "m" || firstArgAsString == "move"
        else {
            print("\"\(args.first, default: "")\" is not an m")
            return nil
        }
        var distance: Distance?
        var directionIsForward: Bool?
        for arg in remaining {
            let isBackwardText: Set<Substring> = ["backward", "back", "b", "away", "from"]
            let isForwardText: Set<Substring> = ["forward", "toward", "to"]
            if let distanceArg = Distance(args: [arg]), distance == nil {
                distance = distanceArg
            } else if let string = arg as? Substring, isBackwardText.contains(string), directionIsForward == nil {
                directionIsForward = false
            } else if let string = arg as? Substring, isForwardText.contains(string), directionIsForward == nil {
                directionIsForward = true
            } else {
                print("not a distance or direction")
                return nil
            }
        }
        let finalDistance = distance ?? 5
        let finalDirectionIsForward = directionIsForward ?? true
        self.init(distanceToward: finalDistance * (finalDirectionIsForward ? 1 : -1))
    }

    static var helpText: Substring { "(m)ove [\(Distance.helpText)] [forward|backward]"}
}

// TODO Make distance a wrapper around a number
extension Distance: CliArgsConvertibleType {
    init?(args: [Any]) {
        if let alreadyParsedDistance = args.first as? Distance, args.count == 1 {
            self = alreadyParsedDistance
            return
        }
        if let string = args.first as? Substring, let int = Int(string) {
            self = int
            return
        }
        print("not a direction")
        return nil
    }

    static var helpText: Substring { "###" }
}

nonisolated(unsafe) let allParseableCombatActions = allCombatActions.compactMap { $0 as? (CliArgsConvertibleType & CombatAction).Type }