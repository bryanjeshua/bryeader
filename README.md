# EPUB Reader with Fast Reading Mode

A production-ready Flutter mobile application featuring a modern EPUB reader with an innovative Fast Reading Mode inspired by RSVP (Rapid Serial Visual Presentation) reading techniques.

## Features

### Standard EPUB Reader
- **Import & Library Management**: Import EPUB files from local storage and manage your library
- **Book Library**: View all books with cover thumbnails, titles, authors, and last read position
- **Reading View**: 
  - Page navigation between chapters
  - Text selection and highlighting with multiple colors
  - Adjustable font size and line spacing
  - Light and dark mode support
  - Automatic reading progress saving

### Fast Reading Mode (Core Innovation)
- **RSVP-Style Reading**: Displays one word or phrase at the center of the screen
- **Visual Design**:
  - Current word/phrase is fully opaque and clear
  - Previous and next words are faded (30% opacity) and visually de-emphasized
  - Smooth transitions between words
- **Controls**:
  - Adjustable reading speed (100-600 words per minute)
  - Play/pause functionality
  - Step forward/backward by one word/phrase
  - Toggle between single-word mode and multi-word phrase mode (2-4 words)

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── models/                        # Data models
│   │   ├── book.dart
│   │   ├── highlight.dart
│   │   └── reading_settings.dart
│   ├── data/
│   │   └── local_storage.dart         # Persistence layer
│   ├── routing/
│   │   └── app_router.dart           # Navigation routing
│   └── theme/
│       ├── app_theme.dart            # Theme configuration
│       └── theme_provider.dart       # Theme state management
├── features/
│   ├── epub/
│   │   └── data/
│   │       ├── epub_parser.dart      # EPUB file parsing
│   │       ├── epub_repository.dart  # EPUB data access
│   │       └── chapter_content_parser.dart  # HTML to text conversion
│   ├── library/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── library_page.dart
│   │       ├── widgets/
│   │       │   └── book_card.dart
│   │       └── providers/
│   │           └── library_provider.dart
│   └── reading/
│       └── presentation/
│           ├── pages/
│           │   ├── reading_page.dart      # Standard reading view
│           │   └── fast_reading_page.dart # Fast Reading Mode
│           └── providers/
│               └── reading_provider.dart
```

## Fast Reading Mode - Technical Details

### Rendering Logic

The Fast Reading Mode uses a three-layer visual approach:

1. **Previous Words Layer**: Displays 1-3 words before the current position
   - Opacity: 30%
   - Smaller font size (24px)
   - Gray color for visual de-emphasis

2. **Current Word/Phrase Layer**: The focal point
   - Opacity: 100%
   - Large font size (48px)
   - Bold weight
   - Centered on screen

3. **Next Words Layer**: Displays 1-3 words after the current position
   - Opacity: 30%
   - Smaller font size (24px)
   - Gray color for visual de-emphasis

### Timing and Speed Control

The reading speed is controlled through a `Timer.periodic` that updates the current token index:

```dart
// Calculate delay based on WPM
final effectiveWPM = _wordsPerMinute ~/ wordsToShow;
final delayMs = (60.0 / effectiveWPM * 1000).round();
```

**Key Implementation Details**:
- For phrase mode (2-4 words), the effective WPM is divided by the number of words per phrase
- This ensures consistent timing regardless of phrase length
- The timer is dynamically restarted when speed changes during playback
- Smooth transitions are achieved through Flutter's reactive state management

### Token Extraction

Text is parsed from EPUB HTML content into individual tokens:

1. HTML content is parsed using the `html` package
2. Plain text is extracted from the DOM
3. Text is split on whitespace to create word tokens
4. Tokens are stored in a list for efficient sequential access

### State Management

The app uses **Riverpod** for state management:
- `booksProvider`: Manages the library of books
- `readingSettingsProvider`: Handles font size, line spacing, etc.
- `highlightsProvider`: Manages highlights per book
- `epubBookProvider`: Loads EPUB content

### Persistence

All data is persisted using `SharedPreferences`:
- Books metadata (title, author, cover path, file path, progress)
- Highlights (text, position, color, notes)
- Reading settings (font size, line spacing)
- Theme preference (light/dark mode)

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (3.0.0 or higher)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Usage

1. **Import a Book**: Tap the "+" button on the library screen and select an EPUB file
2. **Read Normally**: Tap a book to open the standard reading view
3. **Fast Reading Mode**: Tap the flash icon (⚡) in the reading view to switch to Fast Reading Mode
4. **Adjust Settings**: Use the settings icon to customize font size and line spacing

## Dependencies

- `flutter_riverpod`: State management
- `epubx`: EPUB file parsing
- `shared_preferences`: Local data persistence
- `path_provider`: File system access
- `file_picker`: EPUB file import
- `html`: HTML content parsing

## Architecture

The app follows **clean architecture** principles:
- **Data Layer**: EPUB parsing, file I/O, persistence
- **Domain Layer**: Business logic and models
- **Presentation Layer**: UI components and state management

## Performance Considerations

- EPUB parsing is done asynchronously to avoid blocking the UI
- Chapter content is loaded on-demand
- Token extraction is performed once per chapter and cached
- Fast Reading Mode uses efficient timer-based updates
- Smooth 60fps animations through Flutter's rendering engine

## Future Enhancements

Potential improvements:
- Cloud sync for books and progress
- Reading statistics and analytics
- Custom themes and fonts
- Bookmark system
- Search functionality
- Text-to-speech integration
- Reading goals and streaks

## License

This project is provided as-is for educational and development purposes.
