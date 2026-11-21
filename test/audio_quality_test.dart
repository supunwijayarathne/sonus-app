import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:sonus_app/services/audio_quality.dart';

import 'fakes/fake_voice_recorder.dart';

void main() {
  test('a clear 1 s recording passes', () {
    final q = AudioQuality.check(testWav(seconds: 1));
    expect(q.ok, isTrue);
    expect(q.reason, isNull);
    expect(q.durationS, 1.0);
  });

  test('empty', () {
    expect(AudioQuality.check(testWav(seconds: 0)).reason, AudioQuality.empty);
  });

  test('shorter than 0.3 s', () {
    final q = AudioQuality.check(testWav(seconds: 0.2));
    expect(q.ok, isFalse);
    expect(q.reason, AudioQuality.tooShort);
  });

  test('longer than 15 s', () {
    expect(
      AudioQuality.check(testWav(seconds: 15.5)).reason,
      AudioQuality.tooLong,
    );
  });

  test('silent or near-silent', () {
    expect(AudioQuality.check(testWav(level: 0)).reason, AudioQuality.tooQuiet);
    // 0.005 of full scale is about -49 dBFS.
    expect(
      AudioQuality.check(testWav(level: 0.005)).reason,
      AudioQuality.tooQuiet,
    );
    // 0.05 is about -29 dBFS: quiet speech, still accepted.
    expect(AudioQuality.check(testWav(level: 0.05)).ok, isTrue);
  });

  test('a short loud word in a quiet recording passes', () {
    final quiet = testWav(seconds: 2, level: 0.001);
    final loud = testWav(seconds: 0.2, level: 0.3);
    // Put 0.2 s of tone in the middle of the quiet recording.
    quiet.setRange(44 + 16000, 44 + 16000 + loud.length - 44, loud, 44);
    expect(AudioQuality.check(quiet).ok, isTrue);
  });

  test('not a WAV file', () {
    expect(
      AudioQuality.check(Uint8List.fromList([1, 2, 3])).reason,
      AudioQuality.unreadable,
    );
    expect(
      AudioQuality.check(Uint8List.fromList('RIFF....WAVEjunk'.codeUnits))
          .reason,
      AudioQuality.unreadable,
    );
  });

  group('louder', () {
    double peakDbfs(Uint8List wav) {
      final pcm = PcmAudio(ByteData.sublistView(wav, 44), 16000, 1);
      var peak = 0;
      for (var i = 0; i < pcm.frameCount; i++) {
        peak = peak > pcm.sample(i).abs() ? peak : pcm.sample(i).abs();
      }
      return 20 * math.log(peak / 32768) / math.ln10;
    }

    test('a quiet recording is raised to about -3 dBFS', () {
      // 0.03 of full scale is about -30 dBFS, like the emulator microphone.
      final out = AudioQuality.louder(testWav(level: 0.03));
      expect(peakDbfs(out), closeTo(-3.1, 0.2));
      expect(AudioQuality.check(out).durationS, 1.0); // still a valid WAV
    });

    test('the boost is limited to 30x', () {
      final out = AudioQuality.louder(testWav(level: 0.001));
      expect(peakDbfs(out), closeTo(-60 + 29.5, 0.5));
    });

    test('loud recordings and non-WAV bytes are left alone', () {
      final loud = testWav(level: 0.9);
      expect(AudioQuality.louder(loud), same(loud));
      final junk = Uint8List.fromList([1, 2, 3]);
      expect(AudioQuality.louder(junk), same(junk));
    });
  });

  test('loudest frame level in dBFS', () {
    // A sine of amplitude 0.5 has RMS 0.354, about -9 dBFS.
    final wav = testWav(level: 0.5);
    final pcm = PcmAudio(ByteData.sublistView(wav, 44), 16000, 1);
    expect(AudioQuality.loudestFrameDbfs(pcm), closeTo(-9.0, 0.2));
  });
}
