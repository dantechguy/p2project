class EventIDGenerator {
  int _currentID = 0;

  int generateUniqueID() {
    return _currentID++;
  }
}
