public protocol Scene: Sendable {
    func run(in gameSession: isolated GameSession) async
}
extension Scene {
    func run(isolatedIn gameSession: isolated GameSession = #isolation) async {
        gameSession.game.scene = self
        await self.run(in: gameSession)
    }
}

extension GameSession {
    public func `switch`(to newScene: Scene) async {
        await newScene.run()
    }
}

public struct Map: Equatable, Sendable {
    public var characterStartPositions: Set<Position1D>
    public var staticObstacles: Set<Space1D>
}
extension Map {
    public static let emptyDuel: Self = .init(
        characterStartPositions: [10, -10], staticObstacles: [.init(-100 ..< -80), .init(80..<100)])
}
extension Map {
    public func oneLineDescription(in game: GameSnapshot) -> String {
        let width: Int = 44
        let stepSize: Distance = 5
        var origin: Position1D = -20 * stepSize
        let thingsToDisplay: [(Space1D, Character)] =
            game.characters.map {
                ($0.combatState!.space, $0.name.first!)
            } + staticObstacles.map { ($0, "|") }

        let lo = thingsToDisplay.map { $0.0.lo }.min() ?? 0
        if lo - stepSize * 2 < origin {
            origin = lo - stepSize * 2
        }
        let description = (0..<width).map { i in
            let spaceCovered = Space1D(
                origin: origin + i * stepSize, size: stepSize, orientation: .right)
            if let thingToDisplay = thingsToDisplay.filter({ (thingSpace, char) in
                thingSpace.overlaps(spaceCovered)
            }).first {
                return thingToDisplay.1
            } else {
                return "."
            }
        }
        return String(description)
    }
}
