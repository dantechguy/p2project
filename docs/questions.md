
> How to know when to predict a player's inputs from? - Line 84
If send inputs on every tick, simply the last tick when they didn't send inputs
If only send inputs on change, you need to know that player's latency to know when to predict new inputs from. Add client latency syncing module?

> Where does the Re-Computation Extension operate, and how does it work? - Line 113, 776
Client receiving state is super easy. Create a module which receives state and passes it as [initialState] to ClientCore, then server sends all events since last saved state to client as normal.


> How should ticked engines be smoothed? - Line 140
Should smoother module be exponential? Or linear within a period? Sub-tick?

> Should the [Event] type be a type variable? - Line 696

> Should you add events to the client via [addEvent] or an input stream? - Line 717
I think Stream as its how you receive events from the server, so less transformation needed?
But using a Stream is so much overhead and hassle, compared to a simple function.
Shouldn't adding events to the network also be a function? To make it equal?
If network needs to buffer events, it will. Core will never need to buffer- if it does it means computation / event-handling is too slow. But core needs to handle every event.

> How does client and server initialisation work?
Client currently has separate modules which are instantiated, initialised, and then Core is instantiated with modules' values.
How could the server do something similar?
Should both client and server send 'ready'?

> Rename separated [Event] types to ServerToClient-style? Rather than ServerOut?

> For "time warp" - how can malicious players manipulate latest-event-received-from-server event IDs in their input events to gain an advantage? - Line 832
Could do this to make sure they get a particular shot. Consider the bounds within which this is possible.

> For "time warp" - how long do server and clients need to store a recent list of events sorted by time received? - Line 837

> How does the engine driver access the server-time state and local clients state? - Line 843

> How can clients reconnect with the same clientID? - Line 855

> What should the [senderID] and [eventID] of tick events be?

> With a generalisable Event data type, how should tick events be sent? - Line 893