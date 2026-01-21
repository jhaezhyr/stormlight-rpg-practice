public actor GameSession {
    private var _game: Game?
    public var game: Game { _game! }

    public init(game: Game? = nil) {
        if let game {
            self._game = game
        }
    }

    public func provideGame(_ game: Game) {
        self._game = game
    }

    private var _nextId = 0
    func nextId() -> Int {
        _nextId += 1
        return _nextId
    }
}
