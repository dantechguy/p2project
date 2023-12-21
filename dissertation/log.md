Dan Wendon-Blixrud (drw48) Dissertation Log

Current loose-ends have "[???]"

# 2023/10/20 (3 hours)
Setup local and github git repos for proposal, dissertation, and code. Have a local Typst compiler and vscode extension for writing the dissertation.

I need to create a skeleton of my dissertation. The basic outline is fixed:
- Cover page
- Declaration of originality
- Proforma
- Table of contents
- Chapter 1: Introduction
- Chapter 2: Preparation
- Chapter 3: Implementation
- Chapter 4: Evaluation
- Chapter 5: Conclusions
- Bibliography
- Appendices
- Index
- Project Proposal

Within each section I need to plan the structure: "a graph here, analysis here" etc.

# 2023/10/21 (1 hour)
There's an issue with XCode 15.0.0 which causes macos builds to fail. Progress logged https://github.com/flutter/flutter/issues/135277. Will build for web while waiting.

Have written a basic implementation of the envstate `Env` object, a basic renderer for the envstate, and a basic arrow key detection widget. 

Next job is to combine them into the app and see if they all work as expected.

# 2023/10/22 (1 hour)
Got the inputs all working: arrow keys are detected. Rendering works as expected, cars are in the correct place, with the correct colour, size, and rotation.

Excellent, UI and Driver core is finished. The cars and grass look terrible. There is no track, but that will be very quick to implement rendering for, and it's worth me waiting until I know it will be implemented to then render it too.

2023-10-22-18-29-first_render_and_input_test.png

# 2023/10/23 (2 hours coding, 1h thinking)
Currently creating the Env state and how it handles and stores user inputs. Needed to know if user latency information was going to be stored in the Env object or in the client only as a current value. The way you know?: do you need it when re-computing old values, and does it need to be synchronised across all clients?

In this case you don't, as latencies are only needed for CSP. But in the future work where you may do individual client truth computation (for scanline hits) then you may need this information, to know the state of each client at a particular point in time.

Another question is, do you need to store the list of users in the Env state? Are we expecting and do we need to support clients to frequently join and leave? I think yes, we will need expect and support this. But what should happen if a user leaves? Does their vehicle just disappear? Or can they reconnect and retain state. 
|
If they lose state then the user field can be removed, but if state is retained then it must be kept. And what if a new user joins part way through? Is this allowed, and they're given a new car with fresh state? Or are they not allowed to join?

For the sake of this demonstration, I think user's should retain state, and new users should be allowed to join. But in the real game, users should only be allowed to join at the start. Retaining state gives us the potential to use the Re-Connection Extension. Not all games would need this, for example in a `.io` game, each individual game is of little consequence, so deleting a player on disconnection is common.

At the moment the `UserInput` objects use a double for steer and accelerate amounts. At some point these will need to be made cheat-proof, either at compile time (with specific clamped classes) or at runtime.


Another decision I've made is that Env objects aren't immutable. They are treated as immutable, but the internal driver code modifies the env object you give it. The exposed driver code then copies the passed env, and then runs the internal driver which modifies the copy.
|
I've done this anticipating that it will be beneficial for performance. I would have made all of the classes immutable, but it makes updating values very painful, because dart doesn't support easy built in dataclasses.
|
Once the overall structure is more fixed and understood, I may go through and make the dataclasses immutable.
|
I also want to make the updates happen like OCaml functional objects work. It means that they are all immutable, and updates are maximally efficient. If one part of the tree must change, then the only objects that must be re-created are all the ancestor objects of the updated part, up to the root. This may end up being the most efficient method.

Also, with some foresight on the efficient dependency computation, this easy updating may become critical for performance.


To know how best to integrate and design the engine tick system with Flutter, I'm reading through the source code for another game engine called Flame (https://github.com/flame-engine/flame/blob/main/packages/flame/lib/src/game/game_render_box.dart).
|
This github issue shines some light on some of the design decisions. https://github.com/flame-engine/flame/issues/294. I think a CustomPainter should be sufficient, I just need to think about the update control flow works. With CustomPainter, you are not in control of when you re-render. You simply write a function which returns whether you *should* re-render. This means that updates to the internal engine and state cannot be initiated by the render function.
|
But it can still be initiated by a ticker. So engine updates triggered by a Ticker, and re-painting with the CustomPainter be handled separately and asynchronously. You could have CSP and interpolation be triggered by the CustomPainter, as none of that computation is part of the core engine tick and can be done for any. AH NO THIS IS WRONG!
|
Extrapolation and interpolation cannot be triggered by rendering, as they can update based on time elapsed, and the rendering needs to ask *these* modules if anything has happened since last time and if any updates need to be drawn. The engine needs to tell the renderer if updates need to be drawn.
|
But, the interpolation and extrapolation modules can be triggered independently of the core layers. This is because of the different inputs. I already have drawn out what the different core modules' layers' inputs are. They need to be updated when any of the inputs change.
- Core event merger - inputs: latency cutoff, new events, state step function
- Unstable event executor - inputs: state step function
- CSP extrapolator - inputs: clock ticks, state predictor function
- Interpolator - inputs: clock ticks, state interpolator function

Just noticed, but in its current state, the CSP extrapolator isn't doing anything. It's supposed to simulate individual cars which haven't had an input update in a while, but given the local user will always have events up until the current point, the unstable-event-executor will do the job of the CSP extrapolator automatically.
|
This begs the question, will users send a list of their inputs for every engine tick? Or just when the inputs change? I feel like for the sake of efficiency, it should really be just when they change.
|
So perhaps the unstable event executor and CSP module should be the same thing? Really all the CSP module is, is a function to predict what the other clients' events and inputs will be during the unstable period. No module should simulate further than the unstable executor, as it computes environments up to the current point in time, so CSP must be done simulatenously.
|
Now the question is, given clients only send events on input changes, how do we know when to start predicting from? We don't know if an event packet is delayed, or if they just haven't made any changes to their inputs. Unless we have clients send inputs for every tick, we won't know. But sending just on changes is good, as if we switch to a non-tick system (continuous instead) then just on updates will be necessary.
|
So given we just send events on input change, the CSP module will simply have to extrapolate from the last event received from every other client.

