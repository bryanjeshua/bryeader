import 'package:flutter/material.dart';

import '../../features/library/presentation/pages/library_page.dart';
import '../../features/reading/presentation/pages/fast_reading_page.dart';
import '../../features/reading/presentation/pages/reading_page.dart';

class AppRouter {
  static const library = '/';
  static const reading = '/reading';
  static const fastReading = '/fast-reading';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case library:
        return MaterialPageRoute(builder: (_) => const LibraryPage());
      case reading:
        final args = settings.arguments as ReadingArguments;
        return MaterialPageRoute(builder: (_) => ReadingPage(arguments: args));
      case fastReading:
        final args = settings.arguments as FastReadingArguments;
        return MaterialPageRoute(
          builder: (_) => FastReadingPage(arguments: args),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LibraryPage());
    }
  }
}

class ReadingArguments {
  const ReadingArguments({
    required this.bookId,
    required this.filePath,
    this.initialChapter = 0,
  });

  final String bookId;
  final String filePath;
  final int initialChapter;
}

class FastReadingArguments {
  const FastReadingArguments({
    required this.bookId,
    required this.filePath,
    this.initialChapter = 0,
  });

  final String bookId;
  final String filePath;
  final int initialChapter;
}
