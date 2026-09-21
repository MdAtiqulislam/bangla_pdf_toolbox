import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static const String appFolderName = 'PDF Tool';

  /// Format bytes into human-readable string (KB, MB, GB)
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final value = bytes / pow(1024, i);
    return '${value.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format date time
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  /// Generate safe file name with timestamp
  static String generateTimestampFileName(String prefix, {String extension = 'pdf'}) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$timestamp.$extension';
  }

  /// Get app output directory for saving generated PDF files in "PDF Tool" folder
  static Future<Directory> getAppOutputDirectory() async {
    Directory directory;
    if (Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        final pdfToolDir = Directory('${publicDownload.path}/$appFolderName');
        if (!await pdfToolDir.exists()) {
          try {
            await pdfToolDir.create(recursive: true);
            return pdfToolDir;
          } catch (_) {}
        } else {
          return pdfToolDir;
        }
      }

      final rootPdfTool = Directory('/storage/emulated/0/$appFolderName');
      if (!await rootPdfTool.exists()) {
        try {
          await rootPdfTool.create(recursive: true);
          return rootPdfTool;
        } catch (_) {}
      } else {
        return rootPdfTool;
      }

      final extDir = await getExternalStorageDirectory();
      directory = extDir ?? await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final pdfFolder = Directory('${directory.path}/$appFolderName');
    if (!await pdfFolder.exists()) {
      await pdfFolder.create(recursive: true);
    }
    return pdfFolder;
  }

  /// Get temporary directory for processing
  static Future<Directory> getTempProcessingDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final processFolder = Directory('${tempDir.path}/pdf_process_${DateTime.now().millisecondsSinceEpoch}');
    if (!await processFolder.exists()) {
      await processFolder.create(recursive: true);
    }
    return processFolder;
  }

  /// Save / Export a file to device public Downloads/PDF Tool folder
  static Future<File> saveToPublicDownloads(File sourceFile, {String? customFileName}) async {
    final fileName = customFileName ?? sourceFile.uri.pathSegments.last;
    Directory? targetDir;

    if (Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download/$appFolderName');
      if (!await publicDownload.exists()) {
        try {
          await publicDownload.create(recursive: true);
        } catch (_) {}
      }

      if (await publicDownload.exists()) {
        targetDir = publicDownload;
      } else {
        final baseDl = Directory('/storage/emulated/0/Download');
        if (await baseDl.exists()) {
          targetDir = baseDl;
        } else {
          final extDir = await getExternalStorageDirectory();
          targetDir = extDir ?? await getApplicationDocumentsDirectory();
        }
      }
    } else {
      final baseDl = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final pdfToolDir = Directory('${baseDl.path}/$appFolderName');
      if (!await pdfToolDir.exists()) {
        try {
          await pdfToolDir.create(recursive: true);
          targetDir = pdfToolDir;
        } catch (_) {
          targetDir = baseDl;
        }
      } else {
        targetDir = pdfToolDir;
      }
    }

    final targetFile = File('${targetDir.path}/$fileName');
    return await sourceFile.copy(targetFile.path);
  }
}