# 2023/10/25
Work on Blitz renderer, I need to fix the infinite recursion bug with splitting tris on the camera plane. My hypothesis is that after a tri has been split into three, at least one of the three new tris is also considered to lie 'on' the camera plane, and therefore being split itself.

# 2023/10/27
I've been ill twice over the past two weeks, so progress has been less than expected.

The reason I the CSP module I had before was unnecessary was because you get CSP for free with the existing modules. This is because other users' events are inserted into the execution timeline when they *should* have been received, not when they actually were received. And then the unstable executor runs everyone's cars up to the current tick, so everyone is in some predicted position. The latency between two players is essentially a time delay behind which the other player's events are inserted into the timeline.

Then you just have the interpolation module at the end, which smooths things over. Perfect. There is no re-computation optimisation in the core module because it does no re-computation. Its baked state is immutable because it has passed the latency cutoff. All recomp optimisation is in the unstable executor / CSP module (which we now know are the same thing).
|
The uncertainty here is that, if no events are received for ages, the core module baked state never changes, because its only input is events, not the tick clock. The unstable module just gets bigger and bigger. The question is *should* the baked state update? Because after the latency cutoff the state won't change. One thought is that tick updates could be treated as events in the core module - which would make state get baked in. But then if all games would build this on top, surely it should just be built in? And where would the tick events originate from?
|
The only requirement for consistency between all clients is that they all receive the same events, in the end. So regardless of if the events come from the server or locally from the client, as long as they converge, it's okay. Therefore the tick events could originate from the clients, as they are completely deterministic.
|
I guess the two assumptions you could be making to argue for/against ticks as events is
(1) The core module should bake state whenever the environment updates (aka every tick).
(2) The core module should bake state whenever an input which deviates execution from how it would have gone is received (aka on user input).
For some reason I was implicitly thinking that option 2 was best. Why? It does require you to have an additional layer of fast-forwarding. But I think option 1 makes sense. Whether I thought it or not, the game driver was essentially dealing with implicit tick events anyway. Explicit tick events just make it more obvious where the 

Should the core module allow you to retrieve the state of any time (in the past and future)? This broad interface makes it easier for Re-Connection Extension which requires a stable state at a timestamp determined by the server to be uploaded for consistency checking and saving.
|
But then should it also run into the future? This would remove the job of the CSP module. The tick events required (if we go with that) could be inputted to the system infinitely ahead of time, so that wouldn't be a problem.
|
If the only reason for the core module to be able to return any time in the past is for the sake of upstreaming past baked states, then there's no need to expose this and it can be an implementation detail. The question is, would the *user* need to access this? Almost definitely not. They just want the most up-to-date game state to render and process.

Do we want to build the Re-Computation Extension 'on top' of the existing core module? I.e. use the game event objects? Surely not, it should be built with its own meta protocol..? But it could usefully rely on some latency cutoff guarantees, to ensure that the client returns the baked state before sending any new inputs. So, if we need to engrain the baked state upstreaming alongside event timestamps, then the protocols need to be entwined. So it cannot be separate, but still, should it be built 'on top'?
|
This is not a game event, and so should be processed by the core module and not leave and be processed by the user's custom game driver. Regardless of how its implemented, it is a meta-event.

When it comes to thinking of examples, its not helpful to think of 2 player games. At least not with TCP. This is because the unstable period is useful because of differing player latencies. With UDP though it can still be useful.

New issue! Before I was implicitly thinking that the old unstable module was computationally tick-bound and the old CSP module was computationally un-tick-bound (before they were merged). To be tick-bound means that you only compute in tick sized steps, but un-tickbound means that the computations are continuous (rather than discrete Euler approximations). Ideally none of it would be tick-bound, because it would lead to better results, but things like collisions get hairy I think.
|
    I think figuring out how to implement a tick-less physics engine with collision is a half-dissertation in itself, so the best thing we can do here is ensure that our system allows for both ticked and tickless engines equally well.
    |
    In a tickless system you compute the current motion arc for all objects, and at what point some objects collide to change some motion arcs. Then either when that time arrives, or an input is received, the motion arcs are re-calculated, and this loop repeats. How does this relate to our previous assumption about when to bake environment values into the core module? If we went with option 1, then we should bake whenever the environment changes. But here we wouldn't want to do that.
    |
    (1) Ticked engines benefit from baking the environment whenever the environment changes. This is because the computation per step is higher than the mode for unticked, but very consistent. Collisions are estimates but done more regularly.
    (2) Unticked engines benefit from baking the environment whenever the current execution path would change (either from a collision or user input). When following a motion arc steps are extremely cheap, but on execution-path-change the initial position for the motion arc changes, so you it would be wasteful to not start from this position again.
    |
    The base behaviour you need to guarantee you can perfectly simulate is that if you ran the game driver from the start until now, you would have the same outcome.
    |
    How often is the game driver run?
    |
    For a tickless engine, the game driver could be run as much as necessary right? The last initial position would be stored as state, and re-computed when needed. You give the game driver a state, and tell it to simulate for a certain amount of *time*. Both ticked and tickless would store their internal baked values in the envstate.
    |
    A tickless system would store its envstate as an initial state + time offset, and then either pre-compute values and store them in the envstate too or require you to do the simple motion calculation to find out the positions of everyone. But it would store its own internal baked state in the envstate. The ticked system wouldn't require such an explicit internal store of baked state, because it gets it for free. It doesn't need it. It just uses the previous tick's computed values.
    |
    So the end result is that both ticked and tickless systems work. BUT back to the question of option 1 or 2. The answer is that it doesn't matter!! It's an internal implementation detail. All the core module has to expose is the current state, and whether it recomputes lots or has some internal cache is irrelevant. But the good news is that for both a ticked and tickless system, if you called it at extremely high tickrates, it would only really do any computation when it needed to (ticked: on tick boundary; tickless: on collision/input).
