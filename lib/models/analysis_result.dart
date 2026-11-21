/// The analysis service's answer for one recording (`POST /analyze`).
/// Field names follow the JSON in CLAUDE.md. Stored write-once on the attempt.
library;

/// Kinds of alignment step between expected and detected sounds.
enum OpKind { match, sub, del, ins }

/// One alignment step, e.g. expected "m", detected "n" -> [OpKind.sub].
class PhonemeOp {
  const PhonemeOp({
    required this.kind,
    this.expected,
    this.predicted,
    required this.position,
  });

  factory PhonemeOp.fromJson(Map<String, dynamic> json) {
    return PhonemeOp(
      kind: OpKind.values.byName(json['op'] as String),
      expected: json['expected'] as String?,
      predicted: json['predicted'] as String?,
      position: (json['position'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'op': kind.name,
    'expected': expected,
    'predicted': predicted,
    'position': position,
  };

  final OpKind kind;

  /// Expected sound (null for an inserted sound).
  final String? expected;

  /// Detected sound (null for a deleted sound).
  final String? predicted;

  /// Index in the expected sequence.
  final int position;

  bool get isDifference => kind != OpKind.match;
}

/// Result of the recording quality check.
class QualityCheck {
  const QualityCheck({required this.ok, this.reason, required this.durationS});

  factory QualityCheck.fromJson(Map<String, dynamic> json) {
    return QualityCheck(
      ok: json['ok'] as bool,
      reason: json['reason'] as String?,
      durationS: (json['duration_s'] as num).toDouble(),
    );
  }

  final bool ok;
  final String? reason;
  final double durationS;

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'reason': reason,
    'duration_s': durationS,
  };
}

class AnalysisResult {
  const AnalysisResult({
    required this.quality,
    required this.expected,
    required this.predicted,
    required this.ops,
    required this.matchPercent,
    required this.modelVersion,
    required this.g2pVersion,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List? ?? const []).cast<String>();

    return AnalysisResult(
      quality: QualityCheck.fromJson(Map.from(json['quality'] as Map)),
      expected: strings('expected'),
      predicted: strings('predicted'),
      ops: [
        for (final op in json['ops'] as List? ?? const [])
          PhonemeOp.fromJson(Map.from(op as Map)),
      ],
      matchPercent: (json['match_percent'] as num?)?.toDouble() ?? 0,
      modelVersion: json['model_version'] as String? ?? '',
      g2pVersion: json['g2p_version'] as String? ?? '',
    );
  }

  /// The same JSON as the service sends (stored on the attempt).
  Map<String, dynamic> toJson() => {
    'quality': quality.toJson(),
    'expected': expected,
    'predicted': predicted,
    'ops': [for (final op in ops) op.toJson()],
    'match_percent': matchPercent,
    'model_version': modelVersion,
    'g2p_version': g2pVersion,
  };

  final QualityCheck quality;

  /// Phoneme symbols. A symbol can be several code points (t̪, ⁿd̪):
  /// never split them per character.
  final List<String> expected;
  final List<String> predicted;
  final List<PhonemeOp> ops;

  /// Agreement between the expected and detected sound sequences (0-100).
  /// Not a measure of speech health or therapy progress.
  final double matchPercent;

  final String modelVersion;
  final String g2pVersion;

  /// The steps that are possible differences (sub, del, ins).
  List<PhonemeOp> get differences =>
      ops.where((op) => op.isDifference).toList();

  bool get hasDifference => differences.isNotEmpty;
}
