import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../theme/theme_controller.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final ThemeController _themeController = Get.find<ThemeController>();

  final Rx<Locale> currentLocale = const Locale('bn', 'BD').obs;

  @override
  void onInit() {
    super.onInit();
    currentLocale.value = _storage.getLocale();
  }

  void changeLanguage(String langCode, String countryCode) {
    final newLocale = Locale(langCode, countryCode);
    currentLocale.value = newLocale;
    Get.updateLocale(newLocale);
    _storage.saveLocale(newLocale);
    SnackbarHelper.showSuccess(
      langCode == 'bn' ? 'ভাষা বাংলায় পরিবর্তিত হয়েছে' : 'Language changed to English',
    );
  }

  void changeTheme(ThemeMode mode) {
    _themeController.setThemeMode(mode);
  }

  ThemeMode get currentThemeMode => _themeController.themeMode.value;
}
