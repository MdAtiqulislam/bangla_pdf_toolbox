import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../routes/app_routes.dart';

class PageNumberPdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AdmobService _admobService = Get.find<AdmobService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final selectedFormat = 'page_1_of_n'.obs;
  final selectedPosition = 'bottom_center'.obs;
  final isProcessing = false.obs;

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

  Future<void> addPageNumbers() async {
    final pdf = selectedPdf.value;
    if (pdf == null) {
      SnackbarHelper.showError(AppStrings.noFilesSelected.tr);
      return;
    }

    try {
      isProcessing.value = true;

      final result = await _pdfService.addPageNumbers(
        inputPath: pdf.path,
        format: selectedFormat.value,
        position: selectedPosition.value,
      );

      await _storageService.saveRecentFile(result);
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': result,
          'title': AppStrings.pageNumberPdf.tr,
          'message': AppStrings.successCreated.tr,
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Failed to add page numbers: $e');
    } finally {
      isProcessing.value = false;
    }
  }
}
