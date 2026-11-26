import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

import '../models/practice_word.dart';

/// One of the 100 starter words, with its computer-voice recording.
class StarterWord {
  const StarterWord({
    required this.id,
    required this.text,
    required this.english,
    this.group = '',
    required this.focus,
    required this.expected,
    required this.length,
  });

  /// "w001" … "w100"; the recording is `assets/reference_audio/{id}.wav`.
  final String id;

  /// Sinhala (e.g. මල).
  final String text;

  /// Meaning, for the therapist (e.g. "flower").
  final String english;

  /// Practice group (e.g. "r and l").
  final String group;

  /// The sounds this word is for (e.g. "l (r/l)").
  final String focus;

  /// Expected sounds from the Python G2P (the analysis service uses the same).
  final List<String> expected;

  /// Length of the recording.
  final Duration length;

  String get assetPath => 'assets/reference_audio/$id.wav';

  /// For self-practice: the exercise id is "starter-w001" (no assignment).
  PracticeWord get word =>
      PracticeWord(text: text, exerciseId: '${PracticeWord.starterPrefix}$id');
}

/// The starter word list (assets/starter_words.tsv). Its recordings are a
/// computer voice (Piper TTS), bundled with the app.
class StarterWords {
  StarterWords(List<StarterWord> words)
    : words = List.unmodifiable(words),
      _byText = {for (final w in words) w.text: w};

  /// Reads the tab-separated file; lines starting with # are comments.
  factory StarterWords.parse(String tsv) {
    final lines = [
      for (final line in tsv.split('\n'))
        if (line.trim().isNotEmpty && !line.startsWith('#')) line.trimRight(),
    ];
    final header = lines.first.split('\t');
    int col(String name) => header.indexOf(name);
    return StarterWords([
      for (final line in lines.skip(1))
        _word(line.split('\t'), col),
    ]);
  }

  static StarterWord _word(List<String> cells, int Function(String) col) {
    return StarterWord(
      id: cells[col('id')],
      text: cells[col('word')],
      english: cells[col('english')],
      group: cells[col('group')],
      focus: cells[col('focus')],
      expected: cells[col('expected')].split(' '),
      length: Duration(
        milliseconds: (double.parse(cells[col('seconds')]) * 1000).round(),
      ),
    );
  }

  static const asset = 'assets/starter_words.tsv';

  /// Called once in main().
  static Future<StarterWords> load() async =>
      StarterWords.parse(await rootBundle.loadString(asset));

  final List<StarterWord> words;
  final Map<String, StarterWord> _byText;

  /// Words by practice group, in list order ("r and l" first).
  Map<String, List<StarterWord>> get groups {
    final groups = <String, List<StarterWord>>{};
    for (final w in words) {
      (groups[w.group] ??= []).add(w);
    }
    return groups;
  }

  /// The starter word with this text, if there is one (its recording is the
  /// reference audio for any exercise with the same text).
  StarterWord? lookup(String text) => _byText[text.trim()];
}

/// Set in main(); empty in widget tests unless a test sets it.
StarterWords starterWords = StarterWords(const []);

/// Plays reference audio. The app uses [AssetReferencePlayer]; widget tests
/// use a fake (no audio plugin in tests).
abstract class ReferencePlayer {
  /// Plays a bundled recording. Completes when it ends or is stopped.
  Future<void> play(String assetPath);

  Future<void> stop();
}

ReferencePlayer referencePlayer = AssetReferencePlayer();

/// [ReferencePlayer] with just_audio. One player for the whole app.
class AssetReferencePlayer implements ReferencePlayer {
  AudioPlayer? _player;

  @override
  Future<void> play(String assetPath) async {
    final player = _player ??= AudioPlayer();
    await player.setAsset(assetPath); // also rewinds to the start
    // Finished = playback reached the end, or it was stopped.
    final finished = player.playerStateStream
        .skipWhile((s) => !s.playing)
        .firstWhere(
          (s) => !s.playing || s.processingState == ProcessingState.completed,
        );
    unawaited(player.play());
    await finished;
  }

  @override
  Future<void> stop() async => _player?.stop();
}
