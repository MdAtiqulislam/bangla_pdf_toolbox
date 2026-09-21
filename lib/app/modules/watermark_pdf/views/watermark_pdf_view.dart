import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/watermark_pdf_controller.dart';

class WatermarkPdfView extends GetView<WatermarkPdfController> {
  const WatermarkPdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.watermarkPdf.tr,
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
                        Text(AppStrings.applyingWatermark.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
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

                      const SizedBox(height: 20),

                      if (controller.selectedPdf.value != null) ...[
                        // Watermark Text Input
                        Text(AppStrings.watermarkText.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller.textController,
                          decoration: InputDecoration(
                            hintText: 'e.g. CONFIDENTIAL, DRAFT, COPY',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isDark ? AppColors.darkCard : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Preset Quick Buttons
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickChip('CONFIDENTIAL', isDark),
                            _buildQuickChip('DRAFT', isDark),
                            _buildQuickChip('COPY', isDark),
                            _buildQuickChip('গোপনীয়', isDark),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Opacity Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppStrings.watermarkOpacity.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${(controller.opacity.value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                        Slider(
                          value: controller.opacity.value,
                          min: 0.1,
                          max: 0.8,
                          activeColor: AppColors.primary,
                          onChanged: (val) => controller.opacity.value = val,
                        ),
                        const SizedBox(height: 12),

                        // Font Size Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Font Size', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${controller.fontSize.value.toInt()} pt', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                        Slider(
                          value: controller.fontSize.value,
                          min: 20.0,
                          max: 72.0,
                          activeColor: AppColors.primary,
                          onChanged: (val) => controller.fontSize.value = val,
                        ),
                        const SizedBox(height: 12),

                        // Color selection
                        Text(AppStrings.watermarkColor.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildColorChoice(0xFF718096, Colors.grey),
                            const SizedBox(width: 10),
                            _buildColorChoice(0xFFE53E3E, Colors.red),
                            const SizedBox(width: 10),
                            _buildColorChoice(0xFF3182CE, Colors.blue),
                            const SizedBox(width: 10),
                            _buildColorChoice(0xFF38A169, Colors.green),
                            const SizedBox(width: 10),
                            _buildColorChoice(0xFFDD6B20, Colors.orange),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),

            // Bottom Action
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
                    onPressed: () => controller.applyWatermark(),
                    icon: const Icon(Icons.branding_watermark_rounded, size: 20),
                    label: Text(AppStrings.addWatermark.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
              child: const Icon(Icons.branding_watermark_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'ওয়াটারমার্ক যোগ করার জন্য PDF বাছুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            const SizedBox(height: 6),
            const Text('Select PDF to add text or logo watermark', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildQuickChip(String text, bool isDark) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () => controller.textController.text = text,
    );
  }

  Widget _buildColorChoice(int hexValue, Color displayColor) {
    final isSelected = controller.selectedColor.value == hexValue;
    return GestureDetector(
      onTap: () => controller.selectedColor.value = hexValue,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white, width: isSelected ? 3 : 1.5),
        ),
      ),
    );
  }
}
