import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:bangla_pdf_toolbox/app/core/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfService pdfService;
  late String samplePdfPath;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => Directory.systemTemp.path,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider_android'),
      (MethodCall methodCall) async => Directory.systemTemp.path,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider_macos'),
      (MethodCall methodCall) async => Directory.systemTemp.path,
    );

    Get.testMode = true;
    pdfService = PdfService();
    Get.put<PdfService>(pdfService, permanent: true);

    final sample = await pdfService.createSamplePdf();
    samplePdfPath = sample.path;
  });

  group('PdfService Core Engine Unit Tests', () {
    test('1. createSamplePdf generates verified non-empty PDF', () async {
      final sample = await pdfService.createSamplePdf();
      expect(sample.sizeInBytes, greaterThan(0));
      expect(sample.pageCount, 2);
      expect(File(sample.path).existsSync(), isTrue);

      final bytes = await File(sample.path).readAsBytes();
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, '%PDF-');
    });

    test('2. generatePdfFromText creates formatted multi-page PDF', () async {
      const sampleText = 'Bangla PDF ToolBox - 100% Offline and Secure. Testing multi-page text flow with custom font sizes and headers.';
      final result = await pdfService.generatePdfFromText(
        textContent: sampleText,
        title: 'Test Document Title',
        fontSize: 14,
      );

      expect(result.sizeInBytes, greaterThan(0));
      expect(File(result.path).existsSync(), isTrue);
      expect(result.fileName.endsWith('.pdf'), isTrue);
    });

    test('3. addWatermark stamps text watermark on all pages', () async {
      final result = await pdfService.addWatermark(
        inputPath: samplePdfPath,
        watermarkText: 'CONFIDENTIAL',
        fontSize: 36,
        opacity: 0.4,
        angle: -45,
      );

      expect(result.sizeInBytes, greaterThan(0));
      expect(result.pageCount, 2);
      expect(File(result.path).existsSync(), isTrue);
    });

    test('4. addPageNumbers adds formatted page numbers to footers', () async {
      final result = await pdfService.addPageNumbers(
        inputPath: samplePdfPath,
        format: 'page_1_of_n',
        position: 'bottom_center',
        fontSize: 10,
      );

      expect(result.sizeInBytes, greaterThan(0));
      expect(result.pageCount, 2);
      expect(File(result.path).existsSync(), isTrue);
    });

    test('5. organizePdf reorders and rotates pages properly', () async {
      final result = await pdfService.organizePdf(
        inputPath: samplePdfPath,
        pageOrder: [1, 0], // reverse 2 pages
        pageRotations: {0: 90, 1: 0},
      );

      expect(result.sizeInBytes, greaterThan(0));
      expect(result.pageCount, 2);
      expect(File(result.path).existsSync(), isTrue);
    });

    test('6. updatePdfMetadata edits document info fields', () async {
      final result = await pdfService.updatePdfMetadata(
        inputPath: samplePdfPath,
        title: 'Deep Test Title',
        author: 'Antigravity AI',
        subject: 'Automated Testing',
        keywords: 'test, pdf, flutter',
      );

      expect(result.sizeInBytes, greaterThan(0));
      expect(File(result.path).existsSync(), isTrue);
    });

    test('7. extractTextFromPdf extracts readable text from PDF', () async {
      // Create a native Syncfusion doc with text
      final sfDoc = sf.PdfDocument();
      final page = sfDoc.pages.add();
      final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 14);
      page.graphics.drawString('Hello Bangla PDF ToolBox Extraction Test', font, bounds: const Rect.fromLTWH(20, 20, 300, 50));
      final sfBytes = Uint8List.fromList(sfDoc.saveSync());
      sfDoc.dispose();

      final tmpFile = File('${Directory.systemTemp.path}/sf_extract_test.pdf');
      await tmpFile.writeAsBytes(sfBytes);

      final text = await pdfService.extractTextFromPdf(tmpFile.path);
      expect(text, isNotEmpty);
      expect(text.contains('Hello Bangla PDF ToolBox'), isTrue);
    });

    test('8. signPdf places signature bitmap on selected page', () async {
      final dummyPng = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]);

      final result = await pdfService.signPdf(
        inputPath: samplePdfPath,
        signaturePngBytes: dummyPng,
        pageIndex: 0,
        normalizedX: 0.2,
        normalizedY: 0.7,
        normalizedWidth: 0.3,
        normalizedHeight: 0.1,
      );

      expect(result.sizeInBytes, greaterThan(0));
      expect(File(result.path).existsSync(), isTrue);
    });
  });
}
