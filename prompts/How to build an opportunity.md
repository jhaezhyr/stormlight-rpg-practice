Most opportunities or complications provide one of the following:
1. Immediate instant effect. These happen now, once.
2. Future instant effect. These represent things that may happen at a later time, once.
3. Temporary effect. These last until the end of a turn, or until some other inciting event.
4. Permanent effect. These are anything that lasts "until the end of the scene" or "until the end of the battle".

Here are some examples of each.
1. Immediate instant effect
  - You take 1d4 keen damage
  - Your enemy may spend a reaction and 1 focus in order to have advantage on their next attack test against you.
2. Future instant effect
  - An enemy may regain 1d6 health on their next turn as an action.
3. Temporary effect
  - Until the end of your turn, ranged attacks against you have an advantage.
4. Permanent effect
  - Your dodge costs 1 focus less for the rest of the battle.

Let's talk about how to implement each of these examples. You'll find that the exact mechanisms for each of these might overlap.

# Immediate effects
Most of these effects' descriptions clearly show that they might happen on the tester's turn, or they might happen on someone else's turn. However, if the opportunity or complication doesn't make any sense except on the tester's turn (or off the tester's turn), then it should be marked such that it's not presented to the chooser as an option. Such context-bound opportunities and complications are very rare.

The effect of a triggered opportunity may include the chance to choose to accept or reject a boon.

## Example: You take 1d4 keen damage
This is really straightforward. When the opportunity runs, it rolls the d4 and deals that damage to the tester.

## Example: Your enemy may spend a reaction and 1 focus in order to have advantage on their next attack test against you.
When this complication runs, it uses the broadcaster to announce something narrative about the complication, like "Kal lost his footing.". It checks if there is an enemy of the tester that has both a reaction and a focus remaining. If so, it presents that enemy with the choice to either "gain advantage as a reaction, costs 1 focus" or not. If they choose to do it, then the complication code deducts the focus and the reaction, and bestows a new condition on that enemy. It could just be the GainAdvantageCondition, although that condition will need a little refactoring so this complication can apply a skill-less variant. It's a good choice, since it lasts just the right amount of time: till that character attacks the current tester.

# Future instant effect
## Example: An enemy may regain 1d6 health on their next turn as an action
When this complication runs, it first picks an enemy to benefit. It uses the broadcaster to announce some flavor text, like "Kal drops some knobweed, and Parshendi Warform picks it up." Now the enemy gets a condition called "spare knobweed", which has an entry in actionProviders called "slurp spare knobweed". Then the action represented there should cause an instant effect.

The wording was very specific in not saying that this was the Recover action. We can only do each action once per turn, and this new choice for the enemy doesn't keep them from also doing a Recover action as well.

# Temporary effect
Many of these effects will modify the calculation of certain numbers or features. When possible, prefer to assign temporary Conditions onto characters or items. Then, when the number (e.g. the deflect number of a particular character) is being calculated, the calculation function can create an event with a MUTABLE property for the final result, and emit that event into the game. The condition will listen for that event and modify the event's property. Then the calculation function will return whatever the event's final property was.

## Example: Until the end of your next turn, ranged attacks against you have an advantage
This complication announces its flavor text via the broadcaster, perhaps like "Kal's legs fell asleep. His reaction time has increased." Then add a DurationCondition to him wrapping a new SleepingLegsCondition, which listens for the start of attack tests, checks for those that target Kal with ranged weapons, and then gives them one more advantage. The duration should be 1 turn if it's your turn, or 2 if it's not. This is because a DurationCondition's remainingTurns property is reduced by 1 at the end of each turn, and it removes itself the moment it reaches 0.

# Permanent effect
Permanent effects last forever, and since a character is not reused after a battle, we consider anything that lasts the duration of the battle (or scene) to be permanent. We don't have to wrap these conditions in a DurationCondition or provide any kind of removal trigger.

## Example: Your dodge costs 1 focus less for the rest of the battle
This opportunity announces its flavor text first, maybe saying, "A windspren has taken a liking to Kal. It bounces in front of arrows and swords to show him where strikes will come from." Then he gets a WindsprenFavorCondition, which has an event handler for DodgeActionCostCalculation, which first checks which player's dodge action cost is being calculated, and if it's the one with the condition, it reduces the focus cost by 1, never below 0. To make use of this condition, the DodgeReactionProvider must be modified to emit this event and use the result.