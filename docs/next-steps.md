= Code
- [x] Move code over to new separated Events classes.
- [x] Check all event creation uses correct values.
- [x] Fix tick generator 
- [x] Move client time sync to [Interceptor], and finish time sync
- [x] Make tick generator testable
- [x] Finish server networking
- [x] Write UI input system
- [x] Write tests for everything
- [x] Change core event outputs from functions to streams
- [x] Change getStableState and getUnstableEvents to a stream. unstable runner then also outputs a stream. Only after the continuous switch, in extrapolator, do we convert to a function request system.
	- Undone this for now, as it doesn't handle future unstable events becoming stable.
- [x] Make everything generic to Event type
- [-] Write general-purpose input system.
  - Not going to do. Just gonna write one for this project.
- [x] Get server to send connect / disconnected statuses
	- [x] Add server-generated events
		- [x] Update makeEventSI in test helpers
	- [x] Networking module sends server-generated connection and disconnection events.
	- [x] Update tests
- [x] Get server to generate and send a serverID.
	- Going to do in example of init_data
- [x] Server sends all buffered events to newly joined players (until Re-Connection done)
	- [x] Working on stream_split_buffer module
	- [x] Change networking module to only have single-client stream
	- [x] Write new connect splitter module
	- [ ] Write tests for stream_split_buffer, and update tests for networking module
- [x] Put together final game
- [x] Make generic shared 'info sharer' module which sends all needed info like unstable_period, client_id, server_id
- [x] Tick driver wrapper
- [x] Extrapolation module
	- [x] Make compute driver use deltaTime.
	- [x] Fix driver. Looks wonky.
- [x] Interpolation module
- [ ] Re-connection module
	- [x] Allow state serialisation & deserialisation
	- [ ] Create Re-Connection server module. See line 1016
		- [-] Provides init_data module with saved state and events since.
		- [ ] Re-think syncing between init_data, stream_split_buffer, and reconnection. Current idea of updating all at the same time won't work. What if a client joins, stream_split_buffer sends all events, then all modules are updated, then client requests init_data.
		- [x] Sends clients requests for hash of state at timestamp
		- [x] Receives state hashes from all clients, compares, stops if mismatch
		- [x] With agreed hash, request state from client, compare against hash
		- [x] With agreed saved state, update saved state and events since.
		- [x] If client ignores hash request or state request, kick
		- [ ] Tell other clients when a state has been received (so they can discard their copy)
	- [ ] Create Re-Connection client module
		- [ ] Replies to server hash requests
		- [ ] Replies to server state requests
  	- [ ] Update init_data client
		- [ ] Passes initial state and events since into Core before any other events, using .addStream. Actually don't use .addStream, but add an argument to Core which is the 'initial events'. it will execute these first, then read in events from the stream.
- [ ] Shared computation module
- [ ] Look into "time warp" - computing based on each clients' local view.
	- With a client-server, TCP connection, all events are *received* at the same time.
	- Each client needs to keep track of the inputs they received, *in the order they received them*, for some period N seconds into the past at any given time.
	- Every generated client input event also stores the ID of the latest received event from the server (event ID = client ID + event ID).
	- In a clients' driver, when executing a particular player, it now has two possible views it can consider. One is the simple generated-timestamp order, the other is that player's local view at that time.
	- The engines can use this however they like. One example would be in an FPS: event generation time is used for everything, except hit-scan shots. When a player triggers a hit-scan shot with an event, the engine looks at the clients' local view to see if the shot would have hit.
	- ANTICHEAT NOTE: Server must make sure that the stored latest-received-event-from-server ID increases monotonically from each player, and is within reasonable bounds (check maths guarantees about latency cutoff).
- [ ] Ensure that all server checks on are also done on client. They're just done on server to reduce bandwidth load, but if server CPU is overloaded, we can turn this off and let clients deal with it. Should throw error.
	- Event arrives at server too late
	- Server sends events with non-monotonic serverReceivedTimestamp
