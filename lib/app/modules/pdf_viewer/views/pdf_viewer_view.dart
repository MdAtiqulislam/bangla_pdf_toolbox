import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as sf;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../data/models/pdf_file_model.dart';
import '../controllers/pdf_viewer_controller.dart';

class PdfViewerView extends GetView<PdfViewerController> {
  const PdfViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isReading = controller.pdfPath.value.isNotEmpty;

      return PopScope(
        canPop: controller.isDirectView.value || !isReading,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && isReading) {
            controller.closeReader();
          }
        },
        child: Scaffold(
          // Professional Adobe/Chrome Slate backdrop for PDF reading
          backgroundColor: isReading
              ? (isDark ? const Color(0xFF181A1B) : const Color(0xFF383C40))
              : (isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA)),
          appBar: isReading
              ? _buildModernReaderAppBar(context, isDark)
              : _buildScannerAppBar(context, isDark),
          body: SafeArea(
            child: isReading
                ? _buildReaderBody(context, isDark)
                : _buildHubBody(context, isDark),
          ),
          floatingActionButton: !isReading
              ? FloatingActionButton.extended(
                  onPressed: () => controller.pickPdfFile(),
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  icon: const Icon(Icons.file_open_rounded, color: Colors.white),
                  label: Text(
                    AppStrings.pickOtherPdf.tr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                )
              : null,
        ),
      );
    });
  }

  // ==========================================
  //            READER VIEW & CONTROLS
  // ==========================================

  Widget _buildReaderBody(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Main PDF Viewport
        Positioned.fill(
          child: _buildModernReaderViewport(context, isDark),
        ),

        // Floating Top-Right Bookmark Ribbon 🎗️
        Obx(() {
          final isBookmarked = controller.isPageBookmarked(controller.currentPage.value);
          return Positioned(
            top: 0,
            right: 20,
            child: GestureDetector(
              onTap: () => controller.toggleBookmarkCurrentPage(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: isBookmarked ? 48 : 36,
                decoration: BoxDecoration(
                  color: isBookmarked ? const Color(0xFFFF9800) : Colors.black.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          );
        }),

        // Floating Bottom Glass Dock
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: _buildFloatingBottomGlassDock(context, isDark),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildModernReaderAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 2,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 24),
        tooltip: 'ফিরে যান',
        onPressed: () {
          if (controller.isDirectView.value) {
            Get.back();
          } else {
            controller.closeReader();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.pdfTitle.value.isNotEmpty
                ? controller.pdfTitle.value
                : AppStrings.pdfViewer.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          Obx(() {
            final current = controller.currentPage.value;
            final total = controller.pageCount.value;
            return Text(
              '$current of $total pages',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            );
          }),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: AppStrings.appearance.tr,
          onPressed: () => _showAppearanceSheet(context, isDark),
        ),
        IconButton(
          icon: const Icon(Icons.bookmarks_rounded),
          tooltip: AppStrings.bookmarks.tr,
          onPressed: () => _showNavigationSheet(context, isDark),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) {
            switch (val) {
              case 'save':
                controller.saveToDownloads();
                break;
              case 'share':
                controller.sharePdf();
                break;
              case 'print':
                controller.printPdf();
                break;
              case 'external':
                controller.openExternal();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'save',
              child: ListTile(
                leading: const Icon(Icons.download_rounded, size: 20, color: AppColors.primary),
                title: Text(AppStrings.saveToDownloads.tr),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(Icons.share_rounded, size: 20, color: Colors.blue),
                title: Text(AppStrings.sharePdf.tr),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: ListTile(
                leading: Icon(Icons.print_rounded, size: 20, color: Colors.teal),
                title: Text('Print Document'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'external',
              child: ListTile(
                leading: Icon(Icons.open_in_new_rounded, size: 20, color: Colors.purple),
                title: Text('Open with other app'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernReaderViewport(BuildContext context, bool isDark) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Loading document...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      }

      if (controller.hasLoadError.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  controller.loadErrorMessage.value.isNotEmpty
                      ? controller.loadErrorMessage.value
                      : 'Failed to display PDF',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => controller.loadPdf(controller.pdfPath.value, title: controller.pdfTitle.value),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => controller.pickPdfFile(),
                      icon: const Icon(Icons.folder_open_rounded, color: Colors.white),
                      label: const Text('Choose PDF', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      final totalPages = controller.pageCount.value > 0 ? controller.pageCount.value : 1;
      final isContinuous = controller.pageLayoutMode.value == sf.PdfPageLayoutMode.continuous;

      if (isContinuous) {
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: ListView.builder(
            controller: controller.listScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            itemCount: totalPages,
            itemBuilder: (context, index) {
              return _buildContinuousPageCard(context, index, totalPages, isDark);
            },
          ),
        );
      }

      return PageView.builder(
        controller: controller.pageViewController,
        itemCount: totalPages,
        onPageChanged: (index) => controller.onPageChanged(index + 1),
        itemBuilder: (context, index) {
          return _buildSinglePageCard(context, index, totalPages, isDark);
        },
      );
    });
  }

  Widget _buildContinuousPageCard(BuildContext context, int index, int totalPages, bool isDark) {
    return Obx(() {
      final bitmap = controller.pageBitmaps[index];

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: bitmap != null
              ? _applyThemeToImage(
                  Image.memory(
                    bitmap,
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    gaplessPlayback: true,
                  ),
                )
              : AspectRatio(
                  aspectRatio: 1 / 1.414,
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Loading Page ${index + 1}...',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildSinglePageCard(BuildContext context, int index, int totalPages, bool isDark) {
    return Obx(() {
      final bitmap = controller.pageBitmaps[index];

      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        clipBehavior: Clip.none,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: bitmap != null
                    ? _applyThemeToImage(
                        Image.memory(
                          bitmap,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: 1 / 1.414,
                        child: Container(
                          color: Colors.white,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading Page ${index + 1}...',
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _applyThemeToImage(Widget imageWidget) {
    switch (controller.readerTheme.value) {
      case ReaderTheme.sepia:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.9, 0.0, 0.0, 0.0, 30.0,
            0.0, 0.8, 0.0, 0.0, 20.0,
            0.0, 0.0, 0.6, 0.0, 10.0,
            0.0, 0.0, 0.0, 1.0, 0.0,
          ]),
          child: imageWidget,
        );
      case ReaderTheme.night:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -0.85, 0.0, 0.0, 0.0, 220.0,
            0.0, -0.85, 0.0, 0.0, 220.0,
            0.0, 0.0, -0.85, 0.0, 220.0,
            0.0, 0.0, 0.0, 1.0, 0.0,
          ]),
          child: imageWidget,
        );
      case ReaderTheme.oled:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -1.0, 0.0, 0.0, 0.0, 255.0,
            0.0, -1.0, 0.0, 0.0, 255.0,
            0.0, 0.0, -1.0, 0.0, 255.0,
            0.0, 0.0, 0.0, 1.0, 0.0,
          ]),
          child: imageWidget,
        );
      case ReaderTheme.day:
        return imageWidget;
    }
  }

  // Floating Bottom Glass Dock
  Widget _buildFloatingBottomGlassDock(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E2022).withValues(alpha: 0.90)
                : const Color(0xFF2A2D32).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Jump / Page Indicator
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showJumpToPageDialog(context, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(() {
                    final curr = controller.currentPage.value;
                    final total = controller.pageCount.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.import_contacts_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '$curr / $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),

              // Page Slider
              Expanded(
                child: Obx(() {
                  final total = controller.pageCount.value;
                  if (total <= 1) return const SizedBox.shrink();
                  final current = controller.currentPage.value.clamp(1, total).toDouble();

                  return SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: current,
                      min: 1,
                      max: total.toDouble(),
                      divisions: total > 1 ? total - 1 : 1,
                      onChanged: (val) {
                        controller.jumpToPage(val.toInt());
                      },
                    ),
                  );
                }),
              ),

              // Layout Switcher (Continuous vs Single)
              Obx(() {
                final isCont = controller.pageLayoutMode.value == sf.PdfPageLayoutMode.continuous;
                return IconButton(
                  icon: Icon(
                    isCont ? Icons.view_day_rounded : Icons.view_carousel_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: isCont ? 'Continuous View' : 'Single Page View',
                  onPressed: () => controller.togglePageLayout(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  //            SHEETS & DIALOGS
  // ==========================================

  void _showAppearanceSheet(BuildContext context, bool isDark) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.appearance.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text('কালার থিম / রিডিং মোড', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThemeChoice('স্বাভাবিক', ReaderTheme.day, const Color(0xFFFFFFFF), Colors.black87),
                _buildThemeChoice('সেপিয়া', ReaderTheme.sepia, const Color(0xFFFBF0D9), const Color(0xFF5F4B32)),
                _buildThemeChoice('ডার্ক', ReaderTheme.night, const Color(0xFF2C2C2E), Colors.white),
                _buildThemeChoice('OLED', ReaderTheme.oled, const Color(0xFF000000), Colors.white),
              ],
            )),
            const SizedBox(height: 20),
            const Text('পেজ স্ক্রোলিং মোড', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Obx(() {
              final isCont = controller.pageLayoutMode.value == sf.PdfPageLayoutMode.continuous;
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isCont ? AppColors.primary.withValues(alpha: 0.15) : null,
                        side: BorderSide(color: isCont ? AppColors.primary : Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        controller.pageLayoutMode.value = sf.PdfPageLayoutMode.continuous;
                        Get.back();
                      },
                      icon: const Icon(Icons.view_day_rounded, size: 18),
                      label: const Text('ধারাবাহিক (Continuous)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !isCont ? AppColors.primary.withValues(alpha: 0.15) : null,
                        side: BorderSide(color: !isCont ? AppColors.primary : Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        controller.pageLayoutMode.value = sf.PdfPageLayoutMode.single;
                        Get.back();
                      },
                      icon: const Icon(Icons.view_carousel_rounded, size: 18),
                      label: const Text('একক পেজ (Single)'),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChoice(String label, ReaderTheme theme, Color bg, Color text) {
    final isSelected = controller.readerTheme.value == theme;
    return GestureDetector(
      onTap: () {
        controller.readerTheme.value = theme;
        Get.back();
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.4),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showNavigationSheet(BuildContext context, bool isDark) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.bookmarks.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => controller.toggleBookmarkCurrentPage(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('বর্তমান পেজ যোগ করুন'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final bms = controller.bookmarkedPages;
              if (bms.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('কোনো বুকমার্ক যোগ করা হয়নি', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: bms.length,
                  itemBuilder: (context, idx) {
                    final page = bms[idx];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.bookmark_rounded, color: Colors.orange),
                      title: Text('Page $page', style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                        onPressed: () => controller.toggleBookmark(page),
                      ),
                      onTap: () {
                        Get.back();
                        controller.jumpToPage(page);
                      },
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showJumpToPageDialog(BuildContext context, bool isDark) {
    final textController = TextEditingController(text: '${controller.currentPage.value}');
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.jumpToPage.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('১ থেকে ${controller.pageCount.value} পর্যন্ত পেজ নম্বর দিন'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppStrings.cancel.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final num = int.tryParse(textController.text);
              if (num != null && num >= 1 && num <= controller.pageCount.value) {
                Get.back();
                controller.jumpToPage(num);
              }
            },
            child: Text(AppStrings.confirm.tr),
          ),
        ],
      ),
    );
  }

  // ==========================================
  //            HUB / BROWSER SCREEN
  // ==========================================

  PreferredSizeWidget _buildScannerAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        AppStrings.allPdfs.tr,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 24),
        tooltip: 'ফিরে যান',
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: AppStrings.rescan.tr,
          onPressed: () => controller.scanDevicePdfs(),
        ),
        IconButton(
          icon: const Icon(Icons.folder_open_rounded),
          tooltip: AppStrings.pickOtherPdf.tr,
          onPressed: () => controller.pickPdfFile(),
        ),
      ],
    );
  }

  Widget _buildHubBody(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: TextField(
            controller: controller.searchController,
            onChanged: (val) => controller.filterPdfs(val),
            decoration: InputDecoration(
              hintText: AppStrings.searchPdf.tr,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => controller.clearSearch(),
                );
              }),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
          ),
        ),

        // Tabs & Sort Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabChip('সকল (${controller.devicePdfFiles.length})', 0, isDark),
                      const SizedBox(width: 8),
                      _buildTabChip('রিসেন্ট (${controller.readingHistories.length})', 1, isDark),
                      const SizedBox(width: 8),
                      _buildTabChip('বুকমার্ক (${controller.bookmarkedFilePaths.length})', 2, isDark),
                    ],
                  ),
                )),
              ),
              // Sort Menu
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort_rounded, size: 20),
                tooltip: 'সাজান',
                onSelected: (opt) => controller.changeSort(opt),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: SortOption.date, child: Text('তারিখ অনুযায়ী')),
                  const PopupMenuItem(value: SortOption.name, child: Text('নাম অনুযায়ী')),
                  const PopupMenuItem(value: SortOption.size, child: Text('সাইজ অনুযায়ী')),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // File List / Recent reading Banner
        Expanded(
          child: Obx(() {
            if (controller.isScanning.value && controller.devicePdfFiles.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('ডিভাইস স্ক্যান করা হচ্ছে...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              );
            }

            final files = controller.filteredPdfFiles;

            if (files.isEmpty) {
              return _buildEmptyState(isDark);
            }

            final recentPdf = controller.mostRecentHistoryFile;

            return RefreshIndicator(
              onRefresh: () => controller.scanDevicePdfs(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: files.length + (recentPdf != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (recentPdf != null && index == 0) {
                    return _buildRecentReadingCard(context, recentPdf, isDark);
                  }

                  final fileIndex = recentPdf != null ? index - 1 : index;
                  final pdf = files[fileIndex];
                  return _buildPdfCard(context, pdf, isDark);
                },
              ),
            );
          }),
        ),

        const AdBannerWidget(),
      ],
    );
  }

  Widget _buildTabChip(String label, int index, bool isDark) {
    final isSelected = controller.selectedBrowserTab.value == index;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.switchTab(index),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
      ),
    );
  }

  Widget _buildRecentReadingCard(BuildContext context, PdfFileModel pdf, bool isDark) {
    final history = controller.readingHistories[pdf.path];
    if (history == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                AppStrings.readingHistory.tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pdf.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: history.progressPercentage,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Page ${history.lastReadPage} of ${history.totalPages}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => controller.openPdfFile(pdf),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: Text(
                  AppStrings.resumeReading.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(BuildContext context, PdfFileModel pdf, bool isDark) {
    final isFromAppFolder = pdf.path.contains(FileUtils.appFolderName);
    final history = controller.readingHistories[pdf.path];
    final isBookmarked = controller.bookmarkedFilePaths.contains(pdf.path);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFromAppFolder
              ? AppColors.primary.withValues(alpha: 0.35)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isFromAppFolder ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.openPdfFile(pdf),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isFromAppFolder
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              FileUtils.formatBytes(pdf.sizeInBytes),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                FileUtils.formatDate(pdf.modifiedDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isBookmarked)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.bookmark_rounded, color: Colors.orange, size: 18),
                    ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),

              // Progress Bar if History exists
              if (history != null && history.lastReadPage > 1 && history.totalPages > 1) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: history.progressPercentage,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${history.lastReadPage}/${history.totalPages} ${AppStrings.pageProgress.tr}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '${(history.progressPercentage * 100).toInt()}% ${AppStrings.readProgress.tr}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.noPdfFound.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.noPdfFoundDesc.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.scanDevicePdfs(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(AppStrings.rescan.tr),
                ),
                ElevatedButton.icon(
                  onPressed: () => controller.pickPdfFile(),
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(AppStrings.pickOtherPdf.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
