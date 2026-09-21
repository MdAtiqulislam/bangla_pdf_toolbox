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

class LockPdfController extends GetxController {
  final _pdfService = Get.find<PdfService>();
  final _admobService = Get.find<AdmobService>();
  final _storage = Get.find<StorageService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final pdfNameController = TextEditingController();
  final isPasswordVisible = false.obs;
  final isLocking = false.obs;
  final loadingMessage = ''.obs;

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
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

        pdfNameController.text = '${pdf.fileName.replaceAll('.pdf', '')}_locked';
      }
    } catch (e) {
      SnackbarHelper.showError('Error selecting PDF: $e');
    }
  }

  Future<void> lockPdf() async {
    if (selectedPdf.value == null) {
      SnackbarHelper.showError(AppStrings.noFilesSelected.tr);
      return;
    }

    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty) {
      SnackbarHelper.showError(AppStrings.passwordRequired.tr);
      return;
    }

    if (password.length < 4) {
      SnackbarHelper.showError(AppStrings.passwordTooShort.tr);
      return;
    }

    if (password != confirmPassword) {
      SnackbarHelper.showError(AppStrings.passwordsDoNotMatch.tr);
      return;
    }

    try {
      isLocking.value = true;
      loadingMessage.value = AppStrings.locking.tr;

      final result = await _pdfService.lockPdf(
        pdfPath: selectedPdf.value!.path,
        password: password,
        outputFileName: pdfNameController.text.trim(),
      );

      await _storage.saveRecentFile(result);

      isLocking.value = false;
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': result,
          'operation': 'lock_pdf',
        },
      );
    } catch (e) {
      isLocking.value = false;
      SnackbarHelper.showError('${AppStrings.error.tr}: $e');
    }
  }

  void reset() {
    selectedPdf.value = null;
    passwordController.clear();
    confirmPasswordController.clear();
    pdfNameController.clear();
  }
}
