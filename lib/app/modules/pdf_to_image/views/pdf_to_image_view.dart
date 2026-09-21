import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controllers/pdf_to_image_controller.dart';

class PdfToImageView extends GetView<PdfToImageController> {
  const PdfToImageView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: AppStrings.pdfToImage.tr,
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
                    return _buildConversionContent(context, isDark);
                  }),
                ),
                // Bottom Banner
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
        // Loading Overlay
        Obx(() {
          if (controller.isConverting.value) {
            return LoadingOverlay(message: controller.loadingMessage.value);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildPickPrompt(BuildContext context, bool isDark) {
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
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 46,
                color: AppColors.secondary,
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
              AppStrings.pdfToImageDesc.tr,
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
              backgroundColor: AppColors.secondary,
              onPressed: () => controller.pickPdfFile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionContent(BuildContext context, bool isDark) {
    final pdf = controller.selectedPdf.value!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected PDF card
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 28),
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
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.secondary),
                  tooltip: AppStrings.selectPdf.tr,
                  onPressed: () => controller.pickPdfFile(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Convert button (if not converted yet)
          if (controller.extractedImages.isEmpty) ...[
            CustomButton(
              text: AppStrings.convertAndSave.tr,
              icon: Icons.auto_awesome_rounded,
              backgroundColor: AppColors.secondary,
              onPressed: () => controller.convertToImages(),
            ),
          ] else ...[
            // Header for extracted images
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.extractPages.tr} (${controller.extractedImages.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => controller.shareAllImages(),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(AppStrings.shareImages.tr),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid of extracted pages
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isTablet = screenWidth >= 600;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.extractedImages.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                final imagePath = controller.extractedImages[index];
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(imagePath),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Page badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Share action button
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                            onPressed: () => controller.shareSingleImage(imagePath),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
        ],
      ),
    );
  }
}
