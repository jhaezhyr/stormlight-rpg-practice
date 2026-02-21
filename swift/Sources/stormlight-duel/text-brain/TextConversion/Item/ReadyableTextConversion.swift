import stormlight_duel

extension Readyable: CustomStringConvertible {
    public var description: String {
        let readyPhrase =
            switch core {
            case is any Weapon: "equipped"
            case is any Armor: "equipped"
            default: "ready"
            }
        return "\(core), \(isReady ? "" : "not ")\(readyPhrase)"
    }
}
