import 'dart:math' as math;
import 'dart:typed_data';

import '../models/analysis_result.dart';

/// The on-phone quality check (CLAUDE.md "Analysis flow", step 3), run on
/// the recorded WAV *before* anything is analysed or saved.
///
/// Rejects: empty, shorter than 0.3 s, longer than 15 s, or near-silent
/// recordings, each with a friendly "please record again" message.
class AudioQuality {
  AudioQuality._();

  static const minSeconds = 0.3;
  static const maxSeconds = 15.0;

  /// Near-silent: even the loudest 30 ms of the recording is quieter than
  /// this. (The training data dropped whole clips below -50 dBFS; speech
  /// in a quiet room peaks well above -40 dBFS.)
  static const silenceDbfs = -40.0;
  static const _frameSeconds = 0.03;

  static const empty = 'The recording is empty. Please record again.';
  static const tooShort =
      'The recording is too short. Please say the whole word and record again.';
  static const tooLong =
      'The recording is longer than 15 seconds. Please record again.';
  static const tooQuiet =
      "We couldn't hear anything. Please hold the phone closer and record again.";
  static const unreadable =
      'The recording could not be read. Please record again.';

  /// Checks a 16-bit PCM WAV file.
  static QualityCheck check(Uint8List wav) {
    final pcm = _Wav.parse(wav);
    if (pcm == null) return _fail(unreadable, 0);

    final seconds = pcm.frameCount / pcm.sampleRate;
    if (pcm.frameCount == 0) return _fail(empty, 0);
    if (seconds < minSeconds) return _fail(tooShort, seconds);
    if (seconds > maxSeconds) return _fail(tooLong, seconds);
    if (loudestFrameDbfs(pcm) < silenceDbfs) return _fail(tooQuiet, seconds);

    return QualityCheck(ok: true, durationS: _round(seconds));
  }

  /// Level of the loudest 30 ms window, in dBFS (0 = full scale).
  static double loudestFrameDbfs(PcmAudio pcm) {
    final frame = math.max(1, (pcm.sampleRate * _frameSeconds).round());
    var loudest = 0.0;
    for (var start = 0; start < pcm.frameCount; start += frame) {
      final end = math.min(start + frame, pcm.frameCount);
      var sum = 0.0;
      for (var i = start; i < end; i++) {
        final x = pcm.sample(i) / 32768;
        sum += x * x;
      }
      loudest = math.max(loudest, math.sqrt(sum / (end - start)));
    }
    return loudest <= 0 ? -120 : 20 * math.log(loudest) / math.ln10;
  }

  /// The loudest sample after [louder]: 70% of full scale (about -3 dBFS).
  static const _targetPeak = 0.7 * 32767;

  /// [louder] never boosts more than this (30x is about +30 dB), so quiet
  /// background noise is not blown up.
  static const maxGain = 30.0;

  /// A copy of [wav] scaled so its loudest sample is at [_targetPeak], for
  /// playback. Phone and emulator microphones can record very quietly.
  /// Only run on recordings that passed [check] (silence must be rejected
  /// first). The model normalises its input, so the gain does not change
  /// the analysis. Never makes a recording quieter.
  static Uint8List louder(Uint8List wav) {
    final copy = Uint8List.fromList(wav);
    final pcm = _Wav.parse(copy);
    if (pcm == null) return wav;
    final data = pcm._data; // a view into `copy`
    final samples = data.lengthInBytes ~/ 2;

    var peak = 0;
    for (var i = 0; i < samples; i++) {
      peak = math.max(peak, data.getInt16(i * 2, Endian.little).abs());
    }
    if (peak == 0) return wav;
    final gain = math.min(_targetPeak / peak, maxGain);
    if (gain <= 1) return wav;

    for (var i = 0; i < samples; i++) {
      final x = data.getInt16(i * 2, Endian.little) * gain;
      data.setInt16(i * 2, x.round().clamp(-32768, 32767), Endian.little);
    }
    return copy;
  }

  static QualityCheck _fail(String reason, double seconds) =>
      QualityCheck(ok: false, reason: reason, durationS: _round(seconds));

  static double _round(double s) => (s * 100).round() / 100;
}

/// 16-bit PCM samples from a WAV file (first channel only).
class PcmAudio {
  PcmAudio(this._data, this.sampleRate, this.channels);

  final ByteData _data;
  final int sampleRate;
  final int channels;

  int get frameCount => _data.lengthInBytes ~/ (2 * channels);

  int sample(int frame) => _data.getInt16(frame * 2 * channels, Endian.little);
}

/// A tiny WAV reader: finds the "fmt " and "data" chunks.
class _Wav {
  static PcmAudio? parse(Uint8List bytes) {
    if (bytes.length < 12) return null;
    final view = ByteData.sublistView(bytes);
    String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') return null;

    int? format, channels, sampleRate, bits;
    var at = 12;
    while (at + 8 <= bytes.length) {
      final id = tag(at);
      var size = view.getUint32(at + 4, Endian.little);
      final body = at + 8;
      if (id == 'fmt ' && body + 16 <= bytes.length) {
        format = view.getUint16(body, Endian.little);
        channels = view.getUint16(body + 2, Endian.little);
        sampleRate = view.getUint32(body + 4, Endian.little);
        bits = view.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        // Some recorders leave the size at 0 or too big: use what is there.
        if (size == 0 || body + size > bytes.length) size = bytes.length - body;
        // 1 = PCM, 0xFFFE = "extensible" (also PCM here).
        final pcm = format == 1 || format == 0xFFFE;
        if (!pcm || bits != 16 || channels == null || channels == 0) {
          return null;
        }
        if (sampleRate == null || sampleRate == 0) return null;
        return PcmAudio(
          ByteData.sublistView(bytes, body, body + size - size % 2),
          sampleRate,
          channels,
        );
      }
      at = body + size + size % 2; // chunks are padded to even sizes
    }
    return null;
  }
}
