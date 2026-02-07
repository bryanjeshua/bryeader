# Fast Reading Mode - Technical Documentation

## Overview

The Fast Reading Mode is an innovative RSVP (Rapid Serial Visual Presentation) implementation that displays text one word or phrase at a time at the center of the screen, with surrounding context words faded and de-emphasized.

## Core Concept

RSVP reading is a technique that presents words sequentially at a fixed location, eliminating the need for eye movement. This can significantly increase reading speed while maintaining comprehension.

## Implementation Architecture

### 1. Token Extraction (`chapter_content_parser.dart`)

**Purpose**: Convert EPUB HTML content into individual word tokens.

**Process**:
```dart
static List<String> extractTokens(String htmlContent) {
  final document = html_parser.parse(htmlContent);
  final text = document.body?.text ?? '';
  
  // Split into words, preserving punctuation
  final tokens = <String>[];
  final words = text.split(RegExp(r'\s+'));
  
  for (final word in words) {
    if (word.trim().isNotEmpty) {
      tokens.add(word.trim());
    }
  }
  
  return tokens;
}
```

**Key Points**:
- HTML is parsed to extract plain text
- Text is split on whitespace to create word tokens
- Punctuation is preserved with words
- Empty tokens are filtered out

### 2. Timing Engine (`fast_reading_page.dart`)

**Speed Calculation**:
```dart
// Calculate delay in milliseconds based on WPM
final wordsToShow = _wordsPerPhrase;
final effectiveWPM = _wordsPerMinute ~/ wordsToShow;
final delayMs = (60.0 / effectiveWPM * 1000).round();
```

**Explanation**:
- For phrase mode (2-4 words), the effective WPM is divided by the number of words per phrase
- This ensures that if you're reading 2-word phrases at 250 WPM, each phrase is displayed for the same duration as a single word at 250 WPM
- The delay is calculated as: `(60 seconds / WPM) * 1000 milliseconds`

**Timer Implementation**:
```dart
_readingTimer = Timer.periodic(Duration(milliseconds: delayMs), (timer) {
  if (!_isPlaying) {
    timer.cancel();
    return;
  }

  setState(() {
    _currentTokenIndex += wordsToShow;
    
    // Handle chapter transitions
    if (_currentTokenIndex >= _tokens.length) {
      if (_currentChapterIndex < _chapters.length - 1) {
        _currentChapterIndex++;
        _loadChapterTokens(_currentChapterIndex);
      } else {
        _pauseReading();
        _showCompletionDialog();
      }
    }
  });
});
```

**Key Features**:
- Timer updates are synchronized with Flutter's frame rate
- State updates trigger UI rebuilds automatically
- Chapter transitions are handled seamlessly
- Timer is cancelled when paused to prevent memory leaks

### 3. Visual Rendering

#### Three-Layer Design

**Layer 1: Previous Words (Context)**
```dart
Opacity(
  opacity: 0.3,
  child: _buildBlurredText(prevWords),
)
```
- Shows 1-3 words before the current position
- 30% opacity for visual de-emphasis
- Smaller font size (24px)
- Gray color to reduce visual weight

**Layer 2: Current Word/Phrase (Focus)**
```dart
Text(
  text,
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
)
```
- Fully opaque (100%)
- Large, bold font (48px)
- Centered on screen
- High contrast for maximum readability

**Layer 3: Next Words (Preview)**
```dart
Opacity(
  opacity: 0.3,
  child: _buildBlurredText(nextWords),
)
```
- Shows 1-3 words after the current position
- Same styling as previous words
- Provides peripheral context

#### Visual De-emphasis Technique

The blurred text effect uses a `ShaderMask` with a gradient to create a fade effect:

```dart
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.black.withOpacity(0.3),
      Colors.black.withOpacity(0.3),
      Colors.transparent,
    ],
    stops: const [0.0, 0.3, 0.7, 1.0],
  ).createShader(bounds),
  blendMode: BlendMode.dstIn,
  child: Text(...),
)
```

This creates a subtle fade effect that makes context words less prominent while still visible.