- [ ] Event combiner module, which bundles network packets to save bandwidth (less overhead)
- [ ] Server sends NACK to removed events rather than ignoring
- [ ] Change getCurrentState and currentUnstableEvents back to Streams. Remember to deal with future events becoming present. Either have a timer callback, or maybe disallow future events.
- [ ] Check functions aren't unnecessarily `async`
- [ ] Remove redundant info from EventClientInFromLocal - Line 950
- [ ] Write tests for new Events PreCore
- [ ] Move late client connection into Core Server module. Make it part of the API. The whole system should be implementable just by providing implementations for the cores. 
- [x] Add deltaTime as input to driver?
- [ ] Rename 'game time' to 'run time' or something game-agnostic
- [ ] Get tick_generator to only start generating ticks when game starts
- [ ] Test stream_inserter etc classes too
- [ ] Make engine running, if catching up loads, make it run in batches, then release to async to render, so app not left unresponsive.
- [ ] Get tick_generator to generate ticks up to current game time. They should be synced regardless of when a client joined.
- [ ] Get client to produce event when server closed.
- [ ] Figure out how to set framerate. Timer setstate is jank.
- [ ] Have core initialise method be awaited. This way the non-DAN UI can display 'loading'. This includes awaiting for setup and inputting buffered events into the core, until the number of buffered events is zero.
- [ ] Kick players who send invalid events.
- [ ] In driver, check tick event, and connect/disconenct event senderID. -1 and serverId respectively.
- [ ] Get server to send occasional 'clock sync' events, purely for clientCores to bake in old events and not have too many unstable events.
- [ ] For smoother module the weight average calculation is wrong. A states value isn't just the value at that point in the curve, but the integrated area from its point backwards up to the state before it's. So we want users to provide the *integration* of the curve they want.
- [ ] Make a 'determinacy' tester? Run on many clients and they report on the first tick they go out of sync?
- [ ] Have max state size and event size to prevent clients from sending huge events wasting bandwidth or sending huge serialised states wasting memory.
- [ ] Time warp. Server must check that the event ID in 'last server event received' has already been received at the server. (Client can't use future event).
- [ ] Produce RNG library (must do, I said I did!)
- [ ] Provide diverging state testing library.
- [ ] Change tick generator to also produce ticks from local events. Doesn't make any sense to wait just for server events? We do have the periodic generator though so it should be fine.
- [ ] When in debug mode, the engine explicitely tests for determinacy and immutability. Re-runs same event and compares state. Serialises state at different points in time to ensure it's the same (as serialised is String and defo immutable).
- [ ] Consider renaming 'event' to 'input'?
- [ ] Rename unstable list and unstable period? Relate to 'acceptance window'?
- [ ] Change unit tests to use proper stream testing methods.
- [ ] Re-write tick generator.
- [ ] Remove debug local event
- [ ] make smoother use integral for area



= Dissertation
- [x] Continue down diss.typ bullet points, adding to google doc draft 3
- [x] Then move to rest of log.md from where bullet points stopped, and add to google doc. Line 776
- [x] Then copy information from all obsidian pages
- [ ] Then check nothing was missed from google doc draft 2
- [ ] and google doc draft 1
- [ ] Finish draft 3
	- [ ] Introduction
    	- [x] Objectives
	- [ ] Preparation
		- [ ] Explain current replication approaches. 
		- [ ] Explain consistency models
		- [ ] Introduce current quality-of-life features in modern games
		- [x] Explain Flutter and dart
		- [x] Requirements analysis
	- [ ] Implementation
		- [x] Add descriptions to respository overview
	    - [ ] Theory
			- [x] Theory, explain overview of server-client engine
			- [x] Unstable period, explain not using a persistent data structure
			- [x] Opponent prediction
			- [x] Re-Connection module
			- [ ] Independent computation
			- [ ] Efficient re-computation
			- [ ] Time warp, modifications required
			- [x] Add reasons to summary of server anti-cheat checks
			- [x] Misc 'in' items to be sorted
		- [ ] Implementing engine
    		- [x] Overview of code structure
			- [x] Helpers classes, StreamInterceptor, StreamInserter
			- [x] Tick generator, explain implementation
			- [x] Extrapolation and interpolation
			- [ ] Reducing bandwidth
    	- [ ] Building the game
        	- [ ] Input system
        	- [ ] Resulting code, looks nice, all modules fit together
        	- [ ] 3D renderer
		- [ ] Re-order headings to improve flow
		- [ ] Consider audio with rollback engine
	- [ ] Evaluation
    	- [x] Come up with exact tests and graphs to use
- [ ] Draft 4
	- [ ] Add connecting and introductory sentences to each chapter, section, and paragraph where needed
	- [ ] Re-write headings so they make sense without having read the dissertation.
		- Change heading levels to represent amount of content inside, rather than just nesting level.
	- [ ] Re-write paragraphs to follow form in Writing for Computer Science
		- [ ] Justify
		- [ ] Add content from C&DS
		- [ ] What is the balance between:
			- Just showing what I've made <- IMPORTANT
			- Explaining the design choices and considerations <- IMPORTANT
			- Walking through problem solving
			- Demonstrating that it works
		- [ ] Be more explicit about the "attack surface" and my "defences"
		- [ ] Choose consistent keywords and names. 
			- Is the theoretical core a "game engine"? It's a state repl' system.
			- Use "input" instead of "event"?
			- "misbehave" instead of "cheat".
	- [ ] Re-order paragraphs to flow better
		- Should introduction/explanation of my solution be in Preparation or Implementation? Depends on what I want to say: was this known to me before designing the engine, or did I discover it during designing?
	- [ ] Move some side notes into footnotes?
	- [ ] Create diagrams in CeTZ
	- [ ] Show algorithms. Look at past disses to see which sort of algorithms to include
	- [ ] Cite / prove everything. Better/worse, costs, etc.
	- [ ] Add proforma pages
    	- Word count: https://github.com/Jollywatt/typst-wordometer
	- [ ] Make new word definitions highlighted? Add a 'list of definitions' page at start which lists all definitions in order.
- [ ] Get reviewed
	- [ ] Andrew Moore
	- [ ] Ramsey
	- [ ] Andy Rice
	- [ ] Mikel
	- [ ] Dylan

Andrew feedback
- Make it clear what this dissertation's work is.
- The novelty is the game engine design, which I test with a quality implementation.
- There are also some aspects which I have solutions for but haven't implemented.
- There are also some aspects which I know are problems, but don't have solutions for.

- For the implementation, show how it meets the architecture's requirements, and prove that it does.

- defined precisely what i mean by the goals and requirements. 
    - e.g., what is "determinism"? same output if run twice? same output on different machines? all?

- I should make it clear from the outset what category each feature in the dissertation is in:
	1. Know it's an problem
	2. Know it's a problem and have a solution designed
	3. Have a solution which is tested with code
as well as
	1. Core functionality
	2. Optimisations
	3. Extra functionality
- The dissertation's implementation structure should be:
    1. Core engine architecture
    2. Implementation of core game engine
    3. Additional features / optimisations

Diagrams

Ramsey
- Go through mark scheme
- signpost each point somewhere
- For non-implemented features, one paragraph per feature, but you won't get any more marks compared to five pages. Put in appendix presumably.
    - Use language like "contribute to the field" "never been done before"
- Remove aims related to existing work.

- Proving game works - show very small thumbnails of game frames moving, then say see appendix for full details.