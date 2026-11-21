import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_quality.dart';

/// A finished recording: where it is on this phone, and its bytes.
class Recording {
  const Recording({required this.path, required this.bytes});

  final String path;
  final Uint8List bytes;
}

/// Records the user's voice. The app uses [RecordVoiceRecorder]; widget
/// tests use a fake that returns a generated WAV.
abstract class VoiceRecorder {
  /// Asks for microphone access if needed. False when the user refuses.
  Future<bool> requestPermission();

  /// Starts recording to a new file named after [id].
  Future<void> start(String id);

  /// Stops and returns the recording (null if nothing was recorded).
  Future<Recording?> stop();

  /// Stops and throws the recording away (e.g. leaving the screen).
  Future<void> cancel();

  /// Deletes a finished recording that is not kept (failed the check).
  Future<void> discard(Recording recording);

  /// Keeps a recording that passed the check: saves it at a normal
  /// playback level ([AudioQuality.louder]) and returns the saved version.
  Future<Recording> keep(Recording recording);
}

/// Set in main() (and in tests, to a fake).
late VoiceRecorder voiceRecorder;

/// Where recordings are kept on this phone: `<app documents>/recordings/`.
/// Recordings are personal data and are never uploaded (Spark plan: no
/// Firebase Storage); they stay inside the app's private folder.
class RecordingFiles {
  RecordingFiles._();

  static String? _directory;

  /// Called once in main().
  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/recordings');
    await dir.create(recursive: true);
    _directory = dir.path;
  }

  static String pathFor(String id) {
    final dir = _directory;
    if (dir == null) throw StateError('RecordingFiles.init() was not called');
    return '$dir/$id.wav';
  }

  /// Deletes a recording that won't be kept (failed the quality check).
  static Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// The recording of attempt [id] if it is on this phone, else null.
  static String? existing(String id) {
    final dir = _directory;
    if (dir == null) return null;
    final path = '$dir/$id.wav';
    return File(path).existsSync() ? path : null;
  }
}

/// [VoiceRecorder] with the `record` package: 16 kHz, mono, 16-bit PCM WAV,
/// the format the model was trained on (CLAUDE.md).
class RecordVoiceRecorder implements VoiceRecorder {
  final _recorder = AudioRecorder();
  String? _path;

  static const config = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
  );

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String id) async {
    _path = RecordingFiles.pathFor(id);
    await _recorder.start(config, path: _path!);
  }

  @override
  Future<Recording?> stop() async {
    final path = await _recorder.stop() ?? _path;
    _path = null;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return Recording(path: path, bytes: await file.readAsBytes());
  }

  @override
  Future<void> cancel() async {
    _path = null;
    await _recorder.cancel(); // also deletes the file
  }

  @override
  Future<void> discard(Recording recording) =>
      RecordingFiles.delete(recording.path);

  @override
  Future<Recording> keep(Recording recording) async {
    final bytes = AudioQuality.louder(recording.bytes);
    if (!identical(bytes, recording.bytes)) {
      await File(recording.path).writeAsBytes(bytes, flush: true);
    }
    return Recording(path: recording.path, bytes: bytes);
  }
}
