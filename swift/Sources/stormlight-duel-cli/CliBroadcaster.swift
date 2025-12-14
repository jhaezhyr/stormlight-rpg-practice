import stormlight_duel

struct CliBroadcaster: Broadcaster {
    func tellAll(_ message: String) {
        print("ALL: \(message)\n")
    }

    func tell(_ message: String, to recipient: RpgCharacterRef) {
        print("\(recipient.name): \(message)\n")
    }

}
