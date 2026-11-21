/// Sinhala text -> expected phonemes (inventory v1.1).
///
/// A small Dart copy of the rules in the ML repo (`../sonus/g2p/`:
/// `text_norm.py`, `letter_map.tsv`, `g2p.py`, `lexicon.tsv`). The app uses it
/// for the live preview while a therapist types an exercise, and for the
/// expected phonemes saved with the exercise. The analysis service runs the
/// Python version, so a change to the rules there must be copied here.
///
///   SinhalaG2p.convert('කමල').phonemes  ->  [k, a, m, a, l, ə]
class SinhalaG2p {
  SinhalaG2p._();

  /// Stored with each exercise (Firestore `g2pVersion`).
  static const version = 'inv-v1.1+app';

  /// Converts [text] (a word or short phrase). Never throws: when the text
  /// cannot be converted, [G2pResult.problem] says why.
  static G2pResult convert(String text) {
    final cleaned = _clean(text);
    if (cleaned.problem != null) {
      return G2pResult(
        text: cleaned.text,
        words: const [],
        problem: cleaned.problem,
      );
    }
    final words = [
      for (final word in cleaned.text.split(' ')) _wordToPhonemes(word),
    ];
    return G2pResult(text: cleaned.text, words: words);
  }

  /// ASCII name of a phoneme (the typing alias), e.g. ə -> "ax", t̪ -> "t".
  static String asciiOf(String phoneme) => _ascii[phoneme] ?? phoneme;

  // ---------------------------------------------------------------- cleaning
  // Same steps as text_norm.clean: NFC, remove zero-width characters, fix the
  // legacy typing order, punctuation -> space, refuse Latin letters and digits.

  static ({String text, String? problem}) _clean(String input) {
    var text = _composeSinhala(input);
    text = text.replaceAll(RegExp('[​‌‍⁠﻿]'), '');
    text = text.replaceAllMapped(
      RegExp('([$_vowelSignClass]+)්ර'),
      (m) => '්ර${m[1]}',
    );
    text = text.replaceAll(RegExp('(?<=[$_vowelSignClass])්'), '');

    final out = StringBuffer();
    String? problem;
    for (final ch in text.split('')) {
      final code = ch.codeUnitAt(0);
      final isSinhalaDigit = code >= 0x0DE6 && code <= 0x0DEF;
      if (code >= 0x0D80 &&
          code <= 0x0DFF &&
          code != 0x0DF4 &&
          !isSinhalaDigit) {
        out.write(ch);
      } else if (ch.trim().isEmpty ||
          _punctuation.contains(ch) ||
          code == 0x0DF4) {
        out.write(' ');
      } else if (isSinhalaDigit || RegExp(r'\d').hasMatch(ch)) {
        problem ??= 'Numbers can\'t be converted. Please write them as words.';
      } else if (RegExp(r'[A-Za-zÀ-ɏ]').hasMatch(ch)) {
        problem ??= 'Please type in Sinhala letters only.';
      } else {
        problem ??= 'Some characters can\'t be used. Please type in Sinhala.';
      }
    }

    final words = out.toString().split(' ').where((w) => w.isNotEmpty).toList();
    final cleaned = words.join(' ');
    if (problem != null) return (text: cleaned, problem: problem);
    if (words.isEmpty) return (text: '', problem: 'Please type a word.');
    for (final word in words) {
      final first = _letters[word[0]];
      if (first == null) {
        return (text: cleaned, problem: 'Some letters can\'t be converted.');
      }
      if (first.kind == _Kind.sign || first.kind == _Kind.virama) {
        return (
          text: cleaned,
          problem: 'A word can\'t start with a vowel sign.',
        );
      }
    }
    return (text: cleaned, problem: null);
  }

  static const _vowelSignClass = 'ා-ෟෲෳ';
  static const _punctuation = '.,!?;:\'"()[]{}-–—…‘’“”/\\|+*=~^_#@&%<>';

  /// Unicode NFC for Sinhala: the vowel signs that some keyboards type in two
  /// parts (ෙ + ා = ො). Dart has no built-in NFC, and these are the only
  /// Sinhala compositions.
  static String _composeSinhala(String text) => text
      .replaceAll('ො', 'ො') // ෙ + ා = ො
      .replaceAll('ෝ', 'ෝ') // ො + ් = ෝ
      .replaceAll('ේ', 'ේ') // ෙ + ් = ේ
      .replaceAll('ෞ', 'ෞ'); // ෙ + ෟ = ෞ

  // --------------------------------------------------------------- one word

