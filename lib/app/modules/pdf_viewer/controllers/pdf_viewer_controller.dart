import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as sf;
import '../../../core/constants/app_strings.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/device_pdf_scanner.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/device_pdf_picker_sheet.dart';
import '../../../data/models/pdf_file_model.dart';
import '../../../data/models/reading_history_model.dart';

enum ReaderTheme { day, sepia, night, oled }
enum SortOption { date, name, size }

class PdfViewerController extends GetxController {
  final PdfService _pdfService = Get.find<PdfService>();
  final StorageService _storageService = Get.find<StorageService>();

  final PageController pageViewController = PageController();
  final ScrollController listScrollController = ScrollController();

  // Diagnostics & Debug Logs
  final RxList<String> debugLogs = <String>[].obs;

  // File Browser state
  final RxInt selectedBrowserTab = 0.obs; // 0: All, 1: History, 2: Bookmarks
  final Rx<SortOption> selectedSort = SortOption.date.obs;
  final RxList<PdfFileModel> devicePdfFiles = <PdfFileModel>[].obs;
  final RxList<PdfFileModel> filteredPdfFiles = <PdfFileModel>[].obs;
  final RxMap<String, PdfReadingHistoryModel> readingHistories = <String, PdfReadingHistoryModel>{}.obs;
  final RxSet<String> bookmarkedFilePaths = <String>{}.obs;
  final RxBool isScanning = false.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Reader state
  final RxString pdfPath = ''.obs;
  final RxString pdfTitle = ''.obs;
  final Rxn<Uint8List> pdfBytes = Rxn<Uint8List>();
  final RxBool isLoading = false.obs;
  final RxBool hasLoadError = false.obs;
  final RxString loadErrorMessage = ''.obs;
  final RxInt pageCount = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxInt resumePageAvailable = 0.obs;
  final RxBool isDirectView = false.obs;
  final RxBool areToolbarsVisible = true.obs;

  // High-Definition Page Bitmaps Cache (100% Reliable Pure Flutter Rendering)
  final RxMap<int, Uint8List> pageBitmaps = <int, Uint8List>{}.obs;
  final Set<int> _renderingPages = {};
  final RxBool isBackgroundCaching = false.obs;

  // Reading Mode & Layout
  final Rx<sf.PdfPageLayoutMode> pageLayoutMode = sf.PdfPageLayoutMode.continuous.obs;
  final Rx<ReaderTheme> readerTheme = ReaderTheme.day.obs;

  // Bookmarks
  final RxList<int> bookmarkedPages = <int>[].obs;

