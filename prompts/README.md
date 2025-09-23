# Stormlight Duel

A Python CLI MUD-style dueling game where two characters battle using a turn-based system.

## Features

- **Character Creation**: Each character starts with randomized health (10-15), focus (3-5), and six traits (1-3 each)
- **Turn System**: Choose between fast turns (2 actions) or slow turns (3 actions)
- **Distance Mechanics**: Players can move closer or farther apart, affecting available actions
- **Action System**: Attack, move, rest, and more actions available
- **Condition System**: Extensible framework for status effects and temporary conditions

## How to Play

1. Run the game:

   ```bash
   python3 main.py
   ```

2. Enter names for both players

3. Each turn:
   - Choose turn type (fast/slow)
   - Execute actions based on turn order
   - Continue until one player is defeated

## Game Mechanics

### Movement System

- Characters start 30ft apart
- Each character has a speed of either 25ft or 30ft per turn
- Use negative distance to move closer, positive to move away
- Cannot move closer than 5ft apart
- Movement is capped by your speed stat

### Commands

- `help`: Show game help
- `status`: Display current game state
- `actions`: Show available actions
- `quit`: Exit game

### Prompting the user for input

The user represents both players. Prompts will indicate which player's turn it is using both player name and color (green for P1 and red for P2).

Some of the things that will require player input:

- What type of turn to take (fast or slow).
- What action to take next on your turn.
- Whether to graze or miss when you would otherwise miss an attack.
- Which opportunity to choose when you gain one.
- Which complication to choose when your opponent gains one.
- Whether to dodge when your opponent attacks you.
- Whether to Reactively Strike when your opponent retreats.
- Details about the action you are taking, such as how far to move when you advance or retreat, or which weapon to use when you strike.
  - Some actions will have a default effect. Other actions will prompt the user for clarification or further details. When taking an action, the user may always include `-` in order to be prompted for the full list of options for that action. Even if the action doesn't need any further input, the `-` option will still be accepted, and will require confirmation from the user before proceeding.

Some things do not require player input:

- Raising the stakes is an option for all actions that require a test. However, the user will not be prompted to raise the stakes. They must include a `*` in their action command to indicate they want to raise the stakes.
- Die rolls do not require the user's input.

Generally, we show the user all the commands they can take at a given time. We don't show them commands they can't take, such as the Brace action when they are not near cover or wielding a Defensive weapon. However, if the user types the command name, we still parse it for what it is; we simply tell the user they can't take that action right now and why. Similarly, if the player has already spent their reaction, we don't prompt them to say whether to Reactively Strike when their opponent retreats, or whether to Dodge when their opponent attacks.

As often as possible, if we present the user with a list of options to choose from, we will allow them to choose by 1) typing the full name of the option, 2) by typing a single-letter version of the option, or 3) typing the number index of the option from the list. The single-letter version is shown by putting the letter in parentheses in the list of options. For example, when choosing a turn type, the user sees `(f)ast` and can type `fast` or `f` to choose a fast turn. The first word of a command can be any of these three options. The arguments and flags to the command (like 10 for 10ft of movement, or `+` to indicate they want to take a free action after their last action) come after that command word.

User input should always be case-insensitive. For example, `FAST`, `Fast`, and `f` should all be accepted as valid input for choosing a fast turn.

## Testing

Run the test script to verify core mechanics:

```bash
python3 test_game.py
```

---

# Stats

### Character Stats

- **Traits**: Bonuses for tests (1-3 each, summing up to 12 across them all)
  - Strength, Speed, Intellect, Willpower, Presence, Awareness
- **Health**: Hit points
  - Health = 10 + Strength
- **Focus**: Action resource. Based on your willpower:
  - Focus = 2 + Willpower
- **Recovery Die**: Die you roll to recover health and/or focus (1d6, 1d8, or 1d10). Based on your willpower:
  - 0 = d4
  - 1-2 = d6
  - 3-4 = d8
- **Movement Rate**: Movement per advance/retreat action. Based on speed trait:
  - 0 = 20ft
  - 1-2 = 25ft
  - 3-4 = 30ft
