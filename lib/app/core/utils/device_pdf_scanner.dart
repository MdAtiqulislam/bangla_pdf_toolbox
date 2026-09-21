import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/pdf_file_model.dart';
import 'file_utils.dart';

class DevicePdfScanner {
  static const MethodChannel _channel = MethodChannel('com.banglapdftools.bangla_pdf_toolbox/intent');

  /// Scan ALL device directories and MediaStore for every PDF document on the phone
  static Future<List<PdfFileModel>> scanAllPdfs({List<String>? extraPaths}) async {
    final Map<String, PdfFileModel> foundPdfMap = <String, PdfFileModel>{};

    // 1. Native MediaStore Query (Retrieves 100% of system-indexed PDFs instantly)
    try {
      if (Platform.isAndroid) {
        final List<dynamic>? nativeList = await _channel.invokeMethod<List<dynamic>>('queryAllPdfs');
        if (nativeList != null) {
          for (final item in nativeList) {
            final map = Map<String, dynamic>.from(item as Map);
            final path = map['path'] as String? ?? '';
            final fileName = map['fileName'] as String? ?? 'Document.pdf';
            final size = (map['sizeInBytes'] as num?)?.toInt() ?? 0;
            final modMs = (map['modifiedDate'] as num?)?.toInt() ?? 0;

            if (path.isNotEmpty && size >= 100) {
              foundPdfMap[path] = PdfFileModel(
                id: map['id'] as String? ?? '${modMs}_$fileName',
                path: path,
                fileName: fileName,
                sizeInBytes: size,
                modifiedDate: modMs > 0
                    ? DateTime.fromMillisecondsSinceEpoch(modMs)
                    : DateTime.now(),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DevicePdfScanner: MediaStore query error: $e');
    }

    // 2. Extra / Recent Paths
    if (extraPaths != null) {
      for (final p in extraPaths) {
        if (p.toLowerCase().endsWith('.pdf') && !foundPdfMap.containsKey(p)) {
          await _addFileIfValid(File(p), foundPdfMap);
        }
      }
    }

    // 3. Deep Recursive Storage Crawl (Catches un-indexed, nested, and newly created PDFs)
    final List<Directory> rootSearchDirs = [];

    try {
      final appOut = await FileUtils.getAppOutputDirectory();
      rootSearchDirs.add(appOut);
    } catch (_) {}

    try {
      final appDocs = await getApplicationDocumentsDirectory();
      rootSearchDirs.add(appDocs);
    } catch (_) {}

    if (Platform.isAndroid) {
      // Primary Internal Storage
      final primaryStorage = Directory('/storage/emulated/0');
      if (await primaryStorage.exists()) {
        rootSearchDirs.add(primaryStorage);
      }

      // SD Cards and secondary storage mounts
      try {
        final storageRoot = Directory('/storage');
        if (await storageRoot.exists()) {
          final mounts = await storageRoot.list(followLinks: false).toList();
          for (final mount in mounts) {
            if (mount is Directory && mount.path != '/storage/emulated' && mount.path != '/storage/self') {
              rootSearchDirs.add(mount);
            }
          }
        }
      } catch (_) {}

      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null && await extDir.exists()) {
          rootSearchDirs.add(extDir);
        }
      } catch (_) {}
    } else {
      try {
        final dlDir = await getDownloadsDirectory();
        if (dlDir != null && await dlDir.exists()) {
          rootSearchDirs.add(dlDir);
        }
      } catch (_) {}
    }

    // Scan directories up to depth 6
    for (final dir in rootSearchDirs) {
      await _scanDirectory(dir, foundPdfMap, maxDepth: 6, currentDepth: 0);
    }

    final results = foundPdfMap.values.toList();
    // Sort newest first
    results.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));

    return results;
  }

  static Future<void> _scanDirectory(
    Directory dir,
    Map<String, PdfFileModel> map, {
    required int maxDepth,
    required int currentDepth,
  }) async {
    if (currentDepth > maxDepth) return;

    try {
      final List<FileSystemEntity> entities = await dir.list(followLinks: false).toList();

      for (final entity in entities) {
        final path = entity.path;
        final name = entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.where((s) => s.isNotEmpty).last
            : '';

        // Skip hidden files, system Android data/obb which are locked, and cache folders
        if (name.startsWith('.') ||
            name == 'cache' ||
            name == 'Android' ||
            name == '.android_secure' ||
            name == 'thumbnails') {
          continue;
        }

        if (entity is File) {
          if (path.toLowerCase().endsWith('.pdf') && !map.containsKey(path)) {
            await _addFileIfValid(entity, map);
          }
        } else if (entity is Directory && currentDepth < maxDepth) {
          await _scanDirectory(
            entity,
            map,
            maxDepth: maxDepth,
            currentDepth: currentDepth + 1,
          );
        }
      }
    } catch (_) {
      // Ignore permission or inaccessible folders
    }
  }

  static Future<void> _addFileIfValid(File file, Map<String, PdfFileModel> map) async {
    try {
      if (await file.exists()) {
        final stat = await file.stat();
        if (stat.size >= 100) {
          final fileName = file.uri.pathSegments.where((s) => s.isNotEmpty).last;
          map[file.path] = PdfFileModel(
            id: '${stat.modified.millisecondsSinceEpoch}_$fileName',
            path: file.path,
            fileName: fileName,
            sizeInBytes: stat.size,
            modifiedDate: stat.modified,
          );
        }
      }
    } catch (_) {}
  }
}
