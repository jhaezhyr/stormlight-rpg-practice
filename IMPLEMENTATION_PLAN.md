# Stormlight Duel - Implementation Plan

## 🚨 CRITICAL REMINDER FOR EVERY PHASE 🚨
**BEFORE STARTING ANY PHASE: Read the ENTIRE prompts/README.md file to ensure all specification details are captured, including user input requirements, command parsing, mechanics, and interaction patterns. This prevents missing important details and ensures specification compliance.**

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

### 2.2 Equipment System Foundation ✅
- [x] Create basic Weapon class with damage, traits, range
- [x] Create basic Armor class with deflect and traits
- [x] Implement weapon/armor states (carried, equipped, dropped)
- [x] Add inventory management to characters
- [x] Write tests for equipment system
- [x] **REFACTOR**: Organize equipment code into separate modules

## Phase 3: Enhanced Battlefield System ✅

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including user input requirements, command parsing, and interaction patterns.**

### 3.1 Position-Based Combat ✅
- [x] **READ SPEC**: Re-read prompts/README.md completely for Phase 3 requirements
- [x] Replace distance with absolute positions (P1 at 0, P2 at 30)
- [x] Add 3 random cover points within 100ft
- [x] Update movement to use positions instead of relative distance
- [x] Display battlefield with cover positions
- [x] Write tests for positioning system

### 3.2 Advanced Movement Actions ✅
- [x] **READ SPEC**: Re-read prompts/README.md for user input patterns and command parsing
- [x] Implement Advance action (with distance options)
- [x] Implement Retreat action (with distance options)
- [x] Add Disengage action (5ft movement, no reactive strike)
- [x] Implement reach-based combat zones
- [x] Write tests for all movement actions
- [x] **REFACTOR**: Consolidate movement logic

## Phase 4: Combat System Foundation

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including strike mechanics, test resolution, and user interaction flows.**

### 4.1 Strike Mechanics
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 4 requirements
- [ ] Implement basic Strike action with skill tests
- [ ] Add weapon reach and range calculations
- [ ] Implement hit/graze/miss mechanics
- [ ] Add damage calculation with deflect
- [ ] Support mainhand/offhand attacks with focus costs
- [ ] Write comprehensive strike tests

### 4.2 Reaction System
- [ ] **READ SPEC**: Re-read prompts/README.md for reaction timing and user prompts
- [ ] Add reaction tracking (1 per turn)
- [ ] Implement Dodge reaction
- [ ] Implement Reactive Strike reaction
- [ ] Add reaction timing and validation
- [ ] Write tests for reaction system
- [ ] **REFACTOR**: Clean up action/reaction architecture

## Phase 5: Advanced Actions

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including action mechanics, user prompts, and command syntax.**

### 5.1 Combat Actions
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 5 requirements
- [ ] Implement Brace action (cover/defensive weapons)
- [ ] Add Grapple action with Athletics tests
- [ ] Add Shove action (2-action cost)
- [ ] Implement Gain Advantage action with skill tests
- [ ] Write tests for all combat actions

### 5.2 Utility Actions
- [ ] **READ SPEC**: Re-read prompts/README.md for utility action mechanics and free actions
- [ ] Add Recover action with recovery die
- [ ] Implement Drop/Pick Up/Equip/Stow actions
- [ ] Add Use action for consumables
- [ ] Add End turn action
- [ ] Support free actions with `+` continuation
- [ ] Write tests for utility actions
- [ ] **REFACTOR**: Organize actions by category

## Phase 6: Test and Opportunity System

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including dice mechanics, plot die rules, and opportunity/complication selection.**

### 6.1 Core Testing Mechanics
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 6 requirements
- [ ] Implement d20 + trait skill tests
- [ ] Add advantage/disadvantage system
- [ ] Implement "raise the stakes" with plot die
- [ ] Add defense calculations and comparisons
- [ ] Write comprehensive test mechanics tests

### 6.2 Plot Die System
- [ ] **READ SPEC**: Re-read prompts/README.md for plot die mechanics and opportunity/complication options
- [ ] Create plot die with blank/complication/opportunity results
- [ ] Implement natural 1/20 triggers
- [ ] Add opportunity selection system (7 options)
- [ ] Add complication selection system (opponent chooses)
- [ ] Support stacking opportunities/complications
- [ ] Write tests for plot die system
- [ ] **REFACTOR**: Clean up dice and probability code