|
Now back to this thread's initial question. How do you make a ticked system render smoothly? Tickless gets it for free. Is it the job of the interpolator to make ticked systems render smoothly? At a minimum, you need some tickless system which will run intra-tick prediction.
|
We have two layers to achieve good results, and while the end result was what I had initially shown in the core module diagram, the modules I had written down didn't achieve it.
|
First, we have a tickless approximation engine, which gives good smooth results for short periods of time, but quickly deviates. This is what I had envisioned the first CSP module being. This runs FROM the current tick, simulating a rough future for every frame. You could also have a module like this for a tickless engine - the benefit being that it guarantees no heavy collision computation, but it would not be necessary for smooth results.
|
Second, we have the interpolation engine, which smooths over all output. Its main job is to ease between ticks and bigger jumps in envstate, and is useful for both ticked and tickless engines. In ticked engines when a new tick is computed, the approx engine's result and the new tick may be different, so this eases between the two. In tickless engines, when an event is received from another player which happened in the past, the re-computation which happens may change the future (mini butteryfly effect), so we need to ease between the two (this also applies to ticked engines).
|
You *could* use the state-step function to predict one tick into the future and then use a between-tick interpolator, which at first glance seems like a simpler solution as it only uses one interpolator. But this doesn't solve the issue of interpolating when new events arrive. So you would then need another interpolator on top

Had a read about floating point determinacy https://randomascii.wordpress.com/2013/07/16/floating-point-determinism/. Could be an issue! This would require testing and could be half a dissertation on its own. There are definitely methods to ensuring determinacy (including SW implemented floats) but the cost to performance is obviously the largest limiting factor.

# 2023/10/30
Writing some of my introduction chapter draft. Here are some notes and thoughts:

It describes:
- The paper's topic
- The problem being studied
- References to key papers
- The approach to the solution
- Scope and limitations of the solution
- The outcomes
Shows that your paper is worth reading, and introduces some context to help the reader. Don't use specialised terms.


The paper's topic
- introduces a new method of low-level anticheat which improves over existing solutions
- implements this method as an open source, generalisable, modular, game engine core
- builds a simple online multiplayer game using the game engine
- evaluates its success

What are the limitations of my approach?
- Developing stateless game engine is a new way of thinking for developers
- Requires complete computational consistency across platforms (solvable, potentially at the cost of performance)
- Computationally intensive (solvable to an extent)
- Limited conflict resolution algorithm (solvable, at the cost of performance)

What is the scope of this paper?
- Develop the core modules for an anticheat game engine.
- Develop a simple game using the developed modules, for quantitative and visual validation.
- Evaluate the success of the core modules through experimental data and observation.


Motivation:
- Why is the problem interesting
- The relevant scientific issues
- Why the approach is good
- Why the outcomes are significant

Why is the problem interesting?
- There is no single game or game engine which solves all problems at once
    - There exist games which run on deltas (e.g. CSGO)
    - There exist games which require zero/low server computation (e.g. P2P based)
    - There exist open source game engines (e.g. Godot)
    - There exists a game engine for Flutter
- It is possible to solve all problems at once

The relevant scientific issues.
- Games which run on deltas require expensive large-scale server computation.
- P2P based games have limited anticheat.
- Existing open source game engines either do not support delta-based multiplayer, require expensive server computation, or are fixed to a specific physics engine. They also have well-established paradigms which makes deep modifications difficult.
- The Flutter game engine is an example of a limited open source game engine.

Why is my approach good?
- Open source
- Generalisable and modular for all games
- Made in Flutter
- Removes an entire class of cheats
- Requires very little (even zero) server running costs

Why are the outcomes significant?
- Most popular game engines are closed source. Developing this core open source increases the chance it's used.
- This core makes minimal assumptions, so can be used for all types of games.
- This core is developed in Flutter which has a small but growing game development community. If introduced and used by the community now, it has the potential to grow large and be used by many.
- Developers who use this core get anticheat 'for free' when introducing multiplayer.
- This anticheat reduces development and ongoing costs of online multiplayer games. Complex networking problems are solved, and ongoing server costs are low.
- This means players have better experiences with online multiplayer (fewer "hackers"), and developers spend less time and money making and hosting games.

After reading? You should understand the scope of the work and problem, and the contribution.

Paragraphing
- One paragraph, one topic or issue.
- Main point is captured in the first sentence.
- Rest of paragraph amplifies or gives examples.
- All sentences are on the main point in the first sentence.
- Last sentence has more impact.
--
- Context can be lost between paragraphs: use fuller term over "this".
- Link paragraphs with repeated keywords or phrases, and expressions for explicit links.

