# Original prompt:

I'm going to make a remote frontend for a text-based game that I've been writing. Help me plan how it will go.

## Tech stack

Let's use modern Angular with Typescript for this frontend. The connection to the backend will primarily be via websocket.

## Single-page interface

The backend opens up a single endpoint, where a frontend can start a websocket connection. Then when the websocket is open, the backend sends JSON messages. The schema are something like this:

1. { type: "event", message: "...", interface: "..." }
2. { type: "hint", message: "...", interface: "..." }
3. { type: "prompt", message: "...", interface: "..." }

Any time a message is received, three text-display elements on the screen should update.

The "interface" will include my player's health, weapons available, and more. It should be displayed in the first element on the screen. It should have a fixed height, scrolling if the content is too long.

A prompt or a hint displays its message in the second text element. That element should be very prominent, since it's where the main stuff happens. It should have a fixed height. Content should be bottom-justified.

Then comes the answer text input line, including the "submit" button. The submit button should only be active when the most recent message was a "prompt." If the user types an answer and presses return or presses the submit button, it should send that answer back to the backend using the websocket. It should clear the text field, but keep the user's focus there. It should disable the submit button until the next "prompt" is received.

The event stream is a stream of events that should grow continually, with the most recent event(s) always visible at the top. So instead of replacing its contents when a new message comes in, the program should instead prepend the new message to the event stream element.

Make a plan that a medium-power LLM-powered coding agent (Claude Haiku 4.5) could follow to build this web app.

# Plan

#### Phase 1: Project Scaffolding & Core Architecture
Goal: Initialize the Angular project, set up the directory structure, and define the core Typescript interfaces.
1. Initialize Angular Project:
	- Create a new Angular 19+ (standalone components) project.
	- Enable strict mode and routing (though we'll use a single route initially).
	- Install necessary dependencies (e.g., standard Angular libs, perhaps a utility class library like Tailwind CSS for easy styling if desired, otherwise standard SCSS).
2. Define Data Models:
	- Create src/app/models/game-message.model.ts.
	- Define interfaces for GameMessage (base), EventMessage, HintMessage, and PromptMessage based on your JSON schema.
	- Define the InterfaceData type (health, weapons, etc.) to strictly type the "interface" payload.
3. Create WebSocket Service:
	- Create src/app/services/game-socket.service.ts.
	- Implement connect(url: string) method using standard WebSocket or RxJS/webSocket.
	- Expose an RxJS Subject or Observable for incoming messages ( messages$).
	- Implement a sendMessage(answer: string) method.
	- Handle connection lifecycle (open, close, error).
#### Phase 2: State Management & Reactive Logic
Goal: manage the flow of data between the WebSocket and the UI components without cluttering the view logic.
1. Game State Service:
	- Create src/app/services/game-state.service.ts.
	- Inject GameSocketService.
	- Create Signals (Angular 16+ reactivity) or BehaviorSubjects for:
		- playerInterface: (The current health/weapon stats).
		- currentPromptOrHint: (The active message for the central display).
		- eventLog: (An array of event messages).
		- isInputLocked: (Boolean, derived from whether the last message was a "prompt").
2. Message Parsing Logic:
	- Subscribe to the socket's messages$.
	- On "event": Prepend to eventLog. Update playerInterface.
	- On "hint": Update currentPromptOrHint. Update playerInterface. Ensure input remains locked (or unlock if your logic dictates).
	- On "prompt": Update currentPromptOrHint. Update playerInterface. Set isInputLocked to false.
#### Phase 3: Component Implementation (The "View")
Goal: Build the visual elements according to your layout requirements.
1. Main Layout Component ( GameContainerComponent):
	- Create a CSS Grid or Flexbox layout.
	- Structure:
		- Top Section: Player Interface (Fixed height, scrollable).
		- Middle Section: Main Display (Prominent, fixed height, bottom-justified).
		- Bottom Section: Input Area (Text field + Submit button).
		- Footer/Side: Event Stream (Prepending log).
2. Player Status Component ( PlayerStatusComponent):
	- Bind to gameState.playerInterface.
	- Render health, weapons, etc.
	- Styling: Set overflow-y: auto and a fixed height (e.g., 20vh).