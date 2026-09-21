import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/organize_pdf_controller.dart';

class OrganizePdfView extends GetView<OrganizePdfController> {
  const OrganizePdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.organizePdf.tr,
        showActions: false,
        extraActions: [
          Obx(() {
            if (controller.selectedPdf.value == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: AppStrings.resetPages.tr,
              onPressed: () => controller.resetPages(),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isSaving.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('PDF সাজিয়ে সেভ করা হচ্ছে...', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }

                if (controller.selectedPdf.value == null) {
                  return _buildFilePickerPlaceholder(context, isDark);
                }

                if (controller.isRendering.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('পেজের থাম্বনেইল তৈরি হচ্ছে...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tip bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.dragToReorder.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          Text(
                            '${controller.pageIndices.length} Pages',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                    // Drag-and-drop Reorderable Grid
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: controller.pageIndices.length,
                          onReorder: (oldIdx, newIdx) => controller.reorderPages(oldIdx, newIdx),
                          itemBuilder: (context, index) {
                            final pageIdx = controller.pageIndices[index];
                            final thumbnail = controller.pageThumbnails[pageIdx];
                            final rot = controller.pageRotations[pageIdx] ?? 0;

                            return Container(
                              key: ValueKey(pageIdx),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Drag Handle & Position Indicator
                                  Container(
                                    width: 32,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '#${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Thumbnail Preview
                                  Container(
                                    width: 50,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: thumbnail != null
                                          ? RotatedBox(
                                              quarterTurns: (rot / 90).round(),
                                              child: Image.memory(thumbnail, fit: BoxFit.cover),
                                            )
                                          : const Center(child: Icon(Icons.picture_as_pdf_rounded, color: Colors.grey, size: 20)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Page ${pageIdx + 1}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Rotation: $rot°',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions: Rotate & Delete
                                  IconButton(
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.rotate_right_rounded, color: AppColors.primary, size: 20),
                                    tooltip: AppStrings.rotatePage.tr,
                                    onPressed: () => controller.rotatePage(pageIdx),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    tooltip: AppStrings.deletePage.tr,
                                    onPressed: () => controller.deletePage(pageIdx),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
                      elevation: 2,
                    ),
                    onPressed: () => controller.saveOrganizedPdf(),
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      AppStrings.saveOrganized.tr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
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
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.layers_outlined, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'পেজ সাজানোর জন্য PDF বাছুন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Reorder, rotate and delete pages', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