- **Deflect**: Reduces damage taken from strikes. Based on the armor you have equipped.
- **Defenses**: Difficulty for opponents to hit you with attacks. Based on your traits:
  - Physical = 10 + Strength + Speed
  - Mental = 10 + Intellect + Willpower
  - Spiritual = 10 + Presence + Awareness
- **Skills**: Bonuses for specific types of tests. Equal to your score in the corresponding trait:
  - Agility (Speed)
  - Athletics (Strength)
  - Heavy Weaponry (Strength)
  - Light Weaponry (Speed)
  - Stealth (Speed)
  - Thievery (Speed)
  - Crafting (Intellect)
  - Deduction (Intellect)
  - Discipline (Willpower)
  - Intimidation (Willpower)
  - Lore (Intellect)
  - Medicine (Intellect)
  - Medicine (Intellect)
  - Deception (Presence)
  - Insight (Awareness)
  - Leadership (Presence)
  - Perception (Awareness)
  - Persuasion (Presence)
  - Survival (Awareness)

# Battlefield

- Each combatant has a position on the battlefield. P1 starts at 0 and P2 starts at 30.
- Distance between players is the absolute difference between their positions. Any time the distance is displayed (after movement, at the start of a turn, etc), it should be shown in distances. For example, "Distance: X ft".
- There are also 3 "cover" points on the battlefield, at random positions within 100ft of the starting positions. Any time the field is displayed, the cover points should be shown by distances, as "Retreat 20ft or 30ft to cover, or advance 10ft to cover" (even if the enemy is closer than 10ft).
- All field positions should be represented as integers to avoid mathematical errors. Negative integers are perfectly acceptable positions.

# Battle actions

## Some definitions

- "Test": Roll a d20 and add the relevant trait bonus. You may choose to raise the stakes on any tests you make, which means you will simultaneously roll the plot die, possibly incurring a complication or opportunity.

## Turn Types

- **Fast Turn**: 2 actions, goes before slow turns
- **Slow Turn**: 3 actions, goes after fast turns
- Same types: Player 1 goes first

## Examples of actions (you get 2 or 3 per turn):

Some actions actually require 2 actions, such as the Shove action. These are indicated with `>>` in the table below. Others are free actions, like the Drop action. Most cost 1 action, indicated with `>` in the table below.

(x)yz | action cost | Description of effect
(x) is the shorthand form of the action

- (a)dvance | > | Move toward the opponent.
  - Examples: `a` (advance full speed), `a 10` (advance 10ft)
  - All movement actions must be in increments of 5ft
  - If you are already within 5ft of your opponent, you cannot advance closer. This 5ft is the same no matter what size your reach is.
- re(t)reat | > | Move away
  - Examples: `r` (retreat full speed), `r 10` (retreat 10ft)
- (b)race | > | If you are within 5ft of cover, or you have a weapon with the "Defensive" trait, gain the "Braced" condition.
- (d)isengage | > | Move 5ft away from the opponent. The opponent does not get a Reactive Strike.
- (g)ain advantage | > | You use one of your skills to seek the upper hand over your opponent, such as through clever tactics, unexpected feints, or superior strength. Explain how you are doing so, then make a test using a relevant skill against the enemy’s corresponding defense. On a success, you gain an advantage on your next test against that enemy that uses a different skill. For example, you can test Deduction test to guess at your foe’s next move, then use that advantage on your next Light Weaponry test; however, you can’t test Light Weaponry then use that advantage on another Light Weaponry test. (See “Skills” in chapter 3 for more examples of tests to Gain Advantage.)
- gra(p)ple | > | Through strength and skill, you grab your opponent or control their movements to keep them restrained and focused on you. Make an Athletics test against the Physical defense of a character within your reach. On a success, they become Restrained until either you become Unconscious or they are no longer within your reach.
  - Examples: `p` (grapple), `p *` (grapple and raise the stakes)
