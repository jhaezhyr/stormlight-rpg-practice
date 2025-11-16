public enum NumberDie: Int {
    case d4 = 4
    case d6 = 6
    case d8 = 8
    case d10 = 10
    case d12 = 12
    case d20 = 20
    case d100 = 100
}

public enum PlotDieResult {
    case opportunity
    case complication2
    case complication4
    case none
}

public struct RandomDistribution {
    public var dice: [(die: NumberDie, count: Int)]
}

// Measured in ft
public typealias Distance = Int
// Measured in diamond marks or mk
public typealias Money = Int
// Measured in lb
public typealias Weight = Int

public struct Resource: Comparable {
    public var value: Int
    public var maxValue: Int
    public mutating func restore(_ delta: Int) {
        value += max(min(delta, maxValue - value), 0)
    }

    public static func < (lhs: Resource, rhs: Resource) -> Bool {
        lhs.value < rhs.value
    }
}
