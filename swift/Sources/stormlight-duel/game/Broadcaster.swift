public protocol Broadcaster: Sendable {
    func tellAll(_ message: String) async
    func tell(_ message: String, to recipient: RpgCharacterRef) async
}
