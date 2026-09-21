import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/pdf_file_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../services/storage_service.dart';
import '../utils/device_pdf_scanner.dart';
import '../utils/file_utils.dart';

class DevicePdfPickerSheet extends StatefulWidget {
  final bool isMultiSelect;
  final String? title;
  final List<String>? initialSelectedPaths;

  const DevicePdfPickerSheet({
    super.key,
    this.isMultiSelect = false,
    this.title,
    this.initialSelectedPaths,
  });

  static Future<List<PdfFileModel>?> show(
    BuildContext context, {
    bool isMultiSelect = false,
    String? title,
    List<String>? initialSelectedPaths,
  }) async {
    return await showModalBottomSheet<List<PdfFileModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DevicePdfPickerSheet(
        isMultiSelect: isMultiSelect,
        title: title,
        initialSelectedPaths: initialSelectedPaths,
      ),
    );
  }

  @override
  State<DevicePdfPickerSheet> createState() => _DevicePdfPickerSheetState();
}

class _DevicePdfPickerSheetState extends State<DevicePdfPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<PdfFileModel> _allPdfs = [];
  List<PdfFileModel> _filteredPdfs = [];
  final Set<String> _selectedPaths = {};
  final Map<String, PdfFileModel> _selectedModels = {};
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedPaths != null) {
      _selectedPaths.addAll(widget.initialSelectedPaths!);
    }
    _scanPdfs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanPdfs() async {
    setState(() => _isScanning = true);
    try {
      List<String>? recent;
      if (Get.isRegistered<StorageService>()) {
        recent = Get.find<StorageService>().getRecentFiles();
      }
      final results = await DevicePdfScanner.scanAllPdfs(extraPaths: recent);
      if (mounted) {
        setState(() {
          _allPdfs = results;
          _filterPdfs(_searchController.text);
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _filterPdfs(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredPdfs = List.from(_allPdfs);
    } else {
      _filteredPdfs = _allPdfs.where((f) => f.fileName.toLowerCase().contains(q)).toList();
    }
  }

  void _toggleSelection(PdfFileModel pdf) {
    if (!widget.isMultiSelect) {
      Navigator.of(context).pop([pdf]);
      return;
    }

    setState(() {
      if (_selectedPaths.contains(pdf.path)) {
        _selectedPaths.remove(pdf.path);
        _selectedModels.remove(pdf.path);
      } else {
        _selectedPaths.add(pdf.path);
        _selectedModels[pdf.path] = pdf;
      }
    });
  }

  Future<void> _browseSystemStorage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: widget.isMultiSelect,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        final List<PdfFileModel> picked = [];
        for (final f in result.files) {
          if (f.path != null) {
            picked.add(
              PdfFileModel(
                id: '${DateTime.now().millisecondsSinceEpoch}_${f.name}',
                path: f.path!,
                fileName: f.name,
                sizeInBytes: f.size,
                modifiedDate: DateTime.now(),
              ),
            );
          }
        }
        if (picked.isNotEmpty) {
          Navigator.of(context).pop(picked);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBn = Get.locale?.languageCode == 'bn';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Title & Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title ??
                        (widget.isMultiSelect
                            ? (isBn ? 'PDF নির্বাচন করুন' : 'Select PDF Files')
                            : (isBn ? 'PDF ফাইল বাছুন' : 'Select a PDF File')),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: AppStrings.rescan.tr,
                  onPressed: _scanPdfs,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filterPdfs(val)),
              decoration: InputDecoration(
                hintText: AppStrings.searchPdf.tr,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterPdfs(''));
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
              ),
            ),
          ),

          // Info Bar / Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isScanning)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.scanningPdfs.tr,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  )
                else
                  Text(
                    isBn
                        ? '${_filteredPdfs.length} টি PDF পাওয়া গেছে'
                        : '${_filteredPdfs.length} PDFs discovered',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                InkWell(
                  onTap: _browseSystemStorage,
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.pickOtherPdf.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PDF List View
          Expanded(
            child: _isScanning && _allPdfs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredPdfs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.find_in_page_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(AppStrings.noPdfFound.tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _browseSystemStorage,
                              icon: const Icon(Icons.folder_open_rounded, size: 18),
                              label: Text(AppStrings.pickOtherPdf.tr),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _filteredPdfs.length,
                        itemBuilder: (context, index) {
                          final pdf = _filteredPdfs[index];
                          final isSelected = _selectedPaths.contains(pdf.path);
                          final isFromAppFolder = pdf.path.contains(FileUtils.appFolderName);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                                  : (isDark ? AppColors.darkCard : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isFromAppFolder
                                        ? AppColors.primary.withValues(alpha: 0.3)
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              leading: Stack(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                pdf.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    FileUtils.formatBytes(pdf.sizeInBytes),
                                    style: TextStyle(
                                      fontSize: 11,
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
                              trailing: widget.isMultiSelect
                                  ? Checkbox(
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: (_) => _toggleSelection(pdf),
                                    )
                                  : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              onTap: () => _toggleSelection(pdf),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Confirm Bar for Multi-Select
          if (widget.isMultiSelect)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Text(
                      '${_selectedPaths.length} ${isBn ? 'টি নির্বাচিত' : 'selected'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _selectedPaths.isEmpty
                          ? null
                          : () {
                              final List<PdfFileModel> selectedList = [];
                              for (final path in _selectedPaths) {
                                final model = _selectedModels[path] ??
                                    _allPdfs.firstWhere(
                                      (p) => p.path == path,
                                      orElse: () => PdfFileModel(
                                        id: path,
                                        path: path,
                                        fileName: path.split('/').last,
                                        sizeInBytes: 0,
                                        modifiedDate: DateTime.now(),
                                      ),
                                    );
                                selectedList.add(model);
                              }
                              Navigator.of(context).pop(selectedList);
                            },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(AppStrings.confirm.tr),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
