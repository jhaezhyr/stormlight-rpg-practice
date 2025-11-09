import random

def roll_stat(min_val: int, max_val: int) -> int:
    """Generate a random stat within the given range."""
    return random.randint(min_val, max_val)

def create_traits_with_points(total_points: int = 12) -> dict[str, int]:
    """Create traits by distributing total points across 6 attributes (0-4 each)."""
    trait_names = ["Strength", "Speed", "Intellect", "Willpower", "Presence", "Awareness"]
    traits = {trait: 0 for trait in trait_names}

    remaining_points = total_points

    # Distribute points randomly but ensure no trait exceeds 4
    while remaining_points > 0:
        trait = random.choice(trait_names)
        if traits[trait] < 4:
            traits[trait] += 1
            remaining_points -= 1

    return traits

def get_recovery_die(willpower: int) -> str:
    """Get recovery die type based on willpower."""
    if willpower == 0:
        return "d4"
    elif willpower in [1, 2]:
        return "d6"
    else:  # willpower in [3, 4]
        return "d8"

def get_movement_rate(speed: int) -> int:
    """Get movement rate based on speed trait."""
    if speed == 0:
        return 20
    elif speed in [1, 2]:
        return 25
    else:  # speed in [3, 4]
        return 30

def calculate_defense(trait1: int, trait2: int) -> int:
    """Calculate defense value: 10 + trait1 + trait2."""
    return 10 + trait1 + trait2