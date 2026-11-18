/// One word (or short phrase) in a practice session.
class PracticeWord {
  const PracticeWord({required this.text, required this.romanized});

  /// Sinhala text, NFC (e.g. කමල).
  final String text;

  /// Latin spelling shown under the word as a reading aid (e.g. "kamala").
  final String romanized;
}
