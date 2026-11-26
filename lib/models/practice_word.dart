/// One word (or short phrase) in a practice session.
class PracticeWord {
  const PracticeWord({
    required this.text,
    this.romanized = '',
    this.exerciseId = '',
  });

  /// Sinhala text, NFC (e.g. කමල).
  final String text;

  /// Optional Latin spelling shown under the word as a reading aid
  /// (e.g. "kamala"); '' when the therapist didn't give one.
  final String romanized;

  /// The exercise this word comes from ('' for sample data;
  /// "starter-w001" for a starter word the user practised on their own).
  final String exerciseId;

  static const starterPrefix = 'starter-';

  /// Practised on the user's own, from the starter words (not assigned).
  bool get isSelfPractice => exerciseId.startsWith(starterPrefix);
}
