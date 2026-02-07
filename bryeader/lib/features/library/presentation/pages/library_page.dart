import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/book_card.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: books.isEmpty
          ? _EmptyLibrary(onImport: () {
              ref.read(libraryProvider.notifier).importBook();
            })
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return BookCard(
                    book: book,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.reading,
                        arguments: ReadingArguments(
                          bookId: book.id,
                          filePath: book.filePath,
                          initialChapter: book.lastReadChapter,
                        ),
                      );
                    },
                    onDelete: () {
                      ref.read(libraryProvider.notifier).deleteBook(book);
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(libraryProvider.notifier).importBook(),
        icon: const Icon(Icons.add),
        label: const Text('Import EPUB'),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Theme.of(context).hintColor),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Import your first EPUB to start reading.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add),
              label: const Text('Import EPUB'),
            ),
          ],
        ),
      ),
    );
  }
}
