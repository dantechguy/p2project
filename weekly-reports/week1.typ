#set page("a4")

#let author = "Dan Wendon-Blixrud"
#let project_supervisor = "Prof Andrew Moore"
#let project_checkers = "Prof Alan Blackwell and Prof Srinivasan Keshav"
#let project_dos = "Dr Ramsey Faragher"
#let bgn = "2266F"
#let title = "Distributed Anticheat Networking"

#align(right, 
  [
    Dan Wendon-Blixrud \
    2023/10/30
  ]
)

#set text(size: 12pt)
#set par(justify: true)

= Part 2 Project Weekly Report: Week 1

== Short and Medium Term Goals

By this Wednesday (November 1) the plan states to have the UI and Graphics and Game Driver cores implemented, and the Introduction section of the dissertation drafted.

By the end of the term (Nov 29) the plan states to have the all core modules completed, the introduction chapter for the dissertation completed, and a rough skeleton / outline of the whole dissertation completed.

== Work Done This Week

The UI and Graphics core is completed, with the Game Driver core implemented but completely untested. I have done a very rough draft of the Introduction chapter.

I have clarified many aspects of project's design:
- Exactly what information needs to be stored in the 'environment state' objects, which represent the game's state at a single point in time.
- Clarified that the client-side-prediction is not not computed separately but as part of another existing layer above the core module.
- Clarified that there are two interpolation layers. One for smoothing the jumps between each discrete simulation tick. The second for smoothing between when new events are received and merged into the past which changes the current environment significantly (a small version of the butteryfly effect).
- Clarified that the core module can remain independent of whether a Game Driver simulates in discrete simulation 'ticks' or not.
- Clarified that the Re-Computation Extension will be engrained with the core module, rather than separated as a layer 'on top'.

Researched an existing game engine written in Flutter called Flame, to see how certain low level details were implemented.

Researched about determinacy guarantees across platforms, finding that `float` operations may be an issue. Likely outside of the scope of this project, however.

== Insights

I have been very ill twice in the past fortnight so work has started slower than expected. The work plan did not explicitly account for illness, but there is still buffer time and vacation later planned in the timeline in case this delay propagates significantly.

Given the time spent on the project, progress has been very good. I have not had time to go over my Introduction draft at least once however, so it is worse than the milestones expect.

== Agenda

In the next week I will prioritise any urgent coursework deadlines (from other courses), and starting a draft for the introduction chapter of the dissertation.
