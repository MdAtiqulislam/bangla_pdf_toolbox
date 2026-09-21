import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';

class ExtractTextPdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final extractedText = ''.obs;
  final isExtracting = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      final path = Get.arguments['pdfPath'] as String?;
      final title = Get.arguments['title'] as String?;
      if (path != null && path.isNotEmpty) {
        setPdf(PdfFileModel(
          id: path,
          path: path,
          fileName: title ?? path.split('/').last,
          sizeInBytes: 0,
          modifiedDate: DateTime.now(),
        ));
      }
    }
  }

  Future<void> pickPdfFile() async {
    try {
      final context = Get.context;
      if (context == null) return;

      final results = await DevicePdfPickerSheet.show(context, isMultiSelect: false);
      if (results != null && results.isNotEmpty) {
        setPdf(results.first);
      }
    } catch (e) {
      SnackbarHelper.showError('Error selecting file: $e');
    }
  }

  Future<void> setPdf(PdfFileModel pdf) async {
    selectedPdf.value = pdf;
    extractedText.value = '';
    await extractText();
  }

  Future<void> extractText() async {
    final pdf = selectedPdf.value;
    if (pdf == null) return;

    try {
      isExtracting.value = true;
      final text = await _pdfService.extractTextFromPdf(pdf.path);
      extractedText.value = text.trim();
    } catch (e) {
      SnackbarHelper.showError('Failed to extract text: $e');
    } finally {
      isExtracting.value = false;
    }
  }

  void copyToClipboard() {
    if (extractedText.value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: extractedText.value));
      SnackbarHelper.showSuccess(AppStrings.copiedToClipboard.tr);
    }
  }

  Future<void> saveAsTxtFile() async {
    if (extractedText.value.isEmpty) return;

    try {
      final outputDir = await FileUtils.getAppOutputDirectory();
      final name = '${selectedPdf.value?.fileName.replaceAll('.pdf', '') ?? 'Document'}_extracted.txt';
      final file = File('${outputDir.path}/$name');
      await file.writeAsString(extractedText.value);

      SnackbarHelper.showSuccess('Saved to ${file.path}');
      Share.shareXFiles([XFile(file.path)], text: 'Extracted text from PDF');
    } catch (e) {
      SnackbarHelper.showError('Error saving file: $e');
    }
  }
}
