import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

class SnackbarHelper {
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? 'success'.tr,
      message,
      backgroundColor: AppColors.success.withValues(alpha: 0.92),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  static void showError(String message, {String? title}) {
    Get.snackbar(
      title ?? 'error'.tr,
      message,
      backgroundColor: AppColors.error.withValues(alpha: 0.92),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error_rounded, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  static void showInfo(String message, {String? title}) {
    Get.snackbar(
      title ?? 'info',
      message,
      backgroundColor: AppColors.secondary.withValues(alpha: 0.92),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.info_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}