  static List<String> _wordToPhonemes(String word) {
    final fromLexicon = _lexicon[word];
    if (fromLexicon != null) return fromLexicon.split(' ');
    final units = _units(word);
    _decideSchwa(units, word);
    return [for (final u in units) u.symbol];
  }

  /// Letters -> phonemes. A consonant without a vowel sign or al-lakuna gets
  /// an inherent vowel (decided later: a or ə). ං ඃ ඁ come after that vowel.
  static List<_Unit> _units(String word) {
    final chars = word.split('');
    final units = <_Unit>[];
    for (var i = 0; i < chars.length; i++) {
      final letter = _letters[chars[i]]!;
      var symbols = letter.phonemes;
      if (i == 0 && chars[i] == 'ඥ') symbols = symbols.sublist(1); // ɲ
      units.addAll(symbols.map(_Unit.new));
      if (letter.kind == _Kind.consonant) {
        final next = i + 1 < chars.length ? _letters[chars[i + 1]] : null;
        final takesInherent =
            next == null ||
            (next.kind != _Kind.sign && next.kind != _Kind.virama) ||
            'ඁංඃ'.contains(chars[i + 1]);
        if (takesInherent) units.add(_Unit('a', inherent: true));
      }
    }
    return units;
  }

  /// The schwa rules from docs/G2P.md, in order; the first that matches wins.
  static void _decideSchwa(List<_Unit> units, String word) {
    final karKal = _startsKarKal(word);
    final vowelAt = [
      for (var i = 0; i < units.length; i++)
        if (_vowels.contains(units[i].symbol)) i,
    ];
    final syllables = vowelAt.length;

    for (var k = 0; k < syllables; k++) {
      final i = vowelAt[k];
      final unit = units[i];
      if (!unit.inherent) continue;
      final next = k + 1 < syllables ? vowelAt[k + 1] : null;
      final consonantsAfter = (next ?? units.length) - i - 1;
      final rest = [for (final u in units.sublist(i + 1)) u.symbol].join(' ');

      if (consonantsAfter >= 2 || (next == null && consonantsAfter >= 1)) {
        unit.symbol = 'a'; // 1 closed syllable
      } else if (syllables == 1) {
        unit.symbol = 'ə'; // 2 one-syllable word
      } else if (k == 0 && rest == 'n a ʋ aː') {
        unit.symbol = 'ə'; // 3 CV + නවා
      } else if (k == 0 && karKal) {
        unit.symbol = 'ə'; // 4 කර / කළ
      } else if (rest == 'j i') {
        unit.symbol = 'a'; // 5 before final යි
      } else if (k == 0) {
        unit.symbol = 'a'; // 6 first syllable
      } else {
        unit.symbol = 'ə'; // 7 later open syllable
      }
    }
  }

  /// කර + inherent vowel (කර, කරනවා; not කරුණ, කර්ම), or කළ + any vowel.
  static bool _startsKarKal(String word) {
    if (word.length < 2 || word[0] != 'ක') return false;
    final third = word.length > 2 ? word[2] : '';
    // Vowel signs and al-lakuna (U+0DCA..U+0DDF, ෲ, ෳ); not ං ඃ ඁ.
    final code = third.isEmpty ? 0 : third.codeUnitAt(0);
    final thirdIsSign =
        (code >= 0x0DCA && code <= 0x0DDF) || third == 'ෲ' || third == 'ෳ';
    if (word[1] == 'ර') return !thirdIsSign;
    if (word[1] == 'ළ') return third != '්';
    return false;
  }

  // ------------------------------------------------------------------ tables

  static const _vowels = {
    'a', 'aː', 'æ', 'æː', 'i', 'iː', 'u', 'uː', 'e', 'eː', 'o', 'oː', 'ə', //
  };

  /// Reviewed exceptions (lexicon.tsv); they win over the rules.
  static const _lexicon = {
    'වන': 'ʋ ə n ə',
    'සහ': 's a h a',
    // Project author's decision (2026-11-19); rule 7 alone gives k a m ə l ə.
    'කමල': 'k a m a l ə',
  };

  static const _ascii = {
    'a': 'a', 'aː': 'aa', 'æ': 'ae', 'æː': 'aae', 'i': 'i', 'iː': 'ii', //
    'u': 'u', 'uː': 'uu', 'e': 'e', 'eː': 'ee', 'o': 'o', 'oː': 'oo', //
    'ə': 'ax', 'p': 'p', 'b': 'b', 't̪': 't', 'd̪': 'd', 'ʈ': 'T', 'ɖ': 'D', //
    'k': 'k', 'ɡ': 'g', 'tʃ': 'ch', 'dʒ': 'j', 'ᵐb': 'mb', 'ⁿd̪': 'nd', //
    'ⁿɖ': 'nD', 'ᵑɡ': 'ngg', 'm': 'm', 'n': 'n', 'ɲ': 'ny', 'ŋ': 'ng', //
    's': 's', 'ʃ': 'sh', 'h': 'h', 'f': 'f', 'r': 'r', 'l': 'l', 'j': 'y', //
    'ʋ': 'w', //
  };

