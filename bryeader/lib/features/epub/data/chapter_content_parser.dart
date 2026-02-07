import 'package:html/parser.dart' as html_parser;

class TokenRange {
  const TokenRange({required this.text, required this.start, required this.end});

  final String text;
  final int start;
  final int end;
}

class ParsedChapter {
  const ParsedChapter({required this.text, required this.tokens});

  final String text;
  final List<TokenRange> tokens;
}

class ChapterContentParser {
  static ParsedChapter parse(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final raw = document.body?.text ?? '';
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final tokens = <TokenRange>[];

    final matches = RegExp(r'\S+').allMatches(text);
    for (final match in matches) {
      tokens.add(
        TokenRange(
          text: match.group(0) ?? '',
          start: match.start,
          end: match.end,
        ),
      );
    }

    return ParsedChapter(text: text, tokens: tokens);
  }
}