- sho(v)e | >> | Through strength and skill, you forcibly maneuver your opponent. Make an Athletics test against the Physical defense of a character within your reach. On a success, you push or pull the target 5 feet horizontally. If you successfully Shove a character who has grappled you, it ends the Restrained effect of grapple.
- stri(k)e | > | You attack using an unarmed attack or a weapon you’re wielding against the Physical defense of a target. You can use the Strike action more than once per turn, but each attack must use a different hand. If you attack using your offhand, you must spend 2 focus.
- (r)ecover | > | You take a deep breath and steel yourself. Roll your recovery die to recover health and/or focus. You may distribute your recovered health and focus as you choose. You can only use the Recover action once per battle.
- dr(o)p | | You drop one weapon or item of your choice that you are holding. It stays on the ground in exactly the location it was dropped.
- p(i)ck up | > | You pick up one weapon or item of your choice that is on the ground within 5ft of you. If you pick up a thrown weapon this way, you may equip it for free.
- e(q)uip | > | You equip a weapon or a piece of armor that you are carrying.
- (u)se | > | Use a consumable item you are carrying, such as a tonic.
- sto(w) | > | You stow a weapon or piece of armor that you are carrying. It becomes carried instead of equipped.
- e(n)d | | End your turn, foregoing all remaining actions.

If you use your last action, your turn will automatically end unless you include a `+` in the command of your last action. If you do that, then it will prompt you to take an available free action, even though you have 0 actions to spend. If you continue including + in your commands, you can keep being prompted to take free actions until you choose to end your turn.

## Examples of reactions (you get 1 at the start of your turn, to use anytime before the start of your next turn):

- (d)odge | 1 reaction and 1 focus | When an enemy you can see makes an attack against you, you can use your reaction to impose disadvantage on the attack roll. You must decide to use this reaction before the outcome of the attack is determined.
- (r)eactive strike | 1 reaction and 1 focus | As an enemy retreats, you use the opening to attack. When an enemy voluntarily leaves your reach (your reach depends on your weapon, but is always at least 5ft), you can use this reaction and spend 1 focus to make a melee weapon attack against the enemy’s Physical defense.

## Strike mechanics

Strikes can only be done if your opponent is in your reach. If you are unarmed, your reach is 5ft. Many melee weapons increase your reach. Some are ranged weapons, which don't rely on your reach; instead, they can be used from a short range distance at full strength, or from a long-range distance with disadvantage. Some weapons are thrown, which can be used as melee weapons within your reach, or thrown at short or long range; if you throw a weapon, you must pick it up to use it again.

1. Pay the focus cost for the attack. If you are using your offhand, pay 2 focus. If you attack with your main hand, it's free.
2. If you have advantage, choose which die to apply it to. If you have multiple advantage, you must apply the advantages to different dice. If you apply disadvantage and advantage to the same roll, the effects cancel each other out. Also decide whether you'll be raising the stakes. Your enemy may choose to dodge, giving you disadvantage on your attack roll.
3. Make a skill test (roll a d20 and add relevant skill bonus) using the appropriate skill for the weapon or unarmed attack you are using. Simultaneously, roll the damage die for your weapon. If you raised the stakes, also roll the plot die.
   1. Resolving advantage and disadvantage:
      1. If you have advantage on the attack roll, roll two d20s and take the higher result. If you have disadvantage, roll two d20s and take the lower result.
      2. If you have advantage on the damage roll, roll two damage dice and take the higher result. If you have disadvantage, roll two damage dice and take the lower result.
      3. If you have advantage on the plot die, roll two plot dice and take the better result. If you have disadvantage, roll two plot dice and take the worse result.
      4. Resolving the plot die:
         1. The plot die has three possible results: blank (no effect), a complication (something bad happens to you), or an opportunity (something good happens to you).
4. Resolve the attack.
   1. If your test result is equal to or greater than the target's Physical defense, you hit. Otherwise, you may choose to graze (see below) or miss.
   2. If you hit, reduce your opponents hit points by (damage roll + weapon's damage bonus - enemy's deflect).
   3. If you graze, reduce your opponent's hit points by (damage roll - enemy's deflect).
   4. If you miss, no damage is dealt.

## Conditions

