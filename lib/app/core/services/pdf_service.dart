import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../data/models/image_file_model.dart';
import '../../data/models/pdf_file_model.dart';
import '../constants/app_constants.dart';
import '../utils/file_utils.dart';

class PdfService extends GetxService {
  /// Generate a PDF document from a list of images
  Future<PdfFileModel> generatePdfFromImages({
    required List<ImageFileModel> images,
    String? outputFileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool isLandscape = false,
    double margin = AppConstants.marginNone,
    int quality = AppConstants.qualityMedium,
  }) async {
    final pdf = pw.Document();

    final format = isLandscape ? pageFormat.landscape : pageFormat.portrait;

    for (int i = 0; i < images.length; i++) {
      final imageBytes = await images[i].getEffectiveBytes();

      // Compress / re-encode image based on selected quality
      Uint8List processedBytes = imageBytes;
      if (quality < 100) {
        final decoded = img.decodeImage(imageBytes);
        if (decoded != null) {
          processedBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
        }
      }

      final pwImage = pw.MemoryImage(processedBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pwImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('PDF_IMG');

    final outputFile = File('${outputDir.path}/$name');
    final pdfBytes = await pdf.save();
    await outputFile.writeAsBytes(pdfBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: pdfBytes.length,
      pageCount: images.length,
      modifiedDate: DateTime.now(),
    );
  }

  /// Merge multiple PDF documents into a single PDF
  Future<PdfFileModel> mergePdfs({
    required List<PdfFileModel> pdfFiles,
    String? outputFileName,
  }) async {
    final mergedPdf = pw.Document();
    int totalPageCount = 0;

    for (final pdfItem in pdfFiles) {
      final file = File(pdfItem.path);
      if (!await file.exists()) continue;

      final pdfBytes = await file.readAsBytes();

      // Rasterize pages of this PDF at crisp 150 DPI
      await for (final page in Printing.raster(pdfBytes, dpi: 150)) {
        final pngBytes = await page.toPng();
        final pwImage = pw.MemoryImage(pngBytes);
        totalPageCount++;

        mergedPdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pwImage, fit: pw.BoxFit.fill),
              );
            },
          ),
        );
      }
    }

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('MERGED_PDF');

    final outputFile = File('${outputDir.path}/$name');
    final mergedBytes = await mergedPdf.save();
    await outputFile.writeAsBytes(mergedBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: mergedBytes.length,
      pageCount: totalPageCount,
      modifiedDate: DateTime.now(),
    );
  }

  /// Split PDF pages into a new PDF document
  Future<PdfFileModel> splitPdf({
    required String pdfPath,
    required List<int> pageNumbers,
    String? outputFileName,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw Exception('PDF file not found at $pdfPath');
    }

    final inputBytes = await file.readAsBytes();
    final sf.PdfDocument sourceDoc = sf.PdfDocument(inputBytes: inputBytes);
    final sf.PdfDocument outputDoc = sf.PdfDocument();

    final validPages = pageNumbers
        .where((p) => p >= 1 && p <= sourceDoc.pages.count)
        .toSet()
        .toList()
      ..sort();

    if (validPages.isEmpty) {
      sourceDoc.dispose();
      outputDoc.dispose();
      throw Exception('No valid pages selected for splitting');
    }

    for (final pageNum in validPages) {
      final sf.PdfPage sourcePage = sourceDoc.pages[pageNum - 1];
      final sf.PdfTemplate template = sourcePage.createTemplate();
      final sf.PdfPage newPage = outputDoc.pages.add();
      newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
    }

    final List<int> outputBytes = outputDoc.saveSync();
    sourceDoc.dispose();
    outputDoc.dispose();

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('SPLIT_PDF');

    final outputFile = File('${outputDir.path}/$name');
    await outputFile.writeAsBytes(outputBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: outputBytes.length,
      pageCount: validPages.length,
      modifiedDate: DateTime.now(),
    );
  }

  /// Password protect / Encrypt a PDF document
  Future<PdfFileModel> lockPdf({
    required String pdfPath,
    required String password,
    String? outputFileName,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw Exception('PDF file not found at $pdfPath');
    }

    final inputBytes = await file.readAsBytes();
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: inputBytes);

    final sf.PdfSecurity security = document.security;
    security.userPassword = password;
    security.ownerPassword = password;
    security.algorithm = sf.PdfEncryptionAlgorithm.aesx256Bit;
    security.permissions.addAll([
      sf.PdfPermissionsFlags.print,
      sf.PdfPermissionsFlags.copyContent,
    ]);

    final List<int> outputBytes = document.saveSync();
    final int pageCount = document.pages.count;
    document.dispose();

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('LOCKED_PDF');

    final outputFile = File('${outputDir.path}/$name');
    await outputFile.writeAsBytes(outputBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: outputBytes.length,
      pageCount: pageCount,
      modifiedDate: DateTime.now(),
    );
  }

  /// Extract / convert PDF pages to a list of PNG image files
  Future<List<String>> convertPdfToImages({
    required String pdfPath,
    int dpi = 150,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw Exception('PDF file not found at $pdfPath');
    }

    final pdfBytes = await file.readAsBytes();
    final outputDir = await FileUtils.getAppOutputDirectory();
    final baseName = file.uri.pathSegments.last.replaceAll('.pdf', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final List<String> extractedImagePaths = [];
    int pageIndex = 1;

    await for (final page in Printing.raster(pdfBytes, dpi: dpi.toDouble())) {
      final pngBytes = await page.toPng();
      final imageFilePath = '${outputDir.path}/${baseName}_p${pageIndex}_$timestamp.png';
      final imageFile = File(imageFilePath);
      await imageFile.writeAsBytes(pngBytes);
      extractedImagePaths.add(imageFilePath);
      pageIndex++;
    }

    return extractedImagePaths;
  }

  /// Get page count of a PDF file (instant via Syncfusion PDF parser)
  Future<int> getPdfPageCount(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) return 1;
      final pdfBytes = await file.readAsBytes();
      if (pdfBytes.length < 32) return 1;
      final document = sf.PdfDocument(inputBytes: pdfBytes);
      final count = document.pages.count;
      document.dispose();
      return count > 0 ? count : 1;
    } catch (e) {
      return 1;
    }
  }

  /// Create a verified sample PDF document for testing
  Future<PdfFileModel> createSamplePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('PDF Tool - Verified Sample Document',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 14),
              pw.Paragraph(
                text: 'Welcome to PDF Tool! This is a verified, fully functional multi-page PDF document generated by the app. You can use this document to test reading, text highlights, bookmarks, night mode, and zooming.',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 12),
              pw.Bullet(text: 'Feature 1: 1-Tap Golden Bookmark Ribbon on Top-Right'),
              pw.Bullet(text: 'Feature 2: Floating Bottom Glass Dock with Page Scrubber'),
              pw.Bullet(text: 'Feature 3: 5-Color Quick Highlight Palette (Yellow, Green, Pink, Blue, Orange)'),
              pw.Bullet(text: 'Feature 4: Day, Sepia, Night & OLED Dark Themes'),
              pw.Bullet(text: 'Feature 5: Dual-Engine Architecture (Syncfusion + Android Native Core)'),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  '100% Offline & Secure: All PDF operations occur directly on your device with zero data transmission to external servers.',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey800),
                ),
              ),
            ],
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Page 2 - Comprehensive PDF Toolbox',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 14),
              pw.Paragraph(
                text: 'PDF Tool includes a suite of powerful document productivity features:',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 10),
              pw.Bullet(text: 'Image to PDF Converter with Auto-Crop and Color Enhancement Filters'),
              pw.Bullet(text: 'Merge Multiple PDFs into a single unified document'),
              pw.Bullet(text: 'Split PDF by extracting custom page ranges'),
              pw.Bullet(text: 'Lock & Encrypt PDF with standard passwords'),
              pw.Bullet(text: 'Extract High-Resolution PNG Images from any PDF page'),
              pw.Bullet(text: 'Universal In-App Device PDF Scanner & Intent Handler'),
            ],
          );
        },
      ),
    );

    final outputDir = await FileUtils.getAppOutputDirectory();
    final outputFile = File('${outputDir.path}/Sample_Guide.pdf');
    final pdfBytes = await pdf.save();
    await outputFile.writeAsBytes(pdfBytes);

    return PdfFileModel(
      id: 'sample_${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: 'Sample_Guide.pdf',
      sizeInBytes: pdfBytes.length,
      pageCount: 2,
      modifiedDate: DateTime.now(),
    );
  }

  /// Compress a PDF document to reduce file size
  Future<PdfFileModel> compressPdf({
    required String inputPath,
    int quality = 60,
    int dpi = 110,
    String? outputFileName,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input PDF file does not exist');
    }

    final inputBytes = await inputFile.readAsBytes();
    final compressedPdf = pw.Document();
    int totalPages = 0;

    // Rasterize and re-encode with jpeg compression
    await for (final page in Printing.raster(inputBytes, dpi: dpi.toDouble())) {
      final pngBytes = await page.toPng();
      final decoded = img.decodeImage(pngBytes);
      if (decoded != null) {
        final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
        final pwImage = pw.MemoryImage(jpgBytes);
        totalPages++;

        compressedPdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pwImage, fit: pw.BoxFit.fill),
              );
            },
          ),
        );
      }
    }

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('COMPRESSED');

    final outputFile = File('${outputDir.path}/$name');
    final pdfBytes = await compressedPdf.save();
    await outputFile.writeAsBytes(pdfBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: pdfBytes.length,
      pageCount: totalPages,
      modifiedDate: DateTime.now(),
    );
  }

  /// Stamp a signature onto a specific page of a PDF document
  Future<PdfFileModel> signPdf({
    required String inputPath,
    required Uint8List signaturePngBytes,
    required int pageIndex,
    required double normalizedX,
    required double normalizedY,
    required double normalizedWidth,
    required double normalizedHeight,
    String? outputFileName,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input PDF file does not exist');
    }

    final inputBytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: inputBytes);

    if (pageIndex < 0 || pageIndex >= document.pages.count) {
      document.dispose();
      throw Exception('Invalid page index: $pageIndex');
    }

    final page = document.pages[pageIndex];
    final rect = Rect.fromLTWH(
      normalizedX * page.size.width,
      normalizedY * page.size.height,
      normalizedWidth * page.size.width,
      normalizedHeight * page.size.height,
    );

    final bitmap = sf.PdfBitmap(signaturePngBytes);
    page.graphics.drawImage(bitmap, rect);

    final signedBytes = Uint8List.fromList(document.saveSync());
    final pageCount = document.pages.count;
    document.dispose();

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('SIGNED');

    final outputFile = File('${outputDir.path}/$name');
    await outputFile.writeAsBytes(signedBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: signedBytes.length,
      pageCount: pageCount,
      modifiedDate: DateTime.now(),
    );
  }

  /// Organize PDF by reordering, deleting, and rotating pages
  Future<PdfFileModel> organizePdf({
    required String inputPath,
    required List<int> pageOrder,
    Map<int, int>? pageRotations,
    String? outputFileName,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input PDF file does not exist');
    }

    if (pageOrder.isEmpty) {
      throw Exception('At least one page must be selected');
    }

    final inputBytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: inputBytes);
    final newDoc = sf.PdfDocument();

    for (final pageIdx in pageOrder) {
      if (pageIdx >= 0 && pageIdx < document.pages.count) {
        final srcPage = document.pages[pageIdx];
        final template = srcPage.createTemplate();
        final newPage = newDoc.pages.add();

        final rot = pageRotations != null ? (pageRotations[pageIdx] ?? 0) : 0;
        if (rot == 90) newPage.rotation = sf.PdfPageRotateAngle.rotateAngle90;
        if (rot == 180) newPage.rotation = sf.PdfPageRotateAngle.rotateAngle180;
        if (rot == 270) newPage.rotation = sf.PdfPageRotateAngle.rotateAngle270;

        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0), srcPage.size);
      }
    }

    final newBytes = Uint8List.fromList(newDoc.saveSync());
    final totalPageCount = newDoc.pages.count;
    newDoc.dispose();
    document.dispose();

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('ORGANIZED');

    final outputFile = File('${outputDir.path}/$name');
    await outputFile.writeAsBytes(newBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: newBytes.length,
      pageCount: totalPageCount,
      modifiedDate: DateTime.now(),
    );
  }


  /// Add text watermark across all pages of a PDF
  Future<PdfFileModel> addWatermark({
    required String inputPath,
    required String watermarkText,
    double fontSize = 42,
    double opacity = 0.35,
    double angle = -45,
    int colorValue = 0xFF718096, // grey default
    String? outputFileName,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) throw Exception('File not found');

    final bytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);
    final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize, style: sf.PdfFontStyle.bold);
    final a = (opacity * 255).round().clamp(0, 255);
    final r = (colorValue >> 16) & 0xFF;
    final g = (colorValue >> 8) & 0xFF;
    final b = colorValue & 0xFF;
    final brush = sf.PdfSolidBrush(sf.PdfColor(r, g, b, a));

    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final pageSize = page.size;
      final textSize = font.measureString(watermarkText);

      final state = page.graphics.save();
      page.graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
      page.graphics.rotateTransform(angle);
      page.graphics.drawString(
        watermarkText,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, textSize.width, textSize.height),
      );
      page.graphics.restore(state);
    }

    final newBytes = Uint8List.fromList(document.saveSync());
    final total = document.pages.count;
    document.dispose();

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('WATERMARKED');

    final outputFile = File('${outputDir.path}/$name');
    await outputFile.writeAsBytes(newBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: newBytes.length,
      pageCount: total,
      modifiedDate: DateTime.now(),
    );
  }

  /// Add page numbers to header or footer across all pages
  Future<PdfFileModel> addPageNumbers({
    required String inputPath,
    String format = 'page_of_total', // '1', '1_of_n', 'page_1_of_n'
    String position = 'bottom_center', // 'bottom_center', 'bottom_right', 'bottom_left', 'top_center', 'top_right'
    double fontSize = 11,
    String? outputFileName,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) throw Exception('File not found');

    final bytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);
    final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize);
    final brush = sf.PdfSolidBrush(sf.PdfColor(100, 100, 100));
    final total = document.pages.count;

    for (int i = 0; i < total; i++) {
      final pageNum = i + 1;
      String text;
      switch (format) {
        case '1_of_n':
          text = '$pageNum / $total';
          break;
        case 'page_1_of_n':
          text = 'Page $pageNum of $total';
          break;
        case 'single_number':
        default:
          text = '$pageNum';
          break;
      }

      final page = document.pages[i];
      final pageSize = page.size;
      final textSize = font.measureString(text);

      double x = (pageSize.width - textSize.width) / 2;
      double y = pageSize.height - textSize.height - 24;

      if (position == 'bottom_right') {
        x = pageSize.width - textSize.width - 32;
        y = pageSize.height - textSize.height - 24;
      } else if (position == 'bottom_left') {
        x = 32;
        y = pageSize.height - textSize.height - 24;
      } else if (position == 'top_center') {
        x = (pageSize.width - textSize.width) / 2;
        y = 24;
      } else if (position == 'top_right') {
        x = pageSize.width - textSize.width - 32;
        y = 24;
      }

      page.graphics.drawString(
        text,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
      );
    }

    final newBytes = Uint8List.fromList(document.saveSync());
    document.dispose();

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('PAGINATED');

    final outputFile = File('${outputDir.path}/$name');
    await outputFile.writeAsBytes(newBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: newBytes.length,
      pageCount: total,
      modifiedDate: DateTime.now(),
    );
  }

  /// Generate a multi-page PDF document from text content
  Future<PdfFileModel> generatePdfFromText({
    required String textContent,
    String title = '',
    double fontSize = 13,
    String? outputFileName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          if (title.isEmpty) return pw.SizedBox.shrink();
          return pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Paragraph(
              text: textContent,
              style: pw.TextStyle(fontSize: fontSize, lineSpacing: 2.0),
            ),
          ];
        },
      ),
    );

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('TEXT_DOC');

    final outputFile = File('${outputDir.path}/$name');
    final pdfBytes = await pdf.save();
    await outputFile.writeAsBytes(pdfBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: pdfBytes.length,
      pageCount: 1,
      modifiedDate: DateTime.now(),
    );
  }

  /// Extract text from all pages of a PDF document
  Future<String> extractTextFromPdf(String inputPath) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) throw Exception('File not found');

    final bytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);
    final extractor = sf.PdfTextExtractor(document);
    final extracted = extractor.extractText();
    document.dispose();

    return extracted;
  }

  /// Update PDF metadata (Title, Author, Subject, Keywords)
  Future<PdfFileModel> updatePdfMetadata({
    required String inputPath,
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? outputFileName,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) throw Exception('File not found');

    final bytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);

    if (title != null) document.documentInformation.title = title;
    if (author != null) document.documentInformation.author = author;
    if (subject != null) document.documentInformation.subject = subject;
    if (keywords != null) document.documentInformation.keywords = keywords;

    final newBytes = Uint8List.fromList(document.saveSync());
    final total = document.pages.count;
    document.dispose();

    final outputDir = await FileUtils.getAppOutputDirectory();
    final name = (outputFileName != null && outputFileName.trim().isNotEmpty)
        ? (outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf')
        : FileUtils.generateTimestampFileName('METADATA');

    final outputFile = File('${outputDir.path}/$name');
    await outputFile.writeAsBytes(newBytes);

    return PdfFileModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      path: outputFile.path,
      fileName: name,
      sizeInBytes: newBytes.length,
      pageCount: total,
      modifiedDate: DateTime.now(),
    );
  }

}
