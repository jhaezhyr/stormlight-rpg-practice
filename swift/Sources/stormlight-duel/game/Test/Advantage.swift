import CountedSet

func assignAdvantagesAndDisadvantages<Role>(
    advantagesAvailable: Int,
    disadvantagesAvailable: Int,
    disadvantageBrain: RpgCharacterBrain,
    advantageBrain: RpgCharacterBrain,
    dieRoleCounts: CountedSet<Role>,
    in gameSession: isolated GameSession = #isolation
) async throws -> (
    advantagesApplied: Int,
    disadvantagesApplied: Int,
    dieRoleCounts: CountedSet<RoleWithAdvantageNumber<Role>>
) {
    var advantagesApplied = 0
    var disadvantagesApplied = 0
    var result = dieRoleCounts.mapToCountedSet { (role, count) in
        (element: RoleWithAdvantageNumber(role: role, advantageNumber: nil), count: count)
    }

    func allow(
        _ brain: RpgCharacterBrain,
        toAllocate rollModifier: RollModifier,
        in gameSession: isolated GameSession = #isolation
    ) async throws -> Bool {
        let options =
            result.filterToCountedSet { die, count in
                die.advantageNumber != rollModifier ? 1 : 0
            }.sorted().map { DecideOrOther.decide($0) }
            + [
                .other("ignore")
            ]
        let choice = try await brain.decide(
            .whichDieToModify(rollModifier), options: options, in: gameSession.game.snapshot)
        guard case .decide(let choice) = choice else {
            return false
        }
        result.remove(choice)
        result.insert(
            RoleWithAdvantageNumber(
                role: choice.role,
                advantageNumber: combine(modifier: choice.advantageNumber, with: rollModifier)
            )
        )
        return true
    }

    for _ in 0..<disadvantagesAvailable {
        if try await !allow(disadvantageBrain, toAllocate: .disadvantage) {
            break
        } else {
            disadvantagesApplied += 1
        }
    }
    for _ in 0..<advantagesAvailable {
        if try await !allow(advantageBrain, toAllocate: .advantage) {
            break
        } else {
            advantagesApplied += 1
        }
    }
    return (
        advantagesApplied: advantagesApplied,
        disadvantagesApplied: disadvantagesApplied,
        dieRoleCounts: result
    )
}

public enum DecideOrOther<T: Sendable>: Sendable {
    case decide(T)
    case other(String)
}
extension DecideOrOther: CustomStringConvertible {
    public var description: String {
        switch self {
        case .decide(let option):
            "\(option)"
        case .other(let otherString):
            otherString
        }
    }
}
extension DecideOrOther: Equatable where T: Equatable {
}
extension DecideOrOther: Hashable where T: Hashable {
}

public struct RoleWithAdvantageNumber<Role: Hashable & Sendable & Comparable>: Hashable, Sendable {
    public var role: Role
    public var advantageNumber: RollModifier?

    public init(
        role: Role,
        advantageNumber: RollModifier?
    ) {
        self.role = role
        self.advantageNumber = advantageNumber
    }
}
extension RoleWithAdvantageNumber: Comparable {
    public static func < (lhs: RoleWithAdvantageNumber<Role>, rhs: RoleWithAdvantageNumber<Role>)
        -> Bool
    {
        if lhs.role < rhs.role {
            return true
        } else if rhs.role < lhs.role {
            return false
        } else {  // if lhs.role == rhs.role
            switch (lhs.advantageNumber, rhs.advantageNumber) {
            case (nil, .some(_)):
                return true
            case (.some(.disadvantage), .some(.advantage)):
                return true
            default:
                return false
            }
        }
    }
}
extension RoleWithAdvantageNumber: CustomStringConvertible {
    public var description: String {
        switch self.advantageNumber {
        case .advantage:
            "advantaged \(self.role)"
        case .disadvantage:
            "disadvantaged \(self.role)"
        case nil:
            "\(self.role)"
        }
    }
}

public enum RollModifier: Sendable, Hashable {
    case advantage
    case disadvantage
}
func combine(modifier: RollModifier?, with other: RollModifier) -> RollModifier? {
    switch (modifier, other) {
    case (.some(.advantage), .advantage): .some(.advantage)
    case (.some(.advantage), .disadvantage): nil
    case (.some(.disadvantage), .advantage): nil
    case (.some(.disadvantage), .disadvantage): .some(.disadvantage)
    case (.none, _): other
    }
}