  /// letter_map.tsv v1.1.
  static final Map<String, _Letter> _letters = {
    // Signs after a consonant (vowel signs and ං ඃ ඁ).
    for (final (ch, ph) in const [
      ('ඁ', 'ŋ'), ('ං', 'ŋ'), ('ඃ', 'h'), ('ා', 'aː'), ('ැ', 'æ'), //
      ('ෑ', 'æː'), ('ි', 'i'), ('ී', 'iː'), ('ු', 'u'), ('ූ', 'uː'), //
      ('ෘ', 'r u'), ('ෙ', 'e'), ('ේ', 'eː'), ('ෛ', 'a i'), ('ො', 'o'), //
      ('ෝ', 'oː'), ('ෞ', 'a u'), ('ෟ', 'l u'), ('ෲ', 'r uː'), ('ෳ', 'l uː'), //
    ])
      ch: _Letter(_Kind.sign, ph),
    '්': const _Letter(_Kind.virama, ''),
    // Independent vowels.
    for (final (ch, ph) in const [
      ('අ', 'a'), ('ආ', 'aː'), ('ඇ', 'æ'), ('ඈ', 'æː'), ('ඉ', 'i'), //
      ('ඊ', 'iː'), ('උ', 'u'), ('ඌ', 'uː'), ('ඍ', 'r u'), ('ඎ', 'r uː'), //
      ('ඏ', 'l u'), ('ඐ', 'l uː'), ('එ', 'e'), ('ඒ', 'eː'), ('ඓ', 'a i'), //
      ('ඔ', 'o'), ('ඕ', 'oː'), ('ඖ', 'a u'), //
    ])
      ch: _Letter(_Kind.vowel, ph),
    // Consonants (aspirates and retroflex n/l merged, as in the inventory).
    for (final (ch, ph) in const [
      ('ක', 'k'), ('ඛ', 'k'), ('ග', 'ɡ'), ('ඝ', 'ɡ'), ('ඞ', 'ŋ'), //
      ('ඟ', 'ᵑɡ'), ('ච', 'tʃ'), ('ඡ', 'tʃ'), ('ජ', 'dʒ'), ('ඣ', 'dʒ'), //
      ('ඤ', 'ɲ'), ('ඥ', 'k ɲ'), ('ඦ', 'n dʒ'), ('ට', 'ʈ'), ('ඨ', 'ʈ'), //
      ('ඩ', 'ɖ'), ('ඪ', 'ɖ'), ('ණ', 'n'), ('ඬ', 'ⁿɖ'), ('ත', 't̪'), //
      ('ථ', 't̪'), ('ද', 'd̪'), ('ධ', 'd̪'), ('න', 'n'), ('ඳ', 'ⁿd̪'), //
      ('ප', 'p'), ('ඵ', 'p'), ('බ', 'b'), ('භ', 'b'), ('ම', 'm'), //
      ('ඹ', 'ᵐb'), ('ය', 'j'), ('ර', 'r'), ('ල', 'l'), ('ව', 'ʋ'), //
      ('ශ', 'ʃ'), ('ෂ', 'ʃ'), ('ස', 's'), ('හ', 'h'), ('ළ', 'l'), ('ෆ', 'f'), //
    ])
      ch: _Letter(_Kind.consonant, ph),
  };
}

/// Result of [SinhalaG2p.convert].
class G2pResult {
  const G2pResult({required this.text, required this.words, this.problem});

  /// The cleaned text (NFC, single spaces): this is what gets saved.
  final String text;

  /// Phonemes per word, e.g. [[m, a, l, ə]].
  final List<List<String>> words;

  /// Why the text can't be converted (null when it can).
  final String? problem;

  bool get ok => problem == null;

  /// All phonemes in one list (the service's `expected`).
  List<String> get phonemes => [for (final w in words) ...w];
}

enum _Kind { consonant, vowel, sign, virama }

class _Letter {
  const _Letter(this.kind, String phonemes) : _phonemes = phonemes;

  final _Kind kind;
  final String _phonemes;

  List<String> get phonemes =>
      _phonemes.isEmpty ? const [] : _phonemes.split(' ');
}

class _Unit {
  _Unit(this.symbol, {this.inherent = false});

  String symbol;
  final bool inherent;
}
