import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../routes/app_routes.dart';

class WatermarkPdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AdmobService _admobService = Get.find<AdmobService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final watermarkText = 'CONFIDENTIAL'.obs;
  final fontSize = 42.0.obs;
  final opacity = 0.30.obs;
  final angle = (-45.0).obs;
  final selectedColor = 0xFF718096.obs; // Grey
  final isProcessing = false.obs;
  final textController = TextEditingController(text: 'CONFIDENTIAL');

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      final path = Get.arguments['pdfPath'] as String?;
      final title = Get.arguments['title'] as String?;
      if (path != null && path.isNotEmpty) {
        selectedPdf.value = PdfFileModel(
          id: path,
          path: path,
          fileName: title ?? path.split('/').last,
          sizeInBytes: 0,
          modifiedDate: DateTime.now(),
        );
      }
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> pickPdfFile() async {
    try {
      final context = Get.context;
      if (context == null) return;

      final results = await DevicePdfPickerSheet.show(context, isMultiSelect: false);
      if (results != null && results.isNotEmpty) {
        selectedPdf.value = results.first;
      }
    } catch (e) {
      SnackbarHelper.showError('Error selecting file: $e');
    }
  }

  Future<void> applyWatermark() async {
    final pdf = selectedPdf.value;
    final text = textController.text.trim();
    if (pdf == null) {
      SnackbarHelper.showError(AppStrings.noFilesSelected.tr);
      return;
    }
    if (text.isEmpty) {
      SnackbarHelper.showError('Please enter watermark text');
      return;
    }

    try {
      isProcessing.value = true;

      final watermarked = await _pdfService.addWatermark(
        inputPath: pdf.path,
        watermarkText: text,
        fontSize: fontSize.value,
        opacity: opacity.value,
        angle: angle.value,
        colorValue: selectedColor.value,
      );

      await _storageService.saveRecentFile(watermarked);
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': watermarked,
          'title': AppStrings.watermarkPdf.tr,
          'message': AppStrings.successCreated.tr,
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Failed to apply watermark: $e');
    } finally {
      isProcessing.value = false;
    }
  }
}
