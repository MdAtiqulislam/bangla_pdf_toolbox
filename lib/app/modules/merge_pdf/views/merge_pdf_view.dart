import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/file_tile.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controllers/merge_pdf_controller.dart';

class MergePdfView extends GetView<MergePdfController> {
  const MergePdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: AppStrings.mergePdf.tr,
            extraActions: [
              Obx(() {
                if (controller.selectedPdfs.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: AppStrings.clearAll.tr,
                  onPressed: () => controller.clearAll(),
                );
              }),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Obx(() {
                    if (controller.selectedPdfs.isEmpty) {
                      return _buildEmptyState(context, isDark);
                    }
                    return _buildSelectedPdfList(context, isDark);
                  }),
                ),
                // Bottom Panel
                Obx(() {
                  if (controller.selectedPdfs.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: AppStrings.addMorePdf.tr,
                                icon: Icons.add_rounded,
                                isOutlined: true,
                                backgroundColor: AppColors.success,
                                onPressed: () => controller.pickPdfFiles(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: AppStrings.mergeAndSave.tr,
                                icon: Icons.merge_type_rounded,
                                backgroundColor: AppColors.success,
                                onPressed: () => controller.mergePdfs(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
        // Loading Overlay
        Obx(() {
          if (controller.isMerging.value) {
            return LoadingOverlay(message: controller.loadingMessage.value);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
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
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.merge_type_rounded,
                size: 46,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.selectMultiplePdfs.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.mergePdfDesc.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: AppStrings.selectMultiplePdfs.tr,
              icon: Icons.file_open_rounded,
              width: 260,
              backgroundColor: AppColors.success,
              onPressed: () => controller.pickPdfFiles(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPdfList(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.success.withValues(alpha: 0.08),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.reorderTip.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ),
              Text(
                '${controller.selectedPdfs.length} ${Get.locale?.languageCode == 'bn' ? 'টি ফাইল' : 'files'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.selectedPdfs.length,
              onReorder: (oldIndex, newIndex) => controller.reorderPdfs(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final pdf = controller.selectedPdfs[index];
                return FileTile(
                  key: ValueKey(pdf.id),
                  title: pdf.fileName,
                  sizeInBytes: pdf.sizeInBytes,
                  subtitle: '${FileUtils.formatBytes(pdf.sizeInBytes)} • ${pdf.pageCount} ${Get.locale?.languageCode == 'bn' ? 'পেজ' : 'pages'}',
                  isReorderable: true,
                  index: index,
                  onDelete: () => controller.removePdfAt(index),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
