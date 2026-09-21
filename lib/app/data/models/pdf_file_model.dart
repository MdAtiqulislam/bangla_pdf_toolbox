import 'dart:io';

class PdfFileModel {
  final String id;
  final String path;
  final String fileName;
  final int sizeInBytes;
  final int pageCount;
  final DateTime modifiedDate;

  PdfFileModel({
    required this.id,
    required this.path,
    required this.fileName,
    required this.sizeInBytes,
    this.pageCount = 0,
    required this.modifiedDate,
  });

  File get file => File(path);

  factory PdfFileModel.fromPath(String path, {int pageCount = 0}) {
    final file = File(path);
    final fileName = path.split(Platform.pathSeparator).last;
    int size = 0;
    DateTime modified = DateTime.now();
    try {
      size = file.lengthSync();
      modified = file.lastModifiedSync();
    } catch (_) {}

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
      path: path,
      fileName: fileName,
      sizeInBytes: size,
      pageCount: pageCount,
      modifiedDate: modified,
    );
  }

  PdfFileModel copyWith({
    String? id,
    String? path,
    String? fileName,
    int? sizeInBytes,
    int? pageCount,
    DateTime? modifiedDate,
  }) {
    return PdfFileModel(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      pageCount: pageCount ?? this.pageCount,
      modifiedDate: modifiedDate ?? this.modifiedDate,
    );
  }
}
