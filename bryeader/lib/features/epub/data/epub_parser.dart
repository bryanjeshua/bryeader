import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:image/image.dart' as img;

class ParsedEpubBook {
  const ParsedEpubBook({
    required this.title,
    required this.author,
    required this.chapters,
    this.coverBytes,
  });

  final String title;
  final String author;
  final List<EpubChapterData> chapters;
  final Uint8List? coverBytes;
}

class EpubChapterData {
  const EpubChapterData({required this.title, required this.htmlContent});

  final String title;
  final String htmlContent;
}

class EpubParser {
  Future<ParsedEpubBook> parse(Uint8List bytes) async {
    final book = await EpubReader.readBook(bytes);
    final metadata = book.Schema?.Package?.Metadata;
    final title = metadata?.Titles?.firstOrNull ?? 'Untitled';
    final author = metadata?.Creators?.isNotEmpty == true
        ? metadata!.Creators!.first.toString().trim().isNotEmpty
            ? metadata.Creators!.first.toString()
            : 'Unknown Author'
        : 'Unknown Author';
    final coverImage = book.CoverImage;
    final chapters = <EpubChapterData>[];

    void addChapter(EpubChapter chapter) {
      if (chapter.HtmlContent?.trim().isNotEmpty == true) {
        chapters.add(
          EpubChapterData(
            title: chapter.Title?.trim().isNotEmpty == true
                ? chapter.Title!
                : 'Chapter ${chapters.length + 1}',
            htmlContent: chapter.HtmlContent!,
          ),
        );
      }
      if ((chapter.SubChapters ?? <EpubChapter>[]).isNotEmpty) {
        for (final sub in chapter.SubChapters ?? <EpubChapter>[]) {
          addChapter(sub);
        }
      }
    }

    for (final chapter in book.Chapters ?? <EpubChapter>[]) {
      addChapter(chapter);
    }

    Uint8List? coverBytes;
    if (coverImage != null) {
      coverBytes = Uint8List.fromList(img.encodePng(coverImage));
    }

    return ParsedEpubBook(
      title: title,
      author: author,
      coverBytes: coverBytes,
      chapters: chapters,
    );
  }
}
