public struct InteractiveMove: CombatAction {
    public static func actionCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Int
    {
        1
    }
    public static var canBeTakenMoreThanOncePerTurn: Bool { true }
    public static var actionName: CombatActionName { "Move" }
    public init() {
    }
    public static func canMaybeTakeAction(
        by character: RpgCharacterRef, in gameSnapshot: GameSnapshot
    ) -> Bool {
        guard let character = gameSnapshot.characters[character]?.core else {
            fatalError("Stop asking about a character that doesn't exist.")
        }
        return character.movementRate > 0
    }
    public func action(by character: RpgCharacterRef, in gameSession: isolated GameSession)
        async throws
    {
        let me = gameSession.game.characters[character]!.core
        var map: Map { (gameSession.game.scene as! Combat).map }
        var amountMoved = 0
        movementLoop: while amountMoved < me.movementRate {
            let opponents = gameSession.game.opponents(of: character)
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
            let choice = try await me.brain.decide(
                .directionToMove5Ft,
                options: choiceMap.keys.map { DecideOrOther.decide($0) } + [.other("stop")],
                in: gameSession.game.snapshot()
            )
            switch choice {
            case .decide(let direction):
                me.combatState!.space = choiceMap[direction]!
                amountMoved += 5
                try await gameSession.game.dispatch(
                    MovementStepEvent(subject: me, direction: direction, carefully: false),
                    in: gameSession
                )
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

public struct MovementStepEvent: Event {
    let subject: any RpgCharacter
    let direction: Direction1D
    let carefully: Bool
}