  // In-document Search
  final RxBool isSearchOpen = false.obs;
  final TextEditingController docSearchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    logDebug('PdfViewerController initialized');

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['pdfPath'] != null) {
      isDirectView.value = true;
      loadPdf(args['pdfPath'] as String, title: args['title'] as String?);
      scanDevicePdfs();
    } else {
      scanDevicePdfs();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    docSearchController.dispose();
    pageViewController.dispose();
    listScrollController.dispose();
    super.onClose();
  }

  void logDebug(String message) {
    final time = DateTime.now().toIso8601String().split('T').last.split('.').first;
    final entry = '[$time] $message';
    debugLogs.insert(0, entry);
    if (debugLogs.length > 80) debugLogs.removeLast();
    debugPrint('PDF_DEBUG: $entry');
  }

  void clearDebugLogs() {
    debugLogs.clear();
    logDebug('Logs cleared');
  }

  // --- Device PDF File Scanner & History ---
  Future<void> scanDevicePdfs() async {
    try {
      isScanning.value = true;
      logDebug('Starting device storage scan for PDFs...');
      _loadReadingHistoriesAndBookmarks();

      final recent = _storageService.getRecentFiles();
      final scanned = await DevicePdfScanner.scanAllPdfs(extraPaths: recent);
      devicePdfFiles.assignAll(scanned);
      logDebug('Scanned ${scanned.length} PDF files from storage');
      applyFilterAndSort();
    } catch (e) {
      logDebug('Error scanning device PDFs: $e');
    } finally {
      isScanning.value = false;
    }
  }

  void _loadReadingHistoriesAndBookmarks() {
    final list = _storageService.getAllReadingHistories();
    final map = <String, PdfReadingHistoryModel>{};
    final bookmarksSet = <String>{};

    for (final h in list) {
      map[h.path] = h;
      final bm = _storageService.getDocumentBookmarks(h.path);
      if (bm.isNotEmpty) {
        bookmarksSet.add(h.path);
      }
    }
    readingHistories.assignAll(map);

    for (final path in _storageService.getRecentFiles()) {
      final bm = _storageService.getDocumentBookmarks(path);
      if (bm.isNotEmpty) {
        bookmarksSet.add(path);
      }
    }
    bookmarkedFilePaths.assignAll(bookmarksSet);
  }

  void setBrowserTab(int index) {
    selectedBrowserTab.value = index;
    applyFilterAndSort();
  }

  void setSortOption(SortOption option) {
    selectedSort.value = option;
    applyFilterAndSort();
  }

  void filterPdfs(String query) {
    searchQuery.value = query;
    applyFilterAndSort();
  }

  void applyFilterAndSort() {
    List<PdfFileModel> list = List.from(devicePdfFiles);

    if (selectedBrowserTab.value == 1) {
      list = list.where((f) => readingHistories.containsKey(f.path)).toList();
    } else if (selectedBrowserTab.value == 2) {
      list = list.where((f) => bookmarkedFilePaths.contains(f.path) || _storageService.getDocumentBookmarks(f.path).isNotEmpty).toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((f) => f.fileName.toLowerCase().contains(q)).toList();
    }

    switch (selectedSort.value) {
      case SortOption.date:
        list.sort((a, b) {
          final histA = readingHistories[a.path]?.lastReadTime;
          final histB = readingHistories[b.path]?.lastReadTime;
          final dateA = histA ?? a.modifiedDate;
          final dateB = histB ?? b.modifiedDate;
          return dateB.compareTo(dateA);
        });
        break;
      case SortOption.name:
        list.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
        break;
      case SortOption.size:
        list.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
        break;
    }

    filteredPdfFiles.assignAll(list);
  }

  void clearSearch() {
    searchController.clear();
    filterPdfs('');
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

  Future<void> openPdfFile(PdfFileModel file) async {
    await loadPdf(file.path, title: file.fileName);
  }

  Future<void> loadPdf(String path, {String? title}) async {
    try {
      isLoading.value = true;
      hasLoadError.value = false;
      loadErrorMessage.value = '';
      pageBitmaps.clear();
      _renderingPages.clear();
      logDebug('Attempting to open PDF: $path');

      final file = File(path);
      if (!await file.exists()) {
        hasLoadError.value = true;
        loadErrorMessage.value = 'PDF file not found at path: $path';
        logDebug('ERROR: File does not exist at $path');
        SnackbarHelper.showError(loadErrorMessage.value);
        return;
      }

      final fileSize = await file.length();
      logDebug('File verified! Size: $fileSize bytes (${FileUtils.formatBytes(fileSize)})');

      if (fileSize < 32) {
        hasLoadError.value = true;
        loadErrorMessage.value = 'This file is empty ($fileSize bytes) or corrupted. Please choose a valid PDF file.';
        logDebug('ERROR: File size too small ($fileSize bytes)');
        SnackbarHelper.showError(loadErrorMessage.value);
        return;
      }

      pdfPath.value = path;
      pdfTitle.value = title ?? file.uri.pathSegments.last;
      
      final bytes = await file.readAsBytes();
      pdfBytes.value = bytes;
      logDebug('Read ${bytes.length} bytes into memory');

      // Validate %PDF magic header
      if (bytes.length < 4 || bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46) {
        hasLoadError.value = true;
        loadErrorMessage.value = 'This file is not a valid PDF (%PDF header missing).';
        logDebug('ERROR: Missing %PDF magic header');
        SnackbarHelper.showError(loadErrorMessage.value);
        return;
      }

      final header = String.fromCharCodes(bytes.sublist(0, 5));
      logDebug('PDF Magic Header verified: $header');

      final count = await _pdfService.getPdfPageCount(path);
      pageCount.value = count > 0 ? count : 1;
      logDebug('Document page count: ${pageCount.value}');

      currentPage.value = 1;
      areToolbarsVisible.value = true;

      // 1. Restore Bookmarks
      final savedBookmarks = _storageService.getDocumentBookmarks(path);
      bookmarkedPages.assignAll(savedBookmarks);
      logDebug('Loaded ${savedBookmarks.length} bookmarks');

      // 2. Check Reading History for Auto-Resume
      final history = _storageService.getReadingHistory(path);
      if (history != null && history.lastReadPage > 1 && history.lastReadPage <= pageCount.value) {
        resumePageAvailable.value = history.lastReadPage;
        logDebug('Auto-resume found at page ${history.lastReadPage}');
      } else {
        resumePageAvailable.value = 0;
      }

      // 3. Render the initial target page immediately so user sees content in <0.05s
      final targetFirstPage = resumePageAvailable.value > 1 ? resumePageAvailable.value - 1 : 0;
      await _renderSinglePage(targetFirstPage);
      isLoading.value = false; // Dismiss loader immediately as first page is ready!

      // 4. In background, stream & cache all remaining pages
      _cacheAllPagesInBackground(bytes);

      // Save initial visit to history & recents
      await _storageService.saveReadingPosition(
        path: path,
        title: pdfTitle.value,
        page: targetFirstPage + 1,
        totalPages: pageCount.value,
      );
      currentPage.value = targetFirstPage + 1;
      logDebug('loadPdf completed successfully! Page $currentPage is visible.');
    } catch (e, stack) {
      hasLoadError.value = true;
      loadErrorMessage.value = 'Error loading PDF: $e';
      logDebug('CRITICAL loadPdf error: $e\n$stack');
      SnackbarHelper.showError(loadErrorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _renderSinglePage(int pageIndex) async {
    if (pageBitmaps.containsKey(pageIndex) || _renderingPages.contains(pageIndex)) return;
    if (pdfBytes.value == null) return;

    _renderingPages.add(pageIndex);
    try {
      await for (final page in Printing.raster(pdfBytes.value!, pages: [pageIndex], dpi: 180)) {
        final png = await page.toPng();
        pageBitmaps[pageIndex] = png;
        logDebug('Rendered Page ${pageIndex + 1} (${png.length} bytes PNG)');
        break;
      }
    } catch (e) {
      logDebug('Error rendering page ${pageIndex + 1}: $e');
    } finally {
      _renderingPages.remove(pageIndex);
    }
  }

  Future<void> _cacheAllPagesInBackground(Uint8List bytes) async {
    try {
      isBackgroundCaching.value = true;
      logDebug('Starting background caching of all pages at 180 DPI...');
      int index = 0;
      await for (final page in Printing.raster(bytes, dpi: 180)) {
        if (!pageBitmaps.containsKey(index)) {
          final png = await page.toPng();
          pageBitmaps[index] = png;
        }
        index++;
      }
      logDebug('All $index pages successfully cached in memory!');
    } catch (e) {
      logDebug('Background caching note: $e');
    } finally {
      isBackgroundCaching.value = false;
    }
  }

  void ensurePageRendered(int pageIndex) {
    if (!pageBitmaps.containsKey(pageIndex)) {
      _renderSinglePage(pageIndex);
    }
  }

  void onPageChanged(int index) {
    final page = index + 1;
    currentPage.value = page;
    _storageService.saveReadingPosition(
      path: pdfPath.value,
      title: pdfTitle.value,
      page: page,
      totalPages: pageCount.value,
    );
  }

  void closeReader() {
    logDebug('Closing reader');
    _loadReadingHistoriesAndBookmarks();
    if (isDirectView.value) {
      Get.back();
    } else {
      pdfBytes.value = null;
      pdfPath.value = '';
      pdfTitle.value = '';
      resumePageAvailable.value = 0;
      pageBitmaps.clear();
      _renderingPages.clear();
      applyFilterAndSort();
    }
  }

  void toggleToolbars() {
    areToolbarsVisible.value = !areToolbarsVisible.value;
  }

  // --- Reading Modes & Layout ---
  void setPageLayout(sf.PdfPageLayoutMode mode) {
    pageLayoutMode.value = mode;
  }

  void setReaderTheme(ReaderTheme theme) {
    readerTheme.value = theme;
  }

  void jumpToPage(int page) {
    if (page >= 1 && page <= (pageCount.value > 0 ? pageCount.value : 1)) {
      currentPage.value = page;
      ensurePageRendered(page - 1);

      if (pageLayoutMode.value == sf.PdfPageLayoutMode.single) {
        if (pageViewController.hasClients) {
          pageViewController.jumpToPage(page - 1);
        }
      } else {
        if (listScrollController.hasClients) {
          final targetOffset = (page - 1) * 600.0;
          listScrollController.animateTo(
            targetOffset.clamp(0.0, listScrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }

      _storageService.saveReadingPosition(
        path: pdfPath.value,
        title: pdfTitle.value,
        page: page,
        totalPages: pageCount.value,
      );
      logDebug('Jumped to page $page');
    }
  }

  // --- Bookmarks ---
  bool isPageBookmarked(int page) => bookmarkedPages.contains(page);


  void switchTab(int index) => setBrowserTab(index);
  void changeSort(SortOption option) => setSortOption(option);

  void togglePageLayout() {
    pageLayoutMode.value = pageLayoutMode.value == sf.PdfPageLayoutMode.continuous
        ? sf.PdfPageLayoutMode.single
        : sf.PdfPageLayoutMode.continuous;
  }

  void toggleBookmark(int page) {
    if (bookmarkedPages.contains(page)) {
      bookmarkedPages.remove(page);
    } else {
      bookmarkedPages.add(page);
      bookmarkedPages.sort();
    }
    _storageService.saveDocumentBookmarks(pdfPath.value, bookmarkedPages.toList());
  }

  void toggleBookmarkCurrentPage() {
    final page = currentPage.value;
    if (bookmarkedPages.contains(page)) {
      bookmarkedPages.remove(page);
      SnackbarHelper.showInfo('${AppStrings.removeBookmark.tr}: Page $page');
    } else {
      bookmarkedPages.add(page);
      bookmarkedPages.sort();
      SnackbarHelper.showSuccess('${AppStrings.addBookmark.tr}: Page $page');
    }
    _storageService.saveDocumentBookmarks(pdfPath.value, bookmarkedPages.toList());
    _loadReadingHistoriesAndBookmarks();
  }

  // --- File Actions ---
  Future<void> pickPdfFile() async {
    try {
      final context = Get.context;
      if (context == null) return;

      final results = await DevicePdfPickerSheet.show(
        context,
        isMultiSelect: false,
      );

      if (results != null && results.isNotEmpty) {
        final pdf = results.first;
        await loadPdf(pdf.path, title: pdf.fileName);
        scanDevicePdfs();
      }
    } catch (e) {
      SnackbarHelper.showError('Error selecting PDF: $e');
    }
  }

  Future<void> openSamplePdf() async {
    try {
      isLoading.value = true;
      logDebug('Generating verified sample PDF...');
      final sample = await _pdfService.createSamplePdf();
      logDebug('Sample PDF created at: ${sample.path}');
      await loadPdf(sample.path, title: sample.fileName);
      scanDevicePdfs();
    } catch (e) {
      logDebug('Error creating sample PDF: $e');
      SnackbarHelper.showError('Error creating sample PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveToDownloads() async {
    if (pdfPath.value.isEmpty) return;
    try {
      final file = File(pdfPath.value);
      if (!await file.exists()) return;
      final savedFile = await FileUtils.saveToPublicDownloads(file);
      SnackbarHelper.showSuccess('${AppStrings.savedToDownloads.tr}\n${savedFile.path}');
      scanDevicePdfs();
    } catch (e) {
      SnackbarHelper.showError('Error saving PDF: $e');
    }
  }

  Future<void> sharePdf() async {
    if (pdfPath.value.isEmpty) return;
    try {
      await Share.shareXFiles([XFile(pdfPath.value)], text: pdfTitle.value);
    } catch (e) {
      SnackbarHelper.showError('Error sharing PDF: $e');
    }
  }

  Future<void> printPdf() async {
    if (pdfBytes.value == null && pdfPath.value.isNotEmpty) {
      final file = File(pdfPath.value);
      if (await file.exists()) {
        pdfBytes.value = await file.readAsBytes();
      }
    }
    if (pdfBytes.value == null) return;
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes.value!,
        name: pdfTitle.value,
      );
    } catch (e) {
      SnackbarHelper.showError('Error printing PDF: $e');
    }
  }

  Future<void> openExternal() async {
    if (pdfPath.value.isEmpty) return;
    try {
      await OpenFilex.open(pdfPath.value);
    } catch (e) {
      SnackbarHelper.showError('Error opening in external app: $e');
    }
  }
}
