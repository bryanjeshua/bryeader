class ReadingSettings {
  const ReadingSettings({
    this.fontSize = 18,
    this.lineHeight = 1.6,
    this.wordsPerMinute = 260,
    this.wordsPerPhrase = 1,
  });

  final double fontSize;
  final double lineHeight;
  final int wordsPerMinute;
  final int wordsPerPhrase;

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    int? wordsPerMinute,
    int? wordsPerPhrase,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      wordsPerPhrase: wordsPerPhrase ?? this.wordsPerPhrase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'wordsPerMinute': wordsPerMinute,
      'wordsPerPhrase': wordsPerPhrase,
    };
  }

  factory ReadingSettings.fromJson(Map<String, dynamic> json) {
    return ReadingSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
      wordsPerMinute: (json['wordsPerMinute'] as num?)?.toInt() ?? 260,
      wordsPerPhrase: (json['wordsPerPhrase'] as num?)?.toInt() ?? 1,
    );
  }
}
