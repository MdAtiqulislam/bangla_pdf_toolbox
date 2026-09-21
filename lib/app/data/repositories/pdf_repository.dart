import '../models/image_file_model.dart';
import '../models/pdf_file_model.dart';
import '../providers/pdf_provider.dart';
import 'package:pdf/pdf.dart';
import '../../core/constants/app_constants.dart';

class PdfRepository {
  final PdfProvider _provider;

  PdfRepository(this._provider);

  Future<PdfFileModel> imageToPdf({
    required List<ImageFileModel> images,
    String? outputFileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool isLandscape = false,
    double margin = AppConstants.marginNone,
    int quality = AppConstants.qualityMedium,
  }) {
    return _provider.createPdfFromImages(
      images: images,
      outputFileName: outputFileName,
      pageFormat: pageFormat,
      isLandscape: isLandscape,
      margin: margin,
      quality: quality,
    );
  }

  Future<PdfFileModel> mergePdfs({
    required List<PdfFileModel> pdfFiles,
    String? outputFileName,
  }) {
    return _provider.mergePdfFiles(
      pdfFiles: pdfFiles,
      outputFileName: outputFileName,
    );
  }

  Future<List<String>> pdfToImages({
    required String pdfPath,
    int dpi = 150,
  }) {
    return _provider.extractImagesFromPdf(pdfPath: pdfPath, dpi: dpi);
  }
}
