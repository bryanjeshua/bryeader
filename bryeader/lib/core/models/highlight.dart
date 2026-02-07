class Highlight {
  const Highlight({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.startOffset,
    required this.endOffset,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final int chapterIndex;
  final int startOffset;
  final int endOffset;
  final int colorValue;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterIndex: (json['chapterIndex'] as num).toInt(),
      startOffset: (json['startOffset'] as num).toInt(),
      endOffset: (json['endOffset'] as num).toInt(),
      colorValue: (json['colorValue'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
