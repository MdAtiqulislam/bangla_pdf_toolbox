import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/image_filter_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/image_to_pdf_controller.dart';

class PdfConfigSheet extends StatelessWidget {
  const PdfConfigSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ImageToPdfController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.pdfSettings.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          // Document Filter
          Text(
            AppStrings.docFilter.tr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(AppStrings.original.tr),
                    selected: controller.defaultFilter.value == DocFilterType.original,
                    onSelected: (_) => controller.applyFilterToAll(DocFilterType.original),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.defaultFilter.value == DocFilterType.original ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(AppStrings.magicColor.tr),
                    selected: controller.defaultFilter.value == DocFilterType.magicColor,
                    onSelected: (_) => controller.applyFilterToAll(DocFilterType.magicColor),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.defaultFilter.value == DocFilterType.magicColor ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(AppStrings.blackAndWhite.tr),
                    selected: controller.defaultFilter.value == DocFilterType.blackAndWhite,
                    onSelected: (_) => controller.applyFilterToAll(DocFilterType.blackAndWhite),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.defaultFilter.value == DocFilterType.blackAndWhite ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(AppStrings.brighten.tr),
                    selected: controller.defaultFilter.value == DocFilterType.brighten,
                    onSelected: (_) => controller.applyFilterToAll(DocFilterType.brighten),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.defaultFilter.value == DocFilterType.brighten ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(AppStrings.grayscale.tr),
                    selected: controller.defaultFilter.value == DocFilterType.grayscale,
                    onSelected: (_) => controller.applyFilterToAll(DocFilterType.grayscale),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.defaultFilter.value == DocFilterType.grayscale ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Orientation
          Text(
            AppStrings.pageOrientation.tr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.portrait.tr),
                    selected: !controller.isLandscape.value,
                    onSelected: (val) => controller.isLandscape.value = false,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: !controller.isLandscape.value ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.landscape.tr),
                    selected: controller.isLandscape.value,
                    onSelected: (val) => controller.isLandscape.value = true,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.isLandscape.value ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Margins
          Text(
            AppStrings.margins.tr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.noMargin.tr),
                    selected: controller.margin.value == AppConstants.marginNone,
                    onSelected: (_) => controller.margin.value = AppConstants.marginNone,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.margin.value == AppConstants.marginNone ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.smallMargin.tr),
                    selected: controller.margin.value == AppConstants.marginSmall,
                    onSelected: (_) => controller.margin.value = AppConstants.marginSmall,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.margin.value == AppConstants.marginSmall ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.mediumMargin.tr),
                    selected: controller.margin.value == AppConstants.marginMedium,
                    onSelected: (_) => controller.margin.value = AppConstants.marginMedium,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.margin.value == AppConstants.marginMedium ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Quality
          Text(
            AppStrings.imageQuality.tr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.lowQuality.tr),
                    selected: controller.quality.value == AppConstants.qualityLow,
                    onSelected: (_) => controller.quality.value = AppConstants.qualityLow,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.quality.value == AppConstants.qualityLow ? AppColors.primary : null,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.mediumQuality.tr),
                    selected: controller.quality.value == AppConstants.qualityMedium,
                    onSelected: (_) => controller.quality.value = AppConstants.qualityMedium,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.quality.value == AppConstants.qualityMedium ? AppColors.primary : null,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.highQuality.tr),
                    selected: controller.quality.value == AppConstants.qualityHigh,
                    onSelected: (_) => controller.quality.value = AppConstants.qualityHigh,
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: controller.quality.value == AppConstants.qualityHigh ? AppColors.primary : null,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          CustomButton(
            text: AppStrings.confirm.tr,
            onPressed: () => Get.back(),
          ),
        ],
      ),
      ),
    );
  }
}
