import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../routes/app_routes.dart';

class OrganizePdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AdmobService _admobService = Get.find<AdmobService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final pageIndices = <int>[].obs;
  final pageRotations = <int, int>{}.obs;
  final pageThumbnails = <int, Uint8List>{}.obs;
  final isRendering = false.obs;
  final isSaving = false.obs;

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
    pageIndices.clear();
    pageRotations.clear();
    pageThumbnails.clear();
    await _loadThumbnails();
  }

  Future<void> _loadThumbnails() async {
    final pdf = selectedPdf.value;
    if (pdf == null) return;

    try {
      isRendering.value = true;
      final bytes = await File(pdf.path).readAsBytes();

      int index = 0;
      await for (final page in Printing.raster(bytes, dpi: 90)) {
        final png = await page.toPng();
        pageThumbnails[index] = png;
        pageIndices.add(index);
        pageRotations[index] = 0;
        index++;
      }
    } catch (e) {
      debugPrint('Error loading thumbnails: $e');
    } finally {
      isRendering.value = false;
    }
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = pageIndices.removeAt(oldIndex);
    pageIndices.insert(newIndex, item);
  }

  void rotatePage(int pageIndex) {
    final currentRot = pageRotations[pageIndex] ?? 0;
    pageRotations[pageIndex] = (currentRot + 90) % 360;
  }

  void deletePage(int pageIndex) {
    if (pageIndices.length <= 1) {
      SnackbarHelper.showError(AppStrings.atLeastOnePage.tr);
      return;
    }
    pageIndices.remove(pageIndex);
  }

  void resetPages() {
    pageIndices.assignAll(List.generate(pageThumbnails.length, (i) => i));
    pageRotations.assignAll({for (int i = 0; i < pageThumbnails.length; i++) i: 0});
  }

  Future<void> saveOrganizedPdf() async {
    final pdf = selectedPdf.value;
    if (pdf == null || pageIndices.isEmpty) {
      SnackbarHelper.showError(AppStrings.atLeastOnePage.tr);
      return;
    }

    try {
      isSaving.value = true;

      final organizedPdf = await _pdfService.organizePdf(
        inputPath: pdf.path,
        pageOrder: pageIndices.toList(),
        pageRotations: pageRotations,
      );

      await _storageService.saveRecentFile(organizedPdf);
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': organizedPdf,
          'title': AppStrings.organizePdf.tr,
          'message': AppStrings.successCreated.tr,
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Error saving PDF: $e');
    } finally {
      isSaving.value = false;
    }
  }
}
