


/// Object which is passed into the anticheat core, describing an input into the system.
///
/// It is immutable, and contains this information:
/// - Generated timestamp. Used for clients to know when in game-time it occured, and therefore where to insert it.
/// - Sender. Which client (or the server?) produced this event. Used to map inputs to players.
/// - Action. What input occurred.
/// - ID. Unique identifier for this event for the sending client.
/// - ? Server receipt timestamp. Used to discard events which arrive to the server late. Not sure if needed, as server may drop these events anyway.
/// - If it's a local or server generated event. Local events must receive a server confirmation before being baked in. Undecided when it should be discarded.
///
/// An event may be discarded, but the same ID cannot be used for another event. The ID is built from GameID + SenderID + EventID, and is unique for the duration of the game.
///
class Event {
  Event({
    required this.serverReceiptTimestamp,
    required this.generatedTimestamp,
    required this.senderID,
    required this.type,
    required this.eventID,
    required this.isLocal,
  });

  // TODO: Change timestamp type?
  final Duration serverReceiptTimestamp;
  // TODO: Change timestamp type?
  final Duration generatedTimestamp;
  // TODO: Change to ID type?
  final int senderID;
  // TODO: Change type?
  final String type;
  // TODO: Change type?
  final int eventID;
  // TODO: Finalise how local / server events work?
  final bool isLocal;
}