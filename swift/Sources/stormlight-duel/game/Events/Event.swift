public struct TestEvent<E>: Event {
    public let event: E
    public let test: any RpgTest
    public let tester: any RpgCharacter
    public let opponent: (any RpgCharacter)?

    public init?(
        _ event: E,
        test: any RpgTest,
        in gameSession: isolated GameSession = #isolation,
    ) {
        self.event = event
        self.test = test
        if let tester = gameSession.game.characters[test.tester]?.core {
            self.tester = tester
        } else {
            return nil
        }
        if let opponent = test.opponent {
            self.opponent = gameSession.game.characters[opponent]?.core
        } else {
            self.opponent = nil
        }
    }
}
