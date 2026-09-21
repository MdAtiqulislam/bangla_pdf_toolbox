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

class SplitPdfController extends GetxController {
  final _pdfService = Get.find<PdfService>();
  final _admobService = Get.find<AdmobService>();
  final _storage = Get.find<StorageService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final totalPages = 0.obs;
  final selectedPages = <int>{}.obs;
  final rangeController = TextEditingController();
  final pdfNameController = TextEditingController();
  final isSplitting = false.obs;
  final loadingMessage = ''.obs;

  @override
  void onClose() {
    rangeController.dispose();
    pdfNameController.dispose();
    super.onClose();
  }

  Future<void> pickPdfFile() async {
    try {
      final context = Get.context;
      if (context == null) return;

      final results = await DevicePdfPickerSheet.show(
        context,
        isMultiSelect: false,
      );

      if (results != null && results.isNotEmpty) {
        final pdf = results.first;
        final count = await _pdfService.getPdfPageCount(pdf.path);

        selectedPdf.value = PdfFileModel(
          id: pdf.id,
          path: pdf.path,
          fileName: pdf.fileName,
          sizeInBytes: pdf.sizeInBytes,
          modifiedDate: pdf.modifiedDate,
          pageCount: count,
        );

        totalPages.value = count;
        selectedPages.clear();
        rangeController.clear();
        pdfNameController.text = '${pdf.fileName.replaceAll('.pdf', '')}_split';
      }
    } catch (e) {
      SnackbarHelper.showError('Error selecting PDF: $e');
    }
  }

  void togglePage(int page) {
    if (selectedPages.contains(page)) {
      selectedPages.remove(page);
    } else {
      selectedPages.add(page);
    }
    _syncRangeText();
  }

  void selectAllPages() {
    selectedPages.clear();
    for (int i = 1; i <= totalPages.value; i++) {
      selectedPages.add(i);
    }
    _syncRangeText();
  }

  void deselectAllPages() {
    selectedPages.clear();
    rangeController.clear();
  }

  void applyRangeFromInput(String text) {
    if (text.trim().isEmpty) {
      selectedPages.clear();
      return;
    }

    final Set<int> parsed = {};
    final parts = text.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final rangeParts = trimmed.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0].trim());
          final end = int.tryParse(rangeParts[1].trim());
          if (start != null && end != null && start <= end) {
            for (int i = start; i <= end; i++) {
              if (i >= 1 && i <= totalPages.value) {
                parsed.add(i);
              }
            }
          }
        }
      } else {
        final single = int.tryParse(trimmed);
        if (single != null && single >= 1 && single <= totalPages.value) {
          parsed.add(single);
        }
      }
    }

    selectedPages.assignAll(parsed);
  }

  void _syncRangeText() {
    if (selectedPages.isEmpty) {
      rangeController.clear();
      return;
    }
    final sorted = selectedPages.toList()..sort();
    rangeController.text = sorted.join(', ');
  }

  Future<void> splitPdf() async {
    if (selectedPdf.value == null) {
      SnackbarHelper.showError(AppStrings.noFilesSelected.tr);
      return;
    }

    if (selectedPages.isEmpty) {
      SnackbarHelper.showError(AppStrings.selectAtLeastOnePage.tr);
      return;
    }

    try {
      isSplitting.value = true;
      loadingMessage.value = AppStrings.splitting.tr;

      final result = await _pdfService.splitPdf(
        pdfPath: selectedPdf.value!.path,
        pageNumbers: selectedPages.toList(),
        outputFileName: pdfNameController.text.trim(),
      );

      await _storage.saveRecentFile(result);

      isSplitting.value = false;
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': result,
          'operation': 'split_pdf',
        },
      );
    } catch (e) {
      isSplitting.value = false;
      SnackbarHelper.showError('${AppStrings.error.tr}: $e');
    }
  }

  void reset() {
    selectedPdf.value = null;
    totalPages.value = 0;
    selectedPages.clear();
    rangeController.clear();
    pdfNameController.clear();
  }
}
