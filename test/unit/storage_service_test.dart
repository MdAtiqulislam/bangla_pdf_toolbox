import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bangla_pdf_toolbox/app/core/services/storage_service.dart';
import 'package:bangla_pdf_toolbox/app/data/models/pdf_file_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService().init();
  });

  group('StorageService Unit Tests', () {
    test('Saves and retrieves Locale', () async {
      await storage.saveLocale(const Locale('en', 'US'));
      final locale = storage.getLocale();
      expect(locale.languageCode, 'en');

      await storage.saveLocale(const Locale('bn', 'BD'));
      final bnLocale = storage.getLocale();
      expect(bnLocale.languageCode, 'bn');
    });

    test('Saves and retrieves ThemeMode', () async {
      await storage.saveThemeMode(ThemeMode.dark);
      expect(storage.getThemeMode(), ThemeMode.dark);

      await storage.saveThemeMode(ThemeMode.light);
      expect(storage.getThemeMode(), ThemeMode.light);
    });

    test('Toggles and manages bookmarked PDF files', () async {
      const path1 = '/storage/doc1.pdf';
      const path2 = '/storage/doc2.pdf';

      await storage.toggleBookmarkedFile(path1);
      expect(storage.getBookmarkedFiles().contains(path1), isTrue);
      expect(storage.getBookmarkedFiles().contains(path2), isFalse);

      // Toggle off
      await storage.toggleBookmarkedFile(path1);
      expect(storage.getBookmarkedFiles().contains(path1), isFalse);
    });

    test('Saves recent files', () async {
      for (int i = 0; i < 5; i++) {
        await storage.saveRecentFile(PdfFileModel(
          id: 'id_$i',
          path: '/path/file_$i.pdf',
          fileName: 'file_$i.pdf',
          sizeInBytes: 1024 * (i + 1),
          modifiedDate: DateTime.now(),
        ));
      }

      final recents = storage.getRecentFiles();
      expect(recents.length, 5);
      expect(recents.first, '/path/file_4.pdf');
    });
  });
}
