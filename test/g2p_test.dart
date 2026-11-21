import 'package:flutter_test/flutter_test.dart';

import 'package:sonus_app/services/g2p.dart';

String ph(String text) => SinhalaG2p.convert(text).phonemes.join(' ');

/// The same cases as ../sonus/tests/test_g2p.py, so the Dart copy of the
/// rules matches the Python one used by the analysis service.
void main() {
  const words = {
    'ගම': 'ɡ a m ə',
    'මම': 'm a m ə',
    'ගෙදර': 'ɡ e d̪ ə r ə',
    'බලනවා': 'b a l ə n ə ʋ aː',
    'කන්ද': 'k a n d̪ ə',
    'කඳ': 'k a ⁿd̪ ə',
    'බත්': 'b a t̪',
    'ද': 'd̪ ə',
    'සිංහල': 's i ŋ h ə l ə',
    'තාත්තා': 't̪ aː t̪ t̪ aː',
    'ක්රමය': 'k r a m ə j ə',
    'ධර්මය': 'd̪ a r m ə j ə',
    'ශාලාව': 'ʃ aː l aː ʋ ə',
    'පරපුර': 'p a r ə p u r ə',
    'වහන්සේ': 'ʋ a h a n s eː',
    'පහසුවෙන්': 'p a h ə s u ʋ e n',
    'මහත': 'm a h ə t̪ ə',
    'කරනවා': 'k ə r ə n ə ʋ aː',
    'කර': 'k ə r ə',
    'කරන්න': 'k ə r a n n ə',
    'කළ': 'k ə l ə',
    'කළේ': 'k ə l eː',
    'කරුණ': 'k a r u n ə',
    'කර්මය': 'k a r m ə j ə',
    'යනවා': 'j ə n ə ʋ aː',
    'කනවා': 'k ə n ə ʋ aː',
    'තමයි': 't̪ a m a j i',
    'නරකයි': 'n a r ə k a j i',
    'ඥානය': 'ɲ aː n ə j ə',
    'සංඥා': 's a ŋ k ɲ aː',
    'නීතිඥයා': 'n iː t̪ i k ɲ ə j aː',
    // Lexicon.
    'සහ': 's a h a',
    'වන': 'ʋ ə n ə',
    'කමල': 'k a m a l ə',
    // Practice words.
    'මල': 'm a l ə',
    'ගස': 'ɡ a s ə',
    'පොත': 'p o t̪ ə',
    'රස': 'r a s ə',
  };

  for (final entry in words.entries) {
    test('${entry.key} -> ${entry.value}', () {
      expect(ph(entry.key), entry.value);
    });
  }

  test('phrases: punctuation becomes a word break', () {
    final result = SinhalaG2p.convert('මම, ගෙදර!');
    expect(result.text, 'මම ගෙදර');
    expect(result.words, [
      ['m', 'a', 'm', 'ə'],
      ['ɡ', 'e', 'd̪', 'ə', 'r', 'ə'],
    ]);
  });

  test('legacy typing order and zero-width joiner are fixed', () {
    expect(ph('පේ්රම'), 'p r eː m ə');
    expect(ph('ශ්‍රී'), ph('ශ්රී'));
  });

  test('a vowel sign typed in two parts is composed (NFC)', () {
    final result = SinhalaG2p.convert('පොත'); // ප + ෙ + ා + ත
    expect(result.text, 'පොත');
    expect(result.phonemes.join(' '), 'p o t̪ ə');
  });

  test('Latin letters, numbers and empty text are refused', () {
    expect(SinhalaG2p.convert('hello').ok, isFalse);
    expect(SinhalaG2p.convert('මල 3').ok, isFalse);
    expect(SinhalaG2p.convert('   ').ok, isFalse);
    expect(SinhalaG2p.convert('ා').ok, isFalse);
  });

  test('ASCII names', () {
    expect(SinhalaG2p.asciiOf('ə'), 'ax');
    expect(SinhalaG2p.asciiOf('t̪'), 't');
    expect(SinhalaG2p.asciiOf('ⁿd̪'), 'nd');
  });
}
