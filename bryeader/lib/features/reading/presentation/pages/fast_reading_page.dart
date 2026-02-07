import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../epub/data/chapter_content_parser.dart';
import '../../presentation/providers/reading_provider.dart';

class FastReadingPage extends ConsumerStatefulWidget {
  const FastReadingPage({super.key, required this.arguments});

  final FastReadingArguments arguments;

  @override
  ConsumerState<FastReadingPage> createState() => _FastReadingPageState();
}

class _FastReadingPageState extends ConsumerState<FastReadingPage> {
  Timer? _timer;
  int _chapterIndex = 0;
  int? _loadedChapterIndex;
  int _tokenIndex = 0;
  int _wordsPerMinute = 260;
  int _wordsPerPhrase = 1;
  bool _isPlaying = false;
  List<TokenRange> _tokens = const [];

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.arguments.initialChapter;
    final settings = ref.read(readingSettingsProvider);
    _wordsPerMinute = settings.wordsPerMinute;
    _wordsPerPhrase = settings.wordsPerPhrase;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadChapter(String htmlContent) {
    final parsed = ChapterContentParser.parse(htmlContent);
    setState(() {
      _tokens = parsed.tokens;
      _tokenIndex = min(_tokenIndex, max(0, _tokens.length - 1));
      _loadedChapterIndex = _chapterIndex;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    final effectiveWpm = max(1, _wordsPerMinute ~/ _wordsPerPhrase);
    final delayMs = (60.0 / effectiveWpm * 1000).round();

    _timer = Timer.periodic(Duration(milliseconds: delayMs), (_) {
      if (!_isPlaying) {
        return;
      }
      _step(1);
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _step(int direction) {
    if (_tokens.isEmpty) {
      return;
    }
    setState(() {
      _tokenIndex += direction * _wordsPerPhrase;
      _tokenIndex = _tokenIndex.clamp(0, _tokens.length);
    });
  }

  String _phraseAt(int start, int count) {
    if (_tokens.isEmpty) {
      return '';
    }
    final clampedStart = start.clamp(0, _tokens.length - 1);
    final end = min(clampedStart + count, _tokens.length);
    return _tokens.sublist(clampedStart, end).map((t) => t.text).join(' ');
  }

  Widget _contextText(String text) {
    return Opacity(
      opacity: 0.35,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredText(String text, double screenWidth, double screenHeight) {
    // Measure the text width to find its center
    const textStyle = TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.bold,
      height: 1.1,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;
    
    // Calculate position so text center (middle character) is at screen center
    // Horizontal: Position left edge at screenCenter - textCenter = screenWidth/2 - textWidth/2
    final leftPosition = (screenWidth / 2) - (textWidth / 2);
    // Vertical: Position top edge at screenCenter - textCenter = screenHeight/2 - textHeight/2
    final topPosition = (screenHeight / 2) - (textHeight / 2);
    
    return Positioned(
      left: leftPosition,
      top: topPosition,
      child: Text(
        text,
        style: textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final epubAsync = ref.watch(epubBookProvider(widget.arguments.filePath));

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

        if (_tokenIndex >= _tokens.length && _tokens.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            if (_chapterIndex < book.chapters.length - 1) {
              setState(() {
                _chapterIndex += 1;
                _tokenIndex = 0;
                _loadedChapterIndex = null;
              });
            } else {
              setState(() {
                _isPlaying = false;
              });
              _timer?.cancel();
            }
          });
        }

        final previous = _phraseAt(_tokenIndex - 2, 2);
        final current = _phraseAt(_tokenIndex, _wordsPerPhrase);
        final next = _phraseAt(_tokenIndex + _wordsPerPhrase, 2);

        return Scaffold(
          appBar: AppBar(
            title: Text(chapter.title),
            actions: [
              IconButton(
                tooltip: 'Reading settings',
                onPressed: () {
                  final current = ref.read(readingSettingsProvider);
                  ref.read(readingSettingsProvider.notifier).update(
                        current.copyWith(
                          wordsPerMinute: _wordsPerMinute,
                          wordsPerPhrase: _wordsPerPhrase,
                        ),
                      );
                },
                icon: const Icon(Icons.save),
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Fast Reading Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Context words on the sides
                          Positioned(
                            left: 24,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _contextText(previous),
                            ),
                          ),
                          // Centered text with its center character at screen center (both horizontal and vertical)
                          _buildCenteredText(
                            current,
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          // Context words on the right
                          Positioned(
                            right: 24,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _contextText(next),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _Controls(
                  isPlaying: _isPlaying,
                  wpm: _wordsPerMinute,
                  wordsPerPhrase: _wordsPerPhrase,
                  onPlayPause: _togglePlay,
                  onStepBack: () => _step(-1),
                  onStepForward: () => _step(1),
                  onWpmChanged: (value) {
                    setState(() => _wordsPerMinute = value);
                    if (_isPlaying) {
                      _startTimer();
                    }
                  },
                  onPhraseChanged: (value) {
                    setState(() => _wordsPerPhrase = value);
                    if (_isPlaying) {
                      _startTimer();
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Fast Reading')),
        body: Center(child: Text('Failed to load EPUB: $error')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.isPlaying,
    required this.wpm,
    required this.wordsPerPhrase,
    required this.onPlayPause,
    required this.onStepBack,
    required this.onStepForward,
    required this.onWpmChanged,
    required this.onPhraseChanged,
  });

  final bool isPlaying;
  final int wpm;
  final int wordsPerPhrase;
  final VoidCallback onPlayPause;
  final VoidCallback onStepBack;
  final VoidCallback onStepForward;
  final ValueChanged<int> onWpmChanged;
  final ValueChanged<int> onPhraseChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Step back',
              onPressed: onStepBack,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton(
              tooltip: isPlaying ? 'Pause' : 'Play',
              onPressed: onPlayPause,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: 'Step forward',
              onPressed: onStepForward,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Speed: $wpm WPM'),
        Slider(
          min: 100,
          max: 600,
          value: wpm.toDouble(),
          onChanged: (value) => onWpmChanged(value.round()),
        ),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: List.generate(4, (index) => wordsPerPhrase == index + 1),
          onPressed: (index) => onPhraseChanged(index + 1),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('1'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('2'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('3'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('4'),
            ),
          ],
        ),
      ],
    );
  }
}
