import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sonus_app/services/audio_quality.dart';
import 'package:sonus_app/services/voice_recorder.dart';

/// A 16-bit mono PCM WAV: a tone of [seconds] at [level] (0-1 of full scale).
Uint8List testWav({
  double seconds = 1,
  double level = 0.3,
  int sampleRate = 16000,
}) {
  final frames = (seconds * sampleRate).round();
  final bytes = ByteData(44 + frames * 2);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, 36 + frames * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    final x = level * math.sin(2 * math.pi * 220 * i / sampleRate);
    bytes.setInt16(44 + i * 2, (x * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// [VoiceRecorder] for widget tests: no microphone, no files.
/// Every recording is [nextWav] (a clear 1 s tone unless a test changes it).
class FakeVoiceRecorder implements VoiceRecorder {
  FakeVoiceRecorder({this.allowed = true});

  /// Whether the user grants microphone access.
  bool allowed;

  Uint8List nextWav = testWav();

  String? _id;
  final discarded = <String>[];

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<void> start(String id) async => _id = id;

  @override
  Future<Recording?> stop() async {
    final id = _id;
    _id = null;
    return id == null ? null : Recording(path: '/fake/$id.wav', bytes: nextWav);
  }

  @override
  Future<void> cancel() async => _id = null;

  @override
  Future<void> discard(Recording recording) async =>
      discarded.add(recording.path);

  final kept = <String>[];

  @override
  Future<Recording> keep(Recording recording) async {
    kept.add(recording.path);
    return Recording(
      path: recording.path,
      bytes: AudioQuality.louder(recording.bytes),
    );
  }
}
