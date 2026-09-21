import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'app/core/constants/app_constants.dart';
import 'app/core/services/admob_service.dart';
import 'app/core/services/file_intent_service.dart';
import 'app/core/services/pdf_service.dart';
import 'app/core/services/storage_service.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_controller.dart';
import 'app/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Core Services
  final storageService = await Get.putAsync<StorageService>(
    () => StorageService().init(),
  );

  Get.put<PdfService>(PdfService());

  await Get.putAsync<AdmobService>(
    () => AdmobService().init(),
  );

  await Get.putAsync<FileIntentService>(
    () => FileIntentService().init(),
  );

  Get.put<ThemeController>(ThemeController());

  // Retrieve saved locale and theme
  final initialLocale = storageService.getLocale();
  final initialThemeMode = storageService.getThemeMode();

  runApp(
    BanglaPdfApp(
      initialLocale: initialLocale,
      initialThemeMode: initialThemeMode,
    ),
  );
}

class BanglaPdfApp extends StatelessWidget {
  final Locale initialLocale;
  final ThemeMode initialThemeMode;

  const BanglaPdfApp({
    super.key,
    required this.initialLocale,
    required this.initialThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          translations: AppTranslations(),
          locale: initialLocale,
          fallbackLocale: AppTranslations.fallbackLocale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: initialThemeMode,
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          defaultTransition: Transition.cupertino,
        );
      },
    );
  }
}
