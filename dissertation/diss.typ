
#set page("a4")

#let author = "Dan Wendon-Blixrud"
#let project_supervisor = "Prof Andrew Moore"
#let project_checkers = "Prof Alan Blackwell and Prof Srinivasan Keshav"
#let project_dos = "Dr Ramsey Faragher"
#let bgn = "2266F"
#let title = "Distributed Anti-cheat Networking"
#let today = datetime(year: 2023, month: 10, day: 20)


#set page(numbering: "1", margin: 2cm)
#show bibliography: set heading(numbering: "1.")
#show heading: it => {
	v(0.5em)
	it
}
#set text(size: 12pt)
#set heading(numbering: "1.")
#set par(justify: true, first-line-indent: 0.5in)
#show par: set block(spacing: 0.65em)

#pagebreak()

= Acknowledgements

- Prof Andrew Moore
- Locky Baker (listening to ramblings of initial version)
- Quompscis
- Friends

#pagebreak()

*Project Originator:* #author \
*Project Supervisor:* #project_supervisor \
*Project Checkers:* #project_checkers \
*Director of Studies:* #project_dos


#outline(fill: repeat("."), indent: auto)



= Introduction

writing online multiplayer video games is hard. you need to make sure people cant cheat, as they will want to. the first way people try to cheat is by changing the packets they send to the server, by modifying the client or changing packets as they leave.

most modern research focusses on far more complex techniques such as machine learning and kernel-level drivers to scan your computer. this might make you think that the first problem of spoofing packets doesn't exist, but it is still prevalent. most small games aren't designed against it, and there are many popular games which don't either. 

some anticheats are designed to work without it, and detect cheating in a system where cheating isnt prevented. they have a very hard job, which is uncnecessary. wasting time on patching high level problems which could be solved at the core.

the problem is that the problem solutions to this problem arent great. the first solution is checking on the server that all client packets and movement are okay. this is basically simulating all of the clients on the server. this is bad because it is expensive and doesnt scale well. 

the second solution problem is that even if you have the money to run the server side simulation of all clients, all existing solutions are custom built for each game, meaning that its impossible to re-use the code either because its copyrighted code, or because the code is specifically designed for that type of game.

the third solution is to run your game in a peer-to-peer based network, where any conflicts in game state is resolved by majority vote. this is bad because if a majority of a lobby are hackers, then everyone else is at their mercy and cant play the game. this may be unlikely to happen if games are randomly assigned, but often games allow you to choose some of the people you play with.

my solution solves these problems. first, my solution will be compeltely game agnostic, meaning it can be extended and combined and built upon with highly modulearised modules to fit the behaviour any game could need. if an existing wrapping module doesnt do what you need it to, you can just build your own, without needing to rebuild the entire system. it will be open source and usable to build games

second, my solution will not run client simulation on the server, but will instead distribute the computational load of running and checking all clients across the clients playing in the lobby. this is similar to the peer-to-peer network in this regard.

third, unlike the peer-to-peer network, my solution cannot be overrun by hackers. the computation to check other players is only distributed to other players who you can trust. this could be manually assigned, or perhaps based on reputation systems with reputation built up from playing from a long time, and lost instantly once you're found to be hacking once. the asymetry makes it effective - its hard to gain reputation and be trusted to compute for others, but as soon as you're found to cheat you lose it all. as soon as a single conflict in game state is found, the server kicks in and simulates the last few seconds from the last confirmed game state up to the current point of conflict, and marks anyone who sent invalid game state as a cheater. as mentioned with reputation, this may be a heavy penalty. the only way it could be overrun by hackers is if all players are hackers and the server never sees a conflict in game state and never kicks in to check, or if all hackers are trusted by everyone else and their results never conflict with anyone else's real data. trusting other players is always optional, and is only required to improve performance. the chances of a hacker being unnoticed is very unlikely, especially if the automatic reputation trust based system is random so they cannot guarantee they will not be trusted.


