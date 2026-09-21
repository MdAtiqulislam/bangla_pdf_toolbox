import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/page_number_pdf_controller.dart';

class PageNumberPdfView extends GetView<PageNumberPdfController> {
  const PageNumberPdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.pageNumberPdf.tr,
        showActions: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isProcessing.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(AppStrings.applyingPageNumbers.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.selectedPdf.value == null)
                        _buildFilePickerPlaceholder(context, isDark)
                      else
                        _buildSelectedFileCard(context, isDark),

                      const SizedBox(height: 24),

                      if (controller.selectedPdf.value != null) ...[
                        // Format Selection
                        Text(AppStrings.numberFormat.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 10),
                        _buildFormatTile('page_1_of_n', 'Page 1 of N', isDark),
                        _buildFormatTile('1_of_n', '1 / N', isDark),
                        _buildFormatTile('single_number', '1, 2, 3...', isDark),

                        const SizedBox(height: 20),

                        // Position Selection
                        Text(AppStrings.numberPosition.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 10),
                        _buildPositionTile('bottom_center', 'Bottom Center (নিচে মাঝখানে)', isDark),
                        _buildPositionTile('bottom_right', 'Bottom Right (নিচে ডানে)', isDark),
                        _buildPositionTile('bottom_left', 'Bottom Left (নিচে বামে)', isDark),
                        _buildPositionTile('top_center', 'Top Center (উপরে মাঝখানে)', isDark),
                        _buildPositionTile('top_right', 'Top Right (উপরে ডানে)', isDark),
                      ],
                    ],
                  ),
                );
              }),
            ),

            // Bottom Action Bar
            Obx(() {
              if (controller.selectedPdf.value == null || controller.isProcessing.value) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => controller.addPageNumbers(),
                    icon: const Icon(Icons.format_list_numbered_rounded, size: 20),
                    label: Text(AppStrings.addPageNumbers.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }),

            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerPlaceholder(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => controller.pickPdfFile(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.format_list_numbered_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'পেজ নম্বর যোগ করার জন্য PDF বাছুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            const SizedBox(height: 6),
            const Text('Select PDF to insert page numbers into headers or footers', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard(BuildContext context, bool isDark) {
    final pdf = controller.selectedPdf.value!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pdf.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(FileUtils.formatBytes(pdf.sizeInBytes), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.change_circle_outlined, color: AppColors.primary),
            onPressed: () => controller.pickPdfFile(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTile(String key, String title, bool isDark) {
    final isSelected = controller.selectedFormat.value == key;
    return InkWell(
      onTap: () => controller.selectedFormat.value = key,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionTile(String key, String title, bool isDark) {
    final isSelected = controller.selectedPosition.value == key;
    return InkWell(
      onTap: () => controller.selectedPosition.value = key,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
