# Stormlight Duel - Implementation Plan

This plan implements the full Stormlight Duel system as specified in prompts/README.md, building incrementally with tests and refactoring opportunities.

## Phase 1: Core System Refactor ✅
- [x] Initial version committed
- [x] Organized code into src/ directory structure
- [x] Basic character creation with traits
- [x] Turn order system (fast/slow turns)
- [x] Basic movement system
- [x] Simple REPL interface

## Phase 2: Updated Character System ✅
### 2.1 Trait System Overhaul ✅
- [x] Replace current 6 traits with new 6: Strength, Speed, Intellect, Willpower, Presence, Awareness
- [x] Implement trait allocation (12 points total, 0-4 per trait)
- [x] Calculate derived stats:
  - [x] Health = 10 + Strength
  - [x] Focus = 2 + Willpower
  - [x] Recovery Die based on Willpower (d4/d6/d8)
  - [x] Movement Rate based on Speed (20ft/25ft/30ft)
  - [x] Defenses: Physical, Mental, Spiritual
- [x] Add Skills system (based on traits)
- [x] Write comprehensive tests for new character system
- [x] **REFACTOR**: Clean up character creation and display

### 2.2 Equipment System Foundation
- [ ] Create basic Weapon class with damage, traits, range
- [ ] Create basic Armor class with deflect and traits
- [ ] Implement weapon/armor states (carried, equipped, dropped)
- [ ] Add inventory management to characters
- [ ] Write tests for equipment system
- [ ] **REFACTOR**: Organize equipment code into separate modules

## Phase 3: Enhanced Battlefield System
### 3.1 Position-Based Combat
- [ ] Replace distance with absolute positions (P1 at 0, P2 at 30)
- [ ] Add 3 random cover points within 100ft
- [ ] Update movement to use positions instead of relative distance
- [ ] Display battlefield with cover positions
- [ ] Write tests for positioning system

### 3.2 Advanced Movement Actions
- [ ] Implement Advance action (with distance options)
- [ ] Implement Retreat action (with distance options)
- [ ] Add Disengage action (5ft movement, no reactive strike)
- [ ] Implement reach-based combat zones
- [ ] Write tests for all movement actions
- [ ] **REFACTOR**: Consolidate movement logic

## Phase 4: Combat System Foundation
### 4.1 Strike Mechanics
- [ ] Implement basic Strike action with skill tests
- [ ] Add weapon reach and range calculations
- [ ] Implement hit/graze/miss mechanics
- [ ] Add damage calculation with deflect
- [ ] Support mainhand/offhand attacks with focus costs
- [ ] Write comprehensive strike tests

### 4.2 Reaction System
- [ ] Add reaction tracking (1 per turn)
- [ ] Implement Dodge reaction
- [ ] Implement Reactive Strike reaction
- [ ] Add reaction timing and validation
- [ ] Write tests for reaction system
- [ ] **REFACTOR**: Clean up action/reaction architecture

## Phase 5: Advanced Actions
### 5.1 Combat Actions
- [ ] Implement Brace action (cover/defensive weapons)
- [ ] Add Grapple action with Athletics tests
- [ ] Add Shove action (2-action cost)
- [ ] Implement Gain Advantage action with skill tests
- [ ] Write tests for all combat actions

### 5.2 Utility Actions
- [ ] Add Recover action with recovery die
- [ ] Implement Drop/Pick Up/Equip/Stow actions
- [ ] Add Use action for consumables
- [ ] Add End turn action
- [ ] Support free actions with `+` continuation
- [ ] Write tests for utility actions
- [ ] **REFACTOR**: Organize actions by category

## Phase 6: Test and Opportunity System
### 6.1 Core Testing Mechanics
- [ ] Implement d20 + trait skill tests
- [ ] Add advantage/disadvantage system
- [ ] Implement "raise the stakes" with plot die
- [ ] Add defense calculations and comparisons
- [ ] Write comprehensive test mechanics tests

### 6.2 Plot Die System
- [ ] Create plot die with blank/complication/opportunity results
- [ ] Implement natural 1/20 triggers
- [ ] Add opportunity selection system (7 options)
- [ ] Add complication selection system (opponent chooses)
- [ ] Support stacking opportunities/complications
- [ ] Write tests for plot die system
- [ ] **REFACTOR**: Clean up dice and probability code

