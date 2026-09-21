import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';

class PdfToImageController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final AdmobService _admobService = Get.find<AdmobService>();

  final Rx<PdfFileModel?> selectedPdf = Rx<PdfFileModel?>(null);
  final RxList<String> extractedImages = <String>[].obs;
  final RxBool isConverting = false.obs;
  final RxString loadingMessage = ''.obs;

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
        final pageCount = await _pdfService.getPdfPageCount(pdf.path);
        selectedPdf.value = PdfFileModel(
          id: pdf.id,
          path: pdf.path,
          fileName: pdf.fileName,
          sizeInBytes: pdf.sizeInBytes,
          modifiedDate: pdf.modifiedDate,
          pageCount: pageCount,
        );
        extractedImages.clear();
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to select PDF: $e');
    }
  }

  Future<void> convertToImages() async {
    if (selectedPdf.value == null) {
      SnackbarHelper.showError(AppStrings.noFilesSelected.tr);
      return;
    }

    try {
      isConverting.value = true;
      loadingMessage.value = AppStrings.converting.tr;

      final images = await _pdfService.convertPdfToImages(
        pdfPath: selectedPdf.value!.path,
      );

      extractedImages.assignAll(images);
      isConverting.value = false;

      SnackbarHelper.showSuccess(
        '${images.length} ${Get.locale?.languageCode == 'bn' ? 'টি পেজ ছবিতে রূপান্তর হয়েছে' : 'pages converted to images'}',
      );

      // Trigger Interstitial Ad
      _admobService.showInterstitialAd(onComplete: () {});
    } catch (e) {
      isConverting.value = false;
      SnackbarHelper.showError('Failed to convert PDF to images: $e');
    }
  }

  Future<void> shareSingleImage(String imagePath) async {
    try {
      await Share.shareXFiles([XFile(imagePath)], text: 'Extracted PDF Page');
    } catch (e) {
      SnackbarHelper.showError('Failed to share image: $e');
    }
  }

  Future<void> shareAllImages() async {
    if (extractedImages.isEmpty) return;
    try {
      final xFiles = extractedImages.map((p) => XFile(p)).toList();
      await Share.shareXFiles(xFiles, text: 'Extracted Pages from ${selectedPdf.value?.fileName ?? "PDF"}');
    } catch (e) {
      SnackbarHelper.showError('Failed to share images: $e');
    }
  }

  void reset() {
    selectedPdf.value = null;
    extractedImages.clear();
  }
}
