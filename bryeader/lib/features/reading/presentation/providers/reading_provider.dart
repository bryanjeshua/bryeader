import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local_storage.dart';
import '../../../../core/models/highlight.dart';
import '../../../../core/models/reading_settings.dart';
import '../../../epub/data/epub_parser.dart';
import '../../../epub/data/epub_repository.dart';

final _storageProvider = Provider<LocalStorage>((ref) => LocalStorage());
final _epubRepositoryProvider = Provider<EpubRepository>(
  (ref) => EpubRepository(EpubParser()),
);

final epubBookProvider = FutureProvider.family<ParsedEpubBook, String>(
  (ref, filePath) => ref.read(_epubRepositoryProvider).loadEpub(filePath),
);

final readingSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>(
  (ref) => ReadingSettingsNotifier(ref.read(_storageProvider)),
);

class ReadingSettingsNotifier extends StateNotifier<ReadingSettings> {
  ReadingSettingsNotifier(this._storage) : super(const ReadingSettings()) {
    _load();
  }

  final LocalStorage _storage;

  Future<void> _load() async {
    state = await _storage.loadReadingSettings();
  }

  Future<void> update(ReadingSettings settings) async {
    state = settings;
    await _storage.saveReadingSettings(settings);
  }
}

final highlightsProvider =
    StateNotifierProvider.family<HighlightsNotifier, List<Highlight>, String>(
  (ref, bookId) => HighlightsNotifier(ref.read(_storageProvider), bookId),
);

class HighlightsNotifier extends StateNotifier<List<Highlight>> {
  HighlightsNotifier(this._storage, this._bookId) : super(const []) {
    _load();
  }

  final LocalStorage _storage;
  final String _bookId;

  Future<void> _load() async {
    state = await _storage.loadHighlights(_bookId);
  }

  Future<void> add(Highlight highlight) async {
    state = [...state, highlight];
    await _storage.saveHighlights(_bookId, state);
  }

  Future<void> remove(String highlightId) async {
    state = state.where((h) => h.id != highlightId).toList();
    await _storage.saveHighlights(_bookId, state);
  }
}