Sentence stucture
- Simple structure.
- Keep related phrases close (don't have large subsections).

# 2023/11/6
Whether the engine is internally driven or externally driven depends on how the rendering works. In flutter, the paint function is called so its externally driven. Given the interpolation engines, it doesn't make any sense for it to be internally driven, as it could render infinite frames.
|
However it will continue to receive events even if not rendering. What happens if the engine is not called for a long period of time? Should it continue to compute whenever it receives a tick marker. That would make sense. In a tickless engine, it would only re-compute upon collision or new event.

Where do the tick border events come from? Some events are server synchronised in that they either come from the server, or local copies are kept until the server confirms or rejects them. Some events are assumed synchronised such as tick borders. Perhaps its a layer above the core module? Maybe the server also sends tick events? This lets clients bake in values sooner than receving the next event.
|
A layer above could be connected into a system timer, which generates these tick events.

# 2023/11/7
For now to test the Game Driver without the Client Networking module, just set up an interval timer which runs the game engine at tick rate. Inputs will be collated during the tick.

A note: with the tick event generation layer, don't pass this implementation detail to upper layers where users will be interacting. The game driver should be able to deal with events as it wishes, whether thats in bulk per tick, or one at a time.
|
The game driver could simply add in events to an interal buffer and then just use the tick event as a trigger for computation, but this may be too weird for users.

# 2023/11/11
The entire system operates on the assumption that all clocks are synced. Can we trust in-built device clock syncing? Or do we have to manually do some internal clock syncing?

# 23023/11/14
This is a question I've had several times. Are the core module layers wrapped (abstracting other inner modules), or are they linearlly sequenced (exposing all message passing).
|
Presumably linear means they're more composable, as the 'glue' connecting their inputs and outputs is manually defined by the user (although usually it's just passing the data directly in).
|
If its wrapped, 
|
Maybe its depends on if you want both the input and output to be modified, or just the output? The input as an event stays the same. This is right. Wrapped layers could either operate on input or output. In Java for file wrappers, they just wrap the outside I think, and the constant argument is passed to the innermost object. This input can be a Stream for ours.

```dart
// Nested
engine = Interpolator(
    TicklessApproximator(
        UnstableExectutor(
            CoreEngine(),
        )
    )
)

engine.addEvents(evt)

env = engine.getCurrentState()
render(env)
```

```dart
// Linear
core = CoreEngine(
    latencyCutoff: 1 second,
    stateStepFunction: DriveTick,
)
unstableEvents = UnstableExecutor(
    core: core,

)
extrapolatedEvents = TicklessApproximator(unstableEvents)
interpolated = Interpolator(extrapolatedEvents)

core.addEvent(evt)

env = interpolated.getCurrentState()
render(env)
```

These are both almost the same. But with the principle that the wrapper only needs to modify the output, we should go with the one where inputs are sent to the inner-most module.

But these modules aren't generalisable at all. The extrapolator and interpolator both depend on the Env object completely. Is there some way to generalise them?
|
Given they only operate on a constant subset of the envstate, that is, the physics objects, perhaps we could define a generalisable physics object interface for the Env and the relevant objects it contains? Would it be general enough to be useful?
|
Extrapolator would continue with current velocity, perhaps including acceleration. You could pass it a function which, given an Env object, returns a collection of physics objects which all have a velocity and displacement attribute. This anonymous function would make it especially generalisable. Different constructors could be used for different variations (e.g. 3D vs 2D, including or excluding acceleration). Might need a pair of functions, one for getting and one for setting?
|
Interpolator could be passed a pair of set and get functions (to access an iterator of items and update items). Pass an interpolation curve optionally. And optionally pass a calculation function for when simple scalar interpolation isn't enough. If different values need to be handled differently, you can stack interplators. If the interpolation duration also changes, pass a function which takes an iterated item and returns the duration.
|
Both share the 'extract' and 'update' pattern, perhaps we could turn that into its own thing? You could create an transformer class

How do you defined classes and types which are extensible and composable? Interfaces for 'receives stream of events' and 'outputs stream of events' ?

# 2023/11/26
Mention the approximation of Euler physics and why you need constant tickrate with a non-continuous physics engine.

Does the interpolator interpolate based off of Env's that it's *seen*, or Env's that have been generated. If it's off those it's seen, then it will interpolate differently if you've had a big lag spike and missed a bunch of frames. Then it will interpolate from the last rendered frame. 
|
If it's off those that have been generated, then, well, what *does* that mean? It can't statelessly interpolate between the last few envs, because the last few envs may change with a late event. So it must be internal, and must be based off of what's been seen?

Generalising the `Smoother` class:
- This could first involve using anonymous functions.
    - One function to gather an iterator of objects to interpolate over.
    - You need to know which object corresponds to which across frames, so
    either the function above returns a map from ids to objects, or you
    have another function which given an object returns its id.
    - One function to take in a current object and return it interpolated.
    - An issue with the above is that you don't have the object's source
    (where you got it from) when determining it's id, so you may have to
    resort to type lookup. Would be better if you could specify its id
    alongside the item in the iterator, such as in a record.
    - You could also have objects implement a "Smoothable" type where they
    just expose a unique id. There's the question of where the smoothing
    implementation is. I feel doing it in one smoothing object (here)
    is better than across all Smoothable objects, as it keeps the logic
    in one place.
- Then build upon this with a physics object interpolator.
- How does customising the smoothing technique work?
    - For example: exponential vs linear vs whatever.
    - What is the minimum interface to implement any method? You likely just
    need a persistent state object you can write and read.  Maybe for now
    I'll make the state just an object of that type, for ease?  However
    this will not be type safe, as if the same id is used for two
    objects of different types in consecutive frames, it'll break.  I can
    see this being quite a difficult bug to identify and fix too.

When running unstable events, how are events added into the Envs? Is this part of the driver?
|
Is the driver run once for every event, and in a ticked engine, when inbetween ticks and not executing, it will buffer the event inputs until the next tick?

# 2023/12/4
open closed principle blitz. how would you add a line renderer (w and w/out depth). or text renderer. or textures. is the main issue sorting? because we can have user provided rendering right??? ah but lighting wont work if it isnt just tris

# 2023/12/10
How do you know when to bake in an event? You have a latencyCutoff and event timestamp, but can you guarantee that the client's clock is the same as the server's? Every event from the server will send a 'server timestamp on receipt'. You can use this as a guaranteed timestamp passed in the server. The core will store a 'last guaranteed server time passed' value.

In the Env driver function, how are events inputted / processed into the Env? All inputs from all players should be inputted into the Env as events, including local user inputs. The Env should ONLY be modified from events, not anywhere else in the system.

