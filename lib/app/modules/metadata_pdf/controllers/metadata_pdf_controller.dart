import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../routes/app_routes.dart';

class MetadataPdfController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();
  final AdmobService _admobService = Get.find<AdmobService>();

  final selectedPdf = Rxn<PdfFileModel>();
  final isSaving = false.obs;

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final subjectController = TextEditingController();
  final keywordsController = TextEditingController();

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

  @override
  void onClose() {
    titleController.dispose();
    authorController.dispose();
    subjectController.dispose();
    keywordsController.dispose();
    super.onClose();
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
      SnackbarHelper.showError('Error selecting file: $e');
    }
  }

  Future<void> setPdf(PdfFileModel pdf) async {
    selectedPdf.value = pdf;
    try {
      final bytes = await File(pdf.path).readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      titleController.text = doc.documentInformation.title;
      authorController.text = doc.documentInformation.author;
      subjectController.text = doc.documentInformation.subject;
      keywordsController.text = doc.documentInformation.keywords;
      doc.dispose();
    } catch (_) {}
  }

  Future<void> saveMetadata() async {
    final pdf = selectedPdf.value;
    if (pdf == null) {
      SnackbarHelper.showError(AppStrings.noFilesSelected.tr);
      return;
    }

    try {
      isSaving.value = true;

      final result = await _pdfService.updatePdfMetadata(
        inputPath: pdf.path,
        title: titleController.text.trim(),
        author: authorController.text.trim(),
        subject: subjectController.text.trim(),
        keywords: keywordsController.text.trim(),
      );

      await _storageService.saveRecentFile(result);
      _admobService.showInterstitialAd();

      Get.offNamed(
        AppRoutes.result,
        arguments: {
          'pdfFile': result,
          'title': AppStrings.metadataPdf.tr,
          'message': AppStrings.successCreated.tr,
        },
      );
    } catch (e) {
      SnackbarHelper.showError('Failed to save metadata: $e');
    } finally {
      isSaving.value = false;
    }
  }
}