- Surprised: While Surprised, you lose any reactions, you don’t gain a reaction at the start of combat or on your turn, you can’t take a fast turn, and you gain one fewer actions. Remove this condition after your next turn.
- Restrained: While Restrained, you cannot advance, retreat, or disengage. You gain a disadvantage on all tests other than those to escape your bonds. If you are Restrained by grapple, you escape your bonds with a Shove.
- Prone: While Prone, you are lying flat on the ground. While Prone, you are Slowed and melee attacks against you gain an advantage. You can use the Brace action without cover. You can stand up and end this condition as a free action. After you do, your movement rate is reduced by 5 until the start of your next turn.
  - The condition of reduced movement rate is called "Had to Get Up".
- Slowed: While Slowed, your movement rate is halved (rounded up). If you become Slowed in the middle of movement, halve your remaining movement (rounded up).
- Gained advantage(x): You have advantage on your next test using skill `x` against the target that granted you this advantage. After you use that advantage, remove this condition. You may only have one "Gained advantage" condition at a time, no matter what the skill `x` is.
- Cooldown(x): You cannot strike with the hand `x` until the start of your next turn. `x` is either "main" or "offhand". You may have up to two "Cooldown" conditions at a time, one for each hand.

### Armed conditions

- Each weapon may be in one of the following states:

  - Carried: The weapon is on your person but not in hand. You can draw it as an action. Unless you start the battle surprised, you automatically draw a weapon to your mainhand at the start of combat.
  - Equipped: You have the weapon in hand and can use it normally. You can equip one weapon in your main hand and your offhand each.
  - Dropped: The weapon is on the ground. A character may drop a weapon as a free action. Any character can pick it up as an action.

- Armor can also be equipped or unequipped. All armor starts out equipped:
  - Carried: The armor is on your person but not worn. You can don it as an action.
  - Equipped: You are wearing the armor and gain its benefits. You can doff it as an action.
  - Dropped: The armor is on the ground. A character may drop armor as a free action. Any character can pick it up as an action.

## Opportunities and Complications

Various game effects will give you an opportunity or a complication.

- Rolling them on the plot die.
- Rolling a natural 20 on any test gives you an opportunity.
- Rolling a natural 1 on any test gives you a complication.

Opportunities and complications can stack. Notice that a die roll that wasn't taken, like when you have advantage and take the higher die, will not trigger opportunities or complications.

If you roll an opportunity, you pick one of the following benefits for yourself. If you roll a complication, your opponent picks one of the following detriments for you.

1. (r)ecover: Gain 1 focus
2. (d)istract: Your enemy is distracted, granting an advantage on attacks against them.
3. di(s)arm: You disarm your opponent, causing them to drop one weapon or item of your choice that they are holding.
4. sha(k)e: Your opponent is shaken by something in combat and loses 1 focus.
5. (e)scape: Your opponent cannot make a Reactive Strike on you till the next turn starts.
6. (c)ritical: You score a critical hit. You may choose to maximize any die rolled instead of taking the rolled value.
   1. For example, if you roll a d8 for damage, you can choose to deal 8 damage plus the weapon's damage bonus instead of the rolled value. Or if you've rolled a d20 for an attack roll, you can choose to treat it as a 20, although you won't incur any additional opportunities or complications from that. You could also choose to maximize a plot die to get an opportunity.
7. ca(n)cel: Cancel an unresolved complication or your opponent's unresolved opportunity.

# Armor

## Armor traits

- Cumbersome [X]. To wear this armor easily, your Strength score must be equal to or greater than the number indicated in brackets. If your Strength is lower than that number, you’re Slowed while wearing this armor and you gain a disadvantage on all tests that use your Speed attribute.
- Dangerous. Your enemy can spend a complication that you gain while wearing this armor to cause your uncontrolled motion to injure yourself, dealing 2d6 impact damage.
- Presentable. This unobtrusive armor is presentable to wear in public in a non-military context. You don’t suffer undue attention for wearing this armor or gain a disadvantage on tests for doing so in conversations.
- Unique. This armor has unique rules detailed immediately following the word “Unique” in the Armor table (for example, “Unique: loses Cumbersome trait”).

## Armor table

