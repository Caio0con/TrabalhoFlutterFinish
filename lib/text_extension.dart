import 'package:flutter/material.dart';

List<InlineSpan> parseDescricaoComCheckbox(String descricao) {
  final regex = RegExp(r'(\[ \]|\[x\])');
  final matches = regex.allMatches(descricao);

  List<InlineSpan> spans = [];
  int lastEnd = 0;

  for (final match in matches) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: descricao.substring(lastEnd, match.start)));
    }
    final tag = match.group(0);
    spans.add(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Checkbox(
        value: tag == '[x]',
        onChanged: null,
        visualDensity: VisualDensity.compact,
      ),
    ));
    lastEnd = match.end;
  }
  if (lastEnd < descricao.length) {
    spans.add(TextSpan(text: descricao.substring(lastEnd)));
  }
  return spans;
}