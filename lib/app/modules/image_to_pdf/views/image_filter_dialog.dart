import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/image_filter_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/image_file_model.dart';

class ImageFilterDialog extends StatefulWidget {
  final ImageFileModel image;
  final Function(ImageFileModel updatedImage) onApply;
  final Function(DocFilterType filter)? onApplyToAll;

  const ImageFilterDialog({
    super.key,
    required this.image,
    required this.onApply,
    this.onApplyToAll,
  });

  static Future<void> show(
    BuildContext context, {
    required ImageFileModel image,
    required Function(ImageFileModel updatedImage) onApply,
    Function(DocFilterType filter)? onApplyToAll,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageFilterDialog(
        image: image,
        onApply: onApply,
        onApplyToAll: onApplyToAll,
      ),
    );
  }

  @override
  State<ImageFilterDialog> createState() => _ImageFilterDialogState();
}

class _ImageFilterDialogState extends State<ImageFilterDialog> {
  late DocFilterType _selectedFilter;
  late int _rotationAngle;
  Uint8List? _previewBytes;
  Uint8List? _originalBytes;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.image.filterType;
    _rotationAngle = widget.image.rotationAngle;
    _loadOriginalBytes();
  }

  Future<void> _loadOriginalBytes() async {
    final bytes = await widget.image.file.readAsBytes();
    _originalBytes = bytes;
    _updatePreview();
  }

  Future<void> _updatePreview() async {
    if (_originalBytes == null) return;

    if (_selectedFilter == DocFilterType.original && (_rotationAngle % 360 == 0)) {
      if (mounted) {
        setState(() {
          _previewBytes = _originalBytes;
          _isProcessing = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    final processed = await ImageFilterUtils.processImage(
      _originalBytes!,
      filter: _selectedFilter,
      angle: _rotationAngle,
    );

    if (mounted) {
      setState(() {
        _previewBytes = processed;
        _isProcessing = false;
      });
    }
  }

  void _rotate(int deltaAngle) {
    setState(() {
      _rotationAngle = (_rotationAngle + deltaAngle) % 360;
    });
    _updatePreview();
  }

  void _selectFilter(DocFilterType filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    _updatePreview();
  }

  void _applyChanges() {
    final updated = widget.image.copyWith(
      filterType: _selectedFilter,
      rotationAngle: _rotationAngle,
      processedBytes: _previewBytes,
    );
    widget.onApply(updated);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      _FilterOption(DocFilterType.original, AppStrings.original.tr, Icons.image_rounded),
      _FilterOption(DocFilterType.magicColor, AppStrings.magicColor.tr, Icons.auto_awesome_rounded),
      _FilterOption(DocFilterType.blackAndWhite, AppStrings.blackAndWhite.tr, Icons.document_scanner_rounded),
      _FilterOption(DocFilterType.brighten, AppStrings.brighten.tr, Icons.wb_sunny_rounded),
      _FilterOption(DocFilterType.grayscale, AppStrings.grayscale.tr, Icons.filter_b_and_w_rounded),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top Header & Handle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.editImage.tr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.rotate_left_rounded),
                          tooltip: AppStrings.rotateLeft.tr,
                          onPressed: () => _rotate(270),
                        ),
                        IconButton(
                          icon: const Icon(Icons.rotate_right_rounded),
                          tooltip: AppStrings.rotateRight.tr,
                          onPressed: () => _rotate(90),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Preview Area
          Expanded(
            child: Container(
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_previewBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _previewBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      const CircularProgressIndicator(),
                    if (_isProcessing)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Processing...',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Filter Controls & Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter Selection Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((opt) {
                      final isSelected = _selectedFilter == opt.type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            opt.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                          label: Text(opt.label),
                          selected: isSelected,
                          onSelected: (_) => _selectFilter(opt.type),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    if (widget.onApplyToAll != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            widget.onApplyToAll!(_selectedFilter);
                            _applyChanges();
                          },
                          child: Text(
                            AppStrings.applyToAll.tr,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: CustomButton(
                        text: AppStrings.confirm.tr,
                        icon: Icons.check_rounded,
                        onPressed: _applyChanges,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final DocFilterType type;
  final String label;
  final IconData icon;
  _FilterOption(this.type, this.label, this.icon);
}
