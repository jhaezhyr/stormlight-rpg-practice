public protocol Scene {
    func run(in gameSession: isolated GameSession) async
}
extension Scene {
    func run(isolatedIn gameSession: isolated GameSession = #isolation) async {
        await self.run(in: gameSession)
    }
}

extension GameSession {
    public func `switch`(to newScene: Scene) async {
        await newScene.run()
    }
}
