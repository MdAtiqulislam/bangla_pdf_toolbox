import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../services/storage_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showActions;
  final List<Widget>? extraActions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showActions = true,
    this.extraActions,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.isRegistered<ThemeController>() ? Get.find<ThemeController>() : null;
    final storage = Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

    final hasExtra = extraActions != null && extraActions!.isNotEmpty;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.r),
              onPressed: () => Get.back(),
            )
          : null,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (hasExtra) ...extraActions!,
        if (showActions && !hasExtra) ...[
          // Language Switcher Badge
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              final currentLocale = Get.locale ?? const Locale('bn', 'BD');
              if (currentLocale.languageCode == 'bn') {
                const newLocale = Locale('en', 'US');
                Get.updateLocale(newLocale);
                storage?.saveLocale(newLocale);
              } else {
                const newLocale = Locale('bn', 'BD');
                Get.updateLocale(newLocale);
                storage?.saveLocale(newLocale);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                (Get.locale?.languageCode == 'en') ? 'বাংলা' : 'EN',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          // Theme Toggle Icon
          if (themeController != null)
            Obx(() {
              final isDarkMode = themeController.isDarkMode;
              return IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20.r,
                  color: isDarkMode ? Colors.amber : AppColors.lightTextSecondary,
                ),
                tooltip: isDarkMode ? 'light_theme'.tr : 'dark_theme'.tr,
                onPressed: () => themeController.toggleTheme(),
              );
            }),
        ],
      ],
    );
  }
}
