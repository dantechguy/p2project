
#set page("a4")

#let author = "Dan Wendon-Blixrud"
#let project_supervisor = "Prof Andrew Moore"
#let project_checkers = "Prof Alan Blackwell and Prof Srinivasan Keshav"
#let project_dos = "Dr Ramsey Faragher"
#let bgn = "2266F"
#let title = "Distributed Anticheat Networking"
#let today = datetime(year: 2023, month: 10, day: 20)


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

---

the outcomes???



= Preparation
Explain how system works? Explain what an event object consists of? Theory behind future modification, the latency cutoff, and the consequences for cheating.

= Implementation

== UI and Graphics
- Produce as a function which takes an envstate and canvas and draws on the canvas.
- Arrow keys print to log.
- Hand crafted scenes return consistent expected outcome render.

== Game Driver
- Produce as a function which takes an envstate and a set of events, and simulates n ticks modifying the passed envstate or returning a new copy.

== Networking (both client and server developed together)
- 

= Evaluation


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