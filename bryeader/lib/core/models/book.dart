class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverPath,
    this.lastReadChapter = 0,
    this.lastReadOffset = 0.0,
    this.lastReadAt,
  });

  final String id;
  final String title;
  final String author;
  final String filePath;
  final String? coverPath;
  final int lastReadChapter;
  final double lastReadOffset;
  final DateTime? lastReadAt;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    int? lastReadChapter,
    double? lastReadOffset,
    DateTime? lastReadAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      lastReadChapter: lastReadChapter ?? this.lastReadChapter,
      lastReadOffset: lastReadOffset ?? this.lastReadOffset,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'coverPath': coverPath,
      'lastReadChapter': lastReadChapter,
      'lastReadOffset': lastReadOffset,
      'lastReadAt': lastReadAt?.toIso8601String(),
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: (json['author'] as String?)?.trim().isNotEmpty == true
          ? json['author'] as String
          : 'Unknown Author',
      filePath: json['filePath'] as String,
      coverPath: json['coverPath'] as String?,
      lastReadChapter: (json['lastReadChapter'] as num?)?.toInt() ?? 0,
      lastReadOffset: (json['lastReadOffset'] as num?)?.toDouble() ?? 0.0,
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
    );
  }
}
