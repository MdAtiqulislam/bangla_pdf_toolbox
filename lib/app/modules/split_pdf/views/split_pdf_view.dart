import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controllers/split_pdf_controller.dart';

class SplitPdfView extends GetView<SplitPdfController> {
  const SplitPdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: AppStrings.splitPdf.tr,
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
                    return _buildSplitContent(context, isDark);
                  }),
                ),
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
        Obx(() {
          if (controller.isSplitting.value) {
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
                color: AppColors.purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_split_rounded,
                size: 46,
                color: AppColors.purple,
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
              AppStrings.splitPdfDesc.tr,
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
              backgroundColor: AppColors.purple,
              onPressed: () => controller.pickPdfFile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitContent(BuildContext context, bool isDark) {
    final pdf = controller.selectedPdf.value!;

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
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.purple, size: 28),
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
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.purple),
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

          // Range Input
          TextField(
            controller: controller.rangeController,
            onChanged: (val) => controller.applyRangeFromInput(val),
            decoration: InputDecoration(
              labelText: AppStrings.splitRange.tr,
              hintText: AppStrings.splitRangeHint.tr,
              prefixIcon: const Icon(Icons.format_list_numbered_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selection toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Obx(() => Text(
                  '${AppStrings.selectedPagesCount.tr}: ${controller.selectedPages.length}/${controller.totalPages.value}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                )),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => controller.selectAllPages(),
                    child: Text(AppStrings.selectAll.tr),
                  ),
                  TextButton(
                    onPressed: () => controller.deselectAllPages(),
                    child: Text(AppStrings.deselectAll.tr),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Grid of page chips
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(controller.totalPages.value, (i) {
                final pageNum = i + 1;
                final isSelected = controller.selectedPages.contains(pageNum);
                return FilterChip(
                  label: Text('Page $pageNum'),
                  selected: isSelected,
                  onSelected: (_) => controller.togglePage(pageNum),
                  selectedColor: AppColors.purple.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.purple,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.purple : null,
                  ),
                );
              }),
            );
          }),
          const SizedBox(height: 24),

          // Split Button
          CustomButton(
            text: AppStrings.splitAndSave.tr,
            icon: Icons.call_split_rounded,
            backgroundColor: AppColors.purple,
            onPressed: () => controller.splitPdf(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