| Type        | Deflect | Traits         | Expert Traits                                     |
| ----------- | ------- | -------------- | ------------------------------------------------- |
| Uniform     | 0       | Presentable    | —                                                 |
| Leather     | 1       | —              | Presentable                                       |
| Chain       | 2       | Cumbersome [3] | Unique : loses Cumbersome trait                   |
| Breastplate | 2       | Cumbersome [3] | Presentable                                       |
| Half Plate  | 3       | Cumbersome [4] | Unique : Cumbersome [3] instead of Cumbersome [4] |
| Full Plate  | 4       | Cumbersome [5] | —                                                 |

# Weapons

## Weapon traits

- Cumbersome [X]. To wield this weapon easily, your Strength score must be equal to or greater than the number indicated in brackets. If your Strength is lower than that number, you gain a disadvantage on all attacks using this weapon and are Slowed while wielding it.
- Dangerous. When you attack with this weapon, your opponent may spend a complication to cause you to also accidentally graze an ally within the weapon’s reach or range. This deals the usual damage for a graze.
- Deadly. When you hit a target with this weapon, you can spend an opportunity to cause the target to be immediately defeated.
- Defensive. While wielding this weapon, you can use the Brace action without cover nearby.
- Discreet. Ignore. This weapon is less obtrusive than others, and thus less likely to be confiscated in secure settings. In non-combat scenes, you gain an advantage on any test you make to disguise this weapon, to hide it on your person, or to convince others not to take it from you.
- Fragile. When you attack with this weapon, your enemy can spend one of your complications to cause it to break after the attack is resolved.
- Indirect. Ignore. This ranged weapon can arc shots over cover and obscuring terrain. If a target isn’t in your line of effect but you can sense them, you can still attack them with this weapon if there’s a reasonably open path for your projectile to indirectly arc to them. Your target can’t benefit from the Brace action against attacks made with this weapon.
- Loaded [X]. This weapon stores ammunition equal to the number indicated in brackets. To make a ranged attack with this weapon, you must spend 1 stored ammunition. As an action, you can re(l)oad this weapon to full ammunition. When you are attacking with this weapon, your enemy can spend a complication to reduce your stored ammunition; after they do, the weapon only has only one shot remaining.
- Momentum. When you attack using this weapon, if you already moved at least 10 feet in a straight line toward your target on this turn, you gain an advantage on the attack.
- Offhand. While wielding this weapon in your offhand, it only costs you 1 focus (instead of 2) to Strike with it.
- Pierce. This weapon’s damage can’t be reduced by the target’s deflect value.
- Quickdraw. You can equip this weapon as a free action.
- Thrown [X/Y]. You can throw this weapon at a target, making a ranged attack when you do. The two numbers in brackets express the weapon’s short and long range; as with ranged weapons, you gain a disadvantage when attacking a target outside short range. Once the weapon is thrown, it is dropped until you recover it from your target.
- Two-Handed. You must wield this weapon in two hands, not just one. When you attack with it, it uses both hands.
- Unique. Ignore. This weapon has unique rules. These are detailed either in the weapon description or immediately following the word “Unique” in the Weapons table (for example, “Unique: loses Two-Handed trait”).

## Things to ignore

- Any traits marked "Ignore" are not implemented in this version of the game.
- Weights and prices.
- Anything with Unique traits, unless there's a clear inline explanation with it.
- Any expert traits.
- Improvised weapons.

## Damage types

- Keen, impact. Normal damage type. No special properties.

## Weapon table

### Light Weaponry

