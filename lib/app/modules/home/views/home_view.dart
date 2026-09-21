import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';
import '../widgets/tool_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      drawer: _buildHomeDrawer(context, isDark),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        centerTitle: false,
        leading: Builder(
          builder: (scaffoldCtx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24),
            tooltip: 'ড্রয়ার মেনু',
            onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppStrings.appName.tr,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: AppStrings.rescan.tr,
            onPressed: () => controller.scanDevicePdfs(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings.tr,
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sleek Mini Header with PDF count & Quick Open
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bangla PDF ToolBox',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Obx(() => Text(
                                  '${controller.devicePdfFiles.length}টি PDF ডিভাইসে পাওয়া গেছে',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 11),
                                )),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () => Get.toNamed(AppRoutes.pdfViewer),
                            icon: const Icon(Icons.chrome_reader_mode_rounded, size: 16),
                            label: const Text('রিডার', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Modern Category Filter Tabs
                    _buildCategoryTabs(context, isDark),
                    const SizedBox(height: 12),

                    // Compact Grid of Filtered Tools
                    Obx(() {
                      final list = controller.filteredTools;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 3 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: isTablet ? 1.25 : 1.18,
                        ),
                        itemBuilder: (context, index) {
                          final tool = list[index];
                          return ToolCard(
                            tool: tool,
                            onTap: () => controller.onToolSelected(tool),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Bottom Banner Ad
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, bool isDark) {
    final categories = [
      {'label': 'সকল টুল', 'icon': Icons.apps_rounded},
      {'label': 'কনভার্টার', 'icon': Icons.transform_rounded},
      {'label': 'এডিট ও সাইজ', 'icon': Icons.edit_note_rounded},
      {'label': 'অর্গানাইজ', 'icon': Icons.folder_copy_rounded},
    ];

    return Obx(() {
      final selectedIdx = controller.selectedCategoryIndex.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(categories.length, (index) {
            final isSelected = selectedIdx == index;
            final item = categories[index];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.selectedCategoryIndex.value = index,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCard : const Color(0xFFF1F3F5)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : Colors.transparent),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  // ==========================================
  //            NAVIGATION DRAWER
  // ==========================================

  Widget _buildHomeDrawer(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.82).clamp(280.0, 360.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.appName.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Obx(() => Text(
                    '${controller.devicePdfFiles.length}টি PDF ডকুমেন্ট পাওয়া গেছে',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  )),
                ],
              ),
            ),

            // Search Bar inside Drawer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                ),
                child: TextField(
                  controller: controller.searchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: AppStrings.searchPdf.tr,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primary),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => controller.clearSearch(),
                          )
                        : const SizedBox.shrink()),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // Category Filter Chips in Drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDrawerCategoryChip('all', 'সকল', isDark),
                    const SizedBox(width: 6),
                    _buildDrawerCategoryChip('recent', 'রিসেন্ট', isDark),
                    const SizedBox(width: 6),
                    _buildDrawerCategoryChip('bookmarked', 'বুকমার্ক', isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

            // PDF List inside Drawer
            Expanded(
              child: Obx(() {
                if (controller.isScanning.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text('সকল PDF স্ক্যান হচ্ছে...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                final pdfs = controller.filteredPdfFiles;
                if (pdfs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.noPdfFound.tr,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => controller.scanDevicePdfs(),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(AppStrings.rescan.tr, style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: pdfs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 56,
                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final pdf = pdfs[index];
                    return _buildDrawerPdfItem(context, pdf, isDark);
                  },
                );
              }),
            ),

            // Drawer Bottom Section: Quick Links
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.primary),
                    ),
                    title: Text(
                      AppStrings.pickOtherPdf.tr,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(context);
                      controller.pickPdfFile();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerCategoryChip(String categoryKey, String label, bool isDark) {
    return Obx(() {
      final isSelected = controller.selectedBrowserTab.value == (categoryKey == "all" ? 0 : (categoryKey == "recent" ? 1 : 2));
      return FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        checkmarkColor: AppColors.primary,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        onSelected: (_) => controller.switchTab(categoryKey == "all" ? 0 : (categoryKey == "recent" ? 1 : 2)),
      );
    });
  }

  Widget _buildDrawerPdfItem(BuildContext context, dynamic pdf, bool isDark) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
      ),
      title: Text(
        pdf.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        pdf.sizeInBytes > 0 ? FileUtils.formatBytes(pdf.sizeInBytes) : '',
        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
      trailing: IconButton(
        icon: Icon(
          controller.bookmarkedFilePaths.contains(pdf.path) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 18,
          color: controller.bookmarkedFilePaths.contains(pdf.path) ? Colors.amber : Colors.grey,
        ),
        onPressed: () => controller.toggleBookmark(pdf),
      ),
      onTap: () {
        Navigator.pop(context);
        controller.openPdfFile(pdf);
      },
    );
  }
}
