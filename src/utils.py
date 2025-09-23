import random

def roll_stat(min_val: int, max_val: int) -> int:
    """Generate a random stat within the given range."""
    return random.randint(min_val, max_val)

def roll_traits() -> dict[str, int]:
    """Generate six random traits with values 1-3."""
    trait_names = ["Strength", "Agility", "Intelligence", "Perception", "Endurance", "Charisma"]
    return {trait: roll_stat(1, 3) for trait in trait_names}

def roll_speed() -> int:
    """Generate speed stat: either 25ft or 30ft."""
    return random.choice([25, 30])