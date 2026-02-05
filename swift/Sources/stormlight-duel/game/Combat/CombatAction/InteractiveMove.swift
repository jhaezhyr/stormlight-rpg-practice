public struct InteractiveMove: CombatAction {
    public static var actionCost: Int { 1 }
    public init() {
    }
    public func action(by character: RpgCharacterRef, in gameSession: isolated GameSession) async {
        let me = gameSession.game.characters[character]!.core
        let totalMovement = me.movementRate
        var movementRemaining = totalMovement
        movementLoop: while movementRemaining > 0 {
            // TODO When we have teamates, this will need to be changed
            let opponents = gameSession.game.characters.filter { $0.primaryKey != character }
            let opponentSpaces = opponents.map { $0.combatState!.space }
            let mySpace = me.combatState!.space
            let choiceMap = [Direction1D: Space1D](
                uniqueKeysWithValues: Direction1D.allCases.compactMap { direction in
                    let newSpace = mySpace.facing(direction) + (direction == .right ? 5 : -5)
                    if opponentSpaces.contains(where: { $0.overlaps(newSpace) }) {
                        return nil
                    } else {
                        return (direction, newSpace)
                    }
                })
            await gameSession.game.broadcaster.tell(
                (gameSession.game.scene as! Combat).map.oneLineDescription(
                    in: gameSession.game.snapshot
                ),
                to: character
            )
            let choice = await me.brain.decide(
                .directionToMove5Ft,
                options: choiceMap.keys.map { DecideOrOther.decide($0) } + [.other("stop")],
                in: gameSession.game.snapshot
            )
            switch choice {
            case .decide(let direction):
                me.combatState!.space = choiceMap[direction]!
                movementRemaining -= 5
            case .other(_):
                break movementLoop
            }
        }
    }
}

public enum Direction1D: Sendable, Hashable, CaseIterable {
    case left, right
}
extension Direction1D: CustomStringConvertible {
    public var description: String {
        switch self {
        case .left: "left"
        case .right: "right"
        }
    }
}
