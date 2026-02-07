import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local_storage.dart';
import '../../../../core/models/book.dart';
import '../../../epub/data/epub_parser.dart';
import '../../../epub/data/epub_repository.dart';

final libraryProvider = StateNotifierProvider<LibraryNotifier, List<Book>>(
  (ref) => LibraryNotifier(LocalStorage(), EpubRepository(EpubParser())),
);

class LibraryNotifier extends StateNotifier<List<Book>> {
  LibraryNotifier(this._storage, this._repository) : super(const []) {
    _load();
  }

  final LocalStorage _storage;
  final EpubRepository _repository;

  Future<void> _load() async {
    state = await _storage.loadBooks();
  }

  Future<void> importBook() async {
    final book = await _repository.importEpub();
    if (book == null) {
      return;
    }
    state = [...state, book];
    await _storage.saveBooks(state);
  }

  Future<void> deleteBook(Book book) async {
    state = state.where((b) => b.id != book.id).toList();
    await _storage.saveBooks(state);
  }

  Future<void> updateProgress(
    String bookId,
    int chapterIndex,
    double offset,
  ) async {
    final next = state.map((book) {
      if (book.id != bookId) {
        return book;
      }
      return book.copyWith(
        lastReadChapter: chapterIndex,
        lastReadOffset: offset,
        lastReadAt: DateTime.now(),
      );
    }).toList();
    state = next;
    await _storage.saveBooks(state);
  }
}