this approach requires modifying a game engine at its core, so any existing popular game engine will be impossible to implement into. flutter is great because its likely to grow its game development scene large, but its small right now. its cross platform aside from consoles, so has a wide audience potential of desktop and mobile. its performant and gives you full control over graphics. a great game dev platform.

the core module will be developed, and an extremely simple game will be developed using it as a test framework. some flexible modules will be built as part of the game.

there are four primary downsides to this approach. first, it requires game developers to build their game in a new way of thinking, making it harder the first time. second, it requires complete computational consistency across all platforms, which can be difficult with float operations. this can be solved by simulating these aspects in software, but this again makes development more difficult, and makes performance worse. looking into solving this may ne outside the scope of this dissertation, but know that it is a very solvable problem, just requires some careful thought. thirdly, this approach can be very computationally heavy, depending on how many other players you are playing with. if you trust no one, you must simulate every other player yourself, and re-simulate parts of the game state when packets arrive late and must be inserted into the past (causing small versions of the butteryfly effect). there are further optimisations involving only re-computing state which depends on new events received, which may again be outside the scope of this dissertation. lastly, this system has a simple conflict resolution algorithm, which simply executes all player's inputs in the order and at the time they were actually pressed in real-time (by inserting them into the past and re-computing if they arrived late). this can be bad for FPS style games, where users expect that if their shot hit on their screen, that it counts, as it could be very frustrating to then have it undone. this can additionally be solved by each client computing all other clients with the information the other client had at the time, but this increases computational complexity again. this is likely beyond the scope of this dissertation.


the benefits of this project is that building online multiplayer games which are secured at their core becomes free when built with this system. its super easy. lots of money is spent on anticheat, and many games are destroyed because they are overrun by hackers. trying to add anticheat on top of a game which is insecure at its core is very expensive and ineffective, and adding a secure core to a game after it is built is very difficult because it requires rewriting the core fundamentals of the game engine, and changing the network protocols making different versions incompatible with each other. building it the right way from the start is the most effective way - all developers can use this system, add the parts they need, build anything missing, and have a secure system ready to go. they don't need expensive server setups to do loads of computation. it makes developing secure online multiplayer games accessible to everyone.


the outcomes???

---

= >> Second Attempt at Introduction


Write for someone of Josh Bird's competence level.


anticheat is important

the type of anticheat we're looking at 

good qualities of core anticheat

existing approaches don't tick all the boxes

why this is a problem

my solution which ticks all the boxes

the limitations of my solution

paper introduces new approach, implements it, uses it, evaluates it

potential benefits of my solution


**anticheat is important**

online multiplayer games are popular and many people try to cheat. companies want to stop this because normal players won't play if there are cheaters. developing anticheat is a subsection of cybersecurity and an adverserial task. [cite paper which talked about the effects of cheaters on games]. 

**the type of anticheat we're looking at**

this dissertation looks into securing the base protocol and game engine of games, compared to modern research into anticheat is high level machine learning and kernel-level drivers. high level approaches are only worth following after securing the base, with some games only having high level anticheat.

**good qualities of core anticheat**

# > should be either game engines or anticheat. if game engine, a point should be that many don't provide any networking help, let alone anticheat
# > I think it should compare game engines, as that is what I'm building (or at least a core).
# > There isn't much of a difference really. Some anticheat is inbuilt to a game engine, other is separate software.

current game engines / anticheat fail in at least two of the following ways: not open source, not generalisable (re-usable) to other games, expensive to run on servers, trusts clients (not delta based). this means secure online gaming is very inaccessible to many. too expensive to run and hard to make for developers, and poor gaming experiences (with hackers) for players.

anticheat needs to be open source to enable as many developers to use it. closed source anticheat means it is difficult to modify to your needs, and will likely cost money to use and access. however companies with existing solutions aren't incentivised to release it, as it helps others.

the more generalisable an anticheat is the more developers can use it. different games have different architectures and styles so a 'one size fits all' anticheat would probably be bad or not exist, but many aspects of games are similar. building an anticheat which is modular so developers can combine pieces to suit their game needs would then again maximise generalisability and help the most games possible use it.

