import '../../models/analysis_result.dart';

/// All result wording in one place, so it can be checked against
/// CLAUDE.md rule 1: suggestions ("may", "possible"), never diagnoses.
class ResultText {
  ResultText._();

  static String title(AnalysisResult result) {
    if (!result.quality.ok) return 'Please record again';
    final count = result.differences.length;
    if (count == 0) return 'Sounds matched the expected sounds';
    if (count == 1) return 'Possible sound difference detected';
    return 'Possible sound differences detected';
  }

  static String explanation(AnalysisResult result) {
    if (!result.quality.ok) {
      return result.quality.reason ??
          'The recording was too short, too long or too quiet.';
    }
    final diffs = result.differences;
    if (diffs.isEmpty) {
      return 'Your sounds matched the expected sounds for this word.';
    }
    if (diffs.length > 1) {
      return '${diffs.length} sounds may differ from the expected sounds. '
          'Your therapist can review them with you.';
    }

    final op = diffs.single;
    final which = _ordinal(op.position);
    return switch (op.kind) {
      OpKind.sub =>
        'The $which sound may have been pronounced closer to '
            '/${op.predicted}/ than the expected /${op.expected}/.',
      OpKind.del =>
        'The $which sound /${op.expected}/ may not have been heard.',
      OpKind.ins => 'An extra sound /${op.predicted}/ may have been heard.',
      OpKind.match => '',
    };
  }

  /// Short label for one difference, e.g. "m → n, possible substitution".
  static String change(PhonemeOp op) {
    return switch (op.kind) {
      OpKind.sub => '${op.expected} → ${op.predicted}, possible substitution',
      OpKind.del => '${op.expected} not heard, possible omission',
      OpKind.ins => 'extra ${op.predicted}, possible addition',
      OpKind.match => '${op.expected}, matched',
    };
  }

  static String _ordinal(int index) {
    const words = [
      'first', 'second', 'third', 'fourth', 'fifth', //
      'sixth', 'seventh', 'eighth', 'ninth', 'tenth',
    ];
    return index < words.length ? words[index] : '${index + 1}th';
  }
}
