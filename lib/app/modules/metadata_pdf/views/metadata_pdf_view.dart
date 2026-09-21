import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/metadata_pdf_controller.dart';

class MetadataPdfView extends GetView<MetadataPdfController> {
  const MetadataPdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.metadataPdf.tr,
        showActions: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isSaving.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(AppStrings.savingMetadata.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }

                if (controller.selectedPdf.value == null) {
                  return _buildFilePickerPlaceholder(context, isDark);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectedFileCard(context, isDark),
                      const SizedBox(height: 20),

                      // Title
                      Text(AppStrings.docTitle.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.titleController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Author
                      Text(AppStrings.docAuthor.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.authorController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Subject
                      Text(AppStrings.docSubject.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.subjectController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Keywords
                      Text(AppStrings.docKeywords.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.keywordsController,
                        decoration: InputDecoration(
                          hintText: 'Comma separated keywords (e.g. invoice, report)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // Bottom Save Bar
            Obx(() {
              if (controller.selectedPdf.value == null || controller.isSaving.value) {
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
                    onPressed: () => controller.saveMetadata(),
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: Text(AppStrings.saveMetadata.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
    return Center(
      child: GestureDetector(
        onTap: () => controller.pickPdfFile(),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'তথ্য এডিট করার জন্য PDF বাছুন',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              const SizedBox(height: 6),
              const Text('Edit Title, Author, Subject and Keywords', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard(BuildContext context, bool isDark) {
    final pdf = controller.selectedPdf.value!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pdf.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
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
}
