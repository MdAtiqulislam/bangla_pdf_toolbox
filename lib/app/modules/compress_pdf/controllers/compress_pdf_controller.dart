import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../routes/app_routes.dart';

enum CompressionLevel { extreme, recommended, low }

class CompressPdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AdmobService _admobService = Get.find<AdmobService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final selectedPreset = CompressionLevel.recommended.obs;
  final isCompressing = false.obs;

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

  void setPreset(CompressionLevel level) {
    selectedPreset.value = level;
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

  void clearSelection() {
    selectedPdf.value = null;
  }

  Future<void> compressPdf() async {
    final pdf = selectedPdf.value;
    if (pdf == null) {
      SnackbarHelper.showError(AppStrings.noFilesSelected.tr);
      return;
    }

    try {
      isCompressing.value = true;

      int quality = 65;
      int dpi = 115;

      switch (selectedPreset.value) {
        case CompressionLevel.extreme:
          quality = 40;
          dpi = 90;
          break;
        case CompressionLevel.recommended:
          quality = 65;
          dpi = 115;
          break;
        case CompressionLevel.low:
          quality = 85;
          dpi = 145;
          break;
      }

      final compressedModel = await _pdfService.compressPdf(
        inputPath: pdf.path,
        quality: quality,
        dpi: dpi,
      );

      await _storageService.saveRecentFile(compressedModel);
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': compressedModel,
          'title': AppStrings.compressPdf.tr,
          'message': AppStrings.successCreated.tr,
          'originalSize': pdf.sizeInBytes,
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Compression failed: $e');
    } finally {
      isCompressing.value = false;
    }
  }
}
