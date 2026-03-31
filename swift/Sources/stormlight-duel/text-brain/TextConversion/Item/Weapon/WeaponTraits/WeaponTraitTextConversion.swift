import stormlight_duel

extension Thrown: CustomStringConvertible {
    public var description: String {
        "thrown (\(self.short)/\(self.long))"
    }
}
extension Offhand: CustomStringConvertible {
    public var description: String {
        "offhand"
    }
}
extension Loaded: CustomStringConvertible {
    public var description: String {
        "loaded (\(self.ammunition))"
    }
}
extension TwoHanded: CustomStringConvertible {
    public var description: String {
        "two-handed"
    }
}
extension Deadly: CustomStringConvertible {
    public var description: String {
        "deadly"
    }
}
extension CumbersomeWeapon: CustomStringConvertible {
    public var description: String {
        "cumbersome \(self.minStrength)"
    }
}
extension Pierce: CustomStringConvertible {
    public var description: String {
        "pierce"
    }
}
extension Defensive: CustomStringConvertible {
    public var description: String {
        "defensive"
    }
}
extension UniqueWeapon: CustomStringConvertible {
    public var description: String {
        "unique"
    }
}
extension Momentum: CustomStringConvertible {
    public var description: String {
        "momentum"
    }
}
extension Fragile: CustomStringConvertible {
    public var description: String {
        "fragile"
    }
}
extension Indirect: CustomStringConvertible {
    public var description: String {
        "indirect"
    }
}
extension Quickdraw: CustomStringConvertible {
    public var description: String {
        "quickdraw"
    }
}
extension Dangerous: CustomStringConvertible {
    public var description: String {
        "dangerous"
    }
}
extension Discreet: CustomStringConvertible {
    public var description: String {
        "discreet"
    }
}
