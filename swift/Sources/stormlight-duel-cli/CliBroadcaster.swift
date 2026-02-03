import stormlight_duel

struct CliBroadcaster: Broadcaster {
    @MainActor
    func tellAll(_ message: String) async {
        print("ALL: \(message)\n")
    }

    @MainActor
    func tell(_ message: String, to recipient: RpgCharacterRef) async {
        print("\(recipient.name): \(message)\n")
    }
}
