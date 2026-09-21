import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/image_filter_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/file_tile.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controllers/image_to_pdf_controller.dart';
import 'image_filter_dialog.dart';
import '../widgets/pdf_config_sheet.dart';

class ImageToPdfView extends GetView<ImageToPdfController> {
  const ImageToPdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: AppStrings.imageToPdf.tr,
            extraActions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: AppStrings.pdfSettings.tr,
                onPressed: () {
                  Get.bottomSheet(
                    const PdfConfigSheet(),
                    isScrollControlled: true,
                  );
                },
              ),
              Obx(() {
                if (controller.selectedImages.isEmpty) return const SizedBox.shrink();
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
                    if (controller.selectedImages.isEmpty) {
                      return _buildEmptyState(context, isDark);
                    }
                    return _buildSelectedImagesList(context, isDark);
                  }),
                ),
                // Bottom Actions & Banner
                Container(
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
                      // Document Name Input
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
                              text: AppStrings.addMoreImages.tr,
                              icon: Icons.add_photo_alternate_rounded,
                              isOutlined: true,
                              onPressed: () => _showPickerOptions(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: AppStrings.generatePdf.tr,
                              icon: Icons.picture_as_pdf_rounded,
                              onPressed: () => controller.generatePdf(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
        // Loading Overlay
        Obx(() {
          if (controller.isLoading.value) {
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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.noImagesSelected.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.imageToPdfDesc.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => controller.pickFromCamera(),
                  icon: const Icon(Icons.document_scanner_rounded, size: 20),
                  label: Text(AppStrings.smartScan.tr),
                ),
                OutlinedButton.icon(
                  onPressed: () => controller.pickFromGallery(),
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  label: Text(AppStrings.fromGallery.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagesList(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Quick Filters Bar (CamScanner Style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.docFilter.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${controller.selectedImages.length} ${Get.locale?.languageCode == 'bn' ? 'টি ছবি' : 'images'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(DocFilterType.original, AppStrings.original.tr, isDark),
                    _buildFilterChip(DocFilterType.magicColor, AppStrings.magicColor.tr, isDark),
                    _buildFilterChip(DocFilterType.blackAndWhite, AppStrings.blackAndWhite.tr, isDark),
                    _buildFilterChip(DocFilterType.brighten, AppStrings.brighten.tr, isDark),
                    _buildFilterChip(DocFilterType.grayscale, AppStrings.grayscale.tr, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Reorder & Tip Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.primary.withValues(alpha: 0.06),
          child: Row(
            children: [
              const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStrings.reorderTip.tr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reorderable list
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.selectedImages.length,
              onReorder: (oldIndex, newIndex) => controller.reorderImages(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final image = controller.selectedImages[index];
                return FileTile(
                  key: ValueKey(image.id),
                  title: image.fileName,
                  sizeInBytes: image.sizeInBytes,
                  imagePath: image.path,
                  isReorderable: true,
                  index: index,
                  badgeText: _getFilterBadge(image.filterType),
                  onTap: () => _openFilterDialog(context, index, image),
                  onEdit: () => _openFilterDialog(context, index, image),
                  onDelete: () => controller.removeImageAt(index),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(DocFilterType type, String label, bool isDark) {
    return Obx(() {
      final isSelected = controller.defaultFilter.value == type;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => controller.applyFilterToAll(type),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      );
    });
  }

  String? _getFilterBadge(DocFilterType type) {
    switch (type) {
      case DocFilterType.magicColor:
        return 'Magic ✨';
      case DocFilterType.blackAndWhite:
        return 'B&W 📄';
      case DocFilterType.brighten:
        return 'Bright ☀️';
      case DocFilterType.grayscale:
        return 'Gray 🔘';
      case DocFilterType.original:
        return null;
    }
  }

  void _openFilterDialog(BuildContext context, int index, dynamic image) {
    ImageFilterDialog.show(
      context,
      image: image,
      onApply: (updated) => controller.updateImageAt(index, updated),
      onApplyToAll: (filter) => controller.applyFilterToAll(filter),
    );
  }

  void _showPickerOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary),
              ),
              title: Text(
                AppStrings.fromCamera.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                AppStrings.smartScanDesc.tr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              onTap: () {
                Get.back();
                controller.pickFromCamera();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
              ),
              title: Text(
                AppStrings.fromGallery.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Get.back();
                controller.pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}
