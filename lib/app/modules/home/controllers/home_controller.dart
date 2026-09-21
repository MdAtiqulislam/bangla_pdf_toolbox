import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/device_pdf_scanner.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../data/models/reading_history_model.dart';
import '../../../data/models/tool_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/theme_controller.dart';

enum HomeSortOption { date, name, size }

class HomeController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final ThemeController _themeController = Get.find<ThemeController>();

  // Bottom Navigation Index (0: Tools, 1: Files, 2: Settings)
  final RxInt currentNavIndex = 0.obs;
  final selectedCategoryIndex = 0.obs;

  // Tools list for Tab 0
  final tools = <ToolModel>[
    const ToolModel(
      titleKey: AppStrings.imageToPdf,
      descriptionKey: AppStrings.imageToPdfDesc,
      icon: Icons.photo_library_rounded,
      gradient: AppColors.primaryGradient,
      route: AppRoutes.imageToPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.pdfToImage,
      descriptionKey: AppStrings.pdfToImageDesc,
      icon: Icons.image_search_rounded,
      gradient: AppColors.blueGradient,
      route: AppRoutes.pdfToImage,
    ),
    const ToolModel(
      titleKey: AppStrings.compressPdf,
      descriptionKey: AppStrings.compressPdfDesc,
      icon: Icons.compress_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.compressPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.signaturePdf,
      descriptionKey: AppStrings.signaturePdfDesc,
      icon: Icons.draw_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.signaturePdf,
    ),
    const ToolModel(
      titleKey: AppStrings.organizePdf,
      descriptionKey: AppStrings.organizePdfDesc,
      icon: Icons.layers_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.organizePdf,
    ),
    const ToolModel(
      titleKey: AppStrings.watermarkPdf,
      descriptionKey: AppStrings.watermarkPdfDesc,
      icon: Icons.branding_watermark_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFEA580C), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.watermarkPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.pageNumberPdf,
      descriptionKey: AppStrings.pageNumberPdfDesc,
      icon: Icons.format_list_numbered_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.pageNumberPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.textToPdf,
      descriptionKey: AppStrings.textToPdfDesc,
      icon: Icons.note_alt_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.textToPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.extractTextPdf,
      descriptionKey: AppStrings.extractTextPdfDesc,
      icon: Icons.document_scanner_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF34D399)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.extractTextPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.mergePdf,
      descriptionKey: AppStrings.mergePdfDesc,
      icon: Icons.merge_type_rounded,
      gradient: AppColors.greenGradient,
      route: AppRoutes.mergePdf,
    ),
    const ToolModel(
      titleKey: AppStrings.splitPdf,
      descriptionKey: AppStrings.splitPdfDesc,
      icon: Icons.call_split_rounded,
      gradient: AppColors.purpleGradient,
      route: AppRoutes.splitPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.metadataPdf,
      descriptionKey: AppStrings.metadataPdfDesc,
      icon: Icons.info_outline_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF475569), Color(0xFF64748B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.metadataPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.lockPdf,
      descriptionKey: AppStrings.lockPdfDesc,
      icon: Icons.lock_outline_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.lockPdf,
    ),
    const ToolModel(
      titleKey: AppStrings.pdfViewer,
      descriptionKey: AppStrings.pdfViewerDesc,
      icon: Icons.chrome_reader_mode_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: AppRoutes.pdfViewer,
    ),
  ].obs;

  List<ToolModel> get filteredTools {
    final idx = selectedCategoryIndex.value;
    if (idx == 1) {
      // Converter (Image to PDF, PDF to Image, Text to PDF)
      return tools.where((t) =>
        t.route == AppRoutes.imageToPdf ||
        t.route == AppRoutes.pdfToImage ||
        t.route == AppRoutes.textToPdf
      ).toList();
    } else if (idx == 2) {
      // Edit & Size (Compress, Signature, Watermark, Page Numbers)
      return tools.where((t) =>
        t.route == AppRoutes.compressPdf ||
        t.route == AppRoutes.signaturePdf ||
        t.route == AppRoutes.watermarkPdf ||
        t.route == AppRoutes.pageNumberPdf
      ).toList();
    } else if (idx == 3) {
      // Organize & Security (Organize, Merge, Split, Extract, Metadata, Lock, Viewer)
      return tools.where((t) =>
        t.route == AppRoutes.organizePdf ||
        t.route == AppRoutes.mergePdf ||
        t.route == AppRoutes.splitPdf ||
        t.route == AppRoutes.extractTextPdf ||
        t.route == AppRoutes.metadataPdf ||
        t.route == AppRoutes.lockPdf ||
        t.route == AppRoutes.pdfViewer
      ).toList();
    }
    return tools;
  }


  // File Manager & Scanner state (for Drawer and Files Tab)
  final RxList<PdfFileModel> devicePdfFiles = <PdfFileModel>[].obs;
  final RxList<PdfFileModel> filteredPdfFiles = <PdfFileModel>[].obs;
  final RxMap<String, PdfReadingHistoryModel> readingHistories = <String, PdfReadingHistoryModel>{}.obs;
  final RxSet<String> bookmarkedFilePaths = <String>{}.obs;
  final RxBool isScanning = false.obs;
  final RxInt selectedBrowserTab = 0.obs; // 0: All, 1: Recent, 2: Bookmarks
  final Rx<HomeSortOption> selectedSort = HomeSortOption.date.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Settings State
  final Rx<Locale> currentLocale = const Locale('bn', 'BD').obs;

  @override
  void onInit() {
    super.onInit();
    final savedLocale = _storageService.getLocale();
    currentLocale.value = savedLocale;
    scanDevicePdfs();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void changeNavIndex(int index) {
    currentNavIndex.value = index;
  }

  void onToolSelected(ToolModel tool) {
    if (tool.route.isNotEmpty) {
      Get.toNamed(tool.route);
    }
  }

  Future<void> scanDevicePdfs() async {
    try {
      isScanning.value = true;
      _loadReadingHistoriesAndBookmarks();
      final recent = _storageService.getRecentFiles();
      final scanned = await DevicePdfScanner.scanAllPdfs(extraPaths: recent);
      devicePdfFiles.assignAll(scanned);
      applyFilterAndSort();
    } catch (e) {
      debugPrint('HomeController: Error scanning PDFs: $e');
    } finally {
      isScanning.value = false;
    }
  }

  void _loadReadingHistoriesAndBookmarks() {
    final histories = _storageService.getAllReadingHistories();
    readingHistories.assignAll({for (var h in histories) h.path: h});
    final bookmarks = _storageService.getBookmarkedFiles();
    bookmarkedFilePaths.assignAll(bookmarks);
  }

  void switchTab(int index) {
    selectedBrowserTab.value = index;
    applyFilterAndSort();
  }

  void changeSort(HomeSortOption option) {
    selectedSort.value = option;
    applyFilterAndSort();
  }

  void filterPdfs(String query) {
    searchQuery.value = query.trim().toLowerCase();
    applyFilterAndSort();
  }

  void clearSearch() {
    searchController.clear();
    filterPdfs('');
  }

  void applyFilterAndSort() {
    List<PdfFileModel> list = [];

    switch (selectedBrowserTab.value) {
      case 1: // Recent
        list = devicePdfFiles
            .where((f) => readingHistories.containsKey(f.path))
            .toList();
        list.sort((a, b) {
          final hA = readingHistories[a.path]?.lastReadTime ?? DateTime(2000);
          final hB = readingHistories[b.path]?.lastReadTime ?? DateTime(2000);
          return hB.compareTo(hA);
        });
        break;
      case 2: // Bookmarks
        list = devicePdfFiles
            .where((f) => bookmarkedFilePaths.contains(f.path))
            .toList();
        break;
      case 0: // All
      default:
        list = List.from(devicePdfFiles);
        break;
    }

    if (searchQuery.value.isNotEmpty) {
      list = list.where((f) => f.fileName.toLowerCase().contains(searchQuery.value)).toList();
    }

    if (selectedBrowserTab.value != 1) {
      switch (selectedSort.value) {
        case HomeSortOption.name:
          list.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
          break;
        case HomeSortOption.size:
          list.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
          break;
        case HomeSortOption.date:
          list.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
          break;
      }
    }

    filteredPdfFiles.assignAll(list);
  }

  PdfFileModel? get mostRecentHistoryFile {
    if (readingHistories.isEmpty) return null;
    final sortedHist = readingHistories.values.toList()
      ..sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
    if (sortedHist.isEmpty) return null;
    final topPath = sortedHist.first.path;
    return devicePdfFiles.firstWhereOrNull((f) => f.path == topPath) ??
        PdfFileModel(
          id: topPath,
          path: topPath,
          fileName: sortedHist.first.title.isNotEmpty ? sortedHist.first.title : topPath.split('/').last,
          sizeInBytes: 0,
          modifiedDate: sortedHist.first.lastReadTime,
        );
  }

  void toggleBookmark(PdfFileModel file) {
    _storageService.toggleBookmarkedFile(file.path);
    _loadReadingHistoriesAndBookmarks();
    applyFilterAndSort();
  }

  void openPdfFile(PdfFileModel file) {
    Get.toNamed(
      AppRoutes.pdfViewer,
      arguments: {
        'pdfPath': file.path,
        'title': file.fileName,
      },
    );
  }

  Future<void> pickPdfFile() async {
    try {
      final context = Get.context;
      if (context == null) return;
      final results = await DevicePdfPickerSheet.show(context, isMultiSelect: false);
      if (results != null && results.isNotEmpty) {
        openPdfFile(results.first);
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
    }
  }

  // Settings helpers
  Future<void> changeLanguage(String langCode, String countryCode) async {
    final locale = Locale(langCode, countryCode);
    currentLocale.value = locale;
    Get.updateLocale(locale);
    await _storageService.saveLocale(locale);
  }

  void changeTheme(ThemeMode mode) {
    _themeController.setThemeMode(mode);
  }
}
