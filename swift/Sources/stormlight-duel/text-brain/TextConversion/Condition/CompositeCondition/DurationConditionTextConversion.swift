import stormlight_duel

extension DurationConditionSnapshot: CustomStringConvertible {
    public var description: String {
        "\(core), lasting \(self.durationRemainingInTurns) more \(self.waitingCharacter == self.parentCharacter ? "" : "of \(self.waitingCharacter)'s ")turns"
    }
}
