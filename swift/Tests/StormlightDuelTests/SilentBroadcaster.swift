import stormlight_duel

struct SilentBroadcaster: Broadcaster {
    func tellAll(_ message: String) {
    }
    func tell(_ message: String, to recipient: RpgCharacterRef) {
    }
}
