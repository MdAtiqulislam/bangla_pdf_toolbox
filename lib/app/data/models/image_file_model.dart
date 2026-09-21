import 'dart:io';
import 'dart:typed_data';
import '../../core/utils/image_filter_utils.dart';

class ImageFileModel {
  final String id;
  final String path;
  final String fileName;
  final int sizeInBytes;
  final DateTime modifiedDate;
  final DocFilterType filterType;
  final int rotationAngle;
  final Uint8List? processedBytes;

  ImageFileModel({
    required this.id,
    required this.path,
    required this.fileName,
    required this.sizeInBytes,
    required this.modifiedDate,
    this.filterType = DocFilterType.original,
    this.rotationAngle = 0,
    this.processedBytes,
  });

  File get file => File(path);

  bool get hasModifications => filterType != DocFilterType.original || (rotationAngle % 360 != 0);

  Future<Uint8List> getEffectiveBytes() async {
    if (processedBytes != null) {
      return processedBytes!;
    }
    final rawBytes = await file.readAsBytes();
    if (!hasModifications) {
      return rawBytes;
    }
    return await ImageFilterUtils.processImage(
      rawBytes,
      filter: filterType,
      angle: rotationAngle,
    );
  }

  ImageFileModel copyWith({
    String? id,
    String? path,
    String? fileName,
    int? sizeInBytes,
    DateTime? modifiedDate,
    DocFilterType? filterType,
    int? rotationAngle,
    Uint8List? processedBytes,
  }) {
    return ImageFileModel(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      filterType: filterType ?? this.filterType,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      processedBytes: processedBytes ?? this.processedBytes,
    );
  }

  factory ImageFileModel.fromPath(
    String path, {
    DocFilterType filterType = DocFilterType.original,
    int rotationAngle = 0,
    Uint8List? processedBytes,
  }) {
    final file = File(path);
    final fileName = path.split(Platform.pathSeparator).last;
    int size = 0;
    DateTime modified = DateTime.now();
    try {
      size = file.lengthSync();
      modified = file.lastModifiedSync();
    } catch (_) {}

    return ImageFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
      path: path,
      fileName: fileName,
      sizeInBytes: size,
      modifiedDate: modified,
      filterType: filterType,
      rotationAngle: rotationAngle,
      processedBytes: processedBytes,
    );
  }
}
