public func OutmaneuverOpportunity() -> some Opportunity {
    return GiveConditionOpComp(name: "Outmaneuver") {
        (
            SingleTargetMessage(
                w1: "$1 has seized a moment to outmaneuver their opponent!",
                wU: "You have seized a moment to outmaneuver your opponent!",
                as1: $0
            ),
            DurationCondition(
                core: OutmaneuverCondition(for: $0),
                duration: 2,
                turnsFor: $0,
                in: $1
            )
        )
    }
}
