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
