public protocol Scene {
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
}
extension Map {
    public static let emptyDuel: Self = .init(characterStartPositions: [10, -10])
}
extension Map {
    public func oneLineDescription(in game: GameSnapshot) -> String {
        let width: Int = 40
        let stepSize: Distance = 5
        var origin: Position1D = -20 * stepSize
        let lo = game.characters.map { $0.combatState!.space.lo }.min() ?? 0
        //let hi = game.characters.map { $0.combatState!.space.hi }.max() ?? 0
        if lo - stepSize * 2 < origin {
            origin = lo - stepSize * 2
        }
        let thingsToDisplay: [(Space1D, Character)] = game.characters.map {
            ($0.combatState!.space, $0.name.first!)
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
