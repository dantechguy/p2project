#set page("a4")

#let author = "Dan Wendon-Blixrud"
#let project_supervisor = "Prof Andrew Moore"
#let project_checkers = "Prof Alan Blackwell and Prof Srinivasan Keshav"
#let project_dos = "Dr Ramsey Faragher"
#let bgn = "2266F"
#let title = "Distributed Anticheat Networking"
#let today = datetime.today()

//#text([#author Proposal], size: 15pt)

//#v(60pt)

#align(right, 
  text(author, size: 15pt)
)

#align(center, 
  [
    #v(50pt)
    #text("DAN:", size: 40pt, weight: "bold") \
    #v(5pt)
    #text(title, size: 29pt, weight: "bold", ) \
    #v(15pt)
    #text("Part II Project Proposal", size: 15pt)
    #v(15pt)
    #image("cam-crest.png")
    #v(30pt)
    #text(bgn, size: 20pt) \
    #v(40pt)
    #text("Computer Science Tripos", size: 15pt) \
    #v(5pt)
    #text(today.display("[month repr:long] [day], [year]"), size: 15pt) \
  ]
)


#pagebreak()
#set page(numbering: "1", margin: 2cm)
#show bibliography: set heading(numbering: "1.")
#show heading: it => {
  v(0.5em)
  it
}
#set text(size: 12pt)
#set heading(numbering: "1.")
#set par(justify: true)

*Project Originator:* #author \
*Project Supervisor:* #project_supervisor \
*Project Checkers:* #project_checkers \
*Director of Studies:* #project_dos


#v(5%)
#outline(fill: repeat("."), indent: auto)
#v(5%)



= Introduction

Video games are one of the biggest markets worldwide, worth more than both the music and movie industry combined @gamesmoviesmusic. Gaining an unfair advantage in such games is, to no surprise then, extremely desirable; the act of _cheating_.

Cheating in video games is so prevalent that _anticheat_ exists, that is, software designed solely for its prevention and detection.

Both cheats and anticheat come in many forms, with the primary focus of research and this project being on online multiplayer games. The more cheaters present in such games will result in fewer (paying) users, reducing profit. Games overrun by cheaters can have their livelihoods destroyed and companies are well aware, some offering up to hundreds of thousands of dollars for finding bugs in their anticheat systems @vanguardbounty.

Anticheat development today is an arms race of machine learning and increasingly intrusive scanning software. But such high level approaches are only pursued under the assumption that a game is already secured at the lower levels, meaning it has anticheat built into its core right from the start. 

\

To elaborate on exactly what "core" anticheat is, lets briefly look at two popular online multiplayer video games _Minecraft_ and _Counter Strike: Global Offensive_ (CS:GO). Both games feature client-server networking and the ability to move a character around in a virtual 3D environment. When a user wishes to move their character in Minecraft, the client calculates the new position and sends this to the server @minecraftposition. In CS:GO however, the client would instead send the _action_ (e.g. "forward key pressed") to the server, and have the server calculate the new position @csgoposition.

The difference here is that a cheater in Minecraft could send any position to the server, regardless of what is possible within the game's bounds. CS:GO prevents this because its core game logic does not trust the client to calculate their own movements, instead relying on the server. In short, Minecraft does not implement core anticheat, while CS:GO does.

Despite core anticheat having been in use for many years it is still not widely adopted, with many games suffering unnecessarily as a result. The goal of this project is to help tackle this problem.

\

To introduce the approach this project will take it is first helpful to understand some of the reasons why many games don't implement core anticheat:

+ *Inexperience:* developers may not know that integrating anticheat within the core game logic can be necessary or how to do it. Often the obvious approach is to add online multiplayer _after_ writing the core game logic, as a layer 'on top'.

+ *Game Engines:* built-in anticheat is either non-existent or highly limited and expensive @unityanticheat@eosanticheat, so must be implemented by the developer. But the abstractions in game engines designed to simplify development then make it harder to access the necessary core game logic to integrate core anticheat.

+ *Development Cost:* including this anticheat increases the complexity of development, using more time and money -- a resource which is likely already at its limit.

+ *Ongoing Cost:* this anticheat requires servers to be continually running and computing all player movement, which is expensive at scale.

