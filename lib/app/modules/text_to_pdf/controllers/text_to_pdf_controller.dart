import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../routes/app_routes.dart';

class TextToPdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AdmobService _admobService = Get.find<AdmobService>();

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final fontSize = 13.0.obs;
  final isGenerating = false.obs;

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  Future<void> generatePdf() async {
    final text = contentController.text.trim();
    final title = titleController.text.trim();

    if (text.isEmpty) {
      SnackbarHelper.showError('Please enter some text to convert');
      return;
    }

    try {
      isGenerating.value = true;

      final result = await _pdfService.generatePdfFromText(
        textContent: text,
        title: title,
        fontSize: fontSize.value,
      );

      await _storageService.saveRecentFile(result);
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': result,
          'title': AppStrings.textToPdf.tr,
          'message': AppStrings.successCreated.tr,
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Failed to generate PDF: $e');
    } finally {
      isGenerating.value = false;
    }
  }
}
