public struct InteractiveMove: CombatAction {
    public static var actionCost: Int { 1 }
    public init() {
    }
    public func action(by character: RpgCharacterRef, in gameSession: isolated GameSession) async {
        let me = gameSession.game.characters[character]!.core
        var map: Map { (gameSession.game.scene as! Combat).map }
        let totalMovement = me.movementRate
        var movementRemaining = totalMovement
        movementLoop: while movementRemaining > 0 {
            // TODO When we have teamates, this will need to be changed
            let opponents = gameSession.game.characters.filter { $0.primaryKey != character }
            let impassableSpaces = opponents.map { $0.combatState!.space } + map.staticObstacles
            let mySpace = me.combatState!.space
            let choiceMap = [Direction1D: Space1D](
                uniqueKeysWithValues: Direction1D.allCases.compactMap { direction in
                    let newSpace = mySpace.facing(direction) + (direction == .right ? 5 : -5)
                    if impassableSpaces.contains(where: { $0.overlaps(newSpace) }) {
                        return nil
                    } else {
                        return (direction, newSpace)
                    }
                })
            await gameSession.game.broadcaster.tell(
                map.oneLineDescription(
                    in: gameSession.game.snapshot
                ),
                to: character
            )
            await gameSession.game.broadcaster.tell(
                "You have \(movementRemaining) movement remaining.", to: character)
            let choice = await me.brain.decide(
                .directionToMove5Ft,
                options: choiceMap.keys.map { DecideOrOther.decide($0) } + [.other("stop")],
                in: gameSession.game.snapshot
            )
            switch choice {
            case .decide(let direction):
                me.combatState!.space = choiceMap[direction]!
                movementRemaining -= 5
                await gameSession.game.naiveDispatch(
                    MoveHook.stepped(direction: direction, carefully: false), for: character,
                    in: gameSession)
            case .other(_):
                break movementLoop
            }
        }
        await gameSession.game.naiveDispatch(MoveHook.moved, for: character, in: gameSession)
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

public enum MoveHook: HookTrigger {
    case stepped(direction: Direction1D, carefully: Bool)
    case moved
}
