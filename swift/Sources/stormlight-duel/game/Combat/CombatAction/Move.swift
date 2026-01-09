public struct Move: CombatAction {
    public var distanceToward: Distance
    public static var actionCost: Int { 1 }
    public func action(by character: RpgCharacterRef, in gameSession: isolated GameSession) async {
        await gameSession.game.broadcaster.tellAll(
            "\(character.name) moved \(distanceToward) toward their opponent")
    }

    public init(distanceToward: Distance) {
        self.distanceToward = distanceToward
    }
}
