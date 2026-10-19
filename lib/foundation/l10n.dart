/// 多言語の基盤。言語・地域はデータ、コードは中立。
/// 文言は全て翻訳ファイル（arb 相当の Map）経由で引く。
library;

enum ReviewStatus { draft, reviewed, approved }

/// 端末言語から対応言語を決める。
/// 完全一致 → 言語コード一致（pt-BR → pt）→ [fallbackChain] の順。
String resolveLocale(
  String device,
  Set<String> supported, {
  List<String> fallbackChain = const ['en', 'ja'],
}) {
  final d = device.replaceAll('_', '-');
  if (supported.contains(d)) return d;
  final lang = d.split('-').first;
  if (supported.contains(lang)) return lang;
  for (final s in supported) {
    if (s.split('-').first == lang) return s;
  }
  for (final f in fallbackChain) {
    if (supported.contains(f)) return f;
  }
  throw ArgumentError('対応言語が見つからない: $device');
}

/// 翻訳引き。`{name}` の置換と、簡易ICU複数形
/// `{count, plural, one{# move} other{# moves}}` に対応する。
class Translator {
  Translator(
    this.locale,
    this.bundles, {
    this.fallbackChain = const ['en', 'ja'],
  });

  final String locale;
  final Map<String, Map<String, String>> bundles;
  final List<String> fallbackChain;

  String tr(String key, [Map<String, Object> args = const {}]) {
    for (final l in [locale, ...fallbackChain]) {
      final m = bundles[l]?[key];
      if (m != null) return _format(m, args, l);
    }
    return key; // 欠落は lint で検出する前提。実行時はキーを返して落とさない。
  }

  static String _format(String msg, Map<String, Object> args, String locale) {
    final out = StringBuffer();
    var i = 0;
    while (i < msg.length) {
      if (msg[i] != '{') {
        out.write(msg[i++]);
        continue;
      }
      final end = _matchBrace(msg, i);
      if (end < 0) {
        out.write(msg.substring(i));
        break;
      }
      final inner = msg.substring(i + 1, end);
      out.write(_expand(inner, args, locale));
      i = end + 1;
    }
    return out.toString();
  }

  static String _expand(String inner, Map<String, Object> args, String locale) {
    final parts = inner.split(',');
    final name = parts.first.trim();
    final value = args[name];
    if (parts.length == 1) return value?.toString() ?? '{$name}';
    final kind = parts[1].trim();
    if (kind != 'plural' || value is! int) return '{$inner}';
    final body = inner.substring(inner.indexOf('plural') + 'plural'.length);
    final branches = <String, String>{};
    var j = 0;
    while (j < body.length) {
      final open = body.indexOf('{', j);
      if (open < 0) break;
      final sel = body.substring(j, open).replaceAll(',', '').trim();
      final close = _matchBrace(body, open);
      if (close < 0) break;
      branches[sel] = body.substring(open + 1, close);
      j = close + 1;
    }
    final category = _pluralCategory(locale, value);
    final chosen =
        branches['=$value'] ?? branches[category] ?? branches['other'] ?? '';
    return _format(chosen.replaceAll('#', '$value'), args, locale);
  }

  /// ja/ko/zh などは複数形なし（other）。それ以外は one/other。
  /// 言語追加で規則が必要になったらここに足す。
  static String _pluralCategory(String locale, int n) {
    final lang = locale.split('-').first;
    if (const {'ja', 'ko', 'zh', 'th', 'id'}.contains(lang)) return 'other';
    return n == 1 ? 'one' : 'other';
  }

  static int _matchBrace(String s, int open) {
    var depth = 0;
    for (var k = open; k < s.length; k++) {
      if (s[k] == '{') depth++;
      if (s[k] == '}' && --depth == 0) return k;
    }
    return -1;
  }
}

/// CI用 l10n 検査。基準言語 [base] に対する [other] の差分を返す。
class L10nLint {
  const L10nLint._();

  static final _placeholder = RegExp(r'\{(\w+)(?=[,}])');

  static Set<String> placeholders(String msg) =>
      {for (final m in _placeholder.allMatches(msg)) m.group(1)!};

  /// 空なら合格。欠落キー・未使用キー・プレースホルダ不一致を文字列で返す。
  static List<String> compare(
    Map<String, String> base,
    Map<String, String> other, {
    String locale = '?',
  }) {
    final issues = <String>[];
    for (final k in base.keys) {
      final o = other[k];
      if (o == null) {
        issues.add('$locale: 欠落キー $k');
        continue;
      }
      final a = placeholders(base[k]!);
      final b = placeholders(o);
      if (a.length != b.length || !a.containsAll(b)) {
        issues.add('$locale: $k のプレースホルダ不一致 $a vs $b');
      }
    }
    for (final k in other.keys) {
      if (!base.containsKey(k)) issues.add('$locale: 未使用キー $k');
    }
    return issues;
  }

  /// リリース可否: approved 以外のキーを返す（空なら公開可）。
  static List<String> notApproved(Map<String, ReviewStatus> status,
      {String locale = '?'}) {
    return [
      for (final e in status.entries)
        if (e.value != ReviewStatus.approved)
          '$locale: ${e.key} は ${e.value.name}',
    ];
  }
}
