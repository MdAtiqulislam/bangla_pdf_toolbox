import 'dart:io';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../routes/app_routes.dart';

class ResultController extends GetxController {
  late PdfFileModel pdfFile;
  late String operation;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      final model = (args['pdfFile'] ?? args['resultPdf'] ?? args['file']) as PdfFileModel?;
      if (model != null) {
        int actualSize = model.sizeInBytes;
        if (actualSize <= 0 && model.path.isNotEmpty) {
          try {
            final f = File(model.path);
            if (f.existsSync()) {
              actualSize = f.lengthSync();
            }
          } catch (_) {}
        }
        pdfFile = PdfFileModel(
          id: model.id,
          path: model.path,
          fileName: model.fileName,
          sizeInBytes: actualSize,
          pageCount: model.pageCount,
          modifiedDate: model.modifiedDate,
          
        );
        operation = args['operation'] as String? ?? args['title'] as String? ?? 'pdf';
      } else {
        _setFallback();
      }
    } else {
      _setFallback();
    }
  }

  void _setFallback() {
    pdfFile = PdfFileModel(
      id: 'unknown',
      path: '',
      fileName: 'Document.pdf',
      sizeInBytes: 0,
      modifiedDate: DateTime.now(),
    );
    operation = 'pdf';
  }

  String get successMessage {
    if (operation == 'merge_pdf') {
      return AppStrings.successMerged.tr;
    } else if (operation == 'split_pdf') {
      return AppStrings.successSplit.tr;
    } else if (operation == 'lock_pdf') {
      return AppStrings.successLocked.tr;
    }
    return AppStrings.successCreated.tr;
  }

  void openInAppReader() {
    if (pdfFile.path.isEmpty) return;
    Get.toNamed(AppRoutes.pdfViewer, arguments: {
      'pdfPath': pdfFile.path,
      'title': pdfFile.fileName,
    });
  }

  Future<void> saveToDownloads() async {
    if (pdfFile.path.isEmpty) return;
    try {
      final file = File(pdfFile.path);
      if (!await file.exists()) return;
      final savedFile = await FileUtils.saveToPublicDownloads(file);
      SnackbarHelper.showSuccess('${AppStrings.savedToDownloads.tr}\n${savedFile.path}');
    } catch (e) {
      SnackbarHelper.showError('Error saving file: $e');
    }
  }

  Future<void> openPdf() async {
    if (pdfFile.path.isEmpty) return;
    try {
      final result = await OpenFilex.open(pdfFile.path);
      if (result.type != ResultType.done) {
        openInAppReader();
      }
    } catch (e) {
      openInAppReader();
    }
  }

  Future<void> sharePdf() async {
    if (pdfFile.path.isEmpty) return;
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Sharing ${pdfFile.fileName} generated with Bangla PDF ToolBox',
      );
    } catch (e) {
      SnackbarHelper.showError('Error sharing PDF: $e');
    }
  }

  Future<void> printPdf() async {
    if (pdfFile.path.isEmpty) return;
    try {
      final file = File(pdfFile.path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: pdfFile.fileName,
        );
      }
    } catch (e) {
      SnackbarHelper.showError('Error printing PDF: $e');
    }
  }

  void goHome() {
    Get.offAllNamed(AppRoutes.home);
  }
}
