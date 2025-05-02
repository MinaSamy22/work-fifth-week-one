import 'dart:async';

class QuizTimer {
  final int duration;
  final Function(int) onTick;
  final Function() onTimeout;

  late int timeRemaining;
  late Timer _timer;
  bool _paused = false;
  DateTime? _pauseTime;

  QuizTimer({
    required this.duration,
    required this.onTick,
    required this.onTimeout,
  }) {
    timeRemaining = duration;
  }

  String get formattedTime {
    final minutes = (timeRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paused) return;

      timeRemaining--;
      onTick(timeRemaining);

      if (timeRemaining <= 0) {
        timer.cancel();
        onTimeout();
      }
    });
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _pauseTime = DateTime.now();
    _timer.cancel();
  }

  void resume() {
    if (!_paused || _pauseTime == null) return;

    final pausedDuration = DateTime.now().difference(_pauseTime!);
    if (timeRemaining > pausedDuration.inSeconds) {
      timeRemaining -= pausedDuration.inSeconds;
    } else {
      timeRemaining = 0;
      onTimeout();
      return;
    }

    _paused = false;
    _pauseTime = null;
    start();
  }

  void dispose() {
    _timer.cancel();
  }
}