import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controllers/lock_pdf_controller.dart';

class LockPdfView extends GetView<LockPdfController> {
  const LockPdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: AppStrings.lockPdf.tr,
            extraActions: [
              Obx(() {
                if (controller.selectedPdf.value == null) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: AppStrings.clearAll.tr,
                  onPressed: () => controller.reset(),
                );
              }),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Obx(() {
                    if (controller.selectedPdf.value == null) {
                      return _buildPickPrompt(context, isDark);
                    }
                    return _buildLockContent(context, isDark);
                  }),
                ),
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
        Obx(() {
          if (controller.isLocking.value) {
            return LoadingOverlay(message: controller.loadingMessage.value);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildPickPrompt(BuildContext context, bool isDark) {
    const orangeColor = Color(0xFFEA580C);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: orangeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 46,
                color: orangeColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.selectPdf.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.lockPdfDesc.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: AppStrings.selectPdf.tr,
              icon: Icons.file_open_rounded,
              width: 260,
              backgroundColor: orangeColor,
              onPressed: () => controller.pickPdfFile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockContent(BuildContext context, bool isDark) {
    final pdf = controller.selectedPdf.value!;
    const orangeColor = Color(0xFFEA580C);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: orangeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: orangeColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pdf.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${FileUtils.formatBytes(pdf.sizeInBytes)} • ${pdf.pageCount} ${Get.locale?.languageCode == 'bn' ? 'পেজ' : 'pages'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, color: orangeColor),
                  onPressed: () => controller.pickPdfFile(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Output document name
          TextField(
            controller: controller.pdfNameController,
            decoration: InputDecoration(
              hintText: AppStrings.pdfNameHint.tr,
              labelText: AppStrings.enterPdfName.tr,
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Password Field
          Obx(() => TextField(
            controller: controller.passwordController,
            obscureText: !controller.isPasswordVisible.value,
            decoration: InputDecoration(
              labelText: AppStrings.enterPassword.tr,
              hintText: AppStrings.passwordHint.tr,
              prefixIcon: const Icon(Icons.lock_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => controller.isPasswordVisible.toggle(),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )),
          const SizedBox(height: 16),

          // Confirm Password Field
          Obx(() => TextField(
            controller: controller.confirmPasswordController,
            obscureText: !controller.isPasswordVisible.value,
            decoration: InputDecoration(
              labelText: AppStrings.confirmPassword.tr,
              hintText: AppStrings.confirmPassword.tr,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )),
          const SizedBox(height: 24),

          // Lock Button
          CustomButton(
            text: AppStrings.lockAndSave.tr,
            icon: Icons.lock_rounded,
            backgroundColor: orangeColor,
            onPressed: () => controller.lockPdf(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
