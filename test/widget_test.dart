import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bangla_pdf_toolbox/app/theme/theme_controller.dart';
import 'package:bangla_pdf_toolbox/app/core/services/storage_service.dart';
import 'package:bangla_pdf_toolbox/app/core/services/pdf_service.dart';
import 'package:bangla_pdf_toolbox/app/core/services/admob_service.dart';
import 'package:bangla_pdf_toolbox/app/core/services/file_intent_service.dart';
import 'package:bangla_pdf_toolbox/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    final storage = await StorageService().init();
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<PdfService>(PdfService(), permanent: true);
    Get.put<AdmobService>(AdmobService(), permanent: true);
    Get.put<FileIntentService>(FileIntentService(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('BanglaPdfApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const BanglaPdfApp(
        initialLocale: Locale('bn', 'BD'),
        initialThemeMode: ThemeMode.system,
      ),
    );

    expect(find.byType(BanglaPdfApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
  });
}
