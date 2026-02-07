import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class TokenRange {
  const TokenRange({required this.text, required this.start, required this.end});

  final String text;
  final int start;
  final int end;
}

class TextBlock {
  const TextBlock({
    required this.text,
    required this.type,
    required this.start,
    required this.end,
  });

  final String text;
  final String type; // 'paragraph', 'heading', 'list'
  final int start;
  final int end;
}

class ParsedChapter {
  const ParsedChapter({
    required this.text,
    required this.tokens,
    required this.blocks,
  });

  final String text;
  final List<TokenRange> tokens;
  final List<TextBlock> blocks;
}

class ChapterContentParser {
  static ParsedChapter parse(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final body = document.body;
    if (body == null) {
      return const ParsedChapter(text: '', tokens: [], blocks: []);
    }

    final blocks = <TextBlock>[];
    final allText = StringBuffer();
    final tokens = <TokenRange>[];
    var globalOffset = 0;

    // Process each element to preserve structure
    void processElement(element) {
      final tagName = element.localName?.toLowerCase() ?? '';
      
      // Check if it's a block element
      if (['p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote'].contains(tagName)) {
        final text = element.text.trim();
        if (text.isNotEmpty) {
          final start = globalOffset;
          final blockType = tagName.startsWith('h') ? 'heading' : 
                           tagName == 'li' ? 'list' : 'paragraph';
          
          // Add paragraph break before block (except first)
          if (allText.isNotEmpty) {
            allText.write('\n\n');
            globalOffset += 2;
          }
          
          // Normalize whitespace within the block
          final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ');
          allText.write(normalizedText);
          
          final textLength = normalizedText.length;
          final endPos = (globalOffset + textLength).round();
          blocks.add(TextBlock(
            text: normalizedText,
            type: blockType,
            start: start,
            end: endPos,
          ));
          
          // Extract tokens from this block
          final matches = RegExp(r'\S+').allMatches(normalizedText);
          for (final match in matches) {
            tokens.add(
              TokenRange(
                text: match.group(0) ?? '',
                start: start + match.start,
                end: start + match.end,
              ),
            );
          }
          
          globalOffset = (globalOffset + textLength).round();
        }
      } else {
        // Process children recursively
        for (final child in element.nodes) {
          if (child is Element) {
            processElement(child);
          } else if (child is Text) {
            final text = child.text.trim();
            if (text.isNotEmpty) {
              final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ');
              allText.write(normalizedText);
              
              final textLength = normalizedText.length;
              final matches = RegExp(r'\S+').allMatches(normalizedText);
              for (final match in matches) {
                tokens.add(
                  TokenRange(
                    text: match.group(0) ?? '',
                    start: globalOffset + match.start,
                    end: globalOffset + match.end,
                  ),
                );
              }
              
              globalOffset = (globalOffset + textLength).toInt();
            }
          }
        }
      }
    }

    // Process all top-level elements
    for (final element in body.children) {
      processElement(element);
    }

    // If no blocks found, fall back to simple parsing
    if (blocks.isEmpty) {
      final raw = body.text;
      final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
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
      return ParsedChapter(text: text, tokens: tokens, blocks: const []);
    }

    return ParsedChapter(
      text: allText.toString(),
      tokens: tokens,
      blocks: blocks,
    );
  }
}