many anticheat systems run on servers, meaning servers must perform continual computation for every currently playing player. as the number of players increases this gets very expensive. if an anticheat can minimise the ongoing running cost, more developers can implement and use it.

a secure system means you cannot trust the client. this is common knowledge in cyber security and web development, but not necessarily game development. its often the easiest, first, and most intuitive approach, and can then be hard to change later. trusting the client means a cheater can send whatever values they wish to the server, doing what they want. 

**existing approaches don't tick all the boxes**

Game engines such as Valve Source (which runs CSGO) do not trust the client, and instead have clients send deltas. this however then requires their servers to simulate the clients, which is expensive. its additionally not open source.

Peer to peer based games such as Mario Kart, do not require a central server for most communication, reducing server load. however any such solution must be built customly, is complex, and is very difficult to secure from cheaters due to lack of server inclusion.

Popular game engines such as Unity and Unreal Engine and Godot do not provide any networking or anticheat capabilities, and are often closed source. This means you need to build a solution yourself. Their core inner workings also don't allow you to build a delta-based protocol. They also have lots of existing paradigms so its hard for a developer to introduce a new game loop.

**why this is a problem**

the lack of good tooling and anticheat for developers to use when building games means its more expensive to make games (more time to develop, or pay for other solutions), more expensive to keep online multiplayer games online (running anticheat servers), which naturally means many games will have poor online security. this means lots of hackers, which means worse experience for players, and in the end fewer players playing the game.

**my solution which ticks all the boxes**

DAN attempts to overcome all of the issues previously mentioned. it will be open source, based on the Flutter UI framework. it will be generalisable and modular, making minimal assumptions about the game, meaning developers can compose various components as they need for their game. it will require low server computation, without needing the server to constantly compute every player as other systems do. it also does not trust the client, meaning an entire class of cheats are impossible, as it is secure at the game engine and protocol level.

**the limitations of my solution**

DAN's core game loop requires developers to think in a slightly different way about game state, which may be unfamiliar to many game developers.

DAN requires complete computational consistency across all platforms. a particular pain point is floating point numbers. this is completely possible, as any inconsistency otherwise un-removable can be simulated in software, but this can lead to reduced performance.

DAN is more computationally intensive, re-computing states often and often simulating other players locally. many of the dissertation's extensions and future work surrounding DAN revolve around optimisations to significantly reduce this computational load.

DANs state synchronisation algorithm can lead to poor gameplay if a game requires trusting a client regarding specific parts of gameplay, for example in an FPS if your bullet hit another player on your screen then the server believes you. In CSGO this is exploitable by cheaters, but it may be possible to trust clients in a secure way, at the expense of increased computation.

All of these limitations are managable, and will be discussed later on. One point is that often the solution is to increase computation, at the risk of reducing performance. Many modern systems have an abundance of computation power so this may not be an issue. One of the core evaluation metrics is performance of this system.

**paper introduces new approach, implements it, uses it, evaluates it**

This dissertation introduces DAN and explains how it works. I then implement the core and various modules which could be used for real game development. I then use the implementation of the core and modules to build a simple online multiplayer game. Finally, I evaluate the success of DAN based on experiments and observation.

**potential benefits of my solution**

if its successful, then as flutter game dev community grows, so will my game engine core!

if more people build their games on top of DAN, their games will be secured at the engine and protocol level, and require low server running costs, without any additional work.

This makes building secure online games more accessible, and means more players can have better experiences playing multiplayer games.


= >> Third attempt at Introduction

most video games use passive replication. active replication was used early on, but several issues meant it wasnt feasible. this dissertation overcomes those problems, and overcomes modern problems too.

forms of cheating. why we're only focussing on replication
- bug explots -> "solved" by following good SW dev practises and writing good code
- information leakage ->
- aimbots, macros -> impossible to fully fix w/out securing the HW. "solved" with spyware
- replication -> can be fully solved, but often isnt.
- ... look at other forms of cheating

