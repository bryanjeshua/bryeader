import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../models/highlight.dart';
import '../models/reading_settings.dart';

class LocalStorage {
  static const _booksKey = 'books';
  static const _readingSettingsKey = 'reading_settings';
  static const _themeModeKey = 'theme_mode';

  Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_booksKey) ?? <String>[];
    return raw
        .map(
          (entry) => Book.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = books.map((book) => jsonEncode(book.toJson())).toList();
    await prefs.setStringList(_booksKey, raw);
  }

  Future<List<Highlight>> loadHighlights(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_highlightsKey(bookId)) ?? <String>[];
    return raw
        .map(
          (entry) =>
              Highlight.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveHighlights(String bookId, List<Highlight> highlights) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = highlights.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_highlightsKey(bookId), raw);
  }

  Future<ReadingSettings> loadReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readingSettingsKey);
    if (raw == null) {
      return const ReadingSettings();
    }
    return ReadingSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveReadingSettings(ReadingSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readingSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, value);
  }

  String _highlightsKey(String bookId) => 'highlights_$bookId';
}
