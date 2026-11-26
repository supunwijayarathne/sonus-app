import 'dart:async';

import 'package:sonus_app/services/reference_audio.dart';

/// [ReferencePlayer] for widget tests: no audio. Playback lasts until the
/// test calls [finish] (or the app calls [stop]).
class FakeReferencePlayer implements ReferencePlayer {
  final played = <String>[];
  Completer<void>? _current;

  bool get isPlaying => _current != null;

  @override
  Future<void> play(String assetPath) {
    played.add(assetPath);
    _current = Completer<void>();
    return _current!.future;
  }

  @override
  Future<void> stop() async => finish();

  /// The recording reaches its end.
  void finish() {
    _current?.complete();
    _current = null;
  }
}
