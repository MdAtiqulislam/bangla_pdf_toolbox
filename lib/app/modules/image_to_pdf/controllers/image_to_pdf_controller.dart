import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/image_filter_utils.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/image_file_model.dart';
import '../../../routes/app_routes.dart';

class ImageToPdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final AdmobService _admobService = Get.find<AdmobService>();
  final StorageService _storageService = Get.find<StorageService>();
  final ImagePicker _picker = ImagePicker();

  final RxList<ImageFileModel> selectedImages = <ImageFileModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString loadingMessage = ''.obs;

  // Settings
  final RxBool isLandscape = false.obs;
  final RxDouble margin = AppConstants.marginNone.obs;
  final RxInt quality = AppConstants.qualityMedium.obs;
  final Rx<PdfPageFormat> pageFormat = PdfPageFormat.a4.obs;
  final Rx<DocFilterType> defaultFilter = DocFilterType.original.obs;

  final TextEditingController pdfNameController = TextEditingController();

  @override
  void onClose() {
    pdfNameController.dispose();
    super.onClose();
  }

  Future<void> pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (final xFile in images) {
          selectedImages.add(
            ImageFileModel.fromPath(
              xFile.path,
              filterType: defaultFilter.value,
            ),
          );
        }
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to pick images: $e');
    }
  }

  Future<void> pickFromCamera() async {
    try {
      // 1. Try ML Kit / VisionKit Smart Document Scanner with Auto Edge-Detection & Auto-Crop
      final List<String>? pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 50,
      );

      if (pictures != null && pictures.isNotEmpty) {
        for (final path in pictures) {
          selectedImages.add(
            ImageFileModel.fromPath(
              path,
              filterType: defaultFilter.value,
            ),
          );
        }
        return;
      }
    } catch (_) {
      // Fallback to standard camera if device lacks Google Play Services ML Kit
      try {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          selectedImages.add(
            ImageFileModel.fromPath(
              photo.path,
              filterType: defaultFilter.value,
            ),
          );
        }
      } catch (err) {
        SnackbarHelper.showError('Failed to capture photo: $err');
      }
    }
  }

  void updateImageAt(int index, ImageFileModel updated) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages[index] = updated;
    }
  }

  void applyFilterToAll(DocFilterType filter) {
    defaultFilter.value = filter;
    final updatedList = selectedImages.map((img) {
      return img.copyWith(
        filterType: filter,
        processedBytes: null, // clear cache to reprocess
      );
    }).toList();
    selectedImages.assignAll(updatedList);
    SnackbarHelper.showSuccess(AppStrings.filterApplied.tr);
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  void clearAll() {
    selectedImages.clear();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = selectedImages.removeAt(oldIndex);
    selectedImages.insert(newIndex, item);
  }

  Future<void> generatePdf() async {
    if (selectedImages.isEmpty) {
      SnackbarHelper.showError(AppStrings.noImagesSelected.tr);
      return;
    }

    try {
      isLoading.value = true;
      loadingMessage.value = AppStrings.generatingPdf.tr;

      final pdfResult = await _pdfService.generatePdfFromImages(
        images: selectedImages.toList(),
        outputFileName: pdfNameController.text.trim().isNotEmpty
            ? pdfNameController.text.trim()
            : null,
        pageFormat: pageFormat.value,
        isLandscape: isLandscape.value,
        margin: margin.value,
        quality: quality.value,
      );

      // Save to recent files
      await _storageService.addRecentFile(pdfResult.path);

      isLoading.value = false;

      // Show Interstitial Ad before transitioning to Result
      _admobService.showInterstitialAd(
        onComplete: () {
          Get.toNamed(
            AppRoutes.result,
            arguments: {
              'pdfFile': pdfResult,
              'operation': 'image_to_pdf',
            },
          );
        },
      );
    } catch (e) {
      isLoading.value = false;
      SnackbarHelper.showError('Failed to generate PDF: $e');
    }
  }
}