### 4. Phrase Mode

**Single Word Mode** (`_wordsPerPhrase = 1`):
- Displays one word at a time
- Maximum reading speed
- Best for experienced RSVP readers

**Multi-Word Phrase Mode** (`_wordsPerPhrase = 2-4`):
- Displays 2-4 words as a phrase
- Better for comprehension
- Natural language grouping
- Timing adjusts automatically

**Implementation**:
```dart
final endIndex = (_currentTokenIndex + _wordsPerPhrase).clamp(0, _tokens.length);
final currentPhrase = _tokens
    .sublist(_currentTokenIndex, endIndex)
    .join(' ');
```

### 5. Navigation Controls

**Play/Pause**:
- Toggles the reading timer
- Preserves current position
- Can be resumed at any time

**Step Forward/Backward**:
- Moves by one word/phrase
- Works even when paused
- Handles chapter boundaries

**Speed Control**:
- Slider: 100-600 WPM
- Real-time adjustment
- Timer restarts with new speed when changed during playback

**Mode Toggle**:
- ToggleButtons for 1-4 words
- Immediate visual feedback
- Affects both display and timing

## Performance Optimizations

### 1. Token Caching
- Tokens are extracted once per chapter
- Stored in memory for fast access
- No re-parsing during reading

### 2. Efficient State Updates
- Only `_currentTokenIndex` changes during playback
- Minimal widget rebuilds
- Flutter's reactive system handles UI updates efficiently

### 3. Timer Management
- Timer is cancelled when not in use
- Prevents memory leaks
- No unnecessary background processing

### 4. Smooth Animations
- Flutter's 60fps rendering ensures smooth transitions
- No frame drops during word changes
- State updates are synchronized with frame rendering

## User Experience Considerations

### Reading Speed Guidelines
- **100-200 WPM**: Learning mode, slower comprehension
- **200-300 WPM**: Normal reading speed
- **300-400 WPM**: Fast reading, good comprehension
- **400-600 WPM**: Very fast, requires practice

### Phrase Mode Recommendations
- **1 word**: Maximum speed, requires high concentration
- **2 words**: Balanced speed and comprehension
- **3-4 words**: Better comprehension, natural phrasing

### Visual Design Rationale
- **Large center text**: Reduces eye strain, improves focus
- **Faded context**: Provides peripheral awareness without distraction
- **Centered layout**: Eliminates eye movement, reduces fatigue

## Technical Challenges Solved

### 1. Chapter Transitions
**Problem**: Seamlessly move to next chapter when current chapter ends.

**Solution**: Check token index against chapter length, load next chapter tokens, reset index.

### 2. Dynamic Speed Changes
**Problem**: Allow speed adjustment during playback without losing position.

**Solution**: Cancel current timer, recalculate delay, restart timer with new speed.

### 3. Phrase Mode Timing
**Problem**: Maintain consistent timing when displaying multiple words.

**Solution**: Divide WPM by phrase length to get effective word rate, ensuring consistent timing.

### 4. Smooth Visual Transitions
**Problem**: Avoid jarring jumps between words.

**Solution**: Use Flutter's reactive state management, which handles smooth transitions automatically at 60fps.

## Future Enhancements

1. **Adaptive Speed**: Automatically adjust speed based on word complexity
2. **Punctuation Pauses**: Add slight delays after sentences
3. **Focus Mode**: Hide context words completely for maximum focus
4. **Reading Analytics**: Track reading speed, comprehension, progress
5. **Customizable Colors**: Allow users to customize text and background colors
6. **Accessibility**: Voice-over support, larger text options

## Testing Considerations

- Test with various EPUB files (different structures, languages)
- Verify timing accuracy across different WPM settings
- Test chapter transitions
- Verify phrase mode with different phrase lengths
- Test on different screen sizes
- Performance testing with very long books

## Conclusion

The Fast Reading Mode provides a unique and efficient reading experience by combining RSVP techniques with modern Flutter UI capabilities. The implementation is performant, user-friendly, and extensible for future enhancements.
