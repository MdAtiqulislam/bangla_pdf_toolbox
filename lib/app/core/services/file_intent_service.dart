import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../modules/pdf_viewer/controllers/pdf_viewer_controller.dart';
import '../../routes/app_routes.dart';

class FileIntentService extends GetxService {
  static const MethodChannel _channel = MethodChannel('com.banglapdftools.bangla_pdf_toolbox/intent');
  
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  String? pendingPdfPath;
  String? pendingPdfTitle;

  bool get hasPendingPdf => pendingPdfPath != null && pendingPdfPath!.isNotEmpty;

  Future<FileIntentService> init() async {
    _appLinks = AppLinks();
    _setupMethodChannel();
    await _checkInitialNativePdf();
    _initDeepLinks();
    return this;
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPdfOpened') {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final path = data['path'] as String?;
        final title = data['title'] as String?;
        if (path != null && path.isNotEmpty) {
          debugPrint('FileIntentService: Received onPdfOpened via MethodChannel: $path ($title)');
          openPdf(path, title: title);
        }
      }
    });
  }

  Future<void> _checkInitialNativePdf() async {
    try {
      final initialData = await _channel.invokeMethod<Map>('getInitialPdf');
      if (initialData != null) {
        final data = Map<String, dynamic>.from(initialData);
        final path = data['path'] as String?;
        final title = data['title'] as String?;
        if (path != null && path.isNotEmpty) {
          debugPrint('FileIntentService: Got initial PDF from native: $path ($title)');
          pendingPdfPath = path;
          pendingPdfTitle = title;
        }
      }
    } catch (e) {
      debugPrint('FileIntentService: Error checking initial native PDF: $e');
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint('FileIntentService: Error getting initial deep link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleIncomingUri(uri),
      onError: (err) => debugPrint('FileIntentService: Error in uriLinkStream: $err'),
    );
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    try {
      debugPrint('FileIntentService: Handling incoming URI: $uri (scheme: ${uri.scheme})');
      String? resolvedPath;
      String? title;

      if (uri.scheme == 'file') {
        final filePath = uri.toFilePath();
        if (await File(filePath).exists()) {
          resolvedPath = filePath;
          title = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Document.pdf';
        }
      } else if (uri.scheme == 'content') {
        // Resolve content:// URI via Native ContentResolver
        final result = await _channel.invokeMethod<Map>('resolveContentUri', {'uri': uri.toString()});
        if (result != null) {
          final data = Map<String, dynamic>.from(result);
          resolvedPath = data['path'] as String?;
          title = data['title'] as String?;
        }
      }

      if (resolvedPath != null && resolvedPath.isNotEmpty) {
        openPdf(resolvedPath, title: title);
      }
    } catch (e) {
      debugPrint('FileIntentService: Error processing URI $uri: $e');
    }
  }

  void openPendingPdf() {
    if (pendingPdfPath != null) {
      final path = pendingPdfPath!;
      final title = pendingPdfTitle;
      pendingPdfPath = null;
      pendingPdfTitle = null;
      openPdf(path, title: title);
    }
  }

  void openPdf(String path, {String? title}) {
    if (Get.isRegistered<PdfViewerController>()) {
      final controller = Get.find<PdfViewerController>();
      controller.loadPdf(path, title: title);
      if (Get.currentRoute != AppRoutes.pdfViewer) {
        Get.toNamed(AppRoutes.pdfViewer);
      }
    } else {
      Get.toNamed(
        AppRoutes.pdfViewer,
        arguments: {
          'pdfPath': path,
          'title': title,
        },
      );
    }
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
