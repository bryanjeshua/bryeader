import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/highlight.dart';
import '../../../../core/models/reading_settings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../../../epub/data/chapter_content_parser.dart';
import '../../presentation/providers/reading_provider.dart';
import '../../presentation/widgets/zoomable_reader.dart';

class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({super.key, required this.arguments});

  final ReadingArguments arguments;

  @override
  ConsumerState<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage> {
  final ScrollController _scrollController = ScrollController();
  int _chapterIndex = 0;
  int? _loadedChapterIndex;
  ParsedChapter? _parsedChapter;
  TextSelection? _selection;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.arguments.initialChapter;
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      _saveProgress();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _loadChapter(String htmlContent) {
    final parsed = ChapterContentParser.parse(htmlContent);
    setState(() {
      _parsedChapter = parsed;
      _loadedChapterIndex = _chapterIndex;
      _selection = null;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _saveProgress() {
    ref.read(libraryProvider.notifier).updateProgress(
          widget.arguments.bookId,
          _chapterIndex,
          _scrollController.offset,
        );
  }

  void _showSettingsSheet(ReadingSettings settings) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        double fontSize = settings.fontSize;
        double lineHeight = settings.lineHeight;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text('Font size: ${fontSize.toStringAsFixed(0)}'),
                  Slider(
                    min: 14,
                    max: 30,
                    value: fontSize,
                    onChanged: (value) => setState(() => fontSize = value),
                  ),
                  const SizedBox(height: 8),
                  Text('Line spacing: ${lineHeight.toStringAsFixed(1)}'),
                  Slider(
                    min: 1.2,
                    max: 2.0,
                    value: lineHeight,
                    onChanged: (value) => setState(() => lineHeight = value),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(readingSettingsProvider.notifier).update(
                            settings.copyWith(
                              fontSize: fontSize,
                              lineHeight: lineHeight,
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showHighlightSheet(int start, int end) async {
    final colors = <Color>[
      const Color(0xFFFDE68A),
      const Color(0xFFBAE6FD),
      const Color(0xFFBBF7D0),
      const Color(0xFFFBCFE8),
    ];

    final selected = await showModalBottomSheet<Color>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: colors
                .map(
                  (color) => InkWell(
                    onTap: () => Navigator.of(context).pop(color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    final highlight = Highlight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.arguments.bookId,
      chapterIndex: _chapterIndex,
      startOffset: start,
      endOffset: end,
      colorValue: selected.toARGB32(),
      createdAt: DateTime.now(),
    );

    await ref
        .read(highlightsProvider(widget.arguments.bookId).notifier)
        .add(highlight);
  }

  Widget _buildTextContent(
    ParsedChapter chapter,
    List<Highlight> highlights,
    ReadingSettings settings,
  ) {
    if (chapter.blocks.isEmpty) {
      // Fallback to old rendering if no blocks
      return SelectableText.rich(
        _buildHighlightedText(chapter, highlights, settings),
        onSelectionChanged: (selection, _) {
          _selection = selection;
        },
        contextMenuBuilder: (context, editableTextState) {
          return _buildContextMenu(context, editableTextState);
        },
      );
    }

    // Build widgets for each block with proper hierarchy
    final widgets = <Widget>[];
    
    for (final block in chapter.blocks) {
      final blockSpans = <TextSpan>[];
      int cursor = block.start;
      
      // Find tokens within this block
      final blockTokens = chapter.tokens.where((token) =>
        token.start >= block.start && token.end <= block.end
      ).toList();

      for (final token in blockTokens) {
        if (token.start > cursor) {
          final text = chapter.text.substring(cursor, token.start);
          blockSpans.add(TextSpan(text: text));
        }

        final overlapping = highlights.where((h) {
          if (h.chapterIndex != _chapterIndex) {
            return false;
          }
          return h.startOffset < token.end && h.endOffset > token.start;
        }).toList();

        final bgColor = overlapping.isNotEmpty
            ? Color(overlapping.last.colorValue)
            : null;

        blockSpans.add(
          TextSpan(
            text: chapter.text.substring(token.start, token.end),
            style: bgColor == null
                ? null
                : TextStyle(
                    backgroundColor: bgColor.withValues(alpha: 0.7),
                  ),
          ),
        );

        cursor = token.end;
      }

      if (cursor < block.end) {
        blockSpans.add(TextSpan(text: chapter.text.substring(cursor, block.end)));
      }

      // Determine style based on block type
      final baseStyle = TextStyle(
        fontSize: settings.fontSize,
        height: settings.lineHeight,
        color: Theme.of(context).colorScheme.onSurface,
      );

      final blockStyle = block.type == 'heading'
          ? baseStyle.copyWith(
              fontSize: settings.fontSize * 1.4,
              fontWeight: FontWeight.bold,
            )
          : baseStyle;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: block.type == 'heading' ? 16.0 : 12.0,
            top: block.type == 'heading' ? 8.0 : 0.0,
          ),
          child: SelectableText.rich(
            TextSpan(
              style: blockStyle,
              children: blockSpans,
            ),
            onSelectionChanged: (selection, _) {
              _selection = selection;
            },
            contextMenuBuilder: (context, editableTextState) {
              return _buildContextMenu(context, editableTextState);
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  TextSpan _buildHighlightedText(
    ParsedChapter chapter,
    List<Highlight> highlights,
    ReadingSettings settings,
  ) {
    final spans = <TextSpan>[];
    int cursor = 0;

    for (final token in chapter.tokens) {
      if (token.start > cursor) {
        spans.add(TextSpan(text: chapter.text.substring(cursor, token.start)));
      }

      final overlapping = highlights.where((h) {
        if (h.chapterIndex != _chapterIndex) {
          return false;
        }
        return h.startOffset < token.end && h.endOffset > token.start;
      }).toList();

      final bgColor = overlapping.isNotEmpty
          ? Color(overlapping.last.colorValue)
          : null;

      spans.add(
        TextSpan(
          text: chapter.text.substring(token.start, token.end),
          style: bgColor == null
              ? null
              : TextStyle(
                  backgroundColor: bgColor.withValues(alpha: 0.7),
                ),
        ),
      );

      cursor = token.end;
    }

    if (cursor < chapter.text.length) {
      spans.add(TextSpan(text: chapter.text.substring(cursor)));
    }

    return TextSpan(
      style: TextStyle(
        fontSize: settings.fontSize,
        height: settings.lineHeight,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      children: spans,
    );
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
    final items = editableTextState.contextMenuButtonItems;
    if (_selection != null &&
        _selection!.isValid &&
        !_selection!.isCollapsed) {
      items.insert(
        0,
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.hideToolbar();
            final start = min(
              _selection!.start,
              _selection!.end,
            );
            final end = max(
              _selection!.start,
              _selection!.end,
            );
            _showHighlightSheet(start, end);
          },
          label: 'Highlight',
        ),
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final epubAsync = ref.watch(epubBookProvider(widget.arguments.filePath));
    final settings = ref.watch(readingSettingsProvider);
    final highlights =
        ref.watch(highlightsProvider(widget.arguments.bookId));

    return epubAsync.when(
      data: (book) {
        _chapterIndex = min(_chapterIndex, book.chapters.length - 1);
        final chapter = book.chapters[_chapterIndex];
        if (_loadedChapterIndex != _chapterIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadChapter(chapter.htmlContent);
            }
          });
        }

        final parsed = _parsedChapter;
        return Scaffold(
          appBar: AppBar(
            title: Text(chapter.title),
            actions: [
              IconButton(
                tooltip: 'Fast reading mode',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.fastReading,
                    arguments: FastReadingArguments(
                      bookId: widget.arguments.bookId,
                      filePath: widget.arguments.filePath,
                      initialChapter: _chapterIndex,
                    ),
                  );
                },
                icon: const Icon(Icons.bolt),
              ),
              IconButton(
                tooltip: 'Reading settings',
                onPressed: () => _showSettingsSheet(settings),
                icon: const Icon(Icons.text_fields),
              ),
            ],
          ),
          body: parsed == null
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollEndNotification>(
                  onNotification: (_) {
                    _saveProgress();
                    return false;
                  },
                  child: ZoomableReader(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        child: _buildTextContent(parsed, highlights, settings),
                      ),
                    ),
                  ),
                ),
          bottomNavigationBar: _ReadingControls(
            chapterIndex: _chapterIndex,
            chapterCount: book.chapters.length,
            onPrev: _chapterIndex == 0
                ? null
                : () {
                    setState(() {
                      _chapterIndex -= 1;
                      _parsedChapter = null;
                    });
                    _loadChapter(book.chapters[_chapterIndex].htmlContent);
                  },
            onNext: _chapterIndex == book.chapters.length - 1
                ? null
                : () {
                    setState(() {
                      _chapterIndex += 1;
                      _parsedChapter = null;
                    });
                    _loadChapter(book.chapters[_chapterIndex].htmlContent);
                  },
          ),
        );
      },
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Reading')),
        body: Center(child: Text('Failed to load EPUB: $error')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ReadingControls extends StatelessWidget {
  const _ReadingControls({
    required this.chapterIndex,
    required this.chapterCount,
    required this.onPrev,
    required this.onNext,
  });

  final int chapterIndex;
  final int chapterCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Chapter ${chapterIndex + 1} of $chapterCount'),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
