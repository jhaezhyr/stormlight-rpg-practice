public func SurpriseComplication() -> some OpComp {
    return GiveConditionOpComp {
        (
            SingleTargetMessage(
                w1: "$1 was surprised!",
                wU: "You were surprised!",
                as1: $0
            ),
            Surprised(for: $0, in: $1)
        )
    }
}