| Type       | Damage     | Range           | Traits               | Expert Traits                  | Weight | Price  |
| ---------- | ---------- | --------------- | -------------------- | ------------------------------ | ------ | ------ |
| Javelin    | 1d6 keen   | Melee           | Thrown [30/120]      | Indirect                       | 2 lb.  | 20 mk  |
| Knife      | 1d4 keen   | Melee           | Discreet             | Offhand, Thrown (20/60)        | 1 lb.  | 8 mk   |
| Mace       | 1d6 impact | Melee           | —                    | Momentum                       | 3 lb.  | 20 mk  |
| Rapier     | 1d6 keen   | Melee           | Quickdraw            | Defensive                      | 2 lb.  | 100 mk |
| Shortspear | 1d8 keen   | Melee           | Two-Handed           | Unique: loses Two-Handed trait | 3 lb.  | 10 mk  |
| Sidesword  | 1d6 keen   | Melee           | Quickdraw            | Offhand                        | 2 lb.  | 40 mk  |
| Staff      | 1d6 impact | Melee           | Discreet, Two-Handed | Defensive                      | 4 lb.  | 1 mk   |
| Shortbow   | 1d6 keen   | Ranged [80/320] | Two-Handed           | Quickdraw                      | 2 lb.  | 80 mk  |
| Sling      | 1d4 impact | Ranged [30/120] | Discreet             | Indirect                       | 1 lb.  | 2 mk   |

### Heavy Weaponry

Notice that the "Range" of some of these weapons includes a "+5". This means that when you use the weapon in melee, its reach is 5+5=10ft instead of the usual 5ft.

| Type       | Damage      | Range            | Traits                 | Expert Traits                  | Weight | Price  |
| ---------- | ----------- | ---------------- | ---------------------- | ------------------------------ | ------ | ------ |
| Axe        | 1d6 keen    | Melee            | Thrown [20/60]         | Offhand                        | 2 lb.  | 20 mk  |
| Greatsword | 1d10 keen   | Melee            | Two-Handed             | Deadly                         | 7 lb.  | 200 mk |
| Hammer     | 1d10 impact | Melee            | Two-Handed             | Momentum                       | 8 lb.  | 40 mk  |
| Longspear  | 1d8 keen    | Melee [+5]       | Two-Handed             | Defensive                      | 9 lb.  | 15 mk  |
| Longsword  | 1d8 keen    | Melee            | Quickdraw, Two-Handed  | Unique: loses Two-Handed trait | 3 lb.  | 60 mk  |
| Poleaxe    | 1d10 keen   | Melee            | Two-Handed             | Unique: Melee [+5]             | 5 lb.  | 40 mk  |
| Shield     | 1d4 impact  | Melee            | Defensive              | Offhand                        | 2 lb.  | 10 mk  |
| Crossbow   | 1d8 keen    | Ranged [100/400] | Loaded [1], Two-Handed | Deadly                         | 7 lb.  | 200 mk |
| Longbow    | 1d6 keen    | Ranged [150/600] | Two-Handed             | Indirect                       | 3 lb.  | 100 mk |

### Special Weapons

| Type                 | Skill                  | Damage                 | Range            | Traits                        | Expert Traits                 | Weight     | Price       |
| -------------------- | ---------------------- | ---------------------- | ---------------- | ----------------------------- | ----------------------------- | ---------- | ----------- |
| Improvised Weapon    | Same as similar weapon | Same as similar weapon | Melee            | Fragile                       | Unique                        | —          | —           |
| Unarmed Attack       | Athletics              | See table below        | Melee            | Unique                        | Momentum, Offhand             | Weightless | —           |
| Half-Shard           | Heavy Weaponry         | 2d4 impact             | Melee            | Defensive, Two-Handed, Unique | Momentum                      | 10 lb.     | 2,000 mk    |
| Shardblade           | Heavy Weaponry         | 2d8 spirit             | Melee            | Dangerous, Deadly, Unique     | Unique: loses Dangerous trait | 4 lb.      | Reward only |
| Shardblade (Radiant) | Heavy Weaponry         | 2d8 spirit             | Melee            | Deadly, Unique                | —                             | Weightless | Talent only |
| Warhammer            | Heavy Weaponry         | 2d10 impact            | Melee            | Cumbersome [5], Two-Handed    | Unique                        | 150 lb.    | 400 mk      |
| Grandbow             | Heavy Weaponry         | 2d6 keen               | Ranged [200/800] | Cumbersome [5], Two-Handed    | Pierce                        | 20 lb.     | 1,000 mk    |

Unarmed damage based on your strength:

- 0-2 = 1 damage (no die roll)
- 3-4 = 1d4 damage
