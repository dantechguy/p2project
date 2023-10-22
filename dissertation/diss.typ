
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