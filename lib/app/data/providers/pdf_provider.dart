import '../models/pdf_file_model.dart';
import '../../core/services/pdf_service.dart';
import '../../data/models/image_file_model.dart';
import 'package:pdf/pdf.dart';
import '../../core/constants/app_constants.dart';

class PdfProvider {
  final PdfService _pdfService;

  PdfProvider(this._pdfService);

  Future<PdfFileModel> createPdfFromImages({
    required List<ImageFileModel> images,
    String? outputFileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool isLandscape = false,
    double margin = AppConstants.marginNone,
    int quality = AppConstants.qualityMedium,
  }) {
    return _pdfService.generatePdfFromImages(
      images: images,
      outputFileName: outputFileName,
      pageFormat: pageFormat,
      isLandscape: isLandscape,
      margin: margin,
      quality: quality,
    );
  }

  Future<PdfFileModel> mergePdfFiles({
    required List<PdfFileModel> pdfFiles,
    String? outputFileName,
  }) {
    return _pdfService.mergePdfs(
      pdfFiles: pdfFiles,
      outputFileName: outputFileName,
    );
  }

  Future<List<String>> extractImagesFromPdf({
    required String pdfPath,
    int dpi = 150,
  }) {
    return _pdfService.convertPdfToImages(pdfPath: pdfPath, dpi: dpi);
  }
}
