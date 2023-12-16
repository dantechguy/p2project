# Event *(Immutable)*

- Generated timestamp. Used for clients to know when in game-time it occured, and therefore where to insert it.
- Sender. Which client produced this event. Used to map inputs to players. Added by the server.
- Action. What input occurred.
- ID. Unique identifier for this event for the sending client.
- ? Server receipt timestamp. Used to discard events which arrive to the server late, and for clients to synchronise their clocks.
- If it's a local or server generated event. Local events must receive a server confirmation before being baked in. Undecided when it should be discarded.

An event may be discarded, but the same ID cannot be used for another event. The ID is built from GameID + SenderID + EventID, and is unique for the duration of the game.

{
    "generatedTimestamp": int (microseconds since game start?),
    "serverReceivedTimestamp": int (ditto)
    "senderID": int,
    "action": string (what happened?),
    "senderID": int,
}