## Phase 7: Conditions and Status Effects
### 7.1 Core Conditions
- [ ] Implement Surprised condition
- [ ] Add Restrained condition (from grapple)
- [ ] Implement Prone condition with standing mechanics
- [ ] Add Slowed condition with movement penalties
- [ ] Add "Had to Get Up" temporary condition
- [ ] Write tests for all conditions

### 7.2 Combat Conditions
- [ ] Add Braced condition from Brace action
- [ ] Implement advantage/disadvantage tracking
- [ ] Add temporary bonuses from Gain Advantage
- [ ] Support condition stacking and interaction
- [ ] Write comprehensive condition tests
- [ ] **REFACTOR**: Unify condition management system

## Phase 8: Weapons and Equipment
### 8.1 Light Weapons Implementation
- [ ] Add all light weapons (Javelin, Knife, Mace, etc.)
- [ ] Implement weapon traits (Thrown, Quickdraw, Discreet, etc.)
- [ ] Add ranged weapon mechanics
- [ ] Support thrown weapon recovery
- [ ] Write tests for light weapons

### 8.2 Heavy Weapons Implementation
- [ ] Add all heavy weapons (Greatsword, Hammer, etc.)
- [ ] Implement reach bonuses (+5ft weapons)
- [ ] Add cumbersome trait mechanics
- [ ] Support two-handed weapon requirements
- [ ] Write tests for heavy weapons

### 8.3 Armor System
- [ ] Implement all armor types with deflect values
- [ ] Add armor traits (Cumbersome, Presentable, etc.)
- [ ] Support strength requirements for armor
- [ ] Add armor state management
- [ ] Write comprehensive armor tests
- [ ] **REFACTOR**: Optimize equipment validation

## Phase 9: Advanced UI and Interaction
### 9.1 Enhanced User Interface
- [ ] Add player color coding (green P1, red P2)
- [ ] Implement single-letter command shortcuts
- [ ] Add `-` option for full action details
- [ ] Support `*` for raising stakes
- [ ] Improve help system with context-sensitive commands

### 9.2 Input Validation and Flow
- [ ] Add comprehensive command parsing
- [ ] Implement action availability checking
- [ ] Add detailed error messages with explanations
- [ ] Support command history and undo for development
- [ ] Write UI interaction tests
- [ ] **REFACTOR**: Separate UI from game logic

## Phase 10: Special Systems
### 10.1 Unarmed Combat
- [ ] Implement strength-based unarmed damage
- [ ] Add Athletics skill for unarmed attacks
- [ ] Support unarmed grappling mechanics
- [ ] Write unarmed combat tests

### 10.2 Advanced Weapon Features
- [ ] Add Loaded weapon mechanics with ammunition
- [ ] Implement Pierce trait (ignore deflect)
- [ ] Add Momentum trait bonuses
- [ ] Support Deadly trait instant defeats
- [ ] Write tests for advanced weapon traits

## Phase 11: Final Polish and Integration
### 11.1 Battle Flow Integration
- [ ] Connect all systems into cohesive battle flow
- [ ] Add battle start/end conditions
- [ ] Implement victory conditions and scenarios
- [ ] Add battle statistics and replay
- [ ] Comprehensive integration tests

### 11.2 Performance and Polish
- [ ] Optimize critical game loops
- [ ] Add comprehensive error handling
- [ ] Implement save/load functionality for debugging
- [ ] Add extensive logging for development
- [ ] Final code cleanup and documentation
- [ ] **FINAL REFACTOR**: Complete system architecture review

## Testing Strategy
- Unit tests for each component as it's built
- Integration tests after each major milestone
- Battle simulation tests for balance
- UI interaction tests for usability
- Performance tests for responsiveness

## Git Commit Strategy
- Commit after each completed checkbox item
- Tag major milestones (Phase completions)
- Use descriptive commit messages
- Create feature branches for major refactors

## Current Status: Phase 2 Ready
The basic foundation is in place. Next step is to start Phase 2 with the trait system overhaul.