+ *Backwards Compatibility:* updating an existing game's logic may stop different versions of the game working together, which is especially problematic when users and surrounding infrastructure make it difficult for everyone upgrade. #footnote[As backwards incompatibility stems from using incompatible protocols it's not possible to solve this in a generalisable manner. A solution would instead involve modifications to other layers in the stack. It is therefore listed here for completeness, rather than to justify an aspect of the project.]

At first glance, a good solution would be to develop a reuseable form of this anticheat, and either integrate it within a popular game development tool or provide it as a base for others to build on. This alleviates the need for developers to have anticheat development experience (point 1), to modify a complex game engine (point 2), and to spend time implementing it themselves (point 3). However, given the maturity, volume of code, and deep rooted paradigms of popular game development tools, this approach would be both too expensive and disruptive to be successful.

Addressing this, a better solution would be to develop such a reusable form of this anticheat with _Flutter_, a popular and fast-growing cross-platform UI framework @flutterwebsite@stackoverflowsurvey2023@fluttersurvey2023 with a small but equally fast-growing game development community. The small size means a lack of existing paradigms and tools to compete with, meaning a new and effective approach has the potential to have a large impact as the community grows. However, without also reducing the ongoing cost of running the anticheat on servers (point 4) this solution would still not be effective. 

\ 


// emphasise requirement for deterministic execution. other game engines will be deterministic on the same hardware, but differ across platforms (unity https://www.reddit.com/r/Unity3D/comments/lkxb9d/crossplatform_deterministic_physics_with_unity/), (unreal https://forums.unrealengine.com/t/ue5-fully-deterministic-physics-in-ue5-is-it-possible/513853). I don't know if Dart is fully deterministic across platforms? But its especially not deterministic with Web.
Therefore, this project will attempt to implement a modified version of the previously described core anticheat, where instead computation is _distributed between clients_ rather than on the server. This reduces the role of the server to little more than a matchmaking and data relay system, meaning scaling is now significantly more affordable (point 4). It will be built using Flutter, and to evaluate its feasibility for real-world game development, this project will then use the anticheat module to build an extremely basic online multiplayer racing game.

The next section will discuss how the project will be split up into individual development units, and how each unit joins together to form the final game.

= Project Structure

This project consists of five parts, which are explored in further detail below:

+ *Client Networking:* The distributed synchronised data structure acting at the centre of the program, processing inputs and scheduling further processing. The anticheat's "core".

+ *Server Networking:* The platform to facilitate client communication.

+ *Game Driver:* The game logic which runs on the anticheat core. This defines what the game _is_.

+ *UI and Graphics:* The rendering engine, user interface, and input handling. 

+ *Practicality Evaluation:* An evaluation of this anticheat system's real-world use.

== Client Networking
For this part I will develop the data structure at the centre of the program's operation -- the "core" of this anticheat. By design this data structure is modular, with additional pieces of functionality as layers 'wrapped' around previous layers. It makes minimal assumptions about a game's operation and allows developers to add or remove parts based on the nature of their game.

The core receives 'events' and merges these into its current perception of the environment -- events such as "player A move forward" and "player B jump". At any given time clients' perceptions may differ depending on relative latencies, but will all stabilise within a fixed time period I call the _latency cutoff_. Clients will continue to receive new, unstable events as they continue to stabilise old ones, so while the perceptions may never be identical they will always be close.

At this basic level the core offers a distributed, synchronised, ordered, timestamped, sequence of events. Because racing games are very latency sensitive this project would likely develop an additional client-side-prediction (CSP) layer, which 'fast forwards' other clients' simulations to a predicted position 'in the future'. This gives the illusion of near-zero latency.

== Server Networking
This is a simple module by design. At a minimum, it should relay and broadcast events sent from each client to all other clients. It may also delete invalid events it detects.

== Game Driver
To better evaluate this anticheat module's practicality for real-world game development, this project will use the module to build a simple racing game.

For a most basic implementation the game will consist of cars driving around a 2D environment. There may be no collision, realistic turning, or complex resistive forces implemented at this point, but these may be developed later on as extensions.

This module may be developed as a 'pure' function to best fit with how the anticheat core works internally, ensuring replicability and deterministic execution. This means it contains no internal state and, given two identical environment states as input, will return two identical output simulated next states. During execution the core module will be re-computing the same point in time but including newly received events, hence the requirement for determinacy.

== UI and Graphics
As part of evaluating the anticheat module's practicality, a rendering engine and input handling must be included for minimum functioning of the game. This will consist of no less than a static, top-down, 2D view of the cars and track.

This feature may, like the Game Driver, be developed as a 'pure' function, taking in an environment state and producing a consistent rendered output.

== Practicality Evaluation
A key part of this project is to evaluate both quantitatively and qualitatively how practical this anticheat is for game development. Key factors will be ease of implementation of the game, performance with many simulated clients, and quality of state synchronisation (e.g. accuracy, stability), all evaluated under various conditions such as varying player counts, latencies and bandwidth.

= Starting Point

I will be building this project on top of the pre-existing SDK from Dart and Flutter.

I am familiar with Dart and Flutter from building a small variety of applications, and during the two weeks preceding Michaelmas 2023 I partially developed a 3D rendering engine with them. The rendering engine may be completed and used in the project as part of an extension.

I have only studied graphics in _Introduction to Graphics_ and _Further Graphics_, and networking and asynchronous systems in _Computer Networking_ and _Concurrent and Distributed Systems_. 

I additionally have some experience writing simple client-server applications in NodeJS and JavaScript.


= Success Criteria
If the following criteria are fulfilled, the project will have been successful.

+ Develop a distributed state synchronisation data structure.
+ Develop a user interface module to accept user input and render the game.
+ Develop a game driver module, which provides the logic to 'step forward' and run the game.
+ Develop a server module to relay events between clients.
+ Combine the modules into a running game.
+ Evaluate the practical success of the project using metrics such as framerate and synchronisation quality (deviation from true state, rate of jitter), under conditions such as varying player count, latencies, and bandwidth.


= Possible Extensions
This project by its modular design and nature, has extensions which are similarly modular and self-contained, resulting in many smaller extensions rather than few large ones. Some potential extensions are listed below, and given the volume there is no expectation for them all to be completed.

- *Interpolation Extension* - _depends on Client Networking_ \
  This module will reduce the jittery effects of the unstable period (before events pass the latency cutoff), by wrapping the engine's output and smoothing / interpolating all values over a short period.

- *Shared Computation Extension* - _depends on Client Networking, Server Networking_ \
  As each client must simulate all players in the game locally, a large number of players will reduce the game's performance to the point of failure. For example, if client A 'trusts' client B, then B can stream up its computed values for A to stream down. Depending on the 'trust' graph formed by all clients (i.e. who trusts who), total computation can be reduced significantly.

- *Re-Connection Extension* - _depends on Client Networking, Server Networking_ \
  If a client loses its state of the game (e.g. briefly disconnects and re-connects) it would need to re-compute the entire game's worth of events to get back to the present. A more effective solution would be to have all clients regularly upload snapshots of their stable game state, which the server can then check for equivalence and store. When a client requests re-connection, the server can send the latest snapshot and all events since, allowing the client to re-start quickly and efficiently.

- *Room Extension* - _depends on Client Networking, Server Networking_ \
   Adds support for multiple game sessions at once. Will be useful to demonstrate the low strain this anticheat method has on the server as the number of concurrent sessions increases.

- *UDP Extension*  - _depends on Client Networking, Server Networking_ \
  As the anticheat system can handle out-of-order events, modify the networking systems to run over UDP rather than TCP. This would require implementing packet re-sending and evaluating the change in performance and stability.

- *P2P Extension* - _depends on Client Networking_ \
  Given the server's limited role, modify the Client Networking module to run over a peer-to-peer network and evaluate the change in security, stability, and performance.
  
- *Reputation Extension* - _depends on Server Networking, Shared Computation Extension_ \
  In a real online environment most users will not be playing with "trusted" users, meaning they are limited in their ability to share computation. This extension would automate this process giving each player a reputation which is based on the amount of times they've truthfully shared their computation with others.

- *Turning Extension* - _depends on Game Driver_ \
  Make vehicle turning more realistic. Turning would then depend on a vehicle's speed and its origin of rotation.
  
- *Resistance Extension* - _depends on Game Driver_ \
  Make vehicles' resistance forces more realistic, with separate parallel and perpendicular tire and air resistances. Potentially implemented as a stateless function which given a vehicle's state returns the resistive forces.

- *Non-Static Map Extension* - _depends on UI and Graphics_ \
  Makes the screen follow the current player.

- *3D Extension* - _depends on UI and Graphics_ \
  Move to a 3D rendering engine, including vehicles and environment. Camera would follow the current player.

- *Mobile Extension* - _depends on UI and Graphics_ \
  Application runs on mobile either as a native app or web app. Uses touchscreen alternatives to the arrow keys for input.

- *Tilt Extension* - _depends on UI and Graphics, Mobile Extension_ \
  Uses phone's gyroscope for tilt-based steering.

- *Mini-Map Extension* - _depends on UI and Graphics, Non-Static Map Extension_ \
  Adds overlaid static view of the track and all vehicles.

- *Animation Extension* - _depends on UI and Graphics, Non-Static Map Extension, 3D Extension_ \
  Adds nicer 3D models. Animated wheels, particle effects, etc.

= Work Plan

*Michaelmas week 3-4* --- _Oct 19 - Nov 1_
- UI and Graphics core
- Game Driver core
- Draft dissertation introduction chapter

*Michaelmas week 5-6* --- _Nov 2 - Nov 15_
- Client Networking core
- Finish dissertation introduction chapter

*Michaelmas week 7-8* --- _Nov 16 - Nov 29_
- Client Networking core cont.
- Server Networking core
- Produce dissertation outline
- *Milestone: Completed core game*
- *Milestone: Completed dissertation introduction chapter*
- *Milestone: Completed whole dissertation outline*

*Vacation week 1-2* --- _Nov 30 - Dec 13_
- Interpolation Extension
- Shared Computation Extension
- Draft dissertation preparation chapter

*Vacation week 3* --- _Dec 14 - Dec 20_
- Re-Connection Extension
- Finish dissertation preparation chapter
- *Milestone: Completed dissertation preparation chapter*

*Vacation week 4* --- _Dec 21 - Dec 27_
- _Christmas Break_

#pagebreak()
*Vacation week 5-6* --- _Dec 28 - Jan 10_
- Non-Static Map Extension
- Resistance Extension
- Turning Extension
- Draft dissertation implementation chapter

*Vacation week 7* --- _Jan 11 - Jan 17_
- _Break_

*Lent week 1-2* --- _Jan 18 - Jan 31_
- Buffer time

*Lent week 3-4* --- _Feb 1 - Feb 14_
- Buffer time
- *Milestone: Completed project*

*Lent week 5-6* --- _Feb 15 - Feb 28_
- Perform Practicality Evaluation
- Finish implementation chapter
- *Milestone: Completed dissertation implementation chapter*

*Lent week 7-8* --- _Feb 29 - March 13_
- Write dissertation evaluation chapter
- Write dissertation conclusions chapter
- *Milestone: Completed draft dissertation*

*Submission* #emoji.fire --- _May 10_ 

// - Interpolation Extension (1/2 week)
// - Shared Computation Extension (1 week)
// - Re-Connection Extension (1 week)
// - Room Extension (1/2 week)
// - UDP Extension (2 weeks)
// - P2P Extension (4 weeks)
// - Reputation Extension (3 weeks)
// - Resistance Extension (1 week)
// - Turning Extension (1 week)
// - Non-Static Map Extension (1/2 week)
// - 3D Extension (3 weeks)
// - Mobile Extension (1/2 week)
// - Tilt Extension (1/2 week)
// - Mini-Map Extension (1/2 week)
// - Animation Extension (2 weeks)

= Resource Declaration
- My laptop for all work. It is a 16" 2021 M1 MacBook Pro, with 32GB memory and 1TB SSD. This will be the device on which the project will be run and tested on. If this machine fails, I will promptly buy another machine and continue development. _I accept full responsibility for this machine and I have made contingency plans to protect myself against hardware and/or software failure._
- If the Mobile Extension is undertaken, I will be using my iPhone 13 Pro for running and testing.
- The Dart and Flutter SDK. Used to execute and compile code for various platforms, including MacOS, iOS, and web. 
- The following Dart/Flutter libraries:
	- "`dart:io`" for server-side WebSockets
	- "`web_socket_channel`" for cross-platform client-side WebSockets
- A local network if testing across real devices is to happen.
- Git and GitHub as VCS for my source code and dissertation, and I will be making weekly backups of all relevant files to Google Drive and an external SSD.


#pagebreak()
#bibliography("citations.bib")