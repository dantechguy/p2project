


/// Object which is passed into the anticheat core, describing an input into the system.
///
/// It is immutable, and contains this information:
/// - Generated timestamp. Used for clients to know when in game-time it occured, and therefore where to insert it.
/// - Sender. Which client produced this event. Used to map inputs to players.
/// - Action. What input occured.
/// - ID. Unique identifier for this event for the sending client.
/// - ? Server receipt timestamp. Used to discard events which arrive to the server late. Not sure if needed, as server may drop these events anyway.
///
class Event {

}