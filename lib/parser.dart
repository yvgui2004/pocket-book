import 'models.dart';

/// 把「炒饭10 奶茶5」这类输入拆成条目。
/// 支持空格、中英文逗号、顿号、分号、换行分隔；
/// 金额可以带小数，写在名称后面或前面；纯数字会记为「未命名」。
List<ParseItem> parseInput(String text) {
  final tokens = text
      .trim()
      .split(RegExp(r'[\s,，、;；\n]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  final out = <ParseItem>[];

  for (var i = 0; i < tokens.length; i++) {
    final tok = tokens[i];

    if (!RegExp(r'\d').hasMatch(tok)) {
      if (i + 1 < tokens.length &&
          RegExp(r'^\d+(\.\d+)?$').hasMatch(tokens[i + 1])) {
        final amount = double.parse(tokens[i + 1]);
        out.add(ParseItem(tok, amount, amount > 0));
        i++;
      } else {
        out.add(ParseItem(tok, 0, false));
      }
      continue;
    }

    var m = RegExp(r'^(.*?)(\d+(?:\.\d+)?)$').firstMatch(tok);
    if (m != null && m.group(1)!.isNotEmpty) {
      final amount = double.parse(m.group(2)!);
      out.add(ParseItem(m.group(1)!, amount, amount > 0));
      continue;
    }

    m = RegExp(r'^(\d+(?:\.\d+)?)([^\d]+)$').firstMatch(tok);
    if (m != null) {
      final amount = double.parse(m.group(1)!);
      out.add(ParseItem(m.group(2)!, amount, amount > 0));
      continue;
    }

    m = RegExp(r'^(\d+(?:\.\d+)?)$').firstMatch(tok);
    if (m != null) {
      final amount = double.parse(m.group(1)!);
      out.add(ParseItem('未命名', amount, amount > 0));
      continue;
    }

    out.add(ParseItem(tok, 0, false));
  }

  return out;
}