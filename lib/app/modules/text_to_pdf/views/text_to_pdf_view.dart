import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/text_to_pdf_controller.dart';

class TextToPdfView extends GetView<TextToPdfController> {
  const TextToPdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.textToPdf.tr,
        showActions: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isGenerating.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(AppStrings.generatingPdfFromText.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document Title Input
                      Text(AppStrings.documentTitle.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. My Notes / Document Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Text Content Input
                      const Text('Text Content (লেখা)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.contentController,
                        maxLines: 12,
                        decoration: InputDecoration(
                          hintText: AppStrings.enterTextHint.tr,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Font size control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Font Size (ফন্ট সাইজ)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('${controller.fontSize.value.toInt()} pt', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: controller.fontSize.value,
                        min: 9.0,
                        max: 24.0,
                        activeColor: AppColors.primary,
                        onChanged: (val) => controller.fontSize.value = val,
                      ),
                    ],
                  ),
                );
              }),
            ),

            // Bottom Action Bar
            Container(
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
                  onPressed: () => controller.generatePdf(),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: Text(AppStrings.createPdfFromText.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),

            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
