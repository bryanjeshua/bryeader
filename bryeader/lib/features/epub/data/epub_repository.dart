import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/book.dart';
import 'epub_parser.dart';

class EpubRepository {
  EpubRepository(this._parser);

  final EpubParser _parser;

  Future<Book?> importEpub() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['epub'],
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final platformFile = result.files.single;
    Uint8List bytes;
    String filename;

    if (kIsWeb) {
      // On web, use bytes directly
      if (platformFile.bytes == null || platformFile.bytes!.isEmpty) {
        return null;
      }
      bytes = platformFile.bytes!;
      filename = platformFile.name;
    } else {
      // On other platforms, use path
      if (platformFile.path == null) {
        return null;
      }
      final sourcePath = platformFile.path!;
      bytes = await File(sourcePath).readAsBytes();
      filename = p.basename(sourcePath);
    }

    final parsed = await _parser.parse(bytes);
    final bookId = DateTime.now().millisecondsSinceEpoch.toString();

    String? filePath;
    String? coverPath;

    if (kIsWeb) {
      // On web, store bytes in SharedPreferences as base64
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('book_$bookId', base64Encode(bytes));
      filePath = 'book_$bookId'; // Use book ID as identifier

      if (parsed.coverBytes != null && parsed.coverBytes!.isNotEmpty) {
        await prefs.setString('cover_$bookId', base64Encode(parsed.coverBytes!));
        coverPath = 'cover_$bookId';
      }
    } else {
      // On other platforms, use file system
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(p.join(appDir.path, 'books'));
      if (!booksDir.existsSync()) {
        booksDir.createSync(recursive: true);
      }

      final destPath = p.join(booksDir.path, filename);
      await File(destPath).writeAsBytes(bytes, flush: true);
      filePath = destPath;

      if (parsed.coverBytes != null && parsed.coverBytes!.isNotEmpty) {
        final coverFile = File(
          p.join(booksDir.path, '${filename}_cover.png'),
        );
        await coverFile.writeAsBytes(parsed.coverBytes!, flush: true);
        coverPath = coverFile.path;
      }
    }

    return Book(
      id: bookId,
      title: parsed.title,
      author: parsed.author,
      filePath: filePath,
      coverPath: coverPath,
    );
  }

  Future<ParsedEpubBook> loadEpub(String filePath) async {
    Uint8List bytes;
    
    if (kIsWeb) {
      // On web, load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final base64String = prefs.getString(filePath);
      if (base64String == null) {
        throw Exception('Book not found: $filePath');
      }
      bytes = base64Decode(base64String);
    } else {
      // On other platforms, load from file system
      bytes = await File(filePath).readAsBytes();
    }
    
    return _parser.parse(bytes);
  }
}
