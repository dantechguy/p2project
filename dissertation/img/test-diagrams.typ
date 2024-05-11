#import "@local/cetz:0.2.2"

#cetz.canvas({
  import cetz.draw: *

  rect((0.5, 0), (3.5, 1), name: "relay-server")
  content("relay-server", "Relay server")

  rect((0.4, -1.4), (10.4, -6.4), fill: gray)
  rect((0.2, -1.2), (10.2, -6.2), fill: gray)
  rect((0, -1), (10, -6), fill: white)

  rect((0.5, -1.5), (3.5, -3.5), name: "data-structure")
  content("data-structure", align(center, [Distributed State\ Synchronisation\ Data Structure]))

  rect((0.5, -4.5), (3.5, -5.5), name: "game-logic")
  content("game-logic", "Game Logic")

  

})