import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bangla_pdf_toolbox/app/core/services/storage_service.dart';
import 'package:bangla_pdf_toolbox/app/data/models/pdf_file_model.dart';
import 'package:bangla_pdf_toolbox/app/modules/result/controllers/result_controller.dart';
import 'package:bangla_pdf_toolbox/app/modules/result/views/result_view.dart';
import 'package:bangla_pdf_toolbox/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    final storage = await StorageService().init();
    Get.put<StorageService>(storage, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ResultView displays valid file name and non-zero byte size', (tester) async {
    final mockPdf = PdfFileModel(
      id: 'test_123',
      path: '/tmp/Mock_Generated.pdf',
      fileName: 'Mock_Generated.pdf',
      sizeInBytes: 256 * 1024, // 256 KB
      pageCount: 3,
      modifiedDate: DateTime.now(),
    );

    Get.parameters = {};
    Get.replace<ResultController>(ResultController());

    // Inject arguments before controller initializes
    final controller = Get.put(ResultController());
    controller.pdfFile = mockPdf;
    controller.operation = 'compress_pdf';

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) {
          return GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('bn', 'BD'),
            home: const ResultView(),
          );
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ResultView), findsOneWidget);
    expect(find.text('Mock_Generated.pdf'), findsOneWidget);
    expect(find.textContaining('KB'), findsWidgets);
  });
}