And how are local user inputs (which don't come from the server) inputted into it too? [???]
|


# 2023/12/11
Before I was unsure if the input to the Core should be an object or a stream. I want the tick generator to wrap the inputs to the Core, rather than the Core itself, as it modifies the inputs rather than the outputs. This means it matches the decorator pattern.
|
To have it do the same, there's no way to have it wrap the inputs to generate new tick events if it's an object. It would have the wrap the core object. So we must make the input an event stream for this reason: so the Core can wrap *it*.
|
It should be a single-subscription stream, as guided by the Dart docs, as you need to receive all of the events in the correct order. A broadcast stream would insinuate that it's acceptable to miss some of the events, which it's not.

The Tick Generator can generate new tick events either from a regular interval timer, and from receiving new events.
|
How do we ensure that the local client reacts instantly to user input? Because in the current model it can only react once it receives a tick event. What if the driver computed a new unstable Env state for all the current states, regardless of when the last tick event was given, but only bakes and saves envs that were computed in tick events? Or is this what happens already?
|
No, this doesn't happen already, as the unstable runner just runs the driver function same as the Core.
|
NO WAIT. This is the purpose of the tickless approximator. This is exactly the purpose of the tickless approximator. But will the tickless approximator react instantly to new user input? NO! It won't, as the buffered events for the next tick will be stored in the Env.
|
Should this be done in the driver and tick generator, or in the tickless approximator?
|
  Option (1) Driver and tick generator
  |
  Perhaps we have a constant temp-tick event which always sits at the end of the unstable event list. This way the driver will always compute with *all* of the unstable events, rather than ignoring the ones within the period between the last tick event and the present. 
    Note: this wouldn't work if the tick period was longer than the latency cutoff. Why? Actually it might.
  |
  This would work well too as the Smoother would ensure that, even as the player's input is slowly held up to the next incoming tick event, the interpolation would be smooth.
  |
  How would you integrate this nicely with the Core and driver? At the moment the fact the driver is ticked is not nicely handled. The Core doesn't know about it (which is nice), but the tick events are generated from a layer above, and the driver must handle some of this tick buffering logic internally. Maybe the input wrapper can buffer the events instead? If the driver could be independent of the ticked buffering somehow it would be nice.
  |
  I don't like this approach, because it's putting so much re-usable logic inside the custom driver, AND it spreads this custom tick logic across many different layers. It requires modifying the unstable executor to add in the temporary tick event. I guess this *could* be added to a separate layer on top of the unstable executor, by simply running the output Env of the unstable executor through the driver once more with just the tick event. Perhaps the tick generator isn't just a wrapper around the inputs, but also around the outputs?
  |
    I think it could work as a separate layer / wrapper. So far the approach is that you can create any sort of Core by *just* composing existing layers to make what you need. So if you need a ticked system, you add the tick generator layer. And if you want the ticked system to react to user inputs instantly, you add the temp-tick event adder layer.
  |
  Although there may be a way of keeping the driver interface / requirements simple and consistent across different game types, while still being able to implement a wide variety of ticked and tickless systems: if the driver interface is simply that when it receives a tick event it performs a computation, then you could do a computation after each input, just do a computation once every tick, have a temporary computing tick at the end of the unstable list, etc.
  |
  Question is then that is there a type of system that this wouldn't fit? Are there some ticked systems that simply wouldn't work having to be defined in terms of variable computation differences?
  |
  Option (2) Tickless approximator
  |
  ...
|
Does it even make sense to have this? Would it just be better to have the driver update the computation per event, *as well* as the tick period? This way everyone would see the instant reaction. Otherwise the instant reaction is just an illusion for the local player, as the temp-tick event gets pushed back and their input gets computed at the next tick boundary anyway.
|
The adding 'temp-tick' event always at the current timestamp won't work, if the computation is still bulked at the event. I think executing player inputs when they are received could work well, as long as there's additionally a regular tick event generated to keep it moving during periods of no user inputs.
|
One concern is that there will a lot of events generated which will be difficult to compute for low-level devices. Perhaps we have a maximum rate of events generated for each user? Bulk computing events will still be far more efficient though. This is a design choice a game driver designer will make, but ideally you would want the (local?) reactivity of per-event computation, but with the efficiency of bulk computation. Is there some way to have the local user temporarily and locally-only be in a hyper-reactive state where all inputs are computed as soon as they're generated, but they interpolate back to the bulk-tick computation state after a short period? Would this look or feel bad?
|
The max extent of the 'bad' feeling would be moving 'back' by the tick period, over a period of the Smoothing period. So if the Smoothing period and tick period were the same, would you just be frozen in place for a duration of the period? Perhaps if the Smoothing interpolation was linear. Without Smoothing you would teleport back. So you would want to make sure that the Smoothing was longer than the tick period, but the longer the Smoothing period the more sluggish everything feels.
|
  What if you smooth the player's movement separately to other entities? What about things like shooting? It would be weird if your shot was actually delayed by a tick. So there's no perfect solution for all cases, to have bulk computation and fast responses. If you want fast responses, you must 
|
So is there no good answer? Your options for computation are:
- Euler approximation:
  - Bulk compute every regular tick period
  - Compute at every event, and regular tick period
- Continuous computation (not obvious, need continuous physical equations)
|
I guess the only thing to do is choose between the Euler approximation solutions. The tick period is very small, and at least with a racing game with continuous steering, I think it would be acceptable to have this slight input delay.

When the Core returns the unstable events, there may be events with a future timestamp which are scheduled (perhaps tick events). It should remove these in its exposed interface of unstable events. But how does it determine what the current present timestamp is? [???]
|
A first response is that it doesn't matter hugely, as the unstable list can add or remove events per tick.

Basic websocket server implementation from ChatGPT

```dart
// server.dart
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  var server = await HttpServer.bind('127.0.0.1', 4040);
  print('WebSocket server listening on 127.0.0.1:4040');

  server.transform(WebSocketTransformer()).listen((WebSocketChannel channel) {
    channel.stream.listen((message) {
      print('Received: $message');
      channel.sink.add('Server: $message');
    });
  });
}
```

And client on the web:

```dart
// web/client.dart
import 'dart:html';
import 'package:web_socket_channel/html.dart';

void main() {
  var channel = HtmlWebSocketChannel.connect('ws://127.0.0.1:4040');
  print('WebSocket client connected to ws://127.0.0.1:4040');

  channel.stream.listen((message) {
    print('Received: $message');
  });

  channel.sink.add('Hello, WebSocket from Web Client!');
}
```

# 2023/12/12
Done some more implementation of Client Networking Core today. Good stuff.

After ironing and finalising out a few kinks, next steps are to test the Core. To do this I guess I need to have the server implementation running too. So next steps are:
1. Write server networking
2. Write client networking
3. Finalise client networking kinks
4. Test
   - Do basic command tests, then do graph tests. Will need to write custom driver for this.
   - Command tests:
     - Server works, commands are relayed
     - Add artificial delay. Command within latency cutoff are ordered, and outside are dropped.
     - Must show it is:
       - distributed (appears on all clients, without server computation)
       - synchronised (all clients see the same thing)
       - ordered (out of order commands within latency cutoff are re-ordered)
       - timestamped (all commands have time of creation)
       - sequence (there is a total order of commands)
   - Graph tests
     - Do more graph tests once Smoother module written
     - Each graph adds a new layer. Multi players with varied latency, events to move up/down 1D point over ticks:
       - No latency points (truth. Looks stable because all players inputs cancel out nicely)
       - Events through core module (delayed by cutoff latency, but stable copy of previous)
       - Events through unstable runner (points looks shaky from varied client latencies)
       - Tickless approximator (points join to form line, discontinuous jumps at new events)
       - Smoother (line becomes continuous from smoothing)

# 2023/12/14
Got basic server client networking working. Multiple clients connect to a single server, with broadcast messages.

Question regarding game time and timestamps. Without Re-Connection extension, all clients must be connected before the timer is started. Then a game start event is sent to clients and all clients start running their timers. This must consider latency and clients' timers must be as close as possible to the server's.
|
  I guess technically clients don't have to be connected on timer start, you just have to ensure that no events have been sent. They are two separate start events: timer start and events start. Timer start must be before event start.
|
Should they continue to synchronise timers throughout the game, after game timer start? This would only be necessary if either their clocks drift (not sure how realistic this is?), or if the initial offset was inaccurate.
|
With the Re-Connection, clients must be able to join after the timer has started. This would be ideal and then you wouldn't need a timer start event and event start event. Joining clients would just synchronise timers (be told what the time is) and the last baked event + all events since.
|
[???]

Regardless we'll need a 'synchronise timers' mechanic. The core system will call it once at the timer start. Is it better for all clients (and the server) to synchronise with an external NTP server (like time.google.com) or for all clients to synchronise with the server (using a more primitive algorithm perhaps).
|
For now I'll implement a simple round-trip latency based clock synchronisation mechanism.

How would re-synchronisation work? If clients synchronise again with the server and the offset is different. First, what does it mean that it's different? And second, what do you have to do to update the local timer?
|
  If a client and server timer are out of sync, what does this result in?
  |
    An early clock (this client is running ahead of all other clients):
    - Send all inputs to other clients early. Means that all other clients receive this client's events with low latency.
    - If the early clock offset is greater than the server-client latency, then all events arriving at the server will have generated timestamp in the future compared to the server clock. If the server discards future events, then all events from that client will be dropped.
    - The early client will constantly predict all other clients for the offset more time.
    - Generally a disadvantage to this client.
    |
    A late clock (this client is running behind all other clients):
    - Delays all outputs to other clients.
    - Receives events from other clients with lower latency / more stability (as essentially a buffer).
    - All other players will predict this client a constant additional amount, by the offset.
    - Advantages this player, close to cheating. If it didn't buffer events then it *would* be cheating.
  |
  What is the maximum offset manageable?
  |
    If a client is early, as long as the server doesn't throw away future events, theoretically any early offset is okay. The game will be unplayable at a certain point for that client, but nothing in the system will break. If the server discards early events, then if `early_offset > client_server_latency`, all events will be discarded and the client cannot play.
    |
    If a client is late, then if `late_offset + client_server_latency > latency_cutoff`, all events they send will arrive at the server past the latency cutoff and will be discarded, so they cannot play.
  |
  Small offsets in clocks is manageable and won't have much effect. Consider some leeway for future events, especially if latencies are very low (e.g. LAN). Given 20Hz ticks are 50ms long, a few milliseconds offset is okay.
  |
  If network synchronisation proves unusable, perhaps allow for manual synchronisation when users in same place, by tapping on screen at the same time? Black/white alternating flash at 1Hz which should line up. Or synchronise to same external NTP server as suggested above.
|
It would be possible to gradually shift the offset over time, presumably by simply and slowly modifying the interal "gameStart" local timestamp. If you're moving backwards in time, the minimum to prevent the user seeing going back in time is to have the change spread over the difference. The offset changes are likely to be very small (max tens of milliseconds), so spreading the change over a few seconds is very possible. Exact numbers should be proven to be acceptable, given assumptions based on maximum offsets.

It looks like it's impossible to accurately synchronise clocks with assymetric latencies, as shown here:
- https://cs.stackexchange.com/questions/103/clock-synchronization-in-a-network-with-asymmetric-delays
- https://stackoverflow.com/questions/1942877/determine-asymmetric-latencies-in-a-network
- https://www.researchgate.net/publication/224183858_Fundamental_Limits_on_Synchronizing_Clocks_Over_Networks
|
NTP cannot account for it, as shown here:
- https://timetoolsltd.com/ntp/ntp-timing-accuracy/
This answer says most paths are asymmetric
- https://serverfault.com/a/388939
but I just have to hope that the asymmetries are minimal.

For now, as it's all running on my machine, I won't implement clock synchronisation.

When clients synchronise clocks, they will internally have two things: (1) A *local* datetime timestamp of when the game started, and (2) a *global* (within all clients and server) duration of how long the game has been going on.
|
The duration is the timestamp used for events, and this is shared between all clients and the server. The only difference between clients is the GameStart datetime timestamp. This timestamp represents the same point in time in the real world, but may be different across clients due to clock differences.
|
When clients sync, what they are really doing is updating their GameStart datetime timestamp.
|
The local datetime timestamp of an event can be calculated by adding the event's duration timestamp to the GameStart datetime timestamp. And a local datetime timestamp can be converted into an event duration timestamp by finding the elapsed time since the GameStart timestamp.
|
Using duration for timestamps makes monotonicity obvious, makes it an easy shared value, and makes synchronising easy (just change GameStart).
|
I think the GameStart datetime timestamp should be an internal implementation detail? Not that there's any other way of implementing this? Although I guess on re-sync the value will be interpolated and it may not make sense to expose it. I guess the big question is: can everything be done *just* using Durations? What kind of thing would a developer want to do, and how should they do it?
|
  If a developer uses Duration to measure elaped time for a timer or something, then this is a timer within game time. Duration provides a game-time time measure. However this does not necessarily align perfectly with real time. If a re-sync happens, or perhaps a big lag spike, then Duration will simulate accurately within the game logic. However if a Dart timer were used then real-time would be used. Which you use depends on what you are trying to achieve.
  |
  So perhaps we should provide a Game timer module, which allows for timer-like callbacks but within the game time? This could be useful, if the timer is part of the game logic. It needs to be consistent across all clients, having a timer system could be good. Then it would need to be baked into the Env.
  |
|
Is this really the case though? Lag spikes etc won't stop the flow of game time (as directed by the server), and local game time is driven by ticks. Ticks are generated by received events (directed by server time) and through a local device timer, but this isn't important, as any ticks in the future will be discarded. However this means that the Core module needs to know what the current time is, to know the exact boundary after which to exclude future events. Either this, or the tick generator needs to be given the exact current time.
|
  If the time is guaranteed to be monotonic, then the logic could be put into the tick generator only (stop it from generating future ticks). If the logic is in the Core module then it can handle time moving backwards slightly to remove a newly generated tick.
  |
  I think both should be sent the current time (Duration), for redundancy and cleanliness.
|
[???]

Where should time handling be done? Inside of the core module? Or completely separately? It can be completely separate to the core module, I think. Yeah, the core module only ever deals in Durations, so any internal implementation will be separated out.
|
The time module is responsible for giving all clients a shared, monotonic clock, which produces GameTimestamps. A GameTimestamp represents a single moment of time within the game simulation.
|
  Does a GameTimestamp map to a moment in real-world time by definition? If clients sync to the server for time truth, then the server's clock is the mapping from GameTimestamp to real-world time.
  |
  If server and all clients sync to an external time service (NTP), then perhaps the server's clock can still be considered truth.
  |
  Or do we even require / need a true mapping from real-world time to GameTimestamp?
|
What are our minimum assumptions?
- Clients are capable of monotonically increasing time with minor drift (occasional re-syncs).
- Clients with significant drift will ruin gameplay for themselves, so purposeful modification is within expectations.
- We cannot trust the same local client datetime to mean the same real-world time across clients.
- We can figure out a mapping between clients' local datetimes for a moment in real-world time.
|
From the above, do we have a reference drift amount? Or a reference set of snapshot mappings from a local datetime to to GameTimestamp. This is the server's job.
|
So with a client-server based implementation of the Time Module, it must be able to communicate with the server, and provide all clients with a shared abstract GameTimestamp. The GameTimestamp flows in time along with the server, and each client tries to replicate the server's time as accurately as possible.
|
The Time Module must be able to change implementation without the Core module knowing about it. For example if synchronisation happens via the server, or external NTP.
|
  Issue is that communication with the server happens via the events system, which goes through the Core module. So how does it intercept or read the events? 
  |
  Can time synchronisation be done as a separate service on the server? Could a single service (unaware of games) on the server serve all clients time sync requests? At that point, how different is it from just using an NTP server?
  |
  Perhaps the time module is another wrapper/layer? It can intercept events before they reach the Core, and the Core can take as a parameter a Time Module (an interface exposing current time, etc)?
  |
  Okay, these two options seem reasonable, and are to some extent the same idea with different implementations. Have a separate Time Module to the Core, which the Core can query for time(stamp) info. The Time Module could communicate with an external NTP service, a service on the server via different connection, or via the events system by intercepting certain events.
  |
  I guess the question now is which implementation makes the most sense? External NTP vs server endpoint vs server events?
  |
  Unless all clients use the same global time, the Time Module must pass some reference of which client / game room it's in, to get the time source for that room. It is possible to have all clients using the same game source, however I'm not sure if this will affect syncing because of drift.
  |
    What does it mean to use a global sync, code / implementation wise?
    |
    Different places across the world would use different NTP servers, so there is no truly global time. In that case the geography of the client would be the implicit shared game room reference, but that breaks if you have players from across the world.
    |
    But if all players did use the same time reference (or more accurately, if they couldn't pass in a game room reference). It wouldn't matter. The server would just choose a time (e.g. unix epoch), and the latency-RTT syncing would happen as usual. The syncing just finds the offset in clocks, being aware of the RTT.
    |
    But the syncing wouldn't be for the unix time, it would be for whatever the current clocks of the server and client say. The unix time is just the zero-reference, and is independent of syncing.
    |
    Ah. Right. Syncing is just finding the offset between the server's and client's clocks. And then additionally we want this zero-reference for the Duration timestamps for events. They aren't necessary, and we could just use the server time timestamps for events. It would certainly make reasoning about it easier. Then the Time Module's purpose would just be to get the server's current time. This makes sense. A truthful source of the current time is needed.
    |
      How would this extend to a p2p system? The concensus could decide on a time truth of a single external NTP server. Also, it needs to work so that all players following the rules can play (regardless of others), and no guarantees for those who break the rules.
     |
    [???]
  |
  So if Time Modules must pass a game reference, it must have communicated with the Core or the server. To communicate with the Core it then depends on the Core / interface, which I'm not sure we want. To have the Time module be module user-independent (regardless of Core), it'll have to communicate with the server. Although if it communicates with the server via the Core then it must have Core-specific code to know how to work with events. This insinuates that it can't be independent of the Core, and any code which could be made independent has already been done so (think NTP library). Any independent code would be the logic for calculating offset.
|
The result has been decided: a Time Module which depends on the Core (but may have a re-usable syncing mechanism inside). It exposes its best guess at the current shared time. It must be asynchronously initialised, but current time is returned synchronously.
|
Internally it likely need to communicate with the server, either through the events system or via a separate endpoint. It will need a reference from the Core to pass to the server, which is shared between all clients in the room (e.g. room id).

In a peer-to-peer network, what is true clock rate? With a server, the server is the truth for the flow of time within the game. I guess in a peer-to-peer system there is no truth for the flow of time. So when would each client know they can bake in values to the core? What if another client misbehaves or stops sending events: then you wouldn't know when you can bake in events. We have no way of enforcing the latency cutoff in a peer-to-peer system.
|
It's even worse if using UDP, as then you can't even use one event as confirmation of timestamp passing on that client, to bake in events.
|
However this is for the UDP / peer-to-peer extensions, so won't think too hard about it now. But worth considering.
|
[???]

TEMP THOUGHTS:
The time module needs to expose / allow other code to:
- Get the current GameTimestamp
- ? Convert any local datetime timestamp into a GameTimestamp
- Re-synchronise the clock

- Get current duration / convert datetime into duration
There also needs to be a way of synchronising clocks.

# 2023/12/16
Local events. They exist only as a temporary substitute for the real event, while the real event is travelling to the server and back. The sub' should never be baked in, only the real event, so the sub' should only exist within the unstable events list, and if it gets to the point where it would be baked in, it should be discarded. The idea is that the real event should make its way back to the client before the sub' would get baked in, and replace the sub event.
|
The real event should make it back in time before the sub' is discarded (if valid real event). My intuition for this assumes clients have zero timer sync offset. So, assume zero offset: The real event can come back in `RTT = 2 * latency` time. The sub' event will be baked in when it receives an event with a serverReceivedTimestamp of latency_cutoff more than the sub' events generatedTimestamp. Such an event will be sent at that time, received at plus latency (max latency_cutoff), and signal the sub' can be baked in plus latency_cutoff. So the sub' event will be baked in in `latency + latency_cutoff`, which is GEQ to RTT.
|
```md
# Assume zero timer offset
event_generated_timestamp = T
rtt = 2 * latency
real_event_received_client_timestamp = T + rtt = T + 2*latency
bake_event_generated_timestamp = event_generated_timestamp + latency_cutoff = T + latency_cutoff
bake_event_received_client_timestamp = bake_event_generated_timestamp + latency = T + latency + latency_cutoff
latency ≤ latency_cutoff
2*latency ≤ latency_cutoff + latency
T + 2*latency ≤ T + latency_cutoff + latency
real_event_received_client_timestamp ≤ bake_event_received_client_timestamp
```
|
This simple inequality shows it's true. Now, how about we consider offsets? Best shown with a server-client diagram. See dan's notebook. The resulting inequality is that:
|
```
latency_cutoff + latency ≥ 2*latency - offset
latency_cutoff ≥ latency - offset
latency ≤ offset + latency_cutoff
```

# 2023/12/18
p2p: the time module sgould be able to change implementation (ntp vs server) without yhe core knoeing. all it should expose to the core is the duration timestamp

There seem to be a lot of things built on top that need to be included into the Env. Perhaps there's a utility section, or the Env structure can be restricted in a way that enables the additional features? For example with batch tick exectution, maybe the dev's custom Env is inside a larger tick-Env, which batches events and calls the internal driver at regular intervals? Maybe it also wraps the driver passed into the Env?
|
  How would a tick-batch-processor wrapper work? It could, for example, modify the generatedTimestamp value of all the events to be the time of the tick, then run all of those through the driver one-by-one. The assumption here would be that processing an event with zero duration would not cause any world state to change, but would update saved user inputs.
  |
  Some games will rely on the ticks being the only times for execution, so having a zero duration tick may cause weird behaviour if not careful. Although the batch-tick-processor is just a convenience function, and if someone has a different requirement they can write their own batch executor.
  |
  It sort of seems like we're (ab?)using a special case of the driver function (dt==0) to use for collapsing user inputs. Is it common sense / obvious for users to store inputs in the Env, and *then* process it? If you're doing this tick method then you kind of have to - as no computation happens until tick. All other events are *by definition* just input updating events. Ah, okay.
  |
  So you don't even need to worry about (dt==0), as non-tick events won't trigger computation. Great, this makes the tick-batch-processor even simpler.
  |
  Ah, no. This re-raises the question before about if you batch events until the tick, or if non-tick events modify the Env. If you batch events, then the driver itself will need to deal with a list of events. Compare this to having non-tick events (e.g. inputs) just modify the Env, then they can be computed directly by the driver without needing additional logic. This separates out input collection and updating (input events) with computation updates (tick events).
  |
  We can trust that inputs are stored in the Env because you can't pass inputs to the tick event. The tick (computation) event just uses the data it finds in the Env, so anything it's going to work with must be in there already.

Why is there a requirement for monotonically increasing clock? Because the Core module bakes in Envs, and cannot go back in time. If it could, then there would be no requirement. It would also be technically possible to remove the latency cutoff, but you may not want to do that for anti-cheating reasons.