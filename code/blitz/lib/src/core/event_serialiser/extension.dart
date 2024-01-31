extension MapExtension on Map<String, dynamic> {
  bool containsAllKeys(List<String> keys) {
    return keys.every((key) => containsKey(key));
  }

  void containsAllKeysOrThrow(List<String> keys) {
    if (!containsAllKeys(keys)) {
      throw FormatException(
          'JSON string does not contain all required keys: $keys');
    }
  }
}
