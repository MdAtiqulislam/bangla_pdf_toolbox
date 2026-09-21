import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../routes/app_routes.dart';

class SignaturePdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AdmobService _admobService = Get.find<AdmobService>();
  final ImagePicker _imagePicker = ImagePicker();

  final selectedPdf = Rxn<PdfFileModel>();
  final totalPages = 0.obs;
  final selectedPageIndex = 0.obs;
  final signatureBytes = Rxn<Uint8List>();
  final isSigning = false.obs;
  final isRendering = false.obs;
  final pageRasterImages = <Uint8List>[].obs;

  // Signature position & dimensions (relative normalized 0.0 to 1.0)
  final sigNormX = 0.35.obs;
  final sigNormY = 0.70.obs;
  final sigNormW = 0.35.obs;
  final sigNormH = 0.14.obs;

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
      SnackbarHelper.showError('Error selecting PDF: $e');
    }
  }

  Future<void> setPdf(PdfFileModel pdf) async {
    selectedPdf.value = pdf;
    selectedPageIndex.value = 0;
    await _loadPageRasters();
  }

  Future<void> _loadPageRasters() async {
    final pdf = selectedPdf.value;
    if (pdf == null) return;

    try {
      isRendering.value = true;
      pageRasterImages.clear();

      final bytes = await File(pdf.path).readAsBytes();
      await for (final page in Printing.raster(bytes, dpi: 100)) {
        final png = await page.toPng();
        pageRasterImages.add(png);
      }
      totalPages.value = pageRasterImages.length;
    } catch (e) {
      debugPrint('Error rasterizing pages: $e');
    } finally {
      isRendering.value = false;
    }
  }

  void setSignatureBytes(Uint8List bytes) {
    signatureBytes.value = bytes;
  }

  void removeSignature() {
    signatureBytes.value = null;
  }

  Future<void> importSignatureFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setSignatureBytes(bytes);
      }
    } catch (e) {
      SnackbarHelper.showError('Error picking signature image: $e');
    }
  }

  void updateSignaturePosition(double normX, double normY) {
    final maxX = (1.0 - sigNormW.value).clamp(0.0, 1.0);
    final maxY = (1.0 - sigNormH.value).clamp(0.0, 1.0);
    sigNormX.value = normX.clamp(0.0, maxX);
    sigNormY.value = normY.clamp(0.0, maxY);
  }

  void updateSignatureSize(double deltaW, double deltaH, double parentW, double parentH) {
    final newNormW = (sigNormW.value + (deltaW / parentW)).clamp(0.12, 0.85);
    final newNormH = (sigNormH.value + (deltaH / parentH)).clamp(0.05, 0.50);
    sigNormW.value = newNormW;
    sigNormH.value = newNormH;

    // Re-clamp position
    updateSignaturePosition(sigNormX.value, sigNormY.value);
  }

  void setScale(double scale) {
    final w = (0.35 * scale).clamp(0.12, 0.85);
    final h = (0.14 * scale).clamp(0.05, 0.50);
    sigNormW.value = w;
    sigNormH.value = h;
    updateSignaturePosition(sigNormX.value, sigNormY.value);
  }

  void changePage(int index) {
    if (index >= 0 && index < totalPages.value) {
      selectedPageIndex.value = index;
    }
  }

  Future<void> applySignatureAndSave() async {
    final pdf = selectedPdf.value;
    final sig = signatureBytes.value;

    if (pdf == null || sig == null) {
      SnackbarHelper.showError('Please draw or select a signature first');
      return;
    }

    try {
      isSigning.value = true;

      final signedPdf = await _pdfService.signPdf(
        inputPath: pdf.path,
        signaturePngBytes: sig,
        pageIndex: selectedPageIndex.value,
        normalizedX: sigNormX.value,
        normalizedY: sigNormY.value,
        normalizedWidth: sigNormW.value,
        normalizedHeight: sigNormH.value,
      );

      await _storageService.saveRecentFile(signedPdf);
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': signedPdf,
          'title': AppStrings.signaturePdf.tr,
          'operation': 'signature_pdf',
          'message': AppStrings.successCreated.tr,
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Signing failed: $e');
    } finally {
      isSigning.value = false;
    }
  }
}
