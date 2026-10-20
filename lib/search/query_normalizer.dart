/// Port of the Android app's `QueryUtil.normalizeQuery`.
///
/// The rules are intentionally kept in the same order as the Java version so
/// that the bundled vocal/non-vocal indexes keep producing identical hits.
abstract final class QueryNormalizer {
  static final RegExp _whitespaceRun = RegExp(r'[ \t\n\x0B\f\r]+');
  static final RegExp _forbiddenChars = RegExp(r"[^A-Z`'\- \t\n\x0B\f\r]");
  static final RegExp _doubledConsonants = RegExp(
    r'(B|C|D|F|G|H|J|K|L|M|N|P|Q|R|S|T|V|W|X|Y|Z)[ \t\n\x0B\f\r]?\1+',
  );
  static final RegExp _doubledDigraphs = RegExp(
    r'(KH|CH|SH|TS|SY|DH|TH|ZH|DZ|GH)[ \t\n\x0B\f\r]?\1+',
  );
  static final RegExp _doubledVowels = RegExp(r'(A|I|U|E|O)\1+');
  static final RegExp _leadingVowel = RegExp(r'^(A|I|U)');
  static final RegExp _spaceVowel = RegExp(r'[ \t\n\x0B\f\r](A|I|U)');
  static final RegExp _iThenAU = RegExp(r'I(A|U)');
  static final RegExp _uThenAI = RegExp(r'U(A|I)');
  static final RegExp _ngThenConsonant = RegExp(
    r'(A|I|U)NG[ \t\n\x0B\f\r]?(D|F|J|K|P|Q|S|T|V|Z)',
  );
  static final RegExp _nThenB = RegExp(r'N[ \t\n\x0B\f\r]?B');
  static final RegExp _nThenIdgham = RegExp(r'N[ \t\n\x0B\f\r]?(N|M|L|R|Y|W)');
  static final RegExp _khOrCh = RegExp(r'KH|CH');
  static final RegExp _shTsSy = RegExp(r'SH|TS|SY');
  static final RegExp _dh = RegExp(r'DH');
  static final RegExp _zhDz = RegExp(r'ZH|DZ');
  static final RegExp _th = RegExp(r'TH');
  static final RegExp _ngVowel = RegExp(r'NG(A|I|U)');
  static final RegExp _gh = RegExp(r'GH');
  static final RegExp _apostrophes = RegExp(r"'|`");
  static final RegExp _qOrK = RegExp(r'Q|K');
  static final RegExp _fvp = RegExp(r'F|V|P');
  static final RegExp _jOrZ = RegExp(r'J|Z');
  static final RegExp _allWhitespace = RegExp(r'[ \t\n\x0B\f\r]');
  static final RegExp _vowels = RegExp(r'A|I|U');

  static String _replaceGroup(
    String input,
    RegExp pattern,
    int group, {
    String prefix = '',
    String infix = '',
    int? secondGroup,
  }) {
    return input.replaceAllMapped(pattern, (match) {
      final first = match.group(group) ?? '';
      final second = secondGroup == null
          ? ''
          : (match.group(secondGroup) ?? '');
      return '$prefix$first$infix$second';
    });
  }

  static String normalize(String query, {required bool isVocal}) {
    final first = query
        .toUpperCase()
        .replaceAll(_whitespaceRun, ' ')
        .replaceAll('-', ' ')
        .replaceAll(_forbiddenChars, '');

    final second = first.replaceAll('O', 'A').replaceAll('E', 'I');

    final third = _replaceGroup(second, _doubledConsonants, 1);
    final thirdDigraphs = _replaceGroup(third, _doubledDigraphs, 1);

    final fourth = _replaceGroup(thirdDigraphs, _doubledVowels, 1);

    final fifth = fourth.replaceAll('AI', 'AY').replaceAll('AU', 'AW');

    final sixth = _replaceGroup(fifth, _leadingVowel, 1, prefix: 'X');
    final sixthSpace = _replaceGroup(sixth, _spaceVowel, 1, prefix: 'X');
    final sixthI = _replaceGroup(sixthSpace, _iThenAU, 1, prefix: 'IX');
    final sixthU = _replaceGroup(sixthI, _uThenAI, 1, prefix: 'UX');

    final seventh = _replaceGroup(
      sixthU,
      _ngThenConsonant,
      1,
      infix: 'N',
      secondGroup: 2,
    );

    final eighth = seventh.replaceAll(_nThenB, 'MB');

    final ninth = eighth
        .replaceAll('DUNYA', 'DUN_YA')
        .replaceAll('BUNYAN', 'BUN_YAN')
        .replaceAll('QINWAN', 'KIN_WAN')
        .replaceAll('KINWAN', 'KIN_WAN')
        .replaceAll('SINWAN', 'SIN_WAN')
        .replaceAll('SHINWAN', 'SIN_WAN')
        .replaceAllMapped(_nThenIdgham, (m) => m.group(1)!)
        .replaceAll('DUN_YA', 'DUNYA')
        .replaceAll('BUN_YAN', 'BUNYAN')
        .replaceAll('KIN_WAN', 'KINWAN')
        .replaceAll('SIN_WAN', 'SINWAN');

    final tenth = ninth
        .replaceAll(_khOrCh, 'H')
        .replaceAll(_shTsSy, 'S')
        .replaceAll(_dh, 'D')
        .replaceAll(_zhDz, 'Z')
        .replaceAll(_th, 'T')
        .replaceAllMapped(_ngVowel, (m) => 'X${m.group(1)}')
        .replaceAll(_gh, 'G');

    final eleventh = tenth
        .replaceAll(_apostrophes, 'X')
        .replaceAll(_qOrK, 'K')
        .replaceAll(_fvp, 'F')
        .replaceAll(_jOrZ, 'Z');

    final twelfth = eleventh.replaceAll(_allWhitespace, '');

    if (!isVocal) {
      return twelfth.replaceAll(_vowels, '');
    }
    return twelfth;
  }
}