problems with other forms of anticheat. why we want to secure the replication layer
- many games dont secure this layer. have other layers instead
- this layer of replication is often abstracted over in game development tools. devs never touch it, and never realise its a vulnerability.
	- Only 20% of games on Steam from 2021, and it keeps decreasing are not made with an engine. Most top-grossing games are built with custom engines though, so they can implement this anticheat, but then they likely also have the resources to host servers and take the complex route. https://www.gamedeveloper.com/business/game-engines-on-steam-the-definitive-breakdown
- game development tools will sell on-top anticheat
- it doesnt make sense to have any other layer of anticheat without this core foundation. its like trying to hold a car together by duct taping the outside rather than just tightening the screws on the inside.

problems with passive replication, which we want to fix
- expensive to run -> this anticheat makes servers basically no-cost
- not 100% secure -> all games here are 100% replicatable
- if servers shut down, 

problems with active replication and why people dont use it, which we'll overcome
- lock-step is not fast enough
- was expensive to simulate whole world yourself. but modern computers are efficient.
- everyone uses easy-to-use game engines but they dont support it. its hard to write properly. -> im writing a nice-to-use game engine they can use
- switching an old game to an active replication system means re-writing the entire game from scratch, in a new way. writing a determinstic game engine, esp one which is stateless (for DAN) is expensive.
- protection against and recovery from descynronisation (from 0fps blog) is hard -> writing in flutter. same codebase on all platforms, as long as you write determinstic code. just remember floats and PRNGs. synchronisation and re-sync functionality built in. tests for de-sync regularly with hashing as part of anticheat.

active replication first mentioned by lesie lamport Lamport, L. (1978) “Time, clocks and the ordering of events in distributed systems” Communications of the ACM

Doom uses lock-step and is peer-to-peer

>> Check that active and passive replication are actually using SMR (determinstic etc)

justify client-server over p2p. "its what all games do"? not really a good reason when im challenging 'what all games do' by using active replication. it simplifies the distribution and synchronisation of inputs, and avoids issues like players sending different inputs to different people. downsides are increased latency, and having to have a server. having a central server means there's no consensus: there is a single authority on the sequence of inputs sent, which means we can focus on other challenges.

consistency model used (0fps blog 2)
- two most commonly used:
	- strict (limited by CAP theorem)
	- optimistic (csp)
- local perception filters slow the environment around you for other players the more yours is slowed / delayed. they interpolate the delay of objects in the world between the players the objects are closest to. this is unacceptable when high delay players are near you, as it slows down your game, and as it doesn't incorporate csp, so delays are visible. but tbf, neither is better in all scenarios. if you shot someone close to your in a FPS, there's no ideal solution. prediction is best for easily-predicted games, and perhaps LPFs otherwise. FPFs increase local input lag loads based on the other player's ping - THAT is unacceptable.

(0fps blog 4) need to consider both bandwidth and latency.


= Preparation
Explain how system works? Explain what an event object consists of? Theory behind future modification, the latency cutoff, and the consequences for cheating.

Software engineering techniques used. I used an iterative waterfall approach, where I laid out the individual modules and how they operate at a high level first. Then within each module I developed the overarching interface, iterating until all connected modules could work well together. Finally I implemented the interfaces.

Talk about starting point of Flutter, and the high level theory behind the anticheat system.


Doom iphone blog. original doom used p2p lockstep. experience was reduced for everyone to lowest denomenator.

same with age of empires, which fudged over latency by making all commands have fixed latency (2 turns). it would adjust the speed for everyone to the slowest computer. blog recommends making network and game simulators to stress test. this and its two sequels used p2p.

= Implementation

// All extensions lie under one of these three categories, so write about them there.
// What should you actually write about here?: The work that was produced
// - Programs written
// - Theories developed
// - (after:) Major milestones

