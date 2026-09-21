import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.resultTitle.tr),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => controller.goHome(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Success Icon Animation / Graphic
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 54,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Success Message
                    Text(
                      controller.successMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // File Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            icon: Icons.description_rounded,
                            label: AppStrings.fileName.tr,
                            value: controller.pdfFile.fileName,
                            isDark: isDark,
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            context,
                            icon: Icons.data_usage_rounded,
                            label: AppStrings.fileSize.tr,
                            value: FileUtils.formatBytes(controller.pdfFile.sizeInBytes),
                            isDark: isDark,
                          ),
                          if (controller.pdfFile.pageCount > 0) ...[
                            const Divider(height: 20),
                            _buildDetailRow(
                              context,
                              icon: Icons.pages_rounded,
                              label: AppStrings.pageCount.tr,
                              value: '${controller.pdfFile.pageCount} ${Get.locale?.languageCode == 'bn' ? 'পেজ' : 'pages'}',
                              isDark: isDark,
                            ),
                          ],
                          const Divider(height: 20),
                          _buildDetailRow(
                            context,
                            icon: Icons.folder_open_rounded,
                            label: AppStrings.filePath.tr,
                            value: controller.pdfFile.path,
                            isDark: isDark,
                            isSmall: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    CustomButton(
                      text: AppStrings.openInAppReader.tr,
                      icon: Icons.chrome_reader_mode_rounded,
                      onPressed: () => controller.openInAppReader(),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: AppStrings.saveToDownloads.tr,
                      icon: Icons.download_rounded,
                      backgroundColor: AppColors.success,
                      onPressed: () => controller.saveToDownloads(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: AppStrings.sharePdf.tr,
                            icon: Icons.share_rounded,
                            isOutlined: true,
                            backgroundColor: AppColors.secondary,
                            onPressed: () => controller.sharePdf(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: AppStrings.printPdf.tr,
                            icon: Icons.print_rounded,
                            isOutlined: true,
                            backgroundColor: AppColors.primary,
                            onPressed: () => controller.printPdf(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => controller.goHome(),
                      icon: const Icon(Icons.home_rounded, size: 20),
                      label: Text(
                        AppStrings.home.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isSmall = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: isSmall ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
