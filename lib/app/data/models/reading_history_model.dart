import 'dart:convert';

class PdfReadingHistoryModel {
  final String path;
  final String title;
  final int lastReadPage;
  final int totalPages;
  final DateTime lastReadTime;

  PdfReadingHistoryModel({
    required this.path,
    required this.title,
    required this.lastReadPage,
    required this.totalPages,
    required this.lastReadTime,
  });

  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    return (lastReadPage / totalPages).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'title': title,
      'lastReadPage': lastReadPage,
      'totalPages': totalPages,
      'lastReadTime': lastReadTime.toIso8601String(),
    };
  }

  factory PdfReadingHistoryModel.fromMap(Map<String, dynamic> map) {
    return PdfReadingHistoryModel(
      path: map['path'] as String? ?? '',
      title: map['title'] as String? ?? '',
      lastReadPage: map['lastReadPage'] as int? ?? 1,
      totalPages: map['totalPages'] as int? ?? 1,
      lastReadTime: map['lastReadTime'] != null
          ? DateTime.tryParse(map['lastReadTime'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PdfReadingHistoryModel.fromJson(String source) =>
      PdfReadingHistoryModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
