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

class MergePdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final AdmobService _admobService = Get.find<AdmobService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<PdfFileModel> selectedPdfs = <PdfFileModel>[].obs;
  final RxBool isMerging = false.obs;
  final RxString loadingMessage = ''.obs;

  final TextEditingController pdfNameController = TextEditingController();

  @override
  void onClose() {
    pdfNameController.dispose();
    super.onClose();
  }

  Future<void> pickPdfFiles() async {
    try {
      final context = Get.context;
      if (context == null) return;

      final results = await DevicePdfPickerSheet.show(
        context,
        isMultiSelect: true,
        initialSelectedPaths: selectedPdfs.map((p) => p.path).toList(),
      );

      if (results != null && results.isNotEmpty) {
        final currentPaths = selectedPdfs.map((p) => p.path).toSet();
        for (final file in results) {
          if (!currentPaths.contains(file.path)) {
            final count = await _pdfService.getPdfPageCount(file.path);
            selectedPdfs.add(PdfFileModel.fromPath(file.path, pageCount: count));
          }
        }
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to select PDFs: $e');
    }
  }

  void removePdfAt(int index) {
    if (index >= 0 && index < selectedPdfs.length) {
      selectedPdfs.removeAt(index);
    }
  }

  void clearAll() {
    selectedPdfs.clear();
  }

  void reorderPdfs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = selectedPdfs.removeAt(oldIndex);
    selectedPdfs.insert(newIndex, item);
  }

  Future<void> mergePdfs() async {
    if (selectedPdfs.length < 2) {
      SnackbarHelper.showError(AppStrings.selectAtLeastTwoPdfs.tr);
      return;
    }

    try {
      isMerging.value = true;
      loadingMessage.value = AppStrings.merging.tr;

      final mergedResult = await _pdfService.mergePdfs(
        pdfFiles: selectedPdfs.toList(),
        outputFileName: pdfNameController.text.trim().isNotEmpty
            ? pdfNameController.text.trim()
            : null,
      );

      // Save to recent files
      await _storageService.addRecentFile(mergedResult.path);

      isMerging.value = false;

      // Show Interstitial Ad before navigating to Result
      _admobService.showInterstitialAd(
        onComplete: () {
          Get.toNamed(
            AppRoutes.result,
            arguments: {
              'pdfFile': mergedResult,
              'operation': 'merge_pdf',
            },
          );
        },
      );
    } catch (e) {
      isMerging.value = false;
      SnackbarHelper.showError('Failed to merge PDFs: $e');
    }
  }
}
