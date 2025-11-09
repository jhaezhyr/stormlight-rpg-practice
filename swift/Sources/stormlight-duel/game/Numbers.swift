enum NumberDie: Int {
    case d4 = 4
    case d6 = 6
    case d8 = 8
    case d10 = 10
    case d12 = 12
    case d20 = 20
    case d100 = 100
}

struct RandomDistribution {
    public var dice: [(die: NumberDie, count: Int)]
}

// Measured in ft
typealias Distance = Int
// Measured in diamond marks or mk
typealias Money = Int
// Measured in lb
typealias Weight = Int

struct Resource: Comparable {
    public var value: Int
    public var maxValue: Int
    public mutating func restore(_ delta: Int) {
        value += max(min(delta, maxValue - value), 0)
    }

    static func < (lhs: Resource, rhs: Resource) -> Bool {
        lhs.value < rhs.value
    }
}