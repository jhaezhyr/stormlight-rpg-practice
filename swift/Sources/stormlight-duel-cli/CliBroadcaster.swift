import stormlight_duel

struct CliBroadcaster: Broadcaster {
    @MainActor
    func tellAll(_ message: String) {
        print("ALL: \(message)\n")
    }

    @MainActor
    func tell(_ message: String, to recipient: RpgCharacterRef) {
        print("\(recipient.name): \(message)\n")
    }
}
