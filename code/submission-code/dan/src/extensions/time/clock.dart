

class Clock {
  final _stopwatch = Stopwatch();

  Future<void> initialise() async {
    _stopwatch.start();
  }

  Duration getTime() => _stopwatch.elapsed;
}