import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bangla_pdf_toolbox/app/core/services/admob_service.dart';
import 'package:bangla_pdf_toolbox/app/core/services/file_intent_service.dart';
import 'package:bangla_pdf_toolbox/app/core/services/pdf_service.dart';
import 'package:bangla_pdf_toolbox/app/core/services/storage_service.dart';
import 'package:bangla_pdf_toolbox/app/modules/home/bindings/home_binding.dart';
import 'package:bangla_pdf_toolbox/app/modules/home/views/home_view.dart';
import 'package:bangla_pdf_toolbox/app/theme/theme_controller.dart';
import 'package:bangla_pdf_toolbox/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => Directory.systemTemp.path,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.banglapdftools.bangla_pdf_toolbox/pdf_scanner'),
      (MethodCall methodCall) async => <String>[],
    );
  });

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

  Widget createTestWidget() {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('bn', 'BD'),
          initialBinding: HomeBinding(),
          home: const HomeView(),
        );
      },
    );
  }

  group('Home Screen Multi-Device Responsive & Stress Tests', () {
    testWidgets('1. Stress Test: Ultra-small 320x568 screen (0 RenderFlex Overflow)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Stress Test: Standard 390x844 modern mobile screen (0 Overflow)', (tester) async {
      tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Stress Test: 800x1280 Tablet screen with multi-column grid', (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 1280 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Category Tabs switch dynamically without errors', (tester) async {
      tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final converterTab = find.text('কনভার্টার');
      if (converterTab.evaluate().isNotEmpty) {
        await tester.tap(converterTab, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }

      final allTab = find.text('সকল টুল');
      if (allTab.evaluate().isNotEmpty) {
        await tester.tap(allTab, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('5. Navigation Drawer opens smoothly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final drawerBtn = find.byIcon(Icons.menu_rounded);
      expect(drawerBtn, findsOneWidget);
      await tester.tap(drawerBtn);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Drawer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