// Any design strategies that looked ahead to the testing stage should be described in order to demonstrate a professional approach was taken

// "Comparison of alternative distributed algorithms may get more credit in a dissertation (with reference to related work) rather than further game development"

# TODO: going through log to add to implementation. At line 753 atm.

Nice way to introduce the system would be to show the FreeForm diagram, but start sparce and build it up as you explain each module.

- Overall parts that I developed
	- System architecture
		- All functionality is separated into individual and independent modules.
		- There is no dependence on library defined types (classes / interfaces). All interfaces are defined by structural typing through Function types. This is to make the system extensible and composable. Give examples for all modules. Rather than passing, for example, a networking module object to the Core, you pass one method for each action the Core might need to do, as any implementation will do, and I don't want external modules to be built to library-defined interfaces and prevent them from being used elsewhere.
		- The developer themselves composes a game engine with only the functionality needed.
		- No part of implementation is forced on developer, and all parts can be individually replaced with custom implementations. 
			- No pre-made assumptions on ticks, if any.
			- Network protocol is completely customisable, from medium to serialisation format.
		- Client-server communication pipeline is similar to IP stack in that each layer wraps the layer below, and communicates with the same layer on the other side.
		- Environment state
			- Immutable in principle, mutable in practise to make updates more efficient.
				- Consider how to make immutable but with cheap updates, like OCaml: only nodes from root to changed node are newly generated. This is done with [.copyWith] methods.
				- Important for future efficient dependency computation.
			- Stores user's last inputs, which are updated when a user input event is received.
			- Needs to store list of users, and keep track of if any are disconnected. Need to consider how and if we'll handle users connecting, disconnecting, and reconnecting.
		- Where was the system going to be driven from? Would the window call the Core to get the state when it was about to render a new frame? Would the Core push regular updates at ticks to the renderer? Would the core only update when it received an event?
			- I decided on having the core only update on events, and implemented ticks as events.
			- This stemmed from that the engine should be independent of screen refresh rate. This meant that the renderer would have to call the core when it wanted the state, rather than the core pushing state to the renderer.
			- Few options at this point. (1) Core runs when called by renderer. (2) Core runs from in-built timer tick.
			- I additionally wanted the Core to be independent of whether the game is ticked or not. This added a third option (3) Core runs when receives an event.
			- Couldn't choose option 1 because of how CustomPaint in Flutter works. The paint function shouldn't do any computation, and you can only signify if you have something new to paint. Also meant that if no rendering for any reason (lag, background process, etc), large amount of computation is then done on first render again.
			- Combined options 2 and 3 into one, by making ticks an event just the same as any other player input.
			- In a ticked game, user input events update the inputs in the state but don't compute. Only on a tick event, does the driver use the latest stored inputs and computes.
			- It couldn't be interally driven (i.e. push updates when state changes) as, with the interpolation modules, there would be infinite updates.
		- Latency guarantees
			- Late events are inserted into the history when they _should_ have been received (if zero latency). The latency between two players is how far back in the history an event will be inserted when received from the other.
		- Determinism
			- Floating point determinacy https://randomascii.wordpress.com/2013/07/16/floating-point-determinism/. Can solve with SW implemented floats, at the cost of performance.
		- Unstable period
			- We bake in events slightly later than unstable period on clients. This is because to guarantee that the right time has passed (we can't rely on local clock), we use the time sent to us from the server. Therefore the latency will add onto the baking delay. We use the 'server received timestamp' in events and record the latest one.
			- Events generated on client are slightly special. They are marked as 'local' (or 'not server confirmed'), and are inserted into the core unstable event list as normal. They are also sent to the server to be relayed to all other clients.
			- There is a chance that an event will be rejected by the server with a valid client however, for example lag spike or temporary network outage. All clients must be the same, so every client must receive a copy of the event they sent to the server back before they can bake it in (a confirmation) (can't have the sending client bake in the event and not the other clients).
			- Local events. They exist only as a temporary substitute for the real event, while the real event is travelling to the server and back. The sub' should never be baked in, only the real event, so the sub' should only exist within the unstable events list, and if it gets to the point where it would be baked in, it should be discarded. The idea is that the real event should make its way back to the client before the sub' would get baked in, and replace the sub event.
			- [Show proof with server-client packet network diagram]. Result is [latency ≤ offset + latency_cutoff]
		- Build layers on top to make it more like a normal game engine.
			- This is really a modular DIY game engine, but for a real project most user's will just want a single authoritative interface to work with.
			- Hide away tick details: wrap user-passed state object and driver and store buffered user inputs (events). Then on tick event call the user's driver. This would also require a pre-built user input system (unless driver receives a list of events).
			- Provide pre-built tickless approximator and smoother modules: requires pre-built physics system, to know notion of position and velocity etc. User's driver would then just interact with this physics system with an interface.
			- User input module: user's driver would receive inputs in a nicer way. You could make this generalisable, but not sure its really worth it. At that point it becomes unnecessary abstraction.
		- Sync client clocks
			- Whole system relies on client's clocks being synchronised.
			- If client's clock is 0.5 seconds behind server's clock, they'll see everything 0.5 seconds behind everyone else.
			- This is why we do additional clock sync to account for this.
			- As mentioned before, if multiple re-syncs happen during game, the interpolation between offsets must ensure the client game clock remains monotonic. This would only be needed if client's clock drift was significant, which is unlikely.
			- Effect of out-of-sync client and server clocks:
				- An early clock (this client is running ahead of all other clients):
					- Send all inputs to other clients early. Means that all other clients receive this client's events with low latency.
					- If the early clock offset is greater than the server-client latency, then all events arriving at the server will have generated timestamp in the future compared to the server clock. If the server discards future events, then all events from that client will be dropped.
					- The early client will constantly predict all other clients for the offset more time.
					- Generally a disadvantage to this client.
				- A late clock (this client is running behind all other clients):
					- Delays all outputs to other clients.
					- Receives events from other clients with lower latency / more stability (as essentially a buffer).
					- All other players will predict this client a constant additional amount, by the offset.
					- Advantages this player, close to cheating. If it didn't buffer events then it *would* be cheating.
					- Client server connection
				- Maximum offset
					- If a client is early, as long as the server doesn't throw away future events, theoretically any early offset is okay. The game will be unplayable at a certain point for that client, but nothing in the system will break. If the server discards early events, then if `early_offset > client_server_latency`, all events will be discarded and the client cannot play.
					- If a client is late, then if `late_offset + client_server_latency > latency_cutoff`, all events they send will arrive at the server past the latency cutoff and will be discarded, so they cannot play.
				- If server discards future events, on a LAN, you may want some leeway in case clock offset is greater than LAN latency.
			- [Talk about reconnection]
			- [Talk about initialisation of all modules]
			- [Game start and state syncing]
		- Philosophy is that modules are implementation independent to the Core, but not to the programmer.
	- Client core module
		- Lets you access current state, but not past state. It bakes in past state, which leads to the requirement for a monotonic clock. Users would almost never need it, and it would only be convenient for the Re-Connection Extension.
		- No baking would also remove the computation-reason for a latency cutoff / unstable period, but you should still keep it for anti-cheating purposes.
		- Works for both ticked and tickless systems. In ticked, regular tick events signal computation. In tickless, you compute the motion arc for objects, and then until the next collision or user input, you just follow the pre-computed arc, and repeat.
		- Inputs to the core are from a Stream. Single subscription, as broadcast implies it's okay to miss some events.
		- Outputs are a function, because the Core doen't push new state but sends it when requested. So it exposes the current state as a getter. 
		- The core can handle receiving events which occur in the future, it will just buffer them.
	- Server core module
	- Wrapper modules between server and client
		- Overall design
			- Currently all modules communicate with [Event] objects. But given their flexibility, it would be very easy to change them to operate on and wrap strings. Bit like IP stack, wrap payload and add header info, then reverse on the other end. For example use ":" as the header separator.
			- No design is fixed. It currently uses WebSockets and converts strings to Event objects, but could just as easily swap out these modules and use gRPC for example.
			- Core needs information before it can operate. Consider explaining other parameters too like this?
				- Own Client ID. Can't generate local events without it.
				- Unstable period value. Can't bake events in without it.
				- Time sync. Can't generate or bake events, or render tickless without it.
		- Time sync module
			- If automatic time sync fails (which it shouldn't), then an alternative when players are together is a manual sync where users tap their screens at the same time.
			- It looks like it's impossible to accurately synchronise clocks with assymetric latencies, as shown here:
				- https://cs.stackexchange.com/questions/103/clock-synchronization-in-a-network-with-asymmetric-delays
				- https://stackoverflow.com/questions/1942877/determine-asymmetric-latencies-in-a-network
				- https://www.researchgate.net/publication/224183858_Fundamental_Limits_on_Synchronizing_Clocks_Over_Networks
				- Even NTP can't account for it https://timetoolsltd.com/ntp/ntp-timing-accuracy/
			- Game timestamps are [Duration] objects which amount of time (microseconds in current version of Dart) elapsed. It makes monotonicity obvious and easy, and an easy to share and sync value.
			- When clients sync, they first get the UTC timestamp of when the game started according to the server clock, and then calculate the offset between the client and server clocks.
			- This module *just* exposes the [Duration] value to the Core. Anything else is an implementation detail currently.
			- The Core uses this module to add the 'generated timestamp' to events, and to know where to cutoff future events in its unstable list.
			- This module exposes just a local client best estimate of the current server-directed game time. It should not be used for baking, for example.
			- The definition of mapping from game time [Duration] to real-world time is as follows: add the duration to the timestamp game start time on the server - the real-world mapped time is when that resultant timestamp occured on the server's clock. I don't know how this would work on a P2P system with that extension. I think a lot of the guarantees would be lost and a lot of the system would need to be re-designed.
			- One option was for all clients to connect to the server as an NTP server, or perhaps an external NTP server, given their NTP-simple accuracy can be on the order of milliseconds. Overkill for this, also I couldn't find a way to force all clients to use the exact same NTP server.
			- We assume/need that
				- Clients are capable of monotonically increasing their local time with minor drift (occasional re-syncs can resolve significant drift)
				- Clients who purposefully mess with their clock (increasing drift / offset) will only affect them in gameplay.
				- Can't trust the same local client datetime to mean the same real-world time across clients.
			- Decision between having a completely separate time sync service on the server (unaware of the games) or part of the game engine system. Since syncing means finding the server's game start time for that game, a game reference (id perhaps) must be sent to the time sync module, which means it would have dependended on the game engine anyway, so may as well just have it part of the system and use events.
		- Tick generator (COPIED)
			- Researched how ticks were generated in other Flutter game engines. They have a simple callback timer which calls the [game.update] function once per tick. It then sets a flag notifying that the window can be re-rendered.
			- Flame tick implementation was expected but didn't fit into my engine's core's design. 
			- The Core module only reacted and performed computation when it received an event. 
			- Hard-coding a tick timer was the immediate option, but made more sense to have the ticks be an event instead. This fit into the existing design, and means the tick generation is completely customisable and not baked into the game engine.
			- Tick events are the only event not sent through the server. It would be possible to have the server send the ticks to clients, but this would use up bandwidth and mean that computation would be delayed (from latency). The only requirement for events is that all players receive them all in the correct order, so each client can locally generate their own as long as the generation is fully determinstic and identical on all platforms.
			- [talk about tick module implementation and guarantees]
			- You could have it just compute on tick. Just on event, or both tick and event. Or neither and have tickless!. If you want super fast input response rates, compute on both ticks and events. You can't just have events, as otherwise the error from euler physics will be too great. Only issue on computing on events too is that lower end devices may struggle, but in terms of accuracy, it will simply be more accurate. A balance would be running on ticks and events, but with a max event compute rate.
		- UI input event inserter
			- Local client inputs are sent into its Core as events, just the same as all other clients.
			- The system must be entirely determinstic. Same events with same state on all clients results in same new state. Makes sense for all clients to have identical internal state then.
			- Considered if user input should be sent every tick or only when changed. [Open question, see questions.md].
		- Event serialiser
		- ID sync
			- Client needs to know its ID to add onto the local input Events it generates. Thats the only difference between its own input and another clients into the Core system.
	- Wrapper modules between Core and renderer
		- Overall design
			- Multiple possible options.
			- Nothing: screen only updates on tick events.
			- Just unstable runner: constant smooth movement but small jumps on tick events as deviated approximation snaps to true computation.
			- Just smoother: means screen is always at least 1 tick behind, which can be a lot relative to fast monitors.
			- Smoother and +1 future tick computed: Smoother would need to be linear, otherwise the inter-tick movement would look uneven and jumpy, and the period would need to be longer than 1 tick period otherwise it'd freeze again before the next tick computation. However then you'd need another interpolator on top to interpolate between when new events arrive and are inserted (smooth out butteryfly effect).
			- Running two interpolators on top of each other seems inefficient, and may result in quadratic smoothing? Is cleaner to just have a simple tickless approximator with a larger smoother on top.
			- This linear / nested / wrapped structure is intentional. But I never wrap a module completely, just the input and outputs. This is because some modules only modify inputs or outputs.
		- Unstable runner
		- Tickless approximator
			- Issue was, in a ticked system, rendering would lead to screen updates only on tick boundaries. If tickrate is 20Hz, then thats the screen refresh rate too.
			- Needed a way to extrapolate state for any time interval, outside of tick intervals.
			- This module does just that.
			- Only intended to run for short periods of time.
		- Smoother / interpolator
			- For both ticked and tickless engines, eases between sudden state changes when event is inserted into history (mini butteryfly effect), and between hard tick boundaries on ticked systems (but less so as this is handled by tickless approximator).
	- Networking modules
	- Rendering engine
	- Game driver
		- Stores some values as doubles, which don't always have determinstic results on all platforms. Would need to convert to a det' alternative.
	- Blitz library
		- Intended to store all re-usable code. The actual game should be implementing and defining very little itself, but mainly just be composing together the various game engine parts.
		- Library files ordered so the server and client versions of the same module are together, for developer purposes, as the only dependants and dependees are each other.

== Anticheat System Theory
? Have this be its own section?
- Theoretical model improved upon. 
- Updated interpolation layers.
- Refined data and signal flow (what triggers what and when, and where does data go)
- Refined what information was needed to perform all tasks.
- Specified the best way to generalise certain operations (although is this implementation specific?)

== Networking (both client and server developed together)
- First designed a testing suite for each of the modules. As each module layers on top of the previous, you run a test on the core layer, then add a layer and test again, and repeat.
- By running on a simple 1D input for general correctness, I knew the underlying code was correct and functional.

== UI and Graphics
- Produce as a function which takes an envstate and canvas and draws on the canvas.
- Arrow keys print to log.
- Hand crafted scenes return consistent expected outcome render.

== Game Driver
- Produce as a function which takes an envstate and a set of events, and simulates n ticks modifying the passed envstate or returning a new copy.

== Reposity Overview
- Highlight which parts of the repo are my own and which are Flutter's.
- Describe what different parts of the code do.

= Evaluation
- "Visual validation"


= Conclusions

== Future work
- Support determinstic client-side truth computation. This increases total computation significantly.
- Efficient re-computation by limiting to dependency-affected regions of envstate. Would require a formalised way to convey what parts of envstate an event depends on and affects (e.g. read/write).
- Switch from TCP to UDP.
- Create a peer-to-peer version.
- Build a reputation and auto-sharing computation system.
- Cross-platform computation determinacy.

= Bibliography


= Appendices


= Project Proposal