## Phase 7: Conditions and Status Effects

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including condition mechanics, effects, and interactions.**

### 7.1 Core Conditions
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 7 requirements
- [ ] Implement Surprised condition
- [ ] Add Restrained condition (from grapple)
- [ ] Implement Prone condition with standing mechanics
- [ ] Add Slowed condition with movement penalties
- [ ] Add "Had to Get Up" temporary condition
- [ ] Write tests for all conditions

### 7.2 Combat Conditions
- [ ] **READ SPEC**: Re-read prompts/README.md for combat condition interactions
- [ ] Add Braced condition from Brace action
- [ ] Implement advantage/disadvantage tracking
- [ ] Add temporary bonuses from Gain Advantage
- [ ] Support condition stacking and interaction
- [ ] Write comprehensive condition tests
- [ ] **REFACTOR**: Unify condition management system

## Phase 8: Weapons and Equipment

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including weapon traits, armor mechanics, and equipment interactions.**

### 8.1 Light Weapons Implementation
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 8 requirements
- [ ] Add all light weapons (Javelin, Knife, Mace, etc.)
- [ ] Implement weapon traits (Thrown, Quickdraw, Discreet, etc.)
- [ ] Add ranged weapon mechanics
- [ ] Support thrown weapon recovery
- [ ] Write tests for light weapons

### 8.2 Heavy Weapons Implementation
- [ ] **READ SPEC**: Re-read prompts/README.md for heavy weapon traits and mechanics
- [ ] Add all heavy weapons (Greatsword, Hammer, etc.)
- [ ] Implement reach bonuses (+5ft weapons)
- [ ] Add cumbersome trait mechanics
- [ ] Support two-handed weapon requirements
- [ ] Write tests for heavy weapons

### 8.3 Armor System
- [ ] **READ SPEC**: Re-read prompts/README.md for armor traits and requirements
- [ ] Implement all armor types with deflect values
- [ ] Add armor traits (Cumbersome, Presentable, etc.)
- [ ] Support strength requirements for armor
- [ ] Add armor state management
- [ ] Write comprehensive armor tests
- [ ] **REFACTOR**: Optimize equipment validation

## Phase 9: Advanced UI and Interaction

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including user input patterns, command shortcuts, and interaction flows.**

### 9.1 Enhanced User Interface
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 9 requirements
- [ ] Add player color coding (green P1, red P2)
- [ ] Implement single-letter command shortcuts
- [ ] Add `-` option for full action details
- [ ] Support `*` for raising stakes
- [ ] Improve help system with context-sensitive commands

### 9.2 Input Validation and Flow
- [ ] **READ SPEC**: Re-read prompts/README.md for input patterns (full name/single letter/number index)
- [ ] Add comprehensive command parsing
- [ ] Implement action availability checking
- [ ] Add detailed error messages with explanations
- [ ] Support command history and undo for development
- [ ] Write UI interaction tests
- [ ] **REFACTOR**: Separate UI from game logic

## Phase 10: Special Systems

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured, including special weapon mechanics and advanced features.**

### 10.1 Unarmed Combat
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 10 requirements
- [ ] Implement strength-based unarmed damage
- [ ] Add Athletics skill for unarmed attacks
- [ ] Support unarmed grappling mechanics
- [ ] Write unarmed combat tests

### 10.2 Advanced Weapon Features
- [ ] **READ SPEC**: Re-read prompts/README.md for advanced weapon traits and mechanics
- [ ] Add Loaded weapon mechanics with ammunition
- [ ] Implement Pierce trait (ignore deflect)
- [ ] Add Momentum trait bonuses
- [ ] Support Deadly trait instant defeats
- [ ] Write tests for advanced weapon traits

## Phase 11: Final Polish and Integration

**🚨 CRITICAL: Read the ENTIRE prompts/README.md file before starting this phase to ensure all specification details are captured and the final system matches the complete specification.**

### 11.1 Battle Flow Integration
- [ ] **READ SPEC**: Re-read prompts/README.md completely for Phase 11 requirements
- [ ] Connect all systems into cohesive battle flow
- [ ] Add battle start/end conditions
- [ ] Implement victory conditions and scenarios
- [ ] Add battle statistics and replay
- [ ] Comprehensive integration tests

### 11.2 Performance and Polish
- [ ] **READ SPEC**: Final review of prompts/README.md to ensure 100% specification compliance